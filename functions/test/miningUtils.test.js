
"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");

const {
  calculateMining,
  getMiningStartTime,
  getMiningEndTime,
  getMiningHashRate,
  getHalvingMultiplier,
  getEffectiveMiningRate,
  getMiningHalvingMultiplier,
  calculateMiningStatus,
} = require("../src/utils/miningUtils");

const HOUR = 60 * 60 * 1000;
const DAY = 24 * HOUR;

const BASE_TIME = new Date("2026-01-01T00:00:00.000Z");

// Floating point comparison helper.
function assertApproximatelyEqual(
  actual,
  expected,
  tolerance = 1e-10,
) {
  assert.ok(
    Math.abs(actual - expected) <= tolerance,
    `Expected ${actual} to be approximately ${expected}`,
  );
}

// ============================================================
// CALCULATE MINING
// ============================================================

test("calculates mining amount using hash rate and elapsed hours", () => {
  assertApproximatelyEqual(calculateMining(1, HOUR), 0.1);
  assertApproximatelyEqual(calculateMining(2, HOUR), 0.2);
  assertApproximatelyEqual(calculateMining(3.5, DAY), 8.4);
});

test("returns zero when hash rate is zero", () => {
  assert.equal(calculateMining(0, HOUR), 0);
});

test("returns zero when elapsed time is zero", () => {
  assert.equal(calculateMining(2, 0), 0);
});

test("returns zero for negative hash rate", () => {
  assert.equal(calculateMining(-2, HOUR), 0);
});

test("returns zero for negative elapsed time", () => {
  assert.equal(calculateMining(2, -HOUR), 0);
});

test("returns zero for invalid numeric values", () => {
  assert.equal(calculateMining(NaN, HOUR), 0);
  assert.equal(calculateMining(2, NaN), 0);
  assert.equal(calculateMining(Infinity, HOUR), 0);
  assert.equal(calculateMining(2, Infinity), 0);
});

// ============================================================
// HALVING MULTIPLIER
// ============================================================

test("uses multiplier 1.0 below 100 registered users", () => {
  assert.equal(getHalvingMultiplier(0), 1.0);
  assert.equal(getHalvingMultiplier(1), 1.0);
  assert.equal(getHalvingMultiplier(99), 1.0);
});

test("uses multiplier 0.5 from 100 registered users", () => {
  assert.equal(getHalvingMultiplier(100), 0.5);
  assert.equal(getHalvingMultiplier(999), 0.5);
});

test("uses multiplier 0.25 from 1000 registered users", () => {
  assert.equal(getHalvingMultiplier(1000), 0.25);
  assert.equal(getHalvingMultiplier(9999), 0.25);
});

test("uses multiplier 0.125 from 10000 registered users", () => {
  assert.equal(getHalvingMultiplier(10000), 0.125);
  assert.equal(getHalvingMultiplier(99999), 0.125);
});

test("uses multiplier 0.0625 from 100000 registered users", () => {
  assert.equal(getHalvingMultiplier(100000), 0.0625);
  assert.equal(getHalvingMultiplier(999999), 0.0625);
});

test("uses multiplier 0.03125 from 1000000 registered users", () => {
  assert.equal(getHalvingMultiplier(1000000), 0.03125);
  assert.equal(getHalvingMultiplier(9999999), 0.03125);
});

test("uses multiplier 0.015625 from 10000000 registered users", () => {
  assert.equal(getHalvingMultiplier(10000000), 0.015625);
  assert.equal(getHalvingMultiplier(99999999), 0.015625);
});

test("uses multiplier 0.0078125 from 100000000 registered users", () => {
  assert.equal(getHalvingMultiplier(100000000), 0.0078125);
  assert.equal(getHalvingMultiplier(1000000000), 0.0078125);
});

test("handles invalid registered user counts safely", () => {
  assert.equal(getHalvingMultiplier(-100), 1.0);
  assert.equal(getHalvingMultiplier(NaN), 1.0);
  assert.equal(getHalvingMultiplier(Infinity), 1.0);
  assert.equal(getHalvingMultiplier("invalid"), 1.0);
});

