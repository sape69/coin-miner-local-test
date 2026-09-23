"use strict";

// ============================================================
// 🐱 STELLURIINI - ADMOB REWARD SERVICE
// ============================================================
//
// AdMob SSV reward -validointi.
//
// AdMob reward ei ole STL-token reward.
// Se ainoastaan valtuuttaa:
//
// - Mining Start
// - Power Boost
//
// Tämä tiedosto:
//
// - validoi AdMob rewardin
// - validoi transaction ID:n
// - validoi timestampin
// - odottaa verifioitua SSV rewardia
// - estää jo kulutetun rewardin käytön
// - varmistaa UID:n
// - varmistaa reward purposen
//
// Tämä tiedosto EI:
//
// - muuta mining-balancea
// - muuta mining-tilaa
// - aktivoi Power Boostia
// - lisää STL-saldoa
//
// Varsinainen mining-logiikka tapahtuu
// miningFunctions.js-tiedostossa.
//
// ============================================================

const {
  db,
} = require("../firebase/firebase");

const {
  ADMOB_MINING_AD_UNIT_ID,
  ADMOB_POWER_BOOST_AD_UNIT_ID,
  ADMOB_MINING_SSV_AD_UNIT_ID,
  ADMOB_POWER_BOOST_SSV_AD_UNIT_ID,
  ADMOB_MINING_SSV_REWARD_AMOUNT,
  ADMOB_MINING_SSV_REWARD_ITEM,
  ADMOB_POWER_BOOST_SSV_REWARD_AMOUNT,
  ADMOB_POWER_BOOST_SSV_REWARD_ITEM,
} = require("../config/miningConfig");

// ============================================================
// 🔐 TIMING
// ============================================================

// Client-pyynnön ja SSV:n välille sallitaan pieni
// aikapoikkeama. SSV:n todellinen timestamp on
// kuitenkin lopullinen auktoriteetti.
const REQUEST_GRACE_MS =
  5 * 60 * 1000;

// Rewardin täytyy olla riittävän tuore.
const MAX_REWARD_AGE_MS =
  15 * 60 * 1000;

// Pieni tulevaisuuden toleranssi palvelinten
// kellopoikkeamia varten.
const FUTURE_TOLERANCE_MS =
  2 * 60 * 1000;

// Discovery-haun enimmäismäärä.
const REWARD_QUERY_LIMIT = 100;

// Kuinka kauan odotetaan, että AdMob SSV
// ehtii kirjoittaa reward-dokumentin Firestoreen.
const SSV_WAIT_TIMEOUT_MS =
  90 * 1000;

// Kuinka usein Firestore tarkistetaan.
const SSV_POLL_INTERVAL_MS =
  2 * 1000;

// ============================================================
// 🔢 SAFE NUMBERS
// ============================================================

function safeNumber(
  value,
  fallback = 0
) {
  const result =
    Number(value);

  return Number.isFinite(result)
    ? result
    : fallback;
}

function safeNonNegative(
  value,
  fallback = 0
) {
  const result =
    Number(value);

  return Number.isFinite(result) &&
    result >= 0
    ? result
    : fallback;
}

function safePositive(
  value,
  fallback = 0
) {
  const result =
    Number(value);

  return Number.isFinite(result) &&
    result > 0
    ? result
    : fallback;
}

// ============================================================
// 🕒 TIMESTAMP
// ============================================================

function timestampMs(value) {
  if (!value) {
    return 0;
  }

  // Firestore Timestamp
  if (
    typeof value.toDate ===
      "function"
  ) {
    try {
      const date =
        value.toDate();

      return date instanceof Date &&
        Number.isFinite(
          date.getTime()
        )
        ? date.getTime()
        : 0;
    } catch (_) {
      return 0;
    }
  }

  // Joissakin Timestamp-implementaatioissa
  // on käytettävissä suoraan toMillis().
  if (
    typeof value.toMillis ===
      "function"
  ) {
    try {
      const milliseconds =
        value.toMillis();

      return Number.isFinite(
        milliseconds
      )
        ? milliseconds
        : 0;
    } catch (_) {
      return 0;
    }
  }

  if (
    value instanceof Date
  ) {
    return Number.isFinite(
      value.getTime()
    )
      ? value.getTime()
      : 0;
  }

  if (
    typeof value ===
      "string"
  ) {
    const date =
      new Date(value);

    return Number.isFinite(
      date.getTime()
    )
      ? date.getTime()
      : 0;
  }

  if (
    typeof value ===
      "number" &&
    Number.isFinite(value)
  ) {
    return value;
  }

  return 0;
}

