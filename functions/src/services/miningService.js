"use strict";

// ============================================================
// 🐱 STELLURIINI - MINING SERVICE
// ============================================================
//
// Business/service-kerros Stelluriini-miningille.
//
// Vastuu:
//
// ⛏️ Mining Start
// ⚡ Power Boost
// 🧮 Mining-laskenta
// 💰 Mining Balance
// 🔒 Mining/Boost-idempotenssi
// 📜 Mining History
// 🔐 Varmennetun AdMob rewardin claim
//
// AdMob SSV-verifiointi kuuluu admobService.js:lle.
// AdMob reward -dokumentin validointi kuuluu
// admobRewardService.js:lle.
//
// HTTP-callback kuuluu functions/ad.js:lle.
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
// 🔐 ADMOB REWARD SERVICE
// ============================================================
//
// Tämä service on AdMob reward -dokumentin validoinnin
// auktoriteetti.
//
// Se tarkistaa muun muassa:
//
// - verified
// - UID
// - reward purpose
// - transaction ID
// - reward timestamp
// - request timestamp
// - expiration
// - claim/replay protection
//
// MiningService tekee edelleen varsinaisen Firestore-claimin
// omassa transaktiossaan.
//
// ============================================================

const {
  validateVerifiedRewardDocument,
} = require(
  "./admobRewardService",
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

  return Number.isFinite(
    number,
  )
    ? number
    : fallback;
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
    const error =
      new Error(
        "uid must be a string.",
      );

    error.code =
      "MINING_INVALID_UID";

    throw error;
  }

  const value =
    uid.trim();

  if (
    value.length === 0 ||
    value.length > 128
  ) {
    const error =
      new Error(
        "uid is invalid.",
      );

    error.code =
      "MINING_INVALID_UID";

    throw error;
  }

  if (
    !/^[A-Za-z0-9._-]+$/.test(
      value,
    )
  ) {
    const error =
      new Error(
        "uid contains invalid characters.",
      );

    error.code =
      "MINING_INVALID_UID";

    throw error;
  }

  return value;
}


// ============================================================
// 🆔 SAFE TRANSACTION ID
// ============================================================
//
// AdMob transaction_id tulee AdMob SSV:stä.
//
// TÄRKEÄ:
// admobRewardService.js käyttää samaa validointisääntöä.
//
// Transaction ID:n pitää olla:
//
// - merkkijono
// - 1–256 merkkiä
// - heksadesimaalinen
//
// Näin MiningService ja admobRewardService eivät
// hylkää samaa rewardia eri sääntöjen vuoksi.
//
// ============================================================

