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
  getUserRef,
  getHistoryCollection,
} = require("../utils/userUtils");

const {
  calculateMiningStatus,
  getMiningStartTime,
  getMiningEndTime,
  calculateMining,
} = require("../utils/miningUtils");


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
// Stella louhii aina yhden 24h jakson kerrallaan.
//
// ============================================================


// ============================================================
// 🐱 GET MINING STATUS
// ============================================================
//
// Flutter kutsuu tätä funktiota:
//
// getMiningStatus()
//
// Funktio palauttaa nykyisen Stella Mining -tilanteen.
//
// Reaaliaikainen STL voidaan näyttää Flutterissa
// laskemalla unclaimedMining + ajan kuluminen.
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


    // ========================================================
    // CURRENTLY MINED STL
    // ========================================================

    const unclaimedMining =
      miningStatus.minedAmount;


    // ========================================================
    // TOTAL DISPLAY BALANCE
    // ========================================================

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

      // ------------------------------------------------------
      // 🐱 STELLA
      // ------------------------------------------------------

      success: true,

      message:
        miningStatus.miningActive
          ? "🐱⛏️ Stella louhii STL:ää!"
          : "🐱 Stella odottaa seuraavaa louhintaa.",


      // ------------------------------------------------------
      // ⚡ HASH RATE
      // ------------------------------------------------------

      hashRate,


      // ------------------------------------------------------
      // 💰 SAVED BALANCE
      // ------------------------------------------------------

      miningBalance,


      // ------------------------------------------------------
      // ✨ CURRENTLY MINED
      // ------------------------------------------------------

      unclaimedMining,


      // ------------------------------------------------------
      // 💎 TOTAL
      // ------------------------------------------------------

      estimatedTotal,


      // ------------------------------------------------------
      // ⛏️ MINING STATUS
      // ------------------------------------------------------

      miningActive:
        miningStatus.miningActive,


      // ------------------------------------------------------
      // ⏱️ TIME
      // ------------------------------------------------------

      miningRemainingMs:
        miningStatus.miningRemainingMs,

      elapsedMs:
        miningStatus.elapsedMs,

      miningDurationMs:
        MINING_DURATION_MS,


      // ------------------------------------------------------
      // 🕒 START / END
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
      // ⚡ STL SPEED
      // ------------------------------------------------------

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
//
// Painikkeen toiminta:
//
// 🐱 Ei louhintaa
// → käynnistä uusi 24h Stella Mining
//
// 🐱 Louhinta käynnissä
// → palauttaa nykyisen tilanteen
//
// 🐱 Louhinta valmis
// → lisää STL:n Balanceen
// → käynnistää uuden 24h louhinnan
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

            success: true,

            started: false,

            collected: 0,

            miningActive: true,

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


          // ==================================================
          // Calculate the exact STL amount from the completed
          // 24 hour mining cycle.
          // ==================================================

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

            // ⚡ Hash Rate

            hashRate,


            // 💰 STL Balance

            miningBalance:
              newBalance,


            // ⛏️ Mining cycle

            miningStartedAt:
              newMiningStartedAt,

            miningEndsAt:
              newMiningEndsAt,


            // 🕒 Metadata

            updatedAt:
              FieldValue.serverTimestamp(),

          },
          {
            merge: true,
          }
        );


        // ====================================================
        // 📜 HISTORY:
        // COMPLETED MINING
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
        // 📜 HISTORY:
        // NEW MINING STARTED
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

          success: true,


          // --------------------------------------------------
          // ⛏️ STATUS
          // --------------------------------------------------

          started: true,

          miningActive: true,


          // --------------------------------------------------
          // 💰 COLLECTED STL
          // --------------------------------------------------

          collected,


          completedPreviousCycle,


          // --------------------------------------------------
          // 💎 BALANCE
          // --------------------------------------------------

          miningBalance:
            newBalance,


          // --------------------------------------------------
          // ⚡ HASH RATE
          // --------------------------------------------------

          hashRate,


          // --------------------------------------------------
          // ⏱️ MINING
          // --------------------------------------------------

          miningDurationMs:
            MINING_DURATION_MS,

          miningStartedAt:
            newMiningStartedAt
              .toISOString(),

          miningEndsAt:
            newMiningEndsAt
              .toISOString(),


          // --------------------------------------------------
          // 🐱 MESSAGE
          // --------------------------------------------------

          message:
            completedPreviousCycle
              ? "🐱✨ Stella keräsi STL:t ja aloitti uuden louhinnan!"
              : "🐱⛏️ Stella aloitti 24 tunnin STL-louhinnan!",

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