"use strict";

// ==========================================
// 🐱 STELLURIINI MINING CONFIGURATION
// ==========================================
//
// Keskitetty Stelluriini Mining -asetustiedosto.
//
// TÄRKEÄÄ:
//
// - Daily Hash Rate ei ole STL-palkkio.
// - AdMob Rewarded Ad ei anna suoraan STL-tokenia.
// - AdMob SSV ainoastaan vahvistaa mainoksen.
// - Power Boost kasvattaa louhintatehoa määräajaksi.
// - Power Boost ei voi jatkua mining-jakson yli.
// - Power Boost ei siirry seuraavaan mining-jaksoon.
// - Varsinainen STL-tuotto lasketaan mining-logiikassa.
//
// ==========================================


// ==========================================
// 🎁 DAILY HASH RATE
// ==========================================
//
// Päivän Hash Rate määräytyy Daily Streakin
// perusteella.
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
// ==========================================


// Ensimmäisen päivän Hash Rate.
const DAILY_HASH_RATE_START = 0.5;


// Kuinka paljon Hash Rate kasvaa
// jokaisena seuraavana streak-päivänä.
const DAILY_HASH_RATE_STEP = 0.5;


// Kuinka pitkälle Daily Hash Rate
// kasvaa ennen kuin maksimi saavutetaan.
const DAILY_HASH_RATE_MAX_DAY = 7;


// Daily Hash Raten absoluuttinen maksimi.
const MAX_DAILY_HASH_RATE = 3.5;


// ==========================================
// 📺 ADMOB POWER BOOST
// ==========================================
//
// Power Boost ei anna käyttäjälle STL:ää
// suoraan.
//
// Se lisää käyttäjän Hash Ratea
// määräajaksi aktiivisen mining-jakson aikana.
//
// ==========================================


// Power Boostin antama lisä-Hash Rate.
const AD_HASH_RATE_BONUS = 0.5833;


// Power Boostin enimmäiskesto.
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
// 4 tuntia.
const AD_COOLDOWN_MS =
  4 * 60 * 60 * 1000;


// ==========================================
// 🔐 ADMOB REWARDED AD UNITS
// ==========================================
//
// Stelluriinilla on kaksi erillistä
// AdMob Rewarded -mainosyksikköä:
//
// ⛏️ Mining
// 🐱 Power Boost
//
// Näitä EI saa sekoittaa keskenään.
//
// ==========================================


// ⛏️ Stelluriini Mining
//
// AdMob-mainosyksikkö:
//
// ca-app-pub-1131012057145658/6674097787
//
const ADMOB_MINING_AD_UNIT_ID =
  "ca-app-pub-1131012057145658/6674097787";


// 🐱 Stelluriini Power Boost
//
// AdMob-mainosyksikkö:
//
// ca-app-pub-1131012057145658/7225738491
//
const ADMOB_POWER_BOOST_AD_UNIT_ID =
  "ca-app-pub-1131012057145658/7225738491";


// ==========================================
// 🔐 ADMOB SSV AD UNIT IDS
// ==========================================
//
// AdMob SSV:n callbackissa käytettävä
// `ad_unit` on numeerinen Ad Unit ID.
//
// ⛏️ Mining:
// 6674097787
//
// 🐱 Power Boost:
// 7225738491
//
// ==========================================


const ADMOB_MINING_SSV_AD_UNIT_ID =
  "6674097787";


const ADMOB_POWER_BOOST_SSV_AD_UNIT_ID =
  "7225738491";


// ==========================================
// 🎁 ADMOB SSV REWARD METADATA
// ==========================================
//
// AdMob reward metadata ei tarkoita,
// että käyttäjälle siirretään STL-tokenia.
//
// SSV vahvistaa ainoastaan sen,
// että AdMob on hyväksynyt rewarded-mainoksen.
//
// ==========================================


// ⛏️ Mining-mainoksen reward amount.
const ADMOB_MINING_SSV_REWARD_AMOUNT = 1;


// ⛏️ Mining-mainoksen reward item.
const ADMOB_MINING_SSV_REWARD_ITEM =
  "Mining";


// 🐱 Power Boost -mainoksen reward amount.
const ADMOB_POWER_BOOST_SSV_REWARD_AMOUNT = 1;


// 🐱 Power Boost -mainoksen reward item.
const ADMOB_POWER_BOOST_SSV_REWARD_ITEM =
  "Power Boost";


// ==========================================
// ⛏️ MINING
// ==========================================
//
// Yksi mining-jakso kestää 24 tuntia.
//
// Mining Start käynnistää uuden jakson.
//
// Kun jakso päättyy:
//
// 1. Base mining lasketaan
// 2. Power Boost -ajat lasketaan
// 3. STL lisätään miningBalanceen
// 4. Seuraava mining voidaan aloittaa
//
// ==========================================


// Yhden mining-jakson pituus.
//
// 24 tuntia.
const MINING_DURATION_MS =
  24 * 60 * 60 * 1000;


// ==========================================
// 💰 STL MINING RATE
// ==========================================
//
// STL-tuotto yhtä Hash Rate -yksikköä
// ja yhtä tuntia kohden.
//
// Kaava:
//
// Hash Rate
// × MINING_PER_HASH_PER_HOUR
// × tunnit
//
// Esimerkiksi:
//
// 3.5 HR × 0.10 × 24 h
// = 8.4 STL
//
// ==========================================

const MINING_PER_HASH_PER_HOUR = 0.10;


// ==========================================
// 📜 TRANSACTION HISTORY
// ==========================================
//
// Käyttäjän transaction/history-logiikan
// käyttämä enimmäismäärä.
//
// ==========================================

const MAX_TRANSACTION_HISTORY = 50;


// ==========================================
// 📦 EXPORTS
// ==========================================

module.exports = {

  // ----------------------------------------
  // 🎁 Daily Hash Rate
  // ----------------------------------------

  DAILY_HASH_RATE_START,

  DAILY_HASH_RATE_STEP,

  DAILY_HASH_RATE_MAX_DAY,

  MAX_DAILY_HASH_RATE,


  // ----------------------------------------
  // 📺 AdMob Power Boost
  // ----------------------------------------

  AD_HASH_RATE_BONUS,

  AD_BOOST_DURATION_MS,

  MAX_ADS_PER_DAY,

  AD_COOLDOWN_MS,


  // ----------------------------------------
  // 🔐 AdMob Rewarded Ad Units
  // ----------------------------------------

  ADMOB_MINING_AD_UNIT_ID,

  ADMOB_POWER_BOOST_AD_UNIT_ID,


  // ----------------------------------------
  // 🔐 AdMob SSV Ad Unit IDs
  // ----------------------------------------

  ADMOB_MINING_SSV_AD_UNIT_ID,

  ADMOB_POWER_BOOST_SSV_AD_UNIT_ID,


  // ----------------------------------------
  // 🎁 AdMob SSV Reward Metadata
  // ----------------------------------------

  ADMOB_MINING_SSV_REWARD_AMOUNT,

  ADMOB_MINING_SSV_REWARD_ITEM,

  ADMOB_POWER_BOOST_SSV_REWARD_AMOUNT,

  ADMOB_POWER_BOOST_SSV_REWARD_ITEM,


  // ----------------------------------------
  // ⛏️ Mining
  // ----------------------------------------

  MINING_DURATION_MS,

  MINING_PER_HASH_PER_HOUR,


  // ----------------------------------------
  // 📜 History
  // ----------------------------------------

  MAX_TRANSACTION_HISTORY,
};