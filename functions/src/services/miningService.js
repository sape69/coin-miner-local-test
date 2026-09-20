"use strict";

// ============================================================
// 🐱 STELLURIINI - MINING SERVICE
// ============================================================
//
// Stelluriini Miningin varsinainen business/service-kerros.
//
// Vastuu:
//
// ⛏️ Mining Start -jakson hallinta
// ⚡ Power Boost -jakson hallinta
// 🧮 Mining-tuoton laskeminen
// 💰 Mining Balancen päivittäminen
// ⏱️ Mining- ja Boost-aikojen käsittely
// 🔒 Idempotentti Mining/Boost-käsittely
// 📜 Mining History -tapahtumien luominen
//
// TÄMÄ TIEDOSTO EI:
//
// ❌ varmista AdMob SSV-signatuuria
// ❌ vastaanota HTTP-requesteja
// ❌ käsittele AdMob public keytä
// ❌ luo AdMob rewardia
//
// AdMob-verifiointi kuuluu:
//
// services/admobService.js
//
// AdMob callback kuuluu:
//
// functions/ad.js
//
// History-referenceihin liittyvä logiikka kuuluu:
//
// services/historyService.js
//
// Puhtaat mining-laskut kuuluvat:
//
// utils/miningUtils.js
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
// 🧮 MINING UTILITIES
// ============================================================

