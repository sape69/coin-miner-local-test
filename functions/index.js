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

const crypto = require("crypto");


// ============================================================
// FIREBASE INITIALIZATION
// ============================================================

initializeApp();

const db = getFirestore();


// ============================================================
// SETTINGS
// ============================================================

// STL-palkinto yhdestä katsotusta mainoksesta.
const AD_REWARD = 3;

// Maksimimäärä mainoksia päivässä.
const MAX_ADS_PER_DAY = 5;

// Mainosten välinen odotusaika.
// 60 minuuttia.
const AD_COOLDOWN_MS =
  60 * 60 * 1000;


// ============================================================
// GET UTC DATE
// ============================================================

function getUtcDateString() {
  return new Date()
    .toISOString()
    .substring(0, 10);
}


// ============================================================
// GET YESTERDAY UTC DATE
// ============================================================

function getYesterdayUtcDateString() {
  const yesterday = new Date();

  yesterday.setUTCDate(
    yesterday.getUTCDate() - 1
  );

  return yesterday
    .toISOString()
    .substring(0, 10);
}


// ============================================================
// CALCULATE DAILY REWARD
//
// Day 1 = 1 STL
// Day 2 = 2 STL
// Day 3 = 3 STL
// Day 4 = 4 STL
// Day 5 = 5 STL
// Day 6 = 6 STL
// Day 7 = 7 STL
//
// After day 7 = 7 STL every day.
// ============================================================

function calculateDailyReward(streak) {
  const safeStreak =
    Math.max(
      1,
      Math.min(7, Number(streak) || 1)
    );

  return safeStreak;
}


// ============================================================
// DAILY CHECK-IN
// ============================================================

exports.dailyCheckIn =
  onCall(async (request) => {

    if (!request.auth) {
      throw new HttpsError(
        "unauthenticated",
        "Käyttäjän täytyy olla kirjautunut."
      );
    }

    const uid =
      request.auth.uid;

    const userRef =
      db.collection("users")
        .doc(uid);

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
          // CURRENT USER DATA
          // ==================================================

          const oldBalance =
            Number(
              data.stlBalance || 0
            );

          const oldStreak =
            Number(
              data.streak || 0
            );

          const lastDaily =
            data.lastDaily || "";


          // ==================================================
          // ALREADY CLAIMED TODAY
          // ==================================================

          if (lastDaily === today) {
            return {
              alreadyClaimed: true,

              balance:
                oldBalance,

              streak:
                oldStreak,

              reward:
                0,
            };
          }


          // ==================================================
          // CALCULATE NEW STREAK
          //
          // If the user claimed yesterday:
          // continue the streak.
          //
          // If one or more days were missed:
          // restart from day 1.
          // ==================================================

          let newStreak;

          if (lastDaily === yesterday) {
            newStreak =
              oldStreak + 1;
          } else {
            newStreak = 1;
          }


          // ==================================================
          // MAXIMUM STREAK = 7
          //
          // After day 7 the streak stays at 7.
          // ==================================================

          if (newStreak > 7) {
            newStreak = 7;
          }


          // ==================================================
          // DAILY REWARD
          //
          // The reward equals the streak:
          //
          // Day 1 = 1 STL
          // Day 2 = 2 STL
          // ...
          // Day 7 = 7 STL
          // ==================================================

          const reward =
            calculateDailyReward(
              newStreak
            );


          // ==================================================
          // NEW BALANCE
          // ==================================================

          const newBalance =
            oldBalance + reward;


          // ==================================================
          // UPDATE FIRESTORE
          // ==================================================

          transaction.set(
            userRef,
            {
              stlBalance:
                newBalance,

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
          // RETURN RESULT
          // ==================================================

          return {
            alreadyClaimed: false,

            balance:
              newBalance,

            streak:
              newStreak,

            reward:
              reward,
          };
        }
      );


    return result;
  });


// ============================================================
// GET REWARD STATUS
// ============================================================

