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
  AD_HASH_RATE_BONUS,
  MAX_ADS_PER_DAY,
  AD_COOLDOWN_MS,
  MINING_DURATION_MS,
} = require("../config/miningConfig");

const {
  getUtcDateString,
} = require("../utils/dateUtils");

const {
  getUserRef,
  getHistoryCollection,
} = require("../utils/userUtils");

const {
  calculateMiningStatus,
  getMiningStartTime,
  getMiningEndTime,
} = require("../utils/miningUtils");


// ============================================================
// 📺 STELLA AD FUNCTIONS
// ============================================================
//
// Testivaiheen mainosjärjestelmä.
//
// 📺 Mainoksen katsominen:
// +5 Hash Rate
//
// 🐱 Jos Stella ei louhi:
// Mainospalkinto käynnistää 24h Miningin.
//
// ============================================================


// ============================================================
// 📺 TEST AD REWARD
// ============================================================

const testAdReward =
  onCall(async (request) => {

    // ========================================================
    // AUTHENTICATION
    // ========================================================

    if (!request.auth) {
      throw new HttpsError(
        "unauthenticated",
        "🐱 Kirjaudu sisään saadaksesi Stella Power Boostin."
      );
    }


    const uid =
      request.auth.uid;

    const userRef =
      getUserRef(uid);

    const now =
      new Date();

    const today =
      getUtcDateString();


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
        // ADS TODAY
        // ====================================================

        let adsToday =
          Number(
            data.adsToday || 0
          );

        const adDate =
          String(
            data.adDate || ""
          );


        // ====================================================
        // NEW UTC DAY
        // ====================================================

        if (adDate !== today) {
          adsToday = 0;
        }


        // ====================================================
        // DAILY LIMIT
        // ====================================================

        if (
          adsToday >=
          MAX_ADS_PER_DAY
        ) {
          throw new HttpsError(
            "resource-exhausted",
            "🐱📺 Päivän Stella-mainosraja on saavutettu."
          );
        }


        // ====================================================
        // COOLDOWN
        // ====================================================

        const lastAdTimestamp =
          data.lastAdTimestamp;

        if (
          lastAdTimestamp &&
          typeof lastAdTimestamp.toDate ===
            "function"
        ) {

          const lastAdTime =
            lastAdTimestamp.toDate();

          const elapsed =
            now.getTime() -
            lastAdTime.getTime();


          if (
            elapsed <
            AD_COOLDOWN_MS
          ) {

            const remainingMinutes =
              Math.ceil(
                (
                  AD_COOLDOWN_MS -
                  elapsed
                ) / 60000
              );


            throw new HttpsError(
              "failed-precondition",
              `🐱 Stella lepää vielä ${remainingMinutes} minuuttia ennen seuraavaa Power Boostia.`
            );
          }
        }


        // ====================================================
        // CURRENT HASH RATE
        // ====================================================

        const oldHashRate =
          Number(
            data.hashRate ||
            DEFAULT_HASH_RATE
          );


        // ====================================================
        // NEW HASH RATE
        // ====================================================

        const newHashRate =
          oldHashRate +
          AD_HASH_RATE_BONUS;


        // ====================================================
        // NEW AD COUNT
        // ====================================================

        const newAdsToday =
          adsToday + 1;


        // ====================================================
        // MINING STATUS
        // ====================================================

        const miningStatus =
          calculateMiningStatus(
            data,
            now
          );


        let miningStartedAt =
          getMiningStartTime(data);

        let miningEndsAt =
          getMiningEndTime(data);

        let miningRestarted =
          false;


        // ====================================================
        // 🐱 START MINING
        // ====================================================
        //
        // Jos Stella ei tällä hetkellä louhi,
        // mainospalkinto käynnistää uuden 24h jakson.
        //
        // ====================================================

        if (!miningStatus.miningActive) {

          miningStartedAt =
            now;

          miningEndsAt =
            new Date(
              now.getTime() +
              MINING_DURATION_MS
            );

          miningRestarted =
            true;
        }


        // ====================================================
        // UPDATE USER
        // ====================================================

        transaction.set(
          userRef,
          {

            // ⚡ HASH RATE

            hashRate:
              newHashRate,


            // 📺 ADS

            adsToday:
              newAdsToday,

            adDate:
              today,

            lastAdTimestamp:
              FieldValue.serverTimestamp(),


            // ⛏️ MINING

            miningStartedAt,

            miningEndsAt,


            // 🕒 UPDATE TIME

            updatedAt:
              FieldValue.serverTimestamp(),

          },
          {
            merge: true,
          }
        );


        // ====================================================
        // HISTORY
        // ====================================================

        const historyRef =
          getHistoryCollection(uid)
            .doc();


        transaction.set(
          historyRef,
          {

            type:
              "ad_hashrate",

            title:
              "Stella Power Boost 📺🐱⚡",

            amount:
              AD_HASH_RATE_BONUS,

            hashRateAfter:
              newHashRate,

            adsToday:
              newAdsToday,

            miningRestarted,

            createdAt:
              FieldValue.serverTimestamp(),

          }
        );


        // ====================================================
        // RESPONSE
        // ====================================================

        return {

          success: true,

          bonus:
            AD_HASH_RATE_BONUS,

          hashRate:
            newHashRate,

          adsToday:
            newAdsToday,

          maxAdsPerDay:
            MAX_ADS_PER_DAY,

          miningRestarted,

          message:
            miningRestarted
              ? "🐱📺⚡ Stella sai Power Boostin ja aloitti 24h louhinnan!"
              : "🐱📺⚡ Stella sai +5 Hash Rate Power Boostin!",

        };
      }
    );
  });


// ============================================================
// EXPORTS
// ============================================================

module.exports = {

  testAdReward,

};