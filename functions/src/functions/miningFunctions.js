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
} = require("firebase-functions/v2/https");

// ============================================================
// 🔥 FIREBASE
// ============================================================

const {
  db,
  FieldValue,
} = require("../firebase/firebase");

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
} = require("../config/miningConfig");

// ============================================================
// 📅 DATE UTILITIES
// ============================================================

const {
  getUtcDateString,
} = require("../utils/dateUtils");

// ============================================================
// 👤 USER UTILITIES
// ============================================================

const {
  getUserRef,
  getHistoryCollection,
} = require("../utils/userUtils");

// ============================================================
// ⛏️ MINING UTILITIES
// ============================================================

const {
  calculateMiningStatus,
  getMiningStartTime,
  getMiningEndTime,
  calculateMining,
} = require("../utils/miningUtils");

// ============================================================
// 🔢 SAFE NUMBER
// ============================================================

function getSafeNumber(value, fallback = 0) {
  const number = Number(value);

  return Number.isFinite(number)
    ? number
    : fallback;
}

// ============================================================
// 🔥 SAFE NON-NEGATIVE NUMBER
// ============================================================
//
// Hyväksyy myös arvon 0.
//
// ============================================================

function getSafeNonNegativeNumber(
  value,
  fallback
) {
  const number = Number(value);

  if (
    Number.isFinite(number) &&
    number >= 0
  ) {
    return number;
  }

  return fallback;
}

// ============================================================
// 🔥 SAFE POSITIVE NUMBER
// ============================================================
//
// Käytetään asioissa, joiden täytyy olla aidosti suurempia
// kuin nolla.
//
// ============================================================

