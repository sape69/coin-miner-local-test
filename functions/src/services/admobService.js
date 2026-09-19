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
 *
 * ADMOB SSV
 *
 * Google allekirjoittaa callback-URL:n query-stringin.
 *
 * Allekirjoitettavaa sisältöä EI saa muuttaa ennen
 * kryptografista tarkistusta.
 *
 * Googlen SSV-formaatissa:
 *
 *   signature
 *   key_id
 *
 * ovat callbackin kaksi viimeistä parametria.
 *
 * Allekirjoitettava query-string sisältää kaikki parametrit
 * ennen "&signature=" kohtaa.
 *
 * ============================================================
 */


/**
 * ============================================================
 * 🌐 ADMOB PUBLIC KEY URL
 * ============================================================
 */

const ADMOB_SSV_KEYS_URL =
  "https://www.gstatic.com/admob/reward/verifier-keys.json";


/**
 * ============================================================
 * ⏱️ PUBLIC KEY CACHE
 * ============================================================
 *
 * Google voi kierrättää AdMob SSV public key -avaimia.
 *
 * Cache pidetään alle 24 tuntia.
 *
 * ============================================================
 */

const PUBLIC_KEY_CACHE_MS =
  23 * 60 * 60 * 1000;

let cachedPublicKeys = null;

let cachedPublicKeysAt = 0;


/**
 * ============================================================
 * 📺 STELLURIINI ADMOB AD UNITS
 * ============================================================
 *
 * AdMob SSV callbackissa:
 *
 *   ad_unit
 *
 * on numeric AdMob ad unit ID.
 *
 * ============================================================
 */

const ADMOB_AD_UNITS = {
  mining_start:
    "6674097787",

  power_boost:
    "7225738491",
};


/**
 * ============================================================
 * 🎁 EXPECTED REWARDS
 * ============================================================
 *
 * Näiden arvojen tulee vastata AdMobin rewarded
 * ad unit -asetuksia.
 *
 * Näitä arvoja EI käytetä STL-saldon lisäämiseen.
 *
 * ============================================================
 */

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


/**
 * ============================================================
 * 🧾 CREATE ERROR
 * ============================================================
 *
 * Yhtenäinen virheiden luonti.
 *
 * ============================================================
 */

function createAdMobError(
  code,
  message,
  extra = {},
) {
  const error =
    new Error(
      message,
    );

  error.code =
    code;

  Object.assign(
    error,
    extra,
  );

  return error;
}


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
    throw createAdMobError(
      "ADMOB_PUBLIC_KEY_HTTP_ERROR",
      `AdMob public key server returned HTTP ${response.status}.`,
      {
        status:
          response.status,
      },
    );
  }

  try {
    return await response.json();
  } catch (
    error
  ) {
    throw createAdMobError(
      "ADMOB_PUBLIC_KEY_JSON_ERROR",
      `AdMob public key response could not be parsed as JSON: ${error.message}`,
    );
  }
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
    now -
      cachedPublicKeysAt <
      PUBLIC_KEY_CACHE_MS
  ) {
    console.log(
      "🐱 AdMob public key cache HIT.",
      {
        count:
          cachedPublicKeys.size,
      },
    );

    return cachedPublicKeys;
  }


  /**
   * ----------------------------------------------------------
   * FETCH
   * ----------------------------------------------------------
   */

  console.log(
    "🐱 AdMob public key cache MISS. Loading keys from Google.",
    {
      forceRefresh,
    },
  );


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
    throw createAdMobError(
      "ADMOB_PUBLIC_KEY_RESPONSE_INVALID",
      "AdMob public key response is invalid.",
    );
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
    throw createAdMobError(
      "ADMOB_PUBLIC_KEY_EMPTY",
      "No usable AdMob public keys were returned.",
    );
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
 * 🔎 EXTRACT RAW QUERY STRING FROM URL
 * ============================================================
 *
 * Tärkeää:
 *
 * Tätä merkkijonoa ei parsita eikä rakenneta uudelleen
 * ennen kryptografista tarkistusta.
 *
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
 * 🔎 GET RAW QUERY STRING
 * ============================================================
 */

