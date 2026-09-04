"use strict";

// ============================================================
// 🐱 STELLA MINING CONFIGURATION
// ============================================================
//
// Keskitetyt asetukset:
//
// ⚡ Hash Rate
// 📅 Daily Bonus
// 📺 Ad Rewards
// ⛏️ Mining
// 📜 Transaction History
//
// ============================================================


// ============================================================
// ⚡ HASH RATE
// ============================================================

// Käyttäjän oletus Hash Rate.

const DEFAULT_HASH_RATE = 1;


// Päivittäisestä toiminnosta saatava Hash Rate -bonus.

const DAILY_HASH_RATE_BONUS = 1;


// Mainoksen katsomisesta saatava Hash Rate -bonus.

const AD_HASH_RATE_BONUS = 5;


// ============================================================
// 📺 ADMOB / ADS
// ============================================================

// Mainosten suurin määrä päivässä.

const MAX_ADS_PER_DAY = 5;


// Mainosten välinen cooldown.
//
// 1 tunti.

const AD_COOLDOWN_MS =
  60 * 60 * 1000;


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

  // ⚡ HASH RATE

  DEFAULT_HASH_RATE,

  DAILY_HASH_RATE_BONUS,

  AD_HASH_RATE_BONUS,


  // 📺 ADS

  MAX_ADS_PER_DAY,

  AD_COOLDOWN_MS,


  // ⛏️ MINING

  MINING_DURATION_MS,

  MINING_PER_HASH_PER_HOUR,


  // 📜 HISTORY

  MAX_TRANSACTION_HISTORY,

};