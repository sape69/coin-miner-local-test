"use strict";

const {
  db,
} = require("../firebase/firebase");


// ============================================================
// 🐱 STELLA USER REFERENCES
// ============================================================


// ============================================================
// USER DOCUMENT
// ============================================================

function getUserRef(uid) {
  return db
    .collection("users")
    .doc(uid);
}


// ============================================================
// TRANSACTION HISTORY
// ============================================================

function getHistoryCollection(uid) {
  return getUserRef(uid)
    .collection("transactions");
}


// ============================================================
// ADMOB REWARDS
// ============================================================

function getAdMobRewardRef(
  transactionId
) {
  return db
    .collection("admobRewards")
    .doc(transactionId);
}


// ============================================================
// EXPORTS
// ============================================================

module.exports = {
  getUserRef,
  getHistoryCollection,
  getAdMobRewardRef,
};