"use strict";

const crypto = require("crypto");

const {
  ADMOB_SSV_REWARD_AMOUNT,
} = require("../config/miningConfig");

// ============================================================
// 🐱 STELLA ADMOB SSV SERVICE
// ============================================================
//
// AdMob Rewarded
//      ↓
// Google SSV callback
//      ↓
// alkuperäinen query string
//      ↓
// ECDSA signature verification
//      ↓
// callback-parametrien tarkistus
//      ↓
// custom_data
//      ↓
// admobRewards/{transactionId}
//
// TÄRKEÄ:
// Allekirjoitettavaa query stringiä EI muuteta ennen
// kryptografista tarkistusta.
//
// Googlen mukaan SSV callbackin viimeiset kaksi parametriä ovat:
//
//   signature
//   key_id
//
// Kaikki niitä edeltävät parametrit muodostavat
// allekirjoitettavan sisällön.
// ============================================================

// ============================================================
// 🌐 GOOGLE ADMOB PUBLIC KEY URL
// ============================================================

const ADMOB_PUBLIC_KEYS_URL =
  "https://www.gstatic.com/admob/reward/verifier-keys.json";

// ============================================================
// ⏱️ PUBLIC KEY CACHE
// ============================================================

const PUBLIC_KEY_CACHE_MS =
  60 * 60 * 1000;

let cachedPublicKeys = null;
let cachedPublicKeysAt = 0;

// ============================================================
// 📺 STELLURIINI ADMOB REWARDED AD UNITS
// ============================================================

const MINING_AD_UNIT_ID =
  "ca-app-pub-1131012057145658/6674097787";

const POWER_BOOST_AD_UNIT_ID =
  "ca-app-pub-1131012057145658/7225738491";

const ALLOWED_AD_UNIT_IDS = new Set([
  MINING_AD_UNIT_ID,
  POWER_BOOST_AD_UNIT_ID,
]);

// ============================================================
// 🎁 STELLURIINI REWARD ITEMS
// ============================================================

const MINING_REWARD_ITEM =
  "Mining";

const POWER_BOOST_REWARD_ITEM =
  "Power Boost";

// ============================================================
// 🔢 SAFE NUMBER
// ============================================================

function getSafeNumber(
  value,
  fallback = 0
) {
  const number =
    Number(value);

  return Number.isFinite(number)
    ? number
    : fallback;
}

// ============================================================
// 🔐 NORMALIZE STRING
// ============================================================

function normalizeString(
  value
) {
  if (
    value === undefined ||
    value === null
  ) {
    return "";
  }

  return String(value).trim();
}

// ============================================================
// 🔑 LOAD ADMOB PUBLIC KEYS
// ============================================================

