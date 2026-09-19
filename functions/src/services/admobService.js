"use strict";

const crypto = require("crypto");

/**
 * ============================================================
 * 🐱 STELLURIINI - ADMOB SERVICE
 * ============================================================
 *
 * Vastaa:
 *
 * 🔐 AdMob Rewarded SSV -allekirjoituksen tarkistamisesta
 * 🔑 AdMob public key -avainten lataamisesta ja välimuistista
 * 🧩 SSV-parametrien lukemisesta
 * 🛡️ Rewardin validoinnista
 * 👤 UID:n validoinnista
 *
 * TÄMÄ TIEDOSTO EI:
 *
 * ❌ lisää STL-saldoa
 * ❌ aktivoi Power Boostia
 * ❌ käynnistä Mining Startia
 * ❌ muuta adsToday-arvoa
 * ❌ muuta cooldownia
 * ❌ muuta mining-tilaa
 * ❌ kirjoita Firestoreen
 *
 * ============================================================
 */

const ADMOB_SSV_KEYS_URL =
  "https://www.gstatic.com/admob/reward/verifier-keys.json";

/**
 * Google kierrättää AdMob SSV public key -avaimia.
 *
 * Välimuisti pidetään alle 24 tuntia.
 */
const PUBLIC_KEY_CACHE_MS =
  23 * 60 * 60 * 1000;

let cachedPublicKeys = null;
let cachedPublicKeysAt = 0;


/**
 * ============================================================
 * 📺 ADMOB AD UNITS
 * ============================================================
 */

const ADMOB_AD_UNITS = {
  mining_start: "6674097787",
  power_boost: "7225738491",
};


/**
 * ============================================================
 * 🎁 EXPECTED REWARDS
 * ============================================================
 */

const REWARD_DEFINITIONS = {
  mining_start: {
    rewardItem: "Mining",
    rewardAmount: 1,
  },

  power_boost: {
    rewardItem: "Power Boost",
    rewardAmount: 1,
  },
};


/**
 * ============================================================
 * 🌐 FETCH JSON
 * ============================================================
 */

async function fetchJson(url) {
  const response = await fetch(url);

  if (!response.ok) {
    throw new Error(
      `AdMob public key server returned HTTP ${response.status}.`,
    );
  }

  return response.json();
}


/**
 * ============================================================
 * 🔑 LOAD ADMOB PUBLIC KEYS
 * ============================================================
 */

async function getAdMobPublicKeys(
  forceRefresh = false,
) {
  const now = Date.now();

  /**
   * ----------------------------------------------------------
   * CACHE
   * ----------------------------------------------------------
   */

  if (
    !forceRefresh &&
    cachedPublicKeys &&
    now - cachedPublicKeysAt <
      PUBLIC_KEY_CACHE_MS
  ) {
    return cachedPublicKeys;
  }


  /**
   * ----------------------------------------------------------
   * FETCH
   * ----------------------------------------------------------
   */

  const data = await fetchJson(
    ADMOB_SSV_KEYS_URL,
  );


  /**
   * ----------------------------------------------------------
   * VALIDATE RESPONSE
   * ----------------------------------------------------------
   */

  if (
    !data ||
    !Array.isArray(data.keys)
  ) {
    throw new Error(
      "AdMob public key response is invalid.",
    );
  }


  /**
   * ----------------------------------------------------------
   * BUILD KEY MAP
   * ----------------------------------------------------------
   */

  const keys = new Map();

  for (const key of data.keys) {
    if (
      key &&
      key.keyId !== undefined &&
      typeof key.pem === "string" &&
      key.pem.length > 0
    ) {
      keys.set(
        String(key.keyId),
        key.pem,
      );
    }
  }


  if (keys.size === 0) {
    throw new Error(
      "No usable AdMob public keys were returned.",
    );
  }


  /**
   * ----------------------------------------------------------
   * SAVE CACHE
   * ----------------------------------------------------------
   */

  cachedPublicKeys = keys;
  cachedPublicKeysAt = now;


  console.log(
    "🐱 AdMob public keys loaded.",
    {
      count: keys.size,

      keyIds: Array.from(
        keys.keys(),
      ),
    },
  );


  return keys;
}


