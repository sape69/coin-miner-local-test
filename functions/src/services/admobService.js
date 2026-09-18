"use strict";

const crypto = require("crypto");

// ============================================================
// 🐱 STELLURIINI - ADMOB SERVICE
// ============================================================
//
// AdMob Rewarded SSV:
//
// Google
//    ↓
// raw query string
//    ↓
// ECDSA SHA-256
//    ↓
// parameter validation
//    ↓
// verifiedAd
//
// Tämä tiedosto EI:
//
// ❌ lisää STL-saldoa
// ❌ aktivoi Power Boostia
// ❌ käynnistä Mining Startia
// ❌ muuta adsToday-arvoa
// ❌ muuta cooldownia
//
// Varsinaiset toiminnot tehdään erillisissä Cloud Functions
// -toiminnoissa.
//
// ============================================================


// ============================================================
// 🔐 ADMOB PUBLIC KEY URL
// ============================================================

const ADMOB_SSV_KEYS_URL =
  "https://www.gstatic.com/admob/reward/verifier-keys.json";


// ============================================================
// ⏱️ PUBLIC KEY CACHE
// ============================================================
//
// Google suosittelee public key -avainten cachettamista,
// mutta niitä ei pidä cachettaa yli 24 tunniksi.
//
// Käytämme 23 tuntia.
// ============================================================

const PUBLIC_KEY_CACHE_MS =
  23 * 60 * 60 * 1000;

let cachedPublicKeys = null;

let cachedPublicKeysAt = 0;


// ============================================================
// 📺 STELLURIINI ADMOB AD UNITS
// ============================================================

const ADMOB_AD_UNITS = {
  mining_start:
    "6674097787",

  power_boost:
    "7225738491",
};


// ============================================================
// 🎁 EXPECTED REWARDS
// ============================================================
//
// Reward ei ole STL-maksu.
//
// Se kertoo ainoastaan, minkä rewarded-mainoksen käyttäjä
// suoritti.
//
// Varsinainen toiminto käsitellään muualla.
//
// ============================================================

const REWARD_DEFINITIONS = {
  mining_start: {
    rewardItem:
      "Mining",

    rewardAmount:
      1,
  },

  power_boost: {
    rewardItem:
      "Power Boost",

    rewardAmount:
      1,
  },
};


// ============================================================
// 🌐 FETCH JSON
// ============================================================

async function fetchJson(
  url,
) {
  const response =
    await fetch(url);

  if (!response.ok) {
    throw new Error(
      `AdMob public key server returned HTTP ${response.status}`,
    );
  }

  return response.json();
}


// ============================================================
// 🔑 LOAD ADMOB PUBLIC KEYS
// ============================================================

async function getAdMobPublicKeys(
  forceRefresh = false,
) {
  const now =
    Date.now();

  // ----------------------------------------------------------
  // CACHE
  // ----------------------------------------------------------

  if (
    !forceRefresh &&
    cachedPublicKeys &&
    now -
      cachedPublicKeysAt <
      PUBLIC_KEY_CACHE_MS
  ) {
    return cachedPublicKeys;
  }

  // ----------------------------------------------------------
  // DOWNLOAD
  // ----------------------------------------------------------

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

  // ----------------------------------------------------------
  // BUILD KEY MAP
  // ----------------------------------------------------------

  const keys =
    new Map();

  for (
    const key of data.keys
  ) {
    if (
      !key ||
      key.keyId === undefined ||
      typeof key.pem !== "string" ||
      key.pem.length === 0
    ) {
      continue;
    }

    keys.set(
      String(key.keyId),
      key.pem,
    );
  }

  if (
    keys.size === 0
  ) {
    throw new Error(
      "No usable AdMob public keys were returned.",
    );
  }

  // ----------------------------------------------------------
  // SAVE CACHE
  // ----------------------------------------------------------

  cachedPublicKeys =
    keys;

  cachedPublicKeysAt =
    now;

  console.log(
    "🐱 AdMob public keys loaded.",
    {
      count:
        keys.size,

      keyIds:
        Array.from(
          keys.keys(),
        ),
    },
  );

  return keys;
}