exports.getRewardStatus =
  onCall(async (request) => {

    if (!request.auth) {
      throw new HttpsError(
        "unauthenticated",
        "Käyttäjän täytyy olla kirjautunut."
      );
    }

    const uid =
      request.auth.uid;

    const userRef =
      db.collection("users")
        .doc(uid);

    const snapshot =
      await userRef.get();

    const data =
      snapshot.exists
        ? snapshot.data()
        : {};


    const now =
      new Date();

    const today =
      getUtcDateString();

    const yesterday =
      getYesterdayUtcDateString();


    // ========================================================
    // CURRENT BALANCE
    // ========================================================

    const balance =
      Number(
        data.stlBalance || 0
      );


    // ========================================================
    // DAILY STREAK STATUS
    // ========================================================

    const storedStreak =
      Number(
        data.streak || 0
      );

    const lastDaily =
      data.lastDaily || "";


    let nextDailyStreak;

    if (lastDaily === today) {
      nextDailyStreak =
        storedStreak;
    } else if (lastDaily === yesterday) {
      nextDailyStreak =
        storedStreak + 1;
    } else {
      nextDailyStreak = 1;
    }


    if (nextDailyStreak > 7) {
      nextDailyStreak = 7;
    }


    const nextDailyReward =
      lastDaily === today
        ? 0
        : calculateDailyReward(
            nextDailyStreak
          );


    // ========================================================
    // AD STATUS
    // ========================================================

    const adDate =
      data.adDate || "";

    let adsToday =
      Number(
        data.adsToday || 0
      );


    // New UTC day.
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
          AD_COOLDOWN_MS - elapsed
        );
    }


    // ========================================================
    // RETURN STATUS
    // ========================================================

    return {
      balance:
        balance,

      streak:
        storedStreak,

      nextDailyStreak:
        nextDailyStreak,

      nextDailyReward:
        nextDailyReward,

      dailyClaimed:
        lastDaily === today,

      adsToday:
        adsToday,

      maxAdsPerDay:
        MAX_ADS_PER_DAY,

      adReward:
        AD_REWARD,

      canWatchAd:
        adsToday < MAX_ADS_PER_DAY &&
        cooldownRemainingMs === 0,

      cooldownRemainingMs:
        cooldownRemainingMs,
    };
  });


// ============================================================
// TEST AD REWARD
//
// DEVELOPMENT ONLY!
// Used with Google's test rewarded ad.
// ============================================================

exports.testAdReward =
  onCall(async (request) => {

    if (!request.auth) {
      throw new HttpsError(
        "unauthenticated",
        "Käyttäjän täytyy olla kirjautunut."
      );
    }

    const uid =
      request.auth.uid;

    const userRef =
      db.collection("users")
        .doc(uid);

    const now =
      new Date();

    const today =
      getUtcDateString();


    const result =
      await db.runTransaction(
        async (transaction) => {

          // ==================================================
          // GET USER DATA
          // ==================================================

          const snapshot =
            await transaction.get(
              userRef
            );

          const data =
            snapshot.exists
              ? snapshot.data()
              : {};


          // ==================================================
          // CURRENT BALANCE
          // ==================================================

          const oldBalance =
            Number(
              data.stlBalance || 0
            );


          // ==================================================
          // CURRENT ADS
          // ==================================================

          let adsToday =
            Number(
              data.adsToday || 0
            );

          const adDate =
            data.adDate || "";


          // ==================================================
          // NEW UTC DAY
          // ==================================================

          if (adDate !== today) {
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
              "Päivän mainosraja on saavutettu."
            );
          }


          // ==================================================
          // COOLDOWN CHECK
          // ==================================================

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


            if (
              elapsed <
              AD_COOLDOWN_MS
            ) {

              const remainingMs =
                AD_COOLDOWN_MS -
                elapsed;

              throw new HttpsError(
                "failed-precondition",
                `Odota vielä ${Math.ceil(
                  remainingMs / 60000
                )} minuuttia.`
              );
            }
          }


          // ==================================================
          // ADD REWARD
          // ==================================================

          const newBalance =
            oldBalance +
            AD_REWARD;

          const newAdsToday =
            adsToday + 1;


          // ==================================================
          // UPDATE USER
          // ==================================================

          transaction.set(
            userRef,
            {
              stlBalance:
                newBalance,

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
          // RETURN RESULT
          // ==================================================

          return {
            success: true,

            balance:
              newBalance,

            adsToday:
              newAdsToday,

            reward:
              AD_REWARD,
          };
        }
      );


    return result;
  });


