
"use strict";

// ============================================================
// 🐱 STELLURIINI - DAILY MINING SERVICE
// ============================================================
//
// Päivittäisen Hash Raten ja mining streakin laskenta.
//
// Tämä palvelu ei kirjoita Firestoreen.
// ============================================================

const {
  DAILY_HASH_RATE_START,
  DAILY_HASH_RATE_STEP,
  MAX_DAILY_HASH_RATE,
} = require("../config/miningConfig");

const {
  miningWindow,
} = require("./miningCalculationService");

// ============================================================
// CONSTANTS
// ============================================================

const MINING_STREAK_GRACE_MS =
  24 * 60 * 60 * 1000;

// ============================================================
// VALUE HELPERS
// ============================================================

function number(value, fallback = 0) {
  const result = Number(value);

  return Number.isFinite(result)
    ? result
    : fallback;
}

function positive(value, fallback = 0) {
  const result = Number(value);

  return Number.isFinite(result) && result > 0
    ? result
    : fallback;
}

// ============================================================
// DAILY HASH RATE
// ============================================================

function dailyHashRate(streak) {
  const day =
    Math.max(
      1,
      Math.floor(
        number(streak, 1)
      )
    );

  const start =
    positive(
      DAILY_HASH_RATE_START,
      1
    );

  const step =
    Math.max(
      0,
      number(
        DAILY_HASH_RATE_STEP,
        0
      )
    );

  const maximum =
    Math.max(
      start,
      positive(
        MAX_DAILY_HASH_RATE,
        start
      )
    );

  const calculated =
    start +
    (day - 1) * step;

  return Math.min(
    maximum,
    Math.max(
      start,
      calculated
    )
  );
}

// ============================================================
// DAILY HASH RATE BONUS
// ============================================================

function dailyHashRateBonus(streak) {
  return Math.max(
    0,
    dailyHashRate(streak) -
      dailyHashRate(1)
  );
}

// ============================================================
// DAILY STREAK
// ============================================================

function dailyStreak(data) {
  return Math.max(
    0,
    Math.floor(
      number(
        data.dailyStreak ??
          data.streak,
        0
      )
    )
  );
}

// ============================================================
// NEXT DAILY CLAIM
// ============================================================

function nextDailyClaim(
  data,
  today,
  nowMs = Date.now()
) {
  const last =
    typeof data.lastDailyDate === "string"
      ? data.lastDailyDate
      : "";

  const current =
    dailyStreak(data);

  const referenceNowMs =
    Number.isFinite(
      Number(nowMs)
    )
      ? Number(nowMs)
      : Date.now();

  const window =
    miningWindow(data);

  if (window.valid) {
    const miningEndMs =
      window.miningEndMs;

    if (
      referenceNowMs >=
        window.miningStartMs &&
      referenceNowMs <
        miningEndMs
    ) {
      const streak =
        Math.max(
          1,
          current
        );

      return {
        claimedToday: true,
        streak,
        dailyHashRate:
          dailyHashRate(streak),
      };
    }

    const graceDeadlineMs =
      miningEndMs +
      MINING_STREAK_GRACE_MS;

    if (
      referenceNowMs >=
        miningEndMs &&
      referenceNowMs <=
        graceDeadlineMs
    ) {
      const streak =
        current > 0
          ? current + 1
          : 1;

      return {
        claimedToday: false,
        streak,
        dailyHashRate:
          dailyHashRate(streak),
      };
    }

    if (
      referenceNowMs >
      graceDeadlineMs
    ) {
      return {
        claimedToday: false,
        streak: 1,
        dailyHashRate:
          dailyHashRate(1),
      };
    }
  }

  if (last === today) {
    const streak =
      Math.max(
        1,
        current
      );

    return {
      claimedToday: true,
      streak,
      dailyHashRate:
        dailyHashRate(streak),
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

  const streak =
    last === yesterdayString &&
    current > 0
      ? current + 1
      : 1;

  return {
    claimedToday: false,
    streak,
    dailyHashRate:
      dailyHashRate(streak),
  };
}

// ============================================================
// NEXT DAILY HASH RATE
// ============================================================

function nextDailyHashRate(
  data,
  today,
  nowMs = Date.now()
) {
  const daily =
    nextDailyClaim(
      data,
      today,
      nowMs
    );

  if (!daily.claimedToday) {
    return daily.dailyHashRate;
  }

  return dailyHashRate(
    daily.streak + 1
  );
}

// ============================================================
// NEXT DAILY STREAK
// ============================================================

function nextDailyStreak(
  data,
  today,
  nowMs = Date.now()
) {
  const daily =
    nextDailyClaim(
      data,
      today,
      nowMs
    );

  return daily.claimedToday
    ? daily.streak + 1
    : daily.streak;
}

// ============================================================
// EXPORTS
// ============================================================

module.exports = {
  dailyHashRate,
  dailyHashRateBonus,
  dailyStreak,
  nextDailyClaim,
  nextDailyHashRate,
  nextDailyStreak,
};
