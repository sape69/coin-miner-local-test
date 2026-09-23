"use strict";

// ============================================================
// 🐱 STELLURIINI - MINING ACHIEVEMENT UTILS
// ============================================================
//
// Vastuu:
//
// 🏆 Mining-achievementtien käsittely
// 📊 Achievement progress
// 🔓 Achievement unlock
//
// Tämä tiedosto sisältää vain achievement-logiikan.
// Varsinaiset Mining Functions -handlerit pysyvät:
// functions/src/functions/miningFunctions.js
//
// ============================================================

const {
  getUserRef,
} = require("./userUtils");

// ============================================================
// 🏆 ACHIEVEMENT COLLECTION
// ============================================================

function getAchievementCollection(
  uid
) {
  return getUserRef(
    uid
  ).collection(
    "achievements"
  );
}

// ============================================================
// 🏆 GET ACHIEVEMENT DATA
// ============================================================

async function getAchievementData(
  transaction,
  uid,
  achievementId
) {
  const ref =
    getAchievementCollection(
      uid
    ).doc(
      achievementId
    );

  const snapshot =
    await transaction.get(
      ref
    );

  return {
    ref,

    data:
      snapshot.exists
        ? snapshot.data() || {}
        : {},
  };
}

// ============================================================
// 🏆 BUILD ACHIEVEMENT UPDATE
// ============================================================

function buildAchievementUpdate(
  achievementId,
  target,
  reward,
  progress,
  existingData,
  now
) {
  const oldProgress =
    Math.max(
      0,
      Number(
        existingData.progress
      ) || 0
    );

  const safeTarget =
    Math.max(
      0,
      Number(target) || 0
    );

  const requestedProgress =
    Number(progress);

  const safeProgress =
    Math.min(
      safeTarget,
      Math.max(
        oldProgress,
        Number.isFinite(
          requestedProgress
        ) &&
        requestedProgress >= 0
          ? requestedProgress
          : 0
      )
    );

  const alreadyUnlocked =
    existingData.unlocked === true;

  const unlocked =
    alreadyUnlocked ||
    (
      safeTarget > 0 &&
      safeProgress >= safeTarget
    );

  const update = {
    achievementId,

    progress:
      safeProgress,

    target:
      safeTarget,

    reward,

    unlocked,

    rewardClaimed:
      existingData.rewardClaimed === true,

    updatedAt:
      now,
  };

  if (
    unlocked &&
    !alreadyUnlocked &&
    !existingData.unlockedAt
  ) {
    update.unlockedAt =
      now;
  }

  return update;
}

// ============================================================
// 🏆 UPDATE MINING ACHIEVEMENTS
// ============================================================

async function updateMiningAchievements(
  transaction,
  uid,
  collected,
  startedMining,
  now
) {
  const firstPaw =
    await getAchievementData(
      transaction,
      uid,
      "first_paw"
    );

  const littleMiner =
    await getAchievementData(
      transaction,
      uid,
      "little_miner"
    );

  const stlHunter =
    await getAchievementData(
      transaction,
      uid,
      "stl_hunter"
    );

  if (
    startedMining
  ) {
    transaction.set(
      firstPaw.ref,
      buildAchievementUpdate(
        "first_paw",
        1,
        2,
        1,
        firstPaw.data,
        now
      ),
      {
        merge: true,
      }
    );
  }

  const safeCollected =
    Number(collected);

  if (
    !Number.isFinite(
      safeCollected
    ) ||
    safeCollected <= 0
  ) {
    return;
  }

  const littleProgress =
    Math.max(
      0,
      Number(
        littleMiner.data.progress
      ) || 0
    ) +
    safeCollected;

  transaction.set(
    littleMiner.ref,
    buildAchievementUpdate(
      "little_miner",
      10,
      5,
      littleProgress,
      littleMiner.data,
      now
    ),
    {
      merge: true,
    }
  );

  const hunterProgress =
    Math.max(
      0,
      Number(
        stlHunter.data.progress
      ) || 0
    ) +
    safeCollected;

  transaction.set(
    stlHunter.ref,
    buildAchievementUpdate(
      "stl_hunter",
      100,
      10,
      hunterProgress,
      stlHunter.data,
      now
    ),
    {
      merge: true,
    }
  );
}

// ============================================================
// 📦 EXPORTS
// ============================================================

module.exports = {
  getAchievementCollection,
  getAchievementData,
  buildAchievementUpdate,
  updateMiningAchievements,
};