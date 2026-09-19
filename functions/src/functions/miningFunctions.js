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
// AdMob reward is NOT an STL token reward.
// AdMob only authorizes Mining Start / Power Boost.
//
// POWER BOOST:
// - Only active while mining is active.
// - Never continues after miningEndsAt.
// - Never carries into a new mining cycle.
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

  ADMOB_REWARDED_AD_UNIT_ID,
  ADMOB_SSV_AD_UNIT_ID,
  ADMOB_SSV_REWARD_AMOUNT,
  ADMOB_SSV_REWARD_ITEM,
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


function getSafeNonNegativeNumber(value, fallback = 0) {
  const number = Number(value);

  return Number.isFinite(number) && number >= 0
    ? number
    : fallback;
}


function getSafePositiveNumber(value, fallback = 0) {
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
    const date = value.toDate();

    if (
      date instanceof Date &&
      !Number.isNaN(date.getTime())
    ) {
      return date.getTime();
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
// 🎁 EXPECTED REWARD ITEM
// ============================================================

function getExpectedRewardItem(rewardPurpose) {
  if (rewardPurpose === "power_boost") {
    return ADMOB_SSV_REWARD_ITEM;
  }

  if (rewardPurpose === "mining_start") {
    return ADMOB_SSV_REWARD_ITEM;
  }

  return null;
}


// ============================================================
// 🔐 FIND VERIFIED ADMOB REWARD
// ============================================================

async function findVerifiedAdMobReward(
  uid,
  rewardPurpose,
  claimedField
) {
  const snapshot = await db
    .collection("admobRewards")
    .where("uid", "==", uid)
    .limit(100)
    .get();

  if (snapshot.empty) {
    return null;
  }

  const candidates = [];

  snapshot.forEach((doc) => {
    const rewardData = doc.data() || {};

    if (rewardData.uid !== uid) {
      return;
    }

    if (rewardData.rewardType !== "admob") {
      return;
    }

    if (rewardData.rewardPurpose !== rewardPurpose) {
      return;
    }

    if (rewardData[claimedField] === true) {
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

    if (typeof rewardData.adUnit !== "string") {
      return;
    }

    const adUnit = rewardData.adUnit.trim();

    if (
      adUnit !== ADMOB_REWARDED_AD_UNIT_ID &&
      adUnit !== ADMOB_SSV_AD_UNIT_ID
    ) {
      return;
    }

    if (typeof rewardData.rewardItem !== "string") {
      return;
    }

    const rewardItem = rewardData.rewardItem.trim();

    if (!rewardItem) {
      return;
    }

    const expectedRewardItem =
      getExpectedRewardItem(rewardPurpose);

    if (
      expectedRewardItem &&
      rewardItem !== expectedRewardItem
    ) {
      return;
    }

    const rewardAmount =
      Number(rewardData.rewardAmount);

    if (
      !Number.isFinite(rewardAmount) ||
      rewardAmount !== ADMOB_SSV_REWARD_AMOUNT
    ) {
      return;
    }

    const transactionId =
      validateAdMobTransactionId(doc.id);

    if (!transactionId) {
      return;
    }

    if (
      rewardData.transactionId &&
      String(rewardData.transactionId) !== transactionId
    ) {
      return;
    }

    candidates.push({
      ref: doc.ref,
      data: rewardData,
      transactionId,
      createdAtMs:
        getRewardCreatedAtMs(rewardData),
    });
  });

  if (!candidates.length) {
    return null;
  }

  candidates.sort((a, b) => {
    if (b.createdAtMs !== a.createdAtMs) {
      return b.createdAtMs - a.createdAtMs;
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

const ADMOB_SSV_WAIT_TIMEOUT_MS = 110 * 1000;
const ADMOB_SSV_POLL_INTERVAL_MS = 2 * 1000;


async function waitForVerifiedAdMobReward(
  uid,
  rewardPurpose,
  claimedField
) {
  const startedAt = Date.now();

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
            Date.now() - startedAt,
        }
      );

      return reward;
    }

    await new Promise((resolve) => {
      setTimeout(
        resolve,
        ADMOB_SSV_POLL_INTERVAL_MS
      );
    });
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
  if (!rewardSnapshot.exists) {
    throw new HttpsError(
      "failed-precondition",
      "🐱 AdMob-palkintoa ei enää löytynyt."
    );
  }

  const rewardData =
    rewardSnapshot.data() || {};

  if (rewardData.uid !== uid) {
    throw new HttpsError(
      "permission-denied",
      "🐱 AdMob-palkinnon käyttäjä ei täsmää."
    );
  }

  if (rewardData.rewardType !== "admob") {
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

  if (typeof rewardData.adUnit !== "string") {
    throw new HttpsError(
      "failed-precondition",
      "🐱 AdMob-mainoksen tunnistetiedot puuttuvat."
    );
  }

  const adUnit =
    rewardData.adUnit.trim();

  if (
    adUnit !== ADMOB_REWARDED_AD_UNIT_ID &&
    adUnit !== ADMOB_SSV_AD_UNIT_ID
  ) {
    throw new HttpsError(
      "failed-precondition",
      "🐱 AdMob-mainoksen tunnistetiedot eivät täsmää."
    );
  }

  if (
    typeof rewardData.rewardItem !== "string" ||
    !rewardData.rewardItem.trim()
  ) {
    throw new HttpsError(
      "failed-precondition",
      "🐱 AdMob-palkinnon tiedot puuttuvat."
    );
  }

  const expectedRewardItem =
    getExpectedRewardItem(
      rewardPurpose
    );

  if (
    expectedRewardItem &&
    rewardData.rewardItem.trim() !==
      expectedRewardItem
  ) {
    throw new HttpsError(
      "failed-precondition",
      "🐱 AdMob-palkinnon reward item ei täsmää."
    );
  }

  const rewardAmount =
    Number(rewardData.rewardAmount);

  if (
    !Number.isFinite(rewardAmount) ||
    rewardAmount !== ADMOB_SSV_REWARD_AMOUNT
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
    String(rewardData.transactionId) !==
      transactionId
  ) {
    throw new HttpsError(
      "failed-precondition",
      "🐱 AdMob transaction_id ei täsmää."
    );
  }

  if (rewardData[claimedField] === true) {
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
        getSafeNumber(streak, 1)
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
      getSafeNumber(stored, 0)
    )
  );
}


function getDailyStatus(data, today) {
  const lastDailyDate =
    typeof data.lastDailyDate === "string"
      ? data.lastDailyDate
      : "";

  const dailyClaimed =
    lastDailyDate === today;

  const storedStreak =
    getDailyStreak(data);

  const streak =
    dailyClaimed
      ? Math.max(1, storedStreak)
      : 1;

  return {
    dailyClaimed,

    streak,

    dailyHashRate:
      calculateDailyHashRate(streak),
  };
}


function calculateNextDailyClaim(data, today) {
  const lastDailyDate =
    typeof data.lastDailyDate === "string"
      ? data.lastDailyDate
      : "";

  const currentStreak =
    getDailyStreak(data);

  if (lastDailyDate === today) {
    const streak =
      Math.max(1, currentStreak);

    return {
      claimedToday: true,
      streak,
      dailyHashRate:
        calculateDailyHashRate(streak),
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
    lastDailyDate === yesterdayString &&
    currentStreak > 0
      ? currentStreak + 1
      : 1;

  return {
    claimedToday: false,

    streak: newStreak,

    dailyHashRate:
      calculateDailyHashRate(newStreak),
  };
}


// ============================================================
// 📺 AD STATUS
// ============================================================

function getAdStatus(data, nowMs, today) {
  const storedDate =
    typeof data.lastAdDate === "string"
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
    miningEndsMs > miningStartedMs &&
    nowMs >= miningStartedMs &&
    nowMs < miningEndsMs;

  const boostStartedInsideMining =
    miningActive &&
    boostStartedMs >= miningStartedMs &&
    boostStartedMs < miningEndsMs;

  const effectiveBoostEndsMs =
    boostStartedInsideMining &&
    boostEndsMs > boostStartedMs
      ? Math.min(
          boostEndsMs,
          miningEndsMs
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
          effectiveBoostEndsMs -
            nowMs
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
// ⛏️ MINING HASH RATE
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
    stored < DAILY_HASH_RATE_START ||
    stored > MAX_DAILY_HASH_RATE
  ) {
    return fallback;
  }

  return stored;
}


// ============================================================
// 📺 BOOST HISTORY
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
    miningEndMs <= miningStartMs
  ) {
    return [];
  }

  const query =
    getHistoryCollection(uid)
      .where(
        "type",
        "==",
        "ad_reward"
      );

  const snapshot =
    transaction
      ? await transaction.get(query)
      : await query.get();

  const boosts = [];

  snapshot.forEach((doc) => {
    const data =
      doc.data() || {};

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
      boostStartedMs: start,
      boostEndsMs: end,
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
            boost.boostStartedMs
          );

        const end =
          Math.min(
            miningEndMs,
            boost.boostEndsMs
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
// 🏆 ACHIEVEMENTS
// ============================================================

function getAchievementCollection(uid) {
  return getUserRef(uid)
    .collection("achievements");
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
      Math.floor(
        getSafeNumber(
          existingData.progress,
          0
        )
      )
    );

  const safeTarget =
    Math.max(
      0,
      Math.floor(
        getSafeNumber(target, 0)
      )
    );

  const safeProgress =
    Math.min(
      safeTarget,
      Math.max(
        oldProgress,
        Math.floor(
          getSafeNumber(
            progress,
            0
          )
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
      existingData.rewardClaimed === true,

    updatedAt:
      now,
  };

  if (
    unlocked &&
    !alreadyUnlocked &&
    !existingData.unlockedAt
  ) {
    update.unlockedAt = now;
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
      { merge: true }
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
      Math.floor(littleProgress),
      littleMiner.data,
      now
    ),
    { merge: true }
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
      Math.floor(hunterProgress),
      stlHunter.data,
      now
    ),
    { merge: true }
  );
}


// ============================================================
// 🐱 GET MINING STATUS
// ============================================================

const getMiningStatus = onCall(
  {
    region: "us-central1",
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
        getUtcDateString();

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
        getMiningStartTime(data);

      const miningEndsAt =
        getMiningEndTime(data);

      let unclaimedMining =
        Math.max(
          0,
          getSafeNumber(
            miningStatus.minedAmount,
            0
          )
        );

      let adBoostMining = 0;

      if (
        miningStartedAt &&
        miningEndsAt
      ) {
        const miningStartMs =
          miningStartedAt.getTime();

        const miningEndMs =
          Math.min(
            miningEndsAt.getTime(),
            nowMs
          );

        if (
          miningEndMs >
          miningStartMs
        ) {
          const boosts =
            await getAdBoostHistory(
              uid,
              miningStartMs,
              miningEndMs
            );

          const boostMilliseconds =
            calculateAdBoostMilliseconds(
              boosts,
              miningStartMs,
              miningEndMs
            );

          adBoostMining =
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

          unclaimedMining =
            Math.max(
              0,
              unclaimedMining +
                adBoostMining
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
          dailyStatus.dailyHashRate,

        miningHashRate,

        miningBalance,

        unclaimedMining,

        adBoostMining,

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
          dailyStatus.dailyClaimed,

        streak:
          dailyStatus.streak,

        dailyStreak:
          dailyStatus.streak,

        dailyHashRate:
          dailyStatus.dailyHashRate,

        dailyHashRateBonus:
          dailyStatus.dailyHashRate,

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

const claimMining = onCall(
  {
    region: "us-central1",
    timeoutSeconds: 120,
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

      const now =
        new Date();

      const nowMs =
        now.getTime();

      const today =
        getUtcDateString();

      // --------------------------------------------------------
      // 🛡️ EARLY CHECK
      // --------------------------------------------------------

      const earlySnapshot =
        await userRef.get();

      const earlyData =
        earlySnapshot.exists
          ? earlySnapshot.data() || {}
          : {};

      const earlyStreak =
        getDailyStreak(
          earlyData
        );

      const earlyDailyHashRate =
        calculateDailyHashRate(
          earlyStreak > 0
            ? earlyStreak
            : 1
        );

      const earlyMiningHashRate =
        getMiningHashRate(
          earlyData,
          earlyDailyHashRate
        );

      const earlyStatus =
        calculateMiningStatus(
          {
            ...earlyData,
            hashRate:
              earlyMiningHashRate,
          },
          now
        );

      if (earlyStatus.miningActive) {
        return {
          success: true,
          started: false,
          collected: 0,
          miningActive: true,

          hashRate:
            earlyDailyHashRate,

          miningHashRate:
            earlyMiningHashRate,

          dailyHashRate:
            earlyDailyHashRate,

          dailyStreak:
            earlyStreak,

          streak:
            earlyStreak,

          unclaimedMining:
            Math.max(
              0,
              getSafeNumber(
                earlyStatus.minedAmount,
                0
              )
            ),

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

      // --------------------------------------------------------
      // 🔐 SSV
      // --------------------------------------------------------

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

          // ----------------------------------------------------
          // 🛡️ FINAL ACTIVE CHECK
          // ----------------------------------------------------

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
              now
            );

          if (existingStatus.miningActive) {
            return {
              success: true,
              started: false,
              collected: 0,
              miningActive: true,

              hashRate:
                fallbackRate,

              miningHashRate:
                existingHashRate,

              dailyHashRate:
                fallbackRate,

              dailyStreak:
                currentStreak,

              streak:
                currentStreak,

              unclaimedMining:
                Math.max(
                  0,
                  getSafeNumber(
                    existingStatus.minedAmount,
                    0
                  )
                ),

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

              rewardConsumed: false,

              message:
                "🐱⛏️ Stella louhii jo STL:ää. Mainospalkintoa ei kulutettu.",
            };
          }

          // ----------------------------------------------------
          // 🔐 VALIDATE REWARD
          // ----------------------------------------------------

          validateVerifiedRewardDocument(
            rewardSnapshot,
            uid,
            "mining_start",
            "miningStartClaimed"
          );

          // ----------------------------------------------------
          // 🎁 DAILY
          // ----------------------------------------------------

          const dailyClaim =
            calculateNextDailyClaim(
              data,
              today
            );

          const dailyHashRate =
            dailyClaim.dailyHashRate;

          const dailyStreak =
            dailyClaim.streak;

          // ----------------------------------------------------
          // 💰 BALANCE
          // ----------------------------------------------------

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

          let previousAdBoostMining = 0;

          // ----------------------------------------------------
          // ⛏️ PREVIOUS CYCLE
          // ----------------------------------------------------

          const previousHashRate =
            getMiningHashRate(
              data,
              dailyHashRate
            );

          const previousStart =
            getMiningStartTime(data);

          const previousEnd =
            getMiningEndTime(data);

          if (
            previousStart &&
            previousEnd &&
            previousEnd.getTime() <= nowMs
          ) {
            const startMs =
              previousStart.getTime();

            const endMs =
              previousEnd.getTime();

            const durationMs =
              Math.max(
                0,
                endMs - startMs
              );

            const baseMining =
              Math.max(
                0,
                getSafeNumber(
                  calculateMining(
                    previousHashRate,
                    durationMs
                  ),
                  0
                )
              );

            const boosts =
              await getAdBoostHistory(
                uid,
                startMs,
                endMs,
                transaction
              );

            const boostMs =
              calculateAdBoostMilliseconds(
                boosts,
                startMs,
                endMs
              );

            previousAdBoostMining =
              Math.max(
                0,
                getSafeNumber(
                  calculateMining(
                    AD_HASH_RATE_BONUS,
                    boostMs
                  ),
                  0
                )
              );

            collected =
              Math.max(
                0,
                baseMining +
                  previousAdBoostMining
              );

            if (collected > 0) {
              newBalance =
                oldBalance +
                collected;

              completedPreviousCycle =
                true;
            }
          }

          // ----------------------------------------------------
          // 🏆 ACHIEVEMENTS
          // ----------------------------------------------------

          await updateMiningAchievements(
            transaction,
            uid,
            collected,
            true,
            now
          );

          // ----------------------------------------------------
          // ⛏️ NEW CYCLE
          // ----------------------------------------------------

          const newMiningStartedAt =
            now;

          const newMiningEndsAt =
            new Date(
              nowMs +
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
                      : today
                  )
                : today,

            miningHashRate:
              dailyHashRate,

            miningBalance:
              newBalance,

            miningStartedAt:
              newMiningStartedAt,

            miningEndsAt:
              newMiningEndsAt,

            // --------------------------------------------------
            // 🧹 CLEAR OLD BOOST
            // --------------------------------------------------

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
            { merge: true }
          );

          // ----------------------------------------------------
          // 🔐 CONSUME SSV
          // ----------------------------------------------------

          transaction.set(
            rewardRef,
            {
              miningClaimed: true,

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
            { merge: true }
          );

          // ----------------------------------------------------
          // 🎁 DAILY HISTORY
          // ----------------------------------------------------

          if (!dailyClaim.claimedToday) {
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

          // ----------------------------------------------------
          // 📜 COMPLETED HISTORY
          // ----------------------------------------------------

          if (completedPreviousCycle) {
            const historyRef =
              getHistoryCollection(uid)
                .doc();

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

                baseMining:
                  Math.max(
                    0,
                    getSafeNumber(
                      calculateMining(
                        previousHashRate,
                        Math.max(
                          0,
                          previousEnd.getTime() -
                          previousStart.getTime()
                        )
                      ),
                      0
                    )
                  ),

                adBoostMining:
                  previousAdBoostMining,

                createdAt:
                  FieldValue.serverTimestamp(),
              }
            );
          }

          // ----------------------------------------------------
          // 📜 START HISTORY
          // ----------------------------------------------------

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

              dailyHashRate,

              dailyStreak,

              miningDurationMs:
                MINING_DURATION_MS,

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
              transactionId,

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

const powerBoost = onCall(
  {
    region: "us-central1",
    timeoutSeconds: 120,
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

      const now =
        new Date();

      const nowMs =
        now.getTime();

      const today =
        getUtcDateString();

      // --------------------------------------------------------
      // 👤 EARLY CHECK
      // --------------------------------------------------------

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
        earlyEndMs > earlyStartMs &&
        nowMs >= earlyStartMs &&
        nowMs < earlyEndMs;

      if (!earlyMiningActive) {
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
          now
        );

      if (!earlyStatus.miningActive) {
        throw new HttpsError(
          "failed-precondition",
          "🐱⚡ Stella Mining ei ole aktiivinen."
        );
      }

      const earlyAdStatus =
        getAdStatus(
          earlyData,
          nowMs,
          today
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

      // --------------------------------------------------------
      // 🔐 WAIT FOR SSV
      // --------------------------------------------------------

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

          // ----------------------------------------------------
          // ⛏️ FINAL MINING WINDOW
          // ----------------------------------------------------

          const miningStartedAt =
            getMiningStartTime(data);

          const miningEndsAt =
            getMiningEndTime(data);

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
            miningEndsMs > miningStartMs &&
            nowMs >= miningStartMs &&
            nowMs < miningEndsMs;

          if (!miningActive) {
            throw new HttpsError(
              "failed-precondition",
              "🐱⚡ Power Boostia voi käyttää vain aktiivisen louhinnan aikana."
            );
          }

          // ----------------------------------------------------
          // 🔥 FINAL STATUS
          // ----------------------------------------------------

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
              now
            );

          if (!miningStatus.miningActive) {
            throw new HttpsError(
              "failed-precondition",
              "🐱⚡ Stella Mining ei ole enää aktiivinen."
            );
          }

          // ----------------------------------------------------
          // 🔐 VALIDATE SSV
          // ----------------------------------------------------

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
              nowMs,
              today
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

          if (adStatus.adBoostActive) {
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

          // ----------------------------------------------------
          // 🕒 BOOST
          // ----------------------------------------------------

          const boostStartedAt =
            now;

          const requestedEndMs =
            nowMs +
            AD_BOOST_DURATION_MS;

          const actualEndMs =
            Math.min(
              requestedEndMs,
              miningEndsMs
            );

          const boostEndsAt =
            new Date(actualEndMs);

          const actualDurationMs =
            Math.max(
              0,
              actualEndMs -
                nowMs
            );

          if (
            actualDurationMs <= 0
          ) {
            throw new HttpsError(
              "failed-precondition",
              "🐱⚡ Louhintaa ei ole enää tarpeeksi jäljellä Power Boostia varten."
            );
          }

          // ----------------------------------------------------
          // 📊 DAILY AD COUNT
          // ----------------------------------------------------

          const storedAdDate =
            typeof data.lastAdDate === "string"
              ? data.lastAdDate
              : "";

          const currentAds =
            storedAdDate === today
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

          // ----------------------------------------------------
          // 👤 USER
          // ----------------------------------------------------

          transaction.set(
            userRef,
            {
              adsToday:
                newAdsToday,

              lastAdDate:
                today,

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
            { merge: true }
          );

          // ----------------------------------------------------
          // 🔐 CONSUME SSV
          // ----------------------------------------------------

          transaction.set(
            rewardRef,
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
            { merge: true }
          );

          // ----------------------------------------------------
          // 📜 HISTORY
          // ----------------------------------------------------

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

              adsToday:
                newAdsToday,

              maxAdsPerDay:
                MAX_ADS_PER_DAY,

              createdAt:
                FieldValue.serverTimestamp(),
            }
          );

          // ----------------------------------------------------
          // 📊 EFFECTIVE RATE
          // ----------------------------------------------------

          const dailyStatus =
            getDailyStatus(
              data,
              today
            );

          const baseHashRate =
            getMiningHashRate(
              data,
              dailyStatus.dailyHashRate
            );

          const effectiveHashRate =
            baseHashRate +
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
              miningStartedAt.toISOString(),

            miningEndsAt:
              miningEndsAt.toISOString(),

            effectiveHashRate,

            transactionId,

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