"use strict";

// ============================================================
// 🐱 STELLA MINING FUNCTIONS
// ============================================================
//
// Stella Mining
// Daily Hash Rate
// Stella Power Boost
// AdMob SSV verification
// Stella Achievements
// Mining history
//
// IMPORTANT:
//
// AdMob reward is NOT an STL token reward.
//
// AdMob only authorizes:
// - Mining Start
// - Power Boost
//
// MINING CYCLE:
//
// - Every mining cycle lasts MINING_DURATION_MS.
// - miningHashRate belongs ONLY to that cycle.
// - A new cycle receives the current Daily Hash Rate.
// - An old cycle can NEVER inherit a new cycle's Hash Rate.
//
// POWER BOOST:
//
// - Only active while mining is active.
// - Never continues after miningEndsAt.
// - Never carries into a new mining cycle.
// - Boost history is used for actual mining calculations.
// - Only boosts started inside the current mining cycle count.
//
// FIRESTORE TRANSACTION RULE:
//
// ALL transaction.get() / transaction.get(query)
// reads must happen before transaction writes.
// ============================================================

const {
  onCall,
  HttpsError,
} = require("firebase-functions/v2/https");

const {
  db,
  FieldValue,
} = require("../firebase/firebase");

const {
  DAILY_HASH_RATE_START,
  DAILY_HASH_RATE_STEP,
  DAILY_HASH_RATE_MAX_DAY,
  MAX_DAILY_HASH_RATE,

  MINING_DURATION_MS,
  MINING_PER_HASH_PER_HOUR,

  AD_HASH_RATE_BONUS,
  AD_BOOST_DURATION_MS,
  MAX_ADS_PER_DAY,
  AD_COOLDOWN_MS,

  ADMOB_MINING_AD_UNIT_ID,
  ADMOB_POWER_BOOST_AD_UNIT_ID,

  ADMOB_MINING_SSV_AD_UNIT_ID,
  ADMOB_POWER_BOOST_SSV_AD_UNIT_ID,

  ADMOB_MINING_SSV_REWARD_AMOUNT,
  ADMOB_MINING_SSV_REWARD_ITEM,

  ADMOB_POWER_BOOST_SSV_REWARD_AMOUNT,
  ADMOB_POWER_BOOST_SSV_REWARD_ITEM,
} = require("../config/miningConfig");

const {
  getUtcDateString,
} = require("../utils/dateUtils");

const {
  getUserRef,
  getHistoryCollection,
  getAdMobRewardRef,
} = require("../utils/userUtils");

const {
  calculateMiningStatus,
  getMiningStartTime,
  getMiningEndTime,
  calculateMining,
} = require("../utils/miningUtils");


// ============================================================
// 🔢 SAFE NUMBERS
// ============================================================

function getSafeNumber(value, fallback = 0) {
  const number = Number(value);

  return Number.isFinite(number)
    ? number
    : fallback;
}


function getSafeNonNegativeNumber(
  value,
  fallback = 0
) {
  const number = Number(value);

  return Number.isFinite(number) && number >= 0
    ? number
    : fallback;
}


function getSafePositiveNumber(
  value,
  fallback = 0
) {
  const number = Number(value);

  return Number.isFinite(number) && number > 0
    ? number
    : fallback;
}


// ============================================================
// 🔐 ADMOB TRANSACTION ID
// ============================================================

function validateAdMobTransactionId(value) {
  if (typeof value !== "string") {
    return "";
  }

  const transactionId = value.trim();

  if (
    !transactionId ||
    transactionId.length > 256 ||
    transactionId.includes("/") ||
    transactionId.includes("\\")
  ) {
    return "";
  }

  return transactionId;
}


// ============================================================
// 🕒 TIMESTAMP → MILLISECONDS
// ============================================================

