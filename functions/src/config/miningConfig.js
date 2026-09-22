"use strict";

// ============================================================
// 🐱 STELLURIINI MINING CONFIGURATION
// ============================================================
//
// Keskitetty Stelluriini Mining -asetustiedosto.
//
// TÄRKEÄÄ:
//
// - Daily Hash Rate ei ole STL-palkkio.
// - AdMob Rewarded Ad ei anna suoraan STL-tokenia.
// - AdMob SSV vahvistaa rewarded-mainoksen.
// - Mining Start käyttää vahvistettua AdMob-palkintoa
//   uuden mining-jakson käynnistämiseen.
// - Power Boost käyttää vahvistettua AdMob-palkintoa
//   aktiivisen mining-jakson tehostamiseen.
// - Power Boost ei voi jatkua mining-jakson yli.
// - Power Boost ei siirry seuraavaan mining-jaksoon.
// - Varsinainen STL-tuotto lasketaan mining-logiikassa.
//
// ============================================================


// ============================================================
// 🎁 DAILY HASH RATE
// ============================================================
//
// Daily Hash Rate määräytyy Daily Streakin perusteella.
//
// Päivä 1:
// 0.5 HR
//
// Päivä 2:
// 1.0 HR
//
// Päivä 3:
// 1.5 HR
//
// Päivä 4:
// 2.0 HR
//
// Päivä 5:
// 2.5 HR
//
// Päivä 6:
// 3.0 HR
//
// Päivä 7+:
// 3.5 HR
//
// ============================================================

const DAILY_HASH_RATE_START = 0.5;

const DAILY_HASH_RATE_STEP = 0.5;

const DAILY_HASH_RATE_MAX_DAY = 7;

const MAX_DAILY_HASH_RATE = 3.5;


// ============================================================
// 📺 ADMOB POWER BOOST
// ============================================================
//
// Power Boost ei anna käyttäjälle STL:ää suoraan.
//
// Se lisää aktiivisen mining-jakson Hash Ratea
// määräajaksi.
//
// AD_HASH_RATE_BONUS:
//
// +0.5833 HR
//
// Esimerkiksi:
//
// 3.5 HR + 0.5833 HR
// = 4.0833 HR
//
// ============================================================

const AD_HASH_RATE_BONUS = 0.5833;


// ============================================================
// ⏱️ POWER BOOST DURATION
// ============================================================
//
// Power Boostin enimmäiskesto:
//
// 4 tuntia.
//
// Mining Functions rajoittaa todellisen loppuajan
// aina mining-jakson loppuun.
//
// ============================================================

const AD_BOOST_DURATION_MS =
  4 * 60 * 60 * 1000;


// ============================================================
// 📊 ADMOB DAILY LIMIT
// ============================================================
//
// Kuinka monta Power Boost -mainosta käyttäjä voi
// käyttää yhden UTC-päivän aikana.
//
// ============================================================

const MAX_ADS_PER_DAY = 6;


// ============================================================
// ⏳ ADMOB COOLDOWN
// ============================================================
//
// Kahden Power Boost -mainoksen välinen vähimmäisaika.
//
// 4 tuntia.
//
// Koska Power Boost kestää myös enintään 4 tuntia,
// seuraava boost voidaan normaalisti aloittaa,
// kun edellinen boost on päättynyt.
//
// ============================================================

const AD_COOLDOWN_MS =
  4 * 60 * 60 * 1000;


// ============================================================
// 🔐 ADMOB REWARDED AD UNIT IDS
// ============================================================
//
// Stelluriinilla on kaksi erillistä Rewarded-mainosyksikköä:
//
// ⛏️ Mining Start
// 🐱 Power Boost
//
// Näitä ei saa sekoittaa keskenään.
//
// ============================================================


// ============================================================
// ⛏️ STELLURIINI MINING START
// ============================================================

const ADMOB_MINING_AD_UNIT_ID =
  "ca-app-pub-1131012057145658/6674097787";


// ============================================================
// 🐱 STELLURIINI POWER BOOST
// ============================================================

const ADMOB_POWER_BOOST_AD_UNIT_ID =
  "ca-app-pub-1131012057145658/7225738491";


// ============================================================
// 🔐 ADMOB SSV AD UNIT IDS
// ============================================================
//
// AdMob SSV callbackin `ad_unit` käyttää tässä
// numeerista Ad Unit ID:tä.
//
// Mining Start:
//
// Flutter / Rewarded Ad Unit:
// ca-app-pub-1131012057145658/6674097787
//
// SSV:
// 6674097787
//
// Power Boost:
//
// Flutter / Rewarded Ad Unit:
// ca-app-pub-1131012057145658/7225738491
//
// SSV:
// 7225738491
//
// HUOM:
//
// Nämä arvot ovat tarkoituksella eri muodossa kuin
// Flutterissa käytettävät täydet Ad Unit ID:t.
//
// ============================================================

