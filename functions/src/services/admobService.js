"use strict";

const crypto = require("crypto");

const {
  ADMOB_SSV_AD_UNIT_ID,
  ADMOB_SSV_REWARD_AMOUNT,
  ADMOB_SSV_REWARD_ITEM,
} = require("../config/miningConfig");

// ==========================================
// Google AdMob SSV
// ==========================================

const ADMOB_PUBLIC_KEYS_URL =
  "https://www.gstatic.com/admob/reward/verifier-keys.json";

// AdMob can rotate its public keys.
// Cache them for one hour.
const PUBLIC_KEY_CACHE_MS =
  60 * 60 * 1000;

let cachedKeys = null;
let cachedKeysAt = 0;


// ==========================================
// Get AdMob public keys
// ==========================================

async function getAdMobPublicKeys() {
  const now = Date.now();

  if (
    cachedKeys &&
    now - cachedKeysAt <
      PUBLIC_KEY_CACHE_MS
  ) {
    return cachedKeys;
  }

  const response =
    await fetch(
      ADMOB_PUBLIC_KEYS_URL
    );

  if (!response.ok) {
    throw new Error(
      `Failed to fetch AdMob public keys: ${response.status}`
    );
  }

  const data =
    await response.json();

  if (
    !data ||
    !Array.isArray(data.keys)
  ) {
    throw new Error(
      "Invalid AdMob public key response."
    );
  }

  const keys = {};

  for (
    const key of data.keys
  ) {
    if (
      !key ||
      !key.keyId ||
      !key.pem
    ) {
      continue;
    }

    keys[String(key.keyId)] =
      key.pem;
  }

  if (
    Object.keys(keys).length === 0
  ) {
    throw new Error(
      "No valid AdMob public keys found."
    );
  }

  cachedKeys =
    keys;

  cachedKeysAt =
    now;

  return keys;
}


// ==========================================
// Base64URL decoder
// ==========================================

function base64UrlToBuffer(
  value
) {
  if (
    !value ||
    typeof value !== "string"
  ) {
    throw new Error(
      "Invalid base64url value."
    );
  }

  let normalized =
    value
      .replace(/-/g, "+")
      .replace(/_/g, "/");

  while (
    normalized.length % 4 !== 0
  ) {
    normalized += "=";
  }

  return Buffer.from(
    normalized,
    "base64"
  );
}


// ==========================================
// Get signed query string
// ==========================================
//
// IMPORTANT:
//
// AdMob signs ONLY the query string.
//
// Example:
//
// ad_network=...
// &ad_unit=...
// &reward_amount=...
// &reward_item=...
// &timestamp=...
// &transaction_id=...
// &user_id=...
//
// The URL path/domain must NOT be included.
//
// The query parameter order and encoding
// must remain exactly as received.
//
// ==========================================

function buildSignedQueryString(
  originalUrl
) {
  if (
    !originalUrl ||
    typeof originalUrl !== "string"
  ) {
    throw new Error(
      "Missing original request URL."
    );
  }

  // ----------------------------------------
  // Find query string
  // ----------------------------------------

  const questionMarkIndex =
    originalUrl.indexOf("?");

  if (
    questionMarkIndex === -1
  ) {
    throw new Error(
      "Missing query string in AdMob callback URL."
    );
  }

  const queryString =
    originalUrl.substring(
      questionMarkIndex + 1
    );

  // ----------------------------------------
  // Find signature
  // ----------------------------------------
  //
  // Google specifies that signature and
  // key_id are the final parameters.
  //
  // Therefore everything before
  // &signature= is the signed content.
  // ----------------------------------------

  const signatureMarker =
    "&signature=";

  const signatureIndex =
    queryString.indexOf(
      signatureMarker
    );

  if (
    signatureIndex === -1
  ) {
    throw new Error(
      "AdMob signature parameter not found."
    );
  }

  const signedQueryString =
    queryString.substring(
      0,
      signatureIndex
    );

  if (
    signedQueryString.length === 0
  ) {
    throw new Error(
      "Empty AdMob signed query string."
    );
  }

  return signedQueryString;
}


// ==========================================
// Verify cryptographic signature
// ==========================================

