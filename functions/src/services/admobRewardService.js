"use strict";

// ============================================================
// 🐱 STELLURIINI - ADMOB REWARD SERVICE
// ============================================================
// Vastuu:
// - AdMob SSV:n jälkeen tallennetun rewardin validointi
// - UID:n validointi
// - transaction_id:n validointi
// - reward purpose -validointi
// - rewardin aikarajan tarkistus
// - claim/replay-suojauksen tarkistus
//
// Tämä service EI:
// - muuta STL-saldoa
// - käynnistä louhintaa
// - aktivoi Power Boostia
// - tee AdMob SSV:n allekirjoituksen varmennusta
//
// AdMob SSV:n varsinainen varmennus kuuluu:
// functions/src/services/admobService.js
//
// ============================================================

const { db } = require("../firebase/firebase");
const { getAdMobRewardRef } = require("../utils/userUtils");

// ============================================================
// CONFIG
// ============================================================

const REWARD_MAX_AGE_MS = 24 * 60 * 60 * 1000;
const REWARD_FUTURE_TOLERANCE_MS = 5 * 60 * 1000;

const VALID_REWARD_PURPOSES = new Set([
  "mining_start",
  "power_boost",
]);

// ============================================================
// HELPERS
// ============================================================

function normalizeString(value) {
  return typeof value === "string" ? value.trim() : "";
}

function number(value, fallback = 0) {
  const result = Number(value);
  return Number.isFinite(result) ? result : fallback;
}

function createError(code, message) {
  const error = new Error(message);
  error.code = code;
  return error;
}

// ============================================================
// UID
// ============================================================

function validateUid(value) {
  const uid = normalizeString(value);

  if (!uid || uid.length > 128) {
    return "";
  }

  return /^[A-Za-z0-9._-]+$/.test(uid) ? uid : "";
}

// ============================================================
// TRANSACTION ID
// ============================================================
// AdMob transaction_id on opaakki tunniste.
// Sitä ei pidä rajoittaa esimerkiksi vain heksamerkkeihin.
// ============================================================

function validateTransactionId(value) {
  const transactionId = normalizeString(value);

  if (!transactionId || transactionId.length > 256) {
    return "";
  }

  return transactionId;
}

// ============================================================
// REWARD PURPOSE
// ============================================================

