"use strict";

// ============================================================
// 🐱 STELLA MINING UTILITIES
// ============================================================
//
// Stella Miningin keskitetty laskentalogiikka.
//
// ⛏️ Reaaliaikainen louhinta
// ⏱️ 24 tunnin mining-jakso
// ⚡ Daily Hash Rate
// 💰 STL-tuoton laskenta
//
// Kaikki ajat perustuvat palvelimen aikaan.
//
// HUOM:
//
// Daily Hash Rate määritetään muualla
// Daily Streak -logiikassa.
//
// Power Boost käsitellään erillisenä
// väliaikaisena boostina miningFunctions.js:ssä.
//
// Tämä tiedosto laskee vain sille annetun
// Hash Raten perusteella syntyvän STL-tuoton.
//
// ============================================================


// ============================================================
// ⚙️ CONFIG
// ============================================================

const {
  MINING_PER_HASH_PER_HOUR,
} = require(
  "../config/miningConfig"
);


// ============================================================
// 🧮 SAFE HASH RATE
// ============================================================
//
// Muuntaa Hash Raten turvallisesti numeroksi.
//
// 0 on sallittu arvo.
//
// Jos arvo on virheellinen,
// käytetään arvoa 0.
//
// Emme käytä enää vanhaa
// DEFAULT_HASH_RATE-arvoa.
//
// ============================================================

function getSafeHashRate(
  value
) {

  const number =
    Number(value);


  if (
    Number.isFinite(number) &&
    number >= 0
  ) {

    return number;

  }


  return 0;

}


// ============================================================
// 🧮 SAFE ELAPSED TIME
// ============================================================
//
// Muuntaa kuluneen ajan turvallisesti
// ei-negatiiviseksi millisekuntiarvoksi.
//
// ============================================================

function getSafeElapsedMilliseconds(
  value
) {

  const number =
    Number(value);


  if (
    Number.isFinite(number) &&
    number >= 0
  ) {

    return number;

  }


  return 0;

}


// ============================================================
// ⛏️ CALCULATE MINING
// ============================================================
//
// Laskee kuinka paljon STL:ää syntyy
// tietyn ajan aikana.
//
// Kaava:
//
// Hash Rate
// × STL / Hash Rate / tunti
// × tunnit
//
// Esimerkiksi:
//
// 3.5 HR × 0.10 STL/HR/h × 24 h
// = 8.4 STL
//
// ============================================================

function calculateMining(
  hashRate,
  elapsedMilliseconds
) {

  const safeHashRate =
    getSafeHashRate(
      hashRate
    );


  const safeElapsedMilliseconds =
    getSafeElapsedMilliseconds(
      elapsedMilliseconds
    );


  const hours =
    safeElapsedMilliseconds /
    (1000 * 60 * 60);


  const minedAmount =
    safeHashRate *
    MINING_PER_HASH_PER_HOUR *
    hours;


  return Math.max(
    0,
    minedAmount
  );

}


// ============================================================
// ⏱️ GET MINING START TIME
// ============================================================
//
// Hakee mining-jakson aloitusajan.
//
// Tukee:
//
// 🔥 Firestore Timestamp
// 📅 JavaScript Date
//
// ============================================================

function getMiningStartTime(
  data
) {

  const timestamp =
    data?.miningStartedAt;


  // ==========================================================
  // 🔥 FIRESTORE TIMESTAMP
  // ==========================================================

  if (
    timestamp &&
    typeof timestamp.toDate ===
      "function"
  ) {

    const date =
      timestamp.toDate();


    if (
      date instanceof Date &&
      !Number.isNaN(
        date.getTime()
      )
    ) {

      return date;

    }


    return null;

  }


  // ==========================================================
  // 📅 JAVASCRIPT DATE
  // ==========================================================

  if (
    timestamp instanceof Date
  ) {

    return Number.isNaN(
      timestamp.getTime()
    )
      ? null
      : timestamp;

  }


  return null;

}


// ============================================================
// ⏱️ GET MINING END TIME
// ============================================================
//
// Hakee mining-jakson päättymisajan.
//
// Tukee:
//
// 🔥 Firestore Timestamp
// 📅 JavaScript Date
//
// ============================================================

