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
//
// users/{userId}/achievements/{achievementId}
//
// Tämä tiedosto:
//
// 🏆 palauttaa käyttäjän achievementit
// 📊 palauttaa valmistuneiden achievementien määrän
// 🔐 varmistaa käyttäjän autentikoinnin
// 🛡️ normalisoi Firestore-datan turvallisesti
//
// Tämä tiedosto EI:
//
// ❌ anna achievement-palkkioita
// ❌ muuta STL-saldoa
// ❌ muuta mining-tilaa
// ❌ käsittele AdMob SSV:tä
//
// ============================================================

// ============================================================
// 🔥 FIREBASE FUNCTIONS
// ============================================================

const {
onCall,
HttpsError,
} = require(
"firebase-functions/v2/https",
);

// ============================================================
// 🔥 FIRESTORE
// ============================================================

const {
getFirestore,
} = require(
"firebase-admin/firestore",
);

const db =
getFirestore();

// ============================================================
// 🏆 ACHIEVEMENT DEFINITIONS
// ============================================================
//
// Näiden arvojen täytyy vastata miningFunctions.js:n
// achievement-logiikkaa.
//
// first_paw
// → target 1
// → reward 2 STL
//
// little_miner
// → target 10
// → reward 5 STL
//
// stl_hunter
// → target 100
// → reward 10 STL
//
// hot_streak
// → target 7
// → reward 50 STL
//
// stellas_friend
// → target 10
// → reward 30 STL
//
// ============================================================

const achievements = [
{
id:
"first_paw",

target:
  1,

reward:
  2,

},

{
id:
"little_miner",

target:
  10,

reward:
  5,

},

{
id:
"stl_hunter",

target:
  100,

reward:
  10,

},

{
id:
"hot_streak",

target:
  7,

reward:
  50,

},

{
id:
"stellas_friend",

target:
  10,

reward:
  30,

},
];

// ============================================================
// 🔐 USER VALIDATION
// ============================================================

function requireUser(
request,
) {
const uid =
request.auth?.uid;

if (
typeof uid !==
"string" ||
uid.trim().length ===
0
) {
throw new HttpsError(
"unauthenticated",
"Kirjautuminen vaaditaan.",
);
}

return uid.trim();
}

// ============================================================
// 📁 ACHIEVEMENT COLLECTION
// ============================================================

function getAchievementCollection(
uid,
) {
return db
.collection(
"users",
)
.doc(
uid,
)
.collection(
"achievements",
);
}

// ============================================================
// 🧮 SAFE INTEGER
// ============================================================

function getSafeInteger(
value,
fallback = 0,
) {
const number =
Number(value);

return Number.isFinite(
number,
)
? Math.floor(number)
: fallback;
}

// ============================================================
// 🧮 SAFE NON-NEGATIVE INTEGER
// ============================================================

function getSafeNonNegativeInteger(
value,
fallback = 0,
) {
const number =
getSafeInteger(
value,
fallback,
);

return Math.max(
0,
number,
);
}

// ============================================================
// 🏆 NORMALIZE ACHIEVEMENT
// ============================================================
//
// Firestore-datan täytyy aina kulkea tämän normalisoinnin
// läpi ennen kuin se palautetaan Flutterille.
//
// Tärkeää:
//
// Jos progress >= target,
// achievement käsitellään avatuksi vaikka vanha Firestore
// dokumentti ei vielä sisältäisi:
//
// unlocked: true
//
// Tämä pitää lukutilan yhdenmukaisena mining-logiikan kanssa.
//
// ============================================================

function normalizeAchievement(
definition,
data,
) {
const safeData =
data &&
typeof data ===
"object"
? data
: {};

// ==========================================================
// 📊 PROGRESS
// ==========================================================

const progress =
getSafeNonNegativeInteger(
safeData.progress,
0,
);

// ==========================================================
// 🎯 TARGET
// ==========================================================

const storedTarget =
getSafeNonNegativeInteger(
safeData.target,
0,
);

const target =
storedTarget > 0
? storedTarget
: definition.target;

// ==========================================================
// 🎁 REWARD
// ==========================================================

const storedReward =
getSafeNonNegativeInteger(
safeData.reward,
0,
);

const reward =
storedReward > 0
? storedReward
: definition.reward;

// ==========================================================
// 🔓 UNLOCKED
// ==========================================================
//
// Achievement on avattu joko:
//
// 1. Firestoressa olevan unlocked-arvon perusteella
// 2. saavuttamalla targetin
//
// ==========================================================

const unlocked =
safeData.unlocked === true ||
progress >= target;

// ==========================================================
// 🎁 REWARD CLAIMED
// ==========================================================

const rewardClaimed =
safeData.rewardClaimed === true;

// ==========================================================
// 📦 NORMALIZED RESULT
// ==========================================================

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
  safeData.unlockedAt ??
  null,

rewardClaimedAt:
  safeData.rewardClaimedAt ??
  null,

updatedAt:
  safeData.updatedAt ??
  null,

};
}

