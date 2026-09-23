"use strict";

// ============================================================
// 🐱 STELLURIINI - ADMOB REWARD SERVICE
// ============================================================
//
// Vastuu:
//
// 🔐 AdMob SSV reward -validointi
// 🔑 AdMob transaction_id -validointi
// 🕒 Reward timestamp -validointi
// 🔎 Verifioidyn rewardin haku
// ⏳ SSV rewardin odottaminen
// 🎁 Mining Start reward
// ⚡ Power Boost reward
//
// IMPORTANT:
//
// AdMob reward is NOT an STL token reward.
//
// AdMob only authorizes:
// - Mining Start
// - Power Boost
//
// Tämä tiedosto ei muuta käyttäjän mining-balancea eikä
// kirjoita mining-tilaa. Se ainoastaan etsii ja validoi
// AdMob SSV -handlerin jo tallentaman reward-dokumentin.
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
// 🔐 ADMOB SSV TIMING SAFETY
// ============================================================
//
// AdMob SSV callback voi saapua viiveellä.
//
// Sallimme pienen kellon/verkon vaihtelun requestin alkuun
// nähden, mutta emme hyväksy mielivaltaisen vanhaa rewardia.
//
// Varsinainen authoritative validation tehdään edelleen
// Firestore transactionin sisällä.
//
// ============================================================

const ADMOB_REWARD_REQUEST_GRACE_MS =
  5 * 60 * 1000;

const ADMOB_REWARD_MAX_AGE_MS =
  15 * 60 * 1000;

const ADMOB_REWARD_FUTURE_TOLERANCE_MS =
  2 * 60 * 1000;

// ============================================================
// 🔢 SAFE NUMBERS
// ============================================================

function getSafeNumber(
  value,
  fallback = 0
) {
  const number =
    Number(value);

  return Number.isFinite(number)
    ? number
    : fallback;
}

function getSafeNonNegativeNumber(
  value,
  fallback = 0
) {
  const number =
    Number(value);

  return Number.isFinite(number) &&
    number >= 0
    ? number
    : fallback;
}

function getSafePositiveNumber(
  value,
  fallback = 0
) {
  const number =
    Number(value);

  return Number.isFinite(number) &&
    number > 0
    ? number
    : fallback;
}

// ============================================================
// 🔐 ADMOB TRANSACTION ID
// ============================================================
//
// AdMob transaction_id:n yksilöllinen reward-tapahtuman
// tunniste.
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
    transactionId.length > 256
  ) {
    return "";
  }

  if (
    !/^[a-fA-F0-9]+$/.test(
      transactionId
    )
  ) {
    return "";
  }

  return transactionId;
}

// ============================================================
// 🕒 TIMESTAMP → MILLISECONDS
// ============================================================

