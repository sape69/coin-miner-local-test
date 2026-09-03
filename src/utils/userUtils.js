"use strict";

// ============================================================
// 🐱 STELLA USER UTILITIES
// ============================================================
//
// Vastaa:
//
// 👤 Käyttäjän Firestore-referenssistä
// 📜 Käyttäjän tapahtumahistoriasta
// 🎁 AdMob Reward -referensseistä
//
// ============================================================


// ============================================================
// FIREBASE
// ============================================================

const {
  db,
} = require(
  "../firebase/firebase"
);


// ============================================================
// 👤 USER DOCUMENT
// ============================================================

function getUserRef(uid) {

  return db
    .collection("users")
    .doc(uid);

}


// ============================================================
// 📜 TRANSACTION HISTORY COLLECTION
// ============================================================

function getHistoryCollection(uid) {

  return getUserRef(uid)
    .collection("transactions");

}


// ============================================================
// 🎁 ADMOB REWARD DOCUMENT
// ============================================================

function getAdMobRewardRef(
  transactionId
) {

  return db
    .collection("admobRewards")
    .doc(transactionId);

}


// ============================================================
// 📦 EXPORTS
// ============================================================

module.exports = {

  getUserRef,

  getHistoryCollection,

  getAdMobRewardRef,

};