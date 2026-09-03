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
// 🐱 STELLA SETTINGS
// ============================================================

const DEFAULT_HASH_RATE = 1;

const DAILY_HASH_RATE_BONUS = 1;

const AD_HASH_RATE_BONUS = 5;

const MAX_ADS_PER_DAY = 5;

const AD_COOLDOWN_MS =
  60 * 60 * 1000;


// ============================================================
// ⛏️ STELLA MINING SETTINGS
// ============================================================

// Yksi louhintajakso kestää 24 tuntia.

const MINING_DURATION_MS =
  24 * 60 * 60 * 1000;


// 1 Hash Rate = 0.10 STL / tunti.

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
// 📁 FIRESTORE REFERENCES
// ============================================================

function getUserRef(uid) {
  return db
    .collection("users")
    .doc(uid);
}


function getHistoryCollection(uid) {
  return getUserRef(uid)
    .collection("transactions");
}


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
    Number(hashRate) *
    MINING_PER_HASH_PER_HOUR *
    hours
  );
}


// ============================================================
// ⏱️ TIMESTAMP HELPERS
// ============================================================

function timestampToDate(value) {
  if (
    value &&
    typeof value.toDate === "function"
  ) {
    return value.toDate();
  }

  if (value instanceof Date) {
    return value;
  }

  return null;
}


function getMiningStartTime(data) {
  return timestampToDate(
    data.miningStartedAt
  );
}


function getMiningEndTime(data) {
  return timestampToDate(
    data.miningEndsAt
  );
}


// ============================================================
// ⚡ GET MINING HASH RATE
// ============================================================
//
// miningHashRate tallennetaan aina,
// kun uusi 24h louhinta alkaa.
//
// Näin myöhemmin saadut bonus Hash Ratet
// eivät muuta jo mennyttä louhintaa.
//

function getMiningHashRate(data) {
  return Number(
    data.miningHashRate ||
    data.hashRate ||
    DEFAULT_HASH_RATE
  );
}


// ============================================================
// ⛏️ CALCULATE CURRENT MINING STATUS
// ============================================================

function calculateMiningStatus(
  data,
  now
) {
  const miningStartedAt =
    getMiningStartTime(data);

  const miningEndsAt =
    getMiningEndTime(data);

  const miningHashRate =
    getMiningHashRate(data);


  // ----------------------------------------------------------
  // EI AKTIIVISTA LOUHINTAA
  // ----------------------------------------------------------

  if (
    !miningStartedAt ||
    !miningEndsAt
  ) {
    return {
      miningActive: false,

      miningFinished: false,

      elapsedMs: 0,

      miningRemainingMs: 0,

      minedAmount: 0,

      miningHashRate,
    };
  }


  const nowMs =
    now.getTime();

  const startMs =
    miningStartedAt.getTime();

  const endMs =
    miningEndsAt.getTime();


  // ----------------------------------------------------------
  // LOUHINTA PÄÄTTYNYT
  // ----------------------------------------------------------

  if (nowMs >= endMs) {
    const fullElapsedMs =
      Math.max(
        0,
        endMs - startMs
      );

    return {
      miningActive: false,

      miningFinished: true,

      elapsedMs:
        fullElapsedMs,

      miningRemainingMs: 0,

      minedAmount:
        calculateMining(
          miningHashRate,
          fullElapsedMs
        ),

      miningHashRate,
    };
  }


  // ----------------------------------------------------------
  // LOUHINTA AKTIIVINEN
  // ----------------------------------------------------------

  const elapsedMs =
    Math.max(
      0,
      nowMs - startMs
    );

  const miningRemainingMs =
    Math.max(
      0,
      endMs - nowMs
    );


  return {
    miningActive: true,

    miningFinished: false,

    elapsedMs,

    miningRemainingMs,

    minedAmount:
      calculateMining(
        miningHashRate,
        elapsedMs
      ),

    miningHashRate,
  };
}


// ============================================================
// 🐱 START NEW STELLA MINING CYCLE
// ============================================================

function buildNewMiningCycle(
  hashRate,
  now
) {
  return {
    miningStartedAt:
      now,

    miningEndsAt:
      new Date(
        now.getTime() +
        MINING_DURATION_MS
      ),

    miningHashRate:
      hashRate,
  };
}


