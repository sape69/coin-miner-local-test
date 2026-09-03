"use strict";


// ============================================================
// 🐱 STELLURIINI — STELLA MINING CONFIG
// ============================================================
//
// Kaikki Stella Mining Backendin tärkeät asetukset.
//
// ⛏️ Mining
// 🎁 Daily Bonus
// 📺 Ad Power Boost
// 📜 Transaction History
//
// ============================================================


// ============================================================
// 🐱 DEFAULT HASH RATE
// ============================================================
//
// Uusi Stella-pelaaja aloittaa tällä Hash Rate -määrällä.
//

const DEFAULT_HASH_RATE = 1;


// ============================================================
// 🎁 DAILY STELLA BONUS
// ============================================================
//
// Päivittäinen Stella Check-In kasvattaa Hash Ratea.
//

const DAILY_HASH_RATE_BONUS = 1;


// ============================================================
// 📺 STELLA POWER BOOST
// ============================================================
//
// Mainospalkinto kasvattaa Hash Ratea.
//

const AD_HASH_RATE_BONUS = 5;


// ============================================================
// 📺 MAX ADS PER DAY
// ============================================================
//
// Kuinka monta Stella Power Boostia käyttäjä voi saada
// yhden UTC-päivän aikana.
//

const MAX_ADS_PER_DAY = 5;


// ============================================================
// ⏳ AD COOLDOWN
// ============================================================
//
// Mainospalkintojen välinen odotusaika.
//
// 60 minuuttia.
//

const AD_COOLDOWN_MS =
  60 * 60 * 1000;


// ============================================================
// ⛏️ STELLA MINING DURATION
// ============================================================
//
// Yksi Stella Mining -jakso kestää:
//
// 24 tuntia.
//

const MINING_DURATION_MS =
  24 * 60 * 60 * 1000;


// ============================================================
// 💰 STL MINING SPEED
// ============================================================
//
// Kuinka paljon STL:ää syntyy:
//
// 1 Hash Rate
// = 0.10 STL / tunti
//
// Esimerkkejä:
//
// 1 Hash Rate
// = 0.10 STL / tunti
// = 2.40 STL / 24 tuntia
//
// 10 Hash Rate
// = 1.00 STL / tunti
// = 24.00 STL / 24 tuntia
//

const MINING_PER_HASH_PER_HOUR =
  0.10;


// ============================================================
// 📜 TRANSACTION HISTORY
// ============================================================
//
// Kuinka monta viimeisintä Stella-tapahtumaa
// palautetaan sovellukseen.
//

const MAX_TRANSACTION_HISTORY =
  50;


// ============================================================
// ⚙️ EXPORTS
// ============================================================

module.exports = {

  // 🐱 Stella Hash Rate

  DEFAULT_HASH_RATE,


  // 🎁 Stella Daily

  DAILY_HASH_RATE_BONUS,


  // 📺 Stella Power Boost

  AD_HASH_RATE_BONUS,

  MAX_ADS_PER_DAY,

  AD_COOLDOWN_MS,


  // ⛏️ Stella Mining

  MINING_DURATION_MS,

  MINING_PER_HASH_PER_HOUR,


  // 📜 Stella History

  MAX_TRANSACTION_HISTORY,

};