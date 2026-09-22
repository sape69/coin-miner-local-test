"use strict";

// ============================================================
// 🐱 STELLA MINING FUNCTIONS
// ============================================================
//
// ⛏️ Stella Mining
// 🎁 Daily Hash Rate
// 📺 Stella Power Boost
// 🔐 AdMob SSV verification
// 🏆 Stella Achievements
// 📜 Mining history
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
// - miningHashRate belongs ONLY to the current cycle.
// - A new cycle receives the current Daily Hash Rate.
// - An old cycle can never inherit a new cycle's Hash Rate.
//
// POWER BOOST:
//
// - Only active while mining is active.
// - Never continues after miningEndsAt.
// - Never carries into a new mining cycle.
// - Boost history is used for actual mining calculations.
// - Overlapping boost intervals are merged.
//
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
// 🔐 REWARD CREATION TIME
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
// 🎁 EXPECTED REWARD CONFIGURATION
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
// 🔐 FIND VERIFIED ADMOB REWARD
// ============================================================
//
// The server searches rewards belonging to the authenticated
// user and the requested purpose.
//
// A reward must pass ALL local validation rules before it can
// be returned as usable.
//
// ============================================================

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

  const snapshot =
    await db
      .collection("admobRewards")
      .where(
        "uid",
        "==",
        uid
      )
      .where(
        "rewardPurpose",
        "==",
        rewardPurpose
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
      rewardData.uid !== uid
    ) {
      return;
    }

    if (
      rewardData.rewardType !==
      "admob"
    ) {
      return;
    }

    if (
      rewardData.rewardPurpose !==
      rewardPurpose
    ) {
      return;
    }

    if (
      rewardData.rewardConsumed === true
    ) {
      return;
    }

    if (
      rewardData[claimedField] === true
    ) {
      return;
    }

    if (
      rewardPurpose === "mining_start" &&
      (
        rewardData.miningClaimed === true ||
        rewardData.miningStartClaimed === true ||
        rewardData.miningStartClaimedAt
      )
    ) {
      return;
    }

    if (
      rewardPurpose === "power_boost" &&
      (
        rewardData.powerBoostClaimed === true ||
        rewardData.powerBoostClaimedAt
      )
    ) {
      return;
    }

    if (
      typeof rewardData.adUnit !==
      "string"
    ) {
      return;
    }

    const adUnit =
      rewardData.adUnit.trim();

    if (
      adUnit !==
        configuration.rewardedAdUnitId &&
      adUnit !==
        configuration.ssvAdUnitId
    ) {
      return;
    }

    if (
      typeof rewardData.rewardItem !==
      "string"
    ) {
      return;
    }

    const rewardItem =
      rewardData.rewardItem.trim();

    if (
      !rewardItem ||
      rewardItem !==
        configuration.rewardItem
    ) {
      return;
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
        configuration.rewardAmount
    ) {
      return;
    }

    const transactionId =
      validateAdMobTransactionId(
        doc.id
      );

    if (!transactionId) {
      return;
    }

    if (
      rewardData.transactionId &&
      String(
        rewardData.transactionId
      ) !== transactionId
    ) {
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
  110 * 1000;

const ADMOB_SSV_POLL_INTERVAL_MS =
  2 * 1000;


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

    await new Promise(
      (resolve) => {
        setTimeout(
          resolve,
          ADMOB_SSV_POLL_INTERVAL_MS
        );
      }
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
// 🔐 VALIDATE VERIFIED REWARD
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
    rewardData.rewardConsumed === true
  ) {
    throw new HttpsError(
      "already-exists",
      "🐱 Tämä AdMob-palkinto on jo käytetty."
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
      configuration.rewardAmount
  ) {
    throw new HttpsError(
      "failed-precondition",
      "🐱 AdMob-palkinnon määrä ei ole kelvollinen."
    );
  }

  const transactionId =
    validateAdMobTransactionId(
      rewardSnapshot.id
    );

  if (!transactionId) {
    throw new HttpsError(
      "failed-precondition",
      "🐱 AdMob transaction_id ei ole kelvollinen."
    );
  }

  if (
    rewardData.transactionId &&
    String(
      rewardData.transactionId
    ) !== transactionId
  ) {
    throw new HttpsError(
      "failed-precondition",
      "🐱 AdMob transaction_id ei täsmää."
    );
  }

  if (
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

  return rewardData;
}


async function getVerifiedMiningStartReward(
  uid
) {
  return waitForVerifiedAdMobReward(
    uid,
    "mining_start",
    "miningStartClaimed"
  );
}


async function getVerifiedPowerBoostReward(
  uid
) {
  return waitForVerifiedAdMobReward(
    uid,
    "power_boost",
    "powerBoostClaimed"
  );
}


// ============================================================
// 🎁 DAILY HASH RATE
// ============================================================

function calculateDailyHashRate(
  streak
) {
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
    yesterday.getUTCDate() -
      1
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


// ============================================================
// 📊 DAILY STATUS
// ============================================================

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
// 📺 AD STATUS
// ============================================================
//
// Active Boost is valid only if:
//
// 1. Mining is active.
// 2. Boost started inside the current mining cycle.
// 3. Boost end is after boost start.
// 4. Effective end is capped to miningEndsAt.
//
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

  const miningStartedAt =
    getMiningStartTime(data);

  const miningEndsAt =
    getMiningEndTime(data);

  const miningStartedMs =
    miningStartedAt
      ? miningStartedAt.getTime()
      : 0;

  const miningEndsMs =
    miningEndsAt
      ? miningEndsAt.getTime()
      : 0;

  const miningActive =
    miningStartedMs > 0 &&
    miningEndsMs >
      miningStartedMs &&
    nowMs >= miningStartedMs &&
    nowMs < miningEndsMs;

  const boostStartedInsideMining =
    miningActive &&
    boostStartedMs >=
      miningStartedMs &&
    boostStartedMs <
      miningEndsMs;

  const effectiveBoostEndsMs =
    boostStartedInsideMining &&
    boostEndsMs >
      boostStartedMs
      ? Math.min(
          boostEndsMs,
          miningEndsMs
        )
      : 0;

  const adBoostActive =
    miningActive &&
    boostStartedInsideMining &&
    effectiveBoostEndsMs >
      nowMs;

  const adBoostRemainingMs =
    adBoostActive
      ? Math.max(
          0,
          effectiveBoostEndsMs -
            nowMs
        )
      : 0;

  const canWatchAd =
    miningActive &&
    adsToday <
      MAX_ADS_PER_DAY &&
    cooldownRemainingMs ===
      0 &&
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
        ? new Date(
            boostStartedMs
          )
        : null,

    adBoostEndsAt:
      adBoostActive
        ? new Date(
            effectiveBoostEndsMs
          )
        : null,
  };
}


// ============================================================
// ⛏️ MINING HASH RATE
// ============================================================
//
// miningHashRate = current mining cycle's base Hash Rate.
//
// It must NEVER contain AD_HASH_RATE_BONUS.
//
// Power Boost is always calculated separately.
//
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

  const fallback =
    Math.min(
      MAX_DAILY_HASH_RATE,
      Math.max(
        DAILY_HASH_RATE_START,
        getSafePositiveNumber(
          fallbackHashRate,
          DAILY_HASH_RATE_START
        )
      )
    );

  if (
    stored <
      DAILY_HASH_RATE_START ||
    stored >
      MAX_DAILY_HASH_RATE
  ) {
    return fallback;
  }

  return stored;
}