function getRawQueryString(
  req,
) {
  if (
    !req
  ) {
    throw createAdMobError(
      "ADMOB_REQUEST_MISSING",
      "Missing HTTP request.",
    );
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
      console.log(
        "🐱 AdMob raw query string obtained.",
        {
          source:
            value ===
            req.originalUrl
              ? "originalUrl"
              : value ===
                req.url
                ? "url"
                : "rawUrl",

          length:
            query.length,
        },
      );

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
      const query =
        search.substring(
          1,
        );


      console.log(
        "🐱 AdMob raw query string obtained from _parsedUrl.search.",
        {
          length:
            query.length,
        },
      );


      return query;
    }
  }


  throw createAdMobError(
    "ADMOB_QUERY_STRING_MISSING",
    "AdMob SSV query string is missing.",
  );
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
    throw createAdMobError(
      "ADMOB_SIGNATURE_MISSING",
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


  /**
   * Base64URL-pituus ei saa olla 1 mod 4.
   */

  if (
    normalized.length % 4 ===
      1
  ) {
    throw createAdMobError(
      "ADMOB_SIGNATURE_BASE64_LENGTH",
      "AdMob SSV signature has invalid Base64URL length.",
    );
  }


  const remainder =
    normalized.length % 4;


  const padded =
    remainder === 0
      ? normalized
      : normalized +
        "=".repeat(
          4 -
            remainder,
        );


  /**
   * Tarkistetaan Base64-merkistö.
   */

  if (
    !/^[A-Za-z0-9+/]*={0,2}$/.test(
      padded,
    )
  ) {
    throw createAdMobError(
      "ADMOB_SIGNATURE_BASE64_INVALID",
      "AdMob SSV signature contains invalid Base64URL characters.",
    );
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
    throw createAdMobError(
      "ADMOB_SIGNATURE_DECODE_FAILED",
      "AdMob SSV signature could not be decoded.",
    );
  }


  return signatureBuffer;
}


/**
 * ============================================================
 * 🔎 EXTRACT SIGNATURE DATA
 * ============================================================
 *
 * Googlen SSV-formaatti:
 *
 *   ...&signature=...&key_id=...
 *
 * Allekirjoitettavaa sisältöä on kaikki ennen:
 *
 *   &signature=
 *
 * ============================================================
 */

function extractSignatureData(
  rawQueryString,
) {
  if (
    typeof rawQueryString !==
      "string" ||
    rawQueryString.length ===
      0
  ) {
    throw createAdMobError(
      "ADMOB_RAW_QUERY_MISSING",
      "AdMob SSV raw query string is missing.",
    );
  }


  /**
   * ----------------------------------------------------------
   * FIND SIGNATURE
   * ----------------------------------------------------------
   */

  const signatureMarker =
    "&signature=";


  const signatureIndex =
    rawQueryString.indexOf(
      signatureMarker,
    );


  if (
    signatureIndex < 0
  ) {
    throw createAdMobError(
      "ADMOB_SIGNATURE_PARAMETER_NOT_FOUND",
      "AdMob SSV signature parameter was not found.",
    );
  }


  /**
   * ----------------------------------------------------------
   * SIGNED CONTENT
   * ----------------------------------------------------------
   *
   * Tätä merkkijonoa ei muuteta.
   */

  const signedQueryString =
    rawQueryString.substring(
      0,
      signatureIndex,
    );


  if (
    signedQueryString.length ===
      0
  ) {
    throw createAdMobError(
      "ADMOB_SIGNED_QUERY_EMPTY",
      "AdMob SSV signed query string is empty.",
    );
  }


  /**
   * ----------------------------------------------------------
   * SIGNATURE + KEY ID
   * ----------------------------------------------------------
   */

  const signatureAndKeyId =
    rawQueryString.substring(
      signatureIndex + 1,
    );


  const parts =
    signatureAndKeyId.split(
      "&",
    );


  /**
   * AdMob lähettää signature + key_id viimeisinä.
   */

  if (
    parts.length !== 2
  ) {
    throw createAdMobError(
      "ADMOB_SIGNATURE_POSITION_INVALID",
      "AdMob SSV signature and key_id must be the final two query parameters.",
      {
        partsCount:
          parts.length,
      },
    );
  }


  if (
    !parts[0].startsWith(
      "signature=",
    )
  ) {
    throw createAdMobError(
      "ADMOB_SIGNATURE_POSITION_INVALID",
      "AdMob SSV signature is not in the expected position.",
    );
  }


  if (
    !parts[1].startsWith(
      "key_id=",
    )
  ) {
    throw createAdMobError(
      "ADMOB_KEY_ID_POSITION_INVALID",
      "AdMob SSV key_id is not in the expected position.",
    );
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
    throw createAdMobError(
      "ADMOB_SIGNATURE_URL_DECODE_FAILED",
      `AdMob SSV signature/key_id URL decoding failed: ${error.message}`,
    );
  }


  if (
    signature.length ===
      0
  ) {
    throw createAdMobError(
      "ADMOB_SIGNATURE_VALUE_MISSING",
      "AdMob SSV signature value is missing.",
    );
  }


  if (
    keyId.length ===
      0
  ) {
    throw createAdMobError(
      "ADMOB_KEY_ID_VALUE_MISSING",
      "AdMob SSV key_id value is missing.",
    );
  }


  /**
   * key_id on numeerinen tunniste.
   */

  if (
    !/^\d+$/.test(
      keyId,
    )
  ) {
    throw createAdMobError(
      "ADMOB_KEY_ID_INVALID",
      "AdMob SSV key_id is invalid.",
      {
        keyId,
      },
    );
  }


  return {
    signedQueryString,

    signature,

    keyId,
  };
}


