"use strict";

// ============================================================
// 🐱 STELLA AD FUNCTIONS
// ============================================================
//
// Stelluriini AdMob SSV -vastaanotto.
//
// Vastuu:
//
// 📺 Vastaanottaa AdMob SSV callbackin
// 🔐 Luottaa vain admobService.js:n suorittamaan
//    kryptografiseen allekirjoituksen tarkistukseen
// 🆔 Tunnistaa käyttäjän
// 🎯 Tunnistaa rewardin käyttötarkoituksen
// 💾 Tallentaa vahvistetun rewardin admobRewards-kokoelmaan
//
// TÄRKEÄ ARKKITEHTUURI:
//
// AdMob SSV
//      ↓
// admobService.verifyAdMobCallback()
//      ↓
// allekirjoitus + parametrien validointi
//      ↓
// admobRewards/{transactionId}
//      ↓
// Flutter
//      ↓
// powerBoost() / miningStart()
//
// Tämä tiedosto EI:
//
// ❌ aktivoi Power Boostia
// ❌ käynnistä Mining Startia
// ❌ lisää STL-saldoa
// ❌ muuta adsToday-arvoa
// ❌ muuta cooldownia
// ❌ muuta mining-tilaa
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
// 👤 USER UTILITIES
// ============================================================

const {
  getHistoryCollection,
  getAdMobRewardRef,
} = require(
  "../utils/userUtils"
);


// ============================================================
// 🔐 ADMOB SERVICE
// ============================================================
//
// KAIKKI SSV:n kryptografinen tarkistus tehdään täällä.
//
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

  if (
    !Number.isFinite(
      number
    )
  ) {
    return fallback;
  }

  return number;
}


// ============================================================
// 🔐 DECODE CUSTOM DATA
// ============================================================
//
// Google kertoo, että custom_data voi olla
// percent-escaped / URL-koodattu.
//
// Tämä tehdään vasta sen jälkeen,
// kun admobService on tarkistanut allekirjoituksen.
//
// ============================================================

function decodeCustomData(
  value
) {
  if (
    typeof value !==
    "string"
  ) {
    return "";
  }

  const trimmed =
    value.trim();

  if (
    trimmed.length ===
    0
  ) {
    return "";
  }

  try {
    return decodeURIComponent(
      trimmed
    ).trim();
  } catch (
    error
  ) {
    console.error(
      "❌ Failed to decode AdMob custom_data:",
      error.message
    );

    return "";
  }
}


// ============================================================
// 🔐 VALIDATE TRANSACTION ID
// ============================================================
//
// AdMob dokumentoi transaction_id:n hex-enkoodatuksi
// yksilölliseksi reward-tunnisteeksi.
//
// ============================================================

function validateTransactionId(
  value
) {
  if (
    typeof value !==
    "string"
  ) {
    return "";
  }

  const transactionId =
    value.trim();

  if (
    transactionId.length ===
      0 ||
    transactionId.length >
      256
  ) {
    return "";
  }

  if (
    !/^[a-fA-F0-9]+$/.test(
      transactionId
    )
  ) {
    return "";
  }

  return transactionId;
}


// ============================================================
// 💾 SAVE VERIFIED ADMOB REWARD
// ============================================================
//
// Tämä funktio tekee VAIN:
//
// AdMob SSV
//      ↓
// admobRewards/{transactionId}
//
// Varsinaiset pelitoiminnot tehdään muualla.
//
// ============================================================

