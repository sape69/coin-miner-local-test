"use strict";

// ============================================================
// 🐱 STELLURIINI - REFERRAL FUNCTIONS
// ============================================================
//
// Stella Referral System.
//
// Referral-järjestelmä toimii kokonaan backendissä.
//
// Client EI päätä:
// - referral-bonusprosenttia
// - bonusmäärää
// - referreria
// - aktiivisuustilaa
// - referral-palkkion maksamista
//
// Client voi pyytää:
// - oman referral-koodin
// - kutsuttujen käyttäjien listan
// - aktiivisten kutsuttujen määrän
// - referral-bonusten kokonaismäärän
//
// Referral mining reward:
// - maksetaan kutsujalle vain hyväksytystä mining-tuotosta
// - käsitellään Firestore-transaktion sisällä
// - käytetään miningTransactionId:tä idempotenssin varmistamiseen
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
  REFERRAL_BONUS_PERCENT,
  REFERRAL_ACTIVE_DAYS,
} = require("../config/referralConfig");

// ============================================================
// CONSTANTS
// ============================================================

const DEFAULT_ACTIVE_DAYS = 7;

const MAX_REFERRAL_LIST = 100;

const REFERRAL_CODE_LENGTH = 8;

const REFERRAL_CODE_ALPHABET =
  "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";

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

function positive(value, fallback = 0) {
  const result = Number(value);

  return Number.isFinite(result) && result > 0
    ? result
    : fallback;
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

      return Number.isFinite(result)
        ? result
        : 0;
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
    const result =
      new Date(value).getTime();

    return Number.isFinite(result)
      ? result
      : 0;
  }

  if (
    typeof value === "number" &&
    Number.isFinite(value)
  ) {
    return value;
  }

  return 0;
}

// ============================================================
// REFERRAL CONFIG HELPERS
// ============================================================

function referralBonusPercent() {
  const configured =
    number(
      REFERRAL_BONUS_PERCENT,
      0
    );

  return Math.max(
    0,
    Math.min(
      100,
      configured
    )
  );
}

function referralActiveDays() {
  const configured =
    positive(
      REFERRAL_ACTIVE_DAYS,
      DEFAULT_ACTIVE_DAYS
    );

  return Math.max(
    1,
    Math.floor(configured)
  );
}

// ============================================================
// REFERRAL CODE
// ============================================================

function normalizeReferralCode(value) {
  if (
    typeof value !== "string"
  ) {
    return "";
  }

  return value
    .trim()
    .toUpperCase()
    .replace(
      /[^A-Z0-9]/g,
      ""
    );
}

function generateReferralCode() {
  let code = "";

  for (
    let i = 0;
    i < REFERRAL_CODE_LENGTH;
    i++
  ) {
    const index =
      Math.floor(
        Math.random() *
          REFERRAL_CODE_ALPHABET.length
      );

    code +=
      REFERRAL_CODE_ALPHABET[index];
  }

  return code;
}

// ============================================================
// USER DISPLAY NAME
// ============================================================

function safeDisplayName(data, uid) {
  const candidates = [
    data.username,
    data.displayName,
    data.name,
  ];

  for (
    const candidate of candidates
  ) {
    if (
      typeof candidate === "string" &&
      candidate.trim()
    ) {
      return candidate
        .trim()
        .slice(0, 40);
    }
  }

  if (
    typeof uid === "string" &&
    uid.length > 0
  ) {
    return `Stella Miner ${uid.slice(0, 6)}`;
  }

  return "Stella Miner";
}

// ============================================================
// ACTIVITY
// ============================================================

function miningWindowActive(
  data,
  nowMs
) {
  const startMs =
    timestampMs(
      data.miningStartedAt
    );

  const endMs =
    timestampMs(
      data.miningEndsAt
    );

  return (
    startMs > 0 &&
    endMs > startMs &&
    nowMs >= startMs &&
    nowMs < endMs
  );
}

