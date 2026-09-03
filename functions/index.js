"use strict";

const crypto = require("crypto");

const {
  onCall,
  onRequest,
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
// 🐱 STELLA MINING SETTINGS
// ============================================================

// Aloitus Hash Rate.
const DEFAULT_HASH_RATE = 1;


// ============================================================
// 🎁 DAILY STELLA BONUS
// ============================================================

const DAILY_HASH_RATE_BONUS = 1;


// ============================================================
// 📺 STELLA AD BONUS
// ============================================================

// Mainoksen katsomisesta saatava Hash Rate bonus.
const AD_HASH_RATE_BONUS = 5;

// Mainosten maksimimäärä päivässä.
const MAX_ADS_PER_DAY = 5;

// Mainosten välinen odotusaika.
// 60 minuuttia.
const AD_COOLDOWN_MS =
  60 * 60 * 1000;


// ============================================================
// ⛏️ STELLA MINING SESSION
// ============================================================

// Louhinta kestää 24 tuntia.
const MINING_DURATION_MS =
  24 * 60 * 60 * 1000;


// ============================================================
// 💎 STL MINING SPEED
// ============================================================

// Kuinka paljon STL syntyy
// yhdellä Hash Rate -yksiköllä tunnissa.
//
// Esimerkki:
//
// Hash Rate = 10
//
// 10 × 0.10
//
// = 1 STL tunnissa.
//
const MINING_PER_HASH_PER_HOUR = 0.10;


// ============================================================
// 📜 HISTORY
// ============================================================

const MAX_TRANSACTION_HISTORY = 50;


// ============================================================
// 📺 ADMOB SERVER SIDE VERIFICATION
// ============================================================

const ADMOB_KEY_URL =
  "https://www.gstatic.com/admob/reward/verifier-keys.json";

const ADMOB_KEY_CACHE_MS =
  60 * 60 * 1000;


// ============================================================
// 🔐 ADMOB KEY CACHE
// ============================================================

let cachedAdMobKeys = null;

let adMobKeysCachedAt = 0;


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
// 📁 USER REFERENCE
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
// 📺 ADMOB REWARD COLLECTION
// ============================================================

function getAdMobRewardRef(transactionId) {
  return db
    .collection("admobRewards")
    .doc(transactionId);
}


// ============================================================
// ⛏️ CALCULATE MINING
// ============================================================

function calculateMining(
  hashRate,
  elapsedMilliseconds
) {

  if (
    elapsedMilliseconds <= 0
  ) {
    return 0;
  }

  const hours =
    elapsedMilliseconds /
    (1000 * 60 * 60);

  return (
    hashRate *
    MINING_PER_HASH_PER_HOUR *
    hours
  );
}


// ============================================================
// ⏱️ GET TIMESTAMP DATE
// ============================================================

function getTimestampDate(timestamp) {

  if (
    timestamp &&
    typeof timestamp.toDate === "function"
  ) {
    return timestamp.toDate();
  }

  return null;
}


// ============================================================
// ⛏️ GET MINING START TIME
// ============================================================

function getMiningStartTime(data) {
  return getTimestampDate(
    data.miningStartedAt
  );
}


// ============================================================
// ⏱️ GET MINING END TIME
// ============================================================

function getMiningEndTime(data) {
  return getTimestampDate(
    data.miningEndsAt
  );
}


// ============================================================
// 🐱 GET CURRENT MINING SESSION
// ============================================================

function getMiningSessionStatus(
  data,
  now
) {

  const startTime =
    getMiningStartTime(data);

  const endTime =
    getMiningEndTime(data);

  const hashRate =
    Number(
      data.miningSessionHashRate ||
      data.hashRate ||
      DEFAULT_HASH_RATE
    );


  // ==========================================================
  // NO SESSION
  // ==========================================================

  if (
    !startTime ||
    !endTime
  ) {
    return {
      active: false,
      completed: false,
      startTime: null,
      endTime: null,
      hashRate,
      elapsedMs: 0,
      remainingMs: 0,
      minedAmount: 0,
    };
  }


  // ==========================================================
  // SESSION COMPLETED
  // ==========================================================

  if (
    now.getTime() >=
    endTime.getTime()
  ) {

    const elapsedMs =
      Math.max(
        0,
        endTime.getTime() -
          startTime.getTime()
      );

    return {
      active: false,
      completed: true,
      startTime,
      endTime,
      hashRate,
      elapsedMs,
      remainingMs: 0,
      minedAmount:
        calculateMining(
          hashRate,
          elapsedMs
        ),
    };
  }


  // ==========================================================
  // SESSION ACTIVE
  // ==========================================================

  const elapsedMs =
    Math.max(
      0,
      now.getTime() -
        startTime.getTime()
    );

  const remainingMs =
    Math.max(
      0,
      endTime.getTime() -
        now.getTime()
    );


  return {
    active: true,
    completed: false,
    startTime,
    endTime,
    hashRate,
    elapsedMs,
    remainingMs,
    minedAmount:
      calculateMining(
        hashRate,
        elapsedMs
      ),
  };
}


// ============================================================
// 💰 GET STORED BALANCE
// ============================================================

function getStoredBalance(data) {

  return Number(
    data.miningBalance || 0
  );
}


// ============================================================
// 🔑 GET ADMOB PUBLIC KEYS
// ============================================================

async function getAdMobPublicKeys() {

  const now = Date.now();


  if (
    cachedAdMobKeys &&
    now - adMobKeysCachedAt <
      ADMOB_KEY_CACHE_MS
  ) {
    return cachedAdMobKeys;
  }


  const response =
    await fetch(
      ADMOB_KEY_URL
    );


  if (!response.ok) {
    throw new Error(
      "AdMob public keys could not be loaded."
    );
  }


  const data =
    await response.json();


  if (
    !data ||
    !Array.isArray(data.keys)
  ) {
    throw new Error(
      "Invalid AdMob public key response."
    );
  }


  const keys = new Map();


  for (const key of data.keys) {

    if (
      key &&
      key.keyId !== undefined &&
      key.pem
    ) {

      keys.set(
        String(key.keyId),
        key.pem
      );
    }
  }


  cachedAdMobKeys =
    keys;

  adMobKeysCachedAt =
    now;


  return keys;
}


// ============================================================
// 🔐 BASE64 URL DECODE
// ============================================================

function base64UrlDecode(value) {

  let base64 =
    String(value)
      .replace(/-/g, "+")
      .replace(/_/g, "/");


  while (
    base64.length % 4 !== 0
  ) {
    base64 += "=";
  }


  return Buffer.from(
    base64,
    "base64"
  );
}


// ============================================================
// 🔐 BUILD ADMOB SIGNED QUERY
// ============================================================

function buildSignedQueryString(
  originalUrl
) {

  const questionMarkIndex =
    originalUrl.indexOf("?");


  if (
    questionMarkIndex === -1
  ) {
    throw new Error(
      "Missing AdMob query string."
    );
  }


  const queryString =
    originalUrl.substring(
      questionMarkIndex + 1
    );


  const parts =
    queryString.split("&");


  const signedParts = [];


  for (const part of parts) {

    if (
      part.startsWith("signature=") ||
      part.startsWith("key_id=")
    ) {
      continue;
    }

    signedParts.push(part);
  }


  return Buffer.from(
    signedParts.join("&"),
    "utf8"
  );
}


// ============================================================
// 🔐 VERIFY ADMOB CALLBACK
// ============================================================

async function verifyAdMobCallback(req) {

  const signature =
    req.query.signature;

  const keyId =
    req.query.key_id;


  if (
    !signature ||
    !keyId
  ) {
    throw new Error(
      "Missing AdMob signature."
    );
  }


  const publicKeys =
    await getAdMobPublicKeys();


  const pem =
    publicKeys.get(
      String(keyId)
    );


  if (!pem) {
    throw new Error(
      "Unknown AdMob key ID."
    );
  }


  const signedData =
    buildSignedQueryString(
      req.originalUrl
    );


  const signatureBuffer =
    base64UrlDecode(
      signature
    );


  const verifier =
    crypto.createVerify(
      "SHA256"
    );


  verifier.update(
    signedData
  );

  verifier.end();


  const valid =
    verifier.verify(
      pem,
      signatureBuffer
    );


  if (!valid) {
    throw new Error(
      "Invalid AdMob signature."
    );
  }


  return true;
}


// ============================================================
// 🐱 START STELLA MINING
// ============================================================

exports.startMining =
  onCall(async (request) => {

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


        const now =
          new Date();


        // ====================================================
        // CURRENT SESSION
        // ====================================================

        const session =
          getMiningSessionStatus(
            data,
            now
          );


        // ====================================================
        // ALREADY MINING
        // ====================================================

        if (session.active) {

          return {
            success: true,

            alreadyMining: true,

            miningActive: true,

            remainingMs:
              session.remainingMs,

            message:
              "Stella Mining on jo käynnissä! 🐱⛏️",
          };
        }


        // ====================================================
        // HASH RATE
        // ====================================================

        const hashRate =
          Number(
            data.hashRate ||
            DEFAULT_HASH_RATE
          );


        // ====================================================
        // NEW 24H SESSION
        // ====================================================

        const miningEndsAt =
          new Date(
            now.getTime() +
              MINING_DURATION_MS
          );


        transaction.set(
          userRef,
          {
            hashRate,

            miningActive: true,

            miningStartedAt:
              now,

            miningEndsAt:
              miningEndsAt,

            miningSessionHashRate:
              hashRate,

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
              "mining_started",

            title:
              "Stella Mining Started 🐱⛏️",

            amount:
              0,

            hashRate,

            durationHours:
              24,

            createdAt:
              FieldValue.serverTimestamp(),
          }
        );


        return {
          success: true,

          alreadyMining: false,

          miningActive: true,

          hashRate,

          miningDurationMs:
            MINING_DURATION_MS,

          remainingMs:
            MINING_DURATION_MS,

          message:
            "Stella Mining käynnistyi 24 tunniksi! 🐱⛏️✨",
        };
      }
    );
  });


