
"use strict";

// ============================================================
// 🐱 STELLURIINI DAILY FUNCTIONS
// ============================================================
//
// Stella Daily Hash Rate + Daily Achievements
//
// Daily Check-In:
// - Päivittää päivittäisen Hash Raten.
// - Päivittää peräkkäisten kirjautumisten putken.
// - Laskee päivittäisten kirjautumisten kokonaismäärän.
// - Päivittää päivittäiset saavutukset.
// - Maksaa saavutuspalkkiot vain kerran.
//
// Daily Check-In ei:
// - Käynnistä Mining Startia.
// - Aktivoi Power Boostia.
// - Muuta aktiivisen mining-jakson Hash Ratea.
// - Käsittele AdMob SSV:tä.
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
// ⚙️ MINING CONFIG
// ============================================================

const {
  DAILY_HASH_RATE_START,
  DAILY_HASH_RATE_STEP,
  DAILY_HASH_RATE_MAX_DAY,
  MAX_DAILY_HASH_RATE,
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
// 🏆 ACHIEVEMENT FUNCTIONS
// ============================================================

const {
  getAchievementDefinition,
  calculateAchievementReward,
  buildAchievementRewardUpdate,
} = require("./achievementFunctions");


// ============================================================
// 🔢 SAFE NUMBER
// ============================================================

function getSafeNumber(value, fallback = 0) {
  const parsed = Number(value);

  return Number.isFinite(parsed)
    ? parsed
    : fallback;
}


// ============================================================
// 🎁 CALCULATE DAILY HASH RATE
// ============================================================

function calculateDailyHashRate(streak) {
  const safeStreak = Math.max(
    1,
    Math.floor(getSafeNumber(streak, 1))
  );

  const effectiveDay = Math.min(
    safeStreak,
    DAILY_HASH_RATE_MAX_DAY
  );

  const hashRate =
    DAILY_HASH_RATE_START +
    ((effectiveDay - 1) * DAILY_HASH_RATE_STEP);

  return Math.min(
    MAX_DAILY_HASH_RATE,
    Math.max(DAILY_HASH_RATE_START, hashRate)
  );
}


// ============================================================
// 📅 GET PREVIOUS UTC DATE
// ============================================================

function getPreviousUtcDate(dateString) {
  if (
    typeof dateString !== "string" ||
    !/^\d{4}-\d{2}-\d{2}$/.test(dateString)
  ) {
    return "";
  }

  const date = new Date(
    `${dateString}T00:00:00.000Z`
  );

  if (Number.isNaN(date.getTime())) {
    return "";
  }

  date.setUTCDate(date.getUTCDate() - 1);

  return date.toISOString().slice(0, 10);
}


// ============================================================
// 🎁 GET STORED DAILY STREAK
// ============================================================

function getStoredDailyStreak(data) {
  const stored =
    data.dailyStreak ??
    data.streak ??
    0;

  return Math.max(
    0,
    Math.floor(getSafeNumber(stored, 0))
  );
}


// ============================================================
// 🎁 CALCULATE DAILY CHECK-IN
// ============================================================

function calculateDailyCheckIn(data, today) {
  const lastDailyDate =
    typeof data.lastDailyDate === "string"
      ? data.lastDailyDate
      : "";

  const storedStreak =
    getStoredDailyStreak(data);

  // Already claimed today.
  if (lastDailyDate === today) {
    const streak = Math.max(1, storedStreak);

    return {
      alreadyClaimed: true,
      streak,
      dailyHashRate: calculateDailyHashRate(streak),
    };
  }

  const yesterday = getPreviousUtcDate(today);

  let streak = 1;

  if (
    lastDailyDate === yesterday &&
    storedStreak > 0
  ) {
    streak = storedStreak + 1;
  }

  return {
    alreadyClaimed: false,
    streak,
    dailyHashRate: calculateDailyHashRate(streak),
  };
}


// ============================================================
// 🏆 DAILY ACHIEVEMENT DEFINITIONS
// ============================================================

const DAILY_ACHIEVEMENT_IDS = Object.freeze([
  "stellas_friend",
  "stella_companion",
  "stella_devotee",
  "hot_streak",
  "stella_on_fire",
  "stella_legend",
  "stella_eternal",
  "stella_beyond",
]);


// ============================================================
// 🏆 UPDATE DAILY ACHIEVEMENTS
// ============================================================
//
// Kaikki achievement-dokumentit luetaan ennen ensimmäistä
// Firestore-kirjoitusta.
//
// Tämä on tärkeää Firestore-transaktion toiminnan kannalta.
//
// ============================================================

async function updateDailyAchievements(
  transaction,
  uid,
  data,
  streak,
  now
) {
  const achievementCollection =
    getUserRef(uid).collection("achievements");

  const definitions =
    DAILY_ACHIEVEMENT_IDS
      .map((id) => getAchievementDefinition(id))
      .filter(Boolean);

  const achievementSnapshots = [];

  // Read all achievement documents first.
  for (const definition of definitions) {
    const ref = achievementCollection.doc(definition.id);

    const snapshot = await transaction.get(ref);

    achievementSnapshots.push({
      definition,
      ref,
      data: snapshot.exists
        ? snapshot.data() || {}
        : {},
    });
  }

  const newDailyCheckIns =
    Math.max(
      0,
      Math.floor(getSafeNumber(data.dailyCheckIns, 0))
    ) + 1;

  let totalReward = 0;

  const updates = [];

  for (const item of achievementSnapshots) {
    const {
      definition,
      ref,
      data: existingData,
    } = item;

    let progress = 0;

    // Cumulative daily check-ins.
    if (
      definition.id === "stellas_friend" ||
      definition.id === "stella_companion" ||
      definition.id === "stella_devotee"
    ) {
      progress = newDailyCheckIns;
    }

    // Consecutive daily check-in streak.
    if (
      definition.id === "hot_streak" ||
      definition.id === "stella_on_fire" ||
      definition.id === "stella_legend" ||
      definition.id === "stella_eternal" ||
      definition.id === "stella_beyond"
    ) {
      progress = streak;
    }

    const calculation =
      calculateAchievementReward(
        definition,
        existingData,
        progress,
        now
      );

    const update =
      buildAchievementRewardUpdate(calculation);

    if (calculation.rewardToCredit > 0) {
      totalReward += calculation.rewardToCredit;
    }

    updates.push({
      ref,
      update,
      achievementId: definition.id,
      reward: calculation.rewardToCredit,
      newlyUnlocked: calculation.newlyUnlocked,
    });
  }

  return {
    dailyCheckIns: newDailyCheckIns,
    totalReward,
    updates,
  };
}


// ============================================================
// 🐱 DAILY CHECK-IN
// ============================================================

const dailyCheckIn = onCall(
  {
    region: "us-central1",
  },

  async (request) => {
    try {
      // ======================================================
      // 🔐 AUTHENTICATION
      // ======================================================

      if (!request.auth) {
        throw new HttpsError(
          "unauthenticated",
          "🐱 Kirjaudu sisään käyttääksesi Stella Daily Check-Iniä."
        );
      }

      const uid = request.auth.uid;

      const userRef = getUserRef(uid);


      // ======================================================
      // 📅 CURRENT UTC DATE
      // ======================================================

      const now = new Date();

      const today = getUtcDateString(now);

      if (
        typeof today !== "string" ||
        !/^\d{4}-\d{2}-\d{2}$/.test(today)
      ) {
        throw new HttpsError(
          "internal",
          "🐱 Päivämäärän määrittäminen epäonnistui."
        );
      }


      // ======================================================
      // 🔐 FIRESTORE TRANSACTION
      // ======================================================

      return await db.runTransaction(
        async (transaction) => {
          const snapshot = await transaction.get(userRef);

          const data = snapshot.exists
            ? snapshot.data() || {}
            : {};


          // ==================================================
          // 🎁 CALCULATE DAILY STATE
          // ==================================================

          const daily = calculateDailyCheckIn(
            data,
            today
          );


          // ==================================================
          // 🚫 ALREADY CLAIMED TODAY
          // ==================================================

          if (daily.alreadyClaimed) {
            return {
              success: true,
              claimed: false,
              alreadyClaimed: true,
              dailyClaimed: true,

              streak: daily.streak,
              dailyStreak: daily.streak,
              dailyHashRate: daily.dailyHashRate,

              hashRate: daily.dailyHashRate,

              message:
                "🐱✨ Stella on jo saanut tämän päivän Daily Hash Raten.",
            };
          }


          // ==================================================
          // 📊 PREVIOUS DAILY HASH RATE
          // ==================================================

          const oldDailyHashRate = Math.max(
            0,
            getSafeNumber(data.dailyHashRate, 0)
          );


          // ==================================================
          // 🏆 PREPARE ACHIEVEMENTS
          // ==================================================

          const achievementResult =
            await updateDailyAchievements(
              transaction,
              uid,
              data,
              daily.streak,
              now
            );


          // ==================================================
          // 👤 USER UPDATE
          // ==================================================

          const userUpdate = {
            dailyHashRate: daily.dailyHashRate,

            dailyStreak: daily.streak,
            streak: daily.streak,

            lastDailyDate: today,

            dailyCheckIns:
              achievementResult.dailyCheckIns,

            updatedAt:
              FieldValue.serverTimestamp(),
          };

          // Credit achievement rewards only when earned.
          if (achievementResult.totalReward > 0) {
            userUpdate.miningBalance =
              FieldValue.increment(
                achievementResult.totalReward
              );
          }

          transaction.set(
            userRef,
            userUpdate,
            {
              merge: true,
            }
          );


          // ==================================================
          // 🏆 SAVE ACHIEVEMENTS
          // ==================================================

          for (const item of achievementResult.updates) {
            transaction.set(
              item.ref,
              item.update,
              {
                merge: true,
              }
            );
          }


          // ==================================================
          // 📜 DAILY HASH RATE HISTORY
          // ==================================================

          const historyCollection =
            getHistoryCollection(uid);

          const historyRef =
            historyCollection.doc();

          transaction.set(
            historyRef,
            {
              type: "dailyHashRate",

              title: "Stella Daily Hash Rate 🐱✨",

              amount: 0,

              hashRate: daily.dailyHashRate,
              dailyHashRate: daily.dailyHashRate,

              hashRateBefore: oldDailyHashRate,
              hashRateAfter: daily.dailyHashRate,

              dailyHashRateBefore: oldDailyHashRate,
              dailyHashRateAfter: daily.dailyHashRate,

              dailyStreak: daily.streak,
              streak: daily.streak,

              createdAt:
                FieldValue.serverTimestamp(),
            }
          );


          // ==================================================
          // 🎁 ACHIEVEMENT REWARD HISTORY
          // ==================================================

          if (achievementResult.totalReward > 0) {
            const rewardHistoryRef =
              historyCollection.doc();

            transaction.set(
              rewardHistoryRef,
              {
                type: "achievementReward",

                title: "Stella Achievement Reward 🏆",

                amount: achievementResult.totalReward,

                rewards:
                  achievementResult.updates
                    .filter((item) => item.reward > 0)
                    .map((item) => ({
                      achievementId: item.achievementId,
                      reward: item.reward,
                      newlyUnlocked: item.newlyUnlocked,
                    })),

                createdAt:
                  FieldValue.serverTimestamp(),
              }
            );
          }


          // ==================================================
          // ✅ RESPONSE
          // ==================================================

          return {
            success: true,

            claimed: true,
            alreadyClaimed: false,
            dailyClaimed: true,

            streak: daily.streak,
            dailyStreak: daily.streak,

            dailyHashRate: daily.dailyHashRate,
            hashRate: daily.dailyHashRate,

            previousHashRate: oldDailyHashRate,
            previousDailyHashRate: oldDailyHashRate,

            hashRateIncrease: Math.max(
              0,
              daily.dailyHashRate - oldDailyHashRate
            ),

            dailyHashRateIncrease: Math.max(
              0,
              daily.dailyHashRate - oldDailyHashRate
            ),

            dailyCheckIns:
              achievementResult.dailyCheckIns,

            achievementReward:
              achievementResult.totalReward,

            unlockedAchievements:
              achievementResult.updates
                .filter((item) => item.newlyUnlocked)
                .map((item) => item.achievementId),

            message:
              `🐱✨ Stella sai päivän ${daily.streak} Daily Hash Raten: ${daily.dailyHashRate.toFixed(4)} HR!`,
          };
        }
      );
    } catch (error) {
      // ======================================================
      // ❌ ERROR
      // ======================================================

      console.error(
        "dailyCheckIn error:",
        error
      );

      if (error instanceof HttpsError) {
        throw error;
      }

      throw new HttpsError(
        "internal",
        "🐱 Stella Daily Check-Inin käsittely epäonnistui."
      );
    }
  }
);


// ============================================================
// 📦 EXPORTS
// ============================================================

module.exports = {
  dailyCheckIn,
};
