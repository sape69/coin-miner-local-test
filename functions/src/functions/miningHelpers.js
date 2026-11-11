"use strict";

// ============================================================
// 🐱 STELLURIINI - MINING HELPERS
// ============================================================
//
// Yhteiset apufunktiot:
// - Numeric helpers
// - Mining daily streak
// - AdMob error mapping
// - Timestamp conversion
// - Ad status
// - Boost history
// - Mining cycle calculation
// - Current unclaimed mining
//
// POWER BOOST:
// FREE          = 4 hours
// PREMIUM       = 4 hours
// PREMIUM_PLUS  = 24 hours
//
// ============================================================

function createMiningHelpers({
  HttpsError,

  nextDailyClaim,
  nextDailyHashRate,
  nextDailyStreak,

  getHistoryCollection,

  miningWindow,
  historicalHashRate,
  getMiningHalvingMultiplier,

  calculateMining,

  AD_COOLDOWN_MS,
  MAX_ADS_PER_DAY,
  MINING_DURATION_MS,
  AD_HASH_RATE_BONUS,
}) {
  // ==========================================================
  // VALUE HELPERS
  // ==========================================================

  function number(value, fallback = 0) {
    const result = Number(value);

    return Number.isFinite(result)
      ? result
      : fallback;
  }

  function nonNegative(value, fallback = 0) {
    const result = Number(value);

    return Number.isFinite(result) && result >= 0
      ? result
      : fallback;
  }

  function positive(value, fallback = 0) {
    const result = Number(value);

    return Number.isFinite(result) && result > 0
      ? result
      : fallback;
  }

  // ==========================================================
  // MINING-SPECIFIC DAILY STREAK
  // ==========================================================

  function miningDailyStreak(data) {
    const source =
      data && typeof data === "object"
        ? data
        : {};

    const value =
      source.miningStreak ??
      source.dailyStreak ??
      source.streak;

    return Math.max(
      0,
      Math.floor(number(value))
    );
  }

  function miningDailyData(data) {
    const source =
      data && typeof data === "object"
        ? data
        : {};

    const lastMiningDate =
      typeof source.lastMiningDate === "string"
        ? source.lastMiningDate
        : typeof source.lastDailyDate === "string"
          ? source.lastDailyDate
          : "";

    return {
      ...source,
      dailyStreak: miningDailyStreak(source),
      streak: miningDailyStreak(source),
      lastDailyDate: lastMiningDate,
    };
  }

  function getMiningDailyClaim(data, today, nowMs) {
    return nextDailyClaim(
      miningDailyData(data),
      today,
      nowMs
    );
  }

  function getNextMiningDailyHashRate(data, today, nowMs) {
    return nextDailyHashRate(
      miningDailyData(data),
      today,
      nowMs
    );
  }

  function getNextMiningDailyStreak(data, today, nowMs) {
    return nextDailyStreak(
      miningDailyData(data),
      today,
      nowMs
    );
  }

  // ==========================================================
  // ADMOB ERROR MAPPING
  // ==========================================================

  function toRewardHttpsError(error, fallbackMessage) {
    if (error instanceof HttpsError) {
      return error;
    }

    const code =
      typeof error?.code === "string"
        ? error.code
        : "";

    switch (code) {
      case "ADMOB_REWARD_NOT_FOUND":
        return new HttpsError(
          "failed-precondition",
          "🐱 AdMob-palkinnon vahvistusta odotetaan. Yritä hetken kuluttua uudelleen."
        );

      case "ADMOB_REWARD_ALREADY_CLAIMED":
        return new HttpsError(
          "already-exists",
          "🐱 Tämä AdMob-palkinto on jo käytetty."
        );

      case "ADMOB_REWARD_EXPIRED":
        return new HttpsError(
          "failed-precondition",
          "🐱 AdMob-palkinto on vanhentunut."
        );

      case "ADMOB_REWARD_NOT_VERIFIED":
        return new HttpsError(
          "failed-precondition",
          "🐱 AdMob-palkintoa ei ole vielä vahvistettu."
        );

      case "ADMOB_TRANSACTION_ID_MISMATCH":
      case "ADMOB_REWARD_UID_MISMATCH":
      case "ADMOB_REWARD_PURPOSE_MISMATCH":
        return new HttpsError(
          "permission-denied",
          "🐱 AdMob-palkinnon tiedot eivät täsmää."
        );

      case "ADMOB_REWARD_TIMESTAMP_MISSING":
      case "ADMOB_REWARD_TIMESTAMP_INVALID":
      case "ADMOB_REWARD_UID_MISSING":
      case "ADMOB_REWARD_PURPOSE_MISSING":
      case "ADMOB_REWARD_TRANSACTION_ID_MISSING":
        return new HttpsError(
          "failed-precondition",
          "🐱 AdMob-palkinnon vahvistustiedot ovat puutteelliset."
        );

      case "ADMOB_INVALID_UID":
      case "ADMOB_INVALID_REWARD_PURPOSE":
      case "ADMOB_INVALID_CLAIM_FIELD":
        return new HttpsError(
          "invalid-argument",
          "🐱 AdMob-palkinnon tiedot ovat virheelliset."
        );

      default:
        return new HttpsError(
          "failed-precondition",
          fallbackMessage
        );
    }
  }

  // ==========================================================
  // TIMESTAMP HELPERS
  // ==========================================================

  function timestampMs(value) {
    if (!value) {
      return 0;
    }

    if (typeof value.toMillis === "function") {
      try {
        const milliseconds = value.toMillis();

        return Number.isFinite(milliseconds)
          ? milliseconds
          : 0;
      } catch (_) {
        return 0;
      }
    }

    if (typeof value.toDate === "function") {
      try {
        const date = value.toDate();

        return date instanceof Date &&
          Number.isFinite(date.getTime())
          ? date.getTime()
          : 0;
      } catch (_) {
        return 0;
      }
    }

    if (value instanceof Date) {
      return Number.isFinite(value.getTime())
        ? value.getTime()
        : 0;
    }

    if (typeof value === "string") {
      const milliseconds = new Date(value).getTime();

      return Number.isFinite(milliseconds)
        ? milliseconds
        : 0;
    }

    if (
      typeof value === "number" &&
      Number.isFinite(value)
    ) {
      return value;
    }

    return 0;
  }

  // ==========================================================
  // POWER BOOST DURATION
  // ==========================================================

  const NORMAL_BOOST_DURATION_MS =
    4 * 60 * 60 * 1000;

  const PREMIUM_PLUS_BOOST_DURATION_MS =
    24 * 60 * 60 * 1000;

  const PREMIUM_PLUS_PRODUCT_ID =
    "stelluriini_premium_plus_monthly";

  const VALID_PLAY_SUBSCRIPTION_STATES = new Set([
    "SUBSCRIPTION_STATE_ACTIVE",
    "SUBSCRIPTION_STATE_IN_GRACE_PERIOD",
  ]);

  function isActivePremiumPlus(data, nowMs) {
    if (
      !data ||
      data.premium !== true ||
      data.premiumVerified !== true ||
      data.premiumTier !== "premium_plus" ||
      data.premiumProductId !== PREMIUM_PLUS_PRODUCT_ID ||
      !VALID_PLAY_SUBSCRIPTION_STATES.has(
        data.premiumSubscriptionState
      )
    ) {
      return false;
    }

    const expiryMs = timestampMs(
      data.premiumExpiryTime
    );

    return expiryMs > nowMs;
  }

  function getAllowedBoostDurationMs(data, nowMs) {
    return isActivePremiumPlus(data, nowMs)
      ? PREMIUM_PLUS_BOOST_DURATION_MS
      : NORMAL_BOOST_DURATION_MS;
  }

  // ==========================================================
  // AD STATUS
  // ==========================================================

  function adStatus(data, nowMs, today) {
    const source =
      data && typeof data === "object"
        ? data
        : {};

    const lastDate =
      typeof source.lastAdDate === "string"
        ? source.lastAdDate
        : "";

    const adsToday =
      lastDate === today
        ? Math.max(
            0,
            Math.floor(number(source.adsToday))
          )
        : 0;

    const lastRewardMs =
      timestampMs(source.lastAdRewardAt);

    const cooldownRemainingMs =
      lastRewardMs > 0
        ? Math.max(
            0,
            lastRewardMs +
              AD_COOLDOWN_MS -
              nowMs
          )
        : 0;

    const boostStartMs =
      timestampMs(source.adBoostStartedAt);

    const boostEndMs =
      timestampMs(source.adBoostEndsAt);

    const window = miningWindow(source);

    const active =
      window.valid &&
      nowMs >= window.miningStartMs &&
      nowMs < window.miningEndMs;

    const boostInsideMining =
      active &&
      boostStartMs >= window.miningStartMs &&
      boostStartMs < window.miningEndMs;

    const allowedDurationMs =
      getAllowedBoostDurationMs(
        source,
        nowMs
      );

    const maximumAllowedEndMs =
      boostStartMs > 0
        ? boostStartMs + allowedDurationMs
        : 0;

    const effectiveEnd =
      boostInsideMining &&
      boostEndMs > boostStartMs
        ? Math.min(
            boostEndMs,
            maximumAllowedEndMs,
            window.miningEndMs
          )
        : 0;

    const boostActive =
      active &&
      effectiveEnd > nowMs;

    const remainingMs =
      boostActive
        ? effectiveEnd - nowMs
        : 0;

    return {
      adsToday,

      maxAdsPerDay:
        MAX_ADS_PER_DAY,

      cooldownRemainingMs,

      canWatchAd:
        active &&
        adsToday < MAX_ADS_PER_DAY &&
        cooldownRemainingMs === 0 &&
        !boostActive,

      adBoostActive:
        boostActive,

      adBoostRemainingMs:
        remainingMs,

      adBoostStartedAt:
        boostActive
          ? new Date(boostStartMs)
          : null,

      adBoostEndsAt:
        boostActive
          ? new Date(effectiveEnd)
          : null,
    };
  }

  // ==========================================================
  // BOOST HISTORY
  // ==========================================================

  function maxBoostHistoryEntries() {
    const dayMs = 24 * 60 * 60 * 1000;

    const days = Math.max(
      1,
      Math.ceil(MINING_DURATION_MS / dayMs)
    );

    return Math.max(
      MAX_ADS_PER_DAY,
      (days + 1) * MAX_ADS_PER_DAY + 10
    );
  }

  async function getAdBoostHistory(
    uid,
    startMs,
    endMs,
    transaction = null
  ) {
    if (
      !startMs ||
      !endMs ||
      endMs <= startMs
    ) {
      return [];
    }

    const query =
      getHistoryCollection(uid)
        .where(
          "boostStartedAt",
          ">=",
          new Date(startMs)
        )
        .where(
          "boostStartedAt",
          "<",
          new Date(endMs)
        )
        .orderBy(
          "boostStartedAt",
          "asc"
        )
        .limit(maxBoostHistoryEntries());

    const snapshot =
      transaction
        ? await transaction.get(query)
        : await query.get();

    const boosts = [];

    snapshot.forEach((doc) => {
      const data = doc.data() || {};

      if (
        ![
          "ad_reward",
          "premium_power_boost",
        ].includes(data.type) ||
        data.rewardPurpose !== "power_boost"
      ) {
        return;
      }

      const start =
        timestampMs(data.boostStartedAt);

      const end =
        timestampMs(data.boostEndsAt);

      if (
        start <= 0 ||
        end <= start ||
        start < startMs ||
        start >= endMs ||
        end <= startMs
      ) {
        return;
      }

      boosts.push({
        boostStartedMs:
          Math.max(start, startMs),

        boostEndsMs:
          Math.min(end, endMs),
      });
    });

    return boosts;
  }

  function boostMilliseconds(
    boosts,
    startMs,
    endMs
  ) {
    if (
      !Array.isArray(boosts) ||
      !startMs ||
      !endMs ||
      endMs <= startMs
    ) {
      return 0;
    }

    const intervals =
      boosts
        .map((boost) => {
          const start = Math.max(
            startMs,
            number(boost.boostStartedMs)
          );

          const end = Math.min(
            endMs,
            number(boost.boostEndsMs)
          );

          return end > start
            ? { start, end }
            : null;
        })
        .filter(Boolean)
        .sort((a, b) => a.start - b.start);

    if (!intervals.length) {
      return 0;
    }

    let total = 0;
    let start = intervals[0].start;
    let end = intervals[0].end;

    for (let i = 1; i < intervals.length; i++) {
      const current = intervals[i];

      if (current.start <= end) {
        end = Math.max(end, current.end);
      } else {
        total += end - start;
        start = current.start;
        end = current.end;
      }
    }

    return Math.max(
      0,
      total + end - start
    );
  }

  // ==========================================================
  // MINING CALCULATION
  // ==========================================================

  async function calculateMiningCycle(
    uid,
    startMs,
    endMs,
    hashRate,
    transaction = null,
    halvingMultiplier = 1
  ) {
    if (
      !startMs ||
      !endMs ||
      endMs <= startMs
    ) {
      return {
        baseMining: 0,
        adBoostMining: 0,
        boostMilliseconds: 0,
        totalMining: 0,
      };
    }

    const rate = positive(hashRate);

    const safeHalvingMultiplier =
      positive(halvingMultiplier, 1);

    const duration = endMs - startMs;

    const baseMining =
      rate > 0
        ? Math.max(
            0,
            number(
              calculateMining(
                rate,
                duration,
                safeHalvingMultiplier
              )
            )
          )
        : 0;

    const boosts = await getAdBoostHistory(
      uid,
      startMs,
      endMs,
      transaction
    );

    const boostMs = boostMilliseconds(
      boosts,
      startMs,
      endMs
    );

    const adBoostMining =
      boostMs > 0 && AD_HASH_RATE_BONUS > 0
        ? Math.max(
            0,
            number(
              calculateMining(
                AD_HASH_RATE_BONUS,
                boostMs,
                safeHalvingMultiplier
              )
            )
          )
        : 0;

    return {
      baseMining,
      adBoostMining,
      boostMilliseconds: boostMs,
      totalMining: Math.max(
        0,
        baseMining + adBoostMining
      ),
    };
  }

  // ==========================================================
  // CURRENT UNCLAIMED MINING
  // ==========================================================

  async function currentUnclaimedMining(
    uid,
    data,
    nowMs,
    transaction = null
  ) {
    const window = miningWindow(data);

    if (!window.valid) {
      return {
        unclaimedMining: 0,
        baseMining: 0,
        adBoostMining: 0,
        boostMilliseconds: 0,
      };
    }

    const endMs = Math.min(
      window.miningEndMs,
      nowMs
    );

    if (endMs <= window.miningStartMs) {
      return {
        unclaimedMining: 0,
        baseMining: 0,
        adBoostMining: 0,
        boostMilliseconds: 0,
      };
    }

    const rate = historicalHashRate(data);

    if (rate <= 0) {
      return {
        unclaimedMining: 0,
        baseMining: 0,
        adBoostMining: 0,
        boostMilliseconds: 0,
      };
    }

    const cycle = await calculateMiningCycle(
      uid,
      window.miningStartMs,
      endMs,
      rate,
      transaction,
      getMiningHalvingMultiplier(data)
    );

    return {
      unclaimedMining: cycle.totalMining,
      baseMining: cycle.baseMining,
      adBoostMining: cycle.adBoostMining,
      boostMilliseconds: cycle.boostMilliseconds,
    };
  }

  // ==========================================================
  // PUBLIC HELPERS
  // ==========================================================

  return {
    number,
    nonNegative,
    positive,

    miningDailyStreak,
    miningDailyData,

    getMiningDailyClaim,
    getNextMiningDailyHashRate,
    getNextMiningDailyStreak,

    toRewardHttpsError,

    timestampMs,

    adStatus,

    maxBoostHistoryEntries,
    getAdBoostHistory,
    boostMilliseconds,

    calculateMiningCycle,
    currentUnclaimedMining,
  };
}

module.exports = {
  createMiningHelpers,
};
