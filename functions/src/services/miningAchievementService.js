
"use strict";

// ============================================================
// 🐱 STELLURIINI - MINING ACHIEVEMENT SERVICE
// ============================================================
//
// Saavutusten lukeminen, etenemisen laskenta ja tallennus.
//
// Ominaisuudet:
// - Firestore-transaktiot
// - Historiallisen STL-saldon huomioiminen
// - Mining cycle -saavutukset
// - STL-kertymäsaavutukset
// - Daily streak -saavutukset
// - Daily check-in -saavutukset
// - Power Boost -saavutukset
// - Palkintojen kertamaksu
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

function safeInteger(value, fallback = 0) {
  const result = number(value, fallback);

  return Number.isFinite(result)
    ? Math.max(0, Math.floor(result))
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
      data: snapshot.exists
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
    nonNegative(existing.progress);

  const safeTarget =
    nonNegative(definition.target);

  const safeReward =
    nonNegative(definition.reward);

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
    update.unlockedAt = existing.unlockedAt;
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

    let reward = 0;

    // Palkinto maksetaan vain kerran.
    if (
      update.unlocked === true &&
      wasRewardClaimed === false
    ) {
      reward =
        nonNegative(definition.reward);

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
    // Mining
    "first_paw",
    "little_miner",
    "stl_hunter",
    "growing_miner",
    "stl_collector",
    "stl_master",
    "dedicated_miner",

    // Mining cycles
    "seasoned_miner",
    "veteran_miner",

    // STL totals
    "stl_hoarder",
    "stl_tycoon",

    // Daily streak
    "hot_streak",
    "stella_on_fire",
    "stella_legend",
    "stella_eternal",
    "stella_beyond",

    // Daily check-ins
    "stellas_friend",
    "stella_companion",
    "stella_devotee",
  ]
    .map(getAchievementDefinition)
    .filter(Boolean);

  const items =
    await readAchievementData(
      transaction,
      uid,
      definitions
    );

  const userData =
    data && typeof data === "object"
      ? data
      : {};

  const collectedAmount =
    nonNegative(collected);

  // ----------------------------------------------------------
  // HISTORICAL STL BALANCE
  // ----------------------------------------------------------
  //
  // Existing users may already have STL in miningBalance.
  //
  // Achievement progress must not start from zero when
  // the achievement document is newly created.
  //
  // Existing progress is preserved if it is higher.
  //
  // Collected is added only once for this mining claim.
  //
  // ----------------------------------------------------------

  const historicalMiningBalance =
    nonNegative(userData.miningBalance);

  // ----------------------------------------------------------
  // MINING CYCLES
  // ----------------------------------------------------------

  const oldMiningCycles =
    safeInteger(userData.miningCycles);

  const newMiningCycles =
    oldMiningCycles + (started ? 1 : 0);

  // ----------------------------------------------------------
  // DAILY CHECK-INS
  // ----------------------------------------------------------

  const oldDailyCheckIns =
    safeInteger(userData.dailyCheckIns);

  const newDailyCheckIns =
    oldDailyCheckIns +
    (!dailyClaimedToday ? 1 : 0);

  // ----------------------------------------------------------
  // DAILY STREAK
  // ----------------------------------------------------------

  const safeDailyStreak =
    safeInteger(dailyStreakValue);

  // ----------------------------------------------------------
  // EXISTING ACHIEVEMENT PROGRESS
  // ----------------------------------------------------------

  const existingProgress = {};

  for (const item of items) {
    existingProgress[item.definition.id] =
      nonNegative(item.data.progress);
  }

  // ----------------------------------------------------------
  // STL PROGRESS
  // ----------------------------------------------------------
  //
  // Use the greater of:
  // - Existing achievement progress
  // - Historical miningBalance
  //
  // Then add the newly collected mining amount.
  //
  // This migrates existing users without resetting progress.
  //
  // ----------------------------------------------------------

  const lifetimeStlProgress =
    Math.max(
      historicalMiningBalance,
      existingProgress.stl_hoarder || 0,
      existingProgress.stl_tycoon || 0
    ) + collectedAmount;

  // ----------------------------------------------------------
  // PROGRESS CALCULATIONS
  // ----------------------------------------------------------

  const progressById = {

    // --------------------------------------------------------
    // FIRST MINING
    // --------------------------------------------------------

    first_paw:
      Math.max(
        existingProgress.first_paw || 0,
        started ? 1 : 0
      ),

    // --------------------------------------------------------
    // STL ACHIEVEMENTS
    // --------------------------------------------------------

    little_miner:
      Math.max(
        existingProgress.little_miner || 0,
        lifetimeStlProgress
      ),

    stl_hunter:
      Math.max(
        existingProgress.stl_hunter || 0,
        lifetimeStlProgress
      ),

    growing_miner:
      Math.max(
        existingProgress.growing_miner || 0,
        lifetimeStlProgress
      ),

    stl_collector:
      Math.max(
        existingProgress.stl_collector || 0,
        lifetimeStlProgress
      ),

    stl_master:
      Math.max(
        existingProgress.stl_master || 0,
        lifetimeStlProgress
      ),

    stl_hoarder:
      lifetimeStlProgress,

    stl_tycoon:
      lifetimeStlProgress,

    // --------------------------------------------------------
    // MINING CYCLES
    // --------------------------------------------------------

    dedicated_miner:
      newMiningCycles,

    seasoned_miner:
      newMiningCycles,

    veteran_miner:
      newMiningCycles,

    // --------------------------------------------------------
    // DAILY STREAK
    // --------------------------------------------------------

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

    stella_eternal:
      Math.max(
        existingProgress.stella_eternal || 0,
        safeDailyStreak
      ),

    stella_beyond:
      Math.max(
        existingProgress.stella_beyond || 0,
        safeDailyStreak
      ),

    // --------------------------------------------------------
    // DAILY CHECK-INS
    // --------------------------------------------------------

    stellas_friend:
      newDailyCheckIns,

    stella_companion:
      newDailyCheckIns,

    stella_devotee:
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
    "power_paws",
    "super_paws",
    "power_hunter",
    "power_master",
  ]
    .map(getAchievementDefinition)
    .filter(Boolean);

  const items =
    await readAchievementData(
      transaction,
      uid,
      definitions
    );

  const oldPowerBoostCount =
    safeInteger(data.powerBoostCount);

  const newPowerBoostCount =
    oldPowerBoostCount + 1;

  const existingProgress = {};

  for (const item of items) {
    existingProgress[item.definition.id] =
      nonNegative(item.data.progress);
  }

  const progressById = {
    power_paws:
      Math.max(
        existingProgress.power_paws || 0,
        newPowerBoostCount
      ),

    super_paws:
      Math.max(
        existingProgress.super_paws || 0,
        newPowerBoostCount
      ),

    power_hunter:
      Math.max(
        existingProgress.power_hunter || 0,
        newPowerBoostCount
      ),

    power_master:
      Math.max(
        existingProgress.power_master || 0,
        newPowerBoostCount
      ),
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
  if (
    !achievementResult ||
    !Array.isArray(achievementResult.updates)
  ) {
    return;
  }

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
