"use strict";

// ============================================================
// 🐱 STELLURIINI — ADMOB SSV SERVICE
// ============================================================
//
// Responsible for:
//
// - Receiving raw AdMob SSV callback data
// - Loading Google's AdMob verification keys
// - Selecting the correct public key by key_id
// - Verifying the ORIGINAL callback query
// - Validating callback parameters
// - Extracting Stelluriini UID
// - Extracting Stelluriini reward purpose
//
// IMPORTANT:
//
// Google signs the ORIGINAL query string.
//
// The signed query string MUST NOT be:
//
// ❌ reconstructed
// ❌ reordered
// ❌ decoded and re-encoded
// ❌ passed through URLSearchParams before verification
//
// URLSearchParams is used ONLY AFTER cryptographic verification.
//
// ============================================================


// ============================================================
// 🔐 CRYPTO / HTTPS
// ============================================================

const crypto = require("crypto");
const https = require("https");


// ============================================================
// ⚙️ CONFIGURATION
// ============================================================

const ADMOB_PUBLIC_KEYS_URL =
  "https://www.gstatic.com/admob/reward/verifier-keys.json";


// Google's keys may rotate.
// Keeping a 1-hour cache is safely below Google's maximum
// recommended cache lifetime of 24 hours.
//

const KEY_CACHE_TTL_MS =
  60 * 60 * 1000;


// Maximum allowed clock difference into the future.
//
// AdMob timestamp is Epoch milliseconds.
//

const MAX_TIMESTAMP_FUTURE_MS =
  5 * 60 * 1000;


// Maximum callback age.
//
// We allow 24 hours for delayed/retried callbacks.
//

const MAX_TIMESTAMP_AGE_MS =
  24 * 60 * 60 * 1000;


// ============================================================
// 🎯 VALID REWARD PURPOSES
// ============================================================
//
// These values must match the Stelluriini client/server flow.
//
// custom_data:
//
// UID:mining_start
//
// UID:power_boost
//
// ============================================================

const VALID_REWARD_PURPOSES =
  new Set([
    "mining_start",
    "power_boost",
  ]);


// ============================================================
// 🔑 KEY CACHE
// ============================================================

let cachedKeys =
  new Map();

let cachedKeysLoadedAt =
  0;


// ============================================================
// 📝 LOGGING
// ============================================================

function log(
  message,
  data = {},
) {
  console.log(
    `🐱 ${message}`,
    data,
  );
}


function logError(
  message,
  data = {},
) {
  console.error(
    `🐱❌ ${message}`,
    data,
  );
}


// ============================================================
// 🧹 NORMALIZE STRING
// ============================================================

function normalizeString(
  value,
) {
  if (
    typeof value !==
    "string"
  ) {
    return "";
  }

  return value.trim();
}


// ============================================================
// 🆔 VALIDATE UID
// ============================================================

function validateUid(
  value,
) {
  if (
    typeof value !==
    "string"
  ) {
    return "";
  }

  const uid =
    value.trim();

  if (
    uid.length === 0 ||
    uid.length > 128
  ) {
    return "";
  }

  if (
    !/^[A-Za-z0-9._-]+$/.test(
      uid,
    )
  ) {
    return "";
  }

  return uid;
}


// ============================================================
// 🎯 VALIDATE REWARD PURPOSE
// ============================================================

function validateRewardPurpose(
  value,
) {
  if (
    typeof value !==
    "string"
  ) {
    return "";
  }

  const rewardPurpose =
    value.trim();

  if (
    !VALID_REWARD_PURPOSES.has(
      rewardPurpose,
    )
  ) {
    return "";
  }

  return rewardPurpose;
}


// ============================================================
// 🆔 VALIDATE TRANSACTION ID
// ============================================================
//
// Google documents transaction_id as a unique hex encoded
// identifier for each reward grant event.
//
// ============================================================

function validateTransactionId(
  value,
) {
  if (
    typeof value !==
    "string"
  ) {
    return "";
  }

  const transactionId =
    value.trim();

  if (
    transactionId.length === 0 ||
    transactionId.length > 256
  ) {
    return "";
  }

  if (
    !/^[A-Fa-f0-9]+$/.test(
      transactionId,
    )
  ) {
    return "";
  }

  return transactionId;
}