function getSafePositiveNumber(
  value,
  fallback
) {
  const number = Number(value);

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
  // ==========================================================
  // 📅 STORED DATE
  // ==========================================================

  const storedDate =
    typeof data.lastAdDate === "string"
      ? data.lastAdDate
      : "";

  // ==========================================================
  // 🔢 ADS TODAY
  // ==========================================================

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

  // ==========================================================
  // ⏳ LAST AD REWARD
  // ==========================================================

  const lastAdRewardAt =
    data.lastAdRewardAt;

  let lastAdRewardMs = 0;

  if (
    lastAdRewardAt &&
    typeof lastAdRewardAt.toDate === "function"
  ) {
    const date =
      lastAdRewardAt.toDate();

    if (
      date instanceof Date &&
      !Number.isNaN(date.getTime())
    ) {
      lastAdRewardMs =
        date.getTime();
    }
  } else if (
    lastAdRewardAt instanceof Date
  ) {
    if (
      !Number.isNaN(
        lastAdRewardAt.getTime()
      )
    ) {
      lastAdRewardMs =
        lastAdRewardAt.getTime();
    }
  } else if (
    typeof lastAdRewardAt === "string"
  ) {
    const parsedDate =
      new Date(lastAdRewardAt);

    if (
      !Number.isNaN(
        parsedDate.getTime()
      )
    ) {
      lastAdRewardMs =
        parsedDate.getTime();
    }
  }

  // ==========================================================
  // ⏳ COOLDOWN
  // ==========================================================

  const cooldownRemainingMs =
    lastAdRewardMs > 0
      ? Math.max(
          0,
          lastAdRewardMs +
            AD_COOLDOWN_MS -
            nowMs
        )
      : 0;

  // ==========================================================
  // 📺 CAN WATCH
  // ==========================================================

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
  // ==========================================================
  // 📅 LAST DAILY DATE
  // ==========================================================

  const lastDailyDate =
    typeof data.lastDailyDate === "string"
      ? data.lastDailyDate
      : "";

  // ==========================================================
  // 🎁 CLAIMED TODAY
  // ==========================================================

  const dailyClaimed =
    lastDailyDate === today;

  // ==========================================================
  // 🔥 DAILY STREAK
  //
  // Tuetaan:
  //
  // • dailyStreak
  // • streak
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
  // ⚡ DAILY HASH RATE BONUS
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
// ⛏️ GET MINING HASH RATE
// ============================================================
//
// Louhinnan aikana käytetään miningHashRate-arvoa.
//
// Tämä lukitsee aktiivisen louhintajakson Hash Rate -arvon.
// Daily Bonus ja Power Boost vaikuttavat seuraavaan
// louhintajaksoon.
//
// ============================================================

function getMiningHashRate(
  data,
  fallbackHashRate
) {
  return getSafeNonNegativeNumber(
    data.miningHashRate,
    fallbackHashRate
  );
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
        // ⚡ CURRENT HASH RATE
        // ====================================================

        const hashRate =
          getSafeNonNegativeNumber(
            data.hashRate,
            DEFAULT_HASH_RATE
          );

        // ====================================================
        // ⛏️ ACTIVE MINING HASH RATE
        // ====================================================

        const miningHashRate =
          getMiningHashRate(
            data,
            hashRate
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
            {
              ...data,
              hashRate:
                miningHashRate,
            },
            now
          );

        // ====================================================
        // ✨ UNCLAIMED MINING
        // ====================================================

        const unclaimedMining =
          Math.max(
            0,
            getSafeNumber(
              miningStatus.minedAmount,
              0
            )
          );

        // ====================================================
        // 💎 ESTIMATED TOTAL
        // ====================================================

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
        // ⚡ CURRENT MINING SPEED
        // ====================================================

        const miningPerHour =
          hashRate *
          MINING_PER_HASH_PER_HOUR;

        // ====================================================
        // ⛏️ ACTIVE CYCLE SPEED
        // ====================================================

        const activeMiningPerHour =
          miningHashRate *
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

          // ==================================================
          // ⚡ CURRENT HASH RATE
          // ==================================================

          hashRate,

          // ==================================================
          // ⛏️ ACTIVE MINING HASH RATE
          // ==================================================

          miningHashRate,

          // ==================================================
          // 💰 BALANCE
          // ==================================================

          miningBalance,

          // ==================================================
          // ✨ UNCLAIMED
          // ==================================================

          unclaimedMining,

          // ==================================================
          // 💎 TOTAL
          // ==================================================

          estimatedTotal,

          // ==================================================
          // ⛏️ STATUS
          // ==================================================

          miningActive:
            miningStatus.miningActive === true,

          miningFinished:
            miningStatus.miningFinished === true,

          // ==================================================
          // ⏱️ TIME
          // ==================================================

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

          // ==================================================
          // 🕒 START / END
          // ==================================================

          miningStartedAt:
            miningStartedAt
              ? miningStartedAt.toISOString()
              : null,

          miningEndsAt:
            miningEndsAt
              ? miningEndsAt.toISOString()
              : null,

          // ==================================================
          // ⚡ SPEED
          // ==================================================

          miningPerHour,

          miningPerMinute:
            miningPerHour / 60,

          miningPerSecond:
            miningPerHour / 3600,

          // ==================================================
          // ⛏️ ACTIVE CYCLE SPEED
          // ==================================================

          activeMiningPerHour,

          // ==================================================
          // 🎁 DAILY BONUS
          // ==================================================

          dailyClaimed:
            dailyStatus.dailyClaimed,

          streak:
            dailyStatus.streak,

          dailyStreak:
            dailyStatus.streak,

          dailyHashRateBonus:
            dailyStatus.dailyHashRateBonus,

          // ==================================================
          // 📺 POWER BOOST
          // ==================================================

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

        if (
          error instanceof HttpsError
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
            // ⚡ CURRENT HASH RATE
            // ==================================================

            const hashRate =
              getSafeNonNegativeNumber(
                data.hashRate,
                DEFAULT_HASH_RATE
              );

            // ==================================================
            // ⛏️ ACTIVE CYCLE HASH RATE
            // ==================================================

            const miningHashRate =
              getMiningHashRate(
                data,
                hashRate
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
                {
                  ...data,
                  hashRate:
                    miningHashRate,
                },
                now
              );

            // ==================================================
            // 🐱 ALREADY MINING
            // ====================================================

            if (
              miningStatus.miningActive
            ) {
              return {
                success: true,

                started: false,

                collected: 0,

                miningActive: true,

                hashRate,

                miningHashRate,

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

            let collected = 0;

            let completedPreviousCycle =
              false;

            // ==================================================
            // 💰 COLLECT FINISHED MINING
            // ==================================================

            if (
              previousStart &&
              previousEnd &&
              previousEnd.getTime() <=
                now.getTime()
            ) {
              // ================================================
              // ⏱️ PREVIOUS DURATION
              // ================================================

              const previousDuration =
                Math.max(
                  0,
                  previousEnd.getTime() -
                    previousStart.getTime()
                );

              // ================================================
              // 💰 CALCULATE USING LOCKED HASH RATE
              // ================================================

              collected =
                Math.max(
                  0,
                  getSafeNumber(
                    calculateMining(
                      miningHashRate,
                      previousDuration
                    ),
                    0
                  )
                );

              if (
                collected > 0
              ) {
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
            // ⚡ NEW CYCLE HASH RATE
            // ==================================================

            const newMiningHashRate =
              hashRate;

            // ==================================================
            // 👤 UPDATE USER
            // ==================================================

            transaction.set(
              userRef,
              {
                // ==============================================
                // ⚡ CURRENT HASH RATE
                // ==============================================

                hashRate,

                // ==============================================
                // ⛏️ HASH RATE LOCKED FOR THIS CYCLE
                // ==============================================

                miningHashRate:
                  newMiningHashRate,

                // ==============================================
                // 💰 BALANCE
                // ==============================================

                miningBalance:
                  newBalance,

                // ==============================================
                // ⛏️ MINING TIME
                // ==============================================

                miningStartedAt:
                  newMiningStartedAt,

                miningEndsAt:
                  newMiningEndsAt,

                // ==============================================
                // 🕒 METADATA
                // ==============================================

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

            if (
              completedPreviousCycle
            ) {
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

                  hashRate:
                    miningHashRate,

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

                hashRate:
                  newMiningHashRate,

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

              miningHashRate:
                newMiningHashRate,

              miningDurationMs:
                MINING_DURATION_MS,

              miningRemainingMs:
                MINING_DURATION_MS,

              miningStartedAt:
                newMiningStartedAt.toISOString(),

              miningEndsAt:
                newMiningEndsAt.toISOString(),

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

        if (
          error instanceof HttpsError
        ) {
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