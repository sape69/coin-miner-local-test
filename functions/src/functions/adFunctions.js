"use strict";

// ============================================================
// 🐱 STELLURIINI - AD FUNCTIONS
// ============================================================
//
// AdMob Rewarded SSV callback.
//
// Vastuu:
//
// 📺 Vastaanottaa AdMob SSV callbackin
// 🔐 Varmistaa callbackin admobService.js:n kautta
// 🆔 Käyttää vain varmennettua UID:tä
// 🎯 Tunnistaa reward purposen
// 💾 Tallentaa varmennetun AdMob-tapahtuman
// 🛡️ Estää transaction_id:n uudelleenkäytön
//
// TÄMÄ TIEDOSTO EI:
//
// ❌ käynnistä Mining Startia
// ❌ aktivoi Power Boostia
// ❌ lisää STL-saldoa
// ❌ muuta miningBalancea
// ❌ muuta adsToday-arvoa
// ❌ muuta cooldownia
// ❌ muuta mining-tilaa
//
// Varsinainen Mining / Power Boost -business-logiikka
// kuuluu:
//
// functions/src/functions/miningFunctions.js
//
// AdMob SSV:n kryptografinen varmennus kuuluu:
//
// functions/src/services/admobService.js
//
// ============================================================


// ============================================================
// 🔥 FIREBASE FUNCTIONS
// ============================================================

const {
  onRequest,
} = require(
  "firebase-functions/v2/https",
);


// ============================================================
// 🔥 FIREBASE
// ============================================================

const {
  db,
  FieldValue,
} = require(
  "../firebase/firebase",
);


// ============================================================
// ⚙️ ADMOB SERVICE
// ============================================================
//
// Keskitetty AdMob-konfiguraatio ja SSV-validointi.
//
// ============================================================

const {
  verifyAdMobCallback,

  ADMOB_AD_UNITS,

  REWARD_DEFINITIONS,

  getExpectedAdMobConfig:
    getServiceExpectedAdMobConfig,

  validateTransactionId:
    validateServiceTransactionId,

  validateUid:
    validateServiceUid,

  validateAdNetwork:
    validateServiceAdNetwork,
} = require(
  "../services/admobService",
);


// ============================================================
// 👤 USER UTILITIES
// ============================================================

const {
  getHistoryCollection,
  getAdMobRewardRef,
} = require(
  "../utils/userUtils",
);


// ============================================================
// 🎯 VALID REWARD PURPOSES
// ============================================================

const VALID_REWARD_PURPOSES =
  new Set([
    "mining_start",
    "power_boost",
  ]);


// ============================================================
// 🛡️ CLIENT VALIDATION ERROR CODES
// ============================================================
//
// Näissä tapauksissa callback tai sen allekirjoitettu sisältö
// on pysyvästi virheellinen.
//
// HTTP 200 kuittaa callbackin eikä aiheuta turhaa retryä.
//
// ============================================================

const CLIENT_VALIDATION_ERROR_CODES =
  new Set([
    "ADMOB_INVALID_SIGNATURE",
    "ADMOB_INVALID_KEY_ID",
    "ADMOB_REQUEST_MISSING",
    "ADMOB_QUERY_STRING_MISSING",
    "ADMOB_INVALID_UID",
    "ADMOB_INVALID_REWARD_PURPOSE",
    "ADMOB_INVALID_TRANSACTION_ID",
    "ADMOB_INVALID_TIMESTAMP",
    "ADMOB_INVALID_AD_NETWORK",
    "ADMOB_REQUIRED_PARAMETER_MISSING",
    "ADMOB_VERIFIED_DATA_MISSING",
    "ADMOB_USER_ID_MISMATCH",
    "ADMOB_CUSTOM_DATA_MISSING",

    "ADMOB_INVALID_AD_UNIT",
    "ADMOB_INVALID_REWARD_ITEM",
    "ADMOB_INVALID_REWARD_AMOUNT",

    // --------------------------------------------------------
    // Sama transaction_id eri allekirjoitetulla datalla
    // tarkoittaa pysyvää turvallisuuskonfliktia.
    // --------------------------------------------------------

    "ADMOB_TRANSACTION_CONFLICT",
  ]);