// ============================================================
// 📺 BOOST HISTORY
// ============================================================
//
// Only history belonging to the CURRENT mining cycle can
// contribute to the current cycle.
//
// Old boosts therefore cannot leak into a new cycle.
//
// ============================================================

async function getAdBoostHistory(
  uid,
  miningStartMs,
  miningEndMs,
  transaction = null
) {
  if (
    !miningStartMs ||
    !miningEndMs ||
    miningEndMs <=
      miningStartMs
  ) {
    return [];
  }

  // We query only by rewardPurpose here.
  // type is still validated below.
  //
  // This keeps the query simpler while preserving the
  // server-side validation of the actual history record.

  const query =
    getHistoryCollection(uid)
      .where(
        "rewardPurpose",
        "==",
        "power_boost"
      );

  const snapshot =
    transaction
      ? await transaction.get(
          query
        )
      : await query.get();

  const boosts = [];

  snapshot.forEach(
    (doc) => {
      const data =
        doc.data() || {};

      if (
        data.type !==
        "ad_reward"
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
        end <= miningStartMs ||
        start >= miningEndMs
      ) {
        return;
      }

      boosts.push({
        boostStartedMs:
          start,

        boostEndsMs:
          end,
      });
    }
  );

  return boosts;
}


// ============================================================
// ⚡ CALCULATE BOOST TIME
// ============================================================
//
// Overlapping intervals are merged.
//
// This prevents the same second from being rewarded twice
// if two Boost records overlap.
//
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
    miningEndMs <=
      miningStartMs
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
      interval.start <=
      currentEnd
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
//
// Base mining:
//
//   miningHashRate
//   × MINING_PER_HASH_PER_HOUR
//   × elapsed hours
//
// Boost mining:
//
//   AD_HASH_RATE_BONUS
//   × MINING_PER_HASH_PER_HOUR
//   × boost hours
//
// Both calculations are independent.
//
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
    miningEndMs <=
      miningStartMs
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
      DAILY_HASH_RATE_START
    );

  const durationMs =
    Math.max(
      0,
      miningEndMs -
        miningStartMs
    );

  const baseMining =
    Math.max(
      0,
      getSafeNumber(
        calculateMining(
          safeHashRate,
          durationMs
        ),
        0
      )
    );

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
    Math.max(
      0,
      getSafeNumber(
        calculateMining(
          AD_HASH_RATE_BONUS,
          boostMilliseconds
        ),
        0
      )
    );

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