// ============================================================
// 🐱 GET STELLA MINING STATUS
// ============================================================

exports.getMiningStatus =
  onCall(async (request) => {

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
      Number(
        data.hashRate ||
        DEFAULT_HASH_RATE
      );


    // ========================================================
    // STORED BALANCE
    // ========================================================

    const miningBalance =
      getStoredBalance(data);


    // ========================================================
    // MINING SESSION
    // ========================================================

    const session =
      getMiningSessionStatus(
        data,
        now
      );


    // ========================================================
    // REALTIME MINING
    // ========================================================

    const unclaimedMining =
      session.minedAmount;


    const estimatedTotal =
      miningBalance +
      unclaimedMining;


    // ========================================================
    // AD STATUS
    // ========================================================

    const today =
      getUtcDateString();


    let adsToday =
      Number(
        data.adsToday || 0
      );


    const adDate =
      String(
        data.adDate || ""
      );


    if (
      adDate !== today
    ) {
      adsToday = 0;
    }


    // ========================================================
    // AD COOLDOWN
    // ========================================================

    let cooldownRemainingMs = 0;


    const lastAdTimestamp =
      data.lastAdTimestamp;


    if (
      lastAdTimestamp &&
      typeof lastAdTimestamp.toDate ===
        "function"
    ) {

      const lastAdTime =
        lastAdTimestamp.toDate();


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
    // DAILY
    // ========================================================

    const lastDaily =
      String(
        data.lastDaily || ""
      );


    let streak =
      Number(
        data.streak || 0
      );


    const yesterday =
      getYesterdayUtcDateString();


    if (
      lastDaily !== today &&
      lastDaily !== yesterday
    ) {
      streak = 0;
    }


    // ========================================================
    // RETURN STATUS
    // ========================================================

    return {

      // ================================================
      // 🐱 HASH RATE
      // ================================================

      hashRate,


      // ================================================
      // 💰 STL BALANCE
      // ================================================

      miningBalance,

      unclaimedMining,

      estimatedTotal,


      // ================================================
      // ⛏️ MINING SESSION
      // ================================================

      miningActive:
        session.active,

      miningCompleted:
        session.completed,

      miningRemainingMs:
        session.remainingMs,

      miningElapsedMs:
        session.elapsedMs,

      miningDurationMs:
        MINING_DURATION_MS,

      miningStartedAt:
        session.startTime
          ? session.startTime.toISOString()
          : null,

      miningEndsAt:
        session.endTime
          ? session.endTime.toISOString()
          : null,

      miningSessionHashRate:
        session.hashRate,


      // ================================================
      // ⚡ MINING SPEED
      // ================================================

      miningPerHour:
        session.hashRate *
        MINING_PER_HASH_PER_HOUR,


      // ================================================
      // 🎁 DAILY
      // ================================================

      dailyClaimed:
        lastDaily === today,

      streak,

      dailyHashRateBonus:
        DAILY_HASH_RATE_BONUS,


      // ================================================
      // 📺 ADS
      // ================================================

      adsToday,

      maxAdsPerDay:
        MAX_ADS_PER_DAY,

      adHashRateBonus:
        AD_HASH_RATE_BONUS,

      canWatchAd:
        adsToday <
          MAX_ADS_PER_DAY &&
        cooldownRemainingMs === 0,

      cooldownRemainingMs,
    };
  });


// ============================================================
// 💰 COLLECT FINISHED MINING
// ============================================================

exports.claimMining =
  onCall(async (request) => {

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


        const now =
          new Date();


        const session =
          getMiningSessionStatus(
            data,
            now
          );


        // ====================================================
        // NO MINING
        // ====================================================

        if (
          !session.startTime ||
          !session.endTime
        ) {

          return {
            success: false,

            claimed: 0,

            miningActive: false,

            message:
              "Stella Mining ei ole vielä käynnissä 🐱",
          };
        }


        // ====================================================
        // STILL MINING
        // ====================================================

        if (session.active) {

          return {
            success: false,

            claimed: 0,

            miningActive: true,

            remainingMs:
              session.remainingMs,

            message:
              "Stella louhii vielä! 🐱⛏️✨",
          };
        }


        // ====================================================
        // SESSION FINISHED
        // ====================================================

        const oldBalance =
          getStoredBalance(data);


        const mined =
          session.minedAmount;


        const newBalance =
          oldBalance +
          mined;


        // ====================================================
        // UPDATE BALANCE
        // ====================================================

        transaction.set(
          userRef,
          {
            miningBalance:
              newBalance,

            miningActive:
              false,

            miningStartedAt:
              null,

            miningEndsAt:
              null,

            miningSessionHashRate:
              null,

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
              "mining_completed",

            title:
              "Stella Mining Complete 🐱⛏️💎",

            amount:
              mined,

            balanceAfter:
              newBalance,

            hashRate:
              session.hashRate,

            durationHours:
              24,

            createdAt:
              FieldValue.serverTimestamp(),
          }
        );


        return {
          success: true,

          claimed:
            mined,

          balance:
            newBalance,

          miningActive:
            false,

          message:
            `🐱 Stella toi sinulle ${mined.toFixed(2)} STL! 💎✨`,
        };
      }
    );
  });


