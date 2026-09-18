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
 *
 * ============================================================
 *
 * ADMOB SSV
 *
 * Google allekirjoittaa callback-URL:n query-stringin.
 *
 * Allekirjoitettava sisältö on kaikki query-parametrit
 * ennen:
 *
 *   &signature=
 *
 * Google määrittelee, että callbackin kaksi viimeistä
 * parametria ovat:
 *
 *   signature
 *   key_id
 *
 * Allekirjoitettavaa query-stringiä EI saa:
 *
 * ❌ järjestää uudelleen
 * ❌ rakentaa uudelleen
 * ❌ URL-enkoodata uudelleen
 * ❌ muuttaa URLSearchParams.toString():lla
 *
 * URLSearchParamsia käytetään vasta allekirjoituksen
 * tarkistamisen jälkeen parametrien lukemiseen.
 *
 * ============================================================
 */

const ADMOB_SSV_KEYS_URL =
  "https://www.gstatic.com/admob/reward/verifier-keys.json";

/**
 * AdMob vaihtaa allekirjoitusavaimia säännöllisesti.
 *
 * Google suosittelee, ettei avaimia välimuistiteta yli
 * 24 tunniksi.
 *
 * Käytetään 23 tuntia.
 */
const PUBLIC_KEY_CACHE_MS =
  23 * 60 * 60 * 1000;

let cachedPublicKeys = null;
let cachedPublicKeysAt = 0;


/**
 * ============================================================
 * 📺 STELLURIINI ADMOB AD UNITS
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
 * Näiden arvojen pitää vastata AdMobissa kyseiselle
 * rewarded ad unitille määriteltyjä reward-asetuksia.
 *
 * Näitä arvoja EI käytetä STL-saldon lisäämiseen.
 *
 * SSV-palvelu vain tarkistaa, että Google ilmoitti
 * odotetun rewardin.
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

async function fetchJson(url) {
  const response = await fetch(url);

  if (!response.ok) {
    throw new Error(
      `AdMob public key server returned HTTP ${response.status}`,
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

  if (
    !forceRefresh &&
    cachedPublicKeys &&
    now - cachedPublicKeysAt <
      PUBLIC_KEY_CACHE_MS
  ) {
    return cachedPublicKeys;
  }

  const data = await fetchJson(
    ADMOB_SSV_KEYS_URL,
  );

  if (
    !data ||
    !Array.isArray(data.keys)
  ) {
    throw new Error(
      "AdMob public key response is invalid.",
    );
  }

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

  cachedPublicKeys = keys;
  cachedPublicKeysAt = now;

  console.log(
    "🐱 AdMob public keys loaded.",
    {
      count: keys.size,
      keyIds: Array.from(keys.keys()),
    },
  );

  return keys;
}


/**
 * ============================================================
 * 🔎 EXTRACT QUERY STRING FROM URL
 * ============================================================
 */

function extractQueryStringFromUrl(
  value,
) {
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
 * 🔎 GET RAW QUERY CANDIDATES
 * ============================================================
 *
 * Firebase Functions käyttää Express Request -objektia.
 *
 * Eri Firebase/Express-versioissa URL voi löytyä eri
 * request-propertystä.
 *
 * Käytetään vain requestin raakaa URL-esitystä.
 *
 * ============================================================
 */

function getRawQueryCandidates(req) {
  if (!req) {
    throw new Error(
      "Missing HTTP request.",
    );
  }

  const candidates = [];

  const addCandidate = (
    source,
    value,
  ) => {
    const query =
      extractQueryStringFromUrl(
        value,
      );

    if (query.length === 0) {
      return;
    }

    if (
      !candidates.some(
        (item) =>
          item.query === query,
      )
    ) {
      candidates.push({
        source,
        query,
      });
    }
  };

  addCandidate(
    "req.originalUrl",
    req.originalUrl,
  );

  addCandidate(
    "req.url",
    req.url,
  );

  addCandidate(
    "req.rawUrl",
    req.rawUrl,
  );

  if (
    req._parsedUrl &&
    typeof req._parsedUrl.search ===
      "string"
  ) {
    const search =
      req._parsedUrl.search;

    if (
      search.startsWith("?")
    ) {
      addCandidate(
        "req._parsedUrl.search",
        search,
      );
    }
  }

  if (candidates.length === 0) {
    throw new Error(
      "AdMob SSV query string is missing.",
    );
  }

  return candidates;
}


/**
 * ============================================================
 * 🔐 DECODE ADMOB SIGNATURE
 * ============================================================
 *
 * AdMob käyttää URL-safe Base64 -esitystä.
 *
 * ============================================================
 */

function decodeAdMobSignature(
  signature,
) {
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

  const padding =
    normalized.length % 4;

  const padded =
    padding === 0
      ? normalized
      : normalized +
        "=".repeat(
          4 - padding,
        );

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
 * Allekirjoitettava sisältö on kaikki sitä ennen.
 *
 * TÄRKEÄÄ:
 *
 * rawQueryString säilytetään sellaisenaan.
 *
 * Sitä ei rakenneta uudelleen URLSearchParamsilla ennen
 * allekirjoituksen tarkistamista.
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
   * Kaikki ennen "&signature=" kuuluu
   * allekirjoitettuun sisältöön.
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
   * Otetaan signature ja key_id ilman että
   * alkuperäistä query-stringiä muutetaan.
   */
  const signatureAndKeyId =
    rawQueryString.substring(
      signatureIndex + 1,
    );

  const parts =
    signatureAndKeyId.split("&");

  /**
   * Googlen dokumentaation mukaan signature ja key_id
   * ovat kaksi viimeistä parametria.
   */
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
  } = extractSignatureData(
    rawQueryString,
  );

  const signatureBuffer =
    decodeAdMobSignature(
      signature,
    );

  /**
   * ----------------------------------------------------------
   * 1. Hae cached public keys
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
   * 2. Jos key_id puuttuu cachesta, pakota refresh
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
    throw new Error(
      `AdMob SSV public key not found for key_id=${keyId}`,
    );
  }

  /**
   * ==========================================================
   * 🔐 ECDSA SHA-256
   * ==========================================================
   *
   * AdMob käyttää ECDSA SHA-256 + DER.
   *
   * Allekirjoitettava data on alkuperäinen raw query
   * ennen &signature= kohtaa.
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

  const verified =
    verifier.verify(
      {
        key: publicKey,
        dsaEncoding: "der",
      },
      signatureBuffer,
    );

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
   * Vasta onnistuneen allekirjoituksen jälkeen
   * parsitaan query-parametrit.
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
  const candidates =
    getRawQueryCandidates(
      req,
    );

  let lastError = null;

  for (
    const candidate of candidates
  ) {
    try {
      const verification =
        await verifyRawQueryString(
          candidate.query,
        );

      console.log(
        "🐱✅ AdMob SSV signature VERIFIED.",
        {
          keyId:
            verification.keyId,

          source:
            candidate.source,
        },
      );

      return verification;
    } catch (error) {
      lastError = error;

      /**
       * Jos kyseessä on vain URL-esityksen
       * aiheuttama allekirjoitusmismatch,
       * kokeillaan seuraavaa raakaa URL-esitystä.
       */
      if (
        error &&
        error.code ===
          "ADMOB_INVALID_SIGNATURE"
      ) {
        console.warn(
          "🐱⚠️ AdMob SSV signature mismatch for URL representation.",
          {
            source:
              candidate.source,
          },
        );

        continue;
      }

      throw error;
    }
  }

  console.error(
    "🐱❌ AdMob SSV signature INVALID.",
    {
      candidates:
        candidates.map(
          (candidate) =>
            candidate.source,
        ),

      keyId:
        lastError &&
        lastError.keyId
          ? lastError.keyId
          : "",
    },
  );

  const error =
    new Error(
      "AdMob SSV signature verification failed.",
    );

  error.code =
    "ADMOB_INVALID_SIGNATURE";

  throw error;
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

