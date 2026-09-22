"use strict";

// ============================================================
// 🐱 STELLURIINI — ADMOB SSV SERVICE
// ============================================================
//
// Responsible for:
// - Receiving raw AdMob SSV callback data
// - Loading Google's AdMob verification keys
// - Selecting the correct public key by key_id
// - Verifying the ORIGINAL callback query
// - Validating callback parameters
//
// IMPORTANT:
// The query string used for signature verification MUST NOT be
// reconstructed from URLSearchParams or decoded/re-encoded values.
//
// Google signs the original query string exactly as sent.
//
// ============================================================

const crypto = require("crypto");
const https = require("https");

// ============================================================
// CONFIGURATION
// ============================================================

const ADMOB_PUBLIC_KEYS_URL =
  "https://www.gstatic.com/admob/reward/verifier-keys.json";

const KEY_CACHE_TTL_MS = 60 * 60 * 1000;

// ============================================================
// KEY CACHE
// ============================================================

let cachedKeys = new Map();
let cachedKeysLoadedAt = 0;

// ============================================================
// LOGGING
// ============================================================

function log(message, data = {}) {
  console.log(`🐱 ${message}`, data);
}

function logError(message, data = {}) {
  console.error(`🐱❌ ${message}`, data);
}

// ============================================================
// HTTP GET
// ============================================================

function httpGetJson(url) {
  return new Promise((resolve, reject) => {
    const request = https.get(
      url,
      {
        headers: {
          Accept: "application/json",
          "User-Agent": "Stelluriini-AdMob-SSV/1.0",
        },
      },
      (response) => {
        let body = "";

        response.setEncoding("utf8");

        response.on("data", (chunk) => {
          body += chunk;
        });

        response.on("end", () => {
          if (response.statusCode !== 200) {
            reject(
              new Error(
                `AdMob public key server returned HTTP ${response.statusCode}`
              )
            );
            return;
          }

          try {
            const json = JSON.parse(body);
            resolve(json);
          } catch (error) {
            reject(
              new Error(
                `Failed to parse AdMob public key response: ${error.message}`
              )
            );
          }
        });
      }
    );

    request.on("error", (error) => {
      reject(error);
    });

    request.setTimeout(15000, () => {
      request.destroy(new Error("AdMob public key request timed out"));
    });
  });
}

// ============================================================
// LOAD ADMOB PUBLIC KEYS
// ============================================================

async function loadAdMobPublicKeys(forceRefresh = false) {
  const now = Date.now();

  if (
    !forceRefresh &&
    cachedKeys.size > 0 &&
    now - cachedKeysLoadedAt < KEY_CACHE_TTL_MS
  ) {
    return cachedKeys;
  }

  log("AdMob public keys loading.");

  const response = await httpGetJson(ADMOB_PUBLIC_KEYS_URL);

  if (!response || !Array.isArray(response.keys)) {
    throw new Error("Invalid AdMob public key response.");
  }

  const newKeys = new Map();

  for (const key of response.keys) {
    if (key == null) {
      continue;
    }

    const keyId = String(key.keyId ?? "").trim();

    const pem =
      typeof key.pem === "string" && key.pem.trim().length > 0
        ? key.pem.trim()
        : null;

    const base64 =
      typeof key.base64 === "string" && key.base64.trim().length > 0
        ? key.base64.trim()
        : null;

    if (!keyId) {
      continue;
    }

    let publicKeyPem = pem;

    // ----------------------------------------------------------
    // Normally Google's response contains PEM.
    // If PEM is missing but base64 is available, convert it
    // into a SPKI public key.
    // ----------------------------------------------------------

    if (!publicKeyPem && base64) {
      try {
        const keyObject = crypto.createPublicKey({
          key: Buffer.from(base64, "base64"),
          format: "der",
          type: "spki",
        });

        publicKeyPem = keyObject.export({
          type: "spki",
          format: "pem",
        });
      } catch (error) {
        logError("Failed to convert AdMob base64 public key.", {
          keyId,
          error: error.message,
        });

        continue;
      }
    }

    if (!publicKeyPem) {
      continue;
    }

    newKeys.set(keyId, publicKeyPem);
  }

  if (newKeys.size === 0) {
    throw new Error("No usable AdMob public keys were loaded.");
  }

  cachedKeys = newKeys;
  cachedKeysLoadedAt = now;

  log("AdMob public keys loaded.", {
    count: cachedKeys.size,
    keyIds: Array.from(cachedKeys.keys()),
  });

  return cachedKeys;
}

// ============================================================
// GET RAW QUERY STRING
// ============================================================
//
// VERY IMPORTANT:
//
// Do NOT use:
//
//   new URLSearchParams()
//   Object.fromEntries()
//   decodeURIComponent(rawQuery)
//   reconstructed query strings
//
// before signature verification.
//
// Google signs the original query string.
//
// ============================================================

