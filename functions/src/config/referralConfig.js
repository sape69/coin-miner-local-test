"use strict";

// ============================================================
// 🐱 STELLURIINI - REFERRAL CONFIGURATION
// ============================================================
//
// Stella Referral System.
//
// Referral-bonus perustuu kutsutun käyttäjän hyväksyttyyn
// louhintatuottoon.
//
// TÄRKEÄÄ:
//
// Referral EI anna käyttäjälle STL-palkkiota rekisteröitymisestä.
//
// Referral-bonus muodostuu ainoastaan kutsutun käyttäjän
// hyväksytystä louhintatuotosta.
//
// Client ei päätä referral-bonuksen määrää.
// Backend laskee bonuksen server-side.
//
// ============================================================


// ============================================================
// 🎁 DEFAULT REFERRAL BONUS
// ============================================================
//
// Kutsuja saa lähtökohtaisesti 24 % kutsutun käyttäjän
// hyväksytystä louhintatuotosta.
//
// Nykyisellä Day 7+ mining-teholla:
//
// 3.5 HR × 0.10 STL × 24 h
// = 8.4 STL / päivä
//
// 8.4 × 24 %
// = 2.016 STL / päivä
//
// ============================================================

const DEFAULT_REFERRAL_BONUS_PERCENT =
  24;


// ============================================================
// 📉 REFERRAL MILESTONES
// ============================================================
//
// Referral-bonus porrastuu järjestelmän käyttäjämäärän mukaan.
//
// 0 - 999 käyttäjää
//     → 24 %
//
// 1 000 - 4 999 käyttäjää
//     → 20 %
//
// 5 000 - 9 999 käyttäjää
//     → 15 %
//
// 10 000 - 24 999 käyttäjää
//     → 10 %
//
// 25 000+ käyttäjää
//     → 5 %
//
// Lista pidetään suurimmasta milestone-arvosta
// pienimpään, jotta oikea taso löytyy heti.
//
// ============================================================

const REFERRAL_MILESTONES = [
  {
    minUsers: 25000,
    bonusPercent: 5,
  },
  {
    minUsers: 10000,
    bonusPercent: 10,
  },
  {
    minUsers: 5000,
    bonusPercent: 15,
  },
  {
    minUsers: 1000,
    bonusPercent: 20,
  },
];


// ============================================================
// 👤 REFERRAL RELATIONSHIP
// ============================================================
//
// Yhdellä käyttäjällä voi olla vain yksi kutsuja.
//
// Kutsujalla ei ole ylärajaa kutsuttujen käyttäjien määrälle.
//
// ============================================================

const ONE_REFERRER_PER_USER =
  true;


// ============================================================
// 🔄 REFERRER CHANGE
// ============================================================
//
// Referral-suhdetta ei voi vaihtaa sen jälkeen,
// kun käyttäjälle on asetettu kutsuja.
//
// ============================================================

const ALLOW_REFERRER_CHANGE =
  false;


// ============================================================
// 🚫 SELF REFERRAL
// ============================================================
//
// Käyttäjä ei voi käyttää omaa referral-koodiaan.
//
// ============================================================

const ALLOW_SELF_REFERRAL =
  false;


// ============================================================
// 🔗 REFERRAL CODE
// ============================================================

const REFERRAL_CODE_LENGTH =
  8;


// ============================================================
// 🔤 REFERRAL CODE CHARACTERS
// ============================================================
//
// Poistetaan helposti sekoitettavat merkit:
//
// O / 0
// I / 1
// L
//
// ============================================================

const REFERRAL_CODE_CHARACTERS =
  "ABCDEFGHJKMNPQRSTUVWXYZ23456789";


// ============================================================
// 🔁 MAX CODE GENERATION ATTEMPTS
// ============================================================

const MAX_CODE_GENERATION_ATTEMPTS =
  20;


// ============================================================
// 💰 MINIMUM REFERRAL BONUS
// ============================================================
//
// 0 tarkoittaa, ettei erillistä STL-määrärajaa aseteta.
//
// ============================================================

const MIN_REFERRAL_BONUS =
  0;


// ============================================================
// 📊 BONUS SOURCE
// ============================================================
//
// Referral-bonus syntyy vain hyväksytystä mining-tuotosta.
//
// Mainoksen katsomisesta ei makseta suoraan referral-bonusta.
//
// ============================================================

const REFERRAL_BONUS_SOURCE =
  "mining";


// ============================================================
// 🛡️ REFERRAL CALCULATION
// ============================================================
//
// Referral-bonus lasketaan aina backendissä.
//
// Client ei saa päättää:
//
// - referral-prosenttia
// - bonusmäärää
// - kutsujaa
// - kutsutun käyttäjän louhintatuottoa
//
// ============================================================

const REFERRAL_CALCULATION_SERVER_SIDE =
  true;


// ============================================================
// 📜 REFERRAL HISTORY
// ============================================================

const REFERRAL_HISTORY_COLLECTION =
  "referralHistory";


// ============================================================
// 👤 USER REFERRAL DATA
// ============================================================

const REFERRAL_DATA_FIELD =
  "referral";


