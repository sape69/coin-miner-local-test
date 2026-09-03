"use strict";

const {
  onCall,
  onRequest,
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
  getAdMobRewardRef,
} = require("../utils/userUtils");

const {
  calculateMiningStatus,
  getMiningStartTime,
  getMiningEndTime,
} = require("../utils/miningUtils");

const {
  verifyAdMobCallback,
} = require("../utils/admobVerifier");


// ============================================================
// 🐱 STELLA AD FUNCTIONS
// ============================================================
//
// 📺 Stella Power Boost
//
// Mainoksen katsominen:
//
// ⚡ + Hash Rate
// 🐱 Stella saa lisää Mining Poweria
// ⛏️ Voi käynnistää uuden 24h Mining-jakson
//
// ============================================================


// ============================================================
// 🧪 TEST AD REWARD
// ============================================================
//
// Käytetään kehityksen aikana.
//
// Flutter näyttää Google AdMob testimainoksen.
// Kun mainos on katsottu onnistuneesti,
// Flutter kutsuu tätä Firebase Functionia.
//
// ============================================================

const testAdReward =
  onCall(async (request) => {

    // ========================================================
    // 🔐 AUTHENTICATION
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
        // 📺 ADS TODAY
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
        // 📅 NEW DAY RESET
        // ====================================================

        if (adDate !== today) {
          adsToday = 0;
        }


        // ====================================================
        // 🚫 DAILY LIMIT
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
        // ⏳ COOLDOWN
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
              `🐱⏳ Stella lepää vielä ${remainingMinutes} minuuttia ennen seuraavaa Power Boostia.`
            );
          }
        }


        // ====================================================
        // ⚡ CURRENT HASH RATE
        // ====================================================

        const oldHashRate =
          Number(
            data.hashRate ||
            DEFAULT_HASH_RATE
          );


        // ====================================================
        // 🐱 STELLA POWER BOOST
        // ====================================================

        const bonus =
          AD_HASH_RATE_BONUS;


        const newHashRate =
          oldHashRate +
          bonus;


        // ====================================================
        // 📺 NEW AD COUNT
        // ====================================================

        const newAdsToday =
          adsToday + 1;


        // ====================================================
        // ⛏️ CURRENT MINING STATUS
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
        // 🐱 START MINING IF NOT ACTIVE
        // ====================================================
        //
        // Jos Stella ei louhi tällä hetkellä,
        // mainos käynnistää uuden 24h louhinnan.
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
        // 💾 UPDATE USER
        // ====================================================

        transaction.set(
          userRef,
          {

            // ⚡ New Hash Rate
            hashRate:
              newHashRate,


            // 📺 Ads today
            adsToday:
              newAdsToday,


            // 📅 Ad date
            adDate:
              today,


            // ⏱️ Last ad timestamp
            lastAdTimestamp:
              FieldValue.serverTimestamp(),


            // ⛏️ Mining cycle
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
        // 📜 STELLA HISTORY
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
              bonus,


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
        // 🐱 SUCCESS RESPONSE
        // ====================================================

        return {

          success: true,


          bonus,


          hashRate:
            newHashRate,


          adsToday:
            newAdsToday,


          maxAdsPerDay:
            MAX_ADS_PER_DAY,


          miningRestarted,


          message:
            miningRestarted
              ? `🐱📺⚡ Stella sai +${bonus} Hash Rate ja aloitti 24 tunnin louhinnan!`
              : `🐱📺⚡ Stella sai +${bonus} Hash Rate! Louhinta jatkuu entistä nopeampana.`,

        };
      }
    );
  });


// ============================================================
// 📺 ADMOB SERVER-SIDE REWARD
// ============================================================
//
// Google AdMob kutsuu tätä endpointia,
// kun käyttäjä on ansainnut palkinnon.
//
// 🔐 Google signature tarkistetaan
// 🛡️ Duplicate transaction estetään
// ⚡ Stella saa Power Boostin
//
// ============================================================

