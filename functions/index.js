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
// 🐱 STELLURIINI FIREBASE
// ============================================================

initializeApp();

const db = getFirestore();


// ============================================================
// 🐱 STELLA MINING SETTINGS
// ============================================================

// Stella aloittaa tällä Hash Rate -määrällä.
const DEFAULT_HASH_RATE = 1;


// Päivittäinen Stella Bonus.
const DAILY_HASH_RATE_BONUS = 1;


// Testimainoksen Power Boost.
const AD_HASH_RATE_BONUS = 5;


// Mainosten maksimimäärä päivässä.
const MAX_ADS_PER_DAY = 5;


// Mainosten välinen odotusaika.
// 60 minuuttia.
const AD_COOLDOWN_MS =
  60 * 60 * 1000;


// ============================================================
// ⛏️ STELLA MINING SETTINGS
// ============================================================

// Yksi Stella Mining -jakso kestää 24 tuntia.
const MINING_DURATION_MS =
  24 * 60 * 60 * 1000;


// Kuinka paljon STL syntyy yhdellä
// Hash Rate -yksiköllä tunnissa.
//
// Esimerkki:
//
// 1 Hash Rate
// = 0.10 STL / tunti
//
// 10 Hash Rate
// = 1.00 STL / tunti
//
const MINING_PER_HASH_PER_HOUR = 0.10;


// ============================================================
// 📜 HISTORY SETTINGS
// ============================================================

const MAX_TRANSACTION_HISTORY = 50;


// ============================================================
// 📺 ADMOB SSV SETTINGS
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
// ⛏️ CALCULATE STELLA MINING
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
// ⏱️ GET MINING START TIME
// ============================================================

function getMiningStartTime(data) {
  const timestamp =
    data.miningStartedAt;

  if (
    timestamp &&
    typeof timestamp.toDate ===
      "function"
  ) {
    return timestamp.toDate();
  }

  return null;
}


// ============================================================
// ⏱️ GET MINING END TIME
// ============================================================

function getMiningEndTime(data) {
  const timestamp =
    data.miningEndsAt;

  if (
    timestamp &&
    typeof timestamp.toDate ===
      "function"
  ) {
    return timestamp.toDate();
  }

  return null;
}


// ============================================================
// ⛏️ GET CURRENT MINING STATUS
// ============================================================
//
// Tämä laskee aktiivisen Stella Mining -jakson
// tilanteen palvelimen ajan perusteella.
//

function calculateMiningStatus(
  data,
  now
) {
  const hashRate =
    Number(
      data.hashRate ||
      DEFAULT_HASH_RATE
    );

  const miningStartedAt =
    getMiningStartTime(data);

  const miningEndsAt =
    getMiningEndTime(data);


  // ==========================================================
  // NO ACTIVE MINING
  // ==========================================================

  if (
    !miningStartedAt ||
    !miningEndsAt
  ) {
    return {
      miningActive: false,

      elapsedMs: 0,

      miningRemainingMs: 0,

      minedAmount: 0,

      hashRate,
    };
  }


  const nowMs =
    now.getTime();

  const startMs =
    miningStartedAt.getTime();

  const endMs =
    miningEndsAt.getTime();


  // ==========================================================
  // MINING FINISHED
  // ==========================================================

  if (nowMs >= endMs) {
    const totalElapsed =
      Math.max(
        0,
        endMs - startMs
      );

    return {
      miningActive: false,

      elapsedMs:
        totalElapsed,

      miningRemainingMs: 0,

      minedAmount:
        calculateMining(
          hashRate,
          totalElapsed
        ),

      hashRate,
    };
  }


  // ==========================================================
  // MINING ACTIVE
  // ==========================================================

  const elapsedMs =
    Math.max(
      0,
      nowMs - startMs
    );

  const remainingMs =
    Math.max(
      0,
      endMs - nowMs
    );


  return {
    miningActive: true,

    elapsedMs,

    miningRemainingMs:
      remainingMs,

    minedAmount:
      calculateMining(
        hashRate,
        elapsedMs
      ),

    hashRate,
  };
}


// ============================================================
// 🐱 FINALIZE FINISHED MINING
// ============================================================
//
// Kun 24 tuntia on kulunut,
// louhittu STL siirretään Mining Balanceen.
//

