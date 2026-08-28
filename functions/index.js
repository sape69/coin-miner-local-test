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

// STL-palkinto yhdestä mainoksesta.
const AD_REWARD = 3;

// Maksimimäärä mainoksia päivässä.
const MAX_ADS_PER_DAY = 5;

// Mainosten välinen odotusaika.
// 60 minuuttia.
const AD_COOLDOWN_MS =
  60 * 60 * 1000;


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

  if (
    !forceRefresh &&
    cachedKeys &&
    now - keysCachedAt < KEY_CACHE_TIME
  ) {
    return cachedKeys;
  }

  const response =
    await fetch(ADMOB_KEYS_URL);

  if (!response.ok) {
    throw new Error(
      "Could not download AdMob public keys."
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

  if (
    Object.keys(keys).length === 0
  ) {
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
    request.originalUrl ||
    request.url;

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


  // Google-signatuurin tarkistettava data.
  const dataToVerify =
    queryString.substring(
      0,
      signatureIndex
    );


  const signatureAndKey =
    queryString.substring(
      signatureIndex + 1
    );


  const keyMarker =
    "&key_id=";


  const keyIndex =
    signatureAndKey.indexOf(
      keyMarker
    );


  if (keyIndex === -1) {
    throw new Error(
      "Missing key_id."
    );
  }


  const signatureValue =
    signatureAndKey.substring(
      "signature=".length,
      keyIndex
    );


  const keyId =
    signatureAndKey.substring(
      keyIndex +
      keyMarker.length
    );


  let keys =
    await getAdMobKeys();


  let publicKey =
    keys[String(keyId)];


  // Jos Googlen avaimet ovat vaihtuneet,
  // haetaan ne uudelleen.
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


  // URL-safe Base64 -> tavallinen Base64.
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


          // Sama päivä.
          if (lastDaily === today) {

            return {
              alreadyClaimed: true,
              balance: oldBalance,
              streak: oldStreak,
              reward: 0,
            };
          }


          let newStreak;


          // Streak jatkuu,
          // jos edellinen check-in oli eilen.
          if (lastDaily === yesterday) {

            newStreak =
              oldStreak + 1;

          } else {

            newStreak = 1;
          }


          // Maksimi 7.
          if (newStreak > 7) {

            newStreak = 7;
          }


          // Päivät 1–6 = 3 STL
          // Päivä 7 = 7 STL
          const reward =
            newStreak >= 7
              ? 7
              : 3;


          const newBalance =
            oldBalance +
            reward;


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

            reward:
              reward,

          };
        }
      );


    return result;
  });


// ============================================================
// GET USER REWARD STATUS
//
// Flutter voi kutsua tätä tarkistaakseen:
// - STL-saldon
// - päivän mainosmäärän
// - cooldownin
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


    // Jos päivä vaihtui,
    // näytetään 0 mainosta.
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

      adsToday:
        adsToday,

      maxAdsPerDay:
        MAX_ADS_PER_DAY,

      canWatchAd:
        adsToday < MAX_ADS_PER_DAY &&
        cooldownRemainingMs === 0,

      cooldownRemainingMs:
        cooldownRemainingMs,

    };
  });


// ============================================================
// ADMOB SERVER-SIDE VERIFICATION CALLBACK
//
// TÄTÄ EI KUTSUTA FLUTTERISTA.
//
// Google AdMob kutsuu tätä URL:ia,
// kun mainospalkinto on vahvistettu.
// ============================================================

exports.adMobReward =
  onRequest(
    async (request, response) => {

      try {

        // Vain GET hyväksytään.
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


        // ----------------------------------------------------
        // VERIFY GOOGLE ADMOB SIGNATURE
        // ----------------------------------------------------

        await verifyAdMobSignature(
          request
        );


        // ----------------------------------------------------
        // READ ADMOB PARAMETERS
        // ----------------------------------------------------

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


        // ----------------------------------------------------
        // FIRESTORE TRANSACTION
        // ----------------------------------------------------

        const result =
          await db.runTransaction(
            async (transaction) => {

              // Tarkistetaan,
              // onko transaction jo käsitelty.
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
                userData.adDate || "";


              // Päivä vaihtunut.
              if (
                adDate !== today
              ) {

                adsToday = 0;
              }


              // ------------------------------------------------
              // DAILY LIMIT
              // ------------------------------------------------

              if (
                adsToday >=
                MAX_ADS_PER_DAY
              ) {

                return {

                  success: false,

                  limitReached: true,

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

                    success: false,

                    cooldown: true,

                    remainingMs:
                      AD_COOLDOWN_MS -
                      timeSinceLastAd,

                  };
                }
              }


              // ------------------------------------------------
              // ADD STL
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


              // Päivitetään käyttäjä.
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


              // Tallennetaan transaction.
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


        // Google tarvitsee onnistuneen HTTP-vastauksen.
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