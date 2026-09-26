"use strict";

// ============================================================
// 🐱 STELLURIINI - REFERRAL UTILITIES
// ============================================================
//
// Stella Referral System.
//
// Tämä tiedosto sisältää referral-järjestelmän yleiset
// apufunktiot.
//
// TÄRKEÄÄ:
//
// - Referral-bonusta ei kirjata tässä tiedostossa.
// - Firestore-kirjoituksia ei tehdä tässä tiedostossa.
// - Referral-prosenttia ei päätetä tässä tiedostossa.
// - Varsinainen referral-logiikka kuuluu service/function
//   -kerrokselle.
//
// Tämä tiedosto huolehtii esimerkiksi:
//
// - referral-koodin normalisoinnista
// - referral-koodin validoinnista
// - uuden referral-koodin luonnista
// - käyttäjän referral-tietojen lukemisesta
// - kutsujan UID:n lukemisesta
// - referral-suhteen turvallisesta tarkistamisesta
//
// ============================================================

const crypto = require("crypto");

const {
  REFERRAL_CODE_LENGTH,
  REFERRAL_CODE_CHARACTERS,
  MAX_CODE_GENERATION_ATTEMPTS,
  ONE_REFERRER_PER_USER,
  ALLOW_REFERRER_CHANGE,
  ALLOW_SELF_REFERRAL,
  REFERRAL_DATA_FIELD,
} = require("../config/referralConfig");

// ============================================================
// VALUE HELPERS
// ============================================================

function string(value, fallback = "") {
  return typeof value === "string"
    ? value
    : fallback;
}

function trimmedString(
  value,
  fallback = ""
) {
  const result =
    string(value, fallback).trim();

  return result || fallback;
}

// ============================================================
// REFERRAL CODE NORMALIZATION
// ============================================================
//
// Referral-koodit käsitellään aina isoina kirjaimina.
//
// Esimerkiksi:
//
// "abc123xy"
//     ↓
// "ABC123XY"
//
// Tyhjät tai virheelliset arvot palauttavat tyhjän merkkijonon.
//
// ============================================================

function normalizeReferralCode(
  value
) {
  const code =
    trimmedString(value)
      .toUpperCase();

  if (!code) {
    return "";
  }

  return code;
}

// ============================================================
// REFERRAL CODE VALIDATION
// ============================================================
//
// Tarkistaa, että referral-koodi:
//
// - on oikean pituinen
// - sisältää vain sallittuja merkkejä
//
// ============================================================

function isValidReferralCode(
  value
) {
  const code =
    normalizeReferralCode(value);

  if (!code) {
    return false;
  }

  if (
    code.length !==
    REFERRAL_CODE_LENGTH
  ) {
    return false;
  }

  const characters =
    REFERRAL_CODE_CHARACTERS;

  for (const character of code) {
    if (
      !characters.includes(
        character
      )
    ) {
      return false;
    }
  }

  return true;
}

// ============================================================
// REFERRAL CODE GENERATION
// ============================================================
//
// Luo kryptografisesti satunnaisen referral-koodin.
//
// Koodin pituus ja sallitut merkit tulevat
// referralConfig.js-tiedostosta.
//
// Varsinainen UNIQUENESS-tarkistus tehdään service-kerroksessa
// Firestoressa.
//
// Tämä funktio luo vain uuden ehdokaskoodin.
//
// ============================================================

function generateReferralCode() {
  const characters =
    REFERRAL_CODE_CHARACTERS;

  const length =
    Math.max(
      1,
      Math.floor(
        Number(
          REFERRAL_CODE_LENGTH
        )
      )
    );

  let code = "";

  for (
    let index = 0;
    index < length;
    index++
  ) {
    const randomIndex =
      crypto.randomInt(
        0,
        characters.length
      );

    code +=
      characters[randomIndex];
  }

  return code;
}

// ============================================================
// REFERRAL CODE CANDIDATES
// ============================================================
//
// Luo useita ehdokaskoodeja.
//
// Tämä on hyödyllinen tilanteessa, jossa Firestoressa
// sattuu olemaan jo samanlainen koodi.
//
// Varsinainen uniqueness-tarkistus tehdään muualla.
//
// ============================================================

function generateReferralCodeCandidates(
  count = MAX_CODE_GENERATION_ATTEMPTS
) {
  const requestedCount =
    Number(count);

  const safeCount =
    Number.isFinite(
      requestedCount
    )
      ? Math.max(
          1,
          Math.floor(
            requestedCount
          )
        )
      : MAX_CODE_GENERATION_ATTEMPTS;

  const candidates = [];

  const seen =
    new Set();

  while (
    candidates.length <
    safeCount
  ) {
    const code =
      generateReferralCode();

    if (
      seen.has(code)
    ) {
      continue;
    }

    seen.add(code);

    candidates.push(code);
  }

  return candidates;
}

