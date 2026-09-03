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
  Timestamp,
} = require("firebase-admin/firestore");


// ============================================================
// 🔥 FIREBASE
// ============================================================

initializeApp();

const db = getFirestore();


// ============================================================
// 🐱 STELLA MINING SETTINGS
// ============================================================

// Aloitus Mining Power.
const DEFAULT_HASH_RATE = 1;


// ============================================================
// 🎁 DAILY STELLA BONUS
// ============================================================

const DAILY_HASH_RATE_BONUS = 1;


// ============================================================
// 📺 STELLA POWER BOOST
// ============================================================

// Mainoksen katsomisesta saatava Mining Power.
const AD_HASH_RATE_BONUS = 5;

// Mainosten maksimimäärä päivässä.
const MAX_ADS_PER_DAY = 5;

// Mainosten välinen odotusaika.
const AD_COOLDOWN_MS =
  60 * 60 * 1000;


// ============================================================
// ⛏️ STELLA 24H MINING SESSION
// ============================================================

// Louhinnan kesto.
const MINING_SESSION_MS =
  24 * 60 * 60 * 1000;


// ============================================================
// ⚡ MINING SPEED
// ============================================================

// Kuinka paljon STL-simulaatiota syntyy
// yhdellä Hash Rate -yksiköllä tunnissa.
//
// Esimerkki:
//
// Hash Rate 10
// = 10 × 0.10 STL/h
// = 1.00 STL/h
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
// 📜 HISTORY COLLECTION
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
// 🐱 NUMBER HELPERS
// ============================================================

