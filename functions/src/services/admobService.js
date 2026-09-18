"use strict";

const crypto = require("crypto");

/**
 * ============================================================
 * 🐱 STELLURIINI - ADMOB SERVICE
 * ============================================================
 *
 * Vastaa:
 *
 *  🔐 AdMob Rewarded SSV -allekirjoituksen tarkistamisesta
 *  🔑 AdMob public key -avainten lataamisesta ja välimuistista
 *  🧩 SSV-parametrien lukemisesta
 *  🛡️ Rewardin validoinnista
 *  👤 UID:n validoinnista
 *
 * TÄRKEÄ:
 *
 * Tämä tiedosto EI:
 *
 *  ❌ lisää STL-saldoa
 *  ❌ aktivoi Power Boostia
 *  ❌ käynnistä Mining Startia
 *  ❌ muuta adsToday-arvoa
 *  ❌ muuta cooldownia
 *
 * Tämä tiedosto ainoastaan:
 *
 * AdMob SSV
 *      ↓
 * allekirjoituksen tarkistus
 *      ↓
 * parametrien validointi
 *      ↓
 * verifiedAd
 *
 * ============================================================
 *
 * ADMOB SSV SIGNATURE
 *
 * Google allekirjoittaa alkuperäisen query-string-sisällön.
 *
 * Siksi allekirjoitettava sisältöä EI saa:
 *
 *  ❌ järjestää uudelleen
 *  ❌ purkaa ennen tarkistusta
 *  ❌ rakentaa uudelleen
 *  ❌ URL-enkoodata uudelleen
 *  ❌ käsitellä URLSearchParams.toString() kautta
 *
 * Parametrit voidaan lukea vasta allekirjoituksen onnistuneen
 * tarkistuksen jälkeen.
 *
 * ============================================================
 */

// ============================================================
// 🔐 ADMOB PUBLIC KEY URL
// ============================================================

const ADMOB_SSV_KEYS_URL =
  "https://www.gstatic.com/admob/reward/verifier-keys.json";

// ============================================================
// ⏱️ PUBLIC KEY CACHE
// ============================================================
//
// Avaimia ei pidetä välimuistissa täyttä 24 tuntia.
// Käytetään 23 tuntia, jotta avainten kierto ehditään huomioida.
//

const PUBLIC_KEY_CACHE_MS =
  23 * 60 * 60 * 1000;

let cachedPublicKeys = null;

let cachedPublicKeysAt = 0;


// ============================================================
// 📺 STELLURIINI ADMOB AD UNITS
// ============================================================
//
// AdMob SSV:n ad_unit-parametri sisältää vain numeerisen
// ad unit ID:n.
//
// EI esimerkiksi:
//
// ca-app-pub-xxxxxxxx/xxxxxxxx
//
// vaan:
//
// 6674097787
//
// ============================================================

const ADMOB_AD_UNITS = {
  mining_start:
    "6674097787",

  power_boost:
    "7225738491",
};


// ============================================================
// 🎁 EXPECTED REWARDS
// ============================================================
//
// AdMob reward ei ole tässä STL-maksu.
//
// Se kertoo vain, minkä rewarded-mainoksen käyttäjä suoritti.
//
// Varsinainen Power Boost / Mining Start käsitellään
// erillisessä Cloud Functionissa.
//

const REWARD_DEFINITIONS = {
  mining_start: {
    rewardItem:
      "Mining",

    rewardAmount:
      1,
  },

  power_boost: {
    rewardItem:
      "Power Boost",

    rewardAmount:
      1,
  },
};


// ============================================================
// 🌐 FETCH JSON
// ============================================================

async function fetchJson(
  url
) {
  const response =
    await fetch(url);

  if (
    !response.ok
  ) {
    throw new Error(
      `AdMob public key server returned HTTP ${response.status}`,
    );
  }

  return response.json();
}


// ============================================================
// 🔑 LOAD ADMOB PUBLIC KEYS
// ============================================================

