"use strict";

// ============================================================
// 🐱 STELLA MINING FUNCTIONS
// ============================================================
//
// ⛏️ Stella Mining Status
// ⏱️ 24 tunnin louhintajakso
// ✨ Reaaliaikainen STL-louhinta
// 💰 Valmistuneen louhinnan kerääminen
// 🔄 Uuden louhintajakson käynnistäminen
// 📜 Mining-historia
// 🎁 Daily Hash Rate
// 📺 Stella Power Boost
// 🏆 Stella Achievements
// 🔐 AdMob SSV -varmistettu Mining Start
// 🔐 AdMob SSV -varmistettu Power Boost
//
// ============================================================

// ============================================================
// 🔥 FIREBASE FUNCTIONS
// ============================================================

const {
  onCall,
  HttpsError,
} = require("firebase-functions/v2/https");

// ============================================================
// 🔥 FIREBASE
// ============================================================

const {
  db,
  FieldValue,
} = require("../firebase/firebase");

// ============================================================
// ⚙️ CONFIG
// ============================================================

const {
  DAILY_HASH_RATE_START,
  DAILY_HASH_RATE_STEP,
  DAILY_HASH_RATE_MAX_DAY,
  MAX_DAILY_HASH_RATE,
  MINING_DURATION_MS,
  MINING_PER_HASH_PER_HOUR,
  AD_HASH_RATE_BONUS,
  AD_BOOST_DURATION_MS,
  MAX_ADS_PER_DAY,
  AD_COOLDOWN_MS,
} = require("../config/miningConfig");

// ============================================================
// 📅 DATE UTILITIES
// ============================================================

const {
  getUtcDateString,
} = require("../utils/dateUtils");

// ============================================================
// 👤 USER UTILITIES
// ============================================================

const {
  getUserRef,
  getHistoryCollection,
} = require("../utils/userUtils");

// ============================================================
// ⛏️ MINING UTILITIES
// ============================================================

const {
  calculateMiningStatus,
  getMiningStartTime,
  getMiningEndTime,
  calculateMining,
} = require("../utils/miningUtils");

// ============================================================
// 🔢 SAFE NUMBER
// ============================================================

function getSafeNumber(
  value,
  fallback = 0
) {
  const number = Number(value);

  return Number.isFinite(number)
    ? number
    : fallback;
}

// ============================================================
// 🔥 SAFE NON-NEGATIVE NUMBER
// ============================================================

function getSafeNonNegativeNumber(
  value,
  fallback = 0
) {
  const number = Number(value);

  if (
    Number.isFinite(number) &&
    number >= 0
  ) {
    return number;
  }

  return fallback;
}

// ============================================================
// 🔥 SAFE POSITIVE NUMBER
// ============================================================

function getSafePositiveNumber(
  value,
  fallback = 0
) {
  const number = Number(value);

  if (
    Number.isFinite(number) &&
    number > 0
  ) {
    return number;
  }

  return fallback;
}

// ============================================================
// 🔐 VALIDATE ADMOB TRANSACTION ID
// ============================================================

function validateAdMobTransactionId(
  value
) {
  if (
    typeof value !== "string"
  ) {
    return "";
  }

  const transactionId =
    value.trim();

  if (
    transactionId.length === 0 ||
    transactionId.length > 256 ||
    transactionId.includes("/")
  ) {
    return "";
  }

  return transactionId;
}

// ============================================================
// 🔐 GET ADMOB REWARD REFERENCE
// ============================================================

function getAdMobRewardRef(
  transactionId
) {
  const safeTransactionId =
    validateAdMobTransactionId(
      transactionId
    );

  if (!safeTransactionId) {
    return null;
  }

  return db
    .collection("admobRewards")
    .doc(safeTransactionId);
}

// ============================================================
// 🔐 GET TIMESTAMP MILLISECONDS
// ============================================================

function getTimestampMilliseconds(
  value
) {
  if (!value) {
    return 0;
  }

  if (
    typeof value.toDate === "function"
  ) {
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
  }

  if (
    value instanceof Date
  ) {
    if (
      !Number.isNaN(
        value.getTime()
      )
    ) {
      return value.getTime();
    }

    return 0;
  }

  if (
    typeof value === "string"
  ) {
    const parsed =
      new Date(value);

    if (
      !Number.isNaN(
        parsed.getTime()
      )
    ) {
      return parsed.getTime();
    }
  }

  if (
    typeof value === "number" &&
    Number.isFinite(value)
  ) {
    return value;
  }

  return 0;
}

// ============================================================
// 🔐 GET ADMOB REWARD CREATION TIME
// ============================================================