// ============================================================
// 🔄 SERVER / CONFIG / RETRY ERROR CODES
// ============================================================
//
// Näissä tapauksissa callback voi olla kryptografisesti
// validi, mutta palvelimessa, Firestoressa, public key
// -haussa tai konfiguraatiossa on ongelma.
//
// HTTP 500 mahdollistaa AdMobin retry-käsittelyn.
//
// ============================================================

const SERVER_RETRY_ERROR_CODES =
  new Set([
    "ADMOB_PUBLIC_KEY_FETCH_ERROR",
    "ADMOB_PUBLIC_KEY_HTTP_ERROR",
    "ADMOB_PUBLIC_KEY_JSON_ERROR",
    "ADMOB_PUBLIC_KEY_RESPONSE_INVALID",
    "ADMOB_PUBLIC_KEYS_EMPTY",
    "ADMOB_PUBLIC_KEY_NOT_FOUND",
    "ADMOB_CRYPTO_VERIFICATION_ERROR",

    "ADMOB_REWARD_REFERENCE_ERROR",
    "ADMOB_HISTORY_REFERENCE_ERROR",

    "ADMOB_INVALID_REWARD_CONFIGURATION",

    "ADMOB_AUDIT_CONSISTENCY_ERROR",
  ]);


// ============================================================
// 🔐 NORMALIZE STRING
// ============================================================

function normalizeString(
  value,
) {
  if (
    typeof value !==
    "string"
  ) {
    return "";
  }

  return value.trim();
}


// ============================================================
// 🛡️ VALIDATE UID
// ============================================================
//
// Keskitetty varsinainen UID-validointi tulee admobService.js:stä.
//
// Tämä wrapper pitää adFunctions.js:n API:n vakaana ja tekee
// defense-in-depth -validoinnin selkeäksi.
//
// ============================================================

function validateUid(
  value,
) {
  return validateServiceUid(
    value,
  );
}


// ============================================================
// 🆔 VALIDATE TRANSACTION ID
// ============================================================
//
// Varsinainen validointi tulee admobService.js:stä.
//
// ============================================================

function validateTransactionId(
  value,
) {
  return validateServiceTransactionId(
    value,
  );
}


// ============================================================
// 🎯 VALIDATE REWARD PURPOSE
// ============================================================

function validateRewardPurpose(
  value,
) {
  if (
    typeof value !==
    "string"
  ) {
    return "";
  }

  const rewardPurpose =
    value.trim();

  if (
    !VALID_REWARD_PURPOSES.has(
      rewardPurpose,
    )
  ) {
    return "";
  }

  return rewardPurpose;
}


// ============================================================
// 🔐 GET EXPECTED ADMOB CONFIG
// ============================================================
//
// Käytetään admobService.js:n keskitettyä konfiguraatiota.
//
// adFunctions.js ei ylläpidä omia reward-arvojen kopioita.
//
// ============================================================

function getExpectedAdMobConfig(
  rewardPurpose,
) {
  return getServiceExpectedAdMobConfig(
    rewardPurpose,
  );
}


// ============================================================
// 🔐 VALIDATE VERIFIED AD DATA
// ============================================================
//
// admobService.js:n pitää olla suorittanut kryptografinen
// varmennus ennen tätä vaihetta.
//
// Tämä on defense-in-depth -validointi.
//
// ============================================================

