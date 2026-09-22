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
// ⛏️ Daily Check-In määrittää käyttäjän seuraavan mining-jakson
//    Daily Hash Raten.
// 🐱 Daily Hash Rate toimii uuden mining-jakson peruslouhintatehona.
//
// Daily Check-In EI:
//
// ❌ lisää STL-saldoa
// ❌ käynnistä Mining Startia
// ❌ aktivoi Power Boostia
// ❌ muuta aktiivisen mining-jakson Hash Ratea
// ❌ käsittele AdMob SSV:tä
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
  "firebase-functions/v2/https",
);


// ============================================================
// 🔥 FIREBASE
// ============================================================

const {
  db,
  FieldValue,
} = require(
  "../firebase/firebase",
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
  "../config/miningConfig",
);


// ============================================================
// 📅 DATE UTILITIES
// ============================================================

const {
  getUtcDateString,
} = require(
  "../utils/dateUtils",
);


// ============================================================
// 👤 USER UTILITIES
// ============================================================

const {
  getUserRef,
  getHistoryCollection,
} = require(
  "../utils/userUtils",
);


// ============================================================
// 🔢 SAFE NUMBER
// ============================================================

function getSafeNumber(
  value,
  fallback = 0,
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
// DAILY_HASH_RATE_START
//
// Jokainen seuraava päivä:
// + DAILY_HASH_RATE_STEP
//
// Maksimipäivä:
// DAILY_HASH_RATE_MAX_DAY
//
// Lopullinen maksimi:
// MAX_DAILY_HASH_RATE
//
// ============================================================

function calculateDailyHashRate(
  streak,
) {
  const safeStreak =
    Math.max(
      1,
      Math.floor(
        getSafeNumber(
          streak,
          1,
        ),
      ),
    );

  const effectiveDay =
    Math.min(
      safeStreak,
      DAILY_HASH_RATE_MAX_DAY,
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
      hashRate,
    ),
  );
}


// ============================================================
// 📅 GET PREVIOUS UTC DATE
// ============================================================

function getPreviousUtcDate(
  dateString,
) {
  if (
    typeof dateString !==
    "string" ||
    !/^\d{4}-\d{2}-\d{2}$/.test(
      dateString,
    )
  ) {
    return "";
  }

  const date =
    new Date(
      `${dateString}T00:00:00.000Z`,
    );

  if (
    Number.isNaN(
      date.getTime(),
    )
  ) {
    return "";
  }

  date.setUTCDate(
    date.getUTCDate() - 1,
  );

  return date
    .toISOString()
    .slice(
      0,
      10,
    );
}


// ============================================================
// 🎁 GET STORED DAILY STREAK
// ============================================================

function getStoredDailyStreak(
  data,
) {
  const stored =
    data.dailyStreak ??
    data.streak ??
    0;

  return Math.max(
    0,
    Math.floor(
      getSafeNumber(
        stored,
        0,
      ),
    ),
  );
}


// ============================================================
// 🎁 CALCULATE DAILY CHECK-IN
// ============================================================