// ============================================================
// 🔐 HTTP GET JSON
// ============================================================

function httpGetJson(
  url,
) {
  return new Promise(
    (
      resolve,
      reject,
    ) => {
      const request =
        https.get(
          url,
          {
            headers: {
              Accept:
                "application/json",

              "User-Agent":
                "Stelluriini-AdMob-SSV/1.0",
            },
          },
          (
            response,
          ) => {
            let body =
              "";

            response.setEncoding(
              "utf8",
            );

            response.on(
              "data",
              (
                chunk,
              ) => {
                body +=
                  chunk;
              },
            );

            response.on(
              "end",
              () => {
                if (
                  response.statusCode !==
                  200
                ) {
                  const error =
                    new Error(
                      `AdMob public key server returned HTTP ${response.statusCode}`,
                    );

                  error.code =
                    "ADMOB_PUBLIC_KEY_HTTP_ERROR";

                  reject(
                    error,
                  );

                  return;
                }

                try {
                  const json =
                    JSON.parse(
                      body,
                    );

                  resolve(
                    json,
                  );
                } catch (
                  error
                ) {
                  const parseError =
                    new Error(
                      `Failed to parse AdMob public key response: ${error.message}`,
                    );

                  parseError.code =
                    "ADMOB_PUBLIC_KEY_JSON_ERROR";

                  reject(
                    parseError,
                  );
                }
              },
            );
          },
        );


      request.on(
        "error",
        (
          error,
        ) => {
          const requestError =
            new Error(
              `Failed to fetch AdMob public keys: ${error.message}`,
            );

          requestError.code =
            "ADMOB_PUBLIC_KEY_FETCH_ERROR";

          reject(
            requestError,
          );
        },
      );


      request.setTimeout(
        15000,
        () => {
          const timeoutError =
            new Error(
              "AdMob public key request timed out.",
            );

          timeoutError.code =
            "ADMOB_PUBLIC_KEY_FETCH_ERROR";

          request.destroy(
            timeoutError,
          );
        },
      );
    },
  );
}


// ============================================================
// 🔑 LOAD ADMOB PUBLIC KEYS
// ============================================================

async function loadAdMobPublicKeys(
  forceRefresh = false,
) {
  const now =
    Date.now();


  // ----------------------------------------------------------
  // CACHE
  // ----------------------------------------------------------

  if (
    !forceRefresh &&
    cachedKeys.size > 0 &&
    now -
      cachedKeysLoadedAt <
      KEY_CACHE_TTL_MS
  ) {
    return cachedKeys;
  }


  log(
    "AdMob public keys loading.",
  );


  let response;

  try {
    response =
      await httpGetJson(
        ADMOB_PUBLIC_KEYS_URL,
      );
  } catch (
    error
  ) {
    throw error;
  }


  // ----------------------------------------------------------
  // RESPONSE VALIDATION
  // ----------------------------------------------------------

  if (
    !response ||
    !Array.isArray(
      response.keys,
    )
  ) {
    const error =
      new Error(
        "Invalid AdMob public key response.",
      );

    error.code =
      "ADMOB_PUBLIC_KEY_RESPONSE_INVALID";

    throw error;
  }


  const newKeys =
    new Map();


  // ----------------------------------------------------------
  // PARSE KEYS
  // ----------------------------------------------------------

  for (
    const key of response.keys
  ) {
    if (
      !key
    ) {
      continue;
    }


    const keyId =
      String(
        key.keyId ??
          "",
      ).trim();


    if (
      !/^\d+$/.test(
        keyId,
      )
    ) {
      continue;
    }


    const pem =
      typeof key.pem ===
        "string" &&
      key.pem.trim().length >
        0
        ? key.pem.trim()
        : null;


    const base64 =
      typeof key.base64 ===
        "string" &&
      key.base64.trim().length >
        0
        ? key.base64.trim()
        : null;


    let publicKeyPem =
      pem;


    // --------------------------------------------------------
    // BASE64 → SPKI PEM
    // --------------------------------------------------------

    if (
      !publicKeyPem &&
      base64
    ) {
      try {
        const keyObject =
          crypto.createPublicKey(
            {
              key:
                Buffer.from(
                  base64,
                  "base64",
                ),

              format:
                "der",

              type:
                "spki",
            },
          );


        publicKeyPem =
          keyObject.export(
            {
              type:
                "spki",

              format:
                "pem",
            },
          );
      } catch (
        error
      ) {
        logError(
          "Failed to convert AdMob base64 public key.",
          {
            keyId,

            error:
              error.message,
          },
        );

        continue;
      }
    }


    if (
      !publicKeyPem
    ) {
      continue;
    }


    // --------------------------------------------------------
    // VERIFY THAT NODE CAN PARSE THE KEY
    // --------------------------------------------------------

    try {
      crypto.createPublicKey(
        publicKeyPem,
      );
    } catch (
      error
    ) {
      logError(
        "Invalid AdMob public key skipped.",
        {
          keyId,

          error:
            error.message,
        },
      );

      continue;
    }


    newKeys.set(
      keyId,
      publicKeyPem,
    );
  }


  // ----------------------------------------------------------
  // NO USABLE KEYS
  // ----------------------------------------------------------

  if (
    newKeys.size ===
    0
  ) {
    const error =
      new Error(
        "No usable AdMob public keys were loaded.",
      );

    error.code =
      "ADMOB_PUBLIC_KEYS_EMPTY";

    throw error;
  }


  // ----------------------------------------------------------
  // UPDATE CACHE
  // ----------------------------------------------------------

  cachedKeys =
    newKeys;

  cachedKeysLoadedAt =
    now;


  log(
    "AdMob public keys loaded.",
    {
      count:
        cachedKeys.size,

      keyIds:
        Array.from(
          cachedKeys.keys(),
        ),
    },
  );


  return cachedKeys;
}


