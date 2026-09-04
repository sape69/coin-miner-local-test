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

function getAdStatus(
  data,
  nowMs,
  today
) {

  const storedDate =
    typeof data.lastAdDate === "string"
      ? data.lastAdDate
      : null;


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

  }


  const cooldownRemainingMs =
    Math.max(
      0,
      (
        lastAdRewardMs +
        AD_COOLDOWN_MS
      ) -
      nowMs
    );


  return {

    adsToday,

    cooldownRemainingMs,

    canWatchAd:
      adsToday < MAX_ADS_PER_DAY &&
      cooldownRemainingMs === 0,

  };

}


// ============================================================
// 🎁 APPLY AD REWARD
// ============================================================

async function applyAdReward(
  uid,
  transactionId,
  rewardType
) {

  const userRef =
    getUserRef(uid);


  const rewardRef =
    getAdMobRewardRef(
      transactionId
    );


  const now =
    new Date();


  const nowMs =
    now.getTime();


  const today =
    getUtcDateString();


  return await db.runTransaction(
    async (transaction) => {

      const rewardSnapshot =
        await transaction.get(
          rewardRef
        );


      // ======================================================
      // 🔐 DUPLICATE CHECK
      // ======================================================

      if (rewardSnapshot.exists) {

        return {

          success: true,

          rewarded: false,

          duplicate: true,

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

          success: false,

          rewarded: false,

          reason: "daily_limit",

          adsToday:
            adStatus.adsToday,

          maxAdsPerDay:
            MAX_ADS_PER_DAY,

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

          success: false,

          rewarded: false,

          reason: "cooldown",

          cooldownRemainingMs:
            adStatus.cooldownRemainingMs,

          message:
            "🐱⏳ Stella Power Boost on vielä cooldownissa.",

        };

      }


      // ======================================================
      // ⚡ HASH RATE
      // ======================================================

      const currentHashRate =
        Math.max(
          0,
          getSafeNumber(
            data.hashRate,
            DEFAULT_HASH_RATE
          )
        );


      const bonus =
        AD_HASH_RATE_BONUS;


      const newHashRate =
        currentHashRate +
        bonus;


      const newAdsToday =
        adStatus.adsToday +
        1;


      // ======================================================
      // 👤 UPDATE USER
      // ======================================================

      transaction.set(
        userRef,
        {

          hashRate:
            newHashRate,

          lastAdDate:
            today,

          adsToday:
            newAdsToday,

          lastAdRewardAt:
            now,

          updatedAt:
            FieldValue.serverTimestamp(),

        },
        {
          merge: true,
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


      return {

        success: true,

        rewarded: true,

        duplicate: false,

        bonus,

        hashRateBefore:
          currentHashRate,

        hashRate:
          newHashRate,

        adsToday:
          newAdsToday,

        maxAdsPerDay:
          MAX_ADS_PER_DAY,

        cooldownMs:
          AD_COOLDOWN_MS,

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
// Vain testausta varten.
//
// Flutter kutsuu:
//
// testAdReward()
//
// ============================================================

const testAdReward =
  onCall(async (request) => {

    if (!request.auth) {

      throw new HttpsError(
        "unauthenticated",
        "🐱 Kirjaudu sisään saadaksesi Stella Power Boostin."
      );

    }


    const uid =
      request.auth.uid;


    const transactionId =
      `test_${uid}_${Date.now()}`;


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
// Google AdMob kutsuu tätä HTTP-endpointia,
// kun käyttäjä on ansainnut mainospalkinnon.
//
// ============================================================

const adMobReward =
  onRequest(async (req, res) => {

    try {

      // ======================================================
      // 🔐 VERIFY GOOGLE SIGNATURE
      // ======================================================

      await verifyAdMobCallback(
        req
      );


      // ======================================================
      // 👤 GET USER ID
      // ======================================================

      const uid =
        typeof req.query.user_id === "string"
          ? req.query.user_id
          : null;


      // ======================================================
      // 🔐 GET TRANSACTION ID
      // ======================================================

      const transactionId =
        typeof req.query.transaction_id === "string"
          ? req.query.transaction_id
          : null;


      // ======================================================
      // 🛡️ VALIDATE
      // ======================================================

      if (
        !uid ||
        !transactionId
      ) {

        res.status(400).send(
          "Missing user_id or transaction_id."
        );

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
      // 📤 SUCCESS
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

        success: false,

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