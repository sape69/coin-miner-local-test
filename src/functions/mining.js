"use strict";

const {
  onCall,
  HttpsError,
} = require("firebase-functions/v2/https");

const {
  db,
  FieldValue,
} = require("../firebase/firebase");

const {
  DEFAULT_HASH_RATE,
  MINING_DURATION_MS,
  MINING_PER_HASH_PER_HOUR,
} = require("../config/miningConfig");

const {
  calculateMining,
  getMiningStartTime,
  getMiningEndTime,
  calculateMiningStatus,
} = require("../utils/miningUtils");

const {
  getUserRef,
  getHistoryCollection,
} = require("../utils/userUtils");


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
    // 🔐 AUTHENTICATION
    // ========================================================

    if (!request.auth) {

      throw new HttpsError(
        "unauthenticated",
        "🐱 Kirjaudu sisään nähdäksesi Stella Miningin."
      );

    }


    // ========================================================
    // 👤 USER
    // ========================================================

    const uid =
      request.auth.uid;


    const userRef =
      getUserRef(uid);


    // ========================================================
    // 👤 GET USER DATA
    // ========================================================

    const snapshot =
      await userRef.get();


    const data =
      snapshot.exists
        ? snapshot.data()
        : {};


    // ========================================================
    // ⏱️ SERVER TIME
    // ========================================================

    const now =
      new Date();


    // ========================================================
    // ⚡ HASH RATE
    // ========================================================

    const hashRate =
      Number(
        data.hashRate ??
        DEFAULT_HASH_RATE
      );


    // ========================================================
    // 💰 SAVED STL BALANCE
    // ========================================================

    const miningBalance =
      Number(
        data.miningBalance ?? 0
      );


    // ========================================================
    // ⛏️ MINING STATUS
    // ========================================================

    const miningStatus =
      calculateMiningStatus(
        data,
        now
      );


    // ========================================================
    // ✨ UNCLAIMED MINING
    // ========================================================

    const unclaimedMining =
      Number(
        miningStatus.minedAmount ?? 0
      );


    // ========================================================
    // 💎 ESTIMATED TOTAL
    // ========================================================

    const estimatedTotal =
      miningBalance +
      unclaimedMining;


    // ========================================================
    // ⛏️ MINING TIMES
    // ========================================================

    const miningStartedAt =
      getMiningStartTime(data);


    const miningEndsAt =
      getMiningEndTime(data);


    // ========================================================
    // 🐱 RESPONSE
    // ========================================================

    return {

      success:
        true,


      // ------------------------------------------------------
      // 🐱 STELLA STATUS
      // ------------------------------------------------------

      miningActive:
        Boolean(
          miningStatus.miningActive
        ),


      // ------------------------------------------------------
      // ⚡ HASH RATE
      // ------------------------------------------------------

      hashRate,


      // ------------------------------------------------------
      // 💰 SAVED STL
      // ------------------------------------------------------

      miningBalance,


      // ------------------------------------------------------
      // ✨ REAL-TIME UNCLAIMED STL
      // ------------------------------------------------------

      unclaimedMining,


      // ------------------------------------------------------
      // 💎 ESTIMATED TOTAL
      // ------------------------------------------------------

      estimatedTotal,


      // ------------------------------------------------------
      // ⏱️ MINING TIME
      // ------------------------------------------------------

      miningRemainingMs:
        Number(
          miningStatus.miningRemainingMs ?? 0
        ),


      elapsedMs:
        Number(
          miningStatus.elapsedMs ?? 0
        ),


      miningDurationMs:
        MINING_DURATION_MS,


      // ------------------------------------------------------
      // 📅 MINING DATES
      // ------------------------------------------------------

      miningStartedAt:
        miningStartedAt
          ? miningStartedAt.toISOString()
          : null,


      miningEndsAt:
        miningEndsAt
          ? miningEndsAt.toISOString()
          : null,


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
    // 🔐 AUTHENTICATION
    // ========================================================

    if (!request.auth) {

      throw new HttpsError(
        "unauthenticated",
        "🐱 Kirjaudu sisään käyttääksesi Stella Miningia."
      );

    }


    // ========================================================
    // 👤 USER
    // ========================================================

    const uid =
      request.auth.uid;


    const userRef =
      getUserRef(uid);


    // ========================================================
    // ⏱️ SERVER TIME
    // ========================================================

    const now =
      new Date();


    // ========================================================
    // 🔥 FIRESTORE TRANSACTION
    // ========================================================

    return await db.runTransaction(
      async (transaction) => {


        // ====================================================
        // 👤 GET USER
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
        // ⚡ HASH RATE
        // ====================================================

        const hashRate =
          Number(
            data.hashRate ??
            DEFAULT_HASH_RATE
          );


        // ====================================================
        // 💰 OLD STL BALANCE
        // ====================================================

        const oldBalance =
          Number(
            data.miningBalance ?? 0
          );


        // ====================================================
        // ⛏️ CURRENT MINING STATUS
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


            completedCycle:
              false,


            miningActive:
              true,


            balance:
              oldBalance,


            hashRate,


            miningRemainingMs:
              Number(
                miningStatus.miningRemainingMs ?? 0
              ),


            message:
              "🐱⛏️ Stella louhii jo STL:ää!",

          };

        }


        // ====================================================
        // 📅 PREVIOUS MINING CYCLE
        // ====================================================

        const previousStart =
          getMiningStartTime(data);


        const previousEnd =
          getMiningEndTime(data);


        // ====================================================
        // 💰 NEW VALUES
        // ====================================================

        let newBalance =
          oldBalance;


        let collected =
          0;


        let completedCycle =
          false;


        // ====================================================
        // ✨ COMPLETE PREVIOUS MINING CYCLE
        // ====================================================
        //
        // Jos aiempi 24h Mining-jakso on valmis,
        // sen ansaitsema STL lisätään pysyvään balanceen.
        //
        // ====================================================

        if (
          previousStart &&
          previousEnd &&
          previousEnd.getTime() <= now.getTime()
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
        // 🐱 START NEW 24H MINING
        // ====================================================

        const miningStartedAt =
          now;


        const miningEndsAt =
          new Date(
            now.getTime() +
            MINING_DURATION_MS
          );


        // ====================================================
        // 💾 UPDATE USER
        // ====================================================

        transaction.set(
          userRef,
          {

            // ⚡ Hash Rate

            hashRate,


            // 💰 STL Balance

            miningBalance:
              newBalance,


            // ⛏️ New Mining Cycle

            miningStartedAt,

            miningEndsAt,


            // ⏱️ Updated

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
            getHistoryCollection(uid)
              .doc();


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


            miningStartedAt,


            miningEndsAt,


            createdAt:
              FieldValue.serverTimestamp(),

          }
        );


        // ====================================================
        // 🐱 SUCCESS RESPONSE
        // ====================================================

        return {

          success:
            true,


          // --------------------------------------------------
          // ⛏️ MINING
          // --------------------------------------------------

          started:
            true,


          miningActive:
            true,


          // --------------------------------------------------
          // ✨ COLLECTED STL
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
          // ⏱️ NEW MINING CYCLE
          // --------------------------------------------------

          miningDurationMs:
            MINING_DURATION_MS,


          miningStartedAt:
            miningStartedAt.toISOString(),


          miningEndsAt:
            miningEndsAt.toISOString(),


          // --------------------------------------------------
          // 🐱 STELLA MESSAGE
          // --------------------------------------------------

          message:
            completedCycle
              ? `🐱✨ Stella keräsi ${collected} STL ja aloitti uuden louhinnan!`
              : "🐱⛏️ Stella Mining käynnistyi!",

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