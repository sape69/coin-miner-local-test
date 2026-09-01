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

// Päivittäisen palkinnon maksimi.
// Päivä 7 ja kaikki sen jälkeiset päivät = 7 STL.
const MAX_DAILY_REWARD = 7;

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
  const date = new Date();

  date.setUTCDate(
    date.getUTCDate() - 1
  );

  return date
    .toISOString()
    .substring(0, 10);
}


// ============================================================
// CALCULATE DAILY REWARD
// ============================================================
//
// Päivä 1 = 1 STL
// Päivä 2 = 2 STL
// Päivä 3 = 3 STL
// ...
// Päivä 7 = 7 STL
// Päivä 8+ = 7 STL
//
// ============================================================

function calculateDailyReward(streak) {
  if (streak >= MAX_DAILY_REWARD) {
    return MAX_DAILY_REWARD;
  }

  if (streak <= 0) {
    return 1;
  }

  return streak;
}


// ============================================================
// DAILY CHECK-IN
// ============================================================

exports.dailyCheckIn =
  onCall(async (request) => {

    // ========================================================
    // AUTH CHECK
    // ========================================================

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


    // ========================================================
    // TRANSACTION
    // ========================================================

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
          // CURRENT DATA
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
            String(
              data.lastDaily || ""
            );


          // ==================================================
          // ALREADY CLAIMED TODAY
          // ==================================================

          if (lastDaily === today) {
            return {
              alreadyClaimed: true,
              balance: oldBalance,
              streak: oldStreak,
              reward: 0,
            };
          }


          // ==================================================
          // CALCULATE NEW STREAK
          // ==================================================
          //
          // Jos viimeisin palkinto oli eilen:
          // streak jatkuu.
          //
          // Jos päivä jäi välistä:
          // streak alkaa uudestaan päivästä 1.
          //
          // ==================================================

          let newStreak;

          if (lastDaily === yesterday) {
            newStreak =
              oldStreak + 1;
          } else {
            newStreak = 1;
          }


          // Maksimi streak UI:ta varten on 7.
          if (
            newStreak >
            MAX_DAILY_REWARD
          ) {
            newStreak =
              MAX_DAILY_REWARD;
          }


          // ==================================================
          // CALCULATE REWARD
          // ==================================================

          const reward =
            calculateDailyReward(
              newStreak
            );


          // ==================================================
          // NEW BALANCE
          // ==================================================

          const newBalance =
            oldBalance +
            reward;


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

    // ========================================================
    // AUTH CHECK
    // ========================================================

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


    // ========================================================
    // LOAD USER
    // ========================================================

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
    // DAILY REWARD STATUS
    // ========================================================

    const lastDaily =
      String(
        data.lastDaily || ""
      );

    let streak =
      Number(
        data.streak || 0
      );


    // Jos päivä jäi välistä, näytetään uusi streak.
    if (
      lastDaily !== today &&
      lastDaily !== yesterday
    ) {
      streak = 0;
    }


    const dailyClaimed =
      lastDaily === today;


    let nextDailyReward;

    if (dailyClaimed) {
      nextDailyReward =
        streak >= MAX_DAILY_REWARD
          ? MAX_DAILY_REWARD
          : streak;
    } else {
      nextDailyReward =
        Math.min(
          streak + 1,
          MAX_DAILY_REWARD
        );
    }


    // ========================================================
    // AD STATUS
    // ========================================================

    const adDate =
      String(
        data.adDate || ""
      );

    let adsToday =
      Number(
        data.adsToday || 0
      );

    if (adDate !== today) {
      adsToday = 0;
    }


    // ========================================================
    // COOLDOWN
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
    // RETURN STATUS
    // ========================================================

    return {
      balance:
        Number(
          data.stlBalance || 0
        ),

      streak:
        streak,

      dailyClaimed:
        dailyClaimed,

      nextDailyReward:
        nextDailyReward,

      adsToday:
        adsToday,

      maxAdsPerDay:
        MAX_ADS_PER_DAY,

      adReward:
        AD_REWARD,

      canWatchAd:
        adsToday <
          MAX_ADS_PER_DAY &&
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

    // ========================================================
    // AUTH CHECK
    // ========================================================

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


    // ========================================================
    // TRANSACTION
    // ========================================================

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
            String(
              data.adDate || ""
            );


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

              const remainingMinutes =
                Math.ceil(
                  remainingMs / 60000
                );

              throw new HttpsError(
                "failed-precondition",
                `Odota vielä ${remainingMinutes} minuuttia.`
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
// Future production use.
// ============================================================

const ADMOB_KEYS_URL =
  "https://www.gstatic.com/admob/reward/verifier-keys.json";

let cachedKeys = null;

let keysCachedAt = 0;

const KEY_CACHE_TIME =
  24 * 60 * 60 * 1000;


// ============================================================
// GET ADMOB KEYS
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


  // ========================================================
  // FIND SIGNATURE
  // ========================================================

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


  // ========================================================
  // FIND KEY ID
  // ========================================================

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
    keyIdPart
      .split("&")[0];


  if (
    !signatureValue ||
    !keyId
  ) {
    throw new Error(
      "Invalid signature parameters."
    );
  }


  // ========================================================
  // GET PUBLIC KEY
  // ========================================================

  let keys =
    await getAdMobKeys();

  let publicKey =
    keys[
      String(keyId)
    ];


  // Refresh keys if necessary.
  if (!publicKey) {
    keys =
      await getAdMobKeys(true);

    publicKey =
      keys[
        String(keyId)
      ];
  }


  if (!publicKey) {
    throw new Error(
      "Unknown AdMob key ID."
    );
  }


  // ========================================================
  // BASE64 URL SIGNATURE
  // ========================================================

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


  // ========================================================
  // VERIFY
  // ========================================================

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
        // ONLY GET
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


              let adsToday =
                Number(
                  userData.adsToday || 0
                );

              const adDate =
                String(
                  userData.adDate || ""
                );


              // ==================================================
              // NEW DAY
              // ==================================================

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
              // ADD REWARD
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


        // ======================================================
        // RESPONSE
        // ======================================================

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