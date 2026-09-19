"use strict";

const crypto = require("crypto");

/**
 * ============================================================
 * 🐱 STELLURIINI - ADMOB SERVICE
 * ============================================================
 *
 * Vastaa:
 *
 * 🔐 AdMob Rewarded SSV -allekirjoituksen tarkistamisesta
 * 🔑 AdMob public key -avainten lataamisesta ja välimuistista
 * 🧩 SSV-parametrien lukemisesta
 * 🛡️ Rewardin validoinnista
 * 👤 UID:n validoinnista
 *
 * TÄMÄ TIEDOSTO EI:
 *
 * ❌ lisää STL-saldoa
 * ❌ aktivoi Power Boostia
 * ❌ käynnistä Mining Startia
 * ❌ muuta adsToday-arvoa
 * ❌ muuta cooldownia
 * ❌ muuta mining-tilaa
 * ❌ kirjoita Firestoreen
 *
 * ============================================================
 */

const ADMOB_SSV_KEYS_URL =
  "https://www.gstatic.com/admob/reward/verifier-keys.json";

const PUBLIC_KEY_CACHE_MS =
  23 * 60 * 60 * 1000;

let cachedPublicKeys = null;
let cachedPublicKeysAt = 0;


/**
 * ============================================================
 * 📺 STELLURIINI ADMOB AD UNITS
 * ============================================================
 */

const ADMOB_AD_UNITS = {
  mining_start: "6674097787",
  power_boost: "7225738491",
};


/**
 * ============================================================
 * 🎁 EXPECTED REWARDS
 * ============================================================
 */

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


/**
 * ============================================================
 * 🌐 FETCH JSON
 * ============================================================
 */

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
      "ADMOB_KEY_SERVER_HTTP_ERROR";

    throw error;
  }

  return response.json();
}


/**
 * ============================================================
 * 🔑 LOAD ADMOB PUBLIC KEYS
 * ============================================================
 */

async function getAdMobPublicKeys(
  forceRefresh = false,
) {
  const now =
    Date.now();


  /**
   * ----------------------------------------------------------
   * CACHE
   * ----------------------------------------------------------
   */

  if (
    !forceRefresh &&
    cachedPublicKeys &&
    now - cachedPublicKeysAt <
      PUBLIC_KEY_CACHE_MS
  ) {
    return cachedPublicKeys;
  }


  /**
   * ----------------------------------------------------------
   * FETCH
   * ----------------------------------------------------------
   */

  const data =
    await fetchJson(
      ADMOB_SSV_KEYS_URL,
    );


  /**
   * ----------------------------------------------------------
   * VALIDATE RESPONSE
   * ----------------------------------------------------------
   */

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
      "ADMOB_INVALID_KEY_RESPONSE";

    throw error;
  }


  /**
   * ----------------------------------------------------------
   * BUILD KEY MAP
   * ----------------------------------------------------------
   */

  const keys =
    new Map();

  for (
    const key of data.keys
  ) {
    if (
      key &&
      key.keyId !== undefined &&
      typeof key.pem ===
        "string" &&
      key.pem.length > 0
    ) {
      keys.set(
        String(
          key.keyId,
        ),
        key.pem,
      );
    }
  }


  if (
    keys.size === 0
  ) {
    const error =
      new Error(
        "No usable AdMob public keys were returned.",
      );

    error.code =
      "ADMOB_NO_PUBLIC_KEYS";

    throw error;
  }


  /**
   * ----------------------------------------------------------
   * SAVE CACHE
   * ----------------------------------------------------------
   */

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


/**
 * ============================================================
 * 🔎 EXTRACT QUERY STRING FROM URL
 * ============================================================
 */

