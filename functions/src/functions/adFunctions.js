"use strict";

// ============================================================
// 🐱 STELLURIINI - ADMOB FUNCTIONS
// ============================================================
//
// Vastuu:
//
// 📺 Vastaanottaa AdMob Rewarded SSV callbackin
// 🔐 Varmistaa callbackin admobService.js:n kautta
// 🆔 Käyttää vain kryptografisesti varmennettua UID:tä
// 🎯 Tunnistaa reward purposen
// 💾 Tallentaa varmennetun AdMob-tapahtuman
// 🛡️ Estää transaction_id:n uudelleenkäytön
// 📜 Säilyttää audit-historian johdonmukaisena
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
// Varsinainen Mining / Power Boost -business-logiikka kuuluu:
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

const {
  verifyAdMobCallback,

  getExpectedAdMobConfig:
    getServiceExpectedAdMobConfig,

  validateTransactionId:
    validateServiceTransactionId,

  validateUid:
    validateServiceUid,

  validateAdNetwork:
    validateServiceAdNetwork,

  validateTimestamp:
    validateServiceTimestamp,

  validateSignature:
    validateServiceSignature,

  validateKeyId:
    validateServiceKeyId,
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
// Näissä tapauksissa callback on vastaanotettu,
// mutta tapahtumaa ei pidä yrittää uudelleen serverivirheenä.
//
// ============================================================

const CLIENT_VALIDATION_ERROR_CODES =
  new Set([
    "ADMOB_INVALID_SIGNATURE",
    "ADMOB_INVALID_KEY_ID",
    "ADMOB_REQUEST_MISSING",
    "ADMOB_QUERY_STRING_MISSING",
    "ADMOB_QUERY_STRING_TOO_LARGE",
    "ADMOB_INVALID_UID",
    "ADMOB_INVALID_REWARD_PURPOSE",
    "ADMOB_INVALID_TRANSACTION_ID",
    "ADMOB_INVALID_TIMESTAMP",
    "ADMOB_INVALID_AD_NETWORK",
    "ADMOB_REQUIRED_PARAMETER_MISSING",
    "ADMOB_VERIFIED_DATA_MISSING",
    "ADMOB_USER_ID_MISMATCH",
    "ADMOB_CUSTOM_DATA_MISSING",
    "ADMOB_CUSTOM_DATA_INVALID",
    "ADMOB_CUSTOM_DATA_INVALID_ENCODING",
    "ADMOB_CUSTOM_DATA_MISMATCH",
    "ADMOB_INVALID_AD_UNIT",
    "ADMOB_INVALID_REWARD_ITEM",
    "ADMOB_INVALID_REWARD_AMOUNT",
    "ADMOB_TRANSACTION_CONFLICT",
    "ADMOB_INVALID_REWARD_CONFIGURATION",
  ]);


// ============================================================
// 🔄 SERVER / CONFIG / RETRY ERROR CODES
// ============================================================

const SERVER_RETRY_ERROR_CODES =
  new Set([
    "ADMOB_PUBLIC_KEY_FETCH_ERROR",
    "ADMOB_PUBLIC_KEY_HTTP_ERROR",
    "ADMOB_PUBLIC_KEY_JSON_ERROR",
    "ADMOB_PUBLIC_KEY_RESPONSE_INVALID",
    "ADMOB_PUBLIC_KEYS_EMPTY",
    "ADMOB_CRYPTO_VERIFICATION_ERROR",

    "ADMOB_REWARD_REFERENCE_ERROR",
    "ADMOB_HISTORY_REFERENCE_ERROR",

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
// 🛡️ CREATE ERROR
// ============================================================

function createError(
  code,
  message,
) {
  const error =
    new Error(
      message,
    );

  error.code =
    code;

  return error;
}


// ============================================================
// 👤 VALIDATE UID
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
// Google AdMob määrittelee transaction_id:n yksilölliseksi
// hex-enkoodatuksi reward grant -tunnisteeksi.
//
// Lisäksi varmistetaan Firestore-document-ID:n turvallisuus.
//
// ============================================================

function validateTransactionId(
  value,
) {
  const transactionId =
    validateServiceTransactionId(
      value,
    );

  if (
    !transactionId
  ) {
    return "";
  }

  if (
    transactionId.includes(
      "/",
    ) ||
    transactionId.includes(
      "\\",
    )
  ) {
    return "";
  }

  return transactionId;
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

function validateVerifiedAdData(
  verifiedAd,
) {
  if (
    !verifiedAd ||
    typeof verifiedAd !==
      "object"
  ) {
    throw createError(
      "ADMOB_VERIFIED_DATA_MISSING",
      "Verified AdMob data is missing.",
    );
  }


  // ==========================================================
  // VERIFIED FLAG
  // ==========================================================

  if (
    verifiedAd.verified !==
    true
  ) {
    throw createError(
      "ADMOB_VERIFIED_DATA_MISSING",
      "AdMob data is not cryptographically verified.",
    );
  }


  // ==========================================================
  // UID
  // ==========================================================

  const uid =
    validateUid(
      verifiedAd.uid,
    );

  if (
    !uid
  ) {
    throw createError(
      "ADMOB_INVALID_UID",
      "Verified AdMob UID is invalid.",
    );
  }


  // ==========================================================
  // REWARD PURPOSE
  // ==========================================================

  const rewardPurpose =
    validateRewardPurpose(
      verifiedAd.rewardPurpose,
    );

  if (
    !rewardPurpose
  ) {
    throw createError(
      "ADMOB_INVALID_REWARD_PURPOSE",
      "Verified AdMob reward purpose is invalid.",
    );
  }


  // ==========================================================
  // EXPECTED CONFIG
  // ==========================================================

  let expectedAdMob;

  try {
    expectedAdMob =
      getExpectedAdMobConfig(
        rewardPurpose,
      );
  } catch (
    error
  ) {
    throw createError(
      "ADMOB_INVALID_REWARD_CONFIGURATION",
      "Unable to resolve AdMob reward configuration.",
    );
  }

  if (
    !expectedAdMob ||
    typeof expectedAdMob !==
      "object"
  ) {
    throw createError(
      "ADMOB_INVALID_REWARD_CONFIGURATION",
      "AdMob reward configuration is invalid.",
    );
  }


  // ==========================================================
  // TRANSACTION ID
  // ==========================================================

  const transactionId =
    validateTransactionId(
      verifiedAd.transactionId,
    );

  if (
    !transactionId
  ) {
    throw createError(
      "ADMOB_INVALID_TRANSACTION_ID",
      "Verified AdMob transaction_id is invalid.",
    );
  }


  // ==========================================================
  // REWARD AMOUNT
  // ==========================================================

  const rewardAmount =
    Number(
      verifiedAd.rewardAmount,
    );

  const expectedRewardAmount =
    Number(
      expectedAdMob.rewardAmount,
    );

  if (
    !Number.isSafeInteger(
      rewardAmount,
    ) ||
    rewardAmount <
      0 ||
    !Number.isSafeInteger(
      expectedRewardAmount,
    ) ||
    expectedRewardAmount <
      0 ||
    rewardAmount !==
      expectedRewardAmount
  ) {
    throw createError(
      "ADMOB_INVALID_REWARD_AMOUNT",
      "Verified AdMob reward amount does not match server configuration.",
    );
  }


  // ==========================================================
  // REWARD ITEM
  // ==========================================================

  const rewardItem =
    normalizeString(
      verifiedAd.rewardItem,
    );

  const expectedRewardItem =
    normalizeString(
      expectedAdMob.rewardItem,
    );

  if (
    rewardItem.length ===
      0 ||
    rewardItem.length >
      256 ||
    expectedRewardItem.length ===
      0 ||
    expectedRewardItem.length >
      256 ||
    rewardItem !==
      expectedRewardItem
  ) {
    throw createError(
      "ADMOB_INVALID_REWARD_ITEM",
      "Verified AdMob reward item does not match server configuration.",
    );
  }


  // ==========================================================
  // AD UNIT
  // ==========================================================

  const adUnit =
    normalizeString(
      verifiedAd.adUnit,
    );

  const expectedAdUnit =
    normalizeString(
      expectedAdMob.adUnit,
    );

  if (
    adUnit.length ===
      0 ||
    adUnit.length >
      256 ||
    expectedAdUnit.length ===
      0 ||
    expectedAdUnit.length >
      256 ||
    adUnit !==
      expectedAdUnit
  ) {
    throw createError(
      "ADMOB_INVALID_AD_UNIT",
      "Verified AdMob ad unit does not match server configuration.",
    );
  }


  // ==========================================================
  // AD NETWORK
  // ==========================================================

  const adNetwork =
    validateServiceAdNetwork(
      verifiedAd.adNetwork,
    );

  if (
    !adNetwork
  ) {
    throw createError(
      "ADMOB_INVALID_AD_NETWORK",
      "Verified AdMob ad network is invalid.",
    );
  }


  // ==========================================================
  // TIMESTAMP
  // ==========================================================

  const timestamp =
    validateServiceTimestamp(
      verifiedAd.timestamp,
    );

  if (
    !timestamp
  ) {
    throw createError(
      "ADMOB_INVALID_TIMESTAMP",
      "Verified AdMob timestamp is invalid or outside the allowed time window.",
    );
  }


  // ==========================================================
  // KEY ID
  // ==========================================================

  const keyId =
    validateServiceKeyId(
      verifiedAd.keyId,
    );

  if (
    !keyId
  ) {
    throw createError(
      "ADMOB_INVALID_KEY_ID",
      "Verified AdMob key_id is invalid.",
    );
  }


  // ==========================================================
  // SIGNATURE
  // ==========================================================

  const signature =
    validateServiceSignature(
      verifiedAd.signature,
    );

  if (
    !signature
  ) {
    throw createError(
      "ADMOB_INVALID_SIGNATURE",
      "Verified AdMob signature is invalid.",
    );
  }


  // ==========================================================
  // CUSTOM DATA
  // ==========================================================

  const customData =
    normalizeString(
      verifiedAd.customData,
    );

  if (
    customData.length ===
      0 ||
    customData.length >
      256
  ) {
    throw createError(
      "ADMOB_CUSTOM_DATA_MISSING",
      "Verified AdMob custom_data is missing or invalid.",
    );
  }


  // ==========================================================
  // DEFENSE-IN-DEPTH CUSTOM DATA CHECK
  // ==========================================================

  const expectedCustomData =
    `${uid}:${rewardPurpose}`;

  if (
    customData !==
    expectedCustomData
  ) {
    throw createError(
      "ADMOB_CUSTOM_DATA_MISMATCH",
      "Verified AdMob custom_data does not match UID and reward purpose.",
    );
  }


  // ==========================================================
  // USER ID
  // ==========================================================

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
      throw createError(
        "ADMOB_INVALID_UID",
        "Verified AdMob user_id is invalid.",
      );
    }

    if (
      userId !==
      uid
    ) {
      throw createError(
        "ADMOB_USER_ID_MISMATCH",
        "AdMob user_id does not match verified UID.",
      );
    }
  }


  // ==========================================================
  // RETURN NORMALIZED DATA
  // ==========================================================

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
// 📜 COMPARE STORED REWARD DATA
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

  const existingUid =
    normalizeString(
      existingHistoryData.uid,
    );

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

  const existingTimestamp =
    Number(
      existingHistoryData.timestamp,
    );

  const existingKeyId =
    normalizeString(
      existingHistoryData.keyId,
    );

  const existingSignature =
    normalizeString(
      existingHistoryData.signature,
    );

  const existingCustomData =
    normalizeString(
      existingHistoryData.customData,
    );

  const existingUserId =
    normalizeString(
      existingHistoryData.userId,
    );

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
      0 &&

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
// 💾 SAVE VERIFIED ADMOB REWARD
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


  // ==========================================================
  // REWARD REFERENCE
  // ==========================================================

  const rewardRef =
    getAdMobRewardRef(
      transactionId,
    );

  if (
    !rewardRef ||
    typeof rewardRef !==
      "object"
  ) {
    throw createError(
      "ADMOB_REWARD_REFERENCE_ERROR",
      "Unable to create AdMob reward reference.",
    );
  }


  // ==========================================================
  // HISTORY COLLECTION
  // ==========================================================

  const historyCollection =
    getHistoryCollection(
      uid,
    );

  if (
    !historyCollection ||
    typeof historyCollection.doc !==
      "function"
  ) {
    throw createError(
      "ADMOB_HISTORY_REFERENCE_ERROR",
      "Unable to create user history collection.",
    );
  }


  // ==========================================================
  // DETERMINISTIC HISTORY REFERENCE
  // ==========================================================

  const historyDocumentId =
    `admob_${transactionId}`;

  if (
    historyDocumentId.length >
      1500 ||
    historyDocumentId.includes(
      "/",
    ) ||
    historyDocumentId.includes(
      "\\",
    )
  ) {
    throw createError(
      "ADMOB_INVALID_TRANSACTION_ID",
      "AdMob transaction_id cannot be used as a Firestore document ID.",
    );
  }

  const historyRef =
    historyCollection.doc(
      historyDocumentId,
    );


  // ==========================================================
  // FIRESTORE TRANSACTION
  // ==========================================================

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


        // ====================================================
        // SAME VERIFIED EVENT
        // ====================================================

        if (
          isSameVerifiedReward(
            existingData,
            validatedAd,
          )
        ) {

          // ==================================================
          // HISTORY MUST EXIST
          // ==================================================

          if (
            !existingHistorySnapshot.exists
          ) {
            throw createError(
              "ADMOB_AUDIT_CONSISTENCY_ERROR",
              "AdMob reward exists without the corresponding audit history.",
            );
          }


          // ==================================================
          // HISTORY MUST ALSO MATCH
          // ==================================================

          const existingHistoryData =
            existingHistorySnapshot.data() ||
            {};

          if (
            !isSameVerifiedHistory(
              existingHistoryData,
              validatedAd,
            )
          ) {
            throw createError(
              "ADMOB_AUDIT_CONSISTENCY_ERROR",
              "AdMob reward and audit history contain inconsistent data.",
            );
          }


          // ==================================================
          // SAFE DUPLICATE
          // ==================================================

          console.log(
            "🐱 AdMob transaction already processed.",
            {
              transactionId,

              uid,

              rewardPurpose,

              duplicate:
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


        // ====================================================
        // DIFFERENT DATA = PERMANENT CONFLICT
        // ====================================================

        throw createError(
          "ADMOB_TRANSACTION_CONFLICT",
          "AdMob transaction_id is already associated with different reward data.",
        );
      }


      // ======================================================
      // 🛡️ HISTORY CONFLICT
      // ======================================================

      if (
        existingHistorySnapshot.exists
      ) {
        throw createError(
          "ADMOB_AUDIT_CONSISTENCY_ERROR",
          "AdMob audit history exists without the corresponding reward document.",
        );
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

          // ==================================================
          // ⛏️ MINING START STATE
          // ==================================================

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

          // ==================================================
          // ⚡ POWER BOOST STATE
          // ==================================================

          powerBoostClaimed:
            false,

          powerBoostClaimedAt:
            null,

          powerBoostClaimedBy:
            null,

          powerBoostTransactionId:
            null,

          // ==================================================
          // 🕒 TIMESTAMPS
          // ==================================================

          createdAt:
            FieldValue.serverTimestamp(),

          updatedAt:
            FieldValue.serverTimestamp(),
        },
      );


      // ======================================================
      // 📜 AUDIT HISTORY
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

          timestamp,

          keyId,

          signature,

          customData,

          userId,

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
          req.query ||
          {};

        const queryKeys =
          Object.keys(
            query,
          );


        // ====================================================
        // 🩺 HEALTH CHECK
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

            rewarded:
              false,

            endpoint:
              "adMobReward",

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
          throw createError(
            "ADMOB_INVALID_SIGNATURE",
            "Invalid AdMob SSV callback.",
          );
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


        // ====================================================
        // 📋 SAFE LOGGING
        // ====================================================
        //
        // Älä koskaan loggaa:
        //
        // ❌ signature
        // ❌ custom_data
        // ❌ raw query string
        //
        // UID ja transaction_id voidaan logata audit-debugia
        // varten, mutta itse allekirjoitusta ei.
        //
        // ============================================================

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
        // ❌ ERROR INFORMATION
        // ====================================================

        const errorCode =
          error &&
          error.code
            ? String(
                error.code,
              )
            : "UNKNOWN";

        const errorMessage =
          error &&
          error.message
            ? String(
                error.message,
              )
            : "Unknown AdMob error.";


        // ====================================================
        // 🔐 SAFE ERROR LOG
        // ====================================================
        //
        // Signaturea tai raw query-stringiä ei logata.
        //
        // ====================================================

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