async function getAdMobPublicKeys(
  forceRefresh = false
) {
  const now =
    Date.now();

  // ----------------------------------------------------------
  // CACHE
  // ----------------------------------------------------------

  if (
    !forceRefresh &&
    cachedPublicKeys &&
    now -
      cachedPublicKeysAt <
      PUBLIC_KEY_CACHE_MS
  ) {
    return cachedPublicKeys;
  }

  // ----------------------------------------------------------
  // DOWNLOAD
  // ----------------------------------------------------------

  const data =
    await fetchJson(
      ADMOB_SSV_KEYS_URL
    );

  if (
    !data ||
    !Array.isArray(data.keys)
  ) {
    throw new Error(
      "AdMob public key response is invalid.",
    );
  }

  // ----------------------------------------------------------
  // BUILD KEY MAP
  // ----------------------------------------------------------

  const keys =
    new Map();

  for (
    const key of data.keys
  ) {
    if (
      key &&
      key.keyId !==
        undefined &&
      typeof key.pem ===
        "string" &&
      key.pem.length > 0
    ) {
      keys.set(
        String(key.keyId),
        key.pem,
      );
    }
  }

  if (
    keys.size === 0
  ) {
    throw new Error(
      "No usable AdMob public keys were returned.",
    );
  }

  // ----------------------------------------------------------
  // SAVE CACHE
  // ----------------------------------------------------------

  cachedPublicKeys =
    keys;

  cachedPublicKeysAt =
    now;

  console.log(
    "🐱 AdMob public keys loaded.",
    {
      count:
        keys.size,
    }
  );

  return keys;
}


// ============================================================
// 🔎 GET RAW QUERY STRING
// ============================================================
//
// TÄMÄ FUNKTIO ON ERITTÄIN TÄRKEÄ.
//
// Allekirjoituksen tarkistuksessa tarvitaan alkuperäinen
// query-string.
//
// Emme käytä:
//   URLSearchParams.toString()
//
// Emme:
//   decodeURIComponent()
//
// Emme:
//   järjestä parametreja.
//
// ============================================================

function getRawQueryString(
  req
) {
  if (!req) {
    throw new Error(
      "Missing HTTP request.",
    );
  }

  // ----------------------------------------------------------
  // Firebase / Express originalUrl
  // ----------------------------------------------------------

  if (
    typeof req.originalUrl ===
    "string"
  ) {
    const questionMark =
      req.originalUrl.indexOf(
        "?"
      );

    if (
      questionMark >= 0
    ) {
      return req.originalUrl.substring(
        questionMark + 1
      );
    }
  }

  // ----------------------------------------------------------
  // Express req.url
  // ----------------------------------------------------------

  if (
    typeof req.url ===
    "string"
  ) {
    const questionMark =
      req.url.indexOf(
        "?"
      );

    if (
      questionMark >= 0
    ) {
      return req.url.substring(
        questionMark + 1
      );
    }
  }

  // ----------------------------------------------------------
  // Possible rawUrl
  // ----------------------------------------------------------

  if (
    typeof req.rawUrl ===
    "string"
  ) {
    const questionMark =
      req.rawUrl.indexOf(
        "?"
      );

    if (
      questionMark >= 0
    ) {
      return req.rawUrl.substring(
        questionMark + 1
      );
    }
  }

  throw new Error(
    "AdMob SSV query string is missing.",
  );
}


// ============================================================
// 🔐 DECODE ADMOB SIGNATURE
// ============================================================
//
// AdMob käyttää URL-safe Base64 -esitystä.
//
// ============================================================

function decodeAdMobSignature(
  signature
) {
  if (
    typeof signature !==
      "string" ||
    signature.length === 0
  ) {
    throw new Error(
      "AdMob SSV signature is missing.",
    );
  }

  // ----------------------------------------------------------
  // URL-safe Base64 → standard Base64
  // ----------------------------------------------------------

  const normalized =
    signature
      .replace(
        /-/g,
        "+"
      )
      .replace(
        /_/g,
        "/"
      );

  // ----------------------------------------------------------
  // BASE64 PADDING
  // ----------------------------------------------------------

  const padding =
    normalized.length %
    4;

  const padded =
    padding === 0
      ? normalized
      : normalized +
        "=".repeat(
          4 - padding
        );

  const signatureBuffer =
    Buffer.from(
      padded,
      "base64"
    );

  if (
    signatureBuffer.length ===
    0
  ) {
    throw new Error(
      "AdMob SSV signature could not be decoded.",
    );
  }

  return signatureBuffer;
}


// ============================================================
// 🔐 VERIFY ADMOB SIGNATURE
// ============================================================

