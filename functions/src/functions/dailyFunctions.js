"use strict";


// ============================================================
// 🐱 STELLA DAILY FUNCTIONS
// ============================================================
//
// Tämä tiedosto hallitsee:
//
// 🎁 Stella Daily Check-In
// 📅 Päivittäisen bonuksen
// ⚡ Hash Rate -kasvun
// 🛡️ Saman päivän tuplabonuksen estämisen
// 📜 Daily-tapahtumahistorian
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
//
// Flutter kutsuu:
//
// dailyCheckIn()
//
// Pelaaja voi saada Daily Bonus -palkinnon
// kerran yhden UTC-päivän aikana.
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
        "🐱 Kirjaudu sisään saadaksesi Daily Bonus -palkinnon."
      );

    }


    const uid =
      request.auth.uid;


    const userRef =
      getUserRef(uid);


    // ========================================================
    // 📅 CURRENT DATE
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
        // 👤 GET USER
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
        // 📅 LAST DAILY DATE
        // ====================================================

        const lastDailyDate =
          typeof data.lastDailyDate === "string"
            ? data.lastDailyDate
            : null;


        // ====================================================
        // 🛡️ ALREADY CLAIMED TODAY
        // ====================================================

        if (
          lastDailyDate === today
        ) {

          return {

            success:
              true,


            claimed:
              false,


            alreadyClaimed:
              true,


            date:
              today,


            hashRate:
              Number(
                data.hashRate ||
                DEFAULT_HASH_RATE
              ),


            message:
              "🐱🎁 Stella Daily Bonus on jo kerätty tänään!",

          };

        }


        // ====================================================
        // ⚡ CURRENT HASH RATE
        // ====================================================

        const currentHashRate =
          Math.max(
            0,
            Number(
              data.hashRate ||
              DEFAULT_HASH_RATE
            )
          );


        // ====================================================
        // 🎁 DAILY BONUS
        // ====================================================

        const bonus =
          DAILY_HASH_RATE_BONUS;


        const newHashRate =
          currentHashRate +
          bonus;


        // ====================================================
        // 🔥 DAILY STREAK
        // ====================================================
        //
        // Jos käyttäjä teki Daily Check-Inin eilen,
        // streak jatkuu.
        //
        // Muuten streak alkaa uudestaan numerosta 1.
        //
        // ====================================================

        const previousStreak =
          Math.max(
            0,
            Number(
              data.dailyStreak || 0
            )
          );


        const newDailyStreak =
          lastDailyDate === yesterday
            ? previousStreak + 1
            : 1;


        // ====================================================
        // 📜 DAILY HISTORY REFERENCE
        // ====================================================

        const dailyHistoryRef =
          createDailyHistoryRef(
            uid,
            today
          );


        // ====================================================
        // 👤 UPDATE USER
        // ====================================================

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