function extractQueryStringFromUrl(
  value,
) {
  if (
    typeof value !==
      "string" ||
    value.length === 0
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


/**
 * ============================================================
 * 🔎 GET ORIGINAL QUERY STRING
 * ============================================================
 *
 * Tärkeää:
 *
 * Tässä vaiheessa emme vielä dekoodaa mitään.
 *
 * Tarvitsemme ensin AdMobilta vastaanotetun query-stringin.
 *
 * ============================================================
 */

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
      "ADMOB_MISSING_REQUEST";

    throw error;
  }


  const candidates = [
    req.originalUrl,
    req.url,
    req.rawUrl,
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


  /**
   * ----------------------------------------------------------
   * LAST FALLBACK
   * ----------------------------------------------------------
   */

  if (
    req._parsedUrl &&
    typeof req._parsedUrl.search ===
      "string"
  ) {
    const search =
      req._parsedUrl.search;

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


/**
 * ============================================================
 * 🔓 DECODE QUERY STRING FOR ADMOB VERIFICATION
 * ============================================================
 *
 * TÄMÄ ON TÄRKEÄ KORJAUS.
 *
 * AdMob lähettää esimerkiksi:
 *
 *   custom_data=UID%3Amining_start
 *
 * Googlen verifier käsittelee query-stringin dekoodattuna:
 *
 *   custom_data=UID:mining_start
 *
 * Google Tink RewardedAdsVerifier käyttää URI.getQuery():
 *
 *   https://...
 *   ?foo=hello%20world
 *
 * muuttuu varmennettavaksi dataksi:
 *
 *   foo=hello world
 *
 * Siksi emme käytä allekirjoitukseen raakaa:
 *
 *   %3A
 *
 * vaan dekoodattua:
 *
 *   :
 *
 * ============================================================
 */

function decodeQueryStringForVerification(
  rawQueryString,
) {
  if (
    typeof rawQueryString !==
      "string" ||
    rawQueryString.length === 0
  ) {
    const error =
      new Error(
        "AdMob SSV raw query string is empty.",
      );

    error.code =
      "ADMOB_EMPTY_RAW_QUERY";

    throw error;
  }


  try {
    return decodeURIComponent(
      rawQueryString,
    );
  } catch (
    error
  ) {
    const decodingError =
      new Error(
        `AdMob SSV query string URL decoding failed: ${error.message}`,
      );

    decodingError.code =
      "ADMOB_QUERY_DECODE_ERROR";

    throw decodingError;
  }
}


/**
 * ============================================================
 * 🔐 DECODE ADMOB SIGNATURE
 * ============================================================
 */

function decodeAdMobSignature(
  signature,
) {
  if (
    typeof signature !==
      "string" ||
    signature.length === 0
  ) {
    const error =
      new Error(
        "AdMob SSV signature is missing.",
      );

    error.code =
      "ADMOB_SIGNATURE_MISSING";

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


  if (
    normalized.length % 4 ===
      1
  ) {
    const error =
      new Error(
        "AdMob SSV signature has invalid Base64URL length.",
      );

    error.code =
      "ADMOB_SIGNATURE_INVALID_BASE64_LENGTH";

    throw error;
  }


  const remainder =
    normalized.length % 4;


  const padded =
    remainder === 0
      ? normalized
      : normalized +
        "=".repeat(
          4 - remainder,
        );


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
      "ADMOB_SIGNATURE_INVALID_BASE64";

    throw error;
  }


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
      "ADMOB_SIGNATURE_DECODE_ERROR";

    throw error;
  }


  return signatureBuffer;
}


/**
 * ============================================================
 * 🔎 EXTRACT SIGNATURE DATA
 * ============================================================
 */

function extractSignatureData(
  verificationQueryString,
) {
  if (
    typeof verificationQueryString !==
      "string" ||
    verificationQueryString.length ===
      0
  ) {
    const error =
      new Error(
        "AdMob SSV verification query string is missing.",
      );

    error.code =
      "ADMOB_VERIFICATION_QUERY_MISSING";

    throw error;
  }


  /**
   * ----------------------------------------------------------
   * FIND SIGNATURE
   * ----------------------------------------------------------
   */

  const signatureMarker =
    "&signature=";


  const signatureIndex =
    verificationQueryString.indexOf(
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
      "ADMOB_SIGNATURE_PARAMETER_MISSING";

    throw error;
  }


  /**
   * ----------------------------------------------------------
   * SIGNED CONTENT
   * ----------------------------------------------------------
   *
   * Tätä sisältöä ei enää muuteta.
   *
   * Tämä on Googlen allekirjoittama data.
   * ----------------------------------------------------------
   */

  const signedQueryString =
    verificationQueryString.substring(
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
      "ADMOB_SIGNED_QUERY_EMPTY";

    throw error;
  }


  /**
   * ----------------------------------------------------------
   * SIGNATURE + KEY ID
   * ----------------------------------------------------------
   */

  const signatureAndKeyId =
    verificationQueryString.substring(
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
      "ADMOB_SIGNATURE_POSITION_INVALID";

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
      "ADMOB_SIGNATURE_POSITION_INVALID";

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
      "ADMOB_KEY_ID_POSITION_INVALID";

    throw error;
  }


  let signature;
  let keyId;


  try {
    signature =
      parts[0].substring(
        "signature=".length,
      );

    keyId =
      parts[1].substring(
        "key_id=".length,
      );
  } catch (
    error
  ) {
    const parsingError =
      new Error(
        `AdMob SSV signature/key_id parsing failed: ${error.message}`,
      );

    parsingError.code =
      "ADMOB_SIGNATURE_KEY_ID_PARSE_ERROR";

    throw parsingError;
  }


  if (
    signature.length === 0
  ) {
    const error =
      new Error(
        "AdMob SSV signature value is missing.",
      );

    error.code =
      "ADMOB_SIGNATURE_VALUE_MISSING";

    throw error;
  }


  if (
    keyId.length === 0
  ) {
    const error =
      new Error(
        "AdMob SSV key_id value is missing.",
      );

    error.code =
      "ADMOB_KEY_ID_VALUE_MISSING";

    throw error;
  }


  /**
   * key_id on numeerinen tunniste.
   *
   * Käytämme String-muotoa, koska Googlella key_id
   * voi olla suurempi kuin 32-bit integer.
   */

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
      "ADMOB_KEY_ID_INVALID";

    throw error;
  }


  return {
    signedQueryString,

    signature,

    keyId,
  };
}


/**
 * ============================================================
 * 🔐 VERIFY ONE QUERY STRING
 * ============================================================
 */

async function verifyRawQueryString(
  rawQueryString,
) {
  /**
   * ----------------------------------------------------------
   * GOOGLE-COMPATIBLE QUERY STRING
   * ----------------------------------------------------------
   *
   * Tämä on tärkeä ero:
   *
   * raw:
   *
   *   custom_data=UID%3Amining_start
   *
   * verification:
   *
   *   custom_data=UID:mining_start
   *
   * Googlen oma verifier toimii jälkimmäisen kanssa.
   */

  const verificationQueryString =
    decodeQueryStringForVerification(
      rawQueryString,
    );


  const {
    signedQueryString,
    signature,
    keyId,
  } =
    extractSignatureData(
      verificationQueryString,
    );


  /**
   * ----------------------------------------------------------
   * DECODE SIGNATURE
   * ----------------------------------------------------------
   */

  const signatureBuffer =
    decodeAdMobSignature(
      signature,
    );


  /**
   * ----------------------------------------------------------
   * GET PUBLIC KEYS
   * ----------------------------------------------------------
   */

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


  /**
   * ----------------------------------------------------------
   * REFRESH IF KEY IS UNKNOWN
   * ----------------------------------------------------------
   */

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


  /**
   * ==========================================================
   * 🔐 ECDSA SHA-256 / DER
   * ==========================================================
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


  let verified =
    false;


  try {
    verified =
      verifier.verify(
        {
          key:
            publicKey,

          dsaEncoding:
            "der",
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


  /**
   * ----------------------------------------------------------
   * PARAMS
   * ----------------------------------------------------------
   *
   * Parsitaan vasta kryptografisen tarkistuksen jälkeen.
   */

  return {
    verified: true,

    keyId,

    rawQueryString,

    signedQueryString,

    signature,

    params:
      new URLSearchParams(
        verificationQueryString,
      ),
  };
}


/**
 * ============================================================
 * 🔐 VERIFY ADMOB SIGNATURE
 * ============================================================
 */

async function verifyAdMobSignature(
  req,
) {
  const rawQueryString =
    getRawQueryString(
      req,
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
            : "Unknown error.",
      },
    );


    throw error;
  }
}


