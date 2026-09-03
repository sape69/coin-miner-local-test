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
//
// Käyttäjä voi saada kerran päivässä:
//
// ⚡ +1 Hash Rate
// 🔥 Streak kasvaa
//
// Stella-teema säilyy koko järjestelmässä 🐱✨
//
// ============================================================

const dailyCheckIn =
  onCall(async (request) => {

    // ========================================================
    // 🔐 AUTHENTICATION
    // ========================================================

    if (!request.auth) {

      throw new HttpsError(
        "unauthenticated",
        "Kirjaudu sisään jatkaaksesi."
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
            data.hashRate ||
            DEFAULT_HASH_RATE
          );


        // ====================================================
        // 🔥 CURRENT STREAK
        // ====================================================

        const oldStreak =
          Number(
            data.streak || 0
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

        if (
          lastDaily === today
        ) {

          return {

            success:
              true,

            alreadyClaimed:
              true,

            hashRate:
              oldHashRate,

            streak:
              oldStreak,

            bonus:
              0,

            message:
              "🐱🎁 Stella on jo antanut tämän päivän bonuksen!",

          };

        }


        // ====================================================
        // 🔥 CALCULATE NEW STREAK
        // ====================================================
        //
        // Jos käyttäjä kävi eilen:
        //
        // 🔥 streak + 1
        //
        // Muuten:
        //
        // 🐱 uusi streak alkaa numerosta 1
        //
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

            // ------------------------------------------------
            // ⚡ HASH RATE
            // ------------------------------------------------

            hashRate:
              newHashRate,


            // ------------------------------------------------
            // 🔥 STREAK
            // ------------------------------------------------

            streak:
              newStreak,


            // ------------------------------------------------
            // 🗓️ DAILY DATE
            // ------------------------------------------------

            lastDaily:
              today,


            // ------------------------------------------------
            // 🕒 UPDATED
            // ------------------------------------------------

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

            // ------------------------------------------------
            // TYPE
            // ------------------------------------------------

            type:
              "daily_hashrate",


            // ------------------------------------------------
            // TITLE
            // ------------------------------------------------

            title:
              "Stella Daily Bonus 🐱🎁⚡",


            // ------------------------------------------------
            // BONUS
            // ------------------------------------------------

            amount:
              bonus,


            // ------------------------------------------------
            // HASH RATE
            // ------------------------------------------------

            hashRateAfter:
              newHashRate,


            // ------------------------------------------------
            // STREAK
            // ------------------------------------------------

            streak:
              newStreak,


            // ------------------------------------------------
            // TIME
            // ------------------------------------------------

            createdAt:
              FieldValue.serverTimestamp(),

          }
        );


        // ====================================================
        // 🐱 RESPONSE
        // ====================================================

        return {

          success:
            true,

          alreadyClaimed:
            false,


          // --------------------------------------------------
          // ⚡ BONUS
          // --------------------------------------------------

          bonus,


          // --------------------------------------------------
          // ⚡ NEW HASH RATE
          // --------------------------------------------------

          hashRate:
            newHashRate,


          // --------------------------------------------------
          // 🔥 NEW STREAK
          // --------------------------------------------------

          streak:
            newStreak,


          // --------------------------------------------------
          // 🐱 STELLA MESSAGE
          // --------------------------------------------------

          message:
            `🐱🎁 Stella antoi +${bonus} Hash Rate! 🔥 ${newStreak} päivän streak!`,

        };

      }
    );

  });


// ============================================================
// EXPORTS
// ============================================================

module.exports = {

  dailyCheckIn,

};