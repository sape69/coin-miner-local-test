"use strict";

const {
  onCall,
  HttpsError,
} = require("firebase-functions/v2/https");

const {
  MAX_TRANSACTION_HISTORY,
} = require("../config/miningConfig");

const {
  getHistoryCollection,
} = require("../utils/userUtils");


// ============================================================
// 🐱 STELLA HISTORY FUNCTIONS
// ============================================================
//
// 📜 Stella Mining History
//
// Näyttää käyttäjän viimeisimmät:
//
// ⛏️ Stella Mining -tapahtumat
// 🎁 Stella Daily Bonus
// 📺 Stella Power Boost
//
// ============================================================


// ============================================================
// 📜 GET TRANSACTION HISTORY
// ============================================================

const getTransactionHistory =
  onCall(async (request) => {

    // ========================================================
    // 🔐 AUTHENTICATION
    // ========================================================

    if (!request.auth) {
      throw new HttpsError(
        "unauthenticated",
        "🐱 Kirjaudu sisään nähdäksesi Stella Historian."
      );
    }


    const uid =
      request.auth.uid;


    // ========================================================
    // 📁 HISTORY COLLECTION
    // ========================================================

    const historyCollection =
      getHistoryCollection(uid);


    // ========================================================
    // 📜 GET LATEST TRANSACTIONS
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
    // 🐱 FORMAT TRANSACTIONS
    // ========================================================

    const transactions =
      snapshot.docs.map(
        (doc) => {

          const data =
            doc.data();


          // ==================================================
          // ⏱️ CREATED AT
          // ==================================================

          let createdAt =
            null;


          if (
            data.createdAt &&
            typeof data.createdAt.toDate ===
              "function"
          ) {

            createdAt =
              data.createdAt
                .toDate()
                .toISOString();
          }


          // ==================================================
          // 📜 RETURN TRANSACTION
          // ==================================================

          return {

            // Unique transaction ID
            id:
              doc.id,


            // Transaction type
            type:
              String(
                data.type || ""
              ),


            // Stella themed title
            title:
              String(
                data.title || ""
              ),


            // STL amount or Hash Rate bonus
            amount:
              Number(
                data.amount || 0
              ),


            // STL balance after transaction
            balanceAfter:
              Number(
                data.balanceAfter || 0
              ),


            // Hash Rate after transaction
            hashRateAfter:
              Number(
                data.hashRateAfter || 0
              ),


            // Hash Rate used for mining
            hashRate:
              Number(
                data.hashRate || 0
              ),


            // Daily streak
            streak:
              Number(
                data.streak || 0
              ),


            // Ads watched today
            adsToday:
              Number(
                data.adsToday || 0
              ),


            // Did ad restart Stella Mining?
            miningRestarted:
              data.miningRestarted === true,


            // AdMob transaction ID
            admobTransactionId:
              String(
                data.admobTransactionId || ""
              ),


            // Timestamp
            createdAt,

          };
        }
      );


    // ========================================================
    // 🐱 RESPONSE
    // ========================================================

    return {

      success: true,

      count:
        transactions.length,

      transactions,

    };
  });


// ============================================================
// 📦 EXPORTS
// ============================================================

module.exports = {

  getTransactionHistory,

};