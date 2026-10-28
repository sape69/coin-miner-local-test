"use strict";

// ============================================================
// 🐱 STELLURIINI - REFERRAL FUNCTIONS
// ============================================================
//
// Stella Referral System.
//
// Referral-liiketoimintalogiikka kuuluu:
//   services/referralService.js
//
// Tämä tiedosto vastaa callable-rajapinnasta ja referral-tietojen
// palauttamisesta Flutter-sovellukselle.
//
// ============================================================

const {
  onCall,
  HttpsError,
} = require("firebase-functions/v2/https");

const {
  db,
  auth,
  FieldValue,
} = require("../firebase/firebase");

const {
  getUserRef,
  getHistoryCollection,
} = require("../utils/userUtils");

const {
  getUtcDateString,
} = require("../utils/dateUtils");

const {
  REFERRAL_MILESTONES,
} = require("../config/referralConfig");

const {
  normalizeReferralCode,
  isValidReferralCode,
  getReferralData,
} = require("../utils/referralUtils");

const {
  referralsCollection,
  getTotalUsers,
  getCurrentReferralBonusPercent,
  findReferralCode,
  ensureReferralCode,
  createReferralRelationship,
  applyReferralMiningReward,
  getReferralSummary,
} = require("../services/referralService");

// ============================================================
// CONSTANTS
// ============================================================

const MAX_REFERRAL_LIST = 100;

// ============================================================
// VALUE HELPERS
// ============================================================

function number(value, fallback = 0) {
  const result = Number(value);

  return Number.isFinite(result)
    ? result
    : fallback;
}

function nonNegative(value, fallback = 0) {
  const result = Number(value);

  return Number.isFinite(result) && result >= 0
    ? result
    : fallback;
}

// ============================================================
// NEXT REFERRAL MILESTONE
// ============================================================

// Palauttaa seuraavan käyttäjämäärärajan ja siihen kuuluvan
// bonusprosentin. Milestone-asetukset ovat backendissä.

function getNextReferralMilestone(totalUsers) {
  const userCount = Math.max(
    0,
    Math.floor(number(totalUsers, 0)),
  );

  const nextMilestone = REFERRAL_MILESTONES
    .filter((milestone) => (
      number(milestone.minUsers, 0) > userCount
    ))
    .sort((a, b) => (
      number(a.minUsers, 0) - number(b.minUsers, 0)
    ))[0];

  if (!nextMilestone) {
    return null;
  }

  const minUsers = Math.max(
    0,
    Math.floor(number(nextMilestone.minUsers, 0)),
  );

  return {
    minUsers,
    bonusPercent: Math.max(
      0,
      number(nextMilestone.bonusPercent, 0),
    ),
    usersRemaining: Math.max(0, minUsers - userCount),
  };
}

// ============================================================
// TIMESTAMP HELPERS
// ============================================================

function timestampMs(value) {
  if (!value) {
    return 0;
  }

  if (typeof value.toMillis === "function") {
    try {
      const result = value.toMillis();

      return Number.isFinite(result) ? result : 0;
    } catch (_) {
      return 0;
    }
  }

  if (typeof value.toDate === "function") {
    try {
      const date = value.toDate();

      return date instanceof Date &&
          Number.isFinite(date.getTime())
        ? date.getTime()
        : 0;
    } catch (_) {
      return 0;
    }
  }

  if (value instanceof Date) {
    return Number.isFinite(value.getTime())
      ? value.getTime()
      : 0;
  }

  if (typeof value === "string") {
    const result = new Date(value).getTime();

    return Number.isFinite(result) ? result : 0;
  }

  if (typeof value === "number" && Number.isFinite(value)) {
    return value;
  }

  return 0;
}

// ============================================================
// USER DISPLAY NAME
// ============================================================

// Synkroninen varanimi, jota käytetään myös muissa
// referral-toiminnoissa.

function safeDisplayName(data, uid) {
  const candidates = [
    data.username,
    data.displayName,
    data.name,
  ];

  for (const candidate of candidates) {
    if (
      typeof candidate === "string" &&
      candidate.trim()
    ) {
      return candidate.trim().slice(0, 40);
    }
  }

  if (typeof uid === "string" && uid.length > 0) {
    return `Stella Miner ${uid.slice(0, 6)}`;
  }

  return "Stella Miner";
}

// Hakee ensin profiilin nimimerkin.
// Jos sitä ei löydy, yrittää Firebase Authenticationia.

