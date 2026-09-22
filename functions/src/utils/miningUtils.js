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
// Tätä tiedostoa ei saa käyttää uuden Hash Raten
// muodostamiseen Daily Streakistä.
//
// ============================================================


// ============================================================
// ⚙️ CONFIG
// ============================================================

const {
  MINING_PER_HASH_PER_HOUR,
} = require(
  "../config/miningConfig",
);


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
// ============================================================

function getSafeHashRate(
  value,
) {
  const number =
    Number(
      value,
    );

  if (
    Number.isFinite(
      number,
    ) &&
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

function getSafeElapsedMilliseconds(
  value,
) {
  const number =
    Number(
      value,
    );

  if (
    Number.isFinite(
      number,
    ) &&
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

function getSafeDate(
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
    const milliseconds =
      value.getTime();

    if (
      !Number.isFinite(
        milliseconds,
      )
    ) {
      return null;
    }

    return new Date(
      milliseconds,
    );
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
        date instanceof Date
      ) {
        const milliseconds =
          date.getTime();

        if (
          Number.isFinite(
            milliseconds,
          )
        ) {
          return new Date(
            milliseconds,
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
  // 📝 STRING
  // ==========================================================

  if (
    typeof value ===
    "string"
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

    const milliseconds =
      date.getTime();

    if (
      Number.isFinite(
        milliseconds,
      )
    ) {
      return date;
    }

    return null;
  }


  // ==========================================================
  // 🔢 UNIX MILLISECONDS
  // ==========================================================

  if (
    typeof value ===
      "number" &&
    Number.isFinite(
      value,
    )
  ) {
    const date =
      new Date(
        value,
      );

    const milliseconds =
      date.getTime();

    if (
      Number.isFinite(
        milliseconds,
      )
    ) {
      return date;
    }
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

function getSafeNow(
  value,
) {
  const date =
    getSafeDate(
      value,
    );

  return date ||
    new Date();
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
      MINING_PER_HASH_PER_HOUR,
    );

  if (
    Number.isFinite(
      number,
    ) &&
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
// Tämä funktio ei rajoita aikaa
// MINING_DURATION_MS-arvoon.
//
// Kutsuvan toiminnon täytyy antaa oikea aikaväli.
//
// Tämä on tarkoituksellista, koska samaa funktiota
// voidaan käyttää myös Power Boost -ajan laskemiseen.
//
// ============================================================

function calculateMining(
  hashRate,
  elapsedMilliseconds,
) {
  const safeHashRate =
    getSafeHashRate(
      hashRate,
    );

  const safeElapsedMilliseconds =
    getSafeElapsedMilliseconds(
      elapsedMilliseconds,
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
    (
      1000 *
      60 *
      60
    );

  if (
    !Number.isFinite(
      hours,
    ) ||
    hours <= 0
  ) {
    return 0;
  }

  const minedAmount =
    safeHashRate *
    safeMiningRate *
    hours;

  if (
    !Number.isFinite(
      minedAmount,
    )
  ) {
    return 0;
  }

  return Math.max(
    0,
    minedAmount,
  );
}


// ============================================================
// ⏱️ GET MINING START TIME
// ============================================================

function getMiningStartTime(
  data,
) {
  if (
    !data ||
    typeof data !==
      "object"
  ) {
    return null;
  }

  return getSafeDate(
    data.miningStartedAt,
  );
}


// ============================================================
// ⏱️ GET MINING END TIME
// ============================================================

function getMiningEndTime(
  data,
) {
  if (
    !data ||
    typeof data !==
      "object"
  ) {
    return null;
  }

  return getSafeDate(
    data.miningEndsAt,
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
// Yhteensopivuuden fallback:
//
// hashRate
//
// TÄRKEÄÄ:
//
// Tämä funktio EI muodosta uutta Hash Ratea.
//
// Se vain lukee olemassa olevan arvon.
//
// Jos miningHashRate-kenttä on olemassa ja kelvollinen,
// sitä käytetään.
//
// Myös arvo 0 on teknisesti kelvollinen tässä
// matalan tason utilityssä.
//
// Business-kerros päättää erikseen, onko 0 hyväksyttävä
// aktiiviselle tai historialliselle mining-cyclelle.
//
// ============================================================

function getMiningHashRate(
  data,
) {
  if (
    !data ||
    typeof data !==
      "object"
  ) {
    return 0;
  }


  // ==========================================================
  // ⚡ MINING CYCLE HASH RATE
  // ==========================================================

  if (
    Object.prototype.hasOwnProperty.call(
      data,
      "miningHashRate",
    )
  ) {
    const number =
      Number(
        data.miningHashRate,
      );

    if (
      Number.isFinite(
        number,
      ) &&
      number >= 0
    ) {
      return number;
    }

    // --------------------------------------------------------
    // IMPORTANT:
    //
    // miningHashRate-kenttä on olemassa mutta virheellinen.
    //
    // Älä vaihda hiljaa toiseen Hash Rateen.
    //
    // Business-kerros voi tämän jälkeen päättää,
    // miten virheellinen mining cycle käsitellään.
    // --------------------------------------------------------

    return 0;
  }


  // ==========================================================
  // 🔄 COMPATIBILITY FALLBACK
  // ==========================================================
  //
  // Vanhaa hashRate-kenttää käytetään vain silloin,
  // kun miningHashRate-kenttää ei ole lainkaan.
  //
  // ==========================================================

  return getSafeHashRate(
    data.hashRate,
  );
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
// minedAmount sisältää tässä vain annetun
// Mining Hash Raten perusteella lasketun
// peruslouhinnan.
//
// Power Boost lasketaan miningFunctions.js:ssä.
//
// ============================================================

function calculateMiningStatus(
  data,
  now = new Date(),
) {
  const safeData =
    data &&
    typeof data ===
      "object"
      ? data
      : {};


  // ==========================================================
  // ⚡ MINING HASH RATE
  // ==========================================================

  const miningHashRate =
    getMiningHashRate(
      safeData,
    );

  const hashRate =
    miningHashRate;


  // ==========================================================
  // ⏱️ MINING TIMES
  // ==========================================================

  const miningStartedAt =
    getMiningStartTime(
      safeData,
    );

  const miningEndsAt =
    getMiningEndTime(
      safeData,
    );


  // ==========================================================
  // 💤 NO MINING DATA
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

      miningHashRate,

      miningStartedAt:
        null,

      miningEndsAt:
        null,
    };
  }


  // ==========================================================
  // 🕒 SAFE CURRENT TIME
  // ==========================================================

  const safeNow =
    getSafeNow(
      now,
    );

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
    !Number.isFinite(
      nowMs,
    ) ||
    !Number.isFinite(
      startMs,
    ) ||
    !Number.isFinite(
      endMs,
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
      miningActive:
        false,

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
          nowMs -
            startMs,
        ),
        endMs -
          startMs,
      );

    const remainingMs =
      Math.max(
        0,
        endMs -
          nowMs,
      );

    const minedAmount =
      calculateMining(
        miningHashRate,
        elapsedMs,
      );

    return {
      miningActive:
        true,

      miningFinished:
        false,

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
      endMs -
        startMs,
    );

  const minedAmount =
    calculateMining(
      miningHashRate,
      fullDurationMs,
    );

  return {
    miningActive:
      false,

    miningFinished:
      true,

    elapsedMs:
      fullDurationMs,

    miningRemainingMs:
      0,

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