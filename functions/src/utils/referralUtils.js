"use strict";

// ============================================================
// 🐱 STELLURIINI - REFERRAL UTILS
// ============================================================
//
// Stella Referral System.
//
// Tämä tiedosto sisältää Referral-järjestelmän puhtaat
// utility-funktiot.
//
// TÄRKEÄÄ:
//
// - Ei Firestore-kirjoituksia.
// - Ei STL-palkkioiden maksamista.
// - Ei callable functioneja.
// - Ei clientin lähettämän bonusmäärän hyväksymistä.
//
// Referral-bonus lasketaan myöhemmin server-side
// referralService.js-tiedostossa.
//
// ============================================================

const crypto = require("crypto");

const {
  REFERRAL_CODE_LENGTH,
  REFERRAL_CODE_CHARACTERS,
  ONE_REFERRER_PER_USER,
  ALLOW_REFERRER_CHANGE,
  ALLOW_SELF_REFERRAL,
  REFERRAL_DATA_FIELD,
} = require("../config/referralConfig");


// ============================================================
// 🔤 NORMALIZE REFERRAL CODE
// ============================================================
//
// Muuttaa referral-koodin turvalliseen ja yhtenäiseen muotoon.
//
// Esimerkiksi:
//
// " abcd2345 "
//      ↓
// "ABCD2345"
//
// ============================================================