function lastActivityMs(data) {
  const candidates = [
    data.lastMiningAt,
    data.lastMiningActivityAt,
    data.lastActiveAt,
    data.updatedAt,
    data.miningStartedAt,
  ];

  let latest = 0;

  for (
    const value of candidates
  ) {
    latest =
      Math.max(
        latest,
        timestampMs(value)
      );
  }

  return latest;
}

function isReferralUserActive(
  data,
  nowMs
) {
  if (
    miningWindowActive(
      data,
      nowMs
    )
  ) {
    return true;
  }

  const lastActivity =
    lastActivityMs(data);

  if (
    lastActivity <= 0
  ) {
    return false;
  }

  const activeWindowMs =
    referralActiveDays() *
    24 *
    60 *
    60 *
    1000;

  return (
    nowMs -
      lastActivity <=
    activeWindowMs
  );
}

// ============================================================
// REFERRAL CODE LOOKUP
// ============================================================

async function findUserByReferralCode(
  code,
  transaction = null
) {
  const normalized =
    normalizeReferralCode(code);

  if (!normalized) {
    return null;
  }

  const query =
    db.collection("users")
      .where(
        "referralCode",
        "==",
        normalized
      )
      .limit(1);

  const snapshot =
    transaction
      ? await transaction.get(query)
      : await query.get();

  if (
    snapshot.empty
  ) {
    return null;
  }

  const document =
    snapshot.docs[0];

  return {
    uid: document.id,
    ref: document.ref,
    data:
      document.data() || {},
  };
}

// ============================================================
// ENSURE OWN REFERRAL CODE
// ============================================================

async function ensureReferralCode(
  uid
) {
  const userRef =
    getUserRef(uid);

  const snapshot =
    await userRef.get();

  const data =
    snapshot.exists
      ? snapshot.data() || {}
      : {};

  const existing =
    normalizeReferralCode(
      data.referralCode
    );

  if (existing) {
    return existing;
  }

  for (
    let attempt = 0;
    attempt < 10;
    attempt++
  ) {
    const code =
      generateReferralCode();

    const existingUser =
      await findUserByReferralCode(
        code
      );

    if (existingUser) {
      continue;
    }

    await userRef.set(
      {
        referralCode:
          code,

        referralCodeCreatedAt:
          FieldValue.serverTimestamp(),

        updatedAt:
          FieldValue.serverTimestamp(),
      },
      {
        merge: true,
      }
    );

    return code;
  }

  throw new HttpsError(
    "resource-exhausted",
    "🐱 Referral-koodin luominen epäonnistui. Yritä uudelleen."
  );
}

// ============================================================
// PROCESS REFERRAL MINING REWARD
// ============================================================
//
// Tätä funktiota kutsuu miningFunctions.js:
//
// processReferralMiningReward(
//   transaction,
//   uid,
//   collected,
//   miningTransactionId
// )
//
// TÄRKEÄÄ:
//
// Tämä funktio ei tee erillistä Firestore transactionia.
// Se käyttää miningFunctions.js:n olemassa olevaa transactionia.
//
// ============================================================

