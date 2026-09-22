"use strict";

// ============================================================
// 🐱 STELLURIINI - MINING UTILITIES
// ============================================================
//
// Keskitetty Stelluriini Mining -laskentalogiikka.
//
// Vastuu:
//
// ⛏️ Mining-tuoton laskeminen
// ⏱️ Mining-ajan käsittely
// ⚡ Mining Hash Rate -arvon turvallinen käsittely
// 📅 Firestore Timestamp / Date / ISO / milliseconds
// 🐱 Mining-status
//
// TÄMÄ TIEDOSTO EI:
//
// ❌ kirjoita Firestoreen
// ❌ lisää STL-saldoa
// ❌ käsittele Daily Streakia
// ❌ käsittele Power Boostia
// ❌ muuta adsToday-arvoa
// ❌ muuta cooldownia
// ❌ käynnistä mining-jaksoa
//
// Daily Hash Rate määritetään miningFunctions.js:ssä.
//
// Power Boost käsitellään erillisenä väliaikaisena
// boostina miningFunctions.js:ssä.
//
// Tämä tiedosto laskee vain sille annetun
// Mining Hash Raten perusteella syntyvän STL-tuoton.
//
// TÄRKEÄÄ:
//
// Mining-syklin Hash Rate kuuluu kyseiselle syklille.
//
// Tämä utility EI saa:
//
// - muodostaa uutta Hash Ratea
// - periä vanhan cyclen Hash Ratea uuteen cycleen
// - laskea Daily Streakiä
// - käyttää Power Boostia
//
// Business-kerros päättää, mikä Hash Rate kuuluu
// kyseiseen mining-cycleen.
// ============================================================


// ============================================================
// ⚙️ CONFIG
// ============================================================

const {
  MINING_PER_HASH_PER_HOUR,
} = require("../config/miningConfig");


// ============================================================
// 🧮 SAFE HASH RATE
// ============================================================
//
// Muuntaa Hash Raten turvallisesti numeroksi.
//
// Sallittu:
//
// 0
// positiivinen numero
//
// Negatiivinen, NaN tai Infinity
// palautetaan arvona 0.
//
// HUOM:
//
// Tämä on matalan tason utility.
//
// Se EI päätä, onko 0 kelvollinen
// aktiiviselle mining-cyclelle.
//
// ============================================================

