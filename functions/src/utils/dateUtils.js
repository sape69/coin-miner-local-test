"use strict";


// ============================================================
// 🐱 STELLA DATE UTILITIES
// ============================================================
//
// Yhteiset päivämäärä- ja aikafunktiot.
//
// Käytetään:
//
// 📅 Daily Check-In
// 📺 Ad Rewards
// ⏱️ Cooldownien tarkistamiseen
//
// Kaikki päivämäärät käsitellään turvallisesti
// palvelimen ajalla.
//
// ============================================================


// ============================================================
// 📅 GET DATE KEY
// ============================================================
//
// Palauttaa päivämäärän muodossa:
//
// YYYY-MM-DD
//
// Esimerkiksi:
//
// 2026-09-04
//
// ============================================================

function getDateKey(
  date = new Date()
) {

  const year =
    date.getUTCFullYear();


  const month =
    String(
      date.getUTCMonth() + 1
    ).padStart(
      2,
      "0"
    );


  const day =
    String(
      date.getUTCDate()
    ).padStart(
      2,
      "0"
    );


  return `${year}-${month}-${day}`;

}


// ============================================================
// ⏱️ GET TIME FROM VALUE
// ============================================================
//
// Muuntaa eri aikamuodot Date-objektiksi.
//
// Tukee:
//
// 🔥 Firestore Timestamp
// 📅 JavaScript Date
// 🔢 Milliseconds
//
// ============================================================

function getDateFromValue(
  value
) {

  if (!value) {

    return null;

  }


  // ==========================================================
  // 🔥 FIRESTORE TIMESTAMP
  // ==========================================================

  if (
    typeof value.toDate ===
    "function"
  ) {

    const date =
      value.toDate();


    return isNaN(
      date.getTime()
    )
      ? null
      : date;

  }


  // ==========================================================
  // 📅 JAVASCRIPT DATE
  // ==========================================================

  if (
    value instanceof Date
  ) {

    return isNaN(
      value.getTime()
    )
      ? null
      : value;

  }


  // ==========================================================
  // 🔢 NUMBER / STRING
  // ==========================================================

  const date =
    new Date(value);


  return isNaN(
    date.getTime()
  )
    ? null
    : date;

}


// ============================================================
// ⏳ GET ELAPSED MILLISECONDS
// ============================================================
//
// Laskee kuinka paljon aikaa on kulunut.
//
// ============================================================

function getElapsedMilliseconds(
  startDate,
  now = new Date()
) {

  const start =
    getDateFromValue(
      startDate
    );


  if (!start) {

    return 0;

  }


  return Math.max(
    0,
    now.getTime() -
      start.getTime()
  );

}


// ============================================================
// 📤 EXPORTS
// ============================================================

module.exports = {

  getDateKey,

  getDateFromValue,

  getElapsedMilliseconds,

};