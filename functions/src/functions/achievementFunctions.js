"use strict";

const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");

const db = getFirestore();

const achievements = Object.freeze([
  Object.freeze({ id: "first_paw", target: 1, reward: 2 }),
  Object.freeze({ id: "little_miner", target: 10, reward: 5 }),
  Object.freeze({ id: "stl_hunter", target: 100, reward: 10 }),
  Object.freeze({ id: "growing_miner", target: 25, reward: 8 }),
  Object.freeze({ id: "stl_collector", target: 500, reward: 25 }),
  Object.freeze({ id: "stl_master", target: 1000, reward: 50 }),
  Object.freeze({ id: "dedicated_miner", target: 25, reward: 30 }),
  Object.freeze({ id: "hot_streak", target: 7, reward: 50 }),
  Object.freeze({ id: "stella_on_fire", target: 14, reward: 50 }),
  Object.freeze({ id: "stella_legend", target: 30, reward: 100 }),
  Object.freeze({ id: "stellas_friend", target: 10, reward: 30 }),
  Object.freeze({ id: "power_paws", target: 5, reward: 10 }),
  Object.freeze({ id: "super_paws", target: 25, reward: 20 }),
  Object.freeze({ id: "first_invitation", target: 1, reward: 5 }),
  Object.freeze({ id: "friend_circle", target: 5, reward: 10 }),
  Object.freeze({ id: "stellas_community", target: 10, reward: 20 }),
  Object.freeze({ id: "seasoned_miner", target: 50, reward: 40 }),
  Object.freeze({ id: "veteran_miner", target: 100, reward: 75 }),
  Object.freeze({ id: "stl_hoarder", target: 2500, reward: 40 }),
  Object.freeze({ id: "stl_tycoon", target: 5000, reward: 75 }),
  Object.freeze({ id: "power_hunter", target: 50, reward: 30 }),
  Object.freeze({ id: "power_master", target: 100, reward: 50 }),
  Object.freeze({ id: "stella_companion", target: 30, reward: 30 }),
  Object.freeze({ id: "stella_devotee", target: 60, reward: 60 }),
  Object.freeze({ id: "stella_eternal", target: 60, reward: 100 }),
  Object.freeze({ id: "stella_beyond", target: 90, reward: 200 }),
]);

function getAchievementDefinition(achievementId) {
  if (typeof achievementId !== "string") return null;
  const normalizedId = achievementId.trim();
  if (!normalizedId) return null;
  return achievements.find((item) => item.id === normalizedId) || null;
}

function getAchievementDefinitions() {
  return achievements.map((item) => ({ ...item }));
}

function requireUser(request) {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "Kirjautuminen vaaditaan.");
  }
  return uid;
}

function getAchievementCollection(uid) {
  return db.collection("users").doc(uid).collection("achievements");
}

function getUserRef(uid) {
  return db.collection("users").doc(uid);
}

function getSafeInteger(value, fallback = 0) {
  const parsed = Number(value);
  if (!Number.isFinite(parsed)) return fallback;
  return Math.max(0, Math.floor(parsed));
}

function getSafeBalance(value) {
  const parsed = Number(value);
  if (!Number.isFinite(parsed) || parsed < 0) return 0;
  return parsed;
}

function normalizeAchievement(definition, data) {
  const source = data || {};
  const progress = Math.max(0, getSafeInteger(source.progress, 0));
  const target = Math.max(1, getSafeInteger(definition.target, 1));
  const reward = Math.max(0, Number(definition.reward) || 0);
  const normalizedProgress = Math.min(progress, target);
  const unlocked =
    source.unlocked === true || normalizedProgress >= target;
  const rewardClaimed = source.rewardClaimed === true;

  return {
    achievementId: definition.id,
    progress: normalizedProgress,
    target,
    reward,
    unlocked,
    rewardClaimed,
    unlockedAt: source.unlockedAt ?? null,
    rewardClaimedAt: source.rewardClaimedAt ?? null,
    updatedAt: source.updatedAt ?? null,
  };
}

function buildInitialAchievement(definition, now, progress = 0) {
  const safeProgress = Math.min(
    definition.target,
    getSafeInteger(progress)
  );
  const unlocked = safeProgress >= definition.target;

  return {
    achievementId: definition.id,
    progress: safeProgress,
    target: definition.target,
    reward: definition.reward,
    unlocked,
    rewardClaimed: false,
    unlockedAt: unlocked ? now : null,
    rewardClaimedAt: null,
    updatedAt: now,
  };
}

