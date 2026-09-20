"use strict";

// ============================================================
// 🐱 STELLURIINI - MINING SERVICE
// ============================================================
//
// Varsinainen server-authoritative mining-logiikka.
//
// Vastuu:
//
// ⛏️ Mining cyclen hallinta
// 📈 Hash Raten laskeminen
// 🕒 Mining-ajan laskeminen
// 🧮 Mining-tuoton laskeminen
// ⚡ Power Boostin hallinta
// 💾 Mining-tilan tallentaminen Firestoreen
// 📜 Mining-tapahtumien historian luominen
//
// TÄMÄ TIEDOSTO EI:
//
// ❌ varmista AdMob SSV-signaturea
// ❌ käsittele AdMob public keytä
// ❌ vastaanota HTTP callbackia
// ❌ luota clientin lähettämään STL-määrään
// ❌ anna clientin päättää mining-tuottoa
//
// AdMob SSV käsitellään admobService.js / adMobReward
// -kerroksessa.
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

const miningConfig =
  require(
    "../config/miningConfig",
  );


// ============================================================
// 👤 USER UTILITIES
// ============================================================

const {
  getUserRef,
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
// ⚙️ CONFIG HELPERS
// ============================================================
//
// Koska miningConfigia on kehitetty vaiheittain,
// tuetaan tässä myös vanhoja/eri nimisiä config-exportteja.
//
// Varsinaiset nykyiset arvot pidetään Stelluriinin
// tämänhetkisen mining-mallin mukaisina.
//
// ============================================================

function getConfigNumber(
  names,
  fallback,
) {
  for (
    const name of names
  ) {
    const value =
      miningConfig[name];

    const number =
      Number(value);

    if (
      Number.isFinite(number)
    ) {
      return number;
    }
  }

  return fallback;
}


// ============================================================
// ⛏️ MINING CONSTANTS
// ============================================================

const DEFAULT_HASH_RATE =
  getConfigNumber(
    [
      "DEFAULT_HASH_RATE",
      "BASE_HASH_RATE",
      "MINING_BASE_HASH_RATE",
    ],
    0.5,
  );


const DAILY_HASH_RATE_STEP =
  getConfigNumber(
    [
      "DAILY_HASH_RATE_STEP",
      "DAILY_HASH_RATE_BONUS",
      "HASH_RATE_DAILY_BONUS",
    ],
    0.5,
  );


const MAX_HASH_RATE =
  getConfigNumber(
    [
      "MAX_HASH_RATE",
      "MAX_MINING_HASH_RATE",
    ],
    3.5,
  );


const MAX_HASH_RATE_DAY =
  getConfigNumber(
    [
      "MAX_HASH_RATE_DAY",
      "MAX_DAILY_HASH_RATE_DAY",
      "MAX_HASH_RATE_AT_DAY",
    ],
    7,
  );


// ============================================================
// ⚡ POWER BOOST
// ============================================================

const POWER_BOOST_HASH_RATE =
  getConfigNumber(
    [
      "POWER_BOOST_HASH_RATE",
      "POWER_BOOST_BONUS",
      "POWER_BOOST_HASH_RATE_BONUS",
      "POWER_BOOST_HR_BONUS",
    ],
    0.5833,
  );


const POWER_BOOST_DURATION_MS =
  getConfigNumber(
    [
      "POWER_BOOST_DURATION_MS",
    ],
    4 * 60 * 60 * 1000,
  );


// ============================================================
// ⏱️ MINING DURATION
// ============================================================

const MINING_DURATION_MS =
  getConfigNumber(
    [
      "MINING_DURATION_MS",
    ],
    24 * 60 * 60 * 1000,
  );


// ============================================================
// 🧮 MINING YIELD
// ============================================================

const MINING_PER_HASH_PER_HOUR =
  getConfigNumber(
    [
      "MINING_PER_HASH_PER_HOUR",
      "STL_PER_HASH_PER_HOUR",
    ],
    0.10,
  );


// ============================================================
// 🔢 PRECISION
// ============================================================
//
// Firestoreen tallennettava mining-arvo pyöristetään
// turvallisesti kuuteen desimaaliin.
//
// Tämä ei muuta laskennan server-authoritative luonnetta.
//
// ============================================================

const MINING_DECIMAL_PLACES =
  6;


function roundMiningAmount(
  value,
) {
  const number =
    Number(value);

  if (
    !Number.isFinite(number)
  ) {
    return 0;
  }

  const multiplier =
    10 **
    MINING_DECIMAL_PLACES;

  return (
    Math.round(
      number *
        multiplier,
    ) /
    multiplier
  );
}


// ============================================================
// 👤 VALIDATE UID
// ============================================================

function validateUid(
  uid,
) {
  if (
    typeof uid !==
    "string"
  ) {
    return false;
  }

  const value =
    uid.trim();

  if (
    value.length === 0 ||
    value.length > 128
  ) {
    return false;
  }

  return /^[A-Za-z0-9._-]+$/.test(
    value,
  );
}


// ============================================================
// 🕒 DATE CONVERSION
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
    typeof value === "number"
  ) {
    return Number.isFinite(
      value,
    )
      ? value
      : 0;
  }


  if (
    typeof value === "string"
  ) {
    const number =
      Number(value);

    if (
      Number.isFinite(number)
    ) {
      return number;
    }

    const parsed =
      Date.parse(value);

    return Number.isFinite(
      parsed,
    )
      ? parsed
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
    const millis =
      value.toMillis();

    return Number.isFinite(
      millis,
    )
      ? millis
      : 0;
  }


  return 0;
}


