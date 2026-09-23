"use strict";

// ============================================================
// 🐱 STELLURIINI - ADMOB SERVICE
// ============================================================
//
// Vastuu:
//
// 🔐 AdMob Rewarded SSV -allekirjoituksen varmennus
// 🔑 Public key -lataus ja cache
// 🧩 SSV-parametrien validointi
// 👤 UID / user_id -validointi
// 🎯 reward purpose -validointi
// 🆔 transaction_id -validointi
// 🕒 timestamp-validointi
//
// EI:
// ❌ Firestore-kirjoituksia
// ❌ STL-saldon muutoksia
// ❌ Mining-tilan muutoksia
// ❌ Power Boostin aktivointia
//
// ============================================================

const {
  createVerify,
} = require("crypto");

const https = require("https");

const {
  ADMOB_MINING_AD_UNIT_ID,
  ADMOB_POWER_BOOST_AD_UNIT_ID,

  ADMOB_MINING_SSV_REWARD_AMOUNT,
  ADMOB_MINING_SSV_REWARD_ITEM,

  ADMOB_POWER_BOOST_SSV_REWARD_AMOUNT,
  ADMOB_POWER_BOOST_SSV_REWARD_ITEM,
} = require("../config/miningConfig");

// ============================================================
// 🔑 GOOGLE ADMOB PUBLIC KEYS
// ============================================================

const ADMOB_SSV_KEYS_URL =
  "https://www.gstatic.com/admob/reward/verifier-keys.json";

const PUBLIC_KEY_CACHE_MS =
  23 * 60 * 60 * 1000;

const PUBLIC_KEY_FETCH_TIMEOUT_MS =
  10 * 1000;

const PUBLIC_KEY_MAX_RESPONSE_BYTES =
  1024 * 1024;

// ============================================================
// 🛡️ INPUT LIMITS
// ============================================================

const MAX_QUERY_STRING_LENGTH =
  16 * 1024;

const MAX_CUSTOM_DATA_LENGTH =
  256;

const MAX_AD_UNIT_LENGTH =
  256;

const MAX_REWARD_ITEM_LENGTH =
  256;

// ============================================================
// 🕒 TIMESTAMP LIMITS
// ============================================================

const TIMESTAMP_MAX_AGE_MS =
  24 * 60 * 60 * 1000;

const TIMESTAMP_FUTURE_TOLERANCE_MS =
  5 * 60 * 1000;

// ============================================================
// 🎯 REWARD CONFIGURATION
// ============================================================

const REWARD_CONFIG = Object.freeze({
  mining_start: Object.freeze({
    adUnit:
      ADMOB_MINING_AD_UNIT_ID,

    rewardAmount:
      Number(
        ADMOB_MINING_SSV_REWARD_AMOUNT
      ),

    rewardItem:
      ADMOB_MINING_SSV_REWARD_ITEM,
  }),

  power_boost: Object.freeze({
    adUnit:
      ADMOB_POWER_BOOST_AD_UNIT_ID,

    rewardAmount:
      Number(
        ADMOB_POWER_BOOST_SSV_REWARD_AMOUNT
      ),

    rewardItem:
      ADMOB_POWER_BOOST_SSV_REWARD_ITEM,
  }),
});

const VALID_REWARD_PURPOSES =
  new Set([
    "mining_start",
    "power_boost",
  ]);

// ============================================================
// 🔐 PUBLIC KEY CACHE
// ============================================================

let publicKeyCache = null;
let publicKeyFetchPromise = null;

// ============================================================
// 🧹 STRING
// ============================================================

function normalizeString(value) {
  return typeof value === "string"
    ? value.trim()
    : "";
}

// ============================================================
// 🛡️ ERROR
// ============================================================

function createError(code, message) {
  const error = new Error(message);
  error.code = code;
  return error;
}

// ============================================================
// 👤 UID
// ============================================================

function validateUid(value) {
  const uid = normalizeString(value);

  if (
    !uid ||
    uid.length > 128 ||
    !/^[A-Za-z0-9._-]+$/.test(uid)
  ) {
    return "";
  }

  return uid;
}

// ============================================================
// 🆔 TRANSACTION ID
// ============================================================

function validateTransactionId(value) {
  const transactionId =
    normalizeString(value);

  if (
    !transactionId ||
    transactionId.length > 256 ||
    !/^[A-Fa-f0-9]+$/.test(
      transactionId
    )
  ) {
    return "";
  }

  return transactionId;
}