test("floors fractional registered user counts", () => {
  assert.equal(getHalvingMultiplier(99.9), 1.0);
  assert.equal(getHalvingMultiplier(100.9), 0.5);
});

// ============================================================
// EFFECTIVE MINING RATE
// ============================================================

test("calculates effective mining rate with halving multiplier", () => {
  assertApproximatelyEqual(
    getEffectiveMiningRate(1.0),
    0.1,
  );

  assertApproximatelyEqual(
    getEffectiveMiningRate(0.5),
    0.05,
  );

  assertApproximatelyEqual(
    getEffectiveMiningRate(0.25),
    0.025,
  );

  assertApproximatelyEqual(
    getEffectiveMiningRate(0.125),
    0.0125,
  );
});

test("uses multiplier 1 when no multiplier is supplied", () => {
  assertApproximatelyEqual(
    getEffectiveMiningRate(),
    0.1,
  );
});

test("returns zero for invalid effective mining multipliers", () => {
  assert.equal(getEffectiveMiningRate(0), 0);
  assert.equal(getEffectiveMiningRate(-1), 0);
});

// ============================================================
// MINING WITH HALVING
// ============================================================

test("calculates mining using a 0.5 halving multiplier", () => {
  assertApproximatelyEqual(
    calculateMining(1, HOUR, 0.5),
    0.05,
  );
});

test("calculates mining using a 0.25 halving multiplier", () => {
  assertApproximatelyEqual(
    calculateMining(1, HOUR, 0.25),
    0.025,
  );
});

test("calculates mining using a 0.125 halving multiplier", () => {
  assertApproximatelyEqual(
    calculateMining(2, HOUR, 0.125),
    0.025,
  );
});

test("calculates mining using the final 0.0078125 multiplier", () => {
  assertApproximatelyEqual(
    calculateMining(1, HOUR, 0.0078125),
    0.00078125,
  );
});

test("uses the original mining rate when multiplier is omitted", () => {
  assertApproximatelyEqual(
    calculateMining(1, HOUR),
    0.1,
  );
});

// ============================================================
// STORED MINING HALVING MULTIPLIER
// ============================================================

test("reads stored mining halving multiplier", () => {
  assert.equal(
    getMiningHalvingMultiplier({
      miningHalvingMultiplier: 0.5,
    }),
    0.5,
  );

  assert.equal(
    getMiningHalvingMultiplier({
      miningHalvingMultiplier: 0.25,
    }),
    0.25,
  );

  assert.equal(
    getMiningHalvingMultiplier({
      miningHalvingMultiplier: 0.0078125,
    }),
    0.0078125,
  );
});

test("uses multiplier 1 for old mining cycles without stored multiplier", () => {
  assert.equal(
    getMiningHalvingMultiplier({}),
    1,
  );

  assert.equal(
    getMiningHalvingMultiplier({
      hashRate: 2,
    }),
    1,
  );

  assert.equal(
    getMiningHalvingMultiplier(null),
    1,
  );
});

test("rejects invalid stored mining halving multipliers", () => {
  assert.equal(
    getMiningHalvingMultiplier({
      miningHalvingMultiplier: 0,
    }),
    1,
  );

  assert.equal(
    getMiningHalvingMultiplier({
      miningHalvingMultiplier: -0.5,
    }),
    1,
  );

  assert.equal(
    getMiningHalvingMultiplier({
      miningHalvingMultiplier: 2,
    }),
    1,
  );

  assert.equal(
    getMiningHalvingMultiplier({
      miningHalvingMultiplier: "invalid",
    }),
    1,
  );
});

// ============================================================
// MINING START AND END TIMES
// ============================================================

test("reads mining start time from Date", () => {
  const result = getMiningStartTime({
    miningStartedAt: BASE_TIME,
  });

  assert.ok(result instanceof Date);
  assert.equal(result.getTime(), BASE_TIME.getTime());
});

test("reads mining end time from ISO string", () => {
  const endTime = new Date(
    BASE_TIME.getTime() + DAY,
  );

  const result = getMiningEndTime({
    miningEndsAt: endTime.toISOString(),
  });

  assert.ok(result instanceof Date);
  assert.equal(result.getTime(), endTime.getTime());
});