function getRawQueryString(req) {
  // Node's IncomingMessage.url contains the original request
  // target including the raw query string.
  //
  // Prefer req.url because it is closest to the actual HTTP
  // request received by the server.

  const requestUrl =
    typeof req.url === "string" && req.url.length > 0
      ? req.url
      : typeof req.originalUrl === "string" && req.originalUrl.length > 0
        ? req.originalUrl
        : "";

  const questionMarkIndex = requestUrl.indexOf("?");

  if (questionMarkIndex === -1) {
    return "";
  }

  return requestUrl.substring(questionMarkIndex + 1);
}

// ============================================================
// EXTRACT SIGNATURE AND KEY ID
// ============================================================

function extractSignatureAndKeyId(rawQuery) {
  if (!rawQuery) {
    throw new Error("Missing AdMob SSV query string.");
  }

  // Google specifies that the last two query parameters are:
  //
  // signature
  // key_id
  //
  // in exactly this order.

  const signatureMarker = "&signature=";
  const signatureStart = rawQuery.indexOf(signatureMarker);

  if (signatureStart === -1) {
    // Also support the theoretical case where signature is the
    // first parameter, although AdMob normally places it near
    // the end of the callback.
    if (rawQuery.startsWith("signature=")) {
      throw new Error(
        "Invalid AdMob SSV query ordering: signature must follow callback parameters."
      );
    }

    throw new Error("Missing AdMob SSV signature parameter.");
  }

  const dataToVerify = rawQuery.substring(0, signatureStart);

  const signatureAndKeyId = rawQuery.substring(
    signatureStart + 1
  );

  if (!signatureAndKeyId.startsWith("signature=")) {
    throw new Error("Invalid AdMob SSV signature section.");
  }

  const keyIdMarker = "&key_id=";

  const keyIdIndex = signatureAndKeyId.indexOf(keyIdMarker);

  if (keyIdIndex === -1) {
    throw new Error("Missing AdMob SSV key_id parameter.");
  }

  const encodedSignature = signatureAndKeyId.substring(
    "signature=".length,
    keyIdIndex
  );

  const encodedKeyId = signatureAndKeyId.substring(
    keyIdIndex + keyIdMarker.length
  );

  if (!encodedSignature) {
    throw new Error("AdMob SSV signature is empty.");
  }

  if (!encodedKeyId) {
    throw new Error("AdMob SSV key_id is empty.");
  }

  let signature;
  let keyId;

  try {
    // Decode ONLY the signature value.
    //
    // The dataToVerify string above remains untouched.

    signature = decodeURIComponent(encodedSignature);

    keyId = decodeURIComponent(encodedKeyId);
  } catch (error) {
    throw new Error(
      `Failed to decode AdMob SSV signature/key_id: ${error.message}`
    );
  }

  return {
    dataToVerify,
    signature,
    keyId: String(keyId).trim(),
  };
}

// ============================================================
// VERIFY ECDSA SIGNATURE
// ============================================================

function verifySignature({
  dataToVerify,
  signature,
  publicKeyPem,
}) {
  if (!dataToVerify) {
    throw new Error("No AdMob SSV data available for verification.");
  }

  if (!signature) {
    throw new Error("No AdMob SSV signature available.");
  }

  if (!publicKeyPem) {
    throw new Error("No AdMob public key available.");
  }

  let signatureBuffer;

  try {
    signatureBuffer = Buffer.from(signature, "base64");
  } catch (error) {
    throw new Error(
      `Failed to decode AdMob SSV signature: ${error.message}`
    );
  }

  if (signatureBuffer.length === 0) {
    throw new Error("AdMob SSV signature decoded to an empty buffer.");
  }

  // Google AdMob SSV uses:
  //
  // ECDSA
  // SHA-256
  // DER encoded signature
  //
  // Node.js crypto.verify performs the actual cryptographic
  // verification.

  const verified = crypto.verify(
    "sha256",
    Buffer.from(dataToVerify, "utf8"),
    {
      key: publicKeyPem,
      dsaEncoding: "der",
    },
    signatureBuffer
  );

  return verified;
}

// ============================================================
// PARSE CALLBACK PARAMETERS
// ============================================================
//
// This parser is used ONLY AFTER signature verification.
//
// It must never be used to create the signed data.
//
// ============================================================

function parseCallbackParameters(rawQuery) {
  const params = new URLSearchParams(rawQuery);

  return {
    adNetwork: params.get("ad_network"),
    adUnit: params.get("ad_unit"),
    customData: params.get("custom_data"),
    rewardAmount: params.get("reward_amount"),
    rewardItem: params.get("reward_item"),
    timestamp: params.get("timestamp"),
    transactionId: params.get("transaction_id"),
    userId: params.get("user_id"),
    signature: params.get("signature"),
    keyId: params.get("key_id"),
  };
}

// ============================================================
// VALIDATE CALLBACK
// ============================================================

