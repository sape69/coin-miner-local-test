// functions/src/services/admobService.js

const crypto = require("crypto");

/**
 * ==========================================
 * STELLURIINI - ADMOB SSV SERVICE
 * ==========================================
 *
 * Vastaa:
 * - AdMob SSV public key -avainten hakemisesta
 * - SSV-signatuurin tarkistamisesta
 * - AdMob-parametrien lukemisesta
 * - custom_data-arvon käsittelystä
 * - reward-parametrien validoinnista
 *
 * HUOM:
 * AdMob SSV:n ad_unit-parametri sisältää
 * pelkän numeerisen Ad Unit ID:n.
 */

// ==========================================
// ADMOB AD UNIT IDs
// ==========================================

const ADMOB_AD_UNITS = {
  mining_start: "6674097787",
  power_boost: "7225738491",
};

// ==========================================
// REWARD DEFINITIONS
// ==========================================

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

// ==========================================
// ADMOB PUBLIC KEY CACHE
// ==========================================

let cachedPublicKeys = null;
let cachedPublicKeysTimestamp = 0;

const PUBLIC_KEY_CACHE_DURATION_MS =
  23 * 60 * 60 * 1000;

const ADMOB_PUBLIC_KEYS_URL =
  "https://www.gstatic.com/admob/reward/verifier-keys.json";

// ==========================================
// GET ADMOB PUBLIC KEYS
// ==========================================

async function getAdMobPublicKeys() {
  const now = Date.now();

  if (
    cachedPublicKeys &&
    now - cachedPublicKeysTimestamp <
      PUBLIC_KEY_CACHE_DURATION_MS
  ) {
    return cachedPublicKeys;
  }

  console.log(
    "🐱🔑 Fetching AdMob public verification keys..."
  );

  const response = await fetch(
    ADMOB_PUBLIC_KEYS_URL
  );

  if (!response.ok) {
    throw new Error(
      `Failed to fetch AdMob public keys: HTTP ${response.status}`
    );
  }

  const data = await response.json();

  if (
    !data ||
    !Array.isArray(data.keys)
  ) {
    throw new Error(
      "Invalid AdMob public key response."
    );
  }

  const keys = {};

  for (const key of data.keys) {
    if (
      key &&
      key.keyId !== undefined &&
      key.pem
    ) {
      keys[String(key.keyId)] = key.pem;
    }
  }

  if (Object.keys(keys).length === 0) {
    throw new Error(
      "No valid AdMob public keys found."
    );
  }

  cachedPublicKeys = keys;
  cachedPublicKeysTimestamp = now;

  console.log(
    `🐱🔑 Loaded ${Object.keys(keys).length} AdMob public key(s).`
  );

  return keys;
}

// ==========================================
// REQUEST URL
// ==========================================

function getRequestUrl(req) {
  if (req.url) {
    return req.url;
  }

  if (req.originalUrl) {
    return req.originalUrl;
  }

  if (req.rawUrl) {
    return req.rawUrl;
  }

  return "";
}

// ==========================================
// RAW QUERY STRING
// ==========================================

function getRawQueryString(req) {
  const requestUrl = getRequestUrl(req);

  if (!requestUrl) {
    return "";
  }

  const questionMarkIndex =
    requestUrl.indexOf("?");

  if (questionMarkIndex === -1) {
    return "";
  }

  return requestUrl.substring(
    questionMarkIndex + 1
  );
}

// ==========================================
// DECODE SIGNED QUERY
// ==========================================

function decodeSignedQuery(value) {
  if (!value) {
    return "";
  }

  try {
    return decodeURIComponent(value);
  } catch (error) {
    console.warn(
      "🐱⚠️ Failed to decode signed query. Using raw value."
    );

    return value;
  }
}

// ==========================================
// EXTRACT SIGNED CONTENT
// ==========================================

function extractSignedContent(rawQueryString) {
  if (!rawQueryString) {
    throw new Error(
      "Missing AdMob SSV query string."
    );
  }

  const signatureMarker =
    "&signature=";

  const signatureIndex =
    rawQueryString.indexOf(
      signatureMarker
    );

  if (signatureIndex === -1) {
    throw new Error(
      "Missing AdMob SSV signature."
    );
  }

  const signedContent =
    rawQueryString.substring(
      0,
      signatureIndex
    );

  return decodeSignedQuery(
    signedContent
  );
}

// ==========================================
// EXTRACT SIGNATURE + KEY ID
// ==========================================

