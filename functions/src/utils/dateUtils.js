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
// TÄRKEÄÄ:
//
// Virheellistä eksplisiittisesti annettua päivämäärää
// ei muuteta hiljaa nykyhetkeksi.
//
// Tämä estää esimerkiksi Daily Streakin,
// cooldownin tai reward-päivän muuttumisen vääräksi
// päivämääräksi virheellisen timestampin vuoksi.
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
// Jos funktiolle ei anneta arvoa,
// käytetään nykyhetkeä.
//
// Jos eksplisiittisesti annettu arvo on virheellinen,
// palautetaan null.
//
// ============================================================

function getDateKey(
  date,
) {
  const hasExplicitValue =
    arguments.length > 0;


  const safeDate =
    hasExplicitValue
      ? getDateFromValue(
          date,
        )
      : new Date();


  if (
    !safeDate
  ) {
    return null;
  }


  const timestamp =
    safeDate.getTime();


  if (
    !Number.isFinite(
      timestamp,
    )
  ) {
    return null;
  }


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
  // 📅 JAVASCRIPT DATE
  // ==========================================================

  if (
    value instanceof Date
  ) {
    const timestamp =
      value.getTime();


    if (
      !Number.isFinite(
        timestamp,
      )
    ) {
      return null;
    }


    // Palautetaan kopio, jotta alkuperäistä Date-oliota
    // ei voida muuttaa tämän utilin kautta.
    return new Date(
      timestamp,
    );
  }


  // ==========================================================
  // 🔥 FIRESTORE TIMESTAMP
  // ==========================================================

  if (
    value &&
    typeof value.toDate ===
      "function"
  ) {
    try {
      const date =
        value.toDate();


      if (
        date instanceof Date
      ) {
        const timestamp =
          date.getTime();


        if (
          Number.isFinite(
            timestamp,
          )
        ) {
          return new Date(
            timestamp,
          );
        }
      }
    } catch (
      error
    ) {
      return null;
    }


    return null;
  }


  // ==========================================================
  // 🔢 NUMBER
  // ==========================================================

  if (
    typeof value ===
    "number"
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


    if (
      !Number.isFinite(
        date.getTime(),
      )
    ) {
      return null;
    }


    return date;
  }


  // ==========================================================
  // 📝 STRING
  // ==========================================================

  if (
    typeof value ===
    "string"
  ) {
    const trimmed =
      value.trim();


    if (
      trimmed.length ===
      0
    ) {
      return null;
    }


    const date =
      new Date(
        trimmed,
      );


    if (
      !Number.isFinite(
        date.getTime(),
      )
    ) {
      return null;
    }


    return date;
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


  const startMs =
    start.getTime();


  const currentMs =
    current.getTime();


  if (
    !Number.isFinite(
      startMs,
    ) ||
    !Number.isFinite(
      currentMs,
    )
  ) {
    return 0;
  }


  return Math.max(
    0,
    currentMs -
      startMs,
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