async function getReferralDisplayName(data, uid) {
  const profileName = safeDisplayNameFromProfile(data);

  if (profileName) {
    return profileName;
  }

  try {
    const userRecord = await auth.getUser(uid);

    const authName =
      typeof userRecord.displayName === "string"
        ? userRecord.displayName.trim()
        : "";

    if (authName) {
      return authName.slice(0, 40);
    }
  } catch (error) {
    console.error(
      "Referral display name lookup failed:",
      error,
    );
  }

  return safeDisplayName({}, uid);
}

function safeDisplayNameFromProfile(data) {
  const candidates = [
    data.username,
    data.displayName,
    data.name,
  ];

  for (const candidate of candidates) {
    if (
      typeof candidate === "string" &&
      candidate.trim()
    ) {
      return candidate.trim().slice(0, 40);
    }
  }

  return "";
}

// ============================================================
// MINING STATUS
// ============================================================

function miningWindowActive(data, nowMs) {
  const startMs = timestampMs(data.miningStartedAt);
  const endMs = timestampMs(data.miningEndsAt);

  return (
    startMs > 0 &&
    endMs > startMs &&
    nowMs >= startMs &&
    nowMs < endMs
  );
}

// ============================================================
// LAST MINING ACTIVITY
// ============================================================

function lastActivityMs(data) {
  const candidates = [
    data.lastMiningAt,
    data.lastMiningActivityAt,
    data.lastActiveAt,
    data.updatedAt,
    data.miningStartedAt,
  ];

  let latest = 0;

  for (const value of candidates) {
    latest = Math.max(latest, timestampMs(value));
  }

  return latest;
}

// ============================================================
// REFERRAL BONUS HISTORY
// ============================================================

async function getReferralBonusForUser(
  referrerUid,
  referredUid,
) {
  if (
    typeof referrerUid !== "string" ||
    typeof referredUid !== "string"
  ) {
    return 0;
  }

  let total = 0;

  try {
    const historyQuery = getHistoryCollection(referrerUid)
      .where("referredUid", "==", referredUid)
      .where("type", "==", "referral_reward");

    const snapshot = await historyQuery.get();

    snapshot.forEach((document) => {
      const data = document.data() || {};
      total += nonNegative(data.amount);
    });
  } catch (error) {
    console.error(
      "Referral bonus history error:",
      error,
    );
  }

  return Math.max(0, total);
}

// ============================================================
// GET REFERRAL RELATIONSHIPS
// ============================================================

async function getReferredRelationshipDocuments(uid) {
  const snapshot = await referralsCollection()
    .where("referrerUid", "==", uid)
    .limit(MAX_REFERRAL_LIST)
    .get();

  return snapshot.docs;
}

// ============================================================
// BUILD REFERRAL USER LIST
// ============================================================

async function buildReferralUsers(uid, options = {}) {
  const now =
    options.now instanceof Date
      ? options.now
      : new Date();

  const nowMs = now.getTime();

  const relationshipDocuments =
    await getReferredRelationshipDocuments(uid);

  const users = [];
  const seenReferredUids = new Set();

  for (const relationshipDocument of relationshipDocuments) {
    const relationshipData =
      relationshipDocument.data() || {};

    const referredUid =
      typeof relationshipData.referredUid === "string"
        ? relationshipData.referredUid.trim()
        : relationshipDocument.id;

    if (!referredUid) {
      continue;
    }

    // Sama käyttäjä näytetään vain kerran.
    if (seenReferredUids.has(referredUid)) {
      continue;
    }

    seenReferredUids.add(referredUid);

    const userSnapshot =
      await getUserRef(referredUid).get();

    if (!userSnapshot.exists) {
      continue;
    }

    const userData = userSnapshot.data() || {};

    const active =
      miningWindowActive(userData, nowMs);

    const lastActivity =
      lastActivityMs(userData);

    const referralBonus =
      await getReferralBonusForUser(
        uid,
        referredUid,
      );

    // Hae oikea nimimerkki Firestoresta tai Authista.
    const displayName =
      await getReferralDisplayName(
        userData,
        referredUid,
      );

    users.push({
      uid: referredUid,

      displayName,
      username: displayName,

      active,
      miningActive: active,
      isMining: active,

      lastActivityAt:
        lastActivity > 0
          ? new Date(lastActivity).toISOString()
          : null,

      referralJoinedAt:
        timestampMs(relationshipData.createdAt) > 0
          ? new Date(
              timestampMs(relationshipData.createdAt),
            ).toISOString()
          : timestampMs(userData.referralJoinedAt) > 0
            ? new Date(
                timestampMs(userData.referralJoinedAt),
              ).toISOString()
            : null,

      referralBonusEarned:
        Math.max(0, referralBonus),

      referralBonus:
        Math.max(0, referralBonus),
    });
  }

  users.sort((a, b) => {
    if (a.active !== b.active) {
      return a.active ? -1 : 1;
    }

    return (
      timestampMs(b.lastActivityAt) -
      timestampMs(a.lastActivityAt)
    );
  });

  return users;
}