function extractSignatureAndKeyId(
  rawQueryString
) {
  if (!rawQueryString) {
    throw new Error(
      "Missing AdMob SSV query string."
    );
  }

  const signatureMarker =
    "signature=";

  const keyIdMarker =
    "key_id=";

  const signatureIndex =
    rawQueryString.indexOf(
      `&${signatureMarker}`
    );

  const keyIdIndex =
    rawQueryString.indexOf(
      `&${keyIdMarker}`
    );

  if (
    signatureIndex === -1 ||
    keyIdIndex === -1
  ) {
    throw new Error(
      "Missing AdMob SSV signature or key_id."
    );
  }

  const signatureStart =
    signatureIndex +
    `&${signatureMarker}`.length;

  const signatureEnd =
    keyIdIndex;

  const encodedSignature =
    rawQueryString.substring(
      signatureStart,
      signatureEnd
    );

  const keyIdStart =
    keyIdIndex +
    `&${keyIdMarker}`.length;

  const encodedKeyId =
    rawQueryString.substring(
      keyIdStart
    );

  const signature =
    decodeSignedQuery(
      encodedSignature
    );

  const keyId =
    decodeSignedQuery(
      encodedKeyId
    );

  if (!signature) {
    throw new Error(
      "Empty AdMob SSV signature."
    );
  }

  if (!keyId) {
    throw new Error(
      "Empty AdMob SSV key_id."
    );
  }

  return {
    signature,
    keyId,
  };
}

// ==========================================
// VERIFY SIGNATURE
// ==========================================

function verifySignature(
  signedContent,
  signature,
  publicKey
) {
  try {
    const signatureBuffer =
      Buffer.from(
        signature,
        "base64"
      );

    const signedContentBuffer =
      Buffer.from(
        signedContent,
        "utf8"
      );

    console.log(
      "🐱🔐 Verifying AdMob SSV signature.",
      {
        signedBytes:
          signedContentBuffer.length,

        signatureBytes:
          signatureBuffer.length,
      }
    );

    const verifier =
      crypto.createVerify(
        "SHA256"
      );

    verifier.update(
      signedContentBuffer
    );

    verifier.end();

    const verified =
      verifier.verify(
        {
          key: publicKey,
          dsaEncoding: "der",
        },
        signatureBuffer
      );

    if (!verified) {
      console.error(
        "🐱❌ AdMob SSV signature INVALID."
      );

      return false;
    }

    console.log(
      "🐱✅ AdMob SSV signature VALID."
    );

    return true;
  } catch (error) {
    console.error(
      "🐱❌ AdMob signature verification error:",
      error
    );

    return false;
  }
}

// ==========================================
// PARSE VERIFIED PARAMETERS
// ==========================================

function parseVerifiedParameters(
  signedContent
) {
  if (!signedContent) {
    throw new Error(
      "Missing signed AdMob content."
    );
  }

  const params =
    new URLSearchParams(
      signedContent
    );

  const result = {};

  for (const [
    key,
    value,
  ] of params.entries()) {
    result[key] = value;
  }

  return result;
}

// ==========================================
// CUSTOM DATA
// ==========================================

function parseCustomData(
  customData
) {
  if (!customData) {
    return null;
  }

  let decoded =
    String(customData);

  try {
    decoded =
      decodeURIComponent(decoded);
  } catch (error) {
    // Already decoded or invalid encoding.
  }

  const separatorIndex =
    decoded.indexOf(":");

  if (separatorIndex === -1) {
    return {
      userId: decoded,
      purpose: "power_boost",
    };
  }

  const userId =
    decoded.substring(
      0,
      separatorIndex
    );

  const purpose =
    decoded.substring(
      separatorIndex + 1
    );

  return {
    userId,
    purpose,
  };
}

// ==========================================
// VALIDATE REWARD PARAMETERS
// ==========================================

function validateRewardParameters(
  parameters,
  customData
) {
  const adUnit =
    parameters.ad_unit;

  const rewardAmount =
    parameters.reward_amount;

  const rewardItem =
    parameters.reward_item;

  const transactionId =
    parameters.transaction_id;

  const timestamp =
    parameters.timestamp;

  const userId =
    parameters.user_id;

  // ----------------------------------------
  // PURPOSE
  // ----------------------------------------

  const purpose =
    customData?.purpose ||
    "power_boost";

  if (
    purpose !== "mining_start" &&
    purpose !== "power_boost"
  ) {
    return {
      valid: false,
      error:
        `Invalid AdMob reward purpose: ${purpose}`,
    };
  }

  // ----------------------------------------
  // AD UNIT
  // ----------------------------------------

  const expectedAdUnit =
    ADMOB_AD_UNITS[purpose];

  if (
    adUnit !== expectedAdUnit
  ) {
    return {
      valid: false,
      error:
        `Invalid AdMob ad unit for ${purpose}. Expected ${expectedAdUnit}, received ${adUnit}.`,
    };
  }

  // ----------------------------------------
  // REWARD DEFINITION
  // ----------------------------------------

  const rewardDefinition =
    REWARD_DEFINITIONS[purpose];

  if (!rewardDefinition) {
    return {
      valid: false,
      error:
        `Missing reward definition for ${purpose}.`,
    };
  }

  // ----------------------------------------
  // REWARD AMOUNT
  // ----------------------------------------

  if (
    Number(rewardAmount) !==
    rewardDefinition.rewardAmount
  ) {
    return {
      valid: false,
      error:
        `Invalid reward amount for ${purpose}. Expected ${rewardDefinition.rewardAmount}, received ${rewardAmount}.`,
    };
  }

  // ----------------------------------------
  // REWARD ITEM
  // ----------------------------------------

  if (
    rewardItem !==
    rewardDefinition.rewardItem
  ) {
    return {
      valid: false,
      error:
        `Invalid reward item for ${purpose}. Expected ${rewardDefinition.rewardItem}, received ${rewardItem}.`,
    };
  }

  // ----------------------------------------
  // TRANSACTION ID
  // ----------------------------------------

  if (
    !transactionId ||
    !/^[a-fA-F0-9]+$/.test(
      transactionId
    )
  ) {
    return {
      valid: false,
      error:
        "Invalid or missing AdMob transaction ID.",
    };
  }

  // ----------------------------------------
  // TIMESTAMP
  // ----------------------------------------

  if (!timestamp) {
    return {
      valid: false,
      error:
        "Missing AdMob timestamp.",
    };
  }

  const timestampNumber =
    Number(timestamp);

  if (
    !Number.isFinite(
      timestampNumber
    )
  ) {
    return {
      valid: false,
      error:
        "Invalid AdMob timestamp.",
    };
  }

  const now =
    Date.now();

  const timestampMs =
    timestampNumber;

  const maxAgeMs =
    24 * 60 * 60 * 1000;

  if (
    Math.abs(
      now - timestampMs
    ) > maxAgeMs
  ) {
    return {
      valid: false,
      error:
        "AdMob SSV timestamp is outside the allowed 24-hour window.",
    };
  }

  // ----------------------------------------
  // CUSTOM DATA USER ID
  // ----------------------------------------

  if (
    customData &&
    customData.userId &&
    userId &&
    customData.userId !== userId
  ) {
    return {
      valid: false,
      error:
        "AdMob user_id does not match custom_data user ID.",
    };
  }

  return {
    valid: true,
    purpose,
    transactionId,
  };
}

