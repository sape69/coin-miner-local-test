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
// 🐱 STELLA FIREBASE
// ============================================================

initializeApp();

const db = getFirestore();


// ============================================================
// 🐱 STELLA SETTINGS
// ============================================================

const DEFAULT_HASH_RATE = 1;

const DAILY_HASH_RATE_BONUS = 1;

const AD_HASH_RATE_BONUS = 5;


// ============================================================
// 📺 STELLA AD SETTINGS
// ============================================================

const MAX_ADS_PER_DAY = 5;

const AD_COOLDOWN_MS =
  60 * 60 * 1000;


// ============================================================
// ⛏️ STELLA 24H MINING SETTINGS
// ============================================================

const MINING_DURATION_MS =
  24 * 60 * 60 * 1000;


// ============================================================
// 💰 STL MINING SPEED
// ============================================================

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
// 📁 USER
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
// 📺 ADMOB REWARDS
// ============================================================

function getAdMobRewardRef(transactionId) {
  return db
    .collection("admobRewards")
    .doc(transactionId);
}


// ============================================================
// 🔢 SAFE NUMBER
// ============================================================

function safeNumber(value, fallback = 0) {
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
    typeof value.toDate === "function"
  ) {
    return value.toDate();
  }

  return null;
}


// ============================================================
// ⛏️ GET MINING START
// ============================================================

function getMiningStartTime(data) {
  return timestampToDate(
    data.miningStartedAt
  );
}


// ============================================================
// ⏱️ GET MINING END
// ============================================================

function getMiningEndTime(data) {
  return timestampToDate(
    data.miningEndsAt
  );
}


// ============================================================
// 💰 CALCULATE STL MINING
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
// ⏳ GET CURRENT MINING STATUS
// ============================================================

function getMiningStatusFromData(
  data,
  now = new Date()
) {
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

      miningStartedAt: null,

      miningEndsAt: null,

      miningRemainingMs: 0,

      elapsedMs: 0,
    };
  }

  const nowMs =
    now.getTime();

  const startMs =
    miningStartedAt.getTime();

  const endMs =
    miningEndsAt.getTime();

  // ==========================================================
  // NOT STARTED
  // ==========================================================

  if (nowMs < startMs) {
    return {
      miningActive: false,

      miningStartedAt,

      miningEndsAt,

      miningRemainingMs:
        Math.max(
          0,
          endMs - nowMs
        ),

      elapsedMs: 0,
    };
  }

  // ==========================================================
  // ACTIVE
  // ==========================================================

  if (nowMs < endMs) {
    return {
      miningActive: true,

      miningStartedAt,

      miningEndsAt,

      miningRemainingMs:
        endMs - nowMs,

      elapsedMs:
        nowMs - startMs,
    };
  }

  // ==========================================================
  // FINISHED
  // ==========================================================

  return {
    miningActive: false,

    miningStartedAt,

    miningEndsAt,

    miningRemainingMs: 0,

    elapsedMs:
      Math.max(
        0,
        endMs - startMs
      ),
  };
}


// ============================================================
// 💰 CALCULATE CURRENT UNCLAIMED STL
// ============================================================

function getCurrentMiningAmount(
  data,
  now = new Date()
) {
  const hashRate =
    safeNumber(
      data.hashRate,
      DEFAULT_HASH_RATE
    );

  const status =
    getMiningStatusFromData(
      data,
      now
    );

  if (
    !status.miningStartedAt ||
    !status.miningEndsAt
  ) {
    return {
      status,

      amount: 0,
    };
  }

  const amount =
    calculateMining(
      hashRate,
      status.elapsedMs
    );

  return {
    status,

    amount,
  };
}


// ============================================================
// 🐱 DAILY STREAK
// ============================================================

function getCurrentStreak(data) {
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

  return streak;
}


// ============================================================
// 📺 GET AD STATUS
// ============================================================

