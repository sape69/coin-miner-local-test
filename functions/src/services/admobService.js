"use strict";

// ============================================================
// 🐱 STELLURIINI - ADMOB SERVICE
// ============================================================
//
// Vastuu:
//
// 🔐 AdMob Rewarded SSV -allekirjoituksen varmennus
// 🔑 Public key -haku ja cache
// 🛡️ SSV-parametrien validointi
// 🆔 UID / transaction_id -validointi
// 🎯 reward purpose -validointi
//
// EI:
//
// ❌ Firestore-kirjoituksia
// ❌ STL-saldon muutoksia
// ❌ mining-tilan muutoksia
// ❌ Power Boostin aktivointia
//
// ============================================================

const {
  createVerify,
} = require("crypto");

const https =
  require("https");

const {
  ADMOB_MINING_AD_UNIT_ID,
  ADMOB_POWER_BOOST_AD_UNIT_ID,

  ADMOB_MINING_SSV_REWARD_AMOUNT,
  ADMOB_MINING_SSV_REWARD_ITEM,

  ADMOB_POWER_BOOST_SSV_REWARD_AMOUNT,
  ADMOB_POWER_BOOST_SSV_REWARD_ITEM,
} = require("../config/miningConfig");

// ============================================================
// CONFIG
// ============================================================

const ADMOB_SSV_KEYS_URL =
  "https://www.gstatic.com/admob/reward/verifier-keys.json";

const PUBLIC_KEY_CACHE_MS =
  23 * 60 * 60 * 1000;

const PUBLIC_KEY_FETCH_TIMEOUT_MS =
  10 * 1000;

const PUBLIC_KEY_MAX_RESPONSE_BYTES =
  1024 * 1024;

const MAX_QUERY_STRING_LENGTH =
  16 * 1024;

const MAX_CUSTOM_DATA_LENGTH =
  256;

const MAX_AD_UNIT_LENGTH =
  256;

const MAX_REWARD_ITEM_LENGTH =
  256;

const MAX_AD_NETWORK_LENGTH =
  32;

const MAX_KEY_ID_LENGTH =
  32;

const MAX_TRANSACTION_ID_LENGTH =
  256;

const MAX_SIGNATURE_LENGTH =
  8192;

const MAX_UID_LENGTH =
  128;

// AdMob SSV timestamp is Epoch milliseconds.
//
// Tämä tarkistus estää liian vanhojen tai
// tulevaisuuteen sijoittuvien callbackien hyväksymisen.
//
// Varsinainen replay-suojaus kuuluu transaction_id:n
// idempotenttiin käsittelyyn myöhemmässä palvelukerroksessa.

const TIMESTAMP_MAX_AGE_MS =
  24 * 60 * 60 * 1000;

const TIMESTAMP_FUTURE_TOLERANCE_MS =
  5 * 60 * 1000;

// ============================================================
// REWARD CONFIG
// ============================================================

const REWARD_CONFIG =
  Object.freeze({
    mining_start:
      Object.freeze({
        adUnit:
          ADMOB_MINING_AD_UNIT_ID,

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
          ADMOB_POWER_BOOST_AD_UNIT_ID,

        rewardAmount:
          Number(
            ADMOB_POWER_BOOST_SSV_REWARD_AMOUNT,
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
// CACHE
// ============================================================

let publicKeyCache = null;

let publicKeyFetchPromise =
  null;

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

  error.code = code;

  return error;
}

// ============================================================
// UID
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

  return /^[A-Za-z0-9._-]+$/.test(
    uid,
  )
    ? uid
    : "";
}

// ============================================================
// TRANSACTION ID
// ============================================================
//
// AdMob SSV transaction_id:
//
// Yksilöllinen reward-tapahtuman tunniste.
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

  return /^[A-Fa-f0-9]+$/.test(
    transactionId,
  )
    ? transactionId
    : "";
}

// ============================================================
// REWARD PURPOSE
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
// AD NETWORK
// ============================================================

function validateAdNetwork(
  value,
) {
  const network =
    normalizeString(value);

  if (
    !network ||
    network.length >
      MAX_AD_NETWORK_LENGTH
  ) {
    return "";
  }

  return /^\d+$/.test(
    network,
  )
    ? network
    : "";
}

// ============================================================
// TIMESTAMP
// ============================================================
//
// AdMob timestamp:
// Epoch milliseconds.
//
// ============================================================

function validateTimestamp(
  value,
) {
  const raw =
    normalizeString(
      String(
        value ?? "",
      ),
    );

  if (
    !raw ||
    !/^\d+$/.test(raw)
  ) {
    return 0;
  }

  const timestamp =
    Number(raw);

  if (
    !Number.isSafeInteger(
      timestamp,
    ) ||
    timestamp <= 0
  ) {
    return 0;
  }

  const now =
    Date.now();

  if (
    timestamp <
      now -
        TIMESTAMP_MAX_AGE_MS ||
    timestamp >
      now +
        TIMESTAMP_FUTURE_TOLERANCE_MS
  ) {
    return 0;
  }

  return timestamp;
}

// ============================================================
// KEY ID
// ============================================================
//
// AdMob SSV query:
//
// key_id=1234567890
//
// Public key JSON voi käyttää:
//
// "keyId": 1234567890
//
// tai:
//
// "keyId": "1234567890"
//
// Molemmat hyväksytään.
//
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
      MAX_KEY_ID_LENGTH
  ) {
    return "";
  }

  return /^\d+$/.test(
    keyId,
  )
    ? keyId
    : "";
}

