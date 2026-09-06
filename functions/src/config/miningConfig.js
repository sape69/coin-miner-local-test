"use strict";

// ============================================================
// 🐱 STELLA MINING CONFIGURATION
// ============================================================
//
// Keskitetyt Stelluriinin mining-asetukset:
//
// ⚡ Daily Hash Rate
// 📺 Ad Boost
// ⛏️ Mining
// 📜 Transaction History
//
// ============================================================


// ============================================================
// ⚡ DAILY HASH RATE
// ============================================================
//
// Daily Streak määrittää käyttäjän peruslouhintatehon.
//
// Päivä 1  → 0.5 HR
// Päivä 2  → 1.0 HR
// Päivä 3  → 1.5 HR
// Päivä 4  → 2.0 HR
// Päivä 5  → 2.5 HR
// Päivä 6  → 3.0 HR
// Päivä 7+ → 3.5 HR
//
// Yksi väliin jäänyt päivä nollaa streakin.
// Seuraava kirjautuminen alkaa jälleen päivästä 1.
//
// ============================================================

// Ensimmäisen Daily Streak -päivän Hash Rate.

const DAILY_HASH_RATE_START = 0.5;


// Daily Streakin päivittäinen Hash Rate -kasvu.

const DAILY_HASH_RATE_STEP = 0.5;


// Suurin Daily Streak -päivä,
// jonka jälkeen Hash Rate ei enää kasva.

const DAILY_HASH_RATE_MAX_DAY = 7;


// Suurin Daily Streakistä saatava Hash Rate.

const MAX_DAILY_HASH_RATE = 3.5;


// ============================================================
// 📺 AD BOOST
// ============================================================
//
// Mainos antaa väliaikaisen Hash Rate -boostin.
//
// Boost ei kasaannu.
// Vain yksi mainosboost voi olla aktiivinen kerrallaan.
//
// Seuraavan mainoksen voi katsoa vasta,
// kun edellisen 4 tunnin boost on päättynyt.
//
// ============================================================

// Yhdestä mainoksesta saatava Hash Rate -boost.
//
// 3.5 HR / 6 mainosta ≈ 0.5833 HR.

const AD_HASH_RATE_BONUS = 0.5833;


// Mainosboostin kesto.
//
// 4 tuntia.

const AD_BOOST_DURATION_MS =
  4 * 60 * 60 * 1000;


// Mainosten suurin määrä päivässä.

const MAX_ADS_PER_DAY = 6;


// Mainosboostien välinen cooldown.
//
// Seuraava mainos voidaan katsoa vasta,
// kun edellinen 4 tunnin boost on päättynyt.

const AD_COOLDOWN_MS =
  4 * 60 * 60 * 1000;


// ============================================================
// ⛏️ MINING
// ============================================================

// Mining-syklin kokonaiskesto.
//
// 24 tuntia.

const MINING_DURATION_MS =
  24 * 60 * 60 * 1000;


// Kuinka paljon STL:ää muodostuu
// yhtä Hash Rate -yksikköä kohden tunnissa.
//
// 1 HR = 0.10 STL / tunti
// 3.5 HR = 0.35 STL / tunti

const MINING_PER_HASH_PER_HOUR =
  0.10;


// ============================================================
// 📜 TRANSACTION HISTORY
// ============================================================

// Kuinka monta viimeisintä tapahtumaa
// säilytetään käyttäjän historiassa.

const MAX_TRANSACTION_HISTORY =
  50;


// ============================================================
// 📦 EXPORTS
// ============================================================

module.exports = {

  // ⚡ DAILY HASH RATE

  DAILY_HASH_RATE_START,

  DAILY_HASH_RATE_STEP,

  DAILY_HASH_RATE_MAX_DAY,

  MAX_DAILY_HASH_RATE,


  // 📺 AD BOOST

  AD_HASH_RATE_BONUS,

  AD_BOOST_DURATION_MS,

  MAX_ADS_PER_DAY,

  AD_COOLDOWN_MS,


  // ⛏️ MINING

  MINING_DURATION_MS,

  MINING_PER_HASH_PER_HOUR,


  // 📜 HISTORY

  MAX_TRANSACTION_HISTORY,

};