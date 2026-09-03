const {
  onCall,
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
// FIREBASE
// ============================================================

initializeApp();

const db = getFirestore();


// ============================================================
// 🐱 STELLA MINING SETTINGS
// ============================================================

// Aloitus Hash Rate.
const DEFAULT_HASH_RATE = 1;

// Päivittäinen Stella Check-In bonus.
const DAILY_HASH_RATE_BONUS = 1;

// Mainoksen katsomisesta saatava Hash Rate bonus.
const AD_HASH_RATE_BONUS = 5;

// Mainosten maksimimäärä päivässä.
const MAX_ADS_PER_DAY = 5;

// Mainosten välinen odotusaika.
// 60 minuuttia.
const AD_COOLDOWN_MS =
  60 * 60 * 1000;


// ============================================================
// ⛏️ MINING SETTINGS
// ============================================================

// Kuinka paljon Mining Balancea syntyy
// yhdestä Hash Rate -yksiköstä tunnissa.
//
// Esimerkki:
//
// 10 Hash Rate
// = 10 * 0.10
// = 1.0 Mining Balance / tunti
//
const MINING_PER_HASH_PER_HOUR = 0.10;


// ============================================================
// HISTORY
// ============================================================

const MAX_TRANSACTION_HISTORY = 50;


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
// 📜 MINING HISTORY
// ============================================================

function getHistoryCollection(uid) {
  return getUserRef(uid)
    .collection("transactions");
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
    hashRate *
    MINING_PER_HASH_PER_HOUR *
    hours
  );
}


// ============================================================
// ⏱️ GET LAST MINING TIME
// ============================================================

function getLastMiningTime(data) {
  const timestamp =
    data.lastMiningTimestamp;

  if (
    timestamp &&
    typeof timestamp.toDate ===
      "function"
  ) {
    return timestamp.toDate();
  }

  return null;
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
    // HASH RATE
    // ========================================================

    const hashRate =
      Number(
        data.hashRate ||
        DEFAULT_HASH_RATE
      );


    // ========================================================
    // MINING BALANCE
    // ========================================================

    const storedBalance =
      Number(
        data.miningBalance || 0
      );


    // ========================================================
    // CALCULATE UNCLAIMED MINING
    // ========================================================

    const lastMiningTime =
      getLastMiningTime(data);

    let unclaimedMining = 0;

    if (lastMiningTime) {
      const elapsed =
        now.getTime() -
        lastMiningTime.getTime();

      if (elapsed > 0) {
        unclaimedMining =
          calculateMining(
            hashRate,
            elapsed
          );
      }
    }


    // ========================================================
    // AD STATUS
    // ========================================================

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
    // DAILY CHECK-IN
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
      hashRate: hashRate,

      miningBalance:
        storedBalance,

      unclaimedMining:
        unclaimedMining,

      estimatedTotal:
        storedBalance +
        unclaimedMining,

      dailyClaimed:
        lastDaily === today,

      streak:
        streak,

      dailyHashRateBonus:
        DAILY_HASH_RATE_BONUS,

      adsToday:
        adsToday,

      maxAdsPerDay:
        MAX_ADS_PER_DAY,

      adHashRateBonus:
        AD_HASH_RATE_BONUS,

      canWatchAd:
        adsToday <
          MAX_ADS_PER_DAY &&
        cooldownRemainingMs === 0,

      cooldownRemainingMs:
        cooldownRemainingMs,

      miningPerHour:
        hashRate *
        MINING_PER_HASH_PER_HOUR,
    };
  });


