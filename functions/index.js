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
  Timestamp,
} = require("firebase-admin/firestore");

const crypto = require("crypto");


// ============================================================
// FIREBASE INITIALIZATION
// ============================================================

initializeApp();

const db = getFirestore();


// ============================================================
// STELLA MINING SETTINGS
// ============================================================

// 🐱 Stella mining system
//
// Käyttäjä ei saa mainoksesta suoraan STL-tokenia.
//
// Mainokset ja päivittäinen check-in kasvattavat
// käyttäjän Hash Ratea.
//
// Hash Rate määrittää, kuinka nopeasti käyttäjän
// virtual mining balance kasvaa.


// ============================================================
// DEFAULT HASH RATE
// ============================================================

const DEFAULT_HASH_RATE = 1;


// ============================================================
// AD HASH RATE BOOST
// ============================================================
//
// Yksi katsottu mainos lisää Hash Ratea.

const AD_HASHRATE_BOOST = 1;


// ============================================================
// DAILY HASH RATE BOOST
// ============================================================
//
// Päivittäinen check-in kasvattaa Hash Ratea.
//
// Päivä 1 = +1
// Päivä 2 = +2
// ...
// Päivä 7 = +7
// Päivä 8+ = +7

const MAX_DAILY_BOOST = 7;


// ============================================================
// MAX ADS PER DAY
// ============================================================

const MAX_ADS_PER_DAY = 5;


// ============================================================
// AD COOLDOWN
// ============================================================
//
// 60 minuuttia.

const AD_COOLDOWN_MS =
  60 * 60 * 1000;


// ============================================================
// MINING SETTINGS
// ============================================================
//
// Kuinka paljon virtual mining balancea
// yksi Hash Rate tuottaa sekunnissa.
//
// Esimerkki:
//
// Hash Rate 1
// = 0.0001 mining units / second
//
// Hash Rate 10
// = 0.001 mining units / second

const MINING_PER_HASH_PER_SECOND =
  0.0001;


// ============================================================
// TRANSACTION HISTORY SETTINGS
// ============================================================

const MAX_TRANSACTION_HISTORY = 50;


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
// CALCULATE DAILY HASH RATE BOOST
// ============================================================

function calculateDailyBoost(streak) {

  if (
    streak >=
    MAX_DAILY_BOOST
  ) {
    return MAX_DAILY_BOOST;
  }

  if (
    streak <= 0
  ) {
    return 1;
  }

  return streak;
}


// ============================================================
// GET USER TRANSACTIONS COLLECTION
// ============================================================

function getTransactionsCollection(uid) {
  return db
    .collection("users")
    .doc(uid)
    .collection("transactions");
}


// ============================================================
// GET CURRENT MINING BALANCE
// ============================================================
//
// Laskee louhinnan viimeisestä päivityksestä tähän hetkeen.
//
// Tämä funktio EI kirjoita Firestoreen.

function calculateMiningBalance(
  data,
  now
) {

  const oldBalance =
    Number(
      data.miningBalance || 0
    );

  const hashRate =
    Number(
      data.hashRate ||
      DEFAULT_HASH_RATE
    );

  const lastMiningUpdate =
    data.lastMiningUpdate;


  // Jos käyttäjällä ei ole vielä mining timestampia.

  if (
    !lastMiningUpdate ||
    typeof lastMiningUpdate.toDate !==
      "function"
  ) {
    return {
      balance: oldBalance,
      minedAmount: 0,
      elapsedSeconds: 0,
      hashRate: hashRate,
    };
  }


  const lastUpdateDate =
    lastMiningUpdate.toDate();


  const elapsedMilliseconds =
    now.getTime() -
    lastUpdateDate.getTime();


  const elapsedSeconds =
    Math.max(
      0,
      elapsedMilliseconds / 1000
    );


  const minedAmount =
    hashRate *
    MINING_PER_HASH_PER_SECOND *
    elapsedSeconds;


  const newBalance =
    oldBalance +
    minedAmount;


  return {
    balance: newBalance,
    minedAmount: minedAmount,
    elapsedSeconds: elapsedSeconds,
    hashRate: hashRate,
  };
}


