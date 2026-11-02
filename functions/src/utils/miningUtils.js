
"use strict";

// ============================================================
// 🐱 STELLURIINI - MINING UTILITIES
// ============================================================
//
// Keskitetty Mining-laskenta.
//
// Halving perustuu kaikkiin rekisteröityneisiin käyttäjiin.
// Halving-kerroin tallennetaan uuteen mining-jaksoon.
//
// Vanhojen jaksojen laskenta säilyy ennallaan.
//
// ============================================================

const {
  MINING_PER_HASH_PER_HOUR,
  HALVING_ENABLED,
  HALVING_MILESTONES,
} = require("../config/miningConfig");


// ============================================================
// 🔢 SAFE NUMBER
// ============================================================

function getSafeNumber(value, fallback = 0) {
  const number = Number(value);

  return Number.isFinite(number)
    ? number
    : fallback;
}


// ============================================================
// ⚡ SAFE HASH RATE
// ============================================================

function getSafeHashRate(value) {
  const number = Number(value);

  return Number.isFinite(number) && number >= 0
    ? number
    : 0;
}


// ============================================================
// 🕒 SAFE MILLISECONDS
// ============================================================

function getSafeMilliseconds(value) {
  const number = Number(value);

  return Number.isFinite(number) && number >= 0
    ? number
    : 0;
}


// ============================================================
// 📅 SAFE DATE
// ============================================================

function getSafeDate(value) {
  if (
    value === null ||
    value === undefined ||
    value === ""
  ) {
    return null;
  }

  if (value instanceof Date) {
    return Number.isFinite(value.getTime())
      ? new Date(value.getTime())
      : null;
  }

  if (typeof value.toDate === "function") {
    try {
      const date = value.toDate();

      return (
        date instanceof Date &&
        Number.isFinite(date.getTime())
      )
        ? new Date(date.getTime())
        : null;
    } catch (error) {
      return null;
    }
  }

  if (typeof value === "string") {
    const normalized = value.trim();

    if (normalized.length === 0) {
      return null;
    }

    const date = new Date(normalized);

    return Number.isFinite(date.getTime())
      ? date
      : null;
  }

  if (
    typeof value === "number" &&
    Number.isFinite(value)
  ) {
    const date = new Date(value);

    return Number.isFinite(date.getTime())
      ? date
      : null;
  }

  return null;
}


// ============================================================
// 🕒 SAFE NOW
// ============================================================

function getSafeNow(value) {
  return getSafeDate(value) || new Date();
}


// ============================================================
// 💰 BASE MINING RATE
// ============================================================

function getSafeMiningRate() {
  const rate = Number(MINING_PER_HASH_PER_HOUR);

  return Number.isFinite(rate) && rate > 0
    ? rate
    : 0;
}


// ============================================================
// 📉 HALVING MULTIPLIER
// ============================================================
//
// User count must be the total registered user count
// supplied by trusted backend code.
//
// Never accept a client-provided user count.
//
// ============================================================

function getHalvingMultiplier(registeredUserCount) {
  if (HALVING_ENABLED !== true) {
    return 1;
  }

  const userCount = Math.max(
    0,
    Math.floor(getSafeNumber(registeredUserCount, 0)),
  );

  if (!Array.isArray(HALVING_MILESTONES)) {
    return 1;
  }

  const milestones = [...HALVING_MILESTONES]
    .filter((item) => {
      return (
        item &&
        Number.isFinite(Number(item.users)) &&
        Number.isFinite(Number(item.multiplier)) &&
        Number(item.users) >= 0 &&
        Number(item.multiplier) > 0
      );
    })
    .sort((a, b) => Number(a.users) - Number(b.users));

  let multiplier = 1;

  for (const milestone of milestones) {
    if (userCount >= Number(milestone.users)) {
      multiplier = Number(milestone.multiplier);
    } else {
      break;
    }
  }

  return multiplier;
}


// ============================================================
// 📉 EFFECTIVE MINING RATE
// ============================================================

function getEffectiveMiningRate(halvingMultiplier = 1) {
  const baseRate = getSafeMiningRate();

  const multiplier = getSafeNumber(
    halvingMultiplier,
    1,
  );

  if (
    baseRate <= 0 ||
    multiplier <= 0
  ) {
    return 0;
  }

  return baseRate * multiplier;
}


// ============================================================
// 💰 CALCULATE MINING
// ============================================================
//
// Optional halvingMultiplier defaults to 1.
//
// Existing callers therefore retain the original behavior
// until the backend explicitly supplies a stored multiplier.
//
// ============================================================

function calculateMining(
  hashRate,
  elapsedMilliseconds,
  halvingMultiplier = 1,
) {
  const safeHashRate = getSafeHashRate(hashRate);
  const safeElapsed = getSafeMilliseconds(elapsedMilliseconds);

  const rate = getEffectiveMiningRate(
    halvingMultiplier,
  );

  if (
    safeHashRate <= 0 ||
    safeElapsed <= 0 ||
    rate <= 0
  ) {
    return 0;
  }

  const elapsedHours = safeElapsed / 3600000;

  const amount =
    safeHashRate *
    rate *
    elapsedHours;

  if (
    !Number.isFinite(amount) ||
    amount < 0
  ) {
    return 0;
  }

  return amount;
}


