"use strict";

const crypto = require("crypto");

const {
  ADMOB_SSV_AD_UNIT_ID,
  ADMOB_SSV_REWARD_AMOUNT,
  ADMOB_SSV_REWARD_ITEM,
} = require("../config/miningConfig");

// Google AdMob Rewarded SSV public keys.
const ADMOB_PUBLIC_KEYS_URL =
  "https://www.gstatic.com/admob/reward/verifier-keys.json";

// Public keys are cached for one hour.
const PUBLIC_KEY_CACHE_MS = 60 * 60 * 1000;

let cachedKeys = null;
let cachedKeysAt = 0;

/**
 * Fetches the current Google AdMob SSV public keys.
 */
async function getAdMobPublicKeys() {
  const now = Date.now();

  if (
    cachedKeys &&
    now - cachedKeysAt < PUBLIC_KEY_CACHE_MS
  ) {
    return cachedKeys;
  }

  const response = await fetch(ADMOB_PUBLIC_KEYS_URL);

  if (!response.ok) {
    throw new Error(
      `Failed to fetch AdMob public keys: ${response.status}`
    );
  }

  const data = await response.json();

  if (!data || !Array.isArray(data.keys)) {
    throw new Error("Invalid AdMob public key response.");
  }

  const keys = {};

  for (const key of data.keys) {
    if (!key || !key.keyId || !key.pem) {
      continue;
    }

    keys[String(key.keyId)] = key.pem;
  }

  if (Object.keys(keys).length === 0) {
    throw new Error("No valid AdMob public keys found.");
  }

  cachedKeys = keys;
  cachedKeysAt = now;

  return keys;
}

/**
 * Converts a base64url encoded string to a Buffer.
 */
function base64UrlToBuffer(value) {
  if (!value || typeof value !== "string") {
    throw new Error("Invalid base64url value.");
  }

  let normalized = value
    .replace(/-/g, "+")
    .replace(/_/g, "/");

  while (normalized.length % 4 !== 0) {
    normalized += "=";
  }

  return Buffer.from(normalized, "base64");
}

/**
 * Builds the exact query string that AdMob signed.
 *
 * AdMob signs everything before:
 * &signature=
 *
 * The original parameter order must therefore be preserved.
 */
function buildSignedQueryString(originalUrl) {
  if (!originalUrl || typeof originalUrl !== "string") {
    throw new Error("Missing original request URL.");
  }

  const signatureMarker = "&signature=";

  const signatureIndex = originalUrl.indexOf(signatureMarker);

  if (signatureIndex === -1) {
    throw new Error("AdMob signature parameter not found.");
  }

  return originalUrl.substring(0, signatureIndex);
}

/**
 * Verifies the cryptographic AdMob SSV signature.
 */
async function verifyAdMobSignature(req) {
  const originalUrl = req.originalUrl;

  if (!originalUrl) {
    throw new Error("Missing originalUrl.");
  }

  const signature = req.query?.signature;
  const keyId = req.query?.key_id;

  if (!signature) {
    throw new Error("Missing AdMob signature.");
  }

  if (!keyId) {
    throw new Error("Missing AdMob key_id.");
  }

  const publicKeys = await getAdMobPublicKeys();

  const publicKey = publicKeys[String(keyId)];

  if (!publicKey) {
    throw new Error(
      `Unknown AdMob public key: ${keyId}`
    );
  }

  const signedQueryString =
    buildSignedQueryString(originalUrl);

  const signatureBuffer =
    base64UrlToBuffer(signature);

  const verifier = crypto.createVerify("SHA256");

  verifier.update(signedQueryString);
  verifier.end();

  const isValid = verifier.verify(
    publicKey,
    signatureBuffer
  );

  if (!isValid) {
    throw new Error("Invalid AdMob SSV signature.");
  }

  return true;
}

/**
 * Validates the semantic contents of a verified AdMob SSV callback.
 *
 * IMPORTANT:
 * reward_amount = 125 and reward_item = Coins
 * are the values configured in the AdMob ad unit.
 *
 * They are NOT 125 STL.
 */
function validateAdMobCallbackData(req) {
  const query = req.query || {};

  const adUnit = query.ad_unit;
  const rewardAmount = query.reward_amount;
  const rewardItem = query.reward_item;
  const transactionId = query.transaction_id;
  const userId = query.user_id;
  const timestamp = query.timestamp;

  if (!adUnit) {
    throw new Error("Missing AdMob ad_unit.");
  }

  if (String(adUnit) !== String(ADMOB_SSV_AD_UNIT_ID)) {
    throw new Error(
      `Unexpected AdMob ad_unit: ${adUnit}`
    );
  }

  if (rewardAmount === undefined || rewardAmount === null) {
    throw new Error("Missing AdMob reward_amount.");
  }

  const numericRewardAmount = Number(rewardAmount);

  if (
    !Number.isFinite(numericRewardAmount) ||
    numericRewardAmount !== Number(ADMOB_SSV_REWARD_AMOUNT)
  ) {
    throw new Error(
      `Unexpected AdMob reward_amount: ${rewardAmount}`
    );
  }

  if (!rewardItem) {
    throw new Error("Missing AdMob reward_item.");
  }

  if (
    String(rewardItem) !== String(ADMOB_SSV_REWARD_ITEM)
  ) {
    throw new Error(
      `Unexpected AdMob reward_item: ${rewardItem}`
    );
  }

  if (!transactionId) {
    throw new Error(
      "Missing AdMob transaction_id."
    );
  }

  if (!userId) {
    throw new Error("Missing AdMob user_id.");
  }

  if (timestamp === undefined || timestamp === null) {
    throw new Error("Missing AdMob timestamp.");
  }

  const numericTimestamp = Number(timestamp);

  if (
    !Number.isFinite(numericTimestamp) ||
    numericTimestamp <= 0
  ) {
    throw new Error(
      `Invalid AdMob timestamp: ${timestamp}`
    );
  }

  return {
    adNetwork: query.ad_network || null,
    adUnit: String(adUnit),
    customData: query.custom_data || null,
    keyId: String(query.key_id),
    rewardAmount: numericRewardAmount,
    rewardItem: String(rewardItem),
    timestamp: numericTimestamp,
    transactionId: String(transactionId),
    userId: String(userId),
  };
}

/**
 * Verifies and validates an AdMob SSV callback.
 *
 * Returns the trusted callback data only after:
 *
 * 1. The cryptographic AdMob signature is valid.
 * 2. The ad unit matches Stelluriini's production ad unit.
 * 3. The reward amount matches the configured AdMob reward.
 * 4. The reward item matches the configured AdMob reward.
 * 5. Required callback identifiers exist.
 */
async function verifyAdMobCallback(req) {
  await verifyAdMobSignature(req);

  return validateAdMobCallbackData(req);
}

module.exports = {
  verifyAdMobCallback,
};