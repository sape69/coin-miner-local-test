
"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");

const {
  calculateDailyHashRate,
  calculatePowerBoostMining,
  calculateCompletedMining,
  calculateCurrentMining,
} = require("../src/services/miningService");

const HOUR = 60 * 60 * 1000;
const DAY = 24 * HOUR;

const START = new Date("2026-01-01T00:00:00.000Z");

function approximatelyEqual(actual, expected, tolerance = 1e-10) {
  assert.ok(
    Math.abs(actual - expected) <= tolerance,
    `Expected ${actual} to be approximately ${expected}`,
  );
}

function createMiningData(overrides = {}) {
  return {
    hashRate: 1,
    miningStartedAt: START,
    miningEndsAt: new Date(START.getTime() + DAY),
    ...overrides,
  };
}

function createBoostRecord({
  start = START.getTime() + HOUR,
  end = START.getTime() + 5 * HOUR,
  hashRateBonus = 0.5833,
  miningStart = START,
  type = "power_boost_started",
} = {}) {
  return {
    type,
    miningStartedAt: miningStart,
    powerBoostStartedAt: new Date(start),
    powerBoostEndsAt: new Date(end),
    hashRateBonus,
  };
}

// ============================================================
// DAILY HASH RATE
// ============================================================

test("daily hash rate starts at 0.5 HR", () => {
  assert.equal(calculateDailyHashRate(1), 0.5);
});

test("daily hash rate increases by 0.5 HR per day", () => {
  assert.equal(calculateDailyHashRate(2), 1.0);
  assert.equal(calculateDailyHashRate(3), 1.5);
  assert.equal(calculateDailyHashRate(4), 2.0);
  assert.equal(calculateDailyHashRate(5), 2.5);
  assert.equal(calculateDailyHashRate(6), 3.0);
});

test("daily hash rate reaches 3.5 HR on day seven", () => {
  assert.equal(calculateDailyHashRate(7), 3.5);
});

test("daily hash rate never exceeds the configured maximum", () => {
  assert.equal(calculateDailyHashRate(8), 3.5);
  assert.equal(calculateDailyHashRate(30), 3.5);
  assert.equal(calculateDailyHashRate(365), 3.5);
});

test("invalid daily streak uses the safe default", () => {
  assert.equal(calculateDailyHashRate(0), 0.5);
  assert.equal(calculateDailyHashRate(-5), 0.5);
  assert.equal(calculateDailyHashRate(NaN), 0.5);
  assert.equal(calculateDailyHashRate("invalid"), 0.5);
});

// ============================================================
// POWER BOOST MINING CALCULATION
// ============================================================

test("calculates Power Boost mining amount", () => {
  approximatelyEqual(
    calculatePowerBoostMining(0.5833, HOUR),
    0.05833,
  );
});

test("calculates four hours of Power Boost mining", () => {
  approximatelyEqual(
    calculatePowerBoostMining(0.5833, 4 * HOUR),
    0.23332,
  );
});

test("returns zero for zero Power Boost hash rate", () => {
  assert.equal(
    calculatePowerBoostMining(0, HOUR),
    0,
  );
});

test("returns zero for zero Power Boost duration", () => {
  assert.equal(
    calculatePowerBoostMining(0.5833, 0),
    0,
  );
});

test("returns zero for negative Power Boost values", () => {
  assert.equal(
    calculatePowerBoostMining(-1, HOUR),
    0,
  );

  assert.equal(
    calculatePowerBoostMining(0.5833, -HOUR),
    0,
  );
});

test("handles invalid Power Boost values safely", () => {
  assert.equal(
    calculatePowerBoostMining(NaN, HOUR),
    0,
  );

  assert.equal(
    calculatePowerBoostMining(0.5833, NaN),
    0,
  );

  assert.equal(
    calculatePowerBoostMining(Infinity, HOUR),
    0,
  );
});

// ============================================================
// COMPLETED MINING
// ============================================================

test("calculates completed mining without Power Boost", () => {
  const now = new Date(START.getTime() + DAY);

  const result = calculateCompletedMining(
    createMiningData(),
    now,
  );

  approximatelyEqual(result.baseAmount, 2.4);
  assert.equal(result.boostAmount, 0);
  approximatelyEqual(result.totalAmount, 2.4);
  assert.equal(result.elapsedMs, DAY);
  assert.equal(result.boostElapsedMs, 0);
});

test("calculates mining with stored Power Boost", () => {
  const now = new Date(START.getTime() + 5 * HOUR);

  const result = calculateCompletedMining(
    createMiningData({
      powerBoostStartedAt: new Date(
        START.getTime() + HOUR,
      ),
      powerBoostEndsAt: new Date(
        START.getTime() + 5 * HOUR,
      ),
      powerBoostHashRate: 0.5833,
    }),
    now,
  );

  approximatelyEqual(result.baseAmount, 0.5);
  approximatelyEqual(result.boostAmount, 0.23332);
  approximatelyEqual(result.totalAmount, 0.73332);
  assert.equal(result.boostElapsedMs, 4 * HOUR);
});

test("clips Power Boost duration to the mining end time", () => {
  const miningEnd = new Date(
    START.getTime() + 3 * HOUR,
  );

  const now = new Date(
    START.getTime() + 6 * HOUR,
  );

  const result = calculateCompletedMining(
    createMiningData({
      miningEndsAt: miningEnd,
      powerBoostStartedAt: new Date(
        START.getTime() + HOUR,
      ),
      powerBoostEndsAt: new Date(
        START.getTime() + 5 * HOUR,
      ),
      powerBoostHashRate: 0.5833,
    }),
    now,
  );

  assert.equal(result.elapsedMs, 3 * HOUR);
  assert.equal(result.boostElapsedMs, 2 * HOUR);

  approximatelyEqual(result.baseAmount, 0.3);
  approximatelyEqual(result.boostAmount, 0.11666);
  approximatelyEqual(result.totalAmount, 0.41666);
});

