"use strict";

// ============================================================
// 🐱 STELLURIINI - VALIDATE REFERRAL CODE
// ============================================================
//
// Stella Referral System.
//
// Tämä callable function tarkistaa referral-koodin ENNEN kuin
// uusi Firebase Auth -käyttäjä luodaan.
//
// TÄRKEÄÄ:
//
// - käyttäjän ei tarvitse olla kirjautunut
// - tämä funktio EI luo referral-suhdetta
// - tämä funktio EI luo käyttäjätiliä
// - tämä funktio EI muuta Firestore-dataa
// - varsinainen referral-suhde luodaan myöhemmin
//   applyReferralCode-funktiossa
//
// Käyttötarkoitus:
//
// 1. Flutter kysyy, onko referral-koodi olemassa.
// 2. Jos koodi on voimassa, Flutter voi jatkaa rekisteröintiä.
// 3. Jos koodia ei löydy, Flutter kysyy käyttäjältä,
//    haluaako hän jatkaa ilman referral-koodia.
//
// ============================================================

const {
  onCall,
} = require("firebase-functions/v2/https");

const {
  normalizeReferralCode,
  isValidReferralCode,
} = require("../utils/referralUtils");

const {
  findReferralCode,
} = require("../services/referralService");

// ============================================================
// 🔍 VALIDATE REFERRAL CODE
// ============================================================

const validateReferralCode =
  onCall(
    {
      region:
        "us-central1",
    },
    async (request) => {
      const rawCode =
        request.data?.referralCode;

      const referralCode =
        normalizeReferralCode(
          typeof rawCode === "string"
            ? rawCode
            : "",
        );

      // --------------------------------------------------------
      // Tyhjä referral-koodi
      // --------------------------------------------------------
      //
      // Tyhjä koodi ei ole virhe backendissä.
      // Flutter voi tämän perusteella jatkaa normaalisti.
      //
      // --------------------------------------------------------

      if (!referralCode) {
        return {
          success: true,
          valid: true,
          empty: true,
          referralCode: "",
        };
      }

      // --------------------------------------------------------
      // Referral-koodin muoto
      // --------------------------------------------------------

      if (
        !isValidReferralCode(
          referralCode,
        )
      ) {
        return {
          success: true,
          valid: false,
          empty: false,
          referralCode,
        };
      }

      // --------------------------------------------------------
      // Tarkista koodi Firestoresta
      // --------------------------------------------------------
      //
      // findReferralCode palauttaa vain olemassa olevan
      // referral-koodin tiedot.
      //
      // Kutsujan UID:ta ei palauteta clientille.
      //
      // --------------------------------------------------------

      const referral =
        await findReferralCode(
          referralCode,
        );

      if (!referral) {
        return {
          success: true,
          valid: false,
          empty: false,
          referralCode,
        };
      }

      return {
        success: true,
        valid: true,
        empty: false,
        referralCode,
      };
    },
  );

// ============================================================
// EXPORT
// ============================================================

module.exports = {
  validateReferralCode,
};