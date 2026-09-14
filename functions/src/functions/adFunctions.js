"use strict";

// ============================================================
// 🐱 STELLA AD FUNCTIONS
// ============================================================
//
// Tämä tiedosto hallitsee:
//
// 🎁 Stella Power Boost
// ⛏️ Stella Mining Start
// ⚡ Väliaikainen Hash Rate -boost
// ⏳ 4 tunnin boost
// 🔢 Päivittäinen mainosraja
// 📜 Ad-tapahtumahistoria
// 🔐 AdMob SSV -callback
//
// ============================================================
//
// AdMob custom_data -muoto:
//
// UID:power_boost
// UID:mining_start
//
// Vanha pelkkä UID hyväksytään edelleen:
//
// UID → power_boost
//
// ============================================================


// ============================================================
// 🔥 FIREBASE FUNCTIONS
// ============================================================

const {
  onRequest,
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

    const milliseconds =
      date.getTime();

    return Number.isFinite(
      milliseconds
    )
      ? milliseconds
      : 0;
  }

  if (
    value instanceof Date
  ) {
    const milliseconds =
      value.getTime();

    return Number.isFinite(
      milliseconds
    )
      ? milliseconds
      : 0;
  }

  if (
    typeof value === "string"
  ) {
    const parsedDate =
      new Date(value);

    const milliseconds =
      parsedDate.getTime();

    return Number.isFinite(
      milliseconds
    )
      ? milliseconds
      : 0;
  }

  if (
    typeof value === "number" &&
    Number.isFinite(value)
  ) {
    return value;
  }

  return 0;
}


// ============================================================
// 🔐 PARSE ADMOB CUSTOM DATA
// ============================================================

