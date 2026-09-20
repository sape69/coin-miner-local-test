"use strict";

// ============================================================
// 🐱 STELLA HISTORY FUNCTIONS
// ============================================================
//
// Stella Transaction History.
//
// Palauttaa Flutter-sovellukselle käyttäjän oman:
//
// 📜 Mining-historian
// 🎁 Daily Hash Rate -tapahtumat
// 📺 Power Boost -tapahtumat
// ⛏️ Mining Complete -tapahtumat
//
//
// TÄRKEÄÄ:
//
// Tämä tiedosto EI muuta mining-dataa.
//
// Se ainoastaan lukee käyttäjän oman history-kokoelman
// ja muuntaa Firestore-datan turvalliseen Flutter-muotoon.
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
// 🧮 SAFE NON-NEGATIVE NUMBER
// ============================================================

function getSafeNonNegativeNumber(
  value,
  fallback = 0
) {
  const number =
    Number(value);

  return Number.isFinite(number) &&
    number >= 0
    ? number
    : fallback;
}


// ============================================================
// 🧮 SAFE INTEGER
// ============================================================

function getSafeInteger(
  value,
  fallback = 0
) {
  const number =
    Number(value);

  return Number.isFinite(number)
    ? Math.floor(number)
    : fallback;
}


// ============================================================
// 📅 CONVERT TIMESTAMP TO ISO STRING
// ============================================================
//
// Tukee:
//
// 🔥 Firestore Timestamp
// 📅 JavaScript Date
// 📝 ISO Date String
// 🔢 Unix milliseconds
//
// Virheellinen arvo palauttaa null.
//
// ============================================================

function timestampToIsoString(
  value
) {
  if (
    value === null ||
    value === undefined
  ) {
    return null;
  }


  // ==========================================================
  // 🔥 FIRESTORE TIMESTAMP
  // ==========================================================

  if (
    typeof value.toDate ===
    "function"
  ) {
    try {
      const date =
        value.toDate();

      if (
        date instanceof Date &&
        !Number.isNaN(
          date.getTime()
        )
      ) {
        return date.toISOString();
      }
    } catch (
      error
    ) {
      return null;
    }

    return null;
  }


  // ==========================================================
  // 📅 JAVASCRIPT DATE
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


  // ==========================================================
  // 📝 STRING
  // ==========================================================

  if (
    typeof value === "string"
  ) {
    const trimmed =
      value.trim();

    if (
      !trimmed
    ) {
      return null;
    }

    const date =
      new Date(trimmed);

    return Number.isNaN(
      date.getTime()
    )
      ? null
      : date.toISOString();
  }


  // ==========================================================
  // 🔢 UNIX MILLISECONDS
  // ==========================================================

  if (
    typeof value === "number" &&
    Number.isFinite(value)
  ) {
    const date =
      new Date(value);

    return Number.isNaN(
      date.getTime()
    )
      ? null
      : date.toISOString();
  }


  return null;
}


// ============================================================
// 📦 SAFE OPTIONAL NUMBER
// ============================================================
//
// Jos kenttää ei ole olemassa, palautetaan null.
//
// Jos kenttä on olemassa mutta sisältö on virheellinen,
// palautetaan 0.
//
// ============================================================

function getOptionalNumber(
  data,
  field
) {
  if (
    !Object.prototype.hasOwnProperty.call(
      data,
      field
    )
  ) {
    return null;
  }

  return getSafeNumber(
    data[field],
    0
  );
}


// ============================================================
// 📜 FORMAT HISTORY DOCUMENT
// ============================================================
//
// Muuntaa yhden Firestore history-dokumentin
// turvalliseksi Flutter-vastaukseksi.
//
// ============================================================

