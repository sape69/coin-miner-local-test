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

        if (
          lastDaily === today
        ) {

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

            // ⚡ Hash Rate

            hashRate:
              newHashRate,


            // 🔥 Streak

            streak:
              newStreak,


            // 🗓️ Daily claim date

            lastDaily:
              today,


            // ⏱️ Updated

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
            .doc();


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
            // DATE
            // ------------------------------------------------

            date:
              today,


            // ------------------------------------------------
            // TIME
            // ------------------------------------------------

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