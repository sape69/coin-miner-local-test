"use strict";


// ============================================================
// 🐱 STELLURIINI FIREBASE FUNCTIONS
// ============================================================
//
// Stella Mining Backend
//
// ⛏️ Mining
// 🎁 Daily Bonus
// 📺 Ad Rewards
// 📜 Transaction History
//
// ============================================================


// ============================================================
// ⛏️ STELLA MINING FUNCTIONS
// ============================================================

const {
  getMiningStatus,
  claimMining,
} = require(
  "./src/functions/miningFunctions"
);


// ============================================================
// 🎁 STELLA DAILY FUNCTIONS
// ============================================================

const {
  dailyCheckIn,
} = require(
  "./src/functions/dailyFunctions"
);


// ============================================================
// 📺 STELLA AD FUNCTIONS
// ============================================================

const {
  testAdReward,
  adMobReward,
} = require(
  "./src/functions/adFunctions"
);


// ============================================================
// 📜 STELLA HISTORY FUNCTIONS
// ============================================================

const {
  getTransactionHistory,
} = require(
  "./src/functions/historyFunctions"
);


// ============================================================
// 🚀 FIREBASE EXPORTS
// ============================================================

exports.getMiningStatus =
  getMiningStatus;


exports.claimMining =
  claimMining;


exports.dailyCheckIn =
  dailyCheckIn;


exports.testAdReward =
  testAdReward;


exports.adMobReward =
  adMobReward;


exports.getTransactionHistory =
  getTransactionHistory;