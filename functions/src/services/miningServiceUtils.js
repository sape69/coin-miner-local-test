
"use strict";

// ============================================================
// 🐱 STELLURIINI - MINING SERVICE UTILITIES
// ============================================================
//
// MiningServicen apufunktiot.
//
// Vastuu:
// - Turvallinen numeroiden käsittely
// - Turvallinen päivämäärien käsittely
// - Daily Hash Rate
// - Power Boost -louhintalaskenta
// - Louhintajakson aikarajat
// - Power Boost -historian laskenta
// - Valmiin ja käynnissä olevan louhinnan laskenta
//
// HUOM:
// Tämä tiedosto säilyttää alkuperäisen miningService.js:n
// laskentalogiikan. Laskentakaavoja ei ole muutettu.
// ============================================================


// ============================================================
// ⚙️ MINING CONFIG
// ============================================================

const {
  DAILY_HASH_RATE_START,
  DAILY_HASH_RATE_STEP,
  DAILY_HASH_RATE_MAX_DAY,
  MAX_DAILY_HASH_RATE,
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
// 🔢 SAFE NUMBER
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
      normalized.length === 0
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
// Power Boostit eivät stackaa.
//
// Päällekkäinen aika lasketaan vain kerran.
//
// Jos useampi boosti osuu samaan aikaväliin,
// käytetään suurinta hash ratea.
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
      !boostEndsAt
    ) {
      continue;
    }

    if (
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
      segmentHashRate <= 0
    ) {
      continue;
    }

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
    !data ||
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
// 📦 EXPORTS
// ============================================================

module.exports = {
  getSafeNumber,
  getSafeDate,
  getUtcDateKey,

  calculateDailyHashRate,
  calculatePowerBoostMining,

  getMiningWindow,
  calculateBoostFromRecords,
  calculateCurrentStoredBoost,

  calculateCompletedMining,
  calculateCurrentMining,
};