// ============================================================
// 📖 GET ACHIEVEMENTS
// ============================================================
//
// Hakee kaikki käyttäjän achievementit.
//
// Puuttuvat achievementit alustetaan palvelimella.
//
// Flutter ei kirjoita achievements-kokoelmaa suoraan.
//
// ============================================================

const getAchievements =
onCall(
{
region:
"us-central1",
},

async (
  request,
) => {
  const uid =
    requireUser(
      request,
    );


  try {
    // ====================================================
    // 📁 USER COLLECTION
    // ====================================================

    const collection =
      getAchievementCollection(
        uid,
      );


    // ====================================================
    // 📥 READ EXISTING ACHIEVEMENTS
    // ====================================================

    const snapshot =
      await collection.get();


    const existing =
      new Map();


    for (
      const document of
        snapshot.docs
    ) {
      existing.set(
        document.id,
        document.data() ||
          {},
      );
    }


    // ====================================================
    // 📝 BATCH FOR MISSING ACHIEVEMENTS
    // ====================================================

    const batch =
      db.batch();


    const result =
      [];


    let batchHasWrites =
      false;


    // ====================================================
    // 🏆 PROCESS ALL DEFINITIONS
    // ====================================================

    for (
      const definition of
        achievements
    ) {
      const existingData =
        existing.get(
          definition.id,
        );


      // ==================================================
      // 🆕 MISSING ACHIEVEMENT
      // ==================================================

      if (
        !existingData
      ) {
        const document =
          collection.doc(
            definition.id,
          );


        const initialData =
          {
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
              new Date(),
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


      // ==================================================
      // 📊 EXISTING ACHIEVEMENT
      // ==================================================

      result.push(
        normalizeAchievement(
          definition,
          existingData,
        ),
      );
    }


    // ====================================================
    // 💾 CREATE MISSING DOCUMENTS
    // ====================================================

    if (
      batchHasWrites
    ) {
      await batch.commit();
    }


    // ====================================================
    // 📤 RESPONSE
    // ====================================================

    return {
      success:
        true,

      achievements:
        result,
    };
  } catch (
    error
  ) {
    // ====================================================
    // ❌ ERROR
    // ====================================================

    console.error(
      "getAchievements error:",
      error,
    );


    if (
      error instanceof
      HttpsError
    ) {
      throw error;
    }


    throw new HttpsError(
      "internal",
      "Stelluriini-achievementien lataaminen epäonnistui.",
    );
  }
},

);

// ============================================================
// 📊 GET ACHIEVEMENTS COMPLETED
// ============================================================
//
// Palauttaa:
//
// completed
// total
//
// Käyttää samaa unlocked-logiikkaa kuin getAchievements():
//
// unlocked === true
// TAI
// progress >= target
//
// Näin completed-määrä ei jää virheellisesti nollaan,
// jos Firestore-dokumentin unlocked-kenttä ei ole vielä
// päivittynyt vaikka target on jo saavutettu.
//
// ============================================================

const getAchievementsCompleted =
onCall(
{
region:
"us-central1",
},

async (
  request,
) => {
  const uid =
    requireUser(
      request,
    );


  try {
    // ====================================================
    // 📁 USER COLLECTION
    // ====================================================

    const collection =
      getAchievementCollection(
        uid,
      );


    // ====================================================
    // 📥 READ ACHIEVEMENTS
    // ====================================================

    const snapshot =
      await collection.get();


    const existing =
      new Map();


    for (
      const document of
        snapshot.docs
    ) {
      existing.set(
        document.id,
        document.data() ||
          {},
      );
    }


    // ====================================================
    // 📊 COUNT COMPLETED
    // ====================================================

    let completed =
      0;


    for (
      const definition of
        achievements
    ) {
      const data =
        existing.get(
          definition.id,
        );


      if (
        !data
      ) {
        continue;
      }


      const normalized =
        normalizeAchievement(
          definition,
          data,
        );


      if (
        normalized.unlocked
      ) {
        completed++;
      }
    }


    // ====================================================
    // 📤 RESPONSE
    // ====================================================

    return {
      success:
        true,

      completed,

      total:
        achievements.length,
    };
  } catch (
    error
  ) {
    // ====================================================
    // ❌ ERROR
    // ====================================================

    console.error(
      "getAchievementsCompleted error:",
      error,
    );


    if (
      error instanceof
      HttpsError
    ) {
      throw error;
    }


    throw new HttpsError(
      "internal",
      "Stelluriini-achievementien valmistuneiden määrän lataaminen epäonnistui.",
    );
  }
},

);

// ============================================================
// 📦 EXPORTS
// ============================================================

module.exports = {
getAchievements,
getAchievementsCompleted,
};