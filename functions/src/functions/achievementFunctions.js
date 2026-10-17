"use strict";

// ============================================================
// 🐱 STELLURIINI ACHIEVEMENT FUNCTIONS
// ============================================================
//
// Stella Achievements.
//
// Flutter
//    ↓
// Cloud Function
//    ↓
// Firestore
//
// Achievement-palkinnot maksetaan aina serverillä.
// Serveri on achievementien target- ja reward-arvojen
// lopullinen auktoriteetti.
//
// ============================================================

const {
  onCall,
  HttpsError,
} = require("firebase-functions/v2/https");

const {
  getFirestore,
  FieldValue,
} = require("firebase-admin/firestore");

const db = getFirestore();

// ============================================================
// 🏆 ACHIEVEMENT DEFINITIONS
// ============================================================

const achievements = Object.freeze([
  // ==========================================================
  // 🐾 MINING
  // ==========================================================

  Object.freeze({
    id: "first_paw",
    target: 1,
    reward: 2,
  }),

  Object.freeze({
    id: "little_miner",
    target: 10,
    reward: 5,
  }),

  Object.freeze({
    id: "stl_hunter",
    target: 100,
    reward: 10,
  }),

  Object.freeze({
    id: "growing_miner",
    target: 25,
    reward: 8,
  }),

  Object.freeze({
    id: "stl_collector",
    target: 500,
    reward: 25,
  }),

  Object.freeze({
    id: "stl_master",
    target: 1000,
    reward: 50,
  }),

  Object.freeze({
    id: "dedicated_miner",
    target: 25,
    reward: 30,
  }),

  // ==========================================================
  // 🔥 STREAK
  // ==========================================================

  Object.freeze({
    id: "hot_streak",
    target: 7,
    reward: 50,
  }),

  Object.freeze({
    id: "stella_on_fire",
    target: 14,
    reward: 50,
  }),

  Object.freeze({
    id: "stella_legend",
    target: 30,
    reward: 100,
  }),

  // ==========================================================
  // 🐱 DAILY
  // ==========================================================

  Object.freeze({
    id: "stellas_friend",
    target: 10,
    reward: 30,
  }),

  // ==========================================================
  // ⚡ POWER BOOST
  // ==========================================================

  Object.freeze({
    id: "power_paws",
    target: 5,
    reward: 10,
  }),

  Object.freeze({
    id: "super_paws",
    target: 25,
    reward: 20,
  }),

  // ==========================================================
  // 👥 INVITATIONS
  // ==========================================================

  Object.freeze({
    id: "first_invitation",
    target: 1,
    reward: 5,
  }),

  Object.freeze({
    id: "friend_circle",
    target: 5,
    reward: 10,
  }),

  Object.freeze({
    id: "stellas_community",
    target: 10,
    reward: 20,
  }),

  // ==========================================================
  // ⛏️ LONG-TERM MINING
  // ==========================================================

  Object.freeze({
    id: "seasoned_miner",
    target: 50,
    reward: 40,
  }),

  Object.freeze({
    id: "veteran_miner",
    target: 100,
    reward: 75,
  }),

  // ==========================================================
  // 💎 LONG-TERM STL
  // ==========================================================

  Object.freeze({
    id: "stl_hoarder",
    target: 2500,
    reward: 40,
  }),

  Object.freeze({
    id: "stl_tycoon",
    target: 5000,
    reward: 75,
  }),

  // ==========================================================
  // ⚡ LONG-TERM POWER BOOST
  // ==========================================================

  Object.freeze({
    id: "power_hunter",
    target: 50,
    reward: 30,
  }),

  Object.freeze({
    id: "power_master",
    target: 100,
    reward: 50,
  }),

  // ==========================================================
  // 🐾 LONG-TERM DAILY
  // ==========================================================

  Object.freeze({
    id: "stella_companion",
    target: 30,
    reward: 30,
  }),

  Object.freeze({
    id: "stella_devotee",
    target: 60,
    reward: 60,
  }),

  // ==========================================================
  // 🔥 LONG-TERM STREAK
  // ==========================================================

  Object.freeze({
    id: "stella_eternal",
    target: 60,
    reward: 100,
  }),

  Object.freeze({
    id: "stella_beyond",
    target: 90,
    reward: 200,
  }),
]);