function parseAdMobCustomData(
  customData
) {
  if (
    typeof customData !== "string"
  ) {
    return null;
  }

  const value =
    customData.trim();

  if (
    value.length === 0 ||
    value.length > 128
  ) {
    return null;
  }


  // ==========================================================
  // 🐱 VANHA MUOTO
  // ==========================================================

  if (
    !value.includes(":")
  ) {
    if (
      !/^[A-Za-z0-9._:-]+$/.test(value)
    ) {
      return null;
    }

    return {
      uid:
        value,

      rewardPurpose:
        "power_boost",
    };
  }


  // ==========================================================
  // 🎯 UUSI MUOTO
  // ==========================================================

  const separatorIndex =
    value.lastIndexOf(":");

  if (
    separatorIndex <= 0 ||
    separatorIndex >=
      value.length - 1
  ) {
    return null;
  }

  const uid =
    value.substring(
      0,
      separatorIndex
    );

  const rewardPurpose =
    value.substring(
      separatorIndex + 1
    );


  // ==========================================================
  // 🛡️ UID VALIDATION
  // ==========================================================

  if (
    uid.length === 0 ||
    uid.length > 128 ||
    !/^[A-Za-z0-9._:-]+$/.test(uid)
  ) {
    return null;
  }


  // ==========================================================
  // 🛡️ PURPOSE VALIDATION
  // ==========================================================

  if (
    rewardPurpose !== "power_boost" &&
    rewardPurpose !== "mining_start"
  ) {
    return null;
  }

  return {
    uid,
    rewardPurpose,
  };
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
      : "";


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


  const lastAdRewardMs =
    getTimestampMilliseconds(
      data.lastAdRewardAt
    );


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


  const adBoostHashRate =
    Math.max(
      0,
      getSafeNumber(
        data.adBoostHashRate,
        0
      )
    );


  const adBoostEndsAtMs =
    getTimestampMilliseconds(
      data.adBoostEndsAt
    );


  const adBoostRemainingMs =
    adBoostEndsAtMs > nowMs
      ? adBoostEndsAtMs - nowMs
      : 0;


  const adBoostActive =
    adBoostHashRate > 0 &&
    adBoostRemainingMs > 0;


  const canWatchAd =
    adsToday < MAX_ADS_PER_DAY &&
    adBoostRemainingMs === 0 &&
    cooldownRemainingMs === 0;


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
// 🎁 APPLY ADMOB REWARD
// ============================================================

async function applyAdReward(
  uid,
  transactionId,
  rewardType,
  adData = {},
  rewardPurpose = "power_boost"
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
  // 🔐 ONLY VERIFIED ADMOB
  // ==========================================================

  if (
    rewardType !== "admob"
  ) {
    throw new Error(
      "Only verified AdMob rewards are allowed."
    );
  }


  // ==========================================================
  // 🎯 VALIDATE PURPOSE
  // ==========================================================

  if (
    rewardPurpose !== "power_boost" &&
    rewardPurpose !== "mining_start"
  ) {
    throw new Error(
      "Invalid AdMob reward purpose."
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


      // ======================================================
      // 🛡️ USER MUST EXIST
      // ======================================================

      if (
        !userSnapshot.exists
      ) {
        throw new Error(
          "Stelluriini user does not exist."
        );
      }


      const data =
        userSnapshot.data() || {};


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
            "🐱📺 Päivän Stella-mainosraja on saavutettu.",
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
            "🐱⏳ Stella-mainoksen cooldown on vielä aktiivinen.",
        };
      }


      // ======================================================
      // ⚡ DAILY HASH RATE
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
      // 🔢 NEW AD COUNT
      // ======================================================

      const newAdsToday =
        adStatus.adsToday +
        1;


      // ======================================================
      // ⛏️ MINING START
      // ======================================================

      if (
        rewardPurpose === "mining_start"
      ) {

        // ----------------------------------------------------
        // 🔐 SAVE VERIFIED MINING START REWARD
        // ----------------------------------------------------

        transaction.set(
          rewardRef,
          {
            uid,

            transactionId,

            rewardType:
              "admob",

            rewardPurpose:
              "mining_start",

            adNetwork:
              typeof adData.adNetwork === "string"
                ? adData.adNetwork
                : "admob",

            adUnit:
              typeof adData.adUnit === "string"
                ? adData.adUnit
                : "",

            rewardAmount:
              getSafeNumber(
                adData.rewardAmount,
                0
              ),

            rewardItem:
              typeof adData.rewardItem === "string"
                ? adData.rewardItem
                : "",

            timestamp:
              getSafeNumber(
                adData.timestamp,
                nowMs
              ),

            keyId:
              typeof adData.keyId === "string"
                ? adData.keyId
                : "",

            customData:
              typeof adData.customData === "string"
                ? adData.customData
                : `${uid}:mining_start`,

            userId:
              typeof adData.userId === "string"
                ? adData.userId
                : "",

            miningClaimed:
              false,

            miningClaimedAt:
              null,

            miningStartClaimed:
              false,

            miningStartClaimedAt:
              null,

            miningStartClaimedBy:
              null,

            adsToday:
              newAdsToday,

            createdAt:
              FieldValue.serverTimestamp(),
          }
        );


        // ----------------------------------------------------
        // 👤 UPDATE USER
        // ----------------------------------------------------

        transaction.set(
          userRef,
          {
            hashRate:
              dailyHashRate,

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
            merge:
              true,
          }
        );


        // ----------------------------------------------------
        // 📜 HISTORY
        // ----------------------------------------------------

        const historyRef =
          getHistoryCollection(uid)
            .doc();


        transaction.set(
          historyRef,
          {
            type:
              "ad_reward",

            title:
              "Stella Mining Start 🐱⛏️📺",

            amount:
              0,

            hashRateBefore:
              dailyHashRate,

            hashRateAfter:
              dailyHashRate,

            dailyHashRate,

            rewardType:
              "admob",

            rewardPurpose:
              "mining_start",

            adMobTransactionId:
              transactionId,

            adsToday:
              newAdsToday,

            createdAt:
              FieldValue.serverTimestamp(),
          }
        );


        // ----------------------------------------------------
        // 📤 RESPONSE
        // ----------------------------------------------------

        return {
          success:
            true,

          rewarded:
            true,

          duplicate:
            false,

          reason:
            null,

          rewardPurpose:
            "mining_start",

          dailyHashRate,

          hashRate:
            dailyHashRate,

          effectiveHashRate:
            dailyHashRate,

          adsToday:
            newAdsToday,

          maxAdsPerDay:
            MAX_ADS_PER_DAY,

          cooldownRemainingMs:
            AD_COOLDOWN_MS,

          canWatchAd:
            false,

          miningStartReady:
            true,

          adRewardTransactionId:
            transactionId,

          message:
            "🐱⛏️ Stella Mining Start -mainos vahvistettu!",
        };
      }


      // ======================================================
      // 🎁 POWER BOOST
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

      const effectiveHashRate =
        dailyHashRate +
        bonus;


      // ======================================================
      // 👤 UPDATE USER
      // ======================================================

      transaction.set(
        userRef,
        {
          hashRate:
            dailyHashRate,

          adBoostHashRate:
            bonus,

          adBoostStartedAt:
            boostStartedAt,

          adBoostEndsAt:
            boostEndsAt,

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
          merge:
            true,
        }
      );


      // ======================================================
      // 🔐 SAVE VERIFIED POWER BOOST REWARD
      // ======================================================

      transaction.set(
        rewardRef,
        {
          uid,

          transactionId,

          rewardType:
            "admob",

          rewardPurpose:
            "power_boost",

          adNetwork:
            typeof adData.adNetwork === "string"
              ? adData.adNetwork
              : "admob",

          adUnit:
            typeof adData.adUnit === "string"
              ? adData.adUnit
              : "",

          rewardAmount:
            getSafeNumber(
              adData.rewardAmount,
              0
            ),

          rewardItem:
            typeof adData.rewardItem === "string"
              ? adData.rewardItem
              : "",

          timestamp:
            getSafeNumber(
              adData.timestamp,
              nowMs
            ),

          keyId:
            typeof adData.keyId === "string"
              ? adData.keyId
              : "",

          customData:
            typeof adData.customData === "string"
              ? adData.customData
              : `${uid}:power_boost`,

          userId:
            typeof adData.userId === "string"
              ? adData.userId
              : "",

          bonus,

          dailyHashRate,

          effectiveHashRate,

          boostStartedAt,

          boostEndsAt,

          miningClaimed:
            false,

          miningClaimedAt:
            null,

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

          rewardType:
            "admob",

          rewardPurpose:
            "power_boost",

          adMobTransactionId:
            transactionId,

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

        rewardPurpose:
          "power_boost",

        bonus,

        adBoostHashRate:
          bonus,

        adBoostDurationMs:
          AD_BOOST_DURATION_MS,

        dailyHashRate,

        hashRate:
          effectiveHashRate,

        effectiveHashRate,

        adsToday:
          newAdsToday,

        maxAdsPerDay:
          MAX_ADS_PER_DAY,

        boostActive:
          true,

        boostRemainingMs:
          AD_BOOST_DURATION_MS,

        boostEndsAt:
          boostEndsAt.toISOString(),

        cooldownRemainingMs:
          AD_COOLDOWN_MS,

        cooldownMs:
          AD_COOLDOWN_MS,

        canWatchAd:
          false,

        message:
          `🐱📺⚡ Stella Power Boost +${bonus} HR 4 tunniksi!`,
      };
    }
  );
}


