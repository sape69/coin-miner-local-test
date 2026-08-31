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
// FIREBASE
// ============================================================

initializeApp();

const db = getFirestore();


// ============================================================
// SETTINGS
// ============================================================

// STL-palkinto yhdestä mainoksesta.
const AD_REWARD = 3;

// Maksimimäärä mainoksia päivässä.
const MAX_ADS_PER_DAY = 5;

// Mainosten välinen odotusaika.
// 60 minuuttia.
const AD_COOLDOWN_MS = 60 * 60 * 1000;


// ============================================================
// ADMOB PUBLIC KEYS
// ============================================================

const ADMOB_KEYS_URL =
  "https://www.gstatic.com/admob/reward/verifier-keys.json";

let cachedKeys = null;

let keysCachedAt = 0;

const KEY_CACHE_TIME =
  24 * 60 * 60 * 1000;


// ============================================================
// UTC DATE
// ============================================================

function getUtcDateString() {

  return new Date()
    .toISOString()
    .substring(0, 10);

}


// ============================================================
// DEBUG LOG FIRESTOREEN
// ============================================================

async function saveDebugLog(type, data = {}) {

  try {

    await db
      .collection("adMobDebug")
      .add({

        type,

        ...data,

        createdAt:
          FieldValue.serverTimestamp(),

      });

  } catch (error) {

    console.error(
      "Could not save debug log:",
      error
    );

  }

}


// ============================================================
// DOWNLOAD ADMOB PUBLIC KEYS
// ============================================================

async function getAdMobKeys(forceRefresh = false) {

  const now = Date.now();

  if (
    !forceRefresh &&
    cachedKeys &&
    now - keysCachedAt < KEY_CACHE_TIME
  ) {

    return cachedKeys;

  }


  console.log(
    "Downloading AdMob public keys"
  );


  const response =
    await fetch(ADMOB_KEYS_URL);


  if (!response.ok) {

    throw new Error(
      `Could not download AdMob public keys. HTTP ${response.status}`
    );

  }


  const data =
    await response.json();

  const keys = {};


  for (const key of data.keys || []) {

    if (key.keyId && key.pem) {

      keys[String(key.keyId)] =
        key.pem;

    }

  }


  if (Object.keys(keys).length === 0) {

    throw new Error(
      "No AdMob public keys available."
    );

  }


  cachedKeys = keys;

  keysCachedAt = now;


  return keys;

}


// ============================================================
// VERIFY ADMOB SSV SIGNATURE
// ============================================================