/**
 * ============================================================
 * 🔎 EXTRACT QUERY STRING FROM URL
 * ============================================================
 *
 * TÄRKEÄÄ:
 *
 * Tätä merkkijonoa ei parsita eikä rakenneta uudelleen ennen
 * kryptografista tarkistusta.
 *
 * Google edellyttää, ettei allekirjoitettavaa sisältöä muuteta.
 *
 * ============================================================
 */

function extractQueryStringFromUrl(value) {
  if (
    typeof value !== "string" ||
    value.length === 0
  ) {
    return "";
  }

  const questionMark =
    value.indexOf("?");

  if (questionMark < 0) {
    return "";
  }

  return value.substring(
    questionMark + 1,
  );
}


/**
 * ============================================================
 * 🔎 GET RAW QUERY STRING
 * ============================================================
 */

function getRawQueryString(req) {
  if (!req) {
    throw new Error(
      "Missing HTTP request.",
    );
  }


  /**
   * Express:
   *
   * originalUrl = alkuperäinen URL
   * url         = request URL
   * rawUrl      = mahdollinen raakaversio
   *
   * Näistä otetaan vain query-string.
   */

  const candidates = [
    req.originalUrl,
    req.url,
    req.rawUrl,
  ];


  for (const value of candidates) {
    const query =
      extractQueryStringFromUrl(
        value,
      );

    if (query.length > 0) {
      return query;
    }
  }


  /**
   * ----------------------------------------------------------
   * LAST FALLBACK
   * ----------------------------------------------------------
   */

  if (
    req._parsedUrl &&
    typeof req._parsedUrl.search ===
      "string"
  ) {
    const search =
      req._parsedUrl.search;

    if (
      search.startsWith("?") &&
      search.length > 1
    ) {
      return search.substring(1);
    }
  }


  throw new Error(
    "AdMob SSV query string is missing.",
  );
}


/**
 * ============================================================
 * 🔐 DECODE ADMOB SIGNATURE
 * ============================================================
 *
 * AdMob käyttää Base64URL-formaattia.
 *
 * "-" -> "+"
 * "_" -> "/"
 *
 * ============================================================
 */

function decodeAdMobSignature(signature) {
  if (
    typeof signature !== "string" ||
    signature.length === 0
  ) {
    throw new Error(
      "AdMob SSV signature is missing.",
    );
  }


  const normalized =
    signature
      .replace(/-/g, "+")
      .replace(/_/g, "/");


  /**
   * Base64URL ei saa olla pituudeltaan
   * 1 mod 4.
   */

  if (
    normalized.length % 4 === 1
  ) {
    throw new Error(
      "AdMob SSV signature has invalid Base64URL length.",
    );
  }


  const remainder =
    normalized.length % 4;


  const padded =
    remainder === 0
      ? normalized
      : normalized +
        "=".repeat(
          4 - remainder,
        );


  /**
   * Tarkistetaan Base64-merkistö.
   */

  if (
    !/^[A-Za-z0-9+/]*={0,2}$/.test(
      padded,
    )
  ) {
    throw new Error(
      "AdMob SSV signature contains invalid Base64URL characters.",
    );
  }


  const signatureBuffer =
    Buffer.from(
      padded,
      "base64",
    );


  if (
    signatureBuffer.length === 0
  ) {
    throw new Error(
      "AdMob SSV signature could not be decoded.",
    );
  }


  return signatureBuffer;
}