function validateVerifiedAdData(
  verifiedAd,
) {
  if (
    !verifiedAd
  ) {
    const error =
      new Error(
        "Verified AdMob data is missing.",
      );

    error.code =
      "ADMOB_VERIFIED_DATA_MISSING";

    throw error;
  }


  // ----------------------------------------------------------
  // VERIFIED FLAG
  // ----------------------------------------------------------

  if (
    verifiedAd.verified !==
    true
  ) {
    const error =
      new Error(
        "AdMob data is not cryptographically verified.",
      );

    error.code =
      "ADMOB_VERIFIED_DATA_MISSING";

    throw error;
  }


  // ----------------------------------------------------------
  // UID
  // ----------------------------------------------------------

  const uid =
    validateUid(
      verifiedAd.uid,
    );

  if (
    !uid
  ) {
    const error =
      new Error(
        "Verified AdMob UID is invalid.",
      );

    error.code =
      "ADMOB_INVALID_UID";

    throw error;
  }


  // ----------------------------------------------------------
  // REWARD PURPOSE
  // ----------------------------------------------------------

  const rewardPurpose =
    validateRewardPurpose(
      verifiedAd.rewardPurpose,
    );

  if (
    !rewardPurpose
  ) {
    const error =
      new Error(
        "Verified AdMob reward purpose is invalid.",
      );

    error.code =
      "ADMOB_INVALID_REWARD_PURPOSE";

    throw error;
  }


  // ----------------------------------------------------------
  // EXPECTED CONFIG
  // ----------------------------------------------------------

  const expectedAdMob =
    getExpectedAdMobConfig(
      rewardPurpose,
    );


  // ----------------------------------------------------------
  // TRANSACTION ID
  // ----------------------------------------------------------

  const transactionId =
    validateTransactionId(
      verifiedAd.transactionId,
    );

  if (
    !transactionId
  ) {
    const error =
      new Error(
        "Verified AdMob transaction_id is invalid.",
      );

    error.code =
      "ADMOB_INVALID_TRANSACTION_ID";

    throw error;
  }


  // ----------------------------------------------------------
  // REWARD AMOUNT
  // ----------------------------------------------------------

  const rewardAmount =
    Number(
      verifiedAd.rewardAmount,
    );

  if (
    !Number.isSafeInteger(
      rewardAmount,
    ) ||
    rewardAmount !==
      expectedAdMob.rewardAmount
  ) {
    const error =
      new Error(
        "Verified AdMob reward amount does not match server configuration.",
      );

    error.code =
      "ADMOB_INVALID_REWARD_AMOUNT";

    throw error;
  }


  // ----------------------------------------------------------
  // REWARD ITEM
  // ----------------------------------------------------------

  const rewardItem =
    normalizeString(
      verifiedAd.rewardItem,
    );

  if (
    rewardItem.length ===
      0 ||
    rewardItem !==
      expectedAdMob.rewardItem
  ) {
    const error =
      new Error(
        "Verified AdMob reward item does not match server configuration.",
      );

    error.code =
      "ADMOB_INVALID_REWARD_ITEM";

    throw error;
  }


  // ----------------------------------------------------------
  // AD UNIT
  // ----------------------------------------------------------

  const adUnit =
    normalizeString(
      verifiedAd.adUnit,
    );

  if (
    adUnit.length ===
      0 ||
    adUnit !==
      expectedAdMob.adUnit
  ) {
    const error =
      new Error(
        "Verified AdMob ad unit does not match server configuration.",
      );

    error.code =
      "ADMOB_INVALID_AD_UNIT";

    throw error;
  }


  // ----------------------------------------------------------
  // AD NETWORK
  // ----------------------------------------------------------

  const adNetwork =
    validateServiceAdNetwork(
      verifiedAd.adNetwork,
    );

  if (
    !adNetwork
  ) {
    const error =
      new Error(
        "Verified AdMob ad network is invalid.",
      );

    error.code =
      "ADMOB_INVALID_AD_NETWORK";

    throw error;
  }


  // ----------------------------------------------------------
  // TIMESTAMP
  // ----------------------------------------------------------

  const timestamp =
    Number(
      verifiedAd.timestamp,
    );

  if (
    !Number.isSafeInteger(
      timestamp,
    ) ||
    timestamp <= 0
  ) {
    const error =
      new Error(
        "Verified AdMob timestamp is invalid.",
      );

    error.code =
      "ADMOB_INVALID_TIMESTAMP";

    throw error;
  }


  // ----------------------------------------------------------
  // KEY ID
  // ----------------------------------------------------------

  const keyId =
    normalizeString(
      verifiedAd.keyId,
    );

  if (
    keyId.length ===
      0 ||
    keyId.length > 32 ||
    !/^\d+$/.test(
      keyId,
    )
  ) {
    const error =
      new Error(
        "Verified AdMob key_id is invalid.",
      );

    error.code =
      "ADMOB_INVALID_KEY_ID";

    throw error;
  }


  // ----------------------------------------------------------
  // SIGNATURE
  // ----------------------------------------------------------

  const signature =
    normalizeString(
      verifiedAd.signature,
    );

  if (
    signature.length ===
      0 ||
    signature.length > 8192 ||
    !/^[A-Za-z0-9_-]+$/.test(
      signature,
    )
  ) {
    const error =
      new Error(
        "Verified AdMob signature is invalid.",
      );

    error.code =
      "ADMOB_INVALID_SIGNATURE";

    throw error;
  }


  // ----------------------------------------------------------
  // CUSTOM DATA
  // ----------------------------------------------------------
  //
  // admobService.js palauttaa custom_data:n jo varmennettuna
  // ja normalisoituna.
  //
  // Tässä vaiheessa EI tehdä uutta decodeURIComponent()-kutsua.
  //
  // Odotettu rakenne:
  //
  // UID:rewardPurpose
  //
  // ----------------------------------------------------------

  const customData =
    normalizeString(
      verifiedAd.customData,
    );

  if (
    customData.length ===
      0 ||
    customData.length > 256
  ) {
    const error =
      new Error(
        "Verified AdMob custom_data is missing or invalid.",
      );

    error.code =
      "ADMOB_CUSTOM_DATA_MISSING";

    throw error;
  }


  // ----------------------------------------------------------
  // DEFENSE-IN-DEPTH CUSTOM DATA CHECK
  // ----------------------------------------------------------

  const expectedCustomData =
    `${uid}:${rewardPurpose}`;

  if (
    customData !==
    expectedCustomData
  ) {
    const error =
      new Error(
        "Verified AdMob custom_data does not match UID and reward purpose.",
      );

    error.code =
      "ADMOB_CUSTOM_DATA_MISSING";

    throw error;
  }


  // ----------------------------------------------------------
  // USER ID
  // ----------------------------------------------------------

  const rawUserId =
    normalizeString(
      verifiedAd.userId,
    );

  let userId =
    "";

  if (
    rawUserId
  ) {
    userId =
      validateUid(
        rawUserId,
      );

    if (
      !userId
    ) {
      const error =
        new Error(
          "Verified AdMob user_id is invalid.",
        );

      error.code =
        "ADMOB_INVALID_UID";

      throw error;
    }

    if (
      userId !==
      uid
    ) {
      const error =
        new Error(
          "AdMob user_id does not match verified UID.",
        );

      error.code =
        "ADMOB_USER_ID_MISMATCH";

      throw error;
    }
  }


  // ----------------------------------------------------------
  // RETURN NORMALIZED DATA
  // ----------------------------------------------------------

  return {
    uid,

    rewardPurpose,

    transactionId,

    rewardAmount,

    rewardItem,

    adUnit,

    adNetwork,

    timestamp,

    keyId,

    signature,

    customData,

    userId,
  };
}


