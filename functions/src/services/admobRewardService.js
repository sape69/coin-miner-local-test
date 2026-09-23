"use strict";

// ============================================================
// 🐱 STELLURIINI - ADMOB REWARD SERVICE
// ============================================================
//
// AdMob SSV reward -validointi.
//
// AdMob reward ei ole STL-token reward.
// Se ainoastaan valtuuttaa:
// - Mining Start
// - Power Boost
//
// Tämä tiedosto:
// - validoi AdMob rewardin
// - validoi transaction ID:n
// - validoi timestampin
// - odottaa verifioitua SSV rewardia
//
// Tämä tiedosto EI muuta mining-balancea.
// Tämä tiedosto EI muuta mining-tilaa.
// ============================================================

const {
  db,
} = require("../firebase/firebase");

const {
  ADMOB_MINING_AD_UNIT_ID,
  ADMOB_POWER_BOOST_AD_UNIT_ID,
  ADMOB_MINING_SSV_AD_UNIT_ID,
  ADMOB_POWER_BOOST_SSV_AD_UNIT_ID,
  ADMOB_MINING_SSV_REWARD_AMOUNT,
  ADMOB_MINING_SSV_REWARD_ITEM,
  ADMOB_POWER_BOOST_SSV_REWARD_AMOUNT,
  ADMOB_POWER_BOOST_SSV_REWARD_ITEM,
} = require("../config/miningConfig");

// ============================================================
// 🔐 TIMING
// ============================================================

const REQUEST_GRACE_MS =
  5 * 60 * 1000;

const MAX_REWARD_AGE_MS =
  15 * 60 * 1000;

const FUTURE_TOLERANCE_MS =
  2 * 60 * 1000;

const REWARD_QUERY_LIMIT = 100;

const SSV_WAIT_TIMEOUT_MS =
  90 * 1000;

const SSV_POLL_INTERVAL_MS =
  2 * 1000;

// ============================================================
// 🔢 SAFE NUMBERS
// ============================================================

function safeNumber(value, fallback = 0) {
  const result = Number(value);

  return Number.isFinite(result)
    ? result
    : fallback;
}

function safeNonNegative(
  value,
  fallback = 0
) {
  const result = Number(value);

  return Number.isFinite(result) &&
    result >= 0
    ? result
    : fallback;
}

function safePositive(
  value,
  fallback = 0
) {
  const result = Number(value);

  return Number.isFinite(result) &&
    result > 0
    ? result
    : fallback;
}

// ============================================================
// 🕒 TIMESTAMP
// ============================================================

