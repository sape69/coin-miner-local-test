"use strict";


// ============================================================
// 🐱 STELLURIINI FIREBASE CLOUD FUNCTIONS
// ============================================================
//
// Stella Mining Backend
//
// Tämä tiedosto toimii backendin pääsisäänkäyntinä.
//
// Varsinainen logiikka on jaettu:
//
// 📁 config/
// 📁 firebase/
// 📁 utils/
// 📁 services/
// 📁 functions/
//
// Näin index.js pysyy kevyenä ja helposti ylläpidettävänä.
//
// ============================================================


// ============================================================
// ⛏️ STELLA MINING FUNCTIONS
// ============================================================

const {
  getMiningStatus,
  claimMining,
} = require("./functions/miningFunctions");


// ============================================================
// 🎁 STELLA DAILY FUNCTIONS
// ============================================================

const {
  dailyCheckIn,
} = require("./functions/dailyFunctions");


// ============================================================
// 📺 STELLA AD FUNCTIONS
// ============================================================

const {
  testAdReward,
} = require("./functions/adFunctions");


// ============================================================
// 📜 STELLA HISTORY FUNCTIONS
// ============================================================

const {
  getTransactionHistory,
} = require("./functions/historyFunctions");


// ============================================================
// 🌟 EXPORT STELLA FUNCTIONS
// ============================================================
//
// Firebase löytää nämä funktiot tästä tiedostosta.
//
// ============================================================


// ============================================================
// 🐱⛏️ MINING
// ============================================================

exports.getMiningStatus =
  getMiningStatus;

exports.claimMining =
  claimMining;


// ============================================================
// 🐱🎁 DAILY
// ============================================================

exports.dailyCheckIn =
  dailyCheckIn;


// ============================================================
// 🐱📺 TEST AD
// ============================================================
//
// Käytetään kehitysvaiheessa.
//
// Flutter käyttää edelleen Google AdMob TEST MAINOKSIA.
//

exports.testAdReward =
  testAdReward;


// ============================================================
// 🐱📜 HISTORY
// ============================================================

exports.getTransactionHistory =
  getTransactionHistory;