// ============================================================
// 🔎 COMPARE STORED REWARD DATA
// ============================================================
//
// transaction_id:n pitää olla idempotentti.
//
// Sama transaction_id + sama varmennettu data:
// → turvallinen duplicate
//
// Sama transaction_id + eri data:
// → pysyvä turvallisuuskonflikti
//
// ============================================================

function isSameVerifiedReward(
  existingData,
  validatedAd,
) {
  if (
    !existingData ||
    !validatedAd
  ) {
    return false;
  }


  const existingUid =
    normalizeString(
      existingData.uid,
    );

  const existingPurpose =
    normalizeString(
      existingData.rewardPurpose,
    );

  const existingTransactionId =
    normalizeString(
      existingData.transactionId,
    );

  const existingAdUnit =
    normalizeString(
      existingData.adUnit,
    );

  const existingAdNetwork =
    normalizeString(
      existingData.adNetwork,
    );

  const existingRewardAmount =
    Number(
      existingData.rewardAmount,
    );

  const existingRewardItem =
    normalizeString(
      existingData.rewardItem,
    );

  const existingTimestamp =
    Number(
      existingData.timestamp,
    );

  const existingKeyId =
    normalizeString(
      existingData.keyId,
    );

  const existingSignature =
    normalizeString(
      existingData.signature,
    );

  const existingCustomData =
    normalizeString(
      existingData.customData,
    );

  const existingUserId =
    normalizeString(
      existingData.userId,
    );


  return (
    existingUid ===
      validatedAd.uid &&

    existingPurpose ===
      validatedAd.rewardPurpose &&

    existingTransactionId ===
      validatedAd.transactionId &&

    existingAdUnit ===
      validatedAd.adUnit &&

    existingAdNetwork ===
      validatedAd.adNetwork &&

    existingRewardAmount ===
      validatedAd.rewardAmount &&

    existingRewardItem ===
      validatedAd.rewardItem &&

    existingTimestamp ===
      validatedAd.timestamp &&

    existingKeyId ===
      validatedAd.keyId &&

    existingSignature ===
      validatedAd.signature &&

    existingCustomData ===
      validatedAd.customData &&

    existingUserId ===
      validatedAd.userId
  );
}


