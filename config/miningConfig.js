"use strict";


// ============================================================
// 🐱 STELLA MINING CONFIGURATION
// ============================================================


// ============================================================
// ⚡ HASH RATE
// ============================================================

// Stella aloittaa tällä nopeudella.

const DEFAULT_HASH_RATE = 1;


// Päivittäinen Stella Bonus.

const DAILY_HASH_RATE_BONUS = 1;


// Testimainoksen Power Boost.

const AD_HASH_RATE_BONUS = 5;


// ============================================================
// 📺 AD SETTINGS
// ============================================================

const MAX_ADS_PER_DAY = 5;


// 60 minuuttia.

const AD_COOLDOWN_MS =
  60 * 60 * 1000;


// ============================================================
// ⛏️ MINING SETTINGS
// ============================================================

// Stella Mining kestää 24 tuntia.

const MINING_DURATION_MS =
  24 * 60 * 60 * 1000;


// STL per Hash Rate per hour.

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