// ============================================================
// 🎯 REWARD PURPOSE
// ============================================================

function validateRewardPurpose(value) {
  const purpose =
    normalizeString(value);

  return VALID_REWARD_PURPOSES.has(
    purpose
  )
    ? purpose
    : "";
}

// ============================================================
// 📺 AD NETWORK
// ============================================================

function validateAdNetwork(value) {
  const adNetwork =
    normalizeString(value);

  if (
    !adNetwork ||
    adNetwork.length > 32 ||
    !/^\d+$/.test(adNetwork)
  ) {
    return "";
  }

  return adNetwork;
}

// ============================================================
// 🕒 TIMESTAMP
// ============================================================

function validateTimestamp(value) {
  const normalized =
    normalizeString(
      String(value ?? "")
    );

  if (
    !normalized ||
    !/^\d+$/.test(normalized)
  ) {
    return 0;
  }

  const timestamp =
    Number(normalized);

  if (
    !Number.isSafeInteger(timestamp) ||
    timestamp <= 0
  ) {
    return 0;
  }

  const now = Date.now();

  if (
    timestamp <
      now - TIMESTAMP_MAX_AGE_MS ||
    timestamp >
      now + TIMESTAMP_FUTURE_TOLERANCE_MS
  ) {
    return 0;
  }

  return timestamp;
}

// ============================================================
// 🔢 KEY ID
// ============================================================

function validateKeyId(value) {
  const keyId =
    normalizeString(value);

  if (
    !keyId ||
    keyId.length > 32 ||
    !/^\d+$/.test(keyId)
  ) {
    return "";
  }

  return keyId;
}

// ============================================================
// 🔐 SIGNATURE
// ============================================================

function validateSignature(value) {
  const signature =
    normalizeString(value);

  if (
    !signature ||
    signature.length > 8192 ||
    !/^[A-Za-z0-9_-]+$/.test(
      signature
    ) ||
    signature.length % 4 === 1
  ) {
    return "";
  }

  return signature;
}

// ============================================================
// 🔐 BASE64URL
// ============================================================

function decodeBase64Url(value) {
  const signature =
    validateSignature(value);

  if (!signature) {
    throw createError(
      "ADMOB_INVALID_SIGNATURE",
      "AdMob signature is invalid."
    );
  }

  const base64 =
    signature
      .replace(/-/g, "+")
      .replace(/_/g, "/");

  const padding =
    base64.length % 4;

  const padded =
    padding === 0
      ? base64
      : base64 +
        "=".repeat(4 - padding);

  const buffer =
    Buffer.from(
      padded,
      "base64"
    );

  if (!buffer.length) {
    throw createError(
      "ADMOB_INVALID_SIGNATURE",
      "AdMob signature could not be decoded."
    );
  }

  return buffer;
}

// ============================================================
// 🌐 FETCH PUBLIC KEYS
// ============================================================