function buildFinishedMiningUpdate(
  data,
  now
) {
  const miningStatus =
    calculateMiningStatus(
      data,
      now
    );

  const oldBalance =
    Number(
      data.miningBalance || 0
    );


  if (miningStatus.miningActive) {
    return {
      finished: false,

      miningStatus,

      newBalance:
        oldBalance,
    };
  }


  const miningStartedAt =
    getMiningStartTime(data);

  const miningEndsAt =
    getMiningEndTime(data);


  // Ei koskaan ollut aktiivista louhintaa.
  if (
    !miningStartedAt ||
    !miningEndsAt
  ) {
    return {
      finished: false,

      miningStatus,

      newBalance:
        oldBalance,
    };
  }


  const minedAmount =
    miningStatus.minedAmount;


  return {
    finished: true,

    miningStatus,

    newBalance:
      oldBalance +
      minedAmount,
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
    // HASH RATE
    // ========================================================

    const hashRate =
      Number(
        data.hashRate ||
        DEFAULT_HASH_RATE
      );


    // ========================================================
    // BALANCE
    // ========================================================

    const miningBalance =
      Number(
        data.miningBalance || 0
      );


    // ========================================================
    // ACTIVE MINING
    // ========================================================

    const miningStatus =
      calculateMiningStatus(
        data,
        now
      );


    // ========================================================
    // UNCLAIMED STL
    // ========================================================

    const unclaimedMining =
      miningStatus.minedAmount;


    // ========================================================
    // DAILY STATUS
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
      Number(
        data.streak || 0
      );

    if (
      lastDaily !== today &&
      lastDaily !== yesterday
    ) {
      streak = 0;
    }


    // ========================================================
    // AD STATUS
    // ========================================================

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
    // RESPONSE
    // ========================================================

    return {
      // ------------------------------------------------------
      // 🐱 HASH RATE
      // ------------------------------------------------------

      hashRate,


      // ------------------------------------------------------
      // 💰 STL BALANCE
      // ------------------------------------------------------

      miningBalance,


      // ------------------------------------------------------
      // ⛏️ CURRENT MINING
      // ------------------------------------------------------

      miningActive:
        miningStatus.miningActive,

      miningRemainingMs:
        miningStatus.miningRemainingMs,

      unclaimedMining,


      // ------------------------------------------------------
      // ✨ TOTAL
      // ------------------------------------------------------

      estimatedTotal:
        miningBalance +
        unclaimedMining,


      // ------------------------------------------------------
      // ⚡ SPEED
      // ------------------------------------------------------

      miningPerHour:
        hashRate *
        MINING_PER_HASH_PER_HOUR,


      // ------------------------------------------------------
      // 🎁 DAILY
      // ------------------------------------------------------

      dailyClaimed:
        lastDaily === today,

      streak,

      dailyHashRateBonus:
        DAILY_HASH_RATE_BONUS,


      // ------------------------------------------------------
      // 📺 ADS
      // ------------------------------------------------------

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
// ⛏️ START / COLLECT STELLA MINING
// ============================================================
//
// Painike toimii näin:
//
// 🐱 Ei aktiivista louhintaa
// → käynnistää 24h louhinnan
//
// 🐱 Louhinta aktiivinen
// → palauttaa nykyisen tilanteen
//
// 🐱 Louhinta päättynyt
// → lisää STL:n Balanceen
// → aloittaa uuden 24h louhinnan
//

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
        // USER SETTINGS
        // ====================================================

        const hashRate =
          Number(
            data.hashRate ||
            DEFAULT_HASH_RATE
          );

        const oldBalance =
          Number(
            data.miningBalance || 0
          );


        // ====================================================
        // CURRENT STATUS
        // ====================================================

        const miningStatus =
          calculateMiningStatus(
            data,
            now
          );


        // ====================================================
        // ACTIVE MINING
        // ====================================================

        if (miningStatus.miningActive) {
          return {
            success: true,

            started: false,

            claimed: 0,

            miningActive: true,

            message:
              "🐱⛏️ Stella louhii jo STL:ää!",
          };
        }


        // ====================================================
        // CHECK IF PREVIOUS CYCLE EXISTS
        // ====================================================

        const previousStart =
          getMiningStartTime(data);

        const previousEnd =
          getMiningEndTime(data);


        let newBalance =
          oldBalance;

        let collected =
          0;


        // ====================================================
        // FINISH PREVIOUS 24H CYCLE
        // ====================================================

        if (
          previousStart &&
          previousEnd
        ) {
          const fullDuration =
            Math.max(
              0,
              previousEnd.getTime() -
                previousStart.getTime()
            );

          collected =
            calculateMining(
              hashRate,
              fullDuration
            );

          newBalance =
            oldBalance +
            collected;
        }


        // ====================================================
        // START NEW 24H CYCLE
        // ====================================================

        const newEndTime =
          new Date(
            now.getTime() +
              MINING_DURATION_MS
          );


        transaction.set(
          userRef,
          {
            hashRate,

            miningBalance:
              newBalance,

            miningStartedAt:
              now,

            miningEndsAt:
              newEndTime,

            updatedAt:
              FieldValue.serverTimestamp(),
          },
          {
            merge: true,
          }
        );


        // ====================================================
        // HISTORY FOR COLLECTED CYCLE
        // ====================================================

        if (collected > 0) {
          const historyRef =
            getHistoryCollection(uid)
              .doc();

          transaction.set(
            historyRef,
            {
              type:
                "mining_complete",

              title:
                "Stella Mining Complete 🐱⛏️✨",

              amount:
                collected,

              balanceAfter:
                newBalance,

              hashRate,

              createdAt:
                FieldValue.serverTimestamp(),
            }
          );
        }


        // ====================================================
        // HISTORY FOR NEW CYCLE
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

            amount: 0,

            hashRate,

            createdAt:
              FieldValue.serverTimestamp(),
          }
        );


        return {
          success: true,

          started: true,

          claimed:
            collected,

          balance:
            newBalance,

          hashRate,

          miningActive: true,

          miningDurationMs:
            MINING_DURATION_MS,

          message:
            collected > 0
              ? "🐱✨ Stella Mining collected and restarted!"
              : "🐱⛏️ Stella Mining started!",
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

        if (lastDaily === today) {
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
            .doc(`daily_${today}`);

        transaction.set(
          historyRef,
          {
            type:
              "daily_hashrate",

            title:
              "Stella Daily Bonus 🐱🎁⚡",

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
// 📺 TEST AD REWARD
// ============================================================
//
// Käytössä kehityksen aikana.
//
// Flutter käyttää Google AdMob TEST ID:tä.
//

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
        // AD COUNT
        // ====================================================

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

        const lastAdTimestamp =
          data.lastAdTimestamp;

        if (
          lastAdTimestamp &&
          typeof lastAdTimestamp.toDate ===
            "function"
        ) {
          const elapsed =
            now.getTime() -
            lastAdTimestamp
              .toDate()
              .getTime();

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
          Number(
            data.hashRate ||
            DEFAULT_HASH_RATE
          );

        const newHashRate =
          oldHashRate +
          AD_HASH_RATE_BONUS;


        // ====================================================
        // AD COUNT
        // ====================================================

        const newAdsToday =
          adsToday + 1;


        // ====================================================
        // CURRENT MINING STATUS
        // ====================================================

        const miningStatus =
          calculateMiningStatus(
            data,
            now
          );


        let miningStartedAt =
          getMiningStartTime(data);

        let miningEndsAt =
          getMiningEndTime(data);

        let miningRestarted =
          false;


        // ====================================================
        // START MINING IF NOT ACTIVE
        // ====================================================
        //
        // Mainos voi käynnistää uuden
        // Stella Mining -jakson.
        //

        if (!miningStatus.miningActive) {
          miningStartedAt = now;

          miningEndsAt =
            new Date(
              now.getTime() +
                MINING_DURATION_MS
            );

          miningRestarted = true;
        }


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

            miningStartedAt,

            miningEndsAt,

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

            miningRestarted,

            createdAt:
              FieldValue.serverTimestamp(),
          }
        );


        // ====================================================
        // RESPONSE
        // ====================================================

        return {
          success: true,

          bonus:
            AD_HASH_RATE_BONUS,

          hashRate:
            newHashRate,

          adsToday:
            newAdsToday,

          miningRestarted,
        };
      }
    );
  });