async function verifyAdMobSignature(
  req
) {
  // ----------------------------------------------------------
  // RAW QUERY
  // ----------------------------------------------------------

  const rawQueryString =
    getRawQueryString(
      req
    );

  if (
    rawQueryString.length ===
    0
  ) {
    throw new Error(
      "AdMob SSV query string is empty.",
    );
  }

  // ==========================================================
  // 🔎 SIGNATURE LOCATION
  // ==========================================================
  //
  // AdMob SSV:n signature ja key_id ovat callbackin lopussa.
  //
  // Esimerkiksi:
  //
  // ad_network=...
  // &ad_unit=...
  // &reward_amount=...
  // &reward_item=...
  // &timestamp=...
  // &transaction_id=...
  // &custom_data=...
  // &signature=...
  // &key_id=...
  //
  // Allekirjoitettava osa päättyy ennen:
  //
  // &signature=
  //
  // ==========================================================

  const signatureMarker =
    "&signature=";

  const signatureIndex =
    rawQueryString.indexOf(
      signatureMarker
    );

  if (
    signatureIndex ===
    -1
  ) {
    throw new Error(
      "AdMob SSV signature parameter was not found.",
    );
  }

  // ----------------------------------------------------------
  // SIGNED CONTENT
  // ----------------------------------------------------------
  //
  // TÄMÄ MERKKIJONO PIDETÄÄN TÄSMÄLLEEN SELLAISENA KUIN
  // SE SAAPUI REQUESTISSA.
  //
  // ----------------------------------------------------------

  const rawSignedQueryString =
    rawQueryString.substring(
      0,
      signatureIndex
    );

  if (
    rawSignedQueryString.length ===
    0
  ) {
    throw new Error(
      "AdMob SSV signed query string is empty.",
    );
  }

  // ==========================================================
  // 🔐 SIGNATURE + KEY ID
  // ==========================================================

  const signatureAndKeyId =
    rawQueryString.substring(
      signatureIndex + 1
    );

  const signatureParams =
    new URLSearchParams(
      signatureAndKeyId
    );

  const signature =
    signatureParams.get(
      "signature"
    );

  const keyId =
    signatureParams.get(
      "key_id"
    );

  if (
    !signature
  ) {
    throw new Error(
      "AdMob SSV signature value is missing.",
    );
  }

  if (
    !keyId
  ) {
    throw new Error(
      "AdMob SSV key_id value is missing.",
    );
  }

  // ==========================================================
  // 🔓 DECODE SIGNATURE
  // ==========================================================

  const signatureBuffer =
    decodeAdMobSignature(
      signature
    );

  // ==========================================================
  // 🔑 LOAD PUBLIC KEY
  // ==========================================================

  let publicKeys =
    await getAdMobPublicKeys(
      false
    );

  let publicKey =
    publicKeys.get(
      String(keyId)
    );

  // ----------------------------------------------------------
  // KEY ROTATION
  // ----------------------------------------------------------

  if (
    !publicKey
  ) {
    console.log(
      "🐱 AdMob key not found in cache. Refreshing public keys.",
      {
        keyId,
      }
    );

    publicKeys =
      await getAdMobPublicKeys(
        true
      );

    publicKey =
      publicKeys.get(
        String(keyId)
      );
  }

  if (
    !publicKey
  ) {
    throw new Error(
      `AdMob SSV public key not found for key_id=${keyId}`,
    );
  }

  // ==========================================================
  // 🔐 ECDSA SHA-256
  // ==========================================================
  //
  // Google AdMob SSV käyttää ECDSA SHA-256 -allekirjoitusta.
  //
  // TÄRKEÄ:
  //
  // Vain alkuperäinen signed query-string lähetetään
  // verifierille.
  //
  // ==========================================================

  const verifier =
    crypto.createVerify(
      "SHA256"
    );

  verifier.update(
    Buffer.from(
      rawSignedQueryString,
      "utf8"
    )
  );

  verifier.end();

  const verified =
    verifier.verify(
      publicKey,
      signatureBuffer
    );

  if (
    !verified
  ) {
    console.error(
      "🐱❌ AdMob SSV signature INVALID.",
      {
        keyId,
      }
    );

    throw new Error(
      "AdMob SSV signature verification failed.",
    );
  }

  console.log(
    "🐱✅ AdMob SSV signature VERIFIED.",
    {
      keyId,
    }
  );

  // ==========================================================
  // 🔓 PARSE PARAMETERS
  // ==========================================================
  //
  // Vasta tässä vaiheessa query-string voidaan turvallisesti
  // lukea URLSearchParamsilla.
  //
  // ==========================================================

  const params =
    new URLSearchParams(
      rawQueryString
    );

  return {
    verified:
      true,

    keyId,

    rawQueryString,

    signedQueryString:
      rawSignedQueryString,

    params,
  };
}


