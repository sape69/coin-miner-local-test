"use strict";

// ============================================================
// 🐱 STELLURIINI - REFERRAL CONFIGURATION
// ============================================================
//
// Stella Referral System.
//
// Referral-bonus perustuu kutsutun käyttäjän louhintatuottoon.
//
// IMPORTANT:
//
// Referral ei anna käyttäjälle STL-palkkiota rekisteröitymisestä.
//
// Referral-bonus muodostuu ainoastaan kutsutun käyttäjän
// hyväksytystä louhintatuotosta.
//
// ============================================================


// ============================================================
// 🎁 DEFAULT REFERRAL BONUS
// ============================================================
//
// Nykyinen suunniteltu lähtötaso:
//
// Kutsuja saa 5 % kutsutun käyttäjän louhintatuotosta.
//
// ============================================================

const DEFAULT_REFERRAL_BONUS_PERCENT = 5;


// ============================================================
// 📉 REFERRAL MILESTONES
// ============================================================
//
// Referral-bonusta voidaan pienentää käyttäjämäärän kasvaessa.
//
// Näitä arvoja voidaan muuttaa myöhemmin ilman referral-logiikan
// muuttamista.
//
// Esimerkki:
//
// 0 - 999 käyttäjää
//     → 5 %
//
// 1 000 - 4 999 käyttäjää
//     → 4 %
//
// 5 000 - 9 999 käyttäjää
//     → 3 %
//
// 10 000 - 24 999 käyttäjää
//     → 2 %
//
// 25 000+ käyttäjää
//     → 1 %
//
// ============================================================

const REFERRAL_MILESTONES = [
  {
    minUsers: 25000,
    bonusPercent: 1,
  },
  {
    minUsers: 10000,
    bonusPercent: 2,
  },
  {
    minUsers: 5000,
    bonusPercent: 3,
  },
  {
    minUsers: 1000,
    bonusPercent: 4,
  },
];


// ============================================================
// 👥 REFERRAL RELATIONSHIP
// ============================================================
//
// Yhdellä käyttäjällä voi olla vain yksi kutsuja.
//
// Referral-suhdetta ei saa vaihtaa vapaasti myöhemmin.
//
// ============================================================

const MAX_REFERRERS_PER_USER = 1;


// ============================================================
// 🚫 SELF REFERRAL
// ============================================================
//
// Käyttäjä ei voi käyttää omaa referral-koodiaan.
//
// ============================================================

const ALLOW_SELF_REFERRAL = false;


// ============================================================
// 🔗 REFERRAL CODE
// ============================================================
//
// Referral-koodi luodaan käyttäjälle kerran.
//
// Koodin pituus pidetään lyhyenä, jotta se on helppo jakaa.
//
// ============================================================

const REFERRAL_CODE_LENGTH = 8;


// ============================================================
// 🔢 REFERRAL CODE CHARACTERS
// ============================================================
//
// Poistetaan helposti sekoitettavia merkkejä:
//
// O / 0
// I / 1
// L
//
// ============================================================

const REFERRAL_CODE_CHARACTERS =
  "ABCDEFGHJKMNPQRSTUVWXYZ23456789";


// ============================================================
// 💰 MINIMUM REFERRAL BONUS
// ============================================================
//
// Hyvin pieniä pyöristämättömiä bonuksia ei kirjata.
//
// Tämä ei tarkoita käyttäjän STL-nostorajaa.
//
// Se on ainoastaan referral-laskennan tekninen raja.
//
// ============================================================

const MIN_REFERRAL_BONUS = 0;


// ============================================================
// 📊 BONUS SOURCE
// ============================================================
//
// Referral-bonus voidaan laskea vain hyväksytystä louhintatuotosta.
//
// Mainospalkkiot eivät ole referral-bonuksen lähde.
//
// ============================================================

const REFERRAL_BONUS_SOURCE = "mining";


 // ============================================================
 // 🛡️ REFERRAL SAFETY
 // ============================================================
 //
 // Referral-bonuksen laskennan pitää tapahtua backendissä.
 //
 // Client ei saa päättää:
 //
 // - referral-prosenttia
 // - bonusmäärää
 // - kutsujaa
 // - kutsutun käyttäjän louhintatuottoa
 //
 // ============================================================

const REFERRAL_CALCULATION_SERVER_SIDE = true;


// ============================================================
// 📜 REFERRAL HISTORY
// ============================================================
//
// Referral-tapahtumat voidaan tallentaa omaan historiaansa.
//
// ============================================================

const REFERRAL_HISTORY_COLLECTION =
  "referralHistory";


// ============================================================
// 👤 USER REFERRAL DATA
// ============================================================
//
// Käyttäjän referral-tiedot voidaan säilyttää käyttäjän omassa
// Firestore-dokumentissa.
//
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
  const userCount =
    Number.isFinite(totalUsers)
      ? Math.max(0, Math.floor(totalUsers))
      : 0;

  for (
    const milestone of REFERRAL_MILESTONES
  ) {
    if (
      userCount >=
      milestone.minUsers
    ) {
      return milestone.bonusPercent;
    }
  }

  return DEFAULT_REFERRAL_BONUS_PERCENT;
}


// ============================================================
// 🧮 CALCULATE REFERRAL BONUS
// ============================================================
//
// Laskee referral-bonuksen kutsutun käyttäjän louhintatuotosta.
//
// Esimerkki:
//
// miningAmount = 100 STL
// referralPercent = 5
//
// bonus = 5 STL
//
// ============================================================

function calculateReferralBonus(
  miningAmount,
  totalUsers,
) {
  const amount =
    Number(miningAmount);

  if (
    !Number.isFinite(amount) ||
    amount <= 0
  ) {
    return 0;
  }

  const bonusPercent =
    getReferralBonusPercent(
      totalUsers,
    );

  const bonus =
    amount *
    (bonusPercent / 100);

  if (
    !Number.isFinite(bonus) ||
    bonus <= MIN_REFERRAL_BONUS
  ) {
    return 0;
  }

  return bonus;
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
  // 👥 RELATIONSHIP
  // ----------------------------------------------------------

  MAX_REFERRERS_PER_USER,


  // ----------------------------------------------------------
  // 🚫 SELF REFERRAL
  // ----------------------------------------------------------

  ALLOW_SELF_REFERRAL,


  // ----------------------------------------------------------
  // 🔗 REFERRAL CODE
  // ----------------------------------------------------------

  REFERRAL_CODE_LENGTH,

  REFERRAL_CODE_CHARACTERS,


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

  calculateReferralBonus,

};