// ============================================================
// 🔑 TRANSACTION ID
// ============================================================
//
// AdMob transaction_id:tä ei pidä rajoittaa
// pelkästään hexadecimal-muotoon.
//
// Transaction ID on ulkoinen AdMob-tunniste,
// joten palvelin hyväksyy turvallisen merkkijonon,
// mutta rajoittaa pituuden ja kontrollimerkit.
//
// ============================================================

function validateAdMobTransactionId(
  value
) {
  if (
    typeof value !==
    "string"
  ) {
    return "";
  }

  const transactionId =
    value.trim();

  if (
    !transactionId ||
    transactionId.length >
      256
  ) {
    return "";
  }

  // Estetään whitespace- ja kontrollimerkit.
  if (
    /[\u0000-\u0020\u007F]/.test(
      transactionId
    )
  ) {
    return "";
  }

  return transactionId;
}

// ============================================================
// 🕒 REWARD TIMESTAMPS
// ============================================================

function getRewardTimestampMs(
  data
) {
  if (!data) {
    return 0;
  }

  const values = [
    data.timestamp,
    data.rewardedAt,
    data.receivedAt,
    data.createdAt,
  ];

  for (
    const value of values
  ) {
    const result =
      timestampMs(value);

    if (result > 0) {
      return result;
    }
  }

  return 0;
}

function getRewardCreatedAtMs(
  data
) {
  if (!data) {
    return 0;
  }

  const values = [
    data.createdAt,
    data.receivedAt,
    data.timestamp,
    data.rewardedAt,
  ];

  for (
    const value of values
  ) {
    const result =
      timestampMs(value);

    if (result > 0) {
      return result;
    }
  }

  return 0;
}

// ============================================================
// 🎁 REWARD CONFIGURATION
// ============================================================

function getRewardConfiguration(
  rewardPurpose
) {
  if (
    rewardPurpose ===
    "mining_start"
  ) {
    return {
      rewardedAdUnitId:
        ADMOB_MINING_AD_UNIT_ID,

      ssvAdUnitId:
        ADMOB_MINING_SSV_AD_UNIT_ID,

      rewardAmount:
        ADMOB_MINING_SSV_REWARD_AMOUNT,

      rewardItem:
        ADMOB_MINING_SSV_REWARD_ITEM,
    };
  }

  if (
    rewardPurpose ===
    "power_boost"
  ) {
    return {
      rewardedAdUnitId:
        ADMOB_POWER_BOOST_AD_UNIT_ID,

      ssvAdUnitId:
        ADMOB_POWER_BOOST_SSV_AD_UNIT_ID,

      rewardAmount:
        ADMOB_POWER_BOOST_SSV_REWARD_AMOUNT,

      rewardItem:
        ADMOB_POWER_BOOST_SSV_REWARD_ITEM,
    };
  }

  return null;
}

// ============================================================
// 🔐 CONFIGURATION VALIDATION
// ============================================================

function isValidRewardConfiguration(
  config
) {
  if (
    !config ||
    typeof config !==
      "object"
  ) {
    return false;
  }

  const rewardedAdUnitId =
    typeof config.rewardedAdUnitId ===
    "string"
      ? config.rewardedAdUnitId.trim()
      : "";

  const ssvAdUnitId =
    typeof config.ssvAdUnitId ===
    "string"
      ? config.ssvAdUnitId.trim()
      : "";

  const rewardItem =
    typeof config.rewardItem ===
    "string"
      ? config.rewardItem.trim()
      : "";

  const rewardAmount =
    Number(
      config.rewardAmount
    );

  return (
    rewardedAdUnitId.length > 0 &&
    ssvAdUnitId.length > 0 &&
    rewardItem.length > 0 &&
    Number.isFinite(
      rewardAmount
    ) &&
    rewardAmount >= 0
  );
}

// ============================================================
// 🔑 TRANSACTION VALIDATION
// ============================================================