// ============================================================
// 🔎 GET ORIGINAL RAW QUERY STRING
// ============================================================
//
// IMPORTANT:
//
// req.url must be used before any query reconstruction.
//
// ============================================================

function getRawQueryString(
  req,
) {
  if (
    !req
  ) {
    return "";
  }


  const requestUrl =
    typeof req.url ===
      "string" &&
    req.url.length >
      0
      ? req.url
      : typeof req.originalUrl ===
          "string" &&
        req.originalUrl.length >
          0
        ? req.originalUrl
        : "";


  const questionMarkIndex =
    requestUrl.indexOf(
      "?",
    );


  if (
    questionMarkIndex ===
    -1
  ) {
    return "";
  }


  return requestUrl.substring(
    questionMarkIndex +
      1,
  );
}


// ============================================================
// 🔐 EXTRACT SIGNATURE / KEY ID
// ============================================================
//
// Google specifies that the final two parameters are:
//
// signature
// key_id
//
// in exactly that order.
//
// The signed data is everything BEFORE:
//
// &signature=
//
// ============================================================

function extractSignatureAndKeyId(
  rawQuery,
) {
  if (
    typeof rawQuery !==
      "string" ||
    rawQuery.length ===
      0
  ) {
    const error =
      new Error(
        "Missing AdMob SSV query string.",
      );

    error.code =
      "ADMOB_QUERY_STRING_MISSING";

    throw error;
  }


  const signatureMarker =
    "&signature=";


  const signatureStart =
    rawQuery.lastIndexOf(
      signatureMarker,
    );


  if (
    signatureStart ===
    -1
  ) {
    const error =
      new Error(
        "Missing AdMob SSV signature parameter.",
      );

    error.code =
      "ADMOB_REQUIRED_PARAMETER_MISSING";

    throw error;
  }


  const dataToVerify =
    rawQuery.substring(
      0,
      signatureStart,
    );


  const signatureAndKeyId =
    rawQuery.substring(
      signatureStart +
        1,
    );


  if (
    !signatureAndKeyId.startsWith(
      "signature=",
    )
  ) {
    const error =
      new Error(
        "Invalid AdMob SSV signature section.",
      );

    error.code =
      "ADMOB_INVALID_SIGNATURE";

    throw error;
  }


  const keyIdMarker =
    "&key_id=";


  const keyIdIndex =
    signatureAndKeyId.indexOf(
      keyIdMarker,
    );


  if (
    keyIdIndex ===
    -1
  ) {
    const error =
      new Error(
        "Missing AdMob SSV key_id parameter.",
      );

    error.code =
      "ADMOB_INVALID_KEY_ID";

    throw error;
  }


  const encodedSignature =
    signatureAndKeyId.substring(
      "signature=".length,
      keyIdIndex,
    );


  const encodedKeyId =
    signatureAndKeyId.substring(
      keyIdIndex +
        keyIdMarker.length,
    );


  // ----------------------------------------------------------
  // key_id MUST be the final parameter.
  // ----------------------------------------------------------

  if (
    encodedKeyId.includes(
      "&",
    )
  ) {
    const error =
      new Error(
        "AdMob SSV key_id must be the final query parameter.",
      );

    error.code =
      "ADMOB_INVALID_KEY_ID";

    throw error;
  }


  if (
    encodedSignature.length ===
    0
  ) {
    const error =
      new Error(
        "AdMob SSV signature is empty.",
      );

    error.code =
      "ADMOB_INVALID_SIGNATURE";

    throw error;
  }


  if (
    encodedKeyId.length ===
    0
  ) {
    const error =
      new Error(
        "AdMob SSV key_id is empty.",
      );

    error.code =
      "ADMOB_INVALID_KEY_ID";

    throw error;
  }


  let signature;

  let keyId;


  try {
    // --------------------------------------------------------
    // IMPORTANT:
    //
    // Only signature and key_id are decoded.
    //
    // dataToVerify remains byte-for-byte unchanged.
    // --------------------------------------------------------

    signature =
      decodeURIComponent(
        encodedSignature,
      );

    keyId =
      decodeURIComponent(
        encodedKeyId,
      );
  } catch (
    error
  ) {
    const decodeError =
      new Error(
        `Failed to decode AdMob SSV signature/key_id: ${error.message}`,
      );

    decodeError.code =
      "ADMOB_REQUIRED_PARAMETER_MISSING";

    throw decodeError;
  }


  keyId =
    String(
      keyId,
    ).trim();


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
    dataToVerify,

    signature,

    keyId,
  };
}


