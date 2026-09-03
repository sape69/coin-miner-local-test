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
// 🐱✨ STELLA MINING SETTINGS
// ============================================================

// Aloitus Hash Rate.
const DEFAULT_HASH_RATE = 1;


// ============================================================
// 🎁 DAILY STELLA BONUS
// ============================================================

// Päivittäinen Hash Rate -bonus.
const DAILY_HASH_RATE_BONUS = 1;


// ============================================================
// 📺 STELLA POWER BOOST
// ============================================================

// Mainoksesta saatava Hash Rate bonus.
const AD_HASH_RATE_BONUS = 5;

// Mainosten maksimimäärä päivässä.
const MAX_ADS_PER_DAY = 5;

// Mainosten välinen odotusaika.
// 60 minuuttia.
const AD_COOLDOWN_MS =
  60 * 60 * 1000;


// ============================================================
// ⛏️🐱 STELLA 24H MINING
// ============================================================

// Yksi Stella Mining Session kestää 24 tuntia.
const MINING_SESSION_DURATION_MS =
  24 * 60 * 60 * 1000;


// ============================================================
// 💎 STL MINING SPEED
// ============================================================

// Kuinka paljon STL:ää syntyy
// yhdellä Hash Rate -yksiköllä tunnissa.
//
// Esimerkki:
//
// 10 Hash Rate
// = 10 × 0.10
// = 1 STL / tunti.
//
const MINING_PER_HASH_PER_HOUR = 0.10;


// ============================================================
// 📜 HISTORY
// ============================================================

const MAX_TRANSACTION_HISTORY = 50;


// ============================================================
// 📺 ADMOB SSV
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
// ⏰ FIRESTORE TIMESTAMP -> DATE
// ============================================================

