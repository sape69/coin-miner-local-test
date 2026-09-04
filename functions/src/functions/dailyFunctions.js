"use strict";

// ============================================================
// 🐱 STELLA DAILY FUNCTIONS
// ============================================================
//
// 🎁 Stella Daily Check-In
// 📅 Päivittäinen bonus
// ⚡ Hash Rate -kasvu
// 🛡️ Tuplabonuksen esto
// 📜 Daily-tapahtumahistoria
//
// Kaikki päivät käsitellään UTC-ajassa.
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
// ⚙️ CONFIG
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
} = require(
  "../utils/userUtils"
);


// ============================================================
// 📜 HISTORY SERVICE
// ============================================================

const {
  createDailyHistoryRef,
} = require(
  "../services/historyService"
);


// ============================================================
// 🎁 DAILY CHECK-IN
// ============================================================

const dailyCheckIn =
  onCall(
    {
      region: "us-central1",
    },
    async (request) => {

      // ======================================================
      // 🔐 AUTHENTICATION
      // ======================================================

      if (!request.auth) {

        throw new HttpsError(
          "unauthenticated",
          "🐱 Kirjaudu sisään saadaksesi Daily Bonus -palkinnon."
        );

      }


      const uid =
        request.auth.uid;


      const userRef =
        getUserRef(uid);


      // ======================================================
      // 📅 CURRENT DATE
      // ======================================================

      const today =
        getUtcDateString();


      const yesterday =
        getYesterdayUtcDateString();


      try {

        // ====================================================
        // 🔥 FIRESTORE TRANSACTION
        // ====================================================

        return await db.runTransaction(
          async (transaction) => {

            // ==================================================
            // 👤 GET USER
            // ==================================================

            const snapshot =
              await transaction.get(
                userRef
              );


            const data =
              snapshot.exists
                ? snapshot.data() || {}
                : {};


            // ==================================================
            // 📅 LAST DAILY DATE
            // ==================================================

            const lastDailyDate =
              typeof data.lastDailyDate === "string"
                ? data.lastDailyDate
                : null;


            // ==================================================
            // ⚡ CURRENT HASH RATE
            // ==================================================

            const savedHashRate =
              Number(data.hashRate);


            const currentHashRate =
              Number.isFinite(savedHashRate) &&
                      savedHashRate >= 0
                  ? savedHashRate
                  : DEFAULT_HASH_RATE;


            // ==================================================
            // 🔥 CURRENT STREAK
            // ==================================================

            const savedStreak =
              Number(data.dailyStreak);


            const currentStreak =
              Number.isFinite(savedStreak) &&
                      savedStreak >= 0
                  ? Math.floor(savedStreak)
                  : 0;


            // ==================================================
            // 🛡️ ALREADY CLAIMED TODAY
            // ==================================================

            if (lastDailyDate === today) {

              return {

                success: true,

                claimed: false,

                alreadyClaimed: true,

                dailyClaimed: true,

                date: today,

                bonus: 0,

                hashRate: currentHashRate,

                // Flutter-yhteensopivuus
                streak: currentStreak,

                // Backend-yhteensopivuus
                dailyStreak: currentStreak,

                message:
                  "🐱🎁 Stella Daily Bonus on jo kerätty tänään!",

              };

            }


            // ==================================================
            // 🎁 DAILY BONUS
            // ==================================================

            const configuredBonus =
              Number(DAILY_HASH_RATE_BONUS);


            const bonus =
              Number.isFinite(configuredBonus) &&
                      configuredBonus > 0
                  ? configuredBonus
                  : 1;


            const newHashRate =
              currentHashRate +
              bonus;


            // ==================================================
            // 🔥 DAILY STREAK
            // ==================================================

            const newDailyStreak =
              lastDailyDate === yesterday
                ? currentStreak + 1
                : 1;


            // ==================================================
            // 📜 DAILY HISTORY REFERENCE
            // ==================================================

            const dailyHistoryRef =
              createDailyHistoryRef(
                uid,
                today
              );


            // ==================================================
            // 👤 UPDATE USER
            // ==================================================

            transaction.set(
              userRef,
              {

                // ⚡ HASH RATE

                hashRate:
                  newHashRate,


                // 📅 DAILY

                lastDailyDate:
                  today,


                dailyStreak:
                  newDailyStreak,


                // 🕒 METADATA

                updatedAt:
                  FieldValue.serverTimestamp(),

              },
              {
                merge: true,
              }
            );


            // ==================================================
            // 📜 SAVE DAILY HISTORY
            // ==================================================

            transaction.set(
              dailyHistoryRef,
              {

                type:
                  "dailyCheckIn",


                bonusType:
                  "hashRate",


                bonus:
                  bonus,


                previousHashRate:
                  currentHashRate,


                newHashRate:
                  newHashRate,


                // Flutter + backend compatibility

                streak:
                  newDailyStreak,


                dailyStreak:
                  newDailyStreak,


                date:
                  today,


                uid:
                  uid,


                createdAt:
                  FieldValue.serverTimestamp(),

              },
              {
                merge: true,
              }
            );


            // ==================================================
            // ✅ SUCCESS RESPONSE
            // ==================================================

            return {

              success: true,

              claimed: true,

              alreadyClaimed: false,

              dailyClaimed: true,

              date: today,

              bonus: bonus,

              hashRate: newHashRate,

              // Flutter odottaa tätä
              streak: newDailyStreak,

              // Säilytetään myös tämä
              dailyStreak: newDailyStreak,

              message:
                "🐱🎁 Daily Bonus kerätty! Hash Rate kasvoi.",

            };

          }
        );

      } catch (error) {

        console.error(
          "dailyCheckIn error:",
          error
        );


        if (error instanceof HttpsError) {
          throw error;
        }


        throw new HttpsError(
          "internal",
          "Daily Bonus -palkinnon käsittely epäonnistui."
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