
"use strict";

// ============================================================
// 🐱 STELLURIINI - DAILY MINING UTILITIES
// ============================================================
//
// Hanterar:
// - Daglig Hash Rate
// - Daglig Hash Rate-bonus
// - Mining streak
// - Nästa dagliga claim
// - Streakens grace-period
// - Endast en streak-claim per mining-period
//
// ============================================================

const {
  DAILY_HASH_RATE_START,
  DAILY_HASH_RATE_STEP,
  MAX_DAILY_HASH_RATE,
} = require("../../config/miningConfig");

const {
  getMiningWindow,
} = require("./miningWindowUtils");

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
  const day = Math.max(
    1,
    Math.floor(number(streak, 1))
  );

  const start = positive(
    DAILY_HASH_RATE_START,
    1
  );

  const step = Math.max(
    0,
    number(DAILY_HASH_RATE_STEP, 0)
  );

  const maximum = Math.max(
    start,
    positive(MAX_DAILY_HASH_RATE, start)
  );

  const calculated =
    start + (day - 1) * step;

  return Math.min(
    maximum,
    Math.max(start, calculated)
  );
}

function dailyHashRateBonus(streak) {
  return Math.max(
    0,
    dailyHashRate(streak) -
      dailyHashRate(1)
  );
}

function dailyStreak(data) {
  return Math.max(
    0,
    Math.floor(
      number(
        data.dailyStreak ?? data.streak,
        0
      )
    )
  );
}

// ============================================================
// DAILY CLAIM / MINING STREAK
// ============================================================

const MINING_STREAK_GRACE_MS =
  24 * 60 * 60 * 1000;

// ============================================================
// CHECK WHETHER THIS MINING PERIOD WAS ALREADY CLAIMED
// ============================================================
//
// dailyStreakClaimedMiningEndMs tallentaa sen louhintajakson
// päättymisajan, jonka perusteella päiväputki on jo päivitetty.
//
// Sama louhintajakso voidaan kuitata vain kerran.
//
// Uusi louhintajakso saa uuden miningEndMs-arvon.
//
// ============================================================

function wasMiningPeriodAlreadyClaimed(
  data,
  miningEndMs
) {
  const claimedMiningEndMs = number(
    data.dailyStreakClaimedMiningEndMs,
    0
  );

  return (
    claimedMiningEndMs > 0 &&
    claimedMiningEndMs === miningEndMs
  );
}

// ============================================================
// BUILD DAILY CLAIM RESULT
// ============================================================

function buildDailyResult(
  claimedToday,
  streak,
  miningEndMs = null
) {
  const safeStreak = Math.max(
    1,
    Math.floor(number(streak, 1))
  );

  return {
    claimedToday,

    streak: safeStreak,

    dailyHashRate:
      dailyHashRate(safeStreak),

    miningEndMs,
  };
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

  const current = dailyStreak(data);

  const referenceNowMs =
    Number.isFinite(Number(nowMs))
      ? Number(nowMs)
      : Date.now();

  const window = getMiningWindow(data);

  // ==========================================================
  // VALID MINING WINDOW
  // ==========================================================

  if (window.valid) {
    const miningStartMs =
      window.miningStartMs;

    const miningEndMs =
      window.miningEndMs;

    const alreadyClaimedForMining =
      wasMiningPeriodAlreadyClaimed(
        data,
        miningEndMs
      );

    // --------------------------------------------------------
    // ACTIVE MINING
    // --------------------------------------------------------
    //
    // Päiväputki säilyy aktiivisen louhinnan ajan.
    // Uutta Daily Check-Iniä ei voi tehdä vielä.
    //
    // --------------------------------------------------------

    if (
      referenceNowMs >= miningStartMs &&
      referenceNowMs < miningEndMs
    ) {
      return buildDailyResult(
        true,
        Math.max(1, current),
        miningEndMs
      );
    }

    // --------------------------------------------------------
    // MINING END + 24 HOUR GRACE PERIOD
    // --------------------------------------------------------
    //
    // Armonaika alkaa täsmälleen miningEndMs-ajasta.
    //
    // Päiväputki kasvaa vain kerran kyseistä louhintajaksoa
    // kohden.
    //
    // --------------------------------------------------------

    const graceDeadlineMs =
      miningEndMs + MINING_STREAK_GRACE_MS;

    if (
      referenceNowMs >= miningEndMs &&
      referenceNowMs <= graceDeadlineMs
    ) {
      if (alreadyClaimedForMining) {
        return buildDailyResult(
          true,
          Math.max(1, current),
          miningEndMs
        );
      }

      const streak =
        current > 0
          ? current + 1
          : 1;

      return buildDailyResult(
        false,
        streak,
        miningEndMs
      );
    }

    // --------------------------------------------------------
    // GRACE PERIOD EXPIRED
    // --------------------------------------------------------
    //
    // Jos käyttäjä ei tehnyt Check-Iniä armonaikana,
    // päiväputki alkaa uudelleen päivästä 1.
    //
    // Myös tämä nollaus voidaan kuitata vain kerran
    // kyseistä louhintajaksoa kohden.
    //
    // --------------------------------------------------------

    if (
      referenceNowMs > graceDeadlineMs
    ) {
      if (alreadyClaimedForMining) {
        return buildDailyResult(
          true,
          Math.max(1, current),
          miningEndMs
        );
      }

      return buildDailyResult(
        false,
        1,
        miningEndMs
      );
    }
  }

  // ==========================================================
  // FALLBACK WITHOUT VALID MINING WINDOW
  // ==========================================================

  if (last === today) {
    return buildDailyResult(
      true,
      Math.max(1, current)
    );
  }

  const yesterday = new Date(
    `${today}T00:00:00.000Z`
  );

  yesterday.setUTCDate(
    yesterday.getUTCDate() - 1
  );

  const yesterdayString = yesterday
    .toISOString()
    .slice(0, 10);

  const streak =
    last === yesterdayString && current > 0
      ? current + 1
      : 1;

  return buildDailyResult(
    false,
    streak
  );
}

// ============================================================
// NEXT DAILY HASH RATE
// ============================================================

function nextDailyHashRate(
  data,
  today,
  nowMs = Date.now()
) {
  const daily = nextDailyClaim(
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
  const daily = nextDailyClaim(
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
  MINING_STREAK_GRACE_MS,
  dailyHashRate,
  dailyHashRateBonus,
  dailyStreak,
  nextDailyClaim,
  nextDailyHashRate,
  nextDailyStreak,
};