function timestampToDate(timestamp) {
  if (
    timestamp &&
    typeof timestamp.toDate === "function"
  ) {
    return timestamp.toDate();
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
// 🐱 GET MINING SESSION
// ============================================================

function getMiningSession(data, now = new Date()) {

  const miningStartTime =
    timestampToDate(
      data.miningStartTimestamp
    );

  const miningEndTime =
    timestampToDate(
      data.miningEndTimestamp
    );

  const active =
    data.miningActive === true;

  const hashRate =
    Number(
      data.miningSessionHashRate ||
      data.hashRate ||
      DEFAULT_HASH_RATE
    );

  const storedBalance =
    Number(
      data.miningBalance || 0
    );

  // Ei aktiivista louhintaa.
  if (
    !active ||
    !miningStartTime ||
    !miningEndTime
  ) {
    return {
      active: false,

      startedAt:
        miningStartTime,

      endsAt:
        miningEndTime,

      elapsedMs: 0,

      remainingMs: 0,

      sessionMined: 0,

      estimatedTotal:
        storedBalance,

      hashRate,
    };
  }

  const startMs =
    miningStartTime.getTime();

  const endMs =
    miningEndTime.getTime();

  const nowMs =
    now.getTime();

  // Käytetään enintään session loppuaikaa.
  const effectiveNowMs =
    Math.min(
      nowMs,
      endMs
    );

  const elapsedMs =
    Math.max(
      0,
      effectiveNowMs - startMs
    );

  const remainingMs =
    Math.max(
      0,
      endMs - nowMs
    );

  const sessionMined =
    calculateMining(
      hashRate,
      elapsedMs
    );

  const sessionFinished =
    nowMs >= endMs;

  return {
    active:
      !sessionFinished,

    startedAt:
      miningStartTime,

    endsAt:
      miningEndTime,

    elapsedMs,

    remainingMs,

    sessionMined,

    estimatedTotal:
      storedBalance +
      sessionMined,

    hashRate,

    finished:
      sessionFinished,
  };
}


// ============================================================
// 💾 FINISH MINING SESSION
// ============================================================

function buildFinishedMiningData(
  data,
  now = new Date()
) {

  const session =
    getMiningSession(
      data,
      now
    );

  const oldBalance =
    Number(
      data.miningBalance || 0
    );

  const startTime =
    timestampToDate(
      data.miningStartTimestamp
    );

  const endTime =
    timestampToDate(
      data.miningEndTimestamp
    );

  if (
    !data.miningActive ||
    !startTime ||
    !endTime
  ) {
    return {
      shouldFinish: false,

      session,

      newBalance:
        oldBalance,
    };
  }

  if (
    now.getTime() <
    endTime.getTime()
  ) {
    return {
      shouldFinish: false,

      session,

      newBalance:
        oldBalance,
    };
  }

  const fullElapsed =
    Math.max(
      0,
      endTime.getTime() -
        startTime.getTime()
    );

  const sessionHashRate =
    Number(
      data.miningSessionHashRate ||
      data.hashRate ||
      DEFAULT_HASH_RATE
    );

  const fullReward =
    calculateMining(
      sessionHashRate,
      fullElapsed
    );

  return {
    shouldFinish: true,

    session,

    newBalance:
      oldBalance +
      fullReward,

    fullReward,

    sessionHashRate,
  };
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

  cachedAdMobKeys = keys;

  adMobKeysCachedAt = now;

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
// 🔐 BUILD ADMOB SIGNED DATA
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
// 🔐 VERIFY ADMOB SSV
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
    base64UrlDecode(signature);

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
    // 🐱 HASH RATE
    // ========================================================

    const hashRate =
      Number(
        data.hashRate ||
        DEFAULT_HASH_RATE
      );


    // ========================================================
    // ⛏️ MINING SESSION
    // ========================================================

    const session =
      getMiningSession(
        data,
        now
      );


    // ========================================================
    // 💰 BALANCE
    // ========================================================

    const miningBalance =
      Number(
        data.miningBalance || 0
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
    // 🐱 RETURN STELLA STATUS
    // ========================================================

    return {

      // ==============================================
      // ⚡ HASH RATE
      // ==============================================

      hashRate,


      // ==============================================
      // 💰 STL BALANCE
      // ==============================================

      miningBalance,


      // ==============================================
      // ⛏️ LIVE MINING
      // ==============================================

      miningActive:
        session.active,

      miningFinished:
        session.finished === true,

      miningSessionStart:
        session.startedAt
          ? session.startedAt.toISOString()
          : null,

      miningSessionEnd:
        session.endsAt
          ? session.endsAt.toISOString()
          : null,

      miningRemainingMs:
        session.remainingMs,

      miningElapsedMs:
        session.elapsedMs,

      unclaimedMining:
        session.sessionMined,

      estimatedTotal:
        session.estimatedTotal,

      miningSessionHashRate:
        session.hashRate,

      miningPerHour:
        session.hashRate *
        MINING_PER_HASH_PER_HOUR,


      // ==============================================
      // 🎁 DAILY
      // ==============================================

      dailyClaimed:
        lastDaily === today,

      streak,

      dailyHashRateBonus:
        DAILY_HASH_RATE_BONUS,


      // ==============================================
      // 📺 ADS
      // ==============================================

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
// ⛏️🐱 START STELLA MINING
//
// Käynnistää uuden 24h session.
//
// Jos vanha session on päättynyt,
// sen STL tallennetaan ensin saldoon.
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
        // 🐱 HASH RATE
        // ====================================================

        const hashRate =
          Number(
            data.hashRate ||
            DEFAULT_HASH_RATE
          );


        // ====================================================
        // 💰 OLD BALANCE
        // ====================================================

        let miningBalance =
          Number(
            data.miningBalance || 0
          );


        // ====================================================
        // ⛏️ CURRENT SESSION
        // ====================================================

        const currentSession =
          getMiningSession(
            data,
            now
          );


        // ====================================================
        // 🚫 SESSION ALREADY ACTIVE
        // ====================================================

        if (
          currentSession.active
        ) {
          return {
            success: true,

            alreadyActive: true,

            message:
              "🐱 Stella louhii jo! ⛏️✨",

            miningActive: true,

            miningRemainingMs:
              currentSession.remainingMs,
          };
        }


        // ====================================================
        // 💾 FINISH OLD SESSION
        // ====================================================

        const finished =
          buildFinishedMiningData(
            data,
            now
          );

        if (
          finished.shouldFinish
        ) {

          miningBalance =
            finished.newBalance;

          transaction.set(
            userRef,
            {
              miningBalance,

              miningActive:
                false,

              lastCompletedMiningReward:
                finished.fullReward,

              lastCompletedMiningAt:
                FieldValue.serverTimestamp(),
            },
            {
              merge: true,
            }
          );


          const historyRef =
            getHistoryCollection(uid)
              .doc();

          transaction.set(
            historyRef,
            {
              type:
                "mining_completed",

              title:
                "Stella Mining Complete 🐱⛏️✨",

              amount:
                finished.fullReward,

              balanceAfter:
                miningBalance,

              hashRate:
                finished.sessionHashRate,

              createdAt:
                FieldValue.serverTimestamp(),
            }
          );
        }


        // ====================================================
        // 🚀 START NEW 24H SESSION
        // ====================================================

        const endTime =
          new Date(
            now.getTime() +
            MINING_SESSION_DURATION_MS
          );


        transaction.set(
          userRef,
          {
            hashRate,

            miningBalance,

            miningActive:
              true,

            miningSessionHashRate:
              hashRate,

            miningStartTimestamp:
              now,

            miningEndTimestamp:
              endTime,

            updatedAt:
              FieldValue.serverTimestamp(),
          },
          {
            merge: true,
          }
        );


        // ====================================================
        // 📜 HISTORY
        // ====================================================

        const startHistoryRef =
          getHistoryCollection(uid)
            .doc();

        transaction.set(
          startHistoryRef,
          {
            type:
              "mining_started",

            title:
              "Stella Mining Started 🐱⛏️",

            amount:
              0,

            hashRate,

            createdAt:
              FieldValue.serverTimestamp(),
          }
        );


        return {
          success: true,

          alreadyActive: false,

          message:
            "🐱⛏️ Stella Mining käynnistyi! Louhinta jatkuu 24 tuntia. ✨",

          miningActive:
            true,

          miningBalance,

          hashRate,

          miningStart:
            now.toISOString(),

          miningEnd:
            endTime.toISOString(),

          miningRemainingMs:
            MINING_SESSION_DURATION_MS,
        };
      }
    );
  });


// ============================================================
// 🎁🐱 DAILY STELLA CHECK-IN
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
        // 🔥 STREAK
        // ====================================================

        const newStreak =
          lastDaily === yesterday
            ? oldStreak + 1
            : 1;


        // ====================================================
        // ⚡ HASH RATE BONUS
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


        const historyRef =
          getHistoryCollection(uid)
            .doc(`daily_${today}`);


        transaction.set(
          historyRef,
          {
            type:
              "daily_hashrate",

            title:
              "Stella Daily Bonus 🐱🎁",

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
// 📺🐱 TEST AD REWARD
//
// Käytetään kehityksen aikana Google TEST Ads.
//
// Flutter kutsuu tätä vasta,
// kun käyttäjä on oikeasti saanut
// Rewarded Ad -palkinnon.
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
        // 📺 DAILY ADS
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
        // 🚫 DAILY LIMIT
        // ====================================================

        if (
          adsToday >=
          MAX_ADS_PER_DAY
        ) {
          throw new HttpsError(
            "resource-exhausted",
            "🐱 Stella on katsonut päivän kaikki mainokset!"
          );
        }


        // ====================================================
        // ⏳ COOLDOWN
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
        // ⚡ HASH RATE
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
        // 🐱 UPDATE STELLA POWER
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

            updatedAt:
              FieldValue.serverTimestamp(),
          },
          {
            merge: true,
          }
        );


        // ====================================================
        // 📜 HISTORY
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
          success: true,

          bonus:
            AD_HASH_RATE_BONUS,

          hashRate:
            newHashRate,

          adsToday:
            newAdsToday,

          message:
            "🐱⚡ Stella Power Boost activated!",
        };
      }
    );
  });


