"use strict";

// ============================================================
// 🐱 STELLURIINI - ADMOB REWARD SERVICE
// ============================================================
//
// Vastuu:
//
// 🔐 AdMob SSV:n jälkeen tallennetun reward-dokumentin
//    turvallinen validointi
//
// 🆔 UID:n validointi
// 🆔 transaction_id:n validointi
// 🎯 reward purpose -validointi
// 🔒 Rewardin idempotenssin ja claim-tilan tarkistus
// ⏱️ Rewardin aikarajojen tarkistus
//
// EI:
//
// ❌ AdMob SSV:n kryptografista varmennusta
// ❌ Public key -hakua
// ❌ Firestore-kirjoitusten tekemistä
// ❌ STL-saldon muuttamista
// ❌ Mining-tilan muuttamista
// ❌ Power Boostin aktivointia
//
// Varsinainen AdMob SSV:n allekirjoituksen varmennus kuuluu:
//
// functions/src/services/admobService.js
//
// Tämä service käsittelee sen jälkeen Firestoreen
// tallennetun varmennetun rewardin.
//
// ============================================================

const {
  getAdMobRewardRef,
} = require("../utils/userUtils");

// ============================================================
// CONFIG
// ============================================================

// Kuinka kauan ennen requestia luotu reward voidaan
// käyttää.
//
// AdMob SSV voi tulla ennen kuin client ehtii kutsua
// Cloud Functionia.
//
// Rewardin oma timestamp ratkaisee rewardin iän.
//
// ============================================================

const REWARD_MAX_AGE_MS =
  24 * 60 * 60 * 1000;

// Kuinka paljon rewardin timestamp voi olla
// tulevaisuudessa.
//
// Firestore-palvelimen timestampia käytettäessä tämä on
// lähinnä suoja virheellisiä dokumentteja vastaan.
//
// ============================================================

const REWARD_FUTURE_TOLERANCE_MS =
  5 * 60 * 1000;

// ============================================================
// REWARD PURPOSES
// ============================================================

const VALID_REWARD_PURPOSES =
  new Set([
    "mining_start",
    "power_boost",
  ]);

// ============================================================
// HELPERS
// ============================================================

function normalizeString(value) {
  return typeof value === "string"
    ? value.trim()
    : "";
}

function number(
  value,
  fallback = 0,
) {
  const result =
    Number(value);

  return Number.isFinite(result)
    ? result
    : fallback;
}

