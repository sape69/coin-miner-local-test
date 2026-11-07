
"use strict";

// ============================================================
// 🐱 STELLURIINI - CLAIM MINING ACCOUNTING INTEGRATION TEST
// ============================================================
//
// Testaa oikeaa claimMining Callable -toimintoa
// Firestore Emulatorissa.
//
// Varmistaa:
// 1. Päättynyt mining cycle kerätään.
// 2. Louhinta lisätään miningBalance-saldoon.
// 3. Louhinta lisätään totalMined-arvoon.
// 4. Achievement reward ei kasvata totalMined-arvoa.
// 5. Sama mining cycle ei tule kerätyksi kahdesti.
// 6. Mining reward -historiaan syntyy vain yksi tapahtuma.
//
// ============================================================

const {
  test,
  after,
} = require("node:test");

const assert = require("node:assert/strict");

// ============================================================
// FIRESTORE EMULATOR REQUIREMENT
// ============================================================

if (!process.env.FIRESTORE_EMULATOR_HOST) {
  throw new Error(
    "These tests require FIRESTORE_EMULATOR_HOST.",
  );
}

// ============================================================
// FIREBASE ADMIN INITIALIZATION
// ============================================================

const {
  db,
} = require("../src/firebase/firebase");

// ============================================================
// MINING FUNCTION
// ============================================================

const {
  claimMining,
} = require("../src/functions/miningFunctions");

// ============================================================
// TEST CONFIGURATION
// ============================================================

const testPrefix =
  `claim-mining-accounting-${Date.now()}`;

const uid =
  `${testPrefix}-user`;

const userRef =
  db.collection("users").doc(uid);

const historyRef =
  userRef.collection("transactions");

const achievementRef =
  userRef.collection("achievements");

// ============================================================
// CLEANUP HELPERS
// ============================================================

async function deleteCollection(collectionRef) {
  const snapshot =
    await collectionRef.get();

  if (snapshot.empty) {
    return;
  }

  const batch =
    db.batch();

  snapshot.docs.forEach((doc) => {
    batch.delete(doc.ref);
  });

  await batch.commit();
}

async function cleanupTestData() {
  await deleteCollection(historyRef);

  await deleteCollection(achievementRef);

  await userRef.delete().catch(() => {});
}

// ============================================================
// CLEANUP AFTER TESTS
// ============================================================

after(async () => {
  await cleanupTestData();
});

// ============================================================
// TEST: CLAIM MINING ACCOUNTING
// ============================================================

