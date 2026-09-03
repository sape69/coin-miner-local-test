"use strict";

// ============================================================
// 🐱 STELLA MINING CONFIGURATION
// ============================================================


// ============================================================
// ⚡ HASH RATE
// ============================================================

const DEFAULT_HASH_RATE = 1;

const DAILY_HASH_RATE_BONUS = 1;

const AD_HASH_RATE_BONUS = 5;


// ============================================================
// 📺 ADS
// ============================================================

const MAX_ADS_PER_DAY = 5;

const AD_COOLDOWN_MS =
  60 * 60 * 1000;


// ============================================================
// ⛏️ MINING
// ============================================================

// Stella Mining cycle lasts 24 hours.

const MINING_DURATION_MS =
  24 * 60 * 60 * 1000;


// STL generated per Hash Rate per hour.

const MINING_PER_HASH_PER_HOUR =
  0.10;


// ============================================================
// 📜 HISTORY
// ============================================================

const MAX_TRANSACTION_HISTORY =
  50;


// ============================================================
// EXPORTS
// ============================================================

module.exports = {

  DEFAULT_HASH_RATE,

  DAILY_HASH_RATE_BONUS,

  AD_HASH_RATE_BONUS,

  MAX_ADS_PER_DAY,

  AD_COOLDOWN_MS,

  MINING_DURATION_MS,

  MINING_PER_HASH_PER_HOUR,

  MAX_TRANSACTION_HISTORY,

};