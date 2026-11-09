
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
} = require("./src/functions/miningFunctions");


// ============================================================
// 🎁 DAILY CHECK-IN
// ============================================================

const {
  dailyCheckIn,
} = require("./src/functions/dailyFunctions");


// ============================================================
// 📺 ADMOB SSV
// ============================================================

const {
  adMobReward,
} = require("./src/functions/adFunctions");


// ============================================================
// 📜 TRANSACTION HISTORY
// ============================================================

const {
  getTransactionHistory,
} = require("./src/functions/historyFunctions");


// ============================================================
// 🏆 ACHIEVEMENTS
// ============================================================

const {
  getAchievements,
  getAchievementsCompleted,
} = require("./src/functions/achievementFunctions");


// ============================================================
// 👤 USER PROFILE
// ============================================================

const {
  ensureUserProfile,
  getUserProfile,
} = require("./src/functions/userFunctions");


// ============================================================
// 🗑️ ACCOUNT
// ============================================================

const {
  deleteAccount,
} = require("./src/functions/accountFunctions");


// ============================================================
// 🌐 ACCOUNT DELETION REQUEST
// ============================================================

const {
  requestAccountDeletion,
} = require("./src/functions/accountDeletionRequestFunctions");


// ============================================================
// 🔗 REFERRAL
// ============================================================

const {
  getReferralProfile,
  applyReferralCode,
  getReferredUsers,
  getReferralStatus,
  getReferralDashboard,
} = require("./src/functions/referralFunctions");


// ============================================================
// 🔍 REFERRAL CODE VALIDATION
// ============================================================

const {
  validateReferralCode,
} = require("./src/functions/validateReferralCode");


// ============================================================
// ⭐ GOOGLE PLAY SUBSCRIPTIONS
// ============================================================

const {
  verifyPlaySubscription,
  expirePremiumSubscriptions,
} = require("./src/functions/subscriptionFunctions");


// ============================================================
// ⛏️ MINING EXPORTS
// ============================================================

exports.getMiningStatus = getMiningStatus;
exports.claimMining = claimMining;
exports.powerBoost = powerBoost;


// ============================================================
// 🎁 DAILY CHECK-IN EXPORT
// ============================================================

exports.dailyCheckIn = dailyCheckIn;


// ============================================================
// 📺 ADMOB SSV EXPORT
// ============================================================

exports.adMobReward = adMobReward;


// ============================================================
// 📜 TRANSACTION HISTORY EXPORT
// ============================================================

exports.getTransactionHistory = getTransactionHistory;


// ============================================================
// 🏆 ACHIEVEMENT EXPORTS
// ============================================================

exports.getAchievements = getAchievements;
exports.getAchievementsCompleted = getAchievementsCompleted;


// ============================================================
// 👤 USER PROFILE EXPORTS
// ============================================================

exports.ensureUserProfile = ensureUserProfile;
exports.getUserProfile = getUserProfile;


// ============================================================
// 🗑️ ACCOUNT EXPORT
// ============================================================

exports.deleteAccount = deleteAccount;


// ============================================================
// 🌐 ACCOUNT DELETION REQUEST EXPORT
// ============================================================

exports.requestAccountDeletion = requestAccountDeletion;


// ============================================================
// 🔗 REFERRAL EXPORTS
// ============================================================

exports.getReferralProfile = getReferralProfile;
exports.applyReferralCode = applyReferralCode;
exports.getReferredUsers = getReferredUsers;
exports.getReferralStatus = getReferralStatus;
exports.getReferralDashboard = getReferralDashboard;
exports.validateReferralCode = validateReferralCode;


// ============================================================
// ⭐ GOOGLE PLAY SUBSCRIPTION EXPORTS
// ============================================================

exports.verifyPlaySubscription = verifyPlaySubscription;
exports.expirePremiumSubscriptions = expirePremiumSubscriptions;


// ============================================================
// 🐱 END OF STELLURIINI CLOUD FUNCTIONS
// ============================================================
