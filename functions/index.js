"use strict";

const {
  onCall,
  HttpsError,
} = require("firebase-functions/v2/https");

const {
  initializeApp,
} = require("firebase-admin/app");

const {
  getFirestore,
  FieldValue,
} = require("firebase-admin/firestore");


// ============================================================
// 🐱 FIREBASE
// ============================================================

initializeApp();

const db = getFirestore();


// ============================================================
// 🐱⛏️ STELLA MINING SETTINGS
// ============================================================

// Käyttäjän aloitus Hash Rate.
const DEFAULT_HASH_RATE = 1;


// ============================================================
// ⏱️ 24H MINING
// ============================================================

// Yksi Stella Mining -jakso kestää 24 tuntia.
const MINING_DURATION_MS =
  24 * 60 * 60 * 1000;


// ============================================================
// ⚡ MINING SPEED
// ============================================================

// Kuinka paljon STL syntyy:
//
// 1 Hash Rate
// = 0.10 STL tunnissa.
//
// Esimerkki:
//
// 10 Hash Rate
// = 1.00 STL / tunti.
//
const MINING_PER_HASH_PER_HOUR =
  0.10;


// ============================================================
// 🎁 DAILY STELLA BONUS
// ============================================================

const DAILY_HASH_RATE_BONUS = 1;


// ============================================================
// 📺 STELLA POWER BOOST
// ============================================================

// Testimainoksen palkinto.
const AD_HASH_RATE_BONUS = 5;


// Päivän maksimimäärä mainoksia.
const MAX_ADS_PER_DAY = 5;


// Mainosten välinen odotusaika.
//
// 60 minuuttia.
const AD_COOLDOWN_MS =
  60 * 60 * 1000;


// ============================================================
// 📜 HISTORY
// ============================================================

const MAX_TRANSACTION_HISTORY = 50;


// ============================================================
// 🗓️ UTC DATE
// ============================================================

function getUtcDateString() {
  return new Date()
    .toISOString()
    .substring(0, 10);
}


// ============================================================
// 🗓️ YESTERDAY UTC DATE
// ============================================================