// ============================================================
// USER REFERRAL DATA
// ============================================================
//
// Referral-tiedot voidaan säilyttää käyttäjän dokumentissa:
//
// referral: {
//   code: "ABC123XY",
//   referrerUid: "...",
//   referredAt: ...,
//   referralCodeUsed: "..."
// }
//
// Tämä tiedosto ei oleta, että kaikki kentät ovat olemassa.
//
// ============================================================

function getReferralData(
  userData
) {
  if (
    !userData ||
    typeof userData !== "object"
  ) {
    return {};
  }

  const referral =
    userData[
      REFERRAL_DATA_FIELD
    ];

  if (
    !referral ||
    typeof referral !== "object" ||
    Array.isArray(referral)
  ) {
    return {};
  }

  return referral;
}

// ============================================================
// USER REFERRAL CODE
// ============================================================

function getUserReferralCode(
  userData
) {
  const referral =
    getReferralData(
      userData
    );

  return normalizeReferralCode(
    referral.code
  );
}

// ============================================================
// REFERRER UID
// ============================================================
//
// Palauttaa käyttäjän kutsujan UID:n.
//
// Jos kutsujaa ei ole, palautetaan tyhjä merkkijono.
//
// ============================================================

function getReferrerUid(
  userData
) {
  const referral =
    getReferralData(
      userData
    );

  return trimmedString(
    referral.referrerUid
  );
}

// ============================================================
// REFERRAL CODE USED
// ============================================================
//
// Palauttaa sen referral-koodin, jolla käyttäjä liittyi.
//
// ============================================================

function getReferralCodeUsed(
  userData
) {
  const referral =
    getReferralData(
      userData
    );

  return normalizeReferralCode(
    referral.referralCodeUsed
  );
}

// ============================================================
// HAS REFERRER
// ============================================================

function hasReferrer(
  userData
) {
  return (
    getReferrerUid(
      userData
    ).length > 0
  );
}

// ============================================================
// REFERRER RELATIONSHIP VALIDATION
// ============================================================
//
// Tarkistaa, voidaanko käyttäjälle asettaa kutsuja.
//
// Yksi käyttäjä voi normaalisti saada vain yhden kutsujan.
//
// ============================================================

function canSetReferrer(
  userData,
  newReferrerUid
) {
  const referrerUid =
    trimmedString(
      newReferrerUid
    );

  if (!referrerUid) {
    return {
      allowed: false,
      reason:
        "REFERRER_UID_MISSING",
    };
  }

  const existingReferrerUid =
    getReferrerUid(
      userData
    );

  if (
    existingReferrerUid
  ) {
    if (
      existingReferrerUid ===
      referrerUid
    ) {
      return {
        allowed: false,
        reason:
          "REFERRER_ALREADY_SET",
      };
    }

    if (
      !ALLOW_REFERRER_CHANGE
    ) {
      return {
        allowed: false,
        reason:
          "REFERRER_CHANGE_NOT_ALLOWED",
      };
    }
  }

  if (
    !ONE_REFERRER_PER_USER
  ) {
    return {
      allowed: true,
      reason: "",
    };
  }

  return {
    allowed: true,
    reason: "",
  };
}

// ============================================================
// SELF REFERRAL VALIDATION
// ============================================================
//
// Käyttäjä ei saa käyttää omaa referral-koodiaan.
//
// ============================================================

function isSelfReferral(
  userUid,
  referrerUid
) {
  const uid =
    trimmedString(
      userUid
    );

  const referrer =
    trimmedString(
      referrerUid
    );

  if (
    !uid ||
    !referrer
  ) {
    return false;
  }

  return uid === referrer;
}

// ============================================================
// REFERRAL RELATIONSHIP VALIDATION
// ============================================================
//
// Yhdistetty turvallisuustarkistus.
//
// Tarkistaa:
//
// - UID:t ovat olemassa
// - self-referral ei ole sallittu
// - olemassa olevaa referral-suhdetta ei rikota
//
// ============================================================

function validateReferrerRelationship(
  userUid,
  userData,
  newReferrerUid
) {
  const uid =
    trimmedString(
      userUid
    );

  const referrerUid =
    trimmedString(
      newReferrerUid
    );

  if (!uid) {
    return {
      valid: false,
      reason:
        "USER_UID_MISSING",
    };
  }

  if (!referrerUid) {
    return {
      valid: false,
      reason:
        "REFERRER_UID_MISSING",
    };
  }

  if (
    !ALLOW_SELF_REFERRAL &&
    isSelfReferral(
      uid,
      referrerUid
    )
  ) {
    return {
      valid: false,
      reason:
        "SELF_REFERRAL_NOT_ALLOWED",
    };
  }

  const relationship =
    canSetReferrer(
      userData,
      referrerUid
    );

  if (
    !relationship.allowed
  ) {
    return {
      valid: false,
      reason:
        relationship.reason,
    };
  }

  return {
    valid: true,
    reason: "",
  };
}

