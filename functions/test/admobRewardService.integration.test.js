
"use strict";

// ============================================================
// 🐱 STELLURIINI - ADMOB POWER BOOST REWARD TESTS
// ============================================================
//
// Testaa Firestore-emulaattorissa tallennetun AdMob-palkinnon
// Power Boost -validointia.
//
// Testit:
// 1. Kelvollinen Power Boost -palkinto hyväksytään.
// 2. Väärän käyttäjän UID hylätään.
// 3. Väärä reward purpose hylätään.
// 4. Jo käytetty palkinto hylätään.
//
// HUOM:
// Tämä testaa reward-validointia.
// Se ei vielä testaa koko powerBoost-callablea,
// hash raten muutosta tai päivittäistä mainosrajaa.
//
// ============================================================

const {
  test,
  after,
} = require("node:test");

const assert = require("node:assert/strict");

if (!process.env.FIRESTORE_EMULATOR_HOST) {
  throw new Error(
    "These tests require FIRESTORE_EMULATOR_HOST.",
  );
}

const {
  db,
} = require("../src/firebase/firebase");

const {
  validateVerifiedRewardDocument,
} = require("../src/services/admobRewardService");

// ============================================================
// TEST DATA
// ============================================================

const testPrefix = `power-boost-${Date.now()}`;

const testUid = `${testPrefix}-user`;

const rewardRefs = [];

const referenceNowMs = Date.now();

const validTransactionId =
  `${testPrefix}-transaction-valid`;

function createRewardData(overrides = {}) {
  return {
    verified: true,

    uid: testUid,

    rewardPurpose: "power_boost",

    transactionId: validTransactionId,

    timestamp: new Date(referenceNowMs),

    powerBoostClaimed: false,

    rewardConsumed: false,

    ...overrides,
  };
}

async function createRewardDocument(
  transactionId,
  data,
) {
  const ref = db
    .collection("admobRewards")
    .doc(transactionId);

  rewardRefs.push(ref);

  await ref.set(data);

  return ref.get();
}

// ============================================================
// CLEANUP
// ============================================================

after(async () => {
  for (const ref of rewardRefs) {
    await ref.delete();
  }
});

// ============================================================
// TEST 1: VALID POWER BOOST REWARD
// ============================================================

test(
  "valid verified Power Boost reward is accepted",
  async () => {
    const transactionId =
      validTransactionId;

    const snapshot =
      await createRewardDocument(
        transactionId,
        createRewardData(),
      );

    const result =
      validateVerifiedRewardDocument(
        snapshot,
        testUid,
        "power_boost",
        "powerBoostClaimed",
        {
          referenceNowMs,
          transactionId,
        },
      );

    assert.equal(result.verified, true);

    assert.equal(result.uid, testUid);

    assert.equal(
      result.rewardPurpose,
      "power_boost",
    );

    assert.equal(
      result.transactionId,
      transactionId,
    );

    assert.equal(
      result.claimField,
      "powerBoostClaimed",
    );
  },
);

// ============================================================
// TEST 2: WRONG UID
// ============================================================

test(
  "Power Boost reward belonging to another UID is rejected",
  async () => {
    const transactionId =
      `${testPrefix}-wrong-uid`;

    const snapshot =
      await createRewardDocument(
        transactionId,
        createRewardData({
          transactionId,
          uid: `${testPrefix}-another-user`,
        }),
      );

    assert.throws(
      () => {
        validateVerifiedRewardDocument(
          snapshot,
          testUid,
          "power_boost",
          "powerBoostClaimed",
          {
            referenceNowMs,
            transactionId,
          },
        );
      },
      {
        code: "ADMOB_REWARD_UID_MISMATCH",
      },
    );
  },
);

// ============================================================
// TEST 3: WRONG REWARD PURPOSE
// ============================================================

test(
  "mining start reward cannot be used for Power Boost",
  async () => {
    const transactionId =
      `${testPrefix}-wrong-purpose`;

    const snapshot =
      await createRewardDocument(
        transactionId,
        createRewardData({
          transactionId,
          rewardPurpose: "mining_start",
        }),
      );

    assert.throws(
      () => {
        validateVerifiedRewardDocument(
          snapshot,
          testUid,
          "power_boost",
          "powerBoostClaimed",
          {
            referenceNowMs,
            transactionId,
          },
        );
      },
      {
        code: "ADMOB_REWARD_PURPOSE_MISMATCH",
      },
    );
  },
);

// ============================================================
// TEST 4: ALREADY CLAIMED REWARD
// ============================================================

test(
  "already claimed Power Boost reward cannot be reused",
  async () => {
    const transactionId =
      `${testPrefix}-already-claimed`;

    const snapshot =
      await createRewardDocument(
        transactionId,
        createRewardData({
          transactionId,
          powerBoostClaimed: true,
        }),
      );

    assert.throws(
      () => {
        validateVerifiedRewardDocument(
          snapshot,
          testUid,
          "power_boost",
          "powerBoostClaimed",
          {
            referenceNowMs,
            transactionId,
          },
        );
      },
      {
        code: "ADMOB_REWARD_ALREADY_CLAIMED",
      },
    );
  },
);