/**
 * ============================================================
 * 🔎 PARAMETER HELPER
 * ============================================================
 */

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


/**
 * ============================================================
 * 🔎 REQUIRED PARAMETER HELPER
 * ============================================================
 */

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
    value.length === 0
  ) {
    const error =
      new Error(
        `AdMob SSV required parameter "${name}" is missing.`,
      );

    error.code =
      "ADMOB_REQUIRED_PARAMETER_MISSING";

    error.parameter =
      name;

    throw error;
  }


  return value;
}


/**
 * ============================================================
 * 🔢 INTEGER HELPER
 * ============================================================
 */

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


/**
 * ============================================================
 * 🛡️ UID VALIDATION
 * ============================================================
 */

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
    trimmed.length === 0 ||
    trimmed.length > 128
  ) {
    return false;
  }


  return /^[A-Za-z0-9._-]+$/.test(
    trimmed,
  );
}


/**
 * ============================================================
 * 🧩 CUSTOM DATA PARSER
 * ============================================================
 *
 * Formaatti:
 *
 *   UID:mining_start
 *
 *   UID:power_boost
 *
 * ============================================================
 */

function parseCustomData(
  customData,
) {
  if (
    typeof customData !==
      "string"
  ) {
    return {
      uid: "",

      rewardPurpose: "",
    };
  }


  const value =
    customData.trim();


  if (
    value.length === 0 ||
    value.length > 128
  ) {
    return {
      uid: "",

      rewardPurpose: "",
    };
  }


  const separatorIndex =
    value.lastIndexOf(
      ":",
    );


  if (
    separatorIndex <= 0 ||
    separatorIndex >=
      value.length - 1
  ) {
    return {
      uid: "",

      rewardPurpose: "",
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
      uid: "",

      rewardPurpose: "",
    };
  }


  if (
    rewardPurpose !==
      "mining_start" &&
    rewardPurpose !==
      "power_boost"
  ) {
    return {
      uid: "",

      rewardPurpose: "",
    };
  }


  return {
    uid,

    rewardPurpose,
  };
}


