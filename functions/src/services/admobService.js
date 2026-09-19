"use strict";

const crypto = require("crypto");

// ============================================================
// 🐱 STELLURIINI - ADMOB SERVICE
// ============================================================
//
// Vastuu:
//
// 🔐 AdMob Rewarded SSV -allekirjoituksen tarkistaminen
// 🔑 AdMob public key -avainten lataaminen ja cache
// 🧩 SSV-parametrien lukeminen
// 🛡️ Rewardin validointi
// 👤 UID:n validointi
// 🎯 Reward purposen validointi
//
// TÄMÄ TIEDOSTO EI:
//
// ❌ lisää STL-saldoa
// ❌ aktivoi Power Boostia
// ❌ käynnistä Mining Startia
// ❌ muuta adsToday-arvoa
// ❌ muuta cooldownia
// ❌ muuta mining-tilaa
// ❌ kirjoita Firestoreen
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
// Public keys cacheataan enintään 23 tunniksi.
//
// ============================================================

const PUBLIC_KEY_CACHE_MS =
  23 * 60 * 60 * 1000;

let cachedPublicKeys = null;
let cachedPublicKeysAt = 0;


// ============================================================
// 📺 ADMOB AD UNITS
// ============================================================
//
// AdMob SSV callbackissa ad_unit tulee ilman:
//
// ca-app-pub-xxxxxxxxxxxxxxxx/
//
// Esimerkiksi:
//
// Flutter:
// ca-app-pub-1131012057145658/7225738491
//
// SSV:
// 7225738491
//
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
// Nämä ovat AdMob Rewarded Ad -metadata-arvoja.
//
// NE EIVÄT OLE STL-TOKENIPALKINTOJA.
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
    await fetch(
      url,
    );

  if (
    !response.ok
  ) {
    const error =
      new Error(
        `AdMob public key server returned HTTP ${response.status}.`,
      );

    error.code =
      "ADMOB_PUBLIC_KEY_FETCH_FAILED";

    throw error;
  }

  try {
    return await response.json();
  } catch (
    parseError
  ) {
    const error =
      new Error(
        "AdMob public key server returned invalid JSON.",
      );

    error.code =
      "ADMOB_PUBLIC_KEY_RESPONSE_INVALID";

    error.cause =
      parseError;

    throw error;
  }
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
  // FETCH
  // ----------------------------------------------------------

  const data =
    await fetchJson(
      ADMOB_SSV_KEYS_URL,
    );


  // ----------------------------------------------------------
  // RESPONSE VALIDATION
  // ----------------------------------------------------------

  if (
    !data ||
    !Array.isArray(
      data.keys,
    )
  ) {
    const error =
      new Error(
        "AdMob public key response is invalid.",
      );

    error.code =
      "ADMOB_PUBLIC_KEY_RESPONSE_INVALID";

    throw error;
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
      typeof key.pem !==
        "string"
    ) {
      continue;
    }

    const pem =
      key.pem.trim();

    if (
      pem.length === 0
    ) {
      continue;
    }

    const keyId =
      String(
        key.keyId,
      ).trim();

    if (
      !/^\d+$/.test(
        keyId,
      )
    ) {
      continue;
    }

    keys.set(
      keyId,
      pem,
    );
  }


  // ----------------------------------------------------------
  // NO USABLE KEYS
  // ----------------------------------------------------------

  if (
    keys.size === 0
  ) {
    const error =
      new Error(
        "No usable AdMob public keys were returned.",
      );

    error.code =
      "ADMOB_PUBLIC_KEY_RESPONSE_INVALID";

    throw error;
  }


  // ----------------------------------------------------------
  // CACHE
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
// 🔎 EXTRACT QUERY STRING FROM URL
// ============================================================

function extractQueryStringFromUrl(
  value,
) {
  if (
    typeof value !==
      "string" ||
    value.length ===
      0
  ) {
    return "";
  }


  const questionMark =
    value.indexOf(
      "?",
    );


  if (
    questionMark < 0
  ) {
    return "";
  }


  return value.substring(
    questionMark + 1,
  );
}