// ============================================================
// 🐱 DAILY STELLA CHECK-IN
// ============================================================

exports.dailyCheckIn =
  onCall(async (request) => {

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


        const oldHashRate =
          Number(
            data.hashRate ||
            DEFAULT_HASH_RATE
          );


        const oldStreak =
          Number(
            data.streak || 0
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
        // STREAK
        // ====================================================

        const newStreak =
          lastDaily === yesterday
            ? oldStreak + 1
            : 1;


        // ====================================================
        // HASH RATE
        // ====================================================

        const newHashRate =
          oldHashRate +
          DAILY_HASH_RATE_BONUS;


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
            .doc(`daily_${today}`);


        transaction.set(
          historyRef,
          {
            type:
              "daily_hashrate",

            title:
              "Stella Daily Bonus 🐱⚡",

            amount:
              DAILY_HASH_RATE_BONUS,

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

          bonus:
            DAILY_HASH_RATE_BONUS,
        };
      }
    );
  });


// ============================================================
// 📺 TEST AD REWARD
//
// Käytetään kehityksen aikana Google testimainosten kanssa.
//
// Tämä voidaan myöhemmin poistaa,
// kun oikea AdMob SSV on täysin käytössä.
// ============================================================

exports.testAdReward =
  onCall(async (request) => {

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
        // ADS TODAY
        // ====================================================

        let adsToday =
          Number(
            data.adsToday || 0
          );


        const adDate =
          String(
            data.adDate || ""
          );


        if (
          adDate !== today
        ) {
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
            "Päivän Stella-mainosraja on saavutettu 🐱"
          );
        }


        // ====================================================
        // COOLDOWN
        // ====================================================

        const lastAdTime =
          getTimestampDate(
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
              `Stella lepää vielä ${remainingMinutes} minuuttia 🐱💤`
            );
          }
        }


        // ====================================================
        // HASH RATE
        // ====================================================

        const oldHashRate =
          Number(
            data.hashRate ||
            DEFAULT_HASH_RATE
          );


        const newHashRate =
          oldHashRate +
          AD_HASH_RATE_BONUS;


        const newAdsToday =
          adsToday + 1;


        // ====================================================
        // START / RESTART MINING
        // ====================================================

        const miningEndsAt =
          new Date(
            now.getTime() +
              MINING_DURATION_MS
          );


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
              now,

            // 🐱 Mainos käynnistää uuden
            // 24 tunnin Stella Mining session.
            miningActive:
              true,

            miningStartedAt:
              now,

            miningEndsAt:
              miningEndsAt,

            miningSessionHashRate:
              newHashRate,

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
              "Stella Power Boost 📺🐱⚡",

            amount:
              AD_HASH_RATE_BONUS,

            hashRateAfter:
              newHashRate,

            adsToday:
              newAdsToday,

            miningStarted:
              true,

            miningDurationHours:
              24,

            createdAt:
              FieldValue.serverTimestamp(),
          }
        );


        return {
          success: true,

          bonus:
            AD_HASH_RATE_BONUS,

          hashRate:
            newHashRate,

          adsToday:
            newAdsToday,

          miningActive:
            true,

          miningDurationMs:
            MINING_DURATION_MS,

          message:
            "🐱⚡ Stella Power Boost! Uusi 24h louhinta käynnistyi! ⛏️💎",
        };
      }
    );
  });