// ============================================================
// 📜 COMPARE STORED AUDIT HISTORY
// ============================================================
//
// Reward-documentin lisäksi myös audit-history pitää vastata
// varmennettua AdMob-tapahtumaa.
//
// ============================================================

function isSameVerifiedHistory(
  existingHistoryData,
  validatedAd,
) {
  if (
    !existingHistoryData ||
    !validatedAd
  ) {
    return false;
  }


  // ----------------------------------------------------------
  // UID
  // ----------------------------------------------------------

  const existingUid =
    normalizeString(
      existingHistoryData.uid,
    );


  // ----------------------------------------------------------
  // BASIC TYPES
  // ----------------------------------------------------------

  const existingType =
    normalizeString(
      existingHistoryData.type,
    );

  const existingRewardType =
    normalizeString(
      existingHistoryData.rewardType,
    );

  const existingRewardPurpose =
    normalizeString(
      existingHistoryData.rewardPurpose,
    );

  const existingAdMobTransactionId =
    normalizeString(
      existingHistoryData.adMobTransactionId,
    );

  const existingTransactionId =
    normalizeString(
      existingHistoryData.transactionId,
    );

  const existingAdNetwork =
    normalizeString(
      existingHistoryData.adNetwork,
    );

  const existingAdUnit =
    normalizeString(
      existingHistoryData.adUnit,
    );

  const existingRewardAmount =
    Number(
      existingHistoryData.rewardAmount,
    );

  const existingRewardItem =
    normalizeString(
      existingHistoryData.rewardItem,
    );

  const existingAmount =
    Number(
      existingHistoryData.amount,
    );


  // ----------------------------------------------------------
  // FULL AUDIT MATCH
  // ----------------------------------------------------------

  return (
    existingUid ===
      validatedAd.uid &&

    existingType ===
      "admob_verified" &&

    existingRewardType ===
      "admob" &&

    existingRewardPurpose ===
      validatedAd.rewardPurpose &&

    existingAdMobTransactionId ===
      validatedAd.transactionId &&

    existingTransactionId ===
      validatedAd.transactionId &&

    existingAdNetwork ===
      validatedAd.adNetwork &&

    existingAdUnit ===
      validatedAd.adUnit &&

    existingRewardAmount ===
      validatedAd.rewardAmount &&

    existingRewardItem ===
      validatedAd.rewardItem &&

    existingAmount ===
      0
  );
}


// ============================================================
// 💾 SAVE VERIFIED ADMOB REWARD
// ============================================================
//
// TÄMÄ EI SUORITA REWARDIA.
//
// Se tallentaa ainoastaan kryptografisesti varmennetun
// AdMob-tapahtuman.
//
// Varsinainen Mining Start / Power Boost -business-logiikka
// kuuluu:
//
// functions/src/functions/miningFunctions.js
//
// ============================================================