// ============================================================
// 🔐 VERIFY ECDSA SIGNATURE
// ============================================================

function verifySignature({
  dataToVerify,
  signature,
  publicKeyPem,
}) {
  if (
    !dataToVerify
  ) {
    const error =
      new Error(
        "No AdMob SSV data available for verification.",
      );

    error.code =
      "ADMOB_CRYPTO_VERIFICATION_ERROR";

    throw error;
  }


  if (
    !signature
  ) {
    const error =
      new Error(
        "No AdMob SSV signature available.",
      );

    error.code =
      "ADMOB_INVALID_SIGNATURE";

    throw error;
  }


  if (
    !publicKeyPem
  ) {
    const error =
      new Error(
        "No AdMob public key available.",
      );

    error.code =
      "ADMOB_PUBLIC_KEY_NOT_FOUND";

    throw error;
  }


  let signatureBuffer;


  try {
    // AdMob uses a URL-safe Base64 signature.
    //
    // Node's base64 decoder accepts the URL-safe
    // '-' and '_' characters, but we normalize explicitly
    // for predictable behavior.

    let normalizedSignature =
      signature
        .replace(
          /-/g,
          "+",
        )
        .replace(
          /_/g,
          "/",
        );


    while (
      normalizedSignature.length %
        4 !==
      0
    ) {
      normalizedSignature +=
        "=";
    }


    signatureBuffer =
      Buffer.from(
        normalizedSignature,
        "base64",
      );
  } catch (
    error
  ) {
    const decodeError =
      new Error(
        `Failed to decode AdMob SSV signature: ${error.message}`,
      );

    decodeError.code =
      "ADMOB_INVALID_SIGNATURE";

    throw decodeError;
  }


  if (
    signatureBuffer.length ===
    0
  ) {
    const error =
      new Error(
        "AdMob SSV signature decoded to an empty buffer.",
      );

    error.code =
      "ADMOB_INVALID_SIGNATURE";

    throw error;
  }


  try {
    return crypto.verify(
      "sha256",

      Buffer.from(
        dataToVerify,
        "utf8",
      ),

      {
        key:
          publicKeyPem,

        dsaEncoding:
          "der",
      },

      signatureBuffer,
    );
  } catch (
    error
  ) {
    const cryptoError =
      new Error(
        `AdMob cryptographic verification failed: ${error.message}`,
      );

    cryptoError.code =
      "ADMOB_CRYPTO_VERIFICATION_ERROR";

    throw cryptoError;
  }
}


