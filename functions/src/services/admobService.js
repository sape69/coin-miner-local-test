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
 * The SSV signature must be verified against the ORIGINAL
 * query string exactly as received from Google.
 *
 * Do NOT decode/re-encode the signed query string before
 * cryptographic verification.
 * ============================================================
 */

// ============================================================
// AdMob configuration
// ============================================================

const ADMOB_SSV_KEYS_URL =
  "https://www.gstatic.com/admob/reward/verifier-keys.json";

// Public keys must not be cached longer than 24 hours.
const PUBLIC_KEY_CACHE_MS = 23 * 60 * 60 * 1000;

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

async function getAdMobPublicKeys(forceRefresh = false) {
  const now = Date.now();

  if (
    !forceRefresh &&
    cachedPublicKeys &&
    now - cachedPublicKeysAt < PUBLIC_KEY_CACHE_MS
  ) {
    return cachedPublicKeys;
  }

  const data = await fetchJson(ADMOB_SSV_KEYS_URL);

  if (!data || !Array.isArray(data.keys)) {
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
      keys.set(String(key.keyId), key.pem);
    }
  }

  if (keys.size === 0) {
    throw new Error(
      "No usable AdMob public keys were returned.",
    );
  }

  cachedPublicKeys = keys;
  cachedPublicKeysAt = now;

  console.log(
    "🐱 AdMob public keys loaded:",
    {
      count: keys.size,
      keyIds: Array.from(keys.keys()),
    },
  );

  return keys;
}

// ============================================================
// Query diagnostic helper
// ============================================================

function sha256(value) {
  return crypto
    .createHash("sha256")
    .update(value, "utf8")
    .digest("hex");
}

/**
 * Logs only safe diagnostics about the incoming URL.
 *
 * IMPORTANT:
 * We intentionally DO NOT print the complete URL because
 * the query contains UID/custom data/signature information.
 *
 * These hashes allow us to determine whether Firebase/Express
 * changes the query string before signature verification.
 */
function logRawQueryDiagnostics(req) {
  const sources = [];

  if (typeof req.originalUrl === "string") {
    sources.push({
      name: "originalUrl",
      value: req.originalUrl,
    });
  }

  if (typeof req.url === "string") {
    sources.push({
      name: "url",
      value: req.url,
    });
  }

  if (typeof req.rawUrl === "string") {
    sources.push({
      name: "rawUrl",
      value: req.rawUrl,
    });
  }

  const diagnostics = {};

  for (const source of sources) {
    const questionMark =
      source.value.indexOf("?");

    const query =
      questionMark >= 0
        ? source.value.substring(questionMark + 1)
        : "";

    diagnostics[source.name] = {
      totalLength: source.value.length,
      queryLength: query.length,
      querySha256: query
        ? sha256(query)
        : null,
    };
  }

  if (
    typeof req.originalUrl === "string" &&
    typeof req.url === "string"
  ) {
    diagnostics.originalUrlEqualsUrl =
      req.originalUrl === req.url;
  }

  if (
    typeof req.originalUrl === "string" &&
    typeof req.rawUrl === "string"
  ) {
    diagnostics.originalUrlEqualsRawUrl =
      req.originalUrl === req.rawUrl;
  }

  console.log(
    "🐱🔎 AdMob SSV URL diagnostics:",
    diagnostics,
  );
}

// ============================================================
// Raw query extraction
// ============================================================

/**
 * Get the original query string WITHOUT decoding it.
 *
 * This is critical for AdMob SSV.
 *
 * Google's signature covers the exact query content before
 * "&signature=".
 */
function getRawQueryString(req) {
  if (!req) {
    throw new Error(
      "Missing HTTP request.",
    );
  }

  // Diagnostic information only.
  logRawQueryDiagnostics(req);

  // Express normally preserves the original URL here.
  if (typeof req.originalUrl === "string") {
    const questionMark =
      req.originalUrl.indexOf("?");

    if (questionMark >= 0) {
      return req.originalUrl.substring(
        questionMark + 1,
      );
    }
  }

  if (typeof req.url === "string") {
    const questionMark =
      req.url.indexOf("?");

    if (questionMark >= 0) {
      return req.url.substring(
        questionMark + 1,
      );
    }
  }

  if (typeof req.rawUrl === "string") {
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
// Base64 URL-safe decoding
// ============================================================

function decodeAdMobSignature(signature) {
  if (
    !signature ||
    typeof signature !== "string"
  ) {
    throw new Error(
      "AdMob SSV signature is missing.",
    );
  }

  // AdMob uses URL-safe Base64.
  const normalized = signature
    .replace(/-/g, "+")
    .replace(/_/g, "/");

  const padding =
    normalized.length % 4;

  const padded =
    padding === 0
      ? normalized
      : normalized +
        "=".repeat(4 - padding);

  return Buffer.from(
    padded,
    "base64",
  );
}

// ============================================================
// Signature verification
// ============================================================

async function verifyAdMobSignature(req) {
  const rawQueryString =
    getRawQueryString(req);

  console.log(
    "🐱🔐 AdMob SSV raw query received.",
    {
      length: rawQueryString.length,
      sha256: sha256(rawQueryString),
    },
  );

  /**
   * Google's SSV format always puts:
   *
   *   ...signed parameters...
   *   &signature=...
   *   &key_id=...
   *
   * at the end.
   *
   * We MUST verify the exact bytes before &signature=.
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

  const signedQueryString =
    rawQueryString.substring(
      0,
      signatureIndex,
    );

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

  console.log(
    "🐱🔐 AdMob SSV signature information:",
    {
      keyId,
      signedLength:
        signedQueryString.length,
      signedSha256:
        sha256(signedQueryString),
      signatureLength:
        signature.length,
    },
  );

  const signatureBuffer =
    decodeAdMobSignature(
      signature,
    );

  /**
   * AdMob uses ECDSA with SHA-256.
   *
   * The signature format is DER.
   */

  let publicKeys =
    await getAdMobPublicKeys(false);

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
    console.log(
      "🐱 AdMob SSV key ID not found in cache. Refreshing keys.",
      {
        keyId,
      },
    );

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

  const verifier =
    crypto.createVerify(
      "SHA256",
    );

  /**
   * IMPORTANT:
   *
   * Use the exact raw query string.
   *
   * Do NOT use URLSearchParams.toString().
   * Do NOT decodeURIComponent().
   * Do NOT JSON.stringify().
   * Do NOT reorder parameters.
   */
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
        signedLength:
          signedQueryString.length,
        signedSha256:
          sha256(signedQueryString),
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

function getParam(params, name) {
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

  if (!Number.isFinite(number)) {
    return fallback;
  }

  return Math.trunc(number);
}

// ============================================================
// Custom data parser
// ============================================================

function parseCustomData(customData) {
  if (
    !customData ||
    typeof customData !== "string"
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
      rewardPurpose: "power_boost",
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

async function verifyAdMobCallback(req) {
  console.log(
    "🐱🔐 Verifying AdMob SSV callback...",
  );

  const verification =
    await verifyAdMobSignature(req);

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

  console.log(
    "🐱 AdMob SSV verified parameters:",
    {
      adNetwork,
      adUnit,
      rewardAmount,
      rewardItem,
      timestamp,
      transactionId,
      userId,
      rewardPurpose,
      hasCustomData:
        Boolean(customData),
    },
  );

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

  if (ageMs > maxAgeMs) {
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
      adUnit,
      transactionId,
      rewardAmount,
      rewardItem,
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