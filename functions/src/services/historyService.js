"use strict";


// ============================================================
// 🐱 STELLA HISTORY SERVICE
// ============================================================
//
// Vastaa Stella-tapahtumahistorian
// Firestore-referenceista.
//
// ============================================================


const {
  getHistoryCollection,
} = require(
  "../utils/userUtils"
);


// ============================================================
// 🐱 CREATE HISTORY REFERENCE
// ============================================================
//
// Luo uuden automaattisen Transaction ID:n.
//
// Polku:
//
// users/{uid}/transactions/{transactionId}
//
// ============================================================

function createHistoryRef(uid) {

  return getHistoryCollection(uid)
    .doc();

}


// ============================================================
// 🎁 CREATE DAILY HISTORY REFERENCE
// ============================================================
//
// Luo päivittäiselle tapahtumalle
// vakio-ID:n.
//
// Tämä auttaa estämään saman Daily Rewardin
// tallentamisen useita kertoja.
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