function formatHistoryDocument(
  document
) {
  const data =
    document.data() || {};


  return {

    // ========================================================
    // 🆔 DOCUMENT / TRANSACTION ID
    // ========================================================

    id:
      document.id,


    // ========================================================
    // 📜 TYPE
    // ========================================================

    type:
      typeof data.type === "string" &&
      data.type.trim()
        ? data.type.trim()
        : "unknown",


    // ========================================================
    // 📝 TITLE
    // ========================================================

    title:
      typeof data.title === "string" &&
      data.title.trim()
        ? data.title.trim()
        : "Stella Transaction 🐱",


    // ========================================================
    // 💰 AMOUNT
    // ========================================================

    amount:
      getSafeNumber(
        data.amount,
        0
      ),


    // ========================================================
    // ⚡ HASH RATE
    // ========================================================

    hashRate:
      getOptionalNumber(
        data,
        "hashRate"
      ),


    hashRateBefore:
      getOptionalNumber(
        data,
        "hashRateBefore"
      ),


    hashRateAfter:
      getOptionalNumber(
        data,
        "hashRateAfter"
      ),


    // ========================================================
    // ⚡ DAILY HASH RATE
    // ========================================================

    dailyHashRate:
      getOptionalNumber(
        data,
        "dailyHashRate"
      ),


    // ========================================================
    // 🎁 DAILY STREAK
    // ========================================================

    dailyStreak:
      data.dailyStreak !== undefined
        ? Math.max(
            0,
            getSafeInteger(
              data.dailyStreak,
              0
            )
          )
        : null,


    streak:
      data.streak !== undefined
        ? Math.max(
            0,
            getSafeInteger(
              data.streak,
              0
            )
          )
        : null,


    // ========================================================
    // 📺 AD HASH RATE BONUS
    // ========================================================

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
              : (
                  data.adHashRateBonus !== undefined
                    ? getSafeNumber(
                        data.adHashRateBonus,
                        0
                      )
                    : null
                )
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


    // ========================================================
    // ⚡ EFFECTIVE HASH RATE
    // ========================================================

    effectiveHashRate:
      getOptionalNumber(
        data,
        "effectiveHashRate"
      ),


    // ========================================================
    // ⛏️ MINING AMOUNTS
    // ========================================================
    //
    // Stella Mining Complete -historia käyttää:
    //
    // baseMining
    // adBoostMining
    // amount
    //
    // ========================================================

    baseMining:
      getOptionalNumber(
        data,
        "baseMining"
      ),


    adBoostMining:
      getOptionalNumber(
        data,
        "adBoostMining"
      ),


    // ========================================================
    // 💎 BALANCE
    // ========================================================

    balanceAfter:
      data.balanceAfter !== undefined
        ? getSafeNonNegativeNumber(
            data.balanceAfter,
            0
          )
        : null,


    // ========================================================
    // ⏱️ MINING DURATION
    // ========================================================

    miningDurationMs:
      data.miningDurationMs !== undefined
        ? getSafeNonNegativeNumber(
            data.miningDurationMs,
            0
          )
        : null,


    // ========================================================
    // 📺 ADS
    // ========================================================

    adsToday:
      data.adsToday !== undefined
        ? Math.max(
            0,
            getSafeInteger(
              data.adsToday,
              0
            )
          )
        : null,


    maxAdsPerDay:
      data.maxAdsPerDay !== undefined
        ? Math.max(
            0,
            getSafeInteger(
              data.maxAdsPerDay,
              0
            )
          )
        : null,


    // ========================================================
    // 🎁 REWARD TYPE
    // ========================================================

    rewardType:
      typeof data.rewardType === "string"
        ? data.rewardType
        : null,


    rewardPurpose:
      typeof data.rewardPurpose === "string"
        ? data.rewardPurpose
        : null,


    // ========================================================
    // 🔐 ADMOB TRANSACTION
    // ========================================================

    adRewardTransactionId:
      typeof data.adRewardTransactionId ===
        "string"
        ? data.adRewardTransactionId
        : null,


    transactionId:
      typeof data.transactionId ===
        "string"
        ? data.transactionId
        : null,


    // ========================================================
    // ⚡ POWER BOOST
    // ========================================================

    boostStartedAt:
      timestampToIsoString(
        data.boostStartedAt
      ),


    boostEndsAt:
      timestampToIsoString(
        data.boostEndsAt
      ),


    boostDurationMs:
      data.boostDurationMs !== undefined
        ? getSafeNonNegativeNumber(
            data.boostDurationMs,
            0
          )
        : null,


    // ========================================================
    // ⛏️ MINING WINDOW
    // ========================================================

    miningStartedAt:
      timestampToIsoString(
        data.miningStartedAt
      ),


    miningEndsAt:
      timestampToIsoString(
        data.miningEndsAt
      ),


    // ========================================================
    // 📺 POWER BOOST ADS
    // ========================================================

    powerBoostTransactionId:
      typeof data.powerBoostTransactionId ===
        "string"
        ? data.powerBoostTransactionId
        : null,


    // ========================================================
    // 📅 DATE
    // ========================================================

    date:
      typeof data.date === "string"
        ? data.date
        : null,


    // ========================================================
    // 🕒 CREATED AT
    // ========================================================

    createdAt:
      timestampToIsoString(
        data.createdAt
      ),

  };
}


// ============================================================
// 📜 GET TRANSACTION HISTORY
// ============================================================
//
// Flutter kutsuu:
//
// getTransactionHistory()
//
// Käyttäjä voi saada vain oman history-kokoelmansa.
//
// getHistoryCollection(uid)
// muodostaa käyttäjän oman Firestore-polun.
//
// ============================================================

const getTransactionHistory =
  onCall(
    {
      region:
        "us-central1",
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
        // 👤 HISTORY COLLECTION
        // ====================================================

        const historyCollection =
          getHistoryCollection(
            uid
          );


        // ====================================================
        // 🛡️ SAFE HISTORY LIMIT
        // ====================================================

        const configuredLimit =
          getSafeInteger(
            MAX_TRANSACTION_HISTORY,
            50
          );

        const historyLimit =
          Math.min(
            100,
            Math.max(
              1,
              configuredLimit
            )
          );


        // ====================================================
        // 🔥 GET HISTORY
        // ====================================================
        //
        // Haetaan uusimmat tapahtumat ensin.
        //
        // ====================================================

        const snapshot =
          await historyCollection
            .orderBy(
              "createdAt",
              "desc"
            )
            .limit(
              historyLimit
            )
            .get();


        // ====================================================
        // 📦 FORMAT HISTORY
        // ====================================================

        const transactions =
          snapshot.docs.map(
            formatHistoryDocument
          );


        // ====================================================
        // 📊 COUNT
        // ====================================================

        const count =
          transactions.length;


        // ====================================================
        // 📤 RESPONSE
        // ====================================================

        return {

          success:
            true,

          transactions,

          count,

        };

      } catch (error) {

        console.error(
          "getTransactionHistory error:",
          error
        );


        // ====================================================
        // 🔐 PRESERVE FIREBASE ERRORS
        // ====================================================

        if (
          error instanceof HttpsError
        ) {
          throw error;
        }


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