// ============================================================
// 🔎 ACHIEVEMENT DEFINITION LOOKUP
// ============================================================

function getAchievementDefinition(achievementId) {
  if (typeof achievementId !== "string") {
    return null;
  }

  const normalizedId = achievementId.trim();

  if (!normalizedId) {
    return null;
  }

  return (
    achievements.find(
      (achievement) =>
        achievement.id === normalizedId
    ) || null
  );
}

// ============================================================
// 📋 GET ACHIEVEMENT DEFINITIONS
// ============================================================

function getAchievementDefinitions() {
  return achievements.map(
    (achievement) => ({
      ...achievement,
    })
  );
}

// ============================================================
// 👤 USER VALIDATION
// ============================================================

function requireUser(request) {
  const uid = request.auth?.uid;

  if (!uid) {
    throw new HttpsError(
      "unauthenticated",
      "Kirjautuminen vaaditaan."
    );
  }

  return uid;
}

// ============================================================
// 📁 ACHIEVEMENT COLLECTION
// ============================================================

function getAchievementCollection(uid) {
  return db
    .collection("users")
    .doc(uid)
    .collection("achievements");
}

// ============================================================
// 👤 USER REFERENCE
// ============================================================

function getUserRef(uid) {
  return db
    .collection("users")
    .doc(uid);
}

// ============================================================
// 🔢 SAFE INTEGER
// ============================================================

function getSafeInteger(
  value,
  fallback = 0
) {
  const parsed = Number(value);

  if (!Number.isFinite(parsed)) {
    return fallback;
  }

  return Math.floor(parsed);
}

// ============================================================
// 💰 SAFE NON-NEGATIVE NUMBER
// ============================================================

function getSafeBalance(value) {
  const parsed = Number(value);

  if (
    !Number.isFinite(parsed) ||
    parsed < 0
  ) {
    return 0;
  }

  return parsed;
}

// ============================================================
// 📊 NORMALIZE ACHIEVEMENT
// ============================================================

function normalizeAchievement(
  definition,
  data
) {
  const source = data || {};

  const progress = Math.max(
    0,
    getSafeInteger(
      source.progress,
      0
    )
  );

  const target = Math.max(
    1,
    getSafeInteger(
      definition.target,
      1
    )
  );

  const reward = Math.max(
    0,
    Number(definition.reward) || 0
  );

  const normalizedProgress =
    Math.min(
      progress,
      target
    );

  const unlocked =
    source.unlocked === true ||
    normalizedProgress >= target;

  const rewardClaimed =
    source.rewardClaimed === true;

  return {
    achievementId:
      definition.id,

    progress:
      normalizedProgress,

    target,

    reward,

    unlocked,

    rewardClaimed,

    unlockedAt:
      source.unlockedAt ?? null,

    rewardClaimedAt:
      source.rewardClaimedAt ?? null,

    updatedAt:
      source.updatedAt ?? null,
  };
}

// ============================================================
// 📝 BUILD INITIAL ACHIEVEMENT
// ============================================================

function buildInitialAchievement(
  definition,
  now
) {
  return {
    achievementId:
      definition.id,

    progress: 0,

    target:
      definition.target,

    reward:
      definition.reward,

    unlocked: false,

    rewardClaimed: false,

    unlockedAt: null,

    rewardClaimedAt: null,

    updatedAt: now,
  };
}

// ============================================================
// 🔧 BUILD SERVER NORMALIZED UPDATE
// ============================================================

function buildNormalizedUpdate(
  definition,
  data,
  now
) {
  const normalized =
    normalizeAchievement(
      definition,
      data
    );

  const update = {
    achievementId:
      definition.id,

    progress:
      normalized.progress,

    target:
      definition.target,

    reward:
      definition.reward,

    unlocked:
      normalized.unlocked,

    rewardClaimed:
      normalized.rewardClaimed,

    updatedAt: now,
  };

  if (
    normalized.unlocked
  ) {
    update.unlockedAt =
      normalized.unlockedAt ||
      now;
  } else {
    update.unlockedAt =
      normalized.unlockedAt ??
      null;
  }

  update.rewardClaimedAt =
    normalized.rewardClaimedAt ??
    null;

  return update;
}

