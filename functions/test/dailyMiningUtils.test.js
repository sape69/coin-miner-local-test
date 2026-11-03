
"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");

const {
  MINING_STREAK_GRACE_MS,
  dailyHashRate,
  dailyHashRateBonus,
  dailyStreak,
  nextDailyClaim,
  nextDailyHashRate,
  nextDailyStreak,
} = require("../src/utils/mining/dailyMiningUtils");

const HOUR = 60 * 60 * 1000;
const DAY = 24 * HOUR;

const START = new Date("2026-01-01T00:00:00.000Z");
const END = new Date(START.getTime() + DAY);

const TODAY = "2026-01-01";
const YESTERDAY = "2025-12-31";

// ============================================================
// DAILY HASH RATE
// ============================================================

test("calculates daily hash rate for days 1 to 7", () => {
  assert.equal(dailyHashRate(1), 0.5);
  assert.equal(dailyHashRate(2), 1.0);
  assert.equal(dailyHashRate(3), 1.5);
  assert.equal(dailyHashRate(4), 2.0);
  assert.equal(dailyHashRate(5), 2.5);
  assert.equal(dailyHashRate(6), 3.0);
  assert.equal(dailyHashRate(7), 3.5);
});

test("caps daily hash rate at 3.5 after day 7", () => {
  assert.equal(dailyHashRate(8), 3.5);
  assert.equal(dailyHashRate(30), 3.5);
  assert.equal(dailyHashRate(365), 3.5);
});

test("uses day 1 hash rate for zero and negative streaks", () => {
  assert.equal(dailyHashRate(0), 0.5);
  assert.equal(dailyHashRate(-1), 0.5);
  assert.equal(dailyHashRate(-10), 0.5);
});

test("floors fractional streak values", () => {
  assert.equal(dailyHashRate(2.9), 1.0);
  assert.equal(dailyHashRate(6.9), 3.0);
});

test("handles invalid streak values safely", () => {
  assert.equal(dailyHashRate(NaN), 0.5);
  assert.equal(dailyHashRate(Infinity), 0.5);
  assert.equal(dailyHashRate("invalid"), 0.5);
});

// ============================================================
// DAILY HASH RATE BONUS
// ============================================================

test("calculates daily hash rate bonus", () => {
  assert.equal(dailyHashRateBonus(1), 0);
  assert.equal(dailyHashRateBonus(2), 0.5);
  assert.equal(dailyHashRateBonus(3), 1.0);
  assert.equal(dailyHashRateBonus(7), 3.0);
  assert.equal(dailyHashRateBonus(10), 3.0);
});

test("never returns a negative daily hash rate bonus", () => {
  assert.equal(dailyHashRateBonus(0), 0);
  assert.equal(dailyHashRateBonus(-5), 0);
});

// ============================================================
// DAILY STREAK
// ============================================================

test("reads dailyStreak from user data", () => {
  assert.equal(
    dailyStreak({ dailyStreak: 5 }),
    5,
  );
});

test("uses streak as a compatibility fallback", () => {
  assert.equal(
    dailyStreak({ streak: 4 }),
    4,
  );
});

test("prefers dailyStreak over streak", () => {
  assert.equal(
    dailyStreak({
      dailyStreak: 5,
      streak: 2,
    }),
    5,
  );
});

test("floors fractional daily streak values", () => {
  assert.equal(
    dailyStreak({ dailyStreak: 3.9 }),
    3,
  );
});

test("returns zero for invalid daily streak values", () => {
  assert.equal(dailyStreak({}), 0);
  assert.equal(dailyStreak({ dailyStreak: -5 }), 0);
  assert.equal(dailyStreak({ dailyStreak: "invalid" }), 0);
});

// ============================================================
// GRACE PERIOD CONFIGURATION
// ============================================================

test("uses a 24-hour mining streak grace period", () => {
  assert.equal(MINING_STREAK_GRACE_MS, DAY);
});

// ============================================================
// NEXT DAILY CLAIM WITHOUT MINING WINDOW
// ============================================================

test("marks today as already claimed", () => {
  const result = nextDailyClaim(
    {
      lastDailyDate: TODAY,
      dailyStreak: 3,
    },
    TODAY,
    START.getTime(),
  );

  assert.equal(result.claimedToday, true);
  assert.equal(result.streak, 3);
  assert.equal(result.dailyHashRate, 1.5);
});

test("continues streak when previous claim was yesterday", () => {
  const result = nextDailyClaim(
    {
      lastDailyDate: YESTERDAY,
      dailyStreak: 3,
    },
    TODAY,
    START.getTime(),
  );

  assert.equal(result.claimedToday, false);
  assert.equal(result.streak, 4);
  assert.equal(result.dailyHashRate, 2.0);
});