async function verifyAdMobSignature(
  req
) {
  // ----------------------------------------
  // IMPORTANT
  // ----------------------------------------
  //
  // Use the original URL because the exact
  // query parameter order and encoding must
  // remain unchanged.
  //
  // ----------------------------------------

  const originalUrl =
    req.originalUrl ||
    req.url;

  if (
    !originalUrl
  ) {
    throw new Error(
      "Missing originalUrl."
    );
  }

  const signature =
    req.query?.signature;

  const keyId =
    req.query?.key_id;

  if (
    !signature
  ) {
    throw new Error(
      "Missing AdMob signature."
    );
  }

  if (
    !keyId
  ) {
    throw new Error(
      "Missing AdMob key_id."
    );
  }

  console.log(
    "🐱 AdMob SSV signature verification started."
  );

  console.log(
    "🐱 AdMob SSV key_id:",
    String(keyId)
  );

  // ----------------------------------------
  // Get Google's public keys
  // ----------------------------------------

  const publicKeys =
    await getAdMobPublicKeys();

  const publicKey =
    publicKeys[
      String(keyId)
    ];

  if (
    !publicKey
  ) {
    throw new Error(
      `Unknown AdMob public key: ${keyId}`
    );
  }

  // ----------------------------------------
  // Extract ONLY the signed query string
  // ----------------------------------------

  const signedQueryString =
    buildSignedQueryString(
      originalUrl
    );

  console.log(
    "🐱 AdMob SSV signed query extracted."
  );

  // ----------------------------------------
  // Decode signature
  // ----------------------------------------

  const signatureBuffer =
    base64UrlToBuffer(
      String(signature)
    );

  // ----------------------------------------
  // Verify ECDSA SHA-256
  // ----------------------------------------

  const verifier =
    crypto.createVerify(
      "SHA256"
    );

  verifier.update(
    signedQueryString,
    "utf8"
  );

  verifier.end();

  const isValid =
    verifier.verify(
      {
        key:
          publicKey,

        dsaEncoding:
          "der",
      },
      signatureBuffer
    );

  if (
    !isValid
  ) {
    throw new Error(
      "Invalid AdMob SSV signature."
    );
  }

  console.log(
    "🐱✅ AdMob SSV cryptographic signature is valid."
  );

  return true;
}


// ==========================================
// Normalize custom data
// ==========================================

function normalizeCustomData(
  value
) {
  if (
    value === undefined ||
    value === null
  ) {
    throw new Error(
      "Missing AdMob custom_data."
    );
  }

  let normalized =
    String(value).trim();

  if (
    normalized.length === 0
  ) {
    throw new Error(
      "Invalid AdMob custom_data."
    );
  }

  if (
    normalized.length > 128
  ) {
    throw new Error(
      "AdMob custom_data is too long."
    );
  }

  // ----------------------------------------
  // Decode percent-encoded custom data
  // ----------------------------------------

  if (
    normalized.includes("%")
  ) {
    try {
      normalized =
        decodeURIComponent(
          normalized
        );
    } catch (
      error
    ) {
      throw new Error(
        "Invalid percent-encoded AdMob custom_data."
      );
    }
  }

  normalized =
    normalized.trim();

  if (
    normalized.length === 0
  ) {
    throw new Error(
      "Invalid AdMob custom_data."
    );
  }

  if (
    normalized.length > 128
  ) {
    throw new Error(
      "AdMob custom_data is too long."
    );
  }

  // ----------------------------------------
  // Validate format
  // ----------------------------------------

  if (
    !/^[A-Za-z0-9._:-]+$/.test(
      normalized
    )
  ) {
    throw new Error(
      "Invalid AdMob custom_data format."
    );
  }

  return normalized;
}


// ==========================================
// Validate callback data
// ==========================================