// ============================================================
// 🔎 GET RAW QUERY STRING
// ============================================================
//
// TÄRKEÄÄ:
//
// Allekirjoitettava query string täytyy säilyttää
// alkuperäisessä muodossaan.
//
// Emme:
//
// ❌ järjestä parametreja
// ❌ rakenna query stringiä uudelleen
// ❌ käytä URLSearchParamsia allekirjoitettavan datan
//    muodostamiseen
//
// URLSearchParamsia käytetään vasta signature-validoinnin
// yhteydessä parametrien lukemiseen.
//
// ============================================================

function getRawQueryString(
  req,
) {
  if (
    !req
  ) {
    const error =
      new Error(
        "Missing HTTP request.",
      );

    error.code =
      "ADMOB_REQUEST_MISSING";

    throw error;
  }


  const candidates = [
    req.rawUrl,
    req.originalUrl,
    req.url,
  ];


  for (
    const value of candidates
  ) {
    const query =
      extractQueryStringFromUrl(
        value,
      );

    if (
      query.length > 0
    ) {
      return query;
    }
  }


  // ----------------------------------------------------------
  // PARSED URL FALLBACK
  // ----------------------------------------------------------

  if (
    req._parsedUrl &&
    typeof req
      ._parsedUrl
      .search ===
      "string"
  ) {
    const search =
      req
        ._parsedUrl
        .search;

    if (
      search.startsWith(
        "?",
      ) &&
      search.length > 1
    ) {
      return search.substring(
        1,
      );
    }
  }


  const error =
    new Error(
      "AdMob SSV query string is missing.",
    );

  error.code =
    "ADMOB_QUERY_STRING_MISSING";

  throw error;
}


// ============================================================
// 🔐 DECODE ADMOB BASE64URL SIGNATURE
// ============================================================

