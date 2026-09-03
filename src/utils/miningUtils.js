"use strict";


// ============================================================
// 🐱 STELLA MINING UTILITIES
// ============================================================
//
// Vastaa:
//
// ⛏️ Louhinnan STL-laskennasta
// ⏱️ Mining-ajan käsittelystä
// 📅 Firestore Timestamp / Date -muunnoksista
// 🐱 Stella Mining -tilan laskemisesta
//
// ============================================================


// ============================================================
// CONFIG
// ============================================================

const {
  DEFAULT_HASH_RATE,
  MINING_PER_HASH_PER_HOUR,
} = require(
  "../config/miningConfig"
);


// ============================================================
// 🔢 SAFE NUMBER
// ============================================================
//
// Varmistaa, että arvo on kelvollinen numero.
//
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


// ============================================================
// ⚡ GET HASH RATE
// ============================================================

function getHashRate(data) {
  const hashRate =
    getSafeNumber(
      data?.hashRate,
      DEFAULT_HASH_RATE
    );

  return hashRate > 0
    ? hashRate
    : DEFAULT_HASH_RATE;
}


// ============================================================
// 📅 CONVERT TO DATE
// ============================================================
//
// Tukee:
//
// • Firestore Timestamp
// • JavaScript Date
//
// ============================================================

function toDate(value) {

  if (!value) {
    return null;
  }


  // ==========================================================
  // FIRESTORE TIMESTAMP
  // ==========================================================

  if (
    typeof value.toDate ===
    "function"
  ) {

    const date =
      value.toDate();

    return (
      date instanceof Date &&
      !Number.isNaN(date.getTime())
    )
      ? date
      : null;
  }


  // ==========================================================
  // JAVASCRIPT DATE
  // ==========================================================

  if (
    value instanceof Date
  ) {

    return Number.isNaN(
      value.getTime()
    )
      ? null
      : value;
  }


  // ==========================================================
  // STRING / NUMBER DATE
  // ==========================================================

  if (
    typeof value === "string" ||
    typeof value === "number"
  ) {

    const date =
      new Date(value);

    return Number.isNaN(
      date.getTime()
    )
      ? null
      : date;
  }


  return null;
}


// ============================================================
// ⛏️ CALCULATE MINING
// ============================================================
//
// Laskee syntyneen STL-määrän.
//
// Formula:
//
// Hash Rate
// × STL / Hash / Hour
// × Elapsed Hours
//
// ============================================================

function calculateMining(
  hashRate,
  elapsedMilliseconds
) {

  const safeHashRate =
    getSafeNumber(
      hashRate,
      DEFAULT_HASH_RATE
    );


  const safeElapsedMilliseconds =
    Math.max(
      0,
      getSafeNumber(
        elapsedMilliseconds,
        0
      )
    );


  const hours =
    safeElapsedMilliseconds /
    (1000 * 60 * 60);


  const minedAmount =
    safeHashRate *
    MINING_PER_HASH_PER_HOUR *
    hours;


  return Number.isFinite(
    minedAmount
  )
    ? minedAmount
    : 0;
}


// ============================================================
// ⏱️ GET MINING START
// ============================================================

function getMiningStartTime(data) {

  return toDate(
    data?.miningStartedAt
  );
}


// ============================================================
// ⏱️ GET MINING END
// ============================================================

function getMiningEndTime(data) {

  return toDate(
    data?.miningEndsAt
  );
}


// ============================================================
// 🐱 CALCULATE STELLA MINING STATUS
// ============================================================
//
// Palauttaa:
//
// • miningActive
// • elapsedMs
// • miningRemainingMs
// • minedAmount
// • hashRate
//
// ============================================================

function calculateMiningStatus(
  data = {},
  now = new Date()
) {

  // ==========================================================
  // ⚡ HASH RATE
  // ==========================================================

  const hashRate =
    getHashRate(data);


  // ==========================================================
  // ⏱️ MINING TIMES
  // ==========================================================

  const miningStartedAt =
    getMiningStartTime(data);


  const miningEndsAt =
    getMiningEndTime(data);


  // ==========================================================
  // 📅 CURRENT TIME
  // ==========================================================

  const currentTime =
    toDate(now) ||
    new Date();


  // ==========================================================
  // ❌ NO MINING CYCLE
  // ==========================================================

  if (
    !miningStartedAt ||
    !miningEndsAt
  ) {

    return {

      miningActive:
        false,

      elapsedMs:
        0,

      miningRemainingMs:
        0,

      minedAmount:
        0,

      hashRate,

    };
  }


  const nowMs =
    currentTime.getTime();


  const startMs =
    miningStartedAt.getTime();


  const endMs =
    miningEndsAt.getTime();


  // ==========================================================
  // 🚫 INVALID MINING PERIOD
  // ==========================================================

  if (
    endMs <= startMs
  ) {

    return {

      miningActive:
        false,

      elapsedMs:
        0,

      miningRemainingMs:
        0,

      minedAmount:
        0,

      hashRate,

    };
  }


  // ==========================================================
  // ⏳ MINING HAS NOT STARTED YET
  // ==========================================================

  if (
    nowMs < startMs
  ) {

    return {

      miningActive:
        true,

      elapsedMs:
        0,

      miningRemainingMs:
        endMs -
        startMs,

      minedAmount:
        0,

      hashRate,

    };
  }


  // ==========================================================
  // ✨ MINING COMPLETE
  // ==========================================================

  if (
    nowMs >= endMs
  ) {

    const totalElapsed =
      Math.max(
        0,
        endMs -
        startMs
      );


    const minedAmount =
      calculateMining(
        hashRate,
        totalElapsed
      );


    return {

      miningActive:
        false,

      elapsedMs:
        totalElapsed,

      miningRemainingMs:
        0,

      minedAmount,

      hashRate,

    };
  }


  // ==========================================================
  // ⛏️ MINING ACTIVE
  // ==========================================================

  const elapsedMs =
    Math.max(
      0,
      nowMs -
      startMs
    );


  const miningRemainingMs =
    Math.max(
      0,
      endMs -
      nowMs
    );


  const minedAmount =
    calculateMining(
      hashRate,
      elapsedMs
    );


  return {

    miningActive:
      true,

    elapsedMs,

    miningRemainingMs,

    minedAmount,

    hashRate,

  };
}


// ============================================================
// 📦 EXPORTS
// ============================================================

module.exports = {

  getSafeNumber,

  getHashRate,

  toDate,

  calculateMining,

  getMiningStartTime,

  getMiningEndTime,

  calculateMiningStatus,

};