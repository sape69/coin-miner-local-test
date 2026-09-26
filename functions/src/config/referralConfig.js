"use strict";

// ============================================================
// 🐱 STELLURIINI - REFERRAL CONFIGURATION
// ============================================================
//
// Stella Referral System.
//
// Referral-järjestelmän asetukset pidetään tässä tiedostossa,
// jotta niitä voidaan muuttaa myöhemmin ilman että varsinainen
// referral-logiikka täytyy rakentaa uudelleen.
//
// TÄRKEÄÄ:
//
// Referral-bonus ei ole käyttäjälle suoraan jaettava STL-palkkio.
//
// Bonus perustuu kutsutun käyttäjän hyväksyttyyn louhintatuottoon.
//
// Nykyinen suunnitelma:
// - Referral-bonus: 5 %
// - Yksi kutsuja käyttäjää kohden
// - Käyttäjä ei voi kutsua itseään
// - Referral voidaan asettaa vain kerran
//
// ============================================================


// ============================================================
// 🎁 DEFAULT REFERRAL BONUS
// ============================================================
//
// Kutsuja saa aluksi 5 % kutsutun käyttäjän hyväksytystä
// louhintatuotosta.
//
// Esimerkki:
//
// Kutsuttu käyttäjä louhii:
// 10 STL
//
// Referral-bonus:
// 10 × 0.05 = 0.5 STL
//
// ============================================================

const DEFAULT_REFERRAL_BONUS_RATE = 0.05;


// ============================================================
// 📊 REFERRAL BONUS PERCENTAGE
// ============================================================
//
// Julkinen prosenttiluku käyttöliittymää ja muita palveluita varten.
//
// 0.05 = 5 %
//
// ============================================================

const DEFAULT_REFERRAL_BONUS_PERCENT =
  DEFAULT_REFERRAL_BONUS_RATE * 100;


// ============================================================
// 🔢 MINIMUM VALID BONUS
// ============================================================
//
// Hyvin pieniä referral-bonuksia ei käsitellä negatiivisina,
// NaN-arvoina tai virheellisinä arvoina.
//
// Varsinainen taloudellinen käsittely tehdään referral-servicessä.
//
// ============================================================

const MIN_REFERRAL_BONUS = 0;


// ============================================================
// 👤 REFERRAL RELATIONSHIP RULES
// ============================================================
//
// Referral-suhde voidaan muodostaa vain kerran.
//
// Tämä estää käyttäjää vaihtamasta kutsujaa myöhemmin ja
// estää referral-bonusten moninkertaistamisen.
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
// 1️⃣ ONE REFERRER PER USER
// ============================================================
//
// Yhdellä käyttäjällä voi olla vain yksi kutsuja.
//
// ============================================================

const ONE_REFERRER_PER_USER = true;


// ============================================================
// 📈 REFERRAL MILESTONES
// ============================================================
//
// Tulevaisuudessa referral-bonusta voidaan tasapainottaa
// käyttäjämäärän kasvaessa.
//
// Näitä rajoja ei vielä käytetä varsinaisessa referral-
// laskennassa tässä vaiheessa.
//
// Ne toimivat keskitettynä valmisteluna tulevaa järjestelmää
// varten.
//
// Esimerkkimalli:
//
// 0–999 käyttäjää    → 5 %
// 1000–4999          → 4 %
// 5000–9999          → 3 %
// 10000+             → 2 %
//
// Lopulliset rajat voidaan muuttaa myöhemmin.
//
// ============================================================

const REFERRAL_MILESTONES = [
  {
    maxUsers: 999,
    bonusRate: 0.05,
  },
  {
    maxUsers: 4999,
    bonusRate: 0.04,
  },
  {
    maxUsers: 9999,
    bonusRate: 0.03,
  },
  {
    maxUsers: Number.POSITIVE_INFINITY,
    bonusRate: 0.02,
  },
];


// ============================================================
// 🧮 GET REFERRAL BONUS RATE
// ============================================================
//
// Palauttaa referral-bonusprosentin käyttäjämäärän perusteella.
//
// Tällä hetkellä järjestelmä voidaan pitää 5 % tasolla,
// mutta funktio valmistellaan jo käyttäjämäärän mukaiseen
// tasapainotukseen.
//
// ============================================================

function getReferralBonusRate(
  userCount = 0,
) {
  const normalizedUserCount =
    Number.isFinite(userCount) && userCount >= 0
      ? Math.floor(userCount)
      : 0;

  for (
    const milestone of REFERRAL_MILESTONES
  ) {
    if (
      normalizedUserCount <=
      milestone.maxUsers
    ) {
      return milestone.bonusRate;
    }
  }

  return DEFAULT_REFERRAL_BONUS_RATE;
}


// ============================================================
// 📊 GET REFERRAL BONUS PERCENT
// ============================================================

function getReferralBonusPercent(
  userCount = 0,
) {
  return (
    getReferralBonusRate(userCount) *
    100
  );
}


// ============================================================
// 🛡️ VALIDATE REFERRAL BONUS
// ============================================================
//
// Varmistaa, että laskettu bonus on käyttökelpoinen.
//
// ============================================================

function isValidReferralBonus(
  value,
) {
  return (
    Number.isFinite(value) &&
    value >= MIN_REFERRAL_BONUS
  );
}


// ============================================================
// 📦 EXPORTS
// ============================================================

module.exports = {
  DEFAULT_REFERRAL_BONUS_RATE,
  DEFAULT_REFERRAL_BONUS_PERCENT,
  MIN_REFERRAL_BONUS,

  ALLOW_REFERRER_CHANGE,
  ALLOW_SELF_REFERRAL,
  ONE_REFERRER_PER_USER,

  REFERRAL_MILESTONES,

  getReferralBonusRate,
  getReferralBonusPercent,

  isValidReferralBonus,
};