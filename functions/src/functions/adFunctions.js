"use strict";

// ============================================================
// 🐱 STELLA AD FUNCTIONS
// ============================================================
//
// Tämä tiedosto hallitsee:
//
// 📺 Test Ad Reward
// 🎁 Stella Power Boost
// ⚡ Väliaikainen Hash Rate -boost
// ⏳ 4 tunnin boost
// 🔢 Päivittäinen mainosraja
// 📜 Ad-tapahtumahistoria
// 🔐 AdMob SSV -callback
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
  AD_HASH_RATE_BONUS,
  AD_BOOST_DURATION_MS,
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
// 🕒 CONVERT FIRESTORE DATE TO MILLISECONDS
// ============================================================

function getTimestampMilliseconds(
  value
) {
  if (
    value &&
    typeof value.toDate === "function"
  ) {
    const date =
      value.toDate();

    return date.getTime();
  }

  if (
    value instanceof Date
  ) {
    return value.getTime();
  }

  if (
    typeof value === "string"
  ) {
    const parsedDate =
      new Date(value);

    if (
      !Number.isNaN(
        parsedDate.getTime()
      )
    ) {
      return parsedDate.getTime();
    }
  }

  return 0;
}


// ============================================================
// 📺 GET AD STATUS
// ============================================================
//
// Tarkistaa:
//
// • Päivittäisen mainosmäärän
// • Aktiivisen 4 h boostin
// • Cooldownin
// • Seuraavan mainoksen ajankohdan
//
// ============================================================

function getAdStatus(
  data,
  nowMs,
  today
) {
  // ==========================================================
  // 📅 STORED DATE
  // ==========================================================

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
  // ⏳ LAST AD REWARD
  // ==========================================================

  const lastAdRewardMs =
    getTimestampMilliseconds(
      data.lastAdRewardAt
    );


  // ==========================================================
  // ⏳ COOLDOWN
  // ==========================================================

  const cooldownRemainingMs =
    lastAdRewardMs > 0
      ? Math.max(
          0,
          (
            lastAdRewardMs +
            AD_COOLDOWN_MS
          ) -
          nowMs
        )
      : 0;


  // ==========================================================
  // ⚡ CURRENT AD BOOST
  // ==========================================================

  const adBoostHashRate =
    Math.max(
      0,
      getSafeNumber(
        data.adBoostHashRate,
        0
      )
    );


  // ==========================================================
  // ⏳ AD BOOST END
  // ==========================================================

  const adBoostEndsAtMs =
    getTimestampMilliseconds(
      data.adBoostEndsAt
    );


  const adBoostRemainingMs =
    adBoostEndsAtMs > nowMs
      ? adBoostEndsAtMs - nowMs
      : 0;


  // ==========================================================
  // ⚡ ACTIVE BOOST
  // ==========================================================

  const adBoostActive =
    adBoostHashRate > 0 &&
    adBoostRemainingMs > 0;


  // ==========================================================
  // 📺 CAN WATCH
  // ==========================================================
  //
  // Uusi mainos voidaan katsoa vasta,
  // kun edellinen 4 h boost on päättynyt.
  //
  // ==========================================================

  const canWatchAd =
    adsToday < MAX_ADS_PER_DAY &&
    adBoostRemainingMs === 0 &&
    cooldownRemainingMs === 0;


  // ==========================================================
  // 📦 RESULT
  // ==========================================================

  return {
    adsToday,

    maxAdsPerDay:
      MAX_ADS_PER_DAY,

    cooldownRemainingMs,

    adBoostHashRate,

    adBoostEndsAtMs,

    adBoostRemainingMs,

    adBoostActive,

    canWatchAd,
  };
}


// ============================================================
// 🎁 APPLY AD REWARD
// ============================================================
//
// Mainos:
//
// 📺 +0.5833 HR
// ⏳ 4 tunniksi
//
// Mainosboosti EI lisää pysyvästi käyttäjän Daily Hash Ratea.
//
// ============================================================

