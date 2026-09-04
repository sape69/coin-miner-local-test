"use strict";


// ============================================================
// 🐱 STELLA DAILY FUNCTIONS
// ============================================================
//
// Tämä tiedosto hallitsee:
//
// 🎁 Stella Daily Check-In
// ⚡ Päivittäisen Hash Rate -bonuksen
// 🔥 Päivittäisen streakin
// 📅 Päivittäisen claim-rajoituksen
// 📜 Daily Bonus -historian
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
//
// Flutter kutsuu:
//
// dailyCheckIn()
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
        //
        // Käytetään lastDailyDate-kenttää,
        // koska miningFunctions.js käyttää
        // samaa kenttää Daily Status -tilassa.
        //
        // ====================================================

        const lastDailyDate =
          typeof data.lastDailyDate === "string"
            ? data.lastDailyDate
            : "";


        // ====================================================
        // 🐱 ALREADY CLAIMED TODAY
        // ====================================================

        if (
          lastDailyDate === today
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


            dailyClaimed:
              true,


            dailyHashRateBonus:
              DAILY_HASH_RATE_BONUS,


            message:
              "🐱🎁 Stella Daily Bonus on jo kerätty tänään!",

          };

        }


        // ====================================================
        // 🔥 CALCULATE STREAK
        // ====================================================
        //
        // Jos käyttäjä keräsi bonuksen eilen:
        //
        // streak + 1
        //
        // Muuten uusi streak alkaa:
        //
        // 1
        //
        // ====================================================

        const newStreak =
          lastDailyDate === yesterday
            ? oldStreak + 1
            : 1;


        // ====================================================
        // 🎁 DAILY HASH RATE BONUS
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

            // ==================================================
            // ⚡ STELLA MINING POWER
            // ==================================================

            hashRate:
              newHashRate,


            // ==================================================
            // 🔥 DAILY STREAK
            // ==================================================

            streak:
              newStreak,


            // ==================================================
            // 📅 DAILY CLAIM DATE
            // ==================================================

            lastDailyDate:
              today,


            // ==================================================
            // 🎁 DAILY BONUS INFO
            // ==================================================

            dailyHashRateBonus:
              bonus,


            // ==================================================
            // 🕒 METADATA
            // ==================================================

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
        //
        // Päivämäärä dokumentin ID:nä estää
        // saman päivän tuplahistorian.
        //
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


            // ==================================================
            // 🎁 RECEIVED BONUS
            // ==================================================

            amount:
              bonus,


            // ==================================================
            // ⚡ HASH RATE
            // ==================================================

            hashRateBefore:
              oldHashRate,


            hashRateAfter:
              newHashRate,


            // ==================================================
            // 🔥 STREAK
            // ==================================================

            streak:
              newStreak,


            // ==================================================
            // 📅 DATE
            // ==================================================

            date:
              today,


            // ==================================================
            // 🕒 SERVER TIME
            // ==================================================

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


          dailyClaimed:
            true,


          // ==================================================
          // 🎁 BONUS
          // ==================================================

          bonus,


          dailyHashRateBonus:
            bonus,


          // ==================================================
          // ⚡ NEW HASH RATE
          // ==================================================

          hashRate:
            newHashRate,


          // ==================================================
          // 🔥 STREAK
          // ==================================================

          streak:
            newStreak,


          // ==================================================
          // 🐱 MESSAGE
          // ==================================================

          message:
            `🐱🎁 Stella toi sinulle +${bonus} Hash Rate! 🔥 Streak: ${newStreak}`,

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