function validateTransactionId(
  transactionId,
) {
  if (
    typeof transactionId !==
    "string"
  ) {
    const error =
      new Error(
        "transactionId must be a string.",
      );

    error.code =
      "MINING_INVALID_TRANSACTION_ID";

    throw error;
  }

  const value =
    transactionId.trim();

  if (
    value.length === 0 ||
    value.length > 256
  ) {
    const error =
      new Error(
        "transactionId is invalid.",
      );

    error.code =
      "MINING_INVALID_TRANSACTION_ID";

    throw error;
  }

  // ----------------------------------------------------------
  // IMPORTANT:
  // Tämä vastaa admobRewardService.js:n sääntöä.
  // ----------------------------------------------------------

  if (
    !/^[A-Fa-f0-9]+$/.test(
      value,
    )
  ) {
    const error =
      new Error(
        "transactionId contains invalid characters.",
      );

    error.code =
      "MINING_INVALID_TRANSACTION_ID";

    throw error;
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

      return (
        date instanceof Date &&
        !Number.isNaN(
          date.getTime(),
        )
      )
        ? new Date(
            date.getTime(),
          )
        : null;
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
    const normalized =
      value.trim();

    if (
      !normalized
    ) {
      return null;
    }

    const date =
      new Date(
        normalized,
      );

    return Number.isNaN(
      date.getTime(),
    )
      ? null
      : date;
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

    return Number.isNaN(
      date.getTime(),
    )
      ? null
      : date;
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
// 🔐 ADMOB REWARD REF
// ============================================================

function getAdMobRewardRef(
  transactionId,
) {
  return db
    .collection(
      "admobRewards",
    )
    .doc(
      validateTransactionId(
        transactionId,
      ),
    );
}


// ============================================================
// 🎁 CLAIM ADMOB REWARD
// ============================================================
//
// Tämä funktio EI päätä, onko reward turvallinen.
//
// Reward on ensin validoitu
// admobRewardService.js:n avulla.
//
// Tämä funktio ainoastaan kirjoittaa claim-tilan.
//
// ============================================================

function claimAdMobReward(
  transaction,
  rewardRef,
  rewardData,
  claimType,
  now,
) {
  const updateData = {
    claimed:
      true,

    claimedAt:
      now,

    claimedType:
      claimType,

    claimedBy:
      "miningService",

    updatedAt:
      FieldValue.serverTimestamp(),
  };

  if (
    claimType ===
    "mining_start"
  ) {
    updateData.miningClaimed =
      true;

    updateData.miningClaimedAt =
      now;

    updateData.miningClaimedBy =
      "miningService";

    updateData.miningStartClaimed =
      true;

    updateData.miningStartClaimedAt =
      now;

    updateData.miningStartClaimedBy =
      "miningService";
  }

  if (
    claimType ===
    "power_boost"
  ) {
    updateData.powerBoostClaimed =
      true;

    updateData.powerBoostClaimedAt =
      now;

    updateData.powerBoostClaimedBy =
      "miningService";
  }

  transaction.set(
    rewardRef,
    updateData,
    {
      merge:
        true,
    },
  );

  return {
    ...rewardData,
    ...updateData,
  };
}


// ============================================================
// 🎁 VERIFY + CLAIM ADMOB REWARD
// ============================================================
//
// TÄRKEÄ:
//
// 1. Reward luetaan Firestore-transaktion sisällä.
// 2. admobRewardService validoi rewardin.
// 3. Claim kirjoitetaan samaan transaktioon.
//
// Näin rewardin validointi ja claim pysyvät atomisina.
//
// ============================================================

async function verifyAndClaimAdMobReward(
  transaction,
  uid,
  transactionId,
  expectedPurpose,
  now,
) {
  const rewardRef =
    getAdMobRewardRef(
      transactionId,
    );

  // ----------------------------------------------------------
  // 🔐 READ VERIFIED REWARD
  // ----------------------------------------------------------

  const rewardSnapshot =
    await transaction.get(
      rewardRef,
    );

  // ----------------------------------------------------------
  // 🔐 FULL VALIDATION
  // ----------------------------------------------------------

  const validated =
    validateVerifiedRewardDocument(
      rewardSnapshot,
      uid,
      expectedPurpose,
      expectedPurpose ===
        "mining_start"
        ? "miningStartClaimed"
        : "powerBoostClaimed",
      {
        referenceNowMs:
          now.getTime(),

        transactionId,
      },
    );

  // ----------------------------------------------------------
  // 🔒 CLAIM
  // ----------------------------------------------------------

  const claimedData =
    claimAdMobReward(
      transaction,
      rewardRef,
      validated.data,
      expectedPurpose,
      now,
    );

  return {
    rewardRef,

    rewardData:
      claimedData,

    validated,
  };
}


// ============================================================
// 📊 DAILY HASH RATE
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
// ⚡ POWER BOOST MINING
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

  return Math.max(
    0,
    getSafeNumber(
      calculateMining(
        safeHashRate,
        safeElapsed,
      ),
      0,
    ),
  );
}


// ============================================================
// 🪟 MINING WINDOW
// ============================================================

function getMiningWindow(
  data,
  now = new Date(),
) {
  const startedAt =
    getMiningStartTime(
      data,
    );

  const endsAt =
    getMiningEndTime(
      data,
    );

  const nowDate =
    getSafeDate(
      now,
    ) || new Date();

  if (
    !startedAt ||
    !endsAt
  ) {
    return null;
  }

  const startMs =
    startedAt.getTime();

  const endMs =
    endsAt.getTime();

  const nowMs =
    nowDate.getTime();

  if (
    !Number.isFinite(
      startMs,
    ) ||
    !Number.isFinite(
      endMs,
    ) ||
    !Number.isFinite(
      nowMs,
    ) ||
    endMs <= startMs
  ) {
    return null;
  }

  return {
    startedAt,
    endsAt,
    startMs,
    endMs,
    nowMs,

    effectiveNowMs:
      Math.min(
        Math.max(
          nowMs,
          startMs,
        ),
        endMs,
      ),
  };
}


// ============================================================
// ⚡ CALCULATE BOOSTS FROM HISTORY
// ============================================================
//
// Power Boost ei stackaa.
//
// Jos historiallisissa tiedoissa on päällekkäisiä
// intervalleja, sama aika lasketaan vain kerran.
//
// ============================================================

function calculateBoostFromRecords(
  records,
  miningWindow,
) {
  if (
    !Array.isArray(
      records,
    ) ||
    records.length === 0 ||
    !miningWindow
  ) {
    return {
      amount: 0,
      elapsedMs: 0,
    };
  }

  const intervals = [];

  for (
    const record of records
  ) {
    if (
      !record ||
      record.type !==
        "power_boost_started"
    ) {
      continue;
    }

    const recordMiningStart =
      getSafeDate(
        record.miningStartedAt,
      );

    const boostStartedAt =
      getSafeDate(
        record.powerBoostStartedAt,
      );

    const boostEndsAt =
      getSafeDate(
        record.powerBoostEndsAt,
      );

    if (
      !recordMiningStart ||
      !boostStartedAt ||
      !boostEndsAt ||
      recordMiningStart.getTime() !==
        miningWindow.startMs
    ) {
      continue;
    }

    const hashRate =
      Math.max(
        0,
        getSafeNumber(
          record.hashRateBonus,
          0,
        ),
      );

    if (
      hashRate <= 0
    ) {
      continue;
    }

    const startMs =
      Math.max(
        miningWindow.startMs,
        boostStartedAt.getTime(),
      );

    const endMs =
      Math.min(
        miningWindow.endMs,
        boostEndsAt.getTime(),
        miningWindow.effectiveNowMs,
      );

    if (
      endMs > startMs
    ) {
      intervals.push({
        startMs,
        endMs,
        hashRate,
      });
    }
  }

  if (
    intervals.length === 0
  ) {
    return {
      amount: 0,
      elapsedMs: 0,
    };
  }

  const boundaries =
    new Set();

  for (
    const interval of intervals
  ) {
    boundaries.add(
      interval.startMs,
    );

    boundaries.add(
      interval.endMs,
    );
  }

  const sortedBoundaries =
    Array.from(
      boundaries,
    ).sort(
      (
        a,
        b,
      ) =>
        a - b,
    );

  let amount = 0;
  let elapsedMs = 0;

  for (
    let index = 0;
    index <
      sortedBoundaries.length -
        1;
    index += 1
  ) {
    const segmentStart =
      sortedBoundaries[
        index
      ];

    const segmentEnd =
      sortedBoundaries[
        index + 1
      ];

    if (
      segmentEnd <=
      segmentStart
    ) {
      continue;
    }

    let segmentHashRate =
      0;

    for (
      const interval of intervals
    ) {
      if (
        interval.startMs <=
          segmentStart &&
        interval.endMs >=
          segmentEnd
      ) {
        segmentHashRate =
          Math.max(
            segmentHashRate,
            interval.hashRate,
          );
      }
    }

    if (
      segmentHashRate > 0
    ) {
      const duration =
        segmentEnd -
        segmentStart;

      elapsedMs +=
        duration;

      amount +=
        calculatePowerBoostMining(
          segmentHashRate,
          duration,
        );
    }
  }

  return {
    amount:
      Math.max(
        0,
        getSafeNumber(
          amount,
          0,
        ),
      ),

    elapsedMs:
      Math.max(
        0,
        elapsedMs,
      ),
  };
}


// ============================================================
// ⚡ CURRENT STORED BOOST
// ============================================================

function calculateCurrentStoredBoost(
  data,
  miningWindow,
) {
  if (
    !miningWindow
  ) {
    return {
      amount: 0,
      elapsedMs: 0,
    };
  }

  const boostStartedAt =
    getSafeDate(
      data.powerBoostStartedAt,
    );

  const boostEndsAt =
    getSafeDate(
      data.powerBoostEndsAt,
    );

  const boostHashRate =
    Math.max(
      0,
      getSafeNumber(
        data.powerBoostHashRate,
        0,
      ),
    );

  if (
    !boostStartedAt ||
    !boostEndsAt ||
    boostHashRate <= 0
  ) {
    return {
      amount: 0,
      elapsedMs: 0,
    };
  }

  const startMs =
    Math.max(
      miningWindow.startMs,
      boostStartedAt.getTime(),
    );

  const endMs =
    Math.min(
      miningWindow.endMs,
      boostEndsAt.getTime(),
      miningWindow.effectiveNowMs,
    );

  if (
    endMs <= startMs
  ) {
    return {
      amount: 0,
      elapsedMs: 0,
    };
  }

  const elapsedMs =
    endMs -
    startMs;

  return {
    amount:
      calculatePowerBoostMining(
        boostHashRate,
        elapsedMs,
      ),

    elapsedMs,
  };
}


// ============================================================
// 🧮 COMPLETED MINING CALCULATION
// ============================================================

function calculateCompletedMining(
  data,
  now = new Date(),
  boostRecords,
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

  const miningWindow =
    getMiningWindow(
      data,
      now,
    );

  if (
    !miningWindow
  ) {
    return {
      baseAmount: 0,
      boostAmount: 0,
      totalAmount: 0,
      elapsedMs: 0,
      boostElapsedMs: 0,
    };
  }

  const elapsedMs =
    Math.max(
      0,
      miningWindow.effectiveNowMs -
        miningWindow.startMs,
    );

  const baseHashRate =
    Math.max(
      0,
      getSafeNumber(
        data.hashRate,
        0,
      ),
    );

  const baseAmount =
    Math.max(
      0,
      getSafeNumber(
        calculateMining(
          baseHashRate,
          elapsedMs,
        ),
        0,
      ),
    );

  const boostResult =
    Array.isArray(
      boostRecords,
    )
      ? calculateBoostFromRecords(
          boostRecords,
          miningWindow,
        )
      : calculateCurrentStoredBoost(
          data,
          miningWindow,
        );

  const boostAmount =
    Math.max(
      0,
      getSafeNumber(
        boostResult.amount,
        0,
      ),
    );

  return {
    baseAmount,

    boostAmount,

    totalAmount:
      Math.max(
        0,
        baseAmount +
          boostAmount,
      ),

    elapsedMs,

    boostElapsedMs:
      Math.max(
        0,
        boostResult.elapsedMs,
      ),
  };
}


// ============================================================
// 🧮 CURRENT MINING
// ============================================================

function calculateCurrentMining(
  data,
  now = new Date(),
  boostRecords,
) {
  return calculateCompletedMining(
    data,
    now,
    boostRecords,
  );
}


// ============================================================
// 📜 HISTORY COLLECTION
// ============================================================

function getHistoryCollection(
  uid,
) {
  return createHistoryRef(
    uid,
  ).parent;
}


// ============================================================
// 📜 GET POWER BOOST HISTORY
// ============================================================

async function getPowerBoostHistory(
  uid,
  miningStartedAt,
  now,
  transaction,
) {
  const start =
    getSafeDate(
      miningStartedAt,
    );

  const end =
    getSafeDate(
      now,
    ) || new Date();

  if (
    !start
  ) {
    return [];
  }

  const query =
    getHistoryCollection(
      uid,
    )
      .where(
        "miningStartedAt",
        ">=",
        start,
      )
      .where(
        "miningStartedAt",
        "<=",
        end,
      );

  const snapshot =
    transaction
      ? await transaction.get(
          query,
        )
      : await query.get();

  return snapshot.docs.map(
    (
      doc,
    ) =>
      doc.data() || {},
  );
}


// ============================================================
// 👤 USER REF
// ============================================================

function getUserRef(
  uid,
) {
  return db
    .collection(
      "users",
    )
    .doc(
      validateUid(
        uid,
      ),
    );
}


// ============================================================
// ⛏️ START MINING
// ============================================================

async function startMining(
  uid,
  dailyStreak = 1,
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

  return db.runTransaction(
    async (
      transaction,
    ) => {
      const now =
        new Date();

      const snapshot =
        await transaction.get(
          userRef,
        );

      const data =
        snapshot.exists
          ? snapshot.data() || {}
          : {};

      void dailyStreak;

      const authoritativeDailyStreak =
        data.dailyStreak ??
        data.streak ??
        1;

      const existingStart =
        getMiningStartTime(
          data,
        );

      const existingEnd =
        getMiningEndTime(
          data,
        );


      // ======================================================
      // 🔁 IDEMPOTENT MINING START
      // ======================================================

      if (
        data.miningStartTransactionId ===
        validTransactionId
      ) {
        return {
          success:
            true,

          miningActive:
            Boolean(
              existingStart &&
                existingEnd &&
                existingEnd.getTime() >
                  now.getTime(),
            ),

          duplicate:
            true,

          transactionId:
            validTransactionId,

          hashRate:
            Math.max(
              0,
              getSafeNumber(
                data.hashRate,
                0,
              ),
            ),

          miningStartedAt:
            existingStart,

          miningEndsAt:
            existingEnd,

          message:
            "🐱⛏️ Mining Start on jo käsitelty.",
        };
      }


      // ======================================================
      // ⛏️ ACTIVE MINING
      // ======================================================

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


      // ======================================================
      // 🔒 PREVIOUS UNCLAIMED MINING
      // ======================================================

      if (
        existingStart &&
        existingEnd &&
        existingEnd.getTime() <=
          now.getTime() &&
        data.miningClaimed !==
          true
      ) {
        const error =
          new Error(
            "The previous mining session has finished but has not been claimed.",
          );

        error.code =
          "MINING_PREVIOUS_SESSION_UNCLAIMED";

        throw error;
      }


      // ======================================================
      // 🔐 VERIFY + CLAIM ADMOB
      // ======================================================

      await verifyAndClaimAdMobReward(
        transaction,
        validUid,
        validTransactionId,
        "mining_start",
        now,
      );


      // ======================================================
      // ⏱️ DURATION
      // ======================================================

      const durationMs =
        Math.max(
          0,
          getSafeNumber(
            MINING_DURATION_MS,
            0,
          ),
        );

      if (
        durationMs <= 0
      ) {
        const error =
          new Error(
            "Mining duration is invalid.",
          );

        error.code =
          "MINING_INVALID_DURATION";

        throw error;
      }

      const miningStartedAt =
        now;

      const miningEndsAt =
        new Date(
          now.getTime() +
            durationMs,
        );

      if (
        miningEndsAt.getTime() <=
        miningStartedAt.getTime()
      ) {
        const error =
          new Error(
            "Mining end time is invalid.",
          );

        error.code =
          "MINING_INVALID_DURATION";

        throw error;
      }


      // ======================================================
      // 🧮 HASH RATE
      // ======================================================

      const hashRate =
        calculateDailyHashRate(
          authoritativeDailyStreak,
        );


      // ======================================================
      // 💾 START NEW MINING
      // ======================================================

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

          powerBoostLastUsedAt:
            null,

          powerBoostTransactionId:
            null,

          miningStartTransactionId:
            validTransactionId,

          updatedAt:
            FieldValue.serverTimestamp(),
        },
        {
          merge:
            true,
        },
      );


      // ======================================================
      // 📜 HISTORY
      // ======================================================

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

          dailyStreak:
            Math.max(
              1,
              Math.floor(
                getSafeNumber(
                  authoritativeDailyStreak,
                  1,
                ),
              ),
            ),

          miningStartedAt,

          miningEndsAt,

          transactionId:
            validTransactionId,

          createdAt:
            FieldValue.serverTimestamp(),
        },
      );


      return {
        success:
          true,

        miningActive:
          true,

        duplicate:
          false,

        transactionId:
          validTransactionId,

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

  return db.runTransaction(
    async (
      transaction,
    ) => {
      const now =
        new Date();

      const snapshot =
        await transaction.get(
          userRef,
        );

      const data =
        snapshot.exists
          ? snapshot.data() || {}
          : {};

      const miningStartedAt =
        getMiningStartTime(
          data,
        );

      const miningEndsAt =
        getMiningEndTime(
          data,
        );


      // ======================================================
      // 🔁 IDEMPOTENT POWER BOOST
      // ======================================================

      if (
        data.powerBoostTransactionId ===
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

          powerBoostStartedAt:
            getSafeDate(
              data.powerBoostStartedAt,
            ),

          powerBoostEndsAt:
            getSafeDate(
              data.powerBoostEndsAt,
            ),

          message:
            "🐱⚡ Power Boost on jo käsitelty.",
        };
      }


      // ======================================================
      // ⛏️ MINING MUST BE ACTIVE
      // ======================================================

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


      // ======================================================
      // ⚡ NO BOOST STACKING
      // ======================================================

      const currentBoostStartedAt =
        getSafeDate(
          data.powerBoostStartedAt,
        );

      const currentBoostEndsAt =
        getSafeDate(
          data.powerBoostEndsAt,
        );

      const currentBoostActive =
        Boolean(
          currentBoostStartedAt &&
            currentBoostEndsAt &&
            currentBoostEndsAt.getTime() >
              now.getTime() &&
            currentBoostStartedAt.getTime() <
              miningEndsAt.getTime(),
        );

      if (
        currentBoostActive
      ) {
        const error =
          new Error(
            "Power Boost is already active.",
          );

        error.code =
          "POWER_BOOST_ALREADY_ACTIVE";

        throw error;
      }


      // ======================================================
      // 📅 DAILY LIMIT
      // ======================================================

      const today =
        getUtcDateKey(
          now,
        );

      const storedAdDate =
        typeof data.adsTodayDate ===
        "string"
          ? data.adsTodayDate.trim()
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

      adsToday =
        Math.max(
          0,
          Math.floor(
            adsToday,
          ),
        );

      const maxAdsPerDay =
        Math.max(
          0,
          Math.floor(
            getSafeNumber(
              MAX_ADS_PER_DAY,
              0,
            ),
          ),
        );

      if (
        maxAdsPerDay <= 0
      ) {
        const error =
          new Error(
            "Power Boost daily limit is invalid.",
          );

        error.code =
          "POWER_BOOST_INVALID_DAILY_LIMIT";

        throw error;
      }

      if (
        adsToday >=
        maxAdsPerDay
      ) {
        const error =
          new Error(
            "Daily Power Boost ad limit reached.",
          );

        error.code =
          "POWER_BOOST_DAILY_LIMIT_REACHED";

        throw error;
      }


      // ======================================================
      // ⏱️ COOLDOWN
      // ======================================================

      const lastBoostAt =
        getSafeDate(
          data.powerBoostLastUsedAt,
        );

      const cooldownMs =
        Math.max(
          0,
          getSafeNumber(
            AD_COOLDOWN_MS,
            0,
          ),
        );

      if (
        lastBoostAt &&
        cooldownMs > 0
      ) {
        const elapsedSinceLastBoost =
          now.getTime() -
          lastBoostAt.getTime();

        if (
          elapsedSinceLastBoost <
          cooldownMs
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


      // ======================================================
      // ⚡ BOOST HASH RATE
      // ======================================================

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


      // ======================================================
      // ⏱️ BOOST DURATION
      // ======================================================

      const requestedBoostDuration =
        Math.max(
          0,
          getSafeNumber(
            AD_BOOST_DURATION_MS,
            0,
          ),
        );

      if (
        requestedBoostDuration <= 0
      ) {
        const error =
          new Error(
            "Power Boost duration is invalid.",
          );

        error.code =
          "POWER_BOOST_INVALID_DURATION";

        throw error;
      }

      const boostStartedAt =
        now;

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


      // ======================================================
      // 🔐 VERIFY + CLAIM ADMOB
      // ======================================================

      await verifyAndClaimAdMobReward(
        transaction,
        validUid,
        validTransactionId,
        "power_boost",
        now,
      );


      // ======================================================
      // 💾 SAVE BOOST
      // ======================================================

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


      // ======================================================
      // 📜 HISTORY
      // ======================================================

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
            actualBoostEnd.getTime() -
            boostStartedAt.getTime(),

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

  return db.runTransaction(
    async (
      transaction,
    ) => {
      const now =
        new Date();

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
        snapshot.data() ||
        {};

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


      // ======================================================
      // 🔒 ALREADY CLAIMED
      // ======================================================

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
            Math.max(
              0,
              getSafeNumber(
                data.miningClaimedAmount,
                0,
              ),
            ),

          message:
            "🐱⛏️ Tämä mining-jakso on jo käsitelty.",
        };
      }


      // ======================================================
      // ⏱️ MUST BE FINISHED
      // ======================================================

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


      // ======================================================
      // 📜 READ ALL BOOSTS OF THIS MINING SESSION
      // ======================================================

      const boostRecords =
        await getPowerBoostHistory(
          validUid,
          miningStartedAt,
          now,
          transaction,
        );


      // ======================================================
      // 🧮 FINAL CALCULATION
      // ======================================================

      const miningResult =
        calculateCompletedMining(
          data,
          now,
          boostRecords,
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


      // ======================================================
      // 💾 SAVE RESULT
      // ======================================================

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

          updatedAt:
            FieldValue.serverTimestamp(),
        },
        {
          merge:
            true,
        },
      );


      // ======================================================
      // 📜 HISTORY
      // ======================================================

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
    snapshot.data() ||
    {};

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

  let boostRecords =
    [];

  if (
    startedAt &&
    endsAt &&
    endsAt.getTime() >
      startedAt.getTime()
  ) {
    boostRecords =
      await getPowerBoostHistory(
        validUid,
        startedAt,
        now,
      );
  }

  const current =
    calculateCurrentMining(
      data,
      now,
      boostRecords,
    );


  // ==========================================================
  // ⚡ POWER BOOST STATE
  // ==========================================================

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


  // ==========================================================
  // 📅 ADS TODAY
  // ==========================================================

  const adsTodayDate =
    typeof data.adsTodayDate ===
    "string"
      ? data.adsTodayDate.trim()
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
          Math.floor(
            getSafeNumber(
              data.adsToday,
              0,
            ),
          ),
        )
      : 0;


  // ==========================================================
  // ⛏️ MINING STATE
  // ==========================================================

  const miningActive =
    Boolean(
      startedAt &&
        endsAt &&
        endsAt.getTime() >
          now.getTime(),
    );

  const miningFinished =
    Boolean(
      startedAt &&
        endsAt &&
        endsAt.getTime() <=
          now.getTime(),
    );


  // ==========================================================
  // 📤 RESULT
  // ==========================================================

  return {
    success:
      true,

    miningActive,

    miningFinished,

    hashRate:
      Math.max(
        0,
        getSafeNumber(
          data.hashRate,
          0,
        ),
      ),

    dailyStreak:
      Math.max(
        1,
        Math.floor(
          getSafeNumber(
            data.dailyStreak ??
              data.streak,
            1,
          ),
        ),
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
      Math.max(
        0,
        getSafeNumber(
          current.totalAmount,
          0,
        ),
      ),

    baseAmount:
      Math.max(
        0,
        getSafeNumber(
          current.baseAmount,
          0,
        ),
      ),

    boostAmount:
      Math.max(
        0,
        getSafeNumber(
          current.boostAmount,
          0,
        ),
      ),

    elapsedMs:
      Math.max(
        0,
        getSafeNumber(
          current.elapsedMs,
          0,
        ),
      ),

    boostElapsedMs:
      Math.max(
        0,
        getSafeNumber(
          current.boostElapsedMs,
          0,
        ),
      ),

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

    miningStartTransactionId:
      typeof data.miningStartTransactionId ===
      "string"
        ? data.miningStartTransactionId.trim()
        : "",

    powerBoostTransactionId:
      typeof data.powerBoostTransactionId ===
      "string"
        ? data.powerBoostTransactionId.trim()
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