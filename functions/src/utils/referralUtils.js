"use strict";

// ============================================================
// 🐱 STELLURIINI - REFERRAL UTILITIES
// ============================================================
//
// Referral / Referointi.
//
// Tämä tiedosto sisältää referral-järjestelmän yhteiset
// apufunktiot.
//
// Vastuut:
//
// - Referral-koodin normalisointi
// - Referral-koodin validointi
// - Uuden referral-koodin luominen
// - Referral-datan turvallinen käsittely
// - Referral-bonuksen turvallinen laskenta
//
// TÄRKEÄÄ:
//
// Tämä tiedosto ei kirjoita Firestoreen.
//
// Firestore-kirjoitukset ja referral-suhteen luominen
// tehdään referralService.js / referralFunctions.js
// -tiedostoissa.
//
// ============================================================

const {
  REFERRAL_CODE_LENGTH,
  REFERRAL_CODE_CHARACTERS,
  MAX_CODE_GENERATION_ATTEMPTS,
  MIN_REFERRAL_BONUS,
  REFERRAL_BONUS_SOURCE,
  REFERRAL_BONUS_SERVER_SIDE,
  ONE_REFERRER_PER_USER,
  ALLOW_SELF_REFERRAL,
  ALLOW_REFERRER_CHANGE,
  getReferralBonusPercent,
  getReferralBonusRate,
  calculateReferralBonus,
  isValidReferralBonus,
} = require("../config/referralConfig");


// ============================================================
// 🔤 REFERRAL CODE NORMALIZATION
// ============================================================
//
// Kaikki referral-koodit käsitellään uppercase-muodossa.
//
// Esimerkiksi:
//
// " abcd1234 "
//       ↓
// "ABCD1234"
//
// Tämä estää tilanteen, jossa sama koodi käsitellään
// useana eri koodina vain kirjainkoon vuoksi.
// ============================================================

function normalizeReferralCode(
  value
) {
  if (
    typeof value !== "string"
  ) {
    return "";
  }

  return value
    .trim()
    .toUpperCase();
}


// ============================================================
// 🔎 REFERRAL CODE VALIDATION
// ============================================================

function isValidReferralCode(
  value
) {
  const code =
    normalizeReferralCode(
      value
    );

  if (!code) {
    return false;
  }

  if (
    code.length !==
    REFERRAL_CODE_LENGTH
  ) {
    return false;
  }

  if (
    typeof REFERRAL_CODE_CHARACTERS !==
      "string" ||
    !REFERRAL_CODE_CHARACTERS
  ) {
    return false;
  }

  for (
    const character of code
  ) {
    if (
      !REFERRAL_CODE_CHARACTERS.includes(
        character
      )
    ) {
      return false;
    }
  }

  return true;
}


// ============================================================
// 🎲 RANDOM CHARACTER
// ============================================================

function randomReferralCharacter() {
  const characters =
    REFERRAL_CODE_CHARACTERS;

  if (
    typeof characters !==
      "string" ||
    !characters
  ) {
    throw new Error(
      "REFERRAL_CODE_CHARACTERS puuttuu."
    );
  }

  const index =
    Math.floor(
      Math.random() *
        characters.length
    );

  return characters.charAt(
    index
  );
}


// ============================================================
// 🎟️ GENERATE REFERRAL CODE
// ============================================================
//
// Luo uuden referral-koodin.
//
// Esimerkki:
//
// STL7K9PQ
//
// Huom:
//
// Tämä funktio luo vain ehdokkaan.
// Uniqueness varmistetaan Firestoressa
// referralService.js:n transaktiossa.
//
// ============================================================

function generateReferralCode() {
  let code = "";

  for (
    let index = 0;
    index <
    REFERRAL_CODE_LENGTH;
    index++
  ) {
    code +=
      randomReferralCharacter();
  }

  return code;
}


