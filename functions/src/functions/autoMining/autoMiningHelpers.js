
"use strict";

// ============================================================
// 🐱 STELLURIINI - PREMIUM PLUS AUTO MINING HELPERS
// ============================================================
//
// Vastuu:
// - Firestore-aikaleimojen muuntaminen millisekunneiksi
// - Premium Plus -tilauksen palvelinpuolen tarkistus
// - Päättyneen louhintajakson tunnistaminen
//
// Tämä tiedosto ei:
// - muuta käyttäjän saldoa
// - käynnistä louhintaa
// - anna Power Boostia
// - muuta STL-laskentaa
//
// ============================================================


// ============================================================
// TIMESTAMP TO MILLISECONDS
// ============================================================

function timestampToMillis(value) {
  if (value === null || value === undefined) {
    return 0;
  }

  if (typeof value.toMillis === "function") {
    try {
      const result = value.toMillis();

      return Number.isFinite(result) && result > 0
        ? result
        : 0;
    } catch (_) {
      return 0;
    }
  }

  if (typeof value.toDate === "function") {
    try {
      const date = value.toDate();

      return date instanceof Date &&
        Number.isFinite(date.getTime()) &&
        date.getTime() > 0
        ? date.getTime()
        : 0;
    } catch (_) {
      return 0;
    }
  }

  if (value instanceof Date) {
    return Number.isFinite(value.getTime()) &&
      value.getTime() > 0
      ? value.getTime()
      : 0;
  }

  if (typeof value === "number") {
    return Number.isFinite(value) && value > 0
      ? value
      : 0;
  }

  if (typeof value === "string") {
    const result = Date.parse(value);

    return Number.isFinite(result) && result > 0
      ? result
      : 0;
  }

  return 0;
}


// ============================================================
// VALIDATE REFERENCE TIME
// ============================================================

function isValidReferenceTime(referenceNowMs) {
  return (
    typeof referenceNowMs === "number" &&
    Number.isFinite(referenceNowMs) &&
    referenceNowMs > 0
  );
}


// ============================================================
// VERIFIED PREMIUM PLUS ENTITLEMENT
// ============================================================

function hasActiveVerifiedPremiumPlus(
  data,
  referenceNowMs = Date.now()
) {
  if (
    !data ||
    typeof data !== "object" ||
    !isValidReferenceTime(referenceNowMs)
  ) {
    return false;
  }

  // Tilaus on oltava palvelimen varmentama.
  if (
    data.premium !== true ||
    data.premiumVerified !== true
  ) {
    return false;
  }

  // Tavallinen Premium ei oikeuta automaattiseen louhintaan.
  if (data.premiumTier !== "premium_plus") {
    return false;
  }

  const expiryMs = timestampToMillis(
    data.premiumExpiryTime
  );

  // Tilaus ei saa olla vanhentunut.
  return (
    expiryMs > 0 &&
    expiryMs > referenceNowMs
  );
}


// ============================================================
// EXPIRED MINING CYCLE
// ============================================================

function isMiningCycleExpired(
  miningWindow,
  referenceNowMs = Date.now()
) {
  if (
    !miningWindow ||
    miningWindow.valid !== true ||
    !isValidReferenceTime(referenceNowMs)
  ) {
    return false;
  }

  const endMs = Number(
    miningWindow.miningEndMs
  );

  if (
    !Number.isFinite(endMs) ||
    endMs <= 0
  ) {
    return false;
  }

  return endMs <= referenceNowMs;
}


// ============================================================
// AUTOMATIC MINING ELIGIBILITY
// ============================================================

function canAutomaticallyContinueMining({
  userData,
  miningWindow,
  referenceNowMs = Date.now(),
} = {}) {
  if (
    !hasActiveVerifiedPremiumPlus(
      userData,
      referenceNowMs
    )
  ) {
    return false;
  }

  return isMiningCycleExpired(
    miningWindow,
    referenceNowMs
  );
}


// ============================================================
// EXPORTS
// ============================================================

module.exports = {
  timestampToMillis,
  hasActiveVerifiedPremiumPlus,
  isMiningCycleExpired,
  canAutomaticallyContinueMining,
};
