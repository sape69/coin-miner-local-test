"use strict";

const crypto = require("crypto");

/**
 * ============================================================
 * 🐱 STELLURIINI - ADMOB SERVICE
 * ============================================================
 *
 * Vastaa:
 *
 *  - AdMob Rewarded SSV -allekirjoituksen tarkistamisesta
 *  - AdMob public key -avainten lataamisesta ja cachettamisesta
 *  - SSV-parametrien validoinnista
 *  - custom_data-arvon tulkitsemisesta
 *
 * TÄRKEÄ ARKKITEHTUURI:
 *
 * AdMob SSV
 *      ↓
 * verifyAdMobCallback()
 *      ↓
 * adMobReward()
 *      ↓
 * admobRewards/{transactionId}
 *      ↓
 * Flutter
 *      ↓
 * powerBoost() / mining start
 *
 * Tämä service EI:
 *
 *  ❌ aktivoi Power Boostia
 *  ❌ käynnistä louhintaa
 *  ❌ lisää STL-saldoa
 *  ❌ muuta adsToday-arvoa
 *  ❌ muuta cooldownia
 *
 * ============================================================
 * 🔐 SIGNATURE VERIFICATION
 * ============================================================
 *
 * Google allekirjoittaa query-stringin ennen:
 *
 *   &signature=
 *
 * Tämän vuoksi allekirjoitettua sisältöä ei saa:
 *
 *  ❌ järjestää uudelleen
 *  ❌ decodeURIComponent()-käsitellä
 *  ❌ rakentaa uudelleen
 *  ❌ URLSearchParams.toString()-käsitellä
 *  ❌ re-enkoodata
 *
 * Allekirjoitus tarkistetaan alkuperäisestä query-stringistä.
 *
 * Vasta onnistuneen allekirjoituksen jälkeen parametrit
 * parsitaan URLSearchParamsilla.
 *
 * ============================================================
 */

// ============================================================
// 🌐 ADMOB PUBLIC KEY URL
// ============================================================

const ADMOB_SSV_KEYS_URL =
  "https://www.gstatic.com/admob/reward/verifier-keys.json";

// Public keys päivitetään ennen 24 tunnin täyttymistä.

const PUBLIC_KEY_CACHE_MS =
  23 * 60 * 60 * 1000;

// ============================================================
// 🔐 PUBLIC KEY CACHE
// ============================================================

let cachedPublicKeys = null;
let cachedPublicKeysAt = 0;

// ============================================================
// 📺 STELLURIINI ADMOB AD UNITS
// ============================================================
//
// AdMob SSV:n ad_unit sisältää vain numeric ID:n.
//
// EI:
//
// ca-app-pub-xxxxxxxxxxxxxxxx/xxxxxxxxxx
//
// VAAN:
//
// 6674097787
// 7225738491
//
// ============================================================

const ADMOB_AD_UNITS = {
  mining_start: "6674097787",
  power_boost: "7225738491",
};

// ============================================================
// 🎁 EXPECTED REWARDS
// ============================================================
//
// Nämä eivät ole STL-palkkioita.
//
// Rewarded Ad kertoo vain, että oikea mainos on katsottu.
//
// Varsinainen sovelluksen toiminto käsitellään myöhemmin.
//
// ============================================================

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

// ============================================================
// 🌐 FETCH JSON
// ============================================================

async function fetchJson(url) {
  const response =
    await fetch(url);

  if (!response.ok) {
    throw new Error(
      `AdMob public key server returned HTTP ${response.status}`,
    );
  }

  return response.json();
}

// ============================================================
// 🔐 LOAD ADMOB PUBLIC KEYS
// ============================================================

async function getAdMobPublicKeys(
  forceRefresh = false,
) {
  const now =
    Date.now();

  // ----------------------------------------------------------
  // CACHE
  // ----------------------------------------------------------

  if (
    !forceRefresh &&
    cachedPublicKeys &&
    now - cachedPublicKeysAt <
      PUBLIC_KEY_CACHE_MS
  ) {
    return cachedPublicKeys;
  }

  // ----------------------------------------------------------
  // DOWNLOAD
  // ----------------------------------------------------------

  const data =
    await fetchJson(
      ADMOB_SSV_KEYS_URL,
    );

  // ----------------------------------------------------------
  // VALIDATE RESPONSE
  // ----------------------------------------------------------

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

  if (
    keys.size === 0
  ) {
    throw new Error(
      "No usable AdMob public keys were returned.",
    );
  }

  // ----------------------------------------------------------
  // CACHE
  // ----------------------------------------------------------

  cachedPublicKeys =
    keys;

  cachedPublicKeysAt =
    now;

  return keys;
}

