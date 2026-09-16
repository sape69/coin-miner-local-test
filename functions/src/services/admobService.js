"use strict";

const crypto = require("crypto");

const ADMOB_PUBLIC_KEYS_URL =
  "https://www.gstatic.com/admob/reward/verifier-keys.json";

const PUBLIC_KEY_CACHE_MS =
  23 * 60 * 60 * 1000;

const ADMOB_AD_UNITS = {
  mining_start:
    "ca-app-pub-1131012057145658/6674097787",

  power_boost:
    "ca-app-pub-1131012057145658/7225738491",
};

const ADMOB_REWARD_ITEMS = {
  mining_start:
    "Mining",

  power_boost:
    "Power Boost",
};

const ADMOB_REWARD_AMOUNT = 1;

let publicKeyCache = null;
let publicKeyCacheTimestamp = 0;

// ============================================================
// 🔐 FETCH GOOGLE ADMOB PUBLIC KEYS
// ============================================================

async function fetchPublicKeys() {
  const now =
    Date.now();

  if (
    publicKeyCache &&
    now - publicKeyCacheTimestamp <
      PUBLIC_KEY_CACHE_MS
  ) {
    return publicKeyCache;
  }

  console.log(
    "🐱🔐 Fetching fresh AdMob SSV public keys."
  );

  const response =
    await fetch(
      ADMOB_PUBLIC_KEYS_URL
    );

  if (!response.ok) {
    throw new Error(
      `Failed to fetch AdMob public keys. HTTP ${response.status}.`
    );
  }

  const data =
    await response.json();

  if (
    !data ||
    !Array.isArray(data.keys) ||
    data.keys.length === 0
  ) {
    throw new Error(
      "AdMob public key response contained no keys."
    );
  }

  const keyMap =
    new Map();

  for (
    const key of data.keys
  ) {
    if (
      !key ||
      key.keyId == null
    ) {
      continue;
    }

    const keyId =
      String(
        key.keyId
      );

    // --------------------------------------------------------
    // PEM
    // --------------------------------------------------------

    if (
      typeof key.pem === "string" &&
      key.pem.trim() !== ""
    ) {
      const publicKey =
        crypto.createPublicKey(
          key.pem
        );

      keyMap.set(
        keyId,
        publicKey
      );

      continue;
    }

    // --------------------------------------------------------
    // BASE64 SPKI
    // --------------------------------------------------------

    if (
      typeof key.base64 === "string" &&
      key.base64.trim() !== ""
    ) {
      const derBuffer =
        Buffer.from(
          key.base64,
          "base64"
        );

      const publicKey =
        crypto.createPublicKey({
          key:
            derBuffer,
          format:
            "der",
          type:
            "spki",
        });

      keyMap.set(
        keyId,
        publicKey
      );
    }
  }

  if (
    keyMap.size === 0
  ) {
    throw new Error(
      "No usable AdMob public verification keys found."
    );
  }

  publicKeyCache =
    keyMap;

  publicKeyCacheTimestamp =
    now;

  console.log(
    `🐱🔐 Loaded ${keyMap.size} AdMob SSV public key(s).`
  );

  return keyMap;
}

// ============================================================
// 🌐 GET ORIGINAL REQUEST URL
// ============================================================

function getRequestUrl(
  req
) {
  const candidates = [
    req.url,
    req.originalUrl,
    req.rawUrl,
  ];

  for (
    const value of candidates
  ) {
    if (
      typeof value === "string" &&
      value.includes("?")
    ) {
      return value;
    }
  }

  throw new Error(
    "Could not obtain the original AdMob SSV request URL."
  );
}

// ============================================================
// 🌐 GET RAW QUERY STRING
// ============================================================

function getRawQueryString(
  req
) {
  const requestUrl =
    getRequestUrl(
      req
    );

  const questionMarkIndex =
    requestUrl.indexOf("?");

  if (
    questionMarkIndex === -1
  ) {
    throw new Error(
      "AdMob SSV request does not contain a query string."
    );
  }

  const queryString =
    requestUrl.substring(
      questionMarkIndex + 1
    );

  if (
    queryString.length === 0
  ) {
    throw new Error(
      "AdMob SSV query string is empty."
    );
  }

  return queryString;
}