// ============================================================
// ADMOB SSV
//
// This remains for future production use.
// ============================================================

const ADMOB_KEYS_URL =
  "https://www.gstatic.com/admob/reward/verifier-keys.json";

let cachedKeys = null;

let keysCachedAt = 0;

const KEY_CACHE_TIME =
  24 * 60 * 60 * 1000;


// ============================================================
// GET ADMOB PUBLIC KEYS
// ============================================================

async function getAdMobKeys(
  forceRefresh = false
) {

  const now =
    Date.now();


  if (
    !forceRefresh &&
    cachedKeys &&
    now - keysCachedAt <
      KEY_CACHE_TIME
  ) {
    return cachedKeys;
  }


  const response =
    await fetch(
      ADMOB_KEYS_URL
    );


  if (!response.ok) {
    throw new Error(
      "Could not download AdMob public keys."
    );
  }


  const data =
    await response.json();

  const keys = {};


  for (
    const key of data.keys || []
  ) {

    if (
      key.keyId &&
      key.pem
    ) {

      keys[
        String(key.keyId)
      ] =
        key.pem;
    }
  }


  if (
    Object.keys(keys).length === 0
  ) {
    throw new Error(
      "No AdMob public keys available."
    );
  }


  cachedKeys =
    keys;

  keysCachedAt =
    now;


  return keys;
}


// ============================================================
// VERIFY ADMOB SIGNATURE
// ============================================================

async function verifyAdMobSignature(
  request
) {

  const originalUrl =
    request.originalUrl ||
    request.url;


  if (!originalUrl) {
    throw new Error(
      "Missing request URL."
    );
  }


  const questionMarkIndex =
    originalUrl.indexOf("?");


  if (questionMarkIndex === -1) {
    throw new Error(
      "Missing query string."
    );
  }


  const queryString =
    originalUrl.substring(
      questionMarkIndex + 1
    );


  // AdMob signature is normally followed by key_id.
  const signatureMarker =
    "&signature=";

  const signatureIndex =
    queryString.indexOf(
      signatureMarker
    );


  if (signatureIndex === -1) {
    throw new Error(
      "Missing signature."
    );
  }


  const dataToVerify =
    queryString.substring(
      0,
      signatureIndex
    );


  const signaturePart =
    queryString.substring(
      signatureIndex + 1
    );


  const keyMarker =
    "&key_id=";

  const keyIndex =
    signaturePart.indexOf(
      keyMarker
    );


  if (keyIndex === -1) {
    throw new Error(
      "Missing key_id."
    );
  }


  const signatureValue =
    signaturePart.substring(
      "signature=".length,
      keyIndex
    );


  const keyIdPart =
    signaturePart.substring(
      keyIndex +
      keyMarker.length
    );


  const keyId =
    keyIdPart.split("&")[0];


  if (
    !signatureValue ||
    !keyId
  ) {
    throw new Error(
      "Invalid signature parameters."
    );
  }


  let keys =
    await getAdMobKeys();

  let publicKey =
    keys[String(keyId)];


  // Refresh keys if necessary.
  if (!publicKey) {

    keys =
      await getAdMobKeys(true);

    publicKey =
      keys[String(keyId)];
  }


  if (!publicKey) {
    throw new Error(
      "Unknown AdMob key ID."
    );
  }


  // ==========================================================
  // CONVERT BASE64 URL-SAFE SIGNATURE
  // ==========================================================

  const normalizedSignature =
    signatureValue
      .replace(/-/g, "+")
      .replace(/_/g, "/");


  const padding =
    "=".repeat(
      (
        4 -
        normalizedSignature.length % 4
      ) % 4
    );


  const signature =
    Buffer.from(
      normalizedSignature +
      padding,
      "base64"
    );


  // ==========================================================
  // VERIFY SIGNATURE
  // ==========================================================

  const verifier =
    crypto.createVerify(
      "SHA256"
    );


  verifier.update(
    Buffer.from(
      dataToVerify,
      "utf8"
    )
  );

  verifier.end();


  const valid =
    verifier.verify(
      publicKey,
      signature
    );


  if (!valid) {
    throw new Error(
      "Invalid AdMob signature."
    );
  }


  return true;
}


