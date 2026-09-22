"use strict";

const crypto = require("crypto");

// ============================================================
// 🐱 STELLURIINI - ADMOB SERVICE
// ============================================================
//
// Vastuu:
//
// 🔐 AdMob Rewarded SSV -allekirjoituksen tarkistaminen
// 🔑 AdMob public key -avainten lataaminen ja välimuisti
// 🧩 SSV-parametrien lukeminen
// 🛡️ Reward-metadata-validointi
// 👤 UID-validointi
// 🆔 Transaction ID -validointi
// ⏱️ Timestamp-validointi
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
// ⚙️ MINING CONFIG
// ============================================================

const {
  ADMOB_MINING_SSV_AD_UNIT_ID,
  ADMOB_POWER_BOOST_SSV_AD_UNIT_ID,

  ADMOB_MINING_SSV_REWARD_AMOUNT,
  ADMOB_MINING_SSV_REWARD_ITEM,

  ADMOB_POWER_BOOST_SSV_REWARD_AMOUNT,
  ADMOB_POWER_BOOST_SSV_REWARD_ITEM,
} = require("../config/miningConfig");

// ============================================================
// 🔐 ADMOB PUBLIC KEY URL
// ============================================================

const ADMOB_SSV_KEYS_URL =
  "https://www.gstatic.com/admob/reward/verifier-keys.json";

// ============================================================
// ⏱️ PUBLIC KEY CACHE
// ============================================================
//
// AdMob kierrättää public key -avaimia.
//
// Google suosittelee cachettamaan avaimia, mutta ei
// pidempään kuin 24 tuntia.
//
// Käytetään 23 tuntia, jotta cache ehtii vanhentua
// ennen AdMobin 24 tunnin enimmäisaikaa.
//
// ============================================================

const PUBLIC_KEY_CACHE_MS =
  23 * 60 * 60 * 1000;

const PUBLIC_KEY_FETCH_TIMEOUT_MS =
  10 * 1000;

let cachedPublicKeys = null;

let cachedPublicKeysAt = 0;

let publicKeyFetchPromise = null;

// ============================================================
// 📺 ADMOB AD UNITS
// ============================================================

const ADMOB_AD_UNITS = {
  mining_start:
    ADMOB_MINING_SSV_AD_UNIT_ID,

  power_boost:
    ADMOB_POWER_BOOST_SSV_AD_UNIT_ID,
};

// ============================================================
// 🎁 EXPECTED REWARDS
// ============================================================
//
// Nämä ovat AdMob Rewarded -metadata-arvoja.
//
// NE EIVÄT OLE STL-TOKENIPALKINTOJA.
//
// ============================================================

const REWARD_DEFINITIONS = {
  mining_start: {
    rewardItem:
      ADMOB_MINING_SSV_REWARD_ITEM,

    rewardAmount:
      ADMOB_MINING_SSV_REWARD_AMOUNT,
  },

  power_boost: {
    rewardItem:
      ADMOB_POWER_BOOST_SSV_REWARD_ITEM,

    rewardAmount:
      ADMOB_POWER_BOOST_SSV_REWARD_AMOUNT,
  },
};

// ============================================================
// 🌐 FETCH JSON
// ============================================================

