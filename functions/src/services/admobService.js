"use strict";

// ============================================================
// 🐱 STELLURIINI - ADMOB SERVICE
// ============================================================
// AdMob Rewarded SSV verification.
//
// IMPORTANT:
//
// Google signs the query content exactly as it appears in the
// callback URL, preserving parameter order.
//
// We DO NOT:
//
// - sort parameters
// - rebuild the signed query
// - decode the complete signed query
// - re-encode the signed query
// - use req.query for cryptographic verification
//
// req.query is used only AFTER cryptographic verification for
// normal application-level validation.
//
// AdMob SSV documentation:
//
// The last two query parameters are:
//   signature
//   key_id
//
// Everything before signature is the signed content.
//
// ============================================================

const {
  createPublicKey,
  verify,
} = require("crypto");

const https = require("https");

const {
  ADMOB_MINING_SSV_AD_UNIT_ID,
  ADMOB_POWER_BOOST_SSV_AD_UNIT_ID,

  ADMOB_MINING_SSV_REWARD_AMOUNT,
  ADMOB_MINING_SSV_REWARD_ITEM,

  ADMOB_POWER_BOOST_SSV_REWARD_AMOUNT,
  ADMOB_POWER_BOOST_SSV_REWARD_ITEM,
} = require("../config/miningConfig");

// ============================================================
// 🔐 ADMOB PUBLIC KEYS
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
// 📏 LIMITS
// ============================================================

const MAX_QUERY_STRING_LENGTH =
  16 * 1024;

const MAX_CUSTOM_DATA_LENGTH =
  256;

const MAX_AD_UNIT_LENGTH =
  256;

const MAX_REWARD_ITEM_LENGTH =
  256;

const MAX_AD_NETWORK_LENGTH =
  64;

const MAX_KEY_ID_LENGTH =
  32;

const MAX_TRANSACTION_ID_LENGTH =
  256;

const MAX_SIGNATURE_LENGTH =
  8192;

const MAX_UID_LENGTH =
  128;

const TIMESTAMP_FUTURE_TOLERANCE_MS =
  5 * 60 * 1000;

// ============================================================
// 🎁 VALID REWARD PURPOSES
// ============================================================

const VALID_REWARD_PURPOSES =
  new Set([
    "mining_start",
    "power_boost",
  ]);

// ============================================================
// 🎁 REWARD CONFIGURATION
// ============================================================

const REWARD_CONFIG =
  Object.freeze({
    mining_start:
      Object.freeze({
        adUnit:
          ADMOB_MINING_SSV_AD_UNIT_ID,

        rewardAmount:
          Number(
            ADMOB_MINING_SSV_REWARD_AMOUNT,
          ),

        rewardItem:
          ADMOB_MINING_SSV_REWARD_ITEM,
      }),

    power_boost:
      Object.freeze({
        adUnit:
          ADMOB_POWER_BOOST_SSV_AD_UNIT_ID,

        rewardAmount:
          Number(
            ADMOB_POWER_BOOST_SSV_REWARD_AMOUNT,
          ),

        rewardItem:
          ADMOB_POWER_BOOST_SSV_REWARD_ITEM,
      }),
  });

// ============================================================
// 🔐 PUBLIC KEY CACHE
// ============================================================

let publicKeyCache = null;

let publicKeyFetchPromise = null;

// ============================================================
// HELPERS
// ============================================================

function normalizeString(
  value,
) {
  return typeof value === "string"
    ? value.trim()
    : "";
}

function createError(
  code,
  message,
) {
  const error =
    new Error(message);

  error.code =
    code;

  return error;
}

// ============================================================
// 👤 UID
// ============================================================

function validateUid(
  value,
) {
  const uid =
    normalizeString(value);

  if (
    !uid ||
    uid.length >
      MAX_UID_LENGTH
  ) {
    return "";
  }

  return uid;
}

// ============================================================
// 🧾 TRANSACTION ID
// ============================================================
//
// AdMob transaction_id is a unique hex-encoded identifier.
//
// ============================================================