test(
  "claimMining credits completed mining exactly once to totalMined and balance",
  async () => {
    const now =
      Date.now();

    const miningDurationMs =
      24 * 60 * 60 * 1000;

    const cycleEnd =
      new Date(now - 60_000);

    const cycleStart =
      new Date(
        cycleEnd.getTime() -
        miningDurationMs
      );

    const initialBalance =
      100;

    const initialTotalMined =
      25;

    // --------------------------------------------------------
    // SEED USER WITH A COMPLETED MINING CYCLE
    // --------------------------------------------------------

    await userRef.set({
      uid,

      username:
        "Stella Test Miner",

      miningBalance:
        initialBalance,

      totalMined:
        initialTotalMined,

      totalMinedInitialized:
        true,

      hashRate:
        1,

      miningHashRate:
        1,

      miningStreak:
        1,

      miningCycles:
        0,

      miningHalvingMultiplier:
        1,

      miningStartedAt:
        cycleStart,

      miningEndsAt:
        cycleEnd,

      lastMiningDate:
        new Date(
          cycleStart.getTime()
        ).toISOString().slice(0, 10),

      adBoostStartedAt:
        null,

      adBoostEndsAt:
        null,

      lastAdRewardAt:
        null,

      powerBoostTransactionId:
        null,

      adsToday:
        0,

      lastAdDate:
        null,

      createdAt:
        new Date(),

      updatedAt:
        new Date(),
    });

    // --------------------------------------------------------
    // FIRST CLAIM
    // --------------------------------------------------------

    const firstResult =
      await claimMining.run({
        auth: {
          uid,
        },

        data: {},
      });

    assert.equal(
      firstResult.success,
      true,
      "First claim must succeed.",
    );

    assert.equal(
      firstResult.started,
      true,
      "First claim must start a new mining cycle.",
    );

    assert.equal(
      firstResult.completedPreviousCycle,
      true,
      "Previous mining cycle must be completed.",
    );

    const collected =
      Number(firstResult.collected);

    const achievementReward =
      Number(
        firstResult.achievementReward || 0
      );

    assert.ok(
      Number.isFinite(collected) &&
      collected > 0,
      "Completed mining must produce a positive STL amount.",
    );

    // --------------------------------------------------------
    // VERIFY USER BALANCE
    // --------------------------------------------------------

    const afterFirstSnapshot =
      await userRef.get();

    assert.equal(
      afterFirstSnapshot.exists,
      true,
    );

    const afterFirst =
      afterFirstSnapshot.data();

    const expectedBalance =
      initialBalance +
      collected +
      achievementReward;

    assert.ok(
      Math.abs(
        afterFirst.miningBalance -
        expectedBalance
      ) < 0.0000001,
      "Mining balance must include mining and achievement rewards exactly once.",
    );

    // --------------------------------------------------------
    // VERIFY totalMined
    // --------------------------------------------------------

    const expectedTotalMined =
      initialTotalMined +
      collected;

    assert.ok(
      Math.abs(
        afterFirst.totalMined -
        expectedTotalMined
      ) < 0.0000001,
      "totalMined must increase only by the actual mining amount.",
    );

    assert.equal(
      afterFirst.totalMinedInitialized,
      true,
      "totalMined initialization flag must remain true.",
    );

    // --------------------------------------------------------
    // VERIFY MINING HISTORY
    // --------------------------------------------------------

    const firstHistorySnapshot =
      await historyRef
        .where(
          "type",
          "==",
          "mining_reward"
        )
        .get();

    assert.equal(
      firstHistorySnapshot.size,
      1,
      "Exactly one mining_reward history entry must exist.",
    );

    const historyEntry =
      firstHistorySnapshot.docs[0].data();

    assert.ok(
      Math.abs(
        Number(historyEntry.amount) -
        collected
      ) < 0.0000001,
      "Mining history amount must match collected mining.",
    );

    // --------------------------------------------------------
    // SECOND CLAIM
    // --------------------------------------------------------
    //
    // The first claim already started a new active cycle.
    // A second claim must not collect the previous cycle again.
    //
    // --------------------------------------------------------

    const secondResult =
      await claimMining.run({
        auth: {
          uid,
        },

        data: {},
      });

    assert.equal(
      secondResult.success,
      true,
      "Second claim must succeed.",
    );

    assert.equal(
      secondResult.started,
      false,
      "Second claim must not start another mining cycle.",
    );

    assert.equal(
      secondResult.collected,
      0,
      "Second claim must not collect mining again.",
    );

    // --------------------------------------------------------
    // VERIFY NO DUPLICATE ACCOUNTING
    // --------------------------------------------------------

    const afterSecondSnapshot =
      await userRef.get();

    const afterSecond =
      afterSecondSnapshot.data();

    assert.ok(
      Math.abs(
        afterSecond.totalMined -
        expectedTotalMined
      ) < 0.0000001,
      "Second claim must not increase totalMined again.",
    );

    assert.ok(
      Math.abs(
        afterSecond.miningBalance -
        expectedBalance
      ) < 0.0000001,
      "Second claim must not increase miningBalance again.",
    );

    // --------------------------------------------------------
    // VERIFY NO DUPLICATE MINING HISTORY
    // --------------------------------------------------------

    const finalHistorySnapshot =
      await historyRef
        .where(
          "type",
          "==",
          "mining_reward"
        )
        .get();

    assert.equal(
      finalHistorySnapshot.size,
      1,
      "Second claim must not create a duplicate mining_reward entry.",
    );
  },
);
