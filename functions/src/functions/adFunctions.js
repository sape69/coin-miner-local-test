"use strict";


// ============================================================
// 🐱 STELLA AD FUNCTIONS
// ============================================================
//
// Tämä tiedosto hallitsee:
//
// 📺 Test Ad Reward
// 🎁 Stella Power Boost
// ⚡ Hash Rate -palkinnon
// ⏳ Ad Cooldownin
// 🔢 Päivittäisen mainosrajan
// 📜 Ad-tapahtumahistorian
// 🔐 AdMob SSV -callbackin
//
// ============================================================


// ============================================================
// 🔥 FIREBASE FUNCTIONS
// ============================================================

const {
  onCall,
  onRequest,
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
  AD_HASH_RATE_BONUS,
  MAX_ADS_PER_DAY,
  AD_COOLDOWN_MS,
} = require(
  "../config/miningConfig"
);


// ============================================================
// 📅 DATE UTILITIES
// ============================================================

const {
  getUtcDateString,
} = require(
  "../utils/dateUtils"
);


// ============================================================
// 👤 USER UTILITIES
// ============================================================

const {
  getUserRef,
  getHistoryCollection,
  getAdMobRewardRef,
} = require(
  "../utils/userUtils"
);


// ============================================================
// 🔐 ADMOB SERVICE
// ============================================================

