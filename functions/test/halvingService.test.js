
"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");

const {
  getHalvingLevel,
} = require("../src/services/halvingService");

// ============================================================
// 🐱 STELLURIINI - HALVING SERVICE TESTS
// ============================================================

test("uses multiplier 1.0 below 100 registered users", () => {
  const result = getHalvingLevel(0);

  assert.equal(result.registeredUserCount, 0);
  assert.equal(result.multiplier, 1.0);
  assert.equal(result.currentMilestone.users, 0);
  assert.equal(result.nextMilestone.users, 100);
});

test("uses multiplier 1.0 for 99 registered users", () => {
  const result = getHalvingLevel(99);

  assert.equal(result.multiplier, 1.0);
  assert.equal(result.nextMilestone.usersRemaining, 1);
});

test("activates first halving at 100 registered users", () => {
  const result = getHalvingLevel(100);

  assert.equal(result.multiplier, 0.5);
  assert.equal(result.currentMilestone.users, 100);
  assert.equal(result.nextMilestone.users, 1000);
});

test("uses multiplier 0.5 below 1000 registered users", () => {
  const result = getHalvingLevel(999);

  assert.equal(result.multiplier, 0.5);
  assert.equal(result.nextMilestone.usersRemaining, 1);
});

test("activates second halving at 1000 registered users", () => {
  const result = getHalvingLevel(1000);

  assert.equal(result.multiplier, 0.25);
  assert.equal(result.currentMilestone.users, 1000);
});

test("activates third halving at 10000 registered users", () => {
  const result = getHalvingLevel(10000);

  assert.equal(result.multiplier, 0.125);
});

test("activates fourth halving at 100000 registered users", () => {
  const result = getHalvingLevel(100000);

  assert.equal(result.multiplier, 0.0625);
});

test("activates fifth halving at 1000000 registered users", () => {
  const result = getHalvingLevel(1000000);

  assert.equal(result.multiplier, 0.03125);
});

test("activates sixth halving at 10000000 registered users", () => {
  const result = getHalvingLevel(10000000);

  assert.equal(result.multiplier, 0.015625);
});

test("activates final configured halving at 100000000 users", () => {
  const result = getHalvingLevel(100000000);

  assert.equal(result.multiplier, 0.0078125);
  assert.equal(result.currentMilestone.users, 100000000);
  assert.equal(result.nextMilestone, null);
});

test("keeps final multiplier above the last milestone", () => {
  const result = getHalvingLevel(200000000);

  assert.equal(result.multiplier, 0.0078125);
  assert.equal(result.nextMilestone, null);
});

test("floors fractional registered user counts", () => {
  assert.equal(
    getHalvingLevel(99.9).multiplier,
    1.0,
  );

  assert.equal(
    getHalvingLevel(100.9).multiplier,
    0.5,
  );
});

test("handles negative user counts safely", () => {
  const result = getHalvingLevel(-100);

  assert.equal(result.registeredUserCount, 0);
  assert.equal(result.multiplier, 1.0);
});

test("handles invalid user counts safely", () => {
  assert.equal(
    getHalvingLevel(NaN).multiplier,
    1.0,
  );

  assert.equal(
    getHalvingLevel(Infinity).multiplier,
    1.0,
  );

  assert.equal(
    getHalvingLevel("invalid").multiplier,
    1.0,
  );
});

test("reports the configured base mining rate", () => {
  const result = getHalvingLevel(0);

  assert.equal(result.miningPerHashPerHour, 0.10);
  assert.equal(
    result.effectiveMiningPerHashPerHour,
    0.10,
  );
});

test("calculates effective mining rate after halving", () => {
  const result = getHalvingLevel(100);

  assert.equal(result.miningPerHashPerHour, 0.10);
  assert.equal(
    result.effectiveMiningPerHashPerHour,
    0.05,
  );
});

test("reports halving configuration status", () => {
  const result = getHalvingLevel(0);

  assert.equal(
    result.halvingEnabled,
    true,
  );
});