// ============================================================
// 🔎 PARAMETER HELPER
// ============================================================

function getParam(
  params,
  name
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
      name
    );

  if (
    value === null ||
    value === undefined
  ) {
    return "";
  }

  return String(value);
}


// ============================================================
// 🔢 INTEGER HELPER
// ============================================================

function parseInteger(
  value,
  fallback = 0
) {
  const number =
    Number(value);

  if (
    !Number.isFinite(
      number
    )
  ) {
    return fallback;
  }

  return Math.trunc(
    number
  );
}


// ============================================================
// 🛡️ UID VALIDATION
// ============================================================

function validateUid(
  uid
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
    trimmed
  );
}


// ============================================================
// 🧩 CUSTOM DATA PARSER
// ============================================================
//
// Tuetut muodot:
//
// UID
//
// UID:power_boost
//
// UID:mining_start
//
// Vanha pelkkä UID tarkoittaa Power Boostia.
//
// ============================================================

function parseCustomData(
  customData
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
      128
  ) {
    return {
      uid:
        "",

      rewardPurpose:
        "",
    };
  }

  // ==========================================================
  // 🐱 OLD FORMAT
  // ==========================================================

  if (
    !value.includes(":")
  ) {
    return {
      uid:
        value,

      rewardPurpose:
        "power_boost",
    };
  }

  // ==========================================================
  // 🎯 NEW FORMAT
  // ==========================================================

  const separatorIndex =
    value.lastIndexOf(":");

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
        separatorIndex
      )
      .trim();

  const rewardPurpose =
    value
      .substring(
        separatorIndex + 1
      )
      .trim();

  return {
    uid,

    rewardPurpose,
  };
}


// ============================================================
// 🔐 TRANSACTION ID VALIDATION
// ============================================================

function validateTransactionId(
  transactionId
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

  // AdMob transaction_id is expected to be hexadecimal.
  return /^[a-fA-F0-9]+$/.test(
    value
  );
}


// ============================================================
// ⏱️ TIMESTAMP VALIDATION
// ============================================================

