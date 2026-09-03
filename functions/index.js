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
// ⏱️ MINING SESSION
// ============================================================

// Yksi Stella Mining Session kestää 24 tuntia.
const MINING_SESSION_MS =
  24 * 60 * 60 * 1000;


// ============================================================
// 💰 STL MINING SPEED
// ============================================================

// Kuinka paljon STL:ää yksi Hash Rate tuottaa tunnissa.
//
// Esimerkki:
//
// 1 Hash Rate = 0.10 STL / tunti
// 10 Hash Rate = 1.00 STL / tunti
//
const MINING_PER_HASH_PER_HOUR = 0.10;


// ============================================================
// 🎁 DAILY STELLA BONUS
// ============================================================

const DAILY_HASH_RATE_BONUS = 1;


// ============================================================
// 📺 STELLA POWER BOOST
// ============================================================

// Mainoksen katsomisesta saatava Hash Rate bonus.
const AD_HASH_RATE_BONUS = 5;


// Päivittäinen mainosraja.
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
// 📺 ADMOB SERVER-SIDE VERIFICATION
// ============================================================

// Tämä pidetään mukana tulevaa oikeaa AdMob SSV:tä varten.
//
// Testimainosvaiheessa Flutter käyttää testAdReward
// -funktiota.

const ADMOB_KEY_URL =
  "https://www.gstatic.com/admob/reward/verifier-keys.json";

const ADMOB_KEY_CACHE_MS =
  60 * 60 * 1000;


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
// 📺 ADMOB REWARD REFERENCE
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

  return Number.isFinite(number)
    ? number
    : fallback;
}


// ============================================================
// ⏱️ TIMESTAMP TO DATE
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
// ⛏️ CALCULATE STL MINING
// ============================================================

function calculateMining(
  hashRate,
  elapsedMilliseconds
) {

  const safeHashRate =
    Math.max(
      0,
      safeNumber(
        hashRate,
        DEFAULT_HASH_RATE
      )
    );

  const safeElapsed =
    Math.max(
      0,
      safeNumber(
        elapsedMilliseconds,
        0
      )
    );

  const hours =
    safeElapsed /
    (1000 * 60 * 60);

  return (
    safeHashRate *
    MINING_PER_HASH_PER_HOUR *
    hours
  );
}


// ============================================================
// 🐱 GET SESSION DATA
// ============================================================

function getMiningSession(data) {

  const startedAt =
    timestampToDate(
      data.miningStartedAt
    );

  const endsAt =
    timestampToDate(
      data.miningEndsAt
    );

  return {
    startedAt,
    endsAt,
  };
}


// ============================================================
// 🐱 GET MINING STATUS DATA
// ============================================================

function buildMiningStatus(
  data,
  now = new Date()
) {

  const hashRate =
    Math.max(
      0,
      safeNumber(
        data.hashRate,
        DEFAULT_HASH_RATE
      )
    );

  const miningBalance =
    Math.max(
      0,
      safeNumber(
        data.miningBalance,
        0
      )
    );

  const session =
    getMiningSession(data);

  const miningStartedAt =
    session.startedAt;

  const miningEndsAt =
    session.endsAt;


  // ==========================================================
  // SESSION STATUS
  // ==========================================================

  let miningActive = false;

  let miningCompleted = false;

  let elapsedMs = 0;

  let remainingMs = 0;

  let sessionProgress = 0;

  let sessionMined = 0;


  if (
    miningStartedAt &&
    miningEndsAt
  ) {

    const totalDuration =
      Math.max(
        1,
        miningEndsAt.getTime() -
          miningStartedAt.getTime()
      );

    const nowMs =
      now.getTime();

    const startMs =
      miningStartedAt.getTime();

    const endMs =
      miningEndsAt.getTime();


    // Session on vielä käynnissä.
    if (
      nowMs >= startMs &&
      nowMs < endMs
    ) {

      miningActive = true;

      elapsedMs =
        Math.max(
          0,
          nowMs - startMs
        );

      remainingMs =
        Math.max(
          0,
          endMs - nowMs
        );

      sessionProgress =
        Math.min(
          1,
          elapsedMs /
            totalDuration
        );

      sessionMined =
        calculateMining(
          hashRate,
          elapsedMs
        );
    }


    // Session on valmis.
    else if (
      nowMs >= endMs
    ) {

      miningCompleted = true;

      elapsedMs =
        totalDuration;

      remainingMs = 0;

      sessionProgress = 1;

      sessionMined =
        calculateMining(
          hashRate,
          totalDuration
        );
    }
  }


  const estimatedTotal =
    miningBalance +
    sessionMined;


  return {

    // ========================================================
    // BALANCE
    // ========================================================

    miningBalance,

    sessionMined,

    estimatedTotal,


    // ========================================================
    // HASH RATE
    // ========================================================

    hashRate,

    miningPerHour:
      hashRate *
      MINING_PER_HASH_PER_HOUR,


    // ========================================================
    // SESSION
    // ========================================================

    miningActive,

    miningCompleted,

    canStartMining:
      !miningActive &&
      !miningCompleted,

    canClaimMining:
      miningCompleted,

    miningStartedAt:
      miningStartedAt
        ? miningStartedAt.toISOString()
        : null,

    miningEndsAt:
      miningEndsAt
        ? miningEndsAt.toISOString()
        : null,

    miningSessionDurationMs:
      MINING_SESSION_MS,

    elapsedMs,

    remainingMs,

    sessionProgress,
  };
}


