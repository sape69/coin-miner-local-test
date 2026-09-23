"use strict";

// ============================================================
// 🐱 STELLURIINI - ADMOB SERVICE
// ============================================================
//
// Vastuu:
//
// 🔐 AdMob Rewarded SSV -allekirjoituksen varmennus
// 🔑 AdMob public key -avainten lataus ja cache
// 🧩 SSV-parametrien validointi
// 👤 UID:n validointi
// 🎯 reward purposen tunnistus custom_data:sta
// 🆔 transaction_id:n validointi
// 🕒 timestamp-validointi
// 📺 Ad Unit / reward configuration -validointi
// 🛡️ user_id:n ja UID:n vastaavuuden tarkistus
//
// TÄMÄ TIEDOSTO EI:
//
// ❌ kirjoita Firestoreen
// ❌ lisää STL-saldoa
// ❌ käynnistä louhintaa
// ❌ aktivoi Power Boostia
// ❌ muuta miningBalancea
// ❌ muuta adsToday-arvoa
// ❌ muuta cooldownia
//
// Varsinainen SSV-tapahtuman tallennus kuuluu:
//
// functions/src/functions/adFunctions.js
//
// Varsinainen Mining / Power Boost -business-logiikka kuuluu:
//
// functions/src/functions/miningFunctions.js
//
// ============================================================

// ============================================================
// 🔐 NODE CRYPTO
// ============================================================

const {
  createVerify,
} = require(
  "crypto",
);

// ============================================================
// 🌐 NODE HTTPS
// ============================================================

const https =
  require(
    "https",
  );

// ============================================================
// 🔑 ADMOB PUBLIC KEY URL
// ============================================================

const ADMOB_SSV_KEYS_URL =
  "https://www.gstatic.com/admob/reward/verifier-keys.json";

// ============================================================
// 🕒 PUBLIC KEY CACHE
// ============================================================
//
// Public keyt cachetetaan enintään 23 tunniksi.
//
// Google edellyttää, että public keyt päivitetään viimeistään
// 24 tunnin sisällä, koska avaimet voivat vaihtua.
// 23 tuntia jättää tarkoituksellisen turvamarginaalin.
//
// ============================================================

const ADMOB_PUBLIC_KEY_CACHE_MS =
  23 *
  60 *
  60 *
  1000;

// ============================================================
// 🌐 PUBLIC KEY FETCH TIMEOUT
// ============================================================

const ADMOB_PUBLIC_KEY_FETCH_TIMEOUT_MS =
  10 *
  1000;

// ============================================================
// 📦 MAX PUBLIC KEY RESPONSE SIZE
// ============================================================

const ADMOB_PUBLIC_KEY_MAX_RESPONSE_BYTES =
  1024 *
  1024;

// ============================================================
// 🕒 TIMESTAMP LIMITS
// ============================================================
//
// AdMob timestamp on Epoch time millisekunteina.
//
// Sallitaan:
//
// - enintään 24 tuntia vanha callback
// - enintään 5 minuuttia tulevaisuudessa oleva callback
//
// ============================================================

const ADMOB_TIMESTAMP_MAX_AGE_MS =
  24 *
  60 *
  60 *
  1000;

const ADMOB_TIMESTAMP_FUTURE_TOLERANCE_MS =
  5 *
  60 *
  1000;

// ============================================================
// 📺 ADMOB AD UNITS
// ============================================================
//
// Stelluriinin server-side odotetut Ad Unit ID:t.
//
// HUOM:
//
// Nämä ovat AdMob Ad Unit ID:t,
// eivät Android package ID:t.
//
// ============================================================

const ADMOB_AD_UNITS =
  Object.freeze({
    mining_start:
      "6674097787",

    power_boost:
      "7225738491",
  });

// ============================================================
// 🎁 REWARD DEFINITIONS
// ============================================================
//
// HUOM:
//
// rewardAmount EI tarkoita STL-määrää.
//
// AdMob rewardAmount on rewarded-ad-konfiguraation arvo.
//
// adFunctions.js käyttää tätä audit-validointiin.
//
// ============================================================