function fetchPublicKeys() {
  return new Promise(
    (resolve, reject) => {
      let settled = false;
      let request = null;

      const fail = (error) => {
        if (settled) return;
        settled = true;
        reject(error);
      };

      const succeed = (value) => {
        if (settled) return;
        settled = true;
        resolve(value);
      };

      try {
        request = https.get(
          ADMOB_SSV_KEYS_URL,
          {
            headers: {
              Accept:
                "application/json",
            },

            timeout:
              PUBLIC_KEY_FETCH_TIMEOUT_MS,
          },
          (response) => {
            const statusCode =
              response.statusCode || 0;

            if (
              statusCode < 200 ||
              statusCode >= 300
            ) {
              response.resume();

              fail(
                createError(
                  "ADMOB_PUBLIC_KEY_HTTP_ERROR",
                  `AdMob public key server returned HTTP ${statusCode}.`
                )
              );

              return;
            }

            let body = "";
            let bodyBytes = 0;

            response.setEncoding(
              "utf8"
            );

            response.on(
              "data",
              (chunk) => {
                if (settled) return;

                bodyBytes +=
                  Buffer.byteLength(
                    chunk,
                    "utf8"
                  );

                if (
                  bodyBytes >
                  PUBLIC_KEY_MAX_RESPONSE_BYTES
                ) {
                  fail(
                    createError(
                      "ADMOB_PUBLIC_KEY_RESPONSE_INVALID",
                      "AdMob public key response is too large."
                    )
                  );

                  request.destroy();
                  return;
                }

                body += chunk;
              }
            );

            response.on(
              "end",
              () => {
                if (settled) return;

                if (!body) {
                  fail(
                    createError(
                      "ADMOB_PUBLIC_KEY_RESPONSE_INVALID",
                      "AdMob public key response is empty."
                    )
                  );

                  return;
                }

                let parsed;

                try {
                  parsed =
                    JSON.parse(body);
                } catch {
                  fail(
                    createError(
                      "ADMOB_PUBLIC_KEY_JSON_ERROR",
                      "Unable to parse AdMob public key response."
                    )
                  );

                  return;
                }

                if (
                  !parsed ||
                  !Array.isArray(
                    parsed.keys
                  )
                ) {
                  fail(
                    createError(
                      "ADMOB_PUBLIC_KEY_RESPONSE_INVALID",
                      "AdMob public key response has an invalid structure."
                    )
                  );

                  return;
                }

                const keys =
                  new Map();

                for (
                  const key of
                    parsed.keys
                ) {
                  if (
                    !key ||
                    typeof key !==
                      "object"
                  ) {
                    continue;
                  }

                  const keyId =
                    validateKeyId(
                      key.keyId
                    );

                  const pem =
                    normalizeString(
                      key.pem
                    );

                  if (
                    !keyId ||
                    !pem ||
                    !pem.includes(
                      "-----BEGIN PUBLIC KEY-----"
                    ) ||
                    !pem.includes(
                      "-----END PUBLIC KEY-----"
                    )
                  ) {
                    continue;
                  }

                  keys.set(
                    keyId,
                    pem
                  );
                }

                if (!keys.size) {
                  fail(
                    createError(
                      "ADMOB_PUBLIC_KEYS_EMPTY",
                      "AdMob public key response contains no valid keys."
                    )
                  );

                  return;
                }

                succeed(keys);
              }
            );

            response.on(
              "error",
              () => {
                fail(
                  createError(
                    "ADMOB_PUBLIC_KEY_FETCH_ERROR",
                    "Unable to read AdMob public key response."
                  )
                );
              }
            );
          }
        );

        request.on(
          "timeout",
          () => {
            request.destroy();

            fail(
              createError(
                "ADMOB_PUBLIC_KEY_FETCH_ERROR",
                "AdMob public key request timed out."
              )
            );
          }
        );

        request.on(
          "error",
          () => {
            fail(
              createError(
                "ADMOB_PUBLIC_KEY_FETCH_ERROR",
                "Unable to fetch AdMob public keys."
              )
            );
          }
        );
      } catch {
        fail(
          createError(
            "ADMOB_PUBLIC_KEY_FETCH_ERROR",
            "Unable to fetch AdMob public keys."
          )
        );
      }
    }
  );
}

// ============================================================
// 🔑 GET PUBLIC KEYS
// ============================================================

async function getAdMobPublicKeys(
  forceRefresh = false
) {
  const now = Date.now();

  if (
    !forceRefresh &&
    publicKeyCache &&
    now -
      publicKeyCache.loadedAt <
      PUBLIC_KEY_CACHE_MS
  ) {
    return publicKeyCache.keys;
  }

  if (publicKeyFetchPromise) {
    return publicKeyFetchPromise;
  }

  publicKeyFetchPromise =
    fetchPublicKeys()
      .then((keys) => {
        publicKeyCache = {
          keys,
          loadedAt: Date.now(),
        };

        return keys;
      })
      .finally(() => {
        publicKeyFetchPromise = null;
      });

  return publicKeyFetchPromise;
}

// ============================================================
// 🔐 VERIFY ADMOB SIGNATURE
// ============================================================