function validateAdMobCallbackData(
  req
) {
  const query =
    req.query || {};

  const adUnit =
    query.ad_unit;

  const rewardAmount =
    query.reward_amount;

  const rewardItem =
    query.reward_item;

  const transactionId =
    query.transaction_id;

  const customData =
    query.custom_data;

  const userId =
    query.user_id;

  const timestamp =
    query.timestamp;


  // ========================================
  // Diagnostic logging
  // ========================================

  console.log(
    "🐱 AdMob SSV callback parameters received:",
    {
      adNetwork:
        query.ad_network ||
        null,

      adUnit:
        adUnit ||
        null,

      rewardAmount:
        rewardAmount ??
        null,

      rewardItem:
        rewardItem ||
        null,

      transactionId:
        transactionId ||
        null,

      hasCustomData:
        customData !== undefined &&
        customData !== null &&
        String(customData)
          .trim()
          .length > 0,

      hasUserId:
        userId !== undefined &&
        userId !== null &&
        String(userId)
          .trim()
          .length > 0,

      keyId:
        query.key_id ||
        null,

      timestamp:
        timestamp ||
        null,
    }
  );


  // ========================================
  // Ad Unit
  // ========================================

  if (
    !adUnit
  ) {
    throw new Error(
      "Missing AdMob ad_unit."
    );
  }

  if (
    String(adUnit) !==
    String(ADMOB_SSV_AD_UNIT_ID)
  ) {
    throw new Error(
      `Unexpected AdMob ad_unit: ${adUnit}. Expected: ${ADMOB_SSV_AD_UNIT_ID}`
    );
  }


  // ========================================
  // Reward amount
  // ========================================

  if (
    rewardAmount === undefined ||
    rewardAmount === null
  ) {
    throw new Error(
      "Missing AdMob reward_amount."
    );
  }

  const numericRewardAmount =
    Number(
      rewardAmount
    );

  if (
    !Number.isFinite(
      numericRewardAmount
    ) ||
    numericRewardAmount !==
      Number(
        ADMOB_SSV_REWARD_AMOUNT
      )
  ) {
    throw new Error(
      `Unexpected AdMob reward_amount: ${rewardAmount}. Expected: ${ADMOB_SSV_REWARD_AMOUNT}`
    );
  }


  // ========================================
  // Reward item
  // ========================================

  if (
    !rewardItem
  ) {
    throw new Error(
      "Missing AdMob reward_item."
    );
  }

  if (
    String(rewardItem) !==
    String(ADMOB_SSV_REWARD_ITEM)
  ) {
    throw new Error(
      `Unexpected AdMob reward_item: ${rewardItem}. Expected: ${ADMOB_SSV_REWARD_ITEM}`
    );
  }


  // ========================================
  // Transaction ID
  // ========================================

  if (
    !transactionId
  ) {
    throw new Error(
      "Missing AdMob transaction_id."
    );
  }

  const normalizedTransactionId =
    String(
      transactionId
    ).trim();

  if (
    normalizedTransactionId.length === 0
  ) {
    throw new Error(
      "Invalid AdMob transaction_id."
    );
  }

  if (
    normalizedTransactionId.length > 256
  ) {
    throw new Error(
      "AdMob transaction_id is too long."
    );
  }


  // ========================================
  // Custom data
  // ========================================

  const normalizedCustomData =
    normalizeCustomData(
      customData
    );


  // ========================================
  // Optional user ID
  // ========================================

  let normalizedUserId =
    null;

  if (
    userId !== undefined &&
    userId !== null
  ) {
    const value =
      String(
        userId
      ).trim();

    if (
      value.length > 0
    ) {
      normalizedUserId =
        value;
    }
  }


  // ========================================
  // Timestamp
  // ========================================

  if (
    timestamp === undefined ||
    timestamp === null
  ) {
    throw new Error(
      "Missing AdMob timestamp."
    );
  }

  const numericTimestamp =
    Number(
      timestamp
    );

  if (
    !Number.isFinite(
      numericTimestamp
    ) ||
    numericTimestamp <= 0
  ) {
    throw new Error(
      `Invalid AdMob timestamp: ${timestamp}`
    );
  }


  // ========================================
  // Return trusted callback data
  // ========================================

  const result = {
    adNetwork:
      query.ad_network ||
      null,

    adUnit:
      String(
        adUnit
      ),

    customData:
      normalizedCustomData,

    keyId:
      String(
        query.key_id
      ),

    rewardAmount:
      numericRewardAmount,

    rewardItem:
      String(
        rewardItem
      ),

    timestamp:
      numericTimestamp,

    transactionId:
      normalizedTransactionId,

    userId:
      normalizedUserId,
  };


  console.log(
    "🐱✅ AdMob SSV callback data validated:",
    {
      adUnit:
        result.adUnit,

      rewardAmount:
        result.rewardAmount,

      rewardItem:
        result.rewardItem,

      transactionId:
        result.transactionId,

      customData:
        result.customData,

      userId:
        result.userId,
    }
  );

  return result;
}


// ==========================================
// Main SSV verification
// ==========================================
//
// Returns callback data ONLY after:
//
// 1. Cryptographic verification succeeds.
// 2. Ad unit is correct.
// 3. Reward amount is correct.
// 4. Reward item is correct.
// 5. Transaction ID exists.
// 6. Signed custom_data exists.
//
// ==========================================

async function verifyAdMobCallback(
  req
) {
  console.log(
    "🐱 AdMob SSV verification started."
  );

  await verifyAdMobSignature(
    req
  );

  console.log(
    "🐱 AdMob SSV signature verified."
  );

  return validateAdMobCallbackData(
    req
  );
}


// ==========================================
// Export
// ==========================================

module.exports = {
  verifyAdMobCallback,
};