function validateRewardTransactionId(
  snapshot
) {
  if (
    !snapshot ||
    !snapshot.exists
  ) {
    return "";
  }

  const transactionId =
    validateAdMobTransactionId(
      snapshot.id
    );

  if (!transactionId) {
    return "";
  }

  const data =
    snapshot.data() || {};

  if (
    data.transactionId !==
      undefined &&
    data.transactionId !==
      null
  ) {
    const stored =
      validateAdMobTransactionId(
        data.transactionId
      );

    if (
      !stored ||
      stored.toLowerCase() !==
        transactionId.toLowerCase()
    ) {
      return "";
    }
  }

  return transactionId;
}

// ============================================================
// 🕒 TIMESTAMP VALIDATION
// ============================================================

function isRewardTimestampAcceptable(
  data,
  referenceNowMs,
  requestStartedAtMs
) {
  const rewardMs =
    getRewardTimestampMs(data);

  if (rewardMs <= 0) {
    return false;
  }

  // Reward ei saa olla merkittävästi tulevaisuudessa.
  if (
    rewardMs >
    referenceNowMs +
      FUTURE_TOLERANCE_MS
  ) {
    return false;
  }

  // Reward ei saa olla liian vanha.
  if (
    referenceNowMs -
      rewardMs >
    MAX_REWARD_AGE_MS
  ) {
    return false;
  }

  // Client-pyynnön ja rewardin välillä sallitaan
  // grace-aika. Tämä suojaa vanhojen rewardien
  // uudelleenkäytöltä ilman että normaali SSV-viive
  // rikkoo validointia.
  if (
    requestStartedAtMs > 0 &&
    rewardMs <
      requestStartedAtMs -
        REQUEST_GRACE_MS
  ) {
    return false;
  }

  return true;
}

// ============================================================
// 🔐 REWARD VALIDATION
// ============================================================

function validateReward(
  snapshot,
  uid,
  rewardPurpose,
  claimedField,
  options = {}
) {
  const config =
    getRewardConfiguration(
      rewardPurpose
    );

  if (
    !isValidRewardConfiguration(
      config
    ) ||
    !snapshot ||
    !snapshot.exists ||
    typeof uid !==
      "string" ||
    !uid.trim()
  ) {
    return null;
  }

  const data =
    snapshot.data() || {};

  // ----------------------------------------------------------
  // USER
  // ----------------------------------------------------------

  if (
    typeof data.uid !==
      "string" ||
    data.uid !== uid
  ) {
    return null;
  }

  if (
    data.userId !==
      undefined &&
    data.userId !== null &&
    String(data.userId) !==
      uid
  ) {
    return null;
  }

  // ----------------------------------------------------------
  // REWARD TYPE
  // ----------------------------------------------------------

  if (
    data.rewardType !==
      "admob" ||
    data.rewardPurpose !==
      rewardPurpose
  ) {
    return null;
  }

  // ----------------------------------------------------------
  // VERIFICATION
  // ----------------------------------------------------------

  // Reward-dokumentin pitää olla SSV:n
  // kryptografisesti varmentama.
  if (
    data.verified !==
      undefined &&
    data.verified !== true
  ) {
    return null;
  }

  // ----------------------------------------------------------
  // CONSUMPTION
  // ----------------------------------------------------------

  if (
    data.rewardConsumed ===
      true ||
    data[claimedField] ===
      true
  ) {
    return null;
  }

  if (
    rewardPurpose ===
      "mining_start" &&
    (
      data.miningClaimed ===
        true ||
      data.miningStartClaimed ===
        true ||
      Boolean(
        data.miningStartClaimedAt
      )
    )
  ) {
    return null;
  }

  if (
    rewardPurpose ===
      "power_boost" &&
    (
      data.powerBoostClaimed ===
        true ||
      Boolean(
        data.powerBoostClaimedAt
      )
    )
  ) {
    return null;
  }

  // ----------------------------------------------------------
  // SSV AD UNIT
  // ----------------------------------------------------------

  if (
    typeof data.adUnit !==
      "string" ||
    data.adUnit.trim() !==
      String(
        config.ssvAdUnitId
      ).trim()
  ) {
    return null;
  }

  // ----------------------------------------------------------
  // REWARD ITEM
  // ----------------------------------------------------------

  if (
    typeof data.rewardItem !==
      "string" ||
    data.rewardItem.trim() !==
      String(
        config.rewardItem
      ).trim()
  ) {
    return null;
  }

  // ----------------------------------------------------------
  // REWARD AMOUNT
  // ----------------------------------------------------------

  const rewardAmount =
    Number(
      data.rewardAmount
    );

  const expectedAmount =
    Number(
      config.rewardAmount
    );

  if (
    !Number.isFinite(
      rewardAmount
    ) ||
    !Number.isFinite(
      expectedAmount
    ) ||
    rewardAmount !==
      expectedAmount
  ) {
    return null;
  }

  // ----------------------------------------------------------
  // TRANSACTION
  // ----------------------------------------------------------

  const transactionId =
    validateRewardTransactionId(
      snapshot
    );

  if (!transactionId) {
    return null;
  }

  // ----------------------------------------------------------
  // TIMESTAMP
  // ----------------------------------------------------------

  const referenceNowMs =
    safePositive(
      options.referenceNowMs,
      Date.now()
    );

  const requestStartedAtMs =
    safeNonNegative(
      options.requestStartedAtMs,
      0
    );

  if (
    !isRewardTimestampAcceptable(
      data,
      referenceNowMs,
      requestStartedAtMs
    )
  ) {
    return null;
  }

  // ----------------------------------------------------------
  // REQUESTED TRANSACTION
  // ----------------------------------------------------------

  const requestedTransactionId =
    validateAdMobTransactionId(
      options.transactionId
    );

  if (
    requestedTransactionId &&
    requestedTransactionId.toLowerCase() !==
      transactionId.toLowerCase()
  ) {
    return null;
  }

  // ----------------------------------------------------------
  // VERIFIED REWARD
  // ----------------------------------------------------------

  return {
    ref:
      snapshot.ref,

    data,

    transactionId,

    rewardTimestampMs:
      getRewardTimestampMs(
        data
      ),

    createdAtMs:
      getRewardCreatedAtMs(
        data
      ),
  };
}