// ============================================================
// 🐱 GET ADMOB PUBLIC KEYS
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

  for (
    const part of parts
  ) {

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
// 🐱⛏️ GET MINING STATUS
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
    // MINING STATUS
    // ========================================================

    const miningStatus =
      buildMiningStatus(
        data,
        now
      );


    // ========================================================
    // DAILY BONUS
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
      Math.max(
        0,
        safeNumber(
          data.streak,
          0
        )
      );

    if (
      lastDaily !== today &&
      lastDaily !== yesterday
    ) {
      streak = 0;
    }


    // ========================================================
    // ADS
    // ========================================================

    let adsToday =
      Math.max(
        0,
        safeNumber(
          data.adsToday,
          0
        )
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
    // RETURN
    // ========================================================

    return {

      ...miningStatus,


      // ======================================================
      // DAILY
      // ======================================================

      dailyClaimed:
        lastDaily === today,

      streak,

      dailyHashRateBonus:
        DAILY_HASH_RATE_BONUS,


      // ======================================================
      // ADS
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
// 🐱⛏️ START STELLA MINING
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


    const result =
      await db.runTransaction(
        async (transaction) => {

          const snapshot =
            await transaction.get(
              userRef
            );

          const data =
            snapshot.exists
              ? snapshot.data()
              : {};


          // ==================================================
          // CURRENT SESSION
          // ==================================================

          const miningStatus =
            buildMiningStatus(
              data,
              now
            );


          // ==================================================
          // ACTIVE
          // ==================================================

          if (
            miningStatus.miningActive
          ) {
            throw new HttpsError(
              "failed-precondition",
              "Stella louhii jo! 🐱⛏️"
            );
          }


          // ==================================================
          // COMPLETED BUT NOT CLAIMED
          // ==================================================

          if (
            miningStatus.miningCompleted
          ) {
            throw new HttpsError(
              "failed-precondition",
              "Stella on valmis! Lunasta ensin louhittu STL 🐱💰"
            );
          }


          // ==================================================
          // START NEW SESSION
          // ==================================================

          const hashRate =
            Math.max(
              0,
              safeNumber(
                data.hashRate,
                DEFAULT_HASH_RATE
              )
            );

          const miningBalance =
            Math.max(
              0,
              safeNumber(
                data.miningBalance,
                0
              )
            );

          const startedAt =
            now;

          const endsAt =
            new Date(
              now.getTime() +
                MINING_SESSION_MS
            );


          transaction.set(
            userRef,
            {
              hashRate,

              miningBalance,

              miningStartedAt:
                startedAt,

              miningEndsAt:
                endsAt,

              miningSessionActive:
                true,

              updatedAt:
                FieldValue.serverTimestamp(),
            },
            {
              merge: true,
            }
          );


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
                "mining_started",

              title:
                "Stella Mining Started 🐱⛏️",

              amount:
                0,

              hashRate,

              miningStartedAt:
                startedAt,

              miningEndsAt:
                endsAt,

              createdAt:
                FieldValue.serverTimestamp(),
            }
          );


          return {

            success: true,

            message:
              "Stella Mining käynnistyi! 🐱⛏️💚",

            hashRate,

            miningStartedAt:
              startedAt.toISOString(),

            miningEndsAt:
              endsAt.toISOString(),

            durationMs:
              MINING_SESSION_MS,
          };
        }
      );


    return result;
  });


