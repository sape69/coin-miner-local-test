
"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");

const {
  timestampMs,
} = require("../src/utils/mining/timestampUtils");

const EXPECTED_MS = Date.parse("2026-01-01T12:34:56.789Z");

// ============================================================
// MISSING AND INVALID VALUES
// ============================================================

test("returns zero for missing values", () => {
  assert.equal(timestampMs(null), 0);
  assert.equal(timestampMs(undefined), 0);
  assert.equal(timestampMs(""), 0);
  assert.equal(timestampMs(0), 0);
});

test("returns zero for unsupported and invalid values", () => {
  assert.equal(timestampMs({}), 0);
  assert.equal(timestampMs("not-a-date"), 0);
  assert.equal(timestampMs(NaN), 0);
  assert.equal(timestampMs(Infinity), 0);
  assert.equal(timestampMs(-Infinity), 0);
});

// ============================================================
// JAVASCRIPT DATE
// ============================================================

test("converts a valid JavaScript Date to milliseconds", () => {
  assert.equal(
    timestampMs(new Date(EXPECTED_MS)),
    EXPECTED_MS,
  );
});

test("returns zero for an invalid JavaScript Date", () => {
  assert.equal(timestampMs(new Date(NaN)), 0);
});

// ============================================================
// FIRESTORE TIMESTAMP
// ============================================================

test("uses Firestore Timestamp toMillis()", () => {
  assert.equal(
    timestampMs({
      toMillis: () => EXPECTED_MS,
    }),
    EXPECTED_MS,
  );
});

test("falls back to Firestore Timestamp toDate()", () => {
  assert.equal(
    timestampMs({
      toDate: () => new Date(EXPECTED_MS),
    }),
    EXPECTED_MS,
  );
});

test("returns zero when Firestore conversion methods throw", () => {
  assert.equal(
    timestampMs({
      toMillis: () => {
        throw new Error("toMillis failed");
      },
    }),
    0,
  );

  assert.equal(
    timestampMs({
      toDate: () => {
        throw new Error("toDate failed");
      },
    }),
    0,
  );
});

test("returns zero when Firestore conversion results are invalid", () => {
  assert.equal(
    timestampMs({
      toMillis: () => NaN,
    }),
    0,
  );

  assert.equal(
    timestampMs({
      toDate: () => "not-a-date",
    }),
    0,
  );
});

test("prefers toMillis() when both Firestore methods exist", () => {
  assert.equal(
    timestampMs({
      toMillis: () => EXPECTED_MS,
      toDate: () => new Date(0),
    }),
    EXPECTED_MS,
  );
});

// ============================================================
// ISO DATE STRINGS
// ============================================================

test("converts a valid ISO date string to milliseconds", () => {
  assert.equal(
    timestampMs("2026-01-01T12:34:56.789Z"),
    EXPECTED_MS,
  );
});

test("returns zero for invalid date strings", () => {
  assert.equal(timestampMs("invalid-date"), 0);
  assert.equal(timestampMs("   "), 0);
});

// ============================================================
// NUMERIC MILLISECONDS
// ============================================================

test("accepts finite numeric milliseconds", () => {
  assert.equal(timestampMs(EXPECTED_MS), EXPECTED_MS);
  assert.equal(timestampMs(-1000), -1000);
});
