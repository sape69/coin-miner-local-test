"use strict";

const crypto = require("crypto");

/**
 * ============================================================
 * STELLURIINI - ADMOB SERVICE
 * ============================================================
 *
 * Handles:
 *  - AdMob rewarded SSV verification
 *  - AdMob public key download/cache
 *  - SSV parameter validation
 *
 * IMPORTANT:
 * AdMob SSV signature verification follows Google's verifier
 * behavior:
 *
 * 1. The original query string is received from Google.
 * 2. The signature and key_id parameters are extracted without
 *    modifying the original query string.
 * 3. The content before &signature= is URL-decoded for the
 *    cryptographic verification step.
 * 4. Parameter order is preserved.
 * 5. The decoded query content is verified using ECDSA SHA-256
 *    with DER-encoded signatures.
 *
 * IMPORTANT:
 * Do NOT use URLSearchParams.toString() to recreate the signed
 * query because that can change encoding or parameter format.
 *
 * Production logging is intentionally kept concise.
 * Detailed URL/signature diagnostics are not logged because
 * they are only needed during troubleshooting.
 * ============================================================
 */

// ============================================================
// AdMob configuration
// ============================================================

const ADMOB_SSV_KEYS_URL =
  "https://www.gstatic.com/admob/reward/verifier-keys.json";

// Public keys must not be cached longer than 24 hours.
const PUBLIC_KEY_CACHE_MS =
  23 * 60 * 60 * 1000;

let cachedPublicKeys = null;
let cachedPublicKeysAt = 0;

// ============================================================
// Stelluriini AdMob ad units
// ============================================================
//
// IMPORTANT:
// AdMob SSV "ad_unit" contains the numeric ad unit ID only.
// It does NOT contain the full ca-app-pub-.../... string.
// ============================================================

const ADMOB_AD_UNITS = {
  mining_start: "6674097787",
  power_boost: "7225738491",
};

// ============================================================
// Expected rewards
// ============================================================

const REWARD_DEFINITIONS = {
  mining_start: {
    rewardItem: "Mining",
    rewardAmount: 1,
  },

  power_boost: {
    rewardItem: "Power Boost",
    rewardAmount: 1,
  },
};

// ============================================================
// HTTP helper
// ============================================================

async function fetchJson(url) {
  const response = await fetch(url);

  if (!response.ok) {
    throw new Error(
      `AdMob public key server returned HTTP ${response.status}`,
    );
  }

  return response.json();
}

// ============================================================
// Public key loading
// ============================================================

async function getAdMobPublicKeys(
  forceRefresh = false,
) {
  const now = Date.now();

  if (
    !forceRefresh &&
    cachedPublicKeys &&
    now - cachedPublicKeysAt <
      PUBLIC_KEY_CACHE_MS
  ) {
    return cachedPublicKeys;
  }

  const data =
    await fetchJson(
      ADMOB_SSV_KEYS_URL,
    );

  if (
    !data ||
    !Array.isArray(data.keys)
  ) {
    throw new Error(
      "AdMob public key response is invalid.",
    );
  }

  const keys = new Map();

  for (const key of data.keys) {
    if (
      key &&
      key.keyId !== undefined &&
      typeof key.pem === "string" &&
      key.pem.length > 0
    ) {
      keys.set(
        String(key.keyId),
        key.pem,
      );
    }
  }

  if (keys.size === 0) {
    throw new Error(
      "No usable AdMob public keys were returned.",
    );
  }

  cachedPublicKeys = keys;
  cachedPublicKeysAt = now;

  return keys;
}

// ============================================================
// Raw query extraction
// ============================================================

/**
 * Get the original query string from the request.
 *
 * IMPORTANT:
 * This function intentionally does NOT decode the query.
 *
 * The raw query is required so that we can:
 *
 *  - locate signature=
 *  - locate key_id
 *  - preserve Google's original parameter order
 *  - avoid re-encoding the query
 */
