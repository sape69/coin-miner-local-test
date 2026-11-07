
"use strict";

// ============================================================
// 🐱 STELLURIINI - HALVING TRANSITION INTEGRATION TEST
// ============================================================
//
// Testaa käyttäjän siirtymisen seuraavalle halving-tasolle:
//
// 1. Louhinta alkaa 99 käyttäjän tilanteessa kertoimella 1.0.
// 2. Käyttäjämäärä kasvaa sataan.
// 3. Aktiivinen jakso säilyttää kertoimen 1.0.
// 4. Vanha jakso päätetään.
// 5. Seuraava jakso käynnistyy kertoimella 0.5.
// 6. Vanhan jakson louhinta lasketaan vanhalla kertoimella.
// 7. Uuden jakson louhinta käyttää uutta kerrointa.
//
// ============================================================

const {
  test,
  after,
} = require("node:test");

const assert = require("node:assert/strict");

const {
  db,
} = require("../src/firebase/firebase");

const {
  claimMining,
  getMiningStatus,
} = require("../src/functions/miningFunctions");

const {
  getRegisteredUserCount,
} = require("../src/services/halvingService");

const testPrefix =
  `halving-transition-${Date.now()}`;

const testUid =
  `${testPrefix}-miner`;

const createdUserIds = new Set();

const userRef = db
  .collection("users")
  .doc(testUid);

// ============================================================
// FIRESTORE EMULATOR CHECK
// ============================================================

if (!process.env.FIRESTORE_EMULATOR_HOST) {
  throw new Error(
    "These tests require FIRESTORE_EMULATOR_HOST.",
  );
}

// ============================================================
// CREATE 99 REGISTERED USERS
// ============================================================

async function seedInitialUsers() {
  const batch = db.batch();

  // 98 muuta käyttäjää + varsinainen louhija = 99.
  for (let index = 1; index <= 98; index += 1) {
    const uid =
      `${testPrefix}-user-${index}`;

    createdUserIds.add(uid);

    batch.set(
      db.collection("users").doc(uid),
      {
        uid,
        username: `Halving Test ${index}`,
        miningBalance: 0,
        totalMined: 0,
        totalMinedInitialized: true,
        hashRate: 1,
        miningHashRate: 1,
        miningStreak: 0,
        miningCycles: 0,
        miningHalvingMultiplier: 1,
        createdAt: new Date(),
        updatedAt: new Date(),
      },
    );
  }

  createdUserIds.add(testUid);

  batch.set(
    userRef,
    {
      uid: testUid,
      username: "Stella Halving Transition Test",
      miningBalance: 0,
      totalMined: 0,
      totalMinedInitialized: true,
      hashRate: 1,
      miningHashRate: 1,
      miningStreak: 0,
      miningCycles: 0,
      miningHalvingMultiplier: 1,
      adBoostStartedAt: null,
      adBoostEndsAt: null,
      lastAdRewardAt: null,
      adsToday: 0,
      lastAdDate: null,
      createdAt: new Date(),
      updatedAt: new Date(),
    },
  );

  await batch.commit();
}

// ============================================================
// ADD THE 100TH REGISTERED USER
// ============================================================

async function addHundredthUser() {
  const uid =
    `${testPrefix}-user-99`;

  createdUserIds.add(uid);

  await db
    .collection("users")
    .doc(uid)
    .set({
      uid,
      username: "Halving Threshold User",
      miningBalance: 0,
      totalMined: 0,
      totalMinedInitialized: true,
      createdAt: new Date(),
      updatedAt: new Date(),
    });
}

// ============================================================
// CLEANUP
// ============================================================

async function deleteSubcollection(collectionName) {
  const collectionRef = userRef
    .collection(collectionName);

  const snapshot =
    await collectionRef.get();

  if (snapshot.empty) {
    return;
  }

  const batch = db.batch();

  for (const document of snapshot.docs) {
    batch.delete(document.ref);
  }

  await batch.commit();
}

async function cleanupTestUsers() {
  await deleteSubcollection("transactions");
  await deleteSubcollection("achievements");

  const userIds = [
    ...createdUserIds,
  ];

  for (
    let index = 0;
    index < userIds.length;
    index += 400
  ) {
    const batch = db.batch();

    const group = userIds.slice(
      index,
      index + 400,
    );

    for (const uid of group) {
      batch.delete(
        db.collection("users").doc(uid),
      );
    }

    await batch.commit();
  }
}

after(async () => {
  await cleanupTestUsers();
});

// ============================================================
// HALVING TRANSITION TEST
// ============================================================