// ============================================================
// 🎁 ACHIEVEMENT REWARD CALCULATION
// ============================================================

function calculateAchievementReward(
  definition,
  existingData,
  newProgress,
  now
) {
  const normalized =
    normalizeAchievement(
      definition,
      existingData
    );

  const oldProgress =
    normalized.progress;

  const safeProgress =
    Math.min(
      normalized.target,
      Math.max(
        oldProgress,
        getSafeInteger(
          newProgress,
          oldProgress
        )
      )
    );

  const wasUnlocked =
    normalized.unlocked === true;

  const wasRewardClaimed =
    normalized.rewardClaimed === true;

  const isNowUnlocked =
    wasUnlocked ||
    safeProgress >=
      normalized.target;

  const shouldPayReward =
    isNowUnlocked &&
    !wasRewardClaimed;

  const reward =
    shouldPayReward
      ? normalized.reward
      : 0;

  return {
    achievementId:
      definition.id,

    oldProgress,

    progress:
      safeProgress,

    target:
      normalized.target,

    reward:
      normalized.reward,

    rewardToCredit:
      reward,

    unlocked:
      isNowUnlocked,

    rewardClaimed:
      wasRewardClaimed ||
      shouldPayReward,

    wasUnlocked,

    wasRewardClaimed,

    newlyUnlocked:
      !wasUnlocked &&
      isNowUnlocked,

    shouldPayReward,

    unlockedAt:
      normalized.unlockedAt ||
      (
        isNowUnlocked
          ? now
          : null
      ),

    rewardClaimedAt:
      wasRewardClaimed
        ? normalized.rewardClaimedAt
        : shouldPayReward
          ? now
          : null,

    updatedAt: now,
  };
}

// ============================================================
// 🎁 BUILD ACHIEVEMENT REWARD UPDATE
// ============================================================

function buildAchievementRewardUpdate(
  calculation
) {
  return {
    achievementId:
      calculation.achievementId,

    progress:
      calculation.progress,

    target:
      calculation.target,

    reward:
      calculation.reward,

    unlocked:
      calculation.unlocked,

    rewardClaimed:
      calculation.rewardClaimed,

    unlockedAt:
      calculation.unlockedAt,

    rewardClaimedAt:
      calculation.rewardClaimedAt,

    updatedAt:
      calculation.updatedAt,
  };
}

// ============================================================
// 💰 BUILD USER BALANCE UPDATE
// ============================================================

function buildAchievementBalanceUpdate(
  reward,
  now
) {
  const safeReward =
    Math.max(
      0,
      Number(reward) || 0
    );

  if (safeReward <= 0) {
    return null;
  }

  return {
    miningBalance:
      FieldValue.increment(
        safeReward
      ),

    updatedAt: now,
  };
}

// ============================================================
// 🐱 APPLY ACHIEVEMENT PROGRESS
// ============================================================

function applyAchievementProgress(
  transaction,
  uid,
  achievementId,
  existingData,
  newProgress,
  now
) {
  const definition =
    getAchievementDefinition(
      achievementId
    );

  if (!definition) {
    throw new Error(
      `Unknown achievement: ${achievementId}`
    );
  }

  const calculation =
    calculateAchievementReward(
      definition,
      existingData,
      newProgress,
      now
    );

  const achievementRef =
    getAchievementCollection(uid)
      .doc(
        definition.id
      );

  const achievementUpdate =
    buildAchievementRewardUpdate(
      calculation
    );

  transaction.set(
    achievementRef,
    achievementUpdate,
    {
      merge: true,
    }
  );

  if (
    calculation.rewardToCredit > 0
  ) {
    const userRef =
      getUserRef(uid);

    const balanceUpdate =
      buildAchievementBalanceUpdate(
        calculation.rewardToCredit,
        now
      );

    transaction.set(
      userRef,
      balanceUpdate,
      {
        merge: true,
      }
    );
  }

  return calculation;
}

