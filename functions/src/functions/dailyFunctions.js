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
// Päiväputken sääntö:
// - Aktiivisen louhinnan aikana päiväputki säilyy.
// - Louhinnan päätyttyä alkaa 24 tunnin armonaika.
// - Armonaikana uusi Daily Check-In jatkaa päiväputkea.
// - Armonaikaa myöhemmin päiväputki alkaa päivästä 1.
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
// 🎁 DAILY MINING UTILITIES
// ============================================================

const {
  nextDailyClaim,
} = require("../utils/mining/dailyMiningUtils");


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
// 🎁 CALCULATE DAILY CHECK-IN
// ============================================================
//
// Käytetään samaa louhintajaksoon sidottua sääntöä
// kuin dailyMiningUtils-apufunktioissa.
//
// Armonaika lasketaan miningEndsAt-ajasta.
//
// ============================================================

function calculateDailyCheckIn(data, today, nowMs) {
  const daily = nextDailyClaim(
    data,
    today,
    nowMs
  );

  return {
    alreadyClaimed: daily.claimedToday,
    streak: daily.streak,
    dailyHashRate: daily.dailyHashRate,
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
          //
          // Armonaika tarkistetaan nykyisen ajan ja
          // miningEndsAt-arvon perusteella.
          //
          // ==================================================

          const daily = calculateDailyCheckIn(
            data,
            today,
            now.getTime()
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