const adMobReward =
  onRequest(
    {
      region: "us-central1",
    },

    async (req, res) => {

      try {

        // ====================================================
        // 🌐 ONLY GET
        // ====================================================

        if (
          req.method !== "GET"
        ) {
          res
            .status(405)
            .send("Method Not Allowed");

          return;
        }


        // ====================================================
        // 🔐 VERIFY ADMOB SIGNATURE
        // ====================================================

        await verifyAdMobCallback(
          req
        );


        // ====================================================
        // 📥 PARAMETERS
        // ====================================================

        const uid =
          String(
            req.query.user_id || ""
          );


        const transactionId =
          String(
            req.query.transaction_id || ""
          );


        // ====================================================
        // 🚫 VALIDATE USER
        // ====================================================

        if (!uid) {
          res
            .status(400)
            .send("Missing user_id");

          return;
        }


        // ====================================================
        // 🚫 VALIDATE TRANSACTION
        // ====================================================

        if (!transactionId) {
          res
            .status(400)
            .send("Missing transaction_id");

          return;
        }


        // ====================================================
        // 📁 FIRESTORE REFERENCES
        // ====================================================

        const userRef =
          getUserRef(uid);


        const rewardRef =
          getAdMobRewardRef(
            transactionId
          );


        const now =
          new Date();


        const today =
          getUtcDateString();


        // ====================================================
        // 🔥 FIRESTORE TRANSACTION
        // ====================================================

        const result =
          await db.runTransaction(
            async (transaction) => {

              // ==============================================
              // 🛡️ DUPLICATE CHECK
              // ==============================================

              const rewardSnapshot =
                await transaction.get(
                  rewardRef
                );


              if (rewardSnapshot.exists) {

                return {
                  duplicate: true,
                };
              }


              // ==============================================
              // 👤 GET USER
              // ==============================================

              const userSnapshot =
                await transaction.get(
                  userRef
                );


              const data =
                userSnapshot.exists
                  ? userSnapshot.data()
                  : {};


              // ==============================================
              // 📺 ADS TODAY
              // ==============================================

              let adsToday =
                Number(
                  data.adsToday || 0
                );


              const adDate =
                String(
                  data.adDate || ""
                );


              if (adDate !== today) {
                adsToday = 0;
              }


              // ==============================================
              // 🚫 DAILY LIMIT
              // ==============================================

              if (
                adsToday >=
                MAX_ADS_PER_DAY
              ) {

                return {
                  rejected: true,
                  reason:
                    "daily_limit",
                };
              }


              // ==============================================
              // ⏳ COOLDOWN
              // ==============================================

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

                  return {
                    rejected: true,
                    reason:
                      "cooldown",
                  };
                }
              }


              // ==============================================
              // ⚡ CURRENT HASH RATE
              // ==============================================

              const oldHashRate =
                Number(
                  data.hashRate ||
                  DEFAULT_HASH_RATE
                );


              // ==============================================
              // 🐱 STELLA POWER BOOST
              // ==============================================

              const bonus =
                AD_HASH_RATE_BONUS;


              const newHashRate =
                oldHashRate +
                bonus;


              // ==============================================
              // 📺 NEW AD COUNT
              // ==============================================

              const newAdsToday =
                adsToday + 1;


              // ==============================================
              // ⛏️ MINING STATUS
              // ==============================================

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


              // ==============================================
              // 🐱 START 24H MINING
              // ==============================================

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


              // ==============================================
              // 💾 UPDATE USER
              // ==============================================

              transaction.set(
                userRef,
                {

                  hashRate:
                    newHashRate,


                  adsToday:
                    newAdsToday,


                  adDate:
                    today,


                  lastAdTimestamp:
                    FieldValue.serverTimestamp(),


                  miningStartedAt,

                  miningEndsAt,


                  updatedAt:
                    FieldValue.serverTimestamp(),

                },
                {
                  merge: true,
                }
              );


              // ==============================================
              // 💾 SAVE ADMOB TRANSACTION
              // ==============================================

              transaction.set(
                rewardRef,
                {

                  uid,

                  transactionId,


                  adUnit:
                    String(
                      req.query.ad_unit || ""
                    ),


                  adNetwork:
                    String(
                      req.query.ad_network || ""
                    ),


                  rewardAmount:
                    String(
                      req.query.reward_amount || ""
                    ),


                  rewardItem:
                    String(
                      req.query.reward_item || ""
                    ),


                  timestamp:
                    String(
                      req.query.timestamp || ""
                    ),


                  createdAt:
                    FieldValue.serverTimestamp(),

                }
              );


              // ==============================================
              // 📜 HISTORY
              // ==============================================

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
                    bonus,


                  hashRateAfter:
                    newHashRate,


                  adsToday:
                    newAdsToday,


                  miningRestarted,


                  admobTransactionId:
                    transactionId,


                  createdAt:
                    FieldValue.serverTimestamp(),

                }
              );


              // ==============================================
              // 🐱 SUCCESS
              // ==============================================

              return {

                success: true,


                bonus,


                hashRate:
                  newHashRate,


                adsToday:
                  newAdsToday,


                miningRestarted,

              };
            }
          );


        // ====================================================
        // 🛡️ DUPLICATE RESPONSE
        // ====================================================

        if (result.duplicate) {

          res
            .status(200)
            .send("Duplicate ignored");

          return;
        }


        // ====================================================
        // 🚫 REJECTED RESPONSE
        // ====================================================

        if (result.rejected) {

          res
            .status(200)
            .send(
              `Reward rejected: ${result.reason}`
            );

          return;
        }


        // ====================================================
        // 🐱 SUCCESS RESPONSE
        // ====================================================

        res
          .status(200)
          .send(
            "🐱 Stella Power Boost processed successfully!"
          );

      } catch (error) {

        console.error(
          "🐱 AdMob reward error:",
          error
        );


        res
          .status(400)
          .send(
            "Invalid reward callback"
          );
      }
    }
  );


// ============================================================
// 📦 EXPORTS
// ============================================================

module.exports = {

  testAdReward,

  adMobReward,

};