
"use strict";

// ============================================================
// 🐱 STELLURIINI - MINING CALCULATION SERVICE
// ============================================================
//
// Louhintajaksojen laskenta ja apufunktiot.
//
// Vastuu:
// - Mining-ajan tarkistus
// - Hash Raten validointi
// - Power Boost -historian lukeminen
// - Power Boost -aikojen yhdistäminen
// - Louhintajakson tuoton laskenta
// - Lunastamattoman louhinnan laskenta
//
// Halving:
// - Uusi louhintajakso käyttää tallennettua kerrointa.
// - Vanha jakso ilman kerrointa käyttää arvoa 1.
// - Sama kerroin vaikuttaa myös Power Boostiin.
//
// Tämä tiedosto ei muuta käyttäjän saldoa.
// Se ei käynnistä eikä päätä louhintajaksoa.
//
// ============================================================

const {
  DAILY_HASH_RATE_START,
  MAX_DAILY_HASH_RATE,
  MINING_DURATION_MS,
  AD_HASH_RATE_BONUS,
  MAX_ADS_PER_DAY,
} = require("../config/miningConfig");

const {
  getHistoryCollection,
} = require("../utils/userUtils");

const {
  calculateMining,
  getMiningStartTime,
  getMiningEndTime,
  getMiningHalvingMultiplier,
} = require("../utils/miningUtils");

const {
  number,
  positive,
  timestampMs,
} = require("../utils/valueUtils");


// ============================================================
// ⛏️ MINING WINDOW
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


// ============================================================
// ⚡ MINING ACTIVE
// ============================================================

function miningActive(data, nowMs) {
  const window = miningWindow(data);

  return (
    window.valid &&
    nowMs >= window.miningStartMs &&
    nowMs < window.miningEndMs
  );
}


// ============================================================
// ⚡ CURRENT MINING HASH RATE
// ============================================================

function miningHashRate(
  data,
  fallback = DAILY_HASH_RATE_START,
) {
  const stored = positive(data.miningHashRate);

  if (
    stored >= DAILY_HASH_RATE_START &&
    stored <= MAX_DAILY_HASH_RATE
  ) {
    return stored;
  }

  const safeFallback = positive(
    fallback,
    DAILY_HASH_RATE_START,
  );

  return Math.min(
    MAX_DAILY_HASH_RATE,
    Math.max(
      DAILY_HASH_RATE_START,
      safeFallback,
    ),
  );
}


// ============================================================
// 📜 HISTORICAL HASH RATE
// ============================================================

function historicalHashRate(data) {
  const rate = positive(
    data.miningHashRate ?? data.hashRate,
  );

  return (
    rate >= DAILY_HASH_RATE_START &&
    rate <= MAX_DAILY_HASH_RATE
  )
    ? rate
    : 0;
}


// ============================================================
// 📜 MAXIMUM BOOST HISTORY ENTRIES
// ============================================================

function maxBoostHistoryEntries() {
  const dayMs = 24 * 60 * 60 * 1000;

  const days = Math.max(
    1,
    Math.ceil(MINING_DURATION_MS / dayMs),
  );

  return Math.max(
    MAX_ADS_PER_DAY,
    (days + 1) * MAX_ADS_PER_DAY + 10,
  );
}


// ============================================================
// ⚡ GET POWER BOOST HISTORY
// ============================================================

async function getAdBoostHistory(
  uid,
  startMs,
  endMs,
  transaction = null,
) {
  if (
    !startMs ||
    !endMs ||
    endMs <= startMs
  ) {
    return [];
  }

  const query = getHistoryCollection(uid)
    .where(
      "boostStartedAt",
      ">=",
      new Date(startMs),
    )
    .where(
      "boostStartedAt",
      "<",
      new Date(endMs),
    )
    .orderBy(
      "boostStartedAt",
      "asc",
    )
    .limit(
      maxBoostHistoryEntries(),
    );

  const snapshot = transaction
    ? await transaction.get(query)
    : await query.get();

  const boosts = [];

  snapshot.forEach((doc) => {
    const data = doc.data() || {};

    // Hyväksytään mainoksella saadut Boostit
    // sekä Premium-tilauksen Boostit.
    //
    // Premium Plusin automaattinen Boost käyttää
    // samaa premium_power_boost-tyyppiä.

    if (
      ![
        "ad_reward",
        "premium_power_boost",
      ].includes(data.type) ||
      data.rewardPurpose !== "power_boost"
    ) {
      return;
    }

    const start = timestampMs(
      data.boostStartedAt,
    );

    const end = timestampMs(
      data.boostEndsAt,
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
      boostStartedMs: Math.max(
        start,
        startMs,
      ),

      boostEndsMs: Math.min(
        end,
        endMs,
      ),
    });
  });

  return boosts;
}


