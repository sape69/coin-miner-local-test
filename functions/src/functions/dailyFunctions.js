"use strict";

// ============================================================
// 🐱 STELLA DAILY FUNCTIONS
// ============================================================
//
// 🎁 Stella Daily Check-In
// 📅 Päivittäinen bonus
// ⚡ Daily Streak Hash Rate
// 🛡️ Tuplabonuksen esto
// 📜 Daily-tapahtumahistoria
// 🏆 Stella Achievements
//
// Daily Hash Rate:
//
// Päivä 1  → 0.5 HR
// Päivä 2  → 1.0 HR
// Päivä 3  → 1.5 HR
// Päivä 4  → 2.0 HR
// Päivä 5  → 2.5 HR
// Päivä 6  → 3.0 HR
// Päivä 7+ → 3.5 HR
//
// Jos käyttäjä jättää yhden kokonaisen päivän väliin,
// seuraava Daily Check-In aloittaa uuden streakin
// päivästä 1.
//
// Kaikki päivät käsitellään UTC-ajassa.
//
// ============================================================


// ============================================================
// 🔥 FIREBASE FUNCTIONS
// ============================================================

const {
  onCall,
  HttpsError,
} = require(
  "firebase-functions/v2/https"
);


// ============================================================
// 🔥 FIREBASE
// ============================================================

const {
  db,
  FieldValue,
} = require(
  "../firebase/firebase"
);


// ============================================================
// ⚙️ CONFIG
// ============================================================

const {
  DAILY_HASH_RATE_START,
  DAILY_HASH_RATE_STEP,
  DAILY_HASH_RATE_MAX_DAY,
  MAX_DAILY_HASH_RATE,
} = require(
  "../config/miningConfig"
);


// ============================================================
// 📅 DATE UTILITIES
// ============================================================

const {
  getUtcDateString,
  getYesterdayUtcDateString,
} = require(
  "../utils/dateUtils"
);


// ============================================================
// 👤 USER UTILITIES
// ============================================================

const {
  getUserRef,
} = require(
  "../utils/userUtils"
);


// ============================================================
// 📜 HISTORY SERVICE
// ============================================================

const {
  createDailyHistoryRef,
} = require(
  "../services/historyService"
);


// ============================================================
// ⚡ CALCULATE DAILY HASH RATE
// ============================================================
//
// Muuntaa streak-päivän Daily Hash Rateksi.
//
// Päivä 1  → 0.5
// Päivä 2  → 1.0
// Päivä 3  → 1.5
// ...
// Päivä 7+ → 3.5
//
// ============================================================

function calculateDailyHashRate(streak) {
  const safeStreak =
    Number.isFinite(streak) && streak > 0
      ? Math.floor(streak)
      : 1;

  const effectiveDay =
    Math.min(
      safeStreak,
      DAILY_HASH_RATE_MAX_DAY
    );

  const calculatedHashRate =
    DAILY_HASH_RATE_START +
    ((effectiveDay - 1) * DAILY_HASH_RATE_STEP);

  return Math.min(
    calculatedHashRate,
    MAX_DAILY_HASH_RATE
  );
}


// ============================================================
// 🏆 ACHIEVEMENT COLLECTION
// ============================================================

function getAchievementCollection(uid) {
  return getUserRef(uid)
    .collection(
      "achievements"
    );
}


// ============================================================
// 🏆 READ ACHIEVEMENT
// ============================================================
//
// Achievement-documentit luetaan ennen transactionin
// ensimmäisiä kirjoituksia.
//
// ============================================================

