"use strict";

const crypto = require("crypto");

const {
  ADMOB_SSV_REWARD_AMOUNT,
} = require("../config/miningConfig");

// ==========================================
// 🐱 STELLA ADMOB SSV
// ==========================================
//
// AdMob SSV:
//
// 📺 Rewarded Ad
//       ↓
// 🔐 Google SSV callback
//       ↓
// 🔑 Signature verification
//       ↓
// 🎯 custom_data
//       ↓
// 💾 admobRewards/{transactionId}
//
// TÄRKEÄ:
//
// Allekirjoitettavaa query-stringiä EI saa
// muuttaa ennen kryptografista tarkistusta.
//
// Google edellyttää alkuperäisen query-stringin
// säilyttämistä sellaisenaan.
// ==========================================


// ==========================================
// 🌐 ADMOB PUBLIC KEY URL
// ==========================================

const ADMOB_PUBLIC_KEYS_URL =
  "https://www.gstatic.com/admob/reward/verifier-keys.json";

// AdMob voi vaihtaa julkisia avaimia.
// Google suosittelee cachea, mutta ei yli 24 h.
// Käytetään tässä 1 tuntia.
// ==========================================

const PUBLIC_KEY_CACHE_MS =
  60 * 60 * 1000;

let cachedKeys = null;
let cachedKeysAt = 0;


// ==========================================
// 📺 CURRENT STELLURIINI REWARDED AD UNITS
// ==========================================
//
// Mining:
//
// ca-app-pub-1131012057145658/6674097787
//
// Power Boost:
//
// ca-app-pub-1131012057145658/7225738491
//
// Molemmat ovat tällä hetkellä Stelluriinin
// käytössä olevia Rewarded-mainosyksiköitä.
// ==========================================

const MINING_AD_UNIT_ID =
  "ca-app-pub-1131012057145658/6674097787";

const POWER_BOOST_AD_UNIT_ID =
  "ca-app-pub-1131012057145658/7225738491";

const ALLOWED_AD_UNIT_IDS = new Set([
  MINING_AD_UNIT_ID,
  POWER_BOOST_AD_UNIT_ID,
]);


// ==========================================
// 🎁 EXPECTED REWARD ITEMS
// ==========================================
//
// AdMobissa:
//
// Mining:
//
//   1 Mining
//
// Power Boost:
//
//   1 Power Boost
//
// SSV:n custom_data kertoo kumpi toiminto
// kyseessä on.
//
// ==========================================

const MINING_REWARD_ITEM =
  "Mining";

const POWER_BOOST_REWARD_ITEM =
  "Power Boost";


// ==========================================
// 🔑 GET ADMOB PUBLIC KEYS
// ==========================================