function validateTransactionId(
  value,
) {
  const transactionId =
    normalizeString(value);

  if (
    !transactionId ||
    transactionId.length >
      MAX_TRANSACTION_ID_LENGTH
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
// 🎁 REWARD PURPOSE
// ============================================================

function validateRewardPurpose(
  value,
) {
  const purpose =
    normalizeString(value);

  return VALID_REWARD_PURPOSES.has(
    purpose,
  )
    ? purpose
    : "";
}

// ============================================================
// 📡 AD NETWORK
// ============================================================

function validateAdNetwork(
  value,
) {
  const network =
    normalizeString(value);

  if (
    !network ||
    network.length >
      MAX_AD_NETWORK_LENGTH ||
    !/^\d+$/.test(
      network,
    )
  ) {
    return "";
  }

  return network;
}

// ============================================================
// 🕒 TIMESTAMP
// ============================================================
//
// AdMob timestamp is epoch milliseconds.
//
// ============================================================

function validateTimestamp(
  value,
) {
  const raw =
    String(
      value ?? "",
    ).trim();

  if (
    !raw ||
    !/^\d+$/.test(
      raw,
    )
  ) {
    return 0;
  }

  const timestamp =
    Number(raw);

  if (
    !Number.isSafeInteger(
      timestamp,
    ) ||
    timestamp <= 0 ||
    timestamp >
      Date.now() +
        TIMESTAMP_FUTURE_TOLERANCE_MS
  ) {
    return 0;
  }

  return timestamp;
}

// ============================================================
// 🔑 KEY ID
// ============================================================

function validateKeyId(
  value,
) {
  let keyId = "";

  if (
    typeof value ===
    "number"
  ) {
    if (
      !Number.isSafeInteger(
        value,
      ) ||
      value < 0
    ) {
      return "";
    }

    keyId =
      String(value);
  } else if (
    typeof value ===
    "string"
  ) {
    keyId =
      value.trim();
  } else {
    return "";
  }

  if (
    !keyId ||
    keyId.length >
      MAX_KEY_ID_LENGTH ||
    !/^\d+$/.test(
      keyId,
    )
  ) {
    return "";
  }

  return keyId;
}

// ============================================================
// ✍️ SIGNATURE
// ============================================================
//
// AdMob uses base64url-compatible signature data.
//
// ============================================================

function validateSignature(
  value,
) {
  const signature =
    normalizeString(value);

  if (
    !signature ||
    signature.length >
      MAX_SIGNATURE_LENGTH ||
    !/^[A-Za-z0-9_-]+$/.test(
      signature,
    ) ||
    signature.length % 4 ===
      1
  ) {
    return "";
  }

  return signature;
}

// ============================================================
// 🔓 BASE64URL
// ============================================================

function decodeBase64Url(
  value,
) {
  const signature =
    validateSignature(value);

  if (!signature) {
    throw createError(
      "ADMOB_INVALID_SIGNATURE",
      "AdMob signature is invalid.",
    );
  }

  const base64 =
    signature
      .replace(
        /-/g,
        "+",
      )
      .replace(
        /_/g,
        "/",
      );

  const padding =
    (
      4 -
      (
        base64.length %
        4
      )
    ) % 4;

  const buffer =
    Buffer.from(
      base64 +
        "=".repeat(
          padding,
        ),
      "base64",
    );

  if (!buffer.length) {
    throw createError(
      "ADMOB_INVALID_SIGNATURE",
      "AdMob signature could not be decoded.",
    );
  }

  return buffer;
}

// ============================================================
// 🌐 FETCH PUBLIC KEYS
// ============================================================

function fetchPublicKeys() {
  return new Promise(
    (
      resolve,
      reject,
    ) => {
      let settled =
        false;

      let request =
        null;

      const fail =
        (error) => {
          if (settled) {
            return;
          }

          settled =
            true;

          reject(error);
        };

      const succeed =
        (value) => {
          if (settled) {
            return;
          }

          settled =
            true;

          resolve(value);
        };

      try {
        request =
          https.get(
            ADMOB_SSV_KEYS_URL,
            {
              headers: {
                Accept:
                  "application/json",
              },

              timeout:
                PUBLIC_KEY_FETCH_TIMEOUT_MS,
            },
            (
              response,
            ) => {
              const statusCode =
                response.statusCode ||
                0;

              if (
                statusCode <
                  200 ||
                statusCode >=
                  300
              ) {
                response.resume();

                fail(
                  createError(
                    "ADMOB_PUBLIC_KEY_HTTP_ERROR",
                    `AdMob public key server returned HTTP ${statusCode}.`,
                  ),
                );

                return;
              }

              let body =
                "";

              let bodyBytes =
                0;

              response.setEncoding(
                "utf8",
              );

              response.on(
                "data",
                (
                  chunk,
                ) => {
                  if (settled) {
                    return;
                  }

                  bodyBytes +=
                    Buffer.byteLength(
                      chunk,
                      "utf8",
                    );

                  if (
                    bodyBytes >
                    PUBLIC_KEY_MAX_RESPONSE_BYTES
                  ) {
                    fail(
                      createError(
                        "ADMOB_PUBLIC_KEY_RESPONSE_INVALID",
                        "AdMob public key response is too large.",
                      ),
                    );

                    request?.destroy();

                    return;
                  }

                  body +=
                    chunk;
                },
              );

              response.on(
                "end",
                () => {
                  if (settled) {
                    return;
                  }

                  if (!body) {
                    fail(
                      createError(
                        "ADMOB_PUBLIC_KEY_RESPONSE_INVALID",
                        "AdMob public key response is empty.",
                      ),
                    );

                    return;
                  }

                  let parsed;

                  try {
                    parsed =
                      JSON.parse(
                        body,
                      );
                  } catch (_) {
                    fail(
                      createError(
                        "ADMOB_PUBLIC_KEY_JSON_ERROR",
                        "Unable to parse AdMob public key response.",
                      ),
                    );

                    return;
                  }

                  if (
                    !parsed ||
                    !Array.isArray(
                      parsed.keys,
                    )
                  ) {
                    fail(
                      createError(
                        "ADMOB_PUBLIC_KEY_RESPONSE_INVALID",
                        "AdMob public key response has an invalid structure.",
                      ),
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
                        key.keyId,
                      );

                    const pem =
                      normalizeString(
                        key.pem,
                      );

                    const base64 =
                      normalizeString(
                        key.base64,
                      );

                    if (
                      !keyId ||
                      (
                        !pem &&
                        !base64
                      )
                    ) {
                      continue;
                    }

                    keys.set(
                      keyId,
                      {
                        pem,
                        base64,
                      },
                    );
                  }

                  if (
                    !keys.size
                  ) {
                    fail(
                      createError(
                        "ADMOB_PUBLIC_KEYS_EMPTY",
                        "AdMob public key response contains no valid keys.",
                      ),
                    );

                    return;
                  }

                  succeed(
                    keys,
                  );
                },
              );

              response.on(
                "aborted",
                () => {
                  fail(
                    createError(
                      "ADMOB_PUBLIC_KEY_FETCH_ERROR",
                      "AdMob public key response was aborted.",
                    ),
                  );
                },
              );

              response.on(
                "error",
                () => {
                  fail(
                    createError(
                      "ADMOB_PUBLIC_KEY_FETCH_ERROR",
                      "Unable to read AdMob public key response.",
                    ),
                  );
                },
              );
            },
          );

        request.on(
          "timeout",
          () => {
            request.destroy();

            fail(
              createError(
                "ADMOB_PUBLIC_KEY_FETCH_ERROR",
                "AdMob public key request timed out.",
              ),
            );
          },
        );

        request.on(
          "error",
          () => {
            fail(
              createError(
                "ADMOB_PUBLIC_KEY_FETCH_ERROR",
                "Unable to fetch AdMob public keys.",
              ),
            );
          },
        );
      } catch (_) {
        fail(
          createError(
            "ADMOB_PUBLIC_KEY_FETCH_ERROR",
            "Unable to fetch AdMob public keys.",
          ),
        );
      }
    },
  );
}

// ============================================================
// 🔐 PUBLIC KEY CACHE
// ============================================================

async function getAdMobPublicKeys(
  forceRefresh = false,
) {
  const now =
    Date.now();

  if (
    !forceRefresh &&
    publicKeyCache &&
    now -
      publicKeyCache.loadedAt <
      PUBLIC_KEY_CACHE_MS
  ) {
    return publicKeyCache.keys;
  }

  if (
    publicKeyFetchPromise
  ) {
    return publicKeyFetchPromise;
  }

  publicKeyFetchPromise =
    fetchPublicKeys()
      .then(
        (
          keys,
        ) => {
          publicKeyCache = {
            keys,
            loadedAt:
              Date.now(),
          };

          return keys;
        },
      )
      .finally(
        () => {
          publicKeyFetchPromise =
            null;
        },
      );

  return publicKeyFetchPromise;
}

// ============================================================
// 🔑 CREATE PUBLIC KEY
// ============================================================

function createAdMobPublicKey(
  keyData,
) {
  if (
    !keyData ||
    typeof keyData !==
      "object"
  ) {
    throw createError(
      "ADMOB_PUBLIC_KEY_INVALID",
      "AdMob public key is missing.",
    );
  }

  if (
    keyData.pem
  ) {
    try {
      return createPublicKey(
        keyData.pem,
      );
    } catch (_) {
      // Fall through to base64.
    }
  }

  if (
    keyData.base64
  ) {
    try {
      const keyBuffer =
        Buffer.from(
          keyData.base64,
          "base64",
        );

      if (
        keyBuffer.length >
        0
      ) {
        return createPublicKey({
          key:
            keyBuffer,

          format:
            "der",

          type:
            "spki",
        });
      }
    } catch (_) {
      // Unified error below.
    }
  }

  throw createError(
    "ADMOB_PUBLIC_KEY_INVALID",
    "AdMob public key could not be parsed.",
  );
}

// ============================================================
// 🔐 CRYPTOGRAPHIC VERIFICATION
// ============================================================

function verifyWithPublicKey(
  publicKeyData,
  signedQueryString,
  signatureBuffer,
) {
  const publicKey =
    createAdMobPublicKey(
      publicKeyData,
    );

  return verify(
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
}

// ============================================================
// 🔐 VERIFY SIGNED QUERY
// ============================================================

function verifySignedQuery(
  publicKeyData,
  signedQueryString,
  signatureBuffer,
) {
  if (
    typeof signedQueryString !==
      "string" ||
    !signedQueryString
  ) {
    throw createError(
      "ADMOB_QUERY_STRING_MISSING",
      "AdMob signed query string is empty.",
    );
  }

  return verifyWithPublicKey(
    publicKeyData,
    signedQueryString,
    signatureBuffer,
  );
}

// ============================================================
// 🔐 VERIFY ADMOB SIGNATURE
// ============================================================
//
// IMPORTANT:
//
// rawQueryString must remain untouched.
//
// We only locate:
//
// &signature=
//
// and split the final signature/key_id parameters.
//
// The signed part is passed to crypto exactly as received.
//
// ============================================================

async function verifyAdMobSignature(
  rawQueryString,
) {
  if (
    typeof rawQueryString !==
      "string" ||
    !rawQueryString
  ) {
    throw createError(
      "ADMOB_QUERY_STRING_MISSING",
      "AdMob query string is missing.",
    );
  }

  if (
    rawQueryString.length >
      MAX_QUERY_STRING_LENGTH
  ) {
    throw createError(
      "ADMOB_QUERY_STRING_TOO_LARGE",
      "AdMob query string is too large.",
    );
  }

  // ----------------------------------------------------------
  // DO NOT DECODE THE COMPLETE QUERY STRING.
  // ----------------------------------------------------------
  //
  // Google requires the signed content to remain unchanged.
  //
  // Therefore:
  //
  // rawQueryString
  //       ↓
  // exact signed content
  //
  // Individual values are decoded later through req.query.
  //
  // ----------------------------------------------------------

  const queryString =
    rawQueryString;

  // ----------------------------------------------------------
  // SIGNATURE POSITION
  // ----------------------------------------------------------

  const signatureMarker =
    "&signature=";

  const signatureIndex =
    queryString.indexOf(
      signatureMarker,
    );

  if (
    signatureIndex <= 0
  ) {
    throw createError(
      "ADMOB_INVALID_SIGNATURE",
      "AdMob signature parameter was not found.",
    );
  }

  // Everything before "&signature=" is signed.

  const signedQueryString =
    queryString.substring(
      0,
      signatureIndex,
    );

  if (
    !signedQueryString
  ) {
    throw createError(
      "ADMOB_INVALID_SIGNATURE",
      "AdMob signed query content is empty.",
    );
  }

  // ----------------------------------------------------------
  // SIGNATURE + KEY ID
  // ----------------------------------------------------------

  const signatureAndKeyId =
    queryString.substring(
      signatureIndex + 1,
    );

  const signatureParts =
    signatureAndKeyId.split(
      "&",
    );

  if (
    signatureParts.length !==
      2
  ) {
    throw createError(
      "ADMOB_INVALID_SIGNATURE",
      "AdMob signature and key_id must be the final two parameters.",
    );
  }

  const signatureParameter =
    signatureParts[0];

  const keyIdParameter =
    signatureParts[1];

  if (
    !signatureParameter.startsWith(
      "signature=",
    )
  ) {
    throw createError(
      "ADMOB_INVALID_SIGNATURE",
      "AdMob signature must be the second-to-last query parameter.",
    );
  }

  if (
    !keyIdParameter.startsWith(
      "key_id=",
    )
  ) {
    throw createError(
      "ADMOB_INVALID_KEY_ID",
      "AdMob key_id must be the last query parameter.",
    );
  }

  // ----------------------------------------------------------
  // DUPLICATE SIGNATURE / KEY ID
  // ----------------------------------------------------------

  const signedParameters =
    signedQueryString.split(
      "&",
    );

  for (
    const parameter of
    signedParameters
  ) {
    if (
      parameter.startsWith(
        "signature=",
      )
    ) {
      throw createError(
        "ADMOB_INVALID_SIGNATURE",
        "Duplicate AdMob signature parameter.",
      );
    }

    if (
      parameter.startsWith(
        "key_id=",
      )
    ) {
      throw createError(
        "ADMOB_INVALID_KEY_ID",
        "Duplicate AdMob key_id parameter.",
      );
    }
  }

  // ----------------------------------------------------------
  // SIGNATURE + KEY ID VALUES
  // ----------------------------------------------------------

  const signatureValue =
    signatureParameter.substring(
      "signature=".length,
    );

  const keyIdValue =
    keyIdParameter.substring(
      "key_id=".length,
    );

  const signature =
    validateSignature(
      signatureValue,
    );

  const keyId =
    validateKeyId(
      keyIdValue,
    );

  if (!signature) {
    throw createError(
      "ADMOB_INVALID_SIGNATURE",
      "AdMob signature is invalid.",
    );
  }

  if (!keyId) {
    throw createError(
      "ADMOB_INVALID_KEY_ID",
      "AdMob key_id is invalid.",
    );
  }

  const signatureBuffer =
    decodeBase64Url(
      signature,
    );

  // ----------------------------------------------------------
  // PUBLIC KEY
  // ----------------------------------------------------------

  let publicKeys =
    await getAdMobPublicKeys();

  let publicKeyData =
    publicKeys.get(
      keyId,
    );

  // ----------------------------------------------------------
  // PUBLIC KEY ROTATION
  // ----------------------------------------------------------
  //
  // Refresh once when the key is unknown.
  //
  // ----------------------------------------------------------

  if (
    !publicKeyData
  ) {
    publicKeys =
      await getAdMobPublicKeys(
        true,
      );

    publicKeyData =
      publicKeys.get(
        keyId,
      );
  }

  if (
    !publicKeyData
  ) {
    throw createError(
      "ADMOB_PUBLIC_KEY_NOT_FOUND",
      "AdMob public key was not found.",
    );
  }

  // ----------------------------------------------------------
  // CRYPTOGRAPHIC VERIFICATION
  // ----------------------------------------------------------

  let valid =
    false;

  try {
    valid =
      verifySignedQuery(
        publicKeyData,
        signedQueryString,
        signatureBuffer,
      );
  } catch (
    error
  ) {
    console.error(
      "❌ AdMob SSV cryptographic verification error.",
      {
        keyId,

        signedQueryLength:
          signedQueryString.length,

        error:
          error?.message ||
          String(error),
      },
    );

    throw createError(
      "ADMOB_INVALID_SIGNATURE",
      "AdMob signature verification failed.",
    );
  }

  if (!valid) {
    throw createError(
      "ADMOB_INVALID_SIGNATURE",
      "AdMob signature verification failed.",
    );
  }

  console.log(
    "🐱 AdMob SSV signature verified.",
    {
      keyId,

      signedQueryLength:
        signedQueryString.length,
    },
  );

  return {
    verified:
      true,

    signature,

    keyId,

    signedQueryString,

    rawQueryString,
  };
}

// ============================================================
// 🔎 QUERY VALUE
// ============================================================
//
// req.query is used only after cryptographic verification.
//
// Express/query parser has already decoded the individual
// parameter values for application-level validation.
//
// ============================================================

function getQueryValue(
  query,
  key,
) {
  const value =
    query?.[key];

  if (
    Array.isArray(value)
  ) {
    return value.length ===
      1
      ? normalizeString(
          value[0],
        )
      : "";
  }

  return normalizeString(
    value,
  );
}

// ============================================================
// 🧩 CUSTOM DATA
// ============================================================
//
// AdMob custom_data may be percent escaped.
//
// Decode only this individual value.
//
// ============================================================

function decodeCustomDataValue(
  value,
) {
  const normalized =
    normalizeString(
      value,
    );

  if (!normalized) {
    return "";
  }

  if (
    !/%[0-9A-Fa-f]{2}/.test(
      normalized,
    )
  ) {
    return normalized;
  }

  try {
    return normalizeString(
      decodeURIComponent(
        normalized,
      ),
    );
  } catch (_) {
    throw createError(
      "ADMOB_CUSTOM_DATA_INVALID",
      "AdMob custom_data contains invalid URL encoding.",
    );
  }
}

// ============================================================
// 🧩 PARSE CUSTOM DATA
// ============================================================
//
// Expected:
//
// uid:rewardPurpose
//
// Examples:
//
// abc123:mining_start
// abc123:power_boost
//
// ============================================================

function parseCustomData(
  value,
) {
  const decoded =
    decodeCustomDataValue(
      value,
    );

  if (
    !decoded ||
    decoded.length >
      MAX_CUSTOM_DATA_LENGTH ||
    /[\u0000-\u001F\u007F]/.test(
      decoded,
    )
  ) {
    throw createError(
      "ADMOB_CUSTOM_DATA_INVALID",
      "AdMob custom_data is missing or invalid.",
    );
  }

  const separator =
    decoded.indexOf(
      ":",
    );

  if (
    separator <= 0 ||
    separator ===
      decoded.length - 1 ||
    decoded.indexOf(
      ":",
      separator + 1,
    ) !== -1
  ) {
    throw createError(
      "ADMOB_CUSTOM_DATA_MISSING",
      "AdMob custom_data has an invalid format.",
    );
  }

  const uid =
    validateUid(
      decoded.substring(
        0,
        separator,
      ),
    );

  const rewardPurpose =
    validateRewardPurpose(
      decoded.substring(
        separator + 1,
      ),
    );

  if (!uid) {
    throw createError(
      "ADMOB_INVALID_UID",
      "AdMob custom_data contains an invalid UID.",
    );
  }

  if (!rewardPurpose) {
    throw createError(
      "ADMOB_INVALID_REWARD_PURPOSE",
      "AdMob custom_data contains an invalid reward purpose.",
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
// ⚙️ EXPECTED CONFIG
// ============================================================

function getExpectedAdMobConfig(
  rewardPurpose,
) {
  const config =
    REWARD_CONFIG[
      rewardPurpose
    ];

  if (!config) {
    throw createError(
      "ADMOB_INVALID_REWARD_PURPOSE",
      "Unknown AdMob reward purpose.",
    );
  }

  const adUnit =
    normalizeString(
      config.adUnit,
    );

  const rewardItem =
    normalizeString(
      config.rewardItem,
    );

  const rewardAmount =
    Number(
      config.rewardAmount,
    );

  if (
    !adUnit ||
    adUnit.length >
      MAX_AD_UNIT_LENGTH ||
    !Number.isSafeInteger(
      rewardAmount,
    ) ||
    rewardAmount < 0 ||
    !rewardItem ||
    rewardItem.length >
      MAX_REWARD_ITEM_LENGTH
  ) {
    throw createError(
      "ADMOB_INVALID_REWARD_CONFIGURATION",
      "Invalid AdMob reward configuration.",
    );
  }

  return {
    adUnit,

    rewardAmount,

    rewardItem,
  };
}

// ============================================================
// 🌐 RAW QUERY CANDIDATES
// ============================================================
//
// originalUrl is preferred because it preserves the original
// request URL through Express routing.
//
// req.url is kept as a fallback.
//
// We NEVER build the signed query from req.query.
//
// ============================================================

function getRawQueryCandidates(
  req,
) {
  const candidates = [
    req?.originalUrl,
    req?.url,
  ];

  const queries = [];

  for (
    const candidate of
    candidates
  ) {
    if (
      typeof candidate !==
        "string" ||
      !candidate
    ) {
      continue;
    }

    const questionMark =
      candidate.indexOf(
        "?",
      );

    if (
      questionMark ===
        -1
    ) {
      continue;
    }

    const query =
      candidate.substring(
        questionMark + 1,
      );

    if (
      !query ||
      query.includes(
        "#",
      )
    ) {
      continue;
    }

    if (
      query.length >
      MAX_QUERY_STRING_LENGTH
    ) {
      throw createError(
        "ADMOB_QUERY_STRING_TOO_LARGE",
        "AdMob query string is too large.",
      );
    }

    if (
      !queries.includes(
        query,
      )
    ) {
      queries.push(
        query,
      );
    }
  }

  return queries;
}

// ============================================================
// 🔐 VERIFY REQUEST
// ============================================================

async function verifyFromRequest(
  req,
) {
  if (!req) {
    throw createError(
      "ADMOB_REQUEST_MISSING",
      "AdMob request is missing.",
    );
  }

  const method =
    normalizeString(
      req.method,
    ).toUpperCase();

  if (
    method &&
    method !== "GET"
  ) {
    throw createError(
      "ADMOB_INVALID_HTTP_METHOD",
      "AdMob SSV callback must use HTTP GET.",
    );
  }

  const candidates =
    getRawQueryCandidates(
      req,
    );

  if (
    !candidates.length
  ) {
    throw createError(
      "ADMOB_QUERY_STRING_MISSING",
      "AdMob query string is missing.",
    );
  }

  let lastError =
    null;

  for (
    const query of
    candidates
  ) {
    try {
      return await verifyAdMobSignature(
        query,
      );
    } catch (
      error
    ) {
      lastError =
        error;
    }
  }

  throw (
    lastError ||
    createError(
      "ADMOB_INVALID_SIGNATURE",
      "AdMob signature verification failed.",
    )
  );
}

// ============================================================
// 🔐 COMPLETE ADMOB CALLBACK VERIFICATION
// ============================================================
//
// Processing order:
//
// 1. Verify raw cryptographic signature.
// 2. Read decoded query parameters.
// 3. Validate parameters.
// 4. Validate custom_data.
// 5. Validate server configuration.
// 6. Validate optional user_id.
// 7. Return verified reward information.
//
// ============================================================

async function verifyAdMobCallback(
  req,
) {
  if (!req) {
    throw createError(
      "ADMOB_REQUEST_MISSING",
      "AdMob request is missing.",
    );
  }

  // ----------------------------------------------------------
  // 1. CRYPTOGRAPHIC VERIFICATION
  // ----------------------------------------------------------

  const cryptographicResult =
    await verifyFromRequest(
      req,
    );

  // ----------------------------------------------------------
  // 2. PARSED QUERY
  // ----------------------------------------------------------

  const query =
    req.query ||
    {};

  const adNetwork =
    getQueryValue(
      query,
      "ad_network",
    );

  const adUnit =
    getQueryValue(
      query,
      "ad_unit",
    );

  const rewardAmount =
    getQueryValue(
      query,
      "reward_amount",
    );

  const rewardItem =
    getQueryValue(
      query,
      "reward_item",
    );

  const transactionId =
    getQueryValue(
      query,
      "transaction_id",
    );

  const timestamp =
    getQueryValue(
      query,
      "timestamp",
    );

  const userId =
    getQueryValue(
      query,
      "user_id",
    );

  const customData =
    getQueryValue(
      query,
      "custom_data",
    );

  // ----------------------------------------------------------
  // 3. REQUIRED PARAMETERS
  // ----------------------------------------------------------

  if (
    !adNetwork ||
    !adUnit ||
    rewardAmount === "" ||
    !rewardItem ||
    !transactionId ||
    !timestamp ||
    !customData
  ) {
    throw createError(
      "ADMOB_REQUIRED_PARAMETER_MISSING",
      "One or more required AdMob parameters are missing.",
    );
  }

  // ----------------------------------------------------------
  // 4. VALIDATION
  // ----------------------------------------------------------

  const validatedAdNetwork =
    validateAdNetwork(
      adNetwork,
    );

  const validatedAdUnit =
    normalizeString(
      adUnit,
    );

  const validatedRewardAmount =
    Number(
      rewardAmount,
    );

  const validatedRewardItem =
    normalizeString(
      rewardItem,
    );

  const validatedTransactionId =
    validateTransactionId(
      transactionId,
    );

  const validatedTimestamp =
    validateTimestamp(
      timestamp,
    );

  if (
    !validatedAdNetwork
  ) {
    throw createError(
      "ADMOB_INVALID_AD_NETWORK",
      "AdMob ad_network is invalid.",
    );
  }

  if (
    !validatedAdUnit ||
    validatedAdUnit.length >
      MAX_AD_UNIT_LENGTH
  ) {
    throw createError(
      "ADMOB_INVALID_AD_UNIT",
      "AdMob ad_unit is invalid.",
    );
  }

  if (
    !Number.isSafeInteger(
      validatedRewardAmount,
    ) ||
    validatedRewardAmount < 0
  ) {
    throw createError(
      "ADMOB_INVALID_REWARD_AMOUNT",
      "AdMob reward_amount is invalid.",
    );
  }

  if (
    !validatedRewardItem ||
    validatedRewardItem.length >
      MAX_REWARD_ITEM_LENGTH
  ) {
    throw createError(
      "ADMOB_INVALID_REWARD_ITEM",
      "AdMob reward_item is invalid.",
    );
  }

  if (
    !validatedTransactionId
  ) {
    throw createError(
      "ADMOB_INVALID_TRANSACTION_ID",
      "AdMob transaction_id is invalid.",
    );
  }

  if (
    !validatedTimestamp
  ) {
    throw createError(
      "ADMOB_INVALID_TIMESTAMP",
      "AdMob timestamp is invalid.",
    );
  }

  // ----------------------------------------------------------
  // 5. CUSTOM DATA
  // ----------------------------------------------------------

  const {
    uid,
    rewardPurpose,
    customData:
      normalizedCustomData,
  } =
    parseCustomData(
      customData,
    );

  // ----------------------------------------------------------
  // 6. SERVER CONFIGURATION
  // ----------------------------------------------------------

  const expected =
    getExpectedAdMobConfig(
      rewardPurpose,
    );

  if (
    validatedAdUnit !==
    expected.adUnit
  ) {
    throw createError(
      "ADMOB_INVALID_AD_UNIT",
      "AdMob ad_unit does not match server configuration.",
    );
  }

  if (
    validatedRewardAmount !==
    expected.rewardAmount
  ) {
    throw createError(
      "ADMOB_INVALID_REWARD_AMOUNT",
      "AdMob reward_amount does not match server configuration.",
    );
  }

  if (
    validatedRewardItem !==
    expected.rewardItem
  ) {
    throw createError(
      "ADMOB_INVALID_REWARD_ITEM",
      "AdMob reward_item does not match server configuration.",
    );
  }

  // ----------------------------------------------------------
  // 7. USER ID
  // ----------------------------------------------------------
  //
  // user_id is optional in AdMob SSV.
  //
  // If present, it must match the UID encoded into
  // custom_data.
  //
  // ----------------------------------------------------------

  let normalizedUserId =
    "";

  if (
    userId
  ) {
    normalizedUserId =
      validateUid(
        userId,
      );

    if (
      !normalizedUserId
    ) {
      throw createError(
        "ADMOB_INVALID_UID",
        "AdMob user_id is invalid.",
      );
    }

    if (
      normalizedUserId !==
      uid
    ) {
      throw createError(
        "ADMOB_USER_ID_MISMATCH",
        "AdMob user_id does not match the verified UID.",
      );
    }
  }

  // ----------------------------------------------------------
  // 8. VERIFIED RESULT
  // ----------------------------------------------------------

  return {
    verified:
      true,

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