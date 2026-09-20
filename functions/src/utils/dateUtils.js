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
// ⛏️ Stella Mining
//
// Kaikki päivämääräavaimet käsitellään UTC-ajassa.
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
// 2026-09-05
//
// ============================================================

function getDateKey(
  date = new Date(),
) {
  const safeDate =
    getDateFromValue(
      date,
    ) ||
    new Date();


  const year =
    safeDate.getUTCFullYear();


  const month =
    String(
      safeDate.getUTCMonth() + 1,
    ).padStart(
      2,
      "0",
    );


  const day =
    String(
      safeDate.getUTCDate(),
    ).padStart(
      2,
      "0",
    );


  return `${year}-${month}-${day}`;
}


// ============================================================
// 📅 GET UTC DATE STRING
// ============================================================
//
// Palauttaa tämänhetkisen UTC-päivän:
//
// YYYY-MM-DD
//
// ============================================================

function getUtcDateString() {
  return getDateKey(
    new Date(),
  );
}


// ============================================================
// 📅 GET YESTERDAY UTC DATE STRING
// ============================================================
//
// Palauttaa eilisen UTC-päivän:
//
// YYYY-MM-DD
//
// Käytetään erityisesti Daily Streakin laskentaan.
//
// ============================================================

function getYesterdayUtcDateString() {
  const yesterday =
    new Date();


  yesterday.setUTCDate(
    yesterday.getUTCDate() - 1,
  );


  return getDateKey(
    yesterday,
  );
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
// 📝 Date-string
//
// Virheellinen arvo palauttaa null.
//
// ============================================================

function getDateFromValue(
  value,
) {
  if (
    value === null ||
    value === undefined ||
    value === ""
  ) {
    return null;
  }


  // ==========================================================
  // 🔥 FIRESTORE TIMESTAMP
  // ==========================================================

  if (
    typeof value.toDate ===
    "function"
  ) {
    try {
      const date =
        value.toDate();


      if (
        date instanceof Date &&
        !Number.isNaN(
          date.getTime(),
        )
      ) {
        return date;
      }
    } catch (
      error
    ) {
      return null;
    }


    return null;
  }


  // ==========================================================
  // 📅 JAVASCRIPT DATE
  // ==========================================================

  if (
    value instanceof Date
  ) {
    return Number.isNaN(
      value.getTime(),
    )
      ? null
      : value;
  }


  // ==========================================================
  // 🔢 NUMBER
  // ==========================================================

  if (
    typeof value === "number"
  ) {
    if (
      !Number.isFinite(
        value,
      )
    ) {
      return null;
    }


    const date =
      new Date(
        value,
      );


    return Number.isNaN(
      date.getTime(),
    )
      ? null
      : date;
  }


  // ==========================================================
  // 📝 STRING
  // ==========================================================

  if (
    typeof value === "string"
  ) {
    const trimmed =
      value.trim();


    if (
      trimmed.length === 0
    ) {
      return null;
    }


    const date =
      new Date(
        trimmed,
      );


    return Number.isNaN(
      date.getTime(),
    )
      ? null
      : date;
  }


  // ==========================================================
  // ❌ UNSUPPORTED TYPE
  // ==========================================================

  return null;
}


// ============================================================
// ⏳ GET ELAPSED MILLISECONDS
// ============================================================
//
// Laskee kuinka paljon aikaa on kulunut.
//
// Virheelliset ajat palauttavat 0.
//
// Tulos ei voi olla negatiivinen.
//
// ============================================================

function getElapsedMilliseconds(
  startDate,
  now = new Date(),
) {
  const start =
    getDateFromValue(
      startDate,
    );


  const current =
    getDateFromValue(
      now,
    );


  if (
    !start ||
    !current
  ) {
    return 0;
  }


  return Math.max(
    0,
    current.getTime() -
      start.getTime(),
  );
}


// ============================================================
// 📦 EXPORTS
// ============================================================

module.exports = {
  // ----------------------------------------
  // 📅 DATE
  // ----------------------------------------

  getDateKey,

  getUtcDateString,

  getYesterdayUtcDateString,


  // ----------------------------------------
  // ⏱️ TIME
  // ----------------------------------------

  getDateFromValue,

  getElapsedMilliseconds,
};