function validateUid(
  uid,
) {
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

  /**
   * Firebase Auth UID sisältää normaalisti
   * turvallisia merkkejä.
   *
   * Sallitaan:
   *
   * A-Z
   * a-z
   * 0-9
   * .
   * _
   * -
   */
  return /^[A-Za-z0-9._-]+$/.test(
    trimmed,
  );
}


/**
 * ============================================================
 * 🧩 CUSTOM DATA PARSER
 * ============================================================
 *
 * Stelluriinin Flutter lähettää:
 *
 *   UID:mining_start
 *   UID:power_boost
 *
 * Tuettu myös vanha muoto:
 *
 *   UID
 *
 * Vanha muoto tulkitaan Power Boostiksi.
 *
 * ============================================================
 */

function parseCustomData(
  customData,
) {
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

  /**
   * Vanha custom_data:
   *
   * UID
   *
   * Säilytetään yhteensopivuus.
   */
  if (
    !value.includes(":")
  ) {
    return {
      uid: value,
      rewardPurpose: "power_boost",
    };
  }

  /**
   * Käytetään viimeistä ":"-merkkiä.
   */
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
 * Googlen mukaan transaction_id on hex-koodattu.
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
 * AdMob timestamp on Epoch milliseconds.
 *
 * Hyväksytään callback, joka on korkeintaan 24 h vanha
 * tai enintään 24 h tulevaisuudessa.
 *
 * ============================================================
 */

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
    return {
      valid: false,
      timestampMs: 0,
    };
  }

  const now =
    Date.now();

  const ageMs =
    Math.abs(
      now - timestampMs,
    );

  const maxAgeMs =
    24 *
    60 *
    60 *
    1000;

  if (
    ageMs > maxAgeMs
  ) {
    return {
      valid: false,
      timestampMs,
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
 * TÄMÄ FUNKTIO EI anna käyttäjälle rewardia.
 *
 * Rewardin käsittely tehdään erillisessä function/service-
 * kerroksessa vasta tämän palauttaman verified-datan jälkeen.
 *
 * ============================================================
 */

async function verifyAdMobCallback(
  req,
) {
  /**
   * ----------------------------------------------------------
   * 1. Verify cryptographic signature
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
   * 2. Read SSV parameters
   * ----------------------------------------------------------
   */

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
    !validateUid(uid)
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

  if (!expectedAdUnit) {
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

  if (!rewardDefinition) {
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
  // 🔐 TRANSACTION ID
  // ==========================================================

  if (
    !validateTransactionId(
      transactionId,
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
      timestamp,
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
  // user_id on AdMob SSV is optional.
  //
  // Stelluriini käyttää UID:tä custom_data-kentässä.
  //
  // Jos AdMob kuitenkin lähettää user_id:n, sen täytyy
  // vastata samaa UID:tä.
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

    signature:
      getParam(
        params,
        "signature",
      ),

    key_id:
      getParam(
        params,
        "key_id",
      ),
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
      parseInteger(
        rewardAmount,
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