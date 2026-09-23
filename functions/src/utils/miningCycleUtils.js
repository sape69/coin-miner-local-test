"use strict";

// ============================================================
// 🐱 STELLURIINI - MINING CYCLE UTILITIES
// ============================================================
//
// Vastuu:
//
// 🎁 Daily Hash Rate
// ⛏️ Mining cycle
// 📊 Mining cycle Hash Rate
// 📺 Ad / Power Boost status
// ⚡ Power Boost -ajan laskenta
// 💰 Current unclaimed mining
//
// Tämä tiedosto EI kirjoita Firestoreen.
// Tämä tiedosto EI muuta käyttäjän saldoa.
// Tämä tiedosto EI käsittele AdMob SSV-validointia.
//
// ============================================================

const {
  DAILY_HASH_RATE_START,
  DAILY_HASH_RATE_STEP,
  DAILY_HASH_RATE_MAX_DAY,
  MAX_DAILY_HASH_RATE,
  AD_HASH_RATE_BONUS,
  AD_BOOST_DURATION_MS,
  MAX_ADS_PER_DAY,
  AD_COOLDOWN_MS,
} = require("../config/miningConfig");

const {
  getUtcDateString,
} = require("./dateUtils");

const {
  getHistoryCollection,
} = require("./userUtils");

const {
  calculateMining,
  getMiningStartTime,
  getMiningEndTime,
} = require("./miningUtils");

// ============================================================
// 🔢 SAFE VALUES
// ============================================================

function getSafeNumber(
  value,
  fallback = 0
) {
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

  return Number.isFinite(number) &&
    number >= 0
    ? number
    : fallback;
}

function getSafePositiveNumber(
  value,
  fallback = 0
) {
  const number = Number(value);

  return Number.isFinite(number) &&
    number > 0
    ? number
    : fallback;
}

// ============================================================
// 🕒 TIMESTAMP
// ============================================================