// ============================================================
// 🎯 GET REFERRAL BONUS PERCENT
// ============================================================
//
// Palauttaa käyttäjämäärään perustuvan referral-prosentin.
//
// Jos mikään milestone ei täyty, käytetään oletusarvoa.
//
// ============================================================

function getReferralBonusPercent(
  totalUsers,
) {
  const numericUsers =
    Number(totalUsers);

  const userCount =
    Number.isFinite(
      numericUsers,
    )
      ? Math.max(
          0,
          Math.floor(
            numericUsers,
          ),
        )
      : 0;

  for (
    const milestone of
      REFERRAL_MILESTONES
  ) {
    const minUsers =
      Number(
        milestone.minUsers,
      );

    const bonusPercent =
      Number(
        milestone.bonusPercent,
      );

    if (
      !Number.isFinite(
        minUsers,
      ) ||
      !Number.isFinite(
        bonusPercent,
      )
    ) {
      continue;
    }

    if (
      userCount >=
      minUsers
    ) {
      return Math.max(
        0,
        bonusPercent,
      );
    }
  }

  return Math.max(
    0,
    DEFAULT_REFERRAL_BONUS_PERCENT,
  );
}


// ============================================================
// 🔄 GET REFERRAL BONUS RATE
// ============================================================
//
// 24 % = 0.24
// 20 % = 0.20
// 15 % = 0.15
// 10 % = 0.10
// 5 %  = 0.05
//
// ============================================================

function getReferralBonusRate(
  totalUsers,
) {
  const bonusPercent =
    getReferralBonusPercent(
      totalUsers,
    );

  return (
    bonusPercent / 100
  );
}


// ============================================================
// 🧮 CALCULATE REFERRAL BONUS
// ============================================================
//
// Laskee referral-bonuksen kutsutun käyttäjän hyväksytystä
// louhintatuotosta.
//
// Esimerkki:
//
// Day 7+:
//
// miningAmount = 8.4 STL
// referralPercent = 24
//
// bonus = 8.4 × 0.24
//       = 2.016 STL
//
// Tämä funktio EI kirjoita Firestoreen.
//
// ============================================================

function calculateReferralBonus(
  miningAmount,
  totalUsers,
) {
  const amount =
    Number(miningAmount);

  if (
    !Number.isFinite(
      amount,
    ) ||
    amount <= 0
  ) {
    return 0;
  }

  const rate =
    getReferralBonusRate(
      totalUsers,
    );

  if (
    !Number.isFinite(
      rate,
    ) ||
    rate <= 0
  ) {
    return 0;
  }

  const bonus =
    amount * rate;

  if (
    !Number.isFinite(
      bonus,
    ) ||
    bonus <=
      MIN_REFERRAL_BONUS
  ) {
    return 0;
  }

  return bonus;
}


// ============================================================
// 🛡️ VALIDATE REFERRAL BONUS
// ============================================================
//
// Varmistaa, että referral-bonus on kelvollinen.
//
// Bonus ei voi olla negatiivinen eikä nolla.
//
// ============================================================

function isValidReferralBonus(
  bonus,
) {
  const amount =
    Number(bonus);

  return (
    Number.isFinite(
      amount,
    ) &&
    amount >
      MIN_REFERRAL_BONUS
  );
}


// ============================================================
// 📦 EXPORTS
// ============================================================

module.exports = {
  // ----------------------------------------------------------
  // 🎁 DEFAULT BONUS
  // ----------------------------------------------------------

  DEFAULT_REFERRAL_BONUS_PERCENT,


  // ----------------------------------------------------------
  // 📉 MILESTONES
  // ----------------------------------------------------------

  REFERRAL_MILESTONES,


  // ----------------------------------------------------------
  // 👤 RELATIONSHIP
  // ----------------------------------------------------------

  ONE_REFERRER_PER_USER,

  ALLOW_REFERRER_CHANGE,


  // ----------------------------------------------------------
  // 🚫 SELF REFERRAL
  // ----------------------------------------------------------

  ALLOW_SELF_REFERRAL,


  // ----------------------------------------------------------
  // 🔗 REFERRAL CODE
  // ----------------------------------------------------------

  REFERRAL_CODE_LENGTH,

  REFERRAL_CODE_CHARACTERS,

  MAX_CODE_GENERATION_ATTEMPTS,


  // ----------------------------------------------------------
  // 💰 BONUS
  // ----------------------------------------------------------

  MIN_REFERRAL_BONUS,

  REFERRAL_BONUS_SOURCE,


  // ----------------------------------------------------------
  // 🛡️ SECURITY
  // ----------------------------------------------------------

  REFERRAL_CALCULATION_SERVER_SIDE,


  // ----------------------------------------------------------
  // 📜 FIRESTORE
  // ----------------------------------------------------------

  REFERRAL_HISTORY_COLLECTION,

  REFERRAL_DATA_FIELD,


  // ----------------------------------------------------------
  // 🧮 FUNCTIONS
  // ----------------------------------------------------------

  getReferralBonusPercent,

  getReferralBonusRate,

  calculateReferralBonus,

  isValidReferralBonus,
};