function normalizeReferralCode(
  value,
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
// 🔍 REFERRAL CODE VALIDATION
// ============================================================
//
// Tarkistaa, että referral-koodi:
//
// - on oikean pituinen
// - sisältää vain sallitut merkit
//
// ============================================================

function isValidReferralCode(
  value,
) {
  const code =
    normalizeReferralCode(
      value,
    );

  if (
    !code ||
    code.length !==
      REFERRAL_CODE_LENGTH
  ) {
    return false;
  }

  const allowed =
    REFERRAL_CODE_CHARACTERS;

  for (
    const character of code
  ) {
    if (
      !allowed.includes(
        character,
      )
    ) {
      return false;
    }
  }

  return true;
}


// ============================================================
// 🎲 GENERATE REFERRAL CODE
// ============================================================
//
// Luo kryptografisesti satunnaisen referral-koodin.
//
// Esimerkiksi:
//
// ABC7K2MP
//
// Käytössä ovat vain referralConfig.js:n hyväksymät merkit.
//
// ============================================================

function generateReferralCode() {
  const characters =
    REFERRAL_CODE_CHARACTERS;

  const length =
    Math.max(
      1,
      Number(
        REFERRAL_CODE_LENGTH,
      ) || 8,
    );

  let code = "";

  for (
    let index = 0;
    index < length;
    index += 1
  ) {
    const randomIndex =
      crypto.randomInt(
        0,
        characters.length,
      );

    code +=
      characters[randomIndex];
  }

  return code;
}


// ============================================================
// 🔐 REFERRAL CODE COMPARISON
// ============================================================
//
// Referral-koodien vertailu tapahtuu aina normalisoidussa
// muodossa.
//
// ============================================================

function referralCodesMatch(
  first,
  second,
) {
  const firstCode =
    normalizeReferralCode(
      first,
    );

  const secondCode =
    normalizeReferralCode(
      second,
    );

  return (
    firstCode !== "" &&
    secondCode !== "" &&
    firstCode === secondCode
  );
}


// ============================================================
// 👤 HAS REFERRER
// ============================================================
//
// Tarkistaa, onko käyttäjälle jo asetettu kutsuja.
//
// ============================================================

function hasReferrer(
  userData,
) {
  if (
    !userData ||
    typeof userData !==
      "object"
  ) {
    return false;
  }

  const referrerUid =
    typeof userData.referrerUid ===
    "string"
      ? userData.referrerUid.trim()
      : "";

  return referrerUid.length > 0;
}


// ============================================================
// 🚫 CAN SET REFERRER
// ============================================================
//
// Tarkistaa, voidaanko käyttäjälle asettaa kutsuja.
//
// Nykyisen configin mukaan:
//
// ONE_REFERRER_PER_USER = true
// ALLOW_REFERRER_CHANGE = false
//
// Tämän vuoksi olemassa olevaa kutsujaa ei voi vaihtaa.
//
// ============================================================

function canSetReferrer(
  userData,
) {
  if (
    !ONE_REFERRER_PER_USER
  ) {
    return true;
  }

  if (
    !hasReferrer(
      userData,
    )
  ) {
    return true;
  }

  return (
    ALLOW_REFERRER_CHANGE ===
    true
  );
}


// ============================================================
// 🚫 SELF REFERRAL
// ============================================================
//
// Tarkistaa, yrittääkö käyttäjä käyttää omaa referral-koodiaan.
//
// ============================================================

function isSelfReferral(
  uid,
  referrerUid,
) {
  const currentUid =
    typeof uid === "string"
      ? uid.trim()
      : "";

  const possibleReferrerUid =
    typeof referrerUid ===
      "string"
      ? referrerUid.trim()
      : "";

  if (
    !currentUid ||
    !possibleReferrerUid
  ) {
    return false;
  }

  return (
    currentUid ===
    possibleReferrerUid
  );
}


// ============================================================
// 📦 GET REFERRAL DATA
// ============================================================
//
// Palauttaa käyttäjän referral-tiedot turvallisesti.
//
// Firestore-dokumentista voi löytyä myös muita kenttiä.
// Tässä palautetaan vain Referral-järjestelmän tarvitsemat
// kentät.
//
// Nykyinen suunniteltu käyttäjämalli:
//
// users/{uid}
//
// referralCode
// referrerUid
// referralCodeUsed
// referralJoinedAt
// referralCount
//
// ============================================================

function getReferralData(
  userData,
) {
  if (
    !userData ||
    typeof userData !==
      "object"
  ) {
    return {
      referralCode: "",
      referrerUid: "",
      referralCodeUsed: "",
      referralJoinedAt: null,
      referralCount: 0,
    };
  }

  const referralCode =
    normalizeReferralCode(
      userData.referralCode,
    );

  const referrerUid =
    typeof userData.referrerUid ===
    "string"
      ? userData.referrerUid.trim()
      : "";

  const referralCodeUsed =
    normalizeReferralCode(
      userData.referralCodeUsed,
    );

  const referralJoinedAt =
    userData.referralJoinedAt ||
    null;

  const referralCountNumber =
    Number(
      userData.referralCount,
    );

  const referralCount =
    Number.isFinite(
      referralCountNumber,
    ) &&
    referralCountNumber >= 0
      ? Math.floor(
          referralCountNumber,
        )
      : 0;

  return {
    referralCode,

    referrerUid,

    referralCodeUsed,

    referralJoinedAt,

    referralCount,
  };
}


// ============================================================
// 🧩 GET NESTED REFERRAL DATA
// ============================================================
//
// referralConfig.js sisältää:
//
// REFERRAL_DATA_FIELD = "referral"
//
// Tämä helper tukee myös mahdollista nested referral-dataa.
//
// Jos käyttäjädokumentissa on:
//
// referral: {
//   code: "...",
//   referrerUid: "..."
// }
//
// helper voi lukea sen.
//
// Ensisijaisesti käytetään kuitenkin nykyistä sovittua
// root-level rakennetta:
//
// referralCode
// referrerUid
// referralCodeUsed
// referralJoinedAt
// referralCount
//
// ============================================================

function getNestedReferralData(
  userData,
) {
  if (
    !userData ||
    typeof userData !==
      "object"
  ) {
    return {};
  }

  const nested =
    userData[
      REFERRAL_DATA_FIELD
    ];

  if (
    !nested ||
    typeof nested !==
      "object"
  ) {
    return {};
  }

  return nested;
}


// ============================================================
// 🔗 GET EFFECTIVE REFERRAL CODE
// ============================================================
//
// Lukee käyttäjän Referral-koodin.
//
// Root-level kenttä on ensisijainen.
// Nested referral-data toimii varmistuksena.
//
// ============================================================

function getReferralCode(
  userData,
) {
  const directCode =
    normalizeReferralCode(
      userData?.referralCode,
    );

  if (
    directCode
  ) {
    return directCode;
  }

  const nested =
    getNestedReferralData(
      userData,
    );

  return normalizeReferralCode(
    nested.code ??
      nested.referralCode,
  );
}


// ============================================================
// 👤 GET REFERRER UID
// ============================================================
//
// Lukee käyttäjän kutsujan UID:n.
//
// Root-level kenttä on ensisijainen.
// Nested referral-data toimii varmistuksena.
//
// ============================================================

function getReferrerUid(
  userData,
) {
  const directUid =
    typeof userData?.referrerUid ===
    "string"
      ? userData.referrerUid.trim()
      : "";

  if (
    directUid
  ) {
    return directUid;
  }

  const nested =
    getNestedReferralData(
      userData,
    );

  return typeof nested.referrerUid ===
    "string"
    ? nested.referrerUid.trim()
    : "";
}


// ============================================================
// 📊 GET REFERRAL COUNT
// ============================================================
//
// Palauttaa käyttäjän kutsumien käyttäjien määrän.
//
// ============================================================

function getReferralCount(
  userData,
) {
  const direct =
    Number(
      userData?.referralCount,
    );

  if (
    Number.isFinite(direct) &&
    direct >= 0
  ) {
    return Math.floor(
      direct,
    );
  }

  const nested =
    getNestedReferralData(
      userData,
    );

  const nestedCount =
    Number(
      nested.referralCount,
    );

  if (
    Number.isFinite(
      nestedCount,
    ) &&
    nestedCount >= 0
  ) {
    return Math.floor(
      nestedCount,
    );
  }

  return 0;
}


// ============================================================
// 🛡️ REFERRAL RELATIONSHIP VALIDATION
// ============================================================
//
// Tarkistaa Referral-suhteen perussäännöt.
//
// Tämä ei tarkista Firestoresta löytyykö referrer UID.
// Se tehdään referralService.js:ssä.
//
// ============================================================

function validateReferralRelationship(
  uid,
  referrerUid,
  userData,
) {
  if (
    !uid ||
    typeof uid !== "string"
  ) {
    return {
      valid: false,
      reason:
        "INVALID_USER_UID",
    };
  }

  if (
    !referrerUid ||
    typeof referrerUid !==
      "string"
  ) {
    return {
      valid: false,
      reason:
        "INVALID_REFERRER_UID",
    };
  }

  if (
    !ALLOW_SELF_REFERRAL &&
    isSelfReferral(
      uid,
      referrerUid,
    )
  ) {
    return {
      valid: false,
      reason:
        "SELF_REFERRAL",
    };
  }

  if (
    ONE_REFERRER_PER_USER &&
    !canSetReferrer(
      userData,
    )
  ) {
    return {
      valid: false,
      reason:
        "REFERRER_ALREADY_SET",
    };
  }

  return {
    valid: true,
    reason: null,
  };
}


// ============================================================
// 📝 BUILD REFERRAL RELATIONSHIP
// ============================================================
//
// Luo Firestoreen tallennettavan Referral-suhteen peruskentät.
//
// Tämä funktio EI lisää timestampia.
// Kutsuva service lisää serverTimestampin.
//
// ============================================================

function buildReferralRelationship(
  referrerUid,
  referralCode,
) {
  const safeReferrerUid =
    typeof referrerUid ===
    "string"
      ? referrerUid.trim()
      : "";

  const safeCode =
    normalizeReferralCode(
      referralCode,
    );

  return {
    referrerUid:
      safeReferrerUid,

    referralCodeUsed:
      safeCode,
  };
}


// ============================================================
// 📤 EXPORTS
// ============================================================

module.exports = {
  normalizeReferralCode,

  isValidReferralCode,

  generateReferralCode,

  referralCodesMatch,

  hasReferrer,

  canSetReferrer,

  isSelfReferral,

  getReferralData,

  getNestedReferralData,

  getReferralCode,

  getReferrerUid,

  getReferralCount,

  validateReferralRelationship,

  buildReferralRelationship,
};