// ============================================================
// 🔎 EXTRACT QUERY STRING
// ============================================================
//
// TÄMÄ ON ALLEKIRJOITUKSEN KANNALTA KRIITTINEN.
//
// Google allekirjoittaa alkuperäisen query-string-sisällön.
//
// Siksi emme:
//
// ❌ käytä URLSearchParams.toString()
// ❌ pura ja rakenna query-stringiä uudelleen
// ❌ järjestä parametreja
// ❌ URL-enkoodaa arvoja uudelleen
//
// ============================================================

function extractQueryStringFromUrl(
  url,
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
    questionMark < 0
  ) {
    return "";
  }

  return url.substring(
    questionMark + 1,
  );
}


// ============================================================
// 🔎 GET RAW QUERY STRING
// ============================================================
//
// Firebase Functions käyttää Express request -objektia.
//
// Ensisijainen lähde:
//
//   req.originalUrl
//
// Fallback:
//
//   req.url
//
// ============================================================

function getRawQueryString(
  req,
) {
  if (!req) {
    throw new Error(
      "Missing HTTP request.",
    );
  }

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

    {
      name:
        "req.rawUrl",

      value:
        req.rawUrl,
    },
  ];

  for (
    const candidate of candidates
  ) {
    const query =
      extractQueryStringFromUrl(
        candidate.value,
      );

    if (
      query.length > 0
    ) {
      return query;
    }
  }

  // ----------------------------------------------------------
  // Express parsed URL fallback
  // ----------------------------------------------------------

  if (
    req._parsedUrl &&
    typeof req._parsedUrl.search ===
      "string" &&
    req._parsedUrl.search.startsWith("?")
  ) {
    const query =
      req._parsedUrl.search.substring(
        1,
      );

    if (
      query.length > 0
    ) {
      return query;
    }
  }

  throw new Error(
    "AdMob SSV query string is missing.",
  );
}


// ============================================================
// 🔐 DECODE ADMOB SIGNATURE
// ============================================================
//
// AdMob käyttää URL-safe Base64 -esitystä.
//
// ============================================================

function decodeAdMobSignature(
  signature,
) {
  if (
    typeof signature !== "string" ||
    signature.length === 0
  ) {
    throw new Error(
      "AdMob SSV signature is missing.",
    );
  }

  const normalized =
    signature
      .replace(
        /-/g,
        "+",
      )
      .replace(
        /_/g,
        "/",
      );

  const padding =
    normalized.length % 4;

  const padded =
    padding === 0
      ? normalized
      : normalized +
        "=".repeat(
          4 - padding,
        );

  const signatureBuffer =
    Buffer.from(
      padded,
      "base64",
    );

  if (
    signatureBuffer.length === 0
  ) {
    throw new Error(
      "AdMob SSV signature could not be decoded.",
    );
  }

  return signatureBuffer;
}


// ============================================================
// 🔎 EXTRACT SIGNATURE DATA
// ============================================================
//
// Google määrittelee, että kaksi viimeistä parametria ovat:
//
//   signature
//   key_id
//
// Allekirjoitettava sisältö on kaikki sitä edeltävä sisältö.
//
// ============================================================

