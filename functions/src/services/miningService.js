"use strict";


// ============================================================
// 🐱 STELLURIINI - MINING SERVICE
// ============================================================
//
// Vastaa Stelluriinin varsinaisesta mining-logiikasta.
//
// Vastuu:
//
// ⛏️ Mining Start
// 🕒 24 h mining-jakso
// 💜 Daily Hash Rate
// 💰 Mining Balance
// 📺 Power Boost
// ⚡ Power Boost -cooldown
// 🔢 Daily Ad Limit
// 📜 Mining History
// 🛡️ AdMob Reward -claim
// 🔐 Firestore transaction -turvallisuus
//
// TÄMÄ TIEDOSTO EI:
//
// ❌ tarkista AdMob SSV-signatuuria
// ❌ vastaanota AdMob callbackia
// ❌ hae AdMob public keytä
//
// AdMob SSV varmennetaan:
//
// services/admobService.js
//
// Varmennettu reward tallennetaan:
//
// functions/src/functions/adMobFunctions.js
//
// Varsinainen rewardin käyttö tehdään täällä.
//
// ============================================================


// ============================================================
// 🔥 FIREBASE
// ============================================================

const {
  db,
  FieldValue,
} = require(
  "../firebase/firebase",
);


// ============================================================
// 👤 USER UTILITIES
// ============================================================

const {
  getAdMobRewardRef,
} = require(
  "../utils/userUtils",
);


// ============================================================
// 📜 HISTORY SERVICE
// ============================================================

const {
  createHistoryRef,
} = require(
  "./historyService",
);


// ============================================================
// ⚙️ MINING CONFIG
// ============================================================

const {
  DAILY_HASH_RATE_START,

  DAILY_HASH_RATE_STEP,

  DAILY_HASH_RATE_MAX_DAY,

  MAX_DAILY_HASH_RATE,

  AD_HASH_RATE_BONUS,

  AD_BOOST_DURATION_MS,

  MAX_ADS_PER_DAY,

  AD_COOLDOWN_MS,

  MINING_DURATION_MS,

  MINING_PER_HASH_PER_HOUR,
} = require(
  "../config/miningConfig",
);


// ============================================================
// 🎯 REWARD PURPOSES
// ============================================================

const REWARD_MINING_START =
  "mining_start";

const REWARD_POWER_BOOST =
  "power_boost";


// ============================================================
// 👤 CREATE USER REFERENCE
// ============================================================

function getUserRef(
  uid,
) {
  if (
    typeof uid !==
      "string"
  ) {
    const error =
      new Error(
        "Invalid user UID.",
      );

    error.code =
      "MINING_INVALID_UID";

    throw error;
  }


  const value =
    uid.trim();


  if (
    !/^[A-Za-z0-9._-]{1,128}$/.test(
      value,
    )
  ) {
    const error =
      new Error(
        "Invalid user UID.",
      );

    error.code =
      "MINING_INVALID_UID";

    throw error;
  }


  return db
    .collection(
      "users",
    )
    .doc(
      value,
    );
}


// ============================================================
// ⏱️ FIRESTORE VALUE -> MILLISECONDS
// ============================================================

function toMillis(
  value,
) {
  if (
    value === null ||
    value === undefined
  ) {
    return 0;
  }


  if (
    typeof value ===
      "number"
  ) {
    return Number.isFinite(
      value,
    )
      ? value
      : 0;
  }


  if (
    value instanceof Date
  ) {
    return value.getTime();
  }


  if (
    typeof value.toMillis ===
      "function"
  ) {
    return value.toMillis();
  }


  if (
    typeof value ===
      "string"
  ) {
    const milliseconds =
      Date.parse(
        value,
      );


    return Number.isFinite(
      milliseconds,
    )
      ? milliseconds
      : 0;
  }


  return 0;
}


// ============================================================
// 💰 ROUND STL
// ============================================================

function roundStl(
  value,
) {
  if (
    !Number.isFinite(
      value,
    )
  ) {
    return 0;
  }


  return (
    Math.round(
      value * 1000000,
    ) /
    1000000
  );
}