function getYesterdayUtcDateString() {
  const date = new Date();

  date.setUTCDate(
    date.getUTCDate() - 1
  );

  return date
    .toISOString()
    .substring(0, 10);
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
// 📜 TRANSACTION HISTORY
// ============================================================

function getHistoryCollection(uid) {
  return getUserRef(uid)
    .collection("transactions");
}


// ============================================================
// 🔢 SAFE NUMBER
// ============================================================

function safeNumber(
  value,
  fallback = 0
) {
  const number = Number(value);

  if (!Number.isFinite(number)) {
    return fallback;
  }

  return number;
}


// ============================================================
// ⏱️ GET TIMESTAMP DATE
// ============================================================

function timestampToDate(value) {
  if (
    value &&
    typeof value.toDate ===
      "function"
  ) {
    return value.toDate();
  }

  return null;
}


// ============================================================
// ⛏️ CALCULATE STL MINING
// ============================================================

function calculateMining(
  hashRate,
  elapsedMilliseconds
) {
  if (elapsedMilliseconds <= 0) {
    return 0;
  }

  const hours =
    elapsedMilliseconds /
    (60 * 60 * 1000);

  return (
    hashRate *
    MINING_PER_HASH_PER_HOUR *
    hours
  );
}


// ============================================================
// ⛏️ GET MINING STATE
//
// Laskee aktiivisen 24h mining-jakson tilanteen.
// ============================================================

function getMiningState(
  data,
  now
) {
  const miningStartedAt =
    timestampToDate(
      data.miningStartedAt
    );

  if (!miningStartedAt) {
    return {
      miningActive: false,

      elapsedMs: 0,

      remainingMs: 0,

      minedAmount: 0,

      completed: false,

      startedAt: null,

      endsAt: null,
    };
  }


  const startMs =
    miningStartedAt.getTime();

  const nowMs =
    now.getTime();

  const rawElapsedMs =
    Math.max(
      0,
      nowMs - startMs
    );


  // Louhinta ei koskaan ylitä 24 tuntia.
  const elapsedMs =
    Math.min(
      rawElapsedMs,
      MINING_DURATION_MS
    );


  const remainingMs =
    Math.max(
      0,
      MINING_DURATION_MS -
        elapsedMs
    );


  const miningActive =
    rawElapsedMs <
      MINING_DURATION_MS;


  const completed =
    !miningActive;


  const endsAt =
    new Date(
      startMs +
        MINING_DURATION_MS
    );


  return {
    miningActive,

    elapsedMs,

    remainingMs,

    completed,

    startedAt:
      miningStartedAt,

    endsAt,

    minedAmount: 0,
  };
}


// ============================================================
// 🐱 GET MINING STATUS
// ============================================================

exports.getMiningStatus =
  onCall(async (request) => {

    // ========================================================
    // AUTH
    // ========================================================

    if (!request.auth) {
      throw new HttpsError(
        "unauthenticated",
        "Kirjaudu sisään jatkaaksesi Stella Miningia. 🐱"
      );
    }


    const uid =
      request.auth.uid;

    const userRef =
      getUserRef(uid);


    // ========================================================
    // LOAD USER
    // ========================================================

    const snapshot =
      await userRef.get();

    const data =
      snapshot.exists
        ? snapshot.data()
        : {};


    const now =
      new Date();


    // ========================================================
    // HASH RATE
    // ========================================================

    const hashRate =
      safeNumber(
        data.hashRate,
        DEFAULT_HASH_RATE
      );


    // ========================================================
    // STORED STL
    // ========================================================

    const miningBalance =
      safeNumber(
        data.miningBalance,
        0
      );


    // ========================================================
    // MINING STATE
    // ========================================================

    const miningState =
      getMiningState(
        data,
        now
      );


    let unclaimedMining = 0;


    // ========================================================
    // REALTIME STL
    // ========================================================

    if (
      data.miningStartedAt &&
      miningState.elapsedMs > 0
    ) {
      unclaimedMining =
        calculateMining(
          hashRate,
          miningState.elapsedMs
        );
    }


    const estimatedTotal =
      miningBalance +
      unclaimedMining;


    // ========================================================
    // DAILY CHECK-IN
    // ========================================================

    const today =
      getUtcDateString();

    const yesterday =
      getYesterdayUtcDateString();

    const lastDaily =
      String(
        data.lastDaily || ""
      );

    let streak =
      safeNumber(
        data.streak,
        0
      );


    if (
      lastDaily !== today &&
      lastDaily !== yesterday
    ) {
      streak = 0;
    }


    // ========================================================
    // 📺 AD COUNT
    // ========================================================

    const adDate =
      String(
        data.adDate || ""
      );

    let adsToday =
      safeNumber(
        data.adsToday,
        0
      );


    if (adDate !== today) {
      adsToday = 0;
    }


    // ========================================================
    // 📺 AD COOLDOWN
    // ========================================================

    let cooldownRemainingMs = 0;

    const lastAdTime =
      timestampToDate(
        data.lastAdTimestamp
      );


    if (lastAdTime) {
      const elapsed =
        now.getTime() -
        lastAdTime.getTime();

      cooldownRemainingMs =
        Math.max(
          0,
          AD_COOLDOWN_MS -
            elapsed
        );
    }


    // ========================================================
    // 📺 CAN WATCH AD
    // ========================================================

    const canWatchAd =
      adsToday <
        MAX_ADS_PER_DAY &&
      cooldownRemainingMs === 0;


    // ========================================================
    // 🐱 RESPONSE
    // ========================================================

    return {
      // ======================================================
      // ⛏️ MINING
      // ======================================================

      hashRate,

      miningBalance,

      unclaimedMining,

      estimatedTotal,

      miningActive:
        miningState.miningActive,

      miningRemainingMs:
        miningState.remainingMs,

      miningDurationMs:
        MINING_DURATION_MS,

      miningElapsedMs:
        miningState.elapsedMs,

      miningStartedAt:
        miningState.startedAt
          ? miningState.startedAt
              .toISOString()
          : null,

      miningEndsAt:
        miningState.endsAt
          ? miningState.endsAt
              .toISOString()
          : null,


      // ======================================================
      // ⚡ SPEED
      // ======================================================

      miningPerHour:
        hashRate *
        MINING_PER_HASH_PER_HOUR,


      // ======================================================
      // 🎁 DAILY
      // ======================================================

      dailyClaimed:
        lastDaily === today,

      streak,

      dailyHashRateBonus:
        DAILY_HASH_RATE_BONUS,


      // ======================================================
      // 📺 ADS
      // ======================================================

      adsToday,

      maxAdsPerDay:
        MAX_ADS_PER_DAY,

      adHashRateBonus:
        AD_HASH_RATE_BONUS,

      canWatchAd,

      cooldownRemainingMs,
    };
  });


// ============================================================
// 🐱⛏️ START 24H MINING
// ============================================================

exports.startMining =
  onCall(async (request) => {

    // ========================================================
    // AUTH
    // ========================================================

    if (!request.auth) {
      throw new HttpsError(
        "unauthenticated",
        "Kirjaudu sisään jatkaaksesi."
      );
    }


    const uid =
      request.auth.uid;

    const userRef =
      getUserRef(uid);

    const now =
      new Date();


    // ========================================================
    // FIRESTORE TRANSACTION
    // ========================================================

    return await db.runTransaction(
      async (transaction) => {

        const snapshot =
          await transaction.get(
            userRef
          );

        const data =
          snapshot.exists
            ? snapshot.data()
            : {};


        // ====================================================
        // HASH RATE
        // ====================================================

        const hashRate =
          safeNumber(
            data.hashRate,
            DEFAULT_HASH_RATE
          );


        // ====================================================
        // OLD BALANCE
        // ====================================================

        let miningBalance =
          safeNumber(
            data.miningBalance,
            0
          );


        // ====================================================
        // CURRENT MINING
        // ====================================================

        const miningState =
          getMiningState(
            data,
            now
          );


        // ====================================================
        // ACTIVE MINING
        // ====================================================

        if (
          miningState.miningActive
        ) {
          return {
            success: true,

            alreadyActive: true,

            miningActive: true,

            miningRemainingMs:
              miningState.remainingMs,

            message:
              "🐱⛏️ Stella Mining on jo käynnissä!",
          };
        }


        // ====================================================
        // FINISHED PREVIOUS MINING
        //
        // Tallennetaan vanhan 24h jakson STL.
        // ====================================================

        if (
          data.miningStartedAt &&
          miningState.completed
        ) {
          const previousMining =
            calculateMining(
              hashRate,
              MINING_DURATION_MS
            );


          miningBalance +=
            previousMining;


          // ==================================================
          // HISTORY
          // ==================================================

          const historyRef =
            getHistoryCollection(uid)
              .doc();


          transaction.set(
            historyRef,
            {
              type:
                "mining_completed",

              title:
                "🐱⛏️ Stella Mining Complete",

              amount:
                previousMining,

              balanceAfter:
                miningBalance,

              hashRate,

              durationHours:
                24,

              createdAt:
                FieldValue.serverTimestamp(),
            }
          );
        }


        // ====================================================
        // START NEW 24H MINING
        // ====================================================

        transaction.set(
          userRef,
          {
            hashRate,

            miningBalance,

            miningStartedAt:
              FieldValue.serverTimestamp(),

            miningCycle:
              FieldValue.increment(1),

            updatedAt:
              FieldValue.serverTimestamp(),
          },
          {
            merge: true,
          }
        );


        return {
          success: true,

          alreadyActive: false,

          miningActive: true,

          miningDurationMs:
            MINING_DURATION_MS,

          miningRemainingMs:
            MINING_DURATION_MS,

          hashRate,

          miningBalance,

          message:
            "🐱✨ Stella Mining käynnistyi! "
            "STL juoksee seuraavat 24 tuntia ⛏️⚡",
        };
      }
    );
  });


// ============================================================
// 🎁🐱 DAILY STELLA CHECK-IN
// ============================================================

exports.dailyCheckIn =
  onCall(async (request) => {

    // ========================================================
    // AUTH
    // ========================================================

    if (!request.auth) {
      throw new HttpsError(
        "unauthenticated",
        "Kirjaudu sisään jatkaaksesi."
      );
    }


    const uid =
      request.auth.uid;

    const userRef =
      getUserRef(uid);

    const today =
      getUtcDateString();

    const yesterday =
      getYesterdayUtcDateString();


    // ========================================================
    // TRANSACTION
    // ========================================================

    return await db.runTransaction(
      async (transaction) => {

        const snapshot =
          await transaction.get(
            userRef
          );

        const data =
          snapshot.exists
            ? snapshot.data()
            : {};


        // ====================================================
        // HASH RATE
        // ====================================================

        const oldHashRate =
          safeNumber(
            data.hashRate,
            DEFAULT_HASH_RATE
          );


        // ====================================================
        // STREAK
        // ====================================================

        const oldStreak =
          safeNumber(
            data.streak,
            0
          );


        const lastDaily =
          String(
            data.lastDaily || ""
          );


        // ====================================================
        // ALREADY CLAIMED
        // ====================================================

        if (
          lastDaily === today
        ) {
          return {
            alreadyClaimed: true,

            hashRate:
              oldHashRate,

            streak:
              oldStreak,

            bonus: 0,
          };
        }


        // ====================================================
        // NEW STREAK
        // ====================================================

        const newStreak =
          lastDaily === yesterday
            ? oldStreak + 1
            : 1;


        // ====================================================
        // HASH RATE BONUS
        // ====================================================

        const bonus =
          DAILY_HASH_RATE_BONUS;


        const newHashRate =
          oldHashRate +
          bonus;


        // ====================================================
        // UPDATE USER
        // ====================================================

        transaction.set(
          userRef,
          {
            hashRate:
              newHashRate,

            streak:
              newStreak,

            lastDaily:
              today,

            updatedAt:
              FieldValue.serverTimestamp(),
          },
          {
            merge: true,
          }
        );


        // ====================================================
        // HISTORY
        // ====================================================

        const historyRef =
          getHistoryCollection(uid)
            .doc(
              `daily_${today}`
            );


        transaction.set(
          historyRef,
          {
            type:
              "daily_hashrate",

            title:
              "🐱 Stella Daily Bonus ⚡",

            amount:
              bonus,

            hashRateAfter:
              newHashRate,

            streak:
              newStreak,

            createdAt:
              FieldValue.serverTimestamp(),
          }
        );


        return {
          alreadyClaimed: false,

          hashRate:
            newHashRate,

          streak:
            newStreak,

          bonus,
        };
      }
    );
  });


// ============================================================
// 📺🐱 TEST ADMOB REWARD
//
// Käytetään kehityksen aikana Google Test Adsilla.
// ============================================================

exports.testAdReward =
  onCall(async (request) => {

    // ========================================================
    // AUTH
    // ========================================================

    if (!request.auth) {
      throw new HttpsError(
        "unauthenticated",
        "Kirjaudu sisään jatkaaksesi."
      );
    }


    const uid =
      request.auth.uid;

    const userRef =
      getUserRef(uid);

    const now =
      new Date();

    const today =
      getUtcDateString();


    // ========================================================
    // TRANSACTION
    // ========================================================

    return await db.runTransaction(
      async (transaction) => {

        const snapshot =
          await transaction.get(
            userRef
          );

        const data =
          snapshot.exists
            ? snapshot.data()
            : {};


        // ====================================================
        // 📺 DAILY AD COUNT
        // ====================================================

        let adsToday =
          safeNumber(
            data.adsToday,
            0
          );


        const adDate =
          String(
            data.adDate || ""
          );


        if (adDate !== today) {
          adsToday = 0;
        }


        // ====================================================
        // DAILY LIMIT
        // ====================================================

        if (
          adsToday >=
            MAX_ADS_PER_DAY
        ) {
          throw new HttpsError(
            "resource-exhausted",
            "🐱 Päivän Stella-mainosraja on saavutettu."
          );
        }


        // ====================================================
        // COOLDOWN
        // ====================================================

        const lastAdTime =
          timestampToDate(
            data.lastAdTimestamp
          );


        if (lastAdTime) {
          const elapsed =
            now.getTime() -
            lastAdTime.getTime();


          if (
            elapsed <
              AD_COOLDOWN_MS
          ) {
            const remainingMinutes =
              Math.ceil(
                (
                  AD_COOLDOWN_MS -
                  elapsed
                ) / 60000
              );


            throw new HttpsError(
              "failed-precondition",
              `🐱 Stella lepää vielä ${remainingMinutes} minuuttia.`
            );
          }
        }


        // ====================================================
        // HASH RATE
        // ====================================================

        const oldHashRate =
          safeNumber(
            data.hashRate,
            DEFAULT_HASH_RATE
          );


        const bonus =
          AD_HASH_RATE_BONUS;


        const newHashRate =
          oldHashRate +
          bonus;


        const newAdsToday =
          adsToday + 1;


        // ====================================================
        // UPDATE USER
        // ====================================================

        transaction.set(
          userRef,
          {
            hashRate:
              newHashRate,

            adsToday:
              newAdsToday,

            adDate:
              today,

            lastAdTimestamp:
              FieldValue.serverTimestamp(),

            updatedAt:
              FieldValue.serverTimestamp(),
          },
          {
            merge: true,
          }
        );


        // ====================================================
        // HISTORY
        // ====================================================

        const historyRef =
          getHistoryCollection(uid)
            .doc();


        transaction.set(
          historyRef,
          {
            type:
              "ad_hashrate",

            title:
              "📺🐱 Stella Power Boost ⚡",

            amount:
              bonus,

            hashRateAfter:
              newHashRate,

            adsToday:
              newAdsToday,

            createdAt:
              FieldValue.serverTimestamp(),
          }
        );


        return {
          success: true,

          bonus,

          hashRate:
            newHashRate,

          adsToday:
            newAdsToday,

          message:
            "🐱⚡ Stella Power Boost aktivoitu!",
        };
      }
    );
  });


// ============================================================
// 📜🐱 GET TRANSACTION HISTORY
// ============================================================

exports.getTransactionHistory =
  onCall(async (request) => {

    // ========================================================
    // AUTH
    // ========================================================

    if (!request.auth) {
      throw new HttpsError(
        "unauthenticated",
        "Kirjaudu sisään jatkaaksesi."
      );
    }


    const uid =
      request.auth.uid;


    // ========================================================
    // GET HISTORY
    // ========================================================

    const snapshot =
      await getHistoryCollection(uid)
        .orderBy(
          "createdAt",
          "desc"
        )
        .limit(
          MAX_TRANSACTION_HISTORY
        )
        .get();


    // ========================================================
    // FORMAT HISTORY
    // ========================================================

    const transactions =
      snapshot.docs.map(
        (doc) => {

          const data =
            doc.data();


          const createdAtDate =
            timestampToDate(
              data.createdAt
            );


          return {
            id:
              doc.id,

            type:
              String(
                data.type || ""
              ),

            title:
              String(
                data.title || ""
              ),

            amount:
              safeNumber(
                data.amount,
                0
              ),

            balanceAfter:
              safeNumber(
                data.balanceAfter,
                0
              ),

            hashRateAfter:
              safeNumber(
                data.hashRateAfter,
                0
              ),

            hashRate:
              safeNumber(
                data.hashRate,
                0
              ),

            streak:
              safeNumber(
                data.streak,
                0
              ),

            adsToday:
              safeNumber(
                data.adsToday,
                0
              ),

            createdAt:
              createdAtDate
                ? createdAtDate
                    .toISOString()
                : null,
          };
        }
      );


    // ========================================================
    // RESPONSE
    // ========================================================

    return {
      transactions,
    };
  });