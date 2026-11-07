
"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");

const {
  getHalvingLevel,
} = require("../src/services/halvingService");

const {
  getHalvingMultiplier,
  getEffectiveMiningRate,
  calculateMining,
} = require("../src/utils/miningUtils");

// ============================================================
// 🐱 STELLURIINI - COMPLETE HALVING BOUNDARY TESTS
// ============================================================

const HALVING_LEVELS = [
  {
    users: 0,
    multiplier: 1.0,
    label: "Start",
  },
  {
    users: 100,
    multiplier: 0.5,
    label: "100",
  },
  {
    users: 1000,
    multiplier: 0.25,
    label: "1K",
  },
  {
    users: 10000,
    multiplier: 0.125,
    label: "10K",
  },
  {
    users: 100000,
    multiplier: 0.0625,
    label: "100K",
  },
  {
    users: 1000000,
    multiplier: 0.03125,
    label: "1M",
  },
  {
    users: 10000000,
    multiplier: 0.015625,
    label: "10M",
  },
  {
    users: 100000000,
    multiplier: 0.0078125,
    label: "100M",
  },
];

// ============================================================
// 1. VERIFY ALL EIGHT HALVING LEVELS
// ============================================================

test(
  "all eight configured halving levels return correct multipliers",
  () => {
    for (const level of HALVING_LEVELS) {
      const result = getHalvingLevel(level.users);

      assert.equal(
        result.multiplier,
        level.multiplier,
        `Wrong multiplier at ${level.users} users.`,
      );

      assert.equal(
        getHalvingMultiplier(level.users),
        level.multiplier,
        `Mining utility returned wrong multiplier at ${level.users} users.`,
      );

      assert.equal(
        result.currentMilestone.users,
        level.users,
        `Wrong current milestone at ${level.users} users.`,
      );
    }
  },
);

// ============================================================
// 2. VERIFY ONE USER BELOW EACH THRESHOLD
// ============================================================

test(
  "halving does not activate before its exact threshold",
  () => {
    for (let index = 1; index < HALVING_LEVELS.length; index += 1) {
      const currentLevel = HALVING_LEVELS[index];
      const previousLevel = HALVING_LEVELS[index - 1];

      const userCount = currentLevel.users - 1;

      const result = getHalvingLevel(userCount);

      assert.equal(
        result.multiplier,
        previousLevel.multiplier,
        `Halving activated too early at ${userCount} users.`,
      );

      assert.equal(
        getHalvingMultiplier(userCount),
        previousLevel.multiplier,
        `Mining utility activated halving too early at ${userCount} users.`,
      );

      assert.equal(
        result.nextMilestone.users,
        currentLevel.users,
        `Wrong next milestone below ${currentLevel.users}.`,
      );

      assert.equal(
        result.nextMilestone.usersRemaining,
        1,
        `Expected one remaining user below ${currentLevel.users}.`,
      );
    }
  },
);

// ============================================================
// 3. VERIFY ONE USER ABOVE EACH THRESHOLD
// ============================================================

test(
  "halving remains active one user above every threshold",
  () => {
    for (const level of HALVING_LEVELS) {
      const userCount = level.users + 1;

      const result = getHalvingLevel(userCount);

      assert.equal(
        result.multiplier,
        level.multiplier,
        `Wrong multiplier at ${userCount} users.`,
      );

      assert.equal(
        getHalvingMultiplier(userCount),
        level.multiplier,
        `Mining utility returned wrong multiplier at ${userCount} users.`,
      );
    }
  },
);

// ============================================================
// 4. VERIFY ALL MINING RATES
// ============================================================

test(
  "effective mining rate is correct at all eight levels",
  () => {
    const baseRate = 0.10;

    for (const level of HALVING_LEVELS) {
      const result = getHalvingLevel(level.users);

      const expectedRate =
        baseRate * level.multiplier;

      assert.equal(
        result.miningPerHashPerHour,
        baseRate,
        `Base rate changed at ${level.users} users.`,
      );

      assert.equal(
        result.effectiveMiningPerHashPerHour,
        expectedRate,
        `Wrong effective rate at ${level.users} users.`,
      );

      assert.equal(
        getEffectiveMiningRate(level.multiplier),
        expectedRate,
        `Mining utility returned wrong rate at ${level.users} users.`,
      );
    }
  },
);

// ============================================================
// 5. VERIFY ACTUAL MINING CALCULATION
// ============================================================

