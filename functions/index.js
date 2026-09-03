"use strict";

// ============================================================
// 🐱 STELLURIINI FIREBASE FUNCTIONS
// ============================================================
//
// Stella Mining -järjestelmän pääsisäänkäynti.
//
// Kaikki suuremmat järjestelmät on jaettu
// omiin tiedostoihinsa.
//
// 🐱⛏️ Stella pitää projektin siistinä!
// ============================================================


// ============================================================
// ⛏️ MINING
// ============================================================

const {
  getMiningStatus,
  claimMining,
} = require("./functions/miningFunctions");


// ============================================================
// 🎁 DAILY
// ============================================================

const {
  dailyCheckIn,
} = require("./functions/dailyFunctions");


// ============================================================
// 📺 ADS
// ============================================================

const {
  testAdReward,
  adMobReward,
} = require("./functions/adFunctions");


// ============================================================
// 📜 HISTORY
// ============================================================

const {
  getTransactionHistory,
} = require("./functions/historyFunctions");


// ============================================================
// EXPORT FUNCTIONS
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