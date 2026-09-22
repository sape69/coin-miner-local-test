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
} = require(
  "../config/miningConfig",
);


// ============================================================
// 🔐 ADMOB PUBLIC KEY URL
// ============================================================

const ADMOB_SSV_KEYS_URL =
  "https://www.gstatic.com/admob/reward/verifier-keys.json";


// ============================================================
// ⏱️ PUBLIC KEY CACHE
// ============================================================
//
// Google suosittelee public key -avainten välimuistia.
//
// Avaimia ei pidä pitää cachessa yli 24 tuntia,
// koska AdMob voi vaihtaa allekirjoitusavaimia.
//
// 23 tuntia antaa pienen turvamarginaalin.
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

async function fetchJson(
  url,
) {
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
  // NORMAALI CACHE
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
  // ESTÄ USEAT SAMANAIKAISET FETCHIT
  // ----------------------------------------------------------

  if (
    publicKeyFetchPromise
  ) {
    return publicKeyFetchPromise;
  }

  publicKeyFetchPromise =
    (async () => {
      const data =
        await fetchJson(
          ADMOB_SSV_KEYS_URL,
        );

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

        if (
          !/^\d+$/.test(
            keyId,
          )
        ) {
          continue;
        }

        try {
          const publicKey =
            crypto.createPublicKey(
              pem,
            );

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
// AdMob allekirjoittaa alkuperäisen query-stringin.
//
// Siksi raw queryä ei saa rakentaa uudelleen
// URLSearchParamsin, objektin tai muun normalisoinnin kautta
// ennen kryptografista tarkistusta.
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

  if (
    signature.length >
    8192
  ) {
    const error =
      new Error(
        "AdMob SSV signature is too long.",
      );

    error.code =
      "ADMOB_INVALID_SIGNATURE";

    throw error;
  }

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
// Google määrittelee Rewarded SSV callbackin kaksi viimeistä
// query-parametria:
//
//   signature
//   key_id
//
// Tässä:
//
// <signed parameters>&signature=<signature>&key_id=<key_id>
//
// TÄRKEÄÄ:
//
// signedQueryString sisältää alkuperäisen raw-queryn
// täsmälleen siinä muodossa kuin Google lähetti sen.
//
// Sitä EI URL-dekoodata.
// Sitä EI järjestetä uudelleen.
// Sitä EI rakenneta URLSearchParamsin avulla.
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

  if (
    rawQueryString.length >
    16384
  ) {
    const error =
      new Error(
        "AdMob SSV query string is too long.",
      );

    error.code =
      "ADMOB_INVALID_SIGNATURE";

    throw error;
  }

  // ----------------------------------------------------------
  // SPLIT RAW QUERY ILMAN NORMALISOINTIA
  // ----------------------------------------------------------

  const parts =
    rawQueryString.split(
      "&",
    );

  if (
    parts.length <
    3
  ) {
    const error =
      new Error(
        "AdMob SSV callback does not contain enough query parameters.",
      );

    error.code =
      "ADMOB_INVALID_SIGNATURE";

    throw error;
  }

  const keyIdPart =
    parts[
      parts.length - 1
    ];

  const signaturePart =
    parts[
      parts.length - 2
    ];

  // ----------------------------------------------------------
  // SIGNATURE ON TOISEKSI VIIMEINEN
  // ----------------------------------------------------------

  if (
    !signaturePart.startsWith(
      "signature=",
    )
  ) {
    const error =
      new Error(
        "AdMob SSV signature is not the second-to-last query parameter.",
      );

    error.code =
      "ADMOB_INVALID_SIGNATURE";

    throw error;
  }

  // ----------------------------------------------------------
  // KEY_ID ON VIIMEINEN
  // ----------------------------------------------------------

  if (
    !keyIdPart.startsWith(
      "key_id=",
    )
  ) {
    const error =
      new Error(
        "AdMob SSV key_id is not the final query parameter.",
      );

    error.code =
      "ADMOB_INVALID_KEY_ID";

    throw error;
  }

  // ----------------------------------------------------------
  // ESTÄ TYHJÄT ARVOT
  // ----------------------------------------------------------

  const rawSignature =
    signaturePart.substring(
      "signature=".length,
    );

  const rawKeyId =
    keyIdPart.substring(
      "key_id=".length,
    );

  if (
    rawSignature.length ===
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
    rawKeyId.length ===
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

  // ----------------------------------------------------------
  // ALLEKIRJOITETTAVA SISÄLTÖ
  // ----------------------------------------------------------
  //
  // Poistetaan vain kaksi viimeistä parametria.
  //
  // Kaikki niitä edeltävät merkit säilyvät täsmälleen.
  //
  // ----------------------------------------------------------

  const signedQueryString =
    parts
      .slice(
        0,
        -2,
      )
      .join(
        "&",
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
  // URL-DECODE VAIN SIGNATURE JA KEY_ID
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

  let publicKeys =
    await getAdMobPublicKeys(
      false,
    );

  let publicKey =
    publicKeys.get(
      keyId,
    );

  // ----------------------------------------------------------
  // KEY ROTATION
  // ----------------------------------------------------------
  //
  // Jos key_id ei löydy cachesta, haetaan public keys
  // uudelleen.
  //
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
  // ECDSA / SHA-256 / DER
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
  // PARAMETRIT PURETAAN VASTA ALLEKIRJOITUKSEN JÄLKEEN
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
// Expected:
//
// <firebase_uid>:<reward_purpose>
//
// Example:
//
// abc123:mining_start
// abc123:power_boost
//
// custom_data tulee Googlelta percent-escaped muodossa.
// URLSearchParams purkaa sen ennen tämän funktion kutsua.
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
// AdMob määrittelee transaction_id:n unique hex encoded
// identifier -muotoiseksi.
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
  // KRYPTOSOGRAFIA ENSIN
  // ----------------------------------------------------------

  const verification =
    await verifyAdMobSignature(
      req,
    );

  const params =
    verification.params;

  // ----------------------------------------------------------
  // REQUIRED PARAMETERS
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

  // user_id on AdMobissa valinnainen.
  const rawUserId =
    getParam(
      params,
      "user_id",
    );

  // ----------------------------------------------------------
  // AD NETWORK
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
  // CUSTOM DATA
  // ----------------------------------------------------------

  const parsedCustomData =
    parseCustomData(
      customData,
    );

  const uid =
    parsedCustomData.uid;

  const rewardPurpose =
    parsedCustomData.rewardPurpose;

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
  // AD UNIT
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
  // REWARD CONFIGURATION
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
      "ADMOB_INVALID_REWARD_CONFIGURATION";

    throw error;
  }

  // ----------------------------------------------------------
  // REWARD AMOUNT
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
    expectedRewardAmount <
      0
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
  // REWARD ITEM
  // ----------------------------------------------------------

  const expectedRewardItem =
    rewardDefinition.rewardItem;

  if (
    typeof expectedRewardItem !==
      "string" ||
    expectedRewardItem.trim()
      .length ===
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
  // TRANSACTION ID
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
  // TIMESTAMP
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
  // OPTIONAL USER ID
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
  // VERIFIED SIGNATURE METADATA
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
  // VERIFIED PARAMETERS
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
  // LOGGING
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
  // RETURN VERIFIED RESULT
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