// ============================================================
// 🔐 DECODE SIGNED QUERY
// ============================================================
//
// Google AdMobin SSV-esimerkissä query otetaan URI:n
// query-osasta ennen allekirjoituksen tarkistusta.
//
// custom_data voi olla percent-escaped:
//
// UID%3Amining_start
//
// →
//
// UID:mining_start
//
// ============================================================

function decodeSignedQuery(
  rawSignedQuery
) {
  try {
    return decodeURIComponent(
      rawSignedQuery
    );
  } catch (
    error
  ) {
    throw new Error(
      `Failed to decode AdMob SSV signed query: ${error.message}`
    );
  }
}

// ============================================================
// 🔐 EXTRACT SIGNED CONTENT
// ============================================================

function extractSignedContent(
  rawQueryString
) {
  const signatureMarker =
    "&signature=";

  const signatureIndex =
    rawQueryString.indexOf(
      signatureMarker
    );

  if (
    signatureIndex === -1
  ) {
    throw new Error(
      "AdMob SSV signature parameter was not found."
    );
  }

  if (
    signatureIndex === 0
  ) {
    throw new Error(
      "AdMob SSV signed content is empty."
    );
  }

  const rawSignedQuery =
    rawQueryString.substring(
      0,
      signatureIndex
    );

  const decodedSignedQuery =
    decodeSignedQuery(
      rawSignedQuery
    );

  return {
    rawSignedQuery,
    decodedSignedQuery,
  };
}

// ============================================================
// 🔐 EXTRACT SIGNATURE + KEY ID
// ============================================================

function extractSignatureAndKeyId(
  rawQueryString
) {
  const signatureMarker =
    "&signature=";

  const signatureIndex =
    rawQueryString.indexOf(
      signatureMarker
    );

  if (
    signatureIndex === -1
  ) {
    throw new Error(
      "AdMob SSV signature parameter was not found."
    );
  }

  const afterSignature =
    rawQueryString.substring(
      signatureIndex +
        signatureMarker.length
    );

  const keyIdMarker =
    "&key_id=";

  const keyIdIndex =
    afterSignature.indexOf(
      keyIdMarker
    );

  if (
    keyIdIndex === -1
  ) {
    throw new Error(
      "AdMob SSV key_id parameter was not found."
    );
  }

  let rawSignature =
    afterSignature.substring(
      0,
      keyIdIndex
    );

  let rawKeyId =
    afterSignature.substring(
      keyIdIndex +
        keyIdMarker.length
    );

  if (
    rawSignature.length === 0
  ) {
    throw new Error(
      "AdMob SSV signature is empty."
    );
  }

  if (
    rawKeyId.length === 0
  ) {
    throw new Error(
      "AdMob SSV key_id is empty."
    );
  }

  try {
    rawSignature =
      decodeURIComponent(
        rawSignature
      );
  } catch (
    error
  ) {
    throw new Error(
      `Invalid AdMob SSV signature encoding: ${error.message}`
    );
  }

  try {
    rawKeyId =
      decodeURIComponent(
        rawKeyId
      );
  } catch (
    error
  ) {
    throw new Error(
      `Invalid AdMob SSV key_id encoding: ${error.message}`
    );
  }

  return {
    rawSignature,
    rawKeyId,
  };
}

// ============================================================
// 🔐 DECODE BASE64URL SIGNATURE
// ============================================================

function decodeSignature(
  rawSignature
) {
  const signature =
    Buffer.from(
      rawSignature,
      "base64url"
    );

  if (
    signature.length === 0
  ) {
    throw new Error(
      "Decoded AdMob SSV signature is empty."
    );
  }

  return signature;
}

// ============================================================
// 🔐 VERIFY ECDSA SIGNATURE
// ============================================================