/**
 * ============================================================
 * 🔐 TRANSACTION ID VALIDATION
 * ============================================================
 */

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


/**
 * ============================================================
 * ⏱️ TIMESTAMP VALIDATION
 * ============================================================
 */

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
    timestampMs <= 0 ||
    !Number.isInteger(
      timestampMs,
    )
  ) {
    return {
      valid: false,

      timestampMs: 0,
    };
  }


  return {
    valid: true,

    timestampMs,
  };
}


/**
 * ============================================================
 * 🔐 VERIFY ADMOB CALLBACK
 * ============================================================
 */

async function verifyAdMobCallback(
  req,
) {
  /**
   * ----------------------------------------------------------
   * 1. CRYPTOGRAPHIC VERIFICATION
   * ----------------------------------------------------------
   */

  const verification =
    await verifyAdMobSignature(
      req,
    );


  const params =
    verification.params;


  /**
   * ----------------------------------------------------------
   * 2. REQUIRED SSV PARAMETERS
   * ----------------------------------------------------------
   */

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


  /**
   * user_id on valinnainen.
   */

  const userId =
    getParam(
      params,
      "user_id",
    );


  /**
   * ----------------------------------------------------------
   * 3. CUSTOM DATA
   * ----------------------------------------------------------
   */

  const parsedCustomData =
    parseCustomData(
      customData,
    );


  const uid =
    parsedCustomData.uid;


  const rewardPurpose =
    parsedCustomData.rewardPurpose;


  /**
   * ----------------------------------------------------------
   * 4. REWARD PURPOSE
   * ----------------------------------------------------------
   */

  if (
    rewardPurpose !==
      "mining_start" &&
    rewardPurpose !==
      "power_boost"
  ) {
    const error =
      new Error(
        `Invalid AdMob reward purpose: ${rewardPurpose}`,
      );

    error.code =
      "ADMOB_INVALID_REWARD_PURPOSE";

    throw error;
  }


  /**
   * ----------------------------------------------------------
   * 5. UID
   * ----------------------------------------------------------
   */

  if (
    !validateUid(
      uid,
    )
  ) {
    const error =
      new Error(
        "AdMob SSV custom_data does not contain a valid UID.",
      );

    error.code =
      "ADMOB_INVALID_UID";

    throw error;
  }


  /**
   * ----------------------------------------------------------
   * 6. AD UNIT
   * ----------------------------------------------------------
   */

  const expectedAdUnit =
    ADMOB_AD_UNITS[
      rewardPurpose
    ];


  if (
    !expectedAdUnit
  ) {
    const error =
      new Error(
        `No AdMob ad unit configured for ${rewardPurpose}.`,
      );

    error.code =
      "ADMOB_AD_UNIT_NOT_CONFIGURED";

    throw error;
  }


  if (
    adUnit !==
    expectedAdUnit
  ) {
    const error =
      new Error(
        `Invalid AdMob ad unit. Expected ${expectedAdUnit}, received ${adUnit}.`,
      );

    error.code =
      "ADMOB_INVALID_AD_UNIT";

    throw error;
  }


  /**
   * ----------------------------------------------------------
   * 7. REWARD DEFINITION
   * ----------------------------------------------------------
   */

  const rewardDefinition =
    REWARD_DEFINITIONS[
      rewardPurpose
    ];


  if (
    !rewardDefinition
  ) {
    const error =
      new Error(
        `No reward definition configured for ${rewardPurpose}.`,
      );

    error.code =
      "ADMOB_REWARD_DEFINITION_MISSING";

    throw error;
  }


  /**
   * ----------------------------------------------------------
   * 8. REWARD AMOUNT
   * ----------------------------------------------------------
   */

  const parsedRewardAmount =
    parseInteger(
      rewardAmount,
      -1,
    );


  if (
    parsedRewardAmount !==
    rewardDefinition.rewardAmount
  ) {
    const error =
      new Error(
        `Invalid AdMob reward amount. Expected ${rewardDefinition.rewardAmount}, received ${rewardAmount}.`,
      );

    error.code =
      "ADMOB_INVALID_REWARD_AMOUNT";

    throw error;
  }


  /**
   * ----------------------------------------------------------
   * 9. REWARD ITEM
   * ----------------------------------------------------------
   */

  if (
    rewardItem !==
    rewardDefinition.rewardItem
  ) {
    const error =
      new Error(
        `Invalid AdMob reward item. Expected "${rewardDefinition.rewardItem}", received "${rewardItem}".`,
      );

    error.code =
      "ADMOB_INVALID_REWARD_ITEM";

    throw error;
  }


  /**
   * ----------------------------------------------------------
   * 10. TRANSACTION ID
   * ----------------------------------------------------------
   */

  if (
    !validateTransactionId(
      transactionId,
    )
  ) {
    const error =
      new Error(
        "AdMob SSV transaction_id is missing or invalid.",
      );

    error.code =
      "ADMOB_INVALID_TRANSACTION_ID";

    throw error;
  }


  /**
   * ----------------------------------------------------------
   * 11. TIMESTAMP
   * ----------------------------------------------------------
   */

  const timestampResult =
    validateTimestamp(
      timestamp,
    );


  if (
    !timestampResult.valid
  ) {
    const error =
      new Error(
        "AdMob timestamp is invalid.",
      );

    error.code =
      "ADMOB_INVALID_TIMESTAMP";

    throw error;
  }


  /**
   * ----------------------------------------------------------
   * 12. USER ID
   * ----------------------------------------------------------
   */

  if (
    userId &&
    userId !== uid
  ) {
    const error =
      new Error(
        "AdMob SSV user_id does not match custom_data UID.",
      );

    error.code =
      "ADMOB_USER_ID_MISMATCH";

    throw error;
  }


  /**
   * ----------------------------------------------------------
   * 13. SIGNATURE / KEY ID
   * ----------------------------------------------------------
   */

  const signature =
    getParam(
      params,
      "signature",
    );


  const keyId =
    getParam(
      params,
      "key_id",
    );


  if (
    signature.length === 0
  ) {
    const error =
      new Error(
        "AdMob SSV signature parameter is missing.",
      );

    error.code =
      "ADMOB_SIGNATURE_PARAMETER_MISSING";

    throw error;
  }


  if (
    keyId.length === 0
  ) {
    const error =
      new Error(
        "AdMob SSV key_id parameter is missing.",
      );

    error.code =
      "ADMOB_KEY_ID_PARAMETER_MISSING";

    throw error;
  }


  /**
   * ----------------------------------------------------------
   * 14. NORMALIZED PARAMETERS
   * ----------------------------------------------------------
   */

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


  /**
   * ----------------------------------------------------------
   * 15. VERIFIED LOG
   * ----------------------------------------------------------
   */

  console.log(
    "🐱✅ AdMob SSV callback fully verified.",
    {
      uid,

      rewardPurpose,

      transactionId,

      keyId:
        verification.keyId,

      adUnit,

      rewardAmount,

      rewardItem,

      timestamp:
        timestampResult.timestampMs,
    },
  );


  /**
   * ----------------------------------------------------------
   * 16. RETURN VERIFIED AD
   * ----------------------------------------------------------
   */

  return {
    verified: true,

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

    keyId:
      verification.keyId,

    rawQueryString:
      verification.rawQueryString,

    signedQueryString:
      verification.signedQueryString,

    parameters,
  };
}


/**
 * ============================================================
 * 📦 EXPORTS
 * ============================================================
 */

module.exports = {
  ADMOB_AD_UNITS,

  REWARD_DEFINITIONS,

  getAdMobPublicKeys,

  verifyAdMobSignature,

  verifyAdMobCallback,

  parseCustomData,
};