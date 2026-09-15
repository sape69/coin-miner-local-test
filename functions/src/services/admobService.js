"use strict";

const crypto = require("crypto");
const https = require("https");

const ADMOB_KEYS_URL =
  "https://www.gstatic.com/admob/reward/verifier-keys.json";

// ------------------------------------------------------------
// Stelluriini AdMob configuration
// ------------------------------------------------------------

const MINING_AD_UNIT =
  "ca-app-pub-1131012057145658/6674097787";

const POWER_BOOST_AD_UNIT =
  "ca-app-pub-1131012057145658/7225738491";

const MINING_REWARD_ITEM = "Mining";
const POWER_BOOST_REWARD_ITEM = "Power Boost";

const ADMOB_SSV_REWARD_AMOUNT = 1;

// Google recommends refreshing cached SSV keys
// at least within 24 hours because keys can rotate.
const KEY_CACHE_MAX_AGE_MS = 60 * 60 * 1000;

let cachedPublicKeys = null;
let cachedPublicKeysAt = 0;

// ------------------------------------------------------------
// Small helpers
// ------------------------------------------------------------

function normalizeCustomData(value) {
  if (value === undefined || value === null) {
    return "";
  }

  try {
    return decodeURIComponent(String(value));
  } catch (error) {
    console.warn(
      "🐱 AdMob custom_data could not be URL-decoded. Using raw value.",
    );

    return String(value);
  }
}

function base64UrlToBuffer(value) {
  if (!value) {
    throw new Error("Missing AdMob signature.");
  }

  let normalized = String(value)
    .replace(/-/g, "+")
    .replace(/_/g, "/");

  while (normalized.length % 4 !== 0) {
    normalized += "=";
  }

  return Buffer.from(normalized, "base64");
}

function getRawQueryString(req) {
  // IMPORTANT:
  // AdMob signs the ORIGINAL query string.
  //
  // Do NOT use req.query because Express decodes and normalizes
  // query parameters. That would change the bytes that were signed.

  if (req && typeof req.url === "string") {
    const questionMarkIndex = req.url.indexOf("?");

    if (questionMarkIndex >= 0) {
      return req.url.substring(questionMarkIndex + 1);
    }
  }

  if (req && typeof req.originalUrl === "string") {
    const questionMarkIndex = req.originalUrl.indexOf("?");

    if (questionMarkIndex >= 0) {
      return req.originalUrl.substring(questionMarkIndex + 1);
    }
  }

  throw new Error("Unable to obtain raw AdMob SSV query string.");
}

function getRawParameter(queryString, parameterName) {
  const prefix = `${parameterName}=`;

  const parts = queryString.split("&");

  for (const part of parts) {
    if (part.startsWith(prefix)) {
      return part.substring(prefix.length);
    }
  }

  return null;
}

// ------------------------------------------------------------
// Download AdMob public keys
// ------------------------------------------------------------

function downloadPublicKeys() {
  return new Promise((resolve, reject) => {
    https
      .get(ADMOB_KEYS_URL, (response) => {
        let body = "";

        response.setEncoding("utf8");

        response.on("data", (chunk) => {
          body += chunk;
        });

        response.on("end", () => {
          if (response.statusCode !== 200) {
            reject(
              new Error(
                `AdMob public key server returned HTTP ${response.statusCode}.`,
              ),
            );

            return;
          }

          try {
            const json = JSON.parse(body);

            if (!json || !Array.isArray(json.keys)) {
              reject(
                new Error(
                  "AdMob public key response does not contain a keys array.",
                ),
              );

              return;
            }

            const keys = new Map();

            for (const item of json.keys) {
              if (
                item &&
                item.keyId !== undefined &&
                typeof item.pem === "string"
              ) {
                keys.set(String(item.keyId), item.pem);
              }
            }

            if (keys.size === 0) {
              reject(
                new Error(
                  "No usable AdMob public verification keys were returned.",
                ),
              );

              return;
            }

            resolve(keys);
          } catch (error) {
            reject(
              new Error(
                `Failed to parse AdMob public keys: ${error.message}`,
              ),
            );
          }
        });
      })
      .on("error", (error) => {
        reject(
          new Error(
            `Failed to download AdMob public keys: ${error.message}`,
          ),
        );
      });
  });
}

async function getPublicKeys() {
  const now = Date.now();

  if (
    cachedPublicKeys &&
    now - cachedPublicKeysAt < KEY_CACHE_MAX_AGE_MS
  ) {
    return cachedPublicKeys;
  }

  const keys = await downloadPublicKeys();

  cachedPublicKeys = keys;
  cachedPublicKeysAt = now;

  console.log(
    `🐱 AdMob public keys refreshed. Count: ${keys.size}`,
  );

  return keys;
}