const ADMOB_MINING_SSV_AD_UNIT_ID =
  "6674097787";

const ADMOB_POWER_BOOST_SSV_AD_UNIT_ID =
  "7225738491";


// ============================================================
// 🎁 ADMOB SSV REWARD METADATA
// ============================================================
//
// Nämä arvot ovat AdMob Rewarded / SSV -metatietoja.
//
// Ne EIVÄT tarkoita STL-tokenien siirtoa käyttäjälle.
//
// Backend käyttää niitä varmistamaan, että SSV-eventti
// kuuluu oikeaan Stelluriini-toimintoon.
//
// ============================================================


// ============================================================
// ⛏️ MINING START REWARD
// ============================================================

const ADMOB_MINING_SSV_REWARD_AMOUNT = 1;

const ADMOB_MINING_SSV_REWARD_ITEM =
  "Mining";


// ============================================================
// 🐱 POWER BOOST REWARD
// ============================================================

const ADMOB_POWER_BOOST_SSV_REWARD_AMOUNT = 1;

const ADMOB_POWER_BOOST_SSV_REWARD_ITEM =
  "Power Boost";


// ============================================================
// ⛏️ MINING CYCLE
// ============================================================
//
// Yksi mining-jakso kestää 24 tuntia.
//
// Mining Start:
//
// 1. päättää vanhan jakson tarvittaessa
// 2. laskee vanhan jakson STL-tuoton
// 3. lisää tuoton miningBalanceen
// 4. luo uuden mining-jakson
// 5. käyttää uuden jakson Daily Hash Ratea
//
// Vanhan jakson Hash Rate ei saa koskaan siirtyä
// uuden jakson Hash Rateksi.
//
// ============================================================

const MINING_DURATION_MS =
  24 * 60 * 60 * 1000;


// ============================================================
// 💰 STL MINING RATE
// ============================================================
//
// STL-tuotto yhtä Hash Rate -yksikköä ja tuntia kohden.
//
// Kaava:
//
// Hash Rate
// × MINING_PER_HASH_PER_HOUR
// × tunnit
//
// Esimerkki:
//
// 3.5 HR × 0.10 × 24 h
// = 8.4 STL
//
// ============================================================

const MINING_PER_HASH_PER_HOUR = 0.10;


// ============================================================
// 📜 TRANSACTION HISTORY
// ============================================================
//
// Käyttäjän history-kokoelman enimmäismäärä.
//
// ============================================================

const MAX_TRANSACTION_HISTORY = 50;


// ============================================================
// 📦 EXPORTS
// ============================================================

module.exports = {

  // ----------------------------------------------------------
  // 🎁 Daily Hash Rate
  // ----------------------------------------------------------

  DAILY_HASH_RATE_START,

  DAILY_HASH_RATE_STEP,

  DAILY_HASH_RATE_MAX_DAY,

  MAX_DAILY_HASH_RATE,


  // ----------------------------------------------------------
  // 📺 AdMob Power Boost
  // ----------------------------------------------------------

  AD_HASH_RATE_BONUS,

  AD_BOOST_DURATION_MS,

  MAX_ADS_PER_DAY,

  AD_COOLDOWN_MS,


  // ----------------------------------------------------------
  // 🔐 AdMob Rewarded Ad Unit IDs
  // ----------------------------------------------------------

  ADMOB_MINING_AD_UNIT_ID,

  ADMOB_POWER_BOOST_AD_UNIT_ID,


  // ----------------------------------------------------------
  // 🔐 AdMob SSV Ad Unit IDs
  // ----------------------------------------------------------

  ADMOB_MINING_SSV_AD_UNIT_ID,

  ADMOB_POWER_BOOST_SSV_AD_UNIT_ID,


  // ----------------------------------------------------------
  // 🎁 AdMob SSV Reward Metadata
  // ----------------------------------------------------------

  ADMOB_MINING_SSV_REWARD_AMOUNT,

  ADMOB_MINING_SSV_REWARD_ITEM,

  ADMOB_POWER_BOOST_SSV_REWARD_AMOUNT,

  ADMOB_POWER_BOOST_SSV_REWARD_ITEM,


  // ----------------------------------------------------------
  // ⛏️ Mining
  // ----------------------------------------------------------

  MINING_DURATION_MS,

  MINING_PER_HASH_PER_HOUR,


  // ----------------------------------------------------------
  // 📜 Transaction History
  // ----------------------------------------------------------

  MAX_TRANSACTION_HISTORY,
};