async function getAdMobPublicKeys() {
  const now =
    Date.now();

  if (
    cachedPublicKeys &&
    now - cachedPublicKeysAt <
      PUBLIC_KEY_CACHE_MS
  ) {
    return cachedPublicKeys;
  }

  console.log(
    "🐱🔑 Downloading AdMob SSV public keys..."
  );

  const response =
    await fetch(
      ADMOB_PUBLIC_KEYS_URL
    );

  if (
    !response.ok
  ) {
    throw new Error(
      `AdMob public key request failed: HTTP ${response.status}`
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

  const publicKeys = {};

  for (
    const key of data.keys
  ) {
    if (
      !key ||
      key.keyId === undefined ||
      key.keyId === null ||
      typeof key.pem !== "string" ||
      key.pem.trim().length === 0
    ) {
      continue;
    }

    publicKeys[
      String(key.keyId)
    ] =
      key.pem;
  }

  if (
    Object.keys(publicKeys).length === 0
  ) {
    throw new Error(
      "No valid AdMob public keys were returned."
    );
  }

  cachedPublicKeys =
    publicKeys;

  cachedPublicKeysAt =
    now;

  console.log(
    "🐱🔑 AdMob public keys loaded:",
    Object.keys(publicKeys)
  );

  return publicKeys;
}

// ============================================================
// 🔐 GET ORIGINAL QUERY STRING
// ============================================================
//
// TÄRKEIN SÄÄNTÖ:
//
// Tätä dataa ei URL-dekoodata.
// Tätä dataa ei rakenneta uudelleen req.query-arvoista.
//
// Käytämme callbackin alkuperäistä URL:ia.
//
// ============================================================

function getRawQueryString(
  url
) {
  if (
    typeof url !== "string" ||
    url.length === 0
  ) {
    return "";
  }

  const questionMark =
    url.indexOf("?");

  if (
    questionMark === -1
  ) {
    return "";
  }

  return url.substring(
    questionMark + 1
  );
}

// ============================================================
// 🔐 GET ORIGINAL REQUEST URL
// ============================================================

function getOriginalRequestUrl(
  req
) {
  const candidates = [
    {
      name:
        "req.originalUrl",

      value:
        req.originalUrl,
    },

    {
      name:
        "req.url",

      value:
        req.url,
    },
  ];

  for (
    const candidate of candidates
  ) {
    if (
      typeof candidate.value === "string" &&
      candidate.value.includes("?")
    ) {
      return candidate;
    }
  }

  return null;
}

// ============================================================
// 🔐 EXTRACT SIGNED QUERY STRING
// ============================================================
//
// Google AdMob:
//
// ...&user_id=XYZ&signature=ABC&key_id=123
//
// Allekirjoitettava sisältö on:
//
// ...&user_id=XYZ
//
// Huom:
// Emme dekoodaa emmekä järjestä parametreja uudelleen.
// ============================================================

function extractSignedQueryString(
  rawQueryString
) {
  const marker =
    "&signature=";

  const signatureIndex =
    rawQueryString.indexOf(
      marker
    );

  if (
    signatureIndex === -1
  ) {
    throw new Error(
      "AdMob signature parameter was not found in original query string."
    );
  }

  const signedQuery =
    rawQueryString.substring(
      0,
      signatureIndex
    );

  if (
    signedQuery.length === 0
  ) {
    throw new Error(
      "AdMob signed query string is empty."
    );
  }

  return signedQuery;
}

// ============================================================
// 🔐 EXTRACT RAW SIGNATURE
// ============================================================

function extractSignature(
  rawQueryString
) {
  const marker =
    "&signature=";

  const signatureIndex =
    rawQueryString.indexOf(
      marker
    );

  if (
    signatureIndex === -1
  ) {
    throw new Error(
      "AdMob signature parameter not found."
    );
  }

  const afterSignature =
    rawQueryString.substring(
      signatureIndex +
        marker.length
    );

  const keyIdMarker =
    "&key_id=";

  const keyIdIndex =
    afterSignature.indexOf(
      keyIdMarker
    );

  let rawSignature;

  if (
    keyIdIndex === -1
  ) {
    rawSignature =
      afterSignature;
  } else {
    rawSignature =
      afterSignature.substring(
        0,
        keyIdIndex
      );
  }

  if (
    !rawSignature
  ) {
    throw new Error(
      "AdMob signature value is empty."
    );
  }

  // Signature itsessään voidaan decodeURIComponent-käsitellä.
  //
  // Allekirjoitettavaa query-dataa ei koskaan dekoodata.
  try {
    return decodeURIComponent(
      rawSignature
    );
  } catch (
    error
  ) {
    return rawSignature;
  }
}

// ============================================================
// 🔐 BASE64URL → BUFFER
// ============================================================

function base64UrlToBuffer(
  value
) {
  const normalizedValue =
    normalizeString(value);

  if (
    normalizedValue.length === 0
  ) {
    throw new Error(
      "AdMob signature is empty."
    );
  }

  let normalized =
    normalizedValue
      .replace(/-/g, "+")
      .replace(/_/g, "/");

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
    buffer.length === 0
  ) {
    throw new Error(
      "AdMob signature could not be decoded."
    );
  }

  return buffer;
}

// ============================================================
// 🔐 VERIFY ECDSA SIGNATURE
// ============================================================

function verifySignature(
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

// ============================================================
// 🔐 VERIFY ADMOB SIGNATURE
// ============================================================

async function verifyAdMobSignature(
  req
) {
  console.log(
    "🐱🔐 AdMob SSV cryptographic verification started."
  );

  // ==========================================================
  // KEY ID
  // ==========================================================

  const keyId =
    normalizeString(
      req.query?.key_id
    );

  if (
    keyId.length === 0
  ) {
    throw new Error(
      "Missing AdMob key_id."
    );
  }

  console.log(
    "🐱 AdMob key_id:",
    keyId
  );

  // ==========================================================
  // PUBLIC KEY
  // ==========================================================

  const publicKeys =
    await getAdMobPublicKeys();

  const publicKey =
    publicKeys[keyId];

  if (
    !publicKey
  ) {
    throw new Error(
      `Unknown AdMob public key: ${keyId}`
    );
  }

  // ==========================================================
  // ORIGINAL URL
  // ==========================================================

  const requestUrl =
    getOriginalRequestUrl(
      req
    );

  if (
    !requestUrl
  ) {
    throw new Error(
      "Could not obtain original AdMob callback URL."
    );
  }

  console.log(
    "🐱 AdMob callback URL source:",
    requestUrl.name
  );

  const rawQueryString =
    getRawQueryString(
      requestUrl.value
    );

  if (
    rawQueryString.length === 0
  ) {
    throw new Error(
      "AdMob callback contains no query string."
    );
  }

  // ==========================================================
  // SIGNED CONTENT
  // ==========================================================

  const signedQueryString =
    extractSignedQueryString(
      rawQueryString
    );

  // ==========================================================
  // SIGNATURE
  // ==========================================================

  const signature =
    extractSignature(
      rawQueryString
    );

  const signatureBuffer =
    base64UrlToBuffer(
      signature
    );

  // ==========================================================
  // DEBUG HASH
  // ==========================================================
  //
  // Emme tulosta käyttäjän UID:tä tai allekirjoitusta.
  // Hash auttaa vertailemaan callbackien rakennetta
  // Firebase-logeista turvallisesti.
  //
  // ==========================================================

  const signedQueryHash =
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
    "🐱 AdMob signed query diagnostics:",
    {
      queryLength:
        rawQueryString.length,

      signedQueryLength:
        signedQueryString.length,

      signedQueryHash,

      signatureLength:
        signatureBuffer.length,

      keyId,
    }
  );

  // ==========================================================
  // VERIFY
  // ==========================================================

  const valid =
    verifySignature(
      signedQueryString,
      signatureBuffer,
      publicKey
    );

  if (
    !valid
  ) {
    console.error(
      "❌ AdMob SSV signature INVALID.",
      {
        keyId,
        signedQueryLength:
          signedQueryString.length,
        signedQueryHash,
        signatureLength:
          signatureBuffer.length,
      }
    );

    throw new Error(
      "Invalid AdMob SSV signature."
    );
  }

  console.log(
    "🐱✅ AdMob SSV signature VALID.",
    {
      keyId,
      signedQueryHash,
    }
  );

  return true;
}

// ============================================================
// 🔐 NORMALIZE CUSTOM DATA
// ============================================================

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

  // Google kertoo, että custom_data voi olla
  // percent-enkoodattu.
  //
  // Tämä dekoodataan vasta signature verificationin
  // jälkeen.
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
    normalized.length === 0 ||
    normalized.length > 128
  ) {
    throw new Error(
      "Invalid AdMob custom_data length."
    );
  }

  if (
    !/^[A-Za-z0-9._:-]+$/.test(
      normalized
    )
  ) {
    throw new Error(
      "Invalid Stelluriini AdMob custom_data format."
    );
  }

  return normalized;
}

