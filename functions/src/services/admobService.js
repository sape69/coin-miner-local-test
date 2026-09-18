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
 * 🛡️ Reward-parametrien validoinnista
 * 👤 UID:n validoinnista
 * 🔐 Transaction ID:n validoinnista
 * ⏱️ Timestampin validoinnista
 *
 * TÄMÄ TIEDOSTO EI:
 *
 * ❌ lisää STL-saldoa
 * ❌ aktivoi Power Boostia
 * ❌ käynnistä Mining Startia
 * ❌ muuta adsToday-arvoa
 * ❌ muuta cooldownia
 * ❌ muuta mining-tilaa
 * ❌ käsittele transaction_id:tä Firestore-replay-estona
 *
 * ============================================================
 *
 * ADMOB SSV
 *
 * Google allekirjoittaa SSV-callbackin query-stringin.
 *
 * Allekirjoitettava sisältö on:
 *
 *   kaikki query-parametrit ennen:
 *
 *   &signature=
 *
 * Query-stringiä EI saa ennen allekirjoituksen tarkistamista:
 *
 * ❌ järjestää uudelleen
 * ❌ rakentaa uudelleen
 * ❌ URL-enkoodata uudelleen
 * ❌ URL-dekoodata uudelleen
 * ❌ muuttaa URLSearchParams.toString():lla
 *
 * URLSearchParamsia käytetään vasta allekirjoituksen
 * onnistuneen tarkistamisen jälkeen parametrien lukemiseen.
 *
 * ============================================================
 */

const ADMOB_SSV_KEYS_URL =
  "https://www.gstatic.com/admob/reward/verifier-keys.json";

/**
 * Google suosittelee public key -avainten cachettamista,
 * mutta ei yli 24 tunniksi, koska avaimet voivat vaihtua.
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
 * Nämä arvot pitää vastata AdMobin kyseisen ad unitin
 * Reward-asetuksia.
 *
 * TÄMÄ EI tarkoita, että tässä annetaan STL:ää.
 *
 * Tämä tiedosto vain varmistaa, että SSV-callbackin reward
 * vastaa sitä rewardia, jota kyseiselle ad unitille odotetaan.
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
      key.pem.trim().length > 0
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
 * TÄRKEÄÄ:
 *
 * Tässä käytetään vain requestin alkuperäisiä URL-esityksiä.
 *
 * Emme rakenna query-stringiä req.query-objektista, koska se
 * voisi muuttaa parametrien järjestystä tai URL-enkoodausta.
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
 * Googlen SSV-formaatissa:
 *
 *   ...&signature=...&key_id=...
 *
 * signature ja key_id ovat kaksi viimeistä parametria.
 *
 * Allekirjoitettava sisältö on kaikki sitä ennen.
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
    const decodeError =
      new Error(
        "AdMob SSV signature or key_id contains invalid URL encoding.",
      );

    decodeError.code =
      "ADMOB_INVALID_URL_ENCODING";

    decodeError.cause =
      error;

    throw decodeError;
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

  let publicKeys =
    await getAdMobPublicKeys(
      false,
    );

  let publicKey =
    publicKeys.get(
      String(keyId),
    );

  /**
   * Jos key_id ei löydy cachesta, haetaan AdMobilta
   * tuore public key -lista.
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
   * Google käyttää ECDSA SHA-256 -allekirjoitusta DER-
   * esityksessä.
   *
   * Signed query string lähetetään verifierille
   * muuttamattomana UTF-8-datana.
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

  let verified = false;

  try {
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
        "AdMob SSV signature verification could not be performed.",
      );

    verificationError.code =
      "ADMOB_SIGNATURE_VERIFY_ERROR";

    verificationError.keyId =
      keyId;

    verificationError.cause =
      error;

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
   * Vasta tässä vaiheessa raw query voidaan parsia
   * parametreiksi.
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
       * Vain signature mismatch saa yrittämään
       * seuraavaa URL-representaatiota.
       *
       * Muita virheitä ei piiloteta.
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

  if (
    lastError &&
    lastError.keyId
  ) {
    error.keyId =
      lastError.keyId;
  }

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

  return /^[A-Za-z0-9._-]+$/.test(
    trimmed,
  );
}


/**
 * ============================================================
 * 🧩 CUSTOM DATA PARSER
 * ============================================================
 *
 * Stelluriinin käyttämä muoto:
 *
 *   UID:power_boost
 *   UID:mining_start
 *
 * TÄRKEÄÄ:
 *
 * Vanhaa muotoa:
 *
 *   UID
 *
 * ei enää tulkita automaattisesti Power Boostiksi.
 *
 * Purpose pitää tulla eksplisiittisesti.
 *
 * Tämä poistaa epäselvän reward-tyypin oletuksen.
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
 * AdMob käyttää transaction_id:tä yksilöimään reward-
 * tapahtuman.
 *
 * TÄMÄ FUNKTIO tarkistaa vain muodon.
 *
 * Varsinainen duplicate/replay-estäminen tehdään
 * myöhemmin Firestoressa transaction_id:n avulla.
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
 * AdMob ilmoittaa timestampin Epoch-millisekunteina.
 *
 * Käytämme 24 tunnin hyväksyntäikkunaa.
 *
 * HUOM:
 *
 * Tämä EI yksinään estä replayta.
 *
 * Replay-estoon tarvitaan transaction_id + Firestore
 * atominen käsittely.
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
 */

async function verifyAdMobCallback(
  req,
) {
  /**
   * ==========================================================
   * 1. VERIFY CRYPTOGRAPHIC SIGNATURE
   * ==========================================================
   */

  const verification =
    await verifyAdMobSignature(
      req,
    );

  /**
   * ==========================================================
   * 2. READ PARAMETERS
   * ==========================================================
   *
   * Tähän päästään vasta kun signature on hyväksytty.
   */

  const params =
    verification.params;

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
  // 🌐 AD NETWORK
  // ==========================================================

  if (
    adNetwork.length === 0
  ) {
    throw new Error(
      "AdMob SSV ad_network is missing.",
    );
  }


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
  // Flutterin nykyinen HomeAdManager käyttää custom_dataa:
  //
  //   UID:purpose
  //
  // eikä aseta AdMob user_id:tä.
  //
  // Siksi user_id on vapaaehtoinen.
  //
  // Jos AdMob kuitenkin lähettää sen, sen pitää vastata UID:tä.
  //

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

  validateUid,

  validateTransactionId,

  validateTimestamp,
};