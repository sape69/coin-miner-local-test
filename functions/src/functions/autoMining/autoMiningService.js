
"use strict";

// ============================================================
// 🐱 STELLURIINI - PREMIUM PLUS AUTO MINING SERVICE
// ============================================================
//
// Vastuut:
// - Premium Plus -oikeuden tarkistaminen
// - Päättyneen louhintajakson kerääminen
// - STL-saldon päivittäminen
// - Achievementien käsittely
// - Referral-palkkion käsittely
// - Seuraavan 24h louhintajakson käynnistäminen
//
// Kaikki käyttäjän muutokset tehdään yhdessä
// Firestore-transaktiossa.
//
// ============================================================

const {
  hasActiveVerifiedPremiumPlus,
  isMiningCycleExpired,
} = require("./autoMiningHelpers");


// ============================================================
// VALUE HELPERS
// ============================================================

function number(value, fallback = 0) {
  const result = Number(value);

  return Number.isFinite(result)
    ? result
    : fallback;
}

function nonNegative(value, fallback = 0) {
  const result = Number(value);

  return Number.isFinite(result) && result >= 0
    ? result
    : fallback;
}


// ============================================================
// CREATE AUTO MINING SERVICE
// ============================================================

function createAutoMiningService({
  db,
  FieldValue,

  getUserRef,
  getHistoryCollection,

  getUtcDateString,

  miningWindow,
  historicalHashRate,
  miningHashRate,

  dailyHashRate,
  dailyHashRateBonus,
  miningDailyStreak,
  getMiningDailyClaim,
  getNextMiningDailyHashRate,
  getNextMiningDailyStreak,

  getMiningHalvingMultiplier,
  getHalvingMultiplier,
  getRegisteredUserCount,

  collectCompletedMiningCycle,

  prepareMiningAchievements,
  writeMiningAchievements,

  processReferralMiningReward,

  MINING_DURATION_MS,
}) {
  // ----------------------------------------------------------
  // DEPENDENCY VALIDATION
  // ----------------------------------------------------------

  const requiredFunctions = {
    getUserRef,
    getHistoryCollection,
    getUtcDateString,
    miningWindow,
    historicalHashRate,
    miningHashRate,
    dailyHashRate,
    dailyHashRateBonus,
    miningDailyStreak,
    getMiningDailyClaim,
    getNextMiningDailyHashRate,
    getNextMiningDailyStreak,
    getMiningHalvingMultiplier,
    getHalvingMultiplier,
    getRegisteredUserCount,
    collectCompletedMiningCycle,
    prepareMiningAchievements,
    writeMiningAchievements,
    processReferralMiningReward,
  };

  for (const [name, dependency] of Object.entries(
    requiredFunctions
  )) {
    if (typeof dependency !== "function") {
      throw new Error(
        `AUTO_MINING: Missing dependency: ${name}`
      );
    }
  }

  if (!db || !FieldValue) {
    throw new Error(
      "AUTO_MINING: Firestore dependencies missing."
    );
  }

  if (
    !Number.isFinite(MINING_DURATION_MS) ||
    MINING_DURATION_MS <= 0
  ) {
    throw new Error(
      "AUTO_MINING: Invalid mining duration."
    );
  }


  // ==========================================================
  // PROCESS ONE USER
  // ==========================================================

  async function processUser(uid) {
    if (
      typeof uid !== "string" ||
      uid.trim().length === 0
    ) {
      return {
        success: false,
        skipped: true,
        reason: "invalid_uid",
      };
    }

    const userRef = getUserRef(uid);

    return db.runTransaction(
      async (transaction) => {
        const now = new Date();
        const nowMs = now.getTime();
        const today = getUtcDateString(now);

        // ----------------------------------------------------
        // READ USER
        // ----------------------------------------------------

        const snapshot = await transaction.get(userRef);

        if (!snapshot.exists) {
          return {
            success: false,
            skipped: true,
            reason: "user_not_found",
          };
        }

        const data = snapshot.data() || {};

        // ----------------------------------------------------
        // VERIFY PREMIUM PLUS
        // ----------------------------------------------------

        if (
          !hasActiveVerifiedPremiumPlus(
            data,
            nowMs
          )
        ) {
          return {
            success: false,
            skipped: true,
            reason: "premium_plus_inactive",
          };
        }

        // ----------------------------------------------------
        // CHECK MINING WINDOW
        // ----------------------------------------------------

        const previous = miningWindow(data);

        if (
          !isMiningCycleExpired(
            previous,
            nowMs
          )
        ) {
          return {
            success: true,
            skipped: true,
            reason: "mining_cycle_not_expired",
          };
        }

        // ----------------------------------------------------
        // VERIFY HISTORICAL HASH RATE
        // ----------------------------------------------------

        const oldHashRate =
          historicalHashRate(data);

        if (
          !Number.isFinite(oldHashRate) ||
          oldHashRate <= 0
        ) {
          return {
            success: false,
            skipped: true,
            reason: "invalid_historical_hash_rate",
          };
        }

        // ----------------------------------------------------
        // COLLECT PREVIOUS MINING CYCLE
        // ----------------------------------------------------

        const cycle =
          await collectCompletedMiningCycle({
            uid,
            userData: data,
            nowMs,
            transaction,
          });

        if (!cycle || cycle.completed !== true) {
          throw new Error(
            "AUTO_MINING: Completed mining cycle could not be collected."
          );
        }

        const collected = nonNegative(
          cycle.collected
        );

        const oldBalance = nonNegative(
          data.miningBalance
        );

        let newBalance =
          oldBalance + collected;

        // ----------------------------------------------------
        // DAILY HASH RATE
        // ----------------------------------------------------

        const currentStreak =
          miningDailyStreak(data);

        const daily = getMiningDailyClaim(
          data,
          today,
          nowMs
        );

        const rate = number(
          daily.dailyHashRate,
          0
        );

        if (rate <= 0) {
          throw new Error(
            "AUTO_MINING: Invalid next mining Hash Rate."
          );
        }

        // ----------------------------------------------------
        // HALVING
        // ----------------------------------------------------

        const registeredUserCount =
          await getRegisteredUserCount();

        const newHalvingMultiplier =
          getHalvingMultiplier(
            registeredUserCount
          );

        // ----------------------------------------------------
        // ACHIEVEMENTS
        // ----------------------------------------------------

        const achievementResult =
          await prepareMiningAchievements(
            transaction,
            uid,
            collected,
            true,
            daily.claimedToday,
            daily.streak,
            data,
            now
          );

        const achievementReward = nonNegative(
          achievementResult.totalReward
        );

        newBalance += achievementReward;

        // ----------------------------------------------------
        // REFERRAL REWARD
        // ----------------------------------------------------

        let referralResult = {
          rewarded: false,
          duplicate: false,
          bonus: 0,
        };

        let miningTransactionId = "";

        if (collected > 0) {
          miningTransactionId =
            getHistoryCollection(uid).doc().id;

          referralResult =
            await processReferralMiningReward(
              uid,
              collected,
              miningTransactionId,
              transaction
            );
        }

        // ----------------------------------------------------
        // WRITE ACHIEVEMENTS
        // ----------------------------------------------------

        writeMiningAchievements(
          transaction,
          achievementResult
        );

        // ----------------------------------------------------
        // ACHIEVEMENT REWARD HISTORY
        // ----------------------------------------------------

        if (achievementReward > 0) {
          for (
            const reward of achievementResult.rewards
          ) {
            transaction.set(
              getHistoryCollection(uid).doc(),
              {
                type: "achievement_reward",

                title:
                  "Stella Achievement Reward 🐱🏆✨",

                achievementId:
                  reward.achievementId,

                amount: reward.reward,
                reward: reward.reward,
                balanceAfter: newBalance,

                createdAt:
                  FieldValue.serverTimestamp(),
              }
            );
          }
        }

        // ----------------------------------------------------
        // NEW MINING CYCLE
        // ----------------------------------------------------

        const startedAt = now;

        const endsAt = new Date(
          nowMs + MINING_DURATION_MS
        );

        transaction.set(
          userRef,
          {
            hashRate: rate,

            miningHashRate: rate,

            miningStreak: daily.streak,

            lastMiningDate: today,

            miningHalvingMultiplier:
              newHalvingMultiplier,

            miningBalance: newBalance,

            totalMined:
              FieldValue.increment(collected),

            miningStartedAt: startedAt,

            miningEndsAt: endsAt,

            miningCycles:
              achievementResult.miningCycles,

            adBoostStartedAt: null,
            adBoostEndsAt: null,
            lastAdRewardAt: null,
            powerBoostTransactionId: null,

            autoMiningLastRunAt:
              FieldValue.serverTimestamp(),

            autoMiningLastCycleEnd:
              previous.miningEndsAt,

            updatedAt:
              FieldValue.serverTimestamp(),
          },
          {
            merge: true,
          }
        );

        // ----------------------------------------------------
        // DAILY HASH RATE HISTORY
        // ----------------------------------------------------

        if (!daily.claimedToday) {
          transaction.set(
            getHistoryCollection(uid).doc(),
            {
              type: "dailyHashRate",

              title:
                "Stella Daily Hash Rate 🐱✨",

              amount: rate,
              hashRate: rate,
              dailyHashRate: rate,

              hashRateBefore: oldHashRate,
              hashRateAfter: rate,

              dailyHashRateBonus:
                dailyHashRateBonus(daily.streak),

              dailyStreak: daily.streak,
              streak: daily.streak,
              miningDay: daily.streak,

              previousDailyDate:
                typeof data.lastMiningDate === "string"
                  ? data.lastMiningDate
                  : null,

              currentDailyDate: today,

              createdAt:
                FieldValue.serverTimestamp(),
            }
          );
        }

        // ----------------------------------------------------
        // PREVIOUS MINING REWARD HISTORY
        // ----------------------------------------------------

        transaction.set(
          getHistoryCollection(uid).doc(
            miningTransactionId ||
              getHistoryCollection(uid).doc().id
          ),
          {
            type: "mining_reward",

            title:
              "Stella Automatic Mining Complete 🐱⛏️✨",

            amount: collected,

            balanceAfter: newBalance,

            hashRate: oldHashRate,
            miningHashRate: oldHashRate,

            baseMining: cycle.baseMining,
            adBoostMining: cycle.adBoostMining,
            boostMilliseconds: cycle.boostMilliseconds,

            miningStartedAt:
              previous.miningStartedAt,

            miningEndsAt:
              previous.miningEndsAt,

            miningTransactionId:
              miningTransactionId || null,

            referralReward:
              referralResult.rewarded
                ? referralResult.bonus
                : 0,

            automaticMining: true,

            createdAt:
              FieldValue.serverTimestamp(),
          }
        );

        // ----------------------------------------------------
        // NEW MINING HISTORY
        // ----------------------------------------------------

        transaction.set(
          getHistoryCollection(uid).doc(),
          {
            type: "mining",

            title:
              "Stella Premium Plus Auto Mining Started 🐱⛏️",

            amount: 0,

            hashRate: rate,
            miningHashRate: rate,
            dailyHashRate: rate,

            dailyHashRateBonus:
              dailyHashRateBonus(daily.streak),

            dailyStreak: daily.streak,
            streak: daily.streak,
            miningDay: daily.streak,

            miningDurationMs:
              MINING_DURATION_MS,

            miningStartedAt: startedAt,
            miningEndsAt: endsAt,

            automaticMining: true,
            premiumAdFreeMining: true,

            rewardPurpose: "premium_plus_auto_mining",

            createdAt:
              FieldValue.serverTimestamp(),
          }
        );

        // ----------------------------------------------------
        // RESULT
        // ----------------------------------------------------

        return {
          success: true,
          skipped: false,

          uid,

          collected,

          achievementReward,

          referralReward:
            referralResult.rewarded
              ? referralResult.bonus
              : 0,

          miningBalance: newBalance,

          hashRate: rate,

          miningStartedAt:
            startedAt.toISOString(),

          miningEndsAt:
            endsAt.toISOString(),
        };
      }
    );
  }


  // ==========================================================
  // EXPORT SERVICE
  // ==========================================================

  return {
    processUser,
  };
}


// ============================================================
// EXPORTS
// ============================================================

module.exports = {
  createAutoMiningService,
};
