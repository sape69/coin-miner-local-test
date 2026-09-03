"use strict";

const {
  initializeApp,
  getApps,
} = require("firebase-admin/app");

const {
  getFirestore,
} = require("firebase-admin/firestore");


// ============================================================
// 🐱 INITIALIZE FIREBASE
// ============================================================

if (getApps().length === 0) {
  initializeApp();
}


// ============================================================
// FIRESTORE
// ============================================================

const db =
  getFirestore();


// ============================================================
// USER REFERENCE
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

  db,

  getUserRef,

  getHistoryCollection,

  getAdMobRewardRef,

};