const {
  calculateMining,
  getMiningStartTime,
  getMiningEndTime,
} = require(
  "../utils/miningUtils",
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
// 🧮 SAFE NUMBER
// ============================================================

function getSafeNumber(
  value,
  fallback = 0,
) {
  const number =
    Number(
      value,
    );

  if (
    Number.isFinite(
      number,
    )
  ) {
    return number;
  }

  return fallback;
}


// ============================================================
// 🛡️ SAFE UID
// ============================================================

function validateUid(
  uid,
) {
  if (
    typeof uid !==
    "string"
  ) {
    throw new Error(
      "uid must be a string.",
    );
  }

  const value =
    uid.trim();

  if (
    value.length === 0 ||
    value.length > 128
  ) {
    throw new Error(
      "uid is invalid.",
    );
  }

  if (
    !/^[A-Za-z0-9._-]+$/.test(
      value,
    )
  ) {
    throw new Error(
      "uid contains invalid characters.",
    );
  }

  return value;
}


// ============================================================
// 🆔 SAFE TRANSACTION ID
// ============================================================

function validateTransactionId(
  transactionId,
) {
  if (
    typeof transactionId !==
    "string"
  ) {
    throw new Error(
      "transactionId must be a string.",
    );
  }

  const value =
    transactionId.trim();

  if (
    value.length === 0 ||
    value.length > 256
  ) {
    throw new Error(
      "transactionId is invalid.",
    );
  }

  if (
    !/^[A-Za-z0-9._:-]+$/.test(
      value,
    )
  ) {
    throw new Error(
      "transactionId contains invalid characters.",
    );
  }

  return value;
}


// ============================================================
// 🕒 SAFE DATE
// ============================================================

function getSafeDate(
  value,
) {
  if (
    value === null ||
    value === undefined
  ) {
    return null;
  }

  if (
    value instanceof Date
  ) {
    return Number.isNaN(
      value.getTime(),
    )
      ? null
      : new Date(
          value.getTime(),
        );
  }

  if (
    typeof value.toDate ===
    "function"
  ) {
    try {
      const date =
        value.toDate();

      if (
        date instanceof Date &&
        !Number.isNaN(
          date.getTime(),
        )
      ) {
        return new Date(
          date.getTime(),
        );
      }
    } catch (
      error
    ) {
      return null;
    }
  }

  if (
    typeof value ===
    "string"
  ) {
    const date =
      new Date(
        value.trim(),
      );

    if (
      !Number.isNaN(
        date.getTime(),
      )
    ) {
      return date;
    }

    return null;
  }

  if (
    typeof value ===
      "number" &&
    Number.isFinite(
      value,
    )
  ) {
    const date =
      new Date(
        value,
      );

    if (
      !Number.isNaN(
        date.getTime(),
      )
    ) {
      return date;
    }
  }

  return null;
}


// ============================================================
// 📅 UTC DATE KEY
// ============================================================

function getUtcDateKey(
  date = new Date(),
) {
  const safeDate =
    getSafeDate(
      date,
    ) || new Date();

  return safeDate
    .toISOString()
    .substring(
      0,
      10,
    );
}


// ============================================================
// 🎁 CALCULATE DAILY HASH RATE
// ============================================================
//
// Daily Hash Rate:
//
// Päivä 1 = 0.5 HR
// Päivä 2 = 1.0 HR
// Päivä 3 = 1.5 HR
// ...
// Päivä 7 = 3.5 HR
// Päivä 8+ = 3.5 HR
//
// Arvo tallennetaan mining-jakson alkaessa.
//
// Näin aktiivisen mining-jakson Hash Rate ei muutu
// kesken jakson.
//
// ============================================================

function calculateDailyHashRate(
  dailyStreak,
) {
  const streak =
    Math.max(
      1,
      Math.floor(
        getSafeNumber(
          dailyStreak,
          1,
        ),
      ),
    );

  const maxDay =
    Math.max(
      1,
      Math.floor(
        getSafeNumber(
          DAILY_HASH_RATE_MAX_DAY,
          7,
        ),
      ),
    );

  const effectiveDay =
    Math.min(
      streak,
      maxDay,
    );

  const startHashRate =
    Math.max(
      0,
      getSafeNumber(
        DAILY_HASH_RATE_START,
        0,
      ),
    );

  const step =
    Math.max(
      0,
      getSafeNumber(
        DAILY_HASH_RATE_STEP,
        0,
      ),
    );

  const hashRate =
    startHashRate +
    (
      effectiveDay - 1
    ) *
    step;

  const maximum =
    Math.max(
      0,
      getSafeNumber(
        MAX_DAILY_HASH_RATE,
        hashRate,
      ),
    );

  return Math.min(
    Math.max(
      0,
      hashRate,
    ),
    maximum,
  );
}


// ============================================================
// 🧮 CALCULATE POWER BOOST MINING
// ============================================================
//
// Laskee Power Boostin tuottaman lisäosuuden.
//
// Boost ei korvaa base Hash Ratea.
// Se lisätään base miningin päälle.
//
// ============================================================

function calculatePowerBoostMining(
  boostHashRate,
  boostElapsedMilliseconds,
) {
  const safeHashRate =
    Math.max(
      0,
      getSafeNumber(
        boostHashRate,
        0,
      ),
    );

  const safeElapsed =
    Math.max(
      0,
      getSafeNumber(
        boostElapsedMilliseconds,
        0,
      ),
    );

  if (
    safeHashRate <= 0 ||
    safeElapsed <= 0
  ) {
    return 0;
  }

  return calculateMining(
    safeHashRate,
    safeElapsed,
  );
}


// ============================================================
// 🧮 CALCULATE COMPLETED MINING
// ============================================================
//
// Laskee mining-jakson tuotannon:
//
// Base Hash Rate
// +
// Power Boostin lisätuotot
//
// Boost rajataan aina mining-jakson sisälle.
//
// ============================================================

function calculateCompletedMining(
  data,
  now = new Date(),
) {
  if (
    !data ||
    typeof data !==
    "object"
  ) {
    return {
      baseAmount: 0,
      boostAmount: 0,
      totalAmount: 0,
      elapsedMs: 0,
      boostElapsedMs: 0,
    };
  }

  const startedAt =
    getMiningStartTime(
      data,
    );

  const endsAt =
    getMiningEndTime(
      data,
    );

  if (
    !startedAt ||
    !endsAt
  ) {
    return {
      baseAmount: 0,
      boostAmount: 0,
      totalAmount: 0,
      elapsedMs: 0,
      boostElapsedMs: 0,
    };
  }

  const startMs =
    startedAt.getTime();

  const endMs =
    endsAt.getTime();

  const nowDate =
    getSafeDate(
      now,
    ) || new Date();

  const nowMs =
    nowDate.getTime();

  if (
    !Number.isFinite(
      startMs,
    ) ||
    !Number.isFinite(
      endMs,
    ) ||
    endMs <= startMs
  ) {
    return {
      baseAmount: 0,
      boostAmount: 0,
      totalAmount: 0,
      elapsedMs: 0,
      boostElapsedMs: 0,
    };
  }

  const effectiveNow =
    Math.min(
      Math.max(
        nowMs,
        startMs,
      ),
      endMs,
    );

  const elapsedMs =
    Math.max(
      0,
      effectiveNow -
        startMs,
    );

  // ----------------------------------------------------------
  // ⛏️ BASE HASH RATE
  // ----------------------------------------------------------

  const baseHashRate =
    Math.max(
      0,
      getSafeNumber(
        data.hashRate,
        0,
      ),
    );

  const baseAmount =
    calculateMining(
      baseHashRate,
      elapsedMs,
    );

  // ----------------------------------------------------------
  // ⚡ POWER BOOST
  // ----------------------------------------------------------

  const boostStartedAt =
    getSafeDate(
      data.powerBoostStartedAt,
    );

  const boostEndsAt =
    getSafeDate(
      data.powerBoostEndsAt,
    );

  const storedBoostHashRate =
    getSafeNumber(
      data.powerBoostHashRate,
      0,
    );

  let boostElapsedMs =
    0;

  if (
    boostStartedAt &&
    boostEndsAt &&
    storedBoostHashRate > 0
  ) {
    const boostStartMs =
      Math.max(
        startMs,
        boostStartedAt.getTime(),
      );

    const boostEndMs =
      Math.min(
        endMs,
        boostEndsAt.getTime(),
        effectiveNow,
      );

    if (
      boostEndMs >
      boostStartMs
    ) {
      boostElapsedMs =
        boostEndMs -
        boostStartMs;
    }
  }

  const boostAmount =
    calculatePowerBoostMining(
      storedBoostHashRate,
      boostElapsedMs,
    );

  const totalAmount =
    Math.max(
      0,
      baseAmount +
      boostAmount,
    );

  return {
    baseAmount,
    boostAmount,
    totalAmount,
    elapsedMs,
    boostElapsedMs,
  };
}


// ============================================================
// 🧮 CALCULATE CURRENT MINING
// ============================================================

function calculateCurrentMining(
  data,
  now = new Date(),
) {
  return calculateCompletedMining(
    data,
    now,
  );
}


// ============================================================
// 👤 GET USER REF
// ============================================================

function getUserRef(
  uid,
) {
  const validUid =
    validateUid(
      uid,
    );

  return db
    .collection(
      "users",
    )
    .doc(
      validUid,
    );
}


// ============================================================
// ⛏️ START MINING
// ============================================================
//
// Käynnistää uuden 24 h mining-jakson.
//
// Hash Rate määräytyy Daily Streakistä.
//
// ============================================================

async function startMining(
  uid,
  dailyStreak = 1,
) {
  const validUid =
    validateUid(
      uid,
    );

  const userRef =
    getUserRef(
      validUid,
    );

  const now =
    new Date();

  const miningStartedAt =
    now;

  const miningEndsAt =
    new Date(
      now.getTime() +
      MINING_DURATION_MS,
    );

  const hashRate =
    calculateDailyHashRate(
      dailyStreak,
    );

  const historyRef =
    createHistoryRef(
      validUid,
    );

  return db.runTransaction(
    async (
      transaction,
    ) => {
      const snapshot =
        await transaction.get(
          userRef,
        );

      const data =
        snapshot.exists
          ? snapshot.data() || {}
          : {};

      // ------------------------------------------------------
      // ⛏️ EXISTING MINING
      // ------------------------------------------------------

      const existingStart =
        getMiningStartTime(
          data,
        );

      const existingEnd =
        getMiningEndTime(
          data,
        );

      if (
        existingStart &&
        existingEnd &&
        existingEnd.getTime() >
          now.getTime()
      ) {
        const error =
          new Error(
            "Mining is already active.",
          );

        error.code =
          "MINING_ALREADY_ACTIVE";

        throw error;
      }

      // ------------------------------------------------------
      // 💾 START NEW MINING
      // ------------------------------------------------------

      transaction.set(
        userRef,
        {
          miningActive:
            true,

          miningFinished:
            false,

          miningStartedAt,

          miningEndsAt,

          hashRate,

          miningClaimed:
            false,

          miningClaimedAmount:
            0,

          powerBoostActive:
            false,

          powerBoostHashRate:
            0,

          powerBoostStartedAt:
            null,

          powerBoostEndsAt:
            null,

          powerBoostTransactionId:
            null,

          updatedAt:
            FieldValue.serverTimestamp(),
        },
        {
          merge:
            true,
        },
      );

      // ------------------------------------------------------
      // 📜 HISTORY
      // ------------------------------------------------------

      transaction.set(
        historyRef,
        {
          type:
            "mining_started",

          title:
            "Stella Mining Started 🐱⛏️",

          amount:
            0,

          hashRate,

          miningStartedAt,

          miningEndsAt,

          createdAt:
            FieldValue.serverTimestamp(),
        },
      );

      return {
        success:
          true,

        miningActive:
          true,

        hashRate,

        miningStartedAt,

        miningEndsAt,
      };
    },
  );
}


// ============================================================
// ⚡ APPLY POWER BOOST
// ============================================================
//
// Aktivoi yhden Power Boostin.
//
// Boost:
//
// + AD_HASH_RATE_BONUS
// AD_BOOST_DURATION_MS ajan.
//
// Boost rajataan mining-jakson loppuun.
//
// AD_COOLDOWN_MS määrittää vain seuraavan mainoksen
// käyttöön liittyvän cooldown-ajan.
//
// ============================================================

async function applyPowerBoost(
  uid,
  transactionId,
) {
  const validUid =
    validateUid(
      uid,
    );

  const validTransactionId =
    validateTransactionId(
      transactionId,
    );

  const userRef =
    getUserRef(
      validUid,
    );

  const historyRef =
    createHistoryRef(
      validUid,
    );

  const now =
    new Date();

  return db.runTransaction(
    async (
      transaction,
    ) => {
      const snapshot =
        await transaction.get(
          userRef,
        );

      const data =
        snapshot.exists
          ? snapshot.data() || {}
          : {};

      // ------------------------------------------------------
      // ⛏️ MINING MUST BE ACTIVE
      // ------------------------------------------------------

      const miningStartedAt =
        getMiningStartTime(
          data,
        );

      const miningEndsAt =
        getMiningEndTime(
          data,
        );

      if (
        !miningStartedAt ||
        !miningEndsAt ||
        miningEndsAt.getTime() <=
          now.getTime()
      ) {
        const error =
          new Error(
            "Power Boost requires an active mining session.",
          );

        error.code =
          "POWER_BOOST_MINING_INACTIVE";

        throw error;
      }

      // ------------------------------------------------------
      // 🛡️ TRANSACTION ID IDEMPOTENCY
      // ------------------------------------------------------

      const lastBoostTransactionId =
        typeof data.powerBoostTransactionId ===
        "string"
          ? data.powerBoostTransactionId.trim()
          : "";

      if (
        lastBoostTransactionId ===
        validTransactionId
      ) {
        return {
          success:
            true,

          boosted:
            false,

          duplicate:
            true,

          transactionId:
            validTransactionId,

          message:
            "🐱⚡ Tämä Power Boost on jo käsitelty.",
        };
      }

      // ------------------------------------------------------
      // 📅 DAILY LIMIT
      // ------------------------------------------------------

      const today =
        getUtcDateKey(
          now,
        );

      const storedAdDate =
        typeof data.adsTodayDate ===
        "string"
          ? data.adsTodayDate
          : "";

      let adsToday =
        getSafeNumber(
          data.adsToday,
          0,
        );

      if (
        storedAdDate !==
        today
      ) {
        adsToday = 0;
      }

      if (
        adsToday >=
        MAX_ADS_PER_DAY
      ) {
        const error =
          new Error(
            "Daily Power Boost ad limit reached.",
          );

        error.code =
          "POWER_BOOST_DAILY_LIMIT_REACHED";

        throw error;
      }

      // ------------------------------------------------------
      // ⏱️ COOLDOWN
      // ------------------------------------------------------

      const lastBoostAt =
        getSafeDate(
          data.powerBoostLastUsedAt,
        );

      if (
        lastBoostAt
      ) {
        const elapsedSinceLastBoost =
          now.getTime() -
          lastBoostAt.getTime();

        if (
          elapsedSinceLastBoost <
          AD_COOLDOWN_MS
        ) {
          const error =
            new Error(
              "Power Boost cooldown is still active.",
            );

          error.code =
            "POWER_BOOST_COOLDOWN_ACTIVE";

          throw error;
        }
      }

      // ------------------------------------------------------
      // ⚡ BOOST START
      // ------------------------------------------------------

      const boostStartedAt =
        now;

      // ------------------------------------------------------
      // ⚡ BOOST DURATION
      // ------------------------------------------------------
      //
      // TÄRKEÄÄ:
      //
      // AD_BOOST_DURATION_MS =
      // Power Boostin varsinainen kesto.
      //
      // AD_COOLDOWN_MS =
      // seuraavan Power Boostin käyttörajoitus.
      //
      // Näitä ei sekoiteta keskenään.
      //
      // ------------------------------------------------------

      const requestedBoostDuration =
        Math.max(
          0,
          getSafeNumber(
            AD_BOOST_DURATION_MS,
            0,
          ),
        );

      const requestedBoostEnd =
        new Date(
          now.getTime() +
          requestedBoostDuration,
        );

      const actualBoostEnd =
        requestedBoostEnd.getTime() >
        miningEndsAt.getTime()
          ? miningEndsAt
          : requestedBoostEnd;

      if (
        actualBoostEnd.getTime() <=
        boostStartedAt.getTime()
      ) {
        const error =
          new Error(
            "Power Boost duration is invalid.",
          );

        error.code =
          "POWER_BOOST_INVALID_DURATION";

        throw error;
      }

      // ------------------------------------------------------
      // ⚡ BOOST HASH RATE
      // ------------------------------------------------------

      const boostHashRate =
        Math.max(
          0,
          getSafeNumber(
            AD_HASH_RATE_BONUS,
            0,
          ),
        );

      if (
        boostHashRate <= 0
      ) {
        const error =
          new Error(
            "Power Boost Hash Rate bonus is invalid.",
          );

        error.code =
          "POWER_BOOST_INVALID_HASH_RATE";

        throw error;
      }

      // ------------------------------------------------------
      // 💾 SAVE BOOST
      // ------------------------------------------------------

      transaction.set(
        userRef,
        {
          powerBoostActive:
            true,

          powerBoostHashRate:
            boostHashRate,

          powerBoostStartedAt:
            boostStartedAt,

          powerBoostEndsAt:
            actualBoostEnd,

          powerBoostLastUsedAt:
            boostStartedAt,

          powerBoostTransactionId:
            validTransactionId,

          adsToday:
            adsToday + 1,

          adsTodayDate:
            today,

          updatedAt:
            FieldValue.serverTimestamp(),
        },
        {
          merge:
            true,
        },
      );

      // ------------------------------------------------------
      // 📜 HISTORY
      // ------------------------------------------------------

      transaction.set(
        historyRef,
        {
          type:
            "power_boost_started",

          title:
            "Stella Power Boost Activated 🐱⚡",

          amount:
            0,

          hashRateBonus:
            boostHashRate,

          durationMs:
            Math.max(
              0,
              actualBoostEnd.getTime() -
              boostStartedAt.getTime(),
            ),

          transactionId:
            validTransactionId,

          miningStartedAt,

          miningEndsAt,

          powerBoostStartedAt:
            boostStartedAt,

          powerBoostEndsAt:
            actualBoostEnd,

          createdAt:
            FieldValue.serverTimestamp(),
        },
      );

      return {
        success:
          true,

        boosted:
          true,

        duplicate:
          false,

        transactionId:
          validTransactionId,

        hashRateBonus:
          boostHashRate,

        powerBoostStartedAt:
          boostStartedAt,

        powerBoostEndsAt:
          actualBoostEnd,

        adsToday:
          adsToday + 1,
      };
    },
  );
}


// ============================================================
// 💰 COMPLETE MINING
// ============================================================
//
// Päättää yhden valmistuneen mining-jakson.
//
// Laskee:
//
// Base mining
// +
// Power Boost mining
//
// ja lisää tuloksen miningBalanceen.
//
// ============================================================

async function completeMining(
  uid,
) {
  const validUid =
    validateUid(
      uid,
    );

  const userRef =
    getUserRef(
      validUid,
    );

  const historyRef =
    createHistoryRef(
      validUid,
    );

  const now =
    new Date();

  return db.runTransaction(
    async (
      transaction,
    ) => {
      const snapshot =
        await transaction.get(
          userRef,
        );

      if (
        !snapshot.exists
      ) {
        const error =
          new Error(
            "User document does not exist.",
          );

        error.code =
          "MINING_USER_NOT_FOUND";

        throw error;
      }

      const data =
        snapshot.data() || {};

      const miningStartedAt =
        getMiningStartTime(
          data,
        );

      const miningEndsAt =
        getMiningEndTime(
          data,
        );

      if (
        !miningStartedAt ||
        !miningEndsAt
      ) {
        const error =
          new Error(
            "Mining session does not exist.",
          );

        error.code =
          "MINING_SESSION_MISSING";

        throw error;
      }

      // ------------------------------------------------------
      // 🔒 ALREADY CLAIMED
      // ------------------------------------------------------

      if (
        data.miningClaimed ===
        true
      ) {
        return {
          success:
            true,

          completed:
            false,

          duplicate:
            true,

          amount:
            0,

          message:
            "🐱⛏️ Tämä mining-jakso on jo käsitelty.",
        };
      }

      // ------------------------------------------------------
      // ⏱️ MINING MUST BE FINISHED
      // ------------------------------------------------------

      if (
        miningEndsAt.getTime() >
        now.getTime()
      ) {
        const error =
          new Error(
            "Mining session has not finished yet.",
          );

        error.code =
          "MINING_NOT_FINISHED";

        throw error;
      }

      // ------------------------------------------------------
      // 🧮 CALCULATE FINAL AMOUNT
      // ------------------------------------------------------

      const miningResult =
        calculateCompletedMining(
          data,
          now,
        );

      const amount =
        Math.max(
          0,
          getSafeNumber(
            miningResult.totalAmount,
            0,
          ),
        );

      const previousBalance =
        Math.max(
          0,
          getSafeNumber(
            data.miningBalance,
            0,
          ),
        );

      const newBalance =
        previousBalance +
        amount;

      // ------------------------------------------------------
      // 💾 SAVE FINAL MINING RESULT
      // ------------------------------------------------------

      transaction.set(
        userRef,
        {
          miningActive:
            false,

          miningFinished:
            true,

          miningClaimed:
            true,

          miningClaimedAt:
            FieldValue.serverTimestamp(),

          miningClaimedAmount:
            amount,

          miningBalance:
            newBalance,

          powerBoostActive:
            false,

          powerBoostHashRate:
            0,

          powerBoostStartedAt:
            null,

          powerBoostEndsAt:
            null,

          powerBoostTransactionId:
            null,

          updatedAt:
            FieldValue.serverTimestamp(),
        },
        {
          merge:
            true,
        },
      );

      // ------------------------------------------------------
      // 📜 HISTORY
      // ------------------------------------------------------

      transaction.set(
        historyRef,
        {
          type:
            "mining_completed",

          title:
            "Stella Mining Completed 🐱⛏️",

          amount,

          baseAmount:
            miningResult.baseAmount,

          boostAmount:
            miningResult.boostAmount,

          hashRate:
            getSafeNumber(
              data.hashRate,
              0,
            ),

          elapsedMs:
            miningResult.elapsedMs,

          boostElapsedMs:
            miningResult.boostElapsedMs,

          miningStartedAt,

          miningEndsAt,

          createdAt:
            FieldValue.serverTimestamp(),
        },
      );

      return {
        success:
          true,

        completed:
          true,

        duplicate:
          false,

        amount,

        baseAmount:
          miningResult.baseAmount,

        boostAmount:
          miningResult.boostAmount,

        miningBalance:
          newBalance,

        miningStartedAt,

        miningEndsAt,
      };
    },
  );
}


// ============================================================
// 📊 GET MINING STATUS
// ============================================================
//
// Ei kirjoita Firestoreen.
//
// Palauttaa käyttäjän nykyisen mining-tilan.
//
// ============================================================

async function getMiningStatus(
  uid,
) {
  const validUid =
    validateUid(
      uid,
    );

  const userRef =
    getUserRef(
      validUid,
    );

  const snapshot =
    await userRef.get();

  if (
    !snapshot.exists
  ) {
    const error =
      new Error(
        "User document does not exist.",
      );

    error.code =
      "MINING_USER_NOT_FOUND";

    throw error;
  }

  const data =
    snapshot.data() || {};

  const now =
    new Date();

  const startedAt =
    getMiningStartTime(
      data,
    );

  const endsAt =
    getMiningEndTime(
      data,
    );

  const current =
    calculateCurrentMining(
      data,
      now,
    );

  const powerBoostStartedAt =
    getSafeDate(
      data.powerBoostStartedAt,
    );

  const powerBoostEndsAt =
    getSafeDate(
      data.powerBoostEndsAt,
    );

  const powerBoostHashRate =
    Math.max(
      0,
      getSafeNumber(
        data.powerBoostHashRate,
        0,
      ),
    );

  const powerBoostActive =
    Boolean(
      startedAt &&
      endsAt &&
      powerBoostStartedAt &&
      powerBoostEndsAt &&
      powerBoostHashRate > 0 &&
      powerBoostStartedAt.getTime() <=
        now.getTime() &&
      powerBoostEndsAt.getTime() >
        now.getTime() &&
      powerBoostStartedAt.getTime() <
        endsAt.getTime(),
    );

  const adsTodayDate =
    typeof data.adsTodayDate ===
    "string"
      ? data.adsTodayDate
      : "";

  const today =
    getUtcDateKey(
      now,
    );

  const adsToday =
    adsTodayDate ===
    today
      ? Math.max(
          0,
          getSafeNumber(
            data.adsToday,
            0,
          ),
        )
      : 0;

  return {
    success:
      true,

    miningActive:
      Boolean(
        startedAt &&
        endsAt &&
        endsAt.getTime() >
          now.getTime(),
      ),

    miningFinished:
      Boolean(
        endsAt &&
        endsAt.getTime() <=
          now.getTime(),
      ),

    hashRate:
      getSafeNumber(
        data.hashRate,
        0,
      ),

    miningBalance:
      Math.max(
        0,
        getSafeNumber(
          data.miningBalance,
          0,
        ),
      ),

    miningStartedAt:
      startedAt,

    miningEndsAt:
      endsAt,

    minedAmount:
      current.totalAmount,

    baseAmount:
      current.baseAmount,

    boostAmount:
      current.boostAmount,

    elapsedMs:
      current.elapsedMs,

    boostElapsedMs:
      current.boostElapsedMs,

    powerBoostActive,

    powerBoostHashRate,

    powerBoostStartedAt,

    powerBoostEndsAt,

    adsToday,

    adsTodayDate:
      adsTodayDate ===
      today
        ? adsTodayDate
        : "",
  };
}


// ============================================================
// 📦 EXPORTS
// ============================================================

module.exports = {
  calculateDailyHashRate,

  calculatePowerBoostMining,

  calculateCompletedMining,

  calculateCurrentMining,

  startMining,

  applyPowerBoost,

  completeMining,

  getMiningStatus,
};