// ============================================================
// 📺 ADMOB PUBLIC KEYS
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


  const signedParts =
    [];


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


    // --------------------------------------------------------
    // HASH RATE
    // --------------------------------------------------------

    const hashRate =
      Number(
        data.hashRate ||
        DEFAULT_HASH_RATE
      );


    // --------------------------------------------------------
    // BALANCE
    // --------------------------------------------------------

    const miningBalance =
      Number(
        data.miningBalance || 0
      );


    // --------------------------------------------------------
    // MINING STATUS
    // --------------------------------------------------------

    const miningStatus =
      calculateMiningStatus(
        data,
        now
      );


    const unclaimedMining =
      miningStatus.minedAmount;


    // --------------------------------------------------------
    // DAILY
    // --------------------------------------------------------

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


    // --------------------------------------------------------
    // ADS
    // --------------------------------------------------------

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


    // --------------------------------------------------------
    // AD COOLDOWN
    // --------------------------------------------------------

    let cooldownRemainingMs =
      0;


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
          AD_COOLDOWN_MS - elapsed
        );
    }


    // --------------------------------------------------------
    // RESPONSE
    // --------------------------------------------------------

    return {
      hashRate,

      miningBalance,

      miningActive:
        miningStatus.miningActive,

      miningFinished:
        miningStatus.miningFinished,

      miningRemainingMs:
        miningStatus.miningRemainingMs,

      miningHashRate:
        miningStatus.miningHashRate,

      unclaimedMining,

      estimatedTotal:
        miningBalance +
        unclaimedMining,

      miningPerHour:
        miningStatus.miningHashRate *
        MINING_PER_HASH_PER_HOUR,

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

      miningDurationMs:
        MINING_DURATION_MS,
    };
  });


// ============================================================
// ⛏️ START / COLLECT STELLA MINING
// ============================================================
//
// 🐱 Ei louhintaa
// → aloittaa 24h jakson
//
// 🐱 Louhinta käynnissä
// → kertoo että Stella louhii
//
// 🐱 Louhinta valmis
// → kerää STL
// → aloittaa uuden 24h jakson
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


        const hashRate =
          Number(
            data.hashRate ||
            DEFAULT_HASH_RATE
          );


        const oldBalance =
          Number(
            data.miningBalance || 0
          );


        const miningStatus =
          calculateMiningStatus(
            data,
            now
          );


        // ----------------------------------------------------
        // STELLA LOUHII JO
        // ----------------------------------------------------

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


        let newBalance =
          oldBalance;

        let collected =
          0;


        // ----------------------------------------------------
        // KERÄÄ VALMIS JAKSO
        // ----------------------------------------------------

        if (miningStatus.miningFinished) {
          collected =
            miningStatus.minedAmount;

          newBalance =
            oldBalance +
            collected;
        }


        // ----------------------------------------------------
        // ALOITA UUSI 24H JAKSO
        // ----------------------------------------------------

        const newCycle =
          buildNewMiningCycle(
            hashRate,
            now
          );


        transaction.set(
          userRef,
          {
            hashRate,

            miningBalance:
              newBalance,

            ...newCycle,

            updatedAt:
              FieldValue.serverTimestamp(),
          },
          {
            merge: true,
          }
        );


        // ----------------------------------------------------
        // HISTORY: VALMIS LOUHINTA
        // ----------------------------------------------------

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

              hashRate:
                miningStatus.miningHashRate,

              createdAt:
                FieldValue.serverTimestamp(),
            }
          );
        }


        // ----------------------------------------------------
        // HISTORY: UUSI JAKSO
        // ----------------------------------------------------

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
              ? "🐱✨ Stella keräsi STL:n ja aloitti uuden louhinnan!"
              : "🐱⛏️ Stella Mining started!",
        };
      }
    );
  });


// ============================================================
// 🐱 DAILY STELLA BONUS
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
              "Stella Daily Bonus 🐱🎁⚡",

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
// ============================================================
//
// Käytetään kehityksen aikana.
//
// Flutter näyttää AdMob TEST-mainoksen,
// jonka jälkeen tämä funktio antaa
// Stella Power Boostin.
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


        // ----------------------------------------------------
        // ADS TODAY
        // ----------------------------------------------------

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


        // ----------------------------------------------------
        // DAILY LIMIT
        // ----------------------------------------------------

        if (
          adsToday >=
          MAX_ADS_PER_DAY
        ) {
          throw new HttpsError(
            "resource-exhausted",
            "🐱 Päivän Stella-mainosraja on saavutettu."
          );
        }


        // ----------------------------------------------------
        // COOLDOWN
        // ----------------------------------------------------

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


        // ----------------------------------------------------
        // HASH RATE BONUS
        // ----------------------------------------------------

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


        // ----------------------------------------------------
        // UPDATE USER
        // ----------------------------------------------------

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


        // ----------------------------------------------------
        // HISTORY
        // ----------------------------------------------------

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
            "🐱⚡ Stella sai Power Boostin!",
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

              const rewardSnapshot =
                await transaction.get(
                  rewardRef
                );


              if (rewardSnapshot.exists) {
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


              if (adDate !== today) {
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


              // UPDATE USER

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


              // SAVE ADMOB REWARD

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


              // HISTORY

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