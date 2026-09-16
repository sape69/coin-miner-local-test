"use strict";

const crypto = require("crypto");

const ADMOB_PUBLIC_KEYS_URL =
  "https://www.gstatic.com/admob/reward/verifier-keys.json";

// Google suosittelee julkisten avainten cachettamista,
// mutta niitä ei pidä säilyttää yli 24 tuntia.
const PUBLIC_KEY_CACHE_MS = 23 * 60 * 60 * 1000;

let publicKeyCache = null;
let publicKeyCacheTimestamp = 0;

// Stelluriinin käyttämät AdMob Rewarded -mainokset.
const ADMOB_AD_UNITS = {
  mining_start: "ca-app-pub-1131012057145658/6674097787",
  power_boost: "ca-app-pub-1131012057145658/7225738491",
};

const ADMOB_REWARD_ITEMS = {
  mining_start: "Mining",
  power_boost: "Power Boost",
};

const ADMOB_REWARD_AMOUNT = 1;

/**
 * Fetch AdMob public verification keys.
 */
async function fetchPublicKeys() {
  const now = Date.now();

  if (
    publicKeyCache &&
    now - publicKeyCacheTimestamp < PUBLIC_KEY_CACHE_MS
  ) {
    return publicKeyCache;
  }

  console.log("🐱🔐 Fetching fresh AdMob SSV public keys.");

  const response = await fetch(ADMOB_PUBLIC_KEYS_URL);

  if (!response.ok) {
    throw new Error(
      `Failed to fetch AdMob public keys. HTTP ${response.status}.`
    );
  }

  const data = await response.json();

  if (!data || !Array.isArray(data.keys) || data.keys.length === 0) {
    throw new Error("AdMob public key response contained no keys.");
  }

  const keyMap = new Map();

  for (const key of data.keys) {
    if (key == null || key.keyId == null) {
      continue;
    }

    const keyId = String(key.keyId);

    if (typeof key.pem === "string" && key.pem.trim() !== "") {
      keyMap.set(keyId, key.pem);
      continue;
    }

    if (typeof key.base64 === "string" && key.base64.trim() !== "") {
      const derBuffer = Buffer.from(key.base64, "base64");

      const publicKey = crypto.createPublicKey({
        key: derBuffer,
        format: "der",
        type: "spki",
      });

      keyMap.set(keyId, publicKey);
    }
  }

  if (keyMap.size === 0) {
    throw new Error("No usable AdMob public verification keys found.");
  }

  publicKeyCache = keyMap;
  publicKeyCacheTimestamp = now;

  console.log(
    `🐱🔐 Loaded ${keyMap.size} AdMob SSV public verification key(s).`
  );

  return keyMap;
}

/**
 * Get the original raw request URL.
 *
 * IMPORTANT:
 * We intentionally do NOT use req.query for signature verification.
 *
 * Google requires the exact original query string to be verified,
 * including parameter order and URL encoding.
 */
function getRawRequestUrl(req) {
  const candidates = [
    req.rawUrl,
    req.originalUrl,
    req.url,
  ];

  for (const candidate of candidates) {
    if (typeof candidate === "string" && candidate.includes("?")) {
      return candidate;
    }
  }

  throw new Error("Could not obtain the original AdMob SSV request URL.");
}

/**
 * Extract the raw query string from the original request URL.
 */
function getRawQueryString(req) {
  const rawUrl = getRawRequestUrl(req);

  const questionMarkIndex = rawUrl.indexOf("?");

  if (questionMarkIndex === -1) {
    throw new Error("AdMob SSV request does not contain a query string.");
  }

  const queryString = rawUrl.substring(questionMarkIndex + 1);

  if (!queryString) {
    throw new Error("AdMob SSV query string is empty.");
  }

  return queryString;
}

/**
 * Extract the exact signed query content.
 *
 * Google specifies that the final two parameters are:
 *
 *   signature
 *   key_id
 *
 * in that order.
 *
 * Everything before "&signature=" is the content that must be
 * cryptographically verified WITHOUT modification.
 */
function extractSignedContent(queryString) {
  const signatureMarker = "&signature=";

  const signatureIndex = queryString.indexOf(signatureMarker);

  if (signatureIndex === -1) {
    throw new Error("AdMob SSV signature parameter was not found.");
  }

  if (signatureIndex === 0) {
    throw new Error("AdMob SSV signed content is empty.");
  }

  return queryString.substring(0, signatureIndex);
}

/**
 * Extract the raw signature and key_id after the signed content.
 */
