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
// 🐱⚡ STELLA SETTINGS
// ============================================================

// Stella Mining alkaa tällä Hash Ratella.
const DEFAULT_HASH_RATE = 1;


// Päivittäinen Stella Check-In bonus.
const DAILY_HASH_RATE_BONUS = 1;


// Testimainoksen Stella Power Boost.
const AD_HASH_RATE_BONUS = 5;


// Mainosten maksimimäärä päivässä.
const MAX_ADS_PER_DAY = 5;


// Mainosten välinen odotusaika.
//
// 60 minuuttia.
const AD_COOLDOWN_MS =
  60 * 60 * 1000;


// ============================================================
// ⛏️🐱 STELLA MINING SESSION
// ============================================================

// Yksi Stella Mining Session kestää 24 tuntia.
const MINING_SESSION_MS =
  24 * 60 * 60 * 1000;


// Kuinka paljon STL:ää syntyy:
//
// 1 Hash Rate
// = 0.10 STL / tunti
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

  if (!Number.isFinite(number)) {
    return fallback;
  }

  return number;
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
// ⛏️ CALCULATE MINING
// ============================================================

function calculateMining(
  hashRate,
  elapsedMilliseconds
) {

  const safeElapsed =
    Math.max(
      0,
      elapsedMilliseconds
    );

  const hours =
    safeElapsed /
    (1000 * 60 * 60);

  return (
    hashRate *
    MINING_PER_HASH_PER_HOUR *
    hours
  );
}


// ============================================================
// 🐱 GET SESSION START
// ============================================================

function getMiningSessionStart(data) {
  return timestampToDate(
    data.miningSessionStartedAt
  );
}


// ============================================================
// 🐱 GET SESSION END
// ============================================================

function getMiningSessionEnd(data) {
  return timestampToDate(
    data.miningSessionEndsAt
  );
}


// ============================================================
// ⛏️ GET SESSION STATUS
// ============================================================

function getMiningSessionStatus(
  data,
  now
) {

  const sessionStart =
    getMiningSessionStart(data);

  const sessionEnd =
    getMiningSessionEnd(data);

  const storedHashRate =
    safeNumber(
      data.sessionHashRate,
      safeNumber(
        data.hashRate,
        DEFAULT_HASH_RATE
      )
    );


  // ==========================================================
  // NO SESSION
  // ==========================================================

  if (
    !sessionStart ||
    !sessionEnd
  ) {
    return {
      active: false,

      completed: false,

      hashRate:
        storedHashRate,

      elapsedMs: 0,

      remainingMs: 0,

      mined: 0,

      startedAt: null,

      endsAt: null,
    };
  }


  const nowMs =
    now.getTime();

  const startMs =
    sessionStart.getTime();

  const endMs =
    sessionEnd.getTime();


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


  const mined =
    calculateMining(
      storedHashRate,
      elapsedMs
    );


  return {
    active: !completed,

    completed,

    hashRate:
      storedHashRate,

    elapsedMs,

    remainingMs,

    mined,

    startedAt:
      sessionStart.toISOString(),

    endsAt:
      sessionEnd.toISOString(),
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
    await fetch(ADMOB_KEY_URL);


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
    // 🐱 MINING SESSION
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
      safeNumber(
        data.adsToday,
        0
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
    // 🎁 DAILY
    // ========================================================

    const lastDaily =
      String(
        data.lastDaily || ""
      );


    let streak =
      safeNumber(
        data.streak,
        0
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

      // ------------------------------------------------------
      // ⚡ CURRENT POWER
      // ------------------------------------------------------

      hashRate,


      miningPerHour:
        hashRate *
        MINING_PER_HASH_PER_HOUR,


      // ------------------------------------------------------
      // ⛏️ SESSION
      // ------------------------------------------------------

      miningActive:
        session.active,


      miningCompleted:
        session.completed,


      miningSessionStartedAt:
        session.startedAt,


      miningSessionEndsAt:
        session.endsAt,


      sessionElapsedMs:
        session.elapsedMs,


      sessionRemainingMs:
        session.remainingMs,


      sessionHashRate:
        session.hashRate,


      // Reaaliaikaisesti tähän asti louhittu
      // nykyisessä sessiossa.
      sessionMined:
        session.mined,


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


      // ------------------------------------------------------
      // 🐱 UI
      // ------------------------------------------------------

      message:
        session.active
          ? "Stella is mining! 🐱⛏️✨"
          : session.completed
              ? "Stella is ready for a new adventure! 🐱✨"
              : "Start Stella Mining! 🐱⛏️",
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

        const currentEnd =
          getMiningSessionEnd(
            data
          );


        if (
          currentEnd &&
          now.getTime() <
            currentEnd.getTime()
        ) {

          throw new HttpsError(
            "failed-precondition",
            "Stella is already mining! 🐱⛏️"
          );
        }


        // ====================================================
        // HASH RATE
        // ====================================================

        const hashRate =
          safeNumber(
            data.hashRate,
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


            miningSessionStartedAt:
              now,


            miningSessionEndsAt:
              endsAt,


            sessionHashRate:
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


            sessionEndsAt:
              endsAt,


            createdAt:
              FieldValue.serverTimestamp(),

          }
        );


        return {

          success: true,


          message:
            "Stella Mining started! 🐱⛏️✨",


          hashRate,


          startedAt:
            now.toISOString(),


          endsAt:
            endsAt.toISOString(),


          durationMs:
            MINING_SESSION_MS,

        };
      }
    );
  });


// ============================================================
// 🐱🎁 DAILY STELLA CHECK-IN
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
        // ⚡ STELLA POWER
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
              "Stella Daily Power 🐱⚡",


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
//
// Development only.
// Google test ad → Stella Power Boost.
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
          safeNumber(
            data.adsToday,
            0
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
            "Stella has reached today's Power Boost limit! 🐱"
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
              `Stella is resting for ${remainingMinutes} more minutes 🐱💤`
            );
          }
        }


        // ====================================================
        // ⚡ POWER BOOST
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
//
// Real ads later.
// ============================================================

exports.adMobReward =
  onRequest(
    {
      region:
        "us-central1",
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
            .send(
              "Method Not Allowed"
            );

          return;
        }


        // ====================================================
        // VERIFY GOOGLE
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
                  duplicate:
                    true,
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
                safeNumber(
                  data.adsToday,
                  0
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
                    rejected:
                      true,

                    reason:
                      "cooldown",
                  };
                }
              }


              // ==============================================
              // ⚡ POWER BOOST
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
                  merge:
                    true,
                }
              );


              // ==============================================
              // SAVE SSV
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
            "Stella reward processed 🐱⚡"
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
        }
      );


    return {
      transactions,
    };
  });