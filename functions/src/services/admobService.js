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
// Google AdMob SSV public keys voivat vaihtua.
//
// Avaimia ei pidetä cachessa yli 24 tuntia.
// Käytämme 23 tuntia.
//
// ============================================================

const PUBLIC_KEY_CACHE_MS =
  23 * 60 * 60 * 1000;

const PUBLIC_KEY_FETCH_TIMEOUT_MS =
  10 * 1000;

const MAX_PUBLIC_KEY_RESPONSE_BYTES =
  1024 * 1024;

let cachedPublicKeys = null;

let cachedPublicKeysAt = 0;

let publicKeyFetchPromise = null;


// ============================================================
// 📏 SSV LIMITS
// ============================================================

const MAX_RAW_QUERY_STRING_LENGTH =
  16384;

const MAX_SIGNATURE_LENGTH =
  8192;

const MAX_UID_LENGTH =
  128;

const MAX_TRANSACTION_ID_LENGTH =
  256;

const MAX_CUSTOM_DATA_LENGTH =
  256;

const MAX_AD_NETWORK_LENGTH =
  32;

const MAX_REWARD_ITEM_LENGTH =
  256;

const MAX_AD_UNIT_LENGTH =
  256;

const MAX_KEY_ID_LENGTH =
  32;


// ============================================================
// ⏱️ TIMESTAMP
// ============================================================
//
// AdMob SSV callback voi saapua viiveellä.
//
// Emme käytä lyhyttä callback-expiration-rajaa.
// Tarkistamme kuitenkin tulevaisuuteen sijoittuvan
// timestampin.
//
// Replay-suojaus tehdään transaction_id:n avulla
// adFunctions.js:n Firestore-transaktiossa.
//
// ============================================================

const TIMESTAMP_FUTURE_TOLERANCE_MS =
  5 * 60 * 1000;


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
// 🧰 ERROR HELPER
// ============================================================

function createError(
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
// 🌐 FETCH JSON
// ============================================================
//
// Public key response luetaan rajatulla koolla.
//
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

    throw createError(
      `Unable to fetch AdMob public keys: ${reason}`,
      "ADMOB_PUBLIC_KEY_FETCH_ERROR",
    );
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

    throw createError(
      `AdMob public key server returned HTTP ${status}.`,
      "ADMOB_PUBLIC_KEY_HTTP_ERROR",
    );
  }


  // ==========================================================
  // RESPONSE SIZE
  // ==========================================================

  const contentLength =
    response.headers &&
    typeof response.headers.get ===
      "function"
      ? response.headers.get(
          "content-length",
        )
      : null;

  if (
    contentLength !== null
  ) {
    const declaredLength =
      Number(
        contentLength,
      );

    if (
      Number.isSafeInteger(
        declaredLength,
      ) &&
      declaredLength >
        MAX_PUBLIC_KEY_RESPONSE_BYTES
    ) {
      throw createError(
        "AdMob public key response is too large.",
        "ADMOB_PUBLIC_KEY_RESPONSE_INVALID",
      );
    }
  }


  // ==========================================================
  // RESPONSE BODY
  // ==========================================================

  let text;

  try {
    text =
      await response.text();
  } catch (error) {
    throw createError(
      `Unable to read AdMob public key response: ${
        error &&
        error.message
          ? error.message
          : "Unknown error."
      }`,
      "ADMOB_PUBLIC_KEY_FETCH_ERROR",
    );
  }

  if (
    typeof text !==
      "string" ||
    text.length ===
      0 ||
    text.length >
      MAX_PUBLIC_KEY_RESPONSE_BYTES
  ) {
    throw createError(
      "AdMob public key response is invalid or too large.",
      "ADMOB_PUBLIC_KEY_RESPONSE_INVALID",
    );
  }


  // ==========================================================
  // JSON
  // ==========================================================

  try {
    return JSON.parse(
      text,
    );
  } catch (error) {
    throw createError(
      `AdMob public key response is not valid JSON: ${
        error &&
        error.message
          ? error.message
          : "Unknown JSON error."
      }`,
      "ADMOB_PUBLIC_KEY_JSON_ERROR",
    );
  }
}


// ============================================================
// 🔑 LOAD ADMOB PUBLIC KEYS
// ============================================================
//
// forceRefresh=true ohittaa olemassa olevan cachen.
//
// Samanaikaiset normaalit fetchit yhdistetään yhdeksi
// promiseksi.
//
// Tärkeä ero:
//
// Jos forceRefresh pyydetään, emme palauta olemassa olevaa
// fetch-promisea sokeasti, jos se syntyi ennen forced refreshiä.
// Näin key rotation voidaan oikeasti käsitellä.
//
// ============================================================