function buildNormalizedUpdate(
  definition,
  data,
  now,
  historicalProgress = 0
) {
  const normalized = normalizeAchievement(definition, data);
  const progress = Math.min(
    definition.target,
    Math.max(
      normalized.progress,
      getSafeInteger(historicalProgress)
    )
  );
  const unlocked =
    normalized.unlocked || progress >= definition.target;

  const update = {
    achievementId: definition.id,
    progress,
    target: definition.target,
    reward: definition.reward,
    unlocked,
    rewardClaimed: normalized.rewardClaimed,
    updatedAt: now,
  };

  update.unlockedAt =
    normalized.unlockedAt || (unlocked ? now : null);
  update.rewardClaimedAt = normalized.rewardClaimedAt;
  return update;
}

// STL achievement progress is based only on lifetime mined STL.
// miningBalance may also contain achievement and referral rewards.
function getHistoricalAchievementProgress(definition, userData) {
  const data = userData || {};
  const totalMined = getSafeBalance(data.totalMined);
  const miningCycles = getSafeInteger(data.miningCycles);
  const dailyCheckIns = getSafeInteger(data.dailyCheckIns);
  const dailyStreak = Math.max(
    getSafeInteger(data.dailyStreak),
    getSafeInteger(data.streak)
  );
  const powerBoostCount = getSafeInteger(data.powerBoostCount);

  switch (definition.id) {
    case "first_paw":
      return miningCycles > 0 ? 1 : 0;

    case "little_miner":
    case "stl_hunter":
    case "growing_miner":
    case "stl_collector":
    case "stl_master":
    case "stl_hoarder":
    case "stl_tycoon":
      return totalMined;

    case "dedicated_miner":
    case "seasoned_miner":
    case "veteran_miner":
      return miningCycles;

    case "hot_streak":
    case "stella_on_fire":
    case "stella_legend":
    case "stella_eternal":
    case "stella_beyond":
      return dailyStreak;

    case "stellas_friend":
    case "stella_companion":
    case "stella_devotee":
      return dailyCheckIns;

    case "power_paws":
    case "super_paws":
    case "power_hunter":
    case "power_master":
      return powerBoostCount;

    case "first_invitation":
    case "friend_circle":
    case "stellas_community":
      return 0;

    default:
      return 0;
  }
}

function calculateAchievementReward(
  definition,
  existingData,
  newProgress,
  now
) {
  const normalized = normalizeAchievement(definition, existingData);
  const oldProgress = normalized.progress;
  const safeProgress = Math.min(
    normalized.target,
    Math.max(
      oldProgress,
      getSafeInteger(newProgress, oldProgress)
    )
  );
  const wasUnlocked = normalized.unlocked === true;
  const wasRewardClaimed = normalized.rewardClaimed === true;
  const isNowUnlocked =
    wasUnlocked || safeProgress >= normalized.target;
  const shouldPayReward = isNowUnlocked && !wasRewardClaimed;
  const reward = shouldPayReward ? normalized.reward : 0;

  return {
    achievementId: definition.id,
    oldProgress,
    progress: safeProgress,
    target: normalized.target,
    reward: normalized.reward,
    rewardToCredit: reward,
    unlocked: isNowUnlocked,
    rewardClaimed: wasRewardClaimed || shouldPayReward,
    wasUnlocked,
    wasRewardClaimed,
    newlyUnlocked: !wasUnlocked && isNowUnlocked,
    shouldPayReward,
    unlockedAt:
      normalized.unlockedAt || (isNowUnlocked ? now : null),
    rewardClaimedAt: wasRewardClaimed
      ? normalized.rewardClaimedAt
      : shouldPayReward
        ? now
        : null,
    updatedAt: now,
  };
}

function buildAchievementRewardUpdate(calculation) {
  return {
    achievementId: calculation.achievementId,
    progress: calculation.progress,
    target: calculation.target,
    reward: calculation.reward,
    unlocked: calculation.unlocked,
    rewardClaimed: calculation.rewardClaimed,
    unlockedAt: calculation.unlockedAt,
    rewardClaimedAt: calculation.rewardClaimedAt,
    updatedAt: calculation.updatedAt,
  };
}

function buildAchievementBalanceUpdate(reward, now) {
  const safeReward = Math.max(0, Number(reward) || 0);
  if (safeReward <= 0) return null;

  return {
    miningBalance: FieldValue.increment(safeReward),
    updatedAt: now,
  };
}