function timestampMs(value) {
  if (!value) {
    return 0;
  }

  if (
    typeof value.toDate === "function"
  ) {
    try {
      const date = value.toDate();

      return date instanceof Date &&
        Number.isFinite(
          date.getTime()
        )
        ? date.getTime()
        : 0;
    } catch (_) {
      return 0;
    }
  }

  if (value instanceof Date) {
    return Number.isFinite(
      value.getTime()
    )
      ? value.getTime()
      : 0;
  }

  if (typeof value === "string") {
    const date = new Date(value);

    return Number.isFinite(
      date.getTime()
    )
      ? date.getTime()
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
// 🔑 TRANSACTION ID
// ============================================================

function validateAdMobTransactionId(value) {
  if (typeof value !== "string") {
    return "";
  }

  const transactionId = value.trim();

  if (
    !transactionId ||
    transactionId.length > 256
  ) {
    return "";
  }

  if (
    !/^[a-fA-F0-9]+$/.test(
      transactionId
    )
  ) {
    return "";
  }

  return transactionId;
}

// ============================================================
// 🕒 REWARD TIMESTAMPS
// ============================================================

function getRewardTimestampMs(data) {
  if (!data) {
    return 0;
  }

  const values = [
    data.timestamp,
    data.rewardedAt,
    data.receivedAt,
    data.createdAt,
  ];

  for (const value of values) {
    const result =
      timestampMs(value);

    if (result > 0) {
      return result;
    }
  }

  return 0;
}

function getRewardCreatedAtMs(data) {
  if (!data) {
    return 0;
  }

  const values = [
    data.createdAt,
    data.receivedAt,
    data.timestamp,
    data.rewardedAt,
  ];

  for (const value of values) {
    const result =
      timestampMs(value);

    if (result > 0) {
      return result;
    }
  }

  return 0;
}

// ============================================================
// 🎁 REWARD CONFIGURATION
// ============================================================

function getRewardConfiguration(
  rewardPurpose
) {
  if (rewardPurpose === "mining_start") {
    return {
      rewardedAdUnitId:
        ADMOB_MINING_AD_UNIT_ID,

      ssvAdUnitId:
        ADMOB_MINING_SSV_AD_UNIT_ID,

      rewardAmount:
        ADMOB_MINING_SSV_REWARD_AMOUNT,

      rewardItem:
        ADMOB_MINING_SSV_REWARD_ITEM,
    };
  }

  if (rewardPurpose === "power_boost") {
    return {
      rewardedAdUnitId:
        ADMOB_POWER_BOOST_AD_UNIT_ID,

      ssvAdUnitId:
        ADMOB_POWER_BOOST_SSV_AD_UNIT_ID,

      rewardAmount:
        ADMOB_POWER_BOOST_SSV_REWARD_AMOUNT,

      rewardItem:
        ADMOB_POWER_BOOST_SSV_REWARD_ITEM,
    };
  }

  return null;
}

// ============================================================
// 🔑 TRANSACTION VALIDATION
// ============================================================

function validateRewardTransactionId(
  snapshot
) {
  if (
    !snapshot ||
    !snapshot.exists
  ) {
    return "";
  }

  const transactionId =
    validateAdMobTransactionId(
      snapshot.id
    );

  if (!transactionId) {
    return "";
  }

  const data =
    snapshot.data() || {};

  if (
    data.transactionId !==
      undefined &&
    data.transactionId !== null
  ) {
    const stored =
      validateAdMobTransactionId(
        data.transactionId
      );

    if (
      !stored ||
      stored.toLowerCase() !==
        transactionId.toLowerCase()
    ) {
      return "";
    }
  }

  return transactionId;
}

// ============================================================
// 🕒 TIMESTAMP VALIDATION
// ============================================================

function isRewardTimestampAcceptable(
  data,
  referenceNowMs,
  requestStartedAtMs
) {
  const rewardMs =
    getRewardTimestampMs(data);

  if (rewardMs <= 0) {
    return false;
  }

  if (
    rewardMs >
    referenceNowMs +
      FUTURE_TOLERANCE_MS
  ) {
    return false;
  }

  if (
    referenceNowMs - rewardMs >
    MAX_REWARD_AGE_MS
  ) {
    return false;
  }

  if (
    requestStartedAtMs > 0 &&
    rewardMs <
      requestStartedAtMs -
        REQUEST_GRACE_MS
  ) {
    return false;
  }

  return true;
}

// ============================================================
// 🔐 REWARD VALIDATION
// ============================================================

function validateReward(
  snapshot,
  uid,
  rewardPurpose,
  claimedField,
  options = {}
) {
  const config =
    getRewardConfiguration(
      rewardPurpose
    );

  if (
    !config ||
    !snapshot ||
    !snapshot.exists ||
    typeof uid !== "string" ||
    !uid.trim()
  ) {
    return null;
  }

  const data =
    snapshot.data() || {};

  // ----------------------------------------------------------
  // USER
  // ----------------------------------------------------------

  if (data.uid !== uid) {
    return null;
  }

  if (
    data.userId !== undefined &&
    data.userId !== null &&
    String(data.userId) !== uid
  ) {
    return null;
  }

  // ----------------------------------------------------------
  // REWARD TYPE
  // ----------------------------------------------------------

  if (
    data.rewardType !== "admob" ||
    data.rewardPurpose !==
      rewardPurpose
  ) {
    return null;
  }

  // ----------------------------------------------------------
  // CONSUMPTION
  // ----------------------------------------------------------

  if (
    data.rewardConsumed === true ||
    data[claimedField] === true
  ) {
    return null;
  }

  if (
    rewardPurpose === "mining_start" &&
    (
      data.miningClaimed === true ||
      data.miningStartClaimed === true ||
      data.miningStartClaimedAt
    )
  ) {
    return null;
  }

  if (
    rewardPurpose === "power_boost" &&
    (
      data.powerBoostClaimed === true ||
      data.powerBoostClaimedAt
    )
  ) {
    return null;
  }

  // ----------------------------------------------------------
  // SSV AD UNIT
  // ----------------------------------------------------------

  if (
    typeof data.adUnit !== "string" ||
    data.adUnit.trim() !==
      String(config.ssvAdUnitId)
  ) {
    return null;
  }

  // ----------------------------------------------------------
  // REWARD ITEM
  // ----------------------------------------------------------

  if (
    typeof data.rewardItem !== "string" ||
    data.rewardItem.trim() !==
      String(config.rewardItem)
  ) {
    return null;
  }

  // ----------------------------------------------------------
  // REWARD AMOUNT
  // ----------------------------------------------------------

  const rewardAmount =
    Number(data.rewardAmount);

  if (
    !Number.isFinite(rewardAmount) ||
    rewardAmount !==
      Number(config.rewardAmount)
  ) {
    return null;
  }

  // ----------------------------------------------------------
  // TRANSACTION
  // ----------------------------------------------------------

  const transactionId =
    validateRewardTransactionId(
      snapshot
    );

  if (!transactionId) {
    return null;
  }

  // ----------------------------------------------------------
  // TIMESTAMP
  // ----------------------------------------------------------

  const referenceNowMs =
    safePositive(
      options.referenceNowMs,
      Date.now()
    );

  const requestStartedAtMs =
    safeNonNegative(
      options.requestStartedAtMs,
      0
    );

  if (
    !isRewardTimestampAcceptable(
      data,
      referenceNowMs,
      requestStartedAtMs
    )
  ) {
    return null;
  }

  // ----------------------------------------------------------
  // REQUESTED TRANSACTION
  // ----------------------------------------------------------

  const requestedTransactionId =
    validateAdMobTransactionId(
      options.transactionId
    );

  if (
    requestedTransactionId &&
    requestedTransactionId.toLowerCase() !==
      transactionId.toLowerCase()
  ) {
    return null;
  }

  return {
    ref: snapshot.ref,
    data,
    transactionId,

    rewardTimestampMs:
      getRewardTimestampMs(data),

    createdAtMs:
      getRewardCreatedAtMs(data),
  };
}

// ============================================================
// 🔎 FIND VERIFIED REWARD
// ============================================================

async function findVerifiedAdMobReward(
  uid,
  rewardPurpose,
  claimedField,
  options = {}
) {
  const config =
    getRewardConfiguration(
      rewardPurpose
    );

  if (
    !config ||
    typeof uid !== "string" ||
    !uid.trim()
  ) {
    return null;
  }

  const referenceNowMs =
    safePositive(
      options.referenceNowMs,
      Date.now()
    );

  const requestStartedAtMs =
    safeNonNegative(
      options.requestStartedAtMs,
      0
    );

  const requestedTransactionId =
    validateAdMobTransactionId(
      options.transactionId
    );

  // ----------------------------------------------------------
  // EXACT TRANSACTION
  // ----------------------------------------------------------

  if (requestedTransactionId) {
    const snapshot =
      await db
        .collection("admobRewards")
        .doc(requestedTransactionId)
        .get();

    return validateReward(
      snapshot,
      uid,
      rewardPurpose,
      claimedField,
      {
        referenceNowMs,
        requestStartedAtMs,
        transactionId:
          requestedTransactionId,
      }
    );
  }

  // ----------------------------------------------------------
  // DISCOVERY
  // ----------------------------------------------------------

  const snapshot =
    await db
      .collection("admobRewards")
      .where("uid", "==", uid)
      .where(
        "rewardPurpose",
        "==",
        rewardPurpose
      )
      .limit(REWARD_QUERY_LIMIT)
      .get();

  if (snapshot.empty) {
    return null;
  }

  const candidates = [];

  snapshot.forEach((document) => {
    const reward =
      validateReward(
        document,
        uid,
        rewardPurpose,
        claimedField,
        {
          referenceNowMs,
          requestStartedAtMs,
        }
      );

    if (reward) {
      candidates.push(reward);
    }
  });

  if (!candidates.length) {
    return null;
  }

  candidates.sort((a, b) => {
    if (
      b.rewardTimestampMs !==
      a.rewardTimestampMs
    ) {
      return (
        b.rewardTimestampMs -
        a.rewardTimestampMs
      );
    }

    if (
      b.createdAtMs !==
      a.createdAtMs
    ) {
      return (
        b.createdAtMs -
        a.createdAtMs
      );
    }

    return b.transactionId.localeCompare(
      a.transactionId
    );
  });

  return candidates[0];
}

// ============================================================
// ⏳ WAIT FOR SSV
// ============================================================

function sleep(ms) {
  return new Promise((resolve) => {
    setTimeout(resolve, ms);
  });
}

async function waitForVerifiedAdMobReward(
  uid,
  rewardPurpose,
  claimedField,
  options = {}
) {
  const startedAt = Date.now();

  const requestStartedAtMs =
    safePositive(
      options.requestStartedAtMs,
      startedAt
    );

  const transactionId =
    validateAdMobTransactionId(
      options.transactionId
    );

  while (
    Date.now() - startedAt <
    SSV_WAIT_TIMEOUT_MS
  ) {
    const reward =
      await findVerifiedAdMobReward(
        uid,
        rewardPurpose,
        claimedField,
        {
          referenceNowMs:
            Date.now(),

          requestStartedAtMs,

          transactionId,
        }
      );

    if (reward) {
      console.log(
        "🐱 AdMob SSV reward verified",
        {
          uid,
          rewardPurpose,
          transactionId:
            reward.transactionId,
        }
      );

      return reward;
    }

    await sleep(
      SSV_POLL_INTERVAL_MS
    );
  }

  throw new Error(
    rewardPurpose === "mining_start"
      ? "🐱 AdMob-mainoksen SSV-vahvistusta ei löytynyt ajoissa."
      : "🐱 Power Boost -mainoksen SSV-vahvistusta ei löytynyt ajoissa."
  );
}

// ============================================================
// 🔐 AUTHORITATIVE VALIDATION
// ============================================================

function validateVerifiedRewardDocument(
  snapshot,
  uid,
  rewardPurpose,
  claimedField,
  options = {}
) {
  const reward =
    validateReward(
      snapshot,
      uid,
      rewardPurpose,
      claimedField,
      options
    );

  if (!reward) {
    throw new Error(
      "🐱 AdMob-palkinnon validointi epäonnistui."
    );
  }

  return {
    rewardData:
      reward.data,

    transactionId:
      reward.transactionId,

    rewardTimestampMs:
      reward.rewardTimestampMs,
  };
}

// ============================================================
// 🎁 MINING START
// ============================================================

async function getVerifiedMiningStartReward(
  uid,
  options = {}
) {
  return waitForVerifiedAdMobReward(
    uid,
    "mining_start",
    "miningStartClaimed",
    options
  );
}

// ============================================================
// ⚡ POWER BOOST
// ============================================================

async function getVerifiedPowerBoostReward(
  uid,
  options = {}
) {
  return waitForVerifiedAdMobReward(
    uid,
    "power_boost",
    "powerBoostClaimed",
    options
  );
}

// ============================================================
// 📦 EXPORTS
// ============================================================

module.exports = {
  getSafeNumber: safeNumber,
  getSafeNonNegativeNumber:
    safeNonNegative,
  getSafePositiveNumber:
    safePositive,

  validateAdMobTransactionId,

  getTimestampMilliseconds:
    timestampMs,

  getRewardTimestampMs,
  getRewardCreatedAtMs,

  getRewardConfiguration,

  validateRewardTransactionId,

  isRewardTimestampAcceptable,

  isValidRewardData: (
    snapshot,
    uid,
    rewardPurpose,
    claimedField,
    options = {}
  ) =>
    Boolean(
      validateReward(
        snapshot,
        uid,
        rewardPurpose,
        claimedField,
        options
      )
    ),

  findVerifiedAdMobReward,
  waitForVerifiedAdMobReward,

  validateVerifiedRewardDocument,

  getVerifiedMiningStartReward,
  getVerifiedPowerBoostReward,
};