// ============================================================
// ENSURE REFERRAL CODE
// ============================================================

async function ensureUserReferralCode(uid) {
  return db.runTransaction(async (transaction) => {
    return ensureReferralCode(uid, transaction);
  });
}

// ============================================================
// GET TOTAL REFERRAL REWARDS
// ============================================================

function getTotalReferralRewards(userData) {
  return nonNegative(userData.referralTotalEarned);
}

// ============================================================
// PROCESS REFERRAL MINING REWARD
// ============================================================

async function processReferralMiningReward(
  referredUid,
  miningAmount,
  miningTransactionId,
  transaction,
) {
  if (!transaction) {
    throw new Error(
      "REFERRAL_TRANSACTION_REQUIRED",
    );
  }

  return applyReferralMiningReward(
    referredUid,
    miningAmount,
    miningTransactionId,
    transaction,
  );
}

// ============================================================
// GET REFERRAL PROFILE
// ============================================================

const getReferralProfile = onCall(
  {
    region: "us-central1",
  },
  async (request) => {
    try {
      if (!request.auth) {
        throw new HttpsError(
          "unauthenticated",
          "🐱 Kirjaudu sisään nähdäksesi referral-tietosi.",
        );
      }

      const uid = request.auth.uid;

      const ensured =
        await ensureUserReferralCode(uid);

      const totalUsers =
        await getTotalUsers();

      const bonusConfig =
        await getCurrentReferralBonusPercent();

      const snapshot =
        await getUserRef(uid).get();

      const data =
        snapshot.exists
          ? snapshot.data() || {}
          : {};

      const bonusPercent =
        number(bonusConfig.bonusPercent, 0);

      return {
        success: true,

        referralCode: ensured.code,

        referralBonusPercent: bonusPercent,
        referralBonusRate: bonusPercent / 100,

        totalUsers: Math.max(
          0,
          number(totalUsers, 0),
        ),

        referralMilestones: REFERRAL_MILESTONES,

        totalReferralRewards:
          getTotalReferralRewards(data),

        message:
          "🐱🔗 Stella Referral on valmis.",
      };
    } catch (error) {
      console.error(
        "getReferralProfile error:",
        error,
      );

      if (error instanceof HttpsError) {
        throw error;
      }

      throw new HttpsError(
        "internal",
        "🐱 Referral-tietojen lataaminen epäonnistui.",
      );
    }
  },
);

// ============================================================
// APPLY REFERRAL CODE
// ============================================================