test("does not calculate mining before the session starts", () => {
  const now = new Date(
    START.getTime() - HOUR,
  );

  const result = calculateCompletedMining(
    createMiningData(),
    now,
  );

  assert.equal(result.baseAmount, 0);
  assert.equal(result.boostAmount, 0);
  assert.equal(result.totalAmount, 0);
  assert.equal(result.elapsedMs, 0);
});

test("does not calculate mining beyond the session end", () => {
  const now = new Date(
    START.getTime() + 2 * DAY,
  );

  const result = calculateCompletedMining(
    createMiningData(),
    now,
  );

  assert.equal(result.elapsedMs, DAY);
  approximatelyEqual(result.baseAmount, 2.4);
  approximatelyEqual(result.totalAmount, 2.4);
});

test("returns zero amounts for missing mining data", () => {
  const result = calculateCompletedMining(
    null,
    START,
  );

  assert.equal(result.baseAmount, 0);
  assert.equal(result.boostAmount, 0);
  assert.equal(result.totalAmount, 0);
  assert.equal(result.elapsedMs, 0);
  assert.equal(result.boostElapsedMs, 0);
});

test("returns zero amounts for invalid mining window", () => {
  const result = calculateCompletedMining(
    createMiningData({
      miningEndsAt: new Date(
        START.getTime() - HOUR,
      ),
    }),
    START,
  );

  assert.equal(result.baseAmount, 0);
  assert.equal(result.boostAmount, 0);
  assert.equal(result.totalAmount, 0);
});

// ============================================================
// POWER BOOST HISTORY
// ============================================================

test("calculates Power Boost from history records", () => {
  const now = new Date(
    START.getTime() + 5 * HOUR,
  );

  const result = calculateCompletedMining(
    createMiningData(),
    now,
    [
      createBoostRecord(),
    ],
  );

  approximatelyEqual(result.baseAmount, 0.5);
  approximatelyEqual(result.boostAmount, 0.23332);
  approximatelyEqual(result.totalAmount, 0.73332);
  assert.equal(result.boostElapsedMs, 4 * HOUR);
});

test("overlapping Power Boost records do not stack", () => {
  const now = new Date(
    START.getTime() + 6 * HOUR,
  );

  const records = [
    createBoostRecord({
      start: START.getTime() + HOUR,
      end: START.getTime() + 5 * HOUR,
      hashRateBonus: 0.5833,
    }),
    createBoostRecord({
      start: START.getTime() + 3 * HOUR,
      end: START.getTime() + 6 * HOUR,
      hashRateBonus: 0.5833,
    }),
  ];

  const result = calculateCompletedMining(
    createMiningData(),
    now,
    records,
  );

  // The overlapping hour is counted only once.
  assert.equal(result.boostElapsedMs, 5 * HOUR);

  approximatelyEqual(
    result.boostAmount,
    0.5833 * 0.1 * 5,
  );
});

test("overlapping boosts use the highest hash rate, not their sum", () => {
  const now = new Date(
    START.getTime() + 5 * HOUR,
  );

  const records = [
    createBoostRecord({
      start: START.getTime() + HOUR,
      end: START.getTime() + 5 * HOUR,
      hashRateBonus: 0.5,
    }),
    createBoostRecord({
      start: START.getTime() + 2 * HOUR,
      end: START.getTime() + 4 * HOUR,
      hashRateBonus: 1.0,
    }),
  ];

  const result = calculateCompletedMining(
    createMiningData(),
    now,
    records,
  );

  // 1h × 0.5 HR + 2h × 1.0 HR + 1h × 0.5 HR
  assert.equal(result.boostElapsedMs, 4 * HOUR);

  approximatelyEqual(
    result.boostAmount,
    0.05 + 0.2 + 0.05,
  );
});

test("ignores Power Boost records from another mining cycle", () => {
  const now = new Date(
    START.getTime() + 5 * HOUR,
  );

  const result = calculateCompletedMining(
    createMiningData(),
    now,
    [
      createBoostRecord({
        miningStart: new Date(
          START.getTime() - DAY,
        ),
      }),
    ],
  );

  assert.equal(result.boostAmount, 0);
  assert.equal(result.boostElapsedMs, 0);
});

test("ignores invalid Power Boost history records", () => {
  const now = new Date(
    START.getTime() + 5 * HOUR,
  );

  const result = calculateCompletedMining(
    createMiningData(),
    now,
    [
      null,
      {},
      createBoostRecord({
        hashRateBonus: 0,
      }),
      createBoostRecord({
        type: "other_event",
      }),
    ],
  );

  assert.equal(result.boostAmount, 0);
  assert.equal(result.boostElapsedMs, 0);
});

// ============================================================
// CURRENT MINING
// ============================================================

test("current mining uses the same calculation as completed mining", () => {
  const now = new Date(
    START.getTime() + 5 * HOUR,
  );

  const data = createMiningData({
    powerBoostStartedAt: new Date(
      START.getTime() + HOUR,
    ),
    powerBoostEndsAt: new Date(
      START.getTime() + 5 * HOUR,
    ),
    powerBoostHashRate: 0.5833,
  });

  const current = calculateCurrentMining(
    data,
    now,
  );

  const completed = calculateCompletedMining(
    data,
    now,
  );

  approximatelyEqual(
    current.baseAmount,
    completed.baseAmount,
  );

  approximatelyEqual(
    current.boostAmount,
    completed.boostAmount,
  );

  approximatelyEqual(
    current.totalAmount,
    completed.totalAmount,
  );
});
