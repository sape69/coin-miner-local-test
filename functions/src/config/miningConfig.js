
"use strict";

// ============================================================
// 🐱 STELLURIINI - MINING CONFIG
// ============================================================
//
// Stella Mining configuration.
//
// AdMob rewards authorize Mining Start and Power Boost.
// They are NOT direct STL token rewards.
//
// Mining formula:
//
// Hash Rate × STL / Hash / Hour × elapsed time
// × halving multiplier.
//
// ============================================================


// ============================================================
// 🧪 ADMOB TEST MODE
// ============================================================

const ADMOB_TEST_MODE = true;


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
// Applies to new mining cycles only.
//

const DAILY_HASH_RATE_START = 0.5;
const DAILY_HASH_RATE_STEP = 0.5;
const DAILY_HASH_RATE_MAX_DAY = 7;
const MAX_DAILY_HASH_RATE = 3.5;


// ============================================================
// ⛏️ MINING CYCLE
// ============================================================

const MINING_DURATION_MS =
  24 * 60 * 60 * 1000;


// ============================================================
// 💰 MINING RATE
// ============================================================
//
// Base mining rate before halving:
//
// 1 HR × 0.10 × 1 hour = 0.10 STL
//
// The active halving multiplier is applied
// by the mining calculation logic.
//

const MINING_PER_HASH_PER_HOUR = 0.10;


// ============================================================
// 📉 HALVING SYSTEM
// ============================================================
//
// Halving is based on ALL registered users.
//
// User count includes:
// - Users who are mining.
// - Users who are not mining.
//
// Each milestone reduces the mining rate
// by applying the corresponding multiplier.
//
// Halving is enabled and integrated into
// the backend mining calculations.
//

const HALVING_ENABLED = true;

const HALVING_MILESTONES = [
  {
    users: 0,
    multiplier: 1.0,
    label: "Start",
  },
  {
    users: 100,
    multiplier: 0.5,
    label: "100",
  },
  {
    users: 1000,
    multiplier: 0.25,
    label: "1K",
  },
  {
    users: 10000,
    multiplier: 0.125,
    label: "10K",
  },
  {
    users: 100000,
    multiplier: 0.0625,
    label: "100K",
  },
  {
    users: 1000000,
    multiplier: 0.03125,
    label: "1M",
  },
  {
    users: 10000000,
    multiplier: 0.015625,
    label: "10M",
  },
  {
    users: 100000000,
    multiplier: 0.0078125,
    label: "100M",
  },
];


// ============================================================
// ⚡ POWER BOOST
// ============================================================

const AD_HASH_RATE_BONUS = 0.5833;

const AD_BOOST_DURATION_MS =
  4 * 60 * 60 * 1000;


// ============================================================
// 📺 ADMOB DAILY LIMIT
// ============================================================

const MAX_ADS_PER_DAY = 6;


// ============================================================
// ⏱️ ADMOB POWER BOOST COOLDOWN
// ============================================================

const AD_COOLDOWN_MS =
  4 * 60 * 60 * 1000;


// ============================================================
// 📺 ADMOB REWARDED AD UNIT IDS
// ============================================================

const ADMOB_MINING_AD_UNIT_ID =
  "ca-app-pub-1131012057145658/6674097787";

const ADMOB_POWER_BOOST_AD_UNIT_ID =
  "ca-app-pub-1131012057145658/7225738491";


// ============================================================
// 🔐 ADMOB SSV AD UNIT IDS
// ============================================================

const ADMOB_MINING_SSV_AD_UNIT_ID =
  "6674097787";

const ADMOB_POWER_BOOST_SSV_AD_UNIT_ID =
  "7225738491";


// ============================================================
// 🎁 ADMOB MINING SSV REWARD
// ============================================================

const ADMOB_MINING_SSV_REWARD_AMOUNT = 1;
const ADMOB_MINING_SSV_REWARD_ITEM = "Mining";


// ============================================================
// ⚡ ADMOB POWER BOOST SSV REWARD
// ============================================================

const ADMOB_POWER_BOOST_SSV_REWARD_AMOUNT = 1;
const ADMOB_POWER_BOOST_SSV_REWARD_ITEM =
  "Power Boost";


// ============================================================
// 📜 TRANSACTION HISTORY
// ============================================================

const MAX_TRANSACTION_HISTORY = 50;


// ============================================================
// 📦 EXPORTS
// ============================================================

module.exports = {
  // AdMob test mode
  ADMOB_TEST_MODE,

  // Daily Hash Rate
  DAILY_HASH_RATE_START,
  DAILY_HASH_RATE_STEP,
  DAILY_HASH_RATE_MAX_DAY,
  MAX_DAILY_HASH_RATE,

  // Mining
  MINING_DURATION_MS,
  MINING_PER_HASH_PER_HOUR,

  // Halving
  HALVING_ENABLED,
  HALVING_MILESTONES,

  // Power Boost
  AD_HASH_RATE_BONUS,
  AD_BOOST_DURATION_MS,

  // AdMob limits
  MAX_ADS_PER_DAY,
  AD_COOLDOWN_MS,

  // AdMob Rewarded Ad units
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
