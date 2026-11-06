
"use strict";

// ============================================================
// 🐱 STELLURIINI - MINING ACHIEVEMENT SERVICE
// ============================================================
//
// Saavutusten lukeminen, etenemisen laskenta ja tallennus.
//
// Vastuut:
// - Mining cycle -saavutukset
// - Kumulatiiviset STL-louhintasaavutukset
// - Power Boost -saavutukset
// - Saavutuspalkintojen kertamaksu
//
// Daily Check-In- ja daily streak -saavutukset kuuluvat
// yksinomaan dailyFunctions.js-tiedostolle.
//
// Tämä palvelu ei päivitä käyttäjän miningBalance-saldoa.
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
  // Säilytetään vanha kutsurajapinta, jotta
  // miningFunctions.js-tiedostoa ei tarvitse muuttaa
  // tässä samassa työvaiheessa.
  //
  // Daily Check-In -tietoja ei kuitenkaan käsitellä tässä.
  void dailyClaimedToday;
  void dailyStreakValue;

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

    // Cumulative mined STL
    "stl_hoarder",
    "stl_tycoon",
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
  // MINING CYCLES
  // ----------------------------------------------------------

  const oldMiningCycles =
    safeInteger(userData.miningCycles);

  const newMiningCycles =
    oldMiningCycles + (started ? 1 : 0);

  // ----------------------------------------------------------
  // CUMULATIVE MINED STL
  // ----------------------------------------------------------
  //
  // Älä käytä miningBalance-saldoa louhintamääränä:
  // saldoon lisätään myös achievement-, referral- ja muita
  // palkintoja. Ne eivät ole varsinaista louhintaa.
  //
  // totalMined otetaan käyttöön käyttäjädokumentissa
  // erillisessä muutoksessa. Siihen asti progress kasvaa
  // tässä vain todellisella collected-louhintakertymällä.
  //
  // Vanhojen achievement-dokumenttien progress säilyy
  // achievementUpdate()-funktion monotonisen laskennan ansiosta.
  // ----------------------------------------------------------

  const historicalTotalMined =
    nonNegative(userData.totalMined);

  const lifetimeStlProgress =
    historicalTotalMined + collectedAmount;

  // ----------------------------------------------------------
  // PROGRESS CALCULATIONS
  // ----------------------------------------------------------

  const progressById = {
    // First mining
    first_paw:
      started ? 1 : 0,

    // Cumulative mined STL
    little_miner:
      lifetimeStlProgress,

    stl_hunter:
      lifetimeStlProgress,

    growing_miner:
      lifetimeStlProgress,

    stl_collector:
      lifetimeStlProgress,

    stl_master:
      lifetimeStlProgress,

    stl_hoarder:
      lifetimeStlProgress,

    stl_tycoon:
      lifetimeStlProgress,

    // Mining cycles
    dedicated_miner:
      newMiningCycles,

    seasoned_miner:
      newMiningCycles,

    veteran_miner:
      newMiningCycles,
  };

  // Daily Check-In -laskuri säilyy ennallaan.
  const unchangedDailyCheckIns =
    safeInteger(userData.dailyCheckIns);

  return {
    ...buildAchievementResult(
      items,
      progressById,
      now
    ),

    miningCycles: newMiningCycles,

    dailyCheckIns: unchangedDailyCheckIns,
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

  const progressById = {
    power_paws:
      newPowerBoostCount,

    super_paws:
      newPowerBoostCount,

    power_hunter:
      newPowerBoostCount,

    power_master:
      newPowerBoostCount,
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