async function processReferralMiningReward(
  transaction,
  referredUid,
  miningAmount,
  miningTransactionId
) {
  const collected =
    nonNegative(
      miningAmount
    );

  if (
    !transaction
  ) {
    throw new Error(
      "Referral reward requires a Firestore transaction."
    );
  }

  if (
    !referredUid
  ) {
    return {
      rewarded: false,
      duplicate: false,
      bonus: 0,
    };
  }

  if (
    collected <= 0
  ) {
    return {
      rewarded: false,
      duplicate: false,
      bonus: 0,
    };
  }

  if (
    typeof miningTransactionId !==
      "string" ||
    !miningTransactionId.trim()
  ) {
    return {
      rewarded: false,
      duplicate: false,
      bonus: 0,
    };
  }

  const referredUserRef =
    getUserRef(
      referredUid
    );

  const referredSnapshot =
    await transaction.get(
      referredUserRef
    );

  if (
    !referredSnapshot.exists
  ) {
    return {
      rewarded: false,
      duplicate: false,
      bonus: 0,
    };
  }

  const referredData =
    referredSnapshot.data() || {};

  const referrerUid =
    typeof referredData.referrerUid ===
      "string"
      ? referredData.referrerUid.trim()
      : "";

  if (
    !referrerUid ||
    referrerUid === referredUid
  ) {
    return {
      rewarded: false,
      duplicate: false,
      bonus: 0,
    };
  }

  const referrerRef =
    getUserRef(
      referrerUid
    );

  const referrerSnapshot =
    await transaction.get(
      referrerRef
    );

  if (
    !referrerSnapshot.exists
  ) {
    return {
      rewarded: false,
      duplicate: false,
      bonus: 0,
      referrerUid,
    };
  }

  const referrerData =
    referrerSnapshot.data() || {};

  // ----------------------------------------------------------
  // IDEMPOTENCY
  // ----------------------------------------------------------

  const historyRef =
    getHistoryCollection(
      referrerUid
    ).doc(
      `referral_${miningTransactionId}`
    );

  const existingHistory =
    await transaction.get(
      historyRef
    );

  if (
    existingHistory.exists
  ) {
    return {
      rewarded: false,
      duplicate: true,
      bonus: 0,
      referrerUid,
    };
  }

  // ----------------------------------------------------------
  // BONUS
  // ----------------------------------------------------------

  const bonusPercent =
    referralBonusPercent();

  const bonusRate =
    bonusPercent / 100;

  const bonus =
    Math.max(
      0,
      collected *
        bonusRate
    );

  if (
    bonus <= 0
  ) {
    return {
      rewarded: false,
      duplicate: false,
      bonus: 0,
      referrerUid,
      bonusPercent,
      bonusRate,
    };
  }

  const oldBalance =
    nonNegative(
      referrerData.miningBalance
    );

  const newBalance =
    oldBalance +
    bonus;

  // ----------------------------------------------------------
  // REFERRER BALANCE
  // ----------------------------------------------------------

  transaction.set(
    referrerRef,
    {
      miningBalance:
        newBalance,

      referralTotalEarned:
        FieldValue.increment(
          bonus
        ),

      referralLastRewardAt:
        FieldValue.serverTimestamp(),

      updatedAt:
        FieldValue.serverTimestamp(),
    },
    {
      merge: true,
    }
  );

  // ----------------------------------------------------------
  // REFERRAL HISTORY
  // ----------------------------------------------------------

  transaction.set(
    historyRef,
    {
      type:
        "referral_reward",

      title:
        "Stella Referral Reward 🐱🔗✨",

      amount:
        bonus,

      balanceAfter:
        newBalance,

      referredUid,

      referrerUid,

      miningAmount:
        collected,

      bonus:
        bonus,

      bonusPercent:
        bonusPercent,

      bonusRate:
        bonusRate,

      miningTransactionId:
        miningTransactionId,

      createdAt:
        FieldValue.serverTimestamp(),
    },
    {
      merge: false,
    }
  );

  // ----------------------------------------------------------
  // REFERRER SUMMARY
  // ----------------------------------------------------------

  transaction.set(
    referrerRef,
    {
      referralLastMiningAmount:
        collected,

      referralLastBonus:
        bonus,

      referralLastReferredUid:
        referredUid,

      updatedAt:
        FieldValue.serverTimestamp(),
    },
    {
      merge: true,
    }
  );

  return {
    rewarded: true,
    duplicate: false,
    bonus,
    referrerUid,
    bonusPercent,
    bonusRate,
  };
}

// ============================================================
// GET REFERRAL PROFILE
// ============================================================
//
// Flutter käyttää tätä Referral-näkymän yläosaan.
//
// ============================================================

