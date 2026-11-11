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
// CONFIGURATION
// ============================================================

const PREMIUM_PLUS_PRODUCT_ID =
  "stelluriini_premium_plus_monthly";

// Näiden tilojen aikana Google Play -tilaus voi edelleen
// oikeuttaa Premium Plus -ominaisuuksiin.
// CANCELED hyväksytään vain, jos expiryTime on tulevaisuudessa.
const VALID_PLAY_SUBSCRIPTION_STATES = new Set([
  "SUBSCRIPTION_STATE_ACTIVE",
  "SUBSCRIPTION_STATE_IN_GRACE_PERIOD",
  "SUBSCRIPTION_STATE_CANCELED",
]);


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

  // Firestore Timestamp voi joissakin yhteyksissä tulla
  // tavallisena serialisoituna objektina.
  if (typeof value === "object") {
    const seconds = value._seconds ?? value.seconds;
    const nanos =
      value._nanoseconds ??
      value.nanoseconds ??
      0;

    if (
      typeof seconds === "number" &&
      Number.isFinite(seconds) &&
      typeof nanos === "number" &&
      Number.isFinite(nanos)
    ) {
      const result =
        seconds * 1000 +
        Math.floor(nanos / 1000000);

      return result > 0 ? result : 0;
    }
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

  // Vain oikea Google Play Premium Plus -tuote hyväksytään.
  if (
    data.premiumProductId !== PREMIUM_PLUS_PRODUCT_ID ||
    data.premiumTier !== "premium_plus"
  ) {
    return false;
  }

  // TEST_ACTIVE, EXPIRED ja muut tuntemattomat tilat hylätään.
  if (
    !VALID_PLAY_SUBSCRIPTION_STATES.has(
      data.premiumSubscriptionState
    )
  ) {
    return false;
  }

  const expiryMs = timestampToMillis(
    data.premiumExpiryTime
  );

  // Myös peruutetun tilauksen on oltava vielä voimassa.
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