async function saveVerifiedAdMobReward(
  uid,
  transactionId,
  verifiedAd,
  rewardPurpose
) {
  const rewardRef =
    getAdMobRewardRef(
      transactionId
    );

  const now =
    new Date();

  return db.runTransaction(
    async (
      transaction
    ) => {

      // ======================================================
      // 🔐 DUPLICATE CHECK
      // ======================================================

      const existingSnapshot =
        await transaction.get(
          rewardRef
        );

      if (
        existingSnapshot.exists
      ) {
        console.log(
          "🐱 AdMob transaction already exists:",
          transactionId
        );

        return {
          success:
            true,

          rewarded:
            false,

          duplicate:
            true,

          transactionId,

          rewardPurpose,

          message:
            "🐱📺 Tämä AdMob-palkinto on jo vastaanotettu.",
        };
      }


      // ======================================================
      // 🎁 REWARD DATA
      // ======================================================

      const rewardAmount =
        getSafeNumber(
          verifiedAd.rewardAmount,
          0
        );

      const rewardItem =
        typeof verifiedAd.rewardItem ===
          "string"
          ? verifiedAd.rewardItem
          : "";

      const adUnit =
        typeof verifiedAd.adUnit ===
          "string"
          ? verifiedAd.adUnit
          : "";

      const adNetwork =
        typeof verifiedAd.adNetwork ===
          "string"
          ? verifiedAd.adNetwork
          : "admob";

      const timestamp =
        getSafeNumber(
          verifiedAd.timestamp,
          now.getTime()
        );

      const keyId =
        typeof verifiedAd.keyId ===
          "string"
          ? verifiedAd.keyId
          : "";


      // ======================================================
      // 🔐 CUSTOM DATA
      // ======================================================

      const customData =
        typeof verifiedAd.customData ===
          "string"
          ? decodeCustomData(
              verifiedAd.customData
            )
          : "";


      // ======================================================
      // 👤 CALLBACK USER ID
      // ======================================================

      const userId =
        typeof verifiedAd.userId ===
          "string"
          ? verifiedAd.userId
          : "";


      // ======================================================
      // 💾 SAVE VERIFIED REWARD
      // ======================================================

      transaction.set(
        rewardRef,
        {
          uid,

          transactionId,

          rewardType:
            "admob",

          rewardPurpose,

          adNetwork,

          adUnit,

          rewardAmount,

          rewardItem,

          timestamp,

          keyId,

          customData,

          userId,

          // --------------------------------------------------
          // ⛏️ MINING START
          // --------------------------------------------------

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

          // --------------------------------------------------
          // ⚡ POWER BOOST
          // --------------------------------------------------

          powerBoostClaimed:
            false,

          powerBoostClaimedAt:
            null,

          powerBoostClaimedBy:
            null,

          // --------------------------------------------------
          // 🕒 SERVER TIME
          // --------------------------------------------------

          createdAt:
            FieldValue.serverTimestamp(),
        }
      );


      // ======================================================
      // 📜 HISTORY
      // ======================================================
      //
      // Tämä historia kertoo VAIN:
      //
      // "AdMob reward vastaanotettiin ja vahvistettiin."
      //
      // Se ei tarkoita, että Power Boost olisi aktivoitu.
      //
      // ======================================================

      const historyRef =
        getHistoryCollection(
          uid
        ).doc();

      transaction.set(
        historyRef,
        {
          type:
            "admob_verified",

          title:
            rewardPurpose ===
              "power_boost"
              ? "Stella Power Boost Ad Verified 🐱📺⚡"
              : "Stella Mining Start Ad Verified 🐱📺⛏️",

          amount:
            0,

          rewardType:
            "admob",

          rewardPurpose,

          adMobTransactionId:
            transactionId,

          adNetwork,

          adUnit,

          rewardAmount,

          rewardItem,

          createdAt:
            FieldValue.serverTimestamp(),
        }
      );


      // ======================================================
      // 📤 RESULT
      // ======================================================

      return {
        success:
          true,

        rewarded:
          true,

        duplicate:
          false,

        transactionId,

        rewardPurpose,

        rewardAmount,

        rewardItem,

        message:
          rewardPurpose ===
            "power_boost"
            ? "🐱📺 Power Boost -mainos vahvistettu ja palkkio tallennettu."
            : "🐱📺 Mining Start -mainos vahvistettu ja palkkio tallennettu.",
      };
    }
  );
}


