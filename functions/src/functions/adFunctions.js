"use strict";

// ============================================================
// 🐱 STELLURIINI - ADMOB SSV FUNCTION
// ============================================================
//
// Vastuu:
//
// - Vastaanottaa AdMob Rewarded SSV callbackin
// - Käyttää admobService.js:n kryptografista varmennusta
// - Validoi varmennetun AdMob-datan
// - Tallentaa varmennetun rewardin admobRewards-kokoelmaan
// - Tallentaa erillisen audit-historian
// - Estää transaction_id:n uudelleenkäytön
//
// EI:
//
// - käynnistä louhintaa
// - aktivoi Power Boostia
// - muuta mining-tilaa
// - lisää STL-saldoa
//
// AdMob reward toimii ainoastaan valtuutuksena:
//
// - Mining Start
// - Power Boost
//
// Varsinainen mining-logiikka tapahtuu
// miningFunctions.js-tiedostossa.
//
// ============================================================

const {
onRequest,
} = require("firebase-functions/v2/https");

const {
db,
FieldValue,
} = require("../firebase/firebase");

const {
verifyAdMobCallback,
getExpectedAdMobConfig,
validateTransactionId,
validateUid,
validateRewardPurpose,
validateTimestamp,
validateAdNetwork,
validateKeyId,
validateSignature,
} = require("../services/admobService");

const {
getHistoryCollection,
getAdMobRewardRef,
} = require("../utils/userUtils");

// ============================================================
// HELPERS
// ============================================================

function createError(
code,
message
) {
const error =
new Error(message);

error.code = code;

return error;
}

function normalizeString(
value
) {
return typeof value ===
"string"
? value.trim()
: "";
}

// ============================================================
// VALIDATE VERIFIED DATA
// ============================================================