// ============================================================
// REFERRAL DATA BUILDER
// ============================================================
//
// Luo referral-suhteen Firestore-dataobjektin.
//
// Firestore Timestampit lisätään myöhemmin service-kerroksessa,
// joten tämä funktio ei luo serverTimestampia.
//
// ============================================================

function buildReferralData({
  code,
  referrerUid,
  referralCodeUsed,
  referredAt = null,
} = {}) {
  const normalizedCode =
    normalizeReferralCode(
      code
    );

  const normalizedReferrerUid =
    trimmedString(
      referrerUid
    );

  const normalizedCodeUsed =
    normalizeReferralCode(
      referralCodeUsed
    );

  const result = {};

  if (
    normalizedCode &&
    isValidReferralCode(
      normalizedCode
    )
  ) {
    result.code =
      normalizedCode;
  }

  if (
    normalizedReferrerUid
  ) {
    result.referrerUid =
      normalizedReferrerUid;
  }

  if (
    normalizedCodeUsed &&
    isValidReferralCode(
      normalizedCodeUsed
    )
  ) {
    result.referralCodeUsed =
      normalizedCodeUsed;
  }

  if (
    referredAt !== null &&
    referredAt !== undefined
  ) {
    result.referredAt =
      referredAt;
  }

  return result;
}

// ============================================================
// REFERRAL CODE EXTRACTION
// ============================================================
//
// Hyväksyy referral-koodin useista tavallisista input-muodoista.
//
// Esimerkiksi:
//
// {
//   referralCode: "ABC123XY"
// }
//
// tai:
//
// {
//   code: "ABC123XY"
// }
//
// ============================================================

function getReferralCodeFromInput(
  input
) {
  if (
    typeof input === "string"
  ) {
    return normalizeReferralCode(
      input
    );
  }

  if (
    !input ||
    typeof input !== "object"
  ) {
    return "";
  }

  return normalizeReferralCode(
    input.referralCode ??
      input.code ??
      ""
  );
}

// ============================================================
// REFERRAL CODE INPUT VALIDATION
// ============================================================

function validateReferralCodeInput(
  input
) {
  const code =
    getReferralCodeFromInput(
      input
    );

  if (!code) {
    return {
      valid: false,
      code: "",
      reason:
        "REFERRAL_CODE_MISSING",
    };
  }

  if (
    !isValidReferralCode(
      code
    )
  ) {
    return {
      valid: false,
      code,
      reason:
        "REFERRAL_CODE_INVALID",
    };
  }

  return {
    valid: true,
    code,
    reason: "",
  };
}

// ============================================================
// SAFE REFERRAL SUMMARY
// ============================================================
//
// Palauttaa käyttäjän referral-tiedoista vain turvallisen
// clientille sopivan yhteenvedon.
//
// ============================================================

function getReferralSummary(
  userData
) {
  const referral =
    getReferralData(
      userData
    );

  const code =
    getUserReferralCode(
      userData
    );

  const referrerUid =
    getReferrerUid(
      userData
    );

  const referralCodeUsed =
    getReferralCodeUsed(
      userData
    );

  return {
    hasReferralCode:
      code.length > 0,

    referralCode:
      code || null,

    hasReferrer:
      referrerUid.length > 0,

    referralCodeUsed:
      referralCodeUsed || null,

    referredAt:
      referral.referredAt ??
      null,
  };
}

// ============================================================
// EXPORTS
// ============================================================

module.exports = {
  // ----------------------------------------------------------
  // 🔤 NORMALIZATION
  // ----------------------------------------------------------

  normalizeReferralCode,

  // ----------------------------------------------------------
  // 🛡️ VALIDATION
  // ----------------------------------------------------------

  isValidReferralCode,

  validateReferralCodeInput,

  isSelfReferral,

  canSetReferrer,

  validateReferrerRelationship,

  // ----------------------------------------------------------
  // 🔗 CODE GENERATION
  // ----------------------------------------------------------

  generateReferralCode,

  generateReferralCodeCandidates,

  // ----------------------------------------------------------
  // 👤 USER DATA
  // ----------------------------------------------------------

  getReferralData,

  getUserReferralCode,

  getReferrerUid,

  getReferralCodeUsed,

  hasReferrer,

  // ----------------------------------------------------------
  // 📦 DATA
  // ----------------------------------------------------------

  buildReferralData,

  getReferralCodeFromInput,

  getReferralSummary,
};