// ============================================================
// ⏱️ MINING START TIME
// ============================================================

function getMiningStartTime(data) {
  if (!data || typeof data !== "object") {
    return null;
  }

  return getSafeDate(data.miningStartedAt);
}


// ============================================================
// ⏱️ MINING END TIME
// ============================================================

function getMiningEndTime(data) {
  if (!data || typeof data !== "object") {
    return null;
  }

  return getSafeDate(data.miningEndsAt);
}


// ============================================================
// ⚡ MINING HASH RATE
// ============================================================

function getMiningHashRate(data) {
  if (!data || typeof data !== "object") {
    return 0;
  }

  const hashRate = getSafeHashRate(data.hashRate);

  if (hashRate > 0) {
    return hashRate;
  }

  return getSafeHashRate(data.miningHashRate);
}


// ============================================================
// 📉 MINING HALVING MULTIPLIER
// ============================================================
//
// New cycles should store:
//
// miningHalvingMultiplier
//
// Old cycles without this field use 1.
//
// This prevents retroactive changes to existing cycles.
//

function getMiningHalvingMultiplier(data) {
  if (!data || typeof data !== "object") {
    return 1;
  }

  const storedMultiplier = Number(
    data.miningHalvingMultiplier,
  );

  if (
    Number.isFinite(storedMultiplier) &&
    storedMultiplier > 0 &&
    storedMultiplier <= 1
  ) {
    return storedMultiplier;
  }

  return 1;
}


// ============================================================
// 🐱 MINING STATUS
// ============================================================

function calculateMiningStatus(
  data,
  now = new Date(),
) {
  const safeData =
    data && typeof data === "object"
      ? data
      : {};

  const miningHashRate = getMiningHashRate(
    safeData,
  );

  const miningHalvingMultiplier =
    getMiningHalvingMultiplier(safeData);

  const miningStartedAt = getMiningStartTime(
    safeData,
  );

  const miningEndsAt = getMiningEndTime(
    safeData,
  );

  const baseResult = {
    hashRate: miningHashRate,
    miningHashRate,
    miningHalvingMultiplier,
    miningStartedAt,
    miningEndsAt,
  };

  // ==========================================================
  // NO MINING SESSION
  // ==========================================================

  if (!miningStartedAt || !miningEndsAt) {
    return {
      miningActive: false,
      miningFinished: false,
      elapsedMs: 0,
      miningRemainingMs: 0,
      minedAmount: 0,
      ...baseResult,
      miningStartedAt: null,
      miningEndsAt: null,
    };
  }

  const nowMs = getSafeNow(now).getTime();
  const startMs = miningStartedAt.getTime();
  const endMs = miningEndsAt.getTime();

  // ==========================================================
  // INVALID TIME WINDOW
  // ==========================================================

  if (
    !Number.isFinite(nowMs) ||
    !Number.isFinite(startMs) ||
    !Number.isFinite(endMs) ||
    endMs <= startMs
  ) {
    return {
      miningActive: false,
      miningFinished: false,
      elapsedMs: 0,
      miningRemainingMs: 0,
      minedAmount: 0,
      ...baseResult,
    };
  }

  // ==========================================================
  // BEFORE MINING START
  // ==========================================================

  if (nowMs < startMs) {
    return {
      miningActive: false,
      miningFinished: false,
      elapsedMs: 0,
      miningRemainingMs: endMs - startMs,
      minedAmount: 0,
      ...baseResult,
    };
  }

  // ==========================================================
  // ACTIVE MINING
  // ==========================================================

  if (nowMs < endMs) {
    const elapsedMs = Math.min(
      nowMs - startMs,
      endMs - startMs,
    );

    const remainingMs = Math.max(
      0,
      endMs - nowMs,
    );

    return {
      miningActive: true,
      miningFinished: false,
      elapsedMs: Math.max(0, elapsedMs),
      miningRemainingMs: remainingMs,
      minedAmount: calculateMining(
        miningHashRate,
        elapsedMs,
        miningHalvingMultiplier,
      ),
      ...baseResult,
    };
  }

  // ==========================================================
  // MINING FINISHED
  // ==========================================================

  const durationMs = endMs - startMs;

  return {
    miningActive: false,
    miningFinished: true,
    elapsedMs: durationMs,
    miningRemainingMs: 0,
    minedAmount: calculateMining(
      miningHashRate,
      durationMs,
      miningHalvingMultiplier,
    ),
    ...baseResult,
  };
}


// ============================================================
// 📦 EXPORTS
// ============================================================

module.exports = {
  calculateMining,
  getMiningStartTime,
  getMiningEndTime,
  getMiningHashRate,
  getHalvingMultiplier,
  getEffectiveMiningRate,
  getMiningHalvingMultiplier,
  calculateMiningStatus,
};