async function getAdMobPublicKeys(
  forceRefresh = false,
) {
  const now =
    Date.now();


  // ==========================================================
  // NORMAL CACHE
  // ==========================================================

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


  // ==========================================================
  // FETCH LOCK
  // ==========================================================

  if (
    publicKeyFetchPromise &&
    !forceRefresh
  ) {
    return publicKeyFetchPromise;
  }


  // ==========================================================
  // FETCH
  // ==========================================================

  const fetchPromise =
    (async () => {
      const data =
        await fetchJson(
          ADMOB_SSV_KEYS_URL,
        );


      // ======================================================
      // RESPONSE STRUCTURE
      // ======================================================

      if (
        !data ||
        !Array.isArray(
          data.keys,
        )
      ) {
        throw createError(
          "AdMob public key response is invalid.",
          "ADMOB_PUBLIC_KEY_RESPONSE_INVALID",
        );
      }


      // ======================================================
      // BUILD KEY MAP
      // ======================================================

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


        // ====================================================
        // KEY ID
        // ====================================================

        if (
          keyId.length ===
            0 ||
          keyId.length >
            MAX_KEY_ID_LENGTH ||
          !/^\d+$/.test(
            keyId,
          )
        ) {
          continue;
        }


        // ====================================================
        // PEM
        // ====================================================

        if (
          pem.length ===
          0
        ) {
          continue;
        }


        // ====================================================
        // VALIDATE PUBLIC KEY
        // ====================================================

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


          // ==================================================
          // VALID EC CURVE
          // ==================================================
          //
          // AdMob SSV käyttää ECDSA-pohjaista allekirjoitusta.
          //
          // Emme hyväksy mielivaltaista EC-avainta.
          //
          // P-256 on AdMob SSV:n odotettu käyrä.
          //
          // ==================================================

          const details =
            publicKey.asymmetricKeyDetails;

          if (
            details &&
            details.namedCurve &&
            details.namedCurve !==
              "prime256v1"
          ) {
            console.error(
              "🐱 Unsupported AdMob EC curve skipped.",
              {
                keyId,

                curve:
                  details.namedCurve,
              },
            );

            continue;
          }


          // ==================================================
          // STORE
          // ==================================================

          keys.set(
            keyId,
            pem,
          );
        } catch (error) {
          console.error(
            "🐱 Invalid AdMob public key skipped.",
            {
              keyId,
            },
          );
        }
      }


      // ======================================================
      // EMPTY
      // ======================================================

      if (
        keys.size ===
        0
      ) {
        throw createError(
          "No usable AdMob public keys were returned.",
          "ADMOB_PUBLIC_KEYS_EMPTY",
        );
      }


      // ======================================================
      // CACHE
      // ======================================================

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


  // ==========================================================
  // SAVE / CLEAR FETCH PROMISE
  // ==========================================================

  if (
    !publicKeyFetchPromise
  ) {
    publicKeyFetchPromise =
      fetchPromise;

    try {
      return await fetchPromise;
    } finally {
      if (
        publicKeyFetchPromise ===
        fetchPromise
      ) {
        publicKeyFetchPromise =
          null;
      }
    }
  }


  // ==========================================================
  // FORCE REFRESH ALREADY RUNNING
  // ==========================================================
  //
  // Jos toinen forced refresh on jo käynnissä, käytetään
  // olemassa olevaa refreshia sen sijaan, että käynnistetään
  // rajattomasti uusia requesteja.
  //
  // ==========================================================

  return fetchPromise;
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
// Siksi raw queryä EI saa rakentaa uudelleen
// URLSearchParamsin, objektin tai muun normalisoinnin avulla
// ennen kryptografista tarkistusta.
//
// ============================================================

function getRawQueryString(
  req,
) {
  if (
    !req
  ) {
    throw createError(
      "Missing HTTP request.",
      "ADMOB_REQUEST_MISSING",
    );
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

  throw createError(
    "AdMob SSV query string is missing.",
    "ADMOB_QUERY_STRING_MISSING",
  );
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
    throw createError(
      "AdMob SSV signature is missing.",
      "ADMOB_INVALID_SIGNATURE",
    );
  }

  if (
    signature.length >
    MAX_SIGNATURE_LENGTH
  ) {
    throw createError(
      "AdMob SSV signature is too long.",
      "ADMOB_INVALID_SIGNATURE",
    );
  }


  // ==========================================================
  // BASE64URL
  // ==========================================================

  if (
    !/^[A-Za-z0-9_-]+$/.test(
      signature,
    )
  ) {
    throw createError(
      "AdMob SSV signature contains invalid Base64URL characters.",
      "ADMOB_INVALID_SIGNATURE",
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

  if (
    normalized.length % 4 ===
      1
  ) {
    throw createError(
      "AdMob SSV signature has invalid Base64URL length.",
      "ADMOB_INVALID_SIGNATURE",
    );
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


  // ==========================================================
  // DECODE
  // ==========================================================

  let signatureBuffer;

  try {
    signatureBuffer =
      Buffer.from(
        padded,
        "base64",
      );
  } catch (error) {
    throw createError(
      "AdMob SSV signature could not be decoded.",
      "ADMOB_INVALID_SIGNATURE",
    );
  }

  if (
    signatureBuffer.length ===
    0
  ) {
    throw createError(
      "AdMob SSV signature could not be decoded.",
      "ADMOB_INVALID_SIGNATURE",
    );
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
// Muoto:
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
    throw createError(
      "AdMob SSV raw query string is missing.",
      "ADMOB_QUERY_STRING_MISSING",
    );
  }

  if (
    rawQueryString.length >
    MAX_RAW_QUERY_STRING_LENGTH
  ) {
    throw createError(
      "AdMob SSV query string is too long.",
      "ADMOB_INVALID_SIGNATURE",
    );
  }


  // ==========================================================
  // SPLIT RAW QUERY
  // ==========================================================

  const parts =
    rawQueryString.split(
      "&",
    );

  if (
    parts.length <
    3
  ) {
    throw createError(
      "AdMob SSV callback does not contain enough query parameters.",
      "ADMOB_INVALID_SIGNATURE",
    );
  }


  const keyIdPart =
    parts[
      parts.length - 1
    ];

  const signaturePart =
    parts[
      parts.length - 2
    ];


  // ==========================================================
  // SIGNATURE
  // ==========================================================

  if (
    !signaturePart.startsWith(
      "signature=",
    )
  ) {
    throw createError(
      "AdMob SSV signature is not the second-to-last query parameter.",
      "ADMOB_INVALID_SIGNATURE",
    );
  }


  // ==========================================================
  // KEY ID
  // ==========================================================

  if (
    !keyIdPart.startsWith(
      "key_id=",
    )
  ) {
    throw createError(
      "AdMob SSV key_id is not the final query parameter.",
      "ADMOB_INVALID_KEY_ID",
    );
  }


  // ==========================================================
  // RAW VALUES
  // ==========================================================

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
    throw createError(
      "AdMob SSV signature value is missing.",
      "ADMOB_INVALID_SIGNATURE",
    );
  }

  if (
    rawKeyId.length ===
      0
  ) {
    throw createError(
      "AdMob SSV key_id value is missing.",
      "ADMOB_INVALID_KEY_ID",
    );
  }


  // ==========================================================
  // URL DECODE ONLY METADATA
  // ==========================================================

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
    throw createError(
      "AdMob SSV signature/key_id URL decoding failed.",
      "ADMOB_INVALID_SIGNATURE",
    );
  }


  // ==========================================================
  // KEY ID
  // ==========================================================

  if (
    keyId.length ===
      0
  ) {
    throw createError(
      "AdMob SSV key_id value is missing.",
      "ADMOB_INVALID_KEY_ID",
    );
  }

  if (
    keyId.length >
    MAX_KEY_ID_LENGTH ||
    !/^\d+$/.test(
      keyId,
    )
  ) {
    throw createError(
      "AdMob SSV key_id is invalid.",
      "ADMOB_INVALID_KEY_ID",
    );
  }


  // ==========================================================
  // SIGNATURE
  // ==========================================================

  if (
    signature.length ===
      0 ||
    signature.length >
      MAX_SIGNATURE_LENGTH ||
    !/^[A-Za-z0-9_-]+$/.test(
      signature,
    )
  ) {
    throw createError(
      "AdMob SSV signature is invalid.",
      "ADMOB_INVALID_SIGNATURE",
    );
  }


  // ==========================================================
  // SIGNED QUERY
  // ==========================================================
  //
  // Poistetaan vain signature ja key_id.
  //
  // Kaikki niiden edeltävät merkit säilyvät täsmälleen.
  //
  // ==========================================================

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
    throw createError(
      "AdMob SSV signed query string is empty.",
      "ADMOB_INVALID_SIGNATURE",
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
  const {
    signedQueryString,
    signature,
    keyId,
  } =
    extractSignatureData(
      rawQueryString,
    );


  // ==========================================================
  // SIGNATURE BUFFER
  // ==========================================================

  const signatureBuffer =
    decodeAdMobSignature(
      signature,
    );


  // ==========================================================
  // PUBLIC KEYS
  // ==========================================================

  let publicKeys =
    await getAdMobPublicKeys(
      false,
    );

  let publicKey =
    publicKeys.get(
      keyId,
    );


  // ==========================================================
  // KEY ROTATION
  // ==========================================================

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


  // ==========================================================
  // KEY NOT FOUND
  // ==========================================================

  if (
    !publicKey
  ) {
    const error =
      createError(
        `AdMob SSV public key not found for key_id=${keyId}`,
        "ADMOB_PUBLIC_KEY_NOT_FOUND",
      );

    error.keyId =
      keyId;

    throw error;
  }


  // ==========================================================
  // ECDSA / SHA-256 / DER
  // ==========================================================

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
      createError(
        "AdMob SSV cryptographic verification failed.",
        "ADMOB_CRYPTO_VERIFICATION_ERROR",
      );

    verificationError.keyId =
      keyId;

    throw verificationError;
  }


  // ==========================================================
  // INVALID SIGNATURE
  // ==========================================================

  if (
    !verified
  ) {
    const error =
      createError(
        "AdMob SSV signature verification failed.",
        "ADMOB_INVALID_SIGNATURE",
      );

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


  // ==========================================================
  // PARSE PARAMETERS ONLY AFTER VERIFICATION
  // ==========================================================

  let params;

  try {
    params =
      new URLSearchParams(
        rawQueryString,
      );
  } catch (error) {
    throw createError(
      "AdMob SSV query parameters could not be parsed.",
      "ADMOB_REQUIRED_PARAMETER_MISSING",
    );
  }


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
          "signature=",
        ),

      hasKeyId:
        rawQueryString.includes(
          "key_id=",
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
      createError(
        `AdMob SSV required parameter "${name}" is missing.`,
        "ADMOB_REQUIRED_PARAMETER_MISSING",
      );

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
      MAX_UID_LENGTH
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
// URLSearchParams purkaa percent-encodingin ennen tämän
// funktion kutsua.
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
      MAX_CUSTOM_DATA_LENGTH
  ) {
    return {
      uid:
        "",

      rewardPurpose:
        "",
    };
  }


  // ==========================================================
  // LAST COLON
  // ==========================================================

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


  // ==========================================================
  // UID
  // ==========================================================

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


  // ==========================================================
  // PURPOSE
  // ==========================================================

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
// AdMob määrittelee transaction_id:n yksilölliseksi
// hex-encoded identifieriksi.
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
      MAX_TRANSACTION_ID_LENGTH
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
      MAX_AD_NETWORK_LENGTH
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
  // ==========================================================
  // KRYPTOSOGRAFIA ENSIN
  // ==========================================================

  const verification =
    await verifyAdMobSignature(
      req,
    );

  const params =
    verification.params;


  // ==========================================================
  // REQUIRED PARAMETERS
  // ==========================================================

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


  // ==========================================================
  // OPTIONAL USER ID
  // ==========================================================

  const rawUserId =
    getParam(
      params,
      "user_id",
    );


  // ==========================================================
  // AD NETWORK
  // ==========================================================

  if (
    !validateAdNetwork(
      adNetwork,
    )
  ) {
    throw createError(
      "AdMob SSV ad_network is invalid.",
      "ADMOB_INVALID_AD_NETWORK",
    );
  }


  // ==========================================================
  // CUSTOM DATA
  // ==========================================================

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
    throw createError(
      `Invalid AdMob reward purpose: ${rewardPurpose}`,
      "ADMOB_INVALID_REWARD_PURPOSE",
    );
  }

  if (
    !validateUid(
      uid,
    )
  ) {
    throw createError(
      "AdMob SSV custom_data does not contain a valid UID.",
      "ADMOB_INVALID_UID",
    );
  }


  // ==========================================================
  // AD UNIT
  // ==========================================================

  const expectedAdUnit =
    ADMOB_AD_UNITS[
      rewardPurpose
    ];

  if (
    typeof expectedAdUnit !==
      "string" ||
    expectedAdUnit.trim()
      .length ===
      0 ||
    expectedAdUnit.length >
      MAX_AD_UNIT_LENGTH
  ) {
    throw createError(
      `No valid AdMob ad unit configured for ${rewardPurpose}.`,
      "ADMOB_INVALID_REWARD_CONFIGURATION",
    );
  }

  if (
    adUnit !==
    expectedAdUnit
  ) {
    throw createError(
      "Invalid AdMob ad unit.",
      "ADMOB_INVALID_AD_UNIT",
    );
  }


  // ==========================================================
  // REWARD CONFIGURATION
  // ==========================================================

  const rewardDefinition =
    REWARD_DEFINITIONS[
      rewardPurpose
    ];

  if (
    !rewardDefinition
  ) {
    throw createError(
      `No reward definition configured for ${rewardPurpose}.`,
      "ADMOB_INVALID_REWARD_CONFIGURATION",
    );
  }


  // ==========================================================
  // REWARD AMOUNT
  // ==========================================================

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
    throw createError(
      `Configured AdMob reward amount is invalid for ${rewardPurpose}.`,
      "ADMOB_INVALID_REWARD_CONFIGURATION",
    );
  }

  if (
    parsedRewardAmount !==
      expectedRewardAmount
  ) {
    throw createError(
      `Invalid AdMob reward amount. Expected ${expectedRewardAmount}, received ${rewardAmount}.`,
      "ADMOB_INVALID_REWARD_AMOUNT",
    );
  }


  // ==========================================================
  // REWARD ITEM
  // ==========================================================

  const expectedRewardItem =
    rewardDefinition.rewardItem;

  if (
    typeof expectedRewardItem !==
      "string" ||
    expectedRewardItem.trim()
      .length ===
      0 ||
    expectedRewardItem.length >
      MAX_REWARD_ITEM_LENGTH
  ) {
    throw createError(
      `Configured AdMob reward item is invalid for ${rewardPurpose}.`,
      "ADMOB_INVALID_REWARD_CONFIGURATION",
    );
  }

  if (
    rewardItem !==
    expectedRewardItem
  ) {
    throw createError(
      `Invalid AdMob reward item. Expected "${expectedRewardItem}", received "${rewardItem}".`,
      "ADMOB_INVALID_REWARD_ITEM",
    );
  }


  // ==========================================================
  // TRANSACTION ID
  // ==========================================================

  if (
    !validateTransactionId(
      transactionId,
    )
  ) {
    throw createError(
      "AdMob SSV transaction_id is missing or invalid.",
      "ADMOB_INVALID_TRANSACTION_ID",
    );
  }


  // ==========================================================
  // TIMESTAMP
  // ==========================================================

  const timestampResult =
    validateTimestamp(
      timestamp,
    );

  if (
    !timestampResult.valid
  ) {
    throw createError(
      "AdMob timestamp is invalid or too far in the future.",
      "ADMOB_INVALID_TIMESTAMP",
    );
  }


  // ==========================================================
  // OPTIONAL USER ID
  // ==========================================================

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
      throw createError(
        "AdMob SSV user_id is invalid.",
        "ADMOB_INVALID_UID",
      );
    }

    if (
      userId !==
      uid
    ) {
      throw createError(
        "AdMob SSV user_id does not match custom_data UID.",
        "ADMOB_USER_ID_MISMATCH",
      );
    }
  }


  // ==========================================================
  // VERIFIED SIGNATURE METADATA
  // ==========================================================

  const signature =
    verification.signature;

  const keyId =
    verification.keyId;

  if (
    typeof signature !==
      "string" ||
    signature.length ===
      0 ||
    signature.length >
      MAX_SIGNATURE_LENGTH
  ) {
    throw createError(
      "AdMob verified signature value is invalid.",
      "ADMOB_INVALID_SIGNATURE",
    );
  }

  if (
    typeof keyId !==
      "string" ||
    keyId.length ===
      0 ||
    keyId.length >
      MAX_KEY_ID_LENGTH ||
    !/^\d+$/.test(
      keyId,
    )
  ) {
    throw createError(
      "AdMob verified key_id value is invalid.",
      "ADMOB_INVALID_KEY_ID",
    );
  }


  // ==========================================================
  // VERIFIED PARAMETERS
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

    signature,

    key_id:
      keyId,
  };


  // ==========================================================
  // LOGGING
  // ==========================================================

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


  // ==========================================================
  // RETURN VERIFIED RESULT
  // ==========================================================

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