const getReferralProfile =
  onCall(
    {
      region: "us-central1",
    },
    async (request) => {
      try {
        if (!request.auth) {
          throw new HttpsError(
            "unauthenticated",
            "🐱 Kirjaudu sisään nähdäksesi referral-tietosi."
          );
        }

        const uid =
          request.auth.uid;

        const code =
          await ensureReferralCode(
            uid
          );

        const snapshot =
          await getUserRef(uid)
            .get();

        const data =
          snapshot.exists
            ? snapshot.data() || {}
            : {};

        const totalEarned =
          nonNegative(
            data.referralTotalEarned
          );

        return {
          success: true,

          referralCode:
            code,

          referralBonusPercent:
            referralBonusPercent(),

          referralActiveDays:
            referralActiveDays(),

          totalReferralRewards:
            totalEarned,

          message:
            "🐱🔗 Stella Referral on valmis.",
        };
      } catch (error) {
        console.error(
          "getReferralProfile error:",
          error
        );

        if (
          error instanceof HttpsError
        ) {
          throw error;
        }

        throw new HttpsError(
          "internal",
          "🐱 Referral-tietojen lataaminen epäonnistui."
        );
      }
    }
  );

// ============================================================
// APPLY REFERRAL CODE
// ============================================================
//
// Käyttäjä voi käyttää referral-koodin vain kerran.
//
// Referral-koodia ei voi käyttää:
// - omaan käyttäjään
// - uudelleen
// - tyhjään arvoon
//
// ============================================================

const applyReferralCode =
  onCall(
    {
      region: "us-central1",
    },
    async (request) => {
      try {
        if (!request.auth) {
          throw new HttpsError(
            "unauthenticated",
            "🐱 Kirjaudu sisään käyttääksesi referral-koodia."
          );
        }

        const uid =
          request.auth.uid;

        const code =
          normalizeReferralCode(
            request.data?.referralCode
          );

        if (!code) {
          throw new HttpsError(
            "invalid-argument",
            "🐱 Referral-koodi puuttuu."
          );
        }

        if (
          code.length <
            4
        ) {
          throw new HttpsError(
            "invalid-argument",
            "🐱 Referral-koodi on liian lyhyt."
          );
        }

        const userRef =
          getUserRef(uid);

        return await db.runTransaction(
          async (transaction) => {
            const userSnapshot =
              await transaction.get(
                userRef
              );

            const userData =
              userSnapshot.exists
                ? userSnapshot.data() || {}
                : {};

            const alreadyReferred =
              typeof userData.referrerUid ===
                "string" &&
              userData.referrerUid.trim();

            if (
              alreadyReferred
            ) {
              throw new HttpsError(
                "already-exists",
                "🐱 Referral-koodi on jo liitetty tähän käyttäjään."
              );
            }

            const ownCode =
              normalizeReferralCode(
                userData.referralCode
              );

            if (
              ownCode &&
              ownCode === code
            ) {
              throw new HttpsError(
                "invalid-argument",
                "🐱 Et voi käyttää omaa referral-koodiasi."
              );
            }

            const referrer =
              await findUserByReferralCode(
                code,
                transaction
              );

            if (
              !referrer
            ) {
              throw new HttpsError(
                "not-found",
                "🐱 Referral-koodia ei löytynyt."
              );
            }

            if (
              referrer.uid === uid
            ) {
              throw new HttpsError(
                "invalid-argument",
                "🐱 Et voi käyttää omaa referral-koodiasi."
              );
            }

            transaction.set(
              userRef,
              {
                referrerUid:
                  referrer.uid,

                referralCodeUsed:
                  code,

                referralJoinedAt:
                  FieldValue.serverTimestamp(),

                updatedAt:
                  FieldValue.serverTimestamp(),
              },
              {
                merge: true,
              }
            );

            transaction.set(
              referrer.ref,
              {
                referralCount:
                  FieldValue.increment(
                    1
                  ),

                updatedAt:
                  FieldValue.serverTimestamp(),
              },
              {
                merge: true,
              }
            );

            transaction.set(
              getHistoryCollection(uid)
                .doc(),
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
              }
            );

            return {
              success: true,

              applied: true,

              referralCode:
                code,

              referrerUid:
                referrer.uid,

              referrerName:
                safeDisplayName(
                  referrer.data,
                  referrer.uid
                ),

              message:
                "🐱✨ Referral-koodi liitettiin onnistuneesti!",
            };
          }
        );
      } catch (error) {
        console.error(
          "applyReferralCode error:",
          error
        );

        if (
          error instanceof HttpsError
        ) {
          throw error;
        }

        throw new HttpsError(
          "internal",
          "🐱 Referral-koodin käyttäminen epäonnistui."
        );
      }
    }
  );