const REWARD_DEFINITIONS =
  Object.freeze({
    mining_start:
      Object.freeze({
        rewardAmount:
          1,

        rewardItem:
          "mining_start",
      }),

    power_boost:
      Object.freeze({
        rewardAmount:
          1,

        rewardItem:
          "power_boost",
      }),
  });

// ============================================================
// 🎯 VALID REWARD PURPOSES
// ============================================================

const VALID_REWARD_PURPOSES =
  new Set([
    "mining_start",
    "power_boost",
  ]);

// ============================================================
// 🔐 PUBLIC KEY CACHE
// ============================================================

let publicKeyCache =
  null;

// ============================================================
// 🔄 PUBLIC KEY FETCH IN FLIGHT
// ============================================================
//
// Estää useita samanaikaisia public-key HTTP-pyyntöjä,
// jos Cloud Functions -instanssi vastaanottaa useita SSV
// callbackeja juuri cache-expiration hetkellä.
//
// ============================================================

let publicKeyFetchPromise =
  null;

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
// 🛡️ CREATE ERROR
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
// 👤 VALIDATE UID
// ============================================================
//
// Stelluriinin custom_data käyttää:
//
// UID:rewardPurpose
//
// Tämän vuoksi UID:ssä sallitaan vain turvalliset
// yksittäisen segmentin merkit.
//
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
// 🆔 VALIDATE TRANSACTION ID
// ============================================================
//
// AdMob määrittelee transaction_id:n yksilölliseksi
// hex-enkoodatuksi reward event -tunnisteeksi.
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
// 📺 VALIDATE AD NETWORK
// ============================================================
//
// AdMob SSV käyttää ad_network-parametrina
// ad source identifieria.
//
// ============================================================

function validateAdNetwork(
  value,
) {
  if (
    typeof value !==
    "string"
  ) {
    return "";
  }

  const adNetwork =
    value.trim();

  if (
    adNetwork.length === 0 ||
    adNetwork.length > 32
  ) {
    return "";
  }

  if (
    !/^\d+$/.test(
      adNetwork,
    )
  ) {
    return "";
  }

  return adNetwork;
}

// ============================================================
// 🕒 VALIDATE TIMESTAMP
// ============================================================

function validateTimestamp(
  value,
) {
  const timestamp =
    Number(
      value,
    );

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

  const minimumAllowed =
    now -
    ADMOB_TIMESTAMP_MAX_AGE_MS;

  const maximumAllowed =
    now +
    ADMOB_TIMESTAMP_FUTURE_TOLERANCE_MS;

  if (
    timestamp <
      minimumAllowed ||
    timestamp >
      maximumAllowed
  ) {
    return 0;
  }

  return timestamp;
}

// ============================================================
// 🔢 VALIDATE KEY ID
// ============================================================

function validateKeyId(
  value,
) {
  const keyId =
    normalizeString(
      value,
    );

  if (
    keyId.length === 0 ||
    keyId.length > 32
  ) {
    return "";
  }

  if (
    !/^\d+$/.test(
      keyId,
    )
  ) {
    return "";
  }

  return keyId;
}

// ============================================================
// 🔐 VALIDATE SIGNATURE
// ============================================================
//
// AdMob käyttää URL-safe Base64 -muotoista signaturea.
//
// ============================================================

