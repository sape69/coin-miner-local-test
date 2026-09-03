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
// 🐱⛏️ STELLA MINING SETTINGS
// ============================================================

// Aloitus Hash Rate.
const DEFAULT_HASH_RATE = 1;


// ============================================================
// 🎁 DAILY STELLA BONUS
// ============================================================

const DAILY_HASH_RATE_BONUS = 1;


// ============================================================
// 📺 STELLA AD POWER BOOST
// ============================================================

// Mainoksen katsomisesta saatava Hash Rate bonus.
const AD_HASH_RATE_BONUS = 5;


// Mainosten maksimimäärä päivässä.
const MAX_ADS_PER_DAY = 5;


// Mainosten välinen odotusaika.
//
// 60 minuuttia.
const AD_COOLDOWN_MS =
  60 * 60 * 1000;


// ============================================================
// ⛏️ STELLA MINING SESSION
// ============================================================

// Yksi louhintasessio kestää 24 tuntia.
const MINING_SESSION_MS =
  24 * 60 * 60 * 1000;


// Kuinka paljon STL:ää syntyy
// yhdestä Hash Rate -yksiköstä tunnissa.
//
// Esimerkki:
//
// Hash Rate = 10
//
// 10 × 0.10
//
// = 1 STL / tunti
//
const MINING_PER_HASH_PER_HOUR = 0.10;


// ============================================================
// 📜 HISTORY
// ============================================================

const MAX_TRANSACTION_HISTORY = 50;


// ============================================================
// 📺 ADMOB SSV
// ============================================================

// Google AdMob käyttää julkisia avaimia
// Server Side Verification callbackien
// allekirjoituksen tarkistamiseen.

const ADMOB_KEY_URL =
  "https://www.gstatic.com/admob/reward/verifier-keys.json";


// Avaimet pidetään muistissa tunnin.
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
// ⏱️ GET FIRESTORE DATE
// ============================================================

function getFirestoreDate(value) {

  if (
    value &&
    typeof value.toDate === "function"
  ) {
    return value.toDate();
  }

  return null;
}


// ============================================================
// 🐱 GET ACTIVE MINING SESSION
// ============================================================

function getMiningSessionStart(data) {

  return getFirestoreDate(
    data.miningSessionStartedAt
  );
}


// ============================================================
// 🏁 GET MINING SESSION END
// ============================================================

function getMiningSessionEnd(data) {

  return getFirestoreDate(
    data.miningSessionEndsAt
  );
}


// ============================================================
// 🐱 CALCULATE MINING SESSION STATUS
// ============================================================

function getMiningSessionStatus(
  data,
  now = new Date()
) {

  const startedAt =
    getMiningSessionStart(data);

  const endsAt =
    getMiningSessionEnd(data);

  const sessionHashRate =
    Number(
      data.miningSessionHashRate ||
      data.hashRate ||
      DEFAULT_HASH_RATE
    );


  // Ei aktiivista sessiota.
  if (!startedAt || !endsAt) {

    return {
      active: false,

      completed: false,

      startedAt: null,

      endsAt: null,

      elapsedMs: 0,

      remainingMs: 0,

      progress: 0,

      mined: 0,

      sessionHashRate,
    };
  }


  const totalDuration =
    Math.max(
      1,
      endsAt.getTime() -
        startedAt.getTime()
    );


  const rawElapsed =
    now.getTime() -
    startedAt.getTime();


  const elapsedMs =
    Math.max(
      0,
      Math.min(
        rawElapsed,
        totalDuration
      )
    );


  const remainingMs =
    Math.max(
      0,
      endsAt.getTime() -
        now.getTime()
    );


  const progress =
    Math.max(
      0,
      Math.min(
        1,
        elapsedMs /
          totalDuration
      )
    );


  const mined =
    calculateMining(
      sessionHashRate,
      elapsedMs
    );


  const completed =
    remainingMs === 0;


  return {

    active:
      !completed,

    completed,

    startedAt,

    endsAt,

    elapsedMs,

    remainingMs,

    progress,

    mined,

    sessionHashRate,
  };
}


// ============================================================
// 🔑 GET ADMOB PUBLIC KEYS
// ============================================================

