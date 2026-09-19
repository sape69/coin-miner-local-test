"use strict";

// ============================================================
// 🐱 STELLURIINI DAILY FUNCTIONS
// ============================================================
//
// Stella Daily Hash Rate
//
// TÄRKEÄÄ:
//
// 🎁 Daily Check-In EI anna suoraa STL-tokenipalkkiota.
// ⛏️ Daily Check-In kasvattaa käyttäjän Daily Hash Ratea.
// 🐱 Hash Rate vaikuttaa myöhempään Stella Mining -tuottoon.
//
// Firestore:
//
// users/{uid}
//
// Historia:
//
// users/{uid}/transactions
//
// ============================================================


// ============================================================
// 🔥 FIREBASE FUNCTIONS
// ============================================================

const {
  onCall,
  HttpsError,
} = require(
  "firebase-functions/v2/https"
);


// ============================================================
// 🔥 FIREBASE
// ============================================================

const {
  db,
  FieldValue,
} = require(
  "../firebase/firebase"
);


// ============================================================
// ⚙️ MINING CONFIG
// ============================================================

const {
  DAILY_HASH_RATE_START,
  DAILY_HASH_RATE_STEP,
  DAILY_HASH_RATE_MAX_DAY,
  MAX_DAILY_HASH_RATE,
} = require(
  "../config/miningConfig"
);


// ============================================================
// 📅 DATE UTILITIES
// ============================================================

const {
  getUtcDateString,
} = require(
  "../utils/dateUtils"
);


// ============================================================
// 👤 USER UTILITIES
// ============================================================

const {
  getUserRef,
  getHistoryCollection,
} = require(
  "../utils/userUtils"
);


// ============================================================
// 🔢 SAFE NUMBER
// ============================================================

function getSafeNumber(
  value,
  fallback = 0
) {
  const number =
    Number(value);

  return Number.isFinite(number)
    ? number
    : fallback;
}


// ============================================================
// 🎁 CALCULATE DAILY HASH RATE
// ============================================================
//
// Päivä 1:
// 0.5 HR
//
// Päivä 2:
// 1.0 HR
//
// ...
//
// Päivä 7:
// 3.5 HR
//
// Päivä 8+:
// 3.5 HR
//
// ============================================================

function calculateDailyHashRate(
  streak
) {
  const safeStreak =
    Math.max(
      1,
      Math.floor(
        getSafeNumber(
          streak,
          1
        )
      )
    );

  const effectiveDay =
    Math.min(
      safeStreak,
      DAILY_HASH_RATE_MAX_DAY
    );

  const hashRate =
    DAILY_HASH_RATE_START +
    (
      (effectiveDay - 1) *
      DAILY_HASH_RATE_STEP
    );

  return Math.min(
    MAX_DAILY_HASH_RATE,
    Math.max(
      DAILY_HASH_RATE_START,
      hashRate
    )
  );
}


// ============================================================
// 📅 GET PREVIOUS UTC DATE
// ============================================================

function getPreviousUtcDate(
  dateString
) {
  const date =
    new Date(
      `${dateString}T00:00:00.000Z`
    );

  if (
    Number.isNaN(
      date.getTime()
    )
  ) {
    return "";
  }

  date.setUTCDate(
    date.getUTCDate() - 1
  );

  return date
    .toISOString()
    .slice(
      0,
      10
    );
}


// ============================================================
// 🎁 CALCULATE DAILY CHECK-IN
// ============================================================

function calculateDailyCheckIn(
  data,
  today
) {
  const lastDailyDate =
    typeof data.lastDailyDate === "string"
      ? data.lastDailyDate
      : "";

  const storedStreak =
    Math.max(
      0,
      Math.floor(
        getSafeNumber(
          data.dailyStreak ??
          data.streak,
          0
        )
      )
    );

  // ----------------------------------------------------------
  // Already claimed today
  // ----------------------------------------------------------

  if (
    lastDailyDate === today
  ) {
    const streak =
      Math.max(
        1,
        storedStreak
      );

    return {
      alreadyClaimed:
        true,

      streak,

      dailyHashRate:
        calculateDailyHashRate(
          streak
        ),
    };
  }

  // ----------------------------------------------------------
  // Consecutive day
  // ----------------------------------------------------------

  const yesterday =
    getPreviousUtcDate(
      today
    );

  let streak = 1;

  if (
    lastDailyDate === yesterday &&
    storedStreak > 0
  ) {
    streak =
      storedStreak + 1;
  }

  const dailyHashRate =
    calculateDailyHashRate(
      streak
    );

  return {
    alreadyClaimed:
      false,

    streak,

    dailyHashRate,
  };
}