function extractSignatureAndKeyId(queryString) {
  const signatureMarker = "&signature=";

  const signatureIndex = queryString.indexOf(signatureMarker);

  if (signatureIndex === -1) {
    throw new Error("AdMob SSV signature parameter was not found.");
  }

  const afterSignature = queryString.substring(
    signatureIndex + signatureMarker.length
  );

  const keyIdMarker = "&key_id=";

  const keyIdIndex = afterSignature.indexOf(keyIdMarker);

  if (keyIdIndex === -1) {
    throw new Error("AdMob SSV key_id parameter was not found.");
  }

  const rawSignature = afterSignature.substring(0, keyIdIndex);
  const rawKeyId = afterSignature.substring(
    keyIdIndex + keyIdMarker.length
  );

  if (!rawSignature) {
    throw new Error("AdMob SSV signature is empty.");
  }

  if (!rawKeyId) {
    throw new Error("AdMob SSV key_id is empty.");
  }

  return {
    rawSignature,
    rawKeyId,
  };
}

/**
 * Decode Google's base64url signature.
 *
 * AdMob SSV signatures use URL-safe Base64.
 */
function decodeSignature(rawSignature) {
  try {
    return Buffer.from(rawSignature, "base64url");
  } catch (error) {
    throw new Error(
      `Failed to decode AdMob SSV signature: ${error.message}`
    );
  }
}

/**
 * Verify the exact original AdMob SSV query content.
 */
async function verifySignature({
  signedContent,
  rawSignature,
  keyId,
}) {
  const publicKeys = await fetchPublicKeys();

  const publicKey = publicKeys.get(String(keyId));

  if (!publicKey) {
    throw new Error(
      `No AdMob public key found for key_id ${keyId}.`
    );
  }

  const signatureBuffer = decodeSignature(rawSignature);

  if (signatureBuffer.length === 0) {
    throw new Error("Decoded AdMob SSV signature is empty.");
  }

  const signedContentBuffer = Buffer.from(
    signedContent,
    "utf8"
  );

  console.log(
    `🐱🔐 Verifying AdMob SSV. key_id=${keyId}, ` +
      `signedBytes=${signedContentBuffer.length}, ` +
      `signatureBytes=${signatureBuffer.length}`
  );

  const isValid = crypto.verify(
    "sha256",
    signedContentBuffer,
    {
      key: publicKey,
      dsaEncoding: "der",
    },
    signatureBuffer
  );

  if (!isValid) {
    console.error("🐱❌ AdMob SSV signature INVALID.");

    throw new Error("AdMob SSV signature verification failed.");
  }

  console.log("🐱✅ AdMob SSV signature VALID.");

  return true;
}

/**
 * Parse the SSV parameters AFTER signature verification.
 *
 * We intentionally do not use these decoded values for the
 * cryptographic verification itself.
 */
function parseVerifiedParameters(queryString) {
  const params = new URLSearchParams(queryString);

  const getRequired = (name) => {
    const value = params.get(name);

    if (value === null || value === "") {
      throw new Error(
        `AdMob SSV parameter "${name}" is missing.`
      );
    }

    return value;
  };

  const adNetwork = getRequired("ad_network");
  const adUnit = getRequired("ad_unit");
  const rewardAmount = getRequired("reward_amount");
  const rewardItem = getRequired("reward_item");
  const timestamp = getRequired("timestamp");
  const transactionId = getRequired("transaction_id");

  const customData = params.get("custom_data");
  const userId = params.get("user_id");

  return {
    adNetwork,
    adUnit,
    rewardAmount,
    rewardItem,
    timestamp,
    transactionId,
    customData,
    userId,
  };
}

/**
 * Parse custom_data after the signature has already been verified.
 *
 * Flutter sends:
 *
 *   UID:purpose
 *
 * Example:
 *
 *   abc123:power_boost
 *   abc123:mining_start
 */
function parseCustomData(customData) {
  if (!customData) {
    throw new Error(
      "AdMob SSV custom_data is missing."
    );
  }

  let decodedCustomData = customData;

  try {
    decodedCustomData = decodeURIComponent(customData);
  } catch (error) {
    console.warn(
      "🐱⚠️ custom_data was not URI-decoded:",
      error.message
    );
  }

  const separatorIndex = decodedCustomData.indexOf(":");

  if (separatorIndex <= 0) {
    throw new Error(
      "Invalid AdMob custom_data format."
    );
  }

  const uid = decodedCustomData.substring(
    0,
    separatorIndex
  );

  const purpose = decodedCustomData.substring(
    separatorIndex + 1
  );

  if (!uid) {
    throw new Error(
      "AdMob custom_data does not contain a UID."
    );
  }

  if (
    purpose !== "mining_start" &&
    purpose !== "power_boost"
  ) {
    throw new Error(
      `Unsupported AdMob reward purpose: ${purpose}`
    );
  }

  return {
    uid,
    purpose,
    customData: decodedCustomData,
  };
}

/**
 * Validate all non-cryptographic SSV values.
 *
 * This function is called ONLY after the signature is valid.
 */
