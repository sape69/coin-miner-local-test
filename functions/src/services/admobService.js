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
 *
 * ADMOB SSV
 *
 * Google allekirjoittaa callback-URL:n query-stringin.
 *
 * Allekirjoitettavaa sisältöä EI saa muuttaa ennen
 * kryptografista tarkistusta.
 *
 * Googlen SSV-formaatissa kaksi viimeistä parametria ovat:
 *
 *   signature
 *   key_id
 *
 * Allekirjoitettava query-string sisältää kaikki parametrit
 * ennen "&signature=" kohtaa.
 *
 * ============================================================
 */

const ADMOB_SSV_KEYS_URL =
  "https://www.gstatic.com/admob/reward/verifier-keys.json";

/**
 * Google kierrättää AdMob SSV public key -avaimia.
 *
 * Cache pidetään alle 24 tuntia.
 */
const PUBLIC_KEY_CACHE_MS =
  23 * 60 * 60 * 1000;

let cachedPublicKeys = null;
let cachedPublicKeysAt = 0;


/**
 * ============================================================
 * 📺 STELLURIINI ADMOB AD UNITS
 * ============================================================
 *
 * AdMobin SSV callbackissa ad_unit on numeric ad unit ID.
 *
 * Nämä arvot tulee pitää samoina kuin AdMobissa.
 *
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
 *
 * Näiden arvojen tulee vastata AdMobissa kyseisille
 * rewarded ad unit -mainosyksiköille määriteltyjä arvoja.
 *
 * Näitä arvoja EI käytetä STL-saldon lisäämiseen.
 *
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

async function fetchJson(
  url,
) {
  const response =
    await fetch(
      url,
    );

  if (
    !response.ok
  ) {
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
  const now =
    Date.now();

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

  const data =
    await fetchJson(
      ADMOB_SSV_KEYS_URL,
    );


  /**
   * ----------------------------------------------------------
   * VALIDATE RESPONSE
   * ----------------------------------------------------------
   */

  if (
    !data ||
    !Array.isArray(
      data.keys,
    )
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

  const keys =
    new Map();

  for (
    const key of data.keys
  ) {
    if (
      key &&
      key.keyId !== undefined &&
      typeof key.pem ===
        "string" &&
      key.pem.length > 0
    ) {
      keys.set(
        String(
          key.keyId,
        ),
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


  /**
   * ----------------------------------------------------------
   * SAVE CACHE
   * ----------------------------------------------------------
   */

  cachedPublicKeys =
    keys;

  cachedPublicKeysAt =
    now;


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
}


/**
 * ============================================================
 * 🔎 EXTRACT RAW QUERY STRING FROM URL
 * ============================================================
 *
 * Tätä käytetään vain alkuperäisen query-osan irrottamiseen.
 *
 * Query-stringiä ei tässä vaiheessa:
 *
 * ❌ parsita
 * ❌ järjestetä
 * ❌ rakenneta uudelleen
 * ❌ URL-enkoodata
 * ❌ dekoodata
 *
 * ============================================================
 */

function extractQueryStringFromUrl(
  value,
) {
  if (
    typeof value !==
      "string" ||
    value.length === 0
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


/**
 * ============================================================
 * 🔎 GET RAW QUERY STRING
 * ============================================================
 *
 * Firebase Functions käyttää Express Request -objektia.
 *
 * Ensisijainen lähde:
 *
 *   req.originalUrl
 *
 * Fallbackit:
 *
 *   req.url
 *   req.rawUrl
 *   req._parsedUrl.search
 *
 * ============================================================
 */

function getRawQueryString(
  req,
) {
  if (
    !req
  ) {
    throw new Error(
      "Missing HTTP request.",
    );
  }


  const candidates = [
    req.originalUrl,
    req.url,
    req.rawUrl,
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
      search.startsWith(
        "?",
      ) &&
      search.length > 1
    ) {
      return search.substring(
        1,
      );
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
 * AdMob käyttää URL-safe Base64 -esitystä.
 *
 * URL-safe Base64:
 *
 *   - -> +
 *   _ -> /
 *
 * ============================================================
 */

function decodeAdMobSignature(
  signature,
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


  /**
   * Base64URL-pituus ei saa olla 1 mod 4.
   */

  if (
    normalized.length % 4 ===
      1
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
    signatureBuffer.length ===
      0
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
 * Allekirjoitettavaa sisältöä on kaikki ennen:
 *
 *   &signature=
 *
 * ============================================================
 */

function extractSignatureData(
  rawQueryString,
) {
  if (
    typeof rawQueryString !==
      "string" ||
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


  if (
    signatureIndex < 0
  ) {
    throw new Error(
      "AdMob SSV signature parameter was not found.",
    );
  }


  /**
   * ----------------------------------------------------------
   * SIGNED CONTENT
   * ----------------------------------------------------------
   *
   * Tätä merkkijonoa ei muuteta.
   */

  const signedQueryString =
    rawQueryString.substring(
      0,
      signatureIndex,
    );


  if (
    signedQueryString.length ===
      0
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
    signatureAndKeyId.split(
      "&",
    );


  /**
   * AdMob lähettää signature + key_id viimeisinä
   * parametreina tässä järjestyksessä.
   */

  if (
    parts.length !== 2
  ) {
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
  } catch (
    error
  ) {
    throw new Error(
      `AdMob SSV signature/key_id URL decoding failed: ${error.message}`,
    );
  }


  if (
    signature.length === 0
  ) {
    throw new Error(
      "AdMob SSV signature value is missing.",
    );
  }


  if (
    keyId.length === 0
  ) {
    throw new Error(
      "AdMob SSV key_id value is missing.",
    );
  }


  /**
   * key_id on numeerinen tunniste.
   */

  if (
    !/^\d+$/.test(
      keyId,
    )
  ) {
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
 * 🔐 VERIFY ONE RAW QUERY STRING
 * ============================================================
 */

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
   * GET PUBLIC KEYS
   * ----------------------------------------------------------
   */

  let publicKeys =
    await getAdMobPublicKeys(
      false,
    );


  let publicKey =
    publicKeys.get(
      String(
        keyId,
      ),
    );


  /**
   * ----------------------------------------------------------
   * REFRESH IF KEY IS UNKNOWN
   * ----------------------------------------------------------
   */

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
        String(
          keyId,
        ),
      );
  }


  if (
    !publicKey
  ) {
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
   * 🔐 ECDSA SHA-256 / DER
   * ==========================================================
   *
   * Google käyttää ECDSA SHA-256 -allekirjoitusta.
   *
   * Node.js:n verify:
   *
   *   SHA256
   *   dsaEncoding: der
   *
   * ==========================================================
   */

  const verifier =
    crypto.createVerify(
      "SHA256",
    );


  verifier.update(
    Buffer.from(
      signedQueryString,
      "utf8",
    ),
  );


  verifier.end();


  let verified =
    false;


  try {
    verified =
      verifier.verify(
        {
          key:
            publicKey,

          dsaEncoding:
            "der",
        },
        signatureBuffer,
      );
  } catch (
    error
  ) {
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


  if (
    !verified
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


  /**
   * ==========================================================
   * IMPORTANT
   * ==========================================================
   *
   * Vasta kryptografisen tarkistuksen jälkeen
   * query-string parsitaan.
   *
   * ==========================================================
   */

  return {
    verified: true,

    keyId,

    rawQueryString,

    signedQueryString,

    signature,

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

async function verifyAdMobSignature(
  req,
) {
  const rawQueryString =
    getRawQueryString(
      req,
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
  } catch (
    error
  ) {
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


  return String(
    value,
  );
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


  if (
    value.length === 0
  ) {
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
    Number(
      value,
    );


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


/**
 * ============================================================
 * 🛡️ UID VALIDATION
 * ============================================================
 */

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
 * Stelluriini käyttää:
 *
 *   UID:mining_start
 *
 * tai:
 *
 *   UID:power_boost
 *
 * Pelkkä UID ei ole hyväksytty reward-käyttötarkoitukseksi.
 *
 * ============================================================
 */

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


  /**
   * ----------------------------------------------------------
   * FIND LAST SEPARATOR
   * ----------------------------------------------------------
   */

  const separatorIndex =
    value.lastIndexOf(
      ":",
    );


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


  /**
   * ----------------------------------------------------------
   * UID
   * ----------------------------------------------------------
   */

  if (
    !validateUid(
      uid,
    )
  ) {
    return {
      uid: "",

      rewardPurpose: "",
    };
  }


  /**
   * ----------------------------------------------------------
   * REWARD PURPOSE
   * ----------------------------------------------------------
   */

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
 *
 * AdMob dokumentoi transaction_id:n yksilölliseksi
 * hex-koodatuksi reward-tunnisteeksi.
 *
 * Tämä funktio ei tarkista Firestorea.
 *
 * Duplicate-tarkistus tehdään myöhemmin atomisesti
 * Firestore transactionilla.
 *
 * ============================================================
 */

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
 *
 * AdMob timestamp:
 *
 *   Epoch time in milliseconds
 *
 * Emme aseta tässä keinotekoista 24 tunnin rajaa.
 *
 * Replay-suojaus perustuu transaction_id:n atomiseen
 * käsittelyyn Firestoressa.
 *
 * ============================================================
 */

function validateTimestamp(
  timestamp,
) {
  const timestampMs =
    Number(
      timestamp,
    );


  if (
    !Number.isFinite(
      timestampMs,
    ) ||
    timestampMs <= 0 ||
    !Number.isInteger(
      timestampMs,
    )
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
 *
 * Tämä funktio:
 *
 * 1. tarkistaa AdMob SSV-allekirjoituksen
 * 2. lukee callback-parametrit
 * 3. tarkistaa custom_data UID:n
 * 4. tarkistaa reward purposen
 * 5. tarkistaa oikean ad unitin
 * 6. tarkistaa reward amountin
 * 7. tarkistaa reward itemin
 * 8. tarkistaa transaction_id:n
 * 9. tarkistaa timestampin
 * 10. tarkistaa mahdollisen user_id:n
 *
 * TÄMÄ FUNKTIO EI:
 *
 * ❌ anna rewardia
 * ❌ kirjoita Firestoreen
 * ❌ muuta mining-tilaa
 * ❌ muuta Power Boostia
 * ❌ muuta adsToday-arvoa
 *
 * ============================================================
 */

async function verifyAdMobCallback(
  req,
) {
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
   * 2. REQUIRED SSV PARAMETERS
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


  // ==========================================================
  // 🧩 CUSTOM DATA
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
  // 🎯 REWARD PURPOSE
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
      uid,
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
      transactionId,
    )
  ) {
    throw new Error(
      "AdMob SSV transaction_id is missing or invalid.",
    );
  }


  // ==========================================================
  // ⏱️ TIMESTAMP
  // ==========================================================

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


  // ==========================================================
  // 👤 USER ID
  // ==========================================================
  //
  // AdMob user_id on valinnainen.
  //
  // Jos se tulee mukana, sen täytyy vastata
  // custom_data UID:tä.
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
  // 🔐 SIGNATURE / KEY ID
  // ==========================================================

  const signature =
    getParam(
      params,
      "signature",
    );


  const keyId =
    getParam(
      params,
      "key_id",
    );


  if (
    signature.length === 0
  ) {
    throw new Error(
      "AdMob SSV signature parameter is missing.",
    );
  }


  if (
    keyId.length === 0
  ) {
    throw new Error(
      "AdMob SSV key_id parameter is missing.",
    );
  }


  // ==========================================================
  // 📦 NORMALIZED PARAMETERS
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
  // 📝 VERIFIED LOG
  // ==========================================================

  console.log(
    "🐱✅ AdMob SSV callback fully verified.",
    {
      uid,

      rewardPurpose,

      transactionId,

      keyId:
        verification.keyId,

      adUnit,

      rewardAmount,

      rewardItem,

      timestamp:
        timestampResult.timestampMs,
    },
  );


  // ==========================================================
  // 📤 RETURN VERIFIED AD
  // ==========================================================

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

    keyId:
      verification.keyId,

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