function getAchievementCollection(
  uid
) {
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
    getAchievementCollection(
      uid
    ).doc(
      achievementId
    );

  const snapshot =
    await transaction.get(
      ref
    );

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
    existingData.unlocked ===
    true;

  const unlocked =
    alreadyUnlocked ||
    (
      safeTarget > 0 &&
      safeProgress >=
        safeTarget
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
          getUtcDateString(
            now
          );

        const dailyStatus =
          getDailyStatus(
            data,
            today
          );

        const miningHashRate =
          getMiningHashRate(
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

        const miningStartedAt =
          getMiningStartTime(
            data
          );

        const miningEndsAt =
          getMiningEndTime(
            data
          );

        let unclaimedMining = 0;

        let baseMining = 0;

        let adBoostMining = 0;

        let boostMilliseconds = 0;

        if (
          miningStartedAt &&
          miningEndsAt
        ) {
          const miningStartMs =
            miningStartedAt.getTime();

          const miningCycleEndMs =
            miningEndsAt.getTime();

          const calculationEndMs =
            Math.min(
              miningCycleEndMs,
              nowMs
            );

          if (
            calculationEndMs >
            miningStartMs
          ) {
            const cycle =
              await calculateMiningCycle(
                uid,
                miningStartMs,
                calculationEndMs,
                miningHashRate
              );

            baseMining =
              cycle.baseMining;

            adBoostMining =
              cycle.adBoostMining;

            boostMilliseconds =
              cycle.boostMilliseconds;

            unclaimedMining =
              Math.max(
                0,
                cycle.totalMining
              );
          }
        }

        const adStatus =
          getAdStatus(
            data,
            nowMs,
            today
          );

        const estimatedTotal =
          miningBalance +
          unclaimedMining;

        const effectiveHashRate =
          adStatus.adBoostActive
            ? miningHashRate +
              AD_HASH_RATE_BONUS
            : miningHashRate;

        const miningPerHour =
          effectiveHashRate *
          MINING_PER_HASH_PER_HOUR;

        const activeMiningPerHour =
          miningHashRate *
          MINING_PER_HASH_PER_HOUR;

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

          miningHashRate,

          miningBalance,

          unclaimedMining,

          baseMining,

          adBoostMining,

          boostMilliseconds,

          estimatedTotal,

          miningActive:
            miningStatus.miningActive ===
            true,

          miningFinished:
            miningStatus.miningFinished ===
            true,

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
            miningStartedAt
              ? miningStartedAt.toISOString()
              : null,

          miningEndsAt:
            miningEndsAt
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

        const earlyDailyStatus =
          getDailyStatus(
            earlyData,
            getUtcDateString(
              earlyNow
            )
          );

        const earlyMiningHashRate =
          getMiningHashRate(
            earlyData,
            earlyDailyStatus.dailyHashRate
          );

        const earlyStatus =
          calculateMiningStatus(
            {
              ...earlyData,

              hashRate:
                earlyMiningHashRate,
            },
            earlyNow
          );

        if (
          earlyStatus.miningActive
        ) {
          let earlyUnclaimedMining =
            0;

          let earlyBaseMining = 0;

          let earlyAdBoostMining = 0;

          let earlyBoostMilliseconds = 0;

          const earlyStart =
            getMiningStartTime(
              earlyData
            );

          const earlyEnd =
            getMiningEndTime(
              earlyData
            );

          if (
            earlyStart &&
            earlyEnd
          ) {
            const earlyStartMs =
              earlyStart.getTime();

            const earlyCalculationEndMs =
              Math.min(
                earlyEnd.getTime(),
                earlyNowMs
              );

            if (
              earlyCalculationEndMs >
              earlyStartMs
            ) {
              const cycle =
                await calculateMiningCycle(
                  uid,
                  earlyStartMs,
                  earlyCalculationEndMs,
                  earlyMiningHashRate
                );

              earlyBaseMining =
                cycle.baseMining;

              earlyAdBoostMining =
                cycle.adBoostMining;

              earlyBoostMilliseconds =
                cycle.boostMilliseconds;

              earlyUnclaimedMining =
                Math.max(
                  0,
                  cycle.totalMining
                );
            }
          }

          return {
            success: true,

            started: false,

            collected: 0,

            miningActive:
              true,

            hashRate:
              earlyMiningHashRate,

            miningHashRate:
              earlyMiningHashRate,

            dailyHashRate:
              earlyDailyStatus.dailyHashRate,

            dailyStreak:
              earlyDailyStatus.streak,

            streak:
              earlyDailyStatus.streak,

            unclaimedMining:
              earlyUnclaimedMining,

            baseMining:
              earlyBaseMining,

            adBoostMining:
              earlyAdBoostMining,

            boostMilliseconds:
              earlyBoostMilliseconds,

            miningRemainingMs:
              Math.max(
                0,
                getSafeNumber(
                  earlyStatus.miningRemainingMs,
                  0
                )
              ),

            rewardConsumed:
              false,

            message:
              "🐱⛏️ Stella louhii jo STL:ää.",
          };
        }

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

            const existingHashRate =
              getMiningHashRate(
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

            if (
              existingStatus.miningActive
            ) {
              let currentUnclaimedMining =
                0;

              let currentBaseMining = 0;

              let currentAdBoostMining = 0;

              let currentBoostMilliseconds = 0;

              const currentStart =
                getMiningStartTime(
                  data
                );

              const currentEnd =
                getMiningEndTime(
                  data
                );

              if (
                currentStart &&
                currentEnd
              ) {
                const currentStartMs =
                  currentStart.getTime();

                const currentEndCalculationMs =
                  Math.min(
                    currentEnd.getTime(),
                    transactionNowMs
                  );

                if (
                  currentEndCalculationMs >
                  currentStartMs
                ) {
                  const cycle =
                    await calculateMiningCycle(
                      uid,
                      currentStartMs,
                      currentEndCalculationMs,
                      existingHashRate,
                      transaction
                    );

                  currentBaseMining =
                    cycle.baseMining;

                  currentAdBoostMining =
                    cycle.adBoostMining;

                  currentBoostMilliseconds =
                    cycle.boostMilliseconds;

                  currentUnclaimedMining =
                    Math.max(
                      0,
                      cycle.totalMining
                    );
                }
              }

              return {
                success: true,

                started: false,

                collected: 0,

                miningActive:
                  true,

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
                  currentUnclaimedMining,

                baseMining:
                  currentBaseMining,

                adBoostMining:
                  currentAdBoostMining,

                boostMilliseconds:
                  currentBoostMilliseconds,

                miningRemainingMs:
                  Math.max(
                    0,
                    getSafeNumber(
                      existingStatus.miningRemainingMs,
                      0
                    )
                  ),

                adRewardTransactionId:
                  transactionId,

                rewardConsumed:
                  false,

                message:
                  "🐱⛏️ Stella louhii jo STL:ää. Mainospalkintoa ei kulutettu.",
              };
            }

            validateVerifiedRewardDocument(
              rewardSnapshot,
              uid,
              "mining_start",
              "miningStartClaimed"
            );

            const dailyClaim =
              calculateNextDailyClaim(
                data,
                transactionToday
              );

            const dailyHashRate =
              dailyClaim.dailyHashRate;

            const dailyStreak =
              dailyClaim.streak;

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

            const previousHashRate =
              getMiningHashRate(
                data,
                dailyHashRate
              );

            const previousStart =
              getMiningStartTime(
                data
              );

            const previousEnd =
              getMiningEndTime(
                data
              );

            if (
              previousStart &&
              previousEnd &&
              previousEnd.getTime() <=
                transactionNowMs
            ) {
              const startMs =
                previousStart.getTime();

              const endMs =
                previousEnd.getTime();

              const previousCycle =
                await calculateMiningCycle(
                  uid,
                  startMs,
                  endMs,
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

              if (
                collected > 0
              ) {
                newBalance =
                  oldBalance +
                  collected;

                completedPreviousCycle =
                  true;
              }
            }

            await updateMiningAchievements(
              transaction,
              uid,
              collected,
              true,
              transactionNow
            );

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

            transaction.set(
              rewardRef,
              {
                miningClaimed:
                  true,

                miningClaimedAt:
                  FieldValue.serverTimestamp(),

                miningStartClaimed:
                  true,

                miningStartClaimedAt:
                  FieldValue.serverTimestamp(),

                miningStartClaimedBy:
                  uid,

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

            if (
              !dailyClaim.claimedToday
            ) {
              const historyRef =
                getHistoryCollection(
                  uid
                ).doc();

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

            if (
              completedPreviousCycle
            ) {
              const historyRef =
                getHistoryCollection(
                  uid
                ).doc();

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
                    previousHashRate,

                  miningHashRate:
                    previousHashRate,

                  baseMining:
                    previousBaseMining,

                  adBoostMining:
                    previousAdBoostMining,

                  boostMilliseconds:
                    previousBoostMilliseconds,

                  miningStartedAt:
                    previousStart,

                  miningEndsAt:
                    previousEnd,

                  createdAt:
                    FieldValue.serverTimestamp(),
                }
              );
            }

            const startHistoryRef =
              getHistoryCollection(
                uid
              ).doc();

            transaction.set(
              startHistoryRef,
              {
                type:
                  "mining",

                title:
                  "Stella Mining Started 🐱⛏️",

                amount:
                  0,

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
                  transactionId,

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

              miningActive:
                true,

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

              adBoostActive:
                false,

              adBoostRemainingMs:
                0,

              adHashRateBonus:
                AD_HASH_RATE_BONUS,

              effectiveHashRate:
                dailyHashRate,

              adRewardTransactionId:
                transactionId,

              rewardConsumed:
                true,

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

        const earlyStart =
          getMiningStartTime(
            earlyData
          );

        const earlyEnd =
          getMiningEndTime(
            earlyData
          );

        const earlyStartMs =
          earlyStart
            ? earlyStart.getTime()
            : 0;

        const earlyEndMs =
          earlyEnd
            ? earlyEnd.getTime()
            : 0;

        const earlyMiningActive =
          earlyStartMs > 0 &&
          earlyEndMs >
            earlyStartMs &&
          earlyNowMs >= earlyStartMs &&
          earlyNowMs < earlyEndMs;

        if (
          !earlyMiningActive
        ) {
          throw new HttpsError(
            "failed-precondition",
            "🐱⚡ Power Boostia voi käyttää vain aktiivisen louhinnan aikana."
          );
        }

        const earlyHashRate =
          getMiningHashRate(
            earlyData,
            DAILY_HASH_RATE_START
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

            const miningStartedAt =
              getMiningStartTime(
                data
              );

            const miningEndsAt =
              getMiningEndTime(
                data
              );

            const miningStartMs =
              miningStartedAt
                ? miningStartedAt.getTime()
                : 0;

            const miningEndsMs =
              miningEndsAt
                ? miningEndsAt.getTime()
                : 0;

            const miningActive =
              miningStartMs > 0 &&
              miningEndsMs >
                miningStartMs &&
              transactionNowMs >=
                miningStartMs &&
              transactionNowMs <
                miningEndsMs;

            if (
              !miningActive
            ) {
              throw new HttpsError(
                "failed-precondition",
                "🐱⚡ Power Boostia voi käyttää vain aktiivisen louhinnan aikana."
              );
            }

            const miningHashRate =
              getMiningHashRate(
                data,
                DAILY_HASH_RATE_START
              );

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

            const validatedReward =
              validateVerifiedRewardDocument(
                rewardSnapshot,
                uid,
                "power_boost",
                "powerBoostClaimed"
              );

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

            const boostStartedAt =
              transactionNow;

            const requestedEndMs =
              transactionNowMs +
              AD_BOOST_DURATION_MS;

            const actualEndMs =
              Math.min(
                requestedEndMs,
                miningEndsMs
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
                  transactionId,

                updatedAt:
                  FieldValue.serverTimestamp(),
              },
              {
                merge: true,
              }
            );

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
                  transactionId,

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

            const historyRef =
              getHistoryCollection(
                uid
              ).doc();

            transaction.set(
              historyRef,
              {
                type:
                  "ad_reward",

                title:
                  "Stella Power Boost 🐱⚡",

                amount:
                  0,

                adRewardTransactionId:
                  validatedReward.transactionId ||
                  transactionId,

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
                  miningStartedAt,

                miningEndsAt:
                  miningEndsAt,

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

              boostActive:
                true,

              active:
                true,

              alreadyActivated:
                false,

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
                miningStartedAt.toISOString(),

              miningEndsAt:
                miningEndsAt.toISOString(),

              miningHashRate,

              effectiveHashRate,

              dailyHashRate:
                dailyStatus.dailyHashRate,

              dailyStreak:
                dailyStatus.streak,

              transactionId,

              rewardConsumed:
                true,

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