function getRewardCreatedAtMs(
  rewardData
) {
  const candidates = [
    rewardData.createdAt,
    rewardData.receivedAt,
    rewardData.timestamp,
    rewardData.rewardedAt,
  ];

  for (
    const candidate of candidates
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
// 🔐 FIND VERIFIED ADMOB REWARD
// ============================================================
//
// Yksi Firestore-haku.
//
// AdMob SSV voi saapua hieman myöhemmin kuin Flutterin
// RewardedAd.onUserEarnedReward tapahtuma.
//
// Backend odottaa tarvittaessa SSV:tä.
//
// ============================================================

async function findVerifiedAdMobReward(
  uid,
  rewardPurpose,
  claimedField
) {
  const rewardsQuery =
    db
      .collection("admobRewards")
      .where(
        "uid",
        "==",
        uid
      )
      .where(
        "rewardType",
        "==",
        "admob"
      )
      .where(
        "rewardPurpose",
        "==",
        rewardPurpose
      )
      .where(
        claimedField,
        "==",
        false
      )
      .limit(20);

  const rewardSnapshot =
    await rewardsQuery.get();

  if (
    rewardSnapshot.empty
  ) {
    return null;
  }

  const candidates = [];

  rewardSnapshot.forEach(
    (doc) => {
      const rewardData =
        doc.data() || {};

      if (
        typeof rewardData.uid !== "string" ||
        rewardData.uid !== uid
      ) {
        return;
      }

      if (
        rewardData.rewardType !==
        "admob"
      ) {
        return;
      }

      if (
        rewardData.rewardPurpose !==
        rewardPurpose
      ) {
        return;
      }

      if (
        rewardData[claimedField] === true
      ) {
        return;
      }

      if (
        rewardPurpose === "mining_start" &&
        (
          rewardData.miningClaimed === true ||
          rewardData.miningStartClaimed === true ||
          rewardData.miningStartClaimedAt
        )
      ) {
        return;
      }

      if (
        rewardPurpose === "power_boost" &&
        (
          rewardData.powerBoostClaimed === true ||
          rewardData.powerBoostClaimedAt
        )
      ) {
        return;
      }

      if (
        typeof rewardData.adUnit !== "string" ||
        rewardData.adUnit.length === 0
      ) {
        return;
      }

      if (
        typeof rewardData.rewardItem !== "string" ||
        rewardData.rewardItem.length === 0
      ) {
        return;
      }

      const transactionId =
        validateAdMobTransactionId(
          doc.id
        );

      if (!transactionId) {
        return;
      }

      const createdAtMs =
        getRewardCreatedAtMs(
          rewardData
        );

      candidates.push({
        ref: doc.ref,
        data: rewardData,
        transactionId,
        createdAtMs,
      });
    }
  );

  if (
    candidates.length === 0
  ) {
    return null;
  }

  candidates.sort(
    (a, b) => {
      return (
        b.createdAtMs -
        a.createdAtMs
      );
    }
  );

  return candidates[0];
}

// ============================================================
// 🔐 WAIT FOR VERIFIED ADMOB REWARD
// ============================================================
//
// AdMob SSV ei välttämättä ehdi Firestoreen ennen kuin
// Flutter kutsuu claimMining/powerBoost.
//
// Backend odottaa vahvistusta.
//
// Tarkistus:
// - ensimmäinen heti
// - sen jälkeen 2 sekunnin välein
// - enintään 90 sekuntia
//
// Cloud Functionin request timeout on 120 sekuntia,
// joten SSV:lle jää 30 sekunnin turvamarginaali.
//
// ============================================================

const ADMOB_SSV_WAIT_TIMEOUT_MS =
  90 * 1000;

const ADMOB_SSV_POLL_INTERVAL_MS =
  2 * 1000;

async function waitForVerifiedAdMobReward(
  uid,
  rewardPurpose,
  claimedField
) {
  const startedAt =
    Date.now();

  let attempt = 0;

  while (
    Date.now() -
      startedAt <
    ADMOB_SSV_WAIT_TIMEOUT_MS
  ) {
    attempt += 1;

    const reward =
      await findVerifiedAdMobReward(
        uid,
        rewardPurpose,
        claimedField
      );

    if (reward) {
      console.log(
        "🐱 AdMob SSV reward found:",
        {
          uid,
          rewardPurpose,
          transactionId:
            reward.transactionId,
          attempt,
          elapsedMs:
            Date.now() - startedAt,
        }
      );

      return reward;
    }

    const elapsedMs =
      Date.now() -
      startedAt;

    if (
      elapsedMs >=
      ADMOB_SSV_WAIT_TIMEOUT_MS
    ) {
      break;
    }

    await new Promise(
      (resolve) => {
        setTimeout(
          resolve,
          ADMOB_SSV_POLL_INTERVAL_MS
        );
      }
    );
  }

  console.warn(
    "🐱 AdMob SSV reward was not found before timeout:",
    {
      uid,
      rewardPurpose,
      timeoutMs:
        ADMOB_SSV_WAIT_TIMEOUT_MS,
    }
  );

  throw new HttpsError(
    "failed-precondition",
    rewardPurpose === "mining_start"
      ? "🐱 AdMob-mainoksen vahvistusta ei vielä löytynyt. Katso Mining Start -mainos loppuun ja odota hetki."
      : "🐱 Power Boost -mainoksen vahvistusta ei vielä löytynyt. Katso mainos loppuun ja odota hetki."
  );
}

// ============================================================
// 🔐 VALIDATE VERIFIED REWARD DOCUMENT
// ============================================================

function validateVerifiedRewardDocument(
  rewardSnapshot,
  uid,
  rewardPurpose,
  claimedField
) {
  if (
    !rewardSnapshot.exists
  ) {
    throw new HttpsError(
      "failed-precondition",
      "🐱 AdMob-palkintoa ei enää löytynyt."
    );
  }

  const rewardData =
    rewardSnapshot.data() || {};

  if (
    rewardData.uid !== uid
  ) {
    throw new HttpsError(
      "permission-denied",
      "🐱 AdMob-palkinnon käyttäjä ei täsmää."
    );
  }

  if (
    rewardData.rewardType !==
    "admob"
  ) {
    throw new HttpsError(
      "failed-precondition",
      "🐱 AdMob-palkinnon tyyppi ei ole kelvollinen."
    );
  }

  if (
    rewardData.rewardPurpose !==
    rewardPurpose
  ) {
    throw new HttpsError(
      "failed-precondition",
      "🐱 AdMob-palkinnon käyttötarkoitus ei täsmää."
    );
  }

  if (
    rewardData[claimedField] === true
  ) {
    throw new HttpsError(
      "already-exists",
      "🐱 Tämä AdMob-palkinto on jo käytetty."
    );
  }

  if (
    rewardPurpose === "mining_start" &&
    (
      rewardData.miningClaimed === true ||
      rewardData.miningStartClaimed === true ||
      rewardData.miningStartClaimedAt
    )
  ) {
    throw new HttpsError(
      "already-exists",
      "🐱 Tämä Mining Start -palkinto on jo käytetty."
    );
  }

  if (
    rewardPurpose === "power_boost" &&
    (
      rewardData.powerBoostClaimed === true ||
      rewardData.powerBoostClaimedAt
    )
  ) {
    throw new HttpsError(
      "already-exists",
      "🐱 Tämä Power Boost -palkinto on jo käytetty."
    );
  }

  if (
    typeof rewardData.adUnit !== "string" ||
    rewardData.adUnit.length === 0
  ) {
    throw new HttpsError(
      "failed-precondition",
      "🐱 AdMob-mainoksen tunnistetiedot puuttuvat."
    );
  }

  if (
    typeof rewardData.rewardItem !== "string" ||
    rewardData.rewardItem.length === 0
  ) {
    throw new HttpsError(
      "failed-precondition",
      "🐱 AdMob-palkinnon tiedot puuttuvat."
    );
  }

  return rewardData;
}

// ============================================================
// 🔐 FIND VERIFIED ADMOB MINING START REWARD
// ============================================================

async function getVerifiedMiningStartReward(
  uid
) {
  return waitForVerifiedAdMobReward(
    uid,
    "mining_start",
    "miningStartClaimed"
  );
}

// ============================================================
// 🔐 FIND VERIFIED ADMOB POWER BOOST REWARD
// ============================================================

async function getVerifiedPowerBoostReward(
  uid
) {
  return waitForVerifiedAdMobReward(
    uid,
    "power_boost",
    "powerBoostClaimed"
  );
}

// ============================================================
// 🎁 CALCULATE DAILY HASH RATE
// ============================================================

function calculateDailyHashRate(
  streak
) {
  const safeStreak =
    Math.max(
      1,
      Math.floor(
        getSafeNumber(
          streak,
          1
        )
      )
    );

  const effectiveDay =
    Math.min(
      safeStreak,
      DAILY_HASH_RATE_MAX_DAY
    );

  const rate =
    DAILY_HASH_RATE_START +
    (
      (effectiveDay - 1) *
      DAILY_HASH_RATE_STEP
    );

  return Math.min(
    MAX_DAILY_HASH_RATE,
    Math.max(
      DAILY_HASH_RATE_START,
      rate
    )
  );
}

// ============================================================
// 🎁 GET DAILY STREAK
// ============================================================

function getDailyStreak(
  data
) {
  const storedStreak =
    data.dailyStreak ??
    data.streak ??
    0;

  return Math.max(
    0,
    Math.floor(
      getSafeNumber(
        storedStreak,
        0
      )
    )
  );
}

// ============================================================
// 🎁 GET DAILY STATUS
// ============================================================

function getDailyStatus(
  data,
  today
) {
  const lastDailyDate =
    typeof data.lastDailyDate === "string"
      ? data.lastDailyDate
      : "";

  const dailyClaimed =
    lastDailyDate === today;

  const streak =
    getDailyStreak(data);

  const dailyHashRate =
    calculateDailyHashRate(
      streak > 0
        ? streak
        : 1
    );

  return {
    dailyClaimed,
    streak,
    dailyHashRate,
  };
}

// ============================================================
// 🎁 CALCULATE NEXT DAILY CLAIM
// ============================================================

function calculateNextDailyClaim(
  data,
  today
) {
  const lastDailyDate =
    typeof data.lastDailyDate === "string"
      ? data.lastDailyDate
      : "";

  const currentStreak =
    getDailyStreak(data);

  if (
    lastDailyDate === today
  ) {
    const safeStreak =
      currentStreak > 0
        ? currentStreak
        : 1;

    return {
      claimedToday: true,
      streak: safeStreak,
      dailyHashRate:
        calculateDailyHashRate(
          safeStreak
        ),
    };
  }

  const yesterday =
    new Date(
      `${today}T00:00:00.000Z`
    );

  yesterday.setUTCDate(
    yesterday.getUTCDate() - 1
  );

  const yesterdayString =
    yesterday
      .toISOString()
      .slice(
        0,
        10
      );

  let newStreak = 1;

  if (
    lastDailyDate === yesterdayString &&
    currentStreak > 0
  ) {
    newStreak =
      currentStreak + 1;
  }

  const dailyHashRate =
    calculateDailyHashRate(
      newStreak
    );

  return {
    claimedToday: false,
    streak: newStreak,
    dailyHashRate,
  };
}

// ============================================================
// 📺 GET AD STATUS
// ============================================================

function getAdStatus(
  data,
  nowMs,
  today
) {
  const storedDate =
    typeof data.lastAdDate === "string"
      ? data.lastAdDate
      : "";

  const adsToday =
    storedDate === today
      ? Math.max(
          0,
          Math.floor(
            getSafeNumber(
              data.adsToday,
              0
            )
          )
        )
      : 0;

  const lastAdRewardMs =
    getTimestampMilliseconds(
      data.lastAdRewardAt
    );

  const cooldownRemainingMs =
    lastAdRewardMs > 0
      ? Math.max(
          0,
          lastAdRewardMs +
            AD_COOLDOWN_MS -
            nowMs
        )
      : 0;

  const boostStartedMs =
    getTimestampMilliseconds(
      data.adBoostStartedAt
    );

  const boostEndsMs =
    getTimestampMilliseconds(
      data.adBoostEndsAt
    );

  const adBoostActive =
    boostStartedMs > 0 &&
    boostEndsMs > nowMs;

  const adBoostRemainingMs =
    adBoostActive
      ? Math.max(
          0,
          boostEndsMs -
            nowMs
        )
      : 0;

  const canWatchAd =
    adsToday < MAX_ADS_PER_DAY &&
    cooldownRemainingMs === 0 &&
    !adBoostActive;

  return {
    adsToday,

    maxAdsPerDay:
      MAX_ADS_PER_DAY,

    cooldownRemainingMs,

    canWatchAd,

    adBoostActive,

    adBoostRemainingMs,

    adBoostStartedAt:
      boostStartedMs > 0
        ? new Date(
            boostStartedMs
          )
        : null,

    adBoostEndsAt:
      boostEndsMs > 0
        ? new Date(
            boostEndsMs
          )
        : null,
  };
}

// ============================================================
// ⛏️ GET VALID MINING HASH RATE
// ============================================================

function getMiningHashRate(
  data,
  fallbackHashRate
) {
  const stored =
    getSafePositiveNumber(
      data.miningHashRate,
      0
    );

  const safeFallback =
    Math.min(
      MAX_DAILY_HASH_RATE,
      Math.max(
        DAILY_HASH_RATE_START,
        getSafePositiveNumber(
          fallbackHashRate,
          DAILY_HASH_RATE_START
        )
      )
    );

  if (
    stored > MAX_DAILY_HASH_RATE
  ) {
    return safeFallback;
  }

  if (
    stored < DAILY_HASH_RATE_START
  ) {
    return safeFallback;
  }

  return stored;
}

// ============================================================
// 📺 GET AD BOOST HISTORY
// ============================================================

async function getAdBoostHistory(
  uid,
  miningStartMs,
  miningEndMs,
  transaction = null
) {
  if (
    !miningStartMs ||
    !miningEndMs ||
    miningEndMs <= miningStartMs
  ) {
    return [];
  }

  const historyCollection =
    getHistoryCollection(uid);

  const query =
    historyCollection
      .where(
        "type",
        "==",
        "ad_reward"
      );

  let snapshot;

  if (transaction) {
    snapshot =
      await transaction.get(
        query
      );
  } else {
    snapshot =
      await query.get();
  }

  const boosts = [];

  snapshot.forEach(
    (doc) => {
      const data =
        doc.data() || {};

      const boostStartedMs =
        getTimestampMilliseconds(
          data.boostStartedAt
        );

      const boostEndsMs =
        getTimestampMilliseconds(
          data.boostEndsAt
        );

      if (
        boostStartedMs <= 0 ||
        boostEndsMs <= boostStartedMs
      ) {
        return;
      }

      if (
        boostEndsMs <= miningStartMs ||
        boostStartedMs >= miningEndMs
      ) {
        return;
      }

      boosts.push({
        boostStartedMs,
        boostEndsMs,
      });
    }
  );

  return boosts;
}

// ============================================================
// ⚡ CALCULATE AD BOOST MILLISECONDS
// ============================================================

function calculateAdBoostMilliseconds(
  boosts,
  miningStartMs,
  miningEndMs
) {
  let totalMs = 0;

  for (
    const boost of boosts
  ) {
    const overlapStart =
      Math.max(
        miningStartMs,
        boost.boostStartedMs
      );

    const overlapEnd =
      Math.min(
        miningEndMs,
        boost.boostEndsMs
      );

    if (
      overlapEnd > overlapStart
    ) {
      totalMs +=
        overlapEnd -
        overlapStart;
    }
  }

  return Math.max(
    0,
    totalMs
  );
}

// ============================================================
// 🏆 ACHIEVEMENT REFERENCES
// ============================================================

function getAchievementCollection(
  uid
) {
  return getUserRef(uid)
    .collection(
      "achievements"
    );
}

// ============================================================
// 🏆 READ ACHIEVEMENT DATA
// ============================================================

async function getAchievementData(
  transaction,
  uid,
  achievementId
) {
  const ref =
    getAchievementCollection(uid)
      .doc(achievementId);

  const snapshot =
    await transaction.get(
      ref
    );

  return {
    ref,
    data:
      snapshot.exists
        ? snapshot.data() || {}
        : {},
  };
}

// ============================================================
// 🏆 BUILD ACHIEVEMENT UPDATE
// ============================================================

function buildAchievementUpdate(
  achievementId,
  target,
  reward,
  progress,
  existingData,
  now
) {
  const oldProgress =
    Math.max(
      0,
      Math.floor(
        getSafeNumber(
          existingData.progress,
          0
        )
      )
    );

  const safeTarget =
    Math.max(
      0,
      Math.floor(
        getSafeNumber(
          target,
          0
        )
      )
    );

  const safeProgress =
    Math.min(
      safeTarget,
      Math.max(
        oldProgress,
        Math.floor(
          getSafeNumber(
            progress,
            0
          )
        )
      )
    );

  const alreadyUnlocked =
    existingData.unlocked === true;

  const unlocked =
    alreadyUnlocked ||
    (
      safeTarget > 0 &&
      safeProgress >= safeTarget
    );

  const update = {
    achievementId,
    progress: safeProgress,
    target: safeTarget,
    reward,
    unlocked,
    rewardClaimed:
      existingData.rewardClaimed === true,
    updatedAt: now,
  };

  if (
    unlocked &&
    !alreadyUnlocked &&
    !existingData.unlockedAt
  ) {
    update.unlockedAt = now;
  }

  return update;
}

// ============================================================
// 🏆 UPDATE MINING ACHIEVEMENTS
// ============================================================

async function updateMiningAchievements(
  transaction,
  uid,
  collected,
  startedMining,
  now
) {
  const firstPaw =
    await getAchievementData(
      transaction,
      uid,
      "first_paw"
    );

  const littleMiner =
    await getAchievementData(
      transaction,
      uid,
      "little_miner"
    );

  const stlHunter =
    await getAchievementData(
      transaction,
      uid,
      "stl_hunter"
    );

  if (startedMining) {
    const update =
      buildAchievementUpdate(
        "first_paw",
        1,
        2,
        1,
        firstPaw.data,
        now
      );

    transaction.set(
      firstPaw.ref,
      update,
      {
        merge: true,
      }
    );
  }

  if (collected > 0) {
    const oldLittleProgress =
      Math.max(
        0,
        getSafeNumber(
          littleMiner.data.progress,
          0
        )
      );

    const newLittleProgress =
      oldLittleProgress +
      collected;

    const littleUpdate =
      buildAchievementUpdate(
        "little_miner",
        10,
        5,
        Math.floor(
          newLittleProgress
        ),
        littleMiner.data,
        now
      );

    transaction.set(
      littleMiner.ref,
      littleUpdate,
      {
        merge: true,
      }
    );

    const oldHunterProgress =
      Math.max(
        0,
        getSafeNumber(
          stlHunter.data.progress,
          0
        )
      );

    const newHunterProgress =
      oldHunterProgress +
      collected;

    const hunterUpdate =
      buildAchievementUpdate(
        "stl_hunter",
        100,
        10,
        Math.floor(
          newHunterProgress
        ),
        stlHunter.data,
        now
      );

    transaction.set(
      stlHunter.ref,
      hunterUpdate,
      {
        merge: true,
      }
    );
  }
}

// ============================================================
// 🐱 GET MINING STATUS
// ============================================================

const getMiningStatus =
  onCall(
    {
      region: "us-central1",
    },
    async (request) => {
      try {
        if (!request.auth) {
          throw new HttpsError(
            "unauthenticated",
            "🐱 Kirjaudu sisään jatkaaksesi Stella Miningia."
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
            ? snapshot.data() || {}
            : {};

        const now =
          new Date();

        const nowMs =
          now.getTime();

        const today =
          getUtcDateString();

        const dailyStatus =
          getDailyStatus(
            data,
            today
          );

        const hashRate =
          dailyStatus.dailyHashRate;

        const miningHashRate =
          getMiningHashRate(
            data,
            hashRate
          );

        const miningBalance =
          getSafeNonNegativeNumber(
            data.miningBalance,
            0
          );

        const miningStatus =
          calculateMiningStatus(
            {
              ...data,
              hashRate:
                miningHashRate,
            },
            now
          );

        const miningStartedAt =
          getMiningStartTime(data);

        const miningEndsAt =
          getMiningEndTime(data);

        const adStatus =
          getAdStatus(
            data,
            nowMs,
            today
          );

        let unclaimedMining =
          Math.max(
            0,
            getSafeNumber(
              miningStatus.minedAmount,
              0
            )
          );

        let adBoostMining = 0;

        if (
          miningStartedAt &&
          miningEndsAt
        ) {
          const miningStartMs =
            miningStartedAt.getTime();

          const miningEndMs =
            Math.min(
              miningEndsAt.getTime(),
              nowMs
            );

          if (
            miningEndMs >
            miningStartMs
          ) {
            const boosts =
              await getAdBoostHistory(
                uid,
                miningStartMs,
                miningEndMs
              );

            const boostMilliseconds =
              calculateAdBoostMilliseconds(
                boosts,
                miningStartMs,
                miningEndMs
              );

            adBoostMining =
              Math.max(
                0,
                getSafeNumber(
                  calculateMining(
                    AD_HASH_RATE_BONUS,
                    boostMilliseconds
                  ),
                  0
                )
              );

            unclaimedMining =
              Math.max(
                0,
                unclaimedMining +
                  adBoostMining
              );
          }
        }

        const estimatedTotal =
          miningBalance +
          unclaimedMining;

        const effectiveHashRate =
          adStatus.adBoostActive
            ? hashRate +
                AD_HASH_RATE_BONUS
            : hashRate;

        const miningPerHour =
          effectiveHashRate *
          MINING_PER_HASH_PER_HOUR;

        const activeMiningPerHour =
          miningHashRate *
          MINING_PER_HASH_PER_HOUR;

        return {
          success: true,

          message:
            miningStatus.miningActive
              ? "🐱⛏️ Stella louhii STL:ää!"
              : miningStatus.miningFinished
                  ? "🐱✨ Louhinta on valmis kerättäväksi!"
                  : "🐱 Stella odottaa seuraavaa louhintaa.",

          hashRate,

          miningHashRate,

          miningBalance,

          unclaimedMining,

          adBoostMining,

          estimatedTotal,

          miningActive:
            miningStatus.miningActive === true,

          miningFinished:
            miningStatus.miningFinished === true,

          miningRemainingMs:
            Math.max(
              0,
              getSafeNumber(
                miningStatus.miningRemainingMs,
                0
              )
            ),

          elapsedMs:
            Math.max(
              0,
              getSafeNumber(
                miningStatus.elapsedMs,
                0
              )
            ),

          miningDurationMs:
            MINING_DURATION_MS,

          miningStartedAt:
            miningStartedAt
              ? miningStartedAt.toISOString()
              : null,

          miningEndsAt:
            miningEndsAt
              ? miningEndsAt.toISOString()
              : null,

          miningPerHour,

          miningPerMinute:
            miningPerHour / 60,

          miningPerSecond:
            miningPerHour / 3600,

          activeMiningPerHour,

          dailyClaimed:
            dailyStatus.dailyClaimed,

          streak:
            dailyStatus.streak,

          dailyStreak:
            dailyStatus.streak,

          dailyHashRate:
            dailyStatus.dailyHashRate,

          dailyHashRateBonus:
            dailyStatus.dailyHashRate,

          adsToday:
            adStatus.adsToday,

          maxAdsPerDay:
            adStatus.maxAdsPerDay,

          adHashRateBonus:
            AD_HASH_RATE_BONUS,

          adBoostDurationMs:
            AD_BOOST_DURATION_MS,

          adBoostActive:
            adStatus.adBoostActive,

          adBoostRemainingMs:
            adStatus.adBoostRemainingMs,

          adBoostStartedAt:
            adStatus.adBoostStartedAt
              ? adStatus.adBoostStartedAt.toISOString()
              : null,

          adBoostEndsAt:
            adStatus.adBoostEndsAt
              ? adStatus.adBoostEndsAt.toISOString()
              : null,

          canWatchAd:
            adStatus.canWatchAd,

          cooldownRemainingMs:
            adStatus.cooldownRemainingMs,

          effectiveHashRate,
        };
      } catch (error) {
        console.error(
          "getMiningStatus error:",
          error
        );

        if (
          error instanceof HttpsError
        ) {
          throw error;
        }

        throw new HttpsError(
          "internal",
          "Mining Status -tietojen lataaminen epäonnistui."
        );
      }
    }
  );

// ============================================================
// ⛏️ CLAIM / START STELLA MINING
// ============================================================

const claimMining =
  onCall(
    {
      region: "us-central1",

      // AdMob SSV voi saapua hitaasti.
      // 120 s antaa 90 s SSV-odotukselle
      // riittävän turvamarginaalin.
      timeoutSeconds: 120,
    },
    async (request) => {
      try {
        if (!request.auth) {
          throw new HttpsError(
            "unauthenticated",
            "🐱 Kirjaudu sisään aloittaaksesi Stella Miningin."
          );
        }

        const uid =
          request.auth.uid;

        const userRef =
          getUserRef(uid);

        const now =
          new Date();

        const nowMs =
          now.getTime();

        const today =
          getUtcDateString();

        // ======================================================
        // 🔐 ODOTA ADMOB SSV -VAHVISTUSTA
        // ======================================================

        const verifiedReward =
          await getVerifiedMiningStartReward(
            uid
          );

        const verifiedRewardRef =
          getAdMobRewardRef(
            verifiedReward.transactionId
          );

        if (!verifiedRewardRef) {
          throw new HttpsError(
            "failed-precondition",
            "🐱 AdMob-tapahtuman tunnistaminen epäonnistui."
          );
        }

        return await db.runTransaction(
          async (transaction) => {
            const snapshot =
              await transaction.get(
                userRef
              );

            const rewardSnapshot =
              await transaction.get(
                verifiedRewardRef
              );

            const rewardData =
              validateVerifiedRewardDocument(
                rewardSnapshot,
                uid,
                "mining_start",
                "miningStartClaimed"
              );

            const data =
              snapshot.exists
                ? snapshot.data() || {}
                : {};

            const currentDailyStreak =
              getDailyStreak(data);

            const existingMiningHashRate =
              getMiningHashRate(
                data,
                calculateDailyHashRate(
                  currentDailyStreak > 0
                    ? currentDailyStreak
                    : 1
                )
              );

            const existingMiningStatus =
              calculateMiningStatus(
                {
                  ...data,
                  hashRate:
                    existingMiningHashRate,
                },
                now
              );

            // ==================================================
            // ⚠️ JOS MINING ON JO KÄYNNISSÄ
            // ==================================================

            if (
              existingMiningStatus.miningActive
            ) {
              transaction.set(
                verifiedRewardRef,
                {
                  miningClaimed:
                    true,

                  miningClaimedAt:
                    FieldValue.serverTimestamp(),

                  miningStartClaimed:
                    true,

                  miningStartClaimedAt:
                    FieldValue.serverTimestamp(),

                  miningStartClaimedBy:
                    uid,

                  miningStartAlreadyActive:
                    true,
                },
                {
                  merge: true,
                }
              );

              return {
                success: true,

                started: false,

                collected: 0,

                miningActive: true,

                hashRate:
                  calculateDailyHashRate(
                    currentDailyStreak > 0
                      ? currentDailyStreak
                      : 1
                  ),

                miningHashRate:
                  existingMiningHashRate,

                dailyHashRate:
                  calculateDailyHashRate(
                    currentDailyStreak > 0
                      ? currentDailyStreak
                      : 1
                  ),

                dailyStreak:
                  currentDailyStreak,

                streak:
                  currentDailyStreak,

                unclaimedMining:
                  Math.max(
                    0,
                    getSafeNumber(
                      existingMiningStatus.minedAmount,
                      0
                    )
                  ),

                miningRemainingMs:
                  Math.max(
                    0,
                    getSafeNumber(
                      existingMiningStatus.miningRemainingMs,
                      0
                    )
                  ),

                adRewardTransactionId:
                  verifiedReward.transactionId,

                message:
                  "🐱⛏️ Stella louhii jo STL:ää!",
              };
            }

            const dailyClaim =
              calculateNextDailyClaim(
                data,
                today
              );

            const dailyHashRate =
              dailyClaim.dailyHashRate;

            const dailyStreak =
              dailyClaim.streak;

            const oldBalance =
              getSafeNonNegativeNumber(
                data.miningBalance,
                0
              );

            const previousMiningHashRate =
              getMiningHashRate(
                data,
                dailyHashRate
              );

            const miningStatus =
              calculateMiningStatus(
                {
                  ...data,
                  hashRate:
                    previousMiningHashRate,
                },
                now
              );

            const previousStart =
              getMiningStartTime(data);

            const previousEnd =
              getMiningEndTime(data);

            let newBalance =
              oldBalance;

            let collected = 0;

            let completedPreviousCycle =
              false;

            let previousAdBoostMining = 0;

            if (
              previousStart &&
              previousEnd &&
              previousEnd.getTime() <=
                nowMs
            ) {
              const previousStartMs =
                previousStart.getTime();

              const previousEndMs =
                previousEnd.getTime();

              const previousDuration =
                Math.max(
                  0,
                  previousEndMs -
                    previousStartMs
                );

              const baseCollected =
                Math.max(
                  0,
                  getSafeNumber(
                    calculateMining(
                      previousMiningHashRate,
                      previousDuration
                    ),
                    0
                  )
                );

              const boosts =
                await getAdBoostHistory(
                  uid,
                  previousStartMs,
                  previousEndMs,
                  transaction
                );

              const boostMilliseconds =
                calculateAdBoostMilliseconds(
                  boosts,
                  previousStartMs,
                  previousEndMs
                );

              previousAdBoostMining =
                Math.max(
                  0,
                  getSafeNumber(
                    calculateMining(
                      AD_HASH_RATE_BONUS,
                      boostMilliseconds
                    ),
                    0
                  )
                );

              collected =
                Math.max(
                  0,
                  baseCollected +
                    previousAdBoostMining
                );

              if (
                collected > 0
              ) {
                newBalance =
                  oldBalance +
                  collected;

                completedPreviousCycle =
                  true;
              }
            }

            await updateMiningAchievements(
              transaction,
              uid,
              collected,
              true,
              now
            );

            const newMiningStartedAt =
              now;

            const newMiningEndsAt =
              new Date(
                nowMs +
                  MINING_DURATION_MS
              );

            const newMiningHashRate =
              dailyHashRate;

            const userUpdate = {
              hashRate:
                dailyHashRate,

              dailyHashRate,

              dailyStreak,

              streak:
                dailyStreak,

              lastDailyDate:
                dailyClaim.claimedToday
                  ? (
                      typeof data.lastDailyDate === "string"
                        ? data.lastDailyDate
                        : today
                    )
                  : today,

              miningHashRate:
                newMiningHashRate,

              miningBalance:
                newBalance,

              miningStartedAt:
                newMiningStartedAt,

              miningEndsAt:
                newMiningEndsAt,

              updatedAt:
                FieldValue.serverTimestamp(),
            };

            transaction.set(
              userRef,
              userUpdate,
              {
                merge: true,
              }
            );

            // ==================================================
            // 🔐 KULUTA ADMOB MINING START -PALKKIO
            // ==================================================

            transaction.set(
              verifiedRewardRef,
              {
                miningClaimed:
                  true,

                miningClaimedAt:
                  FieldValue.serverTimestamp(),

                miningStartClaimed:
                  true,

                miningStartClaimedAt:
                  FieldValue.serverTimestamp(),

                miningStartClaimedBy:
                  uid,
              },
              {
                merge: true,
              }
            );

            if (
              !dailyClaim.claimedToday
            ) {
              const dailyHistoryRef =
                getHistoryCollection(uid)
                  .doc();

              transaction.set(
                dailyHistoryRef,
                {
                  type:
                    "dailyHashRate",

                  title:
                    "Stella Daily Hash Rate 🐱✨",

                  amount:
                    dailyHashRate,

                  hashRate:
                    dailyHashRate,

                  dailyHashRate,

                  hashRateBefore:
                    getSafeNonNegativeNumber(
                      data.hashRate,
                      0
                    ),

                  hashRateAfter:
                    dailyHashRate,

                  dailyStreak,

                  streak:
                    dailyStreak,

                  createdAt:
                    FieldValue.serverTimestamp(),
                }
              );
            }

            if (
              completedPreviousCycle
            ) {
              const completeHistoryRef =
                getHistoryCollection(uid)
                  .doc();

              transaction.set(
                completeHistoryRef,
                {
                  type:
                    "mining_reward",

                  title:
                    "Stella Mining Complete 🐱⛏️✨",

                  amount:
                    collected,

                  balanceAfter:
                    newBalance,

                  hashRate:
                    previousMiningHashRate,

                  baseMining:
                    Math.max(
                      0,
                      getSafeNumber(
                        calculateMining(
                          previousMiningHashRate,
                          Math.max(
                            0,
                            previousEnd.getTime() -
                              previousStart.getTime()
                          )
                        ),
                        0
                      )
                    ),

                  adBoostMining:
                    previousAdBoostMining,

                  createdAt:
                    FieldValue.serverTimestamp(),
                }
              );
            }

            const startHistoryRef =
              getHistoryCollection(uid)
                .doc();

            transaction.set(
              startHistoryRef,
              {
                type:
                  "mining",

                title:
                  "Stella Mining Started 🐱⛏️",

                amount:
                  0,

                hashRate:
                  newMiningHashRate,

                dailyHashRate,

                dailyStreak,

                miningDurationMs:
                  MINING_DURATION_MS,

                adRewardTransactionId:
                  verifiedReward.transactionId,

                rewardPurpose:
                  "mining_start",

                createdAt:
                  FieldValue.serverTimestamp(),
              }
            );

            const boostStartedMs =
              getTimestampMilliseconds(
                data.adBoostStartedAt
              );

            const boostEndsMs =
              getTimestampMilliseconds(
                data.adBoostEndsAt
              );

            const adBoostActive =
              boostStartedMs > 0 &&
              boostEndsMs > nowMs;

            const adBoostRemainingMs =
              adBoostActive
                ? Math.max(
                    0,
                    boostEndsMs -
                      nowMs
                  )
                : 0;

            const effectiveHashRate =
              adBoostActive
                ? dailyHashRate +
                    AD_HASH_RATE_BONUS
                : dailyHashRate;

            const dailyMessage =
              dailyClaim.claimedToday
                ? "🐱⛏️ Stella jatkaa tämän päivän louhintaa!"
                : `🐱✨ Stella sai päivän ${dailyStreak} Daily Hash Raten: ${dailyHashRate.toFixed(4)} HR!`;

            return {
              success: true,

              started: true,

              miningActive: true,

              collected,

              completedPreviousCycle,

              miningBalance:
                newBalance,

              hashRate:
                dailyHashRate,

              dailyHashRate,

              dailyHashRateBonus:
                dailyHashRate,

              dailyStreak,

              streak:
                dailyStreak,

              miningHashRate:
                newMiningHashRate,

              miningDurationMs:
                MINING_DURATION_MS,

              miningRemainingMs:
                MINING_DURATION_MS,

              miningStartedAt:
                newMiningStartedAt.toISOString(),

              miningEndsAt:
                newMiningEndsAt.toISOString(),

              adBoostActive,

              adBoostRemainingMs,

              adHashRateBonus:
                AD_HASH_RATE_BONUS,

              effectiveHashRate,

              adRewardTransactionId:
                verifiedReward.transactionId,

              message:
                completedPreviousCycle
                  ? `🐱✨ Stella keräsi STL:t ja aloitti uuden louhinnan! ${dailyMessage}`
                  : dailyMessage,
            };
          }
        );
      } catch (error) {
        console.error(
          "claimMining error:",
          error
        );

        if (
          error instanceof HttpsError
        ) {
          throw error;
        }

        throw new HttpsError(
          "internal",
          "🐱 Stella Miningin käynnistäminen epäonnistui."
        );
      }
    }
  );

// ============================================================
// ⚡ POWER BOOST
// ============================================================
//
// Mainos näytetään Flutterissa.
//
// AdMob SSV
//      ↓
// admobRewards/{transactionId}
//      ↓
// powerBoost()
//      ↓
// 4 h Power Boost
//
// ============================================================

const powerBoost =
  onCall(
    {
      region: "us-central1",

      // ======================================================
      // ⏱️ ADMOB SSV TURVAMARGINAALI
      // ======================================================
      //
      // SSV voi saapua noin 60 sekunnin kohdalla.
      //
      // Sisäinen SSV-odotus = 90 s
      // Cloud Function timeout = 120 s
      //
      // Näin Cloud Run ei katkaise requestia ennen
      // kuin meidän SSV-odotus päättyy.
      //
      // ======================================================

      timeoutSeconds: 120,
    },
    async (request) => {
      try {
        // ======================================================
        // 🔐 AUTHENTICATION
        // ======================================================

        if (!request.auth) {
          throw new HttpsError(
            "unauthenticated",
            "🐱 Kirjaudu sisään käyttääksesi Power Boostia."
          );
        }

        const uid =
          request.auth.uid;

        const userRef =
          getUserRef(uid);

        const now =
          new Date();

        const nowMs =
          now.getTime();

        const today =
          getUtcDateString();

        // ======================================================
        // 🔐 ODOTA ADMOB SSV -VAHVISTUSTA
        // ======================================================

        const verifiedReward =
          await getVerifiedPowerBoostReward(
            uid
          );

        const verifiedRewardRef =
          getAdMobRewardRef(
            verifiedReward.transactionId
          );

        if (!verifiedRewardRef) {
          throw new HttpsError(
            "failed-precondition",
            "🐱 Power Boost -AdMob-tapahtuman tunnistaminen epäonnistui."
          );
        }

        // ======================================================
        // 🔥 FIRESTORE TRANSACTION
        // ======================================================

        return await db.runTransaction(
          async (transaction) => {
            // ==================================================
            // 👤 USER
            // ==================================================

            const userSnapshot =
              await transaction.get(
                userRef
              );

            const rewardSnapshot =
              await transaction.get(
                verifiedRewardRef
              );

            const rewardData =
              rewardSnapshot.exists
                ? rewardSnapshot.data() || {}
                : {};

            const userData =
              userSnapshot.exists
                ? userSnapshot.data() || {}
                : {};

            // ==================================================
            // 🛡️ IDEMPOTENCY
            // ==================================================

            if (
              rewardSnapshot.exists &&
              rewardData.uid === uid &&
              rewardData.rewardType === "admob" &&
              rewardData.rewardPurpose === "power_boost" &&
              rewardData.powerBoostClaimed === true &&
              rewardData.powerBoostClaimedBy === uid &&
              rewardData.powerBoostTransactionId ===
                verifiedReward.transactionId
            ) {
              const currentAdStatus =
                getAdStatus(
                  userData,
                  nowMs,
                  today
                );

              if (
                currentAdStatus.adBoostActive
              ) {
                const remainingMs =
                  currentAdStatus.adBoostRemainingMs;

                const dailyStatus =
                  getDailyStatus(
                    userData,
                    today
                  );

                const baseHashRate =
                  getMiningHashRate(
                    userData,
                    dailyStatus.dailyHashRate
                  );

                const effectiveHashRate =
                  baseHashRate +
                  AD_HASH_RATE_BONUS;

                return {
                  success: true,

                  boostActive: true,

                  active: true,

                  alreadyActivated: true,

                  adsToday:
                    currentAdStatus.adsToday,

                  maxAdsPerDay:
                    MAX_ADS_PER_DAY,

                  adHashRateBonus:
                    AD_HASH_RATE_BONUS,

                  boostRemainingMs:
                    remainingMs,

                  remainingBoostMs:
                    remainingMs,

                  adBoostDurationMs:
                    AD_BOOST_DURATION_MS,

                  adBoostStartedAt:
                    currentAdStatus.adBoostStartedAt
                      ? currentAdStatus.adBoostStartedAt.toISOString()
                      : null,

                  adBoostEndsAt:
                    currentAdStatus.adBoostEndsAt
                      ? currentAdStatus.adBoostEndsAt.toISOString()
                      : null,

                  effectiveHashRate,

                  transactionId:
                    verifiedReward.transactionId,

                  message:
                    "🐱⚡ Stella Power Boost on jo aktiivinen!",
                };
              }
            }

            // ==================================================
            // 🔐 VALIDATE VERIFIED REWARD
            // ==================================================

            const validatedRewardData =
              validateVerifiedRewardDocument(
                rewardSnapshot,
                uid,
                "power_boost",
                "powerBoostClaimed"
              );

            // ==================================================
            // 📊 CURRENT AD STATUS
            // ==================================================

            const currentAdStatus =
              getAdStatus(
                userData,
                nowMs,
                today
              );

            // ==================================================
            // 🚫 MAX DAILY ADS
            // ==================================================

            if (
              currentAdStatus.adsToday >=
              MAX_ADS_PER_DAY
            ) {
              throw new HttpsError(
                "resource-exhausted",
                "🐱 Päivän Power Boost -mainosraja on täynnä."
              );
            }

            // ==================================================
            // 🚫 EXISTING ACTIVE BOOST
            // ==================================================

            if (
              currentAdStatus.adBoostActive
            ) {
              throw new HttpsError(
                "failed-precondition",
                "🐱 Power Boost on jo aktiivinen."
              );
            }

            // ==================================================
            // 🚫 COOLDOWN
            // ==================================================

            if (
              currentAdStatus.cooldownRemainingMs >
              0
            ) {
              throw new HttpsError(
                "failed-precondition",
                "🐱 Power Boost ei ole vielä valmis käytettäväksi uudelleen."
              );
            }

            // ==================================================
            // 🕒 BOOST TIME
            // ==================================================

            const boostStartedAt =
              now;

            const boostEndsAt =
              new Date(
                nowMs +
                  AD_BOOST_DURATION_MS
              );

            // ==================================================
            // 📊 NEW DAILY AD COUNT
            // ==================================================

            const storedAdDate =
              typeof userData.lastAdDate === "string"
                ? userData.lastAdDate
                : "";

            const currentAdsToday =
              storedAdDate === today
                ? Math.max(
                    0,
                    Math.floor(
                      getSafeNumber(
                        userData.adsToday,
                        0
                      )
                    )
                  )
                : 0;

            const newAdsToday =
              currentAdsToday + 1;

            // ==================================================
            // 👤 USER UPDATE
            // ==================================================

            transaction.set(
              userRef,
              {
                adsToday:
                  newAdsToday,

                lastAdDate:
                  today,

                lastAdRewardAt:
                  FieldValue.serverTimestamp(),

                adBoostStartedAt:
                  boostStartedAt,

                adBoostEndsAt:
                  boostEndsAt,

                powerBoostTransactionId:
                  verifiedReward.transactionId,

                updatedAt:
                  FieldValue.serverTimestamp(),
              },
              {
                merge: true,
              }
            );

            // ==================================================
            // 🔐 CONSUME ADMOB REWARD
            // ==================================================

            transaction.set(
              verifiedRewardRef,
              {
                powerBoostClaimed:
                  true,

                powerBoostClaimedAt:
                  FieldValue.serverTimestamp(),

                powerBoostClaimedBy:
                  uid,

                powerBoostTransactionId:
                  verifiedReward.transactionId,
              },
              {
                merge: true,
              }
            );

            // ==================================================
            // 📜 POWER BOOST HISTORY
            // ==================================================

            const historyRef =
              getHistoryCollection(uid)
                .doc();

            transaction.set(
              historyRef,
              {
                type:
                  "ad_reward",

                title:
                  "Stella Power Boost 🐱⚡",

                amount:
                  0,

                adRewardTransactionId:
                  validatedRewardData.transactionId ||
                  verifiedReward.transactionId,

                rewardPurpose:
                  "power_boost",

                adHashRateBonus:
                  AD_HASH_RATE_BONUS,

                boostStartedAt:
                  boostStartedAt,

                boostEndsAt:
                  boostEndsAt,

                boostDurationMs:
                  AD_BOOST_DURATION_MS,

                adsToday:
                  newAdsToday,

                maxAdsPerDay:
                  MAX_ADS_PER_DAY,

                createdAt:
                  FieldValue.serverTimestamp(),
              }
            );

            // ==================================================
            // 📊 EFFECTIVE HASH RATE
            // ==================================================

            const dailyStatus =
              getDailyStatus(
                userData,
                today
              );

            const baseHashRate =
              getMiningHashRate(
                userData,
                dailyStatus.dailyHashRate
              );

            const effectiveHashRate =
              baseHashRate +
              AD_HASH_RATE_BONUS;

            // ==================================================
            // ✅ RESPONSE
            // ==================================================

            return {
              success: true,

              boostActive: true,

              active: true,

              alreadyActivated: false,

              adsToday:
                newAdsToday,

              maxAdsPerDay:
                MAX_ADS_PER_DAY,

              adHashRateBonus:
                AD_HASH_RATE_BONUS,

              boostRemainingMs:
                AD_BOOST_DURATION_MS,

              remainingBoostMs:
                AD_BOOST_DURATION_MS,

              adBoostDurationMs:
                AD_BOOST_DURATION_MS,

              adBoostStartedAt:
                boostStartedAt.toISOString(),

              adBoostEndsAt:
                boostEndsAt.toISOString(),

              effectiveHashRate,

              transactionId:
                verifiedReward.transactionId,

              message:
                "🐱⚡ Stella Power Boost on aktiivinen 4 tunnin ajan!",
            };
          }
        );
      } catch (error) {
        console.error(
          "powerBoost error:",
          error
        );

        if (
          error instanceof HttpsError
        ) {
          throw error;
        }

        throw new HttpsError(
          "internal",
          "🐱 Power Boostin aktivointi epäonnistui."
        );
      }
    }
  );

// ============================================================
// 📦 EXPORTS
// ============================================================

module.exports = {
  getMiningStatus,
  claimMining,
  powerBoost,
};