// ============================================================
// 🗓️ UTC DATE KEY
// ============================================================
//
// Ad limit käyttää UTC-päivää.
//
// Esimerkiksi:
//
// 2026-09-20
//
// ============================================================

function getUtcDateKey(
  milliseconds = Date.now(),
) {
  return new Date(
    milliseconds,
  )
    .toISOString()
    .slice(
      0,
      10,
    );
}


// ============================================================
// 💜 DAILY HASH RATE
// ============================================================
//
// Päivä 1 = 0.5 HR
// Päivä 2 = 1.0 HR
// Päivä 3 = 1.5 HR
// ...
// Päivä 7+ = 3.5 HR
//
// ============================================================

function getDailyHashRate(
  streak,
) {
  const numericStreak =
    Number(
      streak,
    );


  const day =
    Number.isFinite(
      numericStreak,
    )
      ? Math.max(
          1,
          Math.floor(
            numericStreak,
          ),
        )
      : 1;


  const cappedDay =
    Math.min(
      day,
      DAILY_HASH_RATE_MAX_DAY,
    );


  const hashRate =
    DAILY_HASH_RATE_START +
    (
      cappedDay - 1
    ) *
      DAILY_HASH_RATE_STEP;


  return Math.min(
    MAX_DAILY_HASH_RATE,
    hashRate,
  );
}


// ============================================================
// ⚡ BOOST OVERLAP
// ============================================================
//
// Laskee kuinka monta tuntia Power Boost
// oli aktiivinen mining-jakson sisällä.
//
// ============================================================

function getBoostOverlapHours(
  miningStartMs,
  miningEndMs,
  boostStartMs,
  boostEndMs,
) {
  const start =
    Math.max(
      miningStartMs,
      boostStartMs,
    );


  const end =
    Math.min(
      miningEndMs,
      boostEndMs,
    );


  if (
    end <= start
  ) {
    return 0;
  }


  return (
    end - start
  ) /
    (
      60 *
      60 *
      1000
    );
}


// ============================================================
// 💰 CALCULATE MINING REWARD
// ============================================================
//
// Base:
//
// Hash Rate
// × STL / Hash / Hour
// × Mining Hours
//
// Power Boost:
//
// Boost Hash Rate
// × STL / Hash / Hour
// × Boost Hours
//
// ============================================================

function calculateMiningReward({
  miningStartedAt,

  miningEndsAt,

  miningHashRate,

  powerBoostHistory = [],

  adBoostStartedAt = null,

  adBoostEndsAt = null,
}) {
  const miningStartMs =
    toMillis(
      miningStartedAt,
    );


  const miningEndMs =
    toMillis(
      miningEndsAt,
    );


  if (
    !miningStartMs ||
    !miningEndMs ||
    miningEndMs <=
      miningStartMs
  ) {
    return 0;
  }


  const hashRate =
    Number(
      miningHashRate,
    );


  if (
    !Number.isFinite(
      hashRate,
    ) ||
    hashRate <= 0
  ) {
    return 0;
  }


  const miningHours =
    (
      miningEndMs -
      miningStartMs
    ) /
    (
      60 *
      60 *
      1000
    );


  const baseReward =
    hashRate *
    MINING_PER_HASH_PER_HOUR *
    miningHours;


  // ----------------------------------------------------------
  // POWER BOOSTS
  // ----------------------------------------------------------

  let boosts =
    Array.isArray(
      powerBoostHistory,
    )
      ? powerBoostHistory
      : [];


  // ----------------------------------------------------------
  // BACKWARD COMPATIBILITY
  // ----------------------------------------------------------
  //
  // Jos vanhassa käyttäjädokumentissa ei vielä ole
  // powerBoostHistory-kenttää, käytetään nykyisiä
  // adBoostStartedAt / adBoostEndsAt -kenttiä.
  //
  // ----------------------------------------------------------

  if (
    boosts.length === 0 &&
    adBoostStartedAt &&
    adBoostEndsAt
  ) {
    boosts = [
      {
        startedAt:
          adBoostStartedAt,

        endsAt:
          adBoostEndsAt,

        hashRateBonus:
          AD_HASH_RATE_BONUS,
      },
    ];
  }


  let boostReward =
    0;


  for (
    const boost of boosts
  ) {
    const boostStartMs =
      toMillis(
        boost.startedAt,
      );


    const boostEndMs =
      toMillis(
        boost.endsAt,
      );


    const bonus =
      Number(
        boost.hashRateBonus,
      );


    if (
      !boostStartMs ||
      !boostEndMs ||
      boostEndMs <=
        boostStartMs
    ) {
      continue;
    }


    if (
      !Number.isFinite(
        bonus,
      ) ||
      bonus <= 0
    ) {
      continue;
    }


    const boostHours =
      getBoostOverlapHours(
        miningStartMs,
        miningEndMs,
        boostStartMs,
        boostEndMs,
      );


    boostReward +=
      bonus *
      MINING_PER_HASH_PER_HOUR *
      boostHours;
  }


  return roundStl(
    baseReward +
      boostReward,
  );
}


