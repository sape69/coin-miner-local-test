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
} = require("./miningFunctions");


// ============================================================
// 🎁 STELLA DAILY FUNCTIONS
// ============================================================

const {
  dailyCheckIn,
} = require("./dailyFunctions");


// ============================================================
// 📺 STELLA AD FUNCTIONS
// ============================================================

const {
  testAdReward,
  adMobReward,
} = require("./adFunctions");


// ============================================================
// 📜 STELLA HISTORY FUNCTIONS
// ============================================================

const {
  getTransactionHistory,
} = require("./historyFunctions");


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