"use strict";

// ============================================================
// 🐱 STELLURIINI ACHIEVEMENT FUNCTIONS
// ============================================================
//
// Flutter
//    ↓
// Cloud Function
//    ↓
// Firestore
//
// Asiakas ei lue achievements-kokoelmaa suoraan.
//
// Firestore:
// users/{userId}/achievements/{achievementId}
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
// IMPORTANT:
//
// Achievement definitions are centralized here.
//
// miningFunctions.js will use these definitions instead
// of maintaining a second copy of target/reward values.
//
// ============================================================

const {
  onCall,
  HttpsError,
} = require("firebase-functions/v2/https");

const {
  getFirestore,
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
// Keep all achievement configuration in ONE place.
//
// Do not duplicate target/reward values in other functions.
//
// ============================================================

const achievements = Object.freeze([
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
    id: "hot_streak",
    target: 7,
    reward: 50,
  }),

  Object.freeze({
    id: "stellas_friend",
    target: 10,
    reward: 30,
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
// Returns a safe copy so callers cannot modify the canonical
// achievement configuration.
//
// This is exported for server-side functions such as
// miningFunctions.js.
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
// 🔢 SAFE INTEGER
// ============================================================

function getSafeInteger(
  value,
  fallback = 0
) {
  const number =
    Number(value);

  if (
    !Number.isFinite(number)
  ) {
    return fallback;
  }

  return Math.floor(number);
}


// ============================================================
// 📊 NORMALIZE ACHIEVEMENT
// ============================================================
//
// Firestore data is never trusted blindly.
//
// Target and reward come from the canonical server-side
// definition whenever possible.
//
// This prevents a client-created or manually modified
// Firestore document from changing the official achievement
// target or reward.
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
      getSafeInteger(
        definition.reward,
        0
      )
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
//
// Existing achievement documents are normalized against the
// canonical server-side definition.
//
// Existing progress is preserved.
//
// Existing reward claim state is preserved.
//
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
// 📖 GET ACHIEVEMENTS
// ============================================================
//
// Hakee kaikki käyttäjän achievements.
//
// Puuttuvat achievements alustetaan palvelimella.
//
// Flutter ei kirjoita achievements-kokoelmaan suoraan.
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

          if (needsUpdate) {
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

        if (batchHasWrites) {
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
//
// Palauttaa käyttäjän avattujen achievementien määrän.
//
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
// These exports are intentionally available for other
// backend functions.
//
// miningFunctions.js can import:
//
// const {
//   getAchievementDefinition,
//   getAchievementDefinitions,
// } = require("./achievementFunctions");
//
// This keeps achievement target/reward values centralized.
//
// ============================================================

module.exports.getAchievementDefinition =
  getAchievementDefinition;

module.exports.getAchievementDefinitions =
  getAchievementDefinitions;