function getRawQueryString(req) {
  if (!req) {
    throw new Error(
      "Missing HTTP request.",
    );
  }

  if (
    typeof req.originalUrl ===
    "string"
  ) {
    const questionMark =
      req.originalUrl.indexOf("?");

    if (questionMark >= 0) {
      return req.originalUrl.substring(
        questionMark + 1,
      );
    }
  }

  if (
    typeof req.url ===
    "string"
  ) {
    const questionMark =
      req.url.indexOf("?");

    if (questionMark >= 0) {
      return req.url.substring(
        questionMark + 1,
      );
    }
  }

  if (
    typeof req.rawUrl ===
    "string"
  ) {
    const questionMark =
      req.rawUrl.indexOf("?");

    if (questionMark >= 0) {
      return req.rawUrl.substring(
        questionMark + 1,
      );
    }
  }

  throw new Error(
    "AdMob SSV query string is missing.",
  );
}

// ============================================================
// Google-compatible query decoding
// ============================================================

/**
 * Decode the signed query content for cryptographic
 * verification.
 *
 * IMPORTANT:
 *
 * - decodeURIComponent() decodes percent-encoded data.
 * - It does NOT convert "+" to a space.
 * - It does NOT reorder parameters.
 * - It does NOT rebuild or re-encode the query.
 *
 * Example:
 *
 *   foo=hello%20world
 *
 * becomes:
 *
 *   foo=hello world
 *
 * while:
 *
 *   foo=a+b
 *
 * remains:
 *
 *   foo=a+b
 */
function decodeSignedQueryString(
  signedQueryString,
) {
  if (
    typeof signedQueryString !==
    "string"
  ) {
    throw new Error(
      "AdMob signed query string is invalid.",
    );
  }

  try {
    return decodeURIComponent(
      signedQueryString,
    );
  } catch (error) {
    console.error(
      "🐱❌ AdMob SSV signed query decoding failed.",
      {
        message:
          error &&
          error.message
            ? error.message
            : String(error),
      },
    );

    throw new Error(
      "AdMob SSV signed query contains invalid URL encoding.",
    );
  }
}

// ============================================================
// Base64 URL-safe decoding
// ============================================================

function decodeAdMobSignature(
  signature,
) {
  if (
    !signature ||
    typeof signature !== "string"
  ) {
    throw new Error(
      "AdMob SSV signature is missing.",
    );
  }

  // AdMob uses URL-safe Base64.
  const normalized =
    signature
      .replace(/-/g, "+")
      .replace(/_/g, "/");

  const padding =
    normalized.length % 4;

  const padded =
    padding === 0
      ? normalized
      : normalized +
        "=".repeat(
          4 - padding,
        );

  return Buffer.from(
    padded,
    "base64",
  );
}

// ============================================================
// Signature verification
// ============================================================