function extractSignatureData(
  rawQueryString,
) {
  const signatureMarker =
    "&signature=";

  const signatureIndex =
    rawQueryString.indexOf(
      signatureMarker,
    );

  if (
    signatureIndex < 0
  ) {
    throw new Error(
      "AdMob SSV signature parameter was not found.",
    );
  }

  const signedQueryString =
    rawQueryString.substring(
      0,
      signatureIndex,
    );

  if (
    signedQueryString.length === 0
  ) {
    throw new Error(
      "AdMob SSV signed query string is empty.",
    );
  }

  // ----------------------------------------------------------
  // SIGNATURE + KEY ID
  // ----------------------------------------------------------

  const signatureAndKeyId =
    rawQueryString.substring(
      signatureIndex + 1,
    );

  const parts =
    signatureAndKeyId.split("&");

  if (
    parts.length !== 2
  ) {
    throw new Error(
      "AdMob SSV signature and key_id must be the final two query parameters.",
    );
  }

  if (
    !parts[0].startsWith(
      "signature=",
    )
  ) {
    throw new Error(
      "AdMob SSV signature is not in the expected position.",
    );
  }

  if (
    !parts[1].startsWith(
      "key_id=",
    )
  ) {
    throw new Error(
      "AdMob SSV key_id is not in the expected position.",
    );
  }

  // ----------------------------------------------------------
  // Decode ONLY the signature/key_id values.
  //
  // Signed query string itself remains untouched.
  // ----------------------------------------------------------

  const signature =
    decodeURIComponent(
      parts[0].substring(
        "signature=".length,
      ),
    );

  const keyId =
    decodeURIComponent(
      parts[1].substring(
        "key_id=".length,
      ),
    );

  if (
    signature.length === 0
  ) {
    throw new Error(
      "AdMob SSV signature value is missing.",
    );
  }

  if (
    keyId.length === 0
  ) {
    throw new Error(
      "AdMob SSV key_id value is missing.",
    );
  }

  return {
    signedQueryString,

    signature,

    keyId,
  };
}


// ============================================================
// 🔐 VERIFY RAW QUERY STRING
// ============================================================