async function verifySignature({
  signedContent,
  rawSignature,
  keyId,
}) {
  const publicKeys =
    await fetchPublicKeys();

  const publicKey =
    publicKeys.get(
      String(keyId)
    );

  if (
    !publicKey
  ) {
    throw new Error(
      `No AdMob public key found for key_id ${keyId}.`
    );
  }

  const signatureBuffer =
    decodeSignature(
      rawSignature
    );

  const signedContentBuffer =
    Buffer.from(
      signedContent,
      "utf8"
    );

  console.log(
    "🐱🔐 Verifying AdMob SSV signature.",
    {
      keyId:
        String(keyId),

      signedBytes:
        signedContentBuffer.length,

      signatureBytes:
        signatureBuffer.length,
    }
  );

  const valid =
    crypto.verify(
      "sha256",
      signedContentBuffer,
      {
        key:
          publicKey,

        dsaEncoding:
          "der",
      },
      signatureBuffer
    );

  if (
    !valid
  ) {
    console.error(
      "🐱❌ AdMob SSV signature INVALID."
    );

    throw new Error(
      "AdMob SSV signature verification failed."
    );
  }

  console.log(
    "🐱✅ AdMob SSV signature VALID."
  );

  return true;
}

// ============================================================
// 📦 PARSE VERIFIED QUERY PARAMETERS
// ============================================================
//
// Tämä tehdään vasta onnistuneen allekirjoituksen jälkeen.
//
// ============================================================

function parseVerifiedParameters(
  decodedSignedQuery
) {
  const params =
    new URLSearchParams(
      decodedSignedQuery
    );

  function required(
    name
  ) {
    const value =
      params.get(
        name
      );

    if (
      value === null ||
      value === ""
    ) {
      throw new Error(
        `AdMob SSV parameter "${name}" is missing.`
      );
    }

    return value;
  }

  return {
    adNetwork:
      required(
        "ad_network"
      ),

    adUnit:
      required(
        "ad_unit"
      ),

    rewardAmount:
      required(
        "reward_amount"
      ),

    rewardItem:
      required(
        "reward_item"
      ),

    timestamp:
      required(
        "timestamp"
      ),

    transactionId:
      required(
        "transaction_id"
      ),

    customData:
      params.get(
        "custom_data"
      ),

    userId:
      params.get(
        "user_id"
      ),
  };
}

// ============================================================
// 🔐 DECODE CUSTOM DATA
// ============================================================
//
// URLSearchParams on jo dekoodannut query-parametrin.
//
// Tämä lisäkäsittely on tarkoitettu vain sellaiseen tilanteeseen,
// jossa custom_data sisältää vielä percent-escapeja.
//
// ============================================================

function decodeCustomData(
  customData
) {
  if (
    typeof customData !== "string"
  ) {
    return "";
  }

  let value =
    customData.trim();

  if (
    value.length === 0
  ) {
    return "";
  }

  // ----------------------------------------------------------
  // Yritetään dekoodata enintään kaksi kertaa.
  //
  // Tämä kattaa normaalin:
  //
  // UID%3Amining_start
  //
  // sekä mahdollisen kaksinkertaisen escapingin.
  // ----------------------------------------------------------

  for (
    let i = 0;
    i < 2;
    i++
  ) {
    if (
      !/%[0-9A-Fa-f]{2}/.test(
        value
      )
    ) {
      break;
    }

    try {
      const decoded =
        decodeURIComponent(
          value
        );

      if (
        decoded === value
      ) {
        break;
      }

      value =
        decoded;
    } catch (
      error
    ) {
      throw new Error(
        `Invalid AdMob custom_data encoding: ${error.message}`
      );
    }
  }

  return value.trim();
}

// ============================================================
// 🎯 PARSE CUSTOM DATA
// ============================================================
//
// Odotettu muoto:
//
// UID:mining_start
//
// tai:
//
// UID:power_boost
//
// ============================================================

