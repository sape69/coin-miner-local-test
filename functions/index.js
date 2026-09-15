"use strict";

// ============================================================
// 🐱 STELLURIINI CLOUD FUNCTIONS
// ============================================================

// ============================================================
// ⛏️ MINING
// ============================================================

const {
  getMiningStatus,
  claimMining,
  powerBoost,
} = require(
  "./src/functions/miningFunctions"
);


// ============================================================
// 🎁 DAILY CHECK-IN
// ============================================================

const {
  dailyCheckIn,
} = require(
  "./src/functions/dailyFunctions"
);


// ============================================================
// 📺 ADMOB SSV
// ============================================================

const {
  adMobReward,
} = require(
  "./src/functions/adFunctions"
);


// ============================================================
// 📜 TRANSACTION HISTORY
// ============================================================

const {
  getTransactionHistory,
} = require(
  "./src/functions/historyFunctions"
);


// ============================================================
// 🏆 ACHIEVEMENTS
// ============================================================

const {
  getAchievements,
  getAchievementsCompleted,
} = require(
  "./src/functions/achievementFunctions"
);


// ============================================================
// ⛏️ MINING EXPORTS
// ============================================================

exports.getMiningStatus =
  getMiningStatus;

exports.claimMining =
  claimMining;

exports.powerBoost =
  powerBoost;


// ============================================================
// 🎁 DAILY CHECK-IN EXPORT
// ============================================================

exports.dailyCheckIn =
  dailyCheckIn;


// ============================================================
// 📺 ADMOB SSV EXPORT
// ============================================================

exports.adMobReward =
  adMobReward;


// ============================================================
// 📜 TRANSACTION HISTORY EXPORT
// ============================================================

exports.getTransactionHistory =
  getTransactionHistory;


// ============================================================
// 🏆 ACHIEVEMENT EXPORTS
// ============================================================

exports.getAchievements =
  getAchievements;

exports.getAchievementsCompleted =
  getAchievementsCompleted;