async function verifyAdMobSignature(request) {

  const originalUrl =
    request.originalUrl || request.url;


  console.log(
    "Original URL:",
    originalUrl
  );


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


  // ==========================================================
  // FIND SIGNATURE
  // ==========================================================

  let signatureStart =
    queryString.indexOf("&signature=");


  let dataToVerify;


  // Jos signature on ensimmäinen parametri.
  if (
    signatureStart === -1 &&
    queryString.startsWith("signature=")
  ) {

    signatureStart = 0;

    dataToVerify = "";

  } else if (signatureStart !== -1) {

    // Kaikki ennen &signature= on allekirjoitettu data.
    dataToVerify =
      queryString.substring(
        0,
        signatureStart
      );

  } else {

    throw new Error(
      "Missing signature."
    );

  }


  // ==========================================================
  // GET SIGNATURE VALUE
  // ==========================================================

  const params =
    new URLSearchParams(queryString);


  const signatureValue =
    params.get("signature");

  const keyId =
    params.get("key_id");


  if (!signatureValue) {

    throw new Error(
      "Missing signature value."
    );

  }


  if (!keyId) {

    throw new Error(
      "Missing key_id."
    );

  }


  console.log(
    "AdMob key ID:",
    keyId
  );


  // ==========================================================
  // GET ADMOB PUBLIC KEY
  // ==========================================================

  let keys =
    await getAdMobKeys();


  let publicKey =
    keys[String(keyId)];


  // Google voi vaihtaa avaimen.
  if (!publicKey) {

    console.log(
      "Key not found in cache. Refreshing keys."
    );


    keys =
      await getAdMobKeys(true);


    publicKey =
      keys[String(keyId)];

  }


  if (!publicKey) {

    throw new Error(
      `Unknown AdMob key ID: ${keyId}`
    );

  }


  // ==========================================================
  // BASE64 URL SAFE -> BASE64
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
      normalizedSignature + padding,
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


  console.log(
    "AdMob signature verified successfully"
  );


  return true;

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


    const now =
      new Date();


    const today =
      getUtcDateString();


    const yesterdayDate =
      new Date(now);


    yesterdayDate.setUTCDate(
      yesterdayDate.getUTCDate() - 1
    );


    const yesterday =
      yesterdayDate
        .toISOString()
        .substring(0, 10);


    return await db.runTransaction(
      async (transaction) => {

        const snapshot =
          await transaction.get(userRef);


        const data =
          snapshot.exists
            ? snapshot.data()
            : {};


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


        // Already claimed today.
        if (lastDaily === today) {

          return {

            alreadyClaimed: true,

            balance:
              oldBalance,

            streak:
              oldStreak,

            reward: 0,

          };

        }


        let newStreak;


        if (lastDaily === yesterday) {

          newStreak =
            oldStreak + 1;

        } else {

          newStreak = 1;

        }


        if (newStreak > 7) {

          newStreak = 7;

        }


        const reward =
          newStreak >= 7
            ? 7
            : 3;


        const newBalance =
          oldBalance + reward;


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


        return {

          alreadyClaimed: false,

          balance:
            newBalance,

          streak:
            newStreak,

          reward,

        };

      }
    );

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


    const adDate =
      data.adDate || "";


    let adsToday =
      Number(
        data.adsToday || 0
      );


    if (adDate !== today) {

      adsToday = 0;

    }


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


    return {

      balance:
        Number(
          data.stlBalance || 0
        ),

      streak:
        Number(
          data.streak || 0
        ),

      adsToday,

      maxAdsPerDay:
        MAX_ADS_PER_DAY,

      adReward:
        AD_REWARD,

      canWatchAd:
        adsToday < MAX_ADS_PER_DAY &&
        cooldownRemainingMs === 0,

      cooldownRemainingMs,

    };

  });


// ============================================================
// ADMOB SERVER-SIDE VERIFICATION
// ============================================================

