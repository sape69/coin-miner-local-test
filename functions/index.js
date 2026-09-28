"use strict";

// ============================================================
// 🐱 STELLURIINI CLOUD FUNCTIONS
// ============================================================
//
// Stelluriini Cloud Functions -päävientitiedosto.
//
// Firebase käyttää tätä tiedostoa Cloud Functions -entry pointina,
// koska functions/package.json sisältää:
//
// "main": "index.js"
//
// Varsinaiset funktiot sijaitsevat:
//
// functions/src/functions/
//
// Tämä tiedosto toimii keskitettynä export-pisteenä.
//
// ============================================================


// ============================================================
// ⛏️ MINING
// ============================================================

const {
  getMiningStatus,
  claimMining,
  powerBoost,
} = require(
  "./src/functions/miningFunctions",
);


// ============================================================
// 🎁 DAILY CHECK-IN
// ============================================================

const {
  dailyCheckIn,
} = require(
  "./src/functions/dailyFunctions",
);


// ============================================================
// 📺 ADMOB SSV
// ============================================================

const {
  adMobReward,
} = require(
  "./src/functions/adFunctions",
);


// ============================================================
// 📜 TRANSACTION HISTORY
// ============================================================

const {
  getTransactionHistory,
} = require(
  "./src/functions/historyFunctions",
);


// ============================================================
// 🏆 ACHIEVEMENTS
// ============================================================

const {
  getAchievements,
  getAchievementsCompleted,
} = require(
  "./src/functions/achievementFunctions",
);


// ============================================================
// 🔗 REFERRAL
// ============================================================
//
// Stella Referral System.
//
// Flutter käyttää tällä hetkellä:
//
// getReferralStatus
//
// Lisäksi backendissä ovat:
//
// getReferralProfile
// applyReferralCode
// getReferredUsers
// getReferralDashboard
// validateReferralCode
//
// processReferralMiningReward
// ei ole suoraan clientin callable,
// vaan mining-järjestelmä käyttää sitä referral-bonuksen
// käsittelyyn.
//
// ============================================================

const {
  getReferralProfile,
  applyReferralCode,
  getReferredUsers,
  getReferralStatus,
  getReferralDashboard,
} = require(
  "./src/functions/referralFunctions",
);


// ============================================================
// 🔍 REFERRAL CODE VALIDATION
// ============================================================
//
// Tarkistaa referral-koodin ennen Firebase Auth -tilin
// luomista.
//
// Tämä funktio ei luo käyttäjää eikä referral-suhdetta.
//
// ============================================================

const {
  validateReferralCode,
} = require(
  "./src/functions/validateReferralCode",
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


// ============================================================
// 🔗 REFERRAL EXPORTS
// ============================================================
//
// Nämä ovat nyt Firebase Cloud Functions -exportteja.
//
// Flutter voi kutsua:
//
// FirebaseFunctions
//   .httpsCallable('getReferralStatus')
//
// FirebaseFunctions
//   .httpsCallable('validateReferralCode')
//
// ============================================================

exports.getReferralProfile =
  getReferralProfile;

exports.applyReferralCode =
  applyReferralCode;

exports.getReferredUsers =
  getReferredUsers;

exports.getReferralStatus =
  getReferralStatus;

exports.getReferralDashboard =
  getReferralDashboard;

exports.validateReferralCode =
  validateReferralCode;


// ============================================================
// 🐱 END OF STELLURIINI CLOUD FUNCTIONS
// ============================================================