// ============================================================
// 🔁 GENERATE REFERRAL CODE CANDIDATES
// ============================================================
//
// Luo useita ehdokkaita, jos ensimmäinen koodi sattuu
// olemaan jo käytössä.
//
// ============================================================

function generateReferralCodeCandidates(
  attempts = MAX_CODE_GENERATION_ATTEMPTS
) {
  const safeAttempts =
    Math.max(
      1,
      Math.floor(
        Number(attempts) ||
          MAX_CODE_GENERATION_ATTEMPTS
      )
    );

  const candidates =
    new Set();

  for (
    let index = 0;
    index < safeAttempts;
    index++
  ) {
    candidates.add(
      generateReferralCode()
    );
  }

  return Array.from(
    candidates
  );
}


// ============================================================
// 🔢 SAFE NUMBER
// ============================================================

function safeNumber(
  value,
  fallback = 0
) {
  const result =
    Number(value);

  return Number.isFinite(result)
    ? result
    : fallback;
}


// ============================================================
// 💰 SAFE MINING PRODUCTION
// ============================================================
//
// Referral-bonus perustuu vain hyväksyttyyn mining-tuottoon.
//
// Negatiivinen tai virheellinen tuotanto muutetaan nollaksi.
//
// ============================================================

function normalizeMiningProduction(
  value
) {
  const production =
    safeNumber(
      value,
      0
    );

  if (
    !Number.isFinite(
      production
    )
  ) {
    return 0;
  }

  return Math.max(
    0,
    production
  );
}


// ============================================================
// 📈 REFERRAL BONUS RATE
// ============================================================
//
// Palauttaa aktiivisen referral-prosentin.
//
// Esimerkiksi:
//
// 5 %
// ↓
// 0.05
//
// ============================================================

function getCurrentReferralBonusRate(
  totalUsers
) {
  const users =
    Math.max(
      0,
      Math.floor(
        safeNumber(
          totalUsers,
          0
        )
      )
    );

  const rate =
    Number(
      getReferralBonusRate(
        users
      )
    );

  if (
    !Number.isFinite(rate) ||
    rate < 0
  ) {
    return 0;
  }

  return rate;
}


// ============================================================
// 📊 REFERRAL BONUS PERCENT
// ============================================================
//
// Palauttaa prosenttilukuna.
//
// Esimerkiksi:
//
// 0.05 -> 5
//
// ============================================================

function getCurrentReferralBonusPercent(
  totalUsers
) {
  const users =
    Math.max(
      0,
      Math.floor(
        safeNumber(
          totalUsers,
          0
        )
      )
    );

  const percent =
    Number(
      getReferralBonusPercent(
        users
      )
    );

  if (
    !Number.isFinite(
      percent
    ) ||
    percent < 0
  ) {
    return 0;
  }

  return percent;
}


// ============================================================
// 💎 CALCULATE REFERRAL BONUS
// ============================================================
//
// Laskee kutsujalle syntyvän referral-bonuksen.
//
// IMPORTANT:
//
// Tämä ei lisää saldoa.
//
// Se ainoastaan laskee summan.
//
// Varsinainen saldo- ja history-kirjoitus tehdään
// referralService.js:n Firestore-transaktiossa.
//
// ============================================================

function calculateReferralMiningBonus(
  miningProduction,
  totalUsers
) {
  const production =
    normalizeMiningProduction(
      miningProduction
    );

  if (
    production <= 0
  ) {
    return 0;
  }

  const rate =
    getCurrentReferralBonusRate(
      totalUsers
    );

  if (
    rate <= 0
  ) {
    return 0;
  }

  const bonus =
    Number(
      calculateReferralBonus(
        production,
        totalUsers
      )
    );

  if (
    !Number.isFinite(
      bonus
    ) ||
    bonus <= 0
  ) {
    return 0;
  }

  return Math.max(
    MIN_REFERRAL_BONUS,
    bonus
  );
}


