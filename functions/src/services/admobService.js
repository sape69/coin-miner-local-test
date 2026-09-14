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

  console.log(
    "🐱 AdMob public keys loaded:",
    Object.keys(keys)
  );

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
// Get raw query string
// ==========================================
//
// IMPORTANT:
//
// AdMob SSV signatures are calculated from
// the exact query string received from AdMob.
//
// We must NOT:
//
// - reorder parameters
// - decode parameters
// - encode parameters again
// - parse and rebuild the query
//
// ==========================================

function getRawQueryString(
  url
) {
  if (
    !url ||
    typeof url !== "string"
  ) {
    return null;
  }

  const questionMarkIndex =
    url.indexOf("?");

  if (
    questionMarkIndex === -1
  ) {
    return null;
  }

  return url.substring(
    questionMarkIndex + 1
  );
}


// ==========================================
// Extract signed query string
// ==========================================
//
// Google AdMob SSV:
//
// Everything BEFORE:
//
// &signature=
//
// is the signed content.
//
// signature and key_id are not part of the
// signed content.
//
// ==========================================

function buildSignedQueryString(
  url
) {
  const queryString =
    getRawQueryString(
      url
    );

  if (
    !queryString
  ) {
    throw new Error(
      "Missing query string in AdMob callback URL."
    );
  }

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
// Extract raw signature
// ==========================================
//
// The signature itself is taken directly
// from the raw URL.
//
// This avoids possible differences between
// Express req.query and the original query.
//
// ==========================================

function extractRawSignature(
  url
) {
  const queryString =
    getRawQueryString(
      url
    );

  if (
    !queryString
  ) {
    return null;
  }

  const signatureMarker =
    "&signature=";

  const signatureIndex =
    queryString.indexOf(
      signatureMarker
    );

  if (
    signatureIndex === -1
  ) {
    return null;
  }

  let signature =
    queryString.substring(
      signatureIndex +
        signatureMarker.length
    );

  // key_id is expected after signature.
  const keyIdMarker =
    "&key_id=";

  const keyIdIndex =
    signature.indexOf(
      keyIdMarker
    );

  if (
    keyIdIndex !== -1
  ) {
    signature =
      signature.substring(
        0,
        keyIdIndex
      );
  }

  if (
    !signature
  ) {
    return null;
  }

  try {
    return decodeURIComponent(
      signature
    );
  } catch (
    error
  ) {
    return signature;
  }
}


// ==========================================
// Verify one signed query
// ==========================================

function verifySignedQuery(
  signedQueryString,
  signatureBuffer,
  publicKey
) {
  const verifier =
    crypto.createVerify(
      "SHA256"
    );

  verifier.update(
    signedQueryString,
    "utf8"
  );

  verifier.end();

  return verifier.verify(
    {
      key:
        publicKey,

      dsaEncoding:
        "der",
    },
    signatureBuffer
  );
}


// ==========================================
// Verify cryptographic signature
// ==========================================

async function verifyAdMobSignature(
  req
) {
  console.log(
    "🐱 AdMob SSV signature verification started."
  );

  // ----------------------------------------
  // Get key ID
  // ----------------------------------------

  const keyId =
    req.query?.key_id;

  if (
    !keyId
  ) {
    throw new Error(
      "Missing AdMob key_id."
    );
  }

  const normalizedKeyId =
    String(
      keyId
    ).trim();

  console.log(
    "🐱 AdMob SSV key_id:",
    normalizedKeyId
  );

  // ----------------------------------------
  // Get AdMob public keys
  // ----------------------------------------

  const publicKeys =
    await getAdMobPublicKeys();

  const publicKey =
    publicKeys[
      normalizedKeyId
    ];

  if (
    !publicKey
  ) {
    throw new Error(
      `Unknown AdMob public key: ${normalizedKeyId}`
    );
  }

  // ----------------------------------------
  // Collect possible raw URLs
  // ----------------------------------------
  //
  // Cloud Functions / Express may expose
  // the incoming URL through either req.url
  // or req.originalUrl.
  //
  // We test both representations.
  //
  // No security is weakened because the
  // cryptographic signature MUST still pass.
  // ----------------------------------------

  const candidateUrls = [];

  if (
    typeof req.url === "string" &&
    req.url.length > 0
  ) {
    candidateUrls.push(
      {
        name: "req.url",
        value: req.url,
      }
    );
  }

  if (
    typeof req.originalUrl === "string" &&
    req.originalUrl.length > 0 &&
    req.originalUrl !== req.url
  ) {
    candidateUrls.push(
      {
        name: "req.originalUrl",
        value:
          req.originalUrl,
      }
    );
  }

  if (
    candidateUrls.length === 0
  ) {
    throw new Error(
      "Missing original request URL."
    );
  }

  // ----------------------------------------
  // Get signature
  // ----------------------------------------
  //
  // Prefer the raw signature from the URL.
  // Fall back to req.query only if necessary.
  //
  // ----------------------------------------

  let rawSignature = null;

  for (
    const candidate of candidateUrls
  ) {
    const extracted =
      extractRawSignature(
        candidate.value
      );

    if (
      extracted
    ) {
      rawSignature =
        extracted;

      break;
    }
  }

  if (
    !rawSignature
  ) {
    const querySignature =
      req.query?.signature;

    if (
      querySignature
    ) {
      rawSignature =
        String(
          querySignature
        );
    }
  }

  if (
    !rawSignature
  ) {
    throw new Error(
      "Missing AdMob signature."
    );
  }

  // ----------------------------------------
  // Decode signature
  // ----------------------------------------

  const signatureBuffer =
    base64UrlToBuffer(
      rawSignature
    );

  console.log(
    "🐱 AdMob SSV signature received:",
    {
      length:
        signatureBuffer.length,

      firstByte:
        signatureBuffer.length > 0
          ? signatureBuffer[0]
          : null,

      candidateUrlCount:
        candidateUrls.length,
    }
  );

  // ----------------------------------------
  // Try each raw URL representation
  // ----------------------------------------

  let successfulSource =
    null;

  for (
    const candidate of candidateUrls
  ) {
    try {
      const signedQueryString =
        buildSignedQueryString(
          candidate.value
        );

      // ------------------------------------
      // Diagnostic hash only.
      //
      // We do NOT log the actual signed
      // query because it may contain UID
      // or other callback data.
      // ------------------------------------

      const queryHash =
        crypto
          .createHash(
            "sha256"
          )
          .update(
            signedQueryString,
            "utf8"
          )
          .digest(
            "hex"
          );

      console.log(
        "🐱 AdMob SSV candidate:",
        {
          source:
            candidate.name,

          signedQueryLength:
            signedQueryString.length,

          signedQueryHash:
            queryHash,
        }
      );

      const isValid =
        verifySignedQuery(
          signedQueryString,
          signatureBuffer,
          publicKey
        );

      if (
        isValid
      ) {
        successfulSource =
          candidate.name;

        console.log(
          "🐱✅ AdMob SSV cryptographic signature is valid.",
          {
            source:
              successfulSource,
          }
        );

        return true;
      }

      console.log(
        "🐱 AdMob SSV signature did not match candidate:",
        candidate.name
      );
    } catch (
      error
    ) {
      console.error(
        "🐱 AdMob SSV candidate verification error:",
        {
          source:
            candidate.name,

          message:
            error.message,
        }
      );
    }
  }

  // ----------------------------------------
  // Signature failed
  // ----------------------------------------

  throw new Error(
    "Invalid AdMob SSV signature."
  );
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

  // Decode percent-encoded custom data
  // BEFORE checking the final length.

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