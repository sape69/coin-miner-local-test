"use strict";

// ============================================================
// 🐱 STELLURIINI - MINING STATUS FUNCTION
// ============================================================
//
// Vastuu:
//
// 📊 Nykyisen Stella Mining -tilan palauttaminen
// ⛏️ Current mining cycle
// ⚡ Power Boost status
// 🎁 Daily Hash Rate
// 💰 Mining balance
// 📈 Current unclaimed mining
//
// IMPORTANT:
//
// Tämä tiedosto sisältää vain getMiningStatus-callable-funktion.
// Varsinaiset laskenta-apufunktiot sijaitsevat utils/-tiedostoissa.
//
// ============================================================

const {
onCall,
HttpsError,
} = require("firebase-functions/v2/https");

const {
getUserRef,
} = require("../utils/userUtils");

const {
getUtcDateString,
} = require("../utils/dateUtils");

const {
DAILY_HASH_RATE_START,
AD_HASH_RATE_BONUS,
MINING_DURATION_MS,
MINING_PER_HASH_PER_HOUR,
} = require("../config/miningConfig");

const {
calculateMiningStatus,
getMiningStartTime,
getMiningEndTime,
} = require("../utils/miningUtils");

const {
getSafeNumber,
getSafeNonNegativeNumber,
calculateDailyHashRate,
getDailyStreak,
getDailyStatus,
getMiningWindow,
isMiningActive,
getMiningHashRate,
getHistoricalMiningHashRate,
calculateCurrentUnclaimedMining,
getAdStatus,
} = require("../utils/miningCycleUtils");

// ============================================================
// 🐱 GET MINING STATUS
// ============================================================