async function getAdMobPublicKeys() {

  const now =
    Date.now();


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


  const keys =
    new Map();


  for (
    const key of data.keys
  ) {

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


  const signedParts =
    [];


  for (
    const part of parts
  ) {

    if (
      part.startsWith(
        "signature="
      ) ||
      part.startsWith(
        "key_id="
      )
    ) {

      continue;
    }


    signedParts.push(
      part
    );
  }


  return Buffer.from(
    signedParts.join("&"),
    "utf8"
  );
}


// ============================================================
// 🔐 VERIFY ADMOB CALLBACK
// ============================================================

async function verifyAdMobCallback(
  req
) {

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
// 🐱 GET MINING STATUS
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
    // ⚡ HASH RATE
    // ========================================================

    const hashRate =
      Number(
        data.hashRate ||
        DEFAULT_HASH_RATE
      );


    // ========================================================
    // 💰 SAVED STL BALANCE
    // ========================================================

    const miningBalance =
      Number(
        data.miningBalance || 0
      );


    // ========================================================
    // ⛏️ ACTIVE MINING SESSION
    // ========================================================

    const session =
      getMiningSessionStatus(
        data,
        now
      );


    // ========================================================
    // 📺 AD STATUS
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
    // ⏳ AD COOLDOWN
    // ========================================================

    let cooldownRemainingMs =
      0;


    const lastAdTime =
      getFirestoreDate(
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
    // 🎁 DAILY CHECK-IN
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
    // 💰 REALTIME STL
    // ========================================================

    const realtimeMining =
      session.active ||
      session.completed
        ? session.mined
        : 0;


    return {

      // ======================================================
      // 🐱 HASH RATE
      // ======================================================

      hashRate,


      // ======================================================
      // 💰 STL BALANCE
      // ======================================================

      miningBalance,

      unclaimedMining:
        realtimeMining,

      estimatedTotal:
        miningBalance +
        realtimeMining,


      // ======================================================
      // ⛏️ MINING SESSION
      // ======================================================

      miningActive:
        session.active,

      miningCompleted:
        session.completed,

      miningSessionStartedAt:
        session.startedAt
          ? session.startedAt.toISOString()
          : null,

      miningSessionEndsAt:
        session.endsAt
          ? session.endsAt.toISOString()
          : null,

      miningElapsedMs:
        session.elapsedMs,

      miningRemainingMs:
        session.remainingMs,

      miningProgress:
        session.progress,

      miningSessionHashRate:
        session.sessionHashRate,

      miningSessionReward:
        session.mined,


      // ======================================================
      // ⚡ MINING SPEED
      // ======================================================

      miningPerHour:
        session.sessionHashRate *
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

      canWatchAd:
        adsToday <
          MAX_ADS_PER_DAY &&
        cooldownRemainingMs === 0,

      cooldownRemainingMs,
    };
  });


// ============================================================
// ⛏️ START STELLA MINING
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


    const now =
      new Date();


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
        // CHECK CURRENT SESSION
        // ====================================================

        const currentSession =
          getMiningSessionStatus(
            data,
            now
          );


        if (
          currentSession.active
        ) {

          throw new HttpsError(
            "failed-precondition",
            "Stella louhii jo! 🐱⛏️"
          );
        }


        // ====================================================
        // COMPLETE OLD SESSION AUTOMATICALLY
        // ====================================================

        let oldBalance =
          Number(
            data.miningBalance || 0
          );


        if (
          currentSession.completed &&
          currentSession.mined > 0
        ) {

          oldBalance +=
            currentSession.mined;
        }


        // ====================================================
        // CURRENT HASH RATE
        // ====================================================

        const hashRate =
          Number(
            data.hashRate ||
            DEFAULT_HASH_RATE
          );


        // ====================================================
        // NEW SESSION
        // ====================================================

        const endsAt =
          new Date(
            now.getTime() +
            MINING_SESSION_MS
          );


        transaction.set(
          userRef,
          {
            hashRate,

            miningBalance:
              oldBalance,

            miningSessionStartedAt:
              now,

            miningSessionEndsAt:
              endsAt,

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

            hashRate,

            durationHours: 24,

            createdAt:
              FieldValue.serverTimestamp(),
          }
        );


        return {

          success: true,

          message:
            "Stella Mining käynnistyi! 🐱⛏️✨",

          miningActive:
            true,

          miningSessionStartedAt:
            now.toISOString(),

          miningSessionEndsAt:
            endsAt.toISOString(),

          miningSessionHashRate:
            hashRate,

          miningPerHour:
            hashRate *
            MINING_PER_HASH_PER_HOUR,

          miningBalance:
            oldBalance,
        };
      }
    );
  });