const applyReferralCode = onCall(
  {
    region: "us-central1",
  },
  async (request) => {
    try {
      if (!request.auth) {
        throw new HttpsError(
          "unauthenticated",
          "🐱 Kirjaudu sisään käyttääksesi referral-koodia.",
        );
      }

      const uid = request.auth.uid;

      const code =
        normalizeReferralCode(
          request.data?.referralCode,
        );

      if (!code) {
        throw new HttpsError(
          "invalid-argument",
          "🐱 Referral-koodi puuttuu.",
        );
      }

      if (!isValidReferralCode(code)) {
        throw new HttpsError(
          "invalid-argument",
          "🐱 Referral-koodi ei ole kelvollinen.",
        );
      }

      const result = await db.runTransaction(
        async (transaction) => {
          const userRef = getUserRef(uid);

          const userSnapshot =
            await transaction.get(userRef);

          const userData =
            userSnapshot.exists
              ? userSnapshot.data() || {}
              : {};

          const referralData =
            getReferralData(userData);

          if (referralData.referrerUid) {
            throw new HttpsError(
              "already-exists",
              "🐱 Referral-koodi on jo liitetty tähän käyttäjään.",
            );
          }

          const ownCode =
            normalizeReferralCode(
              userData.referralCode,
            );

          if (ownCode && ownCode === code) {
            throw new HttpsError(
              "invalid-argument",
              "🐱 Et voi käyttää omaa referral-koodiasi.",
            );
          }

          const referrer =
            await findReferralCode(
              code,
              transaction,
            );

          if (!referrer) {
            throw new HttpsError(
              "not-found",
              "🐱 Referral-koodia ei löytynyt.",
            );
          }

          if (referrer.uid === uid) {
            throw new HttpsError(
              "invalid-argument",
              "🐱 Et voi käyttää omaa referral-koodiasi.",
            );
          }

          const relationship =
            await createReferralRelationship(
              uid,
              code,
              transaction,
            );

          if (
            relationship.alreadyExists &&
            relationship.referrerUid
          ) {
            throw new HttpsError(
              "already-exists",
              "🐱 Referral-koodi on jo liitetty tähän käyttäjään.",
            );
          }

          transaction.set(
            getHistoryCollection(uid).doc(),
            {
              type: "referral_joined",
              title: "Stella Referral Joined 🐱🔗",
              referralCode: code,
              referrerUid: referrer.uid,
              createdAt: FieldValue.serverTimestamp(),
            },
          );

          return {
            relationship,
            referrer,
          };
        },
      );

      return {
        success: true,
        applied: true,
        referralCode: code,
        referrerUid: result.referrer.uid,

        referrerName:
          safeDisplayName(
            result.referrer.data,
            result.referrer.uid,
          ),

        message:
          "🐱✨ Referral-koodi liitettiin onnistuneesti!",
      };
    } catch (error) {
      console.error(
        "applyReferralCode error:",
        error,
      );

      if (error instanceof HttpsError) {
        throw error;
      }

      if (error?.message === "REFERRAL_CODE_NOT_FOUND") {
        throw new HttpsError(
          "not-found",
          "🐱 Referral-koodia ei löytynyt.",
        );
      }

      if (error?.message === "REFERRAL_SELF_REFERRAL") {
        throw new HttpsError(
          "invalid-argument",
          "🐱 Et voi käyttää omaa referral-koodiasi.",
        );
      }

      if (
        error?.message ===
        "REFERRAL_REFERRER_ALREADY_SET"
      ) {
        throw new HttpsError(
          "already-exists",
          "🐱 Referral-koodi on jo liitetty tähän käyttäjään.",
        );
      }

      if (error?.message === "REFERRAL_INVALID_CODE") {
        throw new HttpsError(
          "invalid-argument",
          "🐱 Referral-koodi ei ole kelvollinen.",
        );
      }

      throw new HttpsError(
        "internal",
        "🐱 Referral-koodin käyttäminen epäonnistui.",
      );
    }
  },
);

// ============================================================
// GET REFERRED USERS
// ============================================================

const getReferredUsers = onCall(
  {
    region: "us-central1",
    timeoutSeconds: 120,
  },
  async (request) => {
    try {
      if (!request.auth) {
        throw new HttpsError(
          "unauthenticated",
          "🐱 Kirjaudu sisään nähdäksesi kutsutut käyttäjät.",
        );
      }

      const uid = request.auth.uid;
      const now = new Date();
      const today = getUtcDateString(now);

      const referralSummary =
        await getReferralSummary(uid);

      const ensured =
        await ensureUserReferralCode(uid);

      const totalUsers =
        await getTotalUsers();

      const bonusConfig =
        await getCurrentReferralBonusPercent();

      const userSnapshot =
        await getUserRef(uid).get();

      const ownData =
        userSnapshot.exists
          ? userSnapshot.data() || {}
          : {};

      const users =
        await buildReferralUsers(uid, { now });

      const activeCount =
        users.filter((user) => user.active).length;

      const inactiveCount =
        users.length - activeCount;

      const bonusPercent =
        number(bonusConfig.bonusPercent, 0);

      return {
        success: true,

        referralCode: ensured.code,

        referralBonusPercent: bonusPercent,
        referralBonusRate: bonusPercent / 100,

        totalUsers: Math.max(
          0,
          number(totalUsers, 0),
        ),

        invitedCount: users.length,
        activeCount,
        inactiveCount,

        totalReferralRewards:
          getTotalReferralRewards(ownData),

        referralSummary,

        generatedAt: now.toISOString(),
        utcDate: today,

        users,
      };
    } catch (error) {
      console.error(
        "getReferredUsers error:",
        error,
      );

      if (error instanceof HttpsError) {
        throw error;
      }

      throw new HttpsError(
        "internal",
        "🐱 Kutsuttujen käyttäjien lataaminen epäonnistui.",
      );
    }
  },
);

// ============================================================
// GET REFERRAL STATUS
// ============================================================

