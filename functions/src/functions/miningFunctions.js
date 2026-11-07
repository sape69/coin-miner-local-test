"use strict";

// ============================================================
// 🐱 STELLURIINI - MINING FUNCTIONS
// ============================================================
//
// Stella Mining.
//
// Tämä tiedosto toimii keskitettynä kytkentäpisteenä.
//
// Varsinaiset toiminnot sijaitsevat:
//
// - getMiningStatus.js
// - claimMining.js
// - powerBoost.js
//
// Yhteiset apufunktiot sijaitsevat:
//
// - miningHelpers.js
//
// ============================================================


// ============================================================
// FIREBASE
// ============================================================

const {
  onCall,
  HttpsError,
} = require("firebase-functions/v2/https");

const {
  db,
  FieldValue,
} = require("../firebase/firebase");


// ============================================================
// MINING CONFIG
// ============================================================

const {
  ADMOB_TEST_MODE,
  MINING_DURATION_MS,
  MINING_PER_HASH_PER_HOUR,
  AD_HASH_RATE_BONUS,
  AD_BOOST_DURATION_MS,
  MAX_ADS_PER_DAY,
  AD_COOLDOWN_MS,
} = require("../config/miningConfig");


// ============================================================
// DATE UTILS
// ============================================================

const {
  getUtcDateString,
} = require("../utils/dateUtils");


// ============================================================
// USER UTILS
// ============================================================

const {
  getUserRef,
  getHistoryCollection,
  getAdMobRewardRef,
} = require("../utils/userUtils");


// ============================================================
// MINING UTILS
// ============================================================

const {
  calculateMiningStatus,
  calculateMining,
  getMiningHalvingMultiplier,
  getHalvingMultiplier,
} = require("../utils/miningUtils");


// ============================================================
// ADMOB REWARD SERVICE
// ============================================================

const {
  getVerifiedMiningStartReward,
  getVerifiedPowerBoostReward,
  validateVerifiedRewardDocument,
} = require("../services/admobRewardService");


// ============================================================
// MINING CALCULATION SERVICE
// ============================================================

const {
  miningWindow,
  miningActive,
  miningHashRate,
  historicalHashRate,
} = require("../services/miningCalculationService");


// ============================================================
// DAILY MINING SERVICE
// ============================================================

const {
  dailyHashRate,
  dailyHashRateBonus,
  nextDailyClaim,
  nextDailyHashRate,
  nextDailyStreak,
} = require("../services/dailyMiningService");


// ============================================================
// MINING ACHIEVEMENTS
// ============================================================

const {
  prepareMiningAchievements,
  preparePowerBoostAchievements,
  writeMiningAchievements,
} = require("../services/miningAchievementService");


// ============================================================
// REFERRAL
// ============================================================

const {
  processReferralMiningReward,
} = require("./referralFunctions");


// ============================================================
// HALVING SERVICE
// ============================================================

const {
  getRegisteredUserCount,
} = require("../services/halvingService");


// ============================================================
// MINING HELPERS
// ============================================================

const {
  createMiningHelpers,
} = require("./miningHelpers");


// ============================================================
// MINING FUNCTIONS
// ============================================================

const {
  createGetMiningStatus,
} = require("./getMiningStatus");

const {
  createClaimMining,
} = require("./claimMining");

const {
  createPowerBoost,
} = require("./powerBoost");


// ============================================================
// CREATE SHARED HELPERS
// ============================================================

const miningHelpers =
  createMiningHelpers({
    HttpsError,

    nextDailyClaim,
    nextDailyHashRate,
    nextDailyStreak,

    getHistoryCollection,

    miningWindow,
    historicalHashRate,
    getMiningHalvingMultiplier,

    calculateMining,

    AD_COOLDOWN_MS,
    MAX_ADS_PER_DAY,
    MINING_DURATION_MS,
    AD_HASH_RATE_BONUS,
  });


// ============================================================
// GET MINING STATUS
// ============================================================

const getMiningStatus =
  createGetMiningStatus({
    ...miningHelpers,

    onCall,
    HttpsError,

    getUserRef,
    getUtcDateString,

    miningWindow,
    historicalHashRate,
    miningHashRate,
    calculateMiningStatus,

    // Päivittäisen hash rate -bonuksen laskenta.
    dailyHashRateBonus,

    AD_HASH_RATE_BONUS,
    AD_BOOST_DURATION_MS,
    MINING_PER_HASH_PER_HOUR,
    MINING_DURATION_MS,

    getMiningHalvingMultiplier,
  });


// ============================================================
// CLAIM MINING
// ============================================================

const claimMining =
  createClaimMining({
    ...miningHelpers,

    onCall,
    HttpsError,

    db,
    FieldValue,

    getUserRef,
    getHistoryCollection,
    getAdMobRewardRef,

    getUtcDateString,

    miningWindow,
    historicalHashRate,
    miningHashRate,
    calculateMiningStatus,

    dailyHashRate,
    dailyHashRateBonus,

    getMiningHalvingMultiplier,
    getHalvingMultiplier,
    getRegisteredUserCount,

    getVerifiedMiningStartReward,
    validateVerifiedRewardDocument,

    prepareMiningAchievements,
    writeMiningAchievements,

    processReferralMiningReward,

    ADMOB_TEST_MODE,
    MINING_DURATION_MS,
    AD_HASH_RATE_BONUS,
  });


// ============================================================
// POWER BOOST
// ============================================================

const powerBoost =
  createPowerBoost({
    ...miningHelpers,

    onCall,
    HttpsError,

    db,
    FieldValue,

    getUserRef,
    getHistoryCollection,
    getAdMobRewardRef,

    getUtcDateString,

    miningActive,
    miningWindow,
    historicalHashRate,
    calculateMiningStatus,

    getVerifiedPowerBoostReward,
    validateVerifiedRewardDocument,

    preparePowerBoostAchievements,
    writeMiningAchievements,

    dailyHashRateBonus,

    ADMOB_TEST_MODE,
    AD_BOOST_DURATION_MS,
    AD_HASH_RATE_BONUS,
    MAX_ADS_PER_DAY,
  });


// ============================================================
// EXPORTS
// ============================================================

module.exports = {
  getMiningStatus,
  claimMining,
  powerBoost,
};