
"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");

const {
  calculateMining,
  getMiningStartTime,
  getMiningEndTime,
  getMiningHashRate,
  calculateMiningStatus,
} = require("../src/utils/miningUtils");

const HOUR = 60 * 60 * 1000;
const DAY = 24 * HOUR;

const BASE_TIME = new Date("2026-01-01T00:00:00.000Z");

// ============================================================
// CALCULATE MINING
// ============================================================

test("calculates mining amount using hash rate and elapsed hours", () => {
  assert.equal(calculateMining(1, HOUR), 0.1);
  assert.equal(calculateMining(2, HOUR), 0.2);
  assert.equal(calculateMining(3.5, DAY), 8.4);
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
  assert.equal(result.minedAmount, 0.2);
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
  assert.equal(result.minedAmount, 2.4);
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
  assert.equal(result.minedAmount, 2.4);
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
  assert.equal(result.minedAmount, 0.2);
});