// ============================================================
// 🛡️ VALIDATE REFERRAL BONUS
// ============================================================
//
// Varmistaa, että laskettu bonus on kelvollinen.
//
// ============================================================

function validateReferralBonus(
  value
) {
  const bonus =
    safeNumber(
      value,
      0
    );

  if (
    typeof isValidReferralBonus ===
      "function"
  ) {
    return isValidReferralBonus(
      bonus
    );
  }

  return (
    Number.isFinite(
      bonus
    ) &&
    bonus >=
      MIN_REFERRAL_BONUS
  );
}


// ============================================================
// 👤 REFERRER VALIDATION
// ============================================================
//
// Tarkistaa referral-suhteen perusrajoitukset.
//
// ============================================================

function canCreateReferral(
  referredUid,
  referrerUid
) {
  if (
    typeof referredUid !==
      "string" ||
    typeof referrerUid !==
      "string"
  ) {
    return false;
  }

  const referred =
    referredUid.trim();

  const referrer =
    referrerUid.trim();

  if (
    !referred ||
    !referrer
  ) {
    return false;
  }

  if (
    !ALLOW_SELF_REFERRAL &&
    referred === referrer
  ) {
    return false;
  }

  return true;
}


// ============================================================
// 🔒 REFERRER CHANGE VALIDATION
// ============================================================
//
// Referral-suhdetta ei saa vaihtaa nykyisen suunnitelman
// mukaan.
//
// ============================================================

function canChangeReferrer(
  existingReferrerUid,
  newReferrerUid
) {
  const existing =
    typeof existingReferrerUid ===
      "string"
      ? existingReferrerUid.trim()
      : "";

  const next =
    typeof newReferrerUid ===
      "string"
      ? newReferrerUid.trim()
      : "";

  if (!next) {
    return false;
  }

  if (!existing) {
    return true;
  }

  if (
    existing === next
  ) {
    return true;
  }

  return (
    ALLOW_REFERRER_CHANGE ===
    true
  );
}


// ============================================================
// 📦 NORMALIZE REFERRAL DOCUMENT
// ============================================================
//
// Muuttaa Firestore referral-datan turvalliseen muotoon.
//
// ============================================================

function normalizeReferralDocument(
  data
) {
  const source =
    data || {};

  const userId =
    typeof source.userId ===
      "string"
      ? source.userId.trim()
      : "";

  const referrerUid =
    typeof source.referrerUid ===
      "string"
      ? source.referrerUid.trim()
      : "";

  const referralCode =
    normalizeReferralCode(
      source.referralCode
    );

  const createdAt =
    source.createdAt ??
    null;

  const updatedAt =
    source.updatedAt ??
    null;

  const totalMiningProduction =
    normalizeMiningProduction(
      source.totalMiningProduction
    );

  const totalReferralBonus =
    normalizeMiningProduction(
      source.totalReferralBonus
    );

  return {
    userId,

    referrerUid,

    referralCode,

    createdAt,

    updatedAt,

    totalMiningProduction,

    totalReferralBonus,

    active:
      source.active !== false,

    bonusSource:
      REFERRAL_BONUS_SOURCE,

    serverSide:
      REFERRAL_BONUS_SERVER_SIDE,
  };
}


// ============================================================
// 👥 NORMALIZE USER REFERRAL DATA
// ============================================================

function normalizeUserReferralData(
  data
) {
  const source =
    data || {};

  const referralCode =
    normalizeReferralCode(
      source.referralCode
    );

  const referrerUid =
    typeof source.referrerUid ===
      "string"
      ? source.referrerUid.trim()
      : "";

  const referralCodeUsed =
    normalizeReferralCode(
      source.referralCodeUsed
    );

  const referralCount =
    Math.max(
      0,
      Math.floor(
        safeNumber(
          source.referralCount,
          0
        )
      )
    );

  return {
    referralCode,

    referrerUid,

    referralCodeUsed,

    referralCount,

    referralJoinedAt:
      source.referralJoinedAt ??
      null,

    referralUpdatedAt:
      source.referralUpdatedAt ??
      null,
  };
}


