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
// TÄRKEÄÄ:
//
// Tämä tiedosto vastaa vain mining-laskennasta.
//
// Daily Hash Rate määritetään miningFunctions.js:ssä
// Daily Streak -logiikan perusteella.
//
// Power Boost käsitellään erillisenä väliaikaisena
// boostina miningFunctions.js:ssä.
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
// 0 on sallittu.
//
// Virheellinen tai negatiivinen arvo palautetaan arvona 0.
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
  value
) {
  if (
    value === null ||
    value === undefined
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
          date.getTime()
        )
      ) {
        return date;
      }
    } catch (
      error
    ) {
      return null;
    }
  }


  // ==========================================================
  // 📅 JAVASCRIPT DATE
  // ==========================================================

  if (
    value instanceof Date
  ) {
    if (
      Number.isNaN(
        value.getTime()
      )
    ) {
      return null;
    }

    return value;
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
      new Date(trimmed);

    if (
      !Number.isNaN(
        date.getTime()
      )
    ) {
      return date;
    }

    return null;
  }


  // ==========================================================
  // 🔢 MILLISECONDS
  // ==========================================================

  if (
    typeof value === "number" &&
    Number.isFinite(value)
  ) {
    const date =
      new Date(value);

    if (
      !Number.isNaN(
        date.getTime()
      )
    ) {
      return date;
    }
  }


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
  value
) {
  const date =
    getSafeDate(value);

  if (date) {
    return date;
  }

  return new Date();
}


// ============================================================
// ⛏️ CALCULATE MINING
// ============================================================
//
// Laskee kuinka paljon STL:ää syntyy
// annetulla Hash Ratella annetun ajan aikana.
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

  if (
    safeHashRate <= 0 ||
    safeElapsedMilliseconds <= 0 ||
    MINING_PER_HASH_PER_HOUR <= 0
  ) {
    return 0;
  }

  const hours =
    safeElapsedMilliseconds /
    (1000 * 60 * 60);

  const minedAmount =
    safeHashRate *
    MINING_PER_HASH_PER_HOUR *
    hours;

  if (
    !Number.isFinite(
      minedAmount
    )
  ) {
    return 0;
  }

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
// 📝 ISO Date String
// 🔢 millisekunnit
//
// ============================================================

function getMiningStartTime(
  data
) {
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
//
// Hakee mining-jakson päättymisajan.
//
// Tukee:
//
// 🔥 Firestore Timestamp
// 📅 JavaScript Date
// 📝 ISO Date String
// 🔢 millisekunnit
//
// ============================================================

function getMiningEndTime(
  data
) {
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
// miningStartedAt
// miningEndsAt
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
  // ⚡ HASH RATE
  // ==========================================================

  const hashRate =
    getSafeHashRate(
      safeData.hashRate
    );


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
  // 🕒 SAFE CURRENT TIME
  // ==========================================================

  const safeNow =
    getSafeNow(
      now
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
  //
  // Louhinta ei ole vielä aktiivinen.
  //
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
      Math.max(
        0,
        nowMs -
          startMs
      );

    const remainingMs =
      Math.max(
        0,
        endMs -
          nowMs
      );

    const minedAmount =
      calculateMining(
        hashRate,
        elapsedMs
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
        startMs
    );

  const minedAmount =
    calculateMining(
      hashRate,
      fullDurationMs
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