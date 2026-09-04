"use strict";


// ============================================================
// 🐱 STELLA MINING FUNCTIONS
// ============================================================
//
// Tämä tiedosto hallitsee:
//
// ⛏️ Stella Mining Status
// ⏱️ 24 tunnin louhintajakson
// ✨ Reaaliaikaisesti kasvavan STL-määrän
// 💰 Valmistuneen louhinnan keräämisen
// 🔄 Uuden louhintajakson käynnistämisen
// 📜 Mining-historian
// 🎁 Daily Bonus -tilan
// 📺 Stella Power Boost -tilan
//
// ============================================================


// ============================================================
// 🔥 FIREBASE FUNCTIONS
// ============================================================

const {
  onCall,
  HttpsError,
} = require(
  "firebase-functions/v2/https"
);


// ============================================================
// 🔥 FIREBASE
// ============================================================

const {
  db,
  FieldValue,
} = require(
  "../firebase/firebase"
);


// ============================================================
// ⚙️ CONFIG
// ============================================================

const {
  DEFAULT_HASH_RATE,
  MINING_DURATION_MS,
  MINING_PER_HASH_PER_HOUR,
  AD_HASH_RATE_BONUS,
  MAX_ADS_PER_DAY,
  AD_COOLDOWN_MS,
} = require(
  "../config/miningConfig"
);


// ============================================================
// 📅 DATE UTILITIES
// ============================================================

const {
  getUtcDateString,
} = require(
  "../utils/dateUtils"
);


// ============================================================
// 👤 USER UTILITIES
// ============================================================

const {
  getUserRef,
  getHistoryCollection,
} = require(
  "../utils/userUtils"
);


// ============================================================
// ⛏️ MINING UTILITIES
// ============================================================

const {
  calculateMiningStatus,
  getMiningStartTime,
  getMiningEndTime,
  calculateMining,
} = require(
  "../utils/miningUtils"
);


// ============================================================
// 🧮 SAFE NUMBER
// ============================================================

function getSafeNumber(
  value,
  fallback = 0
) {

  const number =
    Number(value);

  return Number.isFinite(number)
    ? number
    : fallback;

}


// ============================================================
// 📺 GET AD STATUS
// ============================================================

function getAdStatus(
  data,
  nowMs,
  today
) {

  const storedDate =
    typeof data.lastAdDate === "string"
      ? data.lastAdDate
      : null;


  const adsToday =
    storedDate === today
      ? Math.max(
          0,
          Math.floor(
            getSafeNumber(
              data.adsToday,
              0
            )
          )
        )
      : 0;


  const lastAdRewardAt =
    data.lastAdRewardAt;


  let lastAdRewardMs =
    0;


  if (
    lastAdRewardAt &&
    typeof lastAdRewardAt.toDate ===
      "function"
  ) {

    lastAdRewardMs =
      lastAdRewardAt
        .toDate()
        .getTime();

  } else if (
    lastAdRewardAt instanceof Date
  ) {

    lastAdRewardMs =
      lastAdRewardAt.getTime();

  }


  const cooldownRemainingMs =
    Math.max(
      0,
      (
        lastAdRewardMs +
        AD_COOLDOWN_MS
      ) -
      nowMs
    );


  const canWatchAd =
    adsToday < MAX_ADS_PER_DAY &&
    cooldownRemainingMs === 0;


  return {

    adsToday,

    maxAdsPerDay:
      MAX_ADS_PER_DAY,

    cooldownRemainingMs,

    canWatchAd,

  };

}


// ============================================================
// 🎁 DAILY STATUS
// ============================================================

function getDailyStatus(
  data,
  today
) {

  const lastDailyDate =
    typeof data.lastDailyDate === "string"
      ? data.lastDailyDate
      : "";


  const dailyClaimed =
    lastDailyDate === today;


  const streak =
    Math.max(
      0,
      Math.floor(
        getSafeNumber(
          data.streak,
          0
        )
      )
    );


  const dailyHashRateBonus =
    Math.max(
      0,
      getSafeNumber(
        data.dailyHashRateBonus,
        1
      )
    );


  return {

    dailyClaimed,

    streak,

    dailyHashRateBonus,

  };

}


// ============================================================
// 🐱 GET MINING STATUS
// ============================================================

