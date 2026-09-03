"use strict";

// ============================================================
// 🐱 STELLURIINI FIREBASE FUNCTIONS
// ============================================================
//
// Stella Mining System
// Modular architecture
//
// ============================================================


// ============================================================
// ⛏️ MINING
// ============================================================

const {
  getMiningStatus,
  claimMining,
} = require("./src/functions/mining");


// ============================================================
// 🎁 DAILY STELLA BONUS
// ============================================================

const {
  dailyCheckIn,
} = require("./src/functions/daily");


// ============================================================
// 📺 STELLA POWER BOOST
// ============================================================

const {
  testAdReward,
  adMobReward,
} = require("./src/functions/ads");


// ============================================================
// 📜 STELLA HISTORY
// ============================================================

const {
  getTransactionHistory,
} = require("./src/functions/history");


// ============================================================
// 🚀 EXPORT FUNCTIONS
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