// ============================================================
// UPDATE MINING
// ============================================================
//
// Laskee käyttäjän louhinnan ja tallentaa
// uuden tilanteen Firestoreen.

async function updateMining(
  transaction,
  userRef,
  data,
  now
) {

  const mining =
    calculateMiningBalance(
      data,
      now
    );


  transaction.set(
    userRef,
    {
      miningBalance:
        mining.balance,

      totalMined:
        Number(
          data.totalMined || 0
        ) +
        mining.minedAmount,

      lastMiningUpdate:
        Timestamp.fromDate(now),

      updatedAt:
        FieldValue.serverTimestamp(),
    },
    {
      merge: true,
    }
  );


  return mining;
}


// ============================================================
// INITIALIZE USER MINING
// ============================================================

async function ensureMiningUser(
  transaction,
  userRef,
  snapshot,
  now
) {

  if (
    snapshot.exists
  ) {
    return snapshot.data();
  }


  const userData = {
    hashRate:
      DEFAULT_HASH_RATE,

    miningBalance:
      0,

    totalMined:
      0,

    streak:
      0,

    adsToday:
      0,

    adDate:
      "",

    lastDaily:
      "",

    lastMiningUpdate:
      Timestamp.fromDate(now),

    createdAt:
      FieldValue.serverTimestamp(),

    updatedAt:
      FieldValue.serverTimestamp(),
  };


  transaction.set(
    userRef,
    userData,
    {
      merge: true,
    }
  );


  return userData;
}


// ============================================================
// GET MINING STATUS
// ============================================================

