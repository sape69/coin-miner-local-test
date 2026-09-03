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
// 📜 STELLA HISTORY FUNCTIONS
// ============================================================
//
// Hakee käyttäjän Stella Mining -historian.
//
// Historia sisältää:
//
// 🐱 Stella Mining
// ⛏️ Mining Complete
// 🎁 Daily Bonus
// 📺 Power Boost
//
// ============================================================


// ============================================================
// 📜 GET TRANSACTION HISTORY
// ============================================================

const getTransactionHistory =
  onCall(async (request) => {

    // ========================================================
    // AUTHENTICATION
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
    // GET HISTORY
    // ========================================================

    const snapshot =
      await getHistoryCollection(uid)
        .orderBy(
          "createdAt",
          "desc"
        )
        .limit(
          MAX_TRANSACTION_HISTORY
        )
        .get();


    // ========================================================
    // FORMAT HISTORY
    // ========================================================

    const transactions =
      snapshot.docs.map(
        (doc) => {

          const data =
            doc.data();


          // ==================================================
          // DATE
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
          // TRANSACTION
          // ==================================================

          return {

            id:
              doc.id,


            // ----------------------------------------------
            // TYPE
            // ----------------------------------------------

            type:
              String(
                data.type || ""
              ),


            // ----------------------------------------------
            // TITLE
            // ----------------------------------------------

            title:
              String(
                data.title || ""
              ),


            // ----------------------------------------------
            // AMOUNT
            // ----------------------------------------------

            amount:
              Number(
                data.amount || 0
              ),


            // ----------------------------------------------
            // BALANCE
            // ----------------------------------------------

            balanceAfter:
              Number(
                data.balanceAfter || 0
              ),


            // ----------------------------------------------
            // HASH RATE AFTER
            // ----------------------------------------------

            hashRateAfter:
              Number(
                data.hashRateAfter || 0
              ),


            // ----------------------------------------------
            // HASH RATE
            // ----------------------------------------------

            hashRate:
              Number(
                data.hashRate || 0
              ),


            // ----------------------------------------------
            // STREAK
            // ----------------------------------------------

            streak:
              Number(
                data.streak || 0
              ),


            // ----------------------------------------------
            // ADS
            // ----------------------------------------------

            adsToday:
              Number(
                data.adsToday || 0
              ),


            // ----------------------------------------------
            // MINING RESTARTED
            // ----------------------------------------------

            miningRestarted:
              data.miningRestarted === true,


            // ----------------------------------------------
            // DATE
            // ----------------------------------------------

            createdAt,

          };
        }
      );


    // ========================================================
    // RESPONSE
    // ========================================================

    return {

      success:
        true,

      transactions,

    };
  });


// ============================================================
// EXPORTS
// ============================================================

module.exports = {

  getTransactionHistory,

};