"use strict";

const {
  getMiningStatus,
  claimMining,
} = require("./src/functions/miningFunctions");

const {
  dailyCheckIn,
} = require("./src/functions/dailyFunctions");

const {
  testAdReward,
  adMobReward,
} = require("./src/functions/adFunctions");

const {
  getTransactionHistory,
} = require("./src/functions/historyFunctions");

const {
  getAchievements,
  getAchievementsCompleted,
} = require("./src/functions/achievementFunctions");

exports.getMiningStatus = getMiningStatus;
exports.claimMining = claimMining;

exports.dailyCheckIn = dailyCheckIn;

exports.testAdReward = testAdReward;
exports.adMobReward = adMobReward;

exports.getTransactionHistory = getTransactionHistory;

exports.getAchievements = getAchievements;
exports.getAchievementsCompleted = getAchievementsCompleted;