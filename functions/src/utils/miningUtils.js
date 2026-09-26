"use strict";

// ============================================================
// 🐱 STELLURIINI - MINING UTILITIES
// ============================================================
//
// Keskitetty Mining-laskenta.
//
// Tämä tiedosto:
//
// ✅ laskee mining-tuoton
// ✅ käsittelee mining-ajan
// ✅ käsittelee mining-jakson Hash Raten
// ✅ palauttaa mining-statuksen
//
// Tämä tiedosto EI:
//
// ❌ kirjoita Firestoreen
// ❌ muuta käyttäjän saldoa
// ❌ käsittele Daily Streakia
// ❌ käsittele AdMobia
// ❌ käsittele Power Boostia
//
// ============================================================


const {
  MINING_PER_HASH_PER_HOUR,
} = require(
  "../config/miningConfig",
);


// ============================================================
// 🔢 SAFE NUMBER
// ============================================================

function getSafeNumber(
  value,
  fallback = 0,
) {
  const number =
    Number(
      value,
    );

  return Number.isFinite(
    number,
  )
    ? number
    : fallback;
}


// ============================================================
// ⚡ SAFE HASH RATE
// ============================================================

function getSafeHashRate(
  value,
) {
  const number =
    Number(
      value,
    );

  return Number.isFinite(
    number,
  ) &&
    number >= 0
    ? number
    : 0;
}


// ============================================================
// 🕒 SAFE MILLISECONDS
// ============================================================

function getSafeMilliseconds(
  value,
) {
  const number =
    Number(
      value,
    );

  return Number.isFinite(
    number,
  ) &&
    number >= 0
    ? number
    : 0;
}


// ============================================================
// 📅 SAFE DATE
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


  // ----------------------------------------------------------
  // JavaScript Date
  // ----------------------------------------------------------

  if (
    value instanceof Date
  ) {
    return Number.isFinite(
      value.getTime(),
    )
      ? new Date(
          value.getTime(),
        )
      : null;
  }


  // ----------------------------------------------------------
  // Firestore Timestamp
  // ----------------------------------------------------------

  if (
    typeof value.toDate ===
    "function"
  ) {
    try {
      const date =
        value.toDate();

      return (
        date instanceof Date &&
        Number.isFinite(
          date.getTime(),
        )
      )
        ? new Date(
            date.getTime(),
          )
        : null;
    } catch (
      error
    ) {
      return null;
    }
  }


  // ----------------------------------------------------------
  // ISO/string date
  // ----------------------------------------------------------

  if (
    typeof value ===
    "string"
  ) {
    const normalized =
      value.trim();

    if (
      normalized.length === 0
    ) {
      return null;
    }

    const date =
      new Date(
        normalized,
      );

    return Number.isFinite(
      date.getTime(),
    )
      ? date
      : null;
  }


  // ----------------------------------------------------------
  // Milliseconds
  // ----------------------------------------------------------

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

    return Number.isFinite(
      date.getTime(),
    )
      ? date
      : null;
  }


  return null;
}


// ============================================================
// 🕒 SAFE NOW
// ============================================================

function getSafeNow(
  value,
) {
  return (
    getSafeDate(
      value,
    ) ||
    new Date()
  );
}


// ============================================================
// 💰 MINING RATE
// ============================================================
//
// Keskitetty mining rate tulee miningConfig.js:stä.
//
// STL / Hash Rate / Hour
//
// ============================================================

function getSafeMiningRate() {
  const rate =
    Number(
      MINING_PER_HASH_PER_HOUR,
    );

  return Number.isFinite(
    rate,
  ) &&
    rate > 0
    ? rate
    : 0;
}


// ============================================================
// ⛏️ CALCULATE MINING
// ============================================================
//
// Formula:
//
// Hash Rate
// × STL / Hash / Hour
// × elapsed hours
//
// Esimerkiksi:
//
// 3.5 HR × 0.10 × 24 h
// = 8.4 STL
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

  const safeElapsed =
    getSafeMilliseconds(
      elapsedMilliseconds,
    );

  const rate =
    getSafeMiningRate();

  if (
    safeHashRate <= 0 ||
    safeElapsed <= 0 ||
    rate <= 0
  ) {
    return 0;
  }

  const elapsedHours =
    safeElapsed /
    3600000;

  const amount =
    safeHashRate *
    rate *
    elapsedHours;

  if (
    !Number.isFinite(
      amount,
    ) ||
    amount < 0
  ) {
    return 0;
  }

  return amount;
}


// ============================================================
// ⏱️ MINING START TIME
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
// ⏱️ MINING END TIME
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
// ⚡ MINING HASH RATE
// ============================================================
//
// TÄRKEÄ:
//
// MiningService tallentaa nykyisen mining-jakson Hash Raten
// kenttään:
//
//     hashRate
//
// Siksi tämä utility käyttää ensisijaisesti sitä.
//
// `miningHashRate` tuetaan myös yhteensopivuuden vuoksi,
// mutta sitä ei käytetä ensisijaisena arvona.
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


  // ----------------------------------------------------------
  // PRIMARY FIELD
  // ----------------------------------------------------------

  const hashRate =
    getSafeHashRate(
      data.hashRate,
    );

  if (
    hashRate > 0
  ) {
    return hashRate;
  }


  // ----------------------------------------------------------
  // LEGACY / COMPATIBILITY FIELD
  // ----------------------------------------------------------

  return getSafeHashRate(
    data.miningHashRate,
  );
}


// ============================================================
// 🐱 MINING STATUS
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


  const miningHashRate =
    getMiningHashRate(
      safeData,
    );

  const miningStartedAt =
    getMiningStartTime(
      safeData,
    );

  const miningEndsAt =
    getMiningEndTime(
      safeData,
    );


  const baseResult = {
    hashRate:
      miningHashRate,

    miningHashRate,

    miningStartedAt,

    miningEndsAt,
  };


  // ==========================================================
  // NO MINING SESSION
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

      ...baseResult,

      miningStartedAt:
        null,

      miningEndsAt:
        null,
    };
  }


  const nowMs =
    getSafeNow(
      now,
    ).getTime();

  const startMs =
    miningStartedAt.getTime();

  const endMs =
    miningEndsAt.getTime();


  // ==========================================================
  // INVALID TIME WINDOW
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

      ...baseResult,
    };
  }


  // ==========================================================
  // BEFORE MINING START
  // ==========================================================

  if (
    nowMs <
    startMs
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

      ...baseResult,
    };
  }


  // ==========================================================
  // ACTIVE MINING
  // ==========================================================

  if (
    nowMs <
    endMs
  ) {
    const elapsedMs =
      Math.min(
        nowMs -
          startMs,

        endMs -
          startMs,
      );

    const remainingMs =
      Math.max(
        0,

        endMs -
          nowMs,
      );

    return {
      miningActive:
        true,

      miningFinished:
        false,

      elapsedMs:
        Math.max(
          0,
          elapsedMs,
        ),

      miningRemainingMs:
        remainingMs,

      minedAmount:
        calculateMining(
          miningHashRate,
          elapsedMs,
        ),

      ...baseResult,
    };
  }


  // ==========================================================
  // MINING FINISHED
  // ==========================================================

  const durationMs =
    endMs -
    startMs;

  return {
    miningActive:
      false,

    miningFinished:
      true,

    elapsedMs:
      durationMs,

    miningRemainingMs:
      0,

    minedAmount:
      calculateMining(
        miningHashRate,
        durationMs,
      ),

    ...baseResult,
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