const getReferralStatus = onCall(
  {
    region: "us-central1",
    timeoutSeconds: 120,
  },
  async (request) => {
    try {
      if (!request.auth) {
        throw new HttpsError(
          "unauthenticated",
          "🐱 Kirjaudu sisään nähdäksesi Stella Referralin.",
        );
      }

      const uid = request.auth.uid;
      const now = new Date();

      const ensured =
        await ensureUserReferralCode(uid);

      const userSnapshot =
        await getUserRef(uid).get();

      const userData =
        userSnapshot.exists
          ? userSnapshot.data() || {}
          : {};

      // Haetaan palvelimen nykyinen bonusprosentti.
      // Näin sovelluksen näyttämä prosentti vastaa
      // referral-palvelun voimassa olevaa asetusta.
      const bonusConfig =
        await getCurrentReferralBonusPercent();

      const bonusPercent =
        number(bonusConfig.bonusPercent, 0);

      // Käytetään palvelimen nykyistä käyttäjämäärää,
      // jonka perusteella bonusprosentti on laskettu.
      const totalUsers = Math.max(
        0,
        Math.floor(number(bonusConfig.totalUsers, 0)),
      );

      const nextReferralMilestone =
        getNextReferralMilestone(totalUsers);

      const referrals =
        await buildReferralUsers(uid, { now });

      const activeCount =
        referrals.filter(
          (referral) => referral.isMining,
        ).length;

      const inactiveCount =
        referrals.length - activeCount;

      const compactReferrals =
        referrals.map((referral) => ({
          uid: referral.uid,
          username: referral.username,
          isMining: referral.isMining,
          referralBonus: referral.referralBonus,
        }));

      return {
        success: true,

        referralCode: ensured.code,

        // Referral-bonus prosentteina ja desimaalina.
        // Esimerkiksi 24 ja 0.24 tarkoittavat 24 %.
        referralBonusPercent: bonusPercent,
        referralBonusRate: bonusPercent / 100,

        // Käyttäjämäärä ja seuraava bonusporras UI:ta varten.
        totalUsers,
        nextReferralMilestone,

        referralCount: referrals.length,
        activeCount,
        inactiveCount,

        referrals: compactReferrals,

        totalReferralRewards:
          getTotalReferralRewards(userData),

        generatedAt: now.toISOString(),
      };
    } catch (error) {
      console.error(
        "getReferralStatus error:",
        error,
      );

      if (error instanceof HttpsError) {
        throw error;
      }

      throw new HttpsError(
        "internal",
        "🐱 Referral-tietojen lataaminen epäonnistui.",
      );
    }
  },
);

// ============================================================
// GET FULL REFERRAL DASHBOARD
// ============================================================

const getReferralDashboard = onCall(
  {
    region: "us-central1",
    timeoutSeconds: 120,
  },
  async (request) => {
    try {
      if (!request.auth) {
        throw new HttpsError(
          "unauthenticated",
          "🐱 Kirjaudu sisään nähdäksesi Stella Referralin.",
        );
      }

      const uid = request.auth.uid;
      const now = new Date();

      const ensured =
        await ensureUserReferralCode(uid);

      const userSnapshot =
        await getUserRef(uid).get();

      const userData =
        userSnapshot.exists
          ? userSnapshot.data() || {}
          : {};

      const totalUsers =
        await getTotalUsers();

      const bonusConfig =
        await getCurrentReferralBonusPercent();

      const users =
        await buildReferralUsers(uid, { now });

      const activeCount =
        users.filter((user) => user.active).length;

      const inactiveCount =
        users.length - activeCount;

      const bonusPercent =
        number(bonusConfig.bonusPercent, 0);

      return {
        success: true,

        referralCode: ensured.code,

        referralBonusPercent: bonusPercent,
        referralBonusRate: bonusPercent / 100,

        totalUsers: Math.max(
          0,
          number(totalUsers, 0),
        ),

        invitedCount: users.length,
        activeCount,
        inactiveCount,

        totalReferralRewards:
          getTotalReferralRewards(userData),

        users,

        generatedAt: now.toISOString(),
      };
    } catch (error) {
      console.error(
        "getReferralDashboard error:",
        error,
      );

      if (error instanceof HttpsError) {
        throw error;
      }

      throw new HttpsError(
        "internal",
        "🐱 Stella Referral Dashboardin lataaminen epäonnistui.",
      );
    }
  },
);

// ============================================================
// EXPORTS
// ============================================================

module.exports = {
  // Mining käyttää tätä.
  processReferralMiningReward,

  // Säilytetään nykyinen service-wrapper.
  applyReferralMiningReward,

  // Callable Functions
  getReferralProfile,
  applyReferralCode,
  getReferredUsers,
  getReferralStatus,
  getReferralDashboard,
};