"use strict";

// ============================================================
// 🐱 STELLURIINI - STELLA MINING FUNCTIONS
// ============================================================
//
// Vastuu:
//
// ⛏️ Mining Start
// 📊 Mining Status
// ⚡ Power Boost
// 🎁 Daily Hash Rate
// 🏆 Mining Achievements
// 📚 Mining History
//
// AdMob SSV -validointi kuuluu:
// services/admobRewardService.js
//
// AdMob reward ei ole STL-tokenipalkkio.
//
// AdMob ainoastaan valtuuttaa:
// - Mining Start
// - Power Boost
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

const {
  getVerifiedMiningStartReward,
  getVerifiedPowerBoostReward,
  validateVerifiedRewardDocument,
} = require("../services/admobRewardService");

// ============================================================
// 🔢 SAFE NUMBERS
// ============================================================

function getSafeNumber(
  value,
  fallback = 0
) {
  const number =
    Number(value);

  return Number.isFinite(number)
    ? number
    : fallback;
}

function getSafeNonNegativeNumber(
  value,
  fallback = 0
) {
  const number =
    Number(value);

  return Number.isFinite(number) &&
    number >= 0
    ? number
    : fallback;
}

function getSafePositiveNumber(
  value,
  fallback = 0
) {
  const number =
    Number(value);

  return Number.isFinite(number) &&
    number > 0
    ? number
    : fallback;
}

// ============================================================
// 🕒 TIMESTAMP
// ============================================================