function getTimestampMilliseconds(value) {
  if (!value) {
    return 0;
  }

  if (typeof value.toDate === "function") {
    try {
      const date = value.toDate();

      if (
        date instanceof Date &&
        !Number.isNaN(date.getTime())
      ) {
        return date.getTime();
      }
    } catch (error) {
      return 0;
    }
  }

  if (value instanceof Date) {
    return Number.isNaN(value.getTime())
      ? 0
      : value.getTime();
  }

  if (typeof value === "string") {
    const parsed = new Date(value);

    return Number.isNaN(parsed.getTime())
      ? 0
      : parsed.getTime();
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
// 🔐 REWARD CREATED AT
// ============================================================

function getRewardCreatedAtMs(rewardData) {
  if (!rewardData) {
    return 0;
  }

  const candidates = [
    rewardData.createdAt,
    rewardData.receivedAt,
    rewardData.timestamp,
    rewardData.rewardedAt,
  ];

  for (const candidate of candidates) {
    const milliseconds =
      getTimestampMilliseconds(candidate);

    if (milliseconds > 0) {
      return milliseconds;
    }
  }

  return 0;
}


// ============================================================
// 🎁 EXPECTED ADMOB REWARD CONFIGURATION
// ============================================================

function getRewardConfiguration(rewardPurpose) {
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
// 🔐 REWARD TRANSACTION ID CONSISTENCY
// ============================================================

function validateRewardTransactionId(
  rewardSnapshot
) {
  if (!rewardSnapshot || !rewardSnapshot.exists) {
    return "";
  }

  const transactionId =
    validateAdMobTransactionId(
      rewardSnapshot.id
    );

  if (!transactionId) {
    return "";
  }

  const rewardData =
    rewardSnapshot.data() || {};

  if (
    rewardData.transactionId &&
    String(
      rewardData.transactionId
    ) !== transactionId
  ) {
    return "";
  }

  return transactionId;
}


// ============================================================
// 🔐 VALIDATE REWARD DATA
// ============================================================

function isValidRewardData(
  rewardSnapshot,
  uid,
  rewardPurpose,
  claimedField
) {
  const configuration =
    getRewardConfiguration(
      rewardPurpose
    );

  if (!configuration) {
    return false;
  }

  if (
    !rewardSnapshot ||
    !rewardSnapshot.exists
  ) {
    return false;
  }

  const rewardData =
    rewardSnapshot.data() || {};

  if (
    typeof uid !== "string" ||
    !uid
  ) {
    return false;
  }

  if (
    rewardData.uid !== uid
  ) {
    return false;
  }

  if (
    rewardData.rewardType !==
    "admob"
  ) {
    return false;
  }

  if (
    rewardData.rewardPurpose !==
    rewardPurpose
  ) {
    return false;
  }

  if (
    rewardData.rewardConsumed === true
  ) {
    return false;
  }

  if (
    rewardData[claimedField] === true
  ) {
    return false;
  }

  if (
    rewardPurpose === "mining_start" &&
    (
      rewardData.miningClaimed === true ||
      rewardData.miningStartClaimed === true ||
      rewardData.miningStartClaimedAt
    )
  ) {
    return false;
  }

  if (
    rewardPurpose === "power_boost" &&
    (
      rewardData.powerBoostClaimed === true ||
      rewardData.powerBoostClaimedAt
    )
  ) {
    return false;
  }

  if (
    typeof rewardData.adUnit !==
    "string"
  ) {
    return false;
  }

  const adUnit =
    rewardData.adUnit.trim();

  if (
    adUnit !==
      configuration.rewardedAdUnitId &&
    adUnit !==
      configuration.ssvAdUnitId
  ) {
    return false;
  }

  if (
    typeof rewardData.rewardItem !==
    "string"
  ) {
    return false;
  }

  if (
    rewardData.rewardItem.trim() !==
    configuration.rewardItem
  ) {
    return false;
  }

  const rewardAmount =
    Number(
      rewardData.rewardAmount
    );

  if (
    !Number.isFinite(
      rewardAmount
    )
  ) {
    return false;
  }

  if (
    rewardAmount !==
    Number(
      configuration.rewardAmount
    )
  ) {
    return false;
  }

  const transactionId =
    validateRewardTransactionId(
      rewardSnapshot
    );

  if (!transactionId) {
    return false;
  }

  return true;
}


// ============================================================
// 🔐 FIND VERIFIED ADMOB REWARD
// ============================================================

const ADMOB_REWARD_QUERY_LIMIT = 100;

async function findVerifiedAdMobReward(
  uid,
  rewardPurpose,
  claimedField
) {
  const configuration =
    getRewardConfiguration(
      rewardPurpose
    );

  if (!configuration) {
    return null;
  }

  if (
    typeof uid !== "string" ||
    !uid.trim()
  ) {
    return null;
  }

  const snapshot =
    await db
      .collection("admobRewards")
      .where(
        "uid",
        "==",
        uid
      )
      .limit(
        ADMOB_REWARD_QUERY_LIMIT
      )
      .get();

  if (snapshot.empty) {
    return null;
  }

  const candidates = [];

  snapshot.forEach((doc) => {
    const rewardData =
      doc.data() || {};

    if (
      !isValidRewardData(
        doc,
        uid,
        rewardPurpose,
        claimedField
      )
    ) {
      return;
    }

    const transactionId =
      validateRewardTransactionId(
        doc
      );

    if (!transactionId) {
      return;
    }

    candidates.push({
      ref:
        doc.ref,

      data:
        rewardData,

      transactionId,

      createdAtMs:
        getRewardCreatedAtMs(
          rewardData
        ),
    });
  });

  if (!candidates.length) {
    return null;
  }

  candidates.sort((a, b) => {
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
// 🔐 WAIT FOR ADMOB SSV
// ============================================================

const ADMOB_SSV_WAIT_TIMEOUT_MS =
  90 * 1000;

const ADMOB_SSV_POLL_INTERVAL_MS =
  2 * 1000;


function sleep(milliseconds) {
  return new Promise(
    (resolve) => {
      setTimeout(
        resolve,
        milliseconds
      );
    }
  );
}


async function waitForVerifiedAdMobReward(
  uid,
  rewardPurpose,
  claimedField
) {
  const startedAt =
    Date.now();

  while (
    Date.now() - startedAt <
    ADMOB_SSV_WAIT_TIMEOUT_MS
  ) {
    const reward =
      await findVerifiedAdMobReward(
        uid,
        rewardPurpose,
        claimedField
      );

    if (reward) {
      console.log(
        "🐱 AdMob SSV reward found",
        {
          uid,
          rewardPurpose,
          transactionId:
            reward.transactionId,
          elapsedMs:
            Date.now() -
            startedAt,
        }
      );

      return reward;
    }

    await sleep(
      ADMOB_SSV_POLL_INTERVAL_MS
    );
  }

  throw new HttpsError(
    "failed-precondition",
    rewardPurpose === "mining_start"
      ? "🐱 AdMob-mainoksen vahvistusta ei vielä löytynyt. Katso Mining Start -mainos loppuun ja odota hetki."
      : "🐱 Power Boost -mainoksen vahvistusta ei vielä löytynyt. Katso mainos loppuun ja odota hetki."
  );
}


// ============================================================
// 🔐 AUTHORITATIVE REWARD VALIDATION
// ============================================================

function validateVerifiedRewardDocument(
  rewardSnapshot,
  uid,
  rewardPurpose,
  claimedField
) {
  const configuration =
    getRewardConfiguration(
      rewardPurpose
    );

  if (!configuration) {
    throw new HttpsError(
      "invalid-argument",
      "🐱 AdMob-palkinnon käyttötarkoitus ei ole kelvollinen."
    );
  }

  if (!rewardSnapshot.exists) {
    throw new HttpsError(
      "failed-precondition",
      "🐱 AdMob-palkintoa ei enää löytynyt."
    );
  }

  const rewardData =
    rewardSnapshot.data() || {};

  if (
    rewardData.uid !== uid
  ) {
    throw new HttpsError(
      "permission-denied",
      "🐱 AdMob-palkinnon käyttäjä ei täsmää."
    );
  }

  if (
    rewardData.rewardType !==
    "admob"
  ) {
    throw new HttpsError(
      "failed-precondition",
      "🐱 AdMob-palkinnon tyyppi ei ole kelvollinen."
    );
  }

  if (
    rewardData.rewardPurpose !==
    rewardPurpose
  ) {
    throw new HttpsError(
      "failed-precondition",
      "🐱 AdMob-palkinnon käyttötarkoitus ei täsmää."
    );
  }

  if (
    rewardData.rewardConsumed === true ||
    rewardData[claimedField] === true
  ) {
    throw new HttpsError(
      "already-exists",
      "🐱 Tämä AdMob-palkinto on jo käytetty."
    );
  }

  if (
    rewardPurpose === "mining_start" &&
    (
      rewardData.miningClaimed === true ||
      rewardData.miningStartClaimed === true ||
      rewardData.miningStartClaimedAt
    )
  ) {
    throw new HttpsError(
      "already-exists",
      "🐱 Tämä Mining Start -palkinto on jo käytetty."
    );
  }

  if (
    rewardPurpose === "power_boost" &&
    (
      rewardData.powerBoostClaimed === true ||
      rewardData.powerBoostClaimedAt
    )
  ) {
    throw new HttpsError(
      "already-exists",
      "🐱 Tämä Power Boost -palkinto on jo käytetty."
    );
  }

  if (
    typeof rewardData.adUnit !==
    "string"
  ) {
    throw new HttpsError(
      "failed-precondition",
      "🐱 AdMob-mainoksen tunnistetiedot puuttuvat."
    );
  }

  const adUnit =
    rewardData.adUnit.trim();

  if (
    adUnit !==
      configuration.rewardedAdUnitId &&
    adUnit !==
      configuration.ssvAdUnitId
  ) {
    throw new HttpsError(
      "failed-precondition",
      "🐱 AdMob-mainoksen tunnistetiedot eivät täsmää tähän toimintoon."
    );
  }

  if (
    typeof rewardData.rewardItem !==
      "string" ||
    !rewardData.rewardItem.trim()
  ) {
    throw new HttpsError(
      "failed-precondition",
      "🐱 AdMob-palkinnon tiedot puuttuvat."
    );
  }

  if (
    rewardData.rewardItem.trim() !==
    configuration.rewardItem
  ) {
    throw new HttpsError(
      "failed-precondition",
      "🐱 AdMob-palkinnon reward item ei täsmää."
    );
  }

  const rewardAmount =
    Number(
      rewardData.rewardAmount
    );

  if (
    !Number.isFinite(
      rewardAmount
    ) ||
    rewardAmount !==
      Number(
        configuration.rewardAmount
      )
  ) {
    throw new HttpsError(
      "failed-precondition",
      "🐱 AdMob-palkinnon määrä ei ole kelvollinen."
    );
  }

  const transactionId =
    validateRewardTransactionId(
      rewardSnapshot
    );

  if (!transactionId) {
    throw new HttpsError(
      "failed-precondition",
      "🐱 AdMob transaction_id ei ole kelvollinen."
    );
  }

  return {
    rewardData,
    transactionId,
  };
}


async function getVerifiedMiningStartReward(uid) {
  return waitForVerifiedAdMobReward(
    uid,
    "mining_start",
    "miningStartClaimed"
  );
}


async function getVerifiedPowerBoostReward(uid) {
  return waitForVerifiedAdMobReward(
    uid,
    "power_boost",
    "powerBoostClaimed"
  );
}


// ============================================================
// 🎁 DAILY HASH RATE
// ============================================================

function calculateDailyHashRate(streak) {
  const safeStreak =
    Math.max(
      1,
      Math.floor(
        getSafeNumber(
          streak,
          1
        )
      )
    );

  const effectiveDay =
    Math.min(
      safeStreak,
      DAILY_HASH_RATE_MAX_DAY
    );

  const rate =
    DAILY_HASH_RATE_START +
    (
      (effectiveDay - 1) *
      DAILY_HASH_RATE_STEP
    );

  return Math.min(
    MAX_DAILY_HASH_RATE,
    Math.max(
      DAILY_HASH_RATE_START,
      rate
    )
  );
}


function getDailyStreak(data) {
  const stored =
    data.dailyStreak ??
    data.streak ??
    0;

  return Math.max(
    0,
    Math.floor(
      getSafeNumber(
        stored,
        0
      )
    )
  );
}


// ============================================================
// 🎁 NEXT DAILY CLAIM
// ============================================================

function calculateNextDailyClaim(
  data,
  today
) {
  const lastDailyDate =
    typeof data.lastDailyDate ===
    "string"
      ? data.lastDailyDate
      : "";

  const currentStreak =
    getDailyStreak(data);

  if (
    lastDailyDate === today
  ) {
    const streak =
      Math.max(
        1,
        currentStreak
      );

    return {
      claimedToday: true,

      streak,

      dailyHashRate:
        calculateDailyHashRate(
          streak
        ),
    };
  }

  const yesterday =
    new Date(
      `${today}T00:00:00.000Z`
    );

  yesterday.setUTCDate(
    yesterday.getUTCDate() - 1
  );

  const yesterdayString =
    yesterday
      .toISOString()
      .slice(0, 10);

  const newStreak =
    lastDailyDate ===
      yesterdayString &&
    currentStreak > 0
      ? currentStreak + 1
      : 1;

  return {
    claimedToday: false,

    streak:
      newStreak,

    dailyHashRate:
      calculateDailyHashRate(
        newStreak
      ),
  };
}


function getDailyStatus(
  data,
  today
) {
  return calculateNextDailyClaim(
    data,
    today
  );
}


// ============================================================
// 📺 MINING WINDOW
// ============================================================

function getMiningWindow(data) {
  const miningStartedAt =
    getMiningStartTime(data);

  const miningEndsAt =
    getMiningEndTime(data);

  const miningStartMs =
    miningStartedAt
      ? miningStartedAt.getTime()
      : 0;

  const miningEndMs =
    miningEndsAt
      ? miningEndsAt.getTime()
      : 0;

  const valid =
    miningStartMs > 0 &&
    miningEndMs > miningStartMs;

  return {
    miningStartedAt:
      valid
        ? miningStartedAt
        : null,

    miningEndsAt:
      valid
        ? miningEndsAt
        : null,

    miningStartMs:
      valid
        ? miningStartMs
        : 0,

    miningEndMs:
      valid
        ? miningEndMs
        : 0,

    valid,
  };
}


function isMiningActive(
  data,
  nowMs
) {
  const window =
    getMiningWindow(data);

  return (
    window.valid &&
    nowMs >= window.miningStartMs &&
    nowMs < window.miningEndMs
  );
}


// ============================================================
// 📺 AD STATUS
// ============================================================

function getAdStatus(
  data,
  nowMs,
  today
) {
  const storedDate =
    typeof data.lastAdDate ===
    "string"
      ? data.lastAdDate
      : "";

  const adsToday =
    storedDate === today
      ? Math.max(
          0,
          Math.floor(
            getSafeNumber(
              data.adsToday,
              0
            )
          )
        )
      : 0;

  const lastAdRewardMs =
    getTimestampMilliseconds(
      data.lastAdRewardAt
    );

  const cooldownRemainingMs =
    lastAdRewardMs > 0
      ? Math.max(
          0,
          lastAdRewardMs +
            AD_COOLDOWN_MS -
            nowMs
        )
      : 0;

  const boostStartedMs =
    getTimestampMilliseconds(
      data.adBoostStartedAt
    );

  const boostEndsMs =
    getTimestampMilliseconds(
      data.adBoostEndsAt
    );

  const miningWindow =
    getMiningWindow(data);

  const miningActive =
    miningWindow.valid &&
    nowMs >= miningWindow.miningStartMs &&
    nowMs < miningWindow.miningEndMs;

  const boostStartedInsideMining =
    miningActive &&
    boostStartedMs >=
      miningWindow.miningStartMs &&
    boostStartedMs <
      miningWindow.miningEndMs;

  const effectiveBoostEndsMs =
    boostStartedInsideMining &&
    boostEndsMs > boostStartedMs
      ? Math.min(
          boostEndsMs,
          miningWindow.miningEndMs
        )
      : 0;

  const adBoostActive =
    miningActive &&
    boostStartedInsideMining &&
    effectiveBoostEndsMs > nowMs;

  const adBoostRemainingMs =
    adBoostActive
      ? Math.max(
          0,
          effectiveBoostEndsMs - nowMs
        )
      : 0;

  const canWatchAd =
    miningActive &&
    adsToday < MAX_ADS_PER_DAY &&
    cooldownRemainingMs === 0 &&
    !adBoostActive;

  return {
    adsToday,

    maxAdsPerDay:
      MAX_ADS_PER_DAY,

    cooldownRemainingMs,

    canWatchAd,

    adBoostActive,

    adBoostRemainingMs,

    adBoostStartedAt:
      adBoostActive
        ? new Date(boostStartedMs)
        : null,

    adBoostEndsAt:
      adBoostActive
        ? new Date(effectiveBoostEndsMs)
        : null,
  };
}


// ============================================================
// ⛏️ CURRENT CYCLE HASH RATE
// ============================================================

function getMiningHashRate(
  data,
  fallbackHashRate
) {
  const stored =
    getSafePositiveNumber(
      data.miningHashRate,
      0
    );

  if (
    stored >= DAILY_HASH_RATE_START &&
    stored <= MAX_DAILY_HASH_RATE
  ) {
    return stored;
  }

  const fallback =
    getSafePositiveNumber(
      fallbackHashRate,
      DAILY_HASH_RATE_START
    );

  return Math.min(
    MAX_DAILY_HASH_RATE,
    Math.max(
      DAILY_HASH_RATE_START,
      fallback
    )
  );
}


// ============================================================
// ⛏️ HISTORICAL CYCLE HASH RATE
// ============================================================
//
// NEVER fall back to the current Daily Hash Rate.
//
// A historical cycle with an invalid Hash Rate is rejected.
// ============================================================

function getHistoricalMiningHashRate(data) {
  const stored =
    getSafePositiveNumber(
      data.miningHashRate,
      0
    );

  if (
    stored < DAILY_HASH_RATE_START ||
    stored > MAX_DAILY_HASH_RATE
  ) {
    console.warn(
      "🐱 Invalid historical miningHashRate; preventing cross-cycle Hash Rate inheritance.",
      {
        stored,
      }
    );

    return 0;
  }

  return stored;
}


// ============================================================
// 📺 BOOST HISTORY
// ============================================================

function getMaximumBoostHistoryEntries() {
  const cycleDays =
    Math.max(
      1,
      Math.ceil(
        MINING_DURATION_MS /
        (24 * 60 * 60 * 1000)
      )
    );

  return Math.max(
    MAX_ADS_PER_DAY,
    (
      (cycleDays + 1) *
      MAX_ADS_PER_DAY
    ) + 10
  );
}


async function getAdBoostHistory(
  uid,
  miningStartMs,
  miningEndMs,
  transaction = null
) {
  if (
    !miningStartMs ||
    !miningEndMs ||
    miningEndMs <= miningStartMs
  ) {
    return [];
  }

  const query =
    getHistoryCollection(uid)
      .where(
        "boostStartedAt",
        ">=",
        new Date(miningStartMs)
      )
      .where(
        "boostStartedAt",
        "<",
        new Date(miningEndMs)
      )
      .orderBy(
        "boostStartedAt",
        "asc"
      )
      .limit(
        getMaximumBoostHistoryEntries()
      );

  const snapshot =
    transaction
      ? await transaction.get(query)
      : await query.get();

  const boosts = [];

  snapshot.forEach((doc) => {
    const data =
      doc.data() || {};

    if (
      data.type !== "ad_reward"
    ) {
      return;
    }

    if (
      data.rewardPurpose !==
      "power_boost"
    ) {
      return;
    }

    const start =
      getTimestampMilliseconds(
        data.boostStartedAt
      );

    const end =
      getTimestampMilliseconds(
        data.boostEndsAt
      );

    if (
      start <= 0 ||
      end <= start
    ) {
      return;
    }

    if (
      start < miningStartMs ||
      start >= miningEndMs
    ) {
      return;
    }

    if (
      end <= miningStartMs ||
      start >= miningEndMs
    ) {
      return;
    }

    boosts.push({
      boostStartedMs:
        Math.max(
          start,
          miningStartMs
        ),

      boostEndsMs:
        Math.min(
          end,
          miningEndMs
        ),
    });
  });

  return boosts;
}


// ============================================================
// ⚡ CALCULATE BOOST TIME
// ============================================================

function calculateAdBoostMilliseconds(
  boosts,
  miningStartMs,
  miningEndMs
) {
  if (
    !Array.isArray(boosts) ||
    !miningStartMs ||
    !miningEndMs ||
    miningEndMs <= miningStartMs
  ) {
    return 0;
  }

  const intervals =
    boosts
      .map((boost) => {
        const start =
          Math.max(
            miningStartMs,
            getSafeNumber(
              boost.boostStartedMs,
              0
            )
          );

        const end =
          Math.min(
            miningEndMs,
            getSafeNumber(
              boost.boostEndsMs,
              0
            )
          );

        if (end <= start) {
          return null;
        }

        return {
          start,
          end,
        };
      })
      .filter(Boolean)
      .sort(
        (a, b) =>
          a.start - b.start
      );

  if (!intervals.length) {
    return 0;
  }

  let totalMs = 0;

  let currentStart =
    intervals[0].start;

  let currentEnd =
    intervals[0].end;

  for (
    let i = 1;
    i < intervals.length;
    i += 1
  ) {
    const interval =
      intervals[i];

    if (
      interval.start <= currentEnd
    ) {
      currentEnd =
        Math.max(
          currentEnd,
          interval.end
        );
    } else {
      totalMs +=
        currentEnd -
        currentStart;

      currentStart =
        interval.start;

      currentEnd =
        interval.end;
    }
  }

  totalMs +=
    currentEnd -
    currentStart;

  return Math.max(
    0,
    totalMs
  );
}


// ============================================================
// ⛏️ CALCULATE COMPLETE MINING CYCLE
// ============================================================

async function calculateMiningCycle(
  uid,
  miningStartMs,
  miningEndMs,
  miningHashRate,
  transaction = null
) {
  if (
    !miningStartMs ||
    !miningEndMs ||
    miningEndMs <= miningStartMs
  ) {
    return {
      baseMining: 0,
      adBoostMining: 0,
      boostMilliseconds: 0,
      totalMining: 0,
    };
  }

  const safeHashRate =
    getSafePositiveNumber(
      miningHashRate,
      0
    );

  const durationMs =
    Math.max(
      0,
      miningEndMs -
        miningStartMs
    );

  const baseMining =
    safeHashRate > 0
      ? Math.max(
          0,
          getSafeNumber(
            calculateMining(
              safeHashRate,
              durationMs
            ),
            0
          )
        )
      : 0;

  const boosts =
    await getAdBoostHistory(
      uid,
      miningStartMs,
      miningEndMs,
      transaction
    );

  const boostMilliseconds =
    calculateAdBoostMilliseconds(
      boosts,
      miningStartMs,
      miningEndMs
    );

  const adBoostMining =
    boostMilliseconds > 0 &&
    AD_HASH_RATE_BONUS > 0
      ? Math.max(
          0,
          getSafeNumber(
            calculateMining(
              AD_HASH_RATE_BONUS,
              boostMilliseconds
            ),
            0
          )
        )
      : 0;

  const totalMining =
    Math.max(
      0,
      baseMining +
        adBoostMining
    );

  return {
    baseMining,

    adBoostMining,

    boostMilliseconds,

    totalMining,
  };
}


// ============================================================
// 🏆 ACHIEVEMENTS
// ============================================================

function getAchievementCollection(uid) {
  return getUserRef(uid)
    .collection(
      "achievements"
    );
}


async function getAchievementData(
  transaction,
  uid,
  achievementId
) {
  const ref =
    getAchievementCollection(uid)
      .doc(achievementId);

  const snapshot =
    await transaction.get(ref);

  return {
    ref,

    data:
      snapshot.exists
        ? snapshot.data() || {}
        : {},
  };
}


function buildAchievementUpdate(
  achievementId,
  target,
  reward,
  progress,
  existingData,
  now
) {
  const oldProgress =
    Math.max(
      0,
      getSafeNumber(
        existingData.progress,
        0
      )
    );

  const safeTarget =
    Math.max(
      0,
      getSafeNumber(
        target,
        0
      )
    );

  const safeProgress =
    Math.min(
      safeTarget,
      Math.max(
        oldProgress,
        getSafeNonNegativeNumber(
          progress,
          0
        )
      )
    );

  const alreadyUnlocked =
    existingData.unlocked === true;

  const unlocked =
    alreadyUnlocked ||
    (
      safeTarget > 0 &&
      safeProgress >= safeTarget
    );

  const update = {
    achievementId,

    progress:
      safeProgress,

    target:
      safeTarget,

    reward,

    unlocked,

    rewardClaimed:
      existingData.rewardClaimed ===
      true,

    updatedAt:
      now,
  };

  if (
    unlocked &&
    !alreadyUnlocked &&
    !existingData.unlockedAt
  ) {
    update.unlockedAt =
      now;
  }

  return update;
}


async function updateMiningAchievements(
  transaction,
  uid,
  collected,
  startedMining,
  now
) {
  // ----------------------------------------------------------
  // ALL ACHIEVEMENT READS FIRST
  // ----------------------------------------------------------

  const firstPaw =
    await getAchievementData(
      transaction,
      uid,
      "first_paw"
    );

  const littleMiner =
    await getAchievementData(
      transaction,
      uid,
      "little_miner"
    );

  const stlHunter =
    await getAchievementData(
      transaction,
      uid,
      "stl_hunter"
    );

  // ----------------------------------------------------------
  // FIRST PAW
  // ----------------------------------------------------------

  if (startedMining) {
    transaction.set(
      firstPaw.ref,
      buildAchievementUpdate(
        "first_paw",
        1,
        2,
        1,
        firstPaw.data,
        now
      ),
      {
        merge: true,
      }
    );
  }

  if (collected <= 0) {
    return;
  }

  // ----------------------------------------------------------
  // LITTLE MINER
  // ----------------------------------------------------------

  const littleProgress =
    Math.max(
      0,
      getSafeNumber(
        littleMiner.data.progress,
        0
      )
    ) + collected;

  transaction.set(
    littleMiner.ref,
    buildAchievementUpdate(
      "little_miner",
      10,
      5,
      littleProgress,
      littleMiner.data,
      now
    ),
    {
      merge: true,
    }
  );

  // ----------------------------------------------------------
  // STL HUNTER
  // ----------------------------------------------------------

  const hunterProgress =
    Math.max(
      0,
      getSafeNumber(
        stlHunter.data.progress,
        0
      )
    ) + collected;

  transaction.set(
    stlHunter.ref,
    buildAchievementUpdate(
      "stl_hunter",
      100,
      10,
      hunterProgress,
      stlHunter.data,
      now
    ),
    {
      merge: true,
    }
  );
}


// ============================================================
// 📊 CURRENT UNCLAIMED MINING
// ============================================================

async function calculateCurrentUnclaimedMining(
  uid,
  data,
  nowMs,
  transaction = null
) {
  const miningWindow =
    getMiningWindow(data);

  if (!miningWindow.valid) {
    return {
      unclaimedMining: 0,
      baseMining: 0,
      adBoostMining: 0,
      boostMilliseconds: 0,
    };
  }

  const calculationEndMs =
    Math.min(
      miningWindow.miningEndMs,
      nowMs
    );

  if (
    calculationEndMs <=
    miningWindow.miningStartMs
  ) {
    return {
      unclaimedMining: 0,
      baseMining: 0,
      adBoostMining: 0,
      boostMilliseconds: 0,
    };
  }

  const miningHashRate =
    getHistoricalMiningHashRate(
      data
    );

  if (miningHashRate <= 0) {
    return {
      unclaimedMining: 0,
      baseMining: 0,
      adBoostMining: 0,
      boostMilliseconds: 0,
    };
  }

  const cycle =
    await calculateMiningCycle(
      uid,
      miningWindow.miningStartMs,
      calculationEndMs,
      miningHashRate,
      transaction
    );

  return {
    unclaimedMining:
      Math.max(
        0,
        cycle.totalMining
      ),

    baseMining:
      cycle.baseMining,

    adBoostMining:
      cycle.adBoostMining,

    boostMilliseconds:
      cycle.boostMilliseconds,
  };
}


// ============================================================
// 🐱 GET MINING STATUS
// ============================================================

const getMiningStatus =
  onCall(
    {
      region:
        "us-central1",
    },

    async (request) => {
      try {
        if (!request.auth) {
          throw new HttpsError(
            "unauthenticated",
            "🐱 Kirjaudu sisään jatkaaksesi Stella Miningia."
          );
        }

        const uid =
          request.auth.uid;

        const userRef =
          getUserRef(uid);

        const snapshot =
          await userRef.get();

        const data =
          snapshot.exists
            ? snapshot.data() || {}
            : {};

        const now =
          new Date();

        const nowMs =
          now.getTime();

        const today =
          getUtcDateString(now);

        const dailyStatus =
          getDailyStatus(
            data,
            today
          );

        const miningWindow =
          getMiningWindow(data);

        const miningHashRate =
          miningWindow.valid
            ? getHistoricalMiningHashRate(
                data
              )
            : getMiningHashRate(
                data,
                dailyStatus.dailyHashRate
              );

        const miningBalance =
          getSafeNonNegativeNumber(
            data.miningBalance,
            0
          );

        const miningStatus =
          calculateMiningStatus(
            {
              ...data,

              hashRate:
                miningHashRate,
            },
            now
          );

        const currentMining =
          await calculateCurrentUnclaimedMining(
            uid,
            data,
            nowMs
          );

        const adStatus =
          getAdStatus(
            data,
            nowMs,
            today
          );

        const effectiveHashRate =
          adStatus.adBoostActive
            ? miningHashRate +
              AD_HASH_RATE_BONUS
            : miningHashRate;

        const estimatedTotal =
          Math.max(
            0,
            miningBalance +
              currentMining.unclaimedMining
          );

        const miningPerHour =
          effectiveHashRate *
          MINING_PER_HASH_PER_HOUR;

        const activeMiningPerHour =
          miningHashRate *
          MINING_PER_HASH_PER_HOUR;

        const miningStartedAt =
          getMiningStartTime(data);

        const miningEndsAt =
          getMiningEndTime(data);

        const hasMiningWindow =
          miningStartedAt !== null &&
          miningEndsAt !== null;

        return {
          success: true,

          message:
            miningStatus.miningActive
              ? "🐱⛏️ Stella louhii STL:ää!"
              : miningStatus.miningFinished
                ? "🐱✨ Louhinta on valmis kerättäväksi!"
                : "🐱 Stella odottaa seuraavaa louhintaa.",

          hashRate:
            miningHashRate,

          miningBalance,

          unclaimedMining:
            currentMining.unclaimedMining,

          baseMining:
            currentMining.baseMining,

          adBoostMining:
            currentMining.adBoostMining,

          boostMilliseconds:
            currentMining.boostMilliseconds,

          estimatedTotal,

          miningActive:
            miningStatus.miningActive === true,

          miningFinished:
            miningStatus.miningFinished === true,

          miningRemainingMs:
            Math.max(
              0,
              getSafeNumber(
                miningStatus.miningRemainingMs,
                0
              )
            ),

          elapsedMs:
            Math.max(
              0,
              getSafeNumber(
                miningStatus.elapsedMs,
                0
              )
            ),

          miningDurationMs:
            MINING_DURATION_MS,

          miningStartedAt:
            hasMiningWindow
              ? miningStartedAt.toISOString()
              : null,

          miningEndsAt:
            hasMiningWindow
              ? miningEndsAt.toISOString()
              : null,

          miningPerHour,

          miningPerMinute:
            miningPerHour / 60,

          miningPerSecond:
            miningPerHour / 3600,

          activeMiningPerHour,

          dailyClaimed:
            dailyStatus.claimedToday,

          streak:
            dailyStatus.streak,

          dailyStreak:
            dailyStatus.streak,

          dailyHashRate:
            dailyStatus.dailyHashRate,

          dailyHashRateBonus:
            dailyStatus.dailyHashRate,

          nextDailyHashRate:
            dailyStatus.dailyHashRate,

          nextDailyStreak:
            dailyStatus.streak,

          adsToday:
            adStatus.adsToday,

          maxAdsPerDay:
            adStatus.maxAdsPerDay,

          adHashRateBonus:
            AD_HASH_RATE_BONUS,

          adBoostDurationMs:
            AD_BOOST_DURATION_MS,

          adBoostActive:
            adStatus.adBoostActive,

          adBoostRemainingMs:
            adStatus.adBoostRemainingMs,

          adBoostStartedAt:
            adStatus.adBoostStartedAt
              ? adStatus.adBoostStartedAt.toISOString()
              : null,

          adBoostEndsAt:
            adStatus.adBoostEndsAt
              ? adStatus.adBoostEndsAt.toISOString()
              : null,

          canWatchAd:
            adStatus.canWatchAd,

          cooldownRemainingMs:
            adStatus.cooldownRemainingMs,

          effectiveHashRate,
        };
      } catch (error) {
        console.error(
          "getMiningStatus error:",
          error
        );

        if (
          error instanceof HttpsError
        ) {
          throw error;
        }

        throw new HttpsError(
          "internal",
          "Mining Status -tietojen lataaminen epäonnistui."
        );
      }
    }
  );


// ============================================================
// ⛏️ CLAIM / START MINING
// ============================================================

const claimMining =
  onCall(
    {
      region:
        "us-central1",

      timeoutSeconds:
        120,
    },

    async (request) => {
      try {
        if (!request.auth) {
          throw new HttpsError(
            "unauthenticated",
            "🐱 Kirjaudu sisään aloittaaksesi Stella Miningin."
          );
        }

        const uid =
          request.auth.uid;

        const userRef =
          getUserRef(uid);

        // ------------------------------------------------------
        // EARLY CHECK
        // ------------------------------------------------------

        const earlyNow =
          new Date();

        const earlyNowMs =
          earlyNow.getTime();

        const earlySnapshot =
          await userRef.get();

        const earlyData =
          earlySnapshot.exists
            ? earlySnapshot.data() || {}
            : {};

        const earlyWindow =
          getMiningWindow(
            earlyData
          );

        const earlyHashRate =
          earlyWindow.valid
            ? getHistoricalMiningHashRate(
                earlyData
              )
            : getMiningHashRate(
                earlyData,
                calculateDailyHashRate(
                  getDailyStreak(
                    earlyData
                  ) || 1
                )
              );

        const earlyStatus =
          calculateMiningStatus(
            {
              ...earlyData,

              hashRate:
                earlyHashRate,
            },
            earlyNow
          );

        if (
          earlyStatus.miningActive
        ) {
          const currentMining =
            await calculateCurrentUnclaimedMining(
              uid,
              earlyData,
              earlyNowMs
            );

          return {
            success: true,

            started: false,

            collected: 0,

            miningActive: true,

            hashRate:
              earlyHashRate,

            miningHashRate:
              earlyHashRate,

            dailyHashRate:
              calculateDailyHashRate(
                getDailyStreak(
                  earlyData
                ) || 1
              ),

            dailyStreak:
              getDailyStreak(
                earlyData
              ),

            streak:
              getDailyStreak(
                earlyData
              ),

            unclaimedMining:
              currentMining.unclaimedMining,

            baseMining:
              currentMining.baseMining,

            adBoostMining:
              currentMining.adBoostMining,

            boostMilliseconds:
              currentMining.boostMilliseconds,

            miningRemainingMs:
              Math.max(
                0,
                getSafeNumber(
                  earlyStatus.miningRemainingMs,
                  0
                )
              ),

            rewardConsumed: false,

            message:
              "🐱⛏️ Stella louhii jo STL:ää.",
          };
        }

        // ------------------------------------------------------
        // WAIT FOR VERIFIED SSV REWARD
        // ------------------------------------------------------

        const verifiedReward =
          await getVerifiedMiningStartReward(
            uid
          );

        const transactionId =
          validateAdMobTransactionId(
            verifiedReward.transactionId
          );

        if (!transactionId) {
          throw new HttpsError(
            "failed-precondition",
            "🐱 AdMob-tapahtuman tunnistaminen epäonnistui."
          );
        }

        const rewardRef =
          getAdMobRewardRef(
            transactionId
          );

        if (!rewardRef) {
          throw new HttpsError(
            "failed-precondition",
            "🐱 AdMob-tapahtuman tunnistaminen epäonnistui."
          );
        }

        return await db.runTransaction(
          async (transaction) => {
            const transactionNow =
              new Date();

            const transactionNowMs =
              transactionNow.getTime();

            const transactionToday =
              getUtcDateString(
                transactionNow
              );

            // ------------------------------------------------
            // ALL TRANSACTION READS FIRST
            // ------------------------------------------------

            const userSnapshot =
              await transaction.get(
                userRef
              );

            const rewardSnapshot =
              await transaction.get(
                rewardRef
              );

            const data =
              userSnapshot.exists
                ? userSnapshot.data() || {}
                : {};

            const currentStreak =
              getDailyStreak(data);

            const fallbackRate =
              calculateDailyHashRate(
                currentStreak > 0
                  ? currentStreak
                  : 1
              );

            const previousWindow =
              getMiningWindow(data);

            const existingHashRate =
              previousWindow.valid
                ? getHistoricalMiningHashRate(
                    data
                  )
                : getMiningHashRate(
                    data,
                    fallbackRate
                  );

            const existingStatus =
              calculateMiningStatus(
                {
                  ...data,

                  hashRate:
                    existingHashRate,
                },
                transactionNow
              );

            // ------------------------------------------------
            // IMPORTANT:
            //
            // If another request already started mining while
            // this request was waiting for SSV, do NOT consume
            // the reward.
            // ------------------------------------------------

            if (
              existingStatus.miningActive
            ) {
              const currentMining =
                await calculateCurrentUnclaimedMining(
                  uid,
                  data,
                  transactionNowMs,
                  transaction
                );

              return {
                success: true,

                started: false,

                collected: 0,

                miningActive: true,

                hashRate:
                  existingHashRate,

                miningHashRate:
                  existingHashRate,

                dailyHashRate:
                  fallbackRate,

                dailyStreak:
                  currentStreak,

                streak:
                  currentStreak,

                unclaimedMining:
                  currentMining.unclaimedMining,

                baseMining:
                  currentMining.baseMining,

                adBoostMining:
                  currentMining.adBoostMining,

                boostMilliseconds:
                  currentMining.boostMilliseconds,

                miningRemainingMs:
                  Math.max(
                    0,
                    getSafeNumber(
                      existingStatus.miningRemainingMs,
                      0
                    )
                  ),

                rewardConsumed: false,

                message:
                  "🐱⛏️ Stella louhii jo STL:ää. Mainospalkintoa ei kulutettu.",
              };
            }

            // ------------------------------------------------
            // AUTHORITATIVE SSV VALIDATION
            // ------------------------------------------------

            const validatedReward =
              validateVerifiedRewardDocument(
                rewardSnapshot,
                uid,
                "mining_start",
                "miningStartClaimed"
              );

            const authoritativeTransactionId =
              validatedReward.transactionId;

            // ------------------------------------------------
            // DAILY HASH RATE
            // ------------------------------------------------

            const dailyClaim =
              calculateNextDailyClaim(
                data,
                transactionToday
              );

            const dailyHashRate =
              dailyClaim.dailyHashRate;

            const dailyStreak =
              dailyClaim.streak;

            // ------------------------------------------------
            // CURRENT BALANCE
            // ------------------------------------------------

            const oldBalance =
              getSafeNonNegativeNumber(
                data.miningBalance,
                0
              );

            let newBalance =
              oldBalance;

            let collected = 0;

            let completedPreviousCycle =
              false;

            let previousBaseMining =
              0;

            let previousAdBoostMining =
              0;

            let previousBoostMilliseconds =
              0;

            // ------------------------------------------------
            // COMPLETE PREVIOUS CYCLE
            // ------------------------------------------------

            if (
              previousWindow.valid &&
              previousWindow.miningEndMs <=
                transactionNowMs
            ) {
              const previousHashRate =
                getHistoricalMiningHashRate(
                  data
                );

              if (
                previousHashRate <= 0
              ) {
                throw new HttpsError(
                  "failed-precondition",
                  "🐱 Edellisen mining-cyclen Hash Rate on virheellinen. Louhintaa ei korvattu uudella Hash Ratella."
                );
              }

              const previousCycle =
                await calculateMiningCycle(
                  uid,
                  previousWindow.miningStartMs,
                  previousWindow.miningEndMs,
                  previousHashRate,
                  transaction
                );

              previousBaseMining =
                previousCycle.baseMining;

              previousAdBoostMining =
                previousCycle.adBoostMining;

              previousBoostMilliseconds =
                previousCycle.boostMilliseconds;

              collected =
                Math.max(
                  0,
                  previousCycle.totalMining
                );

              if (collected > 0) {
                newBalance =
                  oldBalance +
                  collected;

                completedPreviousCycle =
                  true;
              }
            }

            // ------------------------------------------------
            // ACHIEVEMENT READS + WRITES
            // ------------------------------------------------

            await updateMiningAchievements(
              transaction,
              uid,
              collected,
              true,
              transactionNow
            );

            // ------------------------------------------------
            // NEW MINING CYCLE
            // ------------------------------------------------

            const newMiningStartedAt =
              transactionNow;

            const newMiningEndsAt =
              new Date(
                transactionNowMs +
                MINING_DURATION_MS
              );

            const userUpdate = {
              hashRate:
                dailyHashRate,

              dailyStreak,

              streak:
                dailyStreak,

              lastDailyDate:
                dailyClaim.claimedToday
                  ? (
                      typeof data.lastDailyDate ===
                      "string"
                        ? data.lastDailyDate
                        : transactionToday
                    )
                  : transactionToday,

              miningHashRate:
                dailyHashRate,

              miningBalance:
                newBalance,

              miningStartedAt:
                newMiningStartedAt,

              miningEndsAt:
                newMiningEndsAt,

              adBoostStartedAt:
                null,

              adBoostEndsAt:
                null,

              powerBoostTransactionId:
                null,

              updatedAt:
                FieldValue.serverTimestamp(),
            };

            transaction.set(
              userRef,
              userUpdate,
              {
                merge: true,
              }
            );

            // ------------------------------------------------
            // CONSUME EXACT MINING START SSV REWARD
            // ------------------------------------------------

            transaction.set(
              rewardRef,
              {
                miningClaimed: true,

                miningClaimedAt:
                  FieldValue.serverTimestamp(),

                miningStartClaimed: true,

                miningStartClaimedAt:
                  FieldValue.serverTimestamp(),

                miningStartClaimedBy:
                  uid,

                consumedAt:
                  FieldValue.serverTimestamp(),

                consumedBy:
                  uid,

                rewardConsumed: true,
              },
              {
                merge: true,
              }
            );

            // ------------------------------------------------
            // DAILY HASH RATE HISTORY
            // ------------------------------------------------

            if (
              !dailyClaim.claimedToday
            ) {
              const historyRef =
                getHistoryCollection(uid)
                  .doc();

              transaction.set(
                historyRef,
                {
                  type:
                    "dailyHashRate",

                  title:
                    "Stella Daily Hash Rate 🐱✨",

                  amount:
                    dailyHashRate,

                  hashRate:
                    dailyHashRate,

                  dailyHashRate,

                  hashRateBefore:
                    getSafeNonNegativeNumber(
                      data.hashRate,
                      0
                    ),

                  hashRateAfter:
                    dailyHashRate,

                  dailyStreak,

                  streak:
                    dailyStreak,

                  createdAt:
                    FieldValue.serverTimestamp(),
                }
              );
            }

            // ------------------------------------------------
            // COMPLETED PREVIOUS CYCLE HISTORY
            // ------------------------------------------------

            if (
              completedPreviousCycle
            ) {
              const historyRef =
                getHistoryCollection(uid)
                  .doc();

              const historicalHashRate =
                getHistoricalMiningHashRate(
                  data
                );

              transaction.set(
                historyRef,
                {
                  type:
                    "mining_reward",

                  title:
                    "Stella Mining Complete 🐱⛏️✨",

                  amount:
                    collected,

                  balanceAfter:
                    newBalance,

                  hashRate:
                    historicalHashRate,

                  miningHashRate:
                    historicalHashRate,

                  baseMining:
                    previousBaseMining,

                  adBoostMining:
                    previousAdBoostMining,

                  boostMilliseconds:
                    previousBoostMilliseconds,

                  miningStartedAt:
                    previousWindow.miningStartedAt,

                  miningEndsAt:
                    previousWindow.miningEndsAt,

                  createdAt:
                    FieldValue.serverTimestamp(),
                }
              );
            }

            // ------------------------------------------------
            // NEW MINING CYCLE HISTORY
            // ------------------------------------------------

            const startHistoryRef =
              getHistoryCollection(uid)
                .doc();

            transaction.set(
              startHistoryRef,
              {
                type:
                  "mining",

                title:
                  "Stella Mining Started 🐱⛏️",

                amount: 0,

                hashRate:
                  dailyHashRate,

                miningHashRate:
                  dailyHashRate,

                dailyHashRate,

                dailyStreak,

                miningDurationMs:
                  MINING_DURATION_MS,

                miningStartedAt:
                  newMiningStartedAt,

                miningEndsAt:
                  newMiningEndsAt,

                adRewardTransactionId:
                  authoritativeTransactionId,

                rewardPurpose:
                  "mining_start",

                createdAt:
                  FieldValue.serverTimestamp(),
              }
            );

            const dailyMessage =
              dailyClaim.claimedToday
                ? "🐱⛏️ Stella jatkaa tämän päivän louhintaa!"
                : `🐱✨ Stella sai päivän ${dailyStreak} Daily Hash Raten: ${dailyHashRate.toFixed(4)} HR!`;

            return {
              success: true,

              started: true,

              miningActive: true,

              collected,

              completedPreviousCycle,

              miningBalance:
                newBalance,

              hashRate:
                dailyHashRate,

              dailyHashRate,

              dailyHashRateBonus:
                dailyHashRate,

              dailyStreak,

              streak:
                dailyStreak,

              miningHashRate:
                dailyHashRate,

              miningDurationMs:
                MINING_DURATION_MS,

              miningRemainingMs:
                MINING_DURATION_MS,

              miningStartedAt:
                newMiningStartedAt.toISOString(),

              miningEndsAt:
                newMiningEndsAt.toISOString(),

              adBoostActive: false,

              adBoostRemainingMs: 0,

              adHashRateBonus:
                AD_HASH_RATE_BONUS,

              effectiveHashRate:
                dailyHashRate,

              adRewardTransactionId:
                authoritativeTransactionId,

              rewardConsumed: true,

              message:
                completedPreviousCycle
                  ? `🐱✨ Stella keräsi STL:t ja aloitti uuden louhinnan! ${dailyMessage}`
                  : dailyMessage,
            };
          }
        );
      } catch (error) {
        console.error(
          "claimMining error:",
          error
        );

        if (
          error instanceof HttpsError
        ) {
          throw error;
        }

        throw new HttpsError(
          "internal",
          "🐱 Stella Miningin käynnistäminen epäonnistui."
        );
      }
    }
  );


// ============================================================
// ⚡ POWER BOOST
// ============================================================

const powerBoost =
  onCall(
    {
      region:
        "us-central1",

      timeoutSeconds:
        120,
    },

    async (request) => {
      try {
        if (!request.auth) {
          throw new HttpsError(
            "unauthenticated",
            "🐱 Kirjaudu sisään käyttääksesi Power Boostia."
          );
        }

        const uid =
          request.auth.uid;

        const userRef =
          getUserRef(uid);

        // ------------------------------------------------------
        // EARLY CHECK
        // ------------------------------------------------------

        const earlyNow =
          new Date();

        const earlyNowMs =
          earlyNow.getTime();

        const earlyToday =
          getUtcDateString(
            earlyNow
          );

        const earlySnapshot =
          await userRef.get();

        const earlyData =
          earlySnapshot.exists
            ? earlySnapshot.data() || {}
            : {};

        if (
          !isMiningActive(
            earlyData,
            earlyNowMs
          )
        ) {
          throw new HttpsError(
            "failed-precondition",
            "🐱⚡ Power Boostia voi käyttää vain aktiivisen louhinnan aikana."
          );
        }

        const earlyWindow =
          getMiningWindow(
            earlyData
          );

        const earlyHashRate =
          earlyWindow.valid
            ? getHistoricalMiningHashRate(
                earlyData
              )
            : getMiningHashRate(
                earlyData,
                DAILY_HASH_RATE_START
              );

        if (
          earlyHashRate <= 0
        ) {
          throw new HttpsError(
            "failed-precondition",
            "🐱⚡ Nykyisen louhintasyklin Hash Rate ei ole kelvollinen."
          );
        }

        const earlyStatus =
          calculateMiningStatus(
            {
              ...earlyData,

              hashRate:
                earlyHashRate,
            },
            earlyNow
          );

        if (
          !earlyStatus.miningActive
        ) {
          throw new HttpsError(
            "failed-precondition",
            "🐱⚡ Stella Mining ei ole aktiivinen."
          );
        }

        const earlyAdStatus =
          getAdStatus(
            earlyData,
            earlyNowMs,
            earlyToday
          );

        if (
          earlyAdStatus.adsToday >=
          MAX_ADS_PER_DAY
        ) {
          throw new HttpsError(
            "resource-exhausted",
            "🐱 Päivän Power Boost -mainosraja on täynnä."
          );
        }

        if (
          earlyAdStatus.adBoostActive
        ) {
          throw new HttpsError(
            "failed-precondition",
            "🐱 Power Boost on jo aktiivinen."
          );
        }

        if (
          earlyAdStatus.cooldownRemainingMs >
          0
        ) {
          throw new HttpsError(
            "failed-precondition",
            "🐱 Power Boost ei ole vielä valmis käytettäväksi uudelleen."
          );
        }

        // ------------------------------------------------------
        // WAIT FOR VERIFIED SSV REWARD
        // ------------------------------------------------------

        const verifiedReward =
          await getVerifiedPowerBoostReward(
            uid
          );

        const transactionId =
          validateAdMobTransactionId(
            verifiedReward.transactionId
          );

        if (!transactionId) {
          throw new HttpsError(
            "failed-precondition",
            "🐱 Power Boost -AdMob-tapahtuman tunnistaminen epäonnistui."
          );
        }

        const rewardRef =
          getAdMobRewardRef(
            transactionId
          );

        if (!rewardRef) {
          throw new HttpsError(
            "failed-precondition",
            "🐱 Power Boost -AdMob-tapahtuman tunnistaminen epäonnistui."
          );
        }

        return await db.runTransaction(
          async (transaction) => {
            const transactionNow =
              new Date();

            const transactionNowMs =
              transactionNow.getTime();

            const transactionToday =
              getUtcDateString(
                transactionNow
              );

            // ------------------------------------------------
            // ALL TRANSACTION READS FIRST
            // ------------------------------------------------

            const userSnapshot =
              await transaction.get(
                userRef
              );

            const rewardSnapshot =
              await transaction.get(
                rewardRef
              );

            const data =
              userSnapshot.exists
                ? userSnapshot.data() || {}
                : {};

            const miningWindow =
              getMiningWindow(data);

            const miningActive =
              miningWindow.valid &&
              transactionNowMs >=
                miningWindow.miningStartMs &&
              transactionNowMs <
                miningWindow.miningEndMs;

            if (
              !miningActive
            ) {
              throw new HttpsError(
                "failed-precondition",
                "🐱⚡ Power Boostia voi käyttää vain aktiivisen louhinnan aikana."
              );
            }

            const miningHashRate =
              getHistoricalMiningHashRate(
                data
              );

            if (
              miningHashRate <= 0
            ) {
              throw new HttpsError(
                "failed-precondition",
                "🐱⚡ Nykyisen louhintasyklin Hash Rate ei ole kelvollinen."
              );
            }

            const miningStatus =
              calculateMiningStatus(
                {
                  ...data,

                  hashRate:
                    miningHashRate,
                },
                transactionNow
              );

            if (
              !miningStatus.miningActive
            ) {
              throw new HttpsError(
                "failed-precondition",
                "🐱⚡ Stella Mining ei ole enää aktiivinen."
              );
            }

            // ------------------------------------------------
            // AUTHORITATIVE SSV VALIDATION
            // ------------------------------------------------

            const validatedReward =
              validateVerifiedRewardDocument(
                rewardSnapshot,
                uid,
                "power_boost",
                "powerBoostClaimed"
              );

            const authoritativeTransactionId =
              validatedReward.transactionId;

            // ------------------------------------------------
            // RECHECK LIMITS
            // ------------------------------------------------

            const adStatus =
              getAdStatus(
                data,
                transactionNowMs,
                transactionToday
              );

            if (
              adStatus.adsToday >=
              MAX_ADS_PER_DAY
            ) {
              throw new HttpsError(
                "resource-exhausted",
                "🐱 Päivän Power Boost -mainosraja on täynnä."
              );
            }

            if (
              adStatus.adBoostActive
            ) {
              throw new HttpsError(
                "failed-precondition",
                "🐱 Power Boost on jo aktiivinen."
              );
            }

            if (
              adStatus.cooldownRemainingMs >
              0
            ) {
              throw new HttpsError(
                "failed-precondition",
                "🐱 Power Boost ei ole vielä valmis käytettäväksi uudelleen."
              );
            }

            // ------------------------------------------------
            // ALL READS COMPLETE
            // WRITES START HERE
            // ------------------------------------------------

            const boostStartedAt =
              transactionNow;

            const requestedEndMs =
              transactionNowMs +
              AD_BOOST_DURATION_MS;

            const actualEndMs =
              Math.min(
                requestedEndMs,
                miningWindow.miningEndMs
              );

            const boostEndsAt =
              new Date(
                actualEndMs
              );

            const actualDurationMs =
              Math.max(
                0,
                actualEndMs -
                  transactionNowMs
              );

            if (
              actualDurationMs <= 0
            ) {
              throw new HttpsError(
                "failed-precondition",
                "🐱⚡ Louhintaa ei ole enää tarpeeksi jäljellä Power Boostia varten."
              );
            }

            const storedAdDate =
              typeof data.lastAdDate ===
              "string"
                ? data.lastAdDate
                : "";

            const currentAds =
              storedAdDate ===
                transactionToday
                ? Math.max(
                    0,
                    Math.floor(
                      getSafeNumber(
                        data.adsToday,
                        0
                      )
                    )
                  )
                : 0;

            const newAdsToday =
              currentAds + 1;

            // ------------------------------------------------
            // USER STATE
            // ------------------------------------------------

            transaction.set(
              userRef,
              {
                adsToday:
                  newAdsToday,

                lastAdDate:
                  transactionToday,

                lastAdRewardAt:
                  FieldValue.serverTimestamp(),

                adBoostStartedAt:
                  boostStartedAt,

                adBoostEndsAt:
                  boostEndsAt,

                powerBoostTransactionId:
                  authoritativeTransactionId,

                updatedAt:
                  FieldValue.serverTimestamp(),
              },
              {
                merge: true,
              }
            );

            // ------------------------------------------------
            // CONSUME EXACT POWER BOOST SSV REWARD
            // ------------------------------------------------

            transaction.set(
              rewardSnapshot.ref,
              {
                powerBoostClaimed:
                  true,

                powerBoostClaimedAt:
                  FieldValue.serverTimestamp(),

                powerBoostClaimedBy:
                  uid,

                powerBoostTransactionId:
                  authoritativeTransactionId,

                consumedAt:
                  FieldValue.serverTimestamp(),

                consumedBy:
                  uid,

                rewardConsumed:
                  true,
              },
              {
                merge: true,
              }
            );

            // ------------------------------------------------
            // POWER BOOST HISTORY
            // ------------------------------------------------

            const historyRef =
              getHistoryCollection(uid)
                .doc();

            transaction.set(
              historyRef,
              {
                type:
                  "ad_reward",

                title:
                  "Stella Power Boost 🐱⚡",

                amount: 0,

                adRewardTransactionId:
                  authoritativeTransactionId,

                rewardPurpose:
                  "power_boost",

                adHashRateBonus:
                  AD_HASH_RATE_BONUS,

                boostStartedAt:
                  boostStartedAt,

                boostEndsAt:
                  boostEndsAt,

                boostDurationMs:
                  actualDurationMs,

                miningStartedAt:
                  miningWindow.miningStartedAt,

                miningEndsAt:
                  miningWindow.miningEndsAt,

                miningHashRate:
                  miningHashRate,

                adsToday:
                  newAdsToday,

                maxAdsPerDay:
                  MAX_ADS_PER_DAY,

                createdAt:
                  FieldValue.serverTimestamp(),
              }
            );

            const dailyStatus =
              getDailyStatus(
                data,
                transactionToday
              );

            const effectiveHashRate =
              miningHashRate +
              AD_HASH_RATE_BONUS;

            return {
              success: true,

              boostActive: true,

              active: true,

              alreadyActivated: false,

              adsToday:
                newAdsToday,

              maxAdsPerDay:
                MAX_ADS_PER_DAY,

              adHashRateBonus:
                AD_HASH_RATE_BONUS,

              boostRemainingMs:
                actualDurationMs,

              remainingBoostMs:
                actualDurationMs,

              adBoostDurationMs:
                actualDurationMs,

              configuredBoostDurationMs:
                AD_BOOST_DURATION_MS,

              adBoostStartedAt:
                boostStartedAt.toISOString(),

              adBoostEndsAt:
                boostEndsAt.toISOString(),

              miningStartedAt:
                miningWindow.miningStartedAt.toISOString(),

              miningEndsAt:
                miningWindow.miningEndsAt.toISOString(),

              miningHashRate,

              effectiveHashRate,

              dailyHashRate:
                dailyStatus.dailyHashRate,

              dailyStreak:
                dailyStatus.streak,

              transactionId:
                authoritativeTransactionId,

              rewardConsumed: true,

              message:
                actualDurationMs <
                AD_BOOST_DURATION_MS
                  ? "🐱⚡ Stella Power Boost on aktiivinen louhinnan loppuun asti!"
                  : "🐱⚡ Stella Power Boost on aktiivinen!",
            };
          }
        );
      } catch (error) {
        console.error(
          "powerBoost error:",
          error
        );

        if (
          error instanceof HttpsError
        ) {
          throw error;
        }

        throw new HttpsError(
          "internal",
          "🐱 Power Boostin aktivointi epäonnistui."
        );
      }
    }
  );


// ============================================================
// 📦 EXPORTS
// ============================================================

module.exports = {
  getMiningStatus,
  claimMining,
  powerBoost,
};