const {
  verifyAdMobCallback,
} = require(
  "../services/admobService"
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
// 📺 GET AD STATUS
// ============================================================
//
// Tarkistaa:
//
// • Päivittäisen mainosmäärän
// • Cooldownin
// • Voiko käyttäjä katsoa mainoksen
//
// ============================================================

function getAdStatus(
  data,
  nowMs,
  today
) {

  const storedDate =
    typeof data.lastAdDate === "string"
      ? data.lastAdDate
      : "";


  // ==========================================================
  // 🔢 ADS TODAY
  // ==========================================================

  const adsToday =
    storedDate === today
      ? Math.max(
          0,
          Math.floor(
            getSafeNumber(
              data.adsToday,
              0
            )
          )
        )
      : 0;


  // ==========================================================
  // ⏳ LAST REWARD
  // ==========================================================

  const lastAdRewardAt =
    data.lastAdRewardAt;


  let lastAdRewardMs =
    0;


  if (
    lastAdRewardAt &&
    typeof lastAdRewardAt.toDate ===
      "function"
  ) {

    lastAdRewardMs =
      lastAdRewardAt
        .toDate()
        .getTime();

  } else if (
    lastAdRewardAt instanceof Date
  ) {

    lastAdRewardMs =
      lastAdRewardAt.getTime();

  } else if (
    typeof lastAdRewardAt === "string"
  ) {

    const parsedDate =
      new Date(lastAdRewardAt);


    if (
      !Number.isNaN(
        parsedDate.getTime()
      )
    ) {

      lastAdRewardMs =
        parsedDate.getTime();

    }

  }


  // ==========================================================
  // ⏳ COOLDOWN
  // ==========================================================

  const cooldownRemainingMs =
    Math.max(
      0,
      (
        lastAdRewardMs +
        AD_COOLDOWN_MS
      ) -
      nowMs
    );


  // ==========================================================
  // 📺 CAN WATCH
  // ==========================================================

  const canWatchAd =
    adsToday < MAX_ADS_PER_DAY &&
    cooldownRemainingMs === 0;


  return {

    adsToday,

    maxAdsPerDay:
      MAX_ADS_PER_DAY,

    cooldownRemainingMs,

    canWatchAd,

  };

}


// ============================================================
// 🎁 APPLY AD REWARD
// ============================================================
//
// Lisää käyttäjälle:
//
// ⚡ AD_HASH_RATE_BONUS
//
// Estää:
//
// 🔐 Saman transactionId:n käytön uudelleen
// 🚫 Päivittäisen rajan ylittämisen
// ⏳ Cooldownin ohittamisen
//
// ============================================================

async function applyAdReward(
  uid,
  transactionId,
  rewardType
) {

  // ==========================================================
  // 👤 USER
  // ==========================================================

  const userRef =
    getUserRef(uid);


  // ==========================================================
  // 🔐 REWARD
  // ==========================================================

  const rewardRef =
    getAdMobRewardRef(
      transactionId
    );


  // ==========================================================
  // 🕒 TIME
  // ==========================================================

  const now =
    new Date();


  const nowMs =
    now.getTime();


  const today =
    getUtcDateString();


  // ==========================================================
  // 🔥 TRANSACTION
  // ==========================================================

  return await db.runTransaction(
    async (transaction) => {

      // ======================================================
      // 🔐 DUPLICATE CHECK
      // ======================================================

      const rewardSnapshot =
        await transaction.get(
          rewardRef
        );


      if (rewardSnapshot.exists) {

        return {

          success:
            true,

          rewarded:
            false,

          duplicate:
            true,

          reason:
            "duplicate",

          message:
            "🐱📺 Tämä mainospalkinto on jo käsitelty.",

        };

      }


      // ======================================================
      // 👤 GET USER
      // ======================================================

      const userSnapshot =
        await transaction.get(
          userRef
        );


      const data =
        userSnapshot.exists
          ? userSnapshot.data()
          : {};


      // ======================================================
      // 📺 AD STATUS
      // ======================================================

      const adStatus =
        getAdStatus(
          data,
          nowMs,
          today
        );


      // ======================================================
      // 🚫 DAILY LIMIT
      // ======================================================

      if (
        adStatus.adsToday >=
        MAX_ADS_PER_DAY
      ) {

        return {

          success:
            false,

          rewarded:
            false,

          duplicate:
            false,

          reason:
            "daily_limit",

          adsToday:
            adStatus.adsToday,

          maxAdsPerDay:
            MAX_ADS_PER_DAY,

          canWatchAd:
            false,

          message:
            "🐱📺 Päivän Stella Power Boost -raja on saavutettu.",

        };

      }


      // ======================================================
      // ⏳ COOLDOWN
      // ======================================================

      if (
        adStatus.cooldownRemainingMs > 0
      ) {

        return {

          success:
            false,

          rewarded:
            false,

          duplicate:
            false,

          reason:
            "cooldown",

          adsToday:
            adStatus.adsToday,

          maxAdsPerDay:
            MAX_ADS_PER_DAY,

          cooldownRemainingMs:
            adStatus.cooldownRemainingMs,

          canWatchAd:
            false,

          message:
            "🐱⏳ Stella Power Boost on vielä cooldownissa.",

        };

      }


      // ======================================================
      // ⚡ CURRENT HASH RATE
      // ======================================================

      const currentHashRate =
        Math.max(
          0,
          getSafeNumber(
            data.hashRate,
            DEFAULT_HASH_RATE
          )
        );


      // ======================================================
      // 🎁 BONUS
      // ======================================================

      const bonus =
        Math.max(
          0,
          getSafeNumber(
            AD_HASH_RATE_BONUS,
            0
          )
        );


      const newHashRate =
        currentHashRate +
        bonus;


      // ======================================================
      // 🔢 NEW AD COUNT
      // ======================================================

      const newAdsToday =
        adStatus.adsToday +
        1;


      // ======================================================
      // 👤 UPDATE USER
      // ======================================================

      transaction.set(
        userRef,
        {

          // ⚡ HASH RATE

          hashRate:
            newHashRate,


          // 📺 DAILY AD COUNT

          lastAdDate:
            today,


          adsToday:
            newAdsToday,


          // ⏳ COOLDOWN

          lastAdRewardAt:
            now,


          // 🕒 METADATA

          updatedAt:
            FieldValue.serverTimestamp(),

        },
        {
          merge:
            true,
        }
      );


      // ======================================================
      // 🔐 SAVE REWARD
      // ======================================================

      transaction.set(
        rewardRef,
        {

          uid,

          transactionId,

          rewardType,

          bonus,

          hashRateBefore:
            currentHashRate,

          hashRateAfter:
            newHashRate,

          createdAt:
            FieldValue.serverTimestamp(),

        }
      );


      // ======================================================
      // 📜 HISTORY
      // ======================================================

      const historyRef =
        getHistoryCollection(uid)
          .doc();


      transaction.set(
        historyRef,
        {

          type:
            "ad_reward",

          title:
            "Stella Power Boost 🐱📺⚡",

          amount:
            bonus,

          hashRateBefore:
            currentHashRate,

          hashRateAfter:
            newHashRate,

          rewardType,

          createdAt:
            FieldValue.serverTimestamp(),

        }
      );


      // ======================================================
      // 📤 SUCCESS RESPONSE
      // ======================================================

      return {

        success:
          true,

        rewarded:
          true,

        duplicate:
          false,

        reason:
          null,

        bonus,

        hashRateBefore:
          currentHashRate,

        hashRate:
          newHashRate,

        adsToday:
          newAdsToday,

        maxAdsPerDay:
          MAX_ADS_PER_DAY,

        cooldownRemainingMs:
          AD_COOLDOWN_MS,

        cooldownMs:
          AD_COOLDOWN_MS,

        canWatchAd:
          false,

        message:
          `🐱📺⚡ Stella sai +${bonus} Hash Rate Power Boostin!`,

      };

    }
  );

}


// ============================================================
// 🧪 TEST AD REWARD
// ============================================================
//
// Flutter kutsuu:
//
// testAdReward()
//
// Tämä käytetään testimainoksen jälkeen.
//
// ============================================================

const testAdReward =
  onCall(async (request) => {

    // ========================================================
    // 🔐 AUTH
    // ========================================================

    if (!request.auth) {

      throw new HttpsError(
        "unauthenticated",
        "🐱 Kirjaudu sisään saadaksesi Stella Power Boostin."
      );

    }


    const uid =
      request.auth.uid;


    // ========================================================
    // 🔐 UNIQUE TEST TRANSACTION
    // ========================================================

    const transactionId =
      `test_${uid}_${Date.now()}_${Math.random()
        .toString(36)
        .substring(2, 10)}`;


    // ========================================================
    // 🎁 APPLY REWARD
    // ========================================================

    return await applyAdReward(
      uid,
      transactionId,
      "test"
    );

  });


// ============================================================
// 🔐 ADMOB REWARD CALLBACK
// ============================================================
//
// Google AdMob SSV kutsuu tätä endpointia.
//
// ============================================================

const adMobReward =
  onRequest(async (req, res) => {

    try {

      // ======================================================
      // 🔐 VERIFY GOOGLE CALLBACK
      // ======================================================

      await verifyAdMobCallback(
        req
      );


      // ======================================================
      // 👤 USER ID
      // ======================================================

      const uid =
        typeof req.query.user_id ===
        "string"
          ? req.query.user_id
          : null;


      // ======================================================
      // 🔐 TRANSACTION ID
      // ======================================================

      const transactionId =
        typeof req.query.transaction_id ===
        "string"
          ? req.query.transaction_id
          : null;


      // ======================================================
      // 🛡️ VALIDATE
      // ======================================================

      if (
        !uid ||
        !transactionId
      ) {

        res.status(400).json({

          success:
            false,

          error:
            "Missing user_id or transaction_id.",

        });

        return;

      }


      // ======================================================
      // 🎁 APPLY REWARD
      // ======================================================

      const result =
        await applyAdReward(
          uid,
          transactionId,
          "admob"
        );


      // ======================================================
      // 📤 RESPONSE
      // ======================================================

      res.status(200).json(
        result
      );

    } catch (error) {

      console.error(
        "AdMob reward verification failed:",
        error
      );


      res.status(400).json({

        success:
          false,

        error:
          error instanceof Error
            ? error.message
            : "Unknown error",

      });

    }

  });


// ============================================================
// 📦 EXPORTS
// ============================================================

module.exports = {

  testAdReward,

  adMobReward,

};