async function verifyAdMobSignature(
  rawQueryString
) {
  if (
    typeof rawQueryString !==
      "string" ||
    !rawQueryString
  ) {
    throw createError(
      "ADMOB_QUERY_STRING_MISSING",
      "AdMob query string is missing."
    );
  }

  if (
    rawQueryString.length >
    MAX_QUERY_STRING_LENGTH
  ) {
    throw createError(
      "ADMOB_QUERY_STRING_TOO_LARGE",
      "AdMob query string is too large."
    );
  }

  const parameters =
    rawQueryString.split("&");

  if (parameters.length < 3) {
    throw createError(
      "ADMOB_INVALID_SIGNATURE",
      "AdMob SSV query does not contain enough parameters."
    );
  }

  const signatureParameter =
    parameters[
      parameters.length - 2
    ];

  const keyIdParameter =
    parameters[
      parameters.length - 1
    ];

  if (
    !signatureParameter.startsWith(
      "signature="
    )
  ) {
    throw createError(
      "ADMOB_INVALID_SIGNATURE",
      "AdMob signature parameter is invalid."
    );
  }

  if (
    !keyIdParameter.startsWith(
      "key_id="
    )
  ) {
    throw createError(
      "ADMOB_INVALID_KEY_ID",
      "AdMob key_id parameter is invalid."
    );
  }

  for (
    let i = 0;
    i < parameters.length - 2;
    i += 1
  ) {
    if (
      parameters[i].startsWith(
        "signature="
      )
    ) {
      throw createError(
        "ADMOB_INVALID_SIGNATURE",
        "Duplicate AdMob signature parameter."
      );
    }

    if (
      parameters[i].startsWith(
        "key_id="
      )
    ) {
      throw createError(
        "ADMOB_INVALID_KEY_ID",
        "Duplicate AdMob key_id parameter."
      );
    }
  }

  const signature =
    validateSignature(
      signatureParameter.substring(
        10
      )
    );

  const keyId =
    validateKeyId(
      keyIdParameter.substring(
        7
      )
    );

  if (!signature) {
    throw createError(
      "ADMOB_INVALID_SIGNATURE",
      "AdMob signature is invalid."
    );
  }

  if (!keyId) {
    throw createError(
      "ADMOB_INVALID_KEY_ID",
      "AdMob key_id is invalid."
    );
  }

  const signedQueryString =
    parameters
      .slice(0, -2)
      .join("&");

  if (!signedQueryString) {
    throw createError(
      "ADMOB_QUERY_STRING_MISSING",
      "AdMob signed query string is empty."
    );
  }

  let publicKeys =
    await getAdMobPublicKeys();

  let publicKey =
    publicKeys.get(keyId);

  if (!publicKey) {
    publicKeys =
      await getAdMobPublicKeys(
        true
      );

    publicKey =
      publicKeys.get(keyId);
  }

  if (!publicKey) {
    throw createError(
      "ADMOB_PUBLIC_KEY_NOT_FOUND",
      "AdMob public key was not found."
    );
  }

  const signatureBuffer =
    decodeBase64Url(
      signature
    );

  try {
    const verifier =
      createVerify("SHA256");

    verifier.update(
      Buffer.from(
        signedQueryString,
        "utf8"
      )
    );

    verifier.end();

    if (
      !verifier.verify(
        publicKey,
        signatureBuffer
      )
    ) {
      throw createError(
        "ADMOB_INVALID_SIGNATURE",
        "AdMob signature verification failed."
      );
    }
  } catch (error) {
    if (
      error &&
      error.code ===
        "ADMOB_INVALID_SIGNATURE"
    ) {
      throw error;
    }

    throw createError(
      "ADMOB_CRYPTO_VERIFICATION_ERROR",
      "AdMob cryptographic verification failed."
    );
  }

  return {
    verified: true,
    signature,
    keyId,
    signedQueryString,
    rawQueryString,
  };
}

// ============================================================
// 🎯 PARSE CUSTOM DATA
// ============================================================

function parseCustomData(value) {
  const raw =
    normalizeString(value);

  if (
    !raw ||
    raw.length >
      MAX_CUSTOM_DATA_LENGTH
  ) {
    throw createError(
      "ADMOB_CUSTOM_DATA_MISSING",
      "AdMob custom_data is missing or invalid."
    );
  }

  let decoded;

  try {
    decoded =
      decodeURIComponent(raw);
  } catch {
    throw createError(
      "ADMOB_CUSTOM_DATA_INVALID_ENCODING",
      "AdMob custom_data could not be decoded."
    );
  }

  if (
    !decoded ||
    decoded.length >
      MAX_CUSTOM_DATA_LENGTH ||
    /[\u0000-\u001F\u007F]/.test(
      decoded
    )
  ) {
    throw createError(
      "ADMOB_CUSTOM_DATA_INVALID",
      "AdMob custom_data is invalid."
    );
  }

  const separator =
    decoded.indexOf(":");

  if (
    separator <= 0 ||
    separator ===
      decoded.length - 1 ||
    decoded.indexOf(
      ":",
      separator + 1
    ) !== -1
  ) {
    throw createError(
      "ADMOB_CUSTOM_DATA_MISSING",
      "AdMob custom_data has an invalid format."
    );
  }

  const uid =
    validateUid(
      decoded.substring(
        0,
        separator
      )
    );

  const rewardPurpose =
    validateRewardPurpose(
      decoded.substring(
        separator + 1
      )
    );

  if (!uid) {
    throw createError(
      "ADMOB_INVALID_UID",
      "AdMob custom_data contains an invalid UID."
    );
  }

  if (!rewardPurpose) {
    throw createError(
      "ADMOB_INVALID_REWARD_PURPOSE",
      "AdMob custom_data contains an invalid reward purpose."
    );
  }

  return {
    uid,
    rewardPurpose,
    customData:
      `${uid}:${rewardPurpose}`,
  };
}

