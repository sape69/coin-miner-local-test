
"use strict";

// ============================================================
// 🐱 STELLURIINI - MINING ACHIEVEMENT SERVICE
// ============================================================
//
// Saavutusten lukeminen, etenemisen laskenta ja tallennus.
//
// Tämä palvelu:
// - Lukee käyttäjän saavutukset Firestore-transaktion kautta.
// - Laskee saavutusten etenemisen.
// - Tunnistaa uudet saavutukset.
// - Laskee saavutuspalkkiot.
// - Valmistelee Firestore-päivitykset.
//
// Tämä tiedosto ei itse päivitä käyttäjän miningBalance-saldoa.
// ============================================================

const {
  getUserRef,
} = require("../utils/userUtils");

const {
  getAchievementDefinition,
} = require("../functions/achievementFunctions");

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
// ACHIEVEMENT COLLECTION
// ============================================================

function achievementCollection(uid) {
  return getUserRef(uid)
    .collection("achievements");
}

// ============================================================
// READ ACHIEVEMENT DATA
// ============================================================

async function readAchievementData(
  transaction,
  uid,
  definitions
) {
  const items = [];

  for (const definition of definitions) {
    const ref =
      achievementCollection(uid)
        .doc(definition.id);

    const snapshot =
      await transaction.get(ref);

    items.push({
      definition,
      ref,
      data:
        snapshot.exists
          ? snapshot.data() || {}
          : {},
    });
  }

  return items;
}

// ============================================================
// ACHIEVEMENT UPDATE
// ============================================================

function achievementUpdate(
  definition,
  progress,
  existing,
  now
) {
  const oldProgress =
    Math.max(
      0,
      number(existing.progress)
    );

  const safeTarget =
    Math.max(
      0,
      number(definition.target)
    );

  const safeReward =
    Math.max(
      0,
      number(definition.reward)
    );

  const safeProgress =
    Math.min(
      safeTarget,
      Math.max(
        oldProgress,
        nonNegative(progress)
      )
    );

  const alreadyUnlocked =
    existing.unlocked === true;

  const unlocked =
    alreadyUnlocked ||
    (
      safeTarget > 0 &&
      safeProgress >= safeTarget
    );

  const rewardClaimed =
    existing.rewardClaimed === true;

  const update = {
    achievementId: definition.id,
    progress: safeProgress,
    target: safeTarget,
    reward: safeReward,
    unlocked,
    rewardClaimed,
    updatedAt: now,
  };

  if (
    unlocked &&
    !alreadyUnlocked &&
    !existing.unlockedAt
  ) {
    update.unlockedAt = now;
  } else if (existing.unlockedAt) {
    update.unlockedAt =
      existing.unlockedAt;
  }

  if (existing.rewardClaimedAt) {
    update.rewardClaimedAt =
      existing.rewardClaimedAt;
  }

  return update;
}

// ============================================================
// ACHIEVEMENT RESULT BUILDER
// ============================================================

function buildAchievementResult(
  items,
  progressById,
  now
) {
  const updates = [];

  let totalReward = 0;

  for (const item of items) {
    const {
      definition,
      ref,
      data,
    } = item;

    const progress =
      progressById[definition.id] ??
      data.progress ??
      0;

    const wasUnlocked =
      data.unlocked === true;

    const wasRewardClaimed =
      data.rewardClaimed === true;

    const update =
      achievementUpdate(
        definition,
        progress,
        data,
        now
      );

    const newlyRewardable =
      update.unlocked === true &&
      wasRewardClaimed === false;

    let reward = 0;

    if (newlyRewardable) {
      reward =
        Math.max(
          0,
          number(definition.reward)
        );

      update.rewardClaimed = true;
      update.rewardClaimedAt = now;

      totalReward += reward;
    }

    updates.push({
      ref,
      update,
      achievementId: definition.id,
      reward,
      newlyUnlocked:
        !wasUnlocked &&
        update.unlocked === true,
    });
  }

  return {
    updates,
    totalReward,

    rewards:
      updates
        .filter((item) => item.reward > 0)
        .map((item) => ({
          achievementId: item.achievementId,
          reward: item.reward,
          newlyUnlocked: item.newlyUnlocked,
        })),
  };
}

