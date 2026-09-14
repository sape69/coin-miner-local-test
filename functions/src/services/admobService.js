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

  console.log(
    "🐱 Downloading AdMob SSV public keys..."
  );

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
      key.keyId === undefined ||
      key.keyId === null ||
      !key.pem
    ) {
      continue;
    }

    keys[String(key.keyId)] =
      String(key.pem);
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
// Base64 decoder
// ==========================================
//
// AdMob SSV signatures are Base64 encoded.
// This decoder also supports Base64URL just
// in case the transport representation uses
// URL-safe characters.
//

function base64ToBuffer(
  value
) {
  if (
    !value ||
    typeof value !== "string"
  ) {
    throw new Error(
      "Invalid AdMob signature value."
    );
  }

  let normalized =
    value.trim();

  // Convert URL-safe Base64 to standard
  // Base64.
  normalized =
    normalized
      .replace(/-/g, "+")
      .replace(/_/g, "/");

  // Remove whitespace that could have been
  // introduced by transport.
  normalized =
    normalized.replace(
      /\s/g,
      ""
    );

  while (
    normalized.length % 4 !== 0
  ) {
    normalized += "=";
  }

  const buffer =
    Buffer.from(
      normalized,
      "base64"
    );

  if (
    !buffer ||
    buffer.length === 0
  ) {
    throw new Error(
      "AdMob signature could not be decoded."
    );
  }

  return buffer;
}


// ==========================================
// Get raw request URL
// ==========================================
//
// We deliberately prefer the raw URL
// representation because AdMob signs the
// exact query string.
//
// Possible sources in Firebase / Express:
//
//   req.originalUrl
//   req.url
//   req.rawUrl
//
// We never rebuild the signed query from
// req.query because that could change:
//   - encoding
//   - parameter order
//   - escaped characters
//
// ==========================================

function getCandidateUrls(
  req
) {
  const candidates = [];

  const addCandidate = (
    name,
    value
  ) => {
    if (
      typeof value !== "string" ||
      value.length === 0
    ) {
      return;
    }

    if (
      candidates.some(
        (candidate) =>
          candidate.value === value
      )
    ) {
      return;
    }

    candidates.push({
      name,
      value,
    });
  };

  addCandidate(
    "req.originalUrl",
    req.originalUrl
  );

  addCandidate(
    "req.url",
    req.url
  );

  addCandidate(
    "req.rawUrl",
    req.rawUrl
  );

  return candidates;
}


// ==========================================
// Get raw query string
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

  const queryString =
    url.substring(
      questionMarkIndex + 1
    );

  if (
    queryString.length === 0
  ) {
    return null;
  }

  return queryString;
}


// ==========================================
// Extract signed query string
// ==========================================
//
// According to Google AdMob SSV:
//
// The signature is calculated over all
// query parameters BEFORE:
//
//   &signature=
//
// The signature and key_id themselves are
// NOT part of the signed content.
//
// IMPORTANT:
// We return the exact raw characters from
// the incoming URL.
//

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
      "AdMob signature parameter not found in raw query string."
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

  // According to AdMob SSV the key_id
  // parameter follows the signature.
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

  // The signature value itself is URL
  // encoded in the HTTP request.
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
// Get signature from request
// ==========================================
//
// Raw URL is preferred.
// req.query is only a fallback.
//

function getAdMobSignature(
  req,
  candidateUrls
) {
  for (
    const candidate of candidateUrls
  ) {
    const rawSignature =
      extractRawSignature(
        candidate.value
      );

    if (
      rawSignature
    ) {
      return {
        value:
          rawSignature,

        source:
          candidate.name,
      };
    }
  }

  const querySignature =
    req.query?.signature;

  if (
    querySignature !== undefined &&
    querySignature !== null &&
    String(querySignature).length > 0
  ) {
    return {
      value:
        String(
          querySignature
        ),

      source:
        "req.query.signature",
    };
  }

  return null;
}


// ==========================================
// Verify ECDSA / SHA256 signature
// ==========================================
//
// AdMob SSV uses SHA256 with ECDSA.
// Google's SSV signature uses DER encoding.
//

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
// Cryptographic signature verification
// ==========================================

async function verifyAdMobSignature(
  req
) {
  console.log(
    "🐱 AdMob SSV signature verification started."
  );

  // ----------------------------------------
  // Key ID
  // ----------------------------------------

  const keyId =
    req.query?.key_id;

  if (
    keyId === undefined ||
    keyId === null ||
    String(keyId).trim().length === 0
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
  // Load Google public keys
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

  console.log(
    "🐱 AdMob public key found for key_id:",
    normalizedKeyId
  );

  // ----------------------------------------
  // Candidate raw URLs
  // ----------------------------------------

  const candidateUrls =
    getCandidateUrls(
      req
    );

  if (
    candidateUrls.length === 0
  ) {
    throw new Error(
      "Missing original request URL."
    );
  }

  console.log(
    "🐱 AdMob SSV URL candidates:",
    candidateUrls.map(
      (candidate) =>
        candidate.name
    )
  );

  // ----------------------------------------
  // Signature
  // ----------------------------------------

  const signatureInfo =
    getAdMobSignature(
      req,
      candidateUrls
    );

  if (
    !signatureInfo
  ) {
    throw new Error(
      "Missing AdMob signature."
    );
  }

  console.log(
    "🐱 AdMob SSV signature source:",
    signatureInfo.source
  );

  const signatureBuffer =
    base64ToBuffer(
      signatureInfo.value
    );

  console.log(
    "🐱 AdMob SSV signature decoded:",
    {
      length:
        signatureBuffer.length,

      firstByte:
        signatureBuffer.length > 0
          ? signatureBuffer[0]
          : null,
    }
  );

  // ----------------------------------------
  // Verify each possible raw URL
  // ----------------------------------------

  for (
    const candidate of candidateUrls
  ) {
    try {
      const signedQueryString =
        buildSignedQueryString(
          candidate.value
        );

      // ------------------------------------
      // Diagnostic hash.
      //
      // We intentionally do NOT log the
      // actual signed query because it can
      // contain user/custom data.
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
        console.log(
          "🐱✅ AdMob SSV cryptographic signature is VALID.",
          {
            source:
              candidate.name,

            keyId:
              normalizedKeyId,
          }
        );

        return true;
      }

      console.log(
        "🐱❌ AdMob SSV signature did not match:",
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
    String(
      value
    ).trim();

  if (
    normalized.length === 0
  ) {
    throw new Error(
      "Invalid AdMob custom_data."
    );
  }

  // Decode percent-encoded custom data.
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

  // Only allow the characters our
  // application uses for UID and purpose.
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
        String(
          customData
        ).trim().length > 0,

      hasUserId:
        userId !== undefined &&
        userId !== null &&
        String(
          userId
        ).trim().length > 0,

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
// The callback is accepted ONLY when:
//
// 1. The AdMob cryptographic signature is
//    valid.
// 2. The AdMob ad unit is correct.
// 3. The reward amount is correct.
// 4. The reward item is correct.
// 5. A transaction ID exists.
// 6. Valid custom_data exists.
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
    "🐱✅ AdMob SSV signature verified."
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