// ============================================================
// 🎁 DAILY CHECK-IN
// ============================================================

const dailyCheckIn =
  onCall(
    {
      region:
        "us-central1",
    },

    async (
      request
    ) => {
      try {
        // ======================================================
        // 🔐 AUTHENTICATION
        // ======================================================

        if (!request.auth) {
          throw new HttpsError(
            "unauthenticated",
            "🐱 Kirjaudu sisään käyttääksesi Stella Daily Check-Iniä."
          );
        }

        const uid =
          request.auth.uid;

        const userRef =
          getUserRef(
            uid
          );

        const today =
          getUtcDateString();

        // ======================================================
        // 🔐 FIRESTORE TRANSACTION
        // ======================================================

        return await db.runTransaction(
          async (
            transaction
          ) => {
            const snapshot =
              await transaction.get(
                userRef
              );

            const data =
              snapshot.exists
                ? snapshot.data() || {}
                : {};

            // ==================================================
            // 🎁 DAILY CHECK-IN STATUS
            // ==================================================

            const daily =
              calculateDailyCheckIn(
                data,
                today
              );

            // ==================================================
            // 🚫 ALREADY CLAIMED
            // ==================================================

            if (
              daily.alreadyClaimed
            ) {
              return {
                success:
                  true,

                claimed:
                  false,

                alreadyClaimed:
                  true,

                dailyClaimed:
                  true,

                streak:
                  daily.streak,

                dailyStreak:
                  daily.streak,

                dailyHashRate:
                  daily.dailyHashRate,

                hashRate:
                  daily.dailyHashRate,

                message:
                  "🐱✨ Stella on jo saanut tämän päivän Daily Hash Raten.",
              };
            }

            // ==================================================
            // 📊 OLD HASH RATE
            // ==================================================

            const oldHashRate =
              Math.max(
                0,
                getSafeNumber(
                  data.hashRate,
                  0
                )
              );

            // ==================================================
            // 👤 USER UPDATE
            // ==================================================

            transaction.set(
              userRef,
              {
                hashRate:
                  daily.dailyHashRate,

                dailyHashRate:
                  daily.dailyHashRate,

                dailyStreak:
                  daily.streak,

                streak:
                  daily.streak,

                lastDailyDate:
                  today,

                updatedAt:
                  FieldValue.serverTimestamp(),
              },
              {
                merge: true,
              }
            );

            // ==================================================
            // 📜 HISTORY
            // ==================================================

            const historyRef =
              getHistoryCollection(
                uid
              ).doc();

            transaction.set(
              historyRef,
              {
                type:
                  "dailyHashRate",

                title:
                  "Stella Daily Hash Rate 🐱✨",

                amount:
                  0,

                hashRate:
                  daily.dailyHashRate,

                dailyHashRate:
                  daily.dailyHashRate,

                hashRateBefore:
                  oldHashRate,

                hashRateAfter:
                  daily.dailyHashRate,

                dailyStreak:
                  daily.streak,

                streak:
                  daily.streak,

                createdAt:
                  FieldValue.serverTimestamp(),
              }
            );

            // ==================================================
            // ✅ RESPONSE
            // ==================================================

            return {
              success:
                true,

              claimed:
                true,

              alreadyClaimed:
                false,

              dailyClaimed:
                true,

              streak:
                daily.streak,

              dailyStreak:
                daily.streak,

              dailyHashRate:
                daily.dailyHashRate,

              hashRate:
                daily.dailyHashRate,

              previousHashRate:
                oldHashRate,

              hashRateIncrease:
                Math.max(
                  0,
                  daily.dailyHashRate -
                    oldHashRate
                ),

              message:
                `🐱✨ Stella sai päivän ${daily.streak} Daily Hash Raten: ${daily.dailyHashRate.toFixed(4)} HR!`,
            };
          }
        );
      } catch (
        error
      ) {
        console.error(
          "dailyCheckIn error:",
          error
        );

        if (
          error instanceof HttpsError
        ) {
          throw error;
        }

        throw new HttpsError(
          "internal",
          "🐱 Stella Daily Check-Inin käsittely epäonnistui."
        );
      }
    }
  );


// ============================================================
// 📦 EXPORTS
// ============================================================

module.exports = {
  dailyCheckIn,
};