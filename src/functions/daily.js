"use strict";


// ============================================================
// 🐱 STELLA DAILY FUNCTIONS
// ============================================================
//
// Stella Daily Check-In
//
// 🎁 Päivittäinen Hash Rate -bonus
// 🔥 Streak peräkkäisistä päivistä
// ⚡ Bonus kasvattaa Stella Mining -nopeutta
// 📜 Tapahtuma tallennetaan historiaan
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
  DEFAULT_HASH_RATE,
  DAILY_HASH_RATE_BONUS,
} = require(
  "../config/miningConfig"
);


// ============================================================
// 📅 DATE UTILITIES
// ============================================================

const {
  getUtcDateString,
  getYesterdayUtcDateString,
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
// 🧮 SAFE NUMBER
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
// 🐱 DAILY CHECK-IN
// ============================================================

const dailyCheckIn =
  onCall(async (request) => {

    // ========================================================
    // 🔐 AUTHENTICATION
    // ========================================================

    if (!request.auth) {

      throw new HttpsError(
        "unauthenticated",
        "🐱 Kirjaudu sisään saadaksesi Stella Daily Bonuksen."
      );

    }


    // ========================================================
    // 👤 USER
    // ========================================================

    const uid =
      request.auth.uid;


    const userRef =
      getUserRef(uid);


    // ========================================================
    // 📅 DATES
    // ========================================================

    const today =
      getUtcDateString();


    const yesterday =
      getYesterdayUtcDateString();


    // ========================================================
    // 🔥 FIRESTORE TRANSACTION
    // ========================================================

    return await db.runTransaction(
      async (transaction) => {


        // ====================================================
        // 👤 GET USER DATA
        // ====================================================

        const snapshot =
          await transaction.get(
            userRef
          );


        const data =
          snapshot.exists
            ? snapshot.data()
            : {};


        // ====================================================
        // ⚡ CURRENT HASH RATE
        // ====================================================

        const oldHashRate =
          Math.max(
            0,
            getSafeNumber(
              data.hashRate,
              DEFAULT_HASH_RATE
            )
          );


        // ====================================================
        // 🔥 CURRENT STREAK
        // ====================================================

        const oldStreak =
          Math.max(
            0,
            Math.floor(
              getSafeNumber(
                data.streak,
                0
              )
            )
          );


        // ====================================================
        // 📅 LAST DAILY CLAIM
        // ====================================================

        const lastDailyDate =
          typeof data.lastDailyDate ===
                  "string"
              ? data.lastDailyDate
              : (
                  typeof data.lastDaily ===
                          "string"
                      ? data.lastDaily
                      : ""
                );


        // ====================================================
        // 🐱 ALREADY CLAIMED TODAY
        // ====================================================

        if (lastDailyDate === today) {

          return {

            success:
              true,

            alreadyClaimed:
              true,

            bonus:
              0,

            hashRate:
              oldHashRate,

            streak:
              oldStreak,

            message:
              "🐱🎁 Stella Daily Bonus on jo kerätty tänään!",

          };

        }


        // ====================================================
        // 🔥 CALCULATE NEW STREAK
        // ====================================================

        const newStreak =
          lastDailyDate === yesterday
            ? oldStreak + 1
            : 1;


        // ====================================================
        // 🎁 DAILY BONUS
        // ====================================================

        const bonus =
          Math.max(
            0,
            getSafeNumber(
              DAILY_HASH_RATE_BONUS,
              1
            )
          );


        // ====================================================
        // ⚡ NEW HASH RATE
        // ====================================================

        const newHashRate =
          oldHashRate +
          bonus;


        // ====================================================
        // 💾 UPDATE USER
        // ====================================================

        transaction.set(
          userRef,
          {

            // ⚡ Stella Mining Power

            hashRate:
              newHashRate,


            // 🔥 Daily Streak

            streak:
              newStreak,


            // 📅 Daily Claim

            lastDailyDate:
              today,


            // Yhteensopivuus vanhan datan kanssa.

            lastDaily:
              today,


            // 🎁 Daily Bonus UI

            dailyHashRateBonus:
              bonus,


            // ⏱️ Metadata

            updatedAt:
              FieldValue.serverTimestamp(),

          },
          {
            merge:
              true,
          }
        );


        // ====================================================
        // 📜 STELLA HISTORY
        // ====================================================

        const historyRef =
          getHistoryCollection(uid)
            .doc(
              `daily_${today}`
            );


        transaction.set(
          historyRef,
          {

            type:
              "daily_hashrate",


            title:
              "Stella Daily Bonus 🐱🎁⚡",


            // 🎁 Bonus

            amount:
              bonus,


            // ⚡ New Hash Rate

            hashRateAfter:
              newHashRate,


            // 🔥 Streak

            streak:
              newStreak,


            // 📅 Date

            date:
              today,


            // ⏱️ Timestamp

            createdAt:
              FieldValue.serverTimestamp(),

          }
        );


        // ====================================================
        // 🐱 SUCCESS RESPONSE
        // ====================================================

        return {

          success:
            true,


          alreadyClaimed:
            false,


          // 🎁 Bonus

          bonus,


          // ⚡ New Mining Power

          hashRate:
            newHashRate,


          // 🔥 Streak

          streak:
            newStreak,


          message:
            `🐱🎁 Stella antoi +${bonus} Hash Rate! 🔥 Streak: ${newStreak} päivä${newStreak === 1 ? "" : "ä"}.`,

        };

      }
    );

  });


// ============================================================
// 📦 EXPORTS
// ============================================================

module.exports = {

  dailyCheckIn,

};