// ============================================================
// 🔐 NORMALIZE TRANSACTION ID
// ============================================================

function normalizeTransactionId(
  value
) {
  const normalized =
    normalizeString(value);

  if (
    normalized.length === 0
  ) {
    throw new Error(
      "Missing AdMob transaction_id."
    );
  }

  if (
    normalized.length > 256
  ) {
    throw new Error(
      "AdMob transaction_id is too long."
    );
  }

  return normalized;
}

// ============================================================
// 🔐 NORMALIZE TIMESTAMP
// ============================================================

function normalizeTimestamp(
  value
) {
  const timestamp =
    getSafeNumber(
      value,
      0
    );

  if (
    timestamp <= 0
  ) {
    throw new Error(
      "Invalid AdMob timestamp."
    );
  }

  return timestamp;
}

// ============================================================
// 🎯 DETERMINE REWARD PURPOSE
// ============================================================

function getRewardPurpose(
  customData
) {
  if (
    customData.endsWith(
      ":mining_start"
    )
  ) {
    return "mining_start";
  }

  if (
    customData.endsWith(
      ":power_boost"
    )
  ) {
    return "power_boost";
  }

  throw new Error(
    "Invalid Stelluriini AdMob reward purpose."
  );
}

// ============================================================
// 🔐 VALIDATE CALLBACK DATA
// ============================================================