// ============================================================
// 📺 EXPECTED CONFIG
// ============================================================

function getExpectedAdMobConfig(
  rewardPurpose
) {
  const config =
    REWARD_CONFIG[
      rewardPurpose
    ];

  if (!config) {
    throw createError(
      "ADMOB_INVALID_REWARD_PURPOSE",
      "Unknown AdMob reward purpose."
    );
  }

  if (
    typeof config.adUnit !==
      "string" ||
    !config.adUnit.trim() ||
    !Number.isSafeInteger(
      config.rewardAmount
    ) ||
    config.rewardAmount < 0 ||
    typeof config.rewardItem !==
      "string" ||
    !config.rewardItem.trim()
  ) {
    throw createError(
      "ADMOB_INVALID_REWARD_CONFIGURATION",
      "Invalid AdMob reward configuration."
    );
  }

  return {
    adUnit:
      config.adUnit.trim(),

    rewardAmount:
      config.rewardAmount,

    rewardItem:
      config.rewardItem.trim(),
  };
}

// ============================================================
// 📋 QUERY VALUE
// ============================================================

function getQueryValue(
  query,
  key
) {
  const value =
    query[key];

  if (Array.isArray(value)) {
    return value.length === 1
      ? normalizeString(value[0])
      : "";
  }

  return normalizeString(value);
}

// ============================================================
// 🔐 VERIFY COMPLETE CALLBACK
// ============================================================