function getSafeHashRate(value) {
  const number = Number(value);

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
// ei-negatiiviseksi millisekunniksi.
//
// ============================================================

function getSafeElapsedMilliseconds(value) {
  const number = Number(value);

  if (
    Number.isFinite(number) &&
    number >= 0
  ) {
    return number;
  }

  return 0;
}


// ============================================================
// 🕒 SAFE DATE
// ============================================================
//
// Muuntaa tuetut aikamuodot Date-objektiksi.
//
// Tukee:
//
// 🔥 Firestore Timestamp
// 📅 JavaScript Date
// 📝 ISO Date String
// 🔢 Unix milliseconds
//
// Virheellinen arvo palauttaa null.
//
// ============================================================

function getSafeDate(value) {
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

  if (value instanceof Date) {
    const milliseconds =
      value.getTime();

    if (
      !Number.isFinite(milliseconds)
    ) {
      return null;
    }

    return new Date(milliseconds);
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

      if (!(date instanceof Date)) {
        return null;
      }

      const milliseconds =
        date.getTime();

      if (
        !Number.isFinite(milliseconds)
      ) {
        return null;
      }

      return new Date(milliseconds);
    } catch (error) {
      return null;
    }
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

    if (!trimmed) {
      return null;
    }

    const date =
      new Date(trimmed);

    const milliseconds =
      date.getTime();

    if (
      !Number.isFinite(milliseconds)
    ) {
      return null;
    }

    return date;
  }


  // ==========================================================
  // 🔢 UNIX MILLISECONDS
  // ==========================================================

  if (
    typeof value === "number" &&
    Number.isFinite(value)
  ) {
    const date =
      new Date(value);

    const milliseconds =
      date.getTime();

    if (
      !Number.isFinite(milliseconds)
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
// 🕒 GET SAFE CURRENT DATE
// ============================================================
//
// Varmistaa, että mining-status saa aina
// käyttöönsä kelvollisen Date-objektin.
//
// ============================================================

function getSafeNow(value) {
  const date =
    getSafeDate(value);

  return date || new Date();
}


// ============================================================
// 💰 SAFE MINING RATE
// ============================================================
//
// Muuntaa configista tulevan STL-tuottokertoimen
// turvalliseksi positiiviseksi numeroksi.
//
// ============================================================

function getSafeMiningRate() {
  const number =
    Number(
      MINING_PER_HASH_PER_HOUR
    );

  if (
    Number.isFinite(number) &&
    number > 0
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
// annetulla Mining Hash Ratella annetun ajan aikana.
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
// TÄRKEÄÄ:
//
// Tämä funktio EI rajoita aikaa
// MINING_DURATION_MS-arvoon.
//
// Kutsuvan toiminnon täytyy antaa oikea aikaväli.
//
// Tätä samaa funktiota voidaan käyttää:
//
// - normaalin mining-ajan laskemiseen
// - Power Boost -ajan laskemiseen
//
// Power Boostin logiikka ei kuulu tähän tiedostoon.
//
// ============================================================

function calculateMining(
  hashRate,
  elapsedMilliseconds
) {
  const safeHashRate =
    getSafeHashRate(hashRate);

  const safeElapsedMilliseconds =
    getSafeElapsedMilliseconds(
      elapsedMilliseconds
    );

  const safeMiningRate =
    getSafeMiningRate();

  if (
    safeHashRate <= 0 ||
    safeElapsedMilliseconds <= 0 ||
    safeMiningRate <= 0
  ) {
    return 0;
  }

  const hours =
    safeElapsedMilliseconds /
    (1000 * 60 * 60);

  if (
    !Number.isFinite(hours) ||
    hours <= 0
  ) {
    return 0;
  }

  const minedAmount =
    safeHashRate *
    safeMiningRate *
    hours;

  if (
    !Number.isFinite(minedAmount) ||
    minedAmount < 0
  ) {
    return 0;
  }

  return minedAmount;
}


// ============================================================
// ⏱️ GET MINING START TIME
// ============================================================

function getMiningStartTime(data) {
  if (
    !data ||
    typeof data !== "object"
  ) {
    return null;
  }

  return getSafeDate(
    data.miningStartedAt
  );
}


// ============================================================
// ⏱️ GET MINING END TIME
// ============================================================

function getMiningEndTime(data) {
  if (
    !data ||
    typeof data !== "object"
  ) {
    return null;
  }

  return getSafeDate(
    data.miningEndsAt
  );
}


// ============================================================
// ⚡ GET MINING HASH RATE
// ============================================================
//
// Palauttaa olemassa olevan mining-cyclen Hash Raten.
//
// Ensisijainen kenttä:
//
// miningHashRate
//
// TÄRKEÄÄ:
//
// Jos miningHashRate-kenttä löytyy, sitä käytetään
// ainoana lähteenä.
//
// Jos miningHashRate on olemassa mutta virheellinen,
// palautetaan 0.
//
// Tällöin utility EI saa käyttää hashRate-kenttää
// varakenttänä.
//
// Tämä estää tilanteen:
//
// Vanha miningHashRate = virheellinen
// Uusi hashRate = Daily Hash Rate
//
// jolloin vanha cycle voisi vahingossa saada uuden
// cyclen Hash Raten.
//
// ============================================================

function getMiningHashRate(data) {
  if (
    !data ||
    typeof data !== "object"
  ) {
    return 0;
  }


  // ==========================================================
  // ⚡ CURRENT MINING CYCLE HASH RATE
  // ==========================================================

  if (
    Object.prototype.hasOwnProperty.call(
      data,
      "miningHashRate"
    )
  ) {
    return getSafeHashRate(
      data.miningHashRate
    );
  }


  // ==========================================================
  // 🔒 NO MINING CYCLE HASH RATE
  // ==========================================================
  //
  // Älä muodosta Hash Ratea hashRate-kentästä.
  //
  // Business-kerros päättää erikseen uuden mining-cyclen
  // Hash Raten.
  //
  // Tämä utility käsittelee vain olemassa olevan
  // mining-cyclen tietoja.
  //
  // ==========================================================

  return 0;
}


// ============================================================
// 🐱 CALCULATE MINING STATUS
// ============================================================
//
// Palauttaa Stella Miningin nykyisen tilanteen.
//
// Palauttaa:
//
// miningActive
// miningFinished
// elapsedMs
// miningRemainingMs
// minedAmount
// hashRate
// miningHashRate
// miningStartedAt
// miningEndsAt
//
// HUOM:
//
// minedAmount sisältää vain annetun Mining Hash Raten
// perusteella lasketun peruslouhinnan.
//
// Power Boost lasketaan miningFunctions.js:ssä.
//
// ============================================================

function calculateMiningStatus(
  data,
  now = new Date()
) {
  const safeData =
    data &&
    typeof data === "object"
      ? data
      : {};


  // ==========================================================
  // ⚡ MINING HASH RATE
  // ==========================================================

  const miningHashRate =
    getMiningHashRate(
      safeData
    );

  const hashRate =
    miningHashRate;


  // ==========================================================
  // ⏱️ MINING TIMES
  // ==========================================================

  const miningStartedAt =
    getMiningStartTime(
      safeData
    );

  const miningEndsAt =
    getMiningEndTime(
      safeData
    );


  // ==========================================================
  // 💤 NO MINING DATA
  // ==========================================================

  if (
    !miningStartedAt ||
    !miningEndsAt
  ) {
    return {
      miningActive: false,

      miningFinished: false,

      elapsedMs: 0,

      miningRemainingMs: 0,

      minedAmount: 0,

      hashRate,

      miningHashRate,

      miningStartedAt: null,

      miningEndsAt: null,
    };
  }


  // ==========================================================
  // 🕒 SAFE CURRENT TIME
  // ==========================================================

  const safeNow =
    getSafeNow(now);

  const nowMs =
    safeNow.getTime();

  const startMs =
    miningStartedAt.getTime();

  const endMs =
    miningEndsAt.getTime();


  // ==========================================================
  // 🛡️ INVALID DATES
  // ==========================================================

  if (
    !Number.isFinite(nowMs) ||
    !Number.isFinite(startMs) ||
    !Number.isFinite(endMs) ||
    endMs <= startMs
  ) {
    return {
      miningActive: false,

      miningFinished: false,

      elapsedMs: 0,

      miningRemainingMs: 0,

      minedAmount: 0,

      hashRate,

      miningHashRate,

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
      miningActive: false,

      miningFinished: false,

      elapsedMs: 0,

      miningRemainingMs:
        endMs - startMs,

      minedAmount: 0,

      hashRate,

      miningHashRate,

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
      Math.min(
        Math.max(
          0,
          nowMs - startMs
        ),
        endMs - startMs
      );

    const remainingMs =
      Math.max(
        0,
        endMs - nowMs
      );

    const minedAmount =
      calculateMining(
        miningHashRate,
        elapsedMs
      );

    return {
      miningActive: true,

      miningFinished: false,

      elapsedMs,

      miningRemainingMs:
        remainingMs,

      minedAmount,

      hashRate,

      miningHashRate,

      miningStartedAt,

      miningEndsAt,
    };
  }


  // ==========================================================
  // ✨ MINING FINISHED
  // ==========================================================

  const fullDurationMs =
    Math.max(
      0,
      endMs - startMs
    );

  const minedAmount =
    calculateMining(
      miningHashRate,
      fullDurationMs
    );

  return {
    miningActive: false,

    miningFinished: true,

    elapsedMs:
      fullDurationMs,

    miningRemainingMs: 0,

    minedAmount,

    hashRate,

    miningHashRate,

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

  getMiningHashRate,

  calculateMiningStatus,
};