test("reads mining timestamps from milliseconds", () => {
  const timestamp = BASE_TIME.getTime();

  const result = getMiningStartTime({
    miningStartedAt: timestamp,
  });

  assert.ok(result instanceof Date);
  assert.equal(result.getTime(), timestamp);
});

test("supports Firestore-like timestamp objects", () => {
  const timestamp = {
    toDate: () => new Date(BASE_TIME.getTime()),
  };

  const result = getMiningStartTime({
    miningStartedAt: timestamp,
  });

  assert.ok(result instanceof Date);
  assert.equal(result.getTime(), BASE_TIME.getTime());
});

test("returns null for missing or invalid dates", () => {
  assert.equal(
    getMiningStartTime({ miningStartedAt: null }),
    null,
  );

  assert.equal(
    getMiningEndTime({ miningEndsAt: "" }),
    null,
  );

  assert.equal(
    getMiningStartTime({ miningStartedAt: "invalid-date" }),
    null,
  );

  assert.equal(
    getMiningEndTime(null),
    null,
  );
});

// ============================================================
// HASH RATE
// ============================================================

test("uses hashRate as the primary hash rate field", () => {
  assert.equal(
    getMiningHashRate({
      hashRate: 3.5,
      miningHashRate: 1,
    }),
    3.5,
  );
});

test("uses miningHashRate as a compatibility fallback", () => {
  assert.equal(
    getMiningHashRate({
      hashRate: 0,
      miningHashRate: 2,
    }),
    2,
  );
});

test("returns zero for invalid hash rate values", () => {
  assert.equal(getMiningHashRate(null), 0);

  assert.equal(
    getMiningHashRate({
      hashRate: -5,
      miningHashRate: -2,
    }),
    0,
  );

  assert.equal(
    getMiningHashRate({
      hashRate: "invalid",
    }),
    0,
  );
});

// ============================================================
// MINING STATUS
// ============================================================

test("returns inactive status when no mining session exists", () => {
  const result = calculateMiningStatus(
    {
      hashRate: 2,
    },
    BASE_TIME,
  );

  assert.equal(result.miningActive, false);
  assert.equal(result.miningFinished, false);
  assert.equal(result.elapsedMs, 0);
  assert.equal(result.miningRemainingMs, 0);
  assert.equal(result.minedAmount, 0);
  assert.equal(result.miningStartedAt, null);
  assert.equal(result.miningEndsAt, null);
});

test("returns active status during a mining session", () => {
  const start = BASE_TIME;
  const end = new Date(start.getTime() + DAY);
  const now = new Date(start.getTime() + HOUR);

  const result = calculateMiningStatus(
    {
      hashRate: 2,
      miningStartedAt: start,
      miningEndsAt: end,
    },
    now,
  );

  assert.equal(result.miningActive, true);
  assert.equal(result.miningFinished, false);
  assert.equal(result.elapsedMs, HOUR);
  assert.equal(result.miningRemainingMs, DAY - HOUR);
  assertApproximatelyEqual(result.minedAmount, 0.2);
  assert.equal(result.hashRate, 2);
});

test("returns finished status after the mining session ends", () => {
  const start = BASE_TIME;
  const end = new Date(start.getTime() + DAY);
  const now = new Date(end.getTime() + HOUR);

  const result = calculateMiningStatus(
    {
      hashRate: 1,
      miningStartedAt: start,
      miningEndsAt: end,
    },
    now,
  );

  assert.equal(result.miningActive, false);
  assert.equal(result.miningFinished, true);
  assert.equal(result.elapsedMs, DAY);
  assert.equal(result.miningRemainingMs, 0);
  assertApproximatelyEqual(result.minedAmount, 2.4);
});

