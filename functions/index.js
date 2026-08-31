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
const AD_COOLDOWN_MS = 60 * 60 * 1000;


// ============================================================
// ADMOB DEBUG LOGGING TO FIRESTORE
// ============================================================

async function saveAdMobDebug(type, data = {}) {

  try {

    await db
      .collection("adMobDebug")
      .add({

        type: type,

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
// ADMOB PUBLIC KEYS
// ============================================================

const ADMOB_KEYS_URL =
  "https://www.gstatic.com/admob/reward/verifier-keys.json";

let cachedKeys = null;

let keysCachedAt = 0;

const KEY_CACHE_TIME =
  24 * 60 * 60 * 1000;


// ============================================================
// GET UTC DATE
// ============================================================

function getUtcDateString() {

  return new Date()
    .toISOString()
    .substring(0, 10);
}


// ============================================================
// DOWNLOAD ADMOB PUBLIC KEYS
// ============================================================

async function getAdMobKeys(forceRefresh = false) {

  const now = Date.now();


  // ----------------------------------------------------------
  // USE CACHE
  // ----------------------------------------------------------

  if (
    !forceRefresh &&
    cachedKeys &&
    now - keysCachedAt < KEY_CACHE_TIME
  ) {

    return cachedKeys;
  }


  // ----------------------------------------------------------
  // DEBUG
  // ----------------------------------------------------------

  await saveAdMobDebug(
    "downloading_public_keys",
    {
      forceRefresh: forceRefresh,
    }
  );


  // ----------------------------------------------------------
  // DOWNLOAD KEYS
  // ----------------------------------------------------------

  const response =
    await fetch(ADMOB_KEYS_URL);


  if (!response.ok) {

    await saveAdMobDebug(
      "public_keys_error",
      {
        status: response.status,
      }
    );

    throw new Error(
      "Could not download AdMob public keys."
    );
  }


  const data =
    await response.json();

  const keys = {};


  for (const key of data.keys || []) {

    if (
      key.keyId &&
      key.pem
    ) {

      keys[String(key.keyId)] =
        key.pem;
    }
  }


  if (
    Object.keys(keys).length === 0
  ) {

    await saveAdMobDebug(
      "public_keys_error",
      {
        message:
          "No AdMob public keys available.",
      }
    );

    throw new Error(
      "No AdMob public keys available."
    );
  }


  // ----------------------------------------------------------
  // SAVE CACHE
  // ----------------------------------------------------------

  cachedKeys =
    keys;

  keysCachedAt =
    now;


  await saveAdMobDebug(
    "public_keys_downloaded",
    {
      keyCount:
        Object.keys(keys).length,
    }
  );


  return keys;
}


// ============================================================
// VERIFY ADMOB SSV SIGNATURE
// ============================================================

async function verifyAdMobSignature(request) {

  const originalUrl =
    request.originalUrl ||
    request.url;


  // ----------------------------------------------------------
  // CHECK URL
  // ----------------------------------------------------------

  if (!originalUrl) {

    await saveAdMobDebug(
      "signature_error",
      {
        reason:
          "Missing request URL.",
      }
    );

    throw new Error(
      "Missing request URL."
    );
  }


  const questionMarkIndex =
    originalUrl.indexOf("?");


  if (questionMarkIndex === -1) {

    await saveAdMobDebug(
      "signature_error",
      {
        reason:
          "Missing query string.",
      }
    );

    throw new Error(
      "Missing query string."
    );
  }


  const queryString =
    originalUrl.substring(
      questionMarkIndex + 1
    );


  // ----------------------------------------------------------
  // CHECK SIGNATURE
  // ----------------------------------------------------------

  const signatureIndex =
    queryString.indexOf(
      "&signature="
    );


  if (signatureIndex === -1) {

    await saveAdMobDebug(
      "signature_error",
      {
        reason:
          "Missing signature parameter.",
      }
    );

    throw new Error(
      "Missing signature."
    );
  }


  // ----------------------------------------------------------
  // DATA TO VERIFY
  // ----------------------------------------------------------

  const dataToVerify =
    queryString.substring(
      0,
      signatureIndex
    );


  const signaturePart =
    queryString.substring(
      signatureIndex + 1
    );


  // ----------------------------------------------------------
  // FIND KEY ID
  // ----------------------------------------------------------

  const keyMarker =
    "&key_id=";


  const keyIndex =
    signaturePart.indexOf(
      keyMarker
    );


  if (keyIndex === -1) {

    await saveAdMobDebug(
      "signature_error",
      {
        reason:
          "Missing key_id.",
      }
    );

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

    await saveAdMobDebug(
      "signature_error",
      {
        reason:
          "Invalid signature parameters.",
      }
    );

    throw new Error(
      "Invalid signature parameters."
    );
  }


  await saveAdMobDebug(
    "signature_parameters_found",
    {
      keyId:
        String(keyId),
    }
  );


  // ==========================================================
  // GET PUBLIC KEY
  // ==========================================================

  let keys =
    await getAdMobKeys();


  let publicKey =
    keys[String(keyId)];


  // ----------------------------------------------------------
  // REFRESH KEYS IF GOOGLE CHANGED THEM
  // ----------------------------------------------------------

  if (!publicKey) {

    await saveAdMobDebug(
      "key_not_found_refreshing",
      {
        keyId:
          String(keyId),
      }
    );


    keys =
      await getAdMobKeys(true);


    publicKey =
      keys[String(keyId)];
  }


  if (!publicKey) {

    await saveAdMobDebug(
      "signature_error",
      {
        reason:
          "Unknown AdMob key ID.",
        keyId:
          String(keyId),
      }
    );

    throw new Error(
      "Unknown AdMob key ID."
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

    await saveAdMobDebug(
      "signature_error",
      {
        reason:
          "Invalid AdMob signature.",
        keyId:
          String(keyId),
      }
    );

    throw new Error(
      "Invalid AdMob signature."
    );
  }


  await saveAdMobDebug(
    "signature_verified",
    {
      keyId:
        String(keyId),
    }
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


          // ====================================================
          // ALREADY CLAIMED
          // ====================================================

          if (
            lastDaily === today
          ) {

            return {

              alreadyClaimed:
                true,

              balance:
                oldBalance,

              streak:
                oldStreak,

              reward:
                0,

            };
          }


          // ====================================================
          // CALCULATE STREAK
          // ====================================================

          let newStreak;


          if (
            lastDaily === yesterday
          ) {

            newStreak =
              oldStreak + 1;

          } else {

            newStreak =
              1;
          }


          if (
            newStreak > 7
          ) {

            newStreak =
              7;
          }


          // ====================================================
          // CALCULATE REWARD
          // ====================================================

          const reward =
            newStreak >= 7
              ? 7
              : 3;


          const newBalance =
            oldBalance +
            reward;


          // ====================================================
          // UPDATE USER
          // ====================================================

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

            alreadyClaimed:
              false,

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


    const adDate =
      data.adDate || "";


    let adsToday =
      Number(
        data.adsToday || 0
      );


    // ==========================================================
    // NEW DAY
    // ==========================================================

    if (
      adDate !== today
    ) {

      adsToday =
        0;
    }


    // ==========================================================
    // COOLDOWN
    // ==========================================================

    let cooldownRemainingMs =
      0;


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


    return {

      balance:
        Number(
          data.stlBalance || 0
        ),

      streak:
        Number(
          data.streak || 0
        ),

      adsToday:
        adsToday,

      maxAdsPerDay:
        MAX_ADS_PER_DAY,

      adReward:
        AD_REWARD,

      canWatchAd:
        adsToday <
          MAX_ADS_PER_DAY &&
        cooldownRemainingMs ===
          0,

      cooldownRemainingMs:
        cooldownRemainingMs,

    };
  });


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
        // CALLBACK RECEIVED
        // ======================================================

        console.log(
          "AdMob callback received"
        );


        await saveAdMobDebug(
          "callback_received",
          {
            method:
              request.method,

            hasUserId:
              !!request.query.user_id,

            hasTransactionId:
              !!request.query.transaction_id,

            hasSignature:
              !!request.query.signature,

            hasKeyId:
              !!request.query.key_id,
          }
        );


        // ======================================================
        // ONLY GET
        // ======================================================

        if (
          request.method !== "GET"
        ) {

          await saveAdMobDebug(
            "method_error",
            {
              method:
                request.method,
            }
          );


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

        try {

          await verifyAdMobSignature(
            request
          );

        } catch (signatureError) {

          await saveAdMobDebug(
            "signature_error",
            {
              error:
                String(
                  signatureError
                ),
            }
          );

          throw signatureError;
        }


        // ======================================================
        // GET PARAMETERS
        // ======================================================

        const userId =
          request.query.user_id;


        const transactionId =
          request.query.transaction_id;


        if (
          !userId ||
          !transactionId
        ) {

          await saveAdMobDebug(
            "missing_parameters",
            {
              hasUserId:
                !!userId,

              hasTransactionId:
                !!transactionId,
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


        await saveAdMobDebug(
          "parameters_verified",
          {
            userId:
              uid,

            transactionId:
              transactionIdString,
          }
        );


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


        // ======================================================
        // DUPLICATE PROTECTION
        // ======================================================

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

              // ------------------------------------------------
              // CHECK DUPLICATE
              // ------------------------------------------------

              const existingTransaction =
                await transaction.get(
                  transactionRef
                );


              if (
                existingTransaction.exists
              ) {

                return {

                  success:
                    true,

                  duplicate:
                    true,

                  message:
                    "Transaction already processed.",

                };
              }


              // ------------------------------------------------
              // GET USER
              // ------------------------------------------------

              const userSnapshot =
                await transaction.get(
                  userRef
                );


              const userData =
                userSnapshot.exists
                  ? userSnapshot.data()
                  : {};


              // ------------------------------------------------
              // ADS TODAY
              // ------------------------------------------------

              let adsToday =
                Number(
                  userData.adsToday || 0
                );


              const adDate =
                userData.adDate || "";


              if (
                adDate !== today
              ) {

                adsToday =
                  0;
              }


              // ------------------------------------------------
              // DAILY LIMIT
              // ------------------------------------------------

              if (
                adsToday >=
                MAX_ADS_PER_DAY
              ) {

                return {

                  success:
                    false,

                  limitReached:
                    true,

                  message:
                    "Daily ad limit reached.",

                };
              }


              // ------------------------------------------------
              // COOLDOWN
              // ------------------------------------------------

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

                    success:
                      false,

                    cooldown:
                      true,

                    remainingMs:
                      AD_COOLDOWN_MS -
                      timeSinceLastAd,

                  };
                }
              }


              // ------------------------------------------------
              // ADD REWARD
              // ------------------------------------------------

              const oldBalance =
                Number(
                  userData.stlBalance || 0
                );


              const newBalance =
                oldBalance +
                AD_REWARD;


              const newAdsToday =
                adsToday + 1;


              // ------------------------------------------------
              // UPDATE USER
              // ------------------------------------------------

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


              // ------------------------------------------------
              // SAVE TRANSACTION
              // ------------------------------------------------

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

                success:
                  true,

                duplicate:
                  false,

                reward:
                  AD_REWARD,

                balance:
                  newBalance,

                adsToday:
                  newAdsToday,

              };
            }
          );


        // ======================================================
        // SAVE RESULT TO DEBUG
        // ======================================================

        await saveAdMobDebug(
          "reward_result",
          {
            success:
              result.success,

            duplicate:
              result.duplicate || false,

            limitReached:
              result.limitReached || false,

            cooldown:
              result.cooldown || false,

            reward:
              result.reward || 0,

            balance:
              result.balance || null,

            adsToday:
              result.adsToday || null,
          }
        );


        console.log(
          "AdMob reward result:",
          result
        );


        // ======================================================
        // SUCCESS RESPONSE
        // ======================================================

        response
          .status(200)
          .json(result);

      } catch (error) {

        console.error(
          "AdMob SSV error:",
          error
        );


        // ======================================================
        // SAVE FATAL ERROR
        // ======================================================

        await saveAdMobDebug(
          "fatal_error",
          {
            error:
              String(error),

            message:
              error.message || "",
          }
        );


        response
          .status(400)
          .send(
            "Invalid SSV callback"
          );
      }
    }
  );