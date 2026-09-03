"use strict";

const {
  onCall,
  HttpsError,
} = require("firebase-functions/v2/https");

const {
  db,
  FieldValue,
} = require("../firebase/firebase");

const {
  DEFAULT_HASH_RATE,
  DAILY_HASH_RATE_BONUS,
} = require("../config/miningConfig");

const {
  getUtcDateString,
  getYesterdayUtcDateString,
} = require("../utils/dateUtils");

const {
  getUserRef,
  getHistoryCollection,
} = require("../utils/userUtils");


// ============================================================
// 🐱 STELLA DAILY FUNCTIONS
// ============================================================
//
// Stella Daily Check-In
//
// 🎁 Päivittäinen Hash Rate -bonus
// 🔥 Streak peräkkäisistä päivistä
// ⚡ Bonus kasvattaa Stella Mining -nopeutta
//
// ============================================================


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


    const uid =
      request.auth.uid;


    const userRef =
      getUserRef(uid);


    // ========================================================
    // 📅 CURRENT DATES
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
        // 📅 LAST DAILY CHECK-IN
        // ====================================================

        const lastDaily =
          String(
            data.lastDaily || ""
          );


        // ====================================================
        // 🐱 CHECK IF ALREADY CLAIMED TODAY
        // ====================================================

        if (lastDaily === today) {

          return {

            success: true,

            alreadyClaimed: true,

            bonus: 0,

            hashRate:
              oldHashRate,

            streak:
              oldStreak,

            message:
              "🐱🎁 Stella Daily Bonus on jo kerätty tänään!",

          };
        }


        // ====================================================
        // 🔥 CALCULATE STREAK
        // ====================================================
        //
        // Jos käyttäjä kävi myös eilen:
        //
        // 🔥 streak +1
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
        // 🎁 STELLA DAILY BONUS
        // ====================================================

        const bonus =
          DAILY_HASH_RATE_BONUS;


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


            // 🔥 Daily streak
            streak:
              newStreak,


            // 📅 Today's claim date
            lastDaily:
              today,


            // ⏱️ Last update
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
          getHistoryCollection(uid)
            .doc(`daily_${today}`);


        transaction.set(
          historyRef,
          {

            type:
              "daily_hashrate",


            title:
              "Stella Daily Bonus 🐱🎁⚡",


            // Hash Rate bonus
            amount:
              bonus,


            // New total Hash Rate
            hashRateAfter:
              newHashRate,


            // Current streak
            streak:
              newStreak,


            // Server timestamp
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


          // 🎁 Bonus received
          bonus,


          // ⚡ New mining power
          hashRate:
            newHashRate,


          // 🔥 Current streak
          streak:
            newStreak,


          message:
            `🐱🎁 Stella toi sinulle +${bonus} Hash Rate! 🔥 Streak: ${newStreak} päivä${newStreak === 1 ? "" : "ä"}.`,

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