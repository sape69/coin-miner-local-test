"use strict";

// ============================================================
// 🐱 STELLA MINING FUNCTIONS
// ============================================================
//
// Vastaa:
//
// ⛏️ Stella Miningin tilasta
// ⏱️ 24 tunnin Mining-jaksosta
// 💰 Reaaliaikaisesta STL-laskennasta
// ✨ Valmiin Mining-jakson keräämisestä
// 🔄 Uuden Mining-jakson käynnistämisestä
//
// ============================================================


// ============================================================
// FIREBASE FUNCTIONS
// ============================================================

const {
  onCall,
  HttpsError,
} = require(
  "firebase-functions/v2/https"
);


// ============================================================
// FIRESTORE
// ============================================================

const {
  FieldValue,
} = require(
  "firebase-admin/firestore"
);


// ============================================================
// FIREBASE
// ============================================================

const {
  db,
  getUserRef,
} = require(
  "../firebase/firebase"
);


// ============================================================
// CONFIG
// ============================================================

const {

  DEFAULT_HASH_RATE,

  MINING_DURATION_MS,

  MINING_PER_HASH_PER_HOUR,

} = require(
  "../config/miningConfig"
);


// ============================================================
// MINING UTILITIES
// ============================================================

const {

  calculateMining,

  getMiningStartTime,

  getMiningEndTime,

  calculateMiningStatus,

} = require(
  "../utils/miningUtils"
);


// ============================================================
// HISTORY
// ============================================================

const {
  createHistoryRef,
} = require(
  "../services/historyService"
);


// ============================================================
// 🐱 GET MINING STATUS
// ============================================================
//
// Flutter kutsuu tätä saadakseen:
//
// ⛏️ Onko Stella louhimassa
// ⏱️ Kuinka paljon aikaa on jäljellä
// 💰 Kuinka paljon STL:ää on syntynyt
// ⚡ Nykyinen Hash Rate
//
// ============================================================

const getMiningStatus =
  onCall(async (request) => {

    // ========================================================
    // AUTHENTICATION
    // ========================================================

    if (!request.auth) {

      throw new HttpsError(
        "unauthenticated",
        "Kirjaudu sisään jatkaaksesi."
      );

    }


    // ========================================================
    // USER
    // ========================================================

    const uid =
      request.auth.uid;

    const userRef =
      getUserRef(uid);


    // ========================================================
    // GET USER DATA
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
    // STL BALANCE
    // ========================================================

    const miningBalance =
      Number(
        data.miningBalance || 0
      );


    // ========================================================
    // MINING STATUS
    // ========================================================

    const miningStatus =
      calculateMiningStatus(
        data,
        now
      );


    // ========================================================
    // CURRENTLY MINED STL
    // ========================================================

    const unclaimedMining =
      miningStatus.minedAmount;


    // ========================================================
    // ESTIMATED TOTAL
    // ========================================================

    const estimatedTotal =
      miningBalance +
      unclaimedMining;


    // ========================================================
    // RESPONSE
    // ========================================================

    return {

      // ------------------------------------------------------
      // 🐱 STELLA STATUS
      // ------------------------------------------------------

      miningActive:
        miningStatus.miningActive,


      // ------------------------------------------------------
      // ⚡ HASH RATE
      // ------------------------------------------------------

      hashRate,


      // ------------------------------------------------------
      // 💰 SAVED STL
      // ------------------------------------------------------

      miningBalance,


      // ------------------------------------------------------
      // ✨ REAL-TIME STL
      // ------------------------------------------------------

      unclaimedMining,


      // ------------------------------------------------------
      // 💎 TOTAL STL
      // ------------------------------------------------------

      estimatedTotal,


      // ------------------------------------------------------
      // ⏱️ MINING TIME
      // ------------------------------------------------------

      miningRemainingMs:
        miningStatus.miningRemainingMs,

      elapsedMs:
        miningStatus.elapsedMs,

      miningDurationMs:
        MINING_DURATION_MS,


      // ------------------------------------------------------
      // ⛏️ MINING SPEED
      // ------------------------------------------------------

      miningPerHour:
        hashRate *
        MINING_PER_HASH_PER_HOUR,


      // ------------------------------------------------------
      // 🐱 STELLA MESSAGE
      // ------------------------------------------------------

      message:
        miningStatus.miningActive
          ? "🐱⛏️ Stella louhii STL:ää!"
          : "🐱✨ Stella odottaa seuraavaa louhintaa.",

    };

  });


