"use strict";

// ============================================================
// 🐱 STELLA HISTORY SERVICE
// ============================================================
//
// Vastaa Stella-tapahtumahistorian Firestore-referenceista.
//
// Tämä service:
//
// 👤 käyttää käyttäjän history collectionia
// 🆔 luo automaattisia transaction ID:itä
// 🎁 luo Daily History -dokumenttien vakio-ID:t
//
// TÄMÄ TIEDOSTO EI:
//
// ❌ muuta käyttäjän saldoa
// ❌ aktivoi Power Boostia
// ❌ käynnistä Mining Startia
// ❌ käsittele AdMob SSV:tä
// ❌ kirjoita Firestore-dataa
//
// ============================================================


// ============================================================
// 👤 USER UTILITIES
// ============================================================

const {
  getHistoryCollection,
} = require(
  "../utils/userUtils",
);


// ============================================================
// 🗓️ VALIDATE HISTORY DATE
// ============================================================
//
// Daily History käyttää päivämäärää dokumentin ID:ssä.
//
// Odotettu muoto:
//
// YYYY-MM-DD
//
// Esimerkiksi:
//
// 2026-09-19
//
// Dokumentin ID:ssä ei saa olla "/"-merkkejä
// tai muuta odottamatonta rakennetta.
//
// ============================================================

function validateHistoryDate(
  date,
) {
  if (
    typeof date !==
    "string"
  ) {
    const error =
      new Error(
        "date must be a string.",
      );

    error.code =
      "HISTORY_INVALID_DATE";

    throw error;
  }

  const value =
    date.trim();

  // ----------------------------------------------------------
  // FORMAT
  // ----------------------------------------------------------

  if (
    !/^\d{4}-\d{2}-\d{2}$/.test(
      value,
    )
  ) {
    const error =
      new Error(
        "date must use YYYY-MM-DD format.",
      );

    error.code =
      "HISTORY_INVALID_DATE";

    throw error;
  }

  // ----------------------------------------------------------
  // CALENDAR VALIDATION
  // ----------------------------------------------------------

  const [
    yearString,
    monthString,
    dayString,
  ] =
    value.split("-");

  const year =
    Number(
      yearString,
    );

  const month =
    Number(
      monthString,
    );

  const day =
    Number(
      dayString,
    );

  const dateObject =
    new Date(
      Date.UTC(
        year,
        month - 1,
        day,
      ),
    );

  if (
    Number.isNaN(
      dateObject.getTime(),
    ) ||
    dateObject.getUTCFullYear() !==
      year ||
    dateObject.getUTCMonth() !==
      month - 1 ||
    dateObject.getUTCDate() !==
      day
  ) {
    const error =
      new Error(
        "date is not a valid calendar date.",
      );

    error.code =
      "HISTORY_INVALID_DATE";

    throw error;
  }

  return value;
}


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
// Firestore luo dokumentille automaattisen ID:n.
//
// HUOM:
//
// Tämä funktio EI kirjoita Firestoreen.
// Se ainoastaan palauttaa uuden DocumentReference-olion.
//
// ============================================================

function createHistoryRef(
  uid,
) {
  return getHistoryCollection(
    uid,
  ).doc();
}


// ============================================================
// 🎁 CREATE DAILY HISTORY REFERENCE
// ============================================================
//
// Luo päivittäiselle tapahtumalle
// vakio-ID:n.
//
// Esimerkiksi:
//
// users/{uid}/transactions/daily_2026-09-19
//
// Tämä mahdollistaa saman Daily Rewardin
// idempotentin käsittelyn.
//
// HUOM:
//
// Tämä funktio EI kirjoita Firestoreen.
// Se ainoastaan palauttaa DocumentReference-olion.
//
// ============================================================

function createDailyHistoryRef(
  uid,
  date,
) {
  const validDate =
    validateHistoryDate(
      date,
    );

  return getHistoryCollection(
    uid,
  ).doc(
    `daily_${validDate}`,
  );
}


// ============================================================
// 📦 EXPORTS
// ============================================================

module.exports = {
  createHistoryRef,
  createDailyHistoryRef,
  validateHistoryDate,
};