function parseCustomData(
  customData
) {
  const decoded =
    decodeCustomData(
      customData
    );

  if (
    decoded.length === 0
  ) {
    throw new Error(
      "AdMob SSV custom_data is missing."
    );
  }

  if (
    decoded.length > 128
  ) {
    throw new Error(
      "AdMob SSV custom_data is too long."
    );
  }

  const separatorIndex =
    decoded.lastIndexOf(":");

  if (
    separatorIndex <= 0 ||
    separatorIndex >=
      decoded.length - 1
  ) {
    throw new Error(
      "Invalid AdMob custom_data format."
    );
  }

  const uid =
    decoded.substring(
      0,
      separatorIndex
    );

  const purpose =
    decoded.substring(
      separatorIndex + 1
    );

  if (
    uid.length === 0 ||
    uid.length > 128
  ) {
    throw new Error(
      "Invalid UID in AdMob custom_data."
    );
  }

  if (
    !/^[A-Za-z0-9._-]+$/.test(
      uid
    )
  ) {
    throw new Error(
      "Invalid UID characters in AdMob custom_data."
    );
  }

  if (
    purpose !==
      "mining_start" &&
    purpose !==
      "power_boost"
  ) {
    throw new Error(
      `Unsupported AdMob reward purpose: ${purpose}`
    );
  }

  return {
    uid,
    purpose,
    customData:
      decoded,
  };
}

// ============================================================
// 🛡️ VALIDATE VERIFIED REWARD
// ============================================================

function validateRewardParameters(
  parameters,
  customDataInfo
) {
  const {
    adNetwork,
    adUnit,
    rewardAmount,
    rewardItem,
    timestamp,
    transactionId,
    userId,
  } = parameters;

  const {
    uid,
    purpose,
  } =
    customDataInfo;

  const expectedAdUnit =
    ADMOB_AD_UNITS[
      purpose
    ];

  const expectedRewardItem =
    ADMOB_REWARD_ITEMS[
      purpose
    ];

  // ----------------------------------------------------------
  // AD UNIT
  // ----------------------------------------------------------

  if (
    adUnit !==
    expectedAdUnit
  ) {
    throw new Error(
      `Invalid AdMob ad unit for ${purpose}. ` +
        `Expected ${expectedAdUnit}, received ${adUnit}.`
    );
  }

  // ----------------------------------------------------------
  // REWARD AMOUNT
  // ----------------------------------------------------------

  const numericRewardAmount =
    Number(
      rewardAmount
    );

  if (
    !Number.isFinite(
      numericRewardAmount
    ) ||
    numericRewardAmount !==
      ADMOB_REWARD_AMOUNT
  ) {
    throw new Error(
      `Invalid AdMob reward amount. ` +
        `Expected ${ADMOB_REWARD_AMOUNT}, received ${rewardAmount}.`
    );
  }

  // ----------------------------------------------------------
  // REWARD ITEM
  // ----------------------------------------------------------

  if (
    rewardItem !==
    expectedRewardItem
  ) {
    throw new Error(
      `Invalid AdMob reward item for ${purpose}. ` +
        `Expected "${expectedRewardItem}", received "${rewardItem}".`
    );
  }

  // ----------------------------------------------------------
  // TRANSACTION ID
  // ----------------------------------------------------------

  if (
    !transactionId
  ) {
    throw new Error(
      "AdMob transaction_id is missing."
    );
  }

  if (
    !/^[a-fA-F0-9]+$/.test(
      transactionId
    )
  ) {
    throw new Error(
      "AdMob transaction_id has an invalid format."
    );
  }

  // ----------------------------------------------------------
  // TIMESTAMP
  // ----------------------------------------------------------

  const numericTimestamp =
    Number(
      timestamp
    );

  if (
    !Number.isFinite(
      numericTimestamp
    ) ||
    numericTimestamp <= 0
  ) {
    throw new Error(
      "AdMob timestamp is invalid."
    );
  }

  const now =
    Date.now();

  const maxAgeMs =
    24 *
    60 *
    60 *
    1000;

  if (
    Math.abs(
      now -
        numericTimestamp
    ) > maxAgeMs
  ) {
    throw new Error(
      "AdMob SSV timestamp is outside the allowed time window."
    );
  }

  // ----------------------------------------------------------
  // OPTIONAL USER ID
  // ----------------------------------------------------------

  if (
    userId &&
    userId !== uid
  ) {
    throw new Error(
      "AdMob user_id does not match custom_data UID."
    );
  }

  return {
    uid,

    purpose,

    adNetwork,

    adUnit,

    rewardAmount:
      numericRewardAmount,

    rewardItem,

    transactionId,

    timestamp:
      numericTimestamp,

    userId:
      userId ||
      null,
  };
}