function getTimestampMilliseconds(
  value
) {
  if (!value) {
    return 0;
  }

  if (
    typeof value.toDate ===
    "function"
  ) {
    try {
      const date =
        value.toDate();

      return date instanceof Date &&
        !Number.isNaN(
          date.getTime()
        )
        ? date.getTime()
        : 0;
    } catch (
      error
    ) {
      return 0;
    }
  }

  if (
    value instanceof Date
  ) {
    return Number.isNaN(
      value.getTime()
    )
      ? 0
      : value.getTime();
  }

  if (
    typeof value ===
    "string"
  ) {
    const parsed =
      new Date(value);

    return Number.isNaN(
      parsed.getTime()
    )
      ? 0
      : parsed.getTime();
  }

  if (
    typeof value ===
      "number" &&
    Number.isFinite(value)
  ) {
    return value;
  }

  return 0;
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
      (
        effectiveDay - 1
      ) *
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

function getDailyStreak(
  data
) {
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
    getDailyStreak(
      data
    );

  if (
    lastDailyDate ===
    today
  ) {
    const streak =
      Math.max(
        1,
        currentStreak
      );

    return {
      claimedToday:
        true,

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
      .slice(
        0,
        10
      );

  const newStreak =
    lastDailyDate ===
      yesterdayString &&
    currentStreak > 0
      ? currentStreak + 1
      : 1;

  return {
    claimedToday:
      false,

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

function getMiningWindow(
  data
) {
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

  const miningEndMs =
    miningEndsAt
      ? miningEndsAt.getTime()
      : 0;

  const valid =
    miningStartMs > 0 &&
    miningEndMs >
      miningStartMs;

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
    getMiningWindow(
      data
    );

  return (
    window.valid &&
    nowMs >=
      window.miningStartMs &&
    nowMs <
      window.miningEndMs
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
    getMiningWindow(
      data
    );

  const miningActive =
    miningWindow.valid &&
    nowMs >=
      miningWindow.miningStartMs &&
    nowMs <
      miningWindow.miningEndMs;

  const boostStartedInsideMining =
    miningActive &&
    boostStartedMs >=
      miningWindow.miningStartMs &&
    boostStartedMs <
      miningWindow.miningEndMs;

  const effectiveBoostEndsMs =
    boostStartedInsideMining &&
    boostEndsMs >
      boostStartedMs
      ? Math.min(
          boostEndsMs,
          miningWindow.miningEndMs
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
    stored >=
      DAILY_HASH_RATE_START &&
    stored <=
      MAX_DAILY_HASH_RATE
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

function getHistoricalMiningHashRate(
  data
) {
  const stored =
    getSafePositiveNumber(
      data.miningHashRate,
      0
    );

  if (
    stored <
      DAILY_HASH_RATE_START ||
    stored >
      MAX_DAILY_HASH_RATE
  ) {
    console.warn(
      "🐱 Invalid historical miningHashRate.",
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
          (
            24 *
            60 *
            60 *
            1000
          )
      )
    );

  return Math.max(
    MAX_ADS_PER_DAY,
    (
      (
        cycleDays + 1
      ) *
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
    miningEndMs <=
      miningStartMs
  ) {
    return [];
  }

  const query =
    getHistoryCollection(
      uid
    )
      .where(
        "boostStartedAt",
        ">=",
        new Date(
          miningStartMs
        )
      )
      .where(
        "boostStartedAt",
        "<",
        new Date(
          miningEndMs
        )
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
      ? await transaction.get(
          query
        )
      : await query.get();

  const boosts = [];

  snapshot.forEach(
    (doc) => {
      const data =
        doc.data() ||
        {};

      if (
        data.type !==
          "ad_reward" ||
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
        end <= start ||
        start < miningStartMs ||
        start >= miningEndMs ||
        end <= miningStartMs
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
    }
  );

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
    !Array.isArray(
      boosts
    ) ||
    !miningStartMs ||
    !miningEndMs ||
    miningEndMs <=
      miningStartMs
  ) {
    return 0;
  }

  const intervals =
    boosts
      .map(
        (boost) => {
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

          return end > start
            ? {
                start,
                end,
              }
            : null;
        }
      )
      .filter(Boolean)
      .sort(
        (a, b) =>
          a.start -
          b.start
      );

  if (
    !intervals.length
  ) {
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

  return {
    baseMining,

    adBoostMining,

    boostMilliseconds,

    totalMining:
      Math.max(
        0,
        baseMining +
          adBoostMining
      ),
  };
}

// ============================================================
// 🏆 ACHIEVEMENTS
// ============================================================

function getAchievementCollection(
  uid
) {
  return getUserRef(
    uid
  ).collection(
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
        ? snapshot.data() ||
          {}
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

  if (
    startedMining
  ) {
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

  if (
    collected <= 0
  ) {
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
// 📊 CURRENT UNCLAIMED MINING
// ============================================================

async function calculateCurrentUnclaimedMining(
  uid,
  data,
  nowMs,
  transaction = null
) {
  const miningWindow =
    getMiningWindow(
      data
    );

  if (
    !miningWindow.valid
  ) {
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

  if (
    miningHashRate <= 0
  ) {
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

    async (
      request
    ) => {
      try {
        if (
          !request.auth
        ) {
          throw new HttpsError(
            "unauthenticated",
            "🐱 Kirjaudu sisään jatkaaksesi Stella Miningia."
          );
        }

        const uid =
          request.auth.uid;

        const userRef =
          getUserRef(
            uid
          );

        const snapshot =
          await userRef.get();

        const data =
          snapshot.exists
            ? snapshot.data() ||
              {}
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

        const miningWindow =
          getMiningWindow(
            data
          );

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
          getMiningStartTime(
            data
          );

        const miningEndsAt =
          getMiningEndTime(
            data
          );

        const hasMiningWindow =
          miningStartedAt !==
            null &&
          miningEndsAt !==
            null;

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
            hasMiningWindow
              ? miningStartedAt.toISOString()
              : null,

          miningEndsAt:
            hasMiningWindow
              ? miningEndsAt.toISOString()
              : null,

          miningPerHour,

          miningPerMinute:
            miningPerHour /
            60,

          miningPerSecond:
            miningPerHour /
            3600,

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
      } catch (
        error
      ) {
        console.error(
          "getMiningStatus error:",
          error
        );

        if (
          error instanceof
          HttpsError
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

    async (
      request
    ) => {
      try {
        if (
          !request.auth
        ) {
          throw new HttpsError(
            "unauthenticated",
            "🐱 Kirjaudu sisään aloittaaksesi Stella Miningin."
          );
        }

        const uid =
          request.auth.uid;

        const userRef =
          getUserRef(
            uid
          );

        const requestStartedAtMs =
          Date.now();

        const requestedTransactionId =
          typeof request.data?.adMobTransactionId ===
            "string"
            ? request.data.adMobTransactionId.trim()
            : "";

        const earlyNow =
          new Date();

        const earlyNowMs =
          earlyNow.getTime();

        const earlySnapshot =
          await userRef.get();

        const earlyData =
          earlySnapshot.exists
            ? earlySnapshot.data() ||
              {}
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

            rewardConsumed:
              false,

            message:
              "🐱⛏️ Stella louhii jo STL:ää.",
          };
        }

        const verifiedReward =
          await getVerifiedMiningStartReward(
            uid,
            {
              requestStartedAtMs,

              transactionId:
                requestedTransactionId,
            }
          );

        const transactionId =
          verifiedReward.transactionId;

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
          async (
            transaction
          ) => {
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
                ? userSnapshot.data() ||
                  {}
                : {};

            const currentStreak =
              getDailyStreak(
                data
              );

            const fallbackRate =
              calculateDailyHashRate(
                currentStreak > 0
                  ? currentStreak
                  : 1
              );

            const previousWindow =
              getMiningWindow(
                data
              );

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

                rewardConsumed:
                  false,

                message:
                  "🐱⛏️ Stella louhii jo STL:ää. Mainospalkintoa ei kulutettu.",
              };
            }

            const validatedReward =
              validateVerifiedRewardDocument(
                rewardSnapshot,
                uid,
                "mining_start",
                "miningStartClaimed",
                {
                  referenceNowMs:
                    transactionNowMs,

                  requestStartedAtMs,

                  transactionId,
                }
              );

            const authoritativeTransactionId =
              validatedReward.transactionId;

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
                  "🐱 Edellisen mining-cyclen Hash Rate on virheellinen."
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

            transaction.set(
              userRef,
              {
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
              },
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

              adBoostActive:
                false,

              adBoostRemainingMs:
                0,

              adHashRateBonus:
                AD_HASH_RATE_BONUS,

              effectiveHashRate:
                dailyHashRate,

              adRewardTransactionId:
                authoritativeTransactionId,

              rewardConsumed:
                true,

              message:
                completedPreviousCycle
                  ? `🐱✨ Stella keräsi STL:t ja aloitti uuden louhinnan! ${dailyMessage}`
                  : dailyMessage,
            };
          }
        );
      } catch (
        error
      ) {
        console.error(
          "claimMining error:",
          error
        );

        if (
          error instanceof
          HttpsError
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

    async (
      request
    ) => {
      try {
        if (
          !request.auth
        ) {
          throw new HttpsError(
            "unauthenticated",
            "🐱 Kirjaudu sisään käyttääksesi Power Boostia."
          );
        }

        const uid =
          request.auth.uid;

        const userRef =
          getUserRef(
            uid
          );

        const requestStartedAtMs =
          Date.now();

        const requestedTransactionId =
          typeof request.data?.adMobTransactionId ===
            "string"
            ? request.data.adMobTransactionId.trim()
            : "";

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
            ? earlySnapshot.data() ||
              {}
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

        const earlyHashRate =
          getHistoricalMiningHashRate(
            earlyData
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

        const verifiedReward =
          await getVerifiedPowerBoostReward(
            uid,
            {
              requestStartedAtMs,

              transactionId:
                requestedTransactionId,
            }
          );

        const transactionId =
          verifiedReward.transactionId;

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
          async (
            transaction
          ) => {
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
                ? userSnapshot.data() ||
                  {}
                : {};

            const miningWindow =
              getMiningWindow(
                data
              );

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

            const validatedReward =
              validateVerifiedRewardDocument(
                rewardSnapshot,
                uid,
                "power_boost",
                "powerBoostClaimed",
                {
                  referenceNowMs:
                    transactionNowMs,

                  requestStartedAtMs,

                  transactionId,
                }
              );

            const authoritativeTransactionId =
              validatedReward.transactionId;

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

            const actualEndMs =
              Math.min(
                transactionNowMs +
                  AD_BOOST_DURATION_MS,
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
              actualDurationMs <=
              0
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
                  authoritativeTransactionId,

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
      } catch (
        error
      ) {
        console.error(
          "powerBoost error:",
          error
        );

        if (
          error instanceof
          HttpsError
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