test(
  "existing miner receives new halving multiplier on next cycle",
  async () => {
    // --------------------------------------------------------
    // 1. CREATE 99 USERS
    // --------------------------------------------------------

    await seedInitialUsers();

    const initialCount =
      await getRegisteredUserCount();

    assert.equal(
      initialCount,
      99,
      "Initial registered user count must be 99.",
    );

    // --------------------------------------------------------
    // 2. START FIRST MINING CYCLE
    // --------------------------------------------------------

    const firstClaim =
      await claimMining.run({
        auth: {
          uid: testUid,
        },
        data: {},
      });

    assert.equal(
      firstClaim.success,
      true,
    );

    assert.equal(
      firstClaim.started,
      true,
    );

    const firstSnapshot =
      await userRef.get();

    const firstData =
      firstSnapshot.data();

    assert.equal(
      firstData.miningHalvingMultiplier,
      1.0,
      "99 users must use multiplier 1.0.",
    );

    // --------------------------------------------------------
    // 3. REGISTER THE 100TH USER
    // --------------------------------------------------------

    await addHundredthUser();

    const newCount =
      await getRegisteredUserCount();

    assert.equal(
      newCount,
      100,
      "Registered user count must now be 100.",
    );

    // --------------------------------------------------------
    // 4. ACTIVE CYCLE MUST KEEP OLD MULTIPLIER
    // --------------------------------------------------------

    const activeClaim =
      await claimMining.run({
        auth: {
          uid: testUid,
        },
        data: {},
      });

    assert.equal(
      activeClaim.success,
      true,
    );

    assert.equal(
      activeClaim.started,
      false,
      "An active mining cycle must not start again.",
    );

    const activeSnapshot =
      await userRef.get();

    assert.equal(
      activeSnapshot.data().miningHalvingMultiplier,
      1.0,
      "The active cycle must retain its original multiplier.",
    );

    // --------------------------------------------------------
    // 5. FINISH THE OLD MINING CYCLE
    // --------------------------------------------------------

    const now = Date.now();

    const oldStart =
      new Date(now - 24 * 60 * 60 * 1000);

    const oldEnd =
      new Date(now - 1000);

    await userRef.update({
      miningStartedAt: oldStart,
      miningEndsAt: oldEnd,
    });

    // --------------------------------------------------------
    // 6. CLAIM OLD CYCLE AND START NEW CYCLE
    // --------------------------------------------------------

    const nextClaim =
      await claimMining.run({
        auth: {
          uid: testUid,
        },
        data: {},
      });

    assert.equal(
      nextClaim.success,
      true,
    );

    assert.equal(
      nextClaim.started,
      true,
      "A new mining cycle must start after the old cycle ends.",
    );

    assert.equal(
      nextClaim.completedPreviousCycle,
      true,
      "The previous mining cycle must be completed.",
    );

    // --------------------------------------------------------
    // 7. VERIFY NEW MULTIPLIER
    // --------------------------------------------------------

    const newSnapshot =
      await userRef.get();

    const newData =
      newSnapshot.data();

    assert.equal(
      newData.miningHalvingMultiplier,
      0.5,
      "The new cycle must use the 0.5 multiplier.",
    );

    // Daily hash rate can change when a new mining day
    // begins. It must not be compared with the previous cycle.
    assert.ok(
      Number.isFinite(nextClaim.hashRate) &&
      nextClaim.hashRate > 0,
      "The new mining cycle must have a positive hash rate.",
    );

    // --------------------------------------------------------
    // 8. VERIFY OLD CYCLE WAS ACCOUNTED FOR
    // --------------------------------------------------------

    assert.ok(
      nextClaim.collected > 0,
      "The previous cycle must produce a positive mining amount.",
    );

    assert.ok(
      Math.abs(
        newData.totalMined -
        nextClaim.collected
      ) < 0.000001,
      "Only the previous cycle's actual mining must be added to totalMined.",
    );

    // --------------------------------------------------------
    // 9. VERIFY NEW MINING STATUS
    // --------------------------------------------------------

    const status =
      await getMiningStatus.run({
        auth: {
          uid: testUid,
        },
        data: {},
      });

    assert.equal(
      status.success,
      true,
    );

    assert.equal(
      status.miningActive,
      true,
    );

    assert.equal(
      status.miningHalvingMultiplier,
      0.5,
      "Mining status must use the new cycle multiplier.",
    );

    const expectedRate =
      nextClaim.hashRate *
      0.10 *
      0.5;

    assert.ok(
      Math.abs(
        status.miningPerHour -
        expectedRate
      ) < 0.0000001,
      `Expected ${expectedRate} STL/hour, received ${status.miningPerHour}.`,
    );

    // --------------------------------------------------------
    // 10. FINAL ASSERTIONS
    // --------------------------------------------------------

    assert.equal(
      newData.miningHalvingMultiplier,
      0.5,
    );

    assert.equal(
      status.miningHalvingMultiplier,
      0.5,
    );

    console.log(
      "🐱 HALVING TRANSITION TEST PASSED",
    );

    console.log(
      `Initial users: ${initialCount}`,
    );

    console.log(
      `New registered users: ${newCount}`,
    );

    console.log(
      `Old multiplier: ${firstData.miningHalvingMultiplier}`,
    );

    console.log(
      `New multiplier: ${newData.miningHalvingMultiplier}`,
    );

    console.log(
      `Old hash rate: ${firstClaim.hashRate}`,
    );

    console.log(
      `New hash rate: ${nextClaim.hashRate}`,
    );

    console.log(
      `New mining rate: ${status.miningPerHour} STL/hour`,
    );
  },
);