async function verifyRawQueryString(
  rawQueryString,
) {
  if (
    typeof rawQueryString !==
      "string" ||
    rawQueryString.length === 0
  ) {
    throw new Error(
      "AdMob SSV raw query string is empty.",
    );
  }

  // ----------------------------------------------------------
  // EXTRACT SIGNATURE
  // ----------------------------------------------------------

  const {
    signedQueryString,
    signature,
    keyId,
  } =
    extractSignatureData(
      rawQueryString,
    );

  // ----------------------------------------------------------
  // DECODE SIGNATURE
  // ----------------------------------------------------------

  const signatureBuffer =
    decodeAdMobSignature(
      signature,
    );

  // ----------------------------------------------------------
  // GET PUBLIC KEYS
  // ----------------------------------------------------------

  let publicKeys =
    await getAdMobPublicKeys(
      false,
    );

  let publicKey =
    publicKeys.get(
      String(keyId),
    );

  // ----------------------------------------------------------
  // KEY ROTATION
  // ----------------------------------------------------------

  if (!publicKey) {
    console.log(
      "🐱 AdMob key not found in cache. Refreshing public keys.",
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

  // ==========================================================
  // 🔐 ECDSA SHA-256
  // ==========================================================

  const verifier =
    crypto.createVerify(
      "SHA256",
    );

  // IMPORTANT:
  //
  // signedQueryString is passed exactly as received.
  //
  verifier.update(
    Buffer.from(
      signedQueryString,
      "utf8",
    ),
  );

  verifier.end();

  const verified =
    verifier.verify(
      {
        key:
          publicKey,

        dsaEncoding:
          "der",
      },
      signatureBuffer,
    );

  if (!verified) {
    const error =
      new Error(
        "AdMob SSV signature verification failed.",
      );

    error.code =
      "ADMOB_INVALID_SIGNATURE";

    error.keyId =
      keyId;

    throw error;
  }

  return {
    verified:
      true,

    keyId,

    rawQueryString,

    signedQueryString,

    signature,

    params:
      new URLSearchParams(
        rawQueryString,
      ),
  };
}


// ============================================================
// 🔐 VERIFY ADMOB SIGNATURE
// ============================================================

async function verifyAdMobSignature(
  req,
) {
  const rawQueryString =
    getRawQueryString(
      req,
    );

  const verification =
    await verifyRawQueryString(
      rawQueryString,
    );

  console.log(
    "🐱✅ AdMob SSV signature VERIFIED.",
    {
      keyId:
        verification.keyId,
    },
  );

  return verification;
}


// ============================================================
// 🔎 PARAMETER HELPER
// ============================================================

function getParam(
  params,
  name,
) {
  if (
    !params ||
    typeof params.get !==
      "function"
  ) {
    return "";
  }

  const value =
    params.get(
      name,
    );

  if (
    value === null ||
    value === undefined
  ) {
    return "";
  }

  return String(value);
}


// ============================================================
// 🔢 INTEGER HELPER
// ============================================================

function parseInteger(
  value,
  fallback = 0,
) {
  const number =
    Number(value);

  if (
    !Number.isFinite(
      number,
    )
  ) {
    return fallback;
  }

  return Math.trunc(
    number,
  );
}


// ============================================================
// 🛡️ UID VALIDATION
// ============================================================

function validateUid(
  uid,
) {
  if (
    typeof uid !== "string"
  ) {
    return false;
  }

  const trimmed =
    uid.trim();

  if (
    trimmed.length === 0 ||
    trimmed.length > 128
  ) {
    return false;
  }

  return /^[A-Za-z0-9._-]+$/.test(
    trimmed,
  );
}


// ============================================================
// 🧩 CUSTOM DATA PARSER
// ============================================================
//
// Tuetut:
//
//   UID
//   UID:power_boost
//   UID:mining_start
//
// Vanha pelkkä UID tarkoittaa Power Boostia.
//
// ============================================================

function parseCustomData(
  customData,
) {
  if (
    typeof customData !== "string"
  ) {
    return {
      uid:
        "",

      rewardPurpose:
        "",
    };
  }

  const value =
    customData.trim();

  if (
    value.length === 0 ||
    value.length > 128
  ) {
    return {
      uid:
        "",

      rewardPurpose:
        "",
    };
  }

  // ----------------------------------------------------------
  // OLD FORMAT
  // ----------------------------------------------------------

  if (
    !value.includes(":")
  ) {
    return {
      uid:
        value,

      rewardPurpose:
        "power_boost",
    };
  }

  // ----------------------------------------------------------
  // NEW FORMAT
  // ----------------------------------------------------------

  const separatorIndex =
    value.lastIndexOf(":");

  if (
    separatorIndex <= 0 ||
    separatorIndex >=
      value.length - 1
  ) {
    return {
      uid:
        "",

      rewardPurpose:
        "",
    };
  }

  const uid =
    value
      .substring(
        0,
        separatorIndex,
      )
      .trim();

  const rewardPurpose =
    value
      .substring(
        separatorIndex + 1,
      )
      .trim();

  return {
    uid,

    rewardPurpose,
  };
}


// ============================================================
// 🔐 TRANSACTION ID VALIDATION
// ============================================================
//
// Google määrittelee transaction_id:n unique hex encoded
// identifier -muodossa.
//
// ============================================================

function validateTransactionId(
  transactionId,
) {
  if (
    typeof transactionId !==
      "string"
  ) {
    return false;
  }

  const value =
    transactionId.trim();

  if (
    value.length === 0 ||
    value.length > 256
  ) {
    return false;
  }

  return /^[a-fA-F0-9]+$/.test(
    value,
  );
}


// ============================================================
// ⏱️ TIMESTAMP VALIDATION
// ============================================================
//
// AdMob timestamp on Epoch time milliseconds.
//
// ============================================================

function validateTimestamp(
  timestamp,
) {
  const timestampMs =
    Number(timestamp);

  if (
    !Number.isFinite(
      timestampMs,
    ) ||
    timestampMs <= 0
  ) {
    return {
      valid:
        false,

      timestampMs:
        0,
    };
  }

  const now =
    Date.now();

  const ageMs =
    Math.abs(
      now -
        timestampMs,
    );

  const maxAgeMs =
    24 *
    60 *
    60 *
    1000;

  if (
    ageMs > maxAgeMs
  ) {
    return {
      valid:
        false,

      timestampMs,
    };
  }

  return {
    valid:
      true,

    timestampMs,
  };
}


// ============================================================
// 🔐 VERIFY ADMOB CALLBACK
// ============================================================

async function verifyAdMobCallback(
  req,
) {
  // ==========================================================
  // 🔐 SIGNATURE
  // ==========================================================

  const verification =
    await verifyAdMobSignature(
      req,
    );

  const params =
    verification.params;

  // ==========================================================
  // 📥 READ VERIFIED PARAMETERS
  // ==========================================================

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

  // ==========================================================
  // 🧩 CUSTOM DATA
  // ==========================================================
  //
  // URLSearchParams purkaa custom_data:n tässä vaiheessa.
  //
  // Tämä on oikein, koska allekirjoitus on jo tarkistettu.
  //
  // Google kertoo myös, että custom_data voi olla
  // percent-escaped.
  //
  // ==========================================================

  const parsedCustomData =
    parseCustomData(
      customData,
    );

  const uid =
    parsedCustomData.uid;

  const rewardPurpose =
    parsedCustomData.rewardPurpose;

  // ==========================================================
  // 🎯 REWARD PURPOSE
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
  // 👤 UID
  // ==========================================================

  if (
    !validateUid(
      uid,
    )
  ) {
    throw new Error(
      "AdMob SSV custom_data does not contain a valid UID.",
    );
  }

  // ==========================================================
  // 📺 AD UNIT
  // ==========================================================

  const expectedAdUnit =
    ADMOB_AD_UNITS[
      rewardPurpose
    ];

  if (
    !expectedAdUnit
  ) {
    throw new Error(
      `No AdMob ad unit configured for ${rewardPurpose}.`,
    );
  }

  if (
    adUnit !==
    expectedAdUnit
  ) {
    throw new Error(
      `Invalid AdMob ad unit. Expected ${expectedAdUnit}, received ${adUnit}.`,
    );
  }

  // ==========================================================
  // 🎁 REWARD DEFINITION
  // ==========================================================

  const rewardDefinition =
    REWARD_DEFINITIONS[
      rewardPurpose
    ];

  if (
    !rewardDefinition
  ) {
    throw new Error(
      `No reward definition configured for ${rewardPurpose}.`,
    );
  }

  // ==========================================================
  // 🎁 REWARD AMOUNT
  // ==========================================================

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

  // ==========================================================
  // 🎁 REWARD ITEM
  // ==========================================================

  if (
    rewardItem !==
    rewardDefinition.rewardItem
  ) {
    throw new Error(
      `Invalid AdMob reward item. Expected "${rewardDefinition.rewardItem}", received "${rewardItem}".`,
    );
  }

  // ==========================================================
  // 🔐 TRANSACTION ID
  // ==========================================================

  if (
    !validateTransactionId(
      transactionId,
    )
  ) {
    throw new Error(
      "AdMob transaction_id is missing or invalid.",
    );
  }

  // ==========================================================
  // ⏱️ TIMESTAMP
  // ==========================================================

  const timestampResult =
    validateTimestamp(
      timestamp,
    );

  if (
    !timestampResult.valid
  ) {
    throw new Error(
      "AdMob timestamp is invalid or older than 24 hours.",
    );
  }

  // ==========================================================
  // 👤 USER ID
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
  // 📦 NORMALIZED PARAMETERS
  // ==========================================================

  const parameters = {
    ad_network:
      adNetwork,

    ad_unit:
      adUnit,

    custom_data:
      customData,

    reward_amount:
      rewardAmount,

    reward_item:
      rewardItem,

    timestamp:
      timestamp,

    transaction_id:
      transactionId,

    user_id:
      userId,

    signature:
      getParam(
        params,
        "signature",
      ),

    key_id:
      getParam(
        params,
        "key_id",
      ),
  };

  // ==========================================================
  // 🐱 VERIFIED LOG
  // ==========================================================

  console.log(
    "🐱✅ AdMob SSV callback fully verified.",
    {
      uid,

      rewardPurpose,

      transactionId,

      keyId:
        verification.keyId,
    },
  );

  // ==========================================================
  // 📤 RETURN
  // ==========================================================

  return {
    verified:
      true,

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
      timestampResult.timestampMs,

    transactionId,

    userId,

    customData,

    keyId:
      verification.keyId,

    rawQueryString:
      verification.rawQueryString,

    signedQueryString:
      verification.signedQueryString,

    parameters,
  };
}


// ============================================================
// 📦 EXPORTS
// ============================================================

module.exports = {
  ADMOB_AD_UNITS,

  REWARD_DEFINITIONS,

  getAdMobPublicKeys,

  verifyAdMobSignature,

  verifyAdMobCallback,

  parseCustomData,
};