exports.adMobReward =
  onRequest(
    {
      region: "us-central1",

      timeoutSeconds: 60,

      memory: "256MiB",

    },

    async (request, response) => {

      const originalUrl =
        request.originalUrl || request.url;


      console.log(
        "========================================"
      );

      console.log(
        "AdMob callback received"
      );

      console.log(
        "Method:",
        request.method
      );

      console.log(
        "URL:",
        originalUrl
      );


      // ======================================================
      // DEBUG: CALLBACK ARRIVED
      // ======================================================

      await saveDebugLog(
        "callback_received",
        {

          method:
            request.method,

          // Ei tallenneta signaturea turvallisuussyistä.
          userId:
            request.query.user_id
              ? String(request.query.user_id)
              : null,

          transactionId:
            request.query.transaction_id
              ? String(request.query.transaction_id)
              : null,

          hasSignature:
            Boolean(request.query.signature),

          hasKeyId:
            Boolean(request.query.key_id),

        }
      );


      try {

        // ====================================================
        // ONLY GET
        // ====================================================

        if (request.method !== "GET") {

          await saveDebugLog(
            "error_method",
            {
              method: request.method,
            }
          );


          response
            .status(405)
            .send("Method not allowed");

          return;

        }


        // ====================================================
        // VERIFY SIGNATURE
        // ====================================================

        try {

          await verifyAdMobSignature(
            request
          );


          await saveDebugLog(
            "signature_verified"
          );

        } catch (signatureError) {

          console.error(
            "SIGNATURE ERROR:",
            signatureError
          );


          await saveDebugLog(
            "signature_error",
            {

              error:
                signatureError.message ||
                String(signatureError),

              userId:
                request.query.user_id
                  ? String(request.query.user_id)
                  : null,

              transactionId:
                request.query.transaction_id
                  ? String(request.query.transaction_id)
                  : null,

            }
          );


          response
            .status(400)
            .send("Invalid AdMob signature");

          return;

        }


        // ====================================================
        // GET PARAMETERS
        // ====================================================

        const userId =
          request.query.user_id;


        const transactionId =
          request.query.transaction_id;


        if (!userId || !transactionId) {

          await saveDebugLog(
            "missing_parameters",
            {

              hasUserId:
                Boolean(userId),

              hasTransactionId:
                Boolean(transactionId),

            }
          );


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


        console.log(
          "Processing reward for user:",
          uid
        );


        console.log(
          "Transaction:",
          transactionIdString
        );


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


        // ====================================================
        // FIRESTORE TRANSACTION
        // ====================================================

        const result =
          await db.runTransaction(
            async (transaction) => {

              // Duplicate protection.
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

                  message:
                    "Transaction already processed.",

                };

              }


              // Get user.
              const userSnapshot =
                await transaction.get(
                  userRef
                );


              const userData =
                userSnapshot.exists
                  ? userSnapshot.data()
                  : {};


              // =================================================
              // ADS TODAY
              // =================================================

              let adsToday =
                Number(
                  userData.adsToday || 0
                );


              const adDate =
                userData.adDate || "";


              if (adDate !== today) {

                adsToday = 0;

              }


              // =================================================
              // DAILY LIMIT
              // =================================================

              if (
                adsToday >= MAX_ADS_PER_DAY
              ) {

                return {

                  success: false,

                  limitReached: true,

                  message:
                    "Daily ad limit reached.",

                };

              }


              // =================================================
              // COOLDOWN
              // =================================================

              const lastAdTimestamp =
                userData.lastAdTimestamp;


              if (
                lastAdTimestamp &&
                typeof lastAdTimestamp.toDate ===
                  "function"
              ) {

                const lastAdTime =
                  lastAdTimestamp.toDate();


                const timeSinceLastAd =
                  now.getTime() -
                  lastAdTime.getTime();


                if (
                  timeSinceLastAd <
                  AD_COOLDOWN_MS
                ) {

                  return {

                    success: false,

                    cooldown: true,

                    remainingMs:
                      AD_COOLDOWN_MS -
                      timeSinceLastAd,

                  };

                }

              }


              // =================================================
              // ADD REWARD
              // =================================================

              const oldBalance =
                Number(
                  userData.stlBalance || 0
                );


              const newBalance =
                oldBalance +
                AD_REWARD;


              const newAdsToday =
                adsToday + 1;


              // Update user.
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


              // Save transaction.
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


        console.log(
          "AdMob reward result:",
          result
        );


        // ====================================================
        // SAVE RESULT TO DEBUG
        // ====================================================

        await saveDebugLog(
          "reward_result",
          {

            userId: uid,

            transactionId:
              transactionIdString,

            success:
              Boolean(result.success),

            duplicate:
              Boolean(result.duplicate),

            limitReached:
              Boolean(result.limitReached),

            cooldown:
              Boolean(result.cooldown),

            reward:
              result.reward || 0,

            balance:
              result.balance || null,

            adsToday:
              result.adsToday || null,

          }
        );


        response
          .status(200)
          .json(result);


      } catch (error) {

        console.error(
          "AdMob SSV ERROR:",
          error
        );


        await saveDebugLog(
          "fatal_error",
          {

            error:
              error.message ||
              String(error),

            userId:
              request.query.user_id
                ? String(request.query.user_id)
                : null,

            transactionId:
              request.query.transaction_id
                ? String(request.query.transaction_id)
                : null,

          }
        );


        response
          .status(500)
          .send(
            "Internal SSV error"
          );

      }

    }
  );