// ------------------------------------------------------------
// Raw SSV signature verification
// ------------------------------------------------------------

async function verifyAdMobSignature(req) {
  const queryString = getRawQueryString(req);

  console.log(
    "🐱 AdMob SSV raw query length:",
    queryString.length,
  );

  // Google guarantees that signature and key_id are the final
  // two parameters, with signature immediately before key_id.
  const signatureMarker = "&signature=";

  const signatureIndex = queryString.indexOf(signatureMarker);

  if (signatureIndex === -1) {
    throw new Error(
      "Missing AdMob signature query parameter.",
    );
  }

  // Everything before "&signature=" is the EXACT content
  // that Google signed.
  const signedQuery = queryString.substring(
    0,
    signatureIndex,
  );

  const signatureAndKeyId = queryString.substring(
    signatureIndex + 1,
  );

  const signaturePrefix = "signature=";

  if (!signatureAndKeyId.startsWith(signaturePrefix)) {
    throw new Error(
      "Invalid AdMob signature parameter format.",
    );
  }

  const afterSignature = signatureAndKeyId.substring(
    signaturePrefix.length,
  );

  const keyIdMarker = "&key_id=";

  const keyIdIndex = afterSignature.indexOf(keyIdMarker);

  if (keyIdIndex === -1) {
    throw new Error(
      "Missing AdMob key_id query parameter.",
    );
  }

  const rawSignature = afterSignature.substring(
    0,
    keyIdIndex,
  );

  const rawKeyId = afterSignature.substring(
    keyIdIndex + keyIdMarker.length,
  );

  if (!rawSignature) {
    throw new Error(
      "AdMob signature parameter is empty.",
    );
  }

  if (!rawKeyId) {
    throw new Error(
      "AdMob key_id parameter is empty.",
    );
  }

  const keyId = String(rawKeyId);

  console.log(
    "🐱 AdMob SSV key_id:",
    keyId,
  );

  console.log(
    "🐱 AdMob SSV signed query length:",
    signedQuery.length,
  );

  console.log(
    "🐱 AdMob SSV signature length:",
    rawSignature.length,
  );

  // Never URL-decode the signed query.
  //
  // The exact original bytes must be verified.
  const dataToVerify = Buffer.from(
    signedQuery,
    "utf8",
  );

  const signatureBuffer =
    base64UrlToBuffer(rawSignature);

  const publicKeys = await getPublicKeys();

  const publicKeyPem = publicKeys.get(keyId);

  if (!publicKeyPem) {
    throw new Error(
      `No AdMob public verification key found for key_id ${keyId}.`,
    );
  }

  let publicKey;

  try {
    publicKey = crypto.createPublicKey(publicKeyPem);
  } catch (error) {
    throw new Error(
      `Unable to create AdMob public key: ${error.message}`,
    );
  }

  let verified = false;

  try {
    verified = crypto.verify(
      "sha256",
      dataToVerify,
      {
        key: publicKey,
        dsaEncoding: "der",
      },
      signatureBuffer,
    );
  } catch (error) {
    throw new Error(
      `AdMob ECDSA verification error: ${error.message}`,
    );
  }

  if (!verified) {
    console.error(
      "🐱❌ AdMob SSV signature INVALID.",
    );

    console.error(
      "🐱 AdMob signed query SHA256:",
      crypto
        .createHash("sha256")
        .update(dataToVerify)
        .digest("hex"),
    );

    throw new Error(
      "Invalid AdMob SSV signature.",
    );
  }

  console.log(
    "🐱✅ AdMob SSV signature VALID.",
  );

  return {
    queryString,
    signedQuery,
    keyId,
  };
}

// ------------------------------------------------------------
// Extract decoded SSV parameters AFTER verification
// ------------------------------------------------------------

function getDecodedParameters(queryString) {
  const params = new URLSearchParams(queryString);

  const get = (name) => {
    const value = params.get(name);

    return value === null ? "" : value;
  };

  return {
    adNetwork: get("ad_network"),
    adUnit: get("ad_unit"),
    customData: get("custom_data"),
    rewardAmount: get("reward_amount"),
    rewardItem: get("reward_item"),
    timestamp: get("timestamp"),
    transactionId: get("transaction_id"),
    userId: get("user_id"),
    keyId: get("key_id"),
  };
}

// ------------------------------------------------------------
// Validate decoded AdMob reward
// ------------------------------------------------------------

