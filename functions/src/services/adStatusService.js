
"use strict";

// ============================================================
// 🐱 STELLURIINI - AD STATUS SERVICE
// ============================================================
//
// Laskee käyttäjän mainosten katseluoikeuden,
// jäähdytysajan ja aktiivisen Power Boost -tilan.
//
// POWER BOOST DURATION:
//
// FREE          = 4 HOURS
// PREMIUM       = 4 HOURS
// PREMIUM_PLUS  = 24 HOURS
//
// Palvelin rajoittaa myös vanhat Firestoreen
// tallennetut boostien päättymisajat.
//
// ============================================================

const {
  MAX_ADS_PER_DAY,
  AD_COOLDOWN_MS,
  AD_BOOST_DURATION_MS,
} = require("../config/miningConfig");

const {
  miningWindow,
} = require("./miningCalculationService");

const {
  number,
  timestampMs,
} = require("../utils/valueUtils");

// ============================================================
// PREMIUM PLUS BOOST DURATION
// ============================================================

const PREMIUM_PLUS_BOOST_DURATION_MS =
  24 * 60 * 60 * 1000;

// ============================================================
// VERIFIED PREMIUM CHECK
// ============================================================

function hasActiveVerifiedPremiumPlus(
  data,
  nowMs
) {
  if (
    data.premium !== true ||
    data.premiumVerified !== true ||
    data.premiumTier !== "premium_plus"
  ) {
    return false;
  }

  const expiryMs = timestampMs(
    data.premiumExpiryTime
  );

  return expiryMs > nowMs;
}

// ============================================================
// GET ALLOWED BOOST DURATION
// ============================================================

function getAllowedBoostDuration(
  data,
  nowMs
) {
  return hasActiveVerifiedPremiumPlus(
    data,
    nowMs
  )
    ? PREMIUM_PLUS_BOOST_DURATION_MS
    : AD_BOOST_DURATION_MS;
}

// ============================================================
// AD STATUS
// ============================================================

function adStatus(
  data,
  nowMs,
  today
) {
  const lastDate =
    typeof data.lastAdDate === "string"
      ? data.lastAdDate
      : "";

  const adsToday =
    lastDate === today
      ? Math.max(
          0,
          Math.floor(
            number(data.adsToday)
          )
        )
      : 0;

  // ----------------------------------------------------------
  // COOLDOWN
  // ----------------------------------------------------------

  const lastRewardMs =
    timestampMs(
      data.lastAdRewardAt
    );

  const cooldownRemainingMs =
    lastRewardMs > 0
      ? Math.max(
          0,
          lastRewardMs +
            AD_COOLDOWN_MS -
            nowMs
        )
      : 0;

  // ----------------------------------------------------------
  // BOOST TIMESTAMPS
  // ----------------------------------------------------------

  const boostStartMs =
    timestampMs(
      data.adBoostStartedAt
    );

  const storedBoostEndMs =
    timestampMs(
      data.adBoostEndsAt
    );

  // ----------------------------------------------------------
  // MINING WINDOW
  // ----------------------------------------------------------

  const window =
    miningWindow(data);

  const active =
    window.valid &&
    nowMs >= window.miningStartMs &&
    nowMs < window.miningEndMs;

  const boostInsideMining =
    active &&
    boostStartMs >= window.miningStartMs &&
    boostStartMs < window.miningEndMs;

  // ----------------------------------------------------------
  // SUBSCRIPTION-BASED BOOST DURATION
  // ----------------------------------------------------------

  const allowedDurationMs =
    getAllowedBoostDuration(
      data,
      nowMs
    );

  // Enimmäispäättymisaika määräytyy:
  // 1. Tallennetun päättymisajan perusteella.
  // 2. Tilauksen salliman keston perusteella.
  // 3. Louhintajakson päättymisajan perusteella.

  const maximumAllowedEndMs =
    boostStartMs > 0
      ? boostStartMs + allowedDurationMs
      : 0;

  const effectiveEnd =
    boostInsideMining &&
    storedBoostEndMs > boostStartMs
      ? Math.min(
          storedBoostEndMs,
          maximumAllowedEndMs,
          window.miningEndMs
        )
      : 0;

  // ----------------------------------------------------------
  // BOOST ACTIVE
  // ----------------------------------------------------------

  const boostActive =
    active &&
    effectiveEnd > nowMs;

  const remainingMs =
    boostActive
      ? effectiveEnd - nowMs
      : 0;

  // ----------------------------------------------------------
  // RESPONSE
  // ----------------------------------------------------------

  return {
    adsToday,

    maxAdsPerDay:
      MAX_ADS_PER_DAY,

    cooldownRemainingMs,

    canWatchAd:
      active &&
      adsToday < MAX_ADS_PER_DAY &&
      cooldownRemainingMs === 0 &&
      !boostActive,

    adBoostActive:
      boostActive,

    adBoostRemainingMs:
      remainingMs,

    adBoostStartedAt:
      boostActive
        ? new Date(boostStartMs)
        : null,

    adBoostEndsAt:
      boostActive
        ? new Date(effectiveEnd)
        : null,
  };
}

// ============================================================
// EXPORTS
// ============================================================

module.exports = {
  adStatus,
};