async function saveVerifiedAdMobReward(
  verifiedAd,
) {
  const validatedAd =
    validateVerifiedAdData(
      verifiedAd,
    );


  const {
    uid,
    rewardPurpose,
    transactionId,
    rewardAmount,
    rewardItem,
    adUnit,
    adNetwork,
    timestamp,
    keyId,
    signature,
    customData,
    userId,
  } =
    validatedAd;


  // ----------------------------------------------------------
  // REWARD REFERENCE
  // ----------------------------------------------------------

  const rewardRef =
    getAdMobRewardRef(
      transactionId,
    );

  if (
    !rewardRef
  ) {
    const error =
      new Error(
        "Unable to create AdMob reward reference.",
      );

    error.code =
      "ADMOB_REWARD_REFERENCE_ERROR";

    throw error;
  }


  // ----------------------------------------------------------
  // HISTORY COLLECTION
  // ----------------------------------------------------------

  const historyCollection =
    getHistoryCollection(
      uid,
    );

  if (
    !historyCollection
  ) {
    const error =
      new Error(
        "Unable to create user history collection.",
      );

    error.code =
      "ADMOB_HISTORY_REFERENCE_ERROR";

    throw error;
  }


  // ----------------------------------------------------------
  // DETERMINISTIC HISTORY REFERENCE
  // ----------------------------------------------------------

  const historyRef =
    historyCollection.doc(
      `admob_${transactionId}`,
    );


  // ----------------------------------------------------------
  // FIRESTORE TRANSACTION
  // ----------------------------------------------------------

  return db.runTransaction(
    async (
      transaction,
    ) => {

      // ======================================================
      // 🔎 ALL READS FIRST
      // ======================================================

      const existingSnapshot =
        await transaction.get(
          rewardRef,
        );

      const existingHistorySnapshot =
        await transaction.get(
          historyRef,
        );


      // ======================================================
      // 🔐 EXISTING REWARD
      // ======================================================

      if (
        existingSnapshot.exists
      ) {
        const existingData =
          existingSnapshot.data() ||
          {};


        // ----------------------------------------------------
        // SAME VERIFIED EVENT
        // ----------------------------------------------------

        if (
          isSameVerifiedReward(
            existingData,
            validatedAd,
          )
        ) {

          // --------------------------------------------------
          // HISTORY MUST EXIST
          // --------------------------------------------------

          if (
            !existingHistorySnapshot.exists
          ) {
            const error =
              new Error(
                "AdMob reward exists without the corresponding audit history.",
              );

            error.code =
              "ADMOB_AUDIT_CONSISTENCY_ERROR";

            throw error;
          }


          // --------------------------------------------------
          // HISTORY MUST ALSO MATCH
          // --------------------------------------------------

          const existingHistoryData =
            existingHistorySnapshot.data() ||
            {};

          if (
            !isSameVerifiedHistory(
              existingHistoryData,
              validatedAd,
            )
          ) {
            const error =
              new Error(
                "AdMob reward and audit history contain inconsistent data.",
              );

            error.code =
              "ADMOB_AUDIT_CONSISTENCY_ERROR";

            throw error;
          }


          // --------------------------------------------------
          // SAFE DUPLICATE
          // --------------------------------------------------

          console.log(
            "🐱 AdMob transaction already processed.",
            {
              transactionId,

              uid,

              rewardPurpose,

              historyExists:
                true,
            },
          );


          return {
            success:
              true,

            verified:
              true,

            recorded:
              true,

            rewarded:
              false,

            duplicate:
              true,

            transactionId,

            rewardPurpose,

            message:
              "🐱📺 Tämä AdMob-tapahtuma on jo vastaanotettu.",
          };
        }


        // ----------------------------------------------------
        // DIFFERENT DATA = PERMANENT CONFLICT
        // ----------------------------------------------------

        const error =
          new Error(
            "AdMob transaction_id is already associated with different reward data.",
          );

        error.code =
          "ADMOB_TRANSACTION_CONFLICT";

        throw error;
      }


      // ======================================================
      // 🛡️ HISTORY CONFLICT
      // ======================================================

      if (
        existingHistorySnapshot.exists
      ) {
        const error =
          new Error(
            "AdMob audit history exists without the corresponding reward document.",
          );

        error.code =
          "ADMOB_AUDIT_CONSISTENCY_ERROR";

        throw error;
      }


      // ======================================================
      // 💾 SAVE VERIFIED REWARD EVENT
      // ======================================================

      transaction.create(
        rewardRef,
        {
          uid,

          transactionId,

          rewardType:
            "admob",

          rewardPurpose,

          rewardAmount,

          rewardItem,

          adNetwork,

          adUnit,

          timestamp,

          keyId,

          signature,

          customData,

          userId,

          // --------------------------------------------------
          // ⛏️ MINING START STATE
          // --------------------------------------------------

          miningClaimed:
            false,

          miningClaimedAt:
            null,

          miningClaimedBy:
            null,

          miningStartClaimed:
            false,

          miningStartClaimedAt:
            null,

          miningStartClaimedBy:
            null,

          // --------------------------------------------------
          // ⚡ POWER BOOST STATE
          // --------------------------------------------------

          powerBoostClaimed:
            false,

          powerBoostClaimedAt:
            null,

          powerBoostClaimedBy:
            null,

          powerBoostTransactionId:
            null,

          // --------------------------------------------------
          // 🕒 TIMESTAMPS
          // --------------------------------------------------

          createdAt:
            FieldValue.serverTimestamp(),

          updatedAt:
            FieldValue.serverTimestamp(),
        },
      );


      // ======================================================
      // 📜 HISTORY
      // ======================================================
      //
      // Tämä on vain AUDIT-merkintä.
      //
      // amount = 0
      //
      // AdMob rewardAmount ei ole STL.
      //
      // ======================================================

      transaction.create(
        historyRef,
        {
          uid,

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

          transactionId,

          adNetwork,

          adUnit,

          rewardAmount,

          rewardItem,

          createdAt:
            FieldValue.serverTimestamp(),
        },
      );


      // ======================================================
      // 📤 RESULT
      // ======================================================

      return {
        success:
          true,

        verified:
          true,

        recorded:
          true,

        rewarded:
          false,

        duplicate:
          false,

        transactionId,

        rewardPurpose,

        rewardAmount,

        rewardItem,

        message:
          rewardPurpose ===
          "power_boost"
            ? "🐱📺 Power Boost -mainos vahvistettu ja tapahtuma tallennettu."
            : "🐱📺 Mining Start -mainos vahvistettu ja tapahtuma tallennettu.",
      };
    },
  );
}