async function getAdMobPublicKeys() {
  const now =
    Date.now();

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
// 🔐 BASE64URL DECODER
// ==========================================

function base64UrlToBuffer(
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

  normalized =
    normalized
      .replace(/-/g, "+")
      .replace(/_/g, "/")
      .replace(/\s/g, "");

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
// 🔐 GET CANDIDATE REQUEST URLS
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
// 🔐 GET RAW QUERY STRING
// ==========================================
//
// TÄRKEÄ:
//
// Tätä merkkijonoa ei dekoodata.
//
// Google allekirjoittaa alkuperäisen
// query-stringin.
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
// 🔐 BUILD SIGNED QUERY STRING
// ==========================================
//
// AdMob SSV:
//
// Kaikki parametrit ennen:
//
//   &signature=
//
// kuuluvat allekirjoitukseen.
//
// Mitään URL-dekoodausta ei tehdä.
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
// 🔐 EXTRACT RAW SIGNATURE
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

  // Vain signature dekoodataan.
  //
  // Allekirjoitettavaa query-dataa EI dekoodata.
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
// 🔐 GET ADMOB SIGNATURE
// ==========================================

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
// 🔐 VERIFY SIGNED QUERY
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
// 🔐 VERIFY ADMOB SIGNATURE
// ==========================================

async function verifyAdMobSignature(
  req
) {
  console.log(
    "🐱 AdMob SSV signature verification started."
  );

  // ========================================
  // KEY ID
  // ========================================

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

  // ========================================
  // PUBLIC KEYS
  // ========================================

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
    "🐱 AdMob public key found:",
    normalizedKeyId
  );

  // ========================================
  // CANDIDATE URLS
  // ========================================

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

  // ========================================
  // SIGNATURE
  // ========================================

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
    base64UrlToBuffer(
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

  // ========================================
  // VERIFY CANDIDATE URLS
  // ========================================

  for (
    const candidate of candidateUrls
  ) {
    try {
      const signedQueryString =
        buildSignedQueryString(
          candidate.value
        );

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

  throw new Error(
    "Invalid AdMob SSV signature."
  );
}


// ==========================================
// 🔐 NORMALIZE CUSTOM DATA
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

  // AdMob custom_data voi olla
  // percent-enkoodattu.
  //
  // Tämä tehdään vasta SSV-signatuurin
  // onnistuneen tarkistuksen JÄLKEEN.
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
// 🔐 VALIDATE TRANSACTION ID
// ==========================================

function normalizeTransactionId(
  value
) {
  if (
    value === undefined ||
    value === null
  ) {
    throw new Error(
      "Missing AdMob transaction_id."
    );
  }

  const normalized =
    String(
      value
    ).trim();

  if (
    normalized.length === 0
  ) {
    throw new Error(
      "Invalid AdMob transaction_id."
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


// ==========================================
// 🔐 VALIDATE TIMESTAMP
// ==========================================

function validateTimestamp(
  value
) {
  if (
    value === undefined ||
    value === null
  ) {
    throw new Error(
      "Missing AdMob timestamp."
    );
  }

  const numericTimestamp =
    Number(
      value
    );

  if (
    !Number.isFinite(
      numericTimestamp
    ) ||
    numericTimestamp <= 0
  ) {
    throw new Error(
      `Invalid AdMob timestamp: ${value}`
    );
  }

  return numericTimestamp;
}


// ==========================================
// 🔐 VALIDATE CALLBACK DATA
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
  // AD UNIT
  // ========================================

  if (
    !adUnit
  ) {
    throw new Error(
      "Missing AdMob ad_unit."
    );
  }

  const normalizedAdUnit =
    String(
      adUnit
    ).trim();

  if (
    !ALLOWED_AD_UNIT_IDS.has(
      normalizedAdUnit
    )
  ) {
    throw new Error(
      `Unexpected Stelluriini AdMob ad_unit: ${normalizedAdUnit}`
    );
  }

  // ========================================
  // REWARD AMOUNT
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
  // CUSTOM DATA
  // ========================================

  const normalizedCustomData =
    normalizeCustomData(
      customData
    );

  // ========================================
  // DETERMINE PURPOSE
  // ========================================

  let rewardPurpose =
    null;

  if (
    normalizedCustomData.endsWith(
      ":mining_start"
    )
  ) {
    rewardPurpose =
      "mining_start";
  }

  if (
    normalizedCustomData.endsWith(
      ":power_boost"
    )
  ) {
    rewardPurpose =
      "power_boost";
  }

  if (
    !rewardPurpose
  ) {
    throw new Error(
      "Invalid Stelluriini AdMob reward purpose."
    );
  }

  // ========================================
  // REWARD ITEM
  // ========================================

  if (
    !rewardItem
  ) {
    throw new Error(
      "Missing AdMob reward_item."
    );
  }

  const normalizedRewardItem =
    String(
      rewardItem
    ).trim();

  const expectedRewardItem =
    rewardPurpose ===
      "power_boost"
      ? POWER_BOOST_REWARD_ITEM
      : MINING_REWARD_ITEM;

  if (
    normalizedRewardItem !==
    expectedRewardItem
  ) {
    throw new Error(
      `Unexpected AdMob reward_item: ${normalizedRewardItem}. Expected: ${expectedRewardItem}`
    );
  }

  // ========================================
  // TRANSACTION ID
  // ========================================

  const normalizedTransactionId =
    normalizeTransactionId(
      transactionId
    );

  // ========================================
  // USER ID
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
  // TIMESTAMP
  // ========================================

  const numericTimestamp =
    validateTimestamp(
      timestamp
    );

  // ========================================
  // KEY ID
  // ========================================

  const keyId =
    query.key_id;

  if (
    keyId === undefined ||
    keyId === null ||
    String(keyId).trim().length === 0
  ) {
    throw new Error(
      "Missing AdMob key_id."
    );
  }

  // ========================================
  // AD NETWORK
  // ========================================

  const adNetwork =
    query.ad_network
      ? String(
          query.ad_network
        )
      : null;

  // ========================================
  // TRUSTED RESULT
  // ========================================

  const result = {
    adNetwork,

    adUnit:
      normalizedAdUnit,

    customData:
      normalizedCustomData,

    keyId:
      String(
        keyId
      ),

    rewardAmount:
      numericRewardAmount,

    rewardItem:
      normalizedRewardItem,

    timestamp:
      numericTimestamp,

    transactionId:
      normalizedTransactionId,

    userId:
      normalizedUserId,

    rewardPurpose,
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

      rewardPurpose:
        result.rewardPurpose,

      userId:
        result.userId,
    }
  );

  return result;
}


// ==========================================
// 🔐 MAIN ADMOB SSV VERIFICATION
// ==========================================

async function verifyAdMobCallback(
  req
) {
  console.log(
    "🐱 AdMob SSV verification started."
  );

  // ========================================
  // 1. CRYPTOGRAPHIC VERIFICATION
  // ========================================

  await verifyAdMobSignature(
    req
  );

  console.log(
    "🐱✅ AdMob SSV signature verified."
  );

  // ========================================
  // 2. CALLBACK DATA VALIDATION
  // ========================================

  const result =
    validateAdMobCallbackData(
      req
    );

  console.log(
    "🐱✅ AdMob SSV callback completely verified."
  );

  return result;
}


// ==========================================
// 📦 EXPORT
// ==========================================

module.exports = {
  verifyAdMobCallback,
};