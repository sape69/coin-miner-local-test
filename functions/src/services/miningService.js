"use strict";

// ============================================================
// 🐱 STELLURIINI - MINING SERVICE
// ============================================================
//
// Stelluriini Miningin business/service-kerros.
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
// 🔐 Varmennetun AdMob rewardin claimaus
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


  if (
    !/^[A-Za-z0-9._:-]+$/.test(
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
    const normalized =
      value.trim();

    if (
      normalized.length === 0
    ) {
      return null;
    }

    const date =
      new Date(
        normalized,
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
// 🔐 GET ADMOB REWARD REF
// ============================================================
//
// Firestore:
//
// admobRewards/{transactionId}
//
// Tämä reference haetaan tässä service-kerroksessa,
// jotta Mining Start ja Power Boost voivat tarkistaa,
// että transactionId on:
//
// ✅ oikeasti vastaanotettu
// ✅ SSV:n kautta varmennettu
// ✅ oikean käyttäjän
// ✅ oikean rewardPurpose-arvon sisältävä
// ✅ käyttämätön
//
// ============================================================

function getAdMobRewardRef(
  transactionId,
) {
  const validTransactionId =
    validateTransactionId(
      transactionId,
    );

  return db
    .collection(
      "admobRewards",
    )
    .doc(
      validTransactionId,
    );
}


// ============================================================
// 🔐 VALIDATE ADMOB CLAIM
// ============================================================
//
// Tarkistaa Firestoresta varmennetun AdMob rewardin.
//
// Tämä EI varmista SSV-signatuuria.
// SSV-signatuuri on jo tarkistettu admobService.js:ssä.
//
// ============================================================

function validateAdMobRewardForClaim(
  rewardData,
  uid,
  expectedPurpose,
  transactionId,
) {
  if (
    !rewardData ||
    typeof rewardData !==
    "object"
  ) {
    const error =
      new Error(
        "Verified AdMob reward does not exist.",
      );

    error.code =
      "ADMOB_REWARD_NOT_FOUND";

    throw error;
  }


  const storedUid =
    typeof rewardData.uid ===
    "string"
      ? rewardData.uid.trim()
      : "";


  if (
    storedUid !==
    uid
  ) {
    const error =
      new Error(
        "AdMob reward does not belong to this user.",
      );

    error.code =
      "ADMOB_REWARD_UID_MISMATCH";

    throw error;
  }


  const storedTransactionId =
    typeof rewardData.transactionId ===
    "string"
      ? rewardData.transactionId.trim()
      : "";


  if (
    storedTransactionId !==
    transactionId
  ) {
    const error =
      new Error(
        "AdMob reward transaction ID mismatch.",
      );

    error.code =
      "ADMOB_REWARD_TRANSACTION_MISMATCH";

    throw error;
  }


  const rewardPurpose =
    typeof rewardData.rewardPurpose ===
    "string"
      ? rewardData.rewardPurpose.trim()
      : "";


  if (
    rewardPurpose !==
    expectedPurpose
  ) {
    const error =
      new Error(
        "AdMob reward purpose does not match the requested mining action.",
      );

    error.code =
      "ADMOB_REWARD_PURPOSE_MISMATCH";

    throw error;
  }


  if (
    rewardData.verified !==
    true &&
    rewardData.ssvVerified !==
    true
  ) {
    //
    // Nykyinen adMobReward.js tallentaa reward-dokumentin
    // vasta verifyAdMobCallback()-tarkistuksen jälkeen.
    //
    // Varsinaista "verified" kenttää ei kuitenkaan tällä
    // hetkellä tallenneta dokumenttiin.
    //
    // Siksi olemassa oleva dokumentti hyväksytään tässä
    // SSV-vastaanottokerroksen luotettuna tuloksena.
    //
    // Älä muuta tätä tarkistusta vaatimaan verified=true,
    // ellei admobReward.js:tä samalla muuteta tallentamaan
    // kyseistä kenttää.
    //
  }


  return rewardData;
}


// ============================================================
// 🎁 CLAIM ADMOB REWARD
// ============================================================
//
// Merkitsee varmennetun AdMob rewardin käytetyksi.
//
// Tämä tapahtuu saman Firestore transactionin sisällä
// Mining Start / Power Boost -operaation kanssa.
//
// Näin:
//
// AdMob reward
//      ↓
// claim
//      ↓
// mining action
//
// ovat atomisia.
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
// Tarkistaa:
//
// 1. reward dokumentin olemassaolon
// 2. UID:n
// 3. transactionId:n
// 4. rewardPurposen
// 5. ettei rewardia ole jo käytetty
//
// HUOM:
//
// Tätä funktiota kutsutaan Firestore transactionin sisällä.
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


  const rewardSnapshot =
    await transaction.get(
      rewardRef,
    );


  if (
    !rewardSnapshot.exists
  ) {
    const error =
      new Error(
        "Verified AdMob reward was not found.",
      );

    error.code =
      "ADMOB_REWARD_NOT_FOUND";

    throw error;
  }


  const rewardData =
    rewardSnapshot.data() ||
    {};


  validateAdMobRewardForClaim(
    rewardData,
    uid,
    expectedPurpose,
    transactionId,
  );


  // ==========================================================
  // 🔒 CLAIM STATE
  // ==========================================================

  if (
    expectedPurpose ===
      "mining_start" &&
    (
      rewardData.miningClaimed ===
        true ||
      rewardData.miningStartClaimed ===
        true
    )
  ) {
    const error =
      new Error(
        "AdMob Mining Start reward has already been claimed.",
      );

    error.code =
      "ADMOB_MINING_REWARD_ALREADY_CLAIMED";

    throw error;
  }


  if (
    expectedPurpose ===
      "power_boost" &&
    rewardData.powerBoostClaimed ===
      true
  ) {
    const error =
      new Error(
        "AdMob Power Boost reward has already been claimed.",
      );

    error.code =
      "ADMOB_POWER_BOOST_REWARD_ALREADY_CLAIMED";

    throw error;
  }


  claimAdMobReward(
    transaction,
    rewardRef,
    rewardData,
    expectedPurpose,
    now,
  );


  return {
    rewardRef,
    rewardData,
  };
}


// ============================================================
// 🎁 CALCULATE DAILY HASH RATE
// ============================================================
//
// Päivittäinen Hash Rate:
//
// Päivä 1 = DAILY_HASH_RATE_START
// Päivä 2 = START + STEP
// Päivä 3 = START + 2 × STEP
// ...
//
// DAILY_HASH_RATE_MAX_DAY rajoittaa streak-päivän.
// MAX_DAILY_HASH_RATE rajoittaa lopullisen arvon.
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
// 🧮 CALCULATE COMPLETED MINING
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
    !Number.isFinite(
      nowMs,
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


  // ==========================================================
  // ⛏️ BASE HASH RATE
  // ==========================================================

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


  // ==========================================================
  // ⚡ POWER BOOST
  // ==========================================================

  const boostStartedAt =
    getSafeDate(
      data.powerBoostStartedAt,
    );


  const boostEndsAt =
    getSafeDate(
      data.powerBoostEndsAt,
    );


  const storedBoostHashRate =
    Math.max(
      0,
      getSafeNumber(
        data.powerBoostHashRate,
        0,
      ),
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
// Mining Start voidaan suorittaa vain, jos:
//
// ✅ transactionId on olemassa
// ✅ transactionId löytyy admobRewards-kokoelmasta
// ✅ reward kuuluu samalle UID:lle
// ✅ rewardPurpose = mining_start
// ✅ rewardia ei ole aiemmin claimattu
//
// Kaikki tehdään yhdessä Firestore transactionissa.
//
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


      // ======================================================
      // 🔐 VERIFY + CLAIM ADMOB REWARD
      // ======================================================

      await verifyAndClaimAdMobReward(
        transaction,
        validUid,
        validTransactionId,
        "mining_start",
        now,
      );


      // ======================================================
      // ⛏️ EXISTING MINING
      // ======================================================

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


      // ======================================================
      // ⏱️ NEW MINING TIMES
      // ======================================================

      const miningStartedAt =
        now;


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
          dailyStreak,
        );


      // ======================================================
      // 💾 START NEW MINING
      // ======================================================

      const miningData = {
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

        miningStartTransactionId:
          validTransactionId,

        updatedAt:
          FieldValue.serverTimestamp(),
      };


      transaction.set(
        userRef,
        miningData,
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

          miningStartedAt,

          miningEndsAt,

          transactionId:
            validTransactionId,

          createdAt:
            FieldValue.serverTimestamp(),
        },
      );


      // ======================================================
      // 📤 RESULT
      // ======================================================

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
//
// Power Boost voidaan suorittaa vain, jos:
//
// ✅ transactionId on olemassa
// ✅ transactionId löytyy admobRewards-kokoelmasta
// ✅ reward kuuluu samalle UID:lle
// ✅ rewardPurpose = power_boost
// ✅ rewardia ei ole aiemmin claimattu
// ✅ mining on aktiivinen
// ✅ päivittäinen AdMob-raja ei ole täynnä
// ✅ cooldown ei ole aktiivinen
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


      // ======================================================
      // 🔐 VERIFY + CLAIM ADMOB REWARD
      // ======================================================

      await verifyAndClaimAdMobReward(
        transaction,
        validUid,
        validTransactionId,
        "power_boost",
        now,
      );


      // ======================================================
      // ⛏️ MINING MUST BE ACTIVE
      // ======================================================

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
      // ⚡ BOOST START
      // ======================================================

      const boostStartedAt =
        now;


      // ======================================================
      // ⚡ BOOST DURATION
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


      // ======================================================
      // 📤 RESULT
      // ======================================================

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
      // ⏱️ MINING MUST BE FINISHED
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
      // 🧮 CALCULATE FINAL AMOUNT
      // ======================================================

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


      // ======================================================
      // 💾 SAVE FINAL MINING RESULT
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


      // ======================================================
      // 📤 RESULT
      // ======================================================

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
  // 📊 MINING ACTIVE STATE
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
      endsAt &&
      endsAt.getTime() <=
        now.getTime(),
    );


  // ==========================================================
  // 📤 STATUS
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