function getMiningEndTime(
  data
) {

  const timestamp =
    data?.miningEndsAt;


  // ==========================================================
  // 🔥 FIRESTORE TIMESTAMP
  // ==========================================================

  if (
    timestamp &&
    typeof timestamp.toDate ===
      "function"
  ) {

    const date =
      timestamp.toDate();


    if (
      date instanceof Date &&
      !Number.isNaN(
        date.getTime()
      )
    ) {

      return date;

    }


    return null;

  }


  // ==========================================================
  // 📅 JAVASCRIPT DATE
  // ==========================================================

  if (
    timestamp instanceof Date
  ) {

    return Number.isNaN(
      timestamp.getTime()
    )
      ? null
      : timestamp;

  }


  return null;

}


// ============================================================
// 🐱 CALCULATE MINING STATUS
// ============================================================
//
// Palauttaa Stella Miningin nykyisen tilanteen.
//
// ============================================================

function calculateMiningStatus(
  data,
  now = new Date()
) {

  // ==========================================================
  // ⚡ HASH RATE
  // ==========================================================

  const hashRate =
    getSafeHashRate(
      data?.hashRate
    );


  // ==========================================================
  // ⏱️ MINING TIMES
  // ==========================================================

  const miningStartedAt =
    getMiningStartTime(
      data
    );


  const miningEndsAt =
    getMiningEndTime(
      data
    );


  // ==========================================================
  // 💤 NO MINING
  // ==========================================================

  if (
    !miningStartedAt ||
    !miningEndsAt
  ) {

    return {

      miningActive:
        false,

      miningFinished:
        false,

      elapsedMs:
        0,

      miningRemainingMs:
        0,

      minedAmount:
        0,

      hashRate,

      miningStartedAt:
        null,

      miningEndsAt:
        null,

    };

  }


  // ==========================================================
  // 🕒 TIMES IN MILLISECONDS
  // ==========================================================

  const nowMs =
    now.getTime();


  const startMs =
    miningStartedAt.getTime();


  const endMs =
    miningEndsAt.getTime();


  // ==========================================================
  // 🛡️ INVALID DATES
  // ==========================================================

  if (
    !Number.isFinite(
      nowMs
    ) ||
    !Number.isFinite(
      startMs
    ) ||
    !Number.isFinite(
      endMs
    ) ||
    endMs <= startMs
  ) {

    return {

      miningActive:
        false,

      miningFinished:
        false,

      elapsedMs:
        0,

      miningRemainingMs:
        0,

      minedAmount:
        0,

      hashRate,

      miningStartedAt,

      miningEndsAt,

    };

  }


  // ==========================================================
  // ⏳ BEFORE START
  // ==========================================================

  if (
    nowMs < startMs
  ) {

    return {

      miningActive:
        true,

      miningFinished:
        false,

      elapsedMs:
        0,

      miningRemainingMs:
        endMs -
        startMs,

      minedAmount:
        0,

      hashRate,

      miningStartedAt,

      miningEndsAt,

    };

  }


  // ==========================================================
  // 🐱⛏️ ACTIVE MINING
  // ==========================================================

  if (
    nowMs < endMs
  ) {

    const elapsedMs =
      nowMs -
      startMs;


    const remainingMs =
      endMs -
      nowMs;


    return {

      miningActive:
        true,

      miningFinished:
        false,

      elapsedMs,

      miningRemainingMs:
        remainingMs,

      minedAmount:
        calculateMining(
          hashRate,
          elapsedMs
        ),

      hashRate,

      miningStartedAt,

      miningEndsAt,

    };

  }


  // ==========================================================
  // ✨ MINING FINISHED
  // ==========================================================

  const fullDurationMs =
    endMs -
    startMs;


  return {

    miningActive:
      false,

    miningFinished:
      true,

    elapsedMs:
      fullDurationMs,

    miningRemainingMs:
      0,

    minedAmount:
      calculateMining(
        hashRate,
        fullDurationMs
      ),

    hashRate,

    miningStartedAt,

    miningEndsAt,

  };

}


// ============================================================
// 📦 EXPORTS
// ============================================================

module.exports = {

  calculateMining,

  getMiningStartTime,

  getMiningEndTime,

  calculateMiningStatus,

};