exports.getMiningStatus =
  onCall(async (request) => {

    // ========================================================
    // AUTH CHECK
    // ========================================================

    if (
      !request.auth
    ) {
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


    // ========================================================
    // LOAD USER
    // ========================================================

    const snapshot =
      await userRef.get();


    // ========================================================
    // NEW USER
    // ========================================================

    if (
      !snapshot.exists
    ) {

      await userRef.set(
        {
          hashRate:
            DEFAULT_HASH_RATE,

          miningBalance:
            0,

          totalMined:
            0,

          streak:
            0,

          adsToday:
            0,

          adDate:
            "",

          lastDaily:
            "",

          lastMiningUpdate:
            Timestamp.fromDate(now),

          createdAt:
            FieldValue.serverTimestamp(),

          updatedAt:
            FieldValue.serverTimestamp(),
        },
        {
          merge: true,
        }
      );


      return {
        hashRate:
          DEFAULT_HASH_RATE,

        miningBalance:
          0,

        totalMined:
          0,

        miningPerSecond:
          DEFAULT_HASH_RATE *
          MINING_PER_HASH_PER_SECOND,

        elapsedSeconds:
          0,
      };
    }


    const data =
      snapshot.data();


    // ========================================================
    // CALCULATE CURRENT MINING
    // ========================================================

    const mining =
      calculateMiningBalance(
        data,
        now
      );


    // ========================================================
    // RETURN
    // ========================================================

    return {
      hashRate:
        mining.hashRate,

      miningBalance:
        mining.balance,

      totalMined:
        Number(
          data.totalMined || 0
        ) +
        mining.minedAmount,

      miningPerSecond:
        mining.hashRate *
        MINING_PER_HASH_PER_SECOND,

      elapsedSeconds:
        mining.elapsedSeconds,
    };
  });


// ============================================================
// DAILY CHECK-IN
// ============================================================
//
// Päivittäinen check-in kasvattaa Hash Ratea.

exports.dailyCheckIn =
  onCall(async (request) => {

    if (
      !request.auth
    ) {
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


    const now =
      new Date();


    const transactionRef =
      getTransactionsCollection(uid)
        .doc(
          `daily_${today}`
        );


    const result =
      await db.runTransaction(
        async (transaction) => {

          const snapshot =
            await transaction.get(
              userRef
            );


          const data =
            await ensureMiningUser(
              transaction,
              userRef,
              snapshot,
              now
            );


          // ==================================================
          // UPDATE MINING FIRST
          // ==================================================

          const mining =
            await updateMining(
              transaction,
              userRef,
              data,
              now
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
          // ALREADY CLAIMED
          // ==================================================

          if (
            lastDaily === today
          ) {
            return {
              alreadyClaimed: true,

              hashRate:
                Number(
                  data.hashRate ||
                  DEFAULT_HASH_RATE
                ),

              miningBalance:
                mining.balance,

              streak:
                oldStreak,

              boost:
                0,
            };
          }


          // ==================================================
          // CALCULATE STREAK
          // ==================================================

          let newStreak;


          if (
            lastDaily === yesterday
          ) {
            newStreak =
              oldStreak + 1;
          } else {
            newStreak = 1;
          }


          if (
            newStreak >
            MAX_DAILY_BOOST
          ) {
            newStreak =
              MAX_DAILY_BOOST;
          }


          // ==================================================
          // CALCULATE BOOST
          // ==================================================

          const boost =
            calculateDailyBoost(
              newStreak
            );


          const oldHashRate =
            Number(
              data.hashRate ||
              DEFAULT_HASH_RATE
            );


          const newHashRate =
            oldHashRate +
            boost;


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
          // SAVE HISTORY
          // ==================================================

          transaction.set(
            transactionRef,
            {
              type:
                "daily_hashrate_boost",

              title:
                "🐱 Stella Daily Mining Boost",

              amount:
                boost,

              hashRateAfter:
                newHashRate,

              miningBalanceAfter:
                mining.balance,

              streak:
                newStreak,

              source:
                "daily_check_in",

              date:
                today,

              createdAt:
                FieldValue.serverTimestamp(),
            }
          );


          return {
            alreadyClaimed: false,

            hashRate:
              newHashRate,

            miningBalance:
              mining.balance,

            streak:
              newStreak,

            boost:
              boost,
          };
        }
      );


    return result;
  });


// ============================================================
// GET REWARD / MINING STATUS
// ============================================================
//
// Säilytetään tämä nimi, jotta Flutter-sovellus voidaan
// tarvittaessa päivittää vaiheittain.

exports.getRewardStatus =
  onCall(async (request) => {

    if (
      !request.auth
    ) {
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


    const now =
      new Date();


    const today =
      getUtcDateString();


    const yesterday =
      getYesterdayUtcDateString();


    const data =
      snapshot.exists
        ? snapshot.data()
        : {};


    // ========================================================
    // MINING
    // ========================================================

    const mining =
      calculateMiningBalance(
        data,
        now
      );


    // ========================================================
    // DAILY STATUS
    // ========================================================

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


    const dailyClaimed =
      lastDaily === today;


    let nextDailyBoost;


    if (
      dailyClaimed
    ) {
      nextDailyBoost =
        streak >= MAX_DAILY_BOOST
          ? MAX_DAILY_BOOST
          : streak;
    } else {
      nextDailyBoost =
        Math.min(
          streak + 1,
          MAX_DAILY_BOOST
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


    if (
      adDate !== today
    ) {
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


    return {
      // Mining
      hashRate:
        mining.hashRate,

      miningBalance:
        mining.balance,

      totalMined:
        Number(
          data.totalMined || 0
        ) +
        mining.minedAmount,

      miningPerSecond:
        mining.hashRate *
        MINING_PER_HASH_PER_SECOND,


      // Daily
      streak:
        streak,

      dailyClaimed:
        dailyClaimed,

      nextDailyBoost:
        nextDailyBoost,


      // Ads
      adsToday:
        adsToday,

      maxAdsPerDay:
        MAX_ADS_PER_DAY,

      adHashRateBoost:
        AD_HASHRATE_BOOST,

      canWatchAd:
        adsToday <
          MAX_ADS_PER_DAY &&
        cooldownRemainingMs === 0,

      cooldownRemainingMs:
        cooldownRemainingMs,
    };
  });


// ============================================================
// GET MINING HISTORY
// ============================================================

exports.getTransactionHistory =
  onCall(async (request) => {

    if (
      !request.auth
    ) {
      throw new HttpsError(
        "unauthenticated",
        "Käyttäjän täytyy olla kirjautunut."
      );
    }


    const uid =
      request.auth.uid;


    const snapshot =
      await getTransactionsCollection(uid)
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

            hashRateAfter:
              Number(
                data.hashRateAfter || 0
              ),

            miningBalanceAfter:
              Number(
                data.miningBalanceAfter || 0
              ),

            source:
              String(
                data.source || ""
              ),

            date:
              String(
                data.date || ""
              ),

            streak:
              Number(
                data.streak || 0
              ),

            createdAt:
              createdAt,
          };
        }
      );


    return {
      transactions:
        transactions,
    };
  });


// ============================================================
// TEST AD HASH RATE BOOST
// ============================================================
//
// DEVELOPMENT ONLY
//
// Käytetään Googlen test rewarded adin kanssa.

exports.testAdReward =
  onCall(async (request) => {

    if (
      !request.auth
    ) {
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


    const transactionRef =
      getTransactionsCollection(uid)
        .doc();


    const result =
      await db.runTransaction(
        async (transaction) => {

          const snapshot =
            await transaction.get(
              userRef
            );


          const data =
            await ensureMiningUser(
              transaction,
              userRef,
              snapshot,
              now
            );


          // ==================================================
          // UPDATE MINING BEFORE BOOST
          // ==================================================

          const mining =
            await updateMining(
              transaction,
              userRef,
              data,
              now
            );


          // ==================================================
          // AD COUNT
          // ==================================================

          let adsToday =
            Number(
              data.adsToday || 0
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
              "🐱 Stella on jo saanut päivän maksimi Mining Boostit."
            );
          }


          // ==================================================
          // COOLDOWN
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
                `🐱 Stella lepää vielä ${remainingMinutes} minuuttia.`
              );
            }
          }


          // ==================================================
          // ADD HASH RATE
          // ==================================================

          const oldHashRate =
            Number(
              data.hashRate ||
              DEFAULT_HASH_RATE
            );


          const newHashRate =
            oldHashRate +
            AD_HASHRATE_BOOST;


          const newAdsToday =
            adsToday + 1;


          // ==================================================
          // UPDATE USER
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
                Timestamp.fromDate(now),

              updatedAt:
                FieldValue.serverTimestamp(),
            },
            {
              merge: true,
            }
          );


          // ==================================================
          // SAVE HISTORY
          // ==================================================

          transaction.set(
            transactionRef,
            {
              type:
                "ad_hashrate_boost",

              title:
                "🐱 Stella Mining Boost",

              amount:
                AD_HASHRATE_BOOST,

              hashRateAfter:
                newHashRate,

              miningBalanceAfter:
                mining.balance,

              source:
                "test_ad",

              date:
                today,

              createdAt:
                FieldValue.serverTimestamp(),
            }
          );


          return {
            success:
              true,

            hashRate:
              newHashRate,

            miningBalance:
              mining.balance,

            adsToday:
              newAdsToday,

            boost:
              AD_HASHRATE_BOOST,
          };
        }
      );


    return result;
  });