function getHashRate(data) {
  return Number(
    data.hashRate ||
    DEFAULT_HASH_RATE
  );
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
// 🐱 GET MINING SESSION START
// ============================================================

function getMiningSessionStart(data) {
  return getTimestampDate(
    data.miningSessionStartedAt
  );
}


// ============================================================
// 🐱 GET MINING SESSION END
// ============================================================

function getMiningSessionEnd(data) {
  return getTimestampDate(
    data.miningSessionEndsAt
  );
}


// ============================================================
// ⏱️ GET SESSION STATUS
// ============================================================

function getMiningSessionStatus(
  data,
  now
) {
  const startedAt =
    getMiningSessionStart(data);

  const endsAt =
    getMiningSessionEnd(data);

  if (!startedAt || !endsAt) {
    return {
      active: false,
      completed: false,

      startedAt: null,
      endsAt: null,

      elapsedMs: 0,
      remainingMs: 0,

      progress: 0,
    };
  }

  const nowMs =
    now.getTime();

  const startMs =
    startedAt.getTime();

  const endMs =
    endsAt.getTime();


  if (nowMs < startMs) {
    return {
      active: false,
      completed: false,

      startedAt,
      endsAt,

      elapsedMs: 0,

      remainingMs:
        endMs - nowMs,

      progress: 0,
    };
  }


  const elapsedMs =
    Math.max(
      0,
      Math.min(
        nowMs - startMs,
        MINING_SESSION_MS
      )
    );


  const remainingMs =
    Math.max(
      0,
      endMs - nowMs
    );


  const completed =
    nowMs >= endMs;


  const progress =
    Math.max(
      0,
      Math.min(
        1,
        elapsedMs /
          MINING_SESSION_MS
      )
    );


  return {
    active:
      !completed,

    completed,

    startedAt,

    endsAt,

    elapsedMs,

    remainingMs,

    progress,
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
    // ⚡ HASH RATE
    // ========================================================

    const hashRate =
      getHashRate(data);


    // ========================================================
    // 💰 STORED BALANCE
    // ========================================================

    const miningBalance =
      Number(
        data.miningBalance || 0
      );


    // ========================================================
    // ⛏️ SESSION STATUS
    // ========================================================

    const session =
      getMiningSessionStatus(
        data,
        now
      );


    // ========================================================
    // 🐱 LIVE SESSION MINING
    // ========================================================

    let liveMining = 0;

    if (
      session.active ||
      session.completed
    ) {
      liveMining =
        calculateMining(
          hashRate,
          session.elapsedMs
        );
    }


    // ========================================================
    // 🎯 SESSION TOTAL
    // ========================================================

    const estimatedTotal =
      miningBalance +
      liveMining;


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

    if (adDate !== today) {
      adsToday = 0;
    }


    // ========================================================
    // ⏱️ AD COOLDOWN
    // ========================================================

    let cooldownRemainingMs = 0;

    const lastAdTimestamp =
      getTimestampDate(
        data.lastAdTimestamp
      );

    if (lastAdTimestamp) {

      const elapsed =
        now.getTime() -
        lastAdTimestamp.getTime();

      cooldownRemainingMs =
        Math.max(
          0,
          AD_COOLDOWN_MS - elapsed
        );
    }


    // ========================================================
    // 🎁 DAILY STATUS
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
    // 🐱 RESPONSE
    // ========================================================

    return {

      // ==============================================
      // ⚡ POWER
      // ==============================================

      hashRate,


      // ==============================================
      // 💰 BALANCE
      // ==============================================

      miningBalance,

      unclaimedMining:
        liveMining,

      estimatedTotal,


      // ==============================================
      // ⛏️ SESSION
      // ==============================================

      miningActive:
        session.active,

      miningCompleted:
        session.completed,

      miningStartedAt:
        session.startedAt
          ? session.startedAt.toISOString()
          : null,

      miningEndsAt:
        session.endsAt
          ? session.endsAt.toISOString()
          : null,

      miningElapsedMs:
        session.elapsedMs,

      miningRemainingMs:
        session.remainingMs,

      miningProgress:
        session.progress,

      miningSessionDurationMs:
        MINING_SESSION_MS,


      // ==============================================
      // ⚡ SPEED
      // ==============================================

      miningPerHour:
        hashRate *
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

    const endTime =
      new Date(
        now.getTime() +
          MINING_SESSION_MS
      );


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
        // CURRENT SESSION
        // ====================================================

        const currentSession =
          getMiningSessionStatus(
            data,
            now
          );


        // ====================================================
        // ALREADY ACTIVE
        // ====================================================

        if (
          currentSession.active
        ) {
          throw new HttpsError(
            "failed-precondition",
            "Stella louhii jo! 🐱⛏️"
          );
        }


        // ====================================================
        // HASH RATE
        // ====================================================

        const hashRate =
          getHashRate(data);


        // ====================================================
        // PREVIOUS BALANCE
        // ====================================================

        let miningBalance =
          Number(
            data.miningBalance || 0
          );


        // ====================================================
        // FINISH PREVIOUS SESSION
        // ====================================================

        if (
          currentSession.completed &&
          !data.lastCompletedSessionId
        ) {
          // Tämä kohta on vain varmistus.
          // Varsinainen session tulos
          // tallennetaan finishMining-funktiossa.
        }


        // ====================================================
        // CREATE SESSION ID
        // ====================================================

        const sessionId =
          `stella_${Date.now()}`;


        // ====================================================
        // START NEW SESSION
        // ====================================================

        transaction.set(
          userRef,
          {
            hashRate,

            miningBalance,

            miningSessionId:
              sessionId,

            miningSessionStartedAt:
              Timestamp.fromDate(now),

            miningSessionEndsAt:
              Timestamp.fromDate(endTime),

            miningSessionHashRate:
              hashRate,

            miningSessionCompleted:
              false,

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

            sessionId,

            createdAt:
              FieldValue.serverTimestamp(),
          }
        );


        return {
          success: true,

          miningActive: true,

          sessionId,

          hashRate,

          startedAt:
            now.toISOString(),

          endsAt:
            endTime.toISOString(),

          durationMs:
            MINING_SESSION_MS,

          message:
            "Stella aloitti 24 tunnin louhinnan! 🐱⛏️✨",
        };
      }
    );
  });


// ============================================================
// 🐱 FINISH STELLA MINING
// ============================================================

