"use strict";

// ============================================================
// 🐱 STELLA AD FUNCTIONS
// ============================================================
//
// AdMob SSV:n tehtävä:
//
// 📺 Vastaanottaa AdMob SSV callbackin
// 🔐 Tarkistaa allekirjoituksen
// 🆔 Tunnistaa käyttäjän
// 🎯 Tunnistaa rewardin käyttötarkoituksen
// 💾 Tallentaa vahvistetun rewardin admobRewards-kokoelmaan
//
// TÄRKEÄ:
//
// AdMob SSV EI aktivoi Power Boostia.
//
// AdMob SSV
//      ↓
// admobRewards/{transactionId}
//      ↓
// Flutter
//      ↓
// powerBoost()
//      ↓
// 4 h Power Boost
//
// Sama periaate koskee Mining Startia.
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
// 🔐 DECODE CUSTOM DATA
// ============================================================
//
// AdMob custom_data voi saapua URL-koodattuna.
//
// Esimerkiksi:
//
// UID%3Amining_start
//
// muuttuu:
//
// UID:mining_start
//
// Jos arvo ei ole URL-koodattu, se palautetaan sellaisenaan.
//
// ============================================================

function decodeCustomData(
  value
) {
  if (
    typeof value !== "string"
  ) {
    return "";
  }

  const trimmed =
    value.trim();

  if (
    trimmed.length === 0
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
// 🔐 PARSE ADMOB CUSTOM DATA
// ============================================================
//
// Uusi muoto:
//
// UID:power_boost
// UID:mining_start
//
// Vanha muoto:
//
// UID
//
// Vanha pelkkä UID tulkitaan Power Boostiksi.
//
// ============================================================

function parseAdMobCustomData(
  customData
) {
  const decoded =
    decodeCustomData(
      customData
    );

  if (
    decoded.length === 0 ||
    decoded.length > 128
  ) {
    return null;
  }

  // ==========================================================
  // 🐱 VANHA MUOTO: PELKKÄ UID
  // ==========================================================

  if (
    !decoded.includes(":")
  ) {
    if (
      !/^[A-Za-z0-9._-]+$/.test(
        decoded
      )
    ) {
      return null;
    }

    return {
      uid:
        decoded,

      rewardPurpose:
        "power_boost",
    };
  }

  // ==========================================================
  // 🎯 UUSI MUOTO
  // ==========================================================

  const separatorIndex =
    decoded.lastIndexOf(":");

  if (
    separatorIndex <= 0 ||
    separatorIndex >=
      decoded.length - 1
  ) {
    return null;
  }

  const uid =
    decoded.substring(
      0,
      separatorIndex
    );

  const rewardPurpose =
    decoded.substring(
      separatorIndex + 1
    );

  // ==========================================================
  // 🛡️ UID VALIDATION
  // ==========================================================

  if (
    uid.length === 0 ||
    uid.length > 128 ||
    !/^[A-Za-z0-9._-]+$/.test(
      uid
    )
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
// 🔐 VALIDATE TRANSACTION ID
// ============================================================

function validateTransactionId(
  value
) {
  if (
    typeof value !== "string"
  ) {
    return "";
  }

  const transactionId =
    value.trim();

  if (
    transactionId.length === 0 ||
    transactionId.length > 256
  ) {
    return "";
  }

  return transactionId;
}

// ============================================================
// 🔐 SAVE VERIFIED ADMOB REWARD
// ============================================================
//
// Tämä funktio tekee VAIN tämän:
//
// AdMob SSV
//      ↓
// admobRewards/{transactionId}
//
// Se EI aktivoi boostia.
// Se EI muuta adsToday-arvoa.
// Se EI muuta cooldownia.
// Se EI muuta mining-tilaa.
//
// Näistä asioista vastaa powerBoost() / claimMining().
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

  const userRef =
    getUserRef(uid);

  const now =
    new Date();

  return await db.runTransaction(
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
          `🐱 AdMob transaction already exists: ${transactionId}`
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
      // 👤 USER
      // ======================================================

      const userSnapshot =
        await transaction.get(
          userRef
        );

      if (
        !userSnapshot.exists
      ) {
        console.log(
          `🐱 users/${uid} does not exist. Creating user document.`
        );
      }

      // ======================================================
      // 🎯 REWARD DATA
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

      const customData =
        typeof verifiedAd.customData ===
          "string"
          ? verifiedAd.customData
          : `${uid}:${rewardPurpose}`;

      const userId =
        typeof verifiedAd.userId ===
          "string"
          ? verifiedAd.userId
          : "";

      // ======================================================
      // 💾 SAVE REWARD
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
      // Historia kertoo, että AdMob-palkinto vastaanotettiin.
      //
      // Se EI tarkoita vielä Power Boostin aktivointia.
      //
      // ======================================================

      const historyRef =
        getHistoryCollection(uid)
          .doc();

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
      // 📤 RESPONSE
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
// 🔐 ADMOB REWARD CALLBACK
// ============================================================
//
// Google AdMob SSV kutsuu tätä endpointia.
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
        // AdMob Verify URL voi lähettää callbackin ilman
        // custom_dataa.
        //
        // Tässä tapauksessa:
        //
        // ✅ tarkistetaan endpointin saavutettavuus
        // ❌ EI anneta palkkiota
        //
        // ======================================================

        const hasCustomData =
          typeof req.query.custom_data ===
            "string" &&
          req.query.custom_data
            .trim()
            .length > 0;

        const hasSignature =
          typeof req.query.signature ===
            "string" &&
          req.query.signature
            .trim()
            .length > 0;

        const hasKeyId =
          typeof req.query.key_id ===
            "string" &&
          req.query.key_id
            .trim()
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
        // 🛡️ VERIFY RESULT CHECK
        // ======================================================
        //
        // verifyAdMobCallback() voi palauttaa:
        //
        // {
        //   verified: false,
        //   error: "..."
        // }
        //
        // Tätä ei saa käsitellä normaalina verifiedAd-objektina.
        //
        // ======================================================

        if (
          !verifiedAd ||
          verifiedAd.verified === false
        ) {

          const verificationError =
            verifiedAd &&
            typeof verifiedAd.error ===
              "string"
              ? verifiedAd.error
              : "AdMob SSV verification failed.";

          console.error(
            "❌ AdMob SSV verification failed:",
            verificationError
          );

          // ----------------------------------------------------
          // 🔐 Emme anna palkkiota.
          //
          // Virheellinen allekirjoitus ei saa koskaan päästä
          // reward-järjestelmään.
          //
          // ----------------------------------------------------

          res.status(400).json({
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
        // 🎯 GET CUSTOM DATA
        // ======================================================
        //
        // Ensisijainen kenttä on customData.
        //
        // Fallback custom_data tukee mahdollisia palvelukerroksen
        // nimeämiseroja.
        //
        // ======================================================

        const customData =
          typeof verifiedAd.customData ===
            "string"
            ? verifiedAd.customData
            : typeof verifiedAd.custom_data ===
                "string"
                ? verifiedAd.custom_data
                : "";

        // ======================================================
        // 🔎 DEBUG LOG
        // ======================================================
        //
        // Ei kirjata käyttäjän rewardia tai muita arkaluontoisia
        // tietoja enempää kuin tarpeellista.
        //
        // ======================================================

        console.log(
          "🐱 AdMob verified custom_data received:",
          customData
            ? "present"
            : "missing"
        );

        // ======================================================
        // 🎯 PARSE CUSTOM DATA
        // ======================================================

        const parsedCustomData =
          parseAdMobCustomData(
            customData
          );

        if (
          !parsedCustomData
        ) {

          console.error(
            "❌ Invalid AdMob custom_data."
          );

          // ----------------------------------------------------
          // TÄRKEÄ:
          //
          // Custom_data on pysyvästi virheellinen callbackin
          // sisältö. HTTP 400 aiheuttaisi AdMobilta uusia
          // callback-yrityksiä.
          //
          // Kuittaamme callbackin vastaanotetuksi ilman
          // palkkiota.
          //
          // ----------------------------------------------------

          res.status(200).json({
            success:
              false,

            verified:
              true,

            rewarded:
              false,

            ignored:
              true,

            error:
              "Invalid AdMob custom_data. No reward granted.",
          });

          return;
        }

        // ======================================================
        // 👤 USER ID
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
          validateTransactionId(
            verifiedAd.transactionId
          );

        if (
          !transactionId
        ) {

          console.error(
            "❌ AdMob SSV missing transaction_id."
          );

          // ----------------------------------------------------
          // Transaction ID puuttuu.
          //
          // Tätä callbackia ei voida turvallisesti tallentaa.
          //
          // ----------------------------------------------------

          res.status(200).json({
            success:
              false,

            verified:
              true,

            rewarded:
              false,

            ignored:
              true,

            error:
              "Missing AdMob transaction_id. No reward granted.",
          });

          return;
        }

        // ======================================================
        // 🛡️ USER ID CONSISTENCY
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
            "❌ AdMob user_id does not match custom_data UID."
          );

          // ----------------------------------------------------
          // Turvallisuussyistä ei anneta rewardia.
          // Callback kuitataan, jotta virheellinen request ei
          // synnytä loputonta retry-ketjua.
          // ----------------------------------------------------

          res.status(200).json({
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
        // 📺 LOG VERIFIED AD
        // ======================================================

        console.log(
          "🐱 Verified AdMob reward:",
          {
            uid,
            transactionId,
            rewardPurpose,
            adUnit:
              verifiedAd.adUnit,
            rewardAmount:
              verifiedAd.rewardAmount,
            rewardItem:
              verifiedAd.rewardItem,
            keyId:
              verifiedAd.keyId,
          }
        );

        // ======================================================
        // 💾 SAVE VERIFIED REWARD
        // ======================================================

        const result =
          await saveVerifiedAdMobReward(
            uid,
            transactionId,
            verifiedAd,
            rewardPurpose
          );

        // ======================================================
        // 📤 RESPONSE
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

        res.status(200).json(
          result
        );

      } catch (
        error
      ) {

        console.error(
          "❌ AdMob reward verification failed:",
          error
        );

        // ======================================================
        // ❗ SERVER ERROR
        // ======================================================
        //
        // Todellinen palvelinvirhe palautetaan 400, jotta
        // callbackia ei kuitata onnistuneeksi silloin kun
        // rewardia ei ole pystytty turvallisesti käsittelemään.
        //
        // ======================================================

        res.status(400).json({
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