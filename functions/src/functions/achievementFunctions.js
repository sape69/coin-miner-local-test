"use strict";

const {
  onCall,
  HttpsError,
} = require("firebase-functions/v2/https");

const {
  getFirestore,
} = require("firebase-admin/firestore");

// ============================================================
// 🏆 STELLURIINI ACHIEVEMENT FUNCTIONS
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

const db = getFirestore();

// ============================================================
// 🏆 ACHIEVEMENT DEFINITIONS
// ============================================================

const achievements = [
  {
    id: "first_paw",
    target: 1,
    reward: 5,
  },
  {
    id: "little_miner",
    target: 10,
    reward: 10,
  },
  {
    id: "stl_hunter",
    target: 100,
    reward: 25,
  },
  {
    id: "hot_streak",
    target: 7,
    reward: 50,
  },
  {
    id: "stellas_friend",
    target: 10,
    reward: 30,
  },
];

// ============================================================
// 👤 USER VALIDATION
// ============================================================

function requireUser(request) {
  const uid = request.auth?.uid;

  if (!uid) {
    throw new HttpsError(
      "unauthenticated",
      "Kirjautuminen vaaditaan.",
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
// 📊 NORMALIZE ACHIEVEMENT
// ============================================================

function normalizeAchievement(
  definition,
  data,
) {
  const progress =
    typeof data?.progress === "number"
      ? Math.max(
          0,
          Math.floor(data.progress),
        )
      : 0;

  const target =
    typeof data?.target === "number"
      ? Math.max(
          1,
          Math.floor(data.target),
        )
      : definition.target;

  const reward =
    typeof data?.reward === "number"
      ? Math.max(
          0,
          Math.floor(data.reward),
        )
      : definition.reward;

  const unlocked =
    data?.unlocked === true ||
    progress >= target;

  const rewardClaimed =
    data?.rewardClaimed === true;

  return {
    achievementId:
      definition.id,

    progress:
      Math.min(
        progress,
        target,
      ),

    target,

    reward,

    unlocked,

    rewardClaimed,

    unlockedAt:
      data?.unlockedAt ?? null,

    rewardClaimedAt:
      data?.rewardClaimedAt ?? null,

    updatedAt:
      data?.updatedAt ?? null,
  };
}

// ============================================================
// 📖 GET ACHIEVEMENTS
// ============================================================
//
// Hakee kaikki käyttäjän saavutukset.
//
// Puuttuvat saavutukset alustetaan palvelimella.
// Flutter ei kirjoita Firestoreen.
//
// ============================================================

exports.getAchievements = onCall(
  async (request) => {
    const uid =
      requireUser(request);

    const collection =
      getAchievementCollection(uid);

    const snapshot =
      await collection.get();

    const existing =
      new Map();

    for (
      const document of snapshot.docs
    ) {
      existing.set(
        document.id,
        document.data(),
      );
    }

    const batch =
      db.batch();

    const now =
      new Date();

    const result = [];

    let batchHasWrites = false;

    for (
      const definition of achievements
    ) {
      const existingData =
        existing.get(
          definition.id,
        );

      if (!existingData) {
        const document =
          collection.doc(
            definition.id,
          );

        const initialData = {
          achievementId:
            definition.id,

          progress: 0,

          target:
            definition.target,

          reward:
            definition.reward,

          unlocked: false,

          rewardClaimed: false,

          updatedAt: now,
        };

        batch.set(
          document,
          initialData,
        );

        batchHasWrites = true;

        result.push(
          initialData,
        );
      } else {
        result.push(
          normalizeAchievement(
            definition,
            existingData,
          ),
        );
      }
    }

    if (batchHasWrites) {
      await batch.commit();
    }

    return {
      achievements: result,
    };
  },
);

// ============================================================
// 📊 GET ACHIEVEMENT COMPLETION COUNT
// ============================================================

exports.getAchievementsCompleted =
  onCall(
    async (request) => {
      const uid =
        requireUser(request);

      const collection =
        getAchievementCollection(uid);

      const snapshot =
        await collection.get();

      let completed = 0;

      for (
        const document of snapshot.docs
      ) {
        if (
          document.data().unlocked ===
          true
        ) {
          completed++;
        }
      }

      return {
        completed,
        total: achievements.length,
      };
    },
  );