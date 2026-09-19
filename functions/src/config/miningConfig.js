"use strict";

// ==========================================
// 🐱 STELLURIINI MINING CONFIGURATION
// ==========================================
//
// Keskitetty Stelluriini Mining -asetustiedosto.
//
// TÄRKEÄÄ:
// - Daily Hash Rate ei ole STL-palkkio.
// - AdMob Rewarded Ad ei anna suoraan STL-tokenia.
// - Power Boost kasvattaa louhintatehoa määräajaksi.
// - Varsinainen STL-tuotto lasketaan mining-logiikassa.
//
// ==========================================


// ==========================================
// 🎁 DAILY HASH RATE
// ==========================================

// Ensimmäisen päivän Hash Rate.
const DAILY_HASH_RATE_START = 0.5;


// Päivittäinen Hash Rate -kasvu.
const DAILY_HASH_RATE_STEP = 0.5;


// Kuinka pitkälle Daily Hash Rate kasvaa.
const DAILY_HASH_RATE_MAX_DAY = 7;


// Daily Hash Raten absoluuttinen maksimi.
const MAX_DAILY_HASH_RATE = 3.5;


// ==========================================
// 📺 ADMOB POWER BOOST
// ==========================================

// Power Boostin antama lisä-Hash Rate.
const AD_HASH_RATE_BONUS = 0.5833;


// Power Boostin kesto.
//
// 4 tuntia.
const AD_BOOST_DURATION_MS =
  4 * 60 * 60 * 1000;


// Kuinka monta Power Boost -mainosta
// käyttäjä voi käyttää yhden UTC-päivän aikana.
const MAX_ADS_PER_DAY = 6;


// Kahden Power Boost -mainoksen välinen
// vähimmäisaika.
//
// Tässä se vastaa Boostin 4 tunnin kestoa.
const AD_COOLDOWN_MS =
  4 * 60 * 60 * 1000;


// ==========================================
// 🔐 ADMOB REWARDED AD
// ==========================================

// Tuotannossa käytettävä täydellinen
// AdMob Rewarded Ad Unit ID.
//
// Tätä käytetään Flutter-sovelluksessa.
const ADMOB_REWARDED_AD_UNIT_ID =
  "ca-app-pub-1131012057145658/7225738491";


// AdMob SSV callbackissa tuleva
// numeerinen Ad Unit ID.
//
// Tätä voidaan käyttää palvelinpuolella
// SSV-tapahtuman validointiin.
const ADMOB_SSV_AD_UNIT_ID =
  "7225738491";


// ==========================================
// 🎁 ADMOB SSV REWARD METADATA
// ==========================================
//
// Nämä arvot kuvaavat AdMobin lähettämää
// reward-metadataa.
//
// TÄRKEÄÄ:
// Tämä EI tarkoita, että käyttäjälle
// annetaan 1 STL.
//
// Varsinainen Stelluriini-palkinto on
// Power Boost / Mining-toiminto.
//

const ADMOB_SSV_REWARD_AMOUNT = 1;


const ADMOB_SSV_REWARD_ITEM =
  "Power Boost";


// ==========================================
// ⛏️ MINING
// ==========================================

// Yhden louhintajakson pituus.
//
// 24 tuntia.
const MINING_DURATION_MS =
  24 * 60 * 60 * 1000;


// STL-tuotto yhtä Hash Rate -yksikköä
// ja yhtä tuntia kohden.
//
// Esimerkiksi:
//
// 3.5 HR × 0.10 × 24 h
// = 8.4 STL
//
const MINING_PER_HASH_PER_HOUR = 0.10;


// ==========================================
// 📜 TRANSACTION HISTORY
// ==========================================

// Käyttäjän historian enimmäismäärä,
// jota voidaan käyttää sovelluksen
// transaction/history-logiikassa.
const MAX_TRANSACTION_HISTORY = 50;


// ==========================================
// 📦 EXPORTS
// ==========================================

module.exports = {
  // Daily Hash Rate
  DAILY_HASH_RATE_START,
  DAILY_HASH_RATE_STEP,
  DAILY_HASH_RATE_MAX_DAY,
  MAX_DAILY_HASH_RATE,

  // AdMob Power Boost
  AD_HASH_RATE_BONUS,
  AD_BOOST_DURATION_MS,
  MAX_ADS_PER_DAY,
  AD_COOLDOWN_MS,

  // AdMob
  ADMOB_REWARDED_AD_UNIT_ID,
  ADMOB_SSV_AD_UNIT_ID,
  ADMOB_SSV_REWARD_AMOUNT,
  ADMOB_SSV_REWARD_ITEM,

  // Mining
  MINING_DURATION_MS,
  MINING_PER_HASH_PER_HOUR,

  // History
  MAX_TRANSACTION_HISTORY,
};