function validateTimestamp(
  timestamp
) {
  const timestampMs =
    Number(timestamp);

  if (
    !Number.isFinite(
      timestampMs
    ) ||
    timestampMs <= 0
  ) {
    return {
      valid:
        false,

      timestampMs:
        0,
    };
  }

  const now =
    Date.now();

  const ageMs =
    Math.abs(
      now -
        timestampMs
    );

  // ----------------------------------------------------------
  // Allow callbacks within 24 hours of the server time.
  // ----------------------------------------------------------

  const maxAgeMs =
    24 *
    60 *
    60 *
    1000;

  if (
    ageMs >
    maxAgeMs
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
// 🔐 VERIFY ADMOB CALLBACK
// ============================================================

async function verifyAdMobCallback(
  req
) {
  // ==========================================================
  // 🔐 SIGNATURE
  // ==========================================================

  const verification =
    await verifyAdMobSignature(
      req
    );

  const params =
    verification.params;

  // ==========================================================
  // 📥 READ VERIFIED PARAMETERS
  // ==========================================================

  const adNetwork =
    getParam(
      params,
      "ad_network"
    );

  const adUnit =
    getParam(
      params,
      "ad_unit"
    );

  const customData =
    getParam(
      params,
      "custom_data"
    );

  const rewardAmount =
    getParam(
      params,
      "reward_amount"
    );

  const rewardItem =
    getParam(
      params,
      "reward_item"
    );

  const timestamp =
    getParam(
      params,
      "timestamp"
    );

  const transactionId =
    getParam(
      params,
      "transaction_id"
    );

  const userId =
    getParam(
      params,
      "user_id"
    );

  // ==========================================================
  // 🧩 PARSE CUSTOM DATA
  // ==========================================================

  const parsedCustomData =
    parseCustomData(
      customData
    );

  const uid =
    parsedCustomData.uid;

  const rewardPurpose =
    parsedCustomData.rewardPurpose;

  // ==========================================================
  // 🛡️ REWARD PURPOSE
  // ==========================================================

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

  // ==========================================================
  // 👤 UID
  // ==========================================================

  if (
    !validateUid(
      uid
    )
  ) {
    throw new Error(
      "AdMob SSV custom_data does not contain a valid UID.",
    );
  }

  // ==========================================================
  // 📺 AD UNIT
  // ==========================================================

  const expectedAdUnit =
    ADMOB_AD_UNITS[
      rewardPurpose
    ];

  if (
    !expectedAdUnit
  ) {
    throw new Error(
      `No AdMob ad unit configured for ${rewardPurpose}.`,
    );
  }

  if (
    adUnit !==
    expectedAdUnit
  ) {
    throw new Error(
      `Invalid AdMob ad unit. Expected ${expectedAdUnit}, received ${adUnit}.`,
    );
  }

  // ==========================================================
  // 🎁 REWARD DEFINITION
  // ==========================================================

  const rewardDefinition =
    REWARD_DEFINITIONS[
      rewardPurpose
    ];

  if (
    !rewardDefinition
  ) {
    throw new Error(
      `No reward definition configured for ${rewardPurpose}.`,
    );
  }

  // ==========================================================
  // 🎁 REWARD AMOUNT
  // ==========================================================

  if (
    rewardAmount !==
    String(
      rewardDefinition.rewardAmount
    )
  ) {
    throw new Error(
      `Invalid AdMob reward amount. Expected ${rewardDefinition.rewardAmount}, received ${rewardAmount}.`,
    );
  }

  // ==========================================================
  // 🎁 REWARD ITEM
  // ==========================================================

  if (
    rewardItem !==
    rewardDefinition.rewardItem
  ) {
    throw new Error(
      `Invalid AdMob reward item. Expected "${rewardDefinition.rewardItem}", received "${rewardItem}".`,
    );
  }

  // ==========================================================
  // 🔐 TRANSACTION ID
  // ==========================================================

  if (
    !validateTransactionId(
      transactionId
    )
  ) {
    throw new Error(
      "AdMob transaction_id is missing or invalid.",
    );
  }

  // ==========================================================
  // ⏱️ TIMESTAMP
  // ==========================================================

  const timestampResult =
    validateTimestamp(
      timestamp
    );

  if (
    !timestampResult.valid
  ) {
    throw new Error(
      "AdMob timestamp is invalid or older than 24 hours.",
    );
  }

  // ==========================================================
  // 👤 USER ID
  // ==========================================================
  //
  // user_id voi puuttua AdMob SSV:stä.
  //
  // Jos se löytyy, sen täytyy vastata custom_data UID:tä.
  //
  // ==========================================================

  if (
    userId &&
    userId !==
      uid
  ) {
    throw new Error(
      "AdMob SSV user_id does not match custom_data UID.",
    );
  }

  // ==========================================================
  // 📦 NORMALIZED PARAMETERS
  // ==========================================================
  //
  // Palautetaan myös parameters-objekti yhteensopivuutta
  // varten nykyisen adFunctions.js:n kanssa.
  //
  // Tämä ei ole allekirjoituksen lähde.
  //
  // Allekirjoitus on jo tarkistettu ennen tätä kohtaa.
  //
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

    signature:
      getParam(
        params,
        "signature"
      ),

    key_id:
      getParam(
        params,
        "key_id"
      ),
  };

  // ==========================================================
  // 🐱 VERIFIED LOG
  // ==========================================================

  console.log(
    "🐱✅ AdMob SSV callback fully verified.",
    {
      uid,
      rewardPurpose,
      transactionId,
    }
  );

  // ==========================================================
  // 📤 RETURN VERIFIED AD
  // ==========================================================

  return {
    verified:
      true,

    uid,

    rewardPurpose,

    adUnit,

    adNetwork,

    rewardAmount:
      parseInteger(
        rewardAmount
      ),

    rewardItem,

    timestamp:
      timestampResult.timestampMs,

    transactionId,

    userId,

    customData,

    keyId:
      verification.keyId,

    rawQueryString:
      verification.rawQueryString,

    signedQueryString:
      verification.signedQueryString,

    // --------------------------------------------------------
    // Compatibility with adFunctions.js
    // --------------------------------------------------------

    parameters,
  };
}


// ============================================================
// 📦 EXPORTS
// ============================================================

module.exports = {
  ADMOB_AD_UNITS,

  REWARD_DEFINITIONS,

  getAdMobPublicKeys,

  verifyAdMobSignature,

  verifyAdMobCallback,

  parseCustomData,
};