function validateRewardPurpose(value) {
  const purpose = normalizeString(value);

  return VALID_REWARD_PURPOSES.has(purpose)
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

  if (typeof value.toMillis === "function") {
    try {
      const result = value.toMillis();

      if (Number.isFinite(result)) {
        return result;
      }
    } catch (_) {}
  }

  if (typeof value.toDate === "function") {
    try {
      const date = value.toDate();

      if (
        date instanceof Date &&
        Number.isFinite(date.getTime())
      ) {
        return date.getTime();
      }
    } catch (_) {}
  }

  if (value instanceof Date) {
    return Number.isFinite(value.getTime())
      ? value.getTime()
      : 0;
  }

  if (typeof value === "string") {
    const result = new Date(value).getTime();

    return Number.isFinite(result)
      ? result
      : 0;
  }

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

function getRewardCreatedAtMs(data) {
  const candidates = [
    data.verifiedAt,
    data.ssvVerifiedAt,
    data.createdAt,
    data.timestamp,
  ];

  for (const value of candidates) {
    const milliseconds = timestampMs(value);

    if (milliseconds > 0) {
      return milliseconds;
    }
  }

  return 0;
}

// ============================================================
// REWARD TIMING
// ============================================================

function validateRewardTiming(data, options = {}) {
  const referenceNowMs = number(
    options.referenceNowMs,
    Date.now(),
  );

  const rewardCreatedAtMs =
    getRewardCreatedAtMs(data);

  if (rewardCreatedAtMs <= 0) {
    throw createError(
      "ADMOB_REWARD_TIMESTAMP_MISSING",
      "AdMob reward timestamp is missing.",
    );
  }

  if (
    rewardCreatedAtMs >
    referenceNowMs + REWARD_FUTURE_TOLERANCE_MS
  ) {
    throw createError(
      "ADMOB_REWARD_TIMESTAMP_INVALID",
      "AdMob reward timestamp is in the future.",
    );
  }

  if (
    referenceNowMs - rewardCreatedAtMs >
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

function getDocumentTransactionId(data) {
  const candidates = [
    data.transactionId,
    data.adMobTransactionId,
    data.adRewardTransactionId,
    data.transaction_id,
  ];

  for (const value of candidates) {
    const transactionId =
      validateTransactionId(value);

    if (transactionId) {
      return transactionId;
    }
  }

  return "";
}

function getDocumentRewardPurpose(data) {
  const candidates = [
    data.rewardPurpose,
    data.reward_purpose,
  ];

  for (const value of candidates) {
    const purpose =
      validateRewardPurpose(value);

    if (purpose) {
      return purpose;
    }
  }

  return "";
}

function getDocumentUid(data) {
  const candidates = [
    data.uid,
    data.userId,
    data.user_id,
  ];

  for (const value of candidates) {
    const uid = validateUid(value);

    if (uid) {
      return uid;
    }
  }

  return "";
}

// ============================================================
// CLAIM FIELD
// ============================================================

function getClaimField(rewardPurpose) {
  if (rewardPurpose === "mining_start") {
    return "miningStartClaimed";
  }

  if (rewardPurpose === "power_boost") {
    return "powerBoostClaimed";
  }

  throw createError(
    "ADMOB_INVALID_REWARD_PURPOSE",
    "Unknown AdMob reward purpose.",
  );
}

function isRewardAlreadyClaimed(
  data,
  rewardPurpose,
) {
  const claimField =
    getClaimField(rewardPurpose);

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
    typeof rewardSnapshot.exists !== "boolean"
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

  const data = rewardSnapshot.data() || {};

  const validatedUid = validateUid(uid);

  if (!validatedUid) {
    throw createError(
      "ADMOB_INVALID_UID",
      "UID is invalid.",
    );
  }

  const purpose =
    validateRewardPurpose(expectedPurpose);

  if (!purpose) {
    throw createError(
      "ADMOB_INVALID_REWARD_PURPOSE",
      "Reward purpose is invalid.",
    );
  }

  const expectedClaimField =
    getClaimField(purpose);

  if (
    claimField &&
    claimField !== expectedClaimField
  ) {
    throw createError(
      "ADMOB_INVALID_CLAIM_FIELD",
      "Reward claim field does not match reward purpose.",
    );
  }

  // ----------------------------------------------------------
  // SSV VERIFIED
  // ----------------------------------------------------------

  if (data.verified !== true) {
    throw createError(
      "ADMOB_REWARD_NOT_VERIFIED",
      "AdMob reward has not been verified.",
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

  if (documentUid !== validatedUid) {
    throw createError(
      "ADMOB_REWARD_UID_MISMATCH",
      "Verified AdMob reward UID does not match the authenticated user.",
    );
  }

  // ----------------------------------------------------------
  // PURPOSE
  // ----------------------------------------------------------

  const documentPurpose =
    getDocumentRewardPurpose(data);

  if (!documentPurpose) {
    throw createError(
      "ADMOB_REWARD_PURPOSE_MISSING",
      "Verified AdMob reward does not contain a valid reward purpose.",
    );
  }

  if (documentPurpose !== purpose) {
    throw createError(
      "ADMOB_REWARD_PURPOSE_MISMATCH",
      "Verified AdMob reward purpose does not match the requested operation.",
    );
  }

  // ----------------------------------------------------------
  // TRANSACTION ID
  // ----------------------------------------------------------

  const documentTransactionId =
    getDocumentTransactionId(data);

  if (!documentTransactionId) {
    throw createError(
      "ADMOB_REWARD_TRANSACTION_ID_MISSING",
      "Verified AdMob reward does not contain a valid transaction_id.",
    );
  }

  // transaction_id on vapaaehtoinen client-pyynnössä.
  // Jos client antaa sen, sen on vastattava SSV-rewardia.
  const requestedTransactionId =
    validateTransactionId(
      options.transactionId,
    );

  if (
    requestedTransactionId &&
    documentTransactionId !== requestedTransactionId
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
  // REPLAY PROTECTION
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
  // AUTHORITATIVE RESULT
  // ----------------------------------------------------------

  return {
    verified: true,
    rewardRef: rewardSnapshot.ref,
    uid: validatedUid,
    rewardPurpose: purpose,
    transactionId: documentTransactionId,
    claimField: expectedClaimField,
    data,
  };
}

// ============================================================
// VERIFIED REWARD LOOKUP
// ============================================================
//
// Flutterin RewardedAd callback ei tarjoa AdMob SSV:n
// transaction_id:tä. Siksi transaction_id voi puuttua
// clientin claimMining-kutsusta.
//
// Tällöin haetaan käyttäjän viimeisin:
// - verified === true
// - oikea rewardPurpose
// - käyttämätön reward
//
// ============================================================

async function getVerifiedReward(
  uid,
  options = {},
) {
  const validatedUid = validateUid(uid);

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

  // ----------------------------------------------------------
  // SUORA TRANSACTION ID -HAKU
  // ----------------------------------------------------------

  if (transactionId) {
    const rewardRef =
      getAdMobRewardRef(transactionId);

    return {
      rewardRef,
      rewardSnapshot:
        await rewardRef.get(),
      transactionId,
    };
  }

  // ----------------------------------------------------------
  // TRANSACTION ID PUUTTUU
  // ----------------------------------------------------------

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

  const snapshot = await db
    .collection("admobRewards")
    .where("uid", "==", validatedUid)
    .get();

  const candidates = snapshot.docs
    .filter((doc) => {
      const data = doc.data() || {};

      return (
        data.verified === true &&
        getDocumentRewardPurpose(data) === purpose &&
        !isRewardAlreadyClaimed(
          data,
          purpose,
        )
      );
    })
    .sort((a, b) => {
      const aTime =
        getRewardCreatedAtMs(
          a.data() || {},
        );

      const bTime =
        getRewardCreatedAtMs(
          b.data() || {},
        );

      return bTime - aTime;
    });

  if (candidates.length === 0) {
    throw createError(
      "ADMOB_REWARD_NOT_FOUND",
      "No verified unconsumed AdMob reward is available yet.",
    );
  }

  const rewardSnapshot =
    candidates[0];

  const selectedTransactionId =
    getDocumentTransactionId(
      rewardSnapshot.data() || {},
    );

  if (!selectedTransactionId) {
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
// MINING START REWARD
// ============================================================

async function getVerifiedMiningStartReward(
  uid,
  options = {},
) {
  const result =
    await getVerifiedReward(
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
    await getVerifiedReward(
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
  getVerifiedMiningStartReward,
  getVerifiedPowerBoostReward,
  validateVerifiedRewardDocument,
  validateUid,
  validateTransactionId,
  validateRewardPurpose,
};