// ============================================================
// ADMOB SERVER-SIDE VERIFICATION
// ============================================================

exports.adMobReward =
  onRequest(
    {
      region:
        "us-central1",

      timeoutSeconds:
        60,

      memory:
        "256MiB",
    },

    async (request, response) => {

      try {

        // ======================================================
        // ONLY GET REQUESTS
        // ======================================================

        if (
          request.method !== "GET"
        ) {

          response
            .status(405)
            .send(
              "Method not allowed"
            );

          return;
        }


        // ======================================================
        // VERIFY GOOGLE SIGNATURE
        // ======================================================

        await verifyAdMobSignature(
          request
        );


        // ======================================================
        // GET ADMOB PARAMETERS
        // ======================================================

        const userId =
          request.query.user_id;

        const transactionId =
          request.query.transaction_id;


        if (
          !userId ||
          !transactionId
        ) {

          response
            .status(400)
            .send(
              "Missing user_id or transaction_id"
            );

          return;
        }


        const uid =
          String(userId);

        const transactionIdString =
          String(transactionId);


        const userRef =
          db.collection("users")
            .doc(uid);


        const transactionRef =
          db.collection(
            "adMobTransactions"
          )
            .doc(
              transactionIdString
            );


        const now =
          new Date();

        const today =
          getUtcDateString();


        // ======================================================
        // FIRESTORE TRANSACTION
        // ======================================================

        const result =
          await db.runTransaction(
            async (transaction) => {

              // ==================================================
              // DUPLICATE PROTECTION
              // ==================================================

              const existingTransaction =
                await transaction.get(
                  transactionRef
                );


              if (
                existingTransaction.exists
              ) {

                return {
                  success: true,
                  duplicate: true,
                };
              }


              // ==================================================
              // GET USER DATA
              // ==================================================

              const userSnapshot =
                await transaction.get(
                  userRef
                );


              const userData =
                userSnapshot.exists
                  ? userSnapshot.data()
                  : {};


              // ==================================================
              // ADS TODAY
              // ==================================================

              let adsToday =
                Number(
                  userData.adsToday || 0
                );


              const adDate =
                userData.adDate || "";


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

                return {
                  success: false,
                  limitReached: true,
                };
              }


              // ==================================================
              // COOLDOWN
              // ==================================================

              const lastAdTimestamp =
                userData.lastAdTimestamp;


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


                if (
                  elapsed <
                  AD_COOLDOWN_MS
                ) {

                  return {
                    success: false,

                    cooldown: true,

                    remainingMs:
                      AD_COOLDOWN_MS -
                      elapsed,
                  };
                }
              }


              // ==================================================
              // ADD STL REWARD
              // ==================================================

              const oldBalance =
                Number(
                  userData.stlBalance || 0
                );


              const newBalance =
                oldBalance +
                AD_REWARD;


              const newAdsToday =
                adsToday + 1;


              // ==================================================
              // UPDATE USER
              // ==================================================

              transaction.set(
                userRef,
                {
                  stlBalance:
                    newBalance,

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
              // SAVE TRANSACTION
              // ==================================================

              transaction.set(
                transactionRef,
                {
                  userId:
                    uid,

                  transactionId:
                    transactionIdString,

                  reward:
                    AD_REWARD,

                  createdAt:
                    FieldValue.serverTimestamp(),
                }
              );


              // ==================================================
              // SUCCESS
              // ==================================================

              return {
                success: true,

                duplicate: false,

                reward:
                  AD_REWARD,

                balance:
                  newBalance,

                adsToday:
                  newAdsToday,
              };
            }
          );


        response
          .status(200)
          .json(result);

      } catch (error) {

        console.error(
          "AdMob SSV error:",
          error
        );


        response
          .status(400)
          .send(
            "Invalid SSV callback"
          );
      }
    }
  );