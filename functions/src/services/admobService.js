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
// - Parsing verified callback parameters
// - Deriving UID / reward purpose from signed custom_data
// - Validating callback timestamp
//
// IMPORTANT:
//
// The query string used for signature verification MUST NOT be
// reconstructed from URLSearchParams or decoded/re-encoded values.
//
// Google signs the original query string exactly as sent.
//
// ============================================================

const crypto = require("crypto");
const https = require("https");


// ============================================================
// ⚙️ MINING CONFIG
// ============================================================
//
// AdMob configuration has one canonical source.
//
// admobService.js exposes the configuration to adFunctions.js,
// but does not duplicate the actual values here.
//
// ============================================================

const {
  ADMOB_MINING_SSV_AD_UNIT_ID,
  ADMOB_POWER_BOOST_SSV_AD_UNIT_ID,

  ADMOB_MINING_SSV_REWARD_ITEM,
  ADMOB_MINING_SSV_REWARD_AMOUNT,

  ADMOB_POWER_BOOST_SSV_REWARD_ITEM,
  ADMOB_POWER_BOOST_SSV_REWARD_AMOUNT,
} = require(
  "../config/miningConfig",
);


// ============================================================
// 🎯 CENTRALIZED ADMOB CONFIGURATION
// ============================================================

const ADMOB_AD_UNITS = {
  mining_start:
    ADMOB_MINING_SSV_AD_UNIT_ID,

  power_boost:
    ADMOB_POWER_BOOST_SSV_AD_UNIT_ID,
};


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
// 🔐 ADMOB PUBLIC KEY SERVER
// ============================================================

const ADMOB_PUBLIC_KEYS_URL =
  "https://www.gstatic.com/admob/reward/verifier-keys.json";


// ============================================================
// ⏱️ PUBLIC KEY CACHE
// ============================================================
//
// Google recommends caching the keys, but not longer than
// 24 hours because keys can rotate.
//
// One hour is intentionally used here.
//
// ============================================================

const KEY_CACHE_TTL_MS =
  60 * 60 * 1000;


// ============================================================
// ⏱️ TIMESTAMP VALIDATION
// ============================================================
//
// IMPORTANT:
//
// AdMob timestamp is Epoch time in MILLISECONDS.
//
// Example:
//
// 1507770365237823
//
// ============================================================

const MAX_TIMESTAMP_AGE_MS =
  24 * 60 * 60 * 1000;

const MAX_FUTURE_SKEW_MS =
  5 * 60 * 1000;


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
// ❗ ERROR FACTORY
// ============================================================

