"use strict";

// ============================================================
// 🐱 STELLA USER UTILITIES
// ============================================================
//
// Keskitetyt käyttäjä- ja Firestore-apufunktiot.
//
// Vastaa:
//
// 👤 Käyttäjän Firestore-referenssistä
// 📜 Käyttäjän tapahtumahistoriasta
// 🎁 AdMob Reward -referenssistä
//
// Kaikki Firestore-polut pidetään tässä tiedostossa,
// jotta muu backend käyttää samoja polkuja keskitetysti.
//
// ============================================================


// ============================================================
// 🔥 FIREBASE
// ============================================================

const {
  db,
} = require(
  "../firebase/firebase"
);


// ============================================================
// 👤 USER DOCUMENT
// ============================================================
//
// Firestore:
//
// users/{uid}
//
// ============================================================

function getUserRef(
  uid
) {
  return db
    .collection("users")
    .doc(uid);
}


// ============================================================
// 📜 TRANSACTION HISTORY COLLECTION
// ============================================================
//
// Firestore:
//
// users/{uid}/transactions
//
// ============================================================

function getHistoryCollection(
  uid
) {
  return getUserRef(uid)
    .collection("transactions");
}


// ============================================================
// 🎁 ADMOB REWARD DOCUMENT
// ============================================================
//
// Firestore:
//
// admobRewards/{transactionId}
//
// AdMob transaction ID toimii dokumentin ID:nä.
//
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