async function verifyAdMobSignature(
  req,
) {
  const rawQueryString =
    getRawQueryString(req);

  /**
   * Google's SSV format places:
   *
   *   ...signed parameters...
   *   &signature=...
   *   &key_id=...
   *
   * at the end.
   *
   * We use the raw query to locate these parameters.
   */

  const signatureMarker =
    "&signature=";

  const signatureIndex =
    rawQueryString.indexOf(
      signatureMarker,
    );

  if (signatureIndex === -1) {
    throw new Error(
      "AdMob SSV signature parameter was not found.",
    );
  }

  /**
   * Exact raw content received before &signature=.
   */
  const rawSignedQueryString =
    rawQueryString.substring(
      0,
      signatureIndex,
    );

  /**
   * Extract signature and key_id from the raw query.
   *
   * We do NOT reconstruct the signed content from these
   * parameters.
   */
  const signatureAndKeyId =
    rawQueryString.substring(
      signatureIndex + 1,
    );

  const signatureParams =
    new URLSearchParams(
      signatureAndKeyId,
    );

  const signature =
    signatureParams.get(
      "signature",
    );

  const keyId =
    signatureParams.get(
      "key_id",
    );

  if (!signature) {
    throw new Error(
      "AdMob SSV signature value is missing.",
    );
  }

  if (!keyId) {
    throw new Error(
      "AdMob SSV key_id value is missing.",
    );
  }

  /**
   * Google's verifier decodes the signed query content
   * before cryptographic verification.
   */
  const signedQueryString =
    decodeSignedQueryString(
      rawSignedQueryString,
    );

  const signatureBuffer =
    decodeAdMobSignature(
      signature,
    );

  /**
   * AdMob uses ECDSA with SHA-256.
   *
   * Google's verifier uses DER-encoded ECDSA signatures.
   */
  let publicKeys =
    await getAdMobPublicKeys(
      false,
    );

  let publicKey =
    publicKeys.get(
      String(keyId),
    );

  /**
   * If the key ID is not in our cached list,
   * refresh once.
   *
   * AdMob rotates public keys.
   */
  if (!publicKey) {
    publicKeys =
      await getAdMobPublicKeys(
        true,
      );

    publicKey =
      publicKeys.get(
        String(keyId),
      );
  }

  if (!publicKey) {
    throw new Error(
      `AdMob SSV public key not found for key_id=${keyId}`,
    );
  }

  /**
   * ECDSA SHA-256 verification.
   *
   * IMPORTANT:
   *
   * Verify the Google-compatible decoded query string.
   *
   * Do NOT:
   *
   *  - use URLSearchParams.toString()
   *  - reorder parameters
   *  - rebuild the query
   *  - JSON.stringify()
   */
  const verifier =
    crypto.createVerify(
      "SHA256",
    );

  verifier.update(
    Buffer.from(
      signedQueryString,
      "utf8",
    ),
  );

  verifier.end();

  const verified =
    verifier.verify(
      publicKey,
      signatureBuffer,
    );

  if (!verified) {
    console.error(
      "🐱❌ AdMob SSV signature INVALID.",
      {
        keyId,
      },
    );

    throw new Error(
      "AdMob SSV signature verification failed.",
    );
  }

  console.log(
    "🐱✅ AdMob SSV signature VERIFIED.",
    {
      keyId,
    },
  );

  /**
   * Only parse parameters AFTER signature verification.
   *
   * URLSearchParams is safe here because it is used only
   * to read the already verified callback parameters.
   */
  const params =
    new URLSearchParams(
      rawQueryString,
    );

  return {
    verified: true,

    keyId,

    rawQueryString,

    signedQueryString,

    params,
  };
}

// ============================================================
// Parameter helpers
// ============================================================

function getParam(
  params,
  name,
) {
  const value =
    params.get(name);

  if (
    value === null ||
    value === undefined
  ) {
    return "";
  }

  return value;
}

function parseInteger(
  value,
  fallback = 0,
) {
  const number =
    Number(value);

  if (
    !Number.isFinite(number)
  ) {
    return fallback;
  }

  return Math.trunc(number);
}

// ============================================================
// Custom data parser
// ============================================================

function parseCustomData(
  customData,
) {
  if (
    !customData ||
    typeof customData !==
      "string"
  ) {
    return {
      uid: "",
      rewardPurpose: "",
    };
  }

  const decoded =
    customData;

  /**
   * Supported formats:
   *
   * UID
   *
   * UID:power_boost
   *
   * UID:mining_start
   */

  const separator =
    decoded.indexOf(":");

  if (separator === -1) {
    return {
      uid: decoded.trim(),
      rewardPurpose:
        "power_boost",
    };
  }

  return {
    uid: decoded
      .substring(
        0,
        separator,
      )
      .trim(),

    rewardPurpose: decoded
      .substring(
        separator + 1,
      )
      .trim(),
  };
}

// ============================================================
// Main SSV verification
// ============================================================