const getMiningStatus =
  onCall(async (request) => {

    // ========================================================
    // AUTHENTICATION
    // ========================================================

    if (!request.auth) {

      throw new HttpsError(
        "unauthenticated",
        "🐱 Kirjaudu sisään jatkaaksesi Stella Miningia."
      );

    }


    const uid =
      request.auth.uid;


    const userRef =
      getUserRef(uid);


    // ========================================================
    // GET USER
    // ========================================================

    const snapshot =
      await userRef.get();


    const data =
      snapshot.exists
        ? snapshot.data()
        : {};


    // ========================================================
    // SERVER TIME
    // ========================================================

    const now =
      new Date();


    const nowMs =
      now.getTime();


    const today =
      getUtcDateString();


    // ========================================================
    // HASH RATE
    // ========================================================

    const hashRate =
      Math.max(
        0,
        getSafeNumber(
          data.hashRate,
          DEFAULT_HASH_RATE
        )
      );


    // ========================================================
    // STORED STL BALANCE
    // ========================================================

    const miningBalance =
      Math.max(
        0,
        getSafeNumber(
          data.miningBalance,
          0
        )
      );


    // ========================================================
    // CURRENT MINING STATUS
    // ========================================================

    const miningStatus =
      calculateMiningStatus(
        data,
        now
      );


    const unclaimedMining =
      Math.max(
        0,
        getSafeNumber(
          miningStatus.minedAmount,
          0
        )
      );


    const estimatedTotal =
      miningBalance +
      unclaimedMining;


    // ========================================================
    // MINING TIMES
    // ========================================================

    const miningStartedAt =
      getMiningStartTime(data);


    const miningEndsAt =
      getMiningEndTime(data);


    // ========================================================
    // 📺 AD STATUS
    // ========================================================

    const adStatus =
      getAdStatus(
        data,
        nowMs,
        today
      );


    // ========================================================
    // 🎁 DAILY STATUS
    // ========================================================

    const dailyStatus =
      getDailyStatus(
        data,
        today
      );


    // ========================================================
    // RESPONSE
    // ========================================================

    return {

      success:
        true,


      // ======================================================
      // 🐱 MESSAGE
      // ======================================================

      message:
        miningStatus.miningActive
          ? "🐱⛏️ Stella louhii STL:ää!"
          : "🐱 Stella odottaa seuraavaa louhintaa.",


      // ======================================================
      // ⚡ HASH RATE
      // ======================================================

      hashRate,


      // ======================================================
      // 💰 SAVED BALANCE
      // ======================================================

      miningBalance,


      // ======================================================
      // ✨ CURRENTLY MINED
      // ======================================================

      unclaimedMining,


      // ======================================================
      // 💎 TOTAL
      // ======================================================

      estimatedTotal,


      // ======================================================
      // ⛏️ MINING STATUS
      // ======================================================

      miningActive:
        miningStatus.miningActive === true,


      miningFinished:
        miningStatus.miningFinished === true,


      // ======================================================
      // ⏱️ MINING TIME
      // ======================================================

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


      // ======================================================
      // 🕒 START / END
      // ======================================================

      miningStartedAt:
        miningStartedAt
          ? miningStartedAt.toISOString()
          : null,


      miningEndsAt:
        miningEndsAt
          ? miningEndsAt.toISOString()
          : null,


      // ======================================================
      // ⚡ STL SPEED
      // ======================================================

      miningPerHour:
        hashRate *
        MINING_PER_HASH_PER_HOUR,


      miningPerMinute:
        (
          hashRate *
          MINING_PER_HASH_PER_HOUR
        ) / 60,


      miningPerSecond:
        (
          hashRate *
          MINING_PER_HASH_PER_HOUR
        ) / 3600,


      // ======================================================
      // 🎁 DAILY BONUS
      // ======================================================

      dailyClaimed:
        dailyStatus.dailyClaimed,


      streak:
        dailyStatus.streak,


      dailyHashRateBonus:
        dailyStatus.dailyHashRateBonus,


      // ======================================================
      // 📺 STELLA POWER BOOST
      // ======================================================

      adsToday:
        adStatus.adsToday,


      maxAdsPerDay:
        adStatus.maxAdsPerDay,


      adHashRateBonus:
        AD_HASH_RATE_BONUS,


      canWatchAd:
        adStatus.canWatchAd,


      cooldownRemainingMs:
        adStatus.cooldownRemainingMs,

    };

  });


// ============================================================
// ⛏️ CLAIM / START STELLA MINING
// ============================================================

