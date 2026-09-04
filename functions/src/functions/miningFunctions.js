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
} = require(
  "../config/miningConfig"
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


    // ========================================================
    // HASH RATE
    // ========================================================

    const hashRate =
      Number(
        data.hashRate ||
        DEFAULT_HASH_RATE
      );


    // ========================================================
    // STORED STL BALANCE
    // ========================================================

    const miningBalance =
      Number(
        data.miningBalance || 0
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
      miningStatus.minedAmount;


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
    // RESPONSE
    // ========================================================

    return {

      success:
        true,


      message:
        miningStatus.miningActive
          ? "🐱⛏️ Stella louhii STL:ää!"
          : "🐱 Stella odottaa seuraavaa louhintaa.",


      // ⚡ HASH RATE

      hashRate,


      // 💰 SAVED BALANCE

      miningBalance,


      // ✨ CURRENTLY MINED

      unclaimedMining,


      // 💎 TOTAL

      estimatedTotal,


      // ⛏️ MINING STATUS

      miningActive:
        miningStatus.miningActive,


      miningFinished:
        miningStatus.miningFinished,


      // ⏱️ TIME

      miningRemainingMs:
        miningStatus.miningRemainingMs,


      elapsedMs:
        miningStatus.elapsedMs,


      miningDurationMs:
        MINING_DURATION_MS,


      // 🕒 START / END

      miningStartedAt:
        miningStartedAt
          ? miningStartedAt.toISOString()
          : null,


      miningEndsAt:
        miningEndsAt
          ? miningEndsAt.toISOString()
          : null,


      // ⚡ STL SPEED

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
          Number(
            data.hashRate ||
            DEFAULT_HASH_RATE
          );


        // ====================================================
        // CURRENT BALANCE
        // ====================================================

        const oldBalance =
          Number(
            data.miningBalance || 0
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