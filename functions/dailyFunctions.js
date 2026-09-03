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
// Stella Daily Check-In:
//
// 🎁 Pelaaja saa päivittäisen Hash Rate -bonuksen
// 🔥 Streak kasvaa peräkkäisistä päivistä
// ⚡ Bonus kasvattaa Stella Mining -nopeutta
//
// ============================================================


// ============================================================
// 🐱 DAILY CHECK-IN
// ============================================================

const dailyCheckIn =
  onCall(async (request) => {

    // ========================================================
    // AUTHENTICATION
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
    // DATES
    // ========================================================

    const today =
      getUtcDateString();

    const yesterday =
      getYesterdayUtcDateString();


    // ========================================================
    // FIRESTORE TRANSACTION
    // ========================================================

    return await db.runTransaction(
      async (transaction) => {

        // ====================================================
        // GET USER
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
        // CURRENT HASH RATE
        // ====================================================

        const oldHashRate =
          Number(
            data.hashRate ||
            DEFAULT_HASH_RATE
          );


        // ====================================================
        // CURRENT STREAK
        // ====================================================

        const oldStreak =
          Number(
            data.streak || 0
          );


        // ====================================================
        // LAST DAILY
        // ====================================================

        const lastDaily =
          String(
            data.lastDaily || ""
          );


        // ====================================================
        // ALREADY CLAIMED
        // ====================================================

        if (lastDaily === today) {

          return {

            success: true,

            alreadyClaimed: true,

            hashRate:
              oldHashRate,

            streak:
              oldStreak,

            bonus: 0,

            message:
              "🐱🎁 Stella Daily Bonus on jo kerätty tänään!",
          };
        }


        // ====================================================
        // CALCULATE STREAK
        // ====================================================

        const newStreak =
          lastDaily === yesterday
            ? oldStreak + 1
            : 1;


        // ====================================================
        // DAILY BONUS
        // ====================================================

        const bonus =
          DAILY_HASH_RATE_BONUS;

        const newHashRate =
          oldHashRate +
          bonus;


        // ====================================================
        // UPDATE USER
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
        // HISTORY
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

            amount:
              bonus,

            hashRateAfter:
              newHashRate,

            streak:
              newStreak,

            createdAt:
              FieldValue.serverTimestamp(),

          }
        );


        // ====================================================
        // RESPONSE
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
            `🐱🎁 Stella toi sinulle +${bonus} Hash Rate!`,

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