// ============================================================
// 📅 DAY NUMBER
// ============================================================
//
// Käytetään käyttäjän mining progression
// laskemiseen.
//
// Päivä 1 = 0.5 HR
// Päivä 2 = 1.0 HR
// ...
// Päivä 7 = 3.5 HR
// Päivä 8+ = 3.5 HR
//
// ============================================================

function getMiningDay(
  userData,
) {
  const candidates = [
    userData.miningDay,
    userData.currentMiningDay,
    userData.day,
    userData.streak,
  ];


  for (
    const candidate of candidates
  ) {
    const value =
      Number(candidate);

    if (
      Number.isSafeInteger(
        value,
      ) &&
      value > 0
    ) {
      return value;
    }
  }


  return 1;
}


// ============================================================
// 📈 CALCULATE BASE HASH RATE
// ============================================================

function calculateBaseHashRate(
  miningDay,
) {
  const day =
    Math.max(
      1,
      Number(
        miningDay,
      ) || 1,
    );


  const progressionDay =
    Math.min(
      day,
      MAX_HASH_RATE_DAY,
    );


  const hashRate =
    DEFAULT_HASH_RATE +
    (
      progressionDay - 1
    ) *
      DAILY_HASH_RATE_STEP;


  return roundMiningAmount(
    Math.min(
      hashRate,
      MAX_HASH_RATE,
    ),
  );
}


// ============================================================
// 📈 GET EFFECTIVE HASH RATE
// ============================================================

function calculateEffectiveHashRate(
  baseHashRate,
  powerBoostActive,
) {
  const base =
    Number(
      baseHashRate,
    );


  if (
    !Number.isFinite(base) ||
    base < 0
  ) {
    return 0;
  }


  const effective =
    powerBoostActive
      ? base +
        POWER_BOOST_HASH_RATE
      : base;


  return roundMiningAmount(
    effective,
  );
}


// ============================================================
// ⚡ POWER BOOST ACTIVE CHECK
// ============================================================

function isPowerBoostActive(
  powerBoostStartedAt,
  nowMs = Date.now(),
) {
  const startedAt =
    toMillis(
      powerBoostStartedAt,
    );


  if (
    startedAt <= 0
  ) {
    return false;
  }


  return (
    nowMs <
    startedAt +
      POWER_BOOST_DURATION_MS
  );
}


// ============================================================
// ⚡ POWER BOOST END
// ============================================================

function calculatePowerBoostEndsAt(
  startedAt,
) {
  const startMs =
    toMillis(
      startedAt,
    );


  if (
    startMs <= 0
  ) {
    return 0;
  }


  return (
    startMs +
    POWER_BOOST_DURATION_MS
  );
}