// ============================================================
// ⛏️ CLAIM MINING
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
          // HASH RATE
          // ==================================================

          const hashRate =
            Number(
              data.hashRate ||
              DEFAULT_HASH_RATE
            );


          // ==================================================
          // BALANCE
          // ==================================================

          const oldBalance =
            Number(
              data.miningBalance || 0
            );


          // ==================================================
          // LAST MINING TIME
          // ==================================================

          let lastMiningTime =
            getLastMiningTime(data);

          // Uusi käyttäjä aloittaa louhinnan nyt.
          if (!lastMiningTime) {
            transaction.set(
              userRef,
              {
                hashRate:
                  hashRate,

                miningBalance:
                  oldBalance,

                lastMiningTimestamp:
                  FieldValue.serverTimestamp(),

                updatedAt:
                  FieldValue.serverTimestamp(),
              },
              {
                merge: true,
              }
            );

            return {
              success: true,

              claimed: 0,

              balance:
                oldBalance,

              hashRate:
                hashRate,

              message:
                "Stella Mining started! 🐱⛏️",
            };
          }


          // ==================================================
          // CALCULATE MINING
          // ==================================================

          const elapsed =
            Math.max(
              0,
              now.getTime() -
                lastMiningTime.getTime()
            );

          const mined =
            calculateMining(
              hashRate,
              elapsed
            );


          // ==================================================
          // NEW BALANCE
          // ==================================================

          const newBalance =
            oldBalance +
            mined;


          // ==================================================
          // UPDATE USER
          // ==================================================

          transaction.set(
            userRef,
            {
              hashRate:
                hashRate,

              miningBalance:
                newBalance,

              lastMiningTimestamp:
                FieldValue.serverTimestamp(),

              updatedAt:
                FieldValue.serverTimestamp(),
            },
            {
              merge: true,
            }
          );


          // ==================================================
          // HISTORY
          // ==================================================

          if (mined > 0) {
            const historyRef =
              getHistoryCollection(uid)
                .doc();

            transaction.set(
              historyRef,
              {
                type:
                  "mining_claim",

                title:
                  "Stella Mining ⛏️🐱",

                amount:
                  mined,

                balanceAfter:
                  newBalance,

                hashRate:
                  hashRate,

                createdAt:
                  FieldValue.serverTimestamp(),
              }
            );
          }


          return {
            success: true,

            claimed:
              mined,

            balance:
              newBalance,

            hashRate:
              hashRate,
          };
        }
      );


    return result;
  });


// ============================================================
// 🐱 DAILY STELLA CHECK-IN
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


          // ==================================================
          // ALREADY CLAIMED
          // ==================================================

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


          // ==================================================
          // STREAK
          // ==================================================

          let newStreak;

          if (lastDaily === yesterday) {
            newStreak =
              oldStreak + 1;
          } else {
            newStreak = 1;
          }


          // ==================================================
          // HASH RATE BONUS
          // ==================================================

          const bonus =
            DAILY_HASH_RATE_BONUS;

          const newHashRate =
            oldHashRate +
            bonus;


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
          // HISTORY
          // ==================================================

          const historyRef =
            getHistoryCollection(uid)
              .doc(`daily_${today}`);

          transaction.set(
            historyRef,
            {
              type:
                "daily_hashrate",

              title:
                "Stella Daily Bonus 🐱",

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
            alreadyClaimed: false,

            hashRate:
              newHashRate,

            streak:
              newStreak,

            bonus:
              bonus,
          };
        }
      );


    return result;
  });


// ============================================================
// 📺 TEST AD REWARD
//
// Development / Google test ads
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


          // ==================================================
          // DAILY LIMIT
          // ==================================================

          if (adsToday >= MAX_ADS_PER_DAY) {
            throw new HttpsError(
              "resource-exhausted",
              "Päivän Stella-mainosraja on saavutettu."
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
            const elapsed =
              now.getTime() -
              lastAdTimestamp
                .toDate()
                .getTime();

            if (elapsed < AD_COOLDOWN_MS) {
              const remainingMinutes =
                Math.ceil(
                  (
                    AD_COOLDOWN_MS -
                    elapsed
                  ) / 60000
                );

              throw new HttpsError(
                "failed-precondition",
                `Stella lepää vielä ${remainingMinutes} minuuttia 🐱`
              );
            }
          }


          // ==================================================
          // HASH RATE
          // ==================================================

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


          // ==================================================
          // UPDATE
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
                FieldValue.serverTimestamp(),

              updatedAt:
                FieldValue.serverTimestamp(),
            },
            {
              merge: true,
            }
          );


          // ==================================================
          // HISTORY
          // ==================================================

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


    return result;
  });


// ============================================================
// 📜 GET MINING HISTORY
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
      snapshot.docs.map((doc) => {

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
            String(data.type || ""),

          title:
            String(data.title || ""),

          amount:
            Number(data.amount || 0),

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

          createdAt:
            createdAt,
        };
      });


    return {
      transactions:
        transactions,
    };
  });