// ============================================================
// 💰🐱 CLAIM COMPLETED MINING
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


    const result =
      await db.runTransaction(
        async (transaction) => {

          const snapshot =
            await transaction.get(
              userRef
            );

          const data =
            snapshot.exists
              ? snapshot.data()
              : {};


          const miningStatus =
            buildMiningStatus(
              data,
              now
            );


          // ==================================================
          // NO SESSION
          // ==================================================

          if (
            !miningStatus.miningActive &&
            !miningStatus.miningCompleted
          ) {
            throw new HttpsError(
              "failed-precondition",
              "Aloita ensin Stella Mining! 🐱⛏️"
            );
          }


          // ==================================================
          // STILL MINING
          // ==================================================

          if (
            miningStatus.miningActive
          ) {
            throw new HttpsError(
              "failed-precondition",
              "Stella louhii vielä! 🐱⛏️⏳"
            );
          }


          // ==================================================
          // CLAIM COMPLETED SESSION
          // ==================================================

          const oldBalance =
            miningStatus.miningBalance;

          const mined =
            miningStatus.sessionMined;

          const newBalance =
            oldBalance +
            mined;


          transaction.set(
            userRef,
            {
              miningBalance:
                newBalance,

              miningStartedAt:
                FieldValue.delete(),

              miningEndsAt:
                FieldValue.delete(),

              miningSessionActive:
                false,

              lastMiningClaimAt:
                FieldValue.serverTimestamp(),

              updatedAt:
                FieldValue.serverTimestamp(),
            },
            {
              merge: true,
            }
          );


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
                "mining_claim",

              title:
                "Stella Mining Complete 🐱💰⛏️",

              amount:
                mined,

              balanceAfter:
                newBalance,

              hashRate:
                miningStatus.hashRate,

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

            hashRate:
              miningStatus.hashRate,

            message:
              "Stella toi louhitut STL:t! 🐱💚💰",
          };
        }
      );


    return result;
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


    const result =
      await db.runTransaction(
        async (transaction) => {

          const snapshot =
            await transaction.get(
              userRef
            );

          const data =
            snapshot.exists
              ? snapshot.data()
              : {};


          // ==================================================
          // USER DATA
          // ==================================================

          const oldHashRate =
            Math.max(
              0,
              safeNumber(
                data.hashRate,
                DEFAULT_HASH_RATE
              )
            );

          const oldStreak =
            Math.max(
              0,
              safeNumber(
                data.streak,
                0
              )
            );

          const lastDaily =
            String(
              data.lastDaily || ""
            );


          // ==================================================
          // ALREADY CLAIMED
          // ==================================================

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


          // ==================================================
          // STREAK
          // ==================================================

          const newStreak =
            lastDaily === yesterday
              ? oldStreak + 1
              : 1;


          // ==================================================
          // HASH RATE BONUS
          // ==================================================

          const bonus =
            DAILY_HASH_RATE_BONUS;

          const newHashRate =
            oldHashRate +
            bonus;


          // ==================================================
          // UPDATE USER
          // ==================================================

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


          // ==================================================
          // HISTORY
          // ==================================================

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

            alreadyClaimed: false,

            hashRate:
              newHashRate,

            streak:
              newStreak,

            bonus,
          };
        }
      );


    return result;
  });


// ============================================================
// 📺🐱 TEST AD REWARD
//
// Google TEST ADS / DEVELOPMENT
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


    const result =
      await db.runTransaction(
        async (transaction) => {

          const snapshot =
            await transaction.get(
              userRef
            );

          const data =
            snapshot.exists
              ? snapshot.data()
              : {};


          // ==================================================
          // ADS TODAY
          // ==================================================

          let adsToday =
            Math.max(
              0,
              safeNumber(
                data.adsToday,
                0
              )
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


          // ==================================================
          // DAILY LIMIT
          // ==================================================

          if (
            adsToday >=
            MAX_ADS_PER_DAY
          ) {
            throw new HttpsError(
              "resource-exhausted",
              "Päivän Stella-mainosraja on saavutettu 🐱"
            );
          }


          // ==================================================
          // COOLDOWN
          // ==================================================

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
                `Stella lepää vielä ${remainingMinutes} minuuttia 🐱💤`
              );
            }
          }


          // ==================================================
          // HASH RATE
          // ==================================================

          const oldHashRate =
            Math.max(
              0,
              safeNumber(
                data.hashRate,
                DEFAULT_HASH_RATE
              )
            );

          const newHashRate =
            oldHashRate +
            AD_HASH_RATE_BONUS;

          const newAdsToday =
            adsToday + 1;


          // ==================================================
          // UPDATE
          // ==================================================

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


    return result;
  });


// ============================================================
// 📺 ADMOB SERVER-SIDE REWARD
//
// Future production AdMob SSV
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


        // Verify Google's signature.
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
                Math.max(
                  0,
                  safeNumber(
                    data.adsToday,
                    0
                  )
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
              // HASH RATE
              // ==============================================

              const oldHashRate =
                Math.max(
                  0,
                  safeNumber(
                    data.hashRate,
                    DEFAULT_HASH_RATE
                  )
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

          const createdAt =
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

            createdAt:
              createdAt
                ? createdAt.toISOString()
                : null,
          };
        }
      );


    return {
      transactions,
    };
  });