test("starts streak at day 1 when previous claim was older", () => {
  const result = nextDailyClaim(
    {
      lastDailyDate: "2025-12-29",
      dailyStreak: 5,
    },
    TODAY,
    START.getTime(),
  );

  assert.equal(result.claimedToday, false);
  assert.equal(result.streak, 1);
  assert.equal(result.dailyHashRate, 0.5);
});

test("starts streak at day 1 when no previous claim exists", () => {
  const result = nextDailyClaim(
    {},
    TODAY,
    START.getTime(),
  );

  assert.equal(result.claimedToday, false);
  assert.equal(result.streak, 1);
  assert.equal(result.dailyHashRate, 0.5);
});

// ============================================================
// ACTIVE MINING WINDOW
// ============================================================

test("keeps current streak during active mining", () => {
  const result = nextDailyClaim(
    {
      dailyStreak: 3,
      miningStartedAt: START,
      miningEndsAt: END,
    },
    TODAY,
    START.getTime() + HOUR,
  );

  assert.equal(result.claimedToday, true);
  assert.equal(result.streak, 3);
  assert.equal(result.dailyHashRate, 1.5);
});

test("uses day 1 when active mining has no previous streak", () => {
  const result = nextDailyClaim(
    {
      miningStartedAt: START,
      miningEndsAt: END,
    },
    TODAY,
    START.getTime() + HOUR,
  );

  assert.equal(result.claimedToday, true);
  assert.equal(result.streak, 1);
  assert.equal(result.dailyHashRate, 0.5);
});

// ============================================================
// MINING END AND GRACE PERIOD
// ============================================================

test("continues streak when mining ends", () => {
  const result = nextDailyClaim(
    {
      dailyStreak: 3,
      miningStartedAt: START,
      miningEndsAt: END,
    },
    "2026-01-02",
    END.getTime(),
  );

  assert.equal(result.claimedToday, false);
  assert.equal(result.streak, 4);
  assert.equal(result.dailyHashRate, 2.0);
});

test("continues streak inside the grace period", () => {
  const result = nextDailyClaim(
    {
      dailyStreak: 3,
      miningStartedAt: START,
      miningEndsAt: END,
    },
    "2026-01-02",
    END.getTime() + 12 * HOUR,
  );

  assert.equal(result.claimedToday, false);
  assert.equal(result.streak, 4);
  assert.equal(result.dailyHashRate, 2.0);
});

test("continues streak exactly at the grace deadline", () => {
  const result = nextDailyClaim(
    {
      dailyStreak: 3,
      miningStartedAt: START,
      miningEndsAt: END,
    },
    "2026-01-03",
    END.getTime() + MINING_STREAK_GRACE_MS,
  );

  assert.equal(result.claimedToday, false);
  assert.equal(result.streak, 4);
  assert.equal(result.dailyHashRate, 2.0);
});

test("resets streak after the grace period expires", () => {
  const result = nextDailyClaim(
    {
      dailyStreak: 5,
      miningStartedAt: START,
      miningEndsAt: END,
    },
    "2026-01-03",
    END.getTime() + MINING_STREAK_GRACE_MS + 1,
  );

  assert.equal(result.claimedToday, false);
  assert.equal(result.streak, 1);
  assert.equal(result.dailyHashRate, 0.5);
});

test("starts at day 1 during grace period when no streak exists", () => {
  const result = nextDailyClaim(
    {
      miningStartedAt: START,
      miningEndsAt: END,
    },
    "2026-01-02",
    END.getTime() + HOUR,
  );

  assert.equal(result.claimedToday, false);
  assert.equal(result.streak, 1);
  assert.equal(result.dailyHashRate, 0.5);
});

// ============================================================
// NEXT DAILY HASH RATE
// ============================================================

test("returns current hash rate when daily claim is available", () => {
  const result = nextDailyHashRate(
    {
      lastDailyDate: YESTERDAY,
      dailyStreak: 2,
    },
    TODAY,
    START.getTime(),
  );

  assert.equal(result, 1.5);
});

test("returns next day's hash rate when already claimed", () => {
  const result = nextDailyHashRate(
    {
      lastDailyDate: TODAY,
      dailyStreak: 2,
    },
    TODAY,
    START.getTime(),
  );

  assert.equal(result, 1.5);
});

// ============================================================
// NEXT DAILY STREAK
// ============================================================

test("returns next streak when daily claim is available", () => {
  const result = nextDailyStreak(
    {
      lastDailyDate: YESTERDAY,
      dailyStreak: 2,
    },
    TODAY,
    START.getTime(),
  );

  assert.equal(result, 3);
});

test("returns following streak when already claimed today", () => {
  const result = nextDailyStreak(
    {
      lastDailyDate: TODAY,
      dailyStreak: 2,
    },
    TODAY,
    START.getTime(),
  );

  assert.equal(result, 3);
});