// ============================================================
// 📺 ADMOB SERVER-SIDE REWARD
//
// Käytetään myöhemmin oikeiden AdMob-mainosten kanssa.
// ============================================================

exports.adMobReward =
  onRequest(
    {
      region: "us-central1",
    },

    async (req, res) => {

      try {

        // ====================================================
        // ONLY GET
        // ====================================================

        if (
          req.method !== "GET"
        ) {

          res
            .status(405)
            .send("Method Not Allowed");

          return;
        }


        // ====================================================
        // VERIFY GOOGLE SIGNATURE
        // ====================================================

        await verifyAdMobCallback(
          req
        );


        // ====================================================
        // PARAMETERS
        // ====================================================

        const uid =
          String(
            req.query.user_id || ""
          );


        const transactionId =
          String(
            req.query.transaction_id || ""
          );


        if (!uid) {

          res
            .status(400)
            .send("Missing user_id");

          return;
        }


        if (!transactionId) {

          res
            .status(400)
            .send(
              "Missing transaction_id"
            );

          return;
        }


        const userRef =
          getUserRef(uid);


        const rewardRef =
          getAdMobRewardRef(
            transactionId
          );


        const now =
          new Date();

        const today =
          getUtcDateString();


        // ====================================================
        // FIRESTORE TRANSACTION
        // ====================================================

        const result =
          await db.runTransaction(
            async (transaction) => {

              // ==============================================
              // DUPLICATE CHECK
              // ==============================================

              const rewardSnapshot =
                await transaction.get(
                  rewardRef
                );


              if (
                rewardSnapshot.exists
              ) {

                return {
                  duplicate: true,
                };
              }


              // ==============================================
              // USER DATA
              // ==============================================

              const userSnapshot =
                await transaction.get(
                  userRef
                );


              const data =
                userSnapshot.exists
                  ? userSnapshot.data()
                  : {};


              let adsToday =
                Number(
                  data.adsToday || 0
                );


              const adDate =
                String(
                  data.adDate || ""
                );


              if (
                adDate !== today
              ) {
                adsToday = 0;
              }


              // ==============================================
              // DAILY LIMIT
              // ==============================================

              if (
                adsToday >=
                MAX_ADS_PER_DAY
              ) {

                return {
                  rejected: true,
                  reason:
                    "daily_limit",
                };
              }


              // ==============================================
              // COOLDOWN
              // ==============================================

              const lastAdTime =
                getTimestampDate(
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

                  return {
                    rejected: true,
                    reason:
                      "cooldown",
                  };
                }
              }


              // ==============================================
              // HASH RATE
              // ==============================================

              const oldHashRate =
                Number(
                  data.hashRate ||
                  DEFAULT_HASH_RATE
                );


              const newHashRate =
                oldHashRate +
                AD_HASH_RATE_BONUS;


              const newAdsToday =
                adsToday + 1;


              // ==============================================
              // NEW 24H SESSION
              // ==============================================

              const miningEndsAt =
                new Date(
                  now.getTime() +
                    MINING_DURATION_MS
                );


              // ==============================================
              // UPDATE USER
              // ==============================================

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
                    now,

                  miningActive:
                    true,

                  miningStartedAt:
                    now,

                  miningEndsAt:
                    miningEndsAt,

                  miningSessionHashRate:
                    newHashRate,

                  updatedAt:
                    FieldValue.serverTimestamp(),
                },
                {
                  merge: true,
                }
              );


              // ==============================================
              // SAVE ADMOB TRANSACTION
              // ==============================================

              transaction.set(
                rewardRef,
                {
                  uid,

                  transactionId,

                  adUnit:
                    String(
                      req.query.ad_unit ||
                        ""
                    ),

                  adNetwork:
                    String(
                      req.query.ad_network ||
                        ""
                    ),

                  rewardAmount:
                    String(
                      req.query.reward_amount ||
                        ""
                    ),

                  rewardItem:
                    String(
                      req.query.reward_item ||
                        ""
                    ),

                  timestamp:
                    String(
                      req.query.timestamp ||
                        ""
                    ),

                  createdAt:
                    FieldValue.serverTimestamp(),
                }
              );


              // ==============================================
              // HISTORY
              // ==============================================

              const historyRef =
                getHistoryCollection(uid)
                  .doc();


              transaction.set(
                historyRef,
                {
                  type:
                    "ad_hashrate",

                  title:
                    "Stella Power Boost 📺🐱⚡",

                  amount:
                    AD_HASH_RATE_BONUS,

                  hashRateAfter:
                    newHashRate,

                  adsToday:
                    newAdsToday,

                  admobTransactionId:
                    transactionId,

                  miningStarted:
                    true,

                  miningDurationHours:
                    24,

                  createdAt:
                    FieldValue.serverTimestamp(),
                }
              );


              return {
                success: true,

                bonus:
                  AD_HASH_RATE_BONUS,

                hashRate:
                  newHashRate,

                adsToday:
                  newAdsToday,
              };
            }
          );


        // ====================================================
        // RESPONSE
        // ====================================================

        if (
          result.duplicate
        ) {

          res
            .status(200)
            .send("Duplicate ignored");

          return;
        }


        if (
          result.rejected
        ) {

          res
            .status(200)
            .send(
              `Reward rejected: ${result.reason}`
            );

          return;
        }


        res
          .status(200)
          .send("Reward processed");

      } catch (error) {

        console.error(
          "🐱 AdMob reward error:",
          error
        );


        res
          .status(400)
          .send(
            "Invalid reward callback"
          );
      }
    }
  );


// ============================================================
// 📜 GET TRANSACTION HISTORY
// ============================================================

exports.getTransactionHistory =
  onCall(async (request) => {

    if (!request.auth) {
      throw new HttpsError(
        "unauthenticated",
        "Kirjaudu sisään jatkaaksesi."
      );
    }


    const uid =
      request.auth.uid;


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


    const transactions =
      snapshot.docs.map(
        (doc) => {

          const data =
            doc.data();


          let createdAt =
            null;


          if (
            data.createdAt &&
            typeof data.createdAt.toDate ===
              "function"
          ) {

            createdAt =
              data.createdAt
                .toDate()
                .toISOString();
          }


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
              Number(
                data.amount || 0
              ),

            balanceAfter:
              Number(
                data.balanceAfter || 0
              ),

            hashRateAfter:
              Number(
                data.hashRateAfter || 0
              ),

            hashRate:
              Number(
                data.hashRate || 0
              ),

            streak:
              Number(
                data.streak || 0
              ),

            adsToday:
              Number(
                data.adsToday || 0
              ),

            createdAt,
          };
        }
      );


    return {
      transactions,
    };
  });