function validateVerifiedAdData(
verifiedAd
) {
if (
!verifiedAd ||
typeof verifiedAd !==
"object" ||
verifiedAd.verified !== true
) {
throw createError(
"ADMOB_VERIFIED_DATA_MISSING",
"AdMob data is not cryptographically verified."
);
}

const uid =
validateUid(
verifiedAd.uid
);

if (!uid) {
throw createError(
"ADMOB_INVALID_UID",
"Verified AdMob UID is invalid."
);
}

const rewardPurpose =
validateRewardPurpose(
verifiedAd.rewardPurpose
);

if (!rewardPurpose) {
throw createError(
"ADMOB_INVALID_REWARD_PURPOSE",
"Verified AdMob reward purpose is invalid."
);
}

const transactionId =
validateTransactionId(
verifiedAd.transactionId
);

if (!transactionId) {
throw createError(
"ADMOB_INVALID_TRANSACTION_ID",
"Verified AdMob transaction_id is invalid."
);
}

const config =
getExpectedAdMobConfig(
rewardPurpose
);

if (
!config ||
typeof config !==
"object"
) {
throw createError(
"ADMOB_INVALID_REWARD_CONFIGURATION",
"AdMob reward configuration is invalid."
);
}

const rewardAmount =
Number(
verifiedAd.rewardAmount
);

const expectedRewardAmount =
Number(
config.rewardAmount
);

if (
!Number.isSafeInteger(
rewardAmount
) ||
!Number.isSafeInteger(
expectedRewardAmount
) ||
rewardAmount !==
expectedRewardAmount
) {
throw createError(
"ADMOB_INVALID_REWARD_AMOUNT",
"Verified reward amount is invalid."
);
}

const rewardItem =
normalizeString(
verifiedAd.rewardItem
);

const expectedRewardItem =
normalizeString(
config.rewardItem
);

if (
!rewardItem ||
!expectedRewardItem ||
rewardItem !==
expectedRewardItem
) {
throw createError(
"ADMOB_INVALID_REWARD_ITEM",
"Verified reward item is invalid."
);
}

const adUnit =
normalizeString(
verifiedAd.adUnit
);

const expectedAdUnit =
normalizeString(
config.adUnit
);

if (
!adUnit ||
!expectedAdUnit ||
adUnit !==
expectedAdUnit
) {
throw createError(
"ADMOB_INVALID_AD_UNIT",
"Verified ad unit is invalid."
);
}

const adNetwork =
validateAdNetwork(
verifiedAd.adNetwork
);

if (!adNetwork) {
throw createError(
"ADMOB_INVALID_AD_NETWORK",
"Verified AdMob ad network is invalid."
);
}

const timestamp =
validateTimestamp(
verifiedAd.timestamp
);

if (!timestamp) {
throw createError(
"ADMOB_INVALID_TIMESTAMP",
"Verified AdMob timestamp is invalid."
);
}

const keyId =
validateKeyId(
verifiedAd.keyId
);

if (!keyId) {
throw createError(
"ADMOB_INVALID_KEY_ID",
"Verified AdMob key_id is invalid."
);
}

const signature =
validateSignature(
verifiedAd.signature
);

if (!signature) {
throw createError(
"ADMOB_INVALID_SIGNATURE",
"Verified AdMob signature is invalid."
);
}

const customData =
normalizeString(
verifiedAd.customData
);

// IMPORTANT:
// Template literal is required here.
const expectedCustomData =
"${uid}:${rewardPurpose}";

if (
customData !==
expectedCustomData
) {
throw createError(
"ADMOB_CUSTOM_DATA_MISMATCH",
"Verified custom_data does not match."
);
}

let userId = "";

if (
verifiedAd.userId !==
undefined &&
verifiedAd.userId !==
null
) {
userId =
normalizeString(
verifiedAd.userId
);

if (
  userId &&
  !validateUid(userId)
) {
  throw createError(
    "ADMOB_INVALID_UID",
    "Verified AdMob user_id is invalid."
  );
}

if (
  userId &&
  userId !== uid
) {
  throw createError(
    "ADMOB_USER_ID_MISMATCH",
    "AdMob user_id does not match verified UID."
  );
}

}

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
// DUPLICATE CHECK
// ============================================================

function isSameVerifiedReward(
existing,
current
) {
if (
!existing ||
typeof existing !==
"object"
) {
return false;
}

if (
!current ||
typeof current !==
"object"
) {
return false;
}

return (
normalizeString(
existing.uid
) === current.uid &&

normalizeString(
  existing.rewardPurpose
) ===
  current.rewardPurpose &&

normalizeString(
  existing.transactionId
) ===
  current.transactionId &&

normalizeString(
  existing.adUnit
) ===
  current.adUnit &&

normalizeString(
  existing.adNetwork
) ===
  current.adNetwork &&

Number(
  existing.rewardAmount
) ===
  current.rewardAmount &&

normalizeString(
  existing.rewardItem
) ===
  current.rewardItem &&

Number(
  existing.timestamp
) ===
  current.timestamp &&

normalizeString(
  existing.keyId
) ===
  current.keyId &&

normalizeString(
  existing.signature
) ===
  current.signature &&

normalizeString(
  existing.customData
) ===
  current.customData &&

normalizeString(
  existing.userId
) ===
  current.userId

);
}

// ============================================================
// AUDIT CHECK
// ============================================================

function isSameVerifiedHistory(
existing,
current
) {
if (
!existing ||
typeof existing !==
"object"
) {
return false;
}

if (
!current ||
typeof current !==
"object"
) {
return false;
}

return (
normalizeString(
existing.uid
) === current.uid &&

normalizeString(
  existing.type
) ===
  "admob_verified" &&

normalizeString(
  existing.rewardType
) ===
  "admob" &&

normalizeString(
  existing.rewardPurpose
) ===
  current.rewardPurpose &&

normalizeString(
  existing.adMobTransactionId
) ===
  current.transactionId &&

normalizeString(
  existing.transactionId
) ===
  current.transactionId &&

normalizeString(
  existing.adNetwork
) ===
  current.adNetwork &&

normalizeString(
  existing.adUnit
) ===
  current.adUnit &&

Number(
  existing.rewardAmount
) ===
  current.rewardAmount &&

normalizeString(
  existing.rewardItem
) ===
  current.rewardItem &&

Number(
  existing.amount
) === 0 &&

Number(
  existing.timestamp
) ===
  current.timestamp &&

normalizeString(
  existing.keyId
) ===
  current.keyId &&

normalizeString(
  existing.signature
) ===
  current.signature &&

normalizeString(
  existing.customData
) ===
  current.customData &&

normalizeString(
  existing.userId
) ===
  current.userId

);
}

// ============================================================
// SAVE VERIFIED REWARD
// ============================================================

async function saveVerifiedAdMobReward(
verifiedAd
) {
const data =
validateVerifiedAdData(
verifiedAd
);

const rewardRef =
getAdMobRewardRef(
data.transactionId
);

if (!rewardRef) {
throw createError(
"ADMOB_REWARD_REFERENCE_ERROR",
"Unable to create AdMob reward reference."
);
}

const historyCollection =
getHistoryCollection(
data.uid
);

if (
!historyCollection ||
typeof historyCollection.doc !==
"function"
) {
throw createError(
"ADMOB_HISTORY_REFERENCE_ERROR",
"Unable to create history collection."
);
}

// IMPORTANT:
// Template literal is required here.
const historyRef =
historyCollection.doc(
"admob_${data.transactionId}"
);

return db.runTransaction(
async (
transaction
) => {
// ----------------------------------------------------
// ALL READS FIRST
// ----------------------------------------------------

  const rewardSnapshot =
    await transaction.get(
      rewardRef
    );

  const historySnapshot =
    await transaction.get(
      historyRef
    );

  // ----------------------------------------------------
  // EXISTING REWARD
  // ----------------------------------------------------

  if (
    rewardSnapshot.exists
  ) {
    const existing =
      rewardSnapshot.data() ||
      {};

    if (
      !isSameVerifiedReward(
        existing,
        data
      )
    ) {
      throw createError(
        "ADMOB_TRANSACTION_CONFLICT",
        "AdMob transaction_id conflict."
      );
    }

    if (
      !historySnapshot.exists ||
      !isSameVerifiedHistory(
        historySnapshot.data() ||
          {},
        data
      )
    ) {
      throw createError(
        "ADMOB_AUDIT_CONSISTENCY_ERROR",
        "AdMob reward and audit history are inconsistent."
      );
    }

    console.log(
      "🐱 AdMob duplicate SSV ignored.",
      {
        uid:
          data.uid,

        transactionId:
          data.transactionId,

        rewardPurpose:
          data.rewardPurpose,
      }
    );

    return {
      success: true,

      verified: true,

      recorded: true,

      rewarded: false,

      duplicate: true,

      transactionId:
        data.transactionId,

      rewardPurpose:
        data.rewardPurpose,
    };
  }

  // ----------------------------------------------------
  // ORPHAN AUDIT DOCUMENT
  // ----------------------------------------------------

  if (
    historySnapshot.exists
  ) {
    throw createError(
      "ADMOB_AUDIT_CONSISTENCY_ERROR",
      "Audit history exists without reward document."
    );
  }

  // ----------------------------------------------------
  // AUTHORITATIVE REWARD DOCUMENT
  // ----------------------------------------------------

  transaction.create(
    rewardRef,
    {
      uid:
        data.uid,

      transactionId:
        data.transactionId,

      rewardType:
        "admob",

      rewardPurpose:
        data.rewardPurpose,

      rewardAmount:
        data.rewardAmount,

      rewardItem:
        data.rewardItem,

      adNetwork:
        data.adNetwork,

      adUnit:
        data.adUnit,

      timestamp:
        data.timestamp,

      keyId:
        data.keyId,

      signature:
        data.signature,

      customData:
        data.customData,

      userId:
        data.userId,

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

      powerBoostClaimed:
        false,

      powerBoostClaimedAt:
        null,

      powerBoostClaimedBy:
        null,

      powerBoostTransactionId:
        null,

      rewardConsumed:
        false,

      consumedAt:
        null,

      consumedBy:
        null,

      createdAt:
        FieldValue.serverTimestamp(),

      updatedAt:
        FieldValue.serverTimestamp(),
    }
  );

  // ----------------------------------------------------
  // AUDIT HISTORY
  // ----------------------------------------------------

  transaction.create(
    historyRef,
    {
      uid:
        data.uid,

      type:
        "admob_verified",

      title:
        data.rewardPurpose ===
        "power_boost"
          ? "Stella Power Boost Ad Verified 🐱📺⚡"
          : "Stella Mining Start Ad Verified 🐱📺⛏️",

      amount:
        0,

      rewardType:
        "admob",

      rewardPurpose:
        data.rewardPurpose,

      adMobTransactionId:
        data.transactionId,

      transactionId:
        data.transactionId,

      adNetwork:
        data.adNetwork,

      adUnit:
        data.adUnit,

      rewardAmount:
        data.rewardAmount,

      rewardItem:
        data.rewardItem,

      timestamp:
        data.timestamp,

      keyId:
        data.keyId,

      signature:
        data.signature,

      customData:
        data.customData,

      userId:
        data.userId,

      createdAt:
        FieldValue.serverTimestamp(),
    }
  );

  // ----------------------------------------------------
  // NEW VERIFIED REWARD
  // ----------------------------------------------------

  return {
    success: true,

    verified: true,

    recorded: true,

    rewarded: false,

    duplicate: false,

    transactionId:
      data.transactionId,

    rewardPurpose:
      data.rewardPurpose,

    rewardAmount:
      data.rewardAmount,

    rewardItem:
      data.rewardItem,
  };
}

);
}

// ============================================================
// ADMOB SSV ENDPOINT
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
let ssvVerified =
false;

  try {
    // ----------------------------------------------------
    // METHOD
    // ----------------------------------------------------

    if (
      req.method ===
      "HEAD"
    ) {
      res
        .status(200)
        .end();

      return;
    }

    if (
      req.method !==
      "GET"
    ) {
      res
        .status(405)
        .json({
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

    // ----------------------------------------------------
    // QUERY
    // ----------------------------------------------------

    const query =
      req.query || {};

    // ----------------------------------------------------
    // HEALTH CHECK
    // ----------------------------------------------------

    if (
      Object.keys(
        query
      ).length ===
      0
    ) {
      res
        .status(200)
        .json({
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
        });

      return;
    }

    console.log(
      "🐱 AdMob SSV callback received."
    );

    // ----------------------------------------------------
    // CRYPTOGRAPHIC VERIFICATION
    // ----------------------------------------------------

    const verifiedAd =
      await verifyAdMobCallback(
        req
      );

    if (
      !verifiedAd ||
      verifiedAd.verified !==
        true
    ) {
      throw createError(
        "ADMOB_INVALID_SIGNATURE",
        "Invalid AdMob SSV callback."
      );
    }

    ssvVerified =
      true;

    // ----------------------------------------------------
    // DATA VALIDATION
    // ----------------------------------------------------

    const validatedAd =
      validateVerifiedAdData(
        verifiedAd
      );

    console.log(
      "🐱✅ AdMob SSV verified.",
      {
        uid:
          validatedAd.uid,

        transactionId:
          validatedAd.transactionId,

        rewardPurpose:
          validatedAd.rewardPurpose,
      }
    );

    // ----------------------------------------------------
    // SAVE
    // ----------------------------------------------------

    const result =
      await saveVerifiedAdMobReward(
        validatedAd
      );

    console.log(
      "🐱 AdMob reward stored.",
      {
        uid:
          validatedAd.uid,

        transactionId:
          validatedAd.transactionId,

        rewardPurpose:
          validatedAd.rewardPurpose,

        duplicate:
          result.duplicate,
      }
    );

    // ----------------------------------------------------
    // SUCCESS
    // ----------------------------------------------------

    res
      .status(200)
      .json(
        result
      );
  } catch (
    error
  ) {
    const code =
      error?.code
        ? String(
            error.code
          )
        : "UNKNOWN";

    const message =
      error?.message ||
      "Unknown AdMob error.";

    console.error(
      "❌ AdMob SSV processing failed.",
      {
        code,
        message,
      }
    );

    // ----------------------------------------------------
    // PERMANENT ERRORS
    // ----------------------------------------------------

    const permanentErrors =
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

        "ADMOB_INVALID_REWARD_CONFIGURATION",

        "ADMOB_TRANSACTION_CONFLICT",

        "ADMOB_AUDIT_CONSISTENCY_ERROR",

        "ADMOB_REWARD_REFERENCE_ERROR",

        "ADMOB_HISTORY_REFERENCE_ERROR",
      ]);

    if (
      permanentErrors.has(
        code
      )
    ) {
      res
        .status(200)
        .json({
          success:
            false,

          verified:
            ssvVerified,

          recorded:
            false,

          rewarded:
            false,

          error:
            code,
        });

      return;
    }

    // ----------------------------------------------------
    // TEMPORARY / INTERNAL ERROR
    // ----------------------------------------------------

    res
      .status(500)
      .json({
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
}

);

// ============================================================
// EXPORTS
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