function getTimestampMilliseconds(
  value
) {
  if (!value) {
    return 0;
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
          date.getTime()
        )
      ) {
        return date.getTime();
      }
    } catch (
      error
    ) {
      return 0;
    }
  }

  if (
    value instanceof Date
  ) {
    return Number.isNaN(
      value.getTime()
    )
      ? 0
      : value.getTime();
  }

  if (
    typeof value ===
    "string"
  ) {
    const parsed =
      new Date(value);

    return Number.isNaN(
      parsed.getTime()
    )
      ? 0
      : parsed.getTime();
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
// 🔐 REWARD TIMESTAMP
// ============================================================
//
// AdMob SSV timestamp on reward-dokumentissa on
// authoritative reward-event time, jos se on saatavilla.
//
// ============================================================

function getRewardTimestampMs(
  rewardData
) {
  if (!rewardData) {
    return 0;
  }

  const candidates = [
    rewardData.timestamp,
    rewardData.rewardedAt,
    rewardData.receivedAt,
    rewardData.createdAt,
  ];

  for (
    const candidate of
    candidates
  ) {
    const milliseconds =
      getTimestampMilliseconds(
        candidate
      );

    if (
      milliseconds > 0
    ) {
      return milliseconds;
    }
  }

  return 0;
}

// ============================================================
// 🔐 REWARD CREATED AT
// ============================================================

function getRewardCreatedAtMs(
  rewardData
) {
  if (!rewardData) {
    return 0;
  }

  const candidates = [
    rewardData.createdAt,
    rewardData.receivedAt,
    rewardData.timestamp,
    rewardData.rewardedAt,
  ];

  for (
    const candidate of
    candidates
  ) {
    const milliseconds =
      getTimestampMilliseconds(
        candidate
      );

    if (
      milliseconds > 0
    ) {
      return milliseconds;
    }
  }

  return 0;
}

// ============================================================
// 🎁 EXPECTED ADMOB REWARD CONFIGURATION
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
// 🔐 REWARD TRANSACTION ID CONSISTENCY
// ============================================================

function validateRewardTransactionId(
  rewardSnapshot
) {
  if (
    !rewardSnapshot ||
    !rewardSnapshot.exists
  ) {
    return "";
  }

  const transactionId =
    validateAdMobTransactionId(
      rewardSnapshot.id
    );

  if (!transactionId) {
    return "";
  }

  const rewardData =
    rewardSnapshot.data() ||
    {};

  if (
    rewardData.transactionId
  ) {
    const storedTransactionId =
      validateAdMobTransactionId(
        rewardData.transactionId
      );

    if (
      !storedTransactionId ||
      storedTransactionId.toLowerCase() !==
        transactionId.toLowerCase()
    ) {
      return "";
    }
  }

  return transactionId;
}

// ============================================================
// 🔐 REWARD TIMESTAMP VALIDATION
// ============================================================

function isRewardTimestampAcceptable(
  rewardData,
  referenceNowMs,
  requestStartedAtMs
) {
  const rewardTimestampMs =
    getRewardTimestampMs(
      rewardData
    );

  if (
    rewardTimestampMs <= 0
  ) {
    return false;
  }

  if (
    rewardTimestampMs >
    referenceNowMs +
      ADMOB_REWARD_FUTURE_TOLERANCE_MS
  ) {
    return false;
  }

  if (
    referenceNowMs -
      rewardTimestampMs >
    ADMOB_REWARD_MAX_AGE_MS
  ) {
    return false;
  }

  if (
    requestStartedAtMs > 0 &&
    rewardTimestampMs <
      requestStartedAtMs -
        ADMOB_REWARD_REQUEST_GRACE_MS
  ) {
    return false;
  }

  return true;
}

// ============================================================
// 🔐 VALIDATE REWARD DATA
// ============================================================

function isValidRewardData(
  rewardSnapshot,
  uid,
  rewardPurpose,
  claimedField,
  options = {}
) {
  const configuration =
    getRewardConfiguration(
      rewardPurpose
    );

  if (!configuration) {
    return false;
  }

  if (
    !rewardSnapshot ||
    !rewardSnapshot.exists
  ) {
    return false;
  }

  const rewardData =
    rewardSnapshot.data() ||
    {};

  if (
    typeof uid !==
      "string" ||
    !uid
  ) {
    return false;
  }

  if (
    rewardData.uid !==
    uid
  ) {
    return false;
  }

  if (
    rewardData.userId !==
      undefined &&
    rewardData.userId !==
      null &&
    String(
      rewardData.userId
    ) !== uid
  ) {
    return false;
  }

  if (
    rewardData.rewardType !==
    "admob"
  ) {
    return false;
  }

  if (
    rewardData.rewardPurpose !==
    rewardPurpose
  ) {
    return false;
  }

  if (
    rewardData.rewardConsumed ===
    true
  ) {
    return false;
  }

  if (
    rewardData[claimedField] ===
    true
  ) {
    return false;
  }

  if (
    rewardPurpose ===
      "mining_start" &&
    (
      rewardData.miningClaimed ===
        true ||
      rewardData.miningStartClaimed ===
        true ||
      rewardData.miningStartClaimedAt
    )
  ) {
    return false;
  }

  if (
    rewardPurpose ===
      "power_boost" &&
    (
      rewardData.powerBoostClaimed ===
        true ||
      rewardData.powerBoostClaimedAt
    )
  ) {
    return false;
  }

  if (
    typeof rewardData.adUnit !==
    "string"
  ) {
    return false;
  }

  const adUnit =
    rewardData.adUnit.trim();

  if (
    adUnit !==
      configuration.rewardedAdUnitId &&
    adUnit !==
      configuration.ssvAdUnitId
  ) {
    return false;
  }

  if (
    typeof rewardData.rewardItem !==
    "string"
  ) {
    return false;
  }

  if (
    rewardData.rewardItem.trim() !==
    configuration.rewardItem
  ) {
    return false;
  }

  const rewardAmount =
    Number(
      rewardData.rewardAmount
    );

  if (
    !Number.isFinite(
      rewardAmount
    )
  ) {
    return false;
  }

  if (
    rewardAmount !==
    Number(
      configuration.rewardAmount
    )
  ) {
    return false;
  }

  const transactionId =
    validateRewardTransactionId(
      rewardSnapshot
    );

  if (!transactionId) {
    return false;
  }

  const referenceNowMs =
    getSafePositiveNumber(
      options.referenceNowMs,
      Date.now()
    );

  const requestStartedAtMs =
    getSafeNonNegativeNumber(
      options.requestStartedAtMs,
      0
    );

  if (
    !isRewardTimestampAcceptable(
      rewardData,
      referenceNowMs,
      requestStartedAtMs
    )
  ) {
    return false;
  }

  return true;
}

// ============================================================
// 🔐 FIND VERIFIED ADMOB REWARD
// ============================================================

const ADMOB_REWARD_QUERY_LIMIT =
  100;

async function findVerifiedAdMobReward(
  uid,
  rewardPurpose,
  claimedField,
  options = {}
) {
  const configuration =
    getRewardConfiguration(
      rewardPurpose
    );

  if (!configuration) {
    return null;
  }

  if (
    typeof uid !==
      "string" ||
    !uid.trim()
  ) {
    return null;
  }

  const referenceNowMs =
    getSafePositiveNumber(
      options.referenceNowMs,
      Date.now()
    );

  const requestStartedAtMs =
    getSafeNonNegativeNumber(
      options.requestStartedAtMs,
      0
    );

  const requestedTransactionId =
    validateAdMobTransactionId(
      options.transactionId
    );

  // ----------------------------------------------------------
  // 🎯 EXACT TRANSACTION LOOKUP
  // ----------------------------------------------------------
  //
  // Jos client toimitti transaction_id:n, haetaan juuri tämä
  // dokumentti. Emme käytä silloin 100 dokumentin query-rajaa,
  // joka voisi muuten piilottaa oikean rewardin.
  //
  // ----------------------------------------------------------

  if (
    requestedTransactionId
  ) {
    const rewardRef =
      db
        .collection(
          "admobRewards"
        )
        .doc(
          requestedTransactionId
        );

    const rewardSnapshot =
      await rewardRef.get();

    if (
      !rewardSnapshot.exists
    ) {
      return null;
    }

    if (
      !isValidRewardData(
        rewardSnapshot,
        uid,
        rewardPurpose,
        claimedField,
        {
          referenceNowMs,
          requestStartedAtMs,
        }
      )
    ) {
      return null;
    }

    const rewardData =
      rewardSnapshot.data() ||
      {};

    const transactionId =
      validateRewardTransactionId(
        rewardSnapshot
      );

    if (!transactionId) {
      return null;
    }

    return {
      ref:
        rewardSnapshot.ref,

      data:
        rewardData,

      transactionId,

      rewardTimestampMs:
        getRewardTimestampMs(
          rewardData
        ),

      createdAtMs:
        getRewardCreatedAtMs(
          rewardData
        ),
    };
  }

  // ----------------------------------------------------------
  // 🔎 DISCOVERY LOOKUP
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
      .limit(
        ADMOB_REWARD_QUERY_LIMIT
      )
      .get();

  if (
    snapshot.empty
  ) {
    return null;
  }

  const candidates = [];

  snapshot.forEach(
    (doc) => {
      const rewardData =
        doc.data() ||
        {};

      if (
        !isValidRewardData(
          doc,
          uid,
          rewardPurpose,
          claimedField,
          {
            referenceNowMs,
            requestStartedAtMs,
          }
        )
      ) {
        return;
      }

      const transactionId =
        validateRewardTransactionId(
          doc
        );

      if (!transactionId) {
        return;
      }

      const rewardTimestampMs =
        getRewardTimestampMs(
          rewardData
        );

      const createdAtMs =
        getRewardCreatedAtMs(
          rewardData
        );

      candidates.push({
        ref:
          doc.ref,

        data:
          rewardData,

        transactionId,

        rewardTimestampMs,

        createdAtMs,
      });
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
// 🔐 WAIT FOR ADMOB SSV
// ============================================================

const ADMOB_SSV_WAIT_TIMEOUT_MS =
  90 * 1000;

const ADMOB_SSV_POLL_INTERVAL_MS =
  2 * 1000;

function sleep(
  milliseconds
) {
  return new Promise(
    (resolve) => {
      setTimeout(
        resolve,
        milliseconds
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
    getSafePositiveNumber(
      options.requestStartedAtMs,
      startedAt
    );

  const requestedTransactionId =
    validateAdMobTransactionId(
      options.transactionId
    );

  while (
    Date.now() -
      startedAt <
    ADMOB_SSV_WAIT_TIMEOUT_MS
  ) {
    const nowMs =
      Date.now();

    const reward =
      await findVerifiedAdMobReward(
        uid,
        rewardPurpose,
        claimedField,
        {
          referenceNowMs:
            nowMs,

          requestStartedAtMs,

          transactionId:
            requestedTransactionId,
        }
      );

    if (reward) {
      console.log(
        "🐱 AdMob SSV reward found",
        {
          uid,
          rewardPurpose,
          transactionId:
            reward.transactionId,
          rewardTimestampMs:
            reward.rewardTimestampMs,
          elapsedMs:
            Date.now() -
            startedAt,
        }
      );

      return reward;
    }

    await sleep(
      ADMOB_SSV_POLL_INTERVAL_MS
    );
  }

  throw new Error(
    rewardPurpose ===
      "mining_start"
      ? "🐱 AdMob-mainoksen vahvistusta ei vielä löytynyt. Katso Mining Start -mainos loppuun ja odota hetki."
      : "🐱 Power Boost -mainoksen vahvistusta ei vielä löytynyt. Katso mainos loppuun ja odota hetki."
  );
}

// ============================================================
// 🔐 AUTHORITATIVE REWARD VALIDATION
// ============================================================

function validateVerifiedRewardDocument(
  rewardSnapshot,
  uid,
  rewardPurpose,
  claimedField,
  options = {}
) {
  const configuration =
    getRewardConfiguration(
      rewardPurpose
    );

  if (!configuration) {
    throw new Error(
      "🐱 AdMob-palkinnon käyttötarkoitus ei ole kelvollinen."
    );
  }

  if (
    !rewardSnapshot ||
    !rewardSnapshot.exists
  ) {
    throw new Error(
      "🐱 AdMob-palkintoa ei enää löytynyt."
    );
  }

  const rewardData =
    rewardSnapshot.data() ||
    {};

  if (
    rewardData.uid !==
    uid
  ) {
    throw new Error(
      "🐱 AdMob-palkinnon käyttäjä ei täsmää."
    );
  }

  if (
    rewardData.userId !==
      undefined &&
    rewardData.userId !==
      null &&
    String(
      rewardData.userId
    ) !== uid
  ) {
    throw new Error(
      "🐱 AdMob-palkinnon user ID ei täsmää."
    );
  }

  if (
    rewardData.rewardType !==
    "admob"
  ) {
    throw new Error(
      "🐱 AdMob-palkinnon tyyppi ei ole kelvollinen."
    );
  }

  if (
    rewardData.rewardPurpose !==
    rewardPurpose
  ) {
    throw new Error(
      "🐱 AdMob-palkinnon käyttötarkoitus ei täsmää."
    );
  }

  if (
    rewardData.rewardConsumed ===
      true ||
    rewardData[claimedField] ===
      true
  ) {
    throw new Error(
      "🐱 Tämä AdMob-palkinto on jo käytetty."
    );
  }

  if (
    rewardPurpose ===
      "mining_start" &&
    (
      rewardData.miningClaimed ===
        true ||
      rewardData.miningStartClaimed ===
        true ||
      rewardData.miningStartClaimedAt
    )
  ) {
    throw new Error(
      "🐱 Tämä Mining Start -palkinto on jo käytetty."
    );
  }

  if (
    rewardPurpose ===
      "power_boost" &&
    (
      rewardData.powerBoostClaimed ===
        true ||
      rewardData.powerBoostClaimedAt
    )
  ) {
    throw new Error(
      "🐱 Tämä Power Boost -palkinto on jo käytetty."
    );
  }

  if (
    typeof rewardData.adUnit !==
    "string"
  ) {
    throw new Error(
      "🐱 AdMob-mainoksen tunnistetiedot puuttuvat."
    );
  }

  const adUnit =
    rewardData.adUnit.trim();

  if (
    adUnit !==
      configuration.rewardedAdUnitId &&
    adUnit !==
      configuration.ssvAdUnitId
  ) {
    throw new Error(
      "🐱 AdMob-mainoksen tunnistetiedot eivät täsmää tähän toimintoon."
    );
  }

  if (
    typeof rewardData.rewardItem !==
      "string" ||
    !rewardData.rewardItem.trim()
  ) {
    throw new Error(
      "🐱 AdMob-palkinnon tiedot puuttuvat."
    );
  }

  if (
    rewardData.rewardItem.trim() !==
    configuration.rewardItem
  ) {
    throw new Error(
      "🐱 AdMob-palkinnon reward item ei täsmää."
    );
  }

  const rewardAmount =
    Number(
      rewardData.rewardAmount
    );

  if (
    !Number.isFinite(
      rewardAmount
    ) ||
    rewardAmount !==
      Number(
        configuration.rewardAmount
      )
  ) {
    throw new Error(
      "🐱 AdMob-palkinnon määrä ei ole kelvollinen."
    );
  }

  const transactionId =
    validateRewardTransactionId(
      rewardSnapshot
    );

  if (!transactionId) {
    throw new Error(
      "🐱 AdMob transaction_id ei ole kelvollinen."
    );
  }

  const referenceNowMs =
    getSafePositiveNumber(
      options.referenceNowMs,
      Date.now()
    );

  const requestStartedAtMs =
    getSafeNonNegativeNumber(
      options.requestStartedAtMs,
      0
    );

  if (
    !isRewardTimestampAcceptable(
      rewardData,
      referenceNowMs,
      requestStartedAtMs
    )
  ) {
    throw new Error(
      "🐱 AdMob-palkinnon aikaleima ei ole enää kelvollinen tähän pyyntöön."
    );
  }

  const requestedTransactionId =
    validateAdMobTransactionId(
      options.transactionId
    );

  if (
    requestedTransactionId &&
    requestedTransactionId.toLowerCase() !==
      transactionId.toLowerCase()
  ) {
    throw new Error(
      "🐱 AdMob transaction_id ei täsmää pyydettyyn palkintoon."
    );
  }

  return {
    rewardData,

    transactionId,

    rewardTimestampMs:
      getRewardTimestampMs(
        rewardData
      ),
  };
}

// ============================================================
// 🎁 VERIFIED MINING START REWARD
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
// ⚡ VERIFIED POWER BOOST REWARD
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
  getSafeNumber,
  getSafeNonNegativeNumber,
  getSafePositiveNumber,

  validateAdMobTransactionId,

  getTimestampMilliseconds,
  getRewardTimestampMs,
  getRewardCreatedAtMs,

  getRewardConfiguration,

  validateRewardTransactionId,
  isRewardTimestampAcceptable,
  isValidRewardData,

  findVerifiedAdMobReward,
  waitForVerifiedAdMobReward,

  validateVerifiedRewardDocument,

  getVerifiedMiningStartReward,
  getVerifiedPowerBoostReward,
};