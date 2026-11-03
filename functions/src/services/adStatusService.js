"use strict";

// ============================================================
// 🐱 STELLURIINI - AD STATUS SERVICE
// ============================================================
//
// Laskee käyttäjän mainosten katseluoikeuden,
// jäähdytysajan ja aktiivisen Power Boost -tilan.
//
// Tämä palvelu ei tee Firestore-kirjoituksia.
// ============================================================

const {
MAX_ADS_PER_DAY,
AD_COOLDOWN_MS,
} = require("../config/miningConfig");

const {
miningWindow,
} = require("./miningCalculationService");

const {
number,
timestampMs,
} = require("../utils/valueUtils");

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

const boostStartMs =
timestampMs(
data.adBoostStartedAt
);

const boostEndMs =
timestampMs(
data.adBoostEndsAt
);

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

const effectiveEnd =
boostInsideMining &&
boostEndMs > boostStartMs
? Math.min(
boostEndMs,
window.miningEndMs
)
: 0;

const boostActive =
active &&
effectiveEnd > nowMs;

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
  boostActive
    ? effectiveEnd - nowMs
    : 0,

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