function validateAdMobReward(parameters) {
  const {
    adUnit,
    customData,
    rewardAmount,
    rewardItem,
    transactionId,
    timestamp,
  } = parameters;

  if (!adUnit) {
    throw new Error(
      "Missing AdMob ad_unit.",
    );
  }

  if (!rewardAmount) {
    throw new Error(
      "Missing AdMob reward_amount.",
    );
  }

  if (!rewardItem) {
    throw new Error(
      "Missing AdMob reward_item.",
    );
  }

  if (!transactionId) {
    throw new Error(
      "Missing AdMob transaction_id.",
    );
  }

  if (!timestamp) {
    throw new Error(
      "Missing AdMob timestamp.",
    );
  }

  const amount = Number(rewardAmount);

  if (
    !Number.isFinite(amount) ||
    amount !== ADMOB_SSV_REWARD_AMOUNT
  ) {
    throw new Error(
      `Unexpected AdMob reward_amount: ${rewardAmount}.`,
    );
  }

  // ----------------------------------------------------------
  // Decode custom_data only AFTER signature verification.
  // ----------------------------------------------------------

  const decodedCustomData =
    normalizeCustomData(customData);

  if (!decodedCustomData) {
    throw new Error(
      "Missing AdMob custom_data.",
    );
  }

  const customDataParts =
    decodedCustomData.split(":");

  if (customDataParts.length < 2) {
    throw new Error(
      "Invalid Stelluriini AdMob custom_data format.",
    );
  }

  const uid = customDataParts[0];
  const purpose = customDataParts.slice(1).join(":");

  if (!uid) {
    throw new Error(
      "Missing UID in AdMob custom_data.",
    );
  }

  if (
    purpose !== "mining_start" &&
    purpose !== "power_boost"
  ) {
    throw new Error(
      `Unsupported Stelluriini AdMob reward purpose: ${purpose}.`,
    );
  }

  // ----------------------------------------------------------
  // Purpose ↔ ad unit
  // ----------------------------------------------------------

  if (
    purpose === "mining_start" &&
    adUnit !== MINING_AD_UNIT
  ) {
    throw new Error(
      `Unexpected Mining ad_unit: ${adUnit}.`,
    );
  }

  if (
    purpose === "power_boost" &&
    adUnit !== POWER_BOOST_AD_UNIT
  ) {
    throw new Error(
      `Unexpected Power Boost ad_unit: ${adUnit}.`,
    );
  }

  // ----------------------------------------------------------
  // Purpose ↔ reward item
  // ----------------------------------------------------------

  if (
    purpose === "mining_start" &&
    rewardItem !== MINING_REWARD_ITEM
  ) {
    throw new Error(
      `Unexpected Mining reward_item: ${rewardItem}.`,
    );
  }

  if (
    purpose === "power_boost" &&
    rewardItem !== POWER_BOOST_REWARD_ITEM
  ) {
    throw new Error(
      `Unexpected Power Boost reward_item: ${rewardItem}.`,
    );
  }

  console.log(
    "🐱 AdMob SSV callback completely verified.",
  );

  return {
    uid,
    rewardPurpose: purpose,
    adUnit,
    rewardAmount: amount,
    rewardItem,
    transactionId,
    timestamp,
    userId: parameters.userId || null,
    adNetwork: parameters.adNetwork || null,
    keyId: parameters.keyId || null,
    customData: decodedCustomData,
  };
}

// ------------------------------------------------------------
// Main verification function
// ------------------------------------------------------------

async function verifyAdMobCallback(req) {
  console.log(
    "🐱📺 AdMob SSV callback received.",
  );

  try {
    // --------------------------------------------------------
    // STEP 1
    // Cryptographically verify the ORIGINAL raw query.
    // --------------------------------------------------------

    const verification =
      await verifyAdMobSignature(req);

    // --------------------------------------------------------
    // STEP 2
    // Parse parameters only after signature verification.
    // --------------------------------------------------------

    const parameters =
      getDecodedParameters(
        verification.queryString,
      );

    // Use the verified key_id obtained from the raw query.
    parameters.keyId = verification.keyId;

    console.log(
      "🐱 AdMob SSV parameters parsed.",
    );

    // --------------------------------------------------------
    // STEP 3
    // Validate Stelluriini-specific reward settings.
    // --------------------------------------------------------

    const reward =
      validateAdMobReward(parameters);

    console.log(
      "🐱✅ AdMob SSV reward fully validated.",
    );

    return reward;
  } catch (error) {
    console.error(
      "🐱❌ AdMob reward verification failed:",
      error,
    );

    throw error;
  }
}

// ------------------------------------------------------------
// Exports
// ------------------------------------------------------------

module.exports = {
  verifyAdMobCallback,
  verifyAdMobSignature,
  getPublicKeys,
  normalizeCustomData,
  validateAdMobReward,

  MINING_AD_UNIT,
  POWER_BOOST_AD_UNIT,

  MINING_REWARD_ITEM,
  POWER_BOOST_REWARD_ITEM,

  ADMOB_SSV_REWARD_AMOUNT,
};