/**
 * ============================================================
 * 🔎 EXTRACT SIGNATURE DATA
 * ============================================================
 *
 * Googlen SSV-formaatti:
 *
 *   ...&signature=...&key_id=...
 *
 * signature ja key_id ovat kaksi viimeistä parametria.
 *
 * Allekirjoitettavaa sisältöä on kaikki ennen
 * "&signature=" kohtaa.
 *
 * ============================================================
 */

function extractSignatureData(
  rawQueryString,
) {
  if (
    typeof rawQueryString !== "string" ||
    rawQueryString.length === 0
  ) {
    throw new Error(
      "AdMob SSV raw query string is missing.",
    );
  }


  /**
   * ----------------------------------------------------------
   * FIND SIGNATURE
   * ----------------------------------------------------------
   */

  const signatureMarker =
    "&signature=";

  const signatureIndex =
    rawQueryString.indexOf(
      signatureMarker,
    );


  if (signatureIndex < 0) {
    throw new Error(
      "AdMob SSV signature parameter was not found.",
    );
  }


  /**
   * ----------------------------------------------------------
   * SIGNED CONTENT
   * ----------------------------------------------------------
   *
   * TÄTÄ EI SAA MUUTTAA.
   */

  const signedQueryString =
    rawQueryString.substring(
      0,
      signatureIndex,
    );


  if (
    signedQueryString.length === 0
  ) {
    throw new Error(
      "AdMob SSV signed query string is empty.",
    );
  }


  /**
   * ----------------------------------------------------------
   * SIGNATURE + KEY ID
   * ----------------------------------------------------------
   */

  const signatureAndKeyId =
    rawQueryString.substring(
      signatureIndex + 1,
    );


  const parts =
    signatureAndKeyId.split("&");


  if (parts.length !== 2) {
    throw new Error(
      "AdMob SSV signature and key_id must be the final two query parameters.",
    );
  }


  if (
    !parts[0].startsWith(
      "signature=",
    )
  ) {
    throw new Error(
      "AdMob SSV signature is not in the expected position.",
    );
  }


  if (
    !parts[1].startsWith(
      "key_id=",
    )
  ) {
    throw new Error(
      "AdMob SSV key_id is not in the expected position.",
    );
  }


  let signature;
  let keyId;


  try {
    signature =
      decodeURIComponent(
        parts[0].substring(
          "signature=".length,
        ),
      );

    keyId =
      decodeURIComponent(
        parts[1].substring(
          "key_id=".length,
        ),
      );
  } catch (error) {
    throw new Error(
      `AdMob SSV signature/key_id URL decoding failed: ${error.message}`,
    );
  }


  if (signature.length === 0) {
    throw new Error(
      "AdMob SSV signature value is missing.",
    );
  }


  if (keyId.length === 0) {
    throw new Error(
      "AdMob SSV key_id value is missing.",
    );
  }


  /**
   * key_id on numeerinen tunniste.
   */

  if (!/^\d+$/.test(keyId)) {
    throw new Error(
      "AdMob SSV key_id is invalid.",
    );
  }


  return {
    signedQueryString,
    signature,
    keyId,
  };
}


/**
 * ============================================================
 * 🔐 VERIFY RAW QUERY STRING
 * ============================================================
 */