// ============================================================
// 🔐 MAIN ADMOB SSV VERIFICATION
// ============================================================

async function verifyAdMobCallback(
  req
) {
  try {
    console.log(
      "🐱📺 AdMob SSV callback received."
    );

    // --------------------------------------------------------
    // RAW QUERY
    // --------------------------------------------------------

    const rawQueryString =
      getRawQueryString(
        req
      );

    console.log(
      `🐱📺 AdMob SSV raw query length: ${rawQueryString.length}`
    );

    // --------------------------------------------------------
    // SIGNED CONTENT
    // --------------------------------------------------------

    const {
      rawSignedQuery,
      decodedSignedQuery,
    } =
      extractSignedContent(
        rawQueryString
      );

    console.log(
      `🐱📺 AdMob SSV raw signed length: ${rawSignedQuery.length}`
    );

    console.log(
      `🐱📺 AdMob SSV decoded signed length: ${decodedSignedQuery.length}`
    );

    // --------------------------------------------------------
    // SIGNATURE + KEY ID
    // --------------------------------------------------------

    const {
      rawSignature,
      rawKeyId,
    } =
      extractSignatureAndKeyId(
        rawQueryString
      );

    console.log(
      `🐱📺 AdMob SSV key_id received: ${rawKeyId}`
    );

    // --------------------------------------------------------
    // CRYPTOGRAPHIC VERIFICATION
    // --------------------------------------------------------

    await verifySignature({
      signedContent:
        decodedSignedQuery,

      rawSignature,

      keyId:
        rawKeyId,
    });

    // --------------------------------------------------------
    // PARSE VERIFIED QUERY
    // --------------------------------------------------------

    const parameters =
      parseVerifiedParameters(
        decodedSignedQuery
      );

    // --------------------------------------------------------
    // CUSTOM DATA
    // --------------------------------------------------------

    const customDataInfo =
      parseCustomData(
        parameters.customData
      );

    // --------------------------------------------------------
    // VALIDATE REWARD
    // --------------------------------------------------------

    const validated =
      validateRewardParameters(
        parameters,
        customDataInfo
      );

    // --------------------------------------------------------
    // SUCCESS
    // --------------------------------------------------------

    console.log(
      "🐱✅ AdMob SSV callback VERIFIED.",
      {
        uid:
          validated.uid,

        purpose:
          validated.purpose,

        adUnit:
          validated.adUnit,

        rewardItem:
          validated.rewardItem,

        rewardAmount:
          validated.rewardAmount,

        transactionId:
          validated.transactionId,
      }
    );

    return {
      verified:
        true,

      uid:
        validated.uid,

      userId:
        validated.userId,

      rewardType:
        "admob",

      rewardPurpose:
        validated.purpose,

      adNetwork:
        validated.adNetwork,

      adUnit:
        validated.adUnit,

      rewardAmount:
        validated.rewardAmount,

      rewardItem:
        validated.rewardItem,

      transactionId:
        validated.transactionId,

      timestamp:
        validated.timestamp,

      customData:
        customDataInfo.customData,

      keyId:
        String(
          rawKeyId
        ),
    };

  } catch (
    error
  ) {

    console.error(
      "🐱❌ AdMob SSV verification failed:",
      error.message
    );

    return {
      verified:
        false,

      error:
        error.message,
    };
  }
}

// ============================================================
// 📦 EXPORT
// ============================================================

module.exports = {
  verifyAdMobCallback,
};