function validateCallbackParameters(callback) {
  if (!callback.transactionId) {
    throw new Error("AdMob SSV transaction_id is missing.");
  }

  if (!callback.userId && !callback.customData) {
    throw new Error(
      "AdMob SSV callback does not contain user_id or custom_data."
    );
  }

  if (!callback.timestamp) {
    throw new Error("AdMob SSV timestamp is missing.");
  }

  const timestamp = Number(callback.timestamp);

  if (!Number.isFinite(timestamp)) {
    throw new Error("AdMob SSV timestamp is invalid.");
  }

  // AdMob timestamp is Unix time in seconds.

  const nowSeconds = Math.floor(Date.now() / 1000);

  // Allow a reasonable clock difference while preventing very
  // old/replayed callbacks from being treated as fresh.

  const MAX_TIMESTAMP_AGE_SECONDS = 24 * 60 * 60;

  if (timestamp > nowSeconds + 300) {
    throw new Error("AdMob SSV timestamp is in the future.");
  }

  if (nowSeconds - timestamp > MAX_TIMESTAMP_AGE_SECONDS) {
    throw new Error("AdMob SSV callback is too old.");
  }

  return true;
}

// ============================================================
// MAIN VERIFICATION FUNCTION
// ============================================================

async function verifyAdMobCallback(req) {
  try {
    // ----------------------------------------------------------
    // 1. Get the ORIGINAL raw query.
    // ----------------------------------------------------------

    const rawQuery = getRawQueryString(req);

    log("AdMob SSV raw callback received.", {
      length: rawQuery.length,
      hasSignature: rawQuery.includes("signature="),
      hasKeyId: rawQuery.includes("key_id="),
    });

    if (!rawQuery) {
      throw new Error("AdMob SSV callback contains no query string.");
    }

    // ----------------------------------------------------------
    // 2. Extract signed data, signature and key_id.
    // ----------------------------------------------------------

    const {
      dataToVerify,
      signature,
      keyId,
    } = extractSignatureAndKeyId(rawQuery);

    log("AdMob SSV query parsed.", {
      signedDataLength: dataToVerify.length,
      signatureLength: signature.length,
      keyId,
    });

    // ----------------------------------------------------------
    // 3. Load public keys.
    // ----------------------------------------------------------

    let publicKeys = await loadAdMobPublicKeys(false);

    let publicKeyPem = publicKeys.get(keyId);

    // ----------------------------------------------------------
    // 4. If key rotation happened, refresh once.
    // ----------------------------------------------------------

    if (!publicKeyPem) {
      log("AdMob SSV key_id not found in cache. Refreshing keys.", {
        keyId,
      });

      publicKeys = await loadAdMobPublicKeys(true);

      publicKeyPem = publicKeys.get(keyId);
    }

    if (!publicKeyPem) {
      throw new Error(
        `No AdMob public key found for key_id ${keyId}.`
      );
    }

    // ----------------------------------------------------------
    // 5. Cryptographically verify the ORIGINAL query.
    // ----------------------------------------------------------

    const signatureValid = verifySignature({
      dataToVerify,
      signature,
      publicKeyPem,
    });

    if (!signatureValid) {
      const error = new Error(
        "AdMob SSV signature verification failed."
      );

      error.code = "ADMOB_INVALID_SIGNATURE";
      error.keyId = keyId;

      throw error;
    }

    log("AdMob SSV signature verified successfully.", {
      keyId,
    });

    // ----------------------------------------------------------
    // 6. Parse parameters AFTER verification.
    // ----------------------------------------------------------

    const callback = parseCallbackParameters(rawQuery);

    // ----------------------------------------------------------
    // 7. Validate callback.
    // ----------------------------------------------------------

    validateCallbackParameters(callback);

    // ----------------------------------------------------------
    // 8. Return verified callback.
    // ----------------------------------------------------------

    return {
      verified: true,

      code: "ADMOB_SSV_VERIFIED",

      keyId,

      transactionId: callback.transactionId,

      userId: callback.userId || callback.customData,

      adNetwork: callback.adNetwork,

      adUnit: callback.adUnit,

      customData: callback.customData,

      rewardAmount: callback.rewardAmount,

      rewardItem: callback.rewardItem,

      timestamp: callback.timestamp,

      // Useful for diagnostics/auditing.
      //
      // Do NOT use this value to reconstruct the signature.
      rawQuery,
    };
  } catch (error) {
    const code =
      error.code || "ADMOB_SSV_VERIFICATION_FAILED";

    logError("AdMob SSV signature verification FAILED.", {
      code,
      keyId: error.keyId || null,
      message: error.message,
    });

    return {
      verified: false,
      code,
      message: error.message,
      keyId: error.keyId || null,
    };
  }
}

// ============================================================
// EXPORTS
// ============================================================

module.exports = {
  verifyAdMobCallback,
  loadAdMobPublicKeys,
};