const claimMining =
  onCall(async (request) => {

    // ========================================================
    // AUTHENTICATION
    // ========================================================

    if (!request.auth) {

      throw new HttpsError(
        "unauthenticated",
        "🐱 Kirjaudu sisään aloittaaksesi Stella Miningin."
      );

    }


    const uid =
      request.auth.uid;


    const userRef =
      getUserRef(uid);


    // ========================================================
    // SERVER TIME
    // ========================================================

    const now =
      new Date();


    // ========================================================
    // FIRESTORE TRANSACTION
    // ========================================================

    return await db.runTransaction(
      async (transaction) => {

        // ====================================================
        // GET USER
        // ====================================================

        const snapshot =
          await transaction.get(
            userRef
          );


        const data =
          snapshot.exists
            ? snapshot.data()
            : {};


        // ====================================================
        // HASH RATE
        // ====================================================

        const hashRate =
          Math.max(
            0,
            getSafeNumber(
              data.hashRate,
              DEFAULT_HASH_RATE
            )
          );


        // ====================================================
        // CURRENT BALANCE
        // ====================================================

        const oldBalance =
          Math.max(
            0,
            getSafeNumber(
              data.miningBalance,
              0
            )
          );


        // ====================================================
        // CURRENT MINING STATUS
        // ====================================================

        const miningStatus =
          calculateMiningStatus(
            data,
            now
          );


        // ====================================================
        // 🐱 STELLA IS ALREADY MINING
        // ====================================================

        if (miningStatus.miningActive) {

          return {

            success:
              true,

            started:
              false,

            collected:
              0,

            miningActive:
              true,

            hashRate,

            unclaimedMining:
              miningStatus.minedAmount,

            miningRemainingMs:
              miningStatus.miningRemainingMs,

            message:
              "🐱⛏️ Stella louhii jo STL:ää!",

          };

        }


        // ====================================================
        // PREVIOUS MINING CYCLE
        // ====================================================

        const previousStart =
          getMiningStartTime(data);


        const previousEnd =
          getMiningEndTime(data);


        let newBalance =
          oldBalance;


        let collected =
          0;


        let completedPreviousCycle =
          false;


        // ====================================================
        // 💰 COLLECT FINISHED MINING
        // ====================================================

        if (
          previousStart &&
          previousEnd
        ) {

          const previousDuration =
            Math.max(
              0,
              previousEnd.getTime() -
                previousStart.getTime()
            );


          collected =
            calculateMining(
              hashRate,
              previousDuration
            );


          newBalance =
            oldBalance +
            collected;


          completedPreviousCycle =
            collected > 0;

        }


        // ====================================================
        // 🐱 START NEW 24H MINING
        // ====================================================

        const newMiningStartedAt =
          now;


        const newMiningEndsAt =
          new Date(
            now.getTime() +
            MINING_DURATION_MS
          );


        // ====================================================
        // UPDATE USER
        // ====================================================

        transaction.set(
          userRef,
          {

            // ⚡ HASH RATE

            hashRate,


            // 💰 STL BALANCE

            miningBalance:
              newBalance,


            // ⛏️ MINING CYCLE

            miningStartedAt:
              newMiningStartedAt,


            miningEndsAt:
              newMiningEndsAt,


            // 🕒 METADATA

            updatedAt:
              FieldValue.serverTimestamp(),

          },
          {
            merge:
              true,
          }
        );


        // ====================================================
        // 📜 HISTORY: COMPLETED MINING
        // ====================================================

        if (completedPreviousCycle) {

          const completeHistoryRef =
            getHistoryCollection(uid)
              .doc();


          transaction.set(
            completeHistoryRef,
            {

              type:
                "mining_complete",

              title:
                "Stella Mining Complete 🐱⛏️✨",

              amount:
                collected,

              balanceAfter:
                newBalance,

              hashRate,

              createdAt:
                FieldValue.serverTimestamp(),

            }
          );

        }


        // ====================================================
        // 📜 HISTORY: NEW MINING STARTED
        // ====================================================

        const startHistoryRef =
          getHistoryCollection(uid)
            .doc();


        transaction.set(
          startHistoryRef,
          {

            type:
              "mining_started",

            title:
              "Stella Mining Started 🐱⛏️",

            amount:
              0,

            hashRate,

            miningDurationMs:
              MINING_DURATION_MS,

            createdAt:
              FieldValue.serverTimestamp(),

          }
        );


        // ====================================================
        // RESPONSE
        // ====================================================

        return {

          success:
            true,


          started:
            true,


          miningActive:
            true,


          collected,


          completedPreviousCycle,


          miningBalance:
            newBalance,


          hashRate,


          miningDurationMs:
            MINING_DURATION_MS,


          miningStartedAt:
            newMiningStartedAt
              .toISOString(),


          miningEndsAt:
            newMiningEndsAt
              .toISOString(),


          message:
            completedPreviousCycle
              ? "🐱✨ Stella keräsi STL:t ja aloitti uuden louhinnan!"
              : "🐱⛏️ Stella aloitti 24 tunnin STL-louhinnan!",

        };

      }
    );

  });


// ============================================================
// 📦 EXPORTS
// ============================================================

module.exports = {

  getMiningStatus,

  claimMining,

};