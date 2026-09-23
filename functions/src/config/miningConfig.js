"use strict";

// ============================================================
// 🐱 STELLURIINI - MINING CONFIG
// ============================================================
//
// Stella Mining configuration.
//
// IMPORTANT:
//
// AdMob reward is NOT an STL token reward.
//
// AdMob only authorizes:
// - Mining Start
// - Power Boost
//
// Mining itself is calculated from:
// Hash Rate × STL / Hash / Hour × elapsed time.
//
// ============================================================


// ============================================================
// 🎁 DAILY HASH RATE
// ============================================================
//
// Day 1  = 0.5 HR
// Day 2  = 1.0 HR
// Day 3  = 1.5 HR
// Day 4  = 2.0 HR
// Day 5  = 2.5 HR
// Day 6  = 3.0 HR
// Day 7+ = 3.5 HR
//
// Daily Hash Rate belongs to the mining cycle that is
// started after the daily claim.
//
// ============================================================

const DAILY_HASH_RATE_START = 0.5;

const DAILY_HASH_RATE_STEP = 0.5;

const DAILY_HASH_RATE_MAX_DAY = 7;

const MAX_DAILY_HASH_RATE = 3.5;


// ============================================================
// ⛏️ MINING CYCLE
// ============================================================
//
// One mining cycle lasts 24 hours.
//
// The Hash Rate stored in miningHashRate belongs ONLY
// to that specific mining cycle.
//
// A new cycle must never modify the historical Hash Rate
// of an already completed cycle.
//
// ============================================================

const MINING_DURATION_MS =
  24 * 60 * 60 * 1000;


// ============================================================
// 💰 MINING RATE
// ============================================================
//
// STL generated per:
// 1 Hash Rate
// 1 hour
//
// Formula:
//
// Hash Rate × MINING_PER_HASH_PER_HOUR × elapsed hours
//
// Example:
//
// 1 HR × 0.10 × 1 hour
// = 0.10 STL
//
// ============================================================

const MINING_PER_HASH_PER_HOUR = 0.10;


// ============================================================
// ⚡ POWER BOOST
// ============================================================
//
// Power Boost temporarily adds Hash Rate.
//
// IMPORTANT:
//
// This is NOT a direct STL reward.
//
// The bonus only affects mining calculations while the
// Power Boost is active.
//
// The boost:
//
// +0.5833 HR
// 4 hours
//
// The boost is automatically capped by miningEndsAt.
//
// It never continues into another mining cycle.
//
// ============================================================

const AD_HASH_RATE_BONUS = 0.5833;

const AD_BOOST_DURATION_MS =
  4 * 60 * 60 * 1000;


// ============================================================
// 📺 ADMOB LIMITS
// ============================================================
//
// Maximum number of Power Boost advertisements per UTC day.
//
// Each accepted Power Boost SSV reward consumes one slot.
//
// ============================================================

const MAX_ADS_PER_DAY = 6;


// ============================================================
// ⏱️ ADMOB COOLDOWN
// ============================================================
//
// A new Power Boost cannot be activated until the cooldown
// has elapsed from the previous accepted Power Boost.
//
// ============================================================

const AD_COOLDOWN_MS =
  4 * 60 * 60 * 1000;


// ============================================================
// 📺 ADMOB REWARDED AD UNIT IDS
// ============================================================
//
// These IDs identify the rewarded advertisements shown by
// the Flutter application.
//
// Mining Start:
// ca-app-pub-1131012057145658/6674097787
//
// Power Boost:
// ca-app-pub-1131012057145658/7225738491
//
// ============================================================

const ADMOB_MINING_AD_UNIT_ID =
  "ca-app-pub-1131012057145658/6674097787";

const ADMOB_POWER_BOOST_AD_UNIT_ID =
  "ca-app-pub-1131012057145658/7225738491";


// ============================================================
// 🔐 ADMOB SSV AD UNIT IDS
// ============================================================
//
// These values identify the AdMob SSV callback source.
//
// The miningFunctions.js file validates the SSV reward
// against these identifiers before consuming the reward.
//
// ============================================================

const ADMOB_MINING_SSV_AD_UNIT_ID =
  "6674097787";

const ADMOB_POWER_BOOST_SSV_AD_UNIT_ID =
  "7225738491";


// ============================================================
// 🎁 ADMOB MINING SSV REWARD
// ============================================================
//
// The reward amount is NOT STL.
//
// It is only an authorization signal that the Mining Start
// advertisement was successfully completed.
//
// ============================================================

const ADMOB_MINING_SSV_REWARD_AMOUNT = 1;

const ADMOB_MINING_SSV_REWARD_ITEM =
  "Mining";


// ============================================================
// ⚡ ADMOB POWER BOOST SSV REWARD
// ============================================================
//
// The reward amount is NOT STL.
//
// It is only an authorization signal that the Power Boost
// advertisement was successfully completed.
//
// ============================================================

const ADMOB_POWER_BOOST_SSV_REWARD_AMOUNT = 1;

const ADMOB_POWER_BOOST_SSV_REWARD_ITEM =
  "Power Boost";


// ============================================================
// 📜 TRANSACTION HISTORY
// ============================================================
//
// Maximum number of history entries used by mining-related
// history processing.
//
// ============================================================

const MAX_TRANSACTION_HISTORY = 50;


// ============================================================
// 📦 EXPORTS
// ============================================================

module.exports = {
  // Daily Hash Rate
  DAILY_HASH_RATE_START,
  DAILY_HASH_RATE_STEP,
  DAILY_HASH_RATE_MAX_DAY,
  MAX_DAILY_HASH_RATE,

  // Mining
  MINING_DURATION_MS,
  MINING_PER_HASH_PER_HOUR,

  // Power Boost
  AD_HASH_RATE_BONUS,
  AD_BOOST_DURATION_MS,

  // AdMob limits
  MAX_ADS_PER_DAY,
  AD_COOLDOWN_MS,

  // AdMob rewarded ad units
  ADMOB_MINING_AD_UNIT_ID,
  ADMOB_POWER_BOOST_AD_UNIT_ID,

  // AdMob SSV ad units
  ADMOB_MINING_SSV_AD_UNIT_ID,
  ADMOB_POWER_BOOST_SSV_AD_UNIT_ID,

  // Mining SSV reward
  ADMOB_MINING_SSV_REWARD_AMOUNT,
  ADMOB_MINING_SSV_REWARD_ITEM,

  // Power Boost SSV reward
  ADMOB_POWER_BOOST_SSV_REWARD_AMOUNT,
  ADMOB_POWER_BOOST_SSV_REWARD_ITEM,

  // History
  MAX_TRANSACTION_HISTORY,
};