function getAdStatus(
  data,
  now = new Date()
) {
  const today =
    getUtcDateString();

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

  let cooldownRemainingMs = 0;

  const lastAdTimestamp =
    timestampToDate(
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

  return {
    adsToday,

    cooldownRemainingMs,

    canWatchAd:
      adsToday < MAX_ADS_PER_DAY &&
      cooldownRemainingMs === 0,
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
      safeNumber(
        data.hashRate,
        DEFAULT_HASH_RATE
      );

    // ========================================================
    // 💰 SAVED STL
    // ========================================================

    const miningBalance =
      safeNumber(
        data.miningBalance,
        0
      );

    // ========================================================
    // ⛏️ CURRENT 24H MINING
    // ========================================================

    const mining =
      getCurrentMiningAmount(
        data,
        now
      );

    const status =
      mining.status;

    const unclaimedMining =
      mining.amount;

    const estimatedTotal =
      miningBalance +
      unclaimedMining;

    // ========================================================
    // 📺 ADS
    // ========================================================

    const adStatus =
      getAdStatus(
        data,
        now
      );

    // ========================================================
    // 🔥 STREAK
    // ========================================================

    const streak =
      getCurrentStreak(data);

    const today =
      getUtcDateString();

    const lastDaily =
      String(
        data.lastDaily || ""
      );

    return {
      // ======================================================
      // ⚡ HASH RATE
      // ======================================================

      hashRate,

      miningPerHour:
        hashRate *
        MINING_PER_HASH_PER_HOUR,

      // ======================================================
      // 💰 STL
      // ======================================================

      miningBalance,

      unclaimedMining,

      estimatedTotal,

      // ======================================================
      // ⛏️ 24H MINING
      // ======================================================

      miningActive:
        status.miningActive,

      miningRemainingMs:
        status.miningRemainingMs,

      miningStartedAt:
        status.miningStartedAt
          ? status.miningStartedAt.toISOString()
          : null,

      miningEndsAt:
        status.miningEndsAt
          ? status.miningEndsAt.toISOString()
          : null,

      miningDurationMs:
        MINING_DURATION_MS,

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

      adsToday:
        adStatus.adsToday,

      maxAdsPerDay:
        MAX_ADS_PER_DAY,

      adHashRateBonus:
        AD_HASH_RATE_BONUS,

      canWatchAd:
        adStatus.canWatchAd,

      cooldownRemainingMs:
        adStatus.cooldownRemainingMs,
    };
  });


// ============================================================
// ⛏️ START / FINISH STELLA MINING
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
        // ⚡ HASH RATE
        // ====================================================

        const hashRate =
          safeNumber(
            data.hashRate,
            DEFAULT_HASH_RATE
          );

        // ====================================================
        // 💰 SAVED BALANCE
        // ====================================================

        const oldBalance =
          safeNumber(
            data.miningBalance,
            0
          );

        // ====================================================
        // ⛏️ CURRENT MINING
        // ====================================================

        const mining =
          getCurrentMiningAmount(
            data,
            now
          );

        const status =
          mining.status;

        // ====================================================
        // 🐱 MINING ALREADY ACTIVE
        // ====================================================

        if (status.miningActive) {
          return {
            success: false,

            miningActive: true,

            message:
              "🐱⛏️ Stella louhii jo!",
          };
        }

        // ====================================================
        // 💰 FINISH PREVIOUS 24H MINING
        // ====================================================

        let newBalance =
          oldBalance;

        let completedMining =
          0;

        const hadMiningSession =
          status.miningStartedAt &&
          status.miningEndsAt;

        if (hadMiningSession) {
          completedMining =
            mining.amount;

          if (completedMining > 0) {
            newBalance =
              oldBalance +
              completedMining;
          }
        }

        // ====================================================
        // 🐱 START NEW 24H MINING
        // ====================================================

        const newStart =
          now;

        const newEnd =
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
              newStart,

            miningEndsAt:
              newEnd,

            updatedAt:
              FieldValue.serverTimestamp(),
          },
          {
            merge: true,
          }
        );

        // ====================================================
        // 📜 HISTORY FOR COMPLETED SESSION
        // ====================================================

        if (completedMining > 0) {
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
                completedMining,

              balanceAfter:
                newBalance,

              hashRate,

              createdAt:
                FieldValue.serverTimestamp(),
            }
          );
        }

        // ====================================================
        // 📜 HISTORY FOR NEW SESSION
        // ====================================================

        const startHistoryRef =
          getHistoryCollection(uid)
            .doc();

        transaction.set(
          startHistoryRef,
          {
            type:
              "mining_start",

            title:
              "Stella 24H Mining Started 🐱⛏️",

            amount: 0,

            hashRate,

            miningEndsAt:
              newEnd.toISOString(),

            createdAt:
              FieldValue.serverTimestamp(),
          }
        );

        return {
          success: true,

          miningActive: true,

          completedMining,

          balance:
            newBalance,

          hashRate,

          miningEndsAt:
            newEnd.toISOString(),

          message:
            completedMining > 0
              ? "🐱⛏️ Uusi 24h Stella Mining alkoi!"
              : "🐱⛏️ Stella Mining käynnistyi 24 tunniksi!",
        };
      }
    );
  });