// ============================================================
// ⏱️ MINING END
// ============================================================

function calculateMiningEndsAt(
  startedAt,
) {
  const startMs =
    toMillis(
      startedAt,
    );


  if (
    startMs <= 0
  ) {
    return 0;
  }


  return (
    startMs +
    MINING_DURATION_MS
  );
}


// ============================================================
// ⏳ MINING ACTIVE
// ============================================================

function isMiningActive(
  miningStartedAt,
  miningEndsAt,
  nowMs = Date.now(),
) {
  const startedAt =
    toMillis(
      miningStartedAt,
    );


  const endsAt =
    toMillis(
      miningEndsAt,
    );


  if (
    startedAt <= 0 ||
    endsAt <= 0
  ) {
    return false;
  }


  return (
    nowMs >= startedAt &&
    nowMs < endsAt
  );
}


// ============================================================
// ⏱️ ELAPSED MINING HOURS
// ============================================================

function calculateElapsedMiningHours(
  miningStartedAt,
  miningEndsAt,
  nowMs = Date.now(),
) {
  const startedAt =
    toMillis(
      miningStartedAt,
    );


  const endsAt =
    toMillis(
      miningEndsAt,
    );


  if (
    startedAt <= 0 ||
    endsAt <= 0 ||
    endsAt <= startedAt
  ) {
    return 0;
  }


  const effectiveNow =
    Math.min(
      Math.max(
        nowMs,
        startedAt,
      ),
      endsAt,
    );


  const elapsedMs =
    effectiveNow -
    startedAt;


  if (
    elapsedMs <= 0
  ) {
    return 0;
  }


  return (
    elapsedMs /
    (
      60 *
      60 *
      1000
    )
  );
}


// ============================================================
// 🧮 CALCULATE MINING REWARD
// ============================================================
//
// Formula:
//
// Hash Rate
// ×
// STL per Hash per Hour
// ×
// elapsed hours
//
// Power Boostin vaikutus otetaan huomioon
// aikajaksoittain.
//
// ============================================================

function calculateMiningReward(
  miningStartedAt,
  miningEndsAt,
  baseHashRate,
  powerBoostStartedAt = null,
  nowMs = Date.now(),
) {
  const startedAt =
    toMillis(
      miningStartedAt,
    );


  const endsAt =
    toMillis(
      miningEndsAt,
    );


  if (
    startedAt <= 0 ||
    endsAt <= startedAt
  ) {
    return {
      amount:
        0,

      elapsedHours:
        0,

      baseHashRate:
        roundMiningAmount(
          Number(
            baseHashRate,
          ) || 0,
        ),

      powerBoostHours:
        0,

      normalHours:
        0,
    };
  }


  const effectiveNow =
    Math.min(
      Math.max(
        nowMs,
        startedAt,
      ),
      endsAt,
    );


  const totalElapsedMs =
    Math.max(
      0,
      effectiveNow -
        startedAt,
    );


  const totalElapsedHours =
    totalElapsedMs /
    (
      60 *
      60 *
      1000
    );


  if (
    totalElapsedHours <= 0
  ) {
    return {
      amount:
        0,

      elapsedHours:
        0,

      baseHashRate:
        roundMiningAmount(
          Number(
            baseHashRate,
          ) || 0,
        ),

      powerBoostHours:
        0,

      normalHours:
        0,
    };
  }


  // ----------------------------------------------------------
  // POWER BOOST WINDOW
  // ----------------------------------------------------------

  const boostStartedAt =
    toMillis(
      powerBoostStartedAt,
    );


  let powerBoostHours =
    0;


  if (
    boostStartedAt > 0 &&
    boostStartedAt <
      effectiveNow
  ) {
    const boostEnd =
      boostStartedAt +
      POWER_BOOST_DURATION_MS;


    const boostEffectiveEnd =
      Math.min(
        boostEnd,
        effectiveNow,
        endsAt,
      );


    const boostStart =
      Math.max(
        boostStartedAt,
        startedAt,
      );


    if (
      boostEffectiveEnd >
      boostStart
    ) {
      powerBoostHours =
        (
          boostEffectiveEnd -
          boostStart
        ) /
        (
          60 *
          60 *
          1000
        );
    }
  }


  powerBoostHours =
    Math.min(
      powerBoostHours,
      totalElapsedHours,
    );


  const normalHours =
    Math.max(
      0,
      totalElapsedHours -
        powerBoostHours,
    );


  const safeBaseHashRate =
    Math.max(
      0,
      Number(
        baseHashRate,
      ) || 0,
    );


  const normalReward =
    safeBaseHashRate *
    MINING_PER_HASH_PER_HOUR *
    normalHours;


  const boostedReward =
    (
      safeBaseHashRate +
      POWER_BOOST_HASH_RATE
    ) *
    MINING_PER_HASH_PER_HOUR *
    powerBoostHours;


  const amount =
    roundMiningAmount(
      normalReward +
        boostedReward,
    );


  return {
    amount,

    elapsedHours:
      totalElapsedHours,

    baseHashRate:
      roundMiningAmount(
        safeBaseHashRate,
      ),

    powerBoostHours,

    normalHours,

    normalReward:
      roundMiningAmount(
        normalReward,
      ),

    boostedReward:
      roundMiningAmount(
        boostedReward,
      ),
  };
}


