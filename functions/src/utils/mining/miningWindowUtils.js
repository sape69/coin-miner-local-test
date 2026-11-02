
"use strict";

// ============================================================
// 🐱 STELLURIINI - MINING WINDOW UTILITIES
// ============================================================
//
// Hanterar:
// - Mining-periodens start- och sluttid
// - Kontroll av aktiv mining
// - Validering av mining Hash Rate
// - Historisk Hash Rate
//
// Denna fil innehåller endast hjälpfunktioner.
// Ingen Firestore-data ändras här.
// ============================================================

const {
  DAILY_HASH_RATE_START,
  MAX_DAILY_HASH_RATE,
} = require("../../config/miningConfig");

const {
  getMiningStartTime,
  getMiningEndTime,
} = require("../miningUtils");

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
// MINING WINDOW
// ============================================================

function getMiningWindow(data) {
  const start = getMiningStartTime(data);

  const end = getMiningEndTime(data);

  const startMs = start?.getTime() || 0;

  const endMs = end?.getTime() || 0;

  const valid =
    startMs > 0 &&
    endMs > startMs;

  return {
    miningStartedAt: valid ? start : null,

    miningEndsAt: valid ? end : null,

    miningStartMs: valid ? startMs : 0,

    miningEndMs: valid ? endMs : 0,

    valid,
  };
}

// ============================================================
// MINING ACTIVE
// ============================================================

function isMiningActive(data, nowMs = Date.now()) {
  const window = getMiningWindow(data);

  return (
    window.valid &&
    nowMs >= window.miningStartMs &&
    nowMs < window.miningEndMs
  );
}

// ============================================================
// MINING HASH RATE
// ============================================================

function getValidatedMiningHashRate(
  data,
  fallback = DAILY_HASH_RATE_START
) {
  const stored = positive(data.miningHashRate);

  if (
    stored >= DAILY_HASH_RATE_START &&
    stored <= MAX_DAILY_HASH_RATE
  ) {
    return stored;
  }

  const safeFallback = positive(
    fallback,
    DAILY_HASH_RATE_START
  );

  return Math.min(
    MAX_DAILY_HASH_RATE,
    Math.max(
      DAILY_HASH_RATE_START,
      safeFallback
    )
  );
}

// ============================================================
// HISTORICAL HASH RATE
// ============================================================

function getHistoricalHashRate(data) {
  const rate = positive(
    data.miningHashRate ?? data.hashRate
  );

  return (
    rate >= DAILY_HASH_RATE_START &&
    rate <= MAX_DAILY_HASH_RATE
  )
    ? rate
    : 0;
}

// ============================================================
// EXPORTS
// ============================================================

module.exports = {
  getMiningWindow,
  isMiningActive,
  getValidatedMiningHashRate,
  getHistoricalHashRate,
};