// ============================================================
// 📺 ADMOB REWARD CALLBACK
// ============================================================
//
// Google AdMob kutsuu tätä HTTP endpointia.
//
// ============================================================

const adMobReward =
  onRequest(
    {
      region:
        "us-central1",
    },

    async (
      req,
      res
    ) => {

      try {

        // ======================================================
        // 🔐 ALLOW GET + HEAD
        // ======================================================

        if (
          req.method !==
            "GET" &&
          req.method !==
            "HEAD"
        ) {
          res.status(
            405
          ).json({
            success:
              false,

            error:
              "Method not allowed.",
          });

          return;
        }


        // ======================================================
        // 🔍 QUERY KEYS
        // ======================================================

        const queryKeys =
          Object.keys(
            req.query || {}
          );


        // ======================================================
        // 🩺 BASIC HEALTH CHECK
        // ======================================================

        if (
          queryKeys.length ===
          0
        ) {
          console.log(
            "🐱 AdMob SSV endpoint health check."
          );

          res.status(
            200
          ).json({
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
        // AdMobin Verify URL -testissä ei välttämättä ole
        // custom_dataa.
        //
        // Tällöin endpointin saavutettavuus voidaan vahvistaa,
        // mutta rewardia EI tallenneta.
        //
        // ======================================================

        const hasCustomData =
          typeof req.query.custom_data ===
            "string" &&
          req.query.custom_data
            .trim()
            .length >
            0;

        const hasSignature =
          typeof req.query.signature ===
            "string" &&
          req.query.signature
            .trim()
            .length >
            0;

        const hasKeyId =
          typeof req.query.key_id ===
            "string" &&
          req.query.key_id
            .trim()
            .length >
            0;

        if (
          !hasCustomData &&
          hasSignature &&
          hasKeyId
        ) {
          console.log(
            "🐱 AdMob Verify URL test detected without custom_data. No reward granted."
          );

          res.status(
            200
          ).json({
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
        // 🔐 VERIFY ADMOB CALLBACK
        // ======================================================

        console.log(
          "🐱 AdMob SSV callback received."
        );

        console.log(
          "🐱 AdMob SSV query keys:",
          queryKeys
        );

        const verifiedAd =
          await verifyAdMobCallback(
            req
          );


        // ======================================================
        // 🛡️ VERIFY RESULT
        // ======================================================

        if (
          !verifiedAd ||
          verifiedAd.verified !==
            true
        ) {
          console.error(
            "❌ AdMob SSV verification failed."
          );

          res.status(
            400
          ).json({
            success:
              false,

            verified:
              false,

            rewarded:
              false,

            error:
              "Invalid AdMob SSV callback.",
          });

          return;
        }


        // ======================================================
        // 🔐 VERIFIED CUSTOM DATA
        // ======================================================
        //
        // admobService on jo vahvistanut allekirjoituksen.
        //
        // Tässä vaiheessa custom_data voidaan käsitellä.
        //
        // ======================================================

        const customData =
          decodeCustomData(
            verifiedAd.customData
          );

        if (
          customData.length ===
          0
        ) {
          console.error(
            "❌ AdMob SSV custom_data is missing."
          );

          res.status(
            200
          ).json({
            success:
              false,

            verified:
              true,

            rewarded:
              false,

            ignored:
              true,

            error:
              "Missing AdMob custom_data. No reward granted.",
          });

          return;
        }


        // ======================================================
        // 👤 VERIFIED UID
        // ======================================================

        const uid =
          typeof verifiedAd.uid ===
            "string"
            ? verifiedAd.uid.trim()
            : "";

        if (
          uid.length ===
          0
        ) {
          console.error(
            "❌ AdMob verified UID is missing."
          );

          res.status(
            200
          ).json({
            success:
              false,

            verified:
              true,

            rewarded:
              false,

            ignored:
              true,

            error:
              "Missing verified user ID. No reward granted.",
          });

          return;
        }


        // ======================================================
        // 🎯 REWARD PURPOSE
        // ======================================================

        const rewardPurpose =
          typeof verifiedAd.rewardPurpose ===
            "string"
            ? verifiedAd.rewardPurpose
            : "";

        if (
          rewardPurpose !==
            "power_boost" &&
          rewardPurpose !==
            "mining_start"
        ) {
          console.error(
            "❌ Invalid verified AdMob reward purpose:",
            rewardPurpose
          );

          res.status(
            200
          ).json({
            success:
              false,

            verified:
              true,

            rewarded:
              false,

            ignored:
              true,

            error:
              "Invalid AdMob reward purpose. No reward granted.",
          });

          return;
        }


        // ======================================================
        // 🔐 TRANSACTION ID
        // ======================================================

        const transactionId =
          validateTransactionId(
            verifiedAd.transactionId
          );

        if (
          !transactionId
        ) {
          console.error(
            "❌ AdMob SSV transaction_id is missing or invalid."
          );

          res.status(
            200
          ).json({
            success:
              false,

            verified:
              true,

            rewarded:
              false,

            ignored:
              true,

            error:
              "Invalid AdMob transaction_id. No reward granted.",
          });

          return;
        }


        // ======================================================
        // 👤 USER ID CONSISTENCY
        // ======================================================

        const callbackUserId =
          typeof verifiedAd.userId ===
            "string"
            ? verifiedAd.userId.trim()
            : "";

        if (
          callbackUserId &&
          callbackUserId !==
            uid
        ) {
          console.error(
            "❌ AdMob user_id does not match verified custom_data UID."
          );

          res.status(
            200
          ).json({
            success:
              false,

            verified:
              true,

            rewarded:
              false,

            ignored:
              true,

            error:
              "AdMob user identity mismatch. No reward granted.",
          });

          return;
        }


        // ======================================================
        // 📺 NORMALIZED VERIFIED AD
        // ======================================================
        //
        // Tähän kopioidaan vain jo varmennetut arvot.
        //
        // Ei rakenneta allekirjoitettavaa sisältöä uudelleen.
        //
        // ======================================================

        const normalizedVerifiedAd = {
          verified:
            true,

          uid,

          rewardPurpose,

          transactionId,

          customData,

          userId:
            callbackUserId || uid,

          rewardAmount:
            verifiedAd.rewardAmount,

          rewardItem:
            verifiedAd.rewardItem,

          adUnit:
            verifiedAd.adUnit,

          adNetwork:
            verifiedAd.adNetwork,

          timestamp:
            verifiedAd.timestamp,

          keyId:
            verifiedAd.keyId,
        };


        // ======================================================
        // 📺 LOG VERIFIED AD
        // ======================================================

        console.log(
          "🐱 Verified AdMob reward:",
          {
            uid,

            transactionId,

            rewardPurpose,

            adUnit:
              normalizedVerifiedAd.adUnit,

            rewardAmount:
              normalizedVerifiedAd.rewardAmount,

            rewardItem:
              normalizedVerifiedAd.rewardItem,

            keyId:
              normalizedVerifiedAd.keyId,
          }
        );


        // ======================================================
        // 💾 SAVE VERIFIED REWARD
        // ======================================================

        const result =
          await saveVerifiedAdMobReward(
            uid,

            transactionId,

            normalizedVerifiedAd,

            rewardPurpose
          );


        // ======================================================
        // 📤 SUCCESS RESPONSE
        // ======================================================

        console.log(
          "🐱 AdMob SSV processed successfully:",
          {
            uid,

            transactionId,

            rewardPurpose,

            duplicate:
              result.duplicate,
          }
        );

        res.status(
          200
        ).json(
          result
        );

      } catch (
        error
      ) {

        // ======================================================
        // ❌ ERROR
        // ======================================================

        console.error(
          "❌ AdMob reward verification failed:",
          error
        );

        res.status(
          400
        ).json({
          success:
            false,

          verified:
            false,

          rewarded:
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