// ============================================================
// 🔐 GET RAW QUERY STRING
// ============================================================
//
// TÄMÄ ON ERITTÄIN TÄRKEÄ.
//
// Allekirjoituksen tarkistamiseen tarvitaan alkuperäinen
// query-string sellaisena kuin Google sen lähetti.
//
// Emme käytä:
//
// URLSearchParams.toString()
//
// ennen allekirjoituksen tarkistamista.
//
// ============================================================

function getRawQueryString(req) {
  if (!req) {
    throw new Error(
      "Missing HTTP request.",
    );
  }

  // ----------------------------------------------------------
  // originalUrl
  // ----------------------------------------------------------

  if (
    typeof req.originalUrl ===
    "string"
  ) {
    const questionMark =
      req.originalUrl.indexOf("?");

    if (
      questionMark >= 0
    ) {
      return req.originalUrl.substring(
        questionMark + 1,
      );
    }
  }

  // ----------------------------------------------------------
  // url
  // ----------------------------------------------------------

  if (
    typeof req.url ===
    "string"
  ) {
    const questionMark =
      req.url.indexOf("?");

    if (
      questionMark >= 0
    ) {
      return req.url.substring(
        questionMark + 1,
      );
    }
  }

  // ----------------------------------------------------------
  // rawUrl
  // ----------------------------------------------------------

  if (
    typeof req.rawUrl ===
    "string"
  ) {
    const questionMark =
      req.rawUrl.indexOf("?");

    if (
      questionMark >= 0
    ) {
      return req.rawUrl.substring(
        questionMark + 1,
      );
    }
  }

  throw new Error(
    "AdMob SSV query string is missing.",
  );
}

// ============================================================
// 🔐 BASE64 URL-SAFE SIGNATURE
// ============================================================