// ============================================================
// 📺 ADMOB SERVER-SIDE REWARD
// ============================================================
//
// Tämä on valmiina oikeita AdMob-mainoksia varten.
//
// Testivaiheessa Flutter käyttää edelleen
// testAdReward-funktiota.
//

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

        if (req.method !== "GET") {
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
        // TRANSACTION
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

              if (rewardSnapshot.exists) {
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


              // ==============================================
              // ADS TODAY
              // ==============================================

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

              const lastAdTimestamp =
                data.lastAdTimestamp;

              if (
                lastAdTimestamp &&
                typeof lastAdTimestamp.toDate ===
                  "function"
              ) {
                const elapsed =
                  now.getTime() -
                  lastAdTimestamp
                    .toDate()
                    .getTime();

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
              // MINING
              // ==============================================

              const miningStatus =
                calculateMiningStatus(
                  data,
                  now
                );

              let miningStartedAt =
                getMiningStartTime(data);

              let miningEndsAt =
                getMiningEndTime(data);

              let miningRestarted =
                false;

              if (!miningStatus.miningActive) {
                miningStartedAt = now;

                miningEndsAt =
                  new Date(
                    now.getTime() +
                      MINING_DURATION_MS
                  );

                miningRestarted = true;
              }


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

                  miningStartedAt,

                  miningEndsAt,

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

                  miningRestarted,

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

                miningRestarted,
              };
            }
          );


        // ====================================================
        // RESPONSE
        // ====================================================

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
          .send("Reward processed");
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

            adsToday:
              Number(
                data.adsToday || 0
              ),

            miningRestarted:
              data.miningRestarted === true,

            createdAt,
          };
        }
      );


    return {
      transactions,
    };
  });