// ============================================================
// PREPARE MINING ACHIEVEMENTS
// ============================================================

async function prepareMiningAchievements(
  transaction,
  uid,
  collected,
  started,
  dailyClaimedToday,
  dailyStreakValue,
  data,
  now
) {
  const definitions = [
    getAchievementDefinition("first_paw"),
    getAchievementDefinition("little_miner"),
    getAchievementDefinition("stl_hunter"),
    getAchievementDefinition("growing_miner"),
    getAchievementDefinition("stl_collector"),
    getAchievementDefinition("stl_master"),
    getAchievementDefinition("dedicated_miner"),
    getAchievementDefinition("hot_streak"),
    getAchievementDefinition("stella_on_fire"),
    getAchievementDefinition("stella_legend"),
    getAchievementDefinition("stellas_friend"),
  ].filter(Boolean);

  const items =
    await readAchievementData(
      transaction,
      uid,
      definitions
    );

  const collectedAmount =
    nonNegative(collected);

  const oldMiningCycles =
    nonNegative(data.miningCycles);

  const newMiningCycles =
    oldMiningCycles + (started ? 1 : 0);

  const oldDailyCheckIns =
    nonNegative(data.dailyCheckIns);

  const newDailyCheckIns =
    oldDailyCheckIns +
    (!dailyClaimedToday ? 1 : 0);

  const safeDailyStreak =
    Math.max(
      0,
      Math.floor(
        number(dailyStreakValue)
      )
    );

  const existingProgress = {};

  for (const item of items) {
    existingProgress[item.definition.id] =
      nonNegative(item.data.progress);
  }

  const progressById = {
    first_paw:
      Math.max(
        existingProgress.first_paw || 0,
        started ? 1 : 0
      ),

    little_miner:
      (existingProgress.little_miner || 0) +
      collectedAmount,

    stl_hunter:
      (existingProgress.stl_hunter || 0) +
      collectedAmount,

    growing_miner:
      (existingProgress.growing_miner || 0) +
      collectedAmount,

    stl_collector:
      (existingProgress.stl_collector || 0) +
      collectedAmount,

    stl_master:
      (existingProgress.stl_master || 0) +
      collectedAmount,

    dedicated_miner:
      newMiningCycles,

    hot_streak:
      Math.max(
        existingProgress.hot_streak || 0,
        safeDailyStreak
      ),

    stella_on_fire:
      Math.max(
        existingProgress.stella_on_fire || 0,
        safeDailyStreak
      ),

    stella_legend:
      Math.max(
        existingProgress.stella_legend || 0,
        safeDailyStreak
      ),

    stellas_friend:
      newDailyCheckIns,
  };

  return {
    ...buildAchievementResult(
      items,
      progressById,
      now
    ),

    miningCycles: newMiningCycles,
    dailyCheckIns: newDailyCheckIns,
  };
}

// ============================================================
// PREPARE POWER BOOST ACHIEVEMENTS
// ============================================================

async function preparePowerBoostAchievements(
  transaction,
  uid,
  data,
  now
) {
  const definitions = [
    getAchievementDefinition("power_paws"),
    getAchievementDefinition("super_paws"),
  ].filter(Boolean);

  const items =
    await readAchievementData(
      transaction,
      uid,
      definitions
    );

  const oldPowerBoostCount =
    nonNegative(data.powerBoostCount);

  const newPowerBoostCount =
    oldPowerBoostCount + 1;

  const progressById = {
    power_paws: newPowerBoostCount,
    super_paws: newPowerBoostCount,
  };

  return {
    ...buildAchievementResult(
      items,
      progressById,
      now
    ),

    powerBoostCount: newPowerBoostCount,
  };
}

// ============================================================
// WRITE MINING ACHIEVEMENTS
// ============================================================

function writeMiningAchievements(
  transaction,
  achievementResult
) {
  for (const item of achievementResult.updates) {
    transaction.set(
      item.ref,
      item.update,
      {
        merge: true,
      }
    );
  }
}

// ============================================================
// EXPORTS
// ============================================================

module.exports = {
  prepareMiningAchievements,
  preparePowerBoostAchievements,
  writeMiningAchievements,
};
