const {
  onCall,
  onRequest,
  HttpsError,
} = require("firebase-functions/v2/https");

const { initializeApp } =
  require("firebase-admin/app");

const {
  getFirestore,
  FieldValue,
} = require("firebase-admin/firestore");

const crypto = require("crypto");

initializeApp();

const db = getFirestore();


// ============================================================
// ADMOB SETTINGS
// ============================================================

const ADMOB_KEYS_URL =
  "https://www.gstatic.com/admob/reward/verifier-keys.json";

const AD_REWARD = 3;

const MAX_ADS_PER_DAY = 5;

const AD_COOLDOWN_MS =
  60 * 60 * 1000;


// ============================================================
// ADMOB PUBLIC KEY CACHE
// ============================================================

let cachedKeys = null;

let keysCachedAt = 0;

const KEY_CACHE_TIME =
  24 * 60 * 60 * 1000;


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
    keys[String(key.keyId)] = key.pem;
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

  // Alkuperäinen query string.
  const originalUrl =
    request.originalUrl || request.url;

  const questionMarkIndex =
    originalUrl.indexOf("?");

  if (questionMarkIndex === -1) {
    throw new Error("Missing query string.");
  }

  const queryString =
    originalUrl.substring(
      questionMarkIndex + 1
    );

  const signatureMarker =
    "&signature=";

  const signatureIndex =
    queryString.indexOf(signatureMarker);

  if (signatureIndex === -1) {
    throw new Error("Missing signature.");
  }

  // Google vaatii, että tarkistettava sisältö
  // pidetään alkuperäisessä muodossaan.
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
    throw new Error("Missing key_id.");
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

  // Ladataan Googlen julkiset avaimet.
  let keys =
    await getAdMobKeys();

  let publicKey =
    keys[String(keyId)];

  // Jos key_id vaihtui avainten rotaatiossa,
  // haetaan avaimet kerran uudelleen.
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

  // AdMob käyttää URL-safe Base64 -muotoa.
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

  // ECDSA SHA-256 signature verification.
  const verifier =
    crypto.createVerify("SHA256");

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
      db.collection("users").doc(uid);

    const now = new Date();

    const today =
      now.toISOString()
        .substring(0, 10);

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


          if (lastDaily === today) {

            return {
              alreadyClaimed: true,
              balance: oldBalance,
              streak: oldStreak,
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
                FieldValue
                  .serverTimestamp(),
            },
            {
              merge: true,
            }
          );


          return {
            alreadyClaimed: false,
            balance: newBalance,
            streak: newStreak,
            reward: reward,
          };
        }
      );


    return result;
  });


// ============================================================
// ADMOB SSV CALLBACK
// ============================================================

exports.adMobReward =
  onRequest(
    async (request, response) => {

      try {

        if (request.method !== "GET") {

          response
            .status(405)
            .send(
              "Method not allowed"
            );

          return;
        }


        // ----------------------------------------------------
        // VERIFY GOOGLE SIGNATURE
        // ----------------------------------------------------

        await verifyAdMobSignature(
          request
        );


        // ----------------------------------------------------
        // GET PARAMETERS
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


        // Käyttäjän Firestore-dokumentti.
        const userRef =
          db.collection("users")
            .doc(String(userId));


        // Tallennetaan transaction erikseen.
        const transactionRef =
          db.collection(
            "adMobTransactions"
          )
            .doc(String(transactionId));


        const now =
          new Date();


        const today =
          now.toISOString()
            .substring(0, 10);


        // ----------------------------------------------------
        // FIRESTORE TRANSACTION
        // ----------------------------------------------------

        const result =
          await db.runTransaction(
            async (transaction) => {

              // Tarkistetaan,
              // onko tämä mainospalkinto
              // jo käsitelty.

              const existingTransaction =
                await transaction.get(
                  transactionRef
                );


              if (
                existingTransaction.exists
              ) {

                return {
                  duplicate: true,
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


              // Uusi päivä.
              if (adDate !== today) {
                adsToday = 0;
              }


              if (
                adsToday >=
                MAX_ADS_PER_DAY
              ) {

                return {
                  limitReached: true,
                };
              }


              // ------------------------------------------------
              // COOLDOWN
              // ------------------------------------------------

              const lastAdTimestamp =
                userData.lastAdTimestamp;

              if (
                lastAdTimestamp &&
                lastAdTimestamp.toDate
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
                    cooldown: true,
                  };
                }
              }


              // ------------------------------------------------
              // ADD STL REWARD
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
                    FieldValue
                      .serverTimestamp(),

                  updatedAt:
                    FieldValue
                      .serverTimestamp(),
                },
                {
                  merge: true,
                }
              );


              // ------------------------------------------------
              // SAVE TRANSACTION ID
              // ------------------------------------------------

              transaction.set(
                transactionRef,
                {
                  userId:
                    String(userId),

                  transactionId:
                    String(transactionId),

                  reward:
                    AD_REWARD,

                  createdAt:
                    FieldValue
                      .serverTimestamp(),
                }
              );


              return {
                success: true,

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
          "AdMob reward processed:",
          result
        );


        // Google odottaa HTTP 200,
        // kun callback käsiteltiin onnistuneesti.
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