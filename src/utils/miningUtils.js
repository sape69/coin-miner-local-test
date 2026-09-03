"use strict";

const {

  DEFAULT_HASH_RATE,

  MINING_PER_HASH_PER_HOUR,

} = require(
  "../config/miningConfig"
);


// ============================================================
// ⛏️ CALCULATE MINING
// ============================================================

function calculateMining(
  hashRate,
  elapsedMilliseconds
) {
  const hours =
    elapsedMilliseconds /
    (1000 * 60 * 60);

  return (
    hashRate *
    MINING_PER_HASH_PER_HOUR *
    hours
  );
}


// ============================================================
// ⏱️ GET MINING START
// ============================================================

function getMiningStartTime(data) {
  const timestamp =
    data.miningStartedAt;

  if (
    timestamp &&
    typeof timestamp.toDate ===
      "function"
  ) {
    return timestamp.toDate();
  }

  return null;
}


// ============================================================
// ⏱️ GET MINING END
// ============================================================

function getMiningEndTime(data) {
  const timestamp =
    data.miningEndsAt;

  if (
    timestamp &&
    typeof timestamp.toDate ===
      "function"
  ) {
    return timestamp.toDate();
  }

  return null;
}


// ============================================================
// 🐱 CALCULATE STELLA MINING STATUS
// ============================================================

function calculateMiningStatus(
  data,
  now
) {
  const hashRate =
    Number(
      data.hashRate ||
      DEFAULT_HASH_RATE
    );

  const miningStartedAt =
    getMiningStartTime(data);

  const miningEndsAt =
    getMiningEndTime(data);


  // ==========================================================
  // NO ACTIVE MINING
  // ==========================================================

  if (
    !miningStartedAt ||
    !miningEndsAt
  ) {
    return {

      miningActive:
        false,

      elapsedMs:
        0,

      miningRemainingMs:
        0,

      minedAmount:
        0,

      hashRate,

    };
  }


  const nowMs =
    now.getTime();

  const startMs =
    miningStartedAt.getTime();

  const endMs =
    miningEndsAt.getTime();


  // ==========================================================
  // MINING COMPLETE
  // ==========================================================

  if (
    nowMs >= endMs
  ) {
    const totalElapsed =
      Math.max(
        0,
        endMs -
          startMs
      );

    return {

      miningActive:
        false,

      elapsedMs:
        totalElapsed,

      miningRemainingMs:
        0,

      minedAmount:
        calculateMining(
          hashRate,
          totalElapsed
        ),

      hashRate,

    };
  }


  // ==========================================================
  // MINING ACTIVE
  // ==========================================================

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


  return {

    miningActive:
      true,

    elapsedMs,

    miningRemainingMs:
      remainingMs,

    minedAmount:
      calculateMining(
        hashRate,
        elapsedMs
      ),

    hashRate,

  };
}


// ============================================================
// EXPORTS
// ============================================================

module.exports = {

  calculateMining,

  getMiningStartTime,

  getMiningEndTime,

  calculateMiningStatus,

};