function decodeAdMobSignature(
  signature,
) {
  if (
    !signature ||
    typeof signature !== "string"
  ) {
    throw new Error(
      "AdMob SSV signature is missing.",
    );
  }

  // ----------------------------------------------------------
  // AdMob käyttää URL-safe Base64 -muotoa.
  // ----------------------------------------------------------

  const normalized =
    signature
      .replace(/-/g, "+")
      .replace(/_/g, "/");

  // ----------------------------------------------------------
  // Base64 padding
  // ----------------------------------------------------------

  const padding =
    normalized.length % 4;

  const padded =
    padding === 0
      ? normalized
      : normalized +
        "=".repeat(
          4 - padding,
        );

  // ----------------------------------------------------------
  // Decode
  // ----------------------------------------------------------

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

// ============================================================
// 🔐 VERIFY ADMOB SIGNATURE
// ============================================================

async function verifyAdMobSignature(
  req,
) {
  // ----------------------------------------------------------
  // RAW QUERY
  // ----------------------------------------------------------

  const rawQueryString =
    getRawQueryString(
      req,
    );

  /**
   * Google SSV:
   *
   *   ...parameters...
   *   &signature=...
   *   &key_id=...
   *
   * Allekirjoitettava sisältö on kaikki ennen
   * signature-parametria.
   */

  const signatureMarker =
    "&signature=";

  const signatureIndex =
    rawQueryString.indexOf(
      signatureMarker,
    );

  if (
    signatureIndex === -1
  ) {
    throw new Error(
      "AdMob SSV signature parameter was not found.",
    );
  }

  // ==========================================================
  // 🔐 RAW SIGNED CONTENT
  // ==========================================================
  //
  // ÄLÄ MUUTA TÄTÄ MERKKIJONOA.
  //
  // ==========================================================

  const rawSignedQueryString =
    rawQueryString.substring(
      0,
      signatureIndex,
    );

  // ==========================================================
  // 🔎 SIGNATURE + KEY ID
  // ==========================================================
  //
  // Parsitaan vasta nyt signature ja key_id.
  //
  // ==========================================================

  const signatureAndKeyId =
    rawQueryString.substring(
      signatureIndex + 1,
    );

  const signatureParams =
    new URLSearchParams(
      signatureAndKeyId,
    );

  const signature =
    signatureParams.get(
      "signature",
    );

  const keyId =
    signatureParams.get(
      "key_id",
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
  // 🔐 DECODE SIGNATURE
  // ==========================================================

  const signatureBuffer =
    decodeAdMobSignature(
      signature,
    );

  // ==========================================================
  // 🔑 PUBLIC KEY
  // ==========================================================

  let publicKeys =
    await getAdMobPublicKeys(
      false,
    );

  let publicKey =
    publicKeys.get(
      String(keyId),
    );

  // ----------------------------------------------------------
  // Key rotation:
  //
  // Jos key_id:tä ei löydy cachesta, ladataan avaimet kerran
  // uudelleen.
  // ----------------------------------------------------------

  if (
    !publicKey
  ) {
    publicKeys =
      await getAdMobPublicKeys(
        true,
      );

    publicKey =
      publicKeys.get(
        String(keyId),
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

  const verifier =
    crypto.createVerify(
      "SHA256",
    );

  verifier.update(
    Buffer.from(
      rawSignedQueryString,
      "utf8",
    ),
  );

  verifier.end();

  const verified =
    verifier.verify(
      publicKey,
      signatureBuffer,
    );

  if (
    !verified
  ) {
    console.error(
      "🐱❌ AdMob SSV signature INVALID.",
      {
        keyId,
      },
    );

    throw new Error(
      "AdMob SSV signature verification failed.",
    );
  }

  console.log(
    "🐱✅ AdMob SSV signature VERIFIED.",
    {
      keyId,
    },
  );

  // ==========================================================
  // 🔎 PARSE PARAMETERS
  // ==========================================================
  //
  // Tämä tehdään vasta allekirjoituksen onnistuneen
  // tarkistuksen jälkeen.
  //
  // ==========================================================

  const params =
    new URLSearchParams(
      rawQueryString,
    );

  return {
    verified: true,

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
    value === null ||
    value === undefined
  ) {
    return "";
  }

  return value;
}

// ============================================================
// 🔢 INTEGER PARSER
// ============================================================

function parseInteger(
  value,
  fallback = 0,
) {
  const number =
    Number(value);

  if (
    !Number.isFinite(
      number,
    )
  ) {
    return fallback;
  }

  return Math.trunc(
    number,
  );
}

// ============================================================
// 👤 UID VALIDATION
// ============================================================
//
// Firebase UID:ssa käytetään tyypillisesti turvallista
// merkkijonoa. Rajoitetaan arvo samalla tavalla kuin
// adMobReward-funktiossa.
//
// ============================================================

function validateUid(
  uid,
) {
  if (
    typeof uid !==
    "string"
  ) {
    return "";
  }

  const value =
    uid.trim();

  if (
    value.length === 0 ||
    value.length > 128
  ) {
    return "";
  }

  if (
    !/^[A-Za-z0-9._-]+$/.test(
      value,
    )
  ) {
    return "";
  }

  return value;
}

// ============================================================
// 🔐 CUSTOM DATA PARSER
// ============================================================
//
// Tuetut muodot:
//
//   UID
//
//   UID:power_boost
//
//   UID:mining_start
//
// Vanha pelkkä UID tarkoittaa Power Boostia.
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

  // ==========================================================
  // 🐱 LEGACY FORMAT
  // ==========================================================

  if (
    !value.includes(":")
  ) {
    const uid =
      validateUid(
        value,
      );

    if (
      !uid
    ) {
      return {
        uid: "",
        rewardPurpose: "",
      };
    }

    return {
      uid,

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
    validateUid(
      value.substring(
        0,
        separatorIndex,
      ),
    );

  const rewardPurpose =
    value.substring(
      separatorIndex + 1,
    ).trim();

  if (
    !uid
  ) {
    return {
      uid: "",
      rewardPurpose: "",
    };
  }

  if (
    rewardPurpose !==
      "power_boost" &&
    rewardPurpose !==
      "mining_start"
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

// ============================================================
// 🆔 TRANSACTION ID VALIDATION
// ============================================================

function validateTransactionId(
  transactionId,
) {
  if (
    typeof transactionId !==
    "string"
  ) {
    return "";
  }

  const value =
    transactionId.trim();

  if (
    value.length === 0 ||
    value.length > 256
  ) {
    return "";
  }

  // AdMob transaction_id on hex-encoded unique identifier.

  if (
    !/^[a-fA-F0-9]+$/.test(
      value,
    )
  ) {
    return "";
  }

  return value;
}

// ============================================================
// 🕒 TIMESTAMP VALIDATION
// ============================================================

function validateTimestamp(
  timestamp,
) {
  const timestampMs =
    Number(timestamp);

  if (
    !Number.isFinite(
      timestampMs,
    ) ||
    timestampMs <= 0
  ) {
    return 0;
  }

  // AdMob timestamp is milliseconds since epoch.

  const now =
    Date.now();

  const ageMs =
    Math.abs(
      now - timestampMs,
    );

  const maxAgeMs =
    24 * 60 * 60 * 1000;

  if (
    ageMs > maxAgeMs
  ) {
    return 0;
  }

  return timestampMs;
}

// ============================================================
// 🎯 VERIFY ADMOB CALLBACK
// ============================================================
//
// Tämä on tämän tiedoston pääfunktio.
//
// Se:
//
// 1. tarkistaa SSV-allekirjoituksen
// 2. lukee parametrit
// 3. tunnistaa UID:n
// 4. tunnistaa reward purposen
// 5. tarkistaa oikean ad unitin
// 6. tarkistaa reward itemin
// 7. tarkistaa reward amountin
// 8. tarkistaa transaction ID:n
// 9. tarkistaa timestampin
// 10. tarkistaa user_id:n
//
// Se EI aktivoi mitään rewardia.
//
// ============================================================

async function verifyAdMobCallback(
  req,
) {
  // ==========================================================
  // 🔐 SIGNATURE
  // ==========================================================

  const verification =
    await verifyAdMobSignature(
      req,
    );

  const params =
    verification.params;

  // ==========================================================
  // 📺 PARAMETERS
  // ==========================================================

  const adNetwork =
    getParam(
      params,
      "ad_network",
    );

  const adUnit =
    getParam(
      params,
      "ad_unit",
    );

  const customData =
    getParam(
      params,
      "custom_data",
    );

  const rewardAmount =
    getParam(
      params,
      "reward_amount",
    );

  const rewardItem =
    getParam(
      params,
      "reward_item",
    );

  const timestamp =
    getParam(
      params,
      "timestamp",
    );

  const transactionId =
    getParam(
      params,
      "transaction_id",
    );

  const userId =
    getParam(
      params,
      "user_id",
    ).trim();

  // ==========================================================
  // 🔐 CUSTOM DATA
  // ==========================================================

  const parsedCustomData =
    parseCustomData(
      customData,
    );

  const uid =
    parsedCustomData.uid;

  const rewardPurpose =
    parsedCustomData.rewardPurpose;

  // ==========================================================
  // 🎯 PURPOSE
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
    !uid
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

  // ==========================================================
  // 🔢 REWARD AMOUNT
  // ==========================================================

  if (
    rewardAmount !==
    String(
      rewardDefinition.rewardAmount,
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
  // 🆔 TRANSACTION ID
  // ==========================================================

  const validatedTransactionId =
    validateTransactionId(
      transactionId,
    );

  if (
    !validatedTransactionId
  ) {
    throw new Error(
      "AdMob transaction_id is missing or invalid.",
    );
  }

  // ==========================================================
  // 🕒 TIMESTAMP
  // ==========================================================

  const validatedTimestamp =
    validateTimestamp(
      timestamp,
    );

  if (
    !validatedTimestamp
  ) {
    throw new Error(
      "AdMob timestamp is invalid or older than 24 hours.",
    );
  }

  // ==========================================================
  // 👤 USER ID
  // ==========================================================
  //
  // user_id voi puuttua AdMob-konfiguraatiosta riippuen.
  //
  // Jos se on mukana, sen täytyy vastata custom_data UID:tä.
  //
  // ==========================================================

  if (
    userId &&
    userId !== uid
  ) {
    throw new Error(
      "AdMob SSV user_id does not match custom_data UID.",
    );
  }

  // ==========================================================
  // 🌐 AD NETWORK
  // ==========================================================

  const normalizedAdNetwork =
    adNetwork ||
    "admob";

  // ==========================================================
  // 🐱 SUCCESS
  // ==========================================================

  console.log(
    "🐱✅ AdMob SSV callback fully verified.",
    {
      uid,
      rewardPurpose,
      transactionId:
        validatedTransactionId,
    },
  );

  // ==========================================================
  // 📤 NORMALIZED RESULT
  // ==========================================================
  //
  // TÄRKEÄ:
  //
  // Tämä rakenne vastaa suoraan adMobReward.js:n odottamaa
  // rakennetta.
  //
  // Ei enää tarpeetonta:
  //
  // verifiedAd.parameters
  //
  // -rakennetta.
  //
  // ==========================================================

  return {
    verified: true,

    uid,

    rewardPurpose,

    adUnit,

    adNetwork:
      normalizedAdNetwork,

    rewardAmount:
      parseInteger(
        rewardAmount,
        0,
      ),

    rewardItem,

    timestamp:
      validatedTimestamp,

    transactionId:
      validatedTransactionId,

    userId,

    customData,

    keyId:
      verification.keyId,

    rawQueryString:
      verification.rawQueryString,

    signedQueryString:
      verification.signedQueryString,
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