async function fetchJson(url) {
  const controller =
    new AbortController();

  const timeout =
    setTimeout(
      () => {
        controller.abort();
      },
      PUBLIC_KEY_FETCH_TIMEOUT_MS,
    );

  let response;

  try {
    response =
      await fetch(
        url,
        {
          method:
            "GET",

          signal:
            controller.signal,

          headers: {
            Accept:
              "application/json",
          },
        },
      );
  } catch (error) {
    const reason =
      error &&
      error.name ===
        "AbortError"
        ? "Request timed out."
        : error &&
          error.message
        ? error.message
        : "Unknown network error.";

    const fetchError =
      new Error(
        `Unable to fetch AdMob public keys: ${reason}`,
      );

    fetchError.code =
      "ADMOB_PUBLIC_KEY_FETCH_ERROR";

    throw fetchError;
  } finally {
    clearTimeout(
      timeout,
    );
  }

  // ----------------------------------------------------------
  // HTTP STATUS
  // ----------------------------------------------------------

  if (
    !response ||
    !response.ok
  ) {
    const status =
      response &&
      typeof response.status ===
        "number"
        ? response.status
        : 0;

    const error =
      new Error(
        `AdMob public key server returned HTTP ${status}.`,
      );

    error.code =
      "ADMOB_PUBLIC_KEY_HTTP_ERROR";

    throw error;
  }

  // ----------------------------------------------------------
  // JSON
  // ----------------------------------------------------------

  try {
    return await response.json();
  } catch (error) {
    const jsonError =
      new Error(
        `AdMob public key response is not valid JSON: ${error.message}`,
      );

    jsonError.code =
      "ADMOB_PUBLIC_KEY_JSON_ERROR";

    throw jsonError;
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
    cachedPublicKeysAt > 0 &&
    now -
      cachedPublicKeysAt <
      PUBLIC_KEY_CACHE_MS
  ) {
    return cachedPublicKeys;
  }

  // ----------------------------------------------------------
  // PREVENT SIMULTANEOUS KEY FETCHES
  // ----------------------------------------------------------
  //
  // Jos useampi SSV callback saapuu yhtä aikaa tyhjän tai
  // vanhentuneen cachen aikana, vain yksi HTTP-pyyntö
  // haetaan AdMobilta.
  //
  // ----------------------------------------------------------

  if (
    publicKeyFetchPromise
  ) {
    return publicKeyFetchPromise;
  }

  // ----------------------------------------------------------
  // FETCH
  // ----------------------------------------------------------

  publicKeyFetchPromise =
    (async () => {
      const data =
        await fetchJson(
          ADMOB_SSV_KEYS_URL,
        );

      // ------------------------------------------------------
      // RESPONSE VALIDATION
      // ------------------------------------------------------

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

      // ------------------------------------------------------
      // PARSE KEYS
      // ------------------------------------------------------

      const keys =
        new Map();

      for (
        const key of data.keys
      ) {
        if (
          !key ||
          key.keyId ===
            undefined ||
          typeof key.pem !==
            "string"
        ) {
          continue;
        }

        const keyId =
          String(
            key.keyId,
          ).trim();

        const pem =
          key.pem.trim();

        if (
          keyId.length ===
            0 ||
          pem.length ===
            0
        ) {
          continue;
        }

        // ----------------------------------------------------
        // KEY ID
        // ----------------------------------------------------

        if (
          !/^\d+$/.test(
            keyId,
          )
        ) {
          continue;
        }

        // ----------------------------------------------------
        // PUBLIC KEY
        // ----------------------------------------------------

        try {
          const publicKey =
            crypto.createPublicKey(
              pem,
            );

          // AdMob SSV käyttää ECDSA-public keytä.

          if (
            publicKey.asymmetricKeyType !==
            "ec"
          ) {
            console.error(
              "🐱 Invalid AdMob public key type skipped.",
              {
                keyId,

                type:
                  publicKey.asymmetricKeyType,
              },
            );

            continue;
          }
        } catch (error) {
          console.error(
            "🐱 Invalid AdMob public key skipped.",
            {
              keyId,
            },
          );

          continue;
        }

        keys.set(
          keyId,
          pem,
        );
      }

      // ------------------------------------------------------
      // EMPTY KEY SET
      // ------------------------------------------------------

      if (
        keys.size ===
        0
      ) {
        const error =
          new Error(
            "No usable AdMob public keys were returned.",
          );

        error.code =
          "ADMOB_PUBLIC_KEYS_EMPTY";

        throw error;
      }

      // ------------------------------------------------------
      // CACHE
      // ------------------------------------------------------

      cachedPublicKeys =
        keys;

      cachedPublicKeysAt =
        Date.now();

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
    })();

  try {
    return await publicKeyFetchPromise;
  } finally {
    publicKeyFetchPromise =
      null;
  }
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
// AdMob allekirjoittaa alkuperäisen query stringin.
//
// Ennen allekirjoituksen tarkistamista:
//
// ❌ ei järjestetä parametreja
// ❌ ei rakenneta query stringiä uudelleen
// ❌ ei URL-dekoodata signed dataa
// ❌ ei trimmaa signed dataa
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

  // ----------------------------------------------------------
  // PREFER RAW URL
  // ----------------------------------------------------------

  const candidates = [
    req.rawUrl,
    req.url,
    req.originalUrl,
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
  // FALLBACK
  // ----------------------------------------------------------

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

  // ----------------------------------------------------------
  // BASE64URL CHARACTER VALIDATION
  // ----------------------------------------------------------

  if (
    !/^[A-Za-z0-9_-]+$/.test(
      signature,
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
  // BASE64URL → BASE64
  // ----------------------------------------------------------

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

  // Base64URL-pituuden modulo 4 ei saa olla 1.

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

  const remainder =
    normalized.length % 4;

  const padded =
    remainder ===
      0
      ? normalized
      : normalized +
        "=".repeat(
          4 -
            remainder,
        );

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
// ...signed parameters...
// &signature=...
// &key_id=...
//
// AdMob dokumentoi, että signature ja key_id ovat
// kaksi viimeistä query-parametria tässä järjestyksessä.
//
// Signed data säilytetään täysin muuttamattomana.
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

  // ----------------------------------------------------------
  // SIGNATURE
  // ----------------------------------------------------------

  const signatureMarker =
    "&signature=";

  const signatureIndex =
    rawQueryString.lastIndexOf(
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

  // ----------------------------------------------------------
  // SIGNED DATA
  // ----------------------------------------------------------

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

  // ----------------------------------------------------------
  // SIGNATURE + KEY ID
  // ----------------------------------------------------------

  const signatureAndKeyId =
    rawQueryString.substring(
      signatureIndex + 1,
    );

  const parts =
    signatureAndKeyId.split(
      "&",
    );

  if (
    parts.length !==
      2
  ) {
    const error =
      new Error(
        "AdMob SSV signature and key_id must be the final two query parameters.",
      );

    error.code =
      "ADMOB_INVALID_SIGNATURE";

    throw error;
  }

  // ----------------------------------------------------------
  // SIGNATURE POSITION
  // ----------------------------------------------------------

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

  // ----------------------------------------------------------
  // KEY ID POSITION
  // ----------------------------------------------------------

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
      "ADMOB_INVALID_SIGNATURE";

    throw error;
  }

  const rawSignature =
    parts[0].substring(
      "signature=".length,
    );

  const rawKeyId =
    parts[1].substring(
      "key_id=".length,
    );

  // ----------------------------------------------------------
  // URL DECODE ONLY SIGNATURE / KEY ID
  // ----------------------------------------------------------

  let signature;

  let keyId;

  try {
    signature =
      decodeURIComponent(
        rawSignature,
      );

    keyId =
      decodeURIComponent(
        rawKeyId,
      );
  } catch (error) {
    const decodingError =
      new Error(
        `AdMob SSV signature/key_id URL decoding failed: ${error.message}`,
      );

    decodingError.code =
      "ADMOB_INVALID_SIGNATURE";

    throw decodingError;
  }

  // ----------------------------------------------------------
  // SIGNATURE VALUE
  // ----------------------------------------------------------

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

  // ----------------------------------------------------------
  // KEY ID VALUE
  // ----------------------------------------------------------

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

  // ----------------------------------------------------------
  // DECODE SIGNATURE
  // ----------------------------------------------------------

  const signatureBuffer =
    decodeAdMobSignature(
      signature,
    );

  // ----------------------------------------------------------
  // PUBLIC KEY
  // ----------------------------------------------------------

  let publicKeys =
    await getAdMobPublicKeys(
      false,
    );

  let publicKey =
    publicKeys.get(
      keyId,
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
        keyId,
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
  // 🔐 ECDSA / SHA-256
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

          dsaEncoding:
            "der",
        },

        signatureBuffer,
      );
  } catch (error) {
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
  // SIGNATURE INVALID
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

  // ----------------------------------------------------------
  // DECODE PARAMETERS ONLY AFTER VERIFICATION
  // ----------------------------------------------------------
  //
  // signedQueryString on varmennettu ensin.
  //
  // Vasta tämän jälkeen query-parametrit dekoodataan
  // business-logiikkaa varten.
  //
  // ----------------------------------------------------------

  const params =
    new URLSearchParams(
      rawQueryString,
    );

  return {
    verified:
      true,

    keyId,

    signature,

    rawQueryString,

    signedQueryString,

    params,
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
  } catch (error) {
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
    value ===
      null ||
    value ===
      undefined
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
      "ADMOB_REQUIRED_PARAMETER_MISSING";

    error.parameter =
      name;

    throw error;
  }

  return value;
}

// ============================================================
// 🔢 STRICT INTEGER HELPER
// ============================================================

function parseInteger(
  value,
  fallback = 0,
) {
  if (
    typeof value !==
      "string"
  ) {
    return fallback;
  }

  const trimmed =
    value.trim();

  if (
    !/^\d+$/.test(
      trimmed,
    )
  ) {
    return fallback;
  }

  const number =
    Number(
      trimmed,
    );

  if (
    !Number.isSafeInteger(
      number,
    )
  ) {
    return fallback;
  }

  return number;
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
// custom_data:
//
//   UID:rewardPurpose
//
// Esimerkiksi:
//
//   abc123:mining_start
//   abc123:power_boost
//
// URLSearchParams purkaa percent-encodingin vasta
// kryptografisen varmennuksen jälkeen.
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
      256
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
// AdMob dokumentoi transaction_id:n yksilöllisenä
// hex-enkoodattuna reward grant -tunnisteena.
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

  return /^[A-Fa-f0-9]+$/.test(
    value,
  );
}

// ============================================================
// ⏱️ TIMESTAMP VALIDATION
// ============================================================
//
// AdMob timestamp on Epoch-aika millisekunteina.
//
// Tulevaisuuden callback hyväksytään vain 5 minuutin
// kellopoikkeamalla.
//
// Vanhaa callbackia ei hylätä pelkän iän perusteella,
// koska AdMob SSV callback voi viivästyä.
//
// Duplicate protection tehdään transaction_id:n avulla.
//
// ============================================================

const TIMESTAMP_FUTURE_TOLERANCE_MS =
  5 * 60 * 1000;

function validateTimestamp(
  timestamp,
) {
  if (
    typeof timestamp !==
      "string"
  ) {
    return {
      valid:
        false,

      timestampMs:
        0,
    };
  }

  const value =
    timestamp.trim();

  if (
    !/^\d+$/.test(
      value,
    )
  ) {
    return {
      valid:
        false,

      timestampMs:
        0,
    };
  }

  const timestampMs =
    Number(
      value,
    );

  if (
    !Number.isSafeInteger(
      timestampMs,
    ) ||
    timestampMs <=
      0
  ) {
    return {
      valid:
        false,

      timestampMs,
    };
  }

  const now =
    Date.now();

  if (
    timestampMs >
      now +
        TIMESTAMP_FUTURE_TOLERANCE_MS
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

  const value =
    adNetwork.trim();

  if (
    value.length ===
      0 ||
    value.length >
      32
  ) {
    return false;
  }

  return /^\d+$/.test(
    value,
  );
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

  const rawUserId =
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
    const error =
      new Error(
        "AdMob SSV ad_network is invalid.",
      );

    error.code =
      "ADMOB_INVALID_AD_NETWORK";

    throw error;
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
    const error =
      new Error(
        `Invalid AdMob reward purpose: ${rewardPurpose}`,
      );

    error.code =
      "ADMOB_INVALID_REWARD_PURPOSE";

    throw error;
  }

  // ----------------------------------------------------------
  // 6. UID
  // ----------------------------------------------------------

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

  // ----------------------------------------------------------
  // 7. AD UNIT
  // ----------------------------------------------------------

  const expectedAdUnit =
    ADMOB_AD_UNITS[
      rewardPurpose
    ];

  if (
    typeof expectedAdUnit !==
      "string" ||
    expectedAdUnit.trim()
      .length ===
      0
  ) {
    const error =
      new Error(
        `No AdMob ad unit configured for ${rewardPurpose}.`,
      );

    error.code =
      "ADMOB_INVALID_AD_UNIT";

    throw error;
  }

  if (
    adUnit !==
      expectedAdUnit
  ) {
    const error =
      new Error(
        "Invalid AdMob ad unit.",
      );

    error.code =
      "ADMOB_INVALID_AD_UNIT";

    throw error;
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
    const error =
      new Error(
        `No reward definition configured for ${rewardPurpose}.`,
      );

    error.code =
      "ADMOB_INVALID_REWARD_PURPOSE";

    throw error;
  }

  // ----------------------------------------------------------
  // 9. REWARD AMOUNT
  // ----------------------------------------------------------

  const parsedRewardAmount =
    parseInteger(
      rewardAmount,
      -1,
    );

  const expectedRewardAmount =
    Number(
      rewardDefinition.rewardAmount,
    );

  if (
    !Number.isSafeInteger(
      expectedRewardAmount,
    ) ||
    expectedRewardAmount < 0
  ) {
    const error =
      new Error(
        `Configured AdMob reward amount is invalid for ${rewardPurpose}.`,
      );

    error.code =
      "ADMOB_INVALID_REWARD_CONFIGURATION";

    throw error;
  }

  if (
    parsedRewardAmount !==
      expectedRewardAmount
  ) {
    const error =
      new Error(
        `Invalid AdMob reward amount. Expected ${expectedRewardAmount}, received ${rewardAmount}.`,
      );

    error.code =
      "ADMOB_INVALID_REWARD_AMOUNT";

    throw error;
  }

  // ----------------------------------------------------------
  // 10. REWARD ITEM
  // ----------------------------------------------------------

  const expectedRewardItem =
    rewardDefinition.rewardItem;

  if (
    typeof expectedRewardItem !==
      "string" ||
    expectedRewardItem.length ===
      0
  ) {
    const error =
      new Error(
        `Configured AdMob reward item is invalid for ${rewardPurpose}.`,
      );

    error.code =
      "ADMOB_INVALID_REWARD_CONFIGURATION";

    throw error;
  }

  if (
    rewardItem !==
      expectedRewardItem
  ) {
    const error =
      new Error(
        `Invalid AdMob reward item. Expected "${expectedRewardItem}", received "${rewardItem}".`,
      );

    error.code =
      "ADMOB_INVALID_REWARD_ITEM";

    throw error;
  }

  // ----------------------------------------------------------
  // 11. TRANSACTION ID
  // ----------------------------------------------------------

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
    const error =
      new Error(
        "AdMob timestamp is invalid or too far in the future.",
      );

    error.code =
      "ADMOB_INVALID_TIMESTAMP";

    throw error;
  }

  // ----------------------------------------------------------
  // 13. USER ID
  // ----------------------------------------------------------
  //
  // user_id on AdMobin callbackissa valinnainen.
  //
  // Jos se on mukana, sen täytyy:
  //
  // 1. olla validi UID
  // 2. vastata custom_data UID:tä
  //
  // ----------------------------------------------------------

  const userId =
    rawUserId.trim();

  if (
    userId
  ) {
    if (
      !validateUid(
        userId,
      )
    ) {
      const error =
        new Error(
          "AdMob SSV user_id is invalid.",
        );

      error.code =
        "ADMOB_INVALID_UID";

      throw error;
    }

    if (
      userId !==
        uid
    ) {
      const error =
        new Error(
          "AdMob SSV user_id does not match custom_data UID.",
        );

      error.code =
        "ADMOB_USER_ID_MISMATCH";

      throw error;
    }
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
    const error =
      new Error(
        "AdMob verified signature value is missing.",
      );

    error.code =
      "ADMOB_INVALID_SIGNATURE";

    throw error;
  }

  if (
    typeof keyId !==
      "string" ||
    keyId.length ===
      0 ||
    !/^\d+$/.test(
      keyId,
    )
  ) {
    const error =
      new Error(
        "AdMob verified key_id value is invalid.",
      );

    error.code =
      "ADMOB_INVALID_KEY_ID";

    throw error;
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
  ADMOB_SSV_KEYS_URL,

  ADMOB_AD_UNITS,

  REWARD_DEFINITIONS,

  getAdMobPublicKeys,

  verifyAdMobSignature,

  verifyAdMobCallback,

  parseCustomData,

  validateTransactionId,

  validateUid,

  validateTimestamp,

  validateAdNetwork,
};