// ==========================================
// MAIN ADMOB SSV VERIFICATION
// ==========================================

async function verifyAdMobCallback(
  req
) {
  try {
    const rawQueryString =
      getRawQueryString(req);

    if (!rawQueryString) {
      return {
        verified: false,
        error:
          "Missing AdMob SSV query string.",
      };
    }

    // --------------------------------------
    // SIGNED CONTENT
    // --------------------------------------

    const signedContent =
      extractSignedContent(
        rawQueryString
      );

    // --------------------------------------
    // SIGNATURE + KEY ID
    // --------------------------------------

    const {
      signature,
      keyId,
    } =
      extractSignatureAndKeyId(
        rawQueryString
      );

    // --------------------------------------
    // PUBLIC KEYS
    // --------------------------------------

    const publicKeys =
      await getAdMobPublicKeys();

    const publicKey =
      publicKeys[String(keyId)];

    if (!publicKey) {
      return {
        verified: false,
        error:
          `Unknown AdMob public key ID: ${keyId}`,
      };
    }

    // --------------------------------------
    // CRYPTOGRAPHIC VERIFICATION
    // --------------------------------------

    const signatureValid =
      verifySignature(
        signedContent,
        signature,
        publicKey
      );

    if (!signatureValid) {
      return {
        verified: false,
        error:
          "AdMob SSV signature verification failed.",
      };
    }

    // --------------------------------------
    // PARSE VERIFIED PARAMETERS
    // --------------------------------------

    const parameters =
      parseVerifiedParameters(
        signedContent
      );

    // --------------------------------------
    // CUSTOM DATA
    // --------------------------------------

    const rawCustomData =
      parameters.custom_data ||
      parameters.customData ||
      "";

    const customData =
      parseCustomData(
        rawCustomData
      );

    // --------------------------------------
    // VALIDATE PARAMETERS
    // --------------------------------------

    const validation =
      validateRewardParameters(
        parameters,
        customData
      );

    if (!validation.valid) {
      console.error(
        "🐱❌ AdMob SSV verification failed:",
        validation.error
      );

      return {
        verified: false,
        error:
          validation.error,
      };
    }

    // --------------------------------------
    // SUCCESS
    // --------------------------------------

    console.log(
      "🐱✅ AdMob SSV callback VERIFIED.",
      {
        purpose:
          validation.purpose,

        transactionId:
          validation.transactionId,

        userId:
          customData?.userId || null,

        adUnit:
          parameters.ad_unit,

        rewardAmount:
          parameters.reward_amount,

        rewardItem:
          parameters.reward_item,

        keyId,
      }
    );

    return {
      verified: true,

      purpose:
        validation.purpose,

      transactionId:
        validation.transactionId,

      userId:
        customData?.userId || null,

      parameters,
    };
  } catch (error) {
    console.error(
      "🐱❌ AdMob SSV verification error:",
      error
    );

    return {
      verified: false,
      error:
        error?.message ||
        "Unknown AdMob SSV verification error.",
    };
  }
}

// ==========================================
// EXPORTS
// ==========================================

module.exports = {
  ADMOB_AD_UNITS,
  REWARD_DEFINITIONS,
  verifyAdMobCallback,
  getAdMobPublicKeys,
  parseCustomData,
  validateRewardParameters,
};