function timestampMs(value) {
  if (!value) {
    return 0;
  }

  // Firestore Timestamp
  if (
    typeof value.toDate ===
    "function"
  ) {
    try {
      const date =
        value.toDate();

      return date instanceof Date &&
        Number.isFinite(
          date.getTime(),
        )
        ? date.getTime()
        : 0;
    } catch (_) {
      return 0;
    }
  }

  // Firestore-like Timestamp
  if (
    typeof value.toMillis ===
    "function"
  ) {
    try {
      const milliseconds =
        value.toMillis();

      return Number.isFinite(
        milliseconds,
      )
        ? milliseconds
        : 0;
    } catch (_) {
      return 0;
    }
  }

  // JavaScript Date
  if (value instanceof Date) {
    return Number.isFinite(
      value.getTime(),
    )
      ? value.getTime()
      : 0;
  }

  // ISO date string
  if (
    typeof value === "string"
  ) {
    const date =
      new Date(value);

    return Number.isFinite(
      date.getTime(),
    )
      ? date.getTime()
      : 0;
  }

  // Numeric timestamp
  if (
    typeof value === "number" &&
    Number.isFinite(value)
  ) {
    return value;
  }

  return 0;
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

function validateUid(value) {
  const uid =
    normalizeString(value);

  if (
    !uid ||
    uid.length > 128
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
// AdMob transaction_id on oltava sama kuin SSV:n
// varmennetussa reward-dokumentissa.
//
// ============================================================

function validateTransactionId(
  value,
) {
  const transactionId =
    normalizeString(value);

  if (
    !transactionId ||
    transactionId.length > 256
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
// REWARD CREATED TIME
// ============================================================

function getRewardCreatedAtMs(
  data,
) {
  const candidates = [
    data.verifiedAt,
    data.ssvVerifiedAt,
    data.createdAt,
    data.timestamp,
  ];

  for (
    const value of candidates
  ) {
    const milliseconds =
      timestampMs(value);

    if (milliseconds > 0) {
      return milliseconds;
    }
  }

  return 0;
}

// ============================================================
// REWARD TIMING VALIDATION
// ============================================================
//
// Tärkeää:
//
// Emme vertaa rewardin timestampia Cloud Function
// requestin aloitusaikaan.
//
// AdMob SSV voi viivästyä, joten requestin ja rewardin
// välinen 5 minuutin rajoitus voisi hylätä täysin aidon
// rewardin.
//
// Tarkistamme ainoastaan:
//
// 1. timestamp löytyy
// 2. timestamp ei ole kohtuuttomasti tulevaisuudessa
// 3. reward ei ole yli 24 tuntia vanha
//
// ============================================================

function validateRewardTiming(
  data,
  options,
) {
  const referenceNowMs =
    number(
      options?.referenceNowMs,
      Date.now(),
    );

  const rewardCreatedAtMs =
    getRewardCreatedAtMs(
      data,
    );

  if (
    rewardCreatedAtMs <= 0
  ) {
    throw createError(
      "ADMOB_REWARD_TIMESTAMP_MISSING",
      "AdMob reward timestamp is missing.",
    );
  }

  if (
    rewardCreatedAtMs >
    referenceNowMs +
      REWARD_FUTURE_TOLERANCE_MS
  ) {
    throw createError(
      "ADMOB_REWARD_TIMESTAMP_INVALID",
      "AdMob reward timestamp is in the future.",
    );
  }

  const age =
    referenceNowMs -
    rewardCreatedAtMs;

  if (
    age >
    REWARD_MAX_AGE_MS
  ) {
    throw createError(
      "ADMOB_REWARD_EXPIRED",
      "AdMob reward has expired.",
    );
  }
}

// ============================================================
// TRANSACTION ID EXTRACTION
// ============================================================

function getDocumentTransactionId(
  data,
) {
  const candidates = [
    data.transactionId,
    data.adMobTransactionId,
    data.adRewardTransactionId,
    data.transaction_id,
  ];

  for (
    const value of candidates
  ) {
    const transactionId =
      validateTransactionId(
        value,
      );

    if (transactionId) {
      return transactionId;
    }
  }

  return "";
}

// ============================================================
// PURPOSE EXTRACTION
// ============================================================

function getDocumentRewardPurpose(
  data,
) {
  const candidates = [
    data.rewardPurpose,
    data.reward_purpose,
  ];

  for (
    const value of candidates
  ) {
    const purpose =
      validateRewardPurpose(
        value,
      );

    if (purpose) {
      return purpose;
    }
  }

  return "";
}

// ============================================================
// UID EXTRACTION
// ============================================================

function getDocumentUid(
  data,
) {
  const candidates = [
    data.uid,
    data.userId,
    data.user_id,
  ];

  for (
    const value of candidates
  ) {
    const uid =
      validateUid(value);

    if (uid) {
      return uid;
    }
  }

  return "";
}

// ============================================================
// CLAIM FIELD
// ============================================================

function getClaimField(
  rewardPurpose,
) {
  if (
    rewardPurpose ===
    "mining_start"
  ) {
    return "miningStartClaimed";
  }

  if (
    rewardPurpose ===
    "power_boost"
  ) {
    return "powerBoostClaimed";
  }

  throw createError(
    "ADMOB_INVALID_REWARD_PURPOSE",
    "Unknown AdMob reward purpose.",
  );
}

// ============================================================
// CLAIMED FIELD
// ============================================================

function isRewardAlreadyClaimed(
  data,
  rewardPurpose,
) {
  const claimField =
    getClaimField(
      rewardPurpose,
    );

  return (
    data[claimField] === true ||
    data.rewardConsumed === true
  );
}

// ============================================================
// REWARD DOCUMENT VALIDATION
// ============================================================

function validateVerifiedRewardDocument(
  rewardSnapshot,
  uid,
  expectedPurpose,
  claimField,
  options = {},
) {
  if (
    !rewardSnapshot ||
    typeof rewardSnapshot.exists !==
      "boolean"
  ) {
    throw createError(
      "ADMOB_REWARD_DOCUMENT_MISSING",
      "AdMob reward document is missing.",
    );
  }

  if (!rewardSnapshot.exists) {
    throw createError(
      "ADMOB_REWARD_NOT_FOUND",
      "Verified AdMob reward was not found.",
    );
  }

  const data =
    rewardSnapshot.data() || {};

  const validatedUid =
    validateUid(uid);

  if (!validatedUid) {
    throw createError(
      "ADMOB_INVALID_UID",
      "UID is invalid.",
    );
  }

  const purpose =
    validateRewardPurpose(
      expectedPurpose,
    );

  if (!purpose) {
    throw createError(
      "ADMOB_INVALID_REWARD_PURPOSE",
      "Reward purpose is invalid.",
    );
  }

  const expectedClaimField =
    getClaimField(
      purpose,
    );

  if (
    claimField &&
    claimField !==
      expectedClaimField
  ) {
    throw createError(
      "ADMOB_INVALID_CLAIM_FIELD",
      "Reward claim field does not match reward purpose.",
    );
  }

  // ----------------------------------------------------------
  // VERIFIED FLAG
  // ----------------------------------------------------------

  if (
    data.verified !== true
  ) {
    throw createError(
      "ADMOB_REWARD_NOT_VERIFIED",
      "AdMob reward has not been cryptographically verified.",
    );
  }

  // ----------------------------------------------------------
  // UID
  // ----------------------------------------------------------

  const documentUid =
    getDocumentUid(data);

  if (!documentUid) {
    throw createError(
      "ADMOB_REWARD_UID_MISSING",
      "Verified AdMob reward does not contain a valid UID.",
    );
  }

  if (
    documentUid !==
    validatedUid
  ) {
    throw createError(
      "ADMOB_REWARD_UID_MISMATCH",
      "Verified AdMob reward UID does not match the authenticated user.",
    );
  }

  // ----------------------------------------------------------
  // PURPOSE
  // ----------------------------------------------------------

  const documentPurpose =
    getDocumentRewardPurpose(
      data,
    );

  if (!documentPurpose) {
    throw createError(
      "ADMOB_REWARD_PURPOSE_MISSING",
      "Verified AdMob reward does not contain a valid reward purpose.",
    );
  }

  if (
    documentPurpose !==
    purpose
  ) {
    throw createError(
      "ADMOB_REWARD_PURPOSE_MISMATCH",
      "Verified AdMob reward purpose does not match the requested operation.",
    );
  }

  // ----------------------------------------------------------
  // TRANSACTION ID
  // ----------------------------------------------------------

  const requestedTransactionId =
    validateTransactionId(
      options?.transactionId,
    );

  if (
    !requestedTransactionId
  ) {
    throw createError(
      "ADMOB_TRANSACTION_ID_MISSING",
      "AdMob transaction_id is missing.",
    );
  }

  const documentTransactionId =
    getDocumentTransactionId(
      data,
    );

  if (
    !documentTransactionId
  ) {
    throw createError(
      "ADMOB_REWARD_TRANSACTION_ID_MISSING",
      "Verified AdMob reward does not contain a valid transaction_id.",
    );
  }

  if (
    documentTransactionId !==
    requestedTransactionId
  ) {
    throw createError(
      "ADMOB_TRANSACTION_ID_MISMATCH",
      "AdMob transaction_id does not match the verified reward.",
    );
  }

  // ----------------------------------------------------------
  // TIMING
  // ----------------------------------------------------------

  validateRewardTiming(
    data,
    options,
  );

  // ----------------------------------------------------------
  // CLAIM / REPLAY PROTECTION
  // ----------------------------------------------------------

  if (
    isRewardAlreadyClaimed(
      data,
      purpose,
    )
  ) {
    throw createError(
      "ADMOB_REWARD_ALREADY_CLAIMED",
      "This AdMob reward has already been consumed.",
    );
  }

  // ----------------------------------------------------------
  // RETURN AUTHORITATIVE DATA
  // ----------------------------------------------------------

  return {
    verified: true,

    rewardRef:
      rewardSnapshot.ref,

    uid:
      validatedUid,

    rewardPurpose:
      purpose,

    transactionId:
      documentTransactionId,

    claimField:
      expectedClaimField,

    data,
  };
}

// ============================================================
// INTERNAL REWARD LOOKUP
// ============================================================

async function getVerifiedReward(
  uid,
  options,
) {
  const validatedUid =
    validateUid(uid);

  if (!validatedUid) {
    throw createError(
      "ADMOB_INVALID_UID",
      "Authenticated UID is invalid.",
    );
  }

  const transactionId =
    validateTransactionId(
      options?.transactionId,
    );

  if (!transactionId) {
    throw createError(
      "ADMOB_TRANSACTION_ID_MISSING",
      "AdMob transaction_id is required.",
    );
  }

  const rewardRef =
    getAdMobRewardRef(
      transactionId,
    );

  if (!rewardRef) {
    throw createError(
      "ADMOB_REWARD_REFERENCE_INVALID",
      "Unable to create AdMob reward reference.",
    );
  }

  // get() ei muuta mitään Firestoressa.
  //
  // Varsinainen claim tapahtuu miningFunctions.js:n
  // Firestore transactionissa.
  const rewardSnapshot =
    await rewardRef.get();

  return {
    rewardRef,
    rewardSnapshot,
    transactionId,
  };
}

// ============================================================
// VERIFIED MINING START REWARD
// ============================================================

async function getVerifiedMiningStartReward(
  uid,
  options = {},
) {
  const result =
    await getVerifiedReward(
      uid,
      options,
    );

  const validated =
    validateVerifiedRewardDocument(
      result.rewardSnapshot,
      uid,
      "mining_start",
      "miningStartClaimed",
      {
        referenceNowMs:
          number(
            options.referenceNowMs,
            Date.now(),
          ),

        transactionId:
          result.transactionId,
      },
    );

  return {
    ...validated,

    rewardRef:
      result.rewardRef,

    rewardSnapshot:
      result.rewardSnapshot,
  };
}

// ============================================================
// VERIFIED POWER BOOST REWARD
// ============================================================

async function getVerifiedPowerBoostReward(
  uid,
  options = {},
) {
  const result =
    await getVerifiedReward(
      uid,
      options,
    );

  const validated =
    validateVerifiedRewardDocument(
      result.rewardSnapshot,
      uid,
      "power_boost",
      "powerBoostClaimed",
      {
        referenceNowMs:
          number(
            options.referenceNowMs,
            Date.now(),
          ),

        transactionId:
          result.transactionId,
      },
    );

  return {
    ...validated,

    rewardRef:
      result.rewardRef,

    rewardSnapshot:
      result.rewardSnapshot,
  };
}

// ============================================================
// EXPORTS
// ============================================================

module.exports = {
  getVerifiedMiningStartReward,

  getVerifiedPowerBoostReward,

  validateVerifiedRewardDocument,

  validateUid,

  validateTransactionId,

  validateRewardPurpose,
};