function getTimestampMs(value) {
  if (!value) {
    return 0;
  }

  if (
    typeof value.toDate === "function"
  ) {
    try {
      const date = value.toDate();

      return date instanceof Date &&
        Number.isFinite(date.getTime())
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
// 🎁 DAILY HASH RATE
// ============================================================

function calculateDailyHashRate(
  streak
) {
  const safeStreak = Math.max(
    1,
    Math.floor(
      getSafeNumber(
        streak,
        1
      )
    )
  );

  const effectiveDay = Math.min(
    safeStreak,
    Math.max(
      1,
      Math.floor(
        getSafeNumber(
          DAILY_HASH_RATE_MAX_DAY,
          1
        )
      )
    )
  );

  const calculated =
    DAILY_HASH_RATE_START +
    (
      effectiveDay - 1
    ) *
      DAILY_HASH_RATE_STEP;

  return Math.min(
    MAX_DAILY_HASH_RATE,
    Math.max(
      DAILY_HASH_RATE_START,
      getSafeNonNegativeNumber(
        calculated,
        DAILY_HASH_RATE_START
      )
    )
  );
}

// ============================================================
// 🔢 DAILY STREAK
// ============================================================

function getDailyStreak(
  data
) {
  if (
    !data ||
    typeof data !== "object"
  ) {
    return 0;
  }

  return Math.max(
    0,
    Math.floor(
      getSafeNumber(
        data.dailyStreak ??
          data.streak,
        0
      )
    )
  );
}

// ============================================================
// 🎁 DAILY STATUS
// ============================================================

function getDailyStatus(
  data,
  today
) {
  const safeData =
    data &&
    typeof data === "object"
      ? data
      : {};

  const lastDailyDate =
    typeof safeData.lastDailyDate ===
    "string"
      ? safeData.lastDailyDate
      : "";

  const currentStreak =
    getDailyStreak(
      safeData
    );

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

  let yesterdayString = "";

  if (
    typeof today === "string" &&
    /^\d{4}-\d{2}-\d{2}$/.test(today)
  ) {
    const yesterday =
      new Date(
        `${today}T00:00:00.000Z`
      );

    yesterday.setUTCDate(
      yesterday.getUTCDate() - 1
    );

    yesterdayString =
      yesterday
        .toISOString()
        .slice(0, 10);
  }

  const streak =
    lastDailyDate ===
      yesterdayString &&
    currentStreak > 0
      ? currentStreak + 1
      : 1;

  return {
    claimedToday: false,
    streak,
    dailyHashRate:
      calculateDailyHashRate(
        streak
      ),
  };
}

// ============================================================
// ⛏️ MINING WINDOW
// ============================================================

function getMiningWindow(
  data
) {
  const start =
    getMiningStartTime(
      data
    );

  const end =
    getMiningEndTime(
      data
    );

  const startMs =
    start?.getTime() || 0;

  const endMs =
    end?.getTime() || 0;

  const valid =
    startMs > 0 &&
    endMs > startMs;

  return {
    valid,

    miningStartedAt:
      valid
        ? start
        : null,

    miningEndsAt:
      valid
        ? end
        : null,

    miningStartMs:
      valid
        ? startMs
        : 0,

    miningEndMs:
      valid
        ? endMs
        : 0,
  };
}

// ============================================================
// ⛏️ MINING ACTIVE
// ============================================================

function isMiningActive(
  data,
  nowMs = Date.now()
) {
  const window =
    getMiningWindow(
      data
    );

  const currentMs =
    getSafeNumber(
      nowMs,
      Date.now()
    );

  return (
    window.valid &&
    currentMs >=
      window.miningStartMs &&
    currentMs <
      window.miningEndMs
  );
}

// ============================================================
// 📈 CURRENT MINING HASH RATE
// ============================================================

function getMiningHashRate(
  data,
  fallback = DAILY_HASH_RATE_START
) {
  if (
    !data ||
    typeof data !== "object"
  ) {
    return Math.min(
      MAX_DAILY_HASH_RATE,
      Math.max(
        DAILY_HASH_RATE_START,
        getSafePositiveNumber(
          fallback,
          DAILY_HASH_RATE_START
        )
      )
    );
  }

  const stored =
    getSafePositiveNumber(
      data.miningHashRate
    );

  if (
    stored >= DAILY_HASH_RATE_START &&
    stored <= MAX_DAILY_HASH_RATE
  ) {
    return stored;
  }

  return Math.min(
    MAX_DAILY_HASH_RATE,
    Math.max(
      DAILY_HASH_RATE_START,
      getSafePositiveNumber(
        fallback,
        DAILY_HASH_RATE_START
      )
    )
  );
}

// ============================================================
// 📜 HISTORICAL MINING HASH RATE
// ============================================================
//
// Käytetään olemassa olevan mining-cyclen laskemiseen.
//
// Vanha cycle ei saa periä uutta Daily Hash Ratea.
//
// ============================================================

function getHistoricalMiningHashRate(
  data
) {
  if (
    !data ||
    typeof data !== "object"
  ) {
    return 0;
  }

  const rate =
    getSafePositiveNumber(
      data.miningHashRate
    );

  return rate >=
    DAILY_HASH_RATE_START &&
    rate <=
      MAX_DAILY_HASH_RATE
    ? rate
    : 0;
}

// ============================================================
// 📺 AD STATUS
// ============================================================

function getAdStatus(
  data,
  nowMs,
  today
) {
  const safeData =
    data &&
    typeof data === "object"
      ? data
      : {};

  const currentMs =
    getSafeNumber(
      nowMs,
      Date.now()
    );

  const currentDate =
    typeof today === "string" &&
    today.length > 0
      ? today
      : getUtcDateString(
          new Date(currentMs)
        );

  // ----------------------------------------------------------
  // ADS TODAY
  // ----------------------------------------------------------

  const lastAdDate =
    typeof safeData.lastAdDate ===
    "string"
      ? safeData.lastAdDate
      : "";

  const adsToday =
    lastAdDate === currentDate
      ? Math.max(
          0,
          Math.floor(
            getSafeNumber(
              safeData.adsToday,
              0
            )
          )
        )
      : 0;

  // ----------------------------------------------------------
  // COOLDOWN
  // ----------------------------------------------------------

  const lastRewardMs =
    getTimestampMs(
      safeData.lastAdRewardAt
    );

  const cooldownRemainingMs =
    lastRewardMs > 0
      ? Math.max(
          0,
          lastRewardMs +
            AD_COOLDOWN_MS -
            currentMs
        )
      : 0;

  // ----------------------------------------------------------
  // BOOST
  // ----------------------------------------------------------

  const boostStartMs =
    getTimestampMs(
      safeData.adBoostStartedAt
    );

  const boostEndMs =
    getTimestampMs(
      safeData.adBoostEndsAt
    );

  const miningWindow =
    getMiningWindow(
      safeData
    );

  const miningActive =
    miningWindow.valid &&
    currentMs >=
      miningWindow.miningStartMs &&
    currentMs <
      miningWindow.miningEndMs;

  // ----------------------------------------------------------
  // BOOST MUST BELONG TO CURRENT MINING CYCLE
  // ----------------------------------------------------------

  const boostInsideMining =
    miningActive &&
    boostStartMs >=
      miningWindow.miningStartMs &&
    boostStartMs <
      miningWindow.miningEndMs;

  const effectiveBoostEndMs =
    boostInsideMining &&
    boostEndMs > boostStartMs
      ? Math.min(
          boostEndMs,
          miningWindow.miningEndMs
        )
      : 0;

  const adBoostActive =
    miningActive &&
    effectiveBoostEndMs >
      currentMs;

  // ----------------------------------------------------------
  // RESULT
  // ----------------------------------------------------------

  return {
    adsToday,

    maxAdsPerDay:
      MAX_ADS_PER_DAY,

    cooldownRemainingMs,

    canWatchAd:
      miningActive &&
      adsToday <
        MAX_ADS_PER_DAY &&
      cooldownRemainingMs === 0 &&
      !adBoostActive,

    adBoostActive,

    adBoostRemainingMs:
      adBoostActive
        ? effectiveBoostEndMs -
          currentMs
        : 0,

    adBoostStartedAt:
      adBoostActive
        ? new Date(
            boostStartMs
          )
        : null,

    adBoostEndsAt:
      adBoostActive
        ? new Date(
            effectiveBoostEndMs
          )
        : null,
  };
}

// ============================================================
// 📜 BOOST HISTORY LIMIT
// ============================================================

function getMaxBoostHistoryEntries() {
  const miningDays =
    Math.max(
      1,
      Math.ceil(
        24
      )
    );

  return Math.max(
    MAX_ADS_PER_DAY,
    (
      miningDays + 1
    ) *
      MAX_ADS_PER_DAY +
      10
  );
}

// ============================================================
// 📜 GET BOOST HISTORY
// ============================================================

async function getAdBoostHistory(
  uid,
  startMs,
  endMs,
  transaction = null
) {
  if (
    !uid ||
    !startMs ||
    !endMs ||
    endMs <= startMs
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
        new Date(startMs)
      )
      .where(
        "boostStartedAt",
        "<",
        new Date(endMs)
      )
      .orderBy(
        "boostStartedAt",
        "asc"
      )
      .limit(
        getMaxBoostHistoryEntries()
      );

  const snapshot =
    transaction
      ? await transaction.get(
          query
        )
      : await query.get();

  const boosts = [];

  snapshot.forEach(
    (document) => {
      const data =
        document.data() ||
        {};

      if (
        data.type !==
          "ad_reward" ||
        data.rewardPurpose !==
          "power_boost"
      ) {
        return;
      }

      const boostStartedMs =
        getTimestampMs(
          data.boostStartedAt
        );

      const boostEndsMs =
        getTimestampMs(
          data.boostEndsAt
        );

      if (
        boostStartedMs <= 0 ||
        boostEndsMs <=
          boostStartedMs ||
        boostStartedMs >=
          endMs ||
        boostEndsMs <=
          startMs
      ) {
        return;
      }

      boosts.push({
        boostStartedMs:
          Math.max(
            startMs,
            boostStartedMs
          ),

        boostEndsMs:
          Math.min(
            endMs,
            boostEndsMs
          ),
      });
    }
  );

  return boosts;
}

// ============================================================
// ⚡ BOOST MILLISECONDS
// ============================================================
//
// Yhdistää päällekkäiset Boost-jaksot.
// Sama aika lasketaan vain kerran.
//
// ============================================================

function calculateBoostMilliseconds(
  boosts,
  startMs,
  endMs
) {
  if (
    !Array.isArray(boosts) ||
    !startMs ||
    !endMs ||
    endMs <= startMs
  ) {
    return 0;
  }

  const intervals =
    boosts
      .map(
        (boost) => {
          const start =
            Math.max(
              startMs,
              getSafeNumber(
                boost.boostStartedMs
              )
            );

          const end =
            Math.min(
              endMs,
              getSafeNumber(
                boost.boostEndsMs
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
    intervals.length === 0
  ) {
    return 0;
  }

  let total = 0;

  let currentStart =
    intervals[0].start;

  let currentEnd =
    intervals[0].end;

  for (
    let index = 1;
    index <
      intervals.length;
    index++
  ) {
    const current =
      intervals[index];

    if (
      current.start <=
      currentEnd
    ) {
      currentEnd =
        Math.max(
          currentEnd,
          current.end
        );
    } else {
      total +=
        currentEnd -
        currentStart;

      currentStart =
        current.start;

      currentEnd =
        current.end;
    }
  }

  total +=
    currentEnd -
    currentStart;

  return Math.max(
    0,
    total
  );
}

// ============================================================
// 💰 CURRENT UNCLAIMED MINING
// ============================================================

async function calculateCurrentUnclaimedMining(
  uid,
  data,
  nowMs,
  transaction = null
) {
  const window =
    getMiningWindow(
      data
    );

  if (
    !window.valid
  ) {
    return {
      unclaimedMining: 0,
      baseMining: 0,
      adBoostMining: 0,
      boostMilliseconds: 0,
    };
  }

  const currentMs =
    getSafeNumber(
      nowMs,
      Date.now()
    );

  const endMs =
    Math.min(
      window.miningEndMs,
      currentMs
    );

  if (
    endMs <=
    window.miningStartMs
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

  const elapsedMs =
    endMs -
    window.miningStartMs;

  // ----------------------------------------------------------
  // BASE MINING
  // ----------------------------------------------------------

  const baseMining =
    Math.max(
      0,
      getSafeNonNegativeNumber(
        calculateMining(
          miningHashRate,
          elapsedMs
        ),
        0
      )
    );

  // ----------------------------------------------------------
  // BOOST HISTORY
  // ----------------------------------------------------------

  const boosts =
    await getAdBoostHistory(
      uid,
      window.miningStartMs,
      endMs,
      transaction
    );

  const boostMilliseconds =
    calculateBoostMilliseconds(
      boosts,
      window.miningStartMs,
      endMs
    );

  // ----------------------------------------------------------
  // AD BOOST MINING
  // ----------------------------------------------------------

  const adBoostMining =
    boostMilliseconds > 0 &&
    AD_HASH_RATE_BONUS > 0
      ? Math.max(
          0,
          getSafeNonNegativeNumber(
            calculateMining(
              AD_HASH_RATE_BONUS,
              boostMilliseconds
            ),
            0
          )
        )
      : 0;

  const unclaimedMining =
    Math.max(
      0,
      baseMining +
        adBoostMining
    );

  return {
    unclaimedMining,

    baseMining,

    adBoostMining,

    boostMilliseconds,
  };
}

// ============================================================
// 📦 EXPORTS
// ============================================================

module.exports = {
  getSafeNumber,
  getSafeNonNegativeNumber,

  calculateDailyHashRate,
  getDailyStreak,
  getDailyStatus,

  getMiningWindow,
  isMiningActive,

  getMiningHashRate,
  getHistoricalMiningHashRate,

  getAdStatus,

  getAdBoostHistory,
  calculateBoostMilliseconds,

  calculateCurrentUnclaimedMining,
};