exports.finishMining =
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
        // SESSION TIMES
        // ====================================================

        const startedAt =
          getMiningSessionStart(
            data
          );

        const endsAt =
          getMiningSessionEnd(
            data
          );


        if (
          !startedAt ||
          !endsAt
        ) {
          throw new HttpsError(
            "failed-precondition",
            "Stella Miningia ei ole käynnissä. 🐱"
          );
        }


        // ====================================================
        // NOT FINISHED YET
        // ====================================================

        if (
          now.getTime() <
          endsAt.getTime()
        ) {
          const remaining =
            endsAt.getTime() -
            now.getTime();

          throw new HttpsError(
            "failed-precondition",
            `Stella louhii vielä! ⏱️ ${Math.ceil(
              remaining / 60000
            )} min jäljellä 🐱`
          );
        }


        // ====================================================
        // ALREADY COMPLETED
        // ====================================================

        if (
          data.miningSessionCompleted ===
          true
        ) {
          return {
            success: true,

            alreadyCompleted: true,

            balance:
              Number(
                data.miningBalance || 0
              ),
          };
        }


        // ====================================================
        // SESSION HASH RATE
        // ====================================================

        const sessionHashRate =
          Number(
            data.miningSessionHashRate ||
            getHashRate(data)
          );


        // ====================================================
        // SESSION REWARD
        // ====================================================

        const mined =
          calculateMining(
            sessionHashRate,
            MINING_SESSION_MS
          );


        // ====================================================
        // BALANCE
        // ====================================================

        const oldBalance =
          Number(
            data.miningBalance || 0
          );

        const newBalance =
          oldBalance +
          mined;


        // ====================================================
        // COMPLETE SESSION
        // ====================================================

        transaction.set(
          userRef,
          {
            miningBalance:
              newBalance,

            miningSessionCompleted:
              true,

            miningSessionFinishedAt:
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
              "Stella Mining Complete! 🐱✨⛏️",

            amount:
              mined,

            balanceAfter:
              newBalance,

            hashRate:
              sessionHashRate,

            sessionId:
              String(
                data.miningSessionId || ""
              ),

            createdAt:
              FieldValue.serverTimestamp(),
          }
        );


        return {
          success: true,

          alreadyCompleted: false,

          mined,

          balance:
            newBalance,

          message:
            "Stella sai 24h louhinnan valmiiksi! 🐱✨⛏️",
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
          getHashRate(data);

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
        // BONUS
        // ====================================================

        const bonus =
          DAILY_HASH_RATE_BONUS;

        const newHashRate =
          oldHashRate +
          bonus;


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
// 🧪 TEST AD REWARD
// ============================================================
//
// Käytetään Flutterissa Google TEST Rewarded Adien kanssa.
//
// Oikeassa tuotantoversiossa voidaan vaihtaa
// AdMob SSV -vahvistukseen.
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
            "Päivän Stella-mainosraja on saavutettu. 🐱"
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
          getHashRate(data);

        const bonus =
          AD_HASH_RATE_BONUS;

        const newHashRate =
          oldHashRate +
          bonus;

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

        if (
          req.method !== "GET"
        ) {
          res
            .status(405)
            .send("Method Not Allowed");

          return;
        }


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

              // Duplicate protection.
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


              const oldHashRate =
                getHashRate(data);

              const newHashRate =
                oldHashRate +
                AD_HASH_RATE_BONUS;

              const newAdsToday =
                adsToday + 1;


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


              transaction.set(
                rewardRef,
                {
                  uid,

                  transactionId,

                  adUnit:
                    String(
                      req.query.ad_unit || ""
                    ),

                  adNetwork:
                    String(
                      req.query.ad_network || ""
                    ),

                  rewardAmount:
                    String(
                      req.query.reward_amount || ""
                    ),

                  rewardItem:
                    String(
                      req.query.reward_item || ""
                    ),

                  timestamp:
                    String(
                      req.query.timestamp || ""
                    ),

                  createdAt:
                    FieldValue.serverTimestamp(),
                }
              );


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
              };
            }
          );


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
          .send("Stella reward processed 🐱⚡");

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