async function getAchievementData(
  transaction,
  uid,
  achievementId
) {
  const ref =
    getAchievementCollection(uid)
      .doc(achievementId);

  const snapshot =
    await transaction.get(ref);

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
  const safeTarget =
    Math.max(
      0,
      Math.floor(
        Number(target) || 0
      )
    );

  const oldProgress =
    Math.max(
      0,
      Math.floor(
        Number(existingData.progress) || 0
      )
    );

  const requestedProgress =
    Math.max(
      0,
      Math.floor(
        Number(progress) || 0
      )
    );

  const safeProgress =
    Math.min(
      safeTarget,
      Math.max(
        oldProgress,
        requestedProgress
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
    progress: safeProgress,
    target: safeTarget,
    reward,
    unlocked,
    rewardClaimed:
      existingData.rewardClaimed === true,
    updatedAt: now,
  };

  if (
    unlocked &&
    !alreadyUnlocked &&
    !existingData.unlockedAt
  ) {
    update.unlockedAt = now;
  }

  return update;
}


// ============================================================
// 🏆 UPDATE DAILY ACHIEVEMENTS
// ============================================================
//
// 🔥 Hot Streak
//     Target = 7
//     Progress = current Daily Streak
//
// 🐱 Stella's Friend
//     Target = 10
//     Progress = onnistuneiden Daily Check-Inien määrä
//
// Palkintoja ei lisätä saldoon tässä vaiheessa.
//
// ============================================================

async function updateDailyAchievements(
  transaction,
  uid,
  newDailyStreak,
  now
) {
  // ----------------------------------------------------------
  // 🔥 READ HOT STREAK
  // ----------------------------------------------------------

  const hotStreak =
    await getAchievementData(
      transaction,
      uid,
      "hot_streak"
    );

  // ----------------------------------------------------------
  // 🐱 READ STELLA'S FRIEND
  // ----------------------------------------------------------

  const stellasFriend =
    await getAchievementData(
      transaction,
      uid,
      "stellas_friend"
    );

  // ----------------------------------------------------------
  // 🔥 HOT STREAK
  // ----------------------------------------------------------

  const hotStreakUpdate =
    buildAchievementUpdate(
      "hot_streak",
      7,
      50,
      newDailyStreak,
      hotStreak.data,
      now
    );

  transaction.set(
    hotStreak.ref,
    hotStreakUpdate,
    {
      merge: true,
    }
  );

  // ----------------------------------------------------------
  // 🐱 STELLA'S FRIEND
  // ----------------------------------------------------------
  //
  // Jokainen onnistunut Daily Check-In kasvattaa
  // progressia yhdellä.
  //
  // ----------------------------------------------------------

  const previousCheckIns =
    Math.max(
      0,
      Math.floor(
        Number(
          stellasFriend.data.progress
        ) || 0
      )
    );

  const newCheckIns =
    previousCheckIns + 1;

  const stellasFriendUpdate =
    buildAchievementUpdate(
      "stellas_friend",
      10,
      30,
      newCheckIns,
      stellasFriend.data,
      now
    );

  transaction.set(
    stellasFriend.ref,
    stellasFriendUpdate,
    {
      merge: true,
    }
  );
}


// ============================================================
// 🎁 DAILY CHECK-IN
// ============================================================

const dailyCheckIn =
  onCall(
    {
      region: "us-central1",
    },
    async (request) => {

      // ======================================================
      // 🔐 AUTHENTICATION
      // ======================================================

      if (!request.auth) {

        throw new HttpsError(
          "unauthenticated",
          "🐱 Kirjaudu sisään saadaksesi Daily Bonus -palkinnon."
        );

      }


      const uid =
        request.auth.uid;


      const userRef =
        getUserRef(uid);


      // ======================================================
      // 📅 CURRENT DATE
      // ======================================================

      const today =
        getUtcDateString();


      const yesterday =
        getYesterdayUtcDateString();


      try {

        // ====================================================
        // 🔥 FIRESTORE TRANSACTION
        // ====================================================

        return await db.runTransaction(
          async (transaction) => {

            // ==================================================
            // 👤 GET USER
            // ==================================================

            const snapshot =
              await transaction.get(
                userRef
              );


            const data =
              snapshot.exists
                ? snapshot.data() || {}
                : {};


            // ==================================================
            // 📅 LAST DAILY DATE
            // ==================================================

            const lastDailyDate =
              typeof data.lastDailyDate === "string"
                ? data.lastDailyDate
                : null;


            // ==================================================
            // ⚡ CURRENT HASH RATE
            // ==================================================
            //
            // Hash Rate voidaan säilyttää käyttäjädatassa.
            //
            // Uudessa mallissa Daily Check-In määrittää
            // Daily Hash Raten streakin perusteella.
            //
            // Mainosboostit voivat nostaa aktiivista Hash Ratea
            // väliaikaisesti erillisessä ad-logiikassa.
            //
            // ==================================================

            const savedHashRate =
              Number(data.hashRate);


            const currentHashRate =
              Number.isFinite(savedHashRate) &&
                      savedHashRate >= 0
                  ? savedHashRate
                  : 0;


            // ==================================================
            // 🔥 CURRENT STREAK
            // ==================================================

            const savedStreak =
              Number(data.dailyStreak);


            const currentStreak =
              Number.isFinite(savedStreak) &&
                      savedStreak >= 0
                  ? Math.floor(savedStreak)
                  : 0;


            // ==================================================
            // 🛡️ ALREADY CLAIMED TODAY
            // ==================================================

            if (lastDailyDate === today) {

              return {

                success: true,

                claimed: false,

                alreadyClaimed: true,

                dailyClaimed: true,

                date: today,

                bonus: 0,

                hashRate: currentHashRate,

                streak: currentStreak,

                dailyStreak: currentStreak,

                message:
                  "🐱🎁 Stella Daily Bonus on jo kerätty tänään!",

              };

            }


            // ==================================================
            // 🔥 CALCULATE NEW STREAK
            // ==================================================
            //
            // Jos eilinen Daily oli kerätty:
            //
            //   streak + 1
            //
            // Muussa tapauksessa:
            //
            //   uusi streak alkaa päivästä 1.
            //
            // ==================================================

            const newDailyStreak =
              lastDailyDate === yesterday
                ? currentStreak + 1
                : 1;


            // ==================================================
            // ⚡ CALCULATE DAILY HASH RATE
            // ==================================================

            const dailyHashRate =
              calculateDailyHashRate(
                newDailyStreak
              );


            // ==================================================
            // 📊 PREVIOUS HASH RATE
            // ==================================================

            const previousHashRate =
              currentHashRate;


            // ==================================================
            // ⚡ NEW HASH RATE
            // ============================================================
            //
            // Daily Hash Rate korvaa vanhan Daily-bonuksen
            // kumulatiivisen lisäämisen.
            //
            // Esimerkiksi:
            //
            // vanha HR = 1.5
            // uusi streak = päivä 4
            // Daily HR = 2.0
            //
            // => hashRate = 2.0
            //
            // ============================================================

            const newHashRate =
              dailyHashRate;


            // ==================================================
            // 🏆 ACHIEVEMENTS
            // ==================================================
            //
            // Luetaan Hot Streak ja Stella's Friend ennen
            // transactionin ensimmäisiä kirjoituksia.
            //
            // ==================================================

            const achievementNow =
              new Date();

            await updateDailyAchievements(
              transaction,
              uid,
              newDailyStreak,
              achievementNow
            );


            // ==================================================
            // 📜 DAILY HISTORY REFERENCE
            // ==================================================

            const dailyHistoryRef =
              createDailyHistoryRef(
                uid,
                today
              );


            // ==================================================
            // 👤 UPDATE USER
            // ==================================================

            transaction.set(
              userRef,
              {

                // ⚡ DAILY HASH RATE

                hashRate:
                  newHashRate,


                // 📅 DAILY

                lastDailyDate:
                  today,


                dailyStreak:
                  newDailyStreak,


                // 🕒 METADATA

                updatedAt:
                  FieldValue.serverTimestamp(),

              },
              {
                merge: true,
              }
            );


            // ==================================================
            // 📜 SAVE DAILY HISTORY
            // ==================================================

            transaction.set(
              dailyHistoryRef,
              {

                type:
                  "dailyCheckIn",


                bonusType:
                  "dailyHashRate",


                // Daily Hash Rate kyseisenä päivänä

                bonus:
                  dailyHashRate,


                // Hash Rate ennen Daily Check-Iniä

                previousHashRate:
                  previousHashRate,


                // Hash Rate Daily Check-Inin jälkeen

                newHashRate:
                  newHashRate,


                // Daily Streak

                streak:
                  newDailyStreak,


                dailyStreak:
                  newDailyStreak,


                // Päivän Hash Rate

                dailyHashRate:
                  dailyHashRate,


                date:
                  today,


                uid:
                  uid,


                createdAt:
                  FieldValue.serverTimestamp(),

              },
              {
                merge: true,
              }
            );


            // ==================================================
            // ✅ SUCCESS RESPONSE
            // ==================================================

            return {

              success: true,

              claimed: true,

              alreadyClaimed: false,

              dailyClaimed: true,

              date: today,

              // Päivän Daily Hash Rate

              bonus:
                dailyHashRate,

              dailyHashRate:
                dailyHashRate,

              // Uusi käyttäjän Hash Rate

              hashRate:
                newHashRate,

              // Streak

              streak:
                newDailyStreak,

              dailyStreak:
                newDailyStreak,

              message:
                `🐱🎁 Daily Bonus kerätty! Päivä ${Math.min(
                  newDailyStreak,
                  DAILY_HASH_RATE_MAX_DAY
                )}: +${dailyHashRate} HR.`,

            };

          }
        );

      } catch (error) {

        console.error(
          "dailyCheckIn error:",
          error
        );


        if (error instanceof HttpsError) {
          throw error;
        }


        throw new HttpsError(
          "internal",
          "Daily Bonus -palkinnon käsittely epäonnistui."
        );

      }

    }
  );


// ============================================================
// 📦 EXPORTS
// ============================================================

module.exports = {

  dailyCheckIn,

};