// ============================================================
// 🔎 FIND VERIFIED REWARD
// ============================================================

async function findVerifiedAdMobReward(
  uid,
  rewardPurpose,
  claimedField,
  options = {}
) {
  const config =
    getRewardConfiguration(
      rewardPurpose
    );

  if (
    !isValidRewardConfiguration(
      config
    ) ||
    typeof uid !==
      "string" ||
    !uid.trim()
  ) {
    return null;
  }

  const referenceNowMs =
    safePositive(
      options.referenceNowMs,
      Date.now()
    );

  const requestStartedAtMs =
    safeNonNegative(
      options.requestStartedAtMs,
      0
    );

  const requestedTransactionId =
    validateAdMobTransactionId(
      options.transactionId
    );

  // ----------------------------------------------------------
  // EXACT TRANSACTION
  // ----------------------------------------------------------

  // Tämä on ensisijainen ja turvallisin tapa.
  if (
    requestedTransactionId
  ) {
    const snapshot =
      await db
        .collection(
          "admobRewards"
        )
        .doc(
          requestedTransactionId
        )
        .get();

    return validateReward(
      snapshot,
      uid,
      rewardPurpose,
      claimedField,
      {
        referenceNowMs,

        requestStartedAtMs,

        transactionId:
          requestedTransactionId,
      }
    );
  }

  // ----------------------------------------------------------
  // DISCOVERY
  // ----------------------------------------------------------

  const snapshot =
    await db
      .collection(
        "admobRewards"
      )
      .where(
        "uid",
        "==",
        uid
      )
      .where(
        "rewardPurpose",
        "==",
        rewardPurpose
      )
      .orderBy(
        "timestamp",
        "desc"
      )
      .limit(
        REWARD_QUERY_LIMIT
      )
      .get();

  if (
    snapshot.empty
  ) {
    return null;
  }

  const candidates = [];

  snapshot.forEach(
    (document) => {
      const reward =
        validateReward(
          document,
          uid,
          rewardPurpose,
          claimedField,
          {
            referenceNowMs,

            requestStartedAtMs,
          }
        );

      if (reward) {
        candidates.push(
          reward
        );
      }
    }
  );

  if (
    !candidates.length
  ) {
    return null;
  }

  candidates.sort(
    (a, b) => {
      if (
        b.rewardTimestampMs !==
        a.rewardTimestampMs
      ) {
        return (
          b.rewardTimestampMs -
          a.rewardTimestampMs
        );
      }

      if (
        b.createdAtMs !==
        a.createdAtMs
      ) {
        return (
          b.createdAtMs -
          a.createdAtMs
        );
      }

      return b.transactionId.localeCompare(
        a.transactionId
      );
    }
  );

  return candidates[0];
}

