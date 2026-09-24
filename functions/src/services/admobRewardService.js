"use strict";

// ============================================================
// 🐱 STELLURIINI - ADMOB REWARD SERVICE
// ============================================================
//
// Vastuu:
//
// - AdMob SSV:n jälkeen tallennetun rewardin validointi
// - UID:n validointi
// - transaction_id:n validointi
// - reward purpose -validointi
// - rewardin aikarajan tarkistus
// - claim/replay-suojauksen tarkistus
// - SSV:n ja clientin claim-pyynnön ajoituseron käsittely
//
// Tämä service EI:
//
// - muuta STL-saldoa
// - käynnistä louhintaa
// - aktivoi Power Boostia
// - varmista AdMob SSV:n allekirjoitusta
//
// AdMob SSV:n kryptografinen varmennus kuuluu:
//
// functions/src/services/admobService.js
//
// ============================================================

const { db } = require("../firebase/firebase");
const {
  getAdMobRewardRef,
} = require("../utils/userUtils");

// ============================================================
// CONFIG
// ============================================================

const REWARD_MAX_AGE_MS =
  24 * 60 * 60 * 1000;

const REWARD_FUTURE_TOLERANCE_MS =
  5 * 60 * 1000;

// AdMob SSV voi saapua hieman Flutterin
// RewardedAd-callbackin jälkeen.
//
// claimMining saa tämän vuoksi lyhyen
// server-side odotusajan.
//
// Tärkeää:
// reward hyväksytään vain jos SSV on jo
// kryptografisesti varmennettu ja tallennettu.
const SSV_WAIT_TIMEOUT_MS =
  5000;

const SSV_RETRY_DELAY_MS =
  250;

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

function createError(
  code,
  message,
) {
  const error =
    new Error(message);

  error.code = code;

  return error;
}

function sleep(
  milliseconds,
) {
  return new Promise(
    (resolve) => {
      setTimeout(
        resolve,
        milliseconds,
      );
    },
  );
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

  // Estä kontrollimerkit.
  if (
    /[\x00-\x1F\x7F]/.test(
      transactionId,
    )
  ) {
    return "";
  }

  return transactionId;
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
// TIMESTAMP
// ============================================================

function timestampMs(value) {
  if (!value) {
    return 0;
  }

  // Firestore Timestamp
  if (
    typeof value.toMillis ===
    "function"
  ) {
    try {
      const result =
        value.toMillis();

      if (
        Number.isFinite(result)
      ) {
        return result;
      }
    } catch (_) {}
  }

  // Date-like Firestore object
  if (
    typeof value.toDate ===
    "function"
  ) {
    try {
      const date =
        value.toDate();

      if (
        date instanceof Date &&
        Number.isFinite(
          date.getTime(),
        )
      ) {
        return date.getTime();
      }
    } catch (_) {}
  }

  // JavaScript Date
  if (
    value instanceof Date
  ) {
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
    const result =
      new Date(value).getTime();

    return Number.isFinite(result)
      ? result
      : 0;
  }

  // Milliseconds
  if (
    typeof value === "number" &&
    Number.isFinite(value)
  ) {
    return value;
  }

  return 0;
}

// ============================================================
// REWARD CREATED TIME
// ============================================================
//
// Käytetään ensisijaisesti SSV:n server-verified aikaa.
//
// Jos sitä ei ole saatavilla, käytetään:
// - ssvVerifiedAt
// - createdAt
// - AdMob timestampia
//
// ============================================================

function getRewardCreatedAtMs(
  data,
) {
  if (
    !data ||
    typeof data !== "object"
  ) {
    return 0;
  }

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

    if (
      milliseconds > 0
    ) {
      return milliseconds;
    }
  }

  return 0;
}

// ============================================================
// REWARD TIMING
// ============================================================