async function applyAdReward(
  uid,
  transactionId,
  rewardType
) {
  // ==========================================================
  // 🛡️ BASIC INPUT VALIDATION
  // ==========================================================

  if (
    typeof uid !== "string" ||
    uid.trim().length === 0
  ) {
    throw new Error(
      "Invalid user ID."
    );
  }

  if (
    typeof transactionId !== "string" ||
    transactionId.trim().length === 0
  ) {
    throw new Error(
      "Invalid transaction ID."
    );
  }


  // ==========================================================
  // 👤 USER
  // ==========================================================

  const userRef =
    getUserRef(uid);


  // ==========================================================
  // 🔐 REWARD RECORD
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
  // 🔥 FIRESTORE TRANSACTION
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


      if (
        rewardSnapshot.exists
      ) {
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
          ? userSnapshot.data() || {}
          : {};


      // ======================================================
      // 📺 CURRENT AD STATUS
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

          cooldownRemainingMs:
            0,

          adBoostRemainingMs:
            adStatus.adBoostRemainingMs,

          canWatchAd:
            false,

          message:
            "🐱📺 Päivän Stella Power Boost -raja on saavutettu.",
        };
      }


      // ======================================================
      // ⏳ ACTIVE BOOST
      // ======================================================

      if (
        adStatus.adBoostRemainingMs > 0
      ) {
        return {
          success:
            false,

          rewarded:
            false,

          duplicate:
            false,

          reason:
            "boost_active",

          adsToday:
            adStatus.adsToday,

          maxAdsPerDay:
            MAX_ADS_PER_DAY,

          cooldownRemainingMs:
            adStatus.cooldownRemainingMs,

          adBoostRemainingMs:
            adStatus.adBoostRemainingMs,

          canWatchAd:
            false,

          message:
            "🐱⏳ Stella Power Boost on vielä aktiivinen.",
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

          adBoostRemainingMs:
            0,

          canWatchAd:
            false,

          message:
            "🐱⏳ Stella Power Boost on vielä cooldownissa.",
        };
      }


      // ======================================================
      // ⚡ DAILY HASH RATE
      // ======================================================
      //
      // Daily Hash Rate on käyttäjän pysyvä
      // streak-pohjainen louhintateho.
      //
      // Mainos ei muuta tätä arvoa.
      //
      // ======================================================

      const dailyHashRate =
        Math.max(
          0,
          getSafeNumber(
            data.hashRate,
            0
          )
        );


      // ======================================================
      // 🎁 AD BOOST
      // ======================================================

      const bonus =
        Math.max(
          0,
          getSafeNumber(
            AD_HASH_RATE_BONUS,
            0
          )
        );


      // ======================================================
      // ⏳ BOOST TIMES
      // ======================================================

      const boostStartedAt =
        now;

      const boostEndsAt =
        new Date(
          nowMs +
          AD_BOOST_DURATION_MS
        );


      // ======================================================
      // ⚡ EFFECTIVE HASH RATE
      // ======================================================
      //
      // Daily Hash Rate + yksi aktiivinen mainosboost.
      //
      // Boostit eivät kasaannu.
      //
      // ======================================================

      const effectiveHashRate =
        dailyHashRate +
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
          // ==================================================
          // ⚡ DAILY HASH RATE
          // ==================================================
          //
          // Tätä EI kasvateta mainoksella.
          //
          hashRate:
            dailyHashRate,


          // ==================================================
          // 📺 AD BOOST
          // ==================================================

          adBoostHashRate:
            bonus,

          adBoostStartedAt:
            boostStartedAt,

          adBoostEndsAt:
            boostEndsAt,


          // ==================================================
          // 📺 DAILY AD COUNT
          // ==================================================

          lastAdDate:
            today,

          adsToday:
            newAdsToday,


          // ==================================================
          // ⏳ LAST AD
          // ==================================================

          lastAdRewardAt:
            now,


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

          dailyHashRate,

          effectiveHashRate,

          boostStartedAt,

          boostEndsAt,

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
            dailyHashRate,

          hashRateAfter:
            dailyHashRate,

          dailyHashRate,

          adBoostHashRate:
            bonus,

          effectiveHashRate,

          boostStartedAt,

          boostEndsAt,

          rewardType,

          adsToday:
            newAdsToday,

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


        // ====================================================
        // 🎁 BOOST
        // ====================================================

        bonus,

        adBoostHashRate:
          bonus,

        adBoostDurationMs:
          AD_BOOST_DURATION_MS,


        // ====================================================
        // ⚡ DAILY HASH RATE
        // ====================================================

        dailyHashRate,


        // ====================================================
        // ⚡ EFFECTIVE HASH RATE
        // ====================================================

        hashRate:
          effectiveHashRate,

        effectiveHashRate,


        // ====================================================
        // 📺 ADS
        // ====================================================

        adsToday:
          newAdsToday,

        maxAdsPerDay:
          MAX_ADS_PER_DAY,


        // ====================================================
        // ⏳ BOOST
        // ====================================================

        boostActive:
          true,

        boostRemainingMs:
          AD_BOOST_DURATION_MS,

        boostEndsAt:
          boostEndsAt.toISOString(),


        // ====================================================
        // ⏳ COOLDOWN
        // ====================================================

        cooldownRemainingMs:
          AD_COOLDOWN_MS,

        cooldownMs:
          AD_COOLDOWN_MS,


        // ====================================================
        // 📺 NEXT AD
        // ====================================================

        canWatchAd:
          false,


        // ====================================================
        // 🐱 MESSAGE
        // ====================================================

        message:
          `🐱📺⚡ Stella Power Boost +${bonus} HR 4 tunniksi!`,
      };
    }
  );
}


// ============================================================
// 🧪 TEST AD REWARD
// ============================================================
//
// Flutter käyttää tätä tällä hetkellä kehityksen aikana.
//
// Tätä EI ole tarkoitus käyttää tuotannossa.
// Poistamme tämän myöhemmin, kun oikea AdMob SSV -ketju
// on täysin testattu.
//
// ============================================================

