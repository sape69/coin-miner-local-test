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
// IMPORTANT:
// Achievement-progressia päivitetään palvelinpuolella.
// Flutter ei kirjoita achievement-dataa suoraan.
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
// 🔥 FIRESTORE
// ============================================================

const {
  getFirestore,
} = require("firebase-admin/firestore");


// ============================================================
// 🔥 DATABASE
// ============================================================

const db =
  getFirestore();


// ============================================================
// 🏆 ACHIEVEMENT DEFINITIONS
// ============================================================
//
// Näiden arvojen tulee vastata miningFunctions.js:n
// palvelinpuolella käyttämiä achievement-arvoja.
//
// first_paw
//   target: 1
//   reward: 2
//
// little_miner
//   target: 10
//   reward: 5
//
// stl_hunter
//   target: 100
//   reward: 10
//
// hot_streak ja stellas_friend ovat valmiina
// tulevaa progress-logiikkaa varten.
//
// ============================================================

const achievements = [
  {
    id: "first_paw",

    target: 1,

    reward: 2,
  },

  {
    id: "little_miner",

    target: 10,

    reward: 5,
  },

  {
    id: "stl_hunter",

    target: 100,

    reward: 10,
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
  const uid =
    request.auth?.uid;

  if (!uid) {
    throw new HttpsError(
      "unauthenticated",
      "🐱 Kirjautuminen vaaditaan.",
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
// 🛡️ SAFE INTEGER
// ============================================================

function getSafeInteger(
  value,
  fallback = 0,
) {
  const number =
    Number(value);

  if (!Number.isFinite(number)) {
    return fallback;
  }

  return Math.floor(number);
}


// ============================================================
// 📊 NORMALIZE ACHIEVEMENT
// ============================================================

function normalizeAchievement(
  definition,
  data,
) {
  const progress =
    Math.max(
      0,
      getSafeInteger(
        data?.progress,
        0,
      ),
    );

  const target =
    Math.max(
      1,
      getSafeInteger(
        data?.target,
        definition.target,
      ),
    );

  const reward =
    Math.max(
      0,
      getSafeInteger(
        data?.reward,
        definition.reward,
      ),
    );

  const normalizedProgress =
    Math.min(
      progress,
      target,
    );

  const unlocked =
    data?.unlocked === true ||
    normalizedProgress >= target;

  const rewardClaimed =
    data?.rewardClaimed === true;

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
      data?.unlockedAt ??
      null,

    rewardClaimedAt:
      data?.rewardClaimedAt ??
      null,

    updatedAt:
      data?.updatedAt ??
      null,
  };
}


// ============================================================
// 📖 GET ACHIEVEMENTS
// ============================================================
//
// Hakee kaikki käyttäjän saavutukset.
//
// Puuttuvat achievement-dokumentit alustetaan
// palvelimella.
//
// Flutter ei kirjoita Firestoreen.
//
// ============================================================

exports.getAchievements =
  onCall(
    {
      region:
        "us-central1",
    },

    async (request) => {
      const uid =
        requireUser(request);

      try {
        const collection =
          getAchievementCollection(
            uid,
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
            document.data(),
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
              definition.id,
            );

          // --------------------------------------------------
          // 🆕 CREATE MISSING ACHIEVEMENT
          // --------------------------------------------------

          if (!existingData) {
            const document =
              collection.doc(
                definition.id,
              );

            const initialData = {
              achievementId:
                definition.id,

              progress:
                0,

              target:
                definition.target,

              reward:
                definition.reward,

              unlocked:
                false,

              rewardClaimed:
                false,

              updatedAt:
                now,
            };

            batch.set(
              document,
              initialData,
            );

            batchHasWrites =
              true;

            result.push(
              initialData,
            );

            continue;
          }

          // --------------------------------------------------
          // 📊 EXISTING ACHIEVEMENT
          // --------------------------------------------------

          result.push(
            normalizeAchievement(
              definition,
              existingData,
            ),
          );
        }

        // ----------------------------------------------------
        // 💾 COMMIT INITIALIZATION
        // ----------------------------------------------------

        if (batchHasWrites) {
          await batch.commit();
        }

        return {
          success:
            true,

          achievements:
            result,

          count:
            result.length,
        };
      } catch (error) {
        console.error(
          "getAchievements error:",
          error,
        );

        if (
          error instanceof HttpsError
        ) {
          throw error;
        }

        throw new HttpsError(
          "internal",
          "🐱 Stella-saavutusten lataaminen epäonnistui.",
        );
      }
    },
  );


// ============================================================
// 📊 GET ACHIEVEMENT COMPLETION COUNT
// ============================================================
//
// Palauttaa käyttäjän saavuttamien achievementien määrän.
//
// ============================================================

exports.getAchievementsCompleted =
  onCall(
    {
      region:
        "us-central1",
    },

    async (request) => {
      const uid =
        requireUser(request);

      try {
        const collection =
          getAchievementCollection(
            uid,
          );

        const snapshot =
          await collection.get();

        let completed =
          0;

        for (
          const document of snapshot.docs
        ) {
          const data =
            document.data() || {};

          if (
            data.unlocked === true
          ) {
            completed += 1;
          }
        }

        return {
          success:
            true,

          completed,

          total:
            achievements.length,
        };
      } catch (error) {
        console.error(
          "getAchievementsCompleted error:",
          error,
        );

        if (
          error instanceof HttpsError
        ) {
          throw error;
        }

        throw new HttpsError(
          "internal",
          "🐱 Stella-saavutusten määrän lataaminen epäonnistui.",
        );
      }
    },
  );