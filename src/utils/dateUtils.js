"use strict";


// ============================================================
// 🗓️ STELLA DATE UTILITIES
// ============================================================


// ============================================================
// TODAY UTC
// ============================================================

function getUtcDateString() {
  return new Date()
    .toISOString()
    .substring(0, 10);
}


// ============================================================
// YESTERDAY UTC
// ============================================================

function getYesterdayUtcDateString() {
  const date =
    new Date();

  date.setUTCDate(
    date.getUTCDate() - 1
  );

  return date
    .toISOString()
    .substring(0, 10);
}


// ============================================================
// EXPORTS
// ============================================================

module.exports = {

  getUtcDateString,

  getYesterdayUtcDateString,

};