// ============================================================
// ⏱️ CALCULATE TOTAL BOOST TIME
// ============================================================
//
// Yhdistää päällekkäiset Power Boost -aikavälit.
//
// Päällekkäistä aikaa ei lasketa kahteen kertaan.
//
// ============================================================

function boostMilliseconds(
  boosts,
  startMs,
  endMs,
) {
  if (
    !Array.isArray(boosts) ||
    !startMs ||
    !endMs ||
    endMs <= startMs
  ) {
    return 0;
  }

  const intervals = boosts
    .map((boost) => {
      const start = Math.max(
        startMs,
        number(boost.boostStartedMs),
      );

      const end = Math.min(
        endMs,
        number(boost.boostEndsMs),
      );

      return end > start
        ? { start, end }
        : null;
    })
    .filter(Boolean)
    .sort(
      (a, b) => a.start - b.start,
    );

  if (!intervals.length) {
    return 0;
  }

  let total = 0;

  let start = intervals[0].start;
  let end = intervals[0].end;

  for (
    let i = 1;
    i < intervals.length;
    i++
  ) {
    const current = intervals[i];

    if (current.start <= end) {
      end = Math.max(
        end,
        current.end,
      );
    } else {
      total += end - start;

      start = current.start;
      end = current.end;
    }
  }

  return Math.max(
    0,
    total + end - start,
  );
}


// ============================================================
// 💰 CALCULATE MINING CYCLE
// ============================================================

async function calculateMiningCycle(
  uid,
  startMs,
  endMs,
  hashRate,
  transaction = null,
  halvingMultiplier = 1,
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
  const duration = endMs - startMs;

  const safeHalvingMultiplier =
    positive(halvingMultiplier, 1);

  const baseMining = rate > 0
    ? Math.max(
        0,
        number(
          calculateMining(
            rate,
            duration,
            safeHalvingMultiplier,
          ),
        ),
      )
    : 0;

  const boosts = await getAdBoostHistory(
    uid,
    startMs,
    endMs,
    transaction,
  );

  const boostMs = boostMilliseconds(
    boosts,
    startMs,
    endMs,
  );

  const adBoostMining =
    boostMs > 0 && AD_HASH_RATE_BONUS > 0
      ? Math.max(
          0,
          number(
            calculateMining(
              AD_HASH_RATE_BONUS,
              boostMs,
              safeHalvingMultiplier,
            ),
          ),
        )
      : 0;

  return {
    baseMining,
    adBoostMining,

    boostMilliseconds: boostMs,

    totalMining: Math.max(
      0,
      baseMining + adBoostMining,
    ),
  };
}


// ============================================================
// 💰 CURRENT UNCLAIMED MINING
// ============================================================

async function currentUnclaimedMining(
  uid,
  data,
  nowMs,
  transaction = null,
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
    nowMs,
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

  // Käytetään juuri tämän louhintajakson
  // Firestoreen tallennettua halving-kerrointa.
  //
  // Vanhoilla jaksoilla ilman tallennettua
  // kerrointa arvo on automaattisesti 1.

  const halvingMultiplier =
    getMiningHalvingMultiplier(data);

  const cycle = await calculateMiningCycle(
    uid,
    window.miningStartMs,
    endMs,
    rate,
    transaction,
    halvingMultiplier,
  );

  return {
    unclaimedMining: cycle.totalMining,

    baseMining: cycle.baseMining,

    adBoostMining: cycle.adBoostMining,

    boostMilliseconds: cycle.boostMilliseconds,
  };
}


// ============================================================
// 📦 EXPORTS
// ============================================================

module.exports = {
  miningWindow,
  miningActive,
  miningHashRate,
  historicalHashRate,

  maxBoostHistoryEntries,
  getAdBoostHistory,
  boostMilliseconds,

  calculateMiningCycle,
  currentUnclaimedMining,
};