// ============================================================
// ADMOB SERVER-SIDE VERIFICATION
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


  if (
    !response.ok
  ) {
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


  if (
    !originalUrl
  ) {
    throw new Error(
      "Missing request URL."
    );
  }


  const questionMarkIndex =
    originalUrl.indexOf("?");


  if (
    questionMarkIndex === -1
  ) {
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


  if (
    signatureIndex === -1
  ) {
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


  if (
    keyIndex === -1
  ) {
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


  let keys =
    await getAdMobKeys();


  let publicKey =
    keys[
      String(keyId)
    ];


  if (
    !publicKey
  ) {

    keys =
      await getAdMobKeys(
        true
      );


    publicKey =
      keys[
        String(keyId)
      ];
  }


  if (
    !publicKey
  ) {
    throw new Error(
      "Unknown AdMob key ID."
    );
  }


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


  if (
    !valid
  ) {
    throw new Error(
      "Invalid AdMob signature."
    );
  }


  return true;
}


// ============================================================
// ADMOB HASH RATE REWARD
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

    async (
      request,
      response
    ) => {

      try {

        // ====================================================
        // ONLY GET
        // ====================================================

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


        // ====================================================
        // VERIFY ADMOB SIGNATURE
        // ====================================================

        await verifyAdMobSignature(
          request
        );


        // ====================================================
        // PARAMETERS
        // ====================================================

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


        const historyRef =
          getTransactionsCollection(uid)
            .doc(
              `admob_${transactionIdString}`
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
                  success:
                    true,

                  duplicate:
                    true,
                };
              }


              // ==================================================
              // USER
              // ==================================================

              const userSnapshot =
                await transaction.get(
                  userRef
                );


              const userData =
                await ensureMiningUser(
                  transaction,
                  userRef,
                  userSnapshot,
                  now
                );


              // ==================================================
              // UPDATE MINING
              // ==================================================

              const mining =
                await updateMining(
                  transaction,
                  userRef,
                  userData,
                  now
                );


              // ==================================================
              // ADS
              // ==================================================

              let adsToday =
                Number(
                  userData.adsToday || 0
                );


              const adDate =
                String(
                  userData.adDate || ""
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

                return {
                  success:
                    false,

                  limitReached:
                    true,
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
                    success:
                      false,

                    cooldown:
                      true,

                    remainingMs:
                      AD_COOLDOWN_MS -
                      elapsed,
                  };
                }
              }


              // ==================================================
              // HASH RATE BOOST
              // ==================================================

              const oldHashRate =
                Number(
                  userData.hashRate ||
                  DEFAULT_HASH_RATE
                );


              const newHashRate =
                oldHashRate +
                AD_HASHRATE_BOOST;


              const newAdsToday =
                adsToday + 1;


              // ==================================================
              // UPDATE USER
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
                    Timestamp.fromDate(now),

                  updatedAt:
                    FieldValue.serverTimestamp(),
                },
                {
                  merge:
                    true,
                }
              );


              // ==================================================
              // SAVE ADMOB TRANSACTION
              // ==================================================

              transaction.set(
                transactionRef,
                {
                  userId:
                    uid,

                  transactionId:
                    transactionIdString,

                  hashRateBoost:
                    AD_HASHRATE_BOOST,

                  createdAt:
                    FieldValue.serverTimestamp(),
                }
              );


              // ==================================================
              // SAVE HISTORY
              // ==================================================

              transaction.set(
                historyRef,
                {
                  type:
                    "ad_hashrate_boost",

                  title:
                    "🐱 Stella Ad Mining Boost",

                  amount:
                    AD_HASHRATE_BOOST,

                  hashRateAfter:
                    newHashRate,

                  miningBalanceAfter:
                    mining.balance,

                  source:
                    "admob_ssv",

                  date:
                    today,

                  adMobTransactionId:
                    transactionIdString,

                  createdAt:
                    FieldValue.serverTimestamp(),
                }
              );


              return {
                success:
                  true,

                duplicate:
                  false,

                hashRateBoost:
                  AD_HASHRATE_BOOST,

                hashRate:
                  newHashRate,

                miningBalance:
                  mining.balance,

                adsToday:
                  newAdsToday,
              };
            }
          );


        response
          .status(200)
          .json(
            result
          );

      } catch (
        error
      ) {

        console.error(
          "Stella AdMob SSV error:",
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