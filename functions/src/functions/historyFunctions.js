"use strict";

// ============================================================
// 🐱 STELLA HISTORY FUNCTIONS
// ============================================================
//
// Stella Transaction History.
//
// Palauttaa Flutter-sovellukselle käyttäjän omat:
//
// 📜 Mining-tapahtumat
// 🎁 Daily Hash Rate -tapahtumat
// 📺 Ad Power Boost -tapahtumat
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

function timestampToIsoString(
  value
) {

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
// 🧮 SAFE NUMBER
// ============================================================

function getSafeNumber(
  value,
  fallback = 0
) {

  const number =
    Number(value);


  return Number.isFinite(
    number
  )
    ? number
    : fallback;

}


// ============================================================
// 📜 GET TRANSACTION HISTORY
// ============================================================
//
// Flutter kutsuu:
//
// getTransactionHistory()
//
// Käyttäjä voi saada vain oman käyttäjäpolkunsa
// tapahtumat, koska getHistoryCollection(uid)
// käyttää request.auth.uid-arvoa.
//
// ============================================================

const getTransactionHistory =
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
          "🐱 Kirjaudu sisään nähdäksesi Stella-historian."
        );

      }


      const uid =
        request.auth.uid;


      try {

        // ====================================================
        // 📜 HISTORY COLLECTION
        // ====================================================

        const historyCollection =
          getHistoryCollection(
            uid
          );


        // ====================================================
        // 🔥 GET HISTORY
        // ====================================================
        //
        // Haetaan viimeisimmät tapahtumat.
        //
        // ====================================================

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


        // ====================================================
        // 📦 FORMAT HISTORY
        // ====================================================

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
                  getSafeNumber(
                    data.amount,
                    0
                  ),


                // ------------------------------------------------
                // ⚡ HASH RATE
                // ------------------------------------------------

                hashRate:
                  data.hashRate !== undefined
                    ? getSafeNumber(
                        data.hashRate,
                        0
                      )
                    : null,


                hashRateBefore:
                  data.hashRateBefore !== undefined
                    ? getSafeNumber(
                        data.hashRateBefore,
                        0
                      )
                    : null,


                hashRateAfter:
                  data.hashRateAfter !== undefined
                    ? getSafeNumber(
                        data.hashRateAfter,
                        0
                      )
                    : null,


                // ------------------------------------------------
                // ⚡ DAILY HASH RATE
                // ------------------------------------------------

                dailyHashRate:
                  data.dailyHashRate !== undefined
                    ? getSafeNumber(
                        data.dailyHashRate,
                        0
                      )
                    : null,


                // ------------------------------------------------
                // ⚡ AD HASH RATE BONUS
                // ------------------------------------------------

                hashRateBonus:
                  data.hashRateBonus !== undefined
                    ? getSafeNumber(
                        data.hashRateBonus,
                        0
                      )
                    : (
                        data.adBoostHashRate !== undefined
                          ? getSafeNumber(
                              data.adBoostHashRate,
                              0
                            )
                          : null
                      ),


                adHashRateBonus:
                  data.adHashRateBonus !== undefined
                    ? getSafeNumber(
                        data.adHashRateBonus,
                        0
                      )
                    : (
                        data.adBoostHashRate !== undefined
                          ? getSafeNumber(
                              data.adBoostHashRate,
                              0
                            )
                          : null
                      ),


                adBoostHashRate:
                  data.adBoostHashRate !== undefined
                    ? getSafeNumber(
                        data.adBoostHashRate,
                        0
                      )
                    : null,


                // ------------------------------------------------
                // ⚡ EFFECTIVE HASH RATE
                // ------------------------------------------------

                effectiveHashRate:
                  data.effectiveHashRate !== undefined
                    ? getSafeNumber(
                        data.effectiveHashRate,
                        0
                      )
                    : null,


                // ------------------------------------------------
                // 💎 BALANCE
                // ------------------------------------------------

                balanceAfter:
                  data.balanceAfter !== undefined
                    ? getSafeNumber(
                        data.balanceAfter,
                        0
                      )
                    : null,


                // ------------------------------------------------
                // 🎁 DAILY STREAK
                // ------------------------------------------------

                dailyStreak:
                  data.dailyStreak !== undefined
                    ? getSafeNumber(
                        data.dailyStreak,
                        0
                      )
                    : null,


                streak:
                  data.streak !== undefined
                    ? getSafeNumber(
                        data.streak,
                        0
                      )
                    : null,


                // ------------------------------------------------
                // 📺 ADS
                // ------------------------------------------------

                adsToday:
                  data.adsToday !== undefined
                    ? getSafeNumber(
                        data.adsToday,
                        0
                      )
                    : null,


                // ------------------------------------------------
                // 🎁 REWARD TYPE
                // ------------------------------------------------

                rewardType:
                  data.rewardType ||
                  null,


                // ------------------------------------------------
                // ⏳ BOOST START
                // ------------------------------------------------

                boostStartedAt:
                  timestampToIsoString(
                    data.boostStartedAt
                  ),


                // ------------------------------------------------
                // ⏳ BOOST END
                // ------------------------------------------------

                boostEndsAt:
                  timestampToIsoString(
                    data.boostEndsAt
                  ),


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


        // ====================================================
        // 📤 RESPONSE
        // ====================================================

        return {

          success:
            true,

          transactions,

          count:
            transactions.length,

        };

      } catch (error) {

        console.error(
          "getTransactionHistory error:",
          error
        );


        throw new HttpsError(
          "internal",
          "Stella-tapahtumahistorian lataaminen epäonnistui."
        );

      }

    }
  );


// ============================================================
// 📦 EXPORTS
// ============================================================

module.exports = {

  getTransactionHistory,

};