// ============================================================
// SIGNATURE
// ============================================================
//
// AdMob käyttää URL-safe Base64 -allekirjoitusta.
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
      MAX_SIGNATURE_LENGTH
  ) {
    return "";
  }

  if (
    !/^[A-Za-z0-9_-]+$/.test(
      signature,
    )
  ) {
    return "";
  }

  // Base64URL ei voi päättyä
  // yhden merkin vajaaseen quantumaan.

  if (
    signature.length % 4 === 1
  ) {
    return "";
  }

  return signature;
}

// ============================================================
// BASE64URL DECODE
// ============================================================

function decodeBase64Url(
  value,
) {
  const signature =
    validateSignature(
      value,
    );

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

  const remainder =
    base64.length % 4;

  const padded =
    remainder === 0
      ? base64
      : base64 +
        "=".repeat(
          4 - remainder,
        );

  let buffer;

  try {
    buffer =
      Buffer.from(
        padded,
        "base64",
      );
  } catch {
    throw createError(
      "ADMOB_INVALID_SIGNATURE",
      "AdMob signature could not be decoded.",
    );
  }

  if (!buffer.length) {
    throw createError(
      "ADMOB_INVALID_SIGNATURE",
      "AdMob signature could not be decoded.",
    );
  }

  return buffer;
}