function validateSignature(
  value,
) {
  const signature =
    normalizeString(
      value,
    );

  if (
    signature.length === 0 ||
    signature.length > 8192
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

  // Base64URL:n pituus ei voi olla muodossa mod 4 === 1.
  if (
    signature.length %
      4 ===
    1
  ) {
    return "";
  }

  return signature;
}

// ============================================================
// 🔐 BASE64URL → BUFFER
// ============================================================

function decodeBase64Url(
  value,
) {
  const validated =
    validateSignature(
      value,
    );

  if (
    !validated
  ) {
    throw createError(
      "ADMOB_INVALID_SIGNATURE",
      "AdMob signature is not valid Base64URL.",
    );
  }

  const normalized =
    validated
      .replace(
        /-/g,
        "+",
      )
      .replace(
        /_/g,
        "/",
      );

  const padding =
    normalized.length %
    4;

  const padded =
    padding === 0
      ? normalized
      : normalized +
        "=".repeat(
          4 -
            padding,
        );

  const buffer =
    Buffer.from(
      padded,
      "base64",
    );

  if (
    !buffer ||
    buffer.length === 0
  ) {
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

      // ======================================================
      // ❌ FAIL
      // ======================================================

      const fail =
        (
          error,
        ) => {
          if (
            settled
          ) {
            return;
          }

          settled =
            true;

          reject(
            error,
          );
        };

      // ======================================================
      // ✅ SUCCESS
      // ======================================================

      const succeed =
        (
          value,
        ) => {
          if (
            settled
          ) {
            return;
          }

          settled =
            true;

          resolve(
            value,
          );
        };

      // ======================================================
      // 🌐 HTTPS REQUEST
      // ======================================================

      const request =
        https.get(
          ADMOB_SSV_KEYS_URL,
          {
            headers: {
              Accept:
                "application/json",
            },

            timeout:
              ADMOB_PUBLIC_KEY_FETCH_TIMEOUT_MS,
          },
          (
            response,
          ) => {
            let body =
              "";

            let bodyBytes =
              0;

            response.setEncoding(
              "utf8",
            );

            // ==================================================
            // 📥 DATA
            // ==================================================

            response.on(
              "data",
              (
                chunk,
              ) => {
                if (
                  settled
                ) {
                  return;
                }

                bodyBytes +=
                  Buffer.byteLength(
                    chunk,
                    "utf8",
                  );

                if (
                  bodyBytes >
                  ADMOB_PUBLIC_KEY_MAX_RESPONSE_BYTES
                ) {
                  fail(
                    createError(
                      "ADMOB_PUBLIC_KEY_RESPONSE_INVALID",
                      "AdMob public key response is too large.",
                    ),
                  );

                  request.destroy();

                  return;
                }

                body +=
                  chunk;
              },
            );

            // ==================================================
            // 📦 END
            // ==================================================

            response.on(
              "end",
              () => {
                if (
                  settled
                ) {
                  return;
                }

                const statusCode =
                  response.statusCode ||
                  0;

                // ==============================================
                // HTTP STATUS
                // ==============================================

                if (
                  statusCode <
                    200 ||
                  statusCode >=
                    300
                ) {
                  fail(
                    createError(
                      "ADMOB_PUBLIC_KEY_HTTP_ERROR",
                      `AdMob public key server returned HTTP ${statusCode}.`,
                    ),
                  );

                  return;
                }

                // ==============================================
                // JSON
                // ==============================================

                let parsed;

                try {
                  parsed =
                    JSON.parse(
                      body,
                    );
                } catch (
                  error
                ) {
                  fail(
                    createError(
                      "ADMOB_PUBLIC_KEY_JSON_ERROR",
                      "Unable to parse AdMob public key response.",
                    ),
                  );

                  return;
                }

                // ==============================================
                // STRUCTURE
                // ==============================================

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

                if (
                  parsed.keys.length ===
                  0
                ) {
                  fail(
                    createError(
                      "ADMOB_PUBLIC_KEYS_EMPTY",
                      "AdMob public key response contains no keys.",
                    ),
                  );

                  return;
                }

                // ==============================================
                // BUILD KEY MAP
                // ==============================================

                const keyMap =
                  new Map();

                for (
                  const key
                  of parsed.keys
                ) {
                  if (
                    !key ||
                    typeof key !==
                      "object"
                  ) {
                    continue;
                  }

                  const rawKeyId =
                    key.keyId;

                  const keyId =
                    validateKeyId(
                      rawKeyId ===
                        undefined ||
                      rawKeyId ===
                        null
                        ? ""
                        : String(
                            rawKeyId,
                          ),
                    );

                  const pem =
                    normalizeString(
                      key.pem,
                    );

                  if (
                    !keyId ||
                    !pem
                  ) {
                    continue;
                  }

                  if (
                    !pem.includes(
                      "-----BEGIN PUBLIC KEY-----",
                    ) ||
                    !pem.includes(
                      "-----END PUBLIC KEY-----",
                    )
                  ) {
                    continue;
                  }

                  keyMap.set(
                    keyId,
                    pem,
                  );
                }

                // ==============================================
                // VALID KEY MAP REQUIRED
                // ==============================================

                if (
                  keyMap.size ===
                  0
                ) {
                  fail(
                    createError(
                      "ADMOB_PUBLIC_KEY_RESPONSE_INVALID",
                      "AdMob public key response contains no valid public keys.",
                    ),
                  );

                  return;
                }

                succeed(
                  keyMap,
                );
              },
            );

            // ==================================================
            // RESPONSE ERROR
            // ==================================================

            response.on(
              "error",
              (
                error,
              ) => {
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

      // ========================================================
      // REQUEST TIMEOUT
      // ========================================================

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

      // ========================================================
      // REQUEST ERROR
      // ========================================================

      request.on(
        "error",
        (
          error,
        ) => {
          if (
            error &&
            error.code &&
            String(
              error.code,
            ).startsWith(
              "ADMOB_",
            )
          ) {
            fail(
              error,
            );

            return;
          }

          fail(
            createError(
              "ADMOB_PUBLIC_KEY_FETCH_ERROR",
              "Unable to fetch AdMob public keys.",
            ),
          );
        },
      );
    },
  );
}

// ============================================================
// 🔑 GET ADMOB PUBLIC KEYS
// ============================================================

async function getAdMobPublicKeys(
  forceRefresh = false,
) {
  const now =
    Date.now();

  // ==========================================================
  // CACHE HIT
  // ==========================================================

  if (
    !forceRefresh &&
    publicKeyCache &&
    now -
      publicKeyCache.loadedAt <
      ADMOB_PUBLIC_KEY_CACHE_MS
  ) {
    return publicKeyCache.keys;
  }

  // ==========================================================
  // EXISTING FETCH
  // ==========================================================
//
// Jos public-key-pyyntö on jo käynnissä, käytetään samaa
// Promisea. Tämä estää samanaikaiset duplicate-fetchit.
//

  if (
    publicKeyFetchPromise
  ) {
    return publicKeyFetchPromise;
  }

  // ==========================================================
  // NEW FETCH
  // ==========================================================

  publicKeyFetchPromise =
    fetchPublicKeys()
      .then(
        (
          keys,
        ) => {
          publicKeyCache =
            {
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
// 🔐 VERIFY ADMOB SIGNATURE
// ============================================================
//
// AdMob SSV:
//
// ...&signature=...&key_id=...
//
// Signature on toiseksi viimeinen parametri.
//
// key_id on viimeinen parametri.
//
// Allekirjoitettu data on kaikki sitä edeltävä
// query-string-data.
//
// Query-stringiä EI saa järjestää uudelleen.
//
// ============================================================

async function verifyAdMobSignature(
  rawQueryString,
) {
  if (
    typeof rawQueryString !==
      "string" ||
    rawQueryString.length ===
      0
  ) {
    throw createError(
      "ADMOB_QUERY_STRING_MISSING",
      "AdMob query string is missing.",
    );
  }

  // ==========================================================
  // SPLIT WITHOUT DECODING
  // ==========================================================

  const parameters =
    rawQueryString.split(
      "&",
    );

  if (
    parameters.length <
    3
  ) {
    throw createError(
      "ADMOB_INVALID_SIGNATURE",
      "AdMob SSV query does not contain enough parameters.",
    );
  }

  // ==========================================================
  // LAST TWO PARAMETERS
  // ==========================================================

  const signatureParameter =
    parameters[
      parameters.length -
        2
    ];

  const keyIdParameter =
    parameters[
      parameters.length -
        1
    ];

  // ==========================================================
  // SIGNATURE PARAMETER
  // ==========================================================

  if (
    !signatureParameter.startsWith(
      "signature=",
    )
  ) {
    throw createError(
      "ADMOB_INVALID_SIGNATURE",
      "AdMob signature parameter is missing or is not the second-last parameter.",
    );
  }

  // ==========================================================
  // KEY ID PARAMETER
  // ==========================================================

  if (
    !keyIdParameter.startsWith(
      "key_id=",
    )
  ) {
    throw createError(
      "ADMOB_INVALID_KEY_ID",
      "AdMob key_id parameter is missing or is not the last parameter.",
    );
  }

  const signature =
    signatureParameter.substring(
      "signature=".length,
    );

  const keyId =
    keyIdParameter.substring(
      "key_id=".length,
    );

  const validatedSignature =
    validateSignature(
      signature,
    );

  if (
    !validatedSignature
  ) {
    throw createError(
      "ADMOB_INVALID_SIGNATURE",
      "AdMob signature is invalid.",
    );
  }

  const validatedKeyId =
    validateKeyId(
      keyId,
    );

  if (
    !validatedKeyId
  ) {
    throw createError(
      "ADMOB_INVALID_KEY_ID",
      "AdMob key_id is invalid.",
    );
  }

  // ==========================================================
  // SIGNED QUERY STRING
  // ==========================================================
  //
  // Poistetaan vain signature ja key_id.
  //
  // Kaikki muu säilytetään alkuperäisessä muodossa.
  //
  // ==========================================================

  const signedQueryString =
    parameters
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
      "ADMOB_QUERY_STRING_MISSING",
      "AdMob signed query string is empty.",
    );
  }

  // ==========================================================
  // 🔑 GET PUBLIC KEY
  // ==========================================================

  let publicKeys =
    await getAdMobPublicKeys(
      false,
    );

  let publicKey =
    publicKeys.get(
      validatedKeyId,
    );

  // ==========================================================
  // 🔄 FORCE REFRESH IF KEY IS UNKNOWN
  // ==========================================================

  if (
    !publicKey
  ) {
    publicKeys =
      await getAdMobPublicKeys(
        true,
      );

    publicKey =
      publicKeys.get(
        validatedKeyId,
      );
  }

  if (
    !publicKey
  ) {
    throw createError(
      "ADMOB_PUBLIC_KEY_NOT_FOUND",
      "AdMob public key was not found.",
    );
  }

  // ==========================================================
  // 🔐 DECODE SIGNATURE
  // ==========================================================

  const signatureBuffer =
    decodeBase64Url(
      validatedSignature,
    );

  // ==========================================================
  // 🔐 CRYPTOGRAPHIC VERIFICATION
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

    if (
      !valid
    ) {
      throw createError(
        "ADMOB_INVALID_SIGNATURE",
        "AdMob signature verification failed.",
      );
    }
  } catch (
    error
  ) {
    if (
      error &&
      error.code ===
        "ADMOB_INVALID_SIGNATURE"
    ) {
      throw error;
    }

    throw createError(
      "ADMOB_CRYPTO_VERIFICATION_ERROR",
      "AdMob cryptographic verification failed.",
    );
  }

  // ==========================================================
  // ✅ VERIFIED
  // ==========================================================

  return {
    verified:
      true,

    signature:
      validatedSignature,

    keyId:
      validatedKeyId,

    signedQueryString,

    rawQueryString,
  };
}

// ============================================================
// 🎯 PARSE CUSTOM DATA
// ============================================================
//
// Stelluriinin custom_data:
//
// UID:rewardPurpose
//
// Esimerkiksi:
//
// abc123:mining_start
// abc123:power_boost
//
// AdMob voi percent-encodeta custom_data-arvon.
// Se dekoodataan vasta tässä vaiheessa, kun kryptografinen
// allekirjoitus on jo varmennettu.
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
    raw.length === 0 ||
    raw.length > 256
  ) {
    throw createError(
      "ADMOB_CUSTOM_DATA_MISSING",
      "AdMob custom_data is missing or invalid.",
    );
  }

  let decoded;

  try {
    decoded =
      decodeURIComponent(
        raw,
      );
  } catch (
    error
  ) {
    throw createError(
      "ADMOB_CUSTOM_DATA_MISSING",
      "AdMob custom_data could not be decoded.",
    );
  }

  if (
    decoded.length === 0 ||
    decoded.length > 256
  ) {
    throw createError(
      "ADMOB_CUSTOM_DATA_MISSING",
      "AdMob custom_data is invalid.",
    );
  }

  const separatorIndex =
    decoded.indexOf(
      ":",
    );

  if (
    separatorIndex <= 0 ||
    separatorIndex ===
      decoded.length - 1
  ) {
    throw createError(
      "ADMOB_CUSTOM_DATA_MISSING",
      "AdMob custom_data has an invalid format.",
    );
  }

  const uid =
    decoded.substring(
      0,
      separatorIndex,
    );

  const rewardPurpose =
    decoded.substring(
      separatorIndex +
        1,
    );

  const validatedUid =
    validateUid(
      uid,
    );

  if (
    !validatedUid
  ) {
    throw createError(
      "ADMOB_INVALID_UID",
      "AdMob custom_data contains an invalid UID.",
    );
  }

  const validatedPurpose =
    validateRewardPurpose(
      rewardPurpose,
    );

  if (
    !validatedPurpose
  ) {
    throw createError(
      "ADMOB_INVALID_REWARD_PURPOSE",
      "AdMob custom_data contains an invalid reward purpose.",
    );
  }

  return {
    uid:
      validatedUid,

    rewardPurpose:
      validatedPurpose,

    customData:
      decoded,
  };
}

// ============================================================
// 📺 GET EXPECTED ADMOB CONFIG
// ============================================================

function getExpectedAdMobConfig(
  rewardPurpose,
) {
  if (
    !VALID_REWARD_PURPOSES.has(
      rewardPurpose,
    )
  ) {
    throw createError(
      "ADMOB_INVALID_REWARD_PURPOSE",
      "Unknown AdMob reward purpose.",
    );
  }

  const adUnit =
    ADMOB_AD_UNITS[
      rewardPurpose
    ];

  const rewardDefinition =
    REWARD_DEFINITIONS[
      rewardPurpose
    ];

  if (
    typeof adUnit !==
      "string" ||
    adUnit.trim().length ===
      0 ||
    !rewardDefinition
  ) {
    throw createError(
      "ADMOB_INVALID_REWARD_CONFIGURATION",
      `No AdMob configuration exists for ${rewardPurpose}.`,
    );
  }

  const rewardAmount =
    Number(
      rewardDefinition.rewardAmount,
    );

  const rewardItem =
    normalizeString(
      rewardDefinition.rewardItem,
    );

  if (
    !Number.isSafeInteger(
      rewardAmount,
    ) ||
    rewardAmount < 0 ||
    rewardItem.length ===
      0
  ) {
    throw createError(
      "ADMOB_INVALID_REWARD_CONFIGURATION",
      `Invalid AdMob reward configuration for ${rewardPurpose}.`,
    );
  }

  return {
    adUnit:
      adUnit.trim(),

    rewardAmount,

    rewardItem,
  };
}

// ============================================================
// 📺 VALIDATE VERIFIED PARAMETERS
// ============================================================

function validateVerifiedParameters(
  parameters,
) {
  if (
    !parameters
  ) {
    throw createError(
      "ADMOB_REQUIRED_PARAMETER_MISSING",
      "AdMob parameters are missing.",
    );
  }

  // ==========================================================
  // AD NETWORK
  // ==========================================================

  const adNetwork =
    validateAdNetwork(
      parameters.adNetwork,
    );

  if (
    !adNetwork
  ) {
    throw createError(
      "ADMOB_INVALID_AD_NETWORK",
      "AdMob ad_network is invalid.",
    );
  }

  // ==========================================================
  // AD UNIT
  // ==========================================================

  const adUnit =
    normalizeString(
      parameters.adUnit,
    );

  if (
    adUnit.length === 0 ||
    adUnit.length > 256
  ) {
    throw createError(
      "ADMOB_INVALID_AD_UNIT",
      "AdMob ad_unit is invalid.",
    );
  }

  // ==========================================================
  // REWARD AMOUNT
  // ==========================================================

  const rewardAmount =
    Number(
      parameters.rewardAmount,
    );

  if (
    !Number.isSafeInteger(
      rewardAmount,
    ) ||
    rewardAmount < 0
  ) {
    throw createError(
      "ADMOB_INVALID_REWARD_AMOUNT",
      "AdMob reward_amount is invalid.",
    );
  }

  // ==========================================================
  // REWARD ITEM
  // ==========================================================

  const rewardItem =
    normalizeString(
      parameters.rewardItem,
    );

  if (
    rewardItem.length === 0 ||
    rewardItem.length > 256
  ) {
    throw createError(
      "ADMOB_INVALID_REWARD_ITEM",
      "AdMob reward_item is invalid.",
    );
  }

  // ==========================================================
  // TRANSACTION ID
  // ==========================================================

  const transactionId =
    validateTransactionId(
      parameters.transactionId,
    );

  if (
    !transactionId
  ) {
    throw createError(
      "ADMOB_INVALID_TRANSACTION_ID",
      "AdMob transaction_id is invalid.",
    );
  }

  // ==========================================================
  // TIMESTAMP
  // ==========================================================

  const timestamp =
    validateTimestamp(
      parameters.timestamp,
    );

  if (
    !timestamp
  ) {
    throw createError(
      "ADMOB_INVALID_TIMESTAMP",
      "AdMob timestamp is invalid or outside the allowed time window.",
    );
  }

  // ==========================================================
  // KEY ID
  // ==========================================================

  const keyId =
    validateKeyId(
      parameters.keyId,
    );

  if (
    !keyId
  ) {
    throw createError(
      "ADMOB_INVALID_KEY_ID",
      "AdMob key_id is invalid.",
    );
  }

  // ==========================================================
  // SIGNATURE
  // ==========================================================

  const signature =
    validateSignature(
      parameters.signature,
    );

  if (
    !signature
  ) {
    throw createError(
      "ADMOB_INVALID_SIGNATURE",
      "AdMob signature is invalid.",
    );
  }

  return {
    adNetwork,

    adUnit,

    rewardAmount,

    rewardItem,

    transactionId,

    timestamp,

    keyId,

    signature,
  };
}

// ============================================================
// 🔐 VERIFY COMPLETE ADMOB CALLBACK
// ============================================================

async function verifyAdMobCallback(
  req,
) {
  if (
    !req
  ) {
    throw createError(
      "ADMOB_REQUEST_MISSING",
      "AdMob request is missing.",
    );
  }

  // ==========================================================
  // 🔎 ORIGINAL URL
  // ==========================================================
  //
  // Allekirjoituksen tarkistuksessa käytetään alkuperäistä
  // query-stringiä.
  //
  // ÄLÄ rakenna query-stringiä uudelleen req.query:sta.
  //
  // ==========================================================

  const originalUrl =
    typeof req.originalUrl ===
        "string" &&
      req.originalUrl.length >
        0
      ? req.originalUrl
      : typeof req.url ===
          "string"
        ? req.url
        : "";

  const questionMarkIndex =
    originalUrl.indexOf(
      "?",
    );

  if (
    questionMarkIndex ===
    -1
  ) {
    throw createError(
      "ADMOB_QUERY_STRING_MISSING",
      "AdMob query string is missing.",
    );
  }

  const rawQueryString =
    originalUrl.substring(
      questionMarkIndex +
        1,
    );

  if (
    rawQueryString.length ===
    0
  ) {
    throw createError(
      "ADMOB_QUERY_STRING_MISSING",
      "AdMob query string is empty.",
    );
  }

  // ==========================================================
  // 🔐 CRYPTOGRAPHIC VERIFICATION
  // ==========================================================

  const cryptographicResult =
    await verifyAdMobSignature(
      rawQueryString,
    );

  // ==========================================================
  // 🔎 QUERY PARAMETERS
  // ==========================================================
  //
  // Vasta allekirjoituksen tarkistamisen jälkeen query
  // voidaan lukea ja validoida.
  //
  // ==========================================================

  const query =
    req.query ||
    {};

  const getQueryValue =
    (
      key,
    ) => {
      const value =
        query[key];

      if (
        Array.isArray(
          value,
        )
      ) {
        return normalizeString(
          value[0],
        );
      }

      return normalizeString(
        value,
      );
    };

  // ==========================================================
  // REQUIRED PARAMETERS
  // ==========================================================

  const adNetwork =
    getQueryValue(
      "ad_network",
    );

  const adUnit =
    getQueryValue(
      "ad_unit",
    );

  const rewardAmount =
    getQueryValue(
      "reward_amount",
    );

  const rewardItem =
    getQueryValue(
      "reward_item",
    );

  const transactionId =
    getQueryValue(
      "transaction_id",
    );

  const timestamp =
    getQueryValue(
      "timestamp",
    );

  const userId =
    getQueryValue(
      "user_id",
    );

  const customData =
    getQueryValue(
      "custom_data",
    );

  if (
    !adNetwork ||
    !adUnit ||
    !rewardAmount ||
    !rewardItem ||
    !transactionId ||
    !timestamp
  ) {
    throw createError(
      "ADMOB_REQUIRED_PARAMETER_MISSING",
      "One or more required AdMob parameters are missing.",
    );
  }

  // ==========================================================
  // 🔐 CRYPTOGRAPHIC RESULT
  // ==========================================================

  const keyId =
    cryptographicResult.keyId;

  const signature =
    cryptographicResult.signature;

  // ==========================================================
  // 📺 VALIDATE PARAMETERS
  // ==========================================================

  const validated =
    validateVerifiedParameters({
      adNetwork,

      adUnit,

      rewardAmount,

      rewardItem,

      transactionId,

      timestamp,

      keyId,

      signature,
    });

  // ==========================================================
  // 🎯 CUSTOM DATA
  // ==========================================================

  if (
    !customData
  ) {
    throw createError(
      "ADMOB_CUSTOM_DATA_MISSING",
      "AdMob custom_data is required.",
    );
  }

  const parsedCustomData =
    parseCustomData(
      customData,
    );

  const {
    uid,
    rewardPurpose,
    customData:
      normalizedCustomData,
  } =
    parsedCustomData;

  // ==========================================================
  // 📺 EXPECTED SERVER CONFIG
  // ==========================================================

  const expectedAdMob =
    getExpectedAdMobConfig(
      rewardPurpose,
    );

  // ==========================================================
  // AD UNIT MUST MATCH
  // ==========================================================

  if (
    validated.adUnit !==
    expectedAdMob.adUnit
  ) {
    throw createError(
      "ADMOB_INVALID_AD_UNIT",
      "AdMob ad_unit does not match server configuration.",
    );
  }

  // ==========================================================
  // REWARD AMOUNT MUST MATCH
  // ==========================================================

  if (
    validated.rewardAmount !==
    expectedAdMob.rewardAmount
  ) {
    throw createError(
      "ADMOB_INVALID_REWARD_AMOUNT",
      "AdMob reward_amount does not match server configuration.",
    );
  }

  // ==========================================================
  // REWARD ITEM MUST MATCH
  // ==========================================================

  if (
    validated.rewardItem !==
    expectedAdMob.rewardItem
  ) {
    throw createError(
      "ADMOB_INVALID_REWARD_ITEM",
      "AdMob reward_item does not match server configuration.",
    );
  }

  // ==========================================================
  // USER ID
  // ==========================================================
  //
  // AdMob user_id on valinnainen.
  //
  // Jos se lähetetään, sen pitää vastata
  // custom_data:n UID:tä.
  //
  // ==========================================================

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

  // ==========================================================
  // 🔐 CUSTOM DATA DEFENSE-IN-DEPTH
  // ==========================================================
  //
  // Varmistetaan vielä, että juuri normalisoitu custom_data
  // vastaa UID:tä ja reward purposea.
  //
  // ==========================================================

  const expectedCustomData =
    `${uid}:${rewardPurpose}`;

  if (
    normalizedCustomData !==
    expectedCustomData
  ) {
    throw createError(
      "ADMOB_CUSTOM_DATA_MISSING",
      "AdMob custom_data does not match the verified UID and reward purpose.",
    );
  }

  // ==========================================================
  // ✅ RETURN FULL VERIFIED DATA
  // ==========================================================

  return {
    verified:
      true,

    uid,

    rewardPurpose,

    adUnit:
      validated.adUnit,

    adNetwork:
      validated.adNetwork,

    rewardAmount:
      validated.rewardAmount,

    rewardItem:
      validated.rewardItem,

    timestamp:
      validated.timestamp,

    transactionId:
      validated.transactionId,

    userId:
      normalizedUserId,

    customData:
      normalizedCustomData,

    keyId,

    signature,

    rawQueryString:
      cryptographicResult.rawQueryString,

    signedQueryString:
      cryptographicResult.signedQueryString,

    parameters: {
      adNetwork:
        validated.adNetwork,

      adUnit:
        validated.adUnit,

      rewardAmount:
        validated.rewardAmount,

      rewardItem:
        validated.rewardItem,

      timestamp:
        validated.timestamp,

      transactionId:
        validated.transactionId,

      userId:
        normalizedUserId,

      customData:
        normalizedCustomData,

      keyId,

      signature,
    },
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

  getExpectedAdMobConfig,
};