// ============================================================
// 📦 PARSE CALLBACK PARAMETERS
// ============================================================
//
// IMPORTANT:
//
// This function is called ONLY AFTER signature verification.
//
// ============================================================

function parseCallbackParameters(
  rawQuery,
) {
  const params =
    new URLSearchParams(
      rawQuery,
    );


  return {
    adNetwork:
      params.get(
        "ad_network",
      ),

    adUnit:
      params.get(
        "ad_unit",
      ),

    customData:
      params.get(
        "custom_data",
      ),

    rewardAmount:
      params.get(
        "reward_amount",
      ),

    rewardItem:
      params.get(
        "reward_item",
      ),

    timestamp:
      params.get(
        "timestamp",
      ),

    transactionId:
      params.get(
        "transaction_id",
      ),

    userId:
      params.get(
        "user_id",
      ),

    signature:
      params.get(
        "signature",
      ),

    keyId:
      params.get(
        "key_id",
      ),
  };
}


// ============================================================
// 🧩 PARSE STELLURIINI CUSTOM DATA
// ============================================================
//
// Expected:
//
// UID:rewardPurpose
//
// Example:
//
// abc123:mining_start
//
// abc123:power_boost
//
// ============================================================

function parseStelluriiniCustomData(
  customData,
) {
  const normalized =
    normalizeString(
      customData,
    );


  if (
    normalized.length ===
      0 ||
    normalized.length >
      256
  ) {
    const error =
      new Error(
        "AdMob custom_data is missing or invalid.",
      );

    error.code =
      "ADMOB_CUSTOM_DATA_MISSING";

    throw error;
  }


  const separatorIndex =
    normalized.indexOf(
      ":",
    );


  if (
    separatorIndex <=
      0 ||
    separatorIndex ===
      normalized.length -
        1
  ) {
    const error =
      new Error(
        "AdMob custom_data does not contain a valid UID and reward purpose.",
      );

    error.code =
      "ADMOB_CUSTOM_DATA_MISSING";

    throw error;
  }


  const uid =
    validateUid(
      normalized.substring(
        0,
        separatorIndex,
      ),
    );


  const rewardPurpose =
    validateRewardPurpose(
      normalized.substring(
        separatorIndex +
          1,
      ),
    );


  if (
    !uid
  ) {
    const error =
      new Error(
        "AdMob custom_data contains an invalid UID.",
      );

    error.code =
      "ADMOB_INVALID_UID";

    throw error;
  }


  if (
    !rewardPurpose
  ) {
    const error =
      new Error(
        "AdMob custom_data contains an invalid reward purpose.",
      );

    error.code =
      "ADMOB_INVALID_REWARD_PURPOSE";

    throw error;
  }


  return {
    uid,

    rewardPurpose,

    customData:
      normalized,
  };
}


// ============================================================
// 🛡️ VALIDATE CALLBACK
// ============================================================