// ============================================================
// 🧾 REFERRAL BONUS HISTORY DATA
// ============================================================
//
// Luo turvallisen history-objektin.
// Ei kirjoita Firestoreen.
//
// ============================================================

function buildReferralBonusHistory(
  {
    referredUid,
    referrerUid,
    miningProduction,
    bonusAmount,
    bonusPercent,
    sourceMiningType = "mining",
    miningHistoryId = null,
  } = {}
) {
  const production =
    normalizeMiningProduction(
      miningProduction
    );

  const bonus =
    normalizeMiningProduction(
      bonusAmount
    );

  const percent =
    Math.max(
      0,
      safeNumber(
        bonusPercent,
        0
      )
    );

  return {
    type:
      "referral_bonus",

    source:
      REFERRAL_BONUS_SOURCE,

    sourceMiningType,

    referredUid:
      typeof referredUid ===
        "string"
        ? referredUid.trim()
        : "",

    referrerUid:
      typeof referrerUid ===
        "string"
        ? referrerUid.trim()
        : "",

    miningProduction:
      production,

    bonusAmount:
      bonus,

    bonusPercent:
      percent,

    bonusRate:
      percent / 100,

    miningHistoryId:
      typeof miningHistoryId ===
        "string"
        ? miningHistoryId.trim()
        : null,

    serverSide:
      REFERRAL_BONUS_SERVER_SIDE,
  };
}


// ============================================================
// 🧮 REFERRAL SUMMARY
// ============================================================

function buildReferralSummary(
  {
    referralCode = "",
    referrerUid = "",
    referralCount = 0,
    totalMiningProduction = 0,
    totalReferralBonus = 0,
    totalUsers = 0,
  } = {}
) {
  const normalizedCode =
    normalizeReferralCode(
      referralCode
    );

  const normalizedReferrer =
    typeof referrerUid ===
      "string"
      ? referrerUid.trim()
      : "";

  const users =
    Math.max(
      0,
      Math.floor(
        safeNumber(
          totalUsers,
          0
        )
      )
    );

  const count =
    Math.max(
      0,
      Math.floor(
        safeNumber(
          referralCount,
          0
        )
      )
    );

  const production =
    normalizeMiningProduction(
      totalMiningProduction
    );

  const bonus =
    normalizeMiningProduction(
      totalReferralBonus
    );

  const percent =
    getCurrentReferralBonusPercent(
      users
    );

  return {
    referralCode:
      normalizedCode,

    referrerUid:
      normalizedReferrer,

    referralCount:
      count,

    totalMiningProduction:
      production,

    totalReferralBonus:
      bonus,

    totalUsers:
      users,

    currentBonusPercent:
      percent,

    currentBonusRate:
      percent / 100,

    oneReferrerPerUser:
      ONE_REFERRER_PER_USER,

    selfReferralAllowed:
      ALLOW_SELF_REFERRAL,

    referrerChangeAllowed:
      ALLOW_REFERRER_CHANGE,

    bonusSource:
      REFERRAL_BONUS_SOURCE,

    serverSide:
      REFERRAL_BONUS_SERVER_SIDE,
  };
}


// ============================================================
// EXPORTS
// ============================================================

module.exports = {
  normalizeReferralCode,

  isValidReferralCode,

  generateReferralCode,

  generateReferralCodeCandidates,

  normalizeMiningProduction,

  getCurrentReferralBonusRate,

  getCurrentReferralBonusPercent,

  calculateReferralMiningBonus,

  validateReferralBonus,

  canCreateReferral,

  canChangeReferrer,

  normalizeReferralDocument,

  normalizeUserReferralData,

  buildReferralBonusHistory,

  buildReferralSummary,
};