const testAdReward =
  onCall(
    {
      region: "us-central1",
    },
    async (request) => {

      // ========================================================
      // 🔐 AUTH
      // ========================================================

      if (!request.auth) {
        throw new HttpsError(
          "unauthenticated",
          "🐱 Kirjaudu sisään saadaksesi Stella Power Boostin."
        );
      }


      // ========================================================
      // 👤 USER
      // ========================================================

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

      try {
        return await applyAdReward(
          uid,
          transactionId,
          "test"
        );

      } catch (error) {

        console.error(
          "testAdReward error:",
          error
        );


        if (
          error instanceof HttpsError
        ) {
          throw error;
        }


        throw new HttpsError(
          "internal",
          "🐱 Stella Power Boostin käsittely epäonnistui."
        );
      }
    }
  );


// ============================================================
// 🔐 ADMOB REWARD CALLBACK
// ============================================================
//
// Google AdMob SSV kutsuu tätä endpointia.
//
// TÄRKEÄÄ:
//
// AdMobin SSV-palvelu allekirjoittaa callbackin.
//
// Flutterissa asetimme:
//
// ServerSideVerificationOptions(
//   customData: Firebase UID,
// )
//
// Tämä tulee AdMobilta takaisin:
//
// custom_data=<Firebase UID>
//
// Koska koko SSV-kutsu on allekirjoitettu,
// backend voi käyttää tätä UID:tä palkinnon kohdentamiseen.
//
// ============================================================

const adMobReward =
  onRequest(
    {
      region: "us-central1",
    },
    async (req, res) => {

      try {

        // ======================================================
        // 🔐 VERIFY GOOGLE CALLBACK
        // ======================================================
        //
        // Tämä tarkistaa sekä:
        //
        // 1. AdMobin kryptografisen allekirjoituksen
        // 2. Oikean ad_unitin
        // 3. Oikean reward_amountin
        // 4. Oikean reward_itemin
        // 5. Pakolliset tunnisteet
        //
        // ======================================================

        const verifiedAd =
          await verifyAdMobCallback(
            req
          );


        // ======================================================
        // 👤 TRUSTED USER ID
        // ======================================================
        //
        // ÄLÄ käytä suoraan:
        //
        // req.query.user_id
        //
        // vaan AdMobin allekirjoittamaa custom_data-arvoa.
        //
        // ======================================================

        const uid =
          typeof verifiedAd.customData ===
              "string"
            ? verifiedAd.customData.trim()
            : "";


        // ======================================================
        // 🔐 TRANSACTION ID
        // ======================================================

        const transactionId =
          typeof verifiedAd.transactionId ===
              "string"
            ? verifiedAd.transactionId.trim()
            : "";


        // ======================================================
        // 🛡️ VALIDATE TRUSTED DATA
        // ======================================================

        if (!uid) {

          console.error(
            "AdMob SSV missing custom_data."
          );

          res.status(400).json({
            success:
              false,

            error:
              "Missing AdMob custom_data.",
          });

          return;
        }


        if (!transactionId) {

          console.error(
            "AdMob SSV missing transaction_id."
          );

          res.status(400).json({
            success:
              false,

            error:
              "Missing AdMob transaction_id.",
          });

          return;
        }


        // ======================================================
        // 🛡️ BASIC UID VALIDATION
        // ======================================================
        //
        // Firebase Auth UIDs normally contain a limited set
        // of characters. This prevents obviously malformed
        // values from being used as Firestore document paths.
        //
        // ======================================================

        if (
          uid.length > 128 ||
          !/^[A-Za-z0-9._:-]+$/.test(uid)
        ) {

          console.error(
            "Invalid AdMob custom_data UID."
          );

          res.status(400).json({
            success:
              false,

            error:
              "Invalid AdMob custom_data.",
          });

          return;
        }


        // ======================================================
        // 🛡️ TRANSACTION ID VALIDATION
        // ======================================================

        if (
          transactionId.length > 256
        ) {

          console.error(
            "Invalid AdMob transaction_id."
          );

          res.status(400).json({
            success:
              false,

            error:
              "Invalid AdMob transaction_id.",
          });

          return;
        }


        // ======================================================
        // 🔎 OPTIONAL CONSISTENCY CHECK
        // ======================================================
        //
        // Jos AdMob lähettää myös user_id:n, tarkistetaan
        // että se vastaa custom_dataa.
        //
        // Nykyinen Flutter-versio käyttää custom_dataa,
        // joten user_id voi olla tyhjä.
        //
        // ======================================================

        const callbackUserId =
          typeof verifiedAd.userId ===
              "string"
            ? verifiedAd.userId.trim()
            : "";


        if (
          callbackUserId &&
          callbackUserId !== uid
        ) {

          console.error(
            "AdMob user_id does not match custom_data."
          );

          res.status(400).json({
            success:
              false,

            error:
              "AdMob user identity mismatch.",
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


        // ======================================================
        // 🔐 SECURITY RESPONSE
        // ======================================================
        //
        // Emme paljasta asiakkaalle liikaa sisäisestä
        // palvelinlogiikasta.
        //
        // ======================================================

        res.status(400).json({
          success:
            false,

          error:
            "Invalid AdMob SSV callback.",
        });
      }
    }
  );


// ============================================================
// 📦 EXPORTS
// ============================================================

module.exports = {
  testAdReward,
  adMobReward,
};