// ============================================================
// 🐱 FINALIZE STELLA MINING
// ============================================================
//
// Tätä voidaan kutsua,
// kun 24h louhinta on valmis.
//
// Se siirtää session aikana
// louhitun STL:n pysyvään saldoon.
// ============================================================

exports.finalizeMining =
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


        const session =
          getMiningSessionStatus(
            data,
            now
          );


        // ====================================================
        // NO SESSION
        // ====================================================

        if (
          !session.startedAt ||
          !session.endsAt
        ) {

          return {

            success: false,

            message:
              "Ei aktiivista Stella Mining -sessioita 🐱",
          };
        }


        // ====================================================
        // STILL RUNNING
        // ====================================================

        if (
          session.active
        ) {

          throw new HttpsError(
            "failed-precondition",
            "Stella louhii vielä! 🐱⛏️"
          );
        }


        // ====================================================
        // PREVENT DOUBLE FINALIZATION
        // ====================================================

        if (
          data.miningSessionFinalized ===
            true
        ) {

          return {

            success: true,

            alreadyFinalized:
              true,

            claimed: 0,

            balance:
              Number(
                data.miningBalance || 0
              ),
          };
        }


        // ====================================================
        // BALANCE
        // ====================================================

        const oldBalance =
          Number(
            data.miningBalance || 0
          );


        const reward =
          session.mined;


        const newBalance =
          oldBalance +
          reward;


        // ====================================================
        // UPDATE
        // ====================================================

        transaction.set(
          userRef,
          {
            miningBalance:
              newBalance,

            miningSessionFinalized:
              true,

            miningSessionFinalizedAt:
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
              "mining_completed",

            title:
              "Stella Mining Complete 🐱✨⛏️",

            amount:
              reward,

            balanceAfter:
              newBalance,

            hashRate:
              session.sessionHashRate,

            durationHours:
              24,

            createdAt:
              FieldValue.serverTimestamp(),
          }
        );


        return {

          success: true,

          claimed:
            reward,

          balance:
            newBalance,

          message:
            `🐱 Stella louhi ${reward.toFixed(4)} STL! ✨`,
        };
      }
    );
  });


// ============================================================
// 🎁 DAILY STELLA CHECK-IN
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

            alreadyClaimed:
              true,

            hashRate:
              oldHashRate,

            streak:
              oldStreak,

            bonus:
              0,
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
        // BONUS
        // ====================================================

        const bonus =
          DAILY_HASH_RATE_BONUS;


        const newHashRate =
          oldHashRate +
          bonus;


        // ====================================================
        // UPDATE
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
              "Stella Daily Bonus 🐱🎁",

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

          alreadyClaimed:
            false,

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
// 📺 TEST AD REWARD
// ============================================================
//
// Käytetään tällä hetkellä
// Google TEST Rewarded Ads -mainoksien kanssa.
//
// Tämä voidaan myöhemmin poistaa,
// kun oikea AdMob SSV on käytössä.
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
        // RESET DAILY AD COUNT
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
          getFirestoreDate(
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
        // UPDATE
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
              "Stella Power Boost 📺🐱⚡",

            amount:
              AD_HASH_RATE_BONUS,

            hashRateAfter:
              newHashRate,

            adsToday:
              newAdsToday,

            createdAt:
              FieldValue.serverTimestamp(),
          }
        );


        return {

          success:
            true,

          bonus:
            AD_HASH_RATE_BONUS,

          hashRate:
            newHashRate,

          adsToday:
            newAdsToday,
        };
      }
    );
  });


// ============================================================
// 📺 ADMOB SERVER-SIDE REWARD
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
            .send(
              "Missing user_id"
            );

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
                  duplicate:
                    true,
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
                  rejected:
                    true,

                  reason:
                    "daily_limit",
                };
              }


              // ==============================================
              // COOLDOWN
              // ==============================================

              const lastAdTime =
                getFirestoreDate(
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
                    rejected:
                      true,

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
                    FieldValue.serverTimestamp(),

                  updatedAt:
                    FieldValue.serverTimestamp(),
                },
                {
                  merge: true,
                }
              );


              // ==============================================
              // SAVE ADMOB REWARD
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

                  createdAt:
                    FieldValue.serverTimestamp(),
                }
              );


              return {

                success:
                  true,

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
            .send(
              "Duplicate ignored"
            );

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
          .send(
            "Reward processed"
          );

      } catch (error) {

        console.error(
          "AdMob reward error:",
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
            typeof
              data.createdAt.toDate ===
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