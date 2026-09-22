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
// Replay-suojaus transaction_id:n perusteella tehdään
// myöhemmässä business-kerroksessa.
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
//
// AdMobin virallinen SSV public-key endpoint.
//
// ============================================================

const ADMOB_SSV_KEYS_URL =
  "https://www.gstatic.com/admob/reward/verifier-keys.json";


// ============================================================
// ⏱️ PUBLIC KEY CACHE
// ============================================================
//
// Google suosittelee public key -cachea, mutta avaimia ei
// pidä cachettaa yli 24 tunniksi, koska niitä voidaan kierrättää.
//
// 23 tuntia antaa yhden tunnin marginaalin.
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
// AdMob timestamp on Epoch milliseconds.
//
// Emme aseta callbackille lyhyttä expiry-aikaa, koska
// AdMob voi toimittaa SSV-callbackin viiveellä.
//
// Tarkistamme kuitenkin, ettei timestamp ole tulevaisuudessa
// yli sallitun toleranssin.
//
// Replay-suojaus tehdään transaction_id:n avulla
// myöhemmässä business-kerroksessa.
//
// ============================================================

const TIMESTAMP_FUTURE_TOLERANCE_MS =
  5 * 60 * 1000;


// ============================================================
// 🎯 VALID REWARD PURPOSES
// ============================================================

const VALID_REWARD_PURPOSES =
  new Set([
    "mining_start",
    "power_boost",
  ]);