async function verifyAdMobCallback(
  req,
) {
  const verification =
    await verifyAdMobSignature(
      req,
    );

  const params =
    verification.params;

  const adNetwork =
    getParam(
      params,
      "ad_network",
    );

  const adUnit =
    getParam(
      params,
      "ad_unit",
    );

  const customData =
    getParam(
      params,
      "custom_data",
    );

  const rewardAmount =
    getParam(
      params,
      "reward_amount",
    );

  const rewardItem =
    getParam(
      params,
      "reward_item",
    );

  const timestamp =
    getParam(
      params,
      "timestamp",
    );

  const transactionId =
    getParam(
      params,
      "transaction_id",
    );

  const userId =
    getParam(
      params,
      "user_id",
    );

  const parsedCustomData =
    parseCustomData(
      customData,
    );

  const uid =
    parsedCustomData.uid;

  const rewardPurpose =
    parsedCustomData.rewardPurpose;

  // ==========================================================
  // Purpose validation
  // ==========================================================

  if (
    rewardPurpose !==
      "mining_start" &&
    rewardPurpose !==
      "power_boost"
  ) {
    throw new Error(
      `Invalid AdMob reward purpose: ${rewardPurpose}`,
    );
  }

  // ==========================================================
  // UID validation
  // ==========================================================

  if (!uid) {
    throw new Error(
      "AdMob SSV custom_data does not contain a UID.",
    );
  }

  // ==========================================================
  // Ad unit validation
  // ==========================================================

  const expectedAdUnit =
    ADMOB_AD_UNITS[
      rewardPurpose
    ];

  if (!expectedAdUnit) {
    throw new Error(
      `No AdMob ad unit configured for ${rewardPurpose}.`,
    );
  }

  if (
    adUnit !== expectedAdUnit
  ) {
    throw new Error(
      `Invalid AdMob ad unit. Expected ${expectedAdUnit}, received ${adUnit}.`,
    );
  }

  // ==========================================================
  // Reward validation
  // ==========================================================

  const rewardDefinition =
    REWARD_DEFINITIONS[
      rewardPurpose
    ];

  if (
    rewardAmount !==
    String(
      rewardDefinition.rewardAmount,
    )
  ) {
    throw new Error(
      `Invalid AdMob reward amount. Expected ${rewardDefinition.rewardAmount}, received ${rewardAmount}.`,
    );
  }

  if (
    rewardItem !==
    rewardDefinition.rewardItem
  ) {
    throw new Error(
      `Invalid AdMob reward item. Expected "${rewardDefinition.rewardItem}", received "${rewardItem}".`,
    );
  }

  // ==========================================================
  // Transaction ID validation
  // ==========================================================

  if (!transactionId) {
    throw new Error(
      "AdMob transaction_id is missing.",
    );
  }

  /**
   * Google documents transaction_id as a unique
   * hex-encoded reward identifier.
   */
  if (
    !/^[a-fA-F0-9]+$/.test(
      transactionId,
    )
  ) {
    throw new Error(
      "AdMob transaction_id is not valid hexadecimal.",
    );
  }

  // ==========================================================
  // Timestamp validation
  // ==========================================================

  const timestampMs =
    Number(timestamp);

  if (
    !Number.isFinite(
      timestampMs,
    ) ||
    timestampMs <= 0
  ) {
    throw new Error(
      "AdMob timestamp is invalid.",
    );
  }

  const now =
    Date.now();

  const ageMs =
    Math.abs(
      now - timestampMs,
    );

  const maxAgeMs =
    24 * 60 * 60 * 1000;

  if (
    ageMs > maxAgeMs
  ) {
    throw new Error(
      "AdMob SSV timestamp is older than 24 hours.",
    );
  }

  // ==========================================================
  // User ID validation
  // ==========================================================
  //
  // user_id may be absent depending on the SDK configuration.
  // If present, it must match our Firebase UID.
  // ==========================================================

  if (
    userId &&
    userId !== uid
  ) {
    throw new Error(
      "AdMob SSV user_id does not match custom_data UID.",
    );
  }

  // ==========================================================
  // Success
  // ==========================================================

  console.log(
    "🐱✅ AdMob SSV callback fully verified.",
    {
      uid,
      rewardPurpose,
      transactionId,
    },
  );

  return {
    verified: true,

    uid,

    rewardPurpose,

    adUnit,

    adNetwork,

    rewardAmount:
      parseInteger(
        rewardAmount,
      ),

    rewardItem,

    timestamp:
      timestampMs,

    transactionId,

    userId,

    customData,

    keyId:
      verification.keyId,

    rawQueryString:
      verification.rawQueryString,
  };
}

// ============================================================
// Exports
// ============================================================

module.exports = {
  ADMOB_AD_UNITS,
  REWARD_DEFINITIONS,

  getAdMobPublicKeys,
  verifyAdMobSignature,
  verifyAdMobCallback,
  parseCustomData,
};