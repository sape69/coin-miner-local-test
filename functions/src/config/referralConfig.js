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
// Kutsuja saa lähtökohtaisesti 5 % kutsutun käyttäjän
// hyväksytystä louhintatuotosta.
//
// ============================================================

const DEFAULT_REFERRAL_BONUS_PERCENT = 5;


// ============================================================
// 📉 REFERRAL MILESTONES
// ============================================================
//
// Referral-bonus voidaan porrastaa järjestelmän kokonaiskäyttäjien
// määrän perusteella.
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
// 👤 REFERRAL RELATIONSHIP
// ============================================================
//
// YHDELLÄ KÄYTTÄJÄLLÄ voi olla vain yksi kutsuja.
//
// Tämä EI rajoita kutsujan kutsumien käyttäjien määrää.
//
// Esimerkiksi:
//
// Stella A
//   ├── Käyttäjä B
//   ├── Käyttäjä C
//   ├── Käyttäjä D
//   ├── Käyttäjä E
//   └── ...
//
// Kutsujalla EI ole ylärajaa.
//
// ============================================================

const ONE_REFERRER_PER_USER = true;


// ============================================================
// 🔄 REFERRER CHANGE
// ============================================================
//
// Referral-suhdetta ei voi vaihtaa normaalisti sen jälkeen,
// kun käyttäjälle on asetettu kutsuja.
//
// ============================================================

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
// Koodi on 8 merkkiä pitkä.
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
// 🔁 MAX CODE GENERATION ATTEMPTS
// ============================================================
//
// Kuinka monta kertaa järjestelmä yrittää luoda uuden
// referral-koodin, jos satunnainen koodi on jo käytössä.
//
// Tämä estää referral-koodin luonnin jäämisen
// määrittelemättömään tilaan.
//
// ============================================================

const MAX_CODE_GENERATION_ATTEMPTS = 20;


// ============================================================
// 💰 MINIMUM REFERRAL BONUS
// ============================================================
//
// Referral-laskennan tekninen minimiraja.
//
// Tämä EI ole käyttäjän STL-nostoraja.
//
// ============================================================

const MIN_REFERRAL_BONUS = 0;


// ============================================================
// 📊 BONUS SOURCE
// ============================================================
//
// Referral-bonus syntyy vain hyväksytystä mining-tuotosta.
//
// Mainosten katsomisesta ei makseta suoraan referral-bonusta.
//
// ============================================================

const REFERRAL_BONUS_SOURCE = "mining";


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

const REFERRAL_CALCULATION_SERVER_SIDE = true;


// ============================================================
// 📜 REFERRAL HISTORY
// ============================================================
//
// Referral-tapahtumille voidaan käyttää omaa historiaa.
//
// Varsinainen STL-kirjaus tehdään myöhemmin mining-järjestelmän
// kanssa.
//
// ============================================================

const REFERRAL_HISTORY_COLLECTION =
  "referralHistory";


// ============================================================
// 👤 USER REFERRAL DATA
// ============================================================
//
// Käyttäjän referral-tiedot voidaan säilyttää myös käyttäjän
// omassa Firestore-dokumentissa.
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
// 🔄 GET REFERRAL BONUS RATE
// ============================================================
//
// ReferralService käyttää tätä funktiota.
//
// Palautusarvo on desimaalimuodossa:
//
// 5 % = 0.05
// 4 % = 0.04
// 3 % = 0.03
// 2 % = 0.02
// 1 % = 0.01
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
// miningAmount = 100 STL
// referralPercent = 5
//
// bonus = 5 STL
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
// 🛡️ VALIDATE REFERRAL BONUS
// ============================================================
//
// Varmistaa, että laskettu referral-bonus on kelvollinen.
//
// ============================================================

function isValidReferralBonus(
  bonus,
) {
  const amount =
    Number(bonus);

  return (
    Number.isFinite(amount) &&
    amount > MIN_REFERRAL_BONUS
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