function calculateDailyCheckIn(
  data,
  today,
) {
  const lastDailyDate =
    typeof data.lastDailyDate ===
      "string"
      ? data.lastDailyDate
      : "";

  const storedStreak =
    getStoredDailyStreak(
      data,
    );


  // ==========================================================
  // 🚫 ALREADY CLAIMED TODAY
  // ==========================================================

  if (
    lastDailyDate === today
  ) {
    const streak =
      Math.max(
        1,
        storedStreak,
      );

    return {
      alreadyClaimed:
        true,

      streak,

      dailyHashRate:
        calculateDailyHashRate(
          streak,
        ),
    };
  }


  // ==========================================================
  // 📅 CONSECUTIVE DAY
  // ==========================================================

  const yesterday =
    getPreviousUtcDate(
      today,
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
      streak,
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
      request,
    ) => {
      try {
        // ======================================================
        // 🔐 AUTHENTICATION
        // ======================================================

        if (
          !request.auth
        ) {
          throw new HttpsError(
            "unauthenticated",
            "🐱 Kirjaudu sisään käyttääksesi Stella Daily Check-Iniä.",
          );
        }


        const uid =
          request.auth.uid;


        const userRef =
          getUserRef(
            uid,
          );


        // ======================================================
        // 📅 CURRENT UTC DATE
        // ======================================================
        //
        // Käytetään samaa eksplisiittistä Date-arvoa kuin
        // muualla mining-backendissä.
        //
        // ======================================================

        const now =
          new Date();

        const today =
          getUtcDateString(
            now,
          );


        if (
          typeof today !==
            "string" ||
          !/^\d{4}-\d{2}-\d{2}$/.test(
            today,
          )
        ) {
          throw new HttpsError(
            "internal",
            "🐱 Päivämäärän määrittäminen epäonnistui.",
          );
        }


        // ======================================================
        // 🔐 FIRESTORE TRANSACTION
        // ======================================================

        return await db.runTransaction(
          async (
            transaction,
          ) => {
            const snapshot =
              await transaction.get(
                userRef,
              );


            const data =
              snapshot.exists
                ? snapshot.data() || {}
                : {};


            // ==================================================
            // 🎁 CALCULATE DAILY STATE
            // ==================================================

            const daily =
              calculateDailyCheckIn(
                data,
                today,
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

                // ------------------------------------------------
                // Compatibility field.
                //
                // Tämä ei tarkoita aktiivisen mining-jakson
                // Hash Ratea.
                //
                // Aktiivinen mining-jakso käyttää omaa
                // miningHashRate-arvoaan.
                // ------------------------------------------------

                hashRate:
                  daily.dailyHashRate,

                message:
                  "🐱✨ Stella on jo saanut tämän päivän Daily Hash Raten.",
              };
            }


            // ==================================================
            // 📊 PREVIOUS DAILY HASH RATE
            // ==================================================

            const oldDailyHashRate =
              Math.max(
                0,
                getSafeNumber(
                  data.dailyHashRate,
                  0,
                ),
              );


            // ==================================================
            // 👤 USER UPDATE
            // ==================================================
            //
            // Daily Check-In muuttaa vain Daily Hash Rateen
            // ja streakiin liittyviä kenttiä.
            //
            // Se EI muuta:
            //
            // - miningStartedAt
            // - miningEndsAt
            // - miningHashRate
            // - miningBalance
            // - adBoostStartedAt
            // - adBoostEndsAt
            //
            // Näin aktiivinen mining-sykli säilyttää oman
            // Hash Ratensa loppuun asti.
            //
            // ==================================================

            transaction.set(
              userRef,
              {
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
                merge:
                  true,
              },
            );


            // ==================================================
            // 📜 HISTORY
            // ==================================================

            const historyRef =
              getHistoryCollection(
                uid,
              ).doc();


            transaction.set(
              historyRef,
              {
                type:
                  "dailyHashRate",

                title:
                  "Stella Daily Hash Rate 🐱✨",

                // Daily Hash Rate ei ole STL-palkkio.

                amount:
                  0,

                hashRate:
                  daily.dailyHashRate,

                dailyHashRate:
                  daily.dailyHashRate,

                hashRateBefore:
                  oldDailyHashRate,

                hashRateAfter:
                  daily.dailyHashRate,

                dailyHashRateBefore:
                  oldDailyHashRate,

                dailyHashRateAfter:
                  daily.dailyHashRate,

                dailyStreak:
                  daily.streak,

                streak:
                  daily.streak,

                createdAt:
                  FieldValue.serverTimestamp(),
              },
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

              // Compatibility field.
              //
              // Tämä on Daily Hash Rate eikä aktiivisen
              // mining-jakson Hash Rate.
              hashRate:
                daily.dailyHashRate,

              previousHashRate:
                oldDailyHashRate,

              previousDailyHashRate:
                oldDailyHashRate,

              hashRateIncrease:
                Math.max(
                  0,
                  daily.dailyHashRate -
                    oldDailyHashRate,
                ),

              dailyHashRateIncrease:
                Math.max(
                  0,
                  daily.dailyHashRate -
                    oldDailyHashRate,
                ),

              message:
                `🐱✨ Stella sai päivän ${daily.streak} Daily Hash Raten: ${daily.dailyHashRate.toFixed(4)} HR!`,
            };
          },
        );
      } catch (
        error
      ) {
        // ======================================================
        // ❌ ERROR
        // ======================================================

        console.error(
          "dailyCheckIn error:",
          error,
        );


        if (
          error instanceof HttpsError
        ) {
          throw error;
        }


        throw new HttpsError(
          "internal",
          "🐱 Stella Daily Check-Inin käsittely epäonnistui.",
        );
      }
    },
  );


// ============================================================
// 📦 EXPORTS
// ============================================================

module.exports = {
  dailyCheckIn,
};