test(
  "one hour of mining uses the correct halving multiplier",
  () => {
    const hashRate = 1;
    const oneHour = 60 * 60 * 1000;

    for (const level of HALVING_LEVELS) {
      const expectedMining =
        hashRate *
        0.10 *
        level.multiplier;

      const actualMining = calculateMining(
        hashRate,
        oneHour,
        level.multiplier,
      );

      assert.ok(
        Math.abs(actualMining - expectedMining) < 0.000000001,
        `Wrong mining amount at ${level.users} users. ` +
        `Expected ${expectedMining}, received ${actualMining}.`,
      );
    }
  },
);

// ============================================================
// 6. VERIFY FINAL LEVEL HAS NO NEXT MILESTONE
// ============================================================

test(
  "final halving level remains active above 100 million users",
  () => {
    const testCounts = [
      100000000,
      100000001,
      200000000,
      1000000000,
    ];

    for (const userCount of testCounts) {
      const result = getHalvingLevel(userCount);

      assert.equal(
        result.multiplier,
        0.0078125,
      );

      assert.equal(
        result.nextMilestone,
        null,
      );
    }
  },
);

// ============================================================
// 7. VERIFY FRACTIONAL USER COUNTS
// ============================================================

test(
  "fractional registered user counts are floored",
  () => {
    assert.equal(
      getHalvingLevel(99.9).multiplier,
      1.0,
    );

    assert.equal(
      getHalvingLevel(100.9).multiplier,
      0.5,
    );

    assert.equal(
      getHalvingLevel(999.9).multiplier,
      0.5,
    );

    assert.equal(
      getHalvingLevel(1000.9).multiplier,
      0.25,
    );

    assert.equal(
      getHalvingMultiplier(100.9),
      0.5,
    );
  },
);

// ============================================================
// 8. VERIFY NEGATIVE USER COUNTS
// ============================================================

test(
  "negative user counts are safely normalized to zero",
  () => {
    const result = getHalvingLevel(-100);

    assert.equal(
      result.registeredUserCount,
      0,
    );

    assert.equal(
      result.multiplier,
      1.0,
    );

    assert.equal(
      getHalvingMultiplier(-100),
      1.0,
    );
  },
);

// ============================================================
// 9. VERIFY INVALID USER COUNTS
// ============================================================

test(
  "invalid user counts safely use the initial multiplier",
  () => {
    const invalidValues = [
      NaN,
      Infinity,
      -Infinity,
      "invalid",
      undefined,
      null,
    ];

    for (const value of invalidValues) {
      assert.equal(
        getHalvingLevel(value).multiplier,
        1.0,
        `Halving service failed for ${String(value)}.`,
      );

      assert.equal(
        getHalvingMultiplier(value),
        1.0,
        `Mining utility failed for ${String(value)}.`,
      );
    }
  },
);

// ============================================================
// 10. VERIFY HALVING CONFIGURATION
// ============================================================

test(
  "halving is enabled",
  () => {
    const result = getHalvingLevel(0);

    assert.equal(
      result.halvingEnabled,
      true,
    );
  },
);

// ============================================================
// 11. VERIFY INITIAL MINING RATE
// ============================================================

test(
  "initial mining rate is 0.10 STL per hash per hour",
  () => {
    const result = getHalvingLevel(0);

    assert.equal(
      result.miningPerHashPerHour,
      0.10,
    );

    assert.equal(
      result.effectiveMiningPerHashPerHour,
      0.10,
    );
  },
);

// ============================================================
// 12. VERIFY FIRST HALVING RATE
// ============================================================

test(
  "100 users reduce the effective mining rate to 0.05",
  () => {
    const result = getHalvingLevel(100);

    assert.equal(
      result.miningPerHashPerHour,
      0.10,
    );

    assert.equal(
      result.effectiveMiningPerHashPerHour,
      0.05,
    );
  },
);

// ============================================================
// 13. VERIFY NEXT MILESTONE INFORMATION
// ============================================================

test(
  "next milestone information is correct at every level",
  () => {
    for (
      let index = 0;
      index < HALVING_LEVELS.length - 1;
      index += 1
    ) {
      const current = HALVING_LEVELS[index];
      const next = HALVING_LEVELS[index + 1];

      const result = getHalvingLevel(current.users);

      assert.equal(
        result.nextMilestone.users,
        next.users,
      );

      assert.equal(
        result.nextMilestone.multiplier,
        next.multiplier,
      );

      assert.equal(
        result.nextMilestone.label,
        next.label,
      );

      assert.equal(
        result.nextMilestone.usersRemaining,
        next.users - current.users,
      );
    }
  },
);

console.log(
  "🐱 Stelluriini halving boundary tests loaded.",
);