async function verifyAdMobCallback(
  req
) {
  if (!req) {
    throw createError(
      "ADMOB_REQUEST_MISSING",
      "AdMob request is missing."
    );
  }

  const originalUrl =
    typeof req.originalUrl ===
      "string" &&
    req.originalUrl
      ? req.originalUrl
      : typeof req.url ===
          "string"
        ? req.url
        : "";

  const questionMark =
    originalUrl.indexOf("?");

  if (questionMark === -1) {
    throw createError(
      "ADMOB_QUERY_STRING_MISSING",
      "AdMob query string is missing."
    );
  }

  const rawQueryString =
    originalUrl.substring(
      questionMark + 1
    );

  const cryptographicResult =
    await verifyAdMobSignature(
      rawQueryString
    );

  const query =
    req.query || {};

  const adNetwork =
    getQueryValue(
      query,
      "ad_network"
    );

  const adUnit =
    getQueryValue(
      query,
      "ad_unit"
    );

  const rewardAmount =
    getQueryValue(
      query,
      "reward_amount"
    );

  const rewardItem =
    getQueryValue(
      query,
      "reward_item"
    );

  const transactionId =
    getQueryValue(
      query,
      "transaction_id"
    );

  const timestamp =
    getQueryValue(
      query,
      "timestamp"
    );

  const userId =
    getQueryValue(
      query,
      "user_id"
    );

  const customData =
    getQueryValue(
      query,
      "custom_data"
    );

  if (
    !adNetwork ||
    !adUnit ||
    !rewardAmount ||
    !rewardItem ||
    !transactionId ||
    !timestamp ||
    !customData
  ) {
    throw createError(
      "ADMOB_REQUIRED_PARAMETER_MISSING",
      "One or more required AdMob parameters are missing."
    );
  }

  const validatedAdNetwork =
    validateAdNetwork(
      adNetwork
    );

  const validatedAdUnit =
    normalizeString(adUnit);

  const validatedRewardAmount =
    Number(rewardAmount);

  const validatedRewardItem =
    normalizeString(
      rewardItem
    );

  const validatedTransactionId =
    validateTransactionId(
      transactionId
    );

  const validatedTimestamp =
    validateTimestamp(
      timestamp
    );

  if (!validatedAdNetwork) {
    throw createError(
      "ADMOB_INVALID_AD_NETWORK",
      "AdMob ad_network is invalid."
    );
  }

  if (
    !validatedAdUnit ||
    validatedAdUnit.length >
      MAX_AD_UNIT_LENGTH
  ) {
    throw createError(
      "ADMOB_INVALID_AD_UNIT",
      "AdMob ad_unit is invalid."
    );
  }

  if (
    !Number.isSafeInteger(
      validatedRewardAmount
    ) ||
    validatedRewardAmount < 0
  ) {
    throw createError(
      "ADMOB_INVALID_REWARD_AMOUNT",
      "AdMob reward_amount is invalid."
    );
  }

  if (
    !validatedRewardItem ||
    validatedRewardItem.length >
      MAX_REWARD_ITEM_LENGTH
  ) {
    throw createError(
      "ADMOB_INVALID_REWARD_ITEM",
      "AdMob reward_item is invalid."
    );
  }

  if (!validatedTransactionId) {
    throw createError(
      "ADMOB_INVALID_TRANSACTION_ID",
      "AdMob transaction_id is invalid."
    );
  }

  if (!validatedTimestamp) {
    throw createError(
      "ADMOB_INVALID_TIMESTAMP",
      "AdMob timestamp is invalid."
    );
  }

  const parsedCustomData =
    parseCustomData(
      customData
    );

  const {
    uid,
    rewardPurpose,
    customData:
      normalizedCustomData,
  } = parsedCustomData;

  const expected =
    getExpectedAdMobConfig(
      rewardPurpose
    );

  if (
    validatedAdUnit !==
    expected.adUnit
  ) {
    throw createError(
      "ADMOB_INVALID_AD_UNIT",
      "AdMob ad_unit does not match server configuration."
    );
  }

  if (
    validatedRewardAmount !==
    expected.rewardAmount
  ) {
    throw createError(
      "ADMOB_INVALID_REWARD_AMOUNT",
      "AdMob reward_amount does not match server configuration."
    );
  }

  if (
    validatedRewardItem !==
    expected.rewardItem
  ) {
    throw createError(
      "ADMOB_INVALID_REWARD_ITEM",
      "AdMob reward_item does not match server configuration."
    );
  }

  let normalizedUserId = "";

  if (userId) {
    normalizedUserId =
      validateUid(userId);

    if (!normalizedUserId) {
      throw createError(
        "ADMOB_INVALID_UID",
        "AdMob user_id is invalid."
      );
    }

    if (
      normalizedUserId !==
      uid
    ) {
      throw createError(
        "ADMOB_USER_ID_MISMATCH",
        "AdMob user_id does not match the verified UID."
      );
    }
  }

  return {
    verified: true,

    uid,
    rewardPurpose,

    adUnit:
      validatedAdUnit,

    adNetwork:
      validatedAdNetwork,

    rewardAmount:
      validatedRewardAmount,

    rewardItem:
      validatedRewardItem,

    timestamp:
      validatedTimestamp,

    transactionId:
      validatedTransactionId,

    userId:
      normalizedUserId,

    customData:
      normalizedCustomData,

    keyId:
      cryptographicResult.keyId,

    signature:
      cryptographicResult.signature,

    rawQueryString:
      cryptographicResult.rawQueryString,

    signedQueryString:
      cryptographicResult.signedQueryString,

    parameters: {
      adNetwork:
        validatedAdNetwork,

      adUnit:
        validatedAdUnit,

      rewardAmount:
        validatedRewardAmount,

      rewardItem:
        validatedRewardItem,

      timestamp:
        validatedTimestamp,

      transactionId:
        validatedTransactionId,

      userId:
        normalizedUserId,

      customData:
        normalizedCustomData,

      keyId:
        cryptographicResult.keyId,

      signature:
        cryptographicResult.signature,
    },
  };
}

// ============================================================
// 📦 EXPORTS
// ============================================================

module.exports = {
  ADMOB_SSV_KEYS_URL,

  REWARD_CONFIG,

  getAdMobPublicKeys,

  verifyAdMobSignature,

  verifyAdMobCallback,

  parseCustomData,

  validateTransactionId,

  validateUid,

  validateTimestamp,

  validateAdNetwork,

  validateKeyId,

  validateSignature,

  validateRewardPurpose,

  getExpectedAdMobConfig,
};