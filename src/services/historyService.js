"use strict";

const {
  getHistoryCollection,
} = require(
  "../firebase/firebase"
);


// ============================================================
// 🐱 CREATE STELLA HISTORY ENTRY
// ============================================================

function createHistoryRef(uid) {
  return getHistoryCollection(uid)
    .doc();
}


// ============================================================
// DAILY HISTORY
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
// EXPORTS
// ============================================================

module.exports = {

  createHistoryRef,

  createDailyHistoryRef,

};