function validateCallbackParameters(
  callback,
) {
  if (
    !callback
  ) {
    const error =
      new Error(
        "AdMob SSV callback data is missing.",
      );

    error.code =
      "ADMOB_REQUIRED_PARAMETER_MISSING";

    throw error;
  }


  // ----------------------------------------------------------
  // TRANSACTION ID
  // ----------------------------------------------------------

  const transactionId =
    validateTransactionId(
      callback.transactionId,
    );


  if (
    !transactionId
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
  // CUSTOM DATA
  // ----------------------------------------------------------
  //
  // Stelluriini requires custom_data because it contains:
  //
  // UID:rewardPurpose
  //
  // ----------------------------------------------------------

  const customData =
    normalizeString(
      callback.customData,
    );


  if (
    !customData
  ) {
    const error =
      new Error(
        "AdMob SSV custom_data is missing.",
      );

    error.code =
      "ADMOB_CUSTOM_DATA_MISSING";

    throw error;
  }


  const stelluriiniData =
    parseStelluriiniCustomData(
      customData,
    );


  // ----------------------------------------------------------
  // TIMESTAMP
  // ----------------------------------------------------------
  //
  // IMPORTANT:
  //
  // Google documents timestamp as Epoch milliseconds.
  //
  // ----------------------------------------------------------

  const timestamp =
    Number(
      callback.timestamp,
    );


  if (
    !Number.isSafeInteger(
      timestamp,
    ) ||
    timestamp <=
      0
  ) {
    const error =
      new Error(
        "AdMob SSV timestamp is invalid.",
      );

    error.code =
      "ADMOB_INVALID_TIMESTAMP";

    throw error;
  }


  const now =
    Date.now();


  if (
    timestamp >
    now +
      MAX_TIMESTAMP_FUTURE_MS
  ) {
    const error =
      new Error(
        "AdMob SSV timestamp is in the future.",
      );

    error.code =
      "ADMOB_INVALID_TIMESTAMP";

    throw error;
  }


  if (
    now -
      timestamp >
    MAX_TIMESTAMP_AGE_MS
  ) {
    const error =
      new Error(
        "AdMob SSV callback is too old.",
      );

    error.code =
      "ADMOB_INVALID_TIMESTAMP";

    throw error;
  }


  // ----------------------------------------------------------
  // AD NETWORK
  // ----------------------------------------------------------

  const adNetwork =
    normalizeString(
      callback.adNetwork,
    );


  if (
    adNetwork.length ===
      0 ||
    adNetwork.length >
      32 ||
    !/^\d+$/.test(
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
  // AD UNIT
  // ----------------------------------------------------------

  const adUnit =
    normalizeString(
      callback.adUnit,
    );


  if (
    adUnit.length ===
    0
  ) {
    const error =
      new Error(
        "AdMob SSV ad_unit is missing.",
      );

    error.code =
      "ADMOB_INVALID_AD_UNIT";

    throw error;
  }


  // ----------------------------------------------------------
  // REWARD AMOUNT
  // ----------------------------------------------------------

  const rewardAmount =
    Number(
      callback.rewardAmount,
    );


  if (
    !Number.isSafeInteger(
      rewardAmount,
    ) ||
    rewardAmount <
      0
  ) {
    const error =
      new Error(
        "AdMob SSV reward_amount is invalid.",
      );

    error.code =
      "ADMOB_INVALID_REWARD_AMOUNT";

    throw error;
  }


  // ----------------------------------------------------------
  // REWARD ITEM
  // ----------------------------------------------------------

  const rewardItem =
    normalizeString(
      callback.rewardItem,
    );


  if (
    rewardItem.length ===
    0
  ) {
    const error =
      new Error(
        "AdMob SSV reward_item is missing.",
      );

    error.code =
      "ADMOB_INVALID_REWARD_ITEM";

    throw error;
  }


  // ----------------------------------------------------------
  // USER ID
  // ----------------------------------------------------------
  //
  // user_id is optional in Google's SSV callback.
  //
  // Stelluriini can operate using custom_data.
  //
  // If user_id exists, it MUST match the UID encoded
  // in custom_data.
  //
  // ----------------------------------------------------------

  const rawUserId =
    normalizeString(
      callback.userId,
    );


  let userId =
    "";


  if (
    rawUserId
  ) {
    userId =
      validateUid(
        rawUserId,
      );


    if (
      !userId
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
      stelluriiniData.uid
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


  return {
    transactionId,

    uid:
      stelluriiniData.uid,

    rewardPurpose:
      stelluriiniData.rewardPurpose,

    customData:
      stelluriiniData.customData,

    userId,

    adNetwork,

    adUnit,

    rewardAmount,

    rewardItem,

    timestamp,
  };
}


// ============================================================
// 🔐 MAIN VERIFICATION FUNCTION
// ============================================================

async function verifyAdMobCallback(
  req,
) {
  try {
    // ========================================================
    // 1. ORIGINAL RAW QUERY
    // ========================================================

    const rawQuery =
      getRawQueryString(
        req,
      );


    log(
      "AdMob SSV raw callback received.",
      {
        length:
          rawQuery.length,

        hasSignature:
          rawQuery.includes(
            "signature=",
          ),

        hasKeyId:
          rawQuery.includes(
            "key_id=",
          ),
      },
    );


    if (
      !rawQuery
    ) {
      const error =
        new Error(
          "AdMob SSV callback contains no query string.",
        );

      error.code =
        "ADMOB_QUERY_STRING_MISSING";

      throw error;
    }


    // ========================================================
    // 2. EXTRACT SIGNATURE / KEY ID
    // ========================================================

    const {
      dataToVerify,

      signature,

      keyId,
    } =
      extractSignatureAndKeyId(
        rawQuery,
      );


    log(
      "AdMob SSV query parsed.",
      {
        signedDataLength:
          dataToVerify.length,

        signatureLength:
          signature.length,

        keyId,
      },
    );


    // ========================================================
    // 3. LOAD PUBLIC KEYS
    // ========================================================

    let publicKeys =
      await loadAdMobPublicKeys(
        false,
      );


    let publicKeyPem =
      publicKeys.get(
        keyId,
      );


    // ========================================================
    // 4. KEY ROTATION
    // ========================================================

    if (
      !publicKeyPem
    ) {
      log(
        "AdMob SSV key_id not found in cache. Refreshing keys.",
        {
          keyId,
        },
      );


      publicKeys =
        await loadAdMobPublicKeys(
          true,
        );


      publicKeyPem =
        publicKeys.get(
          keyId,
        );
    }


    if (
      !publicKeyPem
    ) {
      const error =
        new Error(
          `No AdMob public key found for key_id ${keyId}.`,
        );

      error.code =
        "ADMOB_PUBLIC_KEY_NOT_FOUND";

      error.keyId =
        keyId;

      throw error;
    }


    // ========================================================
    // 5. CRYPTOGRAPHIC VERIFICATION
    // ========================================================

    const signatureValid =
      verifySignature({
        dataToVerify,

        signature,

        publicKeyPem,
      });


    if (
      !signatureValid
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


    log(
      "AdMob SSV signature verified successfully.",
      {
        keyId,
      },
    );


    // ========================================================
    // 6. PARSE PARAMETERS
    // ========================================================
    //
    // IMPORTANT:
    //
    // Signature verification has already completed.
    //
    // URLSearchParams is safe here because it is NOT used
    // to construct the signed data.
    //
    // ========================================================

    const callback =
      parseCallbackParameters(
        rawQuery,
      );


    // ========================================================
    // 7. VALIDATE CALLBACK
    // ========================================================

    const validated =
      validateCallbackParameters(
        callback,
      );


    // ========================================================
    // 8. RETURN VERIFIED DATA
    // ========================================================

    return {
      verified:
        true,

      code:
        "ADMOB_SSV_VERIFIED",

      // ------------------------------------------------------
      // Stelluriini-specific identity
      // ------------------------------------------------------

      uid:
        validated.uid,

      rewardPurpose:
        validated.rewardPurpose,

      // ------------------------------------------------------
      // AdMob data
      // ------------------------------------------------------

      keyId,

      transactionId:
        validated.transactionId,

      userId:
        validated.userId,

      adNetwork:
        validated.adNetwork,

      adUnit:
        validated.adUnit,

      customData:
        validated.customData,

      rewardAmount:
        validated.rewardAmount,

      rewardItem:
        validated.rewardItem,

      timestamp:
        validated.timestamp,

      signature,

      // ------------------------------------------------------
      // Diagnostics / audit
      // ------------------------------------------------------
      //
      // This MUST NOT be used to reconstruct the signature.
      //
      rawQuery,
    };
  } catch (
    error
  ) {
    const code =
      error &&
      error.code
        ? error.code
        : "ADMOB_SSV_VERIFICATION_FAILED";


    logError(
      "AdMob SSV signature verification FAILED.",
      {
        code,

        keyId:
          error &&
          error.keyId
            ? error.keyId
            : null,

        message:
          error &&
          error.message
            ? error.message
            : "Unknown AdMob SSV error.",
      },
    );


    return {
      verified:
        false,

      code,

      message:
        error &&
        error.message
          ? error.message
          : "AdMob SSV verification failed.",

      keyId:
        error &&
        error.keyId
          ? error.keyId
          : null,
    };
  }
}


// ============================================================
// 📦 EXPORTS
// ============================================================

module.exports = {
  verifyAdMobCallback,

  loadAdMobPublicKeys,

  getRawQueryString,

  extractSignatureAndKeyId,

  parseCallbackParameters,

  validateCallbackParameters,

  parseStelluriiniCustomData,

  validateUid,

  validateTransactionId,

  validateRewardPurpose,
};