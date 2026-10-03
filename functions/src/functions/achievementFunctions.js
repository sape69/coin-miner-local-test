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
// Asiakas ei kirjoita achievements-kokoelmaan suoraan.
//
// Firestore:
//
// users/{userId}/achievements/{achievementId}
//
// Achievement-palkinnot maksetaan aina serverillä.
//
// IMPORTANT:
//
// Achievement STL -palkinto EI ole AdMob-palkinto.
//
// Achievement reward:
// - lisätään käyttäjän miningBalance-saldoon
// - maksetaan vain kerran
// - käsitellään Firestore-transaktion sisällä
// - reward-arvo tulee vain serverin achievement-definitionistä
//
// ============================================================
//
// ACHIEVEMENT DEFINITIONS:
//
// first_paw
//    Target: 1
//    Reward: 2 STL
//
// little_miner
//    Target: 10
//    Reward: 5 STL
//
// stl_hunter
//    Target: 100
//    Reward: 10 STL
//
// hot_streak
//    Target: 7
//    Reward: 50 STL
//
// stellas_friend
//    Target: 10
//    Reward: 30 STL
//
// growing_miner
//    Target: 25
//    Reward: 8 STL
//
// stl_collector
//    Target: 500
//    Reward: 25 STL
//
// stl_master
//    Target: 1000
//    Reward: 50 STL
//
// dedicated_miner
//    Target: 25
//    Reward: 30 STL
//
// stella_on_fire
//    Target: 14
//    Reward: 50 STL
//
// stella_legend
//    Target: 30
//    Reward: 100 STL
//
// power_paws
//    Target: 5
//    Reward: 20 STL
//
// super_paws
//    Target: 25
//    Reward: 75 STL
//
// first_invitation
//    Target: 1
//    Reward: 5 STL
//
// friend_circle
//    Target: 5
//    Reward: 10 STL
//
// stellas_community
//    Target: 10
//    Reward: 20 STL
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

// ============================================================
// 🔥 FIRESTORE
// ============================================================

const db =
  getFirestore();

// ============================================================
// 🏆 ACHIEVEMENT DEFINITIONS
// ============================================================
//
// Kaikki achievementien target- ja reward-arvot ovat täällä.
//
// ÄLÄ kopioi näitä arvoja muihin tiedostoihin.
//
// Serveri on achievementien target- ja reward-arvojen
// lopullinen auktoriteetti.
//
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
    reward: 20,
  }),

  Object.freeze({
    id: "super_paws",
    target: 25,
    reward: 75,
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
]);

// ============================================================
// 🔎 ACHIEVEMENT DEFINITION LOOKUP
// ============================================================

function getAchievementDefinition(
  achievementId
) {
  if (
    typeof achievementId !== "string"
  ) {
    return null;
  }

  const normalizedId =
    achievementId.trim();

  if (!normalizedId) {
    return null;
  }

  return (
    achievements.find(
      (achievement) =>
        achievement.id ===
        normalizedId
    ) || null
  );
}

// ============================================================
// 📋 GET ACHIEVEMENT DEFINITIONS
// ============================================================
//
// Palauttaa turvallisen kopion achievement-määrityksistä.
//
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
  const uid =
    request.auth?.uid;

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

function getAchievementCollection(
  uid
) {
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
  const parsed =
    Number(value);

  if (
    !Number.isFinite(parsed)
  ) {
    return fallback;
  }

  return Math.floor(parsed);
}

// ============================================================
// 💰 SAFE NON-NEGATIVE NUMBER
// ============================================================

function getSafeBalance(
  value
) {
  const parsed =
    Number(value);

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
//
// Firestore-dataa ei luoteta target/reward-arvojen osalta.
//
// Target ja reward tulevat aina serverin definitionistä.
//
// ============================================================

function normalizeAchievement(
  definition,
  data
) {
  const source =
    data || {};

  const progress =
    Math.max(
      0,
      getSafeInteger(
        source.progress,
        0
      )
    );

  const target =
    Math.max(
      1,
      getSafeInteger(
        definition.target,
        1
      )
    );

  const reward =
    Math.max(
      0,
      Number(
        definition.reward
      ) || 0
    );

  const normalizedProgress =
    Math.min(
      progress,
      target
    );

  const unlocked =
    source.unlocked === true ||
    normalizedProgress >=
      target;

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
      source.unlockedAt ??
      null,

    rewardClaimedAt:
      source.rewardClaimedAt ??
      null,

    updatedAt:
      source.updatedAt ??
      null,
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

    updatedAt:
      now,
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

    updatedAt:
      now,
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
//
// Tämä funktio ei kirjoita Firestoreen.
//
// Se laskee:
// - uuden progressin
// - unlock-tilan
// - pitääkö palkinto maksaa
// - paljonko STL:ää maksetaan
//
// Reward maksetaan vain silloin kun achievement avautuu
// ensimmäisen kerran eikä sitä ole vielä merkitty maksetuksi.
//
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
        : (
          shouldPayReward
            ? now
            : null
        ),

    updatedAt:
      now,
  };
}

// ============================================================
// 🎁 BUILD ACHIEVEMENT REWARD UPDATE
// ============================================================
//
// Luo achievement-dokumentin päivityksen.
//
// Tätä voidaan käyttää saman Firestore-transaktion sisällä.
//
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
//
// Tämä rakentaa serveripuolen miningBalance-päivityksen.
//
// HUOM:
//
// Tämä käyttää increment-operaatiota.
//
// Näin achievement-palkinto voidaan lisätä käyttäjän
// nykyiseen miningBalance-saldoon ilman että client voi
// päättää palkinnon määrää.
//
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

  if (
    safeReward <= 0
  ) {
    return null;
  }

  return {
    miningBalance:
      FieldValue.increment(
        safeReward
      ),

    updatedAt:
      now,
  };
}

// ============================================================
// 🐱 APPLY ACHIEVEMENT PROGRESS
// ============================================================
//
// Server-side helper.
//
// Tämän tarkoitus on olla miningFunctions.js:n käyttämä
// keskitetty achievement-käsittelijä.
//
// IMPORTANT:
//
// Funktio ei tee Firestore-lukuja itse.
//
// Se käyttää transactionissa jo luettua achievement-dataa.
//
// Tämä on tärkeää Firestore-transaktion kannalta.
//
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
//
// Hakee kaikki käyttäjän achievementit.
//
// Puuttuvat achievementit alustetaan palvelimella.
//
// HUOM:
//
// Tämä endpoint EI maksa achievement-palkintoja.
//
// Palkinto syntyy silloin kun achievement saavuttaa targetin
// serveripuolen mining/event-logiikan kautta.
//
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
//
// Achievement configuration
// + reward calculation
// + transaction helper.
//
// miningFunctions.js voi käyttää:
//
// const {
//   getAchievementDefinition,
//   getAchievementDefinitions,
//   applyAchievementProgress,
//   calculateAchievementReward,
// } = require("./achievementFunctions");
//
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