async function verifyRawQueryString(
  rawQueryString,
) {
  const {
    signedQueryString,
    signature,
    keyId,
  } = extractSignatureData(
    rawQueryString,
  );


  /**
   * ----------------------------------------------------------
   * DECODE SIGNATURE
   * ----------------------------------------------------------
   */

  const signatureBuffer =
    decodeAdMobSignature(
      signature,
    );


  /**
   * ----------------------------------------------------------
   * LOAD PUBLIC KEYS
   * ----------------------------------------------------------
   */

  let publicKeys =
    await getAdMobPublicKeys(
      false,
    );


  let publicKey =
    publicKeys.get(
      String(keyId),
    );


  /**
   * ----------------------------------------------------------
   * REFRESH UNKNOWN KEY
   * ----------------------------------------------------------
   */

  if (!publicKey) {
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
        String(keyId),
      );
  }


  if (!publicKey) {
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


  /**
   * ==========================================================
   * 🔐 ECDSA SHA-256
   * ==========================================================
   *
   * Google AdMob SSV käyttää ECDSA SHA-256
   * -allekirjoitusta.
   *
   * ==========================================================
   */

  let verified = false;


  try {
    const verifier =
      crypto.createVerify(
        "SHA256",
      );


    /**
     * ERITTÄIN TÄRKEÄ:
     *
     * Allekirjoitettava sisältö lähetetään sellaisenaan
     * UTF-8-byteina.
     *
     * Emme käytä tässä URLSearchParamsia.
     * Emme dekoodaa query-stringiä.
     * Emme järjestä parametreja.
     * Emme rakenna query-stringiä uudelleen.
     */

    verifier.update(
      Buffer.from(
        signedQueryString,
        "utf8",
      ),
    );

    verifier.end();


    verified =
      verifier.verify(
        {
          key: publicKey,

          dsaEncoding: "der",
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


  if (!verified) {
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


  /**
   * ==========================================================
   * IMPORTANT
   * ==========================================================
   *
   * Query-string parsitaan vasta onnistuneen
   * kryptografisen tarkistuksen jälkeen.
   *
   * HUOM:
   *
   * signature ja keyId palautetaan erikseen suoraan
   * extractSignatureData()-funktiosta.
   *
   * Näin myöhempi validointi ei ole riippuvainen siitä,
   * löytyvätkö nämä arvot uudelleen URLSearchParams-oliosta.
   *
   * ==========================================================
   */

  return {
    verified: true,

    keyId,

    signature,

    rawQueryString,

    signedQueryString,

    params:
      new URLSearchParams(
        rawQueryString,
      ),
  };
}


/**
 * ============================================================
 * 🔐 VERIFY ADMOB SIGNATURE
 * ============================================================
 */

async function verifyAdMobSignature(req) {
  const rawQueryString =
    getRawQueryString(req);


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


/**
 * ============================================================
 * 🔎 PARAMETER HELPER
 * ============================================================
 */

function getParam(
  params,
  name,
) {
  if (
    !params ||
    typeof params.get !== "function"
  ) {
    return "";
  }


  const value =
    params.get(name);


  if (
    value === null ||
    value === undefined
  ) {
    return "";
  }


  return String(value);
}


/**
 * ============================================================
 * 🔎 REQUIRED PARAMETER HELPER
 * ============================================================
 */

function requireParam(
  params,
  name,
) {
  const value =
    getParam(
      params,
      name,
    );


  if (value.length === 0) {
    throw new Error(
      `AdMob SSV required parameter "${name}" is missing.`,
    );
  }


  return value;
}


/**
 * ============================================================
 * 🔢 INTEGER HELPER
 * ============================================================
 */

function parseInteger(
  value,
  fallback = 0,
) {
  const number =
    Number(value);


  if (
    !Number.isFinite(number)
  ) {
    return fallback;
  }


  return Math.trunc(number);
}


/**
 * ============================================================
 * 🛡️ UID VALIDATION
 * ============================================================
 */

function validateUid(uid) {
  if (
    typeof uid !== "string"
  ) {
    return false;
  }


  const trimmed =
    uid.trim();


  if (
    trimmed.length === 0 ||
    trimmed.length > 128
  ) {
    return false;
  }


  return /^[A-Za-z0-9._-]+$/.test(
    trimmed,
  );
}


/**
 * ============================================================
 * 🧩 CUSTOM DATA PARSER
 * ============================================================
 *
 * Formaatti:
 *
 *   UID:mining_start
 *
 *   UID:power_boost
 *
 * ============================================================
 */

function parseCustomData(customData) {
  if (
    typeof customData !== "string"
  ) {
    return {
      uid: "",
      rewardPurpose: "",
    };
  }


  const value =
    customData.trim();


  if (
    value.length === 0 ||
    value.length > 128
  ) {
    return {
      uid: "",
      rewardPurpose: "",
    };
  }


  const separatorIndex =
    value.lastIndexOf(":");


  if (
    separatorIndex <= 0 ||
    separatorIndex >=
      value.length - 1
  ) {
    return {
      uid: "",
      rewardPurpose: "",
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
    !validateUid(uid)
  ) {
    return {
      uid: "",
      rewardPurpose: "",
    };
  }


  if (
    rewardPurpose !==
      "mining_start" &&
    rewardPurpose !==
      "power_boost"
  ) {
    return {
      uid: "",
      rewardPurpose: "",
    };
  }


  return {
    uid,
    rewardPurpose,
  };
}


/**
 * ============================================================
 * 🔐 TRANSACTION ID VALIDATION
 * ============================================================
 */

function validateTransactionId(
  transactionId,
) {
  if (
    typeof transactionId !== "string"
  ) {
    return false;
  }


  const value =
    transactionId.trim();


  if (
    value.length === 0 ||
    value.length > 256
  ) {
    return false;
  }


  return /^[a-fA-F0-9]+$/.test(
    value,
  );
}


/**
 * ============================================================
 * ⏱️ TIMESTAMP VALIDATION
 * ============================================================
 */

function validateTimestamp(timestamp) {
  const timestampMs =
    Number(timestamp);


  if (
    !Number.isFinite(timestampMs) ||
    timestampMs <= 0 ||
    !Number.isInteger(timestampMs)
  ) {
    return {
      valid: false,
      timestampMs: 0,
    };
  }


  return {
    valid: true,
    timestampMs,
  };
}


/**
 * ============================================================
 * 🔐 VERIFY ADMOB CALLBACK
 * ============================================================
 */

async function verifyAdMobCallback(req) {
  /**
   * ----------------------------------------------------------
   * 1. CRYPTOGRAPHIC VERIFICATION
   * ----------------------------------------------------------
   */

  const verification =
    await verifyAdMobSignature(
      req,
    );


  const params =
    verification.params;


  /**
   * ----------------------------------------------------------
   * 2. REQUIRED PARAMETERS
   * ----------------------------------------------------------
   */

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


  /**
   * user_id on valinnainen.
   */

  const userId =
    getParam(
      params,
      "user_id",
    );


  /**
   * ----------------------------------------------------------
   * 3. CUSTOM DATA
   * ----------------------------------------------------------
   */

  const parsedCustomData =
    parseCustomData(
      customData,
    );


  const uid =
    parsedCustomData.uid;


  const rewardPurpose =
    parsedCustomData.rewardPurpose;


  /**
   * ----------------------------------------------------------
   * 4. REWARD PURPOSE
   * ----------------------------------------------------------
   */

  if (
    rewardPurpose !==
      "mining_start" &&
    rewardPurpose !==
      "power_boost"
  ) {
    throw new Error(
      `Invalid AdMob reward purpose: ${rewardPurpose}`,
    );
  }


  /**
   * ----------------------------------------------------------
   * 5. UID
   * ----------------------------------------------------------
   */

  if (
    !validateUid(uid)
  ) {
    throw new Error(
      "AdMob SSV custom_data does not contain a valid UID.",
    );
  }


  /**
   * ----------------------------------------------------------
   * 6. AD UNIT
   * ----------------------------------------------------------
   */

  const expectedAdUnit =
    ADMOB_AD_UNITS[
      rewardPurpose
    ];


  if (!expectedAdUnit) {
    throw new Error(
      `No AdMob ad unit configured for ${rewardPurpose}.`,
    );
  }


  if (
    adUnit !== expectedAdUnit
  ) {
    throw new Error(
      `Invalid AdMob ad unit. Expected ${expectedAdUnit}, received ${adUnit}.`,
    );
  }


  /**
   * ----------------------------------------------------------
   * 7. REWARD DEFINITION
   * ----------------------------------------------------------
   */

  const rewardDefinition =
    REWARD_DEFINITIONS[
      rewardPurpose
    ];


  if (!rewardDefinition) {
    throw new Error(
      `No reward definition configured for ${rewardPurpose}.`,
    );
  }


  /**
   * ----------------------------------------------------------
   * 8. REWARD AMOUNT
   * ----------------------------------------------------------
   */

  const parsedRewardAmount =
    parseInteger(
      rewardAmount,
      -1,
    );


  if (
    parsedRewardAmount !==
    rewardDefinition.rewardAmount
  ) {
    throw new Error(
      `Invalid AdMob reward amount. Expected ${rewardDefinition.rewardAmount}, received ${rewardAmount}.`,
    );
  }


  /**
   * ----------------------------------------------------------
   * 9. REWARD ITEM
   * ----------------------------------------------------------
   */

  if (
    rewardItem !==
    rewardDefinition.rewardItem
  ) {
    throw new Error(
      `Invalid AdMob reward item. Expected "${rewardDefinition.rewardItem}", received "${rewardItem}".`,
    );
  }


  /**
   * ----------------------------------------------------------
   * 10. TRANSACTION ID
   * ----------------------------------------------------------
   */

  if (
    !validateTransactionId(
      transactionId,
    )
  ) {
    throw new Error(
      "AdMob SSV transaction_id is missing or invalid.",
    );
  }


  /**
   * ----------------------------------------------------------
   * 11. TIMESTAMP
   * ----------------------------------------------------------
   */

  const timestampResult =
    validateTimestamp(
      timestamp,
    );


  if (
    !timestampResult.valid
  ) {
    throw new Error(
      "AdMob timestamp is invalid.",
    );
  }


  /**
   * ----------------------------------------------------------
   * 12. USER ID
   * ----------------------------------------------------------
   */

  if (
    userId &&
    userId !== uid
  ) {
    throw new Error(
      "AdMob SSV user_id does not match custom_data UID.",
    );
  }


  /**
   * ----------------------------------------------------------
   * 13. SIGNATURE / KEY ID
   * ----------------------------------------------------------
   *
   * TÄRKEÄ KORJAUS:
   *
   * Näitä EI enää lueta uudelleen params-oliosta.
   *
   * Ne on jo:
   *
   * 1. löydetty raw query-stringistä
   * 2. URL-dekoodattu
   * 3. validoitu
   * 4. kryptografisesti tarkistettu
   *
   * verifyRawQueryString() palauttaa ne suoraan.
   * ==========================================================
   */

  const signature =
    verification.signature;


  const keyId =
    verification.keyId;


  if (
    typeof signature !== "string" ||
    signature.length === 0
  ) {
    throw new Error(
      "AdMob SSV verified signature value is missing.",
    );
  }


  if (
    typeof keyId !== "string" ||
    keyId.length === 0
  ) {
    throw new Error(
      "AdMob SSV verified key_id value is missing.",
    );
  }


  /**
   * ----------------------------------------------------------
   * 14. NORMALIZED PARAMETERS
   * ----------------------------------------------------------
   */

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


  /**
   * ----------------------------------------------------------
   * 15. VERIFIED LOG
   * ----------------------------------------------------------
   */

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


  /**
   * ----------------------------------------------------------
   * 16. RETURN
   * ----------------------------------------------------------
   */

  return {
    verified: true,

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


/**
 * ============================================================
 * 📦 EXPORTS
 * ============================================================
 */

module.exports = {
  ADMOB_AD_UNITS,

  REWARD_DEFINITIONS,

  getAdMobPublicKeys,

  verifyAdMobSignature,

  verifyAdMobCallback,

  parseCustomData,
};