// ============================================================
// 🔐 ADMOB REWARD CALLBACK
// ============================================================
//
// Google AdMob SSV kutsuu tätä endpointia.
//
// Varsinainen SSV-callback sisältää allekirjoitetut
// query-parametrit.
//
// AdMobin Verify URL -toimintoa varten endpoint käsittelee
// myös testicallbackin, jossa custom_data voi puuttua.
//
// TÄRKEÄÄ:
//
// - Verify URL -testi ei saa antaa käyttäjälle palkkiota.
// - Oikea tuotannon callback vaatii custom_data-arvon.
// - Oikea tuotannon callback käsitellään edelleen
//   verifyAdMobCallback()-tarkistuksen kautta.
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
        // 🔐 ALLOW GET + HEAD
        // ======================================================

        if (
          req.method !== "GET" &&
          req.method !== "HEAD"
        ) {
          res.status(405).json({
            success:
              false,

            error:
              "Method not allowed.",
          });

          return;
        }


        // ======================================================
        // 🩺 BASIC HEALTH CHECK
        // ======================================================

        const queryKeys =
          Object.keys(
            req.query || {}
          );


        if (
          queryKeys.length === 0
        ) {
          console.log(
            "🐱 AdMob SSV endpoint health check."
          );

          res.status(200).json({
            success:
              true,

            endpoint:
              "adMobReward",

            message:
              "Stelluriini AdMob SSV endpoint is reachable.",
          });

          return;
        }


        // ======================================================
        // 🧪 ADMOB VERIFY URL TEST
        // ======================================================
        //
        // AdMobin Verify URL -testissä custom_data voidaan
        // jättää tyhjäksi.
        //
        // Jos Google lähettää SSV-testipyynnön ilman
        // custom_data-parametria, emme saa yrittää antaa
        // palkkiota eikä pyytää Stelluriini-käyttäjää.
        //
        // Palautamme 200 OK, jotta AdMob voi vahvistaa
        // endpointin.
        //
        // Oikeassa Stelluriini-mainospyynnössä Flutter
        // lähettää aina:
        //
        // UID:power_boost
        //
        // tai:
        //
        // UID:mining_start
        //
        // ======================================================

        const hasCustomData =
          typeof req.query.custom_data ===
            "string" &&
          req.query.custom_data.trim()
            .length > 0;


        const hasSignature =
          typeof req.query.signature ===
            "string" &&
          req.query.signature.trim()
            .length > 0;


        const hasKeyId =
          typeof req.query.key_id ===
            "string" &&
          req.query.key_id.trim()
            .length > 0;


        if (
          !hasCustomData &&
          hasSignature &&
          hasKeyId
        ) {

          console.log(
            "🐱 AdMob Verify URL test detected without custom_data. No reward granted."
          );

          res.status(200).json({
            success:
              true,

            verificationOnly:
              true,

            rewarded:
              false,

            message:
              "Stelluriini AdMob SSV verification endpoint is reachable.",
          });

          return;
        }


        // ======================================================
        // 🔐 VERIFY GOOGLE CALLBACK
        // ======================================================

        const verifiedAd =
          await verifyAdMobCallback(
            req
          );


        // ======================================================
        // 🎯 PARSE CUSTOM DATA
        // ======================================================

        const parsedCustomData =
          parseAdMobCustomData(
            verifiedAd.customData
          );


        if (
          !parsedCustomData
        ) {

          console.error(
            "Invalid AdMob custom_data."
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
        // 👤 TRUSTED USER ID
        // ======================================================

        const uid =
          parsedCustomData.uid;


        // ======================================================
        // 🎯 REWARD PURPOSE
        // ======================================================

        const rewardPurpose =
          parsedCustomData.rewardPurpose;


        // ======================================================
        // 🔐 TRANSACTION ID
        // ======================================================

        const transactionId =
          typeof verifiedAd.transactionId ===
              "string"
            ? verifiedAd.transactionId.trim()
            : "";


        // ======================================================
        // 🛡️ VALIDATE TRANSACTION ID
        // ======================================================

        if (
          !transactionId
        ) {

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
        // 🛡️ OPTIONAL USER CONSISTENCY CHECK
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
            "AdMob user_id does not match custom_data UID."
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
        // 🎁 APPLY VERIFIED ADMOB REWARD
        // ======================================================

        const result =
          await applyAdReward(
            uid,
            transactionId,
            "admob",
            {
              adNetwork:
                verifiedAd.adNetwork,

              adUnit:
                verifiedAd.adUnit,

              rewardAmount:
                verifiedAd.rewardAmount,

              rewardItem:
                verifiedAd.rewardItem,

              timestamp:
                verifiedAd.timestamp,

              keyId:
                verifiedAd.keyId,

              customData:
                verifiedAd.customData,

              userId:
                verifiedAd.userId,
            },
            rewardPurpose
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
  adMobReward,
};