function validateAdMobCallbackData(
  req
) {
  const query =
    req.query || {};

  const adNetwork =
    normalizeString(
      query.ad_network
    );

  const adUnit =
    normalizeString(
      query.ad_unit
    );

  const rewardAmount =
    getSafeNumber(
      query.reward_amount,
      0
    );

  const rewardItem =
    normalizeString(
      query.reward_item
    );

  const transactionId =
    normalizeTransactionId(
      query.transaction_id
    );

  const customData =
    normalizeCustomData(
      query.custom_data
    );

  const userId =
    normalizeString(
      query.user_id
    );

  const timestamp =
    normalizeTimestamp(
      query.timestamp
    );

  const keyId =
    normalizeString(
      query.key_id
    );

  // ==========================================================
  // AD UNIT
  // ==========================================================

  if (
    !ALLOWED_AD_UNIT_IDS.has(
      adUnit
    )
  ) {
    throw new Error(
      `Unexpected Stelluriini AdMob ad_unit: ${adUnit}`
    );
  }

  // ==========================================================
  // REWARD PURPOSE
  // ==========================================================

  const rewardPurpose =
    getRewardPurpose(
      customData
    );

  // ==========================================================
  // AD UNIT ↔ PURPOSE
  // ==========================================================
  //
  // Estetään esimerkiksi Power Boost custom_data + Mining
  // ad unit -yhdistelmä.
  //
  // ==========================================================

  if (
    rewardPurpose === "mining_start" &&
    adUnit !== MINING_AD_UNIT_ID
  ) {
    throw new Error(
      "Mining Start reward used with unexpected AdMob ad unit."
    );
  }

  if (
    rewardPurpose === "power_boost" &&
    adUnit !== POWER_BOOST_AD_UNIT_ID
  ) {
    throw new Error(
      "Power Boost reward used with unexpected AdMob ad unit."
    );
  }

  // ==========================================================
  // REWARD AMOUNT
  // ==========================================================

  const expectedAmount =
    getSafeNumber(
      ADMOB_SSV_REWARD_AMOUNT,
      1
    );

  if (
    rewardAmount !==
    expectedAmount
  ) {
    throw new Error(
      `Unexpected AdMob reward_amount: ${rewardAmount}. Expected: ${expectedAmount}`
    );
  }

  // ==========================================================
  // REWARD ITEM
  // ==========================================================

  const expectedRewardItem =
    rewardPurpose ===
      "mining_start"
      ? MINING_REWARD_ITEM
      : POWER_BOOST_REWARD_ITEM;

  if (
    rewardItem !==
    expectedRewardItem
  ) {
    throw new Error(
      `Unexpected AdMob reward_item: ${rewardItem}. Expected: ${expectedRewardItem}`
    );
  }

  // ==========================================================
  // KEY ID
  // ==========================================================

  if (
    keyId.length === 0
  ) {
    throw new Error(
      "Missing AdMob key_id."
    );
  }

  // ==========================================================
  // RESULT
  // ==========================================================

  const result = {
    adNetwork:
      adNetwork || "admob",

    adUnit,

    rewardAmount,

    rewardItem,

    transactionId,

    customData,

    userId:
      userId || null,

    timestamp,

    keyId,

    rewardPurpose,
  };

  console.log(
    "🐱✅ AdMob callback data validated:",
    {
      adNetwork:
        result.adNetwork,

      adUnit:
        result.adUnit,

      rewardAmount:
        result.rewardAmount,

      rewardItem:
        result.rewardItem,

      transactionId:
        result.transactionId,

      rewardPurpose:
        result.rewardPurpose,

      hasUserId:
        Boolean(
          result.userId
        ),
    }
  );

  return result;
}

// ============================================================
// 🔐 MAIN ADMOB SSV VERIFICATION
// ============================================================

async function verifyAdMobCallback(
  req
) {
  console.log(
    "🐱📺 AdMob SSV callback received."
  );

  // ==========================================================
  // 1. CRYPTOGRAPHIC VERIFICATION
  // ==========================================================

  await verifyAdMobSignature(
    req
  );

  console.log(
    "🐱✅ AdMob SSV cryptographic verification passed."
  );

  // ==========================================================
  // 2. CALLBACK DATA VALIDATION
  // ==========================================================

  const result =
    validateAdMobCallbackData(
      req
    );

  console.log(
    "🐱✅ AdMob SSV callback fully validated.",
    {
      rewardPurpose:
        result.rewardPurpose,

      transactionId:
        result.transactionId,

      adUnit:
        result.adUnit,
    }
  );

  return result;
}

// ============================================================
// 📦 EXPORT
// ============================================================

module.exports = {
  verifyAdMobCallback,
};