test("returns inactive status before mining starts", () => {
  const start = BASE_TIME;
  const end = new Date(start.getTime() + DAY);
  const now = new Date(start.getTime() - HOUR);

  const result = calculateMiningStatus(
    {
      hashRate: 2,
      miningStartedAt: start,
      miningEndsAt: end,
    },
    now,
  );

  assert.equal(result.miningActive, false);
  assert.equal(result.miningFinished, false);
  assert.equal(result.elapsedMs, 0);
  assert.equal(result.miningRemainingMs, DAY);
  assert.equal(result.minedAmount, 0);
});

test("rejects an invalid mining time window", () => {
  const start = BASE_TIME;
  const end = new Date(start.getTime() - HOUR);

  const result = calculateMiningStatus(
    {
      hashRate: 2,
      miningStartedAt: start,
      miningEndsAt: end,
    },
    BASE_TIME,
  );

  assert.equal(result.miningActive, false);
  assert.equal(result.miningFinished, false);
  assert.equal(result.elapsedMs, 0);
  assert.equal(result.miningRemainingMs, 0);
  assert.equal(result.minedAmount, 0);
});

test("does not calculate mining beyond the session duration", () => {
  const start = BASE_TIME;
  const end = new Date(start.getTime() + DAY);
  const now = new Date(start.getTime() + DAY * 2);

  const result = calculateMiningStatus(
    {
      hashRate: 1,
      miningStartedAt: start,
      miningEndsAt: end,
    },
    now,
  );

  assert.equal(result.miningFinished, true);
  assert.equal(result.elapsedMs, DAY);
  assertApproximatelyEqual(result.minedAmount, 2.4);
});

test("uses the compatibility hash rate field in mining status", () => {
  const start = BASE_TIME;
  const end = new Date(start.getTime() + DAY);
  const now = new Date(start.getTime() + HOUR);

  const result = calculateMiningStatus(
    {
      hashRate: 0,
      miningHashRate: 2,
      miningStartedAt: start,
      miningEndsAt: end,
    },
    now,
  );

  assert.equal(result.hashRate, 2);
  assert.equal(result.miningHashRate, 2);
  assertApproximatelyEqual(result.minedAmount, 0.2);
});

// ============================================================
// MINING STATUS WITH HALVING
// ============================================================

test("applies stored halving multiplier to an active mining cycle", () => {
  const start = BASE_TIME;
  const end = new Date(start.getTime() + DAY);
  const now = new Date(start.getTime() + HOUR);

  const result = calculateMiningStatus(
    {
      hashRate: 2,
      miningHalvingMultiplier: 0.5,
      miningStartedAt: start,
      miningEndsAt: end,
    },
    now,
  );

  assert.equal(result.miningActive, true);
  assert.equal(result.miningHalvingMultiplier, 0.5);
  assertApproximatelyEqual(result.minedAmount, 0.1);
});

test("applies stored halving multiplier to a finished mining cycle", () => {
  const start = BASE_TIME;
  const end = new Date(start.getTime() + DAY);
  const now = new Date(end.getTime() + HOUR);

  const result = calculateMiningStatus(
    {
      hashRate: 1,
      miningHalvingMultiplier: 0.25,
      miningStartedAt: start,
      miningEndsAt: end,
    },
    now,
  );

  assert.equal(result.miningFinished, true);
  assert.equal(result.miningHalvingMultiplier, 0.25);
  assertApproximatelyEqual(result.minedAmount, 0.6);
});

test("keeps old mining cycles at multiplier 1", () => {
  const start = BASE_TIME;
  const end = new Date(start.getTime() + DAY);
  const now = new Date(start.getTime() + HOUR);

  const result = calculateMiningStatus(
    {
      hashRate: 1,
      miningStartedAt: start,
      miningEndsAt: end,
    },
    now,
  );

  assert.equal(result.miningHalvingMultiplier, 1);
  assertApproximatelyEqual(result.minedAmount, 0.1);
});

test("returns stored multiplier even when mining is inactive", () => {
  const result = calculateMiningStatus(
    {
      hashRate: 2,
      miningHalvingMultiplier: 0.5,
    },
    BASE_TIME,
  );

  assert.equal(result.miningActive, false);
  assert.equal(result.miningHalvingMultiplier, 0.5);
  assert.equal(result.minedAmount, 0);
});