function validateRewardParameters(parameters, customDataInfo) {
  const {
    adUnit,
    rewardAmount,
    rewardItem,
    timestamp,
    transactionId,
    userId,
  } = parameters;

  const {
    uid,
    purpose,
  } = customDataInfo;

  const expectedAdUnit = ADMOB_AD_UNITS[purpose];
  const expectedRewardItem = ADMOB_REWARD_ITEMS[purpose];

  if (adUnit !== expectedAdUnit) {
    throw new Error(
      `Invalid AdMob ad unit for ${purpose}. ` +
        `Expected ${expectedAdUnit}, received ${adUnit}.`
    );
  }

  const numericRewardAmount = Number(rewardAmount);

  if (
    !Number.isFinite(numericRewardAmount) ||
    numericRewardAmount !== ADMOB_REWARD_AMOUNT
  ) {
    throw new Error(
      `Invalid AdMob reward amount. ` +
        `Expected ${ADMOB_REWARD_AMOUNT}, received ${rewardAmount}.`
    );
  }

  if (rewardItem !== expectedRewardItem) {
    throw new Error(
      `Invalid AdMob reward item for ${purpose}. ` +
        `Expected "${expectedRewardItem}", received "${rewardItem}".`
    );
  }

  if (!transactionId) {
    throw new Error(
      "AdMob transaction_id is missing."
    );
  }

  if (!/^[a-fA-F0-9]+$/.test(transactionId)) {
    throw new Error(
      "AdMob transaction_id has an invalid format."
    );
  }

  const numericTimestamp = Number(timestamp);

  if (
    !Number.isFinite(numericTimestamp) ||
    numericTimestamp <= 0
  ) {
    throw new Error(
      "AdMob timestamp is invalid."
    );
  }

  // Allow a generous clock window because SSV callbacks can
  // arrive later than the ad itself.
  const now = Date.now();
  const maxAgeMs = 24 * 60 * 60 * 1000;

  if (Math.abs(now - numericTimestamp) > maxAgeMs) {
    throw new Error(
      "AdMob SSV timestamp is outside the allowed time window."
    );
  }

  if (userId && userId !== uid) {
    throw new Error(
      "AdMob user_id does not match custom_data UID."
    );
  }

  return {
    uid,
    purpose,
    adUnit,
    rewardAmount: numericRewardAmount,
    rewardItem,
    transactionId,
    timestamp: numericTimestamp,
    userId: userId || null,
  };
}

/**
 * Main AdMob SSV verification function.
 *
 * This function:
 *
 * 1. Gets the ORIGINAL raw query string.
 * 2. Extracts the exact signed content.
 * 3. Extracts signature and key_id.
 * 4. Verifies the signature using Google's public key.
 * 5. Only after successful verification parses/validates
 *    the reward data.
 */
async function verifyAdMobCallback(req) {
  try {
    console.log("🐱📺 AdMob SSV callback received.");

    const rawQueryString = getRawQueryString(req);

    console.log(
      `🐱📺 AdMob SSV raw query length: ${rawQueryString.length}`
    );

    const signedContent =
      extractSignedContent(rawQueryString);

    const {
      rawSignature,
      rawKeyId,
    } = extractSignatureAndKeyId(rawQueryString);

    console.log(
      `🐱📺 AdMob SSV key_id received: ${rawKeyId}`
    );

    await verifySignature({
      signedContent,
      rawSignature,
      keyId: rawKeyId,
    });

    // IMPORTANT:
    // Everything below this point happens only after the
    // cryptographic signature has been successfully verified.
    const parameters =
      parseVerifiedParameters(signedContent);

    const customDataInfo =
      parseCustomData(parameters.customData);

    const validated =
      validateRewardParameters(
        parameters,
        customDataInfo
      );

    console.log(
      "🐱✅ AdMob SSV callback VERIFIED.",
      {
        uid: validated.uid,
        purpose: validated.purpose,
        adUnit: validated.adUnit,
        rewardItem: validated.rewardItem,
        rewardAmount: validated.rewardAmount,
        transactionId: validated.transactionId,
      }
    );

    return {
      verified: true,
      uid: validated.uid,
      userId: validated.userId,
      rewardType: "admob",
      rewardPurpose: validated.purpose,
      adNetwork: parameters.adNetwork,
      adUnit: validated.adUnit,
      rewardAmount: validated.rewardAmount,
      rewardItem: validated.rewardItem,
      transactionId: validated.transactionId,
      timestamp: validated.timestamp,
      customData: customDataInfo.customData,
      keyId: String(rawKeyId),
    };
  } catch (error) {
    console.error(
      "🐱❌ AdMob SSV verification failed:",
      error.message
    );

    return {
      verified: false,
      error: error.message,
    };
  }
}

module.exports = {
  verifyAdMobCallback,
};