// ============================================================
// 📺 ADMOB REWARD CALLBACK
// ============================================================

const adMobReward =
  onRequest(
    {
      region:
        "us-central1",
    },

    async (
      req,
      res,
    ) => {
      let ssvVerified =
        false;

      try {

        // ====================================================
        // 🔐 METHOD
        // ====================================================

        if (
          req.method ===
          "HEAD"
        ) {
          res.status(
            200,
          ).end();

          return;
        }

        if (
          req.method !==
          "GET"
        ) {
          res.status(
            405,
          ).json({
            success:
              false,

            verified:
              false,

            recorded:
              false,

            rewarded:
              false,

            error:
              "Method not allowed.",
          });

          return;
        }


        // ====================================================
        // 🔎 QUERY
        // ====================================================

        const query =
          req.query || {};

        const queryKeys =
          Object.keys(
            query,
          );


        // ====================================================
        // 🩺 HEALTH CHECK
        // ====================================================
        //
        // Tyhjä GET ei ole varsinainen SSV callback.
        //
        // Tätä voidaan käyttää endpointin saavutettavuuden
        // tarkistamiseen.
        //
        // ====================================================

        if (
          queryKeys.length ===
          0
        ) {
          console.log(
            "🐱 AdMob SSV endpoint health check.",
          );

          res.status(
            200,
          ).json({
            success:
              true,

            verified:
              false,

            recorded:
              false,

            endpoint:
              "adMobReward",

            rewarded:
              false,

            message:
              "Stelluriini AdMob SSV endpoint is reachable.",
          });

          return;
        }


        // ====================================================
        // 🔐 VERIFY CALLBACK
        // ====================================================

        console.log(
          "🐱 AdMob SSV callback received.",
        );

        console.log(
          "🐱 AdMob SSV query keys:",
          queryKeys,
        );


        const verifiedAd =
          await verifyAdMobCallback(
            req,
          );


        // ====================================================
        // 🛡️ VERIFY RESULT
        // ====================================================

        if (
          !verifiedAd ||
          verifiedAd.verified !==
            true
        ) {
          console.error(
            "❌ AdMob SSV verification failed.",
          );

          res.status(
            200,
          ).json({
            success:
              false,

            verified:
              false,

            recorded:
              false,

            rewarded:
              false,

            error:
              "Invalid AdMob SSV callback.",
          });

          return;
        }


        // ====================================================
        // 🔐 CRYPTOGRAPHICALLY VERIFIED
        // ====================================================

        ssvVerified =
          true;


        // ====================================================
        // 🛡️ FINAL VALIDATION
        // ====================================================

        const validatedAd =
          validateVerifiedAdData(
            verifiedAd,
          );


        console.log(
          "🐱✅ Verified AdMob reward ready for Firestore.",
          {
            uid:
              validatedAd.uid,

            transactionId:
              validatedAd.transactionId,

            rewardPurpose:
              validatedAd.rewardPurpose,

            adUnit:
              validatedAd.adUnit,

            adNetwork:
              validatedAd.adNetwork,

            rewardAmount:
              validatedAd.rewardAmount,

            rewardItem:
              validatedAd.rewardItem,

            keyId:
              validatedAd.keyId,
          },
        );


        // ====================================================
        // 💾 SAVE
        // ====================================================

        const result =
          await saveVerifiedAdMobReward(
            validatedAd,
          );


        // ====================================================
        // 📤 SUCCESS
        // ====================================================

        console.log(
          "🐱 AdMob SSV processed successfully.",
          {
            uid:
              validatedAd.uid,

            transactionId:
              validatedAd.transactionId,

            rewardPurpose:
              validatedAd.rewardPurpose,

            duplicate:
              result.duplicate,

            recorded:
              result.recorded,
          },
        );


        res.status(
          200,
        ).json(
          result,
        );

      } catch (
        error
      ) {

        // ====================================================
        // ❌ ERROR LOG
        // ====================================================

        const errorCode =
          error &&
          error.code
            ? error.code
            : "UNKNOWN";

        const errorMessage =
          error &&
          error.message
            ? error.message
            : "Unknown AdMob error.";


        console.error(
          "❌ AdMob reward processing failed.",
          {
            code:
              errorCode,

            message:
              errorMessage,
          },
        );


        // ====================================================
        // 🛡️ CLIENT VALIDATION ERROR
        // ====================================================

        if (
          CLIENT_VALIDATION_ERROR_CODES.has(
            errorCode,
          )
        ) {
          res.status(
            200,
          ).json({
            success:
              false,

            verified:
              ssvVerified,

            recorded:
              false,

            rewarded:
              false,

            error:
              errorCode ===
              "ADMOB_TRANSACTION_CONFLICT"
                ? "AdMob transaction conflict."
                : ssvVerified
                  ? "Verified AdMob callback failed final validation."
                  : "Invalid AdMob SSV callback.",
          });

          return;
        }


        // ====================================================
        // 🔄 SERVER / CONFIG / RETRY ERROR
        // ====================================================

        if (
          SERVER_RETRY_ERROR_CODES.has(
            errorCode,
          )
        ) {
          res.status(
            500,
          ).json({
            success:
              false,

            verified:
              ssvVerified,

            recorded:
              false,

            rewarded:
              false,

            error:
              "AdMob reward processing failed.",
          });

          return;
        }


        // ====================================================
        // ❌ UNKNOWN INTERNAL ERROR
        // ====================================================

        res.status(
          500,
        ).json({
          success:
            false,

          verified:
            ssvVerified,

          recorded:
            false,

          rewarded:
            false,

          error:
            "AdMob reward processing failed.",
        });
      }
    },
  );


// ============================================================
// 📦 EXPORTS
// ============================================================

module.exports = {
  adMobReward,

  validateUid,

  validateTransactionId,

  validateRewardPurpose,

  validateVerifiedAdData,

  getExpectedAdMobConfig,

  isSameVerifiedReward,

  isSameVerifiedHistory,

  saveVerifiedAdMobReward,
};