// ============================================================
// PUBLIC KEY FETCH
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

          settled = true;

          reject(error);
        };

      const succeed =
        (value) => {
          if (settled) {
            return;
          }

          settled = true;

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
            (response) => {
              const statusCode =
                response.statusCode ||
                0;

              if (
                statusCode < 200 ||
                statusCode >= 300
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

              let body = "";

              let bodyBytes = 0;

              response.setEncoding(
                "utf8",
              );

              response.on(
                "data",
                (chunk) => {
                  if (settled) {
                    return;
                  }

                  const chunkBytes =
                    Buffer.byteLength(
                      chunk,
                      "utf8",
                    );

                  bodyBytes +=
                    chunkBytes;

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

                  body += chunk;
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
                  } catch {
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

                    if (
                      !keyId ||
                      !pem ||
                      !pem.includes(
                        "-----BEGIN PUBLIC KEY-----",
                      ) ||
                      !pem.includes(
                        "-----END PUBLIC KEY-----",
                      )
                    ) {
                      continue;
                    }

                    keys.set(
                      keyId,
                      pem,
                    );
                  }

                  if (!keys.size) {
                    fail(
                      createError(
                        "ADMOB_PUBLIC_KEYS_EMPTY",
                        "AdMob public key response contains no valid keys.",
                      ),
                    );

                    return;
                  }

                  succeed(keys);
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
      } catch {
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
// PUBLIC KEY CACHE
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

  if (publicKeyFetchPromise) {
    return publicKeyFetchPromise;
  }

  publicKeyFetchPromise =
    fetchPublicKeys()
      .then(
        (keys) => {
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
// VERIFY SIGNATURE
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

  const parameters =
    rawQueryString.split(
      "&",
    );

  if (
    parameters.length < 3
  ) {
    throw createError(
      "ADMOB_INVALID_SIGNATURE",
      "AdMob SSV query does not contain enough parameters.",
    );
  }

  // ==========================================================
  // SIGNATURE + KEY_ID
  // ==========================================================
  //
  // AdMob määrittelee signature- ja key_id-parametrit
  // queryn kahdeksi viimeiseksi parametriksi.
  //
  // Allekirjoitettava query-string on kaikki niitä
  // edeltävät parametrit TÄSMÄLLEEN alkuperäisessä
  // järjestyksessä ja muodossa.
  //
  // ==========================================================

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
      "signature=",
    )
  ) {
    throw createError(
      "ADMOB_INVALID_SIGNATURE",
      "AdMob signature parameter is invalid.",
    );
  }

  if (
    !keyIdParameter.startsWith(
      "key_id=",
    )
  ) {
    throw createError(
      "ADMOB_INVALID_KEY_ID",
      "AdMob key_id parameter is invalid.",
    );
  }

  // ==========================================================
  // EMPTY PARAMETERS
  // ==========================================================

  for (
    const parameter of
    parameters
  ) {
    if (!parameter) {
      throw createError(
        "ADMOB_INVALID_SIGNATURE",
        "AdMob SSV query contains an empty parameter.",
      );
    }
  }

  // ==========================================================
  // DUPLICATE SIGNATURE / KEY_ID
  // ==========================================================

  for (
    let i = 0;
    i <
      parameters.length - 2;
    i += 1
  ) {
    if (
      parameters[i].startsWith(
        "signature=",
      )
    ) {
      throw createError(
        "ADMOB_INVALID_SIGNATURE",
        "Duplicate AdMob signature parameter.",
      );
    }

    if (
      parameters[i].startsWith(
        "key_id=",
      )
    ) {
      throw createError(
        "ADMOB_INVALID_KEY_ID",
        "Duplicate AdMob key_id parameter.",
      );
    }
  }

  // ==========================================================
  // VALIDATE SIGNATURE
  // ==========================================================

  const signature =
    validateSignature(
      signatureParameter.substring(
        "signature=".length,
      ),
    );

  if (!signature) {
    throw createError(
      "ADMOB_INVALID_SIGNATURE",
      "AdMob signature is invalid.",
    );
  }

  // ==========================================================
  // VALIDATE KEY ID
  // ==========================================================

  const keyId =
    validateKeyId(
      keyIdParameter.substring(
        "key_id=".length,
      ),
    );

  if (!keyId) {
    throw createError(
      "ADMOB_INVALID_KEY_ID",
      "AdMob key_id is invalid.",
    );
  }

  // ==========================================================
  // SIGNED QUERY
  // ==========================================================
  //
  // ÄLÄ:
  //
  // ❌ decodeURIComponent()
  // ❌ encodeURIComponent()
  // ❌ reorder
  // ❌ normalize
  // ❌ trim
  // ❌ muokkaa parametreja
  //
  // AdMob allekirjoittaa alkuperäisen query-stringin.
  //
  // ==========================================================

  const signedQueryString =
    parameters
      .slice(0, -2)
      .join("&");

  if (!signedQueryString) {
    throw createError(
      "ADMOB_QUERY_STRING_MISSING",
      "AdMob signed query string is empty.",
    );
  }

  // ==========================================================
  // PUBLIC KEY
  // ==========================================================

  let publicKeys =
    await getAdMobPublicKeys();

  let publicKey =
    publicKeys.get(
      keyId,
    );

  // Public key voi vaihtua Googlen key rotationissa.
  // Yritetään kerran cache-ohituksella.

  if (!publicKey) {
    publicKeys =
      await getAdMobPublicKeys(
        true,
      );

    publicKey =
      publicKeys.get(
        keyId,
      );
  }

  if (!publicKey) {
    throw createError(
      "ADMOB_PUBLIC_KEY_NOT_FOUND",
      "AdMob public key was not found.",
    );
  }

  // ==========================================================
  // SIGNATURE BUFFER
  // ==========================================================

  const signatureBuffer =
    decodeBase64Url(
      signature,
    );

  // ==========================================================
  // CRYPTOGRAPHIC VERIFICATION
  // ==========================================================

  try {
    const verifier =
      createVerify(
        "SHA256",
      );

    verifier.update(
      Buffer.from(
        signedQueryString,
        "utf8",
      ),
    );

    verifier.end();

    const valid =
      verifier.verify(
        publicKey,
        signatureBuffer,
      );

    if (!valid) {
      throw createError(
        "ADMOB_INVALID_SIGNATURE",
        "AdMob signature verification failed.",
      );
    }
  } catch (error) {
    if (
      error?.code ===
      "ADMOB_INVALID_SIGNATURE"
    ) {
      throw error;
    }

    throw createError(
      "ADMOB_CRYPTO_VERIFICATION_ERROR",
      "AdMob cryptographic verification failed.",
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
// CUSTOM DATA
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
// IMPORTANT:
//
// AdMob/Express voi antaa custom_data-arvon jo
// dekoodattuna req.query:ssa.
//
// Siksi tätä funktiota ei saa käyttää niin,
// että arvo dekoodataan automaattisesti kahdesti.
//
// ============================================================

function parseCustomData(
  value,
) {
  const raw =
    normalizeString(
      value,
    );

  if (
    !raw ||
    raw.length >
      MAX_CUSTOM_DATA_LENGTH
  ) {
    throw createError(
      "ADMOB_CUSTOM_DATA_MISSING",
      "AdMob custom_data is missing or invalid.",
    );
  }

  // ==========================================================
  // VALIDATE CONTROL CHARACTERS
  // ==========================================================

  if (
    /[\u0000-\u001F\u007F]/.test(
      raw,
    )
  ) {
    throw createError(
      "ADMOB_CUSTOM_DATA_INVALID",
      "AdMob custom_data is invalid.",
    );
  }

  // ==========================================================
  // EXPECTED FORMAT
  // ==========================================================

  const separator =
    raw.indexOf(":");

  if (
    separator <= 0 ||
    separator ===
      raw.length - 1 ||
    raw.indexOf(
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
      raw.substring(
        0,
        separator,
      ),
    );

  const rewardPurpose =
    validateRewardPurpose(
      raw.substring(
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
// EXPECTED CONFIG
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
// QUERY VALUE
// ============================================================
//
// req.query voi sisältää joko:
//
// string
//
// tai:
//
// string[]
//
// Jos sama parametri esiintyy useita kertoja,
// hylätään pyyntö.
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
    return value.length === 1
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
// VERIFY COMPLETE CALLBACK
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

  // ==========================================================
  // ORIGINAL URL
  // ==========================================================
  //
  // Allekirjoituksen varmennuksessa tarvitsemme alkuperäisen
  // query-stringin muuttamattomana.
  //
  // ==========================================================

  const originalUrl =
    typeof req.originalUrl ===
      "string" &&
    req.originalUrl
      ? req.originalUrl
      : typeof req.url ===
          "string" &&
        req.url
        ? req.url
        : "";

  const questionMark =
    originalUrl.indexOf("?");

  if (
    questionMark === -1
  ) {
    throw createError(
      "ADMOB_QUERY_STRING_MISSING",
      "AdMob query string is missing.",
    );
  }

  const rawQueryString =
    originalUrl.substring(
      questionMark + 1,
    );

  if (!rawQueryString) {
    throw createError(
      "ADMOB_QUERY_STRING_MISSING",
      "AdMob query string is empty.",
    );
  }

  // ==========================================================
  // 🔐 CRYPTOGRAPHIC SIGNATURE
  // ==========================================================

  const cryptographicResult =
    await verifyAdMobSignature(
      rawQueryString,
    );

  // ==========================================================
  // QUERY
  // ==========================================================

  const query =
    req.query || {};

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

  // ==========================================================
  // REQUIRED PARAMETERS
  // ==========================================================

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
      "One or more required AdMob parameters are missing.",
    );
  }

  // ==========================================================
  // BASIC VALIDATION
  // ==========================================================

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

  if (!validatedAdNetwork) {
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

  if (!validatedTransactionId) {
    throw createError(
      "ADMOB_INVALID_TRANSACTION_ID",
      "AdMob transaction_id is invalid.",
    );
  }

  if (!validatedTimestamp) {
    throw createError(
      "ADMOB_INVALID_TIMESTAMP",
      "AdMob timestamp is invalid.",
    );
  }

  // ==========================================================
  // 🎯 CUSTOM DATA
  // ==========================================================

  const {
    uid,
    rewardPurpose,
    customData:
      normalizedCustomData,
  } =
    parseCustomData(
      customData,
    );

  // ==========================================================
  // 🎯 SERVER CONFIGURATION
  // ==========================================================

  const expected =
    getExpectedAdMobConfig(
      rewardPurpose,
    );

  // ==========================================================
  // AD UNIT
  // ==========================================================

  if (
    validatedAdUnit !==
    expected.adUnit
  ) {
    throw createError(
      "ADMOB_INVALID_AD_UNIT",
      "AdMob ad_unit does not match server configuration.",
    );
  }

  // ==========================================================
  // REWARD AMOUNT
  // ==========================================================

  if (
    validatedRewardAmount !==
    expected.rewardAmount
  ) {
    throw createError(
      "ADMOB_INVALID_REWARD_AMOUNT",
      "AdMob reward_amount does not match server configuration.",
    );
  }

  // ==========================================================
  // REWARD ITEM
  // ==========================================================

  if (
    validatedRewardItem !==
    expected.rewardItem
  ) {
    throw createError(
      "ADMOB_INVALID_REWARD_ITEM",
      "AdMob reward_item does not match server configuration.",
    );
  }

  // ==========================================================
  // 🆔 USER ID
  // ==========================================================

  let normalizedUserId =
    "";

  if (userId) {
    normalizedUserId =
      validateUid(
        userId,
      );

    if (!normalizedUserId) {
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

  // ==========================================================
  // 📦 VERIFIED RESULT
  // ==========================================================

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
  };
}

// ============================================================
// EXPORTS
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