// ============================================================
// 🧮 GET CURRENT MINING PREVIEW
// ============================================================
//
// Tätä voidaan käyttää esimerkiksi HomePagen
// live mining -näkymässä.
//
// Tämä EI kirjoita Firestoreen.
//
// ============================================================

function calculateCurrentMiningState(
  userData,
  nowMs = Date.now(),
) {
  const data =
    userData || {};


  const miningStartedAt =
    data.miningStartedAt ||
    data.miningStartAt ||
    null;


  const miningEndsAt =
    data.miningEndsAt ||
    data.miningEndAt ||
    (
      toMillis(
        miningStartedAt,
      ) > 0
        ? calculateMiningEndsAt(
            miningStartedAt,
          )
        : null
    );


  const miningDay =
    getMiningDay(
      data,
    );


  const baseHashRate =
    Number.isFinite(
      Number(
        data.miningBaseHashRate,
      ),
    )
      ? Number(
          data.miningBaseHashRate,
        )
      : calculateBaseHashRate(
          miningDay,
        );


  const powerBoostStartedAt =
    data.powerBoostStartedAt ||
    null;


  const powerBoostActive =
    isPowerBoostActive(
      powerBoostStartedAt,
      nowMs,
    );


  const effectiveHashRate =
    calculateEffectiveHashRate(
      baseHashRate,
      powerBoostActive,
    );


  const miningActive =
    isMiningActive(
      miningStartedAt,
      miningEndsAt,
      nowMs,
    );


  const reward =
    calculateMiningReward(
      miningStartedAt,
      miningEndsAt,
      baseHashRate,
      powerBoostStartedAt,
      nowMs,
    );


  const remainingMs =
    miningActive
      ? Math.max(
          0,
          toMillis(
            miningEndsAt,
          ) -
            nowMs,
        )
      : 0;


  return {
    miningActive,

    miningStartedAt,

    miningEndsAt,

    miningDay,

    baseHashRate:
      roundMiningAmount(
        baseHashRate,
      ),

    powerBoostActive,

    powerBoostStartedAt,

    powerBoostEndsAt:
      powerBoostStartedAt
        ? calculatePowerBoostEndsAt(
            powerBoostStartedAt,
          )
        : null,

    effectiveHashRate,

    elapsedHours:
      reward.elapsedHours,

    remainingMs,

    pendingMiningReward:
      reward.amount,

    powerBoostHours:
      reward.powerBoostHours,
  };
}


// ============================================================
// ⛏️ START MINING
// ============================================================
//
// Aloittaa uuden 24 h mining-cyclen.
//
// Tärkeää:
//
// Tämä funktio ei luota clientin lähettämään
// hash rateen tai reward amountiin.
//
// Hash rate lasketaan serverillä.
//
// ============================================================

async function startMining(
  uid,
  options = {},
) {
  if (
    !validateUid(
      uid,
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


  const userRef =
    getUserRef(
      uid,
    );


  if (
    !userRef
  ) {
    const error =
      new Error(
        "Unable to create user reference.",
      );

    error.code =
      "MINING_USER_REFERENCE_ERROR";

    throw error;
  }


  return db.runTransaction(
    async (
      transaction,
    ) => {
      const snapshot =
        await transaction.get(
          userRef,
        );


      const userData =
        snapshot.exists
          ? snapshot.data() || {}
          : {};


      const nowMs =
        Date.now();


      const currentMining =
        calculateCurrentMiningState(
          userData,
          nowMs,
        );


      // ------------------------------------------------------
      // ALREADY ACTIVE
      // ------------------------------------------------------

      if (
        currentMining.miningActive
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
      // MINING DAY
      // ------------------------------------------------------

      const miningDay =
        getMiningDay(
          userData,
        );


      const baseHashRate =
        calculateBaseHashRate(
          miningDay,
        );


      const miningStartedAt =
        FieldValue.serverTimestamp();


      const miningEndsAtMs =
        nowMs +
        MINING_DURATION_MS;


      // ------------------------------------------------------
      // SAVE
      // ------------------------------------------------------

      transaction.set(
        userRef,
        {
          miningActive:
            true,

          miningStartedAt,

          miningEndsAt:
            new Date(
              miningEndsAtMs,
            ),

          miningDay,

          miningBaseHashRate:
            baseHashRate,

          miningEffectiveHashRate:
            baseHashRate,

          miningLastCalculatedAt:
            FieldValue.serverTimestamp(),

          miningPendingReward:
            0,

          miningClaimed:
            false,

          miningCompleted:
            false,

          updatedAt:
            FieldValue.serverTimestamp(),
        },
        {
          merge:
            true,
        },
      );


      // ------------------------------------------------------
      // HISTORY
      // ------------------------------------------------------

      const historyRef =
        createHistoryRef(
          uid,
        );


      transaction.set(
        historyRef,
        {
          type:
            "mining_started",

          title:
            "Stella Mining Started 🐱⛏️",

          amount:
            0,

          hashRate:
            baseHashRate,

          miningDay,

          durationHours:
            MINING_DURATION_MS /
            (
              60 *
              60 *
              1000
            ),

          createdAt:
            FieldValue.serverTimestamp(),
        },
      );


      return {
        success:
          true,

        miningActive:
          true,

        miningDay,

        hashRate:
          baseHashRate,

        miningDurationMs:
          MINING_DURATION_MS,

        miningEndsAt:
          new Date(
            miningEndsAtMs,
          ),
      };
    },
  );
}


// ============================================================
// ⚡ APPLY POWER BOOST
// ============================================================
//
// Aktivoi Power Boostin.
//
// Tämä funktio ei itse varmista AdMob SSV:tä.
// AdMob rewardin transaction_id tulee ylemmältä
// business-kerrokselta.
//
// ============================================================

async function applyPowerBoost(
  uid,
  options = {},
) {
  if (
    !validateUid(
      uid,
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


  const userRef =
    getUserRef(
      uid,
    );


  if (
    !userRef
  ) {
    const error =
      new Error(
        "Unable to create user reference.",
      );

    error.code =
      "MINING_USER_REFERENCE_ERROR";

    throw error;
  }


  const transactionId =
    typeof options.transactionId ===
    "string"
      ? options.transactionId.trim()
      : "";


  return db.runTransaction(
    async (
      transaction,
    ) => {
      const snapshot =
        await transaction.get(
          userRef,
        );


      const userData =
        snapshot.exists
          ? snapshot.data() || {}
          : {};


      const nowMs =
        Date.now();


      const currentMining =
        calculateCurrentMiningState(
          userData,
          nowMs,
        );


      if (
        !currentMining.miningActive
      ) {
        const error =
          new Error(
            "Mining must be active before Power Boost can be applied.",
          );

        error.code =
          "MINING_NOT_ACTIVE";

        throw error;
      }


      // ------------------------------------------------------
      // PREVENT ACTIVE BOOST RESTART
      // ------------------------------------------------------

      if (
        currentMining.powerBoostActive
      ) {
        const error =
          new Error(
            "Power Boost is already active.",
          );

        error.code =
          "POWER_BOOST_ALREADY_ACTIVE";

        throw error;
      }


      // ------------------------------------------------------
      // BOOST
      // ------------------------------------------------------

      const effectiveHashRate =
        calculateEffectiveHashRate(
          currentMining.baseHashRate,
          true,
        );


      transaction.set(
        userRef,
        {
          powerBoostActive:
            true,

          powerBoostStartedAt:
            FieldValue.serverTimestamp(),

          powerBoostEndsAt:
            new Date(
              nowMs +
                POWER_BOOST_DURATION_MS,
            ),

          powerBoostHashRateBonus:
            POWER_BOOST_HASH_RATE,

          miningEffectiveHashRate:
            effectiveHashRate,

          powerBoostTransactionId:
            transactionId || null,

          updatedAt:
            FieldValue.serverTimestamp(),
        },
        {
          merge:
            true,
        },
      );


      // ------------------------------------------------------
      // HISTORY
      // ------------------------------------------------------

      const historyRef =
        createHistoryRef(
          uid,
        );


      transaction.set(
        historyRef,
        {
          type:
            "power_boost_activated",

          title:
            "Stella Power Boost Activated 🐱⚡",

          amount:
            0,

          hashRateBonus:
            POWER_BOOST_HASH_RATE,

          durationHours:
            POWER_BOOST_DURATION_MS /
            (
              60 *
              60 *
              1000
            ),

          transactionId:
            transactionId || null,

          createdAt:
            FieldValue.serverTimestamp(),
        },
      );


      return {
        success:
          true,

        powerBoostActive:
          true,

        hashRateBonus:
          POWER_BOOST_HASH_RATE,

        effectiveHashRate,

        durationMs:
          POWER_BOOST_DURATION_MS,

        transactionId:
          transactionId || null,
      };
    },
  );
}


// ============================================================
// 💰 CLAIM MINING REWARD
// ============================================================
//
// Claim tehdään serverillä.
//
// Reward lasketaan aina Firestoren
// server-authoritative datasta.
//
// Client ei voi lähettää claim-määrää.
//
// ============================================================

async function claimMining(
  uid,
) {
  if (
    !validateUid(
      uid,
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


  const userRef =
    getUserRef(
      uid,
    );


  if (
    !userRef
  ) {
    const error =
      new Error(
        "Unable to create user reference.",
      );

    error.code =
      "MINING_USER_REFERENCE_ERROR";

    throw error;
  }


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


      const userData =
        snapshot.data() || {};


      const nowMs =
        Date.now();


      const miningStartedAt =
        userData.miningStartedAt ||
        userData.miningStartAt ||
        null;


      const miningEndsAt =
        userData.miningEndsAt ||
        userData.miningEndAt ||
        null;


      if (
        !miningStartedAt ||
        !miningEndsAt
      ) {
        const error =
          new Error(
            "No mining cycle is available.",
          );

        error.code =
          "MINING_NOT_FOUND";

        throw error;
      }


      const endsAtMs =
        toMillis(
          miningEndsAt,
        );


      if (
        nowMs <
        endsAtMs
      ) {
        const error =
          new Error(
            "Mining cycle has not completed yet.",
          );

        error.code =
          "MINING_NOT_COMPLETED";

        throw error;
      }


      // ------------------------------------------------------
      // ALREADY CLAIMED
      // ------------------------------------------------------

      if (
        userData.miningClaimed ===
        true
      ) {
        return {
          success:
            true,

          claimed:
            false,

          duplicate:
            true,

          amount:
            0,

          message:
            "🐱 Tämä mining-cycle on jo lunastettu.",
        };
      }


      // ------------------------------------------------------
      // HASH RATE
      // ------------------------------------------------------

      const miningDay =
        getMiningDay(
          userData,
        );


      const baseHashRate =
        Number.isFinite(
          Number(
            userData.miningBaseHashRate,
          ),
        )
          ? Number(
              userData.miningBaseHashRate,
            )
          : calculateBaseHashRate(
              miningDay,
            );


      const powerBoostStartedAt =
        userData.powerBoostStartedAt ||
        null;


      // ------------------------------------------------------
      // FINAL REWARD
      // ------------------------------------------------------

      const reward =
        calculateMiningReward(
          miningStartedAt,
          miningEndsAt,
          baseHashRate,
          powerBoostStartedAt,
          endsAtMs,
        );


      const amount =
        reward.amount;


      // ------------------------------------------------------
      // IMPORTANT
      // ------------------------------------------------------
      //
      // Tämä service ei lisää STL-tokenisaldoa.
      //
      // Se merkitsee mining rewardin lunastetuksi
      // ja tallentaa tapahtuman.
      //
      // Varsinainen STL-balance / token accounting
      // voidaan käsitellä erillisessä reward/accounting
      // -kerroksessa.
      //
      // ------------------------------------------------------

      transaction.set(
        userRef,
        {
          miningActive:
            false,

          miningCompleted:
            true,

          miningClaimed:
            true,

          miningClaimedAt:
            FieldValue.serverTimestamp(),

          miningPendingReward:
            amount,

          miningLastCalculatedAt:
            FieldValue.serverTimestamp(),

          powerBoostActive:
            false,

          updatedAt:
            FieldValue.serverTimestamp(),
        },
        {
          merge:
            true,
        },
      );


      // ------------------------------------------------------
      // HISTORY
      // ------------------------------------------------------

      const historyRef =
        createHistoryRef(
          uid,
        );


      transaction.set(
        historyRef,
        {
          type:
            "mining_completed",

          title:
            "Stella Mining Completed 🐱⛏️",

          // Tämä on mining-laskennan tulos.
          // Ei suora AdMob reward.
          amount,

          rewardType:
            "mining",

          hashRate:
            reward.baseHashRate,

          elapsedHours:
            reward.elapsedHours,

          powerBoostHours:
            reward.powerBoostHours,

          createdAt:
            FieldValue.serverTimestamp(),
        },
      );


      return {
        success:
          true,

        claimed:
          true,

        duplicate:
          false,

        amount,

        hashRate:
          reward.baseHashRate,

        elapsedHours:
          reward.elapsedHours,

        powerBoostHours:
          reward.powerBoostHours,

        message:
          "🐱⛏️ Stella Mining -cycle on valmis.",
      };
    },
  );
}


// ============================================================
// 📊 GET MINING STATE
// ============================================================
//
// Hakee käyttäjän mining-tilan Firestoresta.
//
// Tämä funktio ei muuta mitään.
//
// ============================================================

async function getMiningState(
  uid,
) {
  if (
    !validateUid(
      uid,
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


  const userRef =
    getUserRef(
      uid,
    );


  if (
    !userRef
  ) {
    const error =
      new Error(
        "Unable to create user reference.",
      );

    error.code =
      "MINING_USER_REFERENCE_ERROR";

    throw error;
  }


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


  const userData =
    snapshot.data() || {};


  return calculateCurrentMiningState(
    userData,
    Date.now(),
  );
}


// ============================================================
// 🧮 EXPORT CONFIG
// ============================================================

const MINING_CONSTANTS = {
  DEFAULT_HASH_RATE,

  DAILY_HASH_RATE_STEP,

  MAX_HASH_RATE,

  MAX_HASH_RATE_DAY,

  POWER_BOOST_HASH_RATE,

  POWER_BOOST_DURATION_MS,

  MINING_DURATION_MS,

  MINING_PER_HASH_PER_HOUR,
};


// ============================================================
// 📦 EXPORTS
// ============================================================

module.exports = {
  MINING_CONSTANTS,

  calculateBaseHashRate,

  calculateEffectiveHashRate,

  calculatePowerBoostEndsAt,

  calculateMiningEndsAt,

  calculateElapsedMiningHours,

  calculateMiningReward,

  calculateCurrentMiningState,

  isMiningActive,

  isPowerBoostActive,

  startMining,

  applyPowerBoost,

  claimMining,

  getMiningState,

  roundMiningAmount,

  validateUid,
};