// ============================================================
// 📺 ADMOB SERVER-SIDE REWARD
//
// Tämä jää valmiiksi myöhempää
// oikeiden AdMob-mainosten käyttöä varten.
// ============================================================

exports.adMobReward =
  onRequest(
    {
      region: "us-central1",
    },

    async (req, res) => {

      try {

        if (
          req.method !== "GET"
        ) {
          res
            .status(405)
            .send("Method Not Allowed");

          return;
        }


        // ====================================================
        // 🔐 VERIFY GOOGLE SIGNATURE
        // ====================================================

        await verifyAdMobCallback(
          req
        );


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
            .send("Missing transaction_id");

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


        const result =
          await db.runTransaction(
            async (transaction) => {

              // ==============================================
              // DUPLICATE PROTECTION
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
              // USER
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
              // LIMIT
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
                  return {
                    rejected: true,
                    reason:
                      "cooldown",
                  };
                }
              }


              // ==============================================
              // ⚡ HASH RATE
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
                    now,

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


        if (result.duplicate) {
          res
            .status(200)
            .send("Duplicate ignored");

          return;
        }


        if (result.rejected) {
          res
            .status(200)
            .send(
              `Reward rejected: ${result.reason}`
            );

          return;
        }


        res
          .status(200)
          .send("🐱 Stella reward processed!");
      } catch (error) {

        console.error(
          "AdMob reward error:",
          error
        );

        res
          .status(400)
          .send("Invalid reward callback");
      }
    }
  );


// ============================================================
// 📜🐱 GET TRANSACTION HISTORY
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

          let createdAt = null;

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

            createdAt,
          };
        }
      );


    return {
      transactions,
    };
  });