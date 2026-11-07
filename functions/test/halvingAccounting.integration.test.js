
"use strict";

// ============================================================
// 🐱 STELLURIINI - HALVING ACCOUNTING INTEGRATION TEST
// ============================================================
//
// Testaa koko halving-ketjun Firestore Emulatorissa:
//
// 1. Vähintään 100 rekisteröitynyttä käyttäjää.
// 2. claimMining hakee todellisen käyttäjämäärän.
// 3. Uuteen louhintajaksoon tallennetaan kerroin 0.5.
// 4. getMiningStatus käyttää tallennettua kerrointa.
// 5. Todellinen louhintanopeus puolittuu.
//
// Testidata poistetaan testin jälkeen.
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

const testPrefix = `halving-accounting-${Date.now()}`;

const testUid = `${testPrefix}-miner`;

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
// TEST DATA
// ============================================================

function createTestUserIds() {
  const ids = [];

  // 99 muuta käyttäjää.
  for (let index = 1; index <= 99; index += 1) {
    ids.push(`${testPrefix}-user-${index}`);
  }

  // Varsinainen louhija.
  ids.push(testUid);

  return ids;
}

async function seedRegisteredUsers() {
  const userIds = createTestUserIds();

  const batch = db.batch();

  for (const uid of userIds) {
    createdUserIds.add(uid);

    batch.set(
      db.collection("users").doc(uid),
      {
        uid,
        username:
          uid === testUid
            ? "Stella Halving Test"
            : `Halving Test ${uid}`,

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
  }

  await batch.commit();
}

// ============================================================
// CLEANUP HELPERS
// ============================================================

async function deleteSubcollection(
  uid,
  collectionName,
) {
  const collectionRef = db
    .collection("users")
    .doc(uid)
    .collection(collectionName);

  const snapshot = await collectionRef.get();

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
  // Poistetaan louhijan alikokoelmat ensin.
  await deleteSubcollection(
    testUid,
    "transactions",
  );

  await deleteSubcollection(
    testUid,
    "achievements",
  );

  // Poistetaan testikäyttäjät.
  const userIds = [...createdUserIds];

  for (let index = 0; index < userIds.length; index += 400) {
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
// HALVING END-TO-END TEST
// ============================================================

test(
  "100 registered users activate halving in real mining calculations",
  async () => {
    // --------------------------------------------------------
    // 1. CREATE 100 REGISTERED USERS
    // --------------------------------------------------------

    await seedRegisteredUsers();

    const registeredUserCount =
      await getRegisteredUserCount();

    assert.ok(
      registeredUserCount >= 100,
      "Firestore must contain at least 100 registered users.",
    );

    // --------------------------------------------------------
    // 2. VERIFY HALVING STARTS AT 100 USERS
    // --------------------------------------------------------

    // Varsinainen kerroin tarkistetaan myös
    // claimMining-kutsun jälkeen käyttäjädokumentista.
    assert.equal(
      registeredUserCount,
      100,
      "The isolated emulator should contain exactly 100 test users.",
    );

    // --------------------------------------------------------
    // 3. START MINING THROUGH REAL CALLABLE FUNCTION
    // --------------------------------------------------------

    const claimResult = await claimMining.run({
      auth: {
        uid: testUid,
      },
      data: {},
    });

    assert.equal(
      claimResult.success,
      true,
      "Mining Start must succeed.",
    );

    assert.equal(
      claimResult.started,
      true,
      "A new mining cycle must start.",
    );

    // --------------------------------------------------------
    // 4. VERIFY STORED HALVING MULTIPLIER
    // --------------------------------------------------------

    const userSnapshot = await userRef.get();

    assert.equal(
      userSnapshot.exists,
      true,
      "Mining user must exist.",
    );

    const userData = userSnapshot.data();

    assert.equal(
      userData.miningHalvingMultiplier,
      0.5,
      "100 registered users must activate the 0.5 multiplier.",
    );

    assert.equal(
      claimResult.hashRate,
      0.5,
      "The first daily mining hash rate should be 0.5.",
    );

    // --------------------------------------------------------
    // 5. ADVANCE MINING CLOCK FOR STATUS CALCULATION
    // --------------------------------------------------------

    // Siirretään testijakson alkua tunnin taaksepäin.
    // Jakso pysyy aktiivisena ja sen kesto säilyy 24 tuntina.

    const now = Date.now();

    const oneHourMs = 60 * 60 * 1000;

    const miningStartedAt = new Date(
      now - oneHourMs,
    );

    const miningEndsAt = new Date(
      now + 23 * oneHourMs,
    );

    await userRef.update({
      miningStartedAt,
      miningEndsAt,
    });

    // --------------------------------------------------------
    // 6. READ REAL MINING STATUS
    // --------------------------------------------------------

    const status = await getMiningStatus.run({
      auth: {
        uid: testUid,
      },
      data: {},
    });

    assert.equal(
      status.success,
      true,
      "Mining status must load successfully.",
    );

    assert.equal(
      status.miningActive,
      true,
      "Mining cycle must still be active.",
    );

    assert.equal(
      status.miningHalvingMultiplier,
      0.5,
      "Mining status must use the stored halving multiplier.",
    );

    // --------------------------------------------------------
    // 7. VERIFY ACTUAL MINING RATE
    // --------------------------------------------------------

    // 0.5 Hash Rate × 0.10 STL × 0.5 halving
    // = 0.025 STL per hour.

    const expectedMiningPerHour =
      0.5 * 0.10 * 0.5;

    assert.ok(
      Math.abs(
        status.miningPerHour -
        expectedMiningPerHour
      ) < 1e-10,
      `Expected ${expectedMiningPerHour} STL/hour, received ${status.miningPerHour}.`,
    );

    // Ilman halvingia nopeus olisi 0.05 STL tunnissa.
    const normalMiningPerHour =
      0.5 * 0.10;

    assert.ok(
      status.miningPerHour <
      normalMiningPerHour,
      "Halving must reduce the actual mining rate.",
    );

    // --------------------------------------------------------
    // 8. VERIFY MINED AMOUNT
    // --------------------------------------------------------

    assert.ok(
      status.unclaimedMining > 0,
      "Active mining must produce an unclaimed amount.",
    );

    const expectedOneHourMining =
      expectedMiningPerHour;

    assert.ok(
      Math.abs(
        status.unclaimedMining -
        expectedOneHourMining
      ) < 0.002,
      "Unclaimed mining must reflect the halved mining rate.",
    );

    // --------------------------------------------------------
    // 9. FINAL RESULT
    // --------------------------------------------------------

    assert.equal(
      userData.miningHalvingMultiplier,
      0.5,
    );

    assert.equal(
      status.miningHalvingMultiplier,
      0.5,
    );

    console.log(
      "🐱 HALVING TEST PASSED",
    );

    console.log(
      `Registered users: ${registeredUserCount}`,
    );

    console.log(
      `Halving multiplier: ${status.miningHalvingMultiplier}`,
    );

    console.log(
      `Mining rate: ${status.miningPerHour} STL/hour`,
    );

    console.log(
      `Unclaimed mining: ${status.unclaimedMining} STL`,
    );
  },
);
