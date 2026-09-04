"use strict";


// ============================================================
// 🐱 STELLA DATE UTILITIES
// ============================================================
//
// Yhteiset päivämääräfunktiot Stella Backendille.
//
// Kaikki Daily- ja Ad-järjestelmien päivät
// käsitellään UTC-ajassa.
//
// ============================================================


// ============================================================
// 🗓️ GET UTC DATE STRING
// ============================================================
//
// Palauttaa tämän päivän UTC-muodossa:
//
// YYYY-MM-DD
//
// Esimerkki:
//
// 2026-09-04
//
// ============================================================

function getUtcDateString() {

  return new Date()
    .toISOString()
    .substring(0, 10);

}


// ============================================================
// 🗓️ GET YESTERDAY UTC DATE STRING
// ============================================================
//
// Palauttaa eilisen UTC-päivän muodossa:
//
// YYYY-MM-DD
//
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
// 📦 EXPORTS
// ============================================================

module.exports = {

  getUtcDateString,

  getYesterdayUtcDateString,

};