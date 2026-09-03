"use strict";


// ============================================================
// 🐱 STELLA MINING UTILITIES
// ============================================================
//
// Tämä tiedosto sisältää Stella Miningin
// reaaliaikaisen laskentalogiikan.
//
// Mining toimii palvelimen ajan perusteella.
//
// Pelaaja ei tarvitse "claimata" STL:ää jatkuvasti.
//
// Stella louhii reaaliajassa 24 tunnin ajan.
//
// ============================================================


const {
  DEFAULT_HASH_RATE,
  MINING_PER_HASH_PER_HOUR,
} = require("../config/miningConfig");


// ============================================================
// ⛏️ CALCULATE MINING
// ============================================================
//
// Laskee kuinka paljon STL:ää syntyy
// tietyn ajan aikana.
//

function calculateMining(
  hashRate,
  elapsedMilliseconds
) {

  const safeHashRate =
    Math.max(
      0,
      Number(hashRate) ||
        DEFAULT_HASH_RATE
    );


  const safeElapsedMilliseconds =
    Math.max(
      0,
      Number(elapsedMilliseconds) || 0
    );


  const hours =
    safeElapsedMilliseconds /
    (1000 * 60 * 60);


  const minedAmount =
    safeHashRate *
    MINING_PER_HASH_PER_HOUR *
    hours;


  return minedAmount;
}


// ============================================================
// ⏱️ GET MINING START TIME
// ============================================================

function getMiningStartTime(data) {

  const timestamp =
    data?.miningStartedAt;


  if (
    timestamp &&
    typeof timestamp.toDate ===
      "function"
  ) {

    return timestamp.toDate();
  }


  if (
    timestamp instanceof Date
  ) {

    return timestamp;
  }


  return null;
}


// ============================================================
// ⏱️ GET MINING END TIME
// ============================================================

function getMiningEndTime(data) {

  const timestamp =
    data?.miningEndsAt;


  if (
    timestamp &&
    typeof timestamp.toDate ===
      "function"
  ) {

    return timestamp.toDate();
  }


  if (
    timestamp instanceof Date
  ) {

    return timestamp;
  }


  return null;
}


// ============================================================
// 🐱 CALCULATE MINING STATUS
// ============================================================
//
// Palauttaa Stella Miningin nykyisen tilanteen.
//

function calculateMiningStatus(
  data,
  now = new Date()
) {

  const hashRate =
    Math.max(
      0,
      Number(
        data?.hashRate ||
        DEFAULT_HASH_RATE
      )
    );


  const miningStartedAt =
    getMiningStartTime(data);

  const miningEndsAt =
    getMiningEndTime(data);


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
        endMs - startMs,

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
// 📤 EXPORTS
// ============================================================

module.exports = {

  calculateMining,

  getMiningStartTime,

  getMiningEndTime,

  calculateMiningStatus,

};