"use strict";

// ============================================================
// 🐱 STELLURIINI - MINING UTILITIES
// ============================================================
//
// Keskitetty Mining-laskenta.
//
// Ei kirjoita Firestoreen.
// Ei käsittele Daily Streakia.
// Ei käsittele Power Boostia.
// Ei muuta käyttäjän saldoa.
//
// ============================================================

const {
  MINING_PER_HASH_PER_HOUR,
} = require("../config/miningConfig");

// ============================================================
// 🔢 SAFE VALUES
// ============================================================

function getSafeNumber(value, fallback = 0) {
  const number = Number(value);

  return Number.isFinite(number)
    ? number
    : fallback;
}

function getSafeHashRate(value) {
  const number = Number(value);

  return Number.isFinite(number) &&
    number >= 0
    ? number
    : 0;
}

function getSafeMilliseconds(value) {
  const number = Number(value);

  return Number.isFinite(number) &&
    number >= 0
    ? number
    : 0;
}

// ============================================================
// 🕒 DATE
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

  if (
    typeof value.toDate === "function"
  ) {
    try {
      const date = value.toDate();

      return date instanceof Date &&
        Number.isFinite(date.getTime())
        ? new Date(date.getTime())
        : null;
    } catch (error) {
      return null;
    }
  }

  if (typeof value === "string") {
    const date = new Date(value);

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

function getSafeNow(value) {
  return getSafeDate(value) || new Date();
}

// ============================================================
// 💰 MINING RATE
// ============================================================

function getSafeMiningRate() {
  const rate = Number(
    MINING_PER_HASH_PER_HOUR
  );

  return Number.isFinite(rate) && rate > 0
    ? rate
    : 0;
}

// ============================================================
// ⛏️ CALCULATE MINING
// ============================================================
//
// Hash Rate × STL/HR/h × elapsed hours
//
// Esim.
// 3.5 HR × 0.10 × 24 h = 8.4 STL
//
// ============================================================

function calculateMining(
  hashRate,
  elapsedMilliseconds
) {
  const safeHashRate =
    getSafeHashRate(hashRate);

  const safeElapsed =
    getSafeMilliseconds(
      elapsedMilliseconds
    );

  const rate =
    getSafeMiningRate();

  if (
    safeHashRate <= 0 ||
    safeElapsed <= 0 ||
    rate <= 0
  ) {
    return 0;
  }

  const hours =
    safeElapsed / 3600000;

  const amount =
    safeHashRate *
    rate *
    hours;

  return Number.isFinite(amount) &&
    amount >= 0
    ? amount
    : 0;
}

// ============================================================
// ⏱️ MINING TIMES
// ============================================================

function getMiningStartTime(data) {
  if (
    !data ||
    typeof data !== "object"
  ) {
    return null;
  }

  return getSafeDate(
    data.miningStartedAt
  );
}

function getMiningEndTime(data) {
  if (
    !data ||
    typeof data !== "object"
  ) {
    return null;
  }

  return getSafeDate(
    data.miningEndsAt
  );
}

// ============================================================
// ⚡ MINING HASH RATE
// ============================================================
//
// Mining-cycle käyttää aina miningHashRate-kenttää.
// Ei fallbackia hashRate-kenttään.
//
// ============================================================

function getMiningHashRate(data) {
  if (
    !data ||
    typeof data !== "object"
  ) {
    return 0;
  }

  return getSafeHashRate(
    data.miningHashRate
  );
}

// ============================================================
// 🐱 MINING STATUS
// ============================================================

function calculateMiningStatus(
  data,
  now = new Date()
) {
  const safeData =
    data &&
    typeof data === "object"
      ? data
      : {};

  const miningHashRate =
    getMiningHashRate(
      safeData
    );

  const miningStartedAt =
    getMiningStartTime(
      safeData
    );

  const miningEndsAt =
    getMiningEndTime(
      safeData
    );

  const baseResult = {
    hashRate:
      miningHashRate,

    miningHashRate,

    miningStartedAt,
    miningEndsAt,
  };

  if (
    !miningStartedAt ||
    !miningEndsAt
  ) {
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

  const nowMs =
    getSafeNow(now).getTime();

  const startMs =
    miningStartedAt.getTime();

  const endMs =
    miningEndsAt.getTime();

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

  // Ennen louhinnan alkua.
  if (nowMs < startMs) {
    return {
      miningActive: false,
      miningFinished: false,
      elapsedMs: 0,
      miningRemainingMs:
        endMs - startMs,
      minedAmount: 0,
      ...baseResult,
    };
  }

  // Aktiivinen louhinta.
  if (nowMs < endMs) {
    const elapsedMs =
      Math.min(
        nowMs - startMs,
        endMs - startMs
      );

    const remainingMs =
      Math.max(
        0,
        endMs - nowMs
      );

    return {
      miningActive: true,
      miningFinished: false,
      elapsedMs:
        Math.max(
          0,
          elapsedMs
        ),
      miningRemainingMs:
        remainingMs,
      minedAmount:
        calculateMining(
          miningHashRate,
          elapsedMs
        ),
      ...baseResult,
    };
  }

  // Louhinta valmis.
  const durationMs =
    endMs - startMs;

  return {
    miningActive: false,
    miningFinished: true,
    elapsedMs:
      durationMs,
    miningRemainingMs: 0,
    minedAmount:
      calculateMining(
        miningHashRate,
        durationMs
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
  calculateMiningStatus,
};