/**
 * ============================================================
 * 🔐 VERIFY ONE RAW QUERY STRING
 * ============================================================
 */

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
    throw createAdMobError(
      "ADMOB_PUBLIC_KEY_NOT_FOUND",
      `AdMob SSV public key not found for key_id=${keyId}`,
      {
        keyId,
      },
    );
  }


  /**
   * ==========================================================
   * 🔐 ECDSA SHA-256
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
    throw createAdMobError(
      "ADMOB_CRYPTO_VERIFICATION_ERROR",
      `AdMob SSV cryptographic verification failed: ${error.message}`,
      {
        keyId,
      },
    );
  }


  if (
    !verified
  ) {
    throw createAdMobError(
      "ADMOB_INVALID_SIGNATURE",
      "AdMob SSV signature verification failed.",
      {
        keyId,
      },
    );
  }


  /**
   * ==========================================================
   * IMPORTANT
   * ==========================================================
   *
   * Vasta kryptografisen tarkistuksen jälkeen
   * query-string parsitaan.
   *
   * ==========================================================
   */

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


/**
 * ============================================================
 * 🔐 VERIFY ADMOB SIGNATURE
 * ============================================================
 */

async function verifyAdMobSignature(
  req,
) {
  let rawQueryString;


  try {
    rawQueryString =
      getRawQueryString(
        req,
      );
  } catch (
    error
  ) {
    console.error(
      "🐱❌ AdMob SSV raw query extraction FAILED.",
      {
        code:
          error &&
          error.code
            ? error.code
            : "ADMOB_QUERY_ERROR",

        message:
          error &&
          error.message
            ? error.message
            : "Unknown query extraction error.",
      },
    );

    throw error;
  }


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
    /**
     * --------------------------------------------------------
     * TÄRKEÄ DIAGNOSTIIKKA
     * --------------------------------------------------------
     *
     * Aikaisemmin Cloud Loggingiin tuli käytännössä vain
     * "verification failed".
     *
     * Nyt kirjataan sekä code että message.
     *
     * Tämä auttaa selvittämään miksi AdMob palauttaa 400.
     */

    console.error(
      "🐱❌ AdMob SSV signature verification FAILED.",
      {
        code:
          error &&
          error.code
            ? error.code
            : "ADMOB_SIGNATURE_UNKNOWN_ERROR",

        message:
          error &&
          error.message
            ? error.message
            : "Unknown AdMob SSV verification error.",

        keyId:
          error &&
          error.keyId
            ? error.keyId
            : "",
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
    value.length ===
      0
  ) {
    throw createAdMobError(
      "ADMOB_REQUIRED_PARAMETER_MISSING",
      `AdMob SSV required parameter "${name}" is missing.`,
      {
        parameter:
          name,
      },
    );
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
    trimmed.length ===
      0 ||
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
 * Stelluriini käyttää:
 *
 *   UID:mining_start
 *
 * tai:
 *
 *   UID:power_boost
 *
 * Pelkkä UID ei ole hyväksytty reward-käyttötarkoitukseksi.
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
    value.length > 128
  ) {
    return {
      uid:
        "",

      rewardPurpose:
        "",
    };
  }


  /**
   * ----------------------------------------------------------
   * FIND LAST SEPARATOR
   * ----------------------------------------------------------
   */

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


  /**
   * ----------------------------------------------------------
   * UID
   * ----------------------------------------------------------
   */

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


  /**
   * ----------------------------------------------------------
   * REWARD PURPOSE
   * ----------------------------------------------------------
   */

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
    value.length ===
      0 ||
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
 *
 * AdMob timestamp:
 *
 *   Epoch time in milliseconds.
 *
 * Replay-suojaus perustuu transaction_id:n atomiseen
 * käsittelyyn Firestoressa.
 *
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
   * CUSTOM DATA
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
   * REWARD PURPOSE
   * ----------------------------------------------------------
   */

  if (
    rewardPurpose !==
      "mining_start" &&
    rewardPurpose !==
      "power_boost"
  ) {
    throw createAdMobError(
      "ADMOB_INVALID_REWARD_PURPOSE",
      `Invalid AdMob reward purpose: ${rewardPurpose}`,
    );
  }


  /**
   * ----------------------------------------------------------
   * UID
   * ----------------------------------------------------------
   */

  if (
    !validateUid(
      uid,
    )
  ) {
    throw createAdMobError(
      "ADMOB_INVALID_UID",
      "AdMob SSV custom_data does not contain a valid UID.",
    );
  }


  /**
   * ----------------------------------------------------------
   * AD UNIT
   * ----------------------------------------------------------
   */

  const expectedAdUnit =
    ADMOB_AD_UNITS[
      rewardPurpose
    ];


  if (
    !expectedAdUnit
  ) {
    throw createAdMobError(
      "ADMOB_AD_UNIT_NOT_CONFIGURED",
      `No AdMob ad unit configured for ${rewardPurpose}.`,
    );
  }


  if (
    adUnit !==
    expectedAdUnit
  ) {
    throw createAdMobError(
      "ADMOB_INVALID_AD_UNIT",
      `Invalid AdMob ad unit. Expected ${expectedAdUnit}, received ${adUnit}.`,
      {
        expectedAdUnit,

        receivedAdUnit:
          adUnit,

        rewardPurpose,
      },
    );
  }


  /**
   * ----------------------------------------------------------
   * REWARD DEFINITION
   * ----------------------------------------------------------
   */

  const rewardDefinition =
    REWARD_DEFINITIONS[
      rewardPurpose
    ];


  if (
    !rewardDefinition
  ) {
    throw createAdMobError(
      "ADMOB_REWARD_DEFINITION_MISSING",
      `No reward definition configured for ${rewardPurpose}.`,
    );
  }


  /**
   * ----------------------------------------------------------
   * REWARD AMOUNT
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
    throw createAdMobError(
      "ADMOB_INVALID_REWARD_AMOUNT",
      `Invalid AdMob reward amount. Expected ${rewardDefinition.rewardAmount}, received ${rewardAmount}.`,
      {
        expected:
          rewardDefinition.rewardAmount,

        received:
          rewardAmount,

        rewardPurpose,
      },
    );
  }


  /**
   * ----------------------------------------------------------
   * REWARD ITEM
   * ----------------------------------------------------------
   */

  if (
    rewardItem !==
    rewardDefinition.rewardItem
  ) {
    throw createAdMobError(
      "ADMOB_INVALID_REWARD_ITEM",
      `Invalid AdMob reward item. Expected "${rewardDefinition.rewardItem}", received "${rewardItem}".`,
      {
        expected:
          rewardDefinition.rewardItem,

        received:
          rewardItem,

        rewardPurpose,
      },
    );
  }


  /**
   * ----------------------------------------------------------
   * TRANSACTION ID
   * ----------------------------------------------------------
   */

  if (
    !validateTransactionId(
      transactionId,
    )
  ) {
    throw createAdMobError(
      "ADMOB_INVALID_TRANSACTION_ID",
      "AdMob SSV transaction_id is missing or invalid.",
    );
  }


  /**
   * ----------------------------------------------------------
   * TIMESTAMP
   * ----------------------------------------------------------
   */

  const timestampResult =
    validateTimestamp(
      timestamp,
    );


  if (
    !timestampResult.valid
  ) {
    throw createAdMobError(
      "ADMOB_INVALID_TIMESTAMP",
      "AdMob timestamp is invalid.",
      {
        received:
          timestamp,
      },
    );
  }


  /**
   * ----------------------------------------------------------
   * USER ID
   * ----------------------------------------------------------
   */

  if (
    userId &&
    userId !==
      uid
  ) {
    throw createAdMobError(
      "ADMOB_USER_ID_MISMATCH",
      "AdMob SSV user_id does not match custom_data UID.",
      {
        uid,

        userId,
      },
    );
  }


  /**
   * ----------------------------------------------------------
   * SIGNATURE / KEY ID
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
    signature.length ===
      0
  ) {
    throw createAdMobError(
      "ADMOB_SIGNATURE_PARAMETER_MISSING",
      "AdMob SSV signature parameter is missing.",
    );
  }


  if (
    keyId.length ===
      0
  ) {
    throw createAdMobError(
      "ADMOB_KEY_ID_PARAMETER_MISSING",
      "AdMob SSV key_id parameter is missing.",
    );
  }


  /**
   * ----------------------------------------------------------
   * NORMALIZED PARAMETERS
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
   * VERIFIED LOG
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
   * RETURN VERIFIED AD
   * ----------------------------------------------------------
   */

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