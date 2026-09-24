"use strict";

// ============================================================
// 🐱 STELLURIINI - MINING FUNCTIONS
// ============================================================
//
// Stella Mining.
//
// AdMob reward is NOT an STL token reward.
//
// AdMob only authorizes:
// - Mining Start
// - Power Boost
//
// Mining:
// Hash Rate × STL / Hash / Hour × elapsed time.
//
// Power Boost:
// Temporary additional Hash Rate during the active boost.
//
// ============================================================

const {
  onCall,
  HttpsError,
} = require("firebase-functions/v2/https");

const {
  db,
  FieldValue,
} = require("../firebase/firebase");

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

const {
  getUtcDateString,
} = require("../utils/dateUtils");

const {
  getUserRef,
  getHistoryCollection,
  getAdMobRewardRef,
} = require("../utils/userUtils");

const {
  calculateMiningStatus,
  getMiningStartTime,
  getMiningEndTime,
  calculateMining,
} = require("../utils/miningUtils");

const {
  getVerifiedMiningStartReward,
  getVerifiedPowerBoostReward,
  validateVerifiedRewardDocument,
} = require("../services/admobRewardService");

// ============================================================
// HELPERS
// ============================================================

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

// ============================================================
// DAILY HASH RATE
// ============================================================

function dailyHashRate(streak) {
  const day = Math.max(
    1,
    Math.floor(number(streak, 1))
  );

  const effectiveDay = Math.min(
    day,
    DAILY_HASH_RATE_MAX_DAY
  );

  return Math.min(
    MAX_DAILY_HASH_RATE,
    Math.max(
      DAILY_HASH_RATE_START,
      DAILY_HASH_RATE_START +
        (effectiveDay - 1) *
          DAILY_HASH_RATE_STEP
    )
  );
}

function dailyStreak(data) {
  return Math.max(
    0,
    Math.floor(
      number(
        data.dailyStreak ?? data.streak,
        0
      )
    )
  );
}

function nextDailyClaim(data, today) {
  const last =
    typeof data.lastDailyDate === "string"
      ? data.lastDailyDate
      : "";

  const current = dailyStreak(data);

  if (last === today) {
    const streak = Math.max(1, current);

    return {
      claimedToday: true,
      streak,
      dailyHashRate: dailyHashRate(streak),
    };
  }

  const yesterday = new Date(
    `${today}T00:00:00.000Z`
  );

  yesterday.setUTCDate(
    yesterday.getUTCDate() - 1
  );

  const yesterdayString =
    yesterday.toISOString().slice(0, 10);

  const streak =
    last === yesterdayString && current > 0
      ? current + 1
      : 1;

  return {
    claimedToday: false,
    streak,
    dailyHashRate: dailyHashRate(streak),
  };
}

// ============================================================
// MINING WINDOW
// ============================================================

function miningWindow(data) {
  const start = getMiningStartTime(data);
  const end = getMiningEndTime(data);

  const startMs = start?.getTime() || 0;
  const endMs = end?.getTime() || 0;

  const valid =
    startMs > 0 &&
    endMs > startMs;

  return {
    miningStartedAt: valid ? start : null,
    miningEndsAt: valid ? end : null,
    miningStartMs: valid ? startMs : 0,
    miningEndMs: valid ? endMs : 0,
    valid,
  };
}

function miningActive(data, nowMs) {
  const window = miningWindow(data);

  return (
    window.valid &&
    nowMs >= window.miningStartMs &&
    nowMs < window.miningEndMs
  );
}

function miningHashRate(
  data,
  fallback = DAILY_HASH_RATE_START
) {
  const stored = positive(
    data.miningHashRate
  );

  if (
    stored >= DAILY_HASH_RATE_START &&
    stored <= MAX_DAILY_HASH_RATE
  ) {
    return stored;
  }

  const safeFallback = positive(
    fallback,
    DAILY_HASH_RATE_START
  );

  return Math.min(
    MAX_DAILY_HASH_RATE,
    Math.max(
      DAILY_HASH_RATE_START,
      safeFallback
    )
  );
}

function historicalHashRate(data) {
  const rate = positive(
    data.miningHashRate
  );

  return (
    rate >= DAILY_HASH_RATE_START &&
    rate <= MAX_DAILY_HASH_RATE
  )
    ? rate
    : 0;
}

// ============================================================
// AD STATUS
// ============================================================