const getMiningStatus =
onCall(
{
region:
"us-central1",
},

async (
  request
) => {
  try {
    // ------------------------------------------------------
    // 🔐 AUTHENTICATION
    // ------------------------------------------------------

    if (
      !request.auth
    ) {
      throw new HttpsError(
        "unauthenticated",
        "🐱 Kirjaudu sisään jatkaaksesi Stella Miningia."
      );
    }

    const uid =
      request.auth.uid;

    // ------------------------------------------------------
    // 👤 USER
    // ------------------------------------------------------

    const userRef =
      getUserRef(
        uid
      );

    const snapshot =
      await userRef.get();

    const data =
      snapshot.exists
        ? snapshot.data() ||
          {}
        : {};

    // ------------------------------------------------------
    // 🕒 CURRENT TIME
    // ------------------------------------------------------

    const now =
      new Date();

    const nowMs =
      now.getTime();

    const today =
      getUtcDateString(
        now
      );

    // ------------------------------------------------------
    // 🎁 DAILY HASH RATE
    // ------------------------------------------------------

    const dailyStatus =
      getDailyStatus(
        data,
        today
      );

    // ------------------------------------------------------
    // ⛏️ MINING WINDOW
    // ------------------------------------------------------

    const miningWindow =
      getMiningWindow(
        data
      );

    // ------------------------------------------------------
    // ⛏️ CURRENT CYCLE HASH RATE
    // ------------------------------------------------------
    //
    // Jos nykyinen mining cycle on olemassa, käytetään
    // AINA kyseisen cyclen omaa Hash Ratea.
    //
    // Vanha cycle ei saa periä uutta Daily Hash Ratea.
    //
    // ------------------------------------------------------

    const miningHashRate =
      miningWindow.valid
        ? getHistoricalMiningHashRate(
            data
          )
        : getMiningHashRate(
            data,
            dailyStatus.dailyHashRate
          );

    // ------------------------------------------------------
    // 💰 MINING BALANCE
    // ------------------------------------------------------

    const miningBalance =
      getSafeNonNegativeNumber(
        data.miningBalance,
        0
      );

    // ------------------------------------------------------
    // 📊 MINING STATUS
    // ------------------------------------------------------

    const miningStatus =
      calculateMiningStatus(
        {
          ...data,

          hashRate:
            miningHashRate,
        },
        now
      );

    // ------------------------------------------------------
    // ⛏️ CURRENT UNCLAIMED MINING
    // ------------------------------------------------------

    const currentMining =
      await calculateCurrentUnclaimedMining(
        uid,
        data,
        nowMs
      );

    // ------------------------------------------------------
    // 📺 AD STATUS
    // ------------------------------------------------------

    const adStatus =
      getAdStatus(
        data,
        nowMs,
        today
      );

    // ------------------------------------------------------
    // ⚡ EFFECTIVE HASH RATE
    // ------------------------------------------------------

    const effectiveHashRate =
      adStatus.adBoostActive
        ? miningHashRate +
          AD_HASH_RATE_BONUS
        : miningHashRate;

    // ------------------------------------------------------
    // 💰 ESTIMATED TOTAL
    // ------------------------------------------------------

    const estimatedTotal =
      Math.max(
        0,
        miningBalance +
          currentMining.unclaimedMining
      );

    // ------------------------------------------------------
    // 📈 MINING RATE
    // ------------------------------------------------------

    const miningPerHour =
      effectiveHashRate *
      MINING_PER_HASH_PER_HOUR;

    const activeMiningPerHour =
      miningHashRate *
      MINING_PER_HASH_PER_HOUR;

    // ------------------------------------------------------
    // 🕒 MINING TIMESTAMPS
    // ------------------------------------------------------

    const miningStartedAt =
      getMiningStartTime(
        data
      );

    const miningEndsAt =
      getMiningEndTime(
        data
      );

    const hasMiningWindow =
      miningStartedAt !==
        null &&
      miningEndsAt !==
        null;

    // ------------------------------------------------------
    // 📦 RESPONSE
    // ------------------------------------------------------

    return {
      success: true,

      message:
        miningStatus.miningActive
          ? "🐱⛏️ Stella louhii STL:ää!"
          : miningStatus.miningFinished
            ? "🐱✨ Louhinta on valmis kerättäväksi!"
            : "🐱 Stella odottaa seuraavaa louhintaa.",

      // ----------------------------------------------------
      // HASH RATE
      // ----------------------------------------------------

      hashRate:
        miningHashRate,

      miningHashRate:
        miningHashRate,

      effectiveHashRate,

      dailyHashRate:
        dailyStatus.dailyHashRate,

      dailyHashRateBonus:
        dailyStatus.dailyHashRate,

      nextDailyHashRate:
        dailyStatus.dailyHashRate,

      // ----------------------------------------------------
      // BALANCE
      // ----------------------------------------------------

      miningBalance,

      unclaimedMining:
        currentMining.unclaimedMining,

      baseMining:
        currentMining.baseMining,

      adBoostMining:
        currentMining.adBoostMining,

      boostMilliseconds:
        currentMining.boostMilliseconds,

      estimatedTotal,

      // ----------------------------------------------------
      // MINING STATUS
      // ----------------------------------------------------

      miningActive:
        miningStatus.miningActive ===
        true,

      miningFinished:
        miningStatus.miningFinished ===
        true,

      miningRemainingMs:
        Math.max(
          0,
          getSafeNumber(
            miningStatus.miningRemainingMs,
            0
          )
        ),

      elapsedMs:
        Math.max(
          0,
          getSafeNumber(
            miningStatus.elapsedMs,
            0
          )
        ),

      miningDurationMs:
        MINING_DURATION_MS,

      // ----------------------------------------------------
      // MINING WINDOW
      // ----------------------------------------------------

      miningStartedAt:
        hasMiningWindow
          ? miningStartedAt.toISOString()
          : null,

      miningEndsAt:
        hasMiningWindow
          ? miningEndsAt.toISOString()
          : null,

      // ----------------------------------------------------
      // MINING RATE
      // ----------------------------------------------------

      miningPerHour,

      miningPerMinute:
        miningPerHour /
        60,

      miningPerSecond:
        miningPerHour /
        3600,

      activeMiningPerHour,

      // ----------------------------------------------------
      // DAILY STREAK
      // ----------------------------------------------------

      dailyClaimed:
        dailyStatus.claimedToday,

      streak:
        dailyStatus.streak,

      dailyStreak:
        dailyStatus.streak,

      nextDailyStreak:
        dailyStatus.streak,

      // ----------------------------------------------------
      // 📺 ADMOB / POWER BOOST
      // ----------------------------------------------------

      adsToday:
        adStatus.adsToday,

      maxAdsPerDay:
        adStatus.maxAdsPerDay,

      adHashRateBonus:
        AD_HASH_RATE_BONUS,

      adBoostDurationMs:
        require("../config/miningConfig")
          .AD_BOOST_DURATION_MS,

      adBoostActive:
        adStatus.adBoostActive,

      adBoostRemainingMs:
        adStatus.adBoostRemainingMs,

      adBoostStartedAt:
        adStatus.adBoostStartedAt
          ? adStatus.adBoostStartedAt.toISOString()
          : null,

      adBoostEndsAt:
        adStatus.adBoostEndsAt
          ? adStatus.adBoostEndsAt.toISOString()
          : null,

      canWatchAd:
        adStatus.canWatchAd,

      cooldownRemainingMs:
        adStatus.cooldownRemainingMs,
    };
  } catch (
    error
  ) {
    // ------------------------------------------------------
    // ❌ ERROR
    // ------------------------------------------------------

    console.error(
      "getMiningStatus error:",
      error
    );

    if (
      error instanceof
      HttpsError
    ) {
      throw error;
    }

    throw new HttpsError(
      "internal",
      "Mining Status -tietojen lataaminen epäonnistui."
    );
  }
}

);

// ============================================================
// 📦 EXPORTS
// ============================================================

module.exports = {
getMiningStatus,
};