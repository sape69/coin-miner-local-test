"use strict";


// ============================================================
// 🐱 STELLURIINI STELLA MINING CONFIG
// ============================================================
//
// Kaikki Stella Mining -järjestelmän tärkeät asetukset
// ovat tässä yhdessä tiedostossa.
//
// Tämä tekee backendistä helposti säädettävän.
//
// ============================================================


// ============================================================
// 🐱 DEFAULT HASH RATE
// ============================================================
//
// Uusi pelaaja aloittaa tällä Hash Rate -määrällä.
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
// Testimainoksen katsominen antaa tämän verran
// lisää Hash Ratea.
//

const AD_HASH_RATE_BONUS = 5;


// ============================================================
// 📺 MAX ADS PER DAY
// ============================================================
//
// Kuinka monta Power Boost -mainosta
// käyttäjä voi saada yhden UTC-päivän aikana.
//

const MAX_ADS_PER_DAY = 5;


// ============================================================
// ⏳ AD COOLDOWN
// ============================================================
//
// Mainosten välinen odotusaika.
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
// per 1 Hash Rate
// per tunti.
//
// Esimerkki:
//
// 1 Hash Rate
// = 0.10 STL / tunti
//
// 10 Hash Rate
// = 1.00 STL / tunti
//
// 24 tunnissa:
//
// 1 Hash Rate
// = 2.40 STL
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

  // 🐱 Hash Rate

  DEFAULT_HASH_RATE,


  // 🎁 Daily Bonus

  DAILY_HASH_RATE_BONUS,


  // 📺 Ad Power Boost

  AD_HASH_RATE_BONUS,

  MAX_ADS_PER_DAY,

  AD_COOLDOWN_MS,


  // ⛏️ Mining

  MINING_DURATION_MS,

  MINING_PER_HASH_PER_HOUR,


  // 📜 History

  MAX_TRANSACTION_HISTORY,

};