function decodeAdMobSignature(
  signature,
) {
  if (
    typeof signature !==
      "string" ||
    signature.length ===
      0
  ) {
    const error =
      new Error(
        "AdMob SSV signature is missing.",
      );

    error.code =
      "ADMOB_INVALID_SIGNATURE";

    throw error;
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


  // ----------------------------------------------------------
  // INVALID BASE64URL LENGTH
  // ----------------------------------------------------------

  if (
    normalized.length % 4 ===
      1
  ) {
    const error =
      new Error(
        "AdMob SSV signature has invalid Base64URL length.",
      );

    error.code =
      "ADMOB_INVALID_SIGNATURE";

    throw error;
  }


  // ----------------------------------------------------------
  // PADDING
  // ----------------------------------------------------------

  const remainder =
    normalized.length % 4;

  const padded =
    remainder === 0
      ? normalized
      : normalized +
        "=".repeat(
          4 - remainder,
        );


  // ----------------------------------------------------------
  // CHARACTER VALIDATION
  // ----------------------------------------------------------

  if (
    !/^[A-Za-z0-9+/]*={0,2}$/.test(
      padded,
    )
  ) {
    const error =
      new Error(
        "AdMob SSV signature contains invalid Base64URL characters.",
      );

    error.code =
      "ADMOB_INVALID_SIGNATURE";

    throw error;
  }


  // ----------------------------------------------------------
  // DECODE
  // ----------------------------------------------------------

  const signatureBuffer =
    Buffer.from(
      padded,
      "base64",
    );


  if (
    signatureBuffer.length ===
      0
  ) {
    const error =
      new Error(
        "AdMob SSV signature could not be decoded.",
      );

    error.code =
      "ADMOB_INVALID_SIGNATURE";

    throw error;
  }


  return signatureBuffer;
}


// ============================================================
// 🔎 EXTRACT SIGNATURE DATA
// ============================================================
//
// AdMob SSV:
//
// ...&signature=...&key_id=...
//
// signature ja key_id ovat callbackin viimeiset
// query-parametrit.
//
// Allekirjoitettava data on kaikki ennen
// "&signature="-osaa.
//
// ============================================================

function extractSignatureData(
  rawQueryString,
) {
  if (
    typeof rawQueryString !==
      "string" ||
    rawQueryString.length ===
      0
  ) {
    const error =
      new Error(
        "AdMob SSV raw query string is missing.",
      );

    error.code =
      "ADMOB_QUERY_STRING_MISSING";

    throw error;
  }


  const signatureMarker =
    "&signature=";


  const signatureIndex =
    rawQueryString.indexOf(
      signatureMarker,
    );


  if (
    signatureIndex < 0
  ) {
    const error =
      new Error(
        "AdMob SSV signature parameter was not found.",
      );

    error.code =
      "ADMOB_INVALID_SIGNATURE";

    throw error;
  }


  const signedQueryString =
    rawQueryString.substring(
      0,
      signatureIndex,
    );


  if (
    signedQueryString.length ===
      0
  ) {
    const error =
      new Error(
        "AdMob SSV signed query string is empty.",
      );

    error.code =
      "ADMOB_INVALID_SIGNATURE";

    throw error;
  }


  const signatureAndKeyId =
    rawQueryString.substring(
      signatureIndex + 1,
    );


  const parts =
    signatureAndKeyId.split(
      "&",
    );


  if (
    parts.length !== 2
  ) {
    const error =
      new Error(
        "AdMob SSV signature and key_id must be the final two query parameters.",
      );

    error.code =
      "ADMOB_INVALID_SIGNATURE";

    throw error;
  }


  if (
    !parts[0].startsWith(
      "signature=",
    )
  ) {
    const error =
      new Error(
        "AdMob SSV signature is not in the expected position.",
      );

    error.code =
      "ADMOB_INVALID_SIGNATURE";

    throw error;
  }


  if (
    !parts[1].startsWith(
      "key_id=",
    )
  ) {
    const error =
      new Error(
        "AdMob SSV key_id is not in the expected position.",
      );

    error.code =
      "ADMOB_INVALID_KEY_ID";

    throw error;
  }


  let signature;
  let keyId;


  try {
    signature =
      decodeURIComponent(
        parts[0].substring(
          "signature=".length,
        ),
      );

    keyId =
      decodeURIComponent(
        parts[1].substring(
          "key_id=".length,
        ),
      );
  } catch (
    error
  ) {
    const decodingError =
      new Error(
        `AdMob SSV signature/key_id URL decoding failed: ${error.message}`,
      );

    decodingError.code =
      "ADMOB_INVALID_SIGNATURE";

    throw decodingError;
  }


  if (
    signature.length ===
      0
  ) {
    const error =
      new Error(
        "AdMob SSV signature value is missing.",
      );

    error.code =
      "ADMOB_INVALID_SIGNATURE";

    throw error;
  }


  if (
    keyId.length ===
      0
  ) {
    const error =
      new Error(
        "AdMob SSV key_id value is missing.",
      );

    error.code =
      "ADMOB_INVALID_KEY_ID";

    throw error;
  }


  if (
    !/^\d+$/.test(
      keyId,
    )
  ) {
    const error =
      new Error(
        "AdMob SSV key_id is invalid.",
      );

    error.code =
      "ADMOB_INVALID_KEY_ID";

    throw error;
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
  const {
    signedQueryString,
    signature,
    keyId,
  } =
    extractSignatureData(
      rawQueryString,
    );


  const signatureBuffer =
    decodeAdMobSignature(
      signature,
    );


  // ----------------------------------------------------------
  // LOAD CACHED KEYS
  // ----------------------------------------------------------

  let publicKeys =
    await getAdMobPublicKeys(
      false,
    );


  let publicKey =
    publicKeys.get(
      String(
        keyId,
      ),
    );


  // ----------------------------------------------------------
  // KEY ROTATION FALLBACK
  // ----------------------------------------------------------

  if (
    !publicKey
  ) {
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
        String(
          keyId,
        ),
      );
  }


  // ----------------------------------------------------------
  // KEY NOT FOUND
  // ----------------------------------------------------------

  if (
    !publicKey
  ) {
    const error =
      new Error(
        `AdMob SSV public key not found for key_id=${keyId}`,
      );

    error.code =
      "ADMOB_PUBLIC_KEY_NOT_FOUND";

    error.keyId =
      keyId;

    throw error;
  }


  // ----------------------------------------------------------
  // ECDSA / SHA-256
  // ----------------------------------------------------------

  let verified =
    false;


  try {
    verified =
      crypto.verify(
        "sha256",

        Buffer.from(
          signedQueryString,
          "utf8",
        ),

        {
          key:
            publicKey,
        },

        signatureBuffer,
      );
  } catch (
    error
  ) {
    const verificationError =
      new Error(
        `AdMob SSV cryptographic verification failed: ${error.message}`,
      );

    verificationError.code =
      "ADMOB_CRYPTO_VERIFICATION_ERROR";

    verificationError.keyId =
      keyId;

    throw verificationError;
  }


  // ----------------------------------------------------------
  // INVALID SIGNATURE
  // ----------------------------------------------------------

  if (
    !verified
  ) {
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


  console.log(
    "🐱✅ AdMob ECDSA-SHA256 signature VERIFIED.",
    {
      keyId,
    },
  );


  return {
    verified:
      true,

    keyId,

    signature,

    rawQueryString,

    signedQueryString,

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


  console.log(
    "🐱 AdMob SSV raw callback received.",
    {
      length:
        rawQueryString.length,

      hasSignature:
        rawQueryString.includes(
          "&signature=",
        ),

      hasKeyId:
        rawQueryString.includes(
          "&key_id=",
        ),
    },
  );


  try {
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
  } catch (
    error
  ) {
    console.error(
      "🐱❌ AdMob SSV signature verification FAILED.",
      {
        code:
          error &&
          error.code
            ? error.code
            : "UNKNOWN",

        keyId:
          error &&
          error.keyId
            ? error.keyId
            : "",

        message:
          error &&
          error.message
            ? error.message
            : "Unknown AdMob SSV error.",
      },
    );


    throw error;
  }
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


  return String(
    value,
  );
}


// ============================================================
// 🔎 REQUIRED PARAMETER HELPER
// ============================================================

function requireParam(
  params,
  name,
) {
  const value =
    getParam(
      params,
      name,
    );


  if (
    value.length ===
      0
  ) {
    const error =
      new Error(
        `AdMob SSV required parameter "${name}" is missing.`,
      );

    error.code =
      `ADMOB_MISSING_${name
        .toUpperCase()
        .replace(
          /[^A-Z0-9]+/g,
          "_",
        )}`;

    throw error;
  }


  return value;
}


// ============================================================
// 🔢 INTEGER HELPER
// ============================================================

function parseInteger(
  value,
  fallback = 0,
) {
  const number =
    Number(
      value,
    );


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
    typeof uid !==
      "string"
  ) {
    return false;
  }


  const trimmed =
    uid.trim();


  if (
    trimmed.length ===
      0 ||
    trimmed.length >
      128
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
// Muoto:
//
// UID:rewardPurpose
//
// Esimerkiksi:
//
// abc123:mining_start
// abc123:power_boost
//
// ============================================================

function parseCustomData(
  customData,
) {
  if (
    typeof customData !==
      "string"
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
    value.length ===
      0 ||
    value.length >
      128
  ) {
    return {
      uid:
        "",

      rewardPurpose:
        "",
    };
  }


  const separatorIndex =
    value.lastIndexOf(
      ":",
    );


  if (
    separatorIndex <=
      0 ||
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


  if (
    !validateUid(
      uid,
    )
  ) {
    return {
      uid:
        "",

      rewardPurpose:
        "",
    };
  }


  if (
    rewardPurpose !==
      "mining_start" &&
    rewardPurpose !==
      "power_boost"
  ) {
    return {
      uid:
        "",

      rewardPurpose:
        "",
    };
  }


  return {
    uid,

    rewardPurpose,
  };
}


// ============================================================
// 🔐 TRANSACTION ID VALIDATION
// ============================================================
//
// AdMob transaction_id on yksilöllinen reward-tapahtuman
// tunniste.
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
    value.length ===
      0 ||
    value.length >
      256
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

function validateTimestamp(
  timestamp,
) {
  const timestampMs =
    Number(
      timestamp,
    );


  if (
    !Number.isFinite(
      timestampMs,
    ) ||
    timestampMs <=
      0 ||
    !Number.isInteger(
      timestampMs,
    )
  ) {
    return {
      valid:
        false,

      timestampMs:
        0,
    };
  }


  return {
    valid:
      true,

    timestampMs,
  };
}


// ============================================================
// 🌐 AD NETWORK VALIDATION
// ============================================================

function validateAdNetwork(
  adNetwork,
) {
  if (
    typeof adNetwork !==
      "string"
  ) {
    return false;
  }


  return (
    adNetwork.trim()
      .toLowerCase() ===
    "admob"
  );
}


// ============================================================
// ❌ VALIDATION ERROR HELPER
// ============================================================

function createValidationError(
  message,
  code,
) {
  const error =
    new Error(
      message,
    );

  error.code =
    code;

  return error;
}


// ============================================================
// 🔐 VERIFY ADMOB CALLBACK
// ============================================================

async function verifyAdMobCallback(
  req,
) {
  // ----------------------------------------------------------
  // 1. CRYPTOGRAPHIC VERIFICATION
  // ----------------------------------------------------------

  const verification =
    await verifyAdMobSignature(
      req,
    );


  const params =
    verification.params;


  // ----------------------------------------------------------
  // 2. REQUIRED PARAMETERS
  // ----------------------------------------------------------

  const adNetwork =
    requireParam(
      params,
      "ad_network",
    );


  const adUnit =
    requireParam(
      params,
      "ad_unit",
    );


  const customData =
    requireParam(
      params,
      "custom_data",
    );


  const rewardAmount =
    requireParam(
      params,
      "reward_amount",
    );


  const rewardItem =
    requireParam(
      params,
      "reward_item",
    );


  const timestamp =
    requireParam(
      params,
      "timestamp",
    );


  const transactionId =
    requireParam(
      params,
      "transaction_id",
    );


  const userId =
    getParam(
      params,
      "user_id",
    );


  // ----------------------------------------------------------
  // 3. AD NETWORK
  // ----------------------------------------------------------

  if (
    !validateAdNetwork(
      adNetwork,
    )
  ) {
    throw createValidationError(
      "AdMob SSV ad_network is invalid.",
      "ADMOB_INVALID_AD_NETWORK",
    );
  }


  // ----------------------------------------------------------
  // 4. CUSTOM DATA
  // ----------------------------------------------------------

  const parsedCustomData =
    parseCustomData(
      customData,
    );


  const uid =
    parsedCustomData.uid;


  const rewardPurpose =
    parsedCustomData.rewardPurpose;


  // ----------------------------------------------------------
  // 5. REWARD PURPOSE
  // ----------------------------------------------------------

  if (
    rewardPurpose !==
      "mining_start" &&
    rewardPurpose !==
      "power_boost"
  ) {
    throw createValidationError(
      `Invalid AdMob reward purpose: ${rewardPurpose}`,
      "ADMOB_INVALID_REWARD_PURPOSE",
    );
  }


  // ----------------------------------------------------------
  // 6. UID
  // ----------------------------------------------------------

  if (
    !validateUid(
      uid,
    )
  ) {
    throw createValidationError(
      "AdMob SSV custom_data does not contain a valid UID.",
      "ADMOB_INVALID_UID",
    );
  }


  // ----------------------------------------------------------
  // 7. AD UNIT
  // ----------------------------------------------------------

  const expectedAdUnit =
    ADMOB_AD_UNITS[
      rewardPurpose
    ];


  if (
    !expectedAdUnit
  ) {
    throw createValidationError(
      `No AdMob ad unit configured for ${rewardPurpose}.`,
      "ADMOB_INVALID_AD_UNIT",
    );
  }


  if (
    adUnit !==
    expectedAdUnit
  ) {
    throw createValidationError(
      `Invalid AdMob ad unit. Expected ${expectedAdUnit}, received ${adUnit}.`,
      "ADMOB_INVALID_AD_UNIT",
    );
  }


  // ----------------------------------------------------------
  // 8. REWARD DEFINITION
  // ----------------------------------------------------------

  const rewardDefinition =
    REWARD_DEFINITIONS[
      rewardPurpose
    ];


  if (
    !rewardDefinition
  ) {
    throw createValidationError(
      `No reward definition configured for ${rewardPurpose}.`,
      "ADMOB_INVALID_REWARD_PURPOSE",
    );
  }


  // ----------------------------------------------------------
  // 9. REWARD AMOUNT
  // ----------------------------------------------------------

  const parsedRewardAmount =
    parseInteger(
      rewardAmount,
      -1,
    );


  if (
    parsedRewardAmount !==
    rewardDefinition.rewardAmount
  ) {
    throw createValidationError(
      `Invalid AdMob reward amount. Expected ${rewardDefinition.rewardAmount}, received ${rewardAmount}.`,
      "ADMOB_INVALID_REWARD_AMOUNT",
    );
  }


  // ----------------------------------------------------------
  // 10. REWARD ITEM
  // ----------------------------------------------------------

  if (
    rewardItem !==
    rewardDefinition.rewardItem
  ) {
    throw createValidationError(
      `Invalid AdMob reward item. Expected "${rewardDefinition.rewardItem}", received "${rewardItem}".`,
      "ADMOB_INVALID_REWARD_ITEM",
    );
  }


  // ----------------------------------------------------------
  // 11. TRANSACTION ID
  // ----------------------------------------------------------

  if (
    !validateTransactionId(
      transactionId,
    )
  ) {
    throw createValidationError(
      "AdMob SSV transaction_id is missing or invalid.",
      "ADMOB_INVALID_TRANSACTION_ID",
    );
  }


  // ----------------------------------------------------------
  // 12. TIMESTAMP
  // ----------------------------------------------------------

  const timestampResult =
    validateTimestamp(
      timestamp,
    );


  if (
    !timestampResult.valid
  ) {
    throw createValidationError(
      "AdMob timestamp is invalid.",
      "ADMOB_INVALID_TIMESTAMP",
    );
  }


  // ----------------------------------------------------------
  // 13. USER ID
  // ----------------------------------------------------------

  if (
    userId &&
    userId !==
      uid
  ) {
    throw createValidationError(
      "AdMob SSV user_id does not match custom_data UID.",
      "ADMOB_INVALID_UID",
    );
  }


  // ----------------------------------------------------------
  // 14. VERIFIED SIGNATURE
  // ----------------------------------------------------------

  const signature =
    verification.signature;


  const keyId =
    verification.keyId;


  if (
    typeof signature !==
      "string" ||
    signature.length ===
      0
  ) {
    throw createValidationError(
      "AdMob verified signature value is missing.",
      "ADMOB_INVALID_SIGNATURE",
    );
  }


  if (
    typeof keyId !==
      "string" ||
    keyId.length ===
      0
  ) {
    throw createValidationError(
      "AdMob verified key_id value is missing.",
      "ADMOB_INVALID_KEY_ID",
    );
  }


  // ----------------------------------------------------------
  // 15. NORMALIZED PARAMETERS
  // ----------------------------------------------------------

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

    signature,

    key_id:
      keyId,
  };


  // ----------------------------------------------------------
  // 16. VERIFIED LOG
  // ----------------------------------------------------------

  console.log(
    "🐱✅ AdMob SSV callback fully verified.",
    {
      uid,

      rewardPurpose,

      transactionId,

      keyId,

      adUnit,

      rewardAmount,

      rewardItem,

      timestamp:
        timestampResult.timestampMs,
    },
  );


  // ----------------------------------------------------------
  // 17. RETURN
  // ----------------------------------------------------------

  return {
    verified:
      true,

    uid,

    rewardPurpose,

    adUnit,

    adNetwork,

    rewardAmount:
      parsedRewardAmount,

    rewardItem,

    timestamp:
      timestampResult.timestampMs,

    transactionId,

    userId,

    customData,

    keyId,

    signature,

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