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
  DAILY_HASH_RATE_START,
  DAILY_HASH_RATE_STEP,
  DAILY_HASH_RATE_MAX_DAY,
  MAX_DAILY_HASH_RATE,
  MINING_DURATION_MS,
  MINING_PER_HASH_PER_HOUR,
  AD_HASH_RATE_BONUS,
  AD_BOOST_DURATION_MS,
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

function getSafeNumber(
  value,
  fallback = 0
) {
  const number = Number(value);

  return Number.isFinite(number)
    ? number
    : fallback;
}

// ============================================================
// 🔥 SAFE NON-NEGATIVE NUMBER
// ============================================================

function getSafeNonNegativeNumber(
  value,
  fallback = 0
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

function getSafePositiveNumber(
  value,
  fallback = 0
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
// 🎁 CALCULATE DAILY HASH RATE
// ============================================================
//
// Päivittäinen Hash Rate:
//
// Day 1  = 0.5 HR
// Day 2  = 1.0 HR
// Day 3  = 1.5 HR
// Day 4  = 2.0 HR
// Day 5  = 2.5 HR
// Day 6  = 3.0 HR
// Day 7+ = 3.5 HR
//
// ============================================================

function calculateDailyHashRate(
  streak
) {
  const safeStreak =
    Math.max(
      1,
      Math.floor(
        getSafeNumber(
          streak,
          1
        )
      )
    );

  const effectiveDay =
    Math.min(
      safeStreak,
      DAILY_HASH_RATE_MAX_DAY
    );

  const rate =
    DAILY_HASH_RATE_START +
    (
      (effectiveDay - 1) *
      DAILY_HASH_RATE_STEP
    );

  return Math.min(
    MAX_DAILY_HASH_RATE,
    Math.max(
      DAILY_HASH_RATE_START,
      rate
    )
  );
}

// ============================================================
// 🎁 GET DAILY STREAK
// ============================================================

function getDailyStreak(
  data
) {
  const storedStreak =
    data.dailyStreak ??
    data.streak ??
    0;

  return Math.max(
    0,
    Math.floor(
      getSafeNumber(
        storedStreak,
        0
      )
    )
  );
}

// ============================================================
// 🎁 GET DAILY STATUS
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
    getDailyStreak(data);

  const dailyHashRate =
    calculateDailyHashRate(
      streak > 0
        ? streak
        : 1
    );

  return {
    dailyClaimed,
    streak,
    dailyHashRate,
  };
}

// ============================================================
// 📺 TIMESTAMP → MILLISECONDS
// ============================================================

function getTimestampMilliseconds(
  value
) {
  if (!value) {
    return 0;
  }

  if (
    typeof value.toDate === "function"
  ) {
    const date =
      value.toDate();

    if (
      date instanceof Date &&
      !Number.isNaN(
        date.getTime()
      )
    ) {
      return date.getTime();
    }
  }

  if (
    value instanceof Date
  ) {
    if (
      !Number.isNaN(
        value.getTime()
      )
    ) {
      return value.getTime();
    }

    return 0;
  }

  if (
    typeof value === "string"
  ) {
    const parsed =
      new Date(value);

    if (
      !Number.isNaN(
        parsed.getTime()
      )
    ) {
      return parsed.getTime();
    }
  }

  if (
    typeof value === "number" &&
    Number.isFinite(value)
  ) {
    return value;
  }

  return 0;
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
      : "";

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

  const lastAdRewardMs =
    getTimestampMilliseconds(
      data.lastAdRewardAt
    );

  const cooldownRemainingMs =
    lastAdRewardMs > 0
      ? Math.max(
          0,
          lastAdRewardMs +
            AD_COOLDOWN_MS -
            nowMs
        )
      : 0;

  const boostStartedMs =
    getTimestampMilliseconds(
      data.adBoostStartedAt
    );

  const boostEndsMs =
    getTimestampMilliseconds(
      data.adBoostEndsAt
    );

  const adBoostActive =
    boostStartedMs > 0 &&
    boostEndsMs > nowMs;

  const adBoostRemainingMs =
    adBoostActive
      ? Math.max(
          0,
          boostEndsMs -
            nowMs
        )
      : 0;

  const canWatchAd =
    adsToday < MAX_ADS_PER_DAY &&
    cooldownRemainingMs === 0 &&
    !adBoostActive;

  return {
    adsToday,

    maxAdsPerDay:
      MAX_ADS_PER_DAY,

    cooldownRemainingMs,

    canWatchAd,

    adBoostActive,

    adBoostRemainingMs,

    adBoostStartedAt:
      boostStartedMs > 0
        ? new Date(
            boostStartedMs
          )
        : null,

    adBoostEndsAt:
      boostEndsMs > 0
        ? new Date(
            boostEndsMs
          )
        : null,
  };
}

// ============================================================
// ⛏️ GET VALID MINING HASH RATE
// ============================================================
//
// Aktiivisen louhintajakson Hash Rate lukitaan jakson
// alussa.
//
// Uusi järjestelmä sallii vain:
//
// 0.5 → 1.0 → 1.5 → 2.0 → 2.5 → 3.0 → 3.5 HR
//
// Jos Firestoressa on vanha arvo, esimerkiksi 12 HR,
// sitä EI käytetä uuden järjestelmän louhintanopeutena.
//
// ============================================================

function getMiningHashRate(
  data,
  fallbackHashRate
) {
  const stored =
    getSafePositiveNumber(
      data.miningHashRate,
      0
    );

  if (
    stored >= DAILY_HASH_RATE_START &&
    stored <= MAX_DAILY_HASH_RATE
  ) {
    return stored;
  }

  return fallbackHashRate;
}

// ============================================================
// 📺 GET AD BOOST HISTORY
// ============================================================
//
// Haetaan käyttäjän Power Boost -historia.
//
// Jokainen ad_reward sisältää:
//
// boostStartedAt
// boostEndsAt
//
// Näiden avulla lasketaan kuinka paljon aktiivinen boosti
// osui kyseiseen mining-jaksoon.
//
// ============================================================

async function getAdBoostHistory(
  uid,
  miningStartMs,
  miningEndMs
) {
  if (
    !miningStartMs ||
    !miningEndMs ||
    miningEndMs <= miningStartMs
  ) {
    return [];
  }

  const historyCollection =
    getHistoryCollection(uid);

  const snapshot =
    await historyCollection
      .where(
        "type",
        "==",
        "ad_reward"
      )
      .get();

  const boosts = [];

  snapshot.forEach(
    (doc) => {
      const data =
        doc.data() || {};

      const boostStartedMs =
        getTimestampMilliseconds(
          data.boostStartedAt
        );

      const boostEndsMs =
        getTimestampMilliseconds(
          data.boostEndsAt
        );

      if (
        boostStartedMs <= 0 ||
        boostEndsMs <= boostStartedMs
      ) {
        return;
      }

      // --------------------------------------------------------
      // Boostin täytyy leikata mining-jakson kanssa.
      // --------------------------------------------------------

      if (
        boostEndsMs <= miningStartMs ||
        boostStartedMs >= miningEndMs
      ) {
        return;
      }

      boosts.push({
        boostStartedMs,
        boostEndsMs,
      });
    }
  );

  return boosts;
}

// ============================================================
// ⚡ CALCULATE AD BOOST MILLISECONDS
// ============================================================

function calculateAdBoostMilliseconds(
  boosts,
  miningStartMs,
  miningEndMs
) {
  let totalMs = 0;

  for (
    const boost of boosts
  ) {
    const overlapStart =
      Math.max(
        miningStartMs,
        boost.boostStartedMs
      );

    const overlapEnd =
      Math.min(
        miningEndMs,
        boost.boostEndsMs
      );

    if (
      overlapEnd > overlapStart
    ) {
      totalMs +=
        overlapEnd -
        overlapStart;
    }
  }

  return Math.max(
    0,
    totalMs
  );
}

// ============================================================
// 💰 CALCULATE MINING AMOUNT
// ============================================================

function calculateMiningAmount(
  miningHashRate,
  miningStartMs,
  effectiveEndMs,
  adBoostMilliseconds
) {
  if (
    effectiveEndMs <=
    miningStartMs
  ) {
    return 0;
  }

  const totalDurationMs =
    effectiveEndMs -
    miningStartMs;

  // ----------------------------------------------------------
  // Base mining
  // ----------------------------------------------------------

  const baseMining =
    calculateMining(
      miningHashRate,
      totalDurationMs
    );

  // ----------------------------------------------------------
  // Power Boost mining
  //
  // Base rate on koko jaksolta.
  // Boost lisää vain +0.5833 HR sen aktiivisen ajan.
  // ----------------------------------------------------------

  const boostMining =
    calculateMining(
      AD_HASH_RATE_BONUS,
      adBoostMilliseconds
    );

  return Math.max(
    0,
    getSafeNumber(
      baseMining,
      0
    ) +
    getSafeNumber(
      boostMining,
      0
    )
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
        // 🎁 DAILY STATUS
        // ====================================================

        const dailyStatus =
          getDailyStatus(
            data,
            today
          );

        // ====================================================
        // ⚡ CURRENT HASH RATE
        // ====================================================
        //
        // Uusi järjestelmä ei koskaan käytä vanhaa esim.
        // 12 HR Firestore-arvoa.
        //
        // Hash Rate tulee Daily Streakistä.
        //
        // ====================================================

        const hashRate =
          dailyStatus.dailyHashRate;

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
        // ✨ BASE UNCLAIMED MINING
        // ====================================================

        let unclaimedMining =
          Math.max(
            0,
            getSafeNumber(
              miningStatus.minedAmount,
              0
            )
          );

        // ====================================================
        // ⚡ POWER BOOST MINING
        // ====================================================

        let adBoostMining = 0;

        if (
          miningStartedAt &&
          miningEndsAt
        ) {
          const miningStartMs =
            miningStartedAt.getTime();

          const miningEndMs =
            Math.min(
              miningEndsAt.getTime(),
              nowMs
            );

          if (
            miningEndMs >
            miningStartMs
          ) {
            const boosts =
              await getAdBoostHistory(
                uid,
                miningStartMs,
                miningEndMs
              );

            const boostMilliseconds =
              calculateAdBoostMilliseconds(
                boosts,
                miningStartMs,
                miningEndMs
              );

            adBoostMining =
              calculateMining(
                AD_HASH_RATE_BONUS,
                boostMilliseconds
              );

            unclaimedMining =
              Math.max(
                0,
                unclaimedMining +
                  adBoostMining
              );
          }
        }

        // ====================================================
        // 💎 ESTIMATED TOTAL
        // ====================================================

        const estimatedTotal =
          miningBalance +
          unclaimedMining;

        // ====================================================
        // ⚡ EFFECTIVE HASH RATE
        // ====================================================

        const effectiveHashRate =
          adStatus.adBoostActive
            ? hashRate +
                AD_HASH_RATE_BONUS
            : hashRate;

        // ====================================================
        // ⚡ CURRENT MINING SPEED
        // ====================================================

        const miningPerHour =
          effectiveHashRate *
          MINING_PER_HASH_PER_HOUR;

        // ====================================================
        // ⛏️ ACTIVE CYCLE BASE SPEED
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
          // ⚡ CURRENT DAILY HASH RATE
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
          // ⚡ AD BOOST MINING
          // ==================================================

          adBoostMining,

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
            dailyStatus.dailyHashRate,

          // ==================================================
          // 📺 POWER BOOST
          // ==================================================

          adsToday:
            adStatus.adsToday,

          maxAdsPerDay:
            adStatus.maxAdsPerDay,

          adHashRateBonus:
            AD_HASH_RATE_BONUS,

          adBoostDurationMs:
            AD_BOOST_DURATION_MS,

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

          effectiveHashRate,
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

        const nowMs =
          now.getTime();

        const today =
          getUtcDateString();

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
            // 🎁 DAILY STATUS
            // ==================================================

            const dailyStatus =
              getDailyStatus(
                data,
                today
              );

            // ==================================================
            // ⚡ CURRENT HASH RATE
            // ====================================================
            //
            // Vanha Firestore-hashRate, esim. 12 HR,
            // ei enää määrää uutta louhintanopeutta.
            //
            // ====================================================

            const hashRate =
              dailyStatus.dailyHashRate;

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

            let previousAdBoostMining = 0;

            // ==================================================
            // 💰 COLLECT FINISHED MINING
            // ==================================================

            if (
              previousStart &&
              previousEnd &&
              previousEnd.getTime() <=
                nowMs
            ) {
              // ================================================
              // ⏱️ PREVIOUS DURATION
              // ================================================

              const previousStartMs =
                previousStart.getTime();

              const previousEndMs =
                previousEnd.getTime();

              const previousDuration =
                Math.max(
                  0,
                  previousEndMs -
                    previousStartMs
                );

              // ================================================
              // 💰 BASE MINING
              // ================================================

              const baseCollected =
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

              // ================================================
              // ⚡ POWER BOOST MINING
              // ================================================

              const boosts =
                await getAdBoostHistory(
                  uid,
                  previousStartMs,
                  previousEndMs
                );

              const boostMilliseconds =
                calculateAdBoostMilliseconds(
                  boosts,
                  previousStartMs,
                  previousEndMs
                );

              previousAdBoostMining =
                Math.max(
                  0,
                  getSafeNumber(
                    calculateMining(
                      AD_HASH_RATE_BONUS,
                      boostMilliseconds
                    ),
                    0
                  )
                );

              // ================================================
              // 💰 TOTAL COLLECTION
              // ================================================

              collected =
                baseCollected +
                previousAdBoostMining;

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
                nowMs +
                  MINING_DURATION_MS
              );

            // ==================================================
            // ⚡ NEW CYCLE HASH RATE
            // ====================================================
            //
            // Uusi mining-jakso käyttää Daily Hash Ratea.
            //
            // ====================================================

            const newMiningHashRate =
              hashRate;

            // ==================================================
            // 👤 UPDATE USER
            // ==================================================
            //
            // Tärkeää:
            //
            // Power Boost -kenttiä EI poisteta tässä.
            //
            // Jos boost on edelleen aktiivinen uuden mining-
            // jakson alkaessa, sen pitää jatkaa toimintaansa.
            //
            // ==================================================

            const userUpdate = {
              // ==============================================
              // ⚡ CURRENT DAILY HASH RATE
              // ==============================================

              hashRate,

              // ==============================================
              // 🎁 DAILY HASH RATE
              // ==============================================

              dailyHashRate:
                dailyStatus.dailyHashRate,

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
            };

            transaction.set(
              userRef,
              userUpdate,
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

                  baseMining:
                    Math.max(
                      0,
                      getSafeNumber(
                        calculateMining(
                          miningHashRate,
                          Math.max(
                            0,
                            previousEnd.getTime() -
                              previousStart.getTime()
                          )
                        ),
                        0
                      )
                    ),

                  adBoostMining:
                    previousAdBoostMining,

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
            // ⚡ ACTIVE POWER BOOST INFO
            // ==================================================

            const boostStartedMs =
              getTimestampMilliseconds(
                data.adBoostStartedAt
              );

            const boostEndsMs =
              getTimestampMilliseconds(
                data.adBoostEndsAt
              );

            const adBoostActive =
              boostStartedMs > 0 &&
              boostEndsMs > nowMs;

            const adBoostRemainingMs =
              adBoostActive
                ? boostEndsMs -
                    nowMs
                : 0;

            const effectiveHashRate =
              adBoostActive
                ? hashRate +
                    AD_HASH_RATE_BONUS
                : hashRate;

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

              dailyHashRate:
                dailyStatus.dailyHashRate,

              dailyStreak:
                dailyStatus.streak,

              adBoostActive,

              adBoostRemainingMs,

              adHashRateBonus:
                AD_HASH_RATE_BONUS,

              effectiveHashRate,

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