// ============================================================
// 🛡️ VALIDATE ADMOB REWARD DOCUMENT
// ============================================================

function validateRewardDocument(
  data,
  uid,
  transactionId,
  rewardPurpose,
) {
  if (
    !data
  ) {
    const error =
      new Error(
        "AdMob reward document does not exist.",
      );

    error.code =
      "MINING_REWARD_NOT_FOUND";

    throw error;
  }


  if (
    data.uid !== uid
  ) {
    const error =
      new Error(
        "AdMob reward UID does not match user UID.",
      );

    error.code =
      "MINING_REWARD_UID_MISMATCH";

    throw error;
  }


  if (
    data.transactionId !==
      transactionId
  ) {
    const error =
      new Error(
        "AdMob reward transaction ID mismatch.",
      );

    error.code =
      "MINING_REWARD_TRANSACTION_MISMATCH";

    throw error;
  }


  if (
    data.rewardPurpose !==
      rewardPurpose
  ) {
    const error =
      new Error(
        "AdMob reward purpose is invalid.",
      );

    error.code =
      "MINING_REWARD_PURPOSE_MISMATCH";

    throw error;
  }
}


// ============================================================
// ❌ MINING ERROR HELPER
// ============================================================

function throwMiningError(
  code,
  message,
) {
  const error =
    new Error(
      message,
    );

  error.code =
    code;

  throw error;
}


// ============================================================
// 📊 GET MINING STATUS
// ============================================================

async function getMiningStatus(
  uid,
) {
  const userRef =
    getUserRef(
      uid,
    );


  const snapshot =
    await userRef.get();


  if (
    !snapshot.exists
  ) {
    throwMiningError(
      "MINING_USER_NOT_FOUND",
      "User document does not exist.",
    );
  }


  const data =
    snapshot.data() || {};


  const now =
    Date.now();


  const miningStartedMs =
    toMillis(
      data.miningStartedAt,
    );


  const miningEndsMs =
    toMillis(
      data.miningEndsAt,
    );


  const miningActive =
    miningStartedMs > 0 &&
    miningEndsMs > now;


  const miningCompleted =
    miningStartedMs > 0 &&
    miningEndsMs > 0 &&
    miningEndsMs <= now;


  const boostStartedMs =
    toMillis(
      data.adBoostStartedAt,
    );


  const boostEndsMs =
    toMillis(
      data.adBoostEndsAt,
    );


  const boostActive =
    miningActive &&
    boostStartedMs > 0 &&
    boostEndsMs > now;


  const lastAdRewardMs =
    toMillis(
      data.lastAdRewardAt,
    );


  const lastAdDate =
    typeof data.lastAdDate ===
      "string"
      ? data.lastAdDate
      : "";


  const today =
    getUtcDateKey(
      now,
    );


  const adsToday =
    lastAdDate === today
      ? Math.max(
          0,
          Number(
            data.adsToday,
          ) || 0,
        )
      : 0;


  const cooldownRemainingMs =
    lastAdRewardMs > 0
      ? Math.max(
          0,
          AD_COOLDOWN_MS -
            (
              now -
              lastAdRewardMs
            ),
        )
      : 0;


  return {
    success:
      true,

    uid:
      userRef.id,

    miningActive,

    miningCompleted,

    miningStartedAt:
      data.miningStartedAt ||
      null,

    miningEndsAt:
      data.miningEndsAt ||
      null,

    miningHashRate:
      Number(
        data.miningHashRate,
      ) || 0,

    dailyHashRate:
      Number(
        data.dailyHashRate,
      ) || 0,

    miningBalance:
      Number(
        data.miningBalance,
      ) || 0,

    boostActive,

    boostRemainingMs:
      boostActive
        ? Math.max(
            0,
            boostEndsMs -
              now,
          )
        : 0,

    adBoostStartedAt:
      data.adBoostStartedAt ||
      null,

    adBoostEndsAt:
      data.adBoostEndsAt ||
      null,

    powerBoostTransactionId:
      data.powerBoostTransactionId ||
      null,

    adsToday,

    maxAdsPerDay:
      MAX_ADS_PER_DAY,

    adHashRateBonus:
      AD_HASH_RATE_BONUS,

    adCooldownMs:
      AD_COOLDOWN_MS,

    cooldownRemainingMs,
  };
}


