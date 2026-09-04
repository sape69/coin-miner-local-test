"use strict";


// ============================================================
// 🐱 STELLA DAILY BONUS
// ============================================================
//
// Vastaa:
//
// 🎁 Päivittäisestä Stella-bonuksesta
// 🔥 Streak-järjestelmästä
// ⚡ Hash Rate -bonuksesta
// 📜 Bonus-historiasta
//
// ============================================================


// ============================================================
// FIREBASE FUNCTIONS
// ============================================================

const {
  onCall,
  HttpsError,
} = require(
  "firebase-functions/v2/https"
);


// ============================================================
// FIRESTORE
// ============================================================

const {
  FieldValue,
} = require(
  "firebase-admin/firestore"
);


// ============================================================
// FIREBASE
// ============================================================

const {
  db,
  getUserRef,
} = require(
  "../firebase/firebase"
);


// ============================================================
// STELLA CONFIG
// ============================================================

const {
  DEFAULT_HASH_RATE,
  DAILY_HASH_RATE_BONUS,
} = require(
  "../config/miningConfig"
);


// ============================================================
// DATE UTILITIES
// ============================================================

const {
  getUtcDateString,
  getYesterdayUtcDateString,
} = require(
  "../utils/dateUtils"
);


// ============================================================
// HISTORY SERVICE
// ============================================================

const {
  createDailyHistoryRef,
} = require(
  "../services/historyService"
);


// ============================================================
// 🐱 DAILY STELLA CHECK-IN
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
    // 🗓️ DATE
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
          Number(
            data.hashRate ??
            DEFAULT_HASH_RATE
          );


        // ====================================================
        // 🔥 CURRENT STREAK
        // ====================================================

        const oldStreak =
          Number(
            data.streak ?? 0
          );


        // ====================================================
        // 🗓️ LAST DAILY CLAIM
        // ====================================================

        const lastDaily =
          String(
            data.lastDaily || ""
          );


        // ====================================================
        // 🐱 ALREADY CLAIMED TODAY
        // ====================================================

        if (lastDaily === today) {

          return {

            success: true,

            alreadyClaimed: true,

            bonus: 0,

            hashRate: oldHashRate,

            streak: oldStreak,

            message:
              "🐱🎁 Stella on jo antanut tämän päivän bonuksen!",

          };

        }


        // ====================================================
        // 🔥 CALCULATE NEW STREAK
        // ====================================================

        const newStreak =
          lastDaily === yesterday
            ? oldStreak + 1
            : 1;


        // ====================================================
        // ⚡ STELLA DAILY BONUS
        // ====================================================

        const bonus =
          DAILY_HASH_RATE_BONUS;


        const newHashRate =
          oldHashRate +
          bonus;


        // ====================================================
        // 💾 UPDATE USER
        // ====================================================

        transaction.set(
          userRef,
          {

            hashRate:
              newHashRate,

            streak:
              newStreak,

            lastDaily:
              today,

            updatedAt:
              FieldValue.serverTimestamp(),

          },
          {
            merge: true,
          }
        );


        // ====================================================
        // 📜 STELLA HISTORY
        // ====================================================

        const historyRef =
          createDailyHistoryRef(
            uid,
            today
          );


        transaction.set(
          historyRef,
          {

            type:
              "daily_hashrate",

            title:
              "Stella Daily Bonus 🐱🎁⚡",

            amount:
              bonus,

            hashRateAfter:
              newHashRate,

            streak:
              newStreak,

            date:
              today,

            createdAt:
              FieldValue.serverTimestamp(),

          }
        );


        // ====================================================
        // 🐱 SUCCESS RESPONSE
        // ====================================================

        return {

          success: true,

          alreadyClaimed: false,

          bonus,

          hashRate:
            newHashRate,

          streak:
            newStreak,

          message:
            `🐱🎁 Stella antoi +${bonus} Hash Rate! 🔥 ${newStreak} päivän streak!`,

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