// ============================================================
// 📖 GET ACHIEVEMENTS
// ============================================================

exports.getAchievements =
  onCall(
    {
      region:
        "us-central1",
    },

    async (request) => {
      try {
        const uid =
          requireUser(
            request
          );

        const collection =
          getAchievementCollection(
            uid
          );

        const snapshot =
          await collection.get();

        const existing =
          new Map();

        for (
          const document of snapshot.docs
        ) {
          existing.set(
            document.id,
            document.data() || {}
          );
        }

        const batch =
          db.batch();

        const now =
          new Date();

        const result = [];

        let batchHasWrites =
          false;

        for (
          const definition of achievements
        ) {
          const existingData =
            existing.get(
              definition.id
            );

          const document =
            collection.doc(
              definition.id
            );

          if (!existingData) {
            const initialData =
              buildInitialAchievement(
                definition,
                now
              );

            batch.set(
              document,
              initialData
            );

            batchHasWrites =
              true;

            result.push(
              initialData
            );

            continue;
          }

          const normalized =
            buildNormalizedUpdate(
              definition,
              existingData,
              now
            );

          const current =
            normalizeAchievement(
              definition,
              existingData
            );

          const needsUpdate =
            current.progress !==
              normalized.progress ||

            current.target !==
              normalized.target ||

            current.reward !==
              normalized.reward ||

            current.unlocked !==
              normalized.unlocked ||

            current.rewardClaimed !==
              normalized.rewardClaimed ||

            (
              normalized.unlockedAt &&
              !current.unlockedAt
            );

          if (
            needsUpdate
          ) {
            batch.set(
              document,
              normalized,
              {
                merge: true,
              }
            );

            batchHasWrites =
              true;
          }

          result.push(
            normalized
          );
        }

        if (
          batchHasWrites
        ) {
          await batch.commit();
        }

        return {
          success: true,

          achievements:
            result,

          completed:
            result.filter(
              (achievement) =>
                achievement.unlocked ===
                true
            ).length,

          total:
            achievements.length,
        };
      } catch (error) {
        console.error(
          "getAchievements error:",
          error
        );

        if (
          error instanceof HttpsError
        ) {
          throw error;
        }

        throw new HttpsError(
          "internal",
          "🐱 Achievements-tietojen lataaminen epäonnistui."
        );
      }
    }
  );

// ============================================================
// 📊 GET ACHIEVEMENT COMPLETION COUNT
// ============================================================

exports.getAchievementsCompleted =
  onCall(
    {
      region:
        "us-central1",
    },

    async (request) => {
      try {
        const uid =
          requireUser(
            request
          );

        const collection =
          getAchievementCollection(
            uid
          );

        const snapshot =
          await collection.get();

        const unlockedIds =
          new Set();

        for (
          const document of snapshot.docs
        ) {
          const definition =
            getAchievementDefinition(
              document.id
            );

          if (!definition) {
            continue;
          }

          const normalized =
            normalizeAchievement(
              definition,
              document.data() || {}
            );

          if (
            normalized.unlocked
          ) {
            unlockedIds.add(
              definition.id
            );
          }
        }

        return {
          success: true,

          completed:
            unlockedIds.size,

          total:
            achievements.length,
        };
      } catch (error) {
        console.error(
          "getAchievementsCompleted error:",
          error
        );

        if (
          error instanceof HttpsError
        ) {
          throw error;
        }

        throw new HttpsError(
          "internal",
          "🐱 Achievementien valmistumistietojen lataaminen epäonnistui."
        );
      }
    }
  );

// ============================================================
// 📦 SERVER-SIDE EXPORTS
// ============================================================

module.exports.getAchievementDefinition =
  getAchievementDefinition;

module.exports.getAchievementDefinitions =
  getAchievementDefinitions;

module.exports.calculateAchievementReward =
  calculateAchievementReward;

module.exports.buildAchievementRewardUpdate =
  buildAchievementRewardUpdate;

module.exports.buildAchievementBalanceUpdate =
  buildAchievementBalanceUpdate;

module.exports.applyAchievementProgress =
  applyAchievementProgress;