function validateRewardTiming(
  data,
  options = {},
) {
  const referenceNowMs =
    number(
      options.referenceNowMs,
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

  if (
    referenceNowMs -
      rewardCreatedAtMs >
    REWARD_MAX_AGE_MS
  ) {
    throw createError(
      "ADMOB_REWARD_EXPIRED",
      "AdMob reward has expired.",
    );
  }
}

// ============================================================
// DOCUMENT VALUES
// ============================================================

function getDocumentTransactionId(
  data,
) {
  if (
    !data ||
    typeof data !== "object"
  ) {
    return "";
  }

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

function getDocumentRewardPurpose(
  data,
) {
  if (
    !data ||
    typeof data !== "object"
  ) {
    return "";
  }

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

function getDocumentUid(
  data,
) {
  if (
    !data ||
    typeof data !== "object"
  ) {
    return "";
  }

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
// CLAIM STATE
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
// VERIFIED REWARD VALIDATION
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

  if (
    !rewardSnapshot.exists
  ) {
    throw createError(
      "ADMOB_REWARD_NOT_FOUND",
      "Verified AdMob reward was not found.",
    );
  }

  const data =
    rewardSnapshot.data() ||
    {};

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

  // ==========================================================
  // CRYPTOGRAPHIC VERIFICATION STATE
  // ==========================================================
  //
  // Tätä tarkistusta ei saa ohittaa.
  //
  // reward-dokumentti hyväksytään vain jos
  // admobService.js on ensin varmistanut
  // AdMob SSV:n allekirjoituksen.
  //
  // ==========================================================

  if (
    data.verified !== true
  ) {
    throw createError(
      "ADMOB_REWARD_NOT_VERIFIED",
      "AdMob reward has not been verified.",
    );
  }

  // ==========================================================
  // UID
  // ==========================================================

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

  // ==========================================================
  // REWARD PURPOSE
  // ==========================================================

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

  // ==========================================================
  // TRANSACTION ID
  // ==========================================================

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

  const requestedTransactionId =
    validateTransactionId(
      options.transactionId,
    );

  if (
    requestedTransactionId &&
    documentTransactionId !==
      requestedTransactionId
  ) {
    throw createError(
      "ADMOB_TRANSACTION_ID_MISMATCH",
      "AdMob transaction_id does not match the verified reward.",
    );
  }

  // ==========================================================
  // TIMING
  // ==========================================================

  validateRewardTiming(
    data,
    options,
  );

  // ==========================================================
  // CLAIM / REPLAY PROTECTION
  // ==========================================================

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

  // ==========================================================
  // VALIDATED RESULT
  // ==========================================================

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
// VERIFIED REWARD LOOKUP
// ============================================================

async function getVerifiedReward(
  uid,
  options = {},
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
      options.transactionId,
    );

  // ==========================================================
  // DIRECT TRANSACTION LOOKUP
  // ==========================================================

  if (transactionId) {
    let rewardRef;

    try {
      rewardRef =
        getAdMobRewardRef(
          transactionId,
        );
    } catch (_) {
      throw createError(
        "ADMOB_REWARD_REFERENCE_ERROR",
        "Unable to create AdMob reward reference.",
      );
    }

    if (
      !rewardRef ||
      typeof rewardRef.get !==
        "function"
    ) {
      throw createError(
        "ADMOB_REWARD_REFERENCE_ERROR",
        "Unable to create AdMob reward reference.",
      );
    }

    return {
      rewardRef,

      rewardSnapshot:
        await rewardRef.get(),

      transactionId,
    };
  }

  // ==========================================================
  // LATEST VERIFIED REWARD LOOKUP
  // ==========================================================

  const purpose =
    validateRewardPurpose(
      options.rewardPurpose,
    );

  if (!purpose) {
    throw createError(
      "ADMOB_INVALID_REWARD_PURPOSE",
      "Reward purpose is required.",
    );
  }

  const snapshot =
    await db
      .collection(
        "admobRewards",
      )
      .where(
        "uid",
        "==",
        validatedUid,
      )
      .get();

  const candidates =
    snapshot.docs
      .filter(
        (doc) => {
          const data =
            doc.data() || {};

          return (
            data.verified === true &&
            getDocumentUid(
              data,
            ) ===
              validatedUid &&
            getDocumentRewardPurpose(
              data,
            ) ===
              purpose &&
            !isRewardAlreadyClaimed(
              data,
              purpose,
            )
          );
        },
      )
      .sort(
        (a, b) => {
          const aTime =
            getRewardCreatedAtMs(
              a.data() || {},
            );

          const bTime =
            getRewardCreatedAtMs(
              b.data() || {},
            );

          return bTime - aTime;
        },
      );

  if (
    candidates.length === 0
  ) {
    throw createError(
      "ADMOB_REWARD_NOT_FOUND",
      "No verified unconsumed AdMob reward is available yet.",
    );
  }

  const rewardSnapshot =
    candidates[0];

  const selectedTransactionId =
    getDocumentTransactionId(
      rewardSnapshot.data() ||
        {},
    );

  if (
    !selectedTransactionId
  ) {
    throw createError(
      "ADMOB_REWARD_TRANSACTION_ID_MISSING",
      "Verified AdMob reward does not contain a valid transaction_id.",
    );
  }

  return {
    rewardRef:
      rewardSnapshot.ref,

    rewardSnapshot,

    transactionId:
      selectedTransactionId,
  };
}

// ============================================================
// WAIT FOR SSV
// ============================================================
//
// AdMob SSV ja Flutter RewardedAd callback ovat
// toisistaan riippumattomia tapahtumia.
//
// Flutter voi kutsua claimMining-funktiota ennen kuin
// AdMob SSV on ehtinyt tallentaa:
// admobRewards/{transactionId}
//
// Odotamme vain lyhyen ja rajatun ajan.
//
// TÄRKEÄ:
//
// Emme koskaan hyväksy:
// - unverifioitua rewardia
// - puuttuvaa rewardia
// - väärää UID:tä
// - väärää purposea
// - vanhaa rewardia
// - jo käytettyä rewardia
//
// Retry koskee VAIN tilannetta:
// ADMOB_REWARD_NOT_FOUND
//
// ============================================================

async function getVerifiedRewardWithRetry(
  uid,
  options = {},
) {
  const startedAt =
    Date.now();

  let lastError = null;

  while (
    Date.now() -
      startedAt <=
    SSV_WAIT_TIMEOUT_MS
  ) {
    try {
      return await getVerifiedReward(
        uid,
        options,
      );
    } catch (error) {
      lastError = error;

      // ======================================================
      // ONLY RETRY SSV PROPAGATION DELAY
      // ======================================================

      if (
        !error ||
        error.code !==
          "ADMOB_REWARD_NOT_FOUND"
      ) {
        throw error;
      }
    }

    await sleep(
      SSV_RETRY_DELAY_MS,
    );
  }

  throw (
    lastError ||
    createError(
      "ADMOB_REWARD_NOT_FOUND",
      "No verified unconsumed AdMob reward is available yet.",
    )
  );
}

// ============================================================
// MINING START REWARD
// ============================================================

async function getVerifiedMiningStartReward(
  uid,
  options = {},
) {
  const result =
    await getVerifiedRewardWithRetry(
      uid,
      {
        ...options,

        rewardPurpose:
          "mining_start",
      },
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
// POWER BOOST REWARD
// ============================================================

async function getVerifiedPowerBoostReward(
  uid,
  options = {},
) {
  const result =
    await getVerifiedRewardWithRetry(
      uid,
      {
        ...options,

        rewardPurpose:
          "power_boost",
      },
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
  REWARD_MAX_AGE_MS,

  REWARD_FUTURE_TOLERANCE_MS,

  SSV_WAIT_TIMEOUT_MS,

  SSV_RETRY_DELAY_MS,

  validateUid,

  validateTransactionId,

  validateRewardPurpose,

  timestampMs,

  getRewardCreatedAtMs,

  validateRewardTiming,

  getDocumentTransactionId,

  getDocumentRewardPurpose,

  getDocumentUid,

  getClaimField,

  isRewardAlreadyClaimed,

  validateVerifiedRewardDocument,

  getVerifiedReward,

  getVerifiedRewardWithRetry,

  getVerifiedMiningStartReward,

  getVerifiedPowerBoostReward,
};