// ============================================================
// 📺 ADMOB AD UNITS
// ============================================================
//
// AdMob SSV:n ad_unit-arvo tarkistetaan reward-purposen
// mukaan miningConfig.js:n määrittämää arvoa vastaan.
//
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
// Lataa AdMob public-key datan.
//
// Response-koko rajoitetaan myös silloin, kun
// Content-Length-header puuttuu.
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


  // ==========================================================
  // HTTP STATUS
  // ==========================================================

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
  // CONTENT LENGTH
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
      Number.isFinite(
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
  // READ RESPONSE
  // ==========================================================

  let text = "";


  if (
    response.body &&
    typeof response.body.getReader ===
      "function"
  ) {
    const reader =
      response.body.getReader();

    const chunks = [];

    let totalBytes = 0;

    try {
      while (true) {
        const result =
          await reader.read();

        if (
          result.done
        ) {
          break;
        }

        const chunk =
          result.value;

        if (
          !(chunk instanceof Uint8Array)
        ) {
          throw createError(
            "AdMob public key response contains invalid data.",
            "ADMOB_PUBLIC_KEY_RESPONSE_INVALID",
          );
        }

        totalBytes +=
          chunk.byteLength;

        if (
          totalBytes >
          MAX_PUBLIC_KEY_RESPONSE_BYTES
        ) {
          try {
            await reader.cancel();
          } catch (cancelError) {
            // Ignore cancellation errors.
          }

          throw createError(
            "AdMob public key response is too large.",
            "ADMOB_PUBLIC_KEY_RESPONSE_INVALID",
          );
        }

        chunks.push(
          chunk,
        );
      }
    } catch (error) {
      if (
        error &&
        error.code
      ) {
        throw error;
      }

      throw createError(
        `Unable to read AdMob public key response: ${
          error &&
          error.message
            ? error.message
            : "Unknown response error."
        }`,
        "ADMOB_PUBLIC_KEY_FETCH_ERROR",
      );
    }


    const combined =
      new Uint8Array(
        totalBytes,
      );

    let offset = 0;

    for (
      const chunk of chunks
    ) {
      combined.set(
        chunk,
        offset,
      );

      offset +=
        chunk.byteLength;
    }

    text =
      Buffer
        .from(
          combined,
        )
        .toString(
          "utf8",
        );
  } else {
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
      Buffer.byteLength(
        text,
        "utf8",
      ) >
      MAX_PUBLIC_KEY_RESPONSE_BYTES
    ) {
      throw createError(
        "AdMob public key response is too large.",
        "ADMOB_PUBLIC_KEY_RESPONSE_INVALID",
      );
    }
  }


  // ==========================================================
  // RESPONSE VALIDATION
  // ==========================================================

  if (
    typeof text !==
      "string" ||
    text.length ===
      0
  ) {
    throw createError(
      "AdMob public key response is empty.",
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
// 🔑 VALIDATE ADMOB PUBLIC KEY
// ============================================================

function validateAdMobPublicKey(
  pem,
) {
  if (
    typeof pem !==
      "string"
  ) {
    return false;
  }

  const value =
    pem.trim();

  if (
    value.length ===
    0
  ) {
    return false;
  }

  try {
    const publicKey =
      crypto.createPublicKey(
        value,
      );

    if (
      publicKey.asymmetricKeyType !==
      "ec"
    ) {
      return false;
    }

    const details =
      publicKey.asymmetricKeyDetails;

    if (
      details &&
      details.namedCurve &&
      details.namedCurve !==
        "prime256v1"
    ) {
      return false;
    }

    return true;
  } catch (error) {
    return false;
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
  // PREVENT CONCURRENT FETCHES
  // ==========================================================
  //
  // Jos toinen request lataa jo avaimia, käytetään samaa
  // Promisea. Tämä estää useita yhtäaikaisia key-server
  // pyyntöjä Cloud Functions -instanssissa.
  //
  // ==========================================================

  if (
    publicKeyFetchPromise
  ) {
    return publicKeyFetchPromise;
  }


  // ==========================================================
  // FETCH
  // ==========================================================

  publicKeyFetchPromise =
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


      const keys =
        new Map();


      // ======================================================
      // PARSE KEYS
      // ======================================================

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


        if (
          !validateAdMobPublicKey(
            pem,
          )
        ) {
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


      // ======================================================
      // NO KEYS
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
      // UPDATE CACHE
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
// Siksi raw-queryä EI saa rakentaa uudelleen
// URLSearchParamsin, objektin tai muun normalisoinnin avulla
// ennen kryptografista tarkistusta.
//
// Google dokumentoi, että allekirjoitettavaa sisältöä
// ei saa muuttaa eikä parametrien järjestystä saa muuttaa.
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


  // ==========================================================
  // PREFER RAW URL
  // ==========================================================
  //
  // rawUrl säilyttää mahdollisimman suoraan alkuperäisen
  // callback URL:n.
  //
  // Muut vaihtoehdot toimivat fallbackina eri HTTP/Firebase
  // ympäristöissä.
  //
  // ==========================================================

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
      if (
        query.length >
        MAX_RAW_QUERY_STRING_LENGTH
      ) {
        throw createError(
          "AdMob SSV query string is too long.",
          "ADMOB_INVALID_SIGNATURE",
        );
      }

      return query;
    }
  }


  // ==========================================================
  // FALLBACK: PARSED URL
  // ==========================================================

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

      if (
        query.length >
        MAX_RAW_QUERY_STRING_LENGTH
      ) {
        throw createError(
          "AdMob SSV query string is too long.",
          "ADMOB_INVALID_SIGNATURE",
        );
      }

      return query;
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
// AdMob SSV:
//
// ...&signature=...&key_id=...
//
// Google dokumentoi, että signature ja key_id ovat kaksi
// viimeistä query-parametria tässä järjestyksessä.
//
// Niitä edeltävä raw-query muodostaa kryptografisesti
// allekirjoitetun sisällön.
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


  const signaturePart =
    parts[
      parts.length - 2
    ];

  const keyIdPart =
    parts[
      parts.length - 1
    ];


  // ==========================================================
  // SIGNATURE = SECOND-TO-LAST
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
  // KEY_ID = LAST
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
  // URL-DECODE SIGNATURE AND KEY ID
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
  // KEY ID VALIDATION
  // ==========================================================

  if (
    keyId.length ===
      0 ||
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
  // SIGNATURE VALIDATION
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
  // Poistetaan vain kaksi viimeistä parametria.
  //
  // Kaikki aiemmat merkit säilyvät muuttumattomina.
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
// 🔎 ENSURE UNIQUE PARAMETER
// ============================================================

function ensureUniqueParameter(
  params,
  name,
) {
  if (
    !params ||
    typeof params.getAll !==
      "function"
  ) {
    throw createError(
      "AdMob SSV parameters are invalid.",
      "ADMOB_REQUIRED_PARAMETER_MISSING",
    );
  }


  const values =
    params.getAll(
      name,
    );


  if (
    values.length !==
    1
  ) {
    const error =
      createError(
        `AdMob SSV parameter "${name}" must occur exactly once.`,
        "ADMOB_REQUIRED_PARAMETER_MISSING",
      );

    error.parameter =
      name;

    throw error;
  }


  return values[0];
}


// ============================================================
// 🛡️ VALIDATE PARAMETER STRUCTURE
// ============================================================
//
// AdMobin SSV-parametrit:
//
// ad_network
// ad_unit
// custom_data      optional AdMobin näkökulmasta
// key_id
// reward_amount
// reward_item
// signature
// timestamp
// transaction_id
// user_id          optional
//
// Stelluriini vaatii custom_data:n, koska sen avulla
// callback yhdistetään käyttäjään ja reward-purposeen.
//
// ============================================================

function validateParameterStructure(
  params,
) {
  const requiredNames = [
    "ad_network",
    "ad_unit",
    "custom_data",
    "reward_amount",
    "reward_item",
    "timestamp",
    "transaction_id",
  ];


  for (
    const name of requiredNames
  ) {
    ensureUniqueParameter(
      params,
      name,
    );
  }


  // ==========================================================
  // OPTIONAL USER ID
  // ==========================================================

  const userIdValues =
    params.getAll(
      "user_id",
    );


  if (
    userIdValues.length >
    1
  ) {
    const error =
      createError(
        'AdMob SSV parameter "user_id" must occur at most once.',
        "ADMOB_REQUIRED_PARAMETER_MISSING",
      );

    error.parameter =
      "user_id";

    throw error;
  }


  // ==========================================================
  // SIGNATURE
  // ==========================================================

  const signatureValues =
    params.getAll(
      "signature",
    );


  if (
    signatureValues.length !==
    1
  ) {
    throw createError(
      'AdMob SSV parameter "signature" must occur exactly once.',
      "ADMOB_INVALID_SIGNATURE",
    );
  }


  // ==========================================================
  // KEY ID
  // ==========================================================

  const keyIdValues =
    params.getAll(
      "key_id",
    );


  if (
    keyIdValues.length !==
    1
  ) {
    throw createError(
      'AdMob SSV parameter "key_id" must occur exactly once.',
      "ADMOB_INVALID_KEY_ID",
    );
  }


  return true;
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


  // ==========================================================
  // KEY ROTATION
  // ==========================================================
  //
  // Jos key_id ei löydy nykyisestä cacheasta, haetaan
  // public keys välittömästi uudelleen.
  //
  // Tämä auttaa key rotation -tilanteissa.
  //
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
  //
  // AdMob SSV käyttää ECDSA-pohjaista allekirjoitusta.
  //
  // Node.js crypto.verify:
  //
  // SHA-256
  // + EC public key
  // + DER signature
  //
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
  // PARSE PARAMETERS ONLY AFTER SIGNATURE VERIFICATION
  // ==========================================================
  //
  // URLSearchParamsia käytetään vasta kryptografisen
  // varmistuksen jälkeen.
  //
  // Allekirjoitusta varten käytettiin edelleen alkuperäistä
  // raw-queryä.
  //
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


  // ==========================================================
  // DEFENSE-IN-DEPTH STRUCTURE CHECK
  // ==========================================================

  validateParameterStructure(
    params,
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
    ensureUniqueParameter(
      params,
      name,
    );


  if (
    typeof value !==
      "string" ||
    value.length ===
      0
  ) {
    const error =
      createError(
        `AdMob SSV required parameter "${name}" is empty.`,
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
// URLSearchParams purkaa percent-encodingin ennen
// tämän funktion kutsua.
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
    !VALID_REWARD_PURPOSES.has(
      rewardPurpose,
    )
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
// AdMob dokumentoi transaction_id:n yksilölliseksi
// hex-koodatuksi tunnisteeksi jokaiselle reward grant
// -tapahtumalle.
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
//
// AdMob timestamp on Epoch time in milliseconds.
//
// Emme käytä tässä vanhentumisaikaa, koska SSV callback
// voi saapua viiveellä.
//
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
//
// AdMob ad_network on numeerinen ad source identifier.
//
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
//
// Tämä on service-tason pääfunktio.
//
// Se:
//
// 1. varmistaa kryptografisen allekirjoituksen
// 2. lukee SSV-parametrit
// 3. tarkistaa reward-purposen
// 4. tarkistaa ad unitin
// 5. tarkistaa reward amountin
// 6. tarkistaa reward itemin
// 7. tarkistaa UID:n
// 8. tarkistaa transaction ID:n
// 9. tarkistaa timestampin
// 10. tarkistaa mahdollisen user_id:n
//
// Se EI vielä käsittele rewardia.
//
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
    !VALID_REWARD_PURPOSES.has(
      rewardPurpose,
    )
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
      "AdMob verified signature value is missing or invalid.",
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