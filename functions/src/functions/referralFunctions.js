"use strict";

// ============================================================
// 🐱 STELLURIINI - REFERRAL FUNCTIONS
// ============================================================
//
// Stella Referral System.
//
// Tämä tiedosto sisältää Firebase Callable Functions -rajapinnan.
//
// TÄRKEÄÄ:
//
// Referral-liiketoimintalogiikka kuuluu:
//
//   services/referralService.js
//
// Tämä tiedosto EI päätä:
// - referral-bonusprosenttia
// - bonusmäärää
// - referral-koodin uniikkiutta
// - referral-suhdetta
// - referral-idempotenssia
//
// Service hoitaa nämä asiat server-side.
//
// Client voi pyytää:
//
// - oman referral-koodin
// - referral-koodin käyttämistä
// - kutsuttujen käyttäjien listan
// - referral-statuksen
// - referral-dashboardin
//
// ============================================================

const {
  onCall,
  HttpsError,
} = require("firebase-functions/v2/https");

const {
  db,
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
  getReferralData,
} = require("../utils/referralUtils");

const {
  referralCodesCollection,
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

function number(
  value,
  fallback = 0,
) {
  const result =
    Number(value);

  return Number.isFinite(result)
    ? result
    : fallback;
}

function nonNegative(
  value,
  fallback = 0,
) {
  const result =
    Number(value);

  return Number.isFinite(result) &&
      result >= 0
    ? result
    : fallback;
}

// ============================================================
// TIMESTAMP HELPERS
// ============================================================

function timestampMs(
  value,
) {
  if (!value) {
    return 0;
  }

  if (
    typeof value.toMillis ===
    "function"
  ) {
    try {
      const result =
        value.toMillis();

      return Number.isFinite(result)
        ? result
        : 0;
    } catch (_) {
      return 0;
    }
  }

  if (
    typeof value.toDate ===
    "function"
  ) {
    try {
      const date =
        value.toDate();

      return date instanceof Date &&
          Number.isFinite(
            date.getTime(),
          )
        ? date.getTime()
        : 0;
    } catch (_) {
      return 0;
    }
  }

  if (
    value instanceof Date
  ) {
    return Number.isFinite(
      value.getTime(),
    )
      ? value.getTime()
      : 0;
  }

  if (
    typeof value ===
    "string"
  ) {
    const result =
      new Date(value).getTime();

    return Number.isFinite(result)
      ? result
      : 0;
  }

  if (
    typeof value ===
      "number" &&
    Number.isFinite(value)
  ) {
    return value;
  }

  return 0;
}

// ============================================================
// USER DISPLAY NAME
// ============================================================

function safeDisplayName(
  data,
  uid,
) {
  const candidates = [
    data.username,
    data.displayName,
    data.name,
  ];

  for (
    const candidate of
      candidates
  ) {
    if (
      typeof candidate ===
        "string" &&
      candidate.trim()
    ) {
      return candidate
        .trim()
        .slice(0, 40);
    }
  }

  if (
    typeof uid ===
      "string" &&
    uid.length > 0
  ) {
    return `Stella Miner ${uid.slice(
      0,
      6,
    )}`;
  }

  return "Stella Miner";
}

// ============================================================
// MINING STATUS
// ============================================================
//
// ACTIVE:
//
//   miningStartedAt <= now < miningEndsAt
//
// TÄRKEÄÄ:
//
// Referral-aktiivisuus tarkoittaa tässä:
//
//   käyttäjän mining-jakso on parhaillaan käynnissä.
//
// Se EI tarkoita:
//
// - viimeksi kirjautunutta
// - viimeksi sovellusta käyttänyttä
// - viimeksi päivitettyä käyttäjää
//
// ============================================================

function miningWindowActive(
  data,
  nowMs,
) {
  const startMs =
    timestampMs(
      data.miningStartedAt,
    );

  const endMs =
    timestampMs(
      data.miningEndsAt,
    );

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
//
// Tätä käytetään vain listan järjestämiseen.
//
// Se EI määritä active/inactive-tilaa.
//
// ============================================================

function lastActivityMs(
  data,
) {
  const candidates = [
    data.lastMiningAt,
    data.lastMiningActivityAt,
    data.lastActiveAt,
    data.updatedAt,
    data.miningStartedAt,
  ];

  let latest = 0;

  for (
    const value of
      candidates
  ) {
    latest =
      Math.max(
        latest,
        timestampMs(value),
      );
  }

  return latest;
}

// ============================================================
// REFERRAL BONUS HISTORY
// ============================================================
//
// Hakee yhden kutsutun käyttäjän tuottaman referral-bonuksen
// kutsujalle.
//
// Varsinainen bonuslaskenta tapahtuu referralServicessä.
// Tämä funktio vain lukee historian käyttöliittymää varten.
//
// ============================================================

async function getReferralBonusForUser(
  referrerUid,
  referredUid,
) {
  if (
    typeof referrerUid !==
      "string" ||
    typeof referredUid !==
      "string"
  ) {
    return 0;
  }

  let total = 0;

  try {
    const historyQuery =
      getHistoryCollection(
        referrerUid,
      )
        .where(
          "referredUid",
          "==",
          referredUid,
        )
        .where(
          "type",
          "==",
          "referral_reward",
        );

    const snapshot =
      await historyQuery.get();

    snapshot.forEach(
      (document) => {
        const data =
          document.data() || {};

        total +=
          nonNegative(
            data.amount,
          );
      },
    );
  } catch (error) {
    console.error(
      "Referral bonus history error:",
      error,
    );
  }

  return Math.max(
    0,
    total,
  );
}

// ============================================================
// GET REFERRAL RELATIONSHIPS
// ============================================================
//
// Uusi referral-arkkitehtuuri käyttää:
//
//   referrals/{referredUid}
//
// eikä enää pelkästään:
//
//   users.where("referrerUid", "==", uid)
//
// ============================================================

async function getReferredRelationshipDocuments(
  uid,
) {
  const query =
    referralsCollection()
      .where(
        "referrerUid",
        "==",
        uid,
      )
      .limit(
        MAX_REFERRAL_LIST,
      );

  const snapshot =
    await query.get();

  return snapshot.docs;
}

// ============================================================
// BUILD REFERRAL USER LIST
// ============================================================

async function buildReferralUsers(
  uid,
  options = {},
) {
  const now =
    options.now instanceof Date
      ? options.now
      : new Date();

  const nowMs =
    now.getTime();

  const relationshipDocuments =
    await getReferredRelationshipDocuments(
      uid,
    );

  const users = [];

  for (
    const relationshipDocument
      of relationshipDocuments
  ) {
    const relationshipData =
      relationshipDocument.data() ||
      {};

    const referredUid =
      typeof relationshipData.referredUid ===
          "string"
        ? relationshipData.referredUid.trim()
        : relationshipDocument.id;

    if (!referredUid) {
      continue;
    }

    const userSnapshot =
      await getUserRef(
        referredUid,
      ).get();

    if (
      !userSnapshot.exists
    ) {
      continue;
    }

    const userData =
      userSnapshot.data() || {};

    const active =
      miningWindowActive(
        userData,
        nowMs,
      );

    const lastActivity =
      lastActivityMs(
        userData,
      );

    const referralBonus =
      await getReferralBonusForUser(
        uid,
        referredUid,
      );

    users.push({
      uid:
        referredUid,

      displayName:
        safeDisplayName(
          userData,
          referredUid,
        ),

      username:
        safeDisplayName(
          userData,
          referredUid,
        ),

      active,

      miningActive:
        active,

      isMining:
        active,

      lastActivityAt:
        lastActivity > 0
          ? new Date(
              lastActivity,
            ).toISOString()
          : null,

      referralJoinedAt:
        timestampMs(
          relationshipData.createdAt,
        ) > 0
          ? new Date(
              timestampMs(
                relationshipData.createdAt,
              ),
            ).toISOString()
          : timestampMs(
                userData.referralJoinedAt,
              ) > 0
            ? new Date(
                timestampMs(
                  userData.referralJoinedAt,
                ),
              ).toISOString()
            : null,

      referralBonusEarned:
        Math.max(
          0,
          referralBonus,
        ),

      referralBonus:
        Math.max(
          0,
          referralBonus,
        ),
    });
  }

  users.sort(
    (a, b) => {
      if (
        a.active !==
        b.active
      ) {
        return a.active
          ? -1
          : 1;
      }

      return (
        timestampMs(
          b.lastActivityAt,
        ) -
        timestampMs(
          a.lastActivityAt,
        )
      );
    },
  );

  return users;
}

// ============================================================
// ENSURE REFERRAL CODE - CALLABLE SAFE WRAPPER
// ============================================================
//
// referralService.ensureReferralCode() vaatii Firestore
// transactionin.
//
// Tämä wrapper hoitaa transaktion callable-kutsulle.
//
// ============================================================

async function ensureUserReferralCode(
  uid,
) {
  return db.runTransaction(
    async (transaction) => {
      return ensureReferralCode(
        uid,
        transaction,
      );
    },
  );
}

// ============================================================
// GET TOTAL REFERRAL REWARDS
// ============================================================

function getTotalReferralRewards(
  userData,
) {
  return nonNegative(
    userData.referralTotalEarned,
  );
}

// ============================================================
// GET REFERRAL PROFILE
// ============================================================

const getReferralProfile =
  onCall(
    {
      region:
        "us-central1",
    },
    async (request) => {
      try {
        if (!request.auth) {
          throw new HttpsError(
            "unauthenticated",
            "🐱 Kirjaudu sisään nähdäksesi referral-tietosi.",
          );
        }

        const uid =
          request.auth.uid;

        const ensured =
          await ensureUserReferralCode(
            uid,
          );

        const totalUsers =
          await getTotalUsers();

        const bonusConfig =
          getCurrentReferralBonusPercent();

        const snapshot =
          await getUserRef(
            uid,
          ).get();

        const data =
          snapshot.exists
            ? snapshot.data() || {}
            : {};

        const bonusPercent =
          number(
            bonusConfig.bonusPercent,
            0,
          );

        return {
          success:
            true,

          referralCode:
            ensured.code,

          referralBonusPercent:
            bonusPercent,

          referralBonusRate:
            bonusPercent / 100,

          totalUsers:
            Math.max(
              0,
              number(
                totalUsers,
                0,
              ),
            ),

          referralMilestones:
            REFERRAL_MILESTONES,

          totalReferralRewards:
            getTotalReferralRewards(
              data,
            ),

          message:
            "🐱🔗 Stella Referral on valmis.",
        };
      } catch (error) {
        console.error(
          "getReferralProfile error:",
          error,
        );

        if (
          error instanceof
          HttpsError
        ) {
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
//
// Referral-suhde luodaan referralServicen kautta.
//
// ============================================================

const applyReferralCode =
  onCall(
    {
      region:
        "us-central1",
    },
    async (request) => {
      try {
        if (!request.auth) {
          throw new HttpsError(
            "unauthenticated",
            "🐱 Kirjaudu sisään käyttääksesi referral-koodia.",
          );
        }

        const uid =
          request.auth.uid;

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

        if (
          code.length < 4
        ) {
          throw new HttpsError(
            "invalid-argument",
            "🐱 Referral-koodi on liian lyhyt.",
          );
        }

        const result =
          await db.runTransaction(
            async (transaction) => {
              const userRef =
                getUserRef(uid);

              const userSnapshot =
                await transaction.get(
                  userRef,
                );

              const userData =
                userSnapshot.exists
                  ? userSnapshot.data() || {}
                  : {};

              const referralData =
                getReferralData(
                  userData,
                );

              // ------------------------------------------------
              // Referral-suhdetta ei voi vaihtaa.
              // ------------------------------------------------

              if (
                referralData.referrerUid
              ) {
                throw new HttpsError(
                  "already-exists",
                  "🐱 Referral-koodi on jo liitetty tähän käyttäjään.",
                );
              }

              // ------------------------------------------------
              // Oma koodi
              // ------------------------------------------------

              const ownCode =
                normalizeReferralCode(
                  userData.referralCode,
                );

              if (
                ownCode &&
                ownCode === code
              ) {
                throw new HttpsError(
                  "invalid-argument",
                  "🐱 Et voi käyttää omaa referral-koodiasi.",
                );
              }

              // ------------------------------------------------
              // Varmista, että koodi löytyy.
              // ------------------------------------------------

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

              if (
                referrer.uid === uid
              ) {
                throw new HttpsError(
                  "invalid-argument",
                  "🐱 Et voi käyttää omaa referral-koodiasi.",
                );
              }

              // ------------------------------------------------
              // Service luo varsinaisen suhteen.
              // ------------------------------------------------

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

              // ------------------------------------------------
              // Referral history
              // ------------------------------------------------

              transaction.set(
                getHistoryCollection(
                  uid,
                ).doc(),
                {
                  type:
                    "referral_joined",

                  title:
                    "Stella Referral Joined 🐱🔗",

                  referralCode:
                    code,

                  referrerUid:
                    referrer.uid,

                  createdAt:
                    FieldValue.serverTimestamp(),
                },
              );

              return {
                relationship,
                referrer,
              };
            },
          );

        return {
          success:
            true,

          applied:
            true,

          referralCode:
            code,

          referrerUid:
            result.referrer.uid,

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

        if (
          error instanceof
          HttpsError
        ) {
          throw error;
        }

        if (
          error?.message ===
          "REFERRAL_CODE_NOT_FOUND"
        ) {
          throw new HttpsError(
            "not-found",
            "🐱 Referral-koodia ei löytynyt.",
          );
        }

        if (
          error?.message ===
          "REFERRAL_SELF_REFERRAL"
        ) {
          throw new HttpsError(
            "invalid-argument",
            "🐱 Et voi käyttää omaa referral-koodiasi.",
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

const getReferredUsers =
  onCall(
    {
      region:
        "us-central1",

      timeoutSeconds:
        120,
    },
    async (request) => {
      try {
        if (!request.auth) {
          throw new HttpsError(
            "unauthenticated",
            "🐱 Kirjaudu sisään nähdäksesi kutsutut käyttäjät.",
          );
        }

        const uid =
          request.auth.uid;

        const now =
          new Date();

        const today =
          getUtcDateString(
            now,
          );

        const referralSummary =
          await getReferralSummary(
            uid,
          );

        const ensured =
          await ensureUserReferralCode(
            uid,
          );

        const totalUsers =
          await getTotalUsers();

        const bonusConfig =
          getCurrentReferralBonusPercent();

        const userSnapshot =
          await getUserRef(
            uid,
          ).get();

        const ownData =
          userSnapshot.exists
            ? userSnapshot.data() || {}
            : {};

        const users =
          await buildReferralUsers(
            uid,
            {
              now,
            },
          );

        const activeCount =
          users.filter(
            (user) =>
              user.active,
          ).length;

        const inactiveCount =
          users.length -
          activeCount;

        const bonusPercent =
          number(
            bonusConfig.bonusPercent,
            0,
          );

        return {
          success:
            true,

          referralCode:
            ensured.code,

          referralBonusPercent:
            bonusPercent,

          referralBonusRate:
            bonusPercent / 100,

          totalUsers:
            Math.max(
              0,
              number(
                totalUsers,
                0,
              ),
            ),

          invitedCount:
            users.length,

          activeCount,

          inactiveCount,

          totalReferralRewards:
            getTotalReferralRewards(
              ownData,
            ),

          referralSummary,

          generatedAt:
            now.toISOString(),

          utcDate:
            today,

          users,
        };
      } catch (error) {
        console.error(
          "getReferredUsers error:",
          error,
        );

        if (
          error instanceof
          HttpsError
        ) {
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
//
// Flutter ReferralsPage käyttää tätä callablea.
//
// Palautetaan edelleen yhteensopiva rakenne:
//
// {
//   referralCode: "...",
//   referralCount: 5,
//   activeCount: 2,
//   inactiveCount: 3,
//   referrals: [
//     {
//       uid: "...",
//       username: "...",
//       isMining: true,
//       referralBonus: 12.5
//     }
//   ]
// }
//
// ============================================================

const getReferralStatus =
  onCall(
    {
      region:
        "us-central1",

      timeoutSeconds:
        120,
    },
    async (request) => {
      try {
        if (!request.auth) {
          throw new HttpsError(
            "unauthenticated",
            "🐱 Kirjaudu sisään nähdäksesi Stella Referralin.",
          );
        }

        const uid =
          request.auth.uid;

        const now =
          new Date();

        const ensured =
          await ensureUserReferralCode(
            uid,
          );

        const userSnapshot =
          await getUserRef(
            uid,
          ).get();

        const userData =
          userSnapshot.exists
            ? userSnapshot.data() || {}
            : {};

        const referrals =
          await buildReferralUsers(
            uid,
            {
              now,
            },
          );

        const activeCount =
          referrals.filter(
            (referral) =>
              referral.isMining,
          ).length;

        const inactiveCount =
          referrals.length -
          activeCount;

        // ------------------------------------------------------
        // Flutter-yhteensopiva suppea lista
        // ------------------------------------------------------

        const compactReferrals =
          referrals.map(
            (referral) => ({
              uid:
                referral.uid,

              username:
                referral.username,

              isMining:
                referral.isMining,

              referralBonus:
                referral.referralBonus,
            }),
          );

        return {
          success:
            true,

          referralCode:
            ensured.code,

          referralCount:
            referrals.length,

          activeCount,

          inactiveCount,

          referrals:
            compactReferrals,

          totalReferralRewards:
            getTotalReferralRewards(
              userData,
            ),

          generatedAt:
            now.toISOString(),
        };
      } catch (error) {
        console.error(
          "getReferralStatus error:",
          error,
        );

        if (
          error instanceof
          HttpsError
        ) {
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

const getReferralDashboard =
  onCall(
    {
      region:
        "us-central1",

      timeoutSeconds:
        120,
    },
    async (request) => {
      try {
        if (!request.auth) {
          throw new HttpsError(
            "unauthenticated",
            "🐱 Kirjaudu sisään nähdäksesi Stella Referralin.",
          );
        }

        const uid =
          request.auth.uid;

        const now =
          new Date();

        const ensured =
          await ensureUserReferralCode(
            uid,
          );

        const userSnapshot =
          await getUserRef(
            uid,
          ).get();

        const userData =
          userSnapshot.exists
            ? userSnapshot.data() || {}
            : {};

        const totalUsers =
          await getTotalUsers();

        const bonusConfig =
          getCurrentReferralBonusPercent();

        const users =
          await buildReferralUsers(
            uid,
            {
              now,
            },
          );

        const activeCount =
          users.filter(
            (user) =>
              user.active,
          ).length;

        const inactiveCount =
          users.length -
          activeCount;

        const bonusPercent =
          number(
            bonusConfig.bonusPercent,
            0,
          );

        return {
          success:
            true,

          referralCode:
            ensured.code,

          referralBonusPercent:
            bonusPercent,

          referralBonusRate:
            bonusPercent / 100,

          totalUsers:
            Math.max(
              0,
              number(
                totalUsers,
                0,
              ),
            ),

          invitedCount:
            users.length,

          activeCount,

          inactiveCount,

          totalReferralRewards:
            getTotalReferralRewards(
              userData,
            ),

          users,

          generatedAt:
            now.toISOString(),
        };
      } catch (error) {
        console.error(
          "getReferralDashboard error:",
          error,
        );

        if (
          error instanceof
          HttpsError
        ) {
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
  // ----------------------------------------------------------
  // Mining käyttää tätä.
  // ----------------------------------------------------------

  applyReferralMiningReward,

  // ----------------------------------------------------------
  // Callable Functions
  // ----------------------------------------------------------

  getReferralProfile,

  applyReferralCode,

  getReferredUsers,

  getReferralStatus,

  getReferralDashboard,
};