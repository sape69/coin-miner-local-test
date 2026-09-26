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
// IMPORTANT:
//
// Referral ei anna käyttäjälle STL-palkkiota rekisteröitymisestä.
//
// Referral-bonus muodostuu ainoastaan kutsutun käyttäjän
// hyväksytystä louhintatuotosta.
//
// Kaikki referral-bonuksen lopulliset laskennat tehdään
// backendissä.
//
// ============================================================


// ============================================================
// 🎁 DEFAULT REFERRAL BONUS
// ============================================================
//
// Kutsuja saa oletuksena 5 % kutsutun käyttäjän
// hyväksytystä louhintatuotosta.
//
// ============================================================

const DEFAULT_REFERRAL_BONUS_PERCENT = 5;


// ============================================================
// 📉 REFERRAL MILESTONES
// ============================================================
//
// Referral-bonusta voidaan pienentää käyttäjämäärän kasvaessa.
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
// Taulukko käydään läpi suurimmasta rajasta pienimpään.
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
// Referral-suhdetta ei voi vaihtaa myöhemmin.
//
// ============================================================

const MAX_REFERRERS_PER_USER = 1;

const ONE_REFERRER_PER_USER =
  MAX_REFERRERS_PER_USER === 1;

const ALLOW_REFERRER_CHANGE = false;


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
// ============================================================

const REFERRAL_CODE_LENGTH = 8;


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
// 🔢 REFERRAL CODE GENERATION
// ============================================================
//
// Kuinka monta yritystä uuden yksilöllisen referral-koodin
// luomisessa sallitaan.
//
// ============================================================

const MAX_CODE_GENERATION_ATTEMPTS = 10;


// ============================================================
// 💰 MINIMUM REFERRAL BONUS
// ============================================================
//
// Tämä ei ole käyttäjän STL-nostoraja.
//
// Tämä on ainoastaan referral-laskennan tekninen alaraja.
//
// ============================================================

const MIN_REFERRAL_BONUS = 0;


// ============================================================
// 📊 BONUS SOURCE
// ============================================================
//
// Referral-bonus voidaan laskea vain hyväksytystä
// louhintatuotosta.
//
// AdMob-palkkio ei ole referral-bonuksen lähde.
//
// ============================================================

const REFERRAL_BONUS_SOURCE = "mining";


// ============================================================
// 🛡️ SERVER-SIDE CALCULATION
// ============================================================
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
// Käyttäjän referral-tiedot voidaan säilyttää käyttäjän
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
// ============================================================

function getReferralBonusPercent(
  totalUsers,
) {
  const userCount =
    Number.isFinite(
      Number(totalUsers),
    )
      ? Math.max(
          0,
          Math.floor(
            Number(totalUsers),
          ),
        )
      : 0;

  for (
    const milestone of
      REFERRAL_MILESTONES
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
// 📈 GET REFERRAL BONUS RATE
// ============================================================
//
// Palauttaa referral-bonusprosentin desimaalimuodossa.
//
// Esimerkiksi:
//
// 5 % → 0.05
// 4 % → 0.04
// 1 % → 0.01
//
// referralService.js käyttää tätä funktiota
// referral-bonuksen laskennassa.
//
// ============================================================

function getReferralBonusRate(
  totalUsers,
) {
  return (
    getReferralBonusPercent(
      totalUsers,
    ) / 100
  );
}


// ============================================================
// 🧮 CALCULATE REFERRAL BONUS
// ============================================================
//
// Laskee referral-bonuksen kutsutun käyttäjän
// louhintatuotosta.
//
// Esimerkki:
//
// miningAmount = 100 STL
// bonus = 5 %
//
// → 5 STL
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
    !Number.isFinite(amount) ||
    amount <= 0
  ) {
    return 0;
  }

  const rate =
    getReferralBonusRate(
      totalUsers,
    );

  const bonus =
    amount * rate;

  if (
    !Number.isFinite(bonus) ||
    bonus <= MIN_REFERRAL_BONUS
  ) {
    return 0;
  }

  return bonus;
}


// ============================================================
// ✅ VALIDATE REFERRAL BONUS
// ============================================================
//
// Tarkistaa, että referral-bonus on kelvollinen.
//
// Tämä suojaa myöhempää referral-service-logiikkaa
// virheellisiltä arvoilta.
//
// ============================================================

function isValidReferralBonus(
  bonus,
) {
  const value =
    Number(bonus);

  return (
    Number.isFinite(value) &&
    value > MIN_REFERRAL_BONUS
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
  // 👥 RELATIONSHIP
  // ----------------------------------------------------------

  MAX_REFERRERS_PER_USER,

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