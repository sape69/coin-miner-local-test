"use strict";


// ============================================================
// 🐱 STELLA HISTORY FUNCTIONS
// ============================================================
//
// Tämä tiedosto hallitsee:
//
// 📜 Käyttäjän Stella-tapahtumahistorian
// ⛏️ Mining-tapahtumat
// 🎁 Daily Bonus -tapahtumat
// 📺 Ad Reward -tapahtumat
//
// Flutter kutsuu:
//
// getTransactionHistory()
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
// ⚙️ CONFIG
// ============================================================

const {
  MAX_TRANSACTION_HISTORY,
} = require(
  "../config/miningConfig"
);


// ============================================================
// 👤 USER UTILITIES
// ============================================================

const {
  getHistoryCollection,
} = require(
  "../utils/userUtils"
);


// ============================================================
// 📅 CONVERT TIMESTAMP TO ISO STRING
// ============================================================
//
// Tukee:
//
// • Firestore Timestamp
// • JavaScript Date
//
// ============================================================

function timestampToIsoString(value) {

  if (!value) {
    return null;
  }


  // ==========================================================
  // FIRESTORE TIMESTAMP
  // ==========================================================

  if (
    typeof value.toDate ===
    "function"
  ) {

    const date =
      value.toDate();

    return Number.isNaN(
      date.getTime()
    )
      ? null
      : date.toISOString();

  }


  // ==========================================================
  // JAVASCRIPT DATE
  // ==========================================================

  if (
    value instanceof Date
  ) {

    return Number.isNaN(
      value.getTime()
    )
      ? null
      : value.toISOString();

  }


  return null;

}


// ============================================================
// 📜 GET TRANSACTION HISTORY
// ============================================================
//
// Flutter kutsuu:
//
// getTransactionHistory()
//
// Palauttaa käyttäjän viimeisimmät
// Stella-tapahtumat.
//
// ============================================================

const getTransactionHistory =
  onCall(async (request) => {

    // ========================================================
    // 🔐 AUTHENTICATION
    // ========================================================

    if (!request.auth) {

      throw new HttpsError(
        "unauthenticated",
        "🐱 Kirjaudu sisään nähdäksesi Stella-historian."
      );

    }


    const uid =
      request.auth.uid;


    // ========================================================
    // 📜 HISTORY COLLECTION
    // ========================================================

    const historyCollection =
      getHistoryCollection(uid);


    // ========================================================
    // 🔥 GET HISTORY
    // ========================================================

    const snapshot =
      await historyCollection
        .orderBy(
          "createdAt",
          "desc"
        )
        .limit(
          MAX_TRANSACTION_HISTORY
        )
        .get();


    // ========================================================
    // 📦 FORMAT HISTORY
    // ========================================================

    const transactions =
      snapshot.docs.map(
        (document) => {

          const data =
            document.data();


          return {

            // ------------------------------------------------
            // 🆔 TRANSACTION ID
            // ------------------------------------------------

            id:
              document.id,


            // ------------------------------------------------
            // 📜 TYPE
            // ------------------------------------------------

            type:
              data.type ||
              "unknown",


            // ------------------------------------------------
            // 📝 TITLE
            // ------------------------------------------------

            title:
              data.title ||
              "Stella Transaction 🐱",


            // ------------------------------------------------
            // 💰 AMOUNT
            // ------------------------------------------------

            amount:
              Number(
                data.amount || 0
              ),


            // ------------------------------------------------
            // ⚡ HASH RATE
            // ------------------------------------------------

            hashRate:
              data.hashRate !== undefined
                ? Number(data.hashRate)
                : null,


            hashRateBefore:
              data.hashRateBefore !== undefined
                ? Number(
                    data.hashRateBefore
                  )
                : null,


            hashRateAfter:
              data.hashRateAfter !== undefined
                ? Number(
                    data.hashRateAfter
                  )
                : null,


            // ------------------------------------------------
            // 💎 BALANCE
            // ------------------------------------------------

            balanceAfter:
              data.balanceAfter !== undefined
                ? Number(
                    data.balanceAfter
                  )
                : null,


            // ------------------------------------------------
            // 🎁 DAILY STREAK
            // ------------------------------------------------

            dailyStreak:
              data.dailyStreak !== undefined
                ? Number(
                    data.dailyStreak
                  )
                : null,


            // ------------------------------------------------
            // 📅 DATE
            // ------------------------------------------------

            date:
              data.date ||
              null,


            // ------------------------------------------------
            // 🕒 CREATED AT
            // ------------------------------------------------

            createdAt:
              timestampToIsoString(
                data.createdAt
              ),

          };

        }
      );


    // ========================================================
    // 📤 RESPONSE
    // ========================================================

    return {

      success:
        true,


      transactions,


      count:
        transactions.length,

    };

  });


// ============================================================
// 📦 EXPORTS
// ============================================================

module.exports = {

  getTransactionHistory,

};