function adStatus(data, nowMs, today) {
  const lastDate =
    typeof data.lastAdDate === "string"
      ? data.lastAdDate
      : "";

  const adsToday =
    lastDate === today
      ? Math.max(
          0,
          Math.floor(
            number(data.adsToday)
          )
        )
      : 0;

  const lastRewardMs =
    timestampMs(data.lastAdRewardAt);

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
    timestampMs(data.adBoostStartedAt);

  const boostEndMs =
    timestampMs(data.adBoostEndsAt);

  const window = miningWindow(data);

  const active =
    window.valid &&
    nowMs >= window.miningStartMs &&
    nowMs < window.miningEndMs;

  const boostInsideMining =
    active &&
    boostStartMs >= window.miningStartMs &&
    boostStartMs < window.miningEndMs;

  const effectiveEnd =
    boostInsideMining &&
    boostEndMs > boostStartMs
      ? Math.min(
          boostEndMs,
          window.miningEndMs
        )
      : 0;

  const boostActive =
    active &&
    effectiveEnd > nowMs;

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
      boostActive
        ? effectiveEnd - nowMs
        : 0,

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

// ============================================================
// TIMESTAMP
// ============================================================

function timestampMs(value) {
  if (!value) {
    return 0;
  }

  if (
    typeof value.toMillis === "function"
  ) {
    try {
      const milliseconds =
        value.toMillis();

      return Number.isFinite(milliseconds)
        ? milliseconds
        : 0;
    } catch (_) {
      return 0;
    }
  }

  if (
    typeof value.toDate === "function"
  ) {
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
    const milliseconds =
      new Date(value).getTime();

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

// ============================================================
// BOOST HISTORY
// ============================================================

function maxBoostHistoryEntries() {
  const dayMs =
    24 * 60 * 60 * 1000;

  const days = Math.max(
    1,
    Math.ceil(
      MINING_DURATION_MS / dayMs
    )
  );

  return Math.max(
    MAX_ADS_PER_DAY,
    (days + 1) *
      MAX_ADS_PER_DAY +
      10
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
      .limit(
        maxBoostHistoryEntries()
      );

  const snapshot = transaction
    ? await transaction.get(query)
    : await query.get();

  const boosts = [];

  snapshot.forEach((doc) => {
    const data =
      doc.data() || {};

    if (
      data.type !== "ad_reward" ||
      data.rewardPurpose !== "power_boost"
    ) {
      return;
    }

    const start =
      timestampMs(
        data.boostStartedAt
      );

    const end =
      timestampMs(
        data.boostEndsAt
      );

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
        Math.max(
          start,
          startMs
        ),

      boostEndsMs:
        Math.min(
          end,
          endMs
        ),
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
        const start =
          Math.max(
            startMs,
            number(
              boost.boostStartedMs
            )
          );

        const end =
          Math.min(
            endMs,
            number(
              boost.boostEndsMs
            )
          );

        return end > start
          ? { start, end }
          : null;
      })
      .filter(Boolean)
      .sort(
        (a, b) =>
          a.start - b.start
      );

  if (!intervals.length) {
    return 0;
  }

  let total = 0;

  let start =
    intervals[0].start;

  let end =
    intervals[0].end;

  for (
    let i = 1;
    i < intervals.length;
    i++
  ) {
    const current =
      intervals[i];

    if (
      current.start <= end
    ) {
      end = Math.max(
        end,
        current.end
      );
    } else {
      total +=
        end - start;

      start =
        current.start;

      end =
        current.end;
    }
  }

  return Math.max(
    0,
    total + end - start
  );
}

// ============================================================
// MINING CALCULATION
// ============================================================

async function calculateMiningCycle(
  uid,
  startMs,
  endMs,
  hashRate,
  transaction = null
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

  const rate =
    positive(hashRate);

  const duration =
    endMs - startMs;

  const baseMining =
    rate > 0
      ? Math.max(
          0,
          number(
            calculateMining(
              rate,
              duration
            )
          )
        )
      : 0;

  const boosts =
    await getAdBoostHistory(
      uid,
      startMs,
      endMs,
      transaction
    );

  const boostMs =
    boostMilliseconds(
      boosts,
      startMs,
      endMs
    );

  const adBoostMining =
    boostMs > 0 &&
    AD_HASH_RATE_BONUS > 0
      ? Math.max(
          0,
          number(
            calculateMining(
              AD_HASH_RATE_BONUS,
              boostMs
            )
          )
        )
      : 0;

  return {
    baseMining,

    adBoostMining,

    boostMilliseconds:
      boostMs,

    totalMining:
      Math.max(
        0,
        baseMining +
          adBoostMining
      ),
  };
}

async function currentUnclaimedMining(
  uid,
  data,
  nowMs,
  transaction = null
) {
  const window =
    miningWindow(data);

  if (!window.valid) {
    return {
      unclaimedMining: 0,
      baseMining: 0,
      adBoostMining: 0,
      boostMilliseconds: 0,
    };
  }

  const endMs =
    Math.min(
      window.miningEndMs,
      nowMs
    );

  if (
    endMs <=
    window.miningStartMs
  ) {
    return {
      unclaimedMining: 0,
      baseMining: 0,
      adBoostMining: 0,
      boostMilliseconds: 0,
    };
  }

  const rate =
    historicalHashRate(data);

  if (rate <= 0) {
    return {
      unclaimedMining: 0,
      baseMining: 0,
      adBoostMining: 0,
      boostMilliseconds: 0,
    };
  }

  const cycle =
    await calculateMiningCycle(
      uid,
      window.miningStartMs,
      endMs,
      rate,
      transaction
    );

  return {
    unclaimedMining:
      cycle.totalMining,

    baseMining:
      cycle.baseMining,

    adBoostMining:
      cycle.adBoostMining,

    boostMilliseconds:
      cycle.boostMilliseconds,
  };
}

// ============================================================
// ACHIEVEMENTS
// ============================================================

function achievementCollection(uid) {
  return getUserRef(uid)
    .collection("achievements");
}

async function achievementData(
  transaction,
  uid,
  id
) {
  const ref =
    achievementCollection(uid)
      .doc(id);

  const snapshot =
    await transaction.get(ref);

  return {
    ref,

    data:
      snapshot.exists
        ? snapshot.data() || {}
        : {},
  };
}

function achievementUpdate(
  id,
  target,
  reward,
  progress,
  existing,
  now
) {
  const oldProgress =
    Math.max(
      0,
      number(existing.progress)
    );

  const safeTarget =
    Math.max(
      0,
      number(target)
    );

  const safeProgress =
    Math.min(
      safeTarget,
      Math.max(
        oldProgress,
        nonNegative(progress)
      )
    );

  const alreadyUnlocked =
    existing.unlocked === true;

  const unlocked =
    alreadyUnlocked ||
    (
      safeTarget > 0 &&
      safeProgress >= safeTarget
    );

  const update = {
    achievementId: id,
    progress: safeProgress,
    target: safeTarget,
    reward,

    unlocked,

    rewardClaimed:
      existing.rewardClaimed === true,

    updatedAt: now,
  };

  if (
    unlocked &&
    !alreadyUnlocked &&
    !existing.unlockedAt
  ) {
    update.unlockedAt = now;
  }

  return update;
}

async function updateMiningAchievements(
  transaction,
  uid,
  collected,
  started,
  now
) {
  const first =
    await achievementData(
      transaction,
      uid,
      "first_paw"
    );

  const miner =
    await achievementData(
      transaction,
      uid,
      "little_miner"
    );

  const hunter =
    await achievementData(
      transaction,
      uid,
      "stl_hunter"
    );

  if (started) {
    transaction.set(
      first.ref,
      achievementUpdate(
        "first_paw",
        1,
        2,
        1,
        first.data,
        now
      ),
      {
        merge: true,
      }
    );
  }

  if (collected <= 0) {
    return;
  }

  transaction.set(
    miner.ref,
    achievementUpdate(
      "little_miner",
      10,
      5,
      nonNegative(
        miner.data.progress
      ) + collected,
      miner.data,
      now
    ),
    {
      merge: true,
    }
  );

  transaction.set(
    hunter.ref,
    achievementUpdate(
      "stl_hunter",
      100,
      10,
      nonNegative(
        hunter.data.progress
      ) + collected,
      hunter.data,
      now
    ),
    {
      merge: true,
    }
  );
}

// ============================================================
// GET MINING STATUS
// ============================================================

const getMiningStatus = onCall(
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

      const snapshot =
        await getUserRef(uid).get();

      const data =
        snapshot.exists
          ? snapshot.data() || {}
          : {};

      const now =
        new Date();

      const nowMs =
        now.getTime();

      const today =
        getUtcDateString(now);

      const daily =
        nextDailyClaim(
          data,
          today
        );

      const window =
        miningWindow(data);

      const rate =
        window.valid
          ? historicalHashRate(data)
          : miningHashRate(
              data,
              daily.dailyHashRate
            );

      const status =
        calculateMiningStatus(
          {
            ...data,
            hashRate: rate,
          },
          now
        );

      const current =
        await currentUnclaimedMining(
          uid,
          data,
          nowMs
        );

      const ads =
        adStatus(
          data,
          nowMs,
          today
        );

      const effectiveRate =
        ads.adBoostActive
          ? rate + AD_HASH_RATE_BONUS
          : rate;

      const balance =
        nonNegative(
          data.miningBalance
        );

      const estimatedTotal =
        Math.max(
          0,
          balance +
            current.unclaimedMining
        );

      const miningPerHour =
        rate *
        MINING_PER_HASH_PER_HOUR;

      const activeMiningPerHour =
        effectiveRate *
        MINING_PER_HASH_PER_HOUR;

      return {
        success: true,

        message:
          status.miningActive
            ? "🐱⛏️ Stella louhii STL:ää!"
            : status.miningFinished
              ? "🐱✨ Louhinta on valmis kerättäväksi!"
              : "🐱 Stella odottaa seuraavaa louhintaa.",

        hashRate: rate,

        miningBalance:
          balance,

        unclaimedMining:
          current.unclaimedMining,

        baseMining:
          current.baseMining,

        adBoostMining:
          current.adBoostMining,

        boostMilliseconds:
          current.boostMilliseconds,

        estimatedTotal,

        miningActive:
          status.miningActive === true,

        miningFinished:
          status.miningFinished === true,

        miningRemainingMs:
          Math.max(
            0,
            number(
              status.miningRemainingMs
            )
          ),

        elapsedMs:
          Math.max(
            0,
            number(
              status.elapsedMs
            )
          ),

        miningDurationMs:
          MINING_DURATION_MS,

        miningStartedAt:
          window.valid
            ? window.miningStartedAt
                .toISOString()
            : null,

        miningEndsAt:
          window.valid
            ? window.miningEndsAt
                .toISOString()
            : null,

        miningPerHour,

        miningPerMinute:
          miningPerHour / 60,

        miningPerSecond:
          miningPerHour / 3600,

        activeMiningPerHour,

        dailyClaimed:
          daily.claimedToday,

        streak:
          daily.streak,

        dailyStreak:
          daily.streak,

        dailyHashRate:
          daily.dailyHashRate,

        dailyHashRateBonus:
          daily.dailyHashRate,

        nextDailyHashRate:
          daily.dailyHashRate,

        nextDailyStreak:
          daily.streak,

        adsToday:
          ads.adsToday,

        maxAdsPerDay:
          ads.maxAdsPerDay,

        adHashRateBonus:
          AD_HASH_RATE_BONUS,

        adBoostDurationMs:
          AD_BOOST_DURATION_MS,

        adBoostActive:
          ads.adBoostActive,

        adBoostRemainingMs:
          ads.adBoostRemainingMs,

        adBoostStartedAt:
          ads.adBoostStartedAt
            ?.toISOString() || null,

        adBoostEndsAt:
          ads.adBoostEndsAt
            ?.toISOString() || null,

        canWatchAd:
          ads.canWatchAd,

        cooldownRemainingMs:
          ads.cooldownRemainingMs,

        effectiveHashRate:
          effectiveRate,
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
// CLAIM / START MINING
// ============================================================

const claimMining = onCall(
  {
    region: "us-central1",
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

      const requestedTransactionId =
        typeof request.data
          ?.adMobTransactionId === "string"
          ? request.data.adMobTransactionId.trim()
          : "";

      // --------------------------------------------------------
      // FAST PATH
      // --------------------------------------------------------
      // Jos mining on jo aktiivinen, ei kuluteta uutta rewardia.
      // Tämä estää turhan SSV/reward-haun.
      // --------------------------------------------------------

      const earlyNow =
        new Date();

      const earlyNowMs =
        earlyNow.getTime();

      const earlySnapshot =
        await userRef.get();

      const earlyData =
        earlySnapshot.exists
          ? earlySnapshot.data() || {}
          : {};

      const earlyWindow =
        miningWindow(
          earlyData
        );

      const earlyRate =
        earlyWindow.valid
          ? historicalHashRate(
              earlyData
            )
          : miningHashRate(
              earlyData,
              dailyHashRate(
                dailyStreak(
                  earlyData
                ) || 1
              )
            );

      const earlyStatus =
        calculateMiningStatus(
          {
            ...earlyData,
            hashRate: earlyRate,
          },
          earlyNow
        );

      if (
        earlyStatus.miningActive
      ) {
        const current =
          await currentUnclaimedMining(
            uid,
            earlyData,
            earlyNowMs
          );

        return {
          success: true,

          started: false,

          collected: 0,

          miningActive: true,

          hashRate:
            earlyRate,

          miningHashRate:
            earlyRate,

          dailyHashRate:
            dailyHashRate(
              dailyStreak(
                earlyData
              ) || 1
            ),

          dailyStreak:
            dailyStreak(
              earlyData
            ),

          streak:
            dailyStreak(
              earlyData
            ),

          unclaimedMining:
            current.unclaimedMining,

          baseMining:
            current.baseMining,

          adBoostMining:
            current.adBoostMining,

          boostMilliseconds:
            current.boostMilliseconds,

          miningRemainingMs:
            Math.max(
              0,
              number(
                earlyStatus
                  .miningRemainingMs
              )
            ),

          rewardConsumed: false,

          message:
            "🐱⛏️ Stella louhii jo STL:ää.",
        };
      }

      // --------------------------------------------------------
      // VERIFIED ADMOB REWARD
      // --------------------------------------------------------

      const verified =
        await getVerifiedMiningStartReward(
          uid,
          {
            transactionId:
              requestedTransactionId,
          }
        );

      const transactionId =
        verified.transactionId;

      const rewardRef =
        getAdMobRewardRef(
          transactionId
        );

      if (!rewardRef) {
        throw new HttpsError(
          "failed-precondition",
          "🐱 AdMob-tapahtuman tunnistaminen epäonnistui."
        );
      }

      // --------------------------------------------------------
      // ATOMIC TRANSACTION
      // --------------------------------------------------------

      return await db.runTransaction(
        async (transaction) => {
          const now =
            new Date();

          const nowMs =
            now.getTime();

          const today =
            getUtcDateString(now);

          // Kaikki tarvittavat read-operaatiot
          // ennen transaction-write-operaatioita.
          const userSnapshot =
            await transaction.get(
              userRef
            );

          const rewardSnapshot =
            await transaction.get(
              rewardRef
            );

          const data =
            userSnapshot.exists
              ? userSnapshot.data() || {}
              : {};

          const currentStreak =
            dailyStreak(data);

          const fallbackRate =
            dailyHashRate(
              currentStreak || 1
            );

          const previous =
            miningWindow(data);

          const existingRate =
            previous.valid
              ? historicalHashRate(data)
              : miningHashRate(
                  data,
                  fallbackRate
                );

          const status =
            calculateMiningStatus(
              {
                ...data,
                hashRate:
                  existingRate,
              },
              now
            );

          // Toinen tarkistus transaktion sisällä.
          // Tämä suojaa kilpailutilanteelta.
          if (
            status.miningActive
          ) {
            const current =
              await currentUnclaimedMining(
                uid,
                data,
                nowMs,
                transaction
              );

            return {
              success: true,

              started: false,

              collected: 0,

              miningActive: true,

              hashRate:
                existingRate,

              miningHashRate:
                existingRate,

              dailyHashRate:
                fallbackRate,

              dailyStreak:
                currentStreak,

              streak:
                currentStreak,

              unclaimedMining:
                current.unclaimedMining,

              baseMining:
                current.baseMining,

              adBoostMining:
                current.adBoostMining,

              boostMilliseconds:
                current.boostMilliseconds,

              miningRemainingMs:
                Math.max(
                  0,
                  number(
                    status.miningRemainingMs
                  )
                ),

              rewardConsumed: false,

              message:
                "🐱⛏️ Stella louhii jo STL:ää. Mainospalkintoa ei kulutettu.",
            };
          }

          // ------------------------------------------------------
          // AUTHORITATIVE REWARD VALIDATION
          // ------------------------------------------------------

          const validated =
            validateVerifiedRewardDocument(
              rewardSnapshot,
              uid,
              "mining_start",
              "miningStartClaimed",
              {
                referenceNowMs:
                  nowMs,

                transactionId,
              }
            );

          const authoritativeId =
            validated.transactionId;

          // ------------------------------------------------------
          // DAILY HASH RATE
          // ------------------------------------------------------

          const daily =
            nextDailyClaim(
              data,
              today
            );

          const rate =
            daily.dailyHashRate;

          // ------------------------------------------------------
          // EXISTING BALANCE
          // ------------------------------------------------------

          const oldBalance =
            nonNegative(
              data.miningBalance
            );

          let newBalance =
            oldBalance;

          let collected = 0;

          let previousBase = 0;

          let previousBoost = 0;

          let previousBoostMs = 0;

          let completedPrevious =
            false;

          // ------------------------------------------------------
          // COLLECT COMPLETED PREVIOUS CYCLE
          // ------------------------------------------------------

          if (
            previous.valid &&
            previous.miningEndMs <= nowMs
          ) {
            const previousRate =
              historicalHashRate(
                data
              );

            if (previousRate <= 0) {
              throw new HttpsError(
                "failed-precondition",
                "🐱 Edellisen mining-cyclen Hash Rate on virheellinen."
              );
            }

            const cycle =
              await calculateMiningCycle(
                uid,
                previous.miningStartMs,
                previous.miningEndMs,
                previousRate,
                transaction
              );

            previousBase =
              cycle.baseMining;

            previousBoost =
              cycle.adBoostMining;

            previousBoostMs =
              cycle.boostMilliseconds;

            collected =
              Math.max(
                0,
                cycle.totalMining
              );

            if (
              collected > 0
            ) {
              newBalance =
                oldBalance +
                collected;

              completedPrevious =
                true;
            }
          }

          // ------------------------------------------------------
          // ACHIEVEMENTS
          // ------------------------------------------------------

          await updateMiningAchievements(
            transaction,
            uid,
            collected,
            true,
            now
          );

          // ------------------------------------------------------
          // NEW MINING WINDOW
          // ------------------------------------------------------

          const startedAt =
            now;

          const endsAt =
            new Date(
              nowMs +
                MINING_DURATION_MS
            );

          // ------------------------------------------------------
          // USER UPDATE
          // ------------------------------------------------------

          transaction.set(
            userRef,
            {
              hashRate:
                rate,

              dailyStreak:
                daily.streak,

              streak:
                daily.streak,

              lastDailyDate:
                daily.claimedToday
                  ? (
                      typeof data
                        .lastDailyDate ===
                      "string"
                        ? data.lastDailyDate
                        : today
                    )
                  : today,

              miningHashRate:
                rate,

              miningBalance:
                newBalance,

              miningStartedAt:
                startedAt,

              miningEndsAt:
                endsAt,

              adBoostStartedAt:
                null,

              adBoostEndsAt:
                null,

              powerBoostTransactionId:
                null,

              updatedAt:
                FieldValue.serverTimestamp(),
            },
            {
              merge: true,
            }
          );

          // ------------------------------------------------------
          // CONSUME ADMOB REWARD
          // ------------------------------------------------------

          transaction.set(
            rewardRef,
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

              consumedAt:
                FieldValue.serverTimestamp(),

              consumedBy:
                uid,

              rewardConsumed:
                true,
            },
            {
              merge: true,
            }
          );

          // ------------------------------------------------------
          // DAILY HISTORY
          // ------------------------------------------------------

          if (
            !daily.claimedToday
          ) {
            transaction.set(
              getHistoryCollection(uid)
                .doc(),
              {
                type:
                  "dailyHashRate",

                title:
                  "Stella Daily Hash Rate 🐱✨",

                amount:
                  rate,

                hashRate:
                  rate,

                dailyHashRate:
                  rate,

                hashRateBefore:
                  nonNegative(
                    data.hashRate
                  ),

                hashRateAfter:
                  rate,

                dailyStreak:
                  daily.streak,

                streak:
                  daily.streak,

                createdAt:
                  FieldValue.serverTimestamp(),
              }
            );
          }

          // ------------------------------------------------------
          // COMPLETED MINING HISTORY
          // ------------------------------------------------------

          if (
            completedPrevious
          ) {
            transaction.set(
              getHistoryCollection(uid)
                .doc(),
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
                  historicalHashRate(
                    data
                  ),

                miningHashRate:
                  historicalHashRate(
                    data
                  ),

                baseMining:
                  previousBase,

                adBoostMining:
                  previousBoost,

                boostMilliseconds:
                  previousBoostMs,

                miningStartedAt:
                  previous.miningStartedAt,

                miningEndsAt:
                  previous.miningEndsAt,

                createdAt:
                  FieldValue.serverTimestamp(),
              }
            );
          }

          // ------------------------------------------------------
          // NEW MINING HISTORY
          // ------------------------------------------------------

          transaction.set(
            getHistoryCollection(uid)
              .doc(),
            {
              type:
                "mining",

              title:
                "Stella Mining Started 🐱⛏️",

              amount: 0,

              hashRate:
                rate,

              miningHashRate:
                rate,

              dailyHashRate:
                rate,

              dailyStreak:
                daily.streak,

              miningDurationMs:
                MINING_DURATION_MS,

              miningStartedAt:
                startedAt,

              miningEndsAt:
                endsAt,

              adRewardTransactionId:
                authoritativeId,

              rewardPurpose:
                "mining_start",

              createdAt:
                FieldValue.serverTimestamp(),
            }
          );

          const dailyMessage =
            daily.claimedToday
              ? "🐱⛏️ Stella jatkaa tämän päivän louhintaa!"
              : `🐱✨ Stella sai päivän ${daily.streak} Daily Hash Raten: ${rate.toFixed(4)} HR!`;

          return {
            success: true,

            started: true,

            miningActive: true,

            collected,

            completedPreviousCycle:
              completedPrevious,

            miningBalance:
              newBalance,

            hashRate:
              rate,

            dailyHashRate:
              rate,

            dailyHashRateBonus:
              rate,

            dailyStreak:
              daily.streak,

            streak:
              daily.streak,

            miningHashRate:
              rate,

            miningDurationMs:
              MINING_DURATION_MS,

            miningRemainingMs:
              MINING_DURATION_MS,

            miningStartedAt:
              startedAt.toISOString(),

            miningEndsAt:
              endsAt.toISOString(),

            adBoostActive:
              false,

            adBoostRemainingMs:
              0,

            adHashRateBonus:
              AD_HASH_RATE_BONUS,

            effectiveHashRate:
              rate,

            adRewardTransactionId:
              authoritativeId,

            rewardConsumed:
              true,

            message:
              completedPrevious
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
// POWER BOOST
// ============================================================

const powerBoost = onCall(
  {
    region: "us-central1",
    timeoutSeconds: 120,
  },
  async (request) => {
    try {
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

      const requestedTransactionId =
        typeof request.data
          ?.adMobTransactionId === "string"
          ? request.data.adMobTransactionId.trim()
          : "";

      // --------------------------------------------------------
      // FAST PRE-CHECK
      // --------------------------------------------------------

      const earlyNow =
        new Date();

      const earlyNowMs =
        earlyNow.getTime();

      const earlyToday =
        getUtcDateString(
          earlyNow
        );

      const earlySnapshot =
        await userRef.get();

      const earlyData =
        earlySnapshot.exists
          ? earlySnapshot.data() || {}
          : {};

      if (
        !miningActive(
          earlyData,
          earlyNowMs
        )
      ) {
        throw new HttpsError(
          "failed-precondition",
          "🐱⚡ Power Boostia voi käyttää vain aktiivisen louhinnan aikana."
        );
      }

      const earlyRate =
        historicalHashRate(
          earlyData
        );

      if (earlyRate <= 0) {
        throw new HttpsError(
          "failed-precondition",
          "🐱⚡ Nykyisen louhintasyklin Hash Rate ei ole kelvollinen."
        );
      }

      const earlyAds =
        adStatus(
          earlyData,
          earlyNowMs,
          earlyToday
        );

      if (
        earlyAds.adsToday >=
        MAX_ADS_PER_DAY
      ) {
        throw new HttpsError(
          "resource-exhausted",
          "🐱 Päivän Power Boost -mainosraja on täynnä."
        );
      }

      if (
        earlyAds.adBoostActive
      ) {
        throw new HttpsError(
          "failed-precondition",
          "🐱 Power Boost on jo aktiivinen."
        );
      }

      if (
        earlyAds.cooldownRemainingMs >
        0
      ) {
        throw new HttpsError(
          "failed-precondition",
          "🐱 Power Boost ei ole vielä valmis käytettäväksi uudelleen."
        );
      }

      // --------------------------------------------------------
      // VERIFIED ADMOB REWARD
      // --------------------------------------------------------

      const verified =
        await getVerifiedPowerBoostReward(
          uid,
          {
            transactionId:
              requestedTransactionId,
          }
        );

      const transactionId =
        verified.transactionId;

      const rewardRef =
        getAdMobRewardRef(
          transactionId
        );

      if (!rewardRef) {
        throw new HttpsError(
          "failed-precondition",
          "🐱 Power Boost -AdMob-tapahtuman tunnistaminen epäonnistui."
        );
      }

      // --------------------------------------------------------
      // ATOMIC TRANSACTION
      // --------------------------------------------------------

      return await db.runTransaction(
        async (transaction) => {
          const now =
            new Date();

          const nowMs =
            now.getTime();

          const today =
            getUtcDateString(now);

          // Kaikki read-operaatiot ennen write-operaatioita.
          const userSnapshot =
            await transaction.get(
              userRef
            );

          const rewardSnapshot =
            await transaction.get(
              rewardRef
            );

          const data =
            userSnapshot.exists
              ? userSnapshot.data() || {}
              : {};

          const window =
            miningWindow(data);

          if (
            !window.valid ||
            nowMs <
              window.miningStartMs ||
            nowMs >=
              window.miningEndMs
          ) {
            throw new HttpsError(
              "failed-precondition",
              "🐱⚡ Power Boostia voi käyttää vain aktiivisen louhinnan aikana."
            );
          }

          const rate =
            historicalHashRate(data);

          if (rate <= 0) {
            throw new HttpsError(
              "failed-precondition",
              "🐱⚡ Nykyisen louhintasyklin Hash Rate ei ole kelvollinen."
            );
          }

          const status =
            calculateMiningStatus(
              {
                ...data,
                hashRate: rate,
              },
              now
            );

          if (
            !status.miningActive
          ) {
            throw new HttpsError(
              "failed-precondition",
              "🐱⚡ Stella Mining ei ole enää aktiivinen."
            );
          }

          // ------------------------------------------------------
          // AUTHORITATIVE REWARD VALIDATION
          // ------------------------------------------------------

          const validated =
            validateVerifiedRewardDocument(
              rewardSnapshot,
              uid,
              "power_boost",
              "powerBoostClaimed",
              {
                referenceNowMs:
                  nowMs,

                transactionId,
              }
            );

          const authoritativeId =
            validated.transactionId;

          // ------------------------------------------------------
          // CURRENT AD STATE
          // ------------------------------------------------------

          const currentAds =
            adStatus(
              data,
              nowMs,
              today
            );

          if (
            currentAds.adsToday >=
            MAX_ADS_PER_DAY
          ) {
            throw new HttpsError(
              "resource-exhausted",
              "🐱 Päivän Power Boost -mainosraja on täynnä."
            );
          }

          if (
            currentAds.adBoostActive
          ) {
            throw new HttpsError(
              "failed-precondition",
              "🐱 Power Boost on jo aktiivinen."
            );
          }

          if (
            currentAds.cooldownRemainingMs >
            0
          ) {
            throw new HttpsError(
              "failed-precondition",
              "🐱 Power Boost ei ole vielä valmis käytettäväksi uudelleen."
            );
          }

          // ------------------------------------------------------
          // BOOST WINDOW
          // ------------------------------------------------------

          const boostStartedAt =
            now;

          const actualEndMs =
            Math.min(
              nowMs +
                AD_BOOST_DURATION_MS,
              window.miningEndMs
            );

          const boostEndsAt =
            new Date(actualEndMs);

          const durationMs =
            Math.max(
              0,
              actualEndMs -
                nowMs
            );

          if (
            durationMs <= 0
          ) {
            throw new HttpsError(
              "failed-precondition",
              "🐱⚡ Louhintaa ei ole enää tarpeeksi jäljellä Power Boostia varten."
            );
          }

          const storedDate =
            typeof data.lastAdDate ===
            "string"
              ? data.lastAdDate
              : "";

          const oldAds =
            storedDate === today
              ? Math.max(
                  0,
                  Math.floor(
                    number(
                      data.adsToday
                    )
                  )
                )
              : 0;

          const newAdsToday =
            oldAds + 1;

          // ------------------------------------------------------
          // USER UPDATE
          // ------------------------------------------------------

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
                authoritativeId,

              updatedAt:
                FieldValue.serverTimestamp(),
            },
            {
              merge: true,
            }
          );

          // ------------------------------------------------------
          // CONSUME ADMOB REWARD
          // ------------------------------------------------------

          transaction.set(
            rewardSnapshot.ref,
            {
              powerBoostClaimed:
                true,

              powerBoostClaimedAt:
                FieldValue.serverTimestamp(),

              powerBoostClaimedBy:
                uid,

              powerBoostTransactionId:
                authoritativeId,

              consumedAt:
                FieldValue.serverTimestamp(),

              consumedBy:
                uid,

              rewardConsumed:
                true,
            },
            {
              merge: true,
            }
          );

          // ------------------------------------------------------
          // HISTORY
          // ------------------------------------------------------

          transaction.set(
            getHistoryCollection(uid)
              .doc(),
            {
              type:
                "ad_reward",

              title:
                "Stella Power Boost 🐱⚡",

              amount: 0,

              adRewardTransactionId:
                authoritativeId,

              rewardPurpose:
                "power_boost",

              adHashRateBonus:
                AD_HASH_RATE_BONUS,

              boostStartedAt,

              boostEndsAt,

              boostDurationMs:
                durationMs,

              miningStartedAt:
                window.miningStartedAt,

              miningEndsAt:
                window.miningEndsAt,

              miningHashRate:
                rate,

              adsToday:
                newAdsToday,

              maxAdsPerDay:
                MAX_ADS_PER_DAY,

              createdAt:
                FieldValue.serverTimestamp(),
            }
          );

          const daily =
            nextDailyClaim(
              data,
              today
            );

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
              durationMs,

            remainingBoostMs:
              durationMs,

            adBoostDurationMs:
              durationMs,

            configuredBoostDurationMs:
              AD_BOOST_DURATION_MS,

            adBoostStartedAt:
              boostStartedAt.toISOString(),

            adBoostEndsAt:
              boostEndsAt.toISOString(),

            miningStartedAt:
              window.miningStartedAt
                .toISOString(),

            miningEndsAt:
              window.miningEndsAt
                .toISOString(),

            miningHashRate:
              rate,

            effectiveHashRate:
              rate +
              AD_HASH_RATE_BONUS,

            dailyHashRate:
              daily.dailyHashRate,

            dailyStreak:
              daily.streak,

            transactionId:
              authoritativeId,

            rewardConsumed:
              true,

            message:
              durationMs <
              AD_BOOST_DURATION_MS
                ? "🐱⚡ Stella Power Boost on aktiivinen louhinnan loppuun asti!"
                : "🐱⚡ Stella Power Boost on aktiivinen!",
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
// EXPORTS
// ============================================================

module.exports = {
  getMiningStatus,
  claimMining,
  powerBoost,
};