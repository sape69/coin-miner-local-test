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
// 🔥 FIREBASE
// ============================================================

initializeApp();

const db = getFirestore();


// ============================================================
// 🐱 STELLA MINING SETTINGS
// ============================================================

const DEFAULT_HASH_RATE = 1;

const DAILY_HASH_RATE_BONUS = 1;

const AD_HASH_RATE_BONUS = 5;

const MAX_ADS_PER_DAY = 5;

const AD_COOLDOWN_MS =
  60 * 60 * 1000;


// ============================================================
// ⛏️ 24 HOUR MINING SETTINGS
// ============================================================

// Louhinta kestää aina 24 tuntia.
const MINING_DURATION_MS =
  24 * 60 * 60 * 1000;


// ============================================================
// 💰 STL MINING SETTINGS
// ============================================================

// 1 Hash Rate tuottaa tämän verran STL tunnissa.
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
// ⛏️ CALCULATE MINING
// ============================================================

function calculateMining(
  hashRate,
  elapsedMilliseconds
) {
  const safeElapsed =
    Math.max(
      0,
      Math.min(
        elapsedMilliseconds,
        MINING_DURATION_MS
      )
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
// 🔐 ADMOB KEYS
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
// 🔐 BUILD SIGNED QUERY
// ============================================================

function buildSignedQueryString(originalUrl) {

  const questionMarkIndex =
    originalUrl.indexOf("?");

  if (questionMarkIndex === -1) {
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

  if (!signature || !keyId) {
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

  verifier.update(signedData);

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
// 🐱 BUILD MINING STATUS
// ============================================================

function buildMiningStatus(data) {

  const now =
    new Date();

  const hashRate =
    Number(
      data.hashRate ||
      DEFAULT_HASH_RATE
    );

  const miningBalance =
    Number(
      data.miningBalance || 0
    );

  const miningStartDate =
    timestampToDate(
      data.miningStartTimestamp
    );

  const miningEndDate =
    timestampToDate(
      data.miningEndTimestamp
    );

  let miningActive = false;

  let miningCompleted = false;

  let elapsedMs = 0;

  let remainingMs = 0;

  let progress = 0;

  let unclaimedMining = 0;


  if (
    miningStartDate &&
    miningEndDate
  ) {

    const nowMs =
      now.getTime();

    const startMs =
      miningStartDate.getTime();

    const endMs =
      miningEndDate.getTime();

    elapsedMs =
      Math.max(
        0,
        Math.min(
          nowMs - startMs,
          MINING_DURATION_MS
        )
      );

    remainingMs =
      Math.max(
        0,
        endMs - nowMs
      );

    progress =
      Math.max(
        0,
        Math.min(
          1,
          elapsedMs /
            MINING_DURATION_MS
        )
      );

    miningActive =
      nowMs < endMs;

    miningCompleted =
      nowMs >= endMs;

    unclaimedMining =
      calculateMining(
        hashRate,
        elapsedMs
      );
  }


  return {

    hashRate,

    miningBalance,

    unclaimedMining,

    estimatedTotal:
      miningBalance +
      unclaimedMining,

    miningActive,

    miningCompleted,

    miningProgress:
      progress,

    miningElapsedMs:
      elapsedMs,

    miningRemainingMs:
      remainingMs,

    miningDurationMs:
      MINING_DURATION_MS,

    miningStartTime:
      miningStartDate
        ? miningStartDate.toISOString()
        : null,

    miningEndTime:
      miningEndDate
        ? miningEndDate.toISOString()
        : null,

    miningPerHour:
      hashRate *
      MINING_PER_HASH_PER_HOUR,
  };
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


    const mining =
      buildMiningStatus(data);


    // ========================================================
    // 📺 AD STATUS
    // ========================================================

    const now =
      new Date();

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

    let cooldownRemainingMs = 0;

    const lastAdDate =
      timestampToDate(
        data.lastAdTimestamp
      );

    if (lastAdDate) {

      const elapsed =
        now.getTime() -
        lastAdDate.getTime();

      cooldownRemainingMs =
        Math.max(
          0,
          AD_COOLDOWN_MS - elapsed
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


    return {

      ...mining,

      dailyClaimed:
        lastDaily === today,

      streak,

      dailyHashRateBonus:
        DAILY_HASH_RATE_BONUS,

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
// ⛏️ START / COLLECT MINING
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


        const hashRate =
          Number(
            data.hashRate ||
            DEFAULT_HASH_RATE
          );

        const oldBalance =
          Number(
            data.miningBalance || 0
          );

        const startDate =
          timestampToDate(
            data.miningStartTimestamp
          );

        const endDate =
          timestampToDate(
            data.miningEndTimestamp
          );


        // ====================================================
        // 🐱 NO ACTIVE MINING → START NEW 24H MINING
        // ====================================================

        if (
          !startDate ||
          !endDate
        ) {

          const endTime =
            new Date(
              now.getTime() +
              MINING_DURATION_MS
            );

          transaction.set(
            userRef,
            {
              hashRate,

              miningBalance:
                oldBalance,

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

          return {
            success: true,

            action: "started",

            message:
              "Stella aloitti 24 tunnin louhinnan! 🐱⛏️",

            miningActive: true,

            miningEndTime:
              endTime.toISOString(),
          };
        }


        // ====================================================
        // ⛏️ MINING STILL ACTIVE
        // ====================================================

        if (
          now.getTime() <
          endDate.getTime()
        ) {

          const remaining =
            endDate.getTime() -
            now.getTime();

          return {
            success: false,

            action: "active",

            message:
              "Stella louhii edelleen! 🐱⛏️",

            remainingMs:
              remaining,
          };
        }


        // ====================================================
        // 💰 MINING COMPLETED → COLLECT
        // ====================================================

        const mined =
          calculateMining(
            hashRate,
            MINING_DURATION_MS
          );

        const newBalance =
          oldBalance +
          mined;


        transaction.set(
          userRef,
          {
            miningBalance:
              newBalance,

            miningStartTimestamp:
              FieldValue.delete(),

            miningEndTimestamp:
              FieldValue.delete(),

            updatedAt:
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
              "mining_complete",

            title:
              "Stella Mining Complete! 🐱⛏️✨",

            amount:
              mined,

            balanceAfter:
              newBalance,

            hashRate,

            createdAt:
              FieldValue.serverTimestamp(),
          }
        );


        return {
          success: true,

          action: "collected",

          claimed:
            mined,

          balance:
            newBalance,

          hashRate,

          message:
            "Stella toi louhinnan kotiin! 🐱💚✨",
        };
      }
    );
  });


// ============================================================
// 🐱 DAILY CHECK-IN
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
          await transaction.get(userRef);

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


        if (lastDaily === today) {
          return {
            alreadyClaimed: true,
            hashRate: oldHashRate,
            streak: oldStreak,
            bonus: 0,
          };
        }


        const newStreak =
          lastDaily === yesterday
            ? oldStreak + 1
            : 1;

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
          hashRate: newHashRate,
          streak: newStreak,
          bonus: DAILY_HASH_RATE_BONUS,
        };
      }
    );
  });


// ============================================================
// 🧪 TEST AD REWARD
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
          await transaction.get(userRef);

        const data =
          snapshot.exists
            ? snapshot.data()
            : {};


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


        if (
          adsToday >= MAX_ADS_PER_DAY
        ) {
          throw new HttpsError(
            "resource-exhausted",
            "Päivän Stella-mainosraja on saavutettu."
          );
        }


        const lastAdDate =
          timestampToDate(
            data.lastAdTimestamp
          );

        if (lastAdDate) {

          const elapsed =
            now.getTime() -
            lastAdDate.getTime();

          if (
            elapsed <
            AD_COOLDOWN_MS
          ) {
            throw new HttpsError(
              "failed-precondition",
              "Stella lepää ennen seuraavaa mainosta 🐱💤"
            );
          }
        }


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
        // ⚡ AD BOOST
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
// ============================================================

exports.adMobReward =
  onRequest(
    {
      region: "us-central1",
    },

    async (req, res) => {

      try {

        if (req.method !== "GET") {
          res
            .status(405)
            .send("Method Not Allowed");

          return;
        }


        await verifyAdMobCallback(req);


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

              const rewardSnapshot =
                await transaction.get(rewardRef);

              if (rewardSnapshot.exists) {
                return {
                  duplicate: true,
                };
              }


              const userSnapshot =
                await transaction.get(userRef);

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

              if (adDate !== today) {
                adsToday = 0;
              }


              if (
                adsToday >= MAX_ADS_PER_DAY
              ) {
                return {
                  rejected: true,
                  reason: "daily_limit",
                };
              }


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


              transaction.set(
                rewardRef,
                {
                  uid,

                  transactionId,

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


        if (result.duplicate) {
          res.status(200).send("Duplicate ignored");
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

            id: doc.id,

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