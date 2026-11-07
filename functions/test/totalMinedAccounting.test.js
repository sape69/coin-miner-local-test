
"use strict";

// ============================================================
// 🐱 STELLURIINI - TOTAL MINED ACCOUNTING TESTS
// ============================================================
//
// Varmistaa, että STL-saavutukset perustuvat elinkaaren
// aikana louhittuun STL-määrään (totalMined), eivät
// miningBalance-saldoon.
//
// miningBalance voi sisältää myös achievement- ja
// referral-palkkioita, joita ei lasketa louhintatuotoksi.
//
// Nämä ovat yksikkötestejä. Ne eivät käytä Firestorea
// eivätkä muuta käyttäjien saldoja.
// ============================================================

const test = require("node:test");
const assert = require("node:assert/strict");

// ============================================================
// FIREBASE ADMIN INITIALIZATION
// ============================================================
//
// achievementFunctions.js hakee Firestore-yhteyden
// tiedoston lataamisen yhteydessä.
//
// Alustetaan Firebase Admin ensin, jotta getFirestore()
// löytää oletussovelluksen.
// ============================================================

require("../src/firebase/firebase");

// ============================================================
// IMPORT ACHIEVEMENT FUNCTIONS
// ============================================================

const {
  getHistoricalAchievementProgress,
  buildAchievementBalanceUpdate,
} = require("../src/functions/achievementFunctions");

function achievement(id) {
  return { id };
}

// ============================================================
// TEST 1: STL PROGRESS USES totalMined
// ============================================================

test("STL achievement progress uses totalMined, not miningBalance", () => {
  const progress = getHistoricalAchievementProgress(
    achievement("stl_hunter"),
    {
      totalMined: 125,
      miningBalance: 925,
    },
  );

  assert.equal(progress, 125);
});

// ============================================================
// TEST 2: REWARD BALANCE DOES NOT INCREASE MINED PROGRESS
// ============================================================

test("achievement and referral rewards in miningBalance do not increase STL progress", () => {
  const progress = getHistoricalAchievementProgress(
    achievement("stl_collector"),
    {
      totalMined: 40,
      miningBalance: 1040,
    },
  );

  assert.equal(progress, 40);
});

// ============================================================
// TEST 3: MISSING totalMined IS SAFE
// ============================================================

test("missing totalMined produces zero STL achievement progress", () => {
  const progress = getHistoricalAchievementProgress(
    achievement("stl_master"),
    {
      miningBalance: 5000,
    },
  );

  assert.equal(progress, 0);
});

// ============================================================
// TEST 4: INVALID totalMined IS SAFE
// ============================================================

test("invalid totalMined does not fall back to miningBalance", () => {
  const invalidValues = [
    undefined,
    null,
    -1,
    NaN,
    Infinity,
    "not-a-number",
  ];

  for (const value of invalidValues) {
    const progress = getHistoricalAchievementProgress(
      achievement("stl_tycoon"),
      {
        totalMined: value,
        miningBalance: 999999,
      },
    );

    assert.equal(
      progress,
      0,
      `Invalid totalMined value ${String(value)} must not use miningBalance.`,
    );
  }
});

// ============================================================
// TEST 5: ACHIEVEMENT REWARD UPDATES BALANCE ONLY
// ============================================================

test("achievement reward update does not modify totalMined", () => {
  const update = buildAchievementBalanceUpdate(
    25,
    new Date("2026-01-01T00:00:00.000Z"),
  );

  assert.ok(update);

  assert.deepEqual(
    Object.keys(update).sort(),
    ["miningBalance", "updatedAt"].sort(),
  );

  assert.equal(
    Object.prototype.hasOwnProperty.call(update, "totalMined"),
    false,
  );
});

// ============================================================
// TEST 6: ZERO REWARD DOES NOT CREATE A BALANCE UPDATE
// ============================================================

test("zero achievement reward creates no balance update", () => {
  assert.equal(
    buildAchievementBalanceUpdate(
      0,
      new Date("2026-01-01T00:00:00.000Z"),
    ),
    null,
  );
});
