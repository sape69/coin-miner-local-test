"use strict";


// ============================================================
// 🐱 STELLA MINING FUNCTIONS
// ============================================================
//
// ⛏️ Stella Mining Status
// ⏱️ 24 tunnin louhintajakso
// ✨ Reaaliaikainen STL-louhinta
// 💰 Valmistuneen louhinnan kerääminen
// 🔄 Uuden louhintajakson käynnistäminen
// 📜 Mining-historia
// 🎁 Daily Bonus -tila
// 📺 Stella Power Boost -tila
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
// 🔢 SAFE NUMBER
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
// 🔥 SAFE POSITIVE NUMBER
// ============================================================

function getSafePositiveNumber(
  value,
  fallback
) {

  const number =
    Number(value);

  if (
    Number.isFinite(number) &&
    number > 0
  ) {
    return number;
  }

  return fallback;

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
    lastAdRewardMs > 0
      ? Math.max(
          0,
          (
            lastAdRewardMs +
            AD_COOLDOWN_MS
          ) -
          nowMs
        )
      : 0;


  const canWatchAd =
    adsToday < MAX_ADS_PER_DAY &&
    cooldownRemainingMs <= 0;


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


  // ==========================================================
  // DAILY STREAK
  //
  // Uusi dailyFunctions.js käyttää dailyStreak.
  // Tuetaan myös vanhaa streak-kenttää.
  //
  // ==========================================================

  const storedStreak =
    data.dailyStreak ??
    data.streak ??
    0;


  const streak =
    Math.max(
      0,
      Math.floor(
        getSafeNumber(
          storedStreak,
          0
        )
      )
    );


  // ==========================================================
  // DAILY BONUS
  // ==========================================================

  const dailyHashRateBonus =
    getSafePositiveNumber(
      data.dailyHashRateBonus,
      1
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
  onCall(
    {
      region: "us-central1",
    },
    async (request) => {

      try {

        // ====================================================
        // 🔐 AUTHENTICATION
        // ====================================================

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


        // ====================================================
        // 👤 GET USER
        // ====================================================

        const snapshot =
          await userRef.get();


        const data =
          snapshot.exists
            ? snapshot.data() || {}
            : {};


        // ====================================================
        // 🕒 SERVER TIME
        // ====================================================

        const now =
          new Date();


        const nowMs =
          now.getTime();


        const today =
          getUtcDateString();


        // ====================================================
        // ⚡ HASH RATE
        // ====================================================

        const hashRate =
          Math.max(
            0,
            getSafePositiveNumber(
              data.hashRate,
              DEFAULT_HASH_RATE
            )
          );


        // ====================================================
        // 💰 SAVED BALANCE
        // ====================================================

        const miningBalance =
          Math.max(
            0,
            getSafeNumber(
              data.miningBalance,
              0
            )
          );


        // ====================================================
        // ⛏️ MINING STATUS
        // ====================================================

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


        // ====================================================
        // 🕒 MINING TIMES
        // ====================================================

        const miningStartedAt =
          getMiningStartTime(data);


        const miningEndsAt =
          getMiningEndTime(data);


        // ====================================================
        // 📺 AD STATUS
        // ====================================================

        const adStatus =
          getAdStatus(
            data,
            nowMs,
            today
          );


        // ====================================================
        // 🎁 DAILY STATUS
        // ====================================================

        const dailyStatus =
          getDailyStatus(
            data,
            today
          );


        // ====================================================
        // ⚡ MINING SPEED
        // ====================================================

        const miningPerHour =
          hashRate *
          MINING_PER_HASH_PER_HOUR;


        // ====================================================
        // 📦 RESPONSE
        // ====================================================

        return {

          success: true,


          message:
            miningStatus.miningActive
              ? "🐱⛏️ Stella louhii STL:ää!"
              : miningStatus.miningFinished
                  ? "🐱✨ Louhinta on valmis kerättäväksi!"
                  : "🐱 Stella odottaa seuraavaa louhintaa.",


          // ⚡ HASH RATE

          hashRate,


          // 💰 BALANCE

          miningBalance,


          // ✨ UNCLAIMED

          unclaimedMining,


          // 💎 TOTAL

          estimatedTotal,


          // ⛏️ STATUS

          miningActive:
            miningStatus.miningActive === true,


          miningFinished:
            miningStatus.miningFinished === true,


          // ⏱️ TIME

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


          // 🕒 START / END

          miningStartedAt:
            miningStartedAt
              ? miningStartedAt.toISOString()
              : null,


          miningEndsAt:
            miningEndsAt
              ? miningEndsAt.toISOString()
              : null,


          // ⚡ SPEED

          miningPerHour,


          miningPerMinute:
            miningPerHour / 60,


          miningPerSecond:
            miningPerHour / 3600,


          // 🎁 DAILY BONUS

          dailyClaimed:
            dailyStatus.dailyClaimed,


          streak:
            dailyStatus.streak,


          dailyStreak:
            dailyStatus.streak,


          dailyHashRateBonus:
            dailyStatus.dailyHashRateBonus,


          // 📺 POWER BOOST

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

      } catch (error) {

        console.error(
          "getMiningStatus error:",
          error
        );


        if (error instanceof HttpsError) {
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
// ⛏️ CLAIM / START STELLA MINING
// ============================================================
//
// Tämä funktio:
//
// 1. Tarkistaa käyttäjän
// 2. Tarkistaa louhiiko Stella jo
// 3. Kerää valmistuneen louhinnan
// 4. Lisää STL-saldon
// 5. Käynnistää uuden 24h louhinnan
//
// ============================================================

const claimMining =
  onCall(
    {
      region: "us-central1",
    },
    async (request) => {

      try {

        // ====================================================
        // 🔐 AUTHENTICATION
        // ====================================================

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


        // ====================================================
        // 🕒 SERVER TIME
        // ====================================================

        const now =
          new Date();


        // ====================================================
        // 🔥 FIRESTORE TRANSACTION
        // ====================================================

        return await db.runTransaction(
          async (transaction) => {

            // ==================================================
            // 👤 GET USER
            // ==================================================

            const snapshot =
              await transaction.get(
                userRef
              );


            const data =
              snapshot.exists
                ? snapshot.data() || {}
                : {};


            // ==================================================
            // ⚡ HASH RATE
            // ==================================================

            const hashRate =
              getSafePositiveNumber(
                data.hashRate,
                DEFAULT_HASH_RATE
              );


            // ==================================================
            // 💰 CURRENT BALANCE
            // ==================================================

            const oldBalance =
              Math.max(
                0,
                getSafeNumber(
                  data.miningBalance,
                  0
                )
              );


            // ==================================================
            // ⛏️ CURRENT MINING STATUS
            // ==================================================

            const miningStatus =
              calculateMiningStatus(
                data,
                now
              );


            // ==================================================
            // 🐱 ALREADY MINING
            // ==================================================

            if (miningStatus.miningActive) {

              return {

                success: true,

                started: false,

                collected: 0,

                miningActive: true,

                hashRate,

                unclaimedMining:
                  Math.max(
                    0,
                    getSafeNumber(
                      miningStatus.minedAmount,
                      0
                    )
                  ),

                miningRemainingMs:
                  Math.max(
                    0,
                    getSafeNumber(
                      miningStatus.miningRemainingMs,
                      0
                    )
                  ),

                message:
                  "🐱⛏️ Stella louhii jo STL:ää!",

              };

            }


            // ==================================================
            // 🕒 PREVIOUS MINING CYCLE
            // ==================================================

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


            // ==================================================
            // 💰 COLLECT FINISHED MINING
            // ==================================================

            if (
              previousStart &&
              previousEnd &&
              previousEnd.getTime() <= now.getTime()
            ) {

              const previousDuration =
                Math.max(
                  0,
                  previousEnd.getTime() -
                    previousStart.getTime()
                );


              collected =
                Math.max(
                  0,
                  getSafeNumber(
                    calculateMining(
                      hashRate,
                      previousDuration
                    ),
                    0
                  )
                );


              if (collected > 0) {

                newBalance =
                  oldBalance +
                  collected;


                completedPreviousCycle =
                  true;

              }

            }


            // ==================================================
            // 🐱 START NEW MINING CYCLE
            // ==================================================

            const newMiningStartedAt =
              now;


            const newMiningEndsAt =
              new Date(
                now.getTime() +
                MINING_DURATION_MS
              );


            // ==================================================
            // 👤 UPDATE USER
            // ==================================================

            transaction.set(
              userRef,
              {

                hashRate,


                miningBalance:
                  newBalance,


                miningStartedAt:
                  newMiningStartedAt,


                miningEndsAt:
                  newMiningEndsAt,


                updatedAt:
                  FieldValue.serverTimestamp(),

              },
              {
                merge: true,
              }
            );


            // ==================================================
            // 📜 HISTORY: COMPLETED MINING
            // ==================================================

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


            // ==================================================
            // 📜 HISTORY: NEW MINING
            // ==================================================

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


            // ==================================================
            // ✅ RESPONSE
            // ==================================================

            return {

              success: true,


              started: true,


              miningActive: true,


              collected,


              completedPreviousCycle,


              miningBalance:
                newBalance,


              hashRate,


              miningDurationMs:
                MINING_DURATION_MS,


              miningRemainingMs:
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

      } catch (error) {

        console.error(
          "claimMining error:",
          error
        );


        if (error instanceof HttpsError) {
          throw error;
        }


        throw new HttpsError(
          "internal",
          "🐱 Stella Miningin käynnistäminen epäonnistui."
        );

      }

    }
  );


// ============================================================
// 📦 EXPORTS
// ============================================================

module.exports = {

  getMiningStatus,

  claimMining,

};