// ============================================================
// 🎁 STELLA DAILY CHECK-IN
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
          safeNumber(
            data.hashRate,
            DEFAULT_HASH_RATE
          );

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
        // 🔥 STREAK
        // ====================================================

        const newStreak =
          lastDaily === yesterday
            ? oldStreak + 1
            : 1;

        // ====================================================
        // ⚡ BONUS
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
        // 📜 HISTORY
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
//
// DEVELOPMENT ONLY
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
        // 📺 CURRENT AD STATUS
        // ====================================================

        const adStatus =
          getAdStatus(
            data,
            now
          );

        let adsToday =
          adStatus.adsToday;

        // ====================================================
        // DAILY LIMIT
        // ====================================================

        if (
          adsToday >=
          MAX_ADS_PER_DAY
        ) {
          throw new HttpsError(
            "resource-exhausted",
            "🐱 Päivän Stella-mainosraja saavutettu."
          );
        }

        // ====================================================
        // COOLDOWN
        // ====================================================

        if (
          adStatus.cooldownRemainingMs >
          0
        ) {
          const minutes =
            Math.ceil(
              adStatus.cooldownRemainingMs /
                60000
            );

          throw new HttpsError(
            "failed-precondition",
            `🐱 Stella lepää vielä ${minutes} minuuttia.`
          );
        }

        // ====================================================
        // ⚡ HASH RATE
        // ====================================================

        const oldHashRate =
          safeNumber(
            data.hashRate,
            DEFAULT_HASH_RATE
          );

        const newHashRate =
          oldHashRate +
          AD_HASH_RATE_BONUS;

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
        };
      }
    );
  });


// ============================================================
// 📺 ADMOB SERVER-SIDE REWARD
//
// FUTURE PRODUCTION USE
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

        if (req.method !== "GET") {
          res
            .status(405)
            .send("Method Not Allowed");

          return;
        }

        // ====================================================
        // VERIFY ADMOB
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

        // ====================================================
        // FIRESTORE TRANSACTION
        // ====================================================

        const result =
          await db.runTransaction(
            async (transaction) => {
              // ==============================================
              // DUPLICATE
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
              // AD STATUS
              // ==============================================

              const adStatus =
                getAdStatus(
                  data,
                  now
                );

              if (
                adStatus.adsToday >=
                MAX_ADS_PER_DAY
              ) {
                return {
                  rejected: true,
                  reason:
                    "daily_limit",
                };
              }

              if (
                adStatus.cooldownRemainingMs >
                0
              ) {
                return {
                  rejected: true,
                  reason:
                    "cooldown",
                };
              }

              // ==============================================
              // HASH RATE
              // ==============================================

              const oldHashRate =
                safeNumber(
                  data.hashRate,
                  DEFAULT_HASH_RATE
                );

              const newHashRate =
                oldHashRate +
                AD_HASH_RATE_BONUS;

              const newAdsToday =
                adStatus.adsToday +
                1;

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
          .send("Invalid reward callback");
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
      snapshot.docs.map((doc) => {
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

          createdAt,
        };
      });

    return {
      transactions,
    };
  });