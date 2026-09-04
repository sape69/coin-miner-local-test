"use strict";

// ============================================================
// 🐱 STELLA HISTORY SERVICE
// ============================================================
//
// Vastaa:
//
// 📜 Käyttäjän tapahtumahistorian referensseistä
// 📅 Daily-tapahtumien referensseistä
//
// ============================================================


// ============================================================
// USER UTILITIES
// ============================================================

const {
  getHistoryCollection,
} = require(
  "../utils/userUtils"
);


// ============================================================
// 🐱 CREATE STELLA HISTORY ENTRY
// ============================================================

function createHistoryRef(uid) {

  return getHistoryCollection(uid)
    .doc();

}


// ============================================================
// 📅 DAILY HISTORY
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