// ============================================================
// ⛏️ CLAIM MINING / START NEXT CYCLE
// ============================================================
//
// Käyttää varmennettua:
//
// rewardPurpose = mining_start
//
// AdMob reward kulutetaan vasta tässä vaiheessa.
//
// Jos edellinen mining-jakso on valmis:
//
// 1. lasketaan edellisen jakson tuotto
// 2. lisätään se miningBalanceen
// 3. käynnistetään uusi 24 h mining
// 4. kulutetaan Mining Start -reward
//
// ============================================================

async function claimMining(
  uid,
  transactionId,
) {
  const userRef =
    getUserRef(
      uid,
    );


  if (
    typeof transactionId !==
      "string" ||
    !/^[A-Fa-f0-9]{1,256}$/.test(
      transactionId.trim(),
    )
  ) {
    throwMiningError(
      "MINING_INVALID_TRANSACTION_ID",
      "Invalid mining AdMob transaction ID.",
    );
  }


  transactionId =
    transactionId.trim();


  const rewardRef =
    getAdMobRewardRef(
      transactionId,
    );


  if (
    !rewardRef
  ) {
    throwMiningError(
      "MINING_REWARD_REFERENCE_ERROR",
      "Unable to create AdMob reward reference.",
    );
  }


  return db.runTransaction(
    async (
      transaction,
    ) => {
      // ------------------------------------------------------
      // READS
      // ------------------------------------------------------

      const userSnapshot =
        await transaction.get(
          userRef,
        );


      const rewardSnapshot =
        await transaction.get(
          rewardRef,
        );


      if (
        !userSnapshot.exists
      ) {
        throwMiningError(
          "MINING_USER_NOT_FOUND",
          "User document does not exist.",
        );
      }


      validateRewardDocument(
        rewardSnapshot.exists
          ? rewardSnapshot.data()
          : null,

        uid,

        transactionId,

        REWARD_MINING_START,
      );


      const rewardData =
        rewardSnapshot.data();


      // ------------------------------------------------------
      // DUPLICATE PROTECTION
      // ------------------------------------------------------

      if (
        rewardData.miningStartClaimed ===
          true ||
        rewardData.miningClaimed ===
          true
      ) {
        throwMiningError(
          "MINING_REWARD_ALREADY_CLAIMED",
          "This Mining Start reward has already been claimed.",
        );
      }


      const user =
        userSnapshot.data() || {};


      const now =
        Date.now();


      // ------------------------------------------------------
      // PREVIOUS MINING
      // ------------------------------------------------------

      const previousMiningStart =
        toMillis(
          user.miningStartedAt,
        );


      const previousMiningEnd =
        toMillis(
          user.miningEndsAt,
        );


      const miningActive =
        previousMiningStart > 0 &&
        previousMiningEnd > now;


      if (
        miningActive
      ) {
        throwMiningError(
          "MINING_ALREADY_ACTIVE",
          "Mining is already active.",
        );
      }


      // ------------------------------------------------------
      // COMPLETE PREVIOUS CYCLE
      // ------------------------------------------------------

      let previousMiningReward =
        0;


      if (
        previousMiningStart > 0 &&
        previousMiningEnd > 0 &&
        previousMiningEnd <= now
      ) {
        previousMiningReward =
          calculateMiningReward({
            miningStartedAt:
              user.miningStartedAt,

            miningEndsAt:
              user.miningEndsAt,

            miningHashRate:
              user.miningHashRate,

            powerBoostHistory:
              user.powerBoostHistory,

            adBoostStartedAt:
              user.adBoostStartedAt,

            adBoostEndsAt:
              user.adBoostEndsAt,
          });
      }


      // ------------------------------------------------------
      // BALANCE
      // ------------------------------------------------------

      const currentBalance =
        Number(
          user.miningBalance,
        ) || 0;


      const newBalance =
        roundStl(
          currentBalance +
            previousMiningReward,
        );


      // ------------------------------------------------------
      // NEW DAILY HASH RATE
      // ------------------------------------------------------

      const dailyHashRate =
        getDailyHashRate(
          user.streak,
        );


      // ------------------------------------------------------
      // NEW MINING CYCLE
      // ------------------------------------------------------

      const miningStartedAt =
        new Date(
          now,
        );


      const miningEndsAt =
        new Date(
          now +
            MINING_DURATION_MS,
        );


      // ------------------------------------------------------
      // HISTORY REFERENCE
      // ------------------------------------------------------

      const miningHistoryRef =
        createHistoryRef(
          uid,
        );


      // ------------------------------------------------------
      // USER UPDATE
      // ------------------------------------------------------

      transaction.set(
        userRef,
        {
          miningStartedAt,

          miningEndsAt,

          miningHashRate:
            dailyHashRate,

          dailyHashRate,

          miningBalance:
            newBalance,

          // Power Boost kuuluu aina
          // uuteen mining-jaksoon.
          adBoostStartedAt:
            null,

          adBoostEndsAt:
            null,

          powerBoostTransactionId:
            null,

          powerBoostHistory:
            [],

          updatedAt:
            FieldValue.serverTimestamp(),
        },
        {
          merge:
            true,
        },
      );


      // ------------------------------------------------------
      // CONSUME MINING START REWARD
      // ------------------------------------------------------

      transaction.update(
        rewardRef,
        {
          miningClaimed:
            true,

          miningClaimedAt:
            FieldValue.serverTimestamp(),

          miningClaimedBy:
            "miningService.claimMining",

          miningStartClaimed:
            true,

          miningStartClaimedAt:
            FieldValue.serverTimestamp(),

          miningStartClaimedBy:
            "miningService.claimMining",

          updatedAt:
            FieldValue.serverTimestamp(),
        },
      );


      // ------------------------------------------------------
      // NEW MINING HISTORY
      // ------------------------------------------------------

      transaction.set(
        miningHistoryRef,
        {
          type:
            "mining_started",

          title:
            "Stella Mining Started 🐱⛏️",

          amount:
            0,

          rewardType:
            "mining",

          rewardPurpose:
            REWARD_MINING_START,

          adMobTransactionId:
            transactionId,

          dailyHashRate,

          miningHashRate:
            dailyHashRate,

          miningStartedAt,

          miningEndsAt,

          previousMiningReward,

          createdAt:
            FieldValue.serverTimestamp(),
        },
      );


      // ------------------------------------------------------
      // PREVIOUS MINING HISTORY
      // ------------------------------------------------------

      if (
        previousMiningReward >
        0
      ) {
        const completeHistoryRef =
          createHistoryRef(
            uid,
          );


        transaction.set(
          completeHistoryRef,
          {
            type:
              "mining_complete",

            title:
              "Stella Mining Complete 🐱💜⛏️",

            amount:
              previousMiningReward,

            rewardType:
              "mining",

            miningHashRate:
              user.miningHashRate ||
              0,

            miningStartedAt:
              user.miningStartedAt ||
              null,

            miningEndsAt:
              user.miningEndsAt ||
              null,

            createdAt:
              FieldValue.serverTimestamp(),
          },
        );
      }


      // ------------------------------------------------------
      // RESULT
      // ------------------------------------------------------

      return {
        success:
          true,

        claimed:
          true,

        transactionId,

        previousMiningReward,

        miningBalance:
          newBalance,

        miningStartedAt,

        miningEndsAt,

        miningHashRate:
          dailyHashRate,
      };
    },
  );
}