function applyAchievementProgress(
  transaction,
  uid,
  achievementId,
  existingData,
  newProgress,
  now
) {
  const definition = getAchievementDefinition(achievementId);
  if (!definition) {
    throw new Error(`Unknown achievement: ${achievementId}`);
  }

  const calculation = calculateAchievementReward(
    definition,
    existingData,
    newProgress,
    now
  );
  const achievementRef = getAchievementCollection(uid).doc(definition.id);
  const achievementUpdate = buildAchievementRewardUpdate(calculation);

  transaction.set(achievementRef, achievementUpdate, { merge: true });

  if (calculation.rewardToCredit > 0) {
    const userRef = getUserRef(uid);
    const balanceUpdate = buildAchievementBalanceUpdate(
      calculation.rewardToCredit,
      now
    );
    transaction.set(userRef, balanceUpdate, { merge: true });
  }

  return calculation;
}

exports.getAchievements = onCall(
  { region: "us-central1" },
  async (request) => {
    try {
      const uid = requireUser(request);
      const userRef = getUserRef(uid);
      const collection = getAchievementCollection(uid);

      const userSnapshot = await userRef.get();
      const userData = userSnapshot.exists
        ? userSnapshot.data() || {}
        : {};

      const snapshot = await collection.get();
      const existing = new Map();

      for (const document of snapshot.docs) {
        existing.set(document.id, document.data() || {});
      }

      const batch = db.batch();
      const now = new Date();
      const result = [];
      let batchHasWrites = false;

      for (const definition of achievements) {
        const existingData = existing.get(definition.id);
        const document = collection.doc(definition.id);
        const historicalProgress =
          getHistoricalAchievementProgress(definition, userData);

        if (!existingData) {
          const initialData = buildInitialAchievement(
            definition,
            now,
            historicalProgress
          );
          batch.set(document, initialData);
          batchHasWrites = true;
          result.push(initialData);
          continue;
        }

        const normalized = buildNormalizedUpdate(
          definition,
          existingData,
          now,
          historicalProgress
        );
        const current = normalizeAchievement(
          definition,
          existingData
        );

        const needsUpdate =
          current.progress !== normalized.progress ||
          current.target !== normalized.target ||
          current.reward !== normalized.reward ||
          current.unlocked !== normalized.unlocked ||
          current.rewardClaimed !== normalized.rewardClaimed ||
          (normalized.unlockedAt && !current.unlockedAt);

        if (needsUpdate) {
          batch.set(document, normalized, { merge: true });
          batchHasWrites = true;
        }

        result.push(normalized);
      }

      if (batchHasWrites) {
        await batch.commit();
      }

      const completed = result.filter(
        (achievement) => achievement.unlocked === true
      ).length;

      return {
        success: true,
        achievements: result,
        completed,
        total: achievements.length,
        miningBalance: getSafeBalance(userData.miningBalance),
        totalMined: getSafeBalance(userData.totalMined),
        miningCycles: getSafeInteger(userData.miningCycles),
        dailyCheckIns: getSafeInteger(userData.dailyCheckIns),
        powerBoostCount: getSafeInteger(userData.powerBoostCount),
      };
    } catch (error) {
      console.error("getAchievements error:", error);
      if (error instanceof HttpsError) throw error;

      throw new HttpsError(
        "internal",
        "🐱 Achievements-tietojen lataaminen epäonnistui."
      );
    }
  }
);

exports.getAchievementsCompleted = onCall(
  { region: "us-central1" },
  async (request) => {
    try {
      const uid = requireUser(request);
      const collection = getAchievementCollection(uid);
      const snapshot = await collection.get();
      const unlockedIds = new Set();

      for (const document of snapshot.docs) {
        const definition = getAchievementDefinition(document.id);
        if (!definition) continue;

        const normalized = normalizeAchievement(
          definition,
          document.data() || {}
        );

        if (normalized.unlocked) {
          unlockedIds.add(definition.id);
        }
      }

      return {
        success: true,
        completed: unlockedIds.size,
        total: achievements.length,
      };
    } catch (error) {
      console.error("getAchievementsCompleted error:", error);
      if (error instanceof HttpsError) throw error;

      throw new HttpsError(
        "internal",
        "🐱 Achievementien valmistumistietojen lataaminen epäonnistui."
      );
    }
  }
);

module.exports.getAchievementDefinition = getAchievementDefinition;
module.exports.getAchievementDefinitions = getAchievementDefinitions;
module.exports.calculateAchievementReward = calculateAchievementReward;
module.exports.buildAchievementRewardUpdate = buildAchievementRewardUpdate;
module.exports.buildAchievementBalanceUpdate = buildAchievementBalanceUpdate;
module.exports.applyAchievementProgress = applyAchievementProgress;
module.exports.getHistoricalAchievementProgress =
  getHistoricalAchievementProgress;
