"use strict";


// ============================================================
// 🐱 STELLA HISTORY UTILITIES
// ============================================================
//
// Vastaa:
//
// 📜 Transaction History -dokumenttien
// Firestore-referenceista.
//
// ============================================================


// ============================================================
// 👤 USER UTILITIES
// ============================================================

const {
  getHistoryCollection,
} = require(
  "./userUtils"
);


// ============================================================
// 🐱 CREATE STELLA HISTORY ENTRY
// ============================================================
//
// Luo uuden automaattisen Transaction History
// -dokumenttireferenssin.
//
// Firestore:
//
// users/{uid}/transactions/{transactionId}
//
// ============================================================

function createHistoryRef(uid) {

  return getHistoryCollection(uid)
    .doc();

}


// ============================================================
// 📅 DAILY HISTORY
// ============================================================
//
// Luo deterministisen Daily History -referenssin.
//
// Firestore:
//
// users/{uid}/transactions/daily_YYYY-MM-DD
//
// ============================================================

function createDailyHistoryRef(
  uid,
  date
) {

  return getHistoryCollection(uid)
    .doc(
      `daily_${date}`
    );

}


// ============================================================
// 📦 EXPORTS
// ============================================================

module.exports = {

  createHistoryRef,

  createDailyHistoryRef,

};