// ============================================================
// GET REFERRED USERS
// ============================================================
//
// Tämä on tulevan Flutter Referral UI:n tärkein endpoint.
//
// Palauttaa:
// - kaikki kutsutut käyttäjät
// - aktiiviset
// - ei aktiiviset
// - mining-tilan
// - viimeisimmän aktiivisuuden
// - kutsutun käyttäjän kautta saadut referral-bonukset
//
// Sähköpostiosoitetta EI palauteta.
//
// ============================================================

const getReferredUsers =
  onCall(
    {
      region: "us-central1",
      timeoutSeconds: 120,
    },
    async (request) => {
      try {
        if (!request.auth) {
          throw new HttpsError(
            "unauthenticated",
            "🐱 Kirjaudu sisään nähdäksesi kutsutut käyttäjät."
          );
        }

        const uid =
          request.auth.uid;

        const now =
          new Date();

        const nowMs =
          now.getTime();

        const today =
          getUtcDateString(now);

        const ownSnapshot =
          await getUserRef(uid)
            .get();

        const ownData =
          ownSnapshot.exists
            ? ownSnapshot.data() || {}
            : {};

        const referralCode =
          await ensureReferralCode(
            uid
          );

        // ------------------------------------------------------
        // FIND USERS
        // ------------------------------------------------------

        const referredQuery =
          db.collection("users")
            .where(
              "referrerUid",
              "==",
              uid
            )
            .limit(
              MAX_REFERRAL_LIST
            );

        const referredSnapshot =
          await referredQuery.get();

        const users = [];

        let activeCount = 0;

        let inactiveCount = 0;

        let totalReferralRewards =
          nonNegative(
            ownData.referralTotalEarned
          );

        // ------------------------------------------------------
        // READ EACH REFERRED USER
        // ------------------------------------------------------

        for (
          const document
          of referredSnapshot.docs
        ) {
          const referredUid =
            document.id;

          const data =
            document.data() || {};

          const active =
            isReferralUserActive(
              data,
              nowMs
            );

          const miningActive =
            miningWindowActive(
              data,
              nowMs
            );

          const lastActivity =
            lastActivityMs(data);

          if (active) {
            activeCount++;
          } else {
            inactiveCount++;
          }

          // ----------------------------------------------------
          // REFERRAL BONUS FOR THIS USER
          // ----------------------------------------------------

          let userReferralBonus = 0;

          try {
            const historyQuery =
              getHistoryCollection(
                uid
              )
                .where(
                  "referredUid",
                  "==",
                  referredUid
                )
                .where(
                  "type",
                  "==",
                  "referral_reward"
                );

            const historySnapshot =
              await historyQuery.get();

            historySnapshot.forEach(
              (historyDocument) => {
                const historyData =
                  historyDocument.data() ||
                  {};

                userReferralBonus +=
                  nonNegative(
                    historyData.amount
                  );
              }
            );
          } catch (historyError) {
            console.error(
              "Referral history read error:",
              historyError
            );
          }

          totalReferralRewards +=
            0;

          users.push({
            uid:
              referredUid,

            displayName:
              safeDisplayName(
                data,
                referredUid
              ),

            active,

            miningActive,

            lastActivityAt:
              lastActivity > 0
                ? new Date(
                    lastActivity
                  ).toISOString()
                : null,

            referralJoinedAt:
              timestampMs(
                data.referralJoinedAt
              ) > 0
                ? new Date(
                    timestampMs(
                      data.referralJoinedAt
                    )
                  ).toISOString()
                : null,

            referralBonusEarned:
              Math.max(
                0,
                userReferralBonus
              ),
          });
        }

        // ------------------------------------------------------
        // SORTING
        // ------------------------------------------------------
        //
        // Aktiiviset ensin.
        // Sen jälkeen viimeksi aktiiviset.
        //
        // ------------------------------------------------------

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

            const aTime =
              timestampMs(
                a.lastActivityAt
              );

            const bTime =
              timestampMs(
                b.lastActivityAt
              );

            return (
              bTime -
              aTime
            );
          }
        );

        // ------------------------------------------------------
        // PROFILE
        // ------------------------------------------------------

        return {
          success: true,

          referralCode,

          referralBonusPercent:
            referralBonusPercent(),

          referralActiveDays:
            referralActiveDays(),

          invitedCount:
            users.length,

          activeCount,

          inactiveCount,

          totalReferralRewards,

          generatedAt:
            now.toISOString(),

          utcDate:
            today,

          users,
        };
      } catch (error) {
        console.error(
          "getReferredUsers error:",
          error
        );

        if (
          error instanceof HttpsError
        ) {
          throw error;
        }

        throw new HttpsError(
          "internal",
          "🐱 Kutsuttujen käyttäjien lataaminen epäonnistui."
        );
      }
    }
  );

