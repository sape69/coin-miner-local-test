"use strict";

// ==========================================
// STELLURIINI MINING CONFIGURATION
// ==========================================

// ------------------------------------------
// Daily Hash Rate
// ------------------------------------------

const DAILY_HASH_RATE_START = 0.5;

const DAILY_HASH_RATE_STEP = 0.5;

const DAILY_HASH_RATE_MAX_DAY = 7;

const MAX_DAILY_HASH_RATE = 3.5;

// ------------------------------------------
// AdMob Power Boost
// ------------------------------------------

const AD_HASH_RATE_BONUS = 0.5833;

const AD_BOOST_DURATION_MS =
  4 * 60 * 60 * 1000;

const MAX_ADS_PER_DAY = 6;

const AD_COOLDOWN_MS =
  4 * 60 * 60 * 1000;

// ------------------------------------------
// Production AdMob Rewarded Ad
// ------------------------------------------

// Full AdMob Rewarded Ad Unit ID used by Flutter.
const ADMOB_REWARDED_AD_UNIT_ID =
  "ca-app-pub-1131012057145658/2252768949";

// Numeric Ad Unit ID received in AdMob SSV callback.
const ADMOB_SSV_AD_UNIT_ID =
  "2252768949";

// AdMob reward configuration.
//
// IMPORTANT:
// This is the AdMob reward metadata.
// It is NOT an STL token reward.
//
// Stelluriini's actual reward is handled
// separately by the Power Boost logic above.
const ADMOB_SSV_REWARD_AMOUNT = 1;

const ADMOB_SSV_REWARD_ITEM =
  "Power Boost";

// ------------------------------------------
// Mining
// ------------------------------------------

const MINING_DURATION_MS =
  24 * 60 * 60 * 1000;

const MINING_PER_HASH_PER_HOUR = 0.10;

// ------------------------------------------
// Transaction History
// ------------------------------------------

const MAX_TRANSACTION_HISTORY = 50;

// ------------------------------------------
// Exports
// ------------------------------------------

module.exports = {
  DAILY_HASH_RATE_START,
  DAILY_HASH_RATE_STEP,
  DAILY_HASH_RATE_MAX_DAY,
  MAX_DAILY_HASH_RATE,

  AD_HASH_RATE_BONUS,
  AD_BOOST_DURATION_MS,
  MAX_ADS_PER_DAY,
  AD_COOLDOWN_MS,

  ADMOB_REWARDED_AD_UNIT_ID,
  ADMOB_SSV_AD_UNIT_ID,
  ADMOB_SSV_REWARD_AMOUNT,
  ADMOB_SSV_REWARD_ITEM,

  MINING_DURATION_MS,
  MINING_PER_HASH_PER_HOUR,

  MAX_TRANSACTION_HISTORY,
};