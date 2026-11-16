
"use strict";

// ============================================================
// 🐱 STELLURIINI - PREMIUM PLUS AUTO MINING SERVICE
// ============================================================
//
// Vastuut:
// - Premium Plus -tilauksen palvelinpuolen tarkistus
// - Päättyneen louhintajakson kerääminen
// - STL-saldon päivittäminen
// - Mining achievementien käsittely
// - Referral-palkkion käsittely
// - Ensimmäisen tai seuraavan 24h louhintajakson käynnistäminen
// - Automaattisen 24h Power Boostin käynnistäminen
//
// Premium Plus Power Boost:
// - Sama AD_HASH_RATE_BONUS kuin tavallisessa Boostissa.
// - Kesto on koko 24h louhintajakso.
// - Käynnistyy täsmälleen louhinnan alkaessa.
// - Ei kuluta AdMob-mainosten käyttökiintiötä.
// - Ei anna erillistä STL-palkkiota.
// - Ei muuta tavallisen AdMob-Boostin jäähdytysaikaa.
//
// Kaikki käyttäjän muutokset tehdään yhdessä
// Firestore-transaktiossa.
//
// ============================================================

const {
  AD_HASH_RATE_BONUS,
} = require("../../config/miningConfig");

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
  return Number.isFinite(Number(value)) &&
    Number(value) >= 0
    ? Number(value)
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

  collectCompletedMiningCycle,

  getMiningDailyClaim,
  getNextMiningDailyHashRate,
  getNextMiningDailyStreak,
  dailyHashRateBonus,

  getHalvingMultiplier,
  getRegisteredUserCount,

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
    collectCompletedMiningCycle,
    getMiningDailyClaim,
    getNextMiningDailyHashRate,
    getNextMiningDailyStreak,
    dailyHashRateBonus,
    getHalvingMultiplier,
    getRegisteredUserCount,
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

  if (
    !Number.isFinite(AD_HASH_RATE_BONUS) ||
    AD_HASH_RATE_BONUS <= 0
  ) {
    throw new Error(
      "AUTO_MINING: Invalid Power Boost Hash Rate bonus."
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

        const userSnapshot =
          await transaction.get(userRef);

        if (!userSnapshot.exists) {
          return {
            success: false,
            skipped: true,
            reason: "user_not_found",
          };
        }

        const data =
          userSnapshot.data() || {};

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
        // CHECK PREVIOUS MINING WINDOW
        // ----------------------------------------------------

        const previous =
          miningWindow(data);

        // Jos käyttäjällä on voimassa oleva louhintajakso,
        // sitä ei saa käynnistää uudelleen.
        const hasPreviousCycle =
          previous && previous.valid === true;

        if (
          hasPreviousCycle &&
          !isMiningCycleExpired(previous, nowMs)
        ) {
          return {
            success: true,
            skipped: true,
            reason: "mining_cycle_not_expired",
          };
        }

        // ----------------------------------------------------
        // PREVIOUS HASH RATE
        // ----------------------------------------------------

        const historicalRate =
          historicalHashRate(data);

        // ----------------------------------------------------
        // COLLECT PREVIOUS CYCLE ONLY WHEN ONE EXISTS
        // ----------------------------------------------------

        // Uudella Premium Plus -käyttäjällä ei ole
        // aikaisempaa louhintajaksoa kerättävänä.
        let cycle = {
          completed: true,
          collected: 0,
          baseMining: 0,
          adBoostMining: 0,
          boostMilliseconds: 0,
        };

        if (hasPreviousCycle) {
          if (
            !Number.isFinite(historicalRate) ||
            historicalRate <= 0
          ) {
            return {
              success: false,
              skipped: true,
              reason: "invalid_historical_hash_rate",
            };
          }

          cycle =
            await collectCompletedMiningCycle({
              uid,
              userData: data,
              nowMs,
              transaction,
            });

          if (
            !cycle ||
            cycle.completed !== true
          ) {
            throw new Error(
              "AUTO_MINING: Completed mining cycle calculation failed."
            );
          }
        }

        const collected =
          nonNegative(cycle.collected);

        // ----------------------------------------------------
        // DAILY HASH RATE
        // ----------------------------------------------------

        const daily =
          getMiningDailyClaim(
            data,
            today,
            nowMs
          );

        const rate =
          number(daily.dailyHashRate);

        // Ensimmäisellä louhintakerralla ei ole aiempaa
        // Hash Ratea. Käytetään silloin uutta päivittäistä
        // Hash Ratea historiatiedoissa.
        const oldHashRate =
          Number.isFinite(historicalRate) &&
          historicalRate > 0
            ? historicalRate
            : rate;

        if (rate <= 0) {
          throw new Error(
            "AUTO_MINING: Invalid daily Hash Rate."
          );
        }

        const oldBalance =
          nonNegative(data.miningBalance);

        let newBalance =
          oldBalance + collected;

        // ----------------------------------------------------
        // HALVING
        // ----------------------------------------------------

        const registeredUserCount =
          await getRegisteredUserCount();

        const newMiningHalvingMultiplier =
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

        const achievementReward =
          nonNegative(
            achievementResult.totalReward
          );

        newBalance += achievementReward;

        // ----------------------------------------------------
        // REFERRAL REWARD
        // ----------------------------------------------------

        let referralResult = {
          applied: false,
          alreadyProcessed: false,
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

        // ====================================================
        // ALL TRANSACTION READS ARE NOW COMPLETE.
        // FIRESTORE WRITES BEGIN BELOW.
        // ====================================================

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
                balanceAfter: newBalance,
                reward: reward.reward,

                createdAt:
                  FieldValue.serverTimestamp(),
              }
            );
          }
        }

        // ----------------------------------------------------
        // START MINING CYCLE
        // ----------------------------------------------------

        const startedAt = now;

        const endsAt = new Date(
          nowMs + MINING_DURATION_MS
        );

        // ----------------------------------------------------
        // AUTOMATIC PREMIUM PLUS POWER BOOST
        // ----------------------------------------------------

        const boostStartedAt = startedAt;
        const boostEndsAt = endsAt;

        const boostDurationMs =
          boostEndsAt.getTime() -
          boostStartedAt.getTime();

        const autoBoostTransactionId =
          `premium-plus-auto-${uid}-${nowMs}`;

        // ----------------------------------------------------
        // UPDATE USER
        // ----------------------------------------------------

        transaction.set(
          userRef,
          {
            hashRate: rate,

            miningHashRate: rate,

            miningStreak: daily.streak,

            lastMiningDate: today,

            miningHalvingMultiplier:
              newMiningHalvingMultiplier,

            miningBalance: newBalance,

            totalMined:
              FieldValue.increment(collected),

            miningStartedAt: startedAt,

            miningEndsAt: endsAt,

            miningCycles:
              achievementResult.miningCycles,

            // Automatic Premium Plus Power Boost.
            adBoostStartedAt: boostStartedAt,

            adBoostEndsAt: boostEndsAt,

            powerBoostTransactionId:
              autoBoostTransactionId,

            // lastAdRewardAt jätetään ennalleen.
            // Automaattinen Premium Plus Boost ei ole
            // AdMob-mainospalkinto eikä muuta jäähdytysaikaa.

            autoMiningLastRunAt:
              FieldValue.serverTimestamp(),

            autoMiningLastCycleEnd:
              hasPreviousCycle
                ? previous.miningEndsAt
                : null,

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
                  : typeof data.lastDailyDate === "string"
                    ? data.lastDailyDate
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

        if (collected > 0) {
          transaction.set(
            getHistoryCollection(uid).doc(
              miningTransactionId
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

              miningTransactionId,

              referralReward:
                referralResult.applied
                  ? referralResult.bonus
                  : 0,

              automaticMining: true,

              createdAt:
                FieldValue.serverTimestamp(),
            }
          );
        }

        // ----------------------------------------------------
        // NEW MINING HISTORY
        // ----------------------------------------------------

        transaction.set(
          getHistoryCollection(uid).doc(),
          {
            type: "mining",

            title:
              "Stella Premium Plus Auto Mining Started 🐱⛏️✨",

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

            rewardPurpose:
              "premium_plus_auto_mining",

            premiumAdFreeMining: true,
            automaticMining: true,

            createdAt:
              FieldValue.serverTimestamp(),
          }
        );

        // ----------------------------------------------------
        // AUTOMATIC POWER BOOST HISTORY
        // ----------------------------------------------------

        transaction.set(
          getHistoryCollection(uid).doc(),
          {
            type: "premium_power_boost",

            title:
              "Stelluriini Premium Plus Automatic Power Boost 🐱⚡",

            amount: 0,

            adRewardTransactionId:
              autoBoostTransactionId,

            rewardPurpose: "power_boost",

            premiumAdFreePowerBoost: true,

            automaticPremiumPlusPowerBoost: true,

            adHashRateBonus:
              AD_HASH_RATE_BONUS,

            boostStartedAt,
            boostEndsAt,

            boostDurationMs,

            miningStartedAt: startedAt,
            miningEndsAt: endsAt,

            miningHashRate: rate,

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
            referralResult.applied
              ? referralResult.bonus
              : 0,

          referralRewarded:
            referralResult.applied === true,

          referralDuplicate:
            referralResult.alreadyProcessed === true,

          miningBalance: newBalance,

          hashRate: rate,

          adHashRateBonus:
            AD_HASH_RATE_BONUS,

          boostDurationMs,

          boostStartedAt:
            boostStartedAt.toISOString(),

          boostEndsAt:
            boostEndsAt.toISOString(),

          miningDay: daily.streak,

          nextDailyHashRate:
            getNextMiningDailyHashRate(
              data,
              today,
              nowMs
            ),

          nextDailyStreak:
            getNextMiningDailyStreak(
              data,
              today,
              nowMs
            ),

          miningStartedAt:
            startedAt.toISOString(),

          miningEndsAt:
            endsAt.toISOString(),
        };
      }
    );
  }


  // ==========================================================
  // EXPORTS
  // ==========================================================

  return {
    processUser,
  };
}


// ============================================================
// MODULE EXPORTS
// ============================================================

module.exports = {
  createAutoMiningService,
};