// ============================================================
// GET FULL REFERRAL DASHBOARD
// ============================================================
//
// Flutter voi käyttää tätä myöhemmin yhtenä kutsuna.
//
// ============================================================

const getReferralDashboard =
  onCall(
    {
      region: "us-central1",
      timeoutSeconds: 120,
    },
    async (request) => {
      try {
        if (!request.auth) {
          throw new HttpsError(
            "unauthenticated",
            "🐱 Kirjaudu sisään nähdäksesi Stella Referralin."
          );
        }

        const uid =
          request.auth.uid;

        const code =
          await ensureReferralCode(
            uid
          );

        const now =
          new Date();

        const nowMs =
          now.getTime();

        const userSnapshot =
          await getUserRef(uid)
            .get();

        const userData =
          userSnapshot.exists
            ? userSnapshot.data() || {}
            : {};

        const referredQuery =
          db.collection("users")
            .where(
              "referrerUid",
              "==",
              uid
            )
            .limit(
              MAX_REFERRAL_LIST
            );

        const referredSnapshot =
          await referredQuery.get();

        const users = [];

        let activeCount = 0;

        let inactiveCount = 0;

        for (
          const document
          of referredSnapshot.docs
        ) {
          const referredUid =
            document.id;

          const data =
            document.data() || {};

          const active =
            isReferralUserActive(
              data,
              nowMs
            );

          const miningActive =
            miningWindowActive(
              data,
              nowMs
            );

          const lastActivity =
            lastActivityMs(data);

          if (active) {
            activeCount++;
          } else {
            inactiveCount++;
          }

          users.push({
            uid:
              referredUid,

            displayName:
              safeDisplayName(
                data,
                referredUid
              ),

            active,

            miningActive,

            lastActivityAt:
              lastActivity > 0
                ? new Date(
                    lastActivity
                  ).toISOString()
                : null,

            referralJoinedAt:
              timestampMs(
                data.referralJoinedAt
              ) > 0
                ? new Date(
                    timestampMs(
                      data.referralJoinedAt
                    )
                  ).toISOString()
                : null,
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
                b.lastActivityAt
              ) -
              timestampMs(
                a.lastActivityAt
              )
            );
          }
        );

        return {
          success: true,

          referralCode:
            code,

          referralBonusPercent:
            referralBonusPercent(),

          referralActiveDays:
            referralActiveDays(),

          invitedCount:
            users.length,

          activeCount,

          inactiveCount,

          totalReferralRewards:
            nonNegative(
              userData.referralTotalEarned
            ),

          users,

          generatedAt:
            now.toISOString(),
        };
      } catch (error) {
        console.error(
          "getReferralDashboard error:",
          error
        );

        if (
          error instanceof HttpsError
        ) {
          throw error;
        }

        throw new HttpsError(
          "internal",
          "🐱 Stella Referral Dashboardin lataaminen epäonnistui."
        );
      }
    }
  );

// ============================================================
// EXPORTS
// ============================================================

module.exports = {
  processReferralMiningReward,

  getReferralProfile,

  applyReferralCode,

  getReferredUsers,

  getReferralDashboard,
};