// ============================================================
// ⚡ POWER BOOST
// ============================================================
//
// Käyttää varmennettua:
//
// rewardPurpose = power_boost
//
// Tarkistaa:
//
// ✅ Mining aktiivinen
// ✅ Reward oikealle käyttäjälle
// ✅ Reward oikeaan tarkoitukseen
// ✅ Rewardia ei ole käytetty
// ✅ Max 6 mainosta / UTC-päivä
// ✅ 4 h cooldown
//
// Power Boost:
//
// +0.5833 HR
// 4 tuntia
//
// Boost ei voi jatkua mining-jakson yli.
//
// ============================================================

async function powerBoost(
  uid,
  transactionId,
) {
  const userRef =
    getUserRef(
      uid,
    );


  if (
    typeof transactionId !==
      "string" ||
    !/^[A-Fa-f0-9]{1,256}$/.test(
      transactionId.trim(),
    )
  ) {
    throwMiningError(
      "MINING_INVALID_TRANSACTION_ID",
      "Invalid Power Boost AdMob transaction ID.",
    );
  }


  transactionId =
    transactionId.trim();


  const rewardRef =
    getAdMobRewardRef(
      transactionId,
    );


  if (
    !rewardRef
  ) {
    throwMiningError(
      "MINING_REWARD_REFERENCE_ERROR",
      "Unable to create AdMob reward reference.",
    );
  }


  return db.runTransaction(
    async (
      transaction,
    ) => {
      // ------------------------------------------------------
      // READS
      // ------------------------------------------------------

      const userSnapshot =
        await transaction.get(
          userRef,
        );


      const rewardSnapshot =
        await transaction.get(
          rewardRef,
        );


      if (
        !userSnapshot.exists
      ) {
        throwMiningError(
          "MINING_USER_NOT_FOUND",
          "User document does not exist.",
        );
      }


      validateRewardDocument(
        rewardSnapshot.exists
          ? rewardSnapshot.data()
          : null,

        uid,

        transactionId,

        REWARD_POWER_BOOST,
      );


      const rewardData =
        rewardSnapshot.data();


      // ------------------------------------------------------
      // DUPLICATE PROTECTION
      // ------------------------------------------------------

      if (
        rewardData.powerBoostClaimed ===
          true
      ) {
        throwMiningError(
          "POWER_BOOST_ALREADY_CLAIMED",
          "This Power Boost reward has already been claimed.",
        );
      }


      const user =
        userSnapshot.data() || {};


      const now =
        Date.now();


      // ------------------------------------------------------
      // MINING WINDOW
      // ------------------------------------------------------

      const miningStartMs =
        toMillis(
          user.miningStartedAt,
        );


      const miningEndMs =
        toMillis(
          user.miningEndsAt,
        );


      if (
        !miningStartMs ||
        !miningEndMs ||
        miningEndMs <= now
      ) {
        throwMiningError(
          "MINING_NOT_ACTIVE",
          "Power Boost requires an active mining cycle.",
        );
      }


      // ------------------------------------------------------
      // DAILY AD COUNT
      // ------------------------------------------------------

      const lastAdDate =
        typeof user.lastAdDate ===
          "string"
          ? user.lastAdDate
          : "";


      const today =
        getUtcDateKey(
          now,
        );


      const adsToday =
        lastAdDate === today
          ? Math.max(
              0,
              Number(
                user.adsToday,
              ) || 0,
            )
          : 0;


      if (
        adsToday >=
        MAX_ADS_PER_DAY
      ) {
        throwMiningError(
          "POWER_BOOST_DAILY_LIMIT",
          "Daily Power Boost ad limit reached.",
        );
      }


      // ------------------------------------------------------
      // COOLDOWN
      // ------------------------------------------------------

      const lastAdRewardMs =
        toMillis(
          user.lastAdRewardAt,
        );


      if (
        lastAdRewardMs > 0 &&
        now -
          lastAdRewardMs <
            AD_COOLDOWN_MS
      ) {
        throwMiningError(
          "POWER_BOOST_COOLDOWN",
          "Power Boost cooldown is still active.",
        );
      }


      // ------------------------------------------------------
      // BOOST WINDOW
      // ------------------------------------------------------

      const boostStartedAt =
        new Date(
          now,
        );


      const boostEndsAt =
        new Date(
          Math.min(
            now +
              AD_BOOST_DURATION_MS,

            miningEndMs,
          ),
        );


      if (
        boostEndsAt.getTime() <=
          now
      ) {
        throwMiningError(
          "POWER_BOOST_WINDOW_INVALID",
          "Power Boost cannot be started in the remaining mining window.",
        );
      }


      // ------------------------------------------------------
      // BOOST HISTORY
      // ------------------------------------------------------
      //
      // Enintään 6 boostia / päivä.
      //
      // Säilytetään boostit nykyisen mining-jakson
      // laskemista varten.
      //
      // ------------------------------------------------------

      const existingBoostHistory =
        Array.isArray(
          user.powerBoostHistory,
        )
          ? user.powerBoostHistory
          : [];


      const nextBoostHistory =
        existingBoostHistory
          .slice(
            -11,
          );


      nextBoostHistory.push(
        {
          transactionId,

          startedAt:
            boostStartedAt,

          endsAt:
            boostEndsAt,

          hashRateBonus:
            AD_HASH_RATE_BONUS,
        },
      );


      // ------------------------------------------------------
      // HISTORY REFERENCE
      // ------------------------------------------------------

      const historyRef =
        createHistoryRef(
          uid,
        );


      // ------------------------------------------------------
      // USER UPDATE
      // ------------------------------------------------------

      transaction.set(
        userRef,
        {
          adBoostStartedAt:
            boostStartedAt,

          adBoostEndsAt:
            boostEndsAt,

          powerBoostTransactionId:
            transactionId,

          powerBoostHistory:
            nextBoostHistory,

          adsToday:
            adsToday + 1,

          lastAdDate:
            today,

          lastAdRewardAt:
            boostStartedAt,

          updatedAt:
            FieldValue.serverTimestamp(),
        },
        {
          merge:
            true,
        },
      );


      // ------------------------------------------------------
      // CONSUME POWER BOOST REWARD
      // ------------------------------------------------------

      transaction.update(
        rewardRef,
        {
          powerBoostClaimed:
            true,

          powerBoostClaimedAt:
            FieldValue.serverTimestamp(),

          powerBoostClaimedBy:
            "miningService.powerBoost",

          powerBoostTransactionId:
            transactionId,

          updatedAt:
            FieldValue.serverTimestamp(),
        },
      );


      // ------------------------------------------------------
      // HISTORY
      // ------------------------------------------------------

      transaction.set(
        historyRef,
        {
          type:
            "ad_reward",

          title:
            "Stella Power Boost 🐱📺⚡",

          amount:
            0,

          rewardType:
            "admob",

          rewardPurpose:
            REWARD_POWER_BOOST,

          adMobTransactionId:
            transactionId,

          hashRateBonus:
            AD_HASH_RATE_BONUS,

          boostStartedAt,

          boostEndsAt,

          createdAt:
            FieldValue.serverTimestamp(),
        },
      );


      // ------------------------------------------------------
      // RESULT
      // ------------------------------------------------------

      return {
        success:
          true,

        claimed:
          true,

        transactionId,

        boostStartedAt,

        boostEndsAt,

        hashRateBonus:
          AD_HASH_RATE_BONUS,

        adsToday:
          adsToday + 1,

        maxAdsPerDay:
          MAX_ADS_PER_DAY,
      };
    },
  );
}


// ============================================================
// 📦 EXPORTS
// ============================================================

module.exports = {

  getMiningStatus,

  claimMining,

  powerBoost,

  calculateMiningReward,

  getDailyHashRate,
};