function createError(
  code,
  message,
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
// 🌐 HTTP GET JSON
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
                  reject(
                    createError(
                      "ADMOB_PUBLIC_KEY_HTTP_ERROR",

                      `AdMob public key server returned HTTP ${response.statusCode}.`,
                    ),
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
                  reject(
                    createError(
                      "ADMOB_PUBLIC_KEY_JSON_ERROR",

                      `Failed to parse AdMob public key response: ${error.message}`,
                    ),
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
          const wrappedError =
            createError(
              "ADMOB_PUBLIC_KEY_FETCH_ERROR",

              `Failed to fetch AdMob public keys: ${error.message}`,
            );

          reject(
            wrappedError,
          );
        },
      );


      request.setTimeout(
        15000,
        () => {
          request.destroy(
            new Error(
              "AdMob public key request timed out",
            ),
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


  if (
    !response ||
    !Array.isArray(
      response.keys,
    )
  ) {
    throw createError(
      "ADMOB_PUBLIC_KEY_RESPONSE_INVALID",

      "Invalid AdMob public key response.",
    );
  }


  const newKeys =
    new Map();


  for (
    const key of response.keys
  ) {
    if (
      key == null
    ) {
      continue;
    }


    const keyId =
      String(
        key.keyId ??
          "",
      ).trim();


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


    if (
      !keyId
    ) {
      continue;
    }


    let publicKeyPem =
      pem;


    // --------------------------------------------------------
    // Google's response normally contains PEM.
    //
    // If PEM is missing but base64 DER SPKI exists, convert
    // it to PEM.
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


    newKeys.set(
      keyId,
      publicKeyPem,
    );
  }


  if (
    newKeys.size ===
    0
  ) {
    throw createError(
      "ADMOB_PUBLIC_KEYS_EMPTY",

      "No usable AdMob public keys were loaded.",
    );
  }


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
// NEVER use URLSearchParams before cryptographic verification.
//
// NEVER decode and reconstruct the query.
//
// NEVER sort parameters.
//
// NEVER re-encode values.
//
// The exact query string received from AdMob is what is verified.
//
// ============================================================

function getRawQueryString(
  req,
) {
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
    questionMarkIndex + 1,
  );
}


// ============================================================
// 🔐 EXTRACT SIGNATURE / KEY ID
// ============================================================
//
// Google specifies:
//
// ...&signature=...&key_id=...
//
// The content before "&signature=" is the exact signed data.
//
// ============================================================

function extractSignatureAndKeyId(
  rawQuery,
) {
  if (
    !rawQuery
  ) {
    throw createError(
      "ADMOB_QUERY_STRING_MISSING",

      "Missing AdMob SSV query string.",
    );
  }


  const signatureMarker =
    "&signature=";


  const signatureStart =
    rawQuery.indexOf(
      signatureMarker,
    );


  if (
    signatureStart ===
    -1
  ) {
    throw createError(
      "ADMOB_REQUIRED_PARAMETER_MISSING",

      "Missing AdMob SSV signature parameter.",
    );
  }


  // ----------------------------------------------------------
  // Everything before "&signature=" is the ORIGINAL signed
  // content.
  // ----------------------------------------------------------

  const dataToVerify =
    rawQuery.substring(
      0,
      signatureStart,
    );


  const signatureAndKeyId =
    rawQuery.substring(
      signatureStart + 1,
    );


  if (
    !signatureAndKeyId.startsWith(
      "signature=",
    )
  ) {
    throw createError(
      "ADMOB_REQUIRED_PARAMETER_MISSING",

      "Invalid AdMob SSV signature section.",
    );
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
    throw createError(
      "ADMOB_REQUIRED_PARAMETER_MISSING",

      "Missing AdMob SSV key_id parameter.",
    );
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
  // key_id must be the FINAL query parameter.
  // ----------------------------------------------------------

  if (
    encodedKeyId.includes(
      "&",
    )
  ) {
    throw createError(
      "ADMOB_REQUIRED_PARAMETER_MISSING",

      "AdMob SSV key_id must be the final query parameter.",
    );
  }


  if (
    !encodedSignature
  ) {
    throw createError(
      "ADMOB_INVALID_SIGNATURE",

      "AdMob SSV signature is empty.",
    );
  }


  if (
    !encodedKeyId
  ) {
    throw createError(
      "ADMOB_INVALID_KEY_ID",

      "AdMob SSV key_id is empty.",
    );
  }


  let signature;

  let keyId;


  try {
    // --------------------------------------------------------
    // Decode ONLY signature and key_id.
    //
    // dataToVerify remains untouched.
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
    throw createError(
      "ADMOB_REQUIRED_PARAMETER_MISSING",

      `Failed to decode AdMob SSV signature/key_id: ${error.message}`,
    );
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
    throw createError(
      "ADMOB_INVALID_KEY_ID",

      "AdMob SSV key_id is invalid.",
    );
  }


  if (
    keyId.length >
    32
  ) {
    throw createError(
      "ADMOB_INVALID_KEY_ID",

      "AdMob SSV key_id is too long.",
    );
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
//
// AdMob SSV:
//
// ECDSA
// SHA-256
// DER encoding
//
// ============================================================

function verifySignature({
  dataToVerify,
  signature,
  publicKeyPem,
}) {
  if (
    !dataToVerify
  ) {
    throw createError(
      "ADMOB_CRYPTO_VERIFICATION_ERROR",

      "No AdMob SSV data available for verification.",
    );
  }


  if (
    !signature
  ) {
    throw createError(
      "ADMOB_INVALID_SIGNATURE",

      "No AdMob SSV signature available.",
    );
  }


  if (
    !publicKeyPem
  ) {
    throw createError(
      "ADMOB_PUBLIC_KEY_NOT_FOUND",

      "No AdMob public key available.",
    );
  }


  let signatureBuffer;


  try {
    // --------------------------------------------------------
    // AdMob signatures use URL-safe Base64.
    //
    // Node's base64 decoder accepts the URL-safe alphabet,
    // but "base64url" explicitly documents the intended format.
    // --------------------------------------------------------

    signatureBuffer =
      Buffer.from(
        signature,
        "base64url",
      );
  } catch (
    error
  ) {
    throw createError(
      "ADMOB_CRYPTO_VERIFICATION_ERROR",

      `Failed to decode AdMob SSV signature: ${error.message}`,
    );
  }


  if (
    signatureBuffer.length ===
    0
  ) {
    throw createError(
      "ADMOB_INVALID_SIGNATURE",

      "AdMob SSV signature decoded to an empty buffer.",
    );
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
    throw createError(
      "ADMOB_CRYPTO_VERIFICATION_ERROR",

      `AdMob SSV cryptographic verification failed: ${error.message}`,
    );
  }
}


// ============================================================
// 📦 PARSE CALLBACK PARAMETERS
// ============================================================
//
// IMPORTANT:
//
// This function is used ONLY AFTER cryptographic verification.
//
// URLSearchParams is therefore safe here.
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
// 🆔 PARSE CUSTOM DATA
// ============================================================
//
// Stelluriinin expected custom_data:
//
// UID:rewardPurpose
//
// Example:
//
// abc123:mining_start
//
// or:
//
// abc123:power_boost
//
// custom_data itself is part of the cryptographically signed
// AdMob callback, so this value can safely be used after
// successful signature verification.
//
// ============================================================

function parseCustomData(
  customData,
) {
  if (
    typeof customData !==
    "string"
  ) {
    throw createError(
      "ADMOB_CUSTOM_DATA_MISSING",

      "AdMob custom_data is missing.",
    );
  }


  const normalized =
    customData.trim();


  if (
    normalized.length ===
      0 ||
    normalized.length >
      256
  ) {
    throw createError(
      "ADMOB_CUSTOM_DATA_MISSING",

      "AdMob custom_data is missing or invalid.",
    );
  }


  const separatorIndex =
    normalized.indexOf(
      ":",
    );


  if (
    separatorIndex <=
    0 ||
    separatorIndex ===
      normalized.length - 1
  ) {
    throw createError(
      "ADMOB_CUSTOM_DATA_MISSING",

      "AdMob custom_data has an invalid format.",
    );
  }


  const uid =
    normalized.substring(
      0,
      separatorIndex,
    );


  const rewardPurpose =
    normalized.substring(
      separatorIndex + 1,
    );


  if (
    !/^[A-Za-z0-9._-]{1,128}$/.test(
      uid,
    )
  ) {
    throw createError(
      "ADMOB_INVALID_UID",

      "AdMob custom_data contains an invalid UID.",
    );
  }


  if (
    rewardPurpose !==
      "mining_start" &&
    rewardPurpose !==
      "power_boost"
  ) {
    throw createError(
      "ADMOB_INVALID_REWARD_PURPOSE",

      "AdMob custom_data contains an invalid reward purpose.",
    );
  }


  return {
    uid,

    rewardPurpose,

    customData:
      normalized,
  };
}


// ============================================================
// 🛡️ VALIDATE VERIFIED CALLBACK
// ============================================================

function validateCallback(
  callback,
) {
  if (
    !callback
  ) {
    throw createError(
      "ADMOB_VERIFIED_DATA_MISSING",

      "Verified AdMob callback data is missing.",
    );
  }


  // ----------------------------------------------------------
  // TRANSACTION ID
  // ----------------------------------------------------------

  if (
    typeof callback.transactionId !==
      "string" ||
    !/^[A-Fa-f0-9]{1,256}$/.test(
      callback.transactionId,
    )
  ) {
    throw createError(
      "ADMOB_INVALID_TRANSACTION_ID",

      "AdMob SSV transaction_id is invalid.",
    );
  }


  // ----------------------------------------------------------
  // TIMESTAMP
  // ----------------------------------------------------------

  if (
    typeof callback.timestamp !==
      "string" ||
    !/^\d+$/.test(
      callback.timestamp,
    )
  ) {
    throw createError(
      "ADMOB_INVALID_TIMESTAMP",

      "AdMob SSV timestamp is invalid.",
    );
  }


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
    throw createError(
      "ADMOB_INVALID_TIMESTAMP",

      "AdMob SSV timestamp is invalid.",
    );
  }


  // ----------------------------------------------------------
  // IMPORTANT:
  //
  // AdMob timestamp is milliseconds.
  // ----------------------------------------------------------

  const nowMs =
    Date.now();


  if (
    timestamp >
    nowMs +
      MAX_FUTURE_SKEW_MS
  ) {
    throw createError(
      "ADMOB_INVALID_TIMESTAMP",

      "AdMob SSV timestamp is in the future.",
    );
  }


  if (
    nowMs -
      timestamp >
      MAX_TIMESTAMP_AGE_MS
  ) {
    throw createError(
      "ADMOB_INVALID_TIMESTAMP",

      "AdMob SSV callback is too old.",
    );
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
    throw createError(
      "ADMOB_INVALID_REWARD_AMOUNT",

      "AdMob SSV reward_amount is invalid.",
    );
  }


  // ----------------------------------------------------------
  // REQUIRED REWARD ITEM
  // ----------------------------------------------------------

  if (
    typeof callback.rewardItem !==
      "string" ||
    callback.rewardItem.trim()
      .length ===
      0
  ) {
    throw createError(
      "ADMOB_INVALID_REWARD_ITEM",

      "AdMob SSV reward_item is missing.",
    );
  }


  // ----------------------------------------------------------
  // REQUIRED AD UNIT
  // ----------------------------------------------------------

  if (
    typeof callback.adUnit !==
      "string" ||
    callback.adUnit.trim()
      .length ===
      0
  ) {
    throw createError(
      "ADMOB_INVALID_AD_UNIT",

      "AdMob SSV ad_unit is missing.",
    );
  }


  // ----------------------------------------------------------
  // AD NETWORK
  // ----------------------------------------------------------

  if (
    typeof callback.adNetwork !==
      "string" ||
    !/^\d{1,32}$/.test(
      callback.adNetwork.trim(),
    )
  ) {
    throw createError(
      "ADMOB_INVALID_AD_NETWORK",

      "AdMob SSV ad_network is invalid.",
    );
  }


  // ----------------------------------------------------------
  // KEY ID
  // ----------------------------------------------------------

  if (
    typeof callback.keyId !==
      "string" ||
    !/^\d{1,32}$/.test(
      callback.keyId.trim(),
    )
  ) {
    throw createError(
      "ADMOB_INVALID_KEY_ID",

      "AdMob SSV key_id is invalid.",
    );
  }


  // ----------------------------------------------------------
  // SIGNATURE
  // ----------------------------------------------------------

  if (
    typeof callback.signature !==
      "string" ||
    callback.signature.length ===
      0 ||
    callback.signature.length >
      8192
  ) {
    throw createError(
      "ADMOB_INVALID_SIGNATURE",

      "AdMob SSV signature is invalid.",
    );
  }


  // ----------------------------------------------------------
  // CUSTOM DATA
  // ----------------------------------------------------------

  const customDataInfo =
    parseCustomData(
      callback.customData,
    );


  // ----------------------------------------------------------
  // USER ID
  // ----------------------------------------------------------
  //
  // user_id is optional in Google's SSV callback.
  //
  // Stelluriini nevertheless requires the UID to be present
  // inside signed custom_data.
  //
  // If user_id exists, it must match the UID from custom_data.
  //
  // ----------------------------------------------------------

  let userId =
    "";


  if (
    callback.userId !=
      null &&
    String(
      callback.userId,
    ).trim()
      .length >
      0
  ) {
    userId =
      String(
        callback.userId,
      ).trim();


    if (
      !/^[A-Za-z0-9._-]{1,128}$/.test(
        userId,
      )
    ) {
      throw createError(
        "ADMOB_INVALID_UID",

        "AdMob SSV user_id is invalid.",
      );
    }


    if (
      userId !==
      customDataInfo.uid
    ) {
      throw createError(
        "ADMOB_USER_ID_MISMATCH",

        "AdMob SSV user_id does not match UID in custom_data.",
      );
    }
  }


  return {
    uid:
      customDataInfo.uid,

    rewardPurpose:
      customDataInfo.rewardPurpose,

    customData:
      customDataInfo.customData,

    transactionId:
      callback.transactionId,

    rewardAmount,

    rewardItem:
      callback.rewardItem.trim(),

    adUnit:
      callback.adUnit.trim(),

    adNetwork:
      callback.adNetwork.trim(),

    timestamp,

    keyId:
      callback.keyId.trim(),

    signature:
      callback.signature,

    userId,
  };
}


// ============================================================
// 🔐 MAIN ADMOB CALLBACK VERIFICATION
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
      throw createError(
        "ADMOB_QUERY_STRING_MISSING",

        "AdMob SSV callback contains no query string.",
      );
    }


    // ========================================================
    // 2. EXTRACT SIGNED DATA
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
      throw createError(
        "ADMOB_PUBLIC_KEY_NOT_FOUND",

        `No AdMob public key found for key_id ${keyId}.`,
      );
    }


    // ========================================================
    // 5. CRYPTOGRAPHIC VERIFICATION
    // ========================================================

    const signatureValid =
      verifySignature(
        {
          dataToVerify,

          signature,

          publicKeyPem,
        },
      );


    if (
      !signatureValid
    ) {
      throw createError(
        "ADMOB_INVALID_SIGNATURE",

        "AdMob SSV signature verification failed.",
      );
    }


    log(
      "AdMob SSV signature verified successfully.",
      {
        keyId,
      },
    );


    // ========================================================
    // 6. PARSE ONLY AFTER SIGNATURE VERIFICATION
    // ========================================================

    const callback =
      parseCallbackParameters(
        rawQuery,
      );


    // ========================================================
    // 7. DEFENSE-IN-DEPTH CHECK
    // ========================================================

    // The parsed key_id and signature must correspond to the
    // exact values extracted from the original query.

    if (
      callback.keyId !==
      keyId
    ) {
      throw createError(
        "ADMOB_INVALID_KEY_ID",

        "Parsed key_id does not match the verified key_id.",
      );
    }


    if (
      callback.signature !==
      signature
    ) {
      throw createError(
        "ADMOB_INVALID_SIGNATURE",

        "Parsed signature does not match the verified signature.",
      );
    }


    // ========================================================
    // 8. VALIDATE VERIFIED CALLBACK
    // ========================================================

    const validated =
      validateCallback(
        callback,
      );


    // ========================================================
    // 9. RETURN VERIFIED DATA
    // ========================================================

    return {
      verified:
        true,

      code:
        "ADMOB_SSV_VERIFIED",

      uid:
        validated.uid,

      rewardPurpose:
        validated.rewardPurpose,

      keyId:
        validated.keyId,

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

      signature:
        validated.signature,

      // ------------------------------------------------------
      // Diagnostic/audit value.
      //
      // This is the exact original query string.
      //
      // NEVER reconstruct the signature from parsed values.
      // ------------------------------------------------------

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


    const message =
      error &&
      error.message
        ? error.message
        : "AdMob SSV verification failed.";


    logError(
      "AdMob SSV verification FAILED.",
      {
        code,

        message,
      },
    );


    return {
      verified:
        false,

      code,

      message,

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

  parseCallbackParameters,

  validateCallback,

  parseCustomData,

  verifySignature,

  getRawQueryString,

  extractSignatureAndKeyId,

  ADMOB_AD_UNITS,

  REWARD_DEFINITIONS,
};