// ============================================================
// ⛏️ CLAIM / START STELLA MINING
// ============================================================
//
// Painikkeen toiminta:
//
// 🐱 Ei aktiivista Miningia
// → aloita uusi 24h Mining
//
// ⛏️ Mining aktiivinen
// → ei käynnistetä uutta
//
// ✨ Mining valmis
// → kerää STL Balanceen
// → aloita uusi 24h Mining
//
// ============================================================

const claimMining =
  onCall(async (request) => {

    // ========================================================
    // AUTHENTICATION
    // ========================================================

    if (!request.auth) {

      throw new HttpsError(
        "unauthenticated",
        "Kirjaudu sisään jatkaaksesi."
      );

    }


    // ========================================================
    // USER
    // ========================================================

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
        // OLD STL BALANCE
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

        if (
          miningStatus.miningActive
        ) {

          return {

            success:
              true,

            started:
              false,

            collected:
              0,

            miningActive:
              true,

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


        // ====================================================
        // NEW VALUES
        // ====================================================

        let newBalance =
          oldBalance;

        let collected =
          0;

        let completedCycle =
          false;


        // ====================================================
        // ✨ COMPLETE PREVIOUS 24H CYCLE
        // ====================================================

        if (
          previousStart &&
          previousEnd
        ) {

          const fullDuration =
            Math.max(
              0,
              previousEnd.getTime() -
              previousStart.getTime()
            );


          collected =
            calculateMining(
              hashRate,
              fullDuration
            );


          newBalance =
            oldBalance +
            collected;


          completedCycle =
            true;

        }


        // ====================================================
        // 🐱 START NEW STELLA MINING
        // ====================================================

        const miningStartedAt =
          now;

        const miningEndsAt =
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

            // ------------------------------------------------
            // ⚡ HASH RATE
            // ------------------------------------------------

            hashRate,


            // ------------------------------------------------
            // 💰 STL BALANCE
            // ------------------------------------------------

            miningBalance:
              newBalance,


            // ------------------------------------------------
            // ⛏️ NEW MINING CYCLE
            // ------------------------------------------------

            miningStartedAt,

            miningEndsAt,


            // ------------------------------------------------
            // 🕒 UPDATE
            // ------------------------------------------------

            updatedAt:
              FieldValue.serverTimestamp(),

          },
          {
            merge: true,
          }
        );


        // ====================================================
        // 📜 HISTORY: COMPLETED MINING
        // ====================================================

        if (
          completedCycle &&
          collected > 0
        ) {

          const historyRef =
            createHistoryRef(uid);


          transaction.set(
            historyRef,
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
          createHistoryRef(uid);


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


          // --------------------------------------------------
          // 🐱 MINING
          // --------------------------------------------------

          started:
            true,

          miningActive:
            true,


          // --------------------------------------------------
          // ✨ COLLECTED
          // --------------------------------------------------

          collected,


          completedCycle,


          // --------------------------------------------------
          // 💰 BALANCE
          // --------------------------------------------------

          balance:
            newBalance,


          // --------------------------------------------------
          // ⚡ HASH RATE
          // --------------------------------------------------

          hashRate,


          // --------------------------------------------------
          // ⏱️ NEW CYCLE
          // --------------------------------------------------

          miningDurationMs:
            MINING_DURATION_MS,

          miningStartedAt:
            miningStartedAt.toISOString(),

          miningEndsAt:
            miningEndsAt.toISOString(),


          // --------------------------------------------------
          // 🐱 MESSAGE
          // --------------------------------------------------

          message:
            completedCycle
              ? "🐱✨ Stella keräsi STL:n ja aloitti uuden louhinnan!"
              : "🐱⛏️ Stella Mining käynnistyi!",

        };

      }
    );

  });


// ============================================================
// EXPORTS
// ============================================================

module.exports = {

  getMiningStatus,

  claimMining,

};