// ============================================================
// ⏳ WAIT FOR SSV
// ============================================================

function sleep(ms) {
  return new Promise(
    (resolve) => {
      setTimeout(
        resolve,
        ms
      );
    }
  );
}

async function waitForVerifiedAdMobReward(
  uid,
  rewardPurpose,
  claimedField,
  options = {}
) {
  const startedAt =
    Date.now();

  const requestStartedAtMs =
    safePositive(
      options.requestStartedAtMs,
      startedAt
    );

  const transactionId =
    validateAdMobTransactionId(
      options.transactionId
    );

  while (
    Date.now() -
      startedAt <
    SSV_WAIT_TIMEOUT_MS
  ) {
    const reward =
      await findVerifiedAdMobReward(
        uid,
        rewardPurpose,
        claimedField,
        {
          referenceNowMs:
            Date.now(),

          requestStartedAtMs,

          transactionId,
        }
      );

    if (reward) {
      console.log(
        "🐱 AdMob SSV reward verified.",
        {
          uid,

          rewardPurpose,

          transactionId:
            reward.transactionId,
        }
      );

      return reward;
    }

    await sleep(
      SSV_POLL_INTERVAL_MS
    );
  }

  const error =
    new Error(
      rewardPurpose ===
        "mining_start"
        ? "🐱 AdMob-mainoksen SSV-vahvistusta ei löytynyt ajoissa."
        : "🐱 Power Boost -mainoksen SSV-vahvistusta ei löytynyt ajoissa."
    );

  error.code =
    "ADMOB_SSV_TIMEOUT";

  throw error;
}

// ============================================================
// 🔐 AUTHORITATIVE VALIDATION
// ============================================================

function validateVerifiedRewardDocument(
  snapshot,
  uid,
  rewardPurpose,
  claimedField,
  options = {}
) {
  const reward =
    validateReward(
      snapshot,
      uid,
      rewardPurpose,
      claimedField,
      options
    );

  if (!reward) {
    const error =
      new Error(
        "🐱 AdMob-palkinnon validointi epäonnistui."
      );

    error.code =
      "ADMOB_REWARD_VALIDATION_FAILED";

    throw error;
  }

  return {
    ref:
      reward.ref,

    rewardData:
      reward.data,

    transactionId:
      reward.transactionId,

    rewardTimestampMs:
      reward.rewardTimestampMs,

    createdAtMs:
      reward.createdAtMs,
  };
}

// ============================================================
// 🎁 MINING START
// ============================================================

async function getVerifiedMiningStartReward(
  uid,
  options = {}
) {
  return waitForVerifiedAdMobReward(
    uid,
    "mining_start",
    "miningStartClaimed",
    options
  );
}

// ============================================================
// ⚡ POWER BOOST
// ============================================================

async function getVerifiedPowerBoostReward(
  uid,
  options = {}
) {
  return waitForVerifiedAdMobReward(
    uid,
    "power_boost",
    "powerBoostClaimed",
    options
  );
}

// ============================================================
// 📦 EXPORTS
// ============================================================

module.exports = {
  getSafeNumber:
    safeNumber,

  getSafeNonNegativeNumber:
    safeNonNegative,

  getSafePositiveNumber:
    safePositive,

  validateAdMobTransactionId,

  getTimestampMilliseconds:
    timestampMs,

  getRewardTimestampMs,

  getRewardCreatedAtMs,

  getRewardConfiguration,

  validateRewardTransactionId,

  isRewardTimestampAcceptable,

  isValidRewardData: (
    snapshot,
    uid,
    rewardPurpose,
    claimedField,
    options = {}
  ) =>
    Boolean(
      validateReward(
        snapshot,
        uid,
        rewardPurpose,
        claimedField,
        options
      )
    ),

  findVerifiedAdMobReward,

  waitForVerifiedAdMobReward,

  validateVerifiedRewardDocument,

  getVerifiedMiningStartReward,

  getVerifiedPowerBoostReward,
};