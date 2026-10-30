"use strict";

// ============================================================
// 🐱 STELLURIINI - REFERRAL MINING REWARD INTEGRATION TESTS
// ============================================================
//
// Testaa varsinaista applyReferralMiningReward()-toimintoa
// Firestore Emulatorissa.
//
// Testit:
// 1. Sama mining-tapahtuma käsitellään vain kerran.
// 2. Saman tapahtuman rinnakkaiset pyynnöt eivät maksa
//    bonusta kahdesti.
// 3. Eri samanaikaiset tapahtumat säilyttävät kaikki bonukset.
// 4. Käyttäjän saldo, referral-yhteenveto ja historia täsmäävät.
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
  applyReferralMiningReward,
} = require("../src/services/referralService");

if (!process.env.FIRESTORE_EMULATOR_HOST) {
  throw new Error(
    "These tests require FIRESTORE_EMULATOR_HOST.",
  );
}

const testPrefix = `referral-mining-${Date.now()}`;

const createdTestUsers = new Set();
const createdRelationships = new Set();
const createdBonusMarkers = new Set();

// ============================================================
// TEST DATA HELPERS
// ============================================================

function createTestCase(name) {
  const id = `${testPrefix}-${name}`;

  const referrerUid = `${id}-referrer`;
  const referredUid = `${id}-referred`;

  createdTestUsers.add(referrerUid);
  createdTestUsers.add(referredUid);
  createdRelationships.add(referredUid);

  return {
    referrerUid,
    referredUid,
  };
}

function createBonusMarkerRef(miningTransactionId) {
  const bonusId = `referral_${miningTransactionId}`;
  const markerRef = db
    .collection("referrals")
    .doc(`_bonus_${bonusId}`);

  createdBonusMarkers.add(markerRef);

  return markerRef;
}

async function seedTestUsers({
  referrerUid,
  referredUid,
}) {
  const batch = db.batch();

  batch.set(
    db.collection("users").doc(referrerUid),
    {
      miningBalance: 0,
      referralTotalEarned: 0,
    },
  );

  batch.set(
    db.collection("users").doc(referredUid),
    {
      referrerUid,
    },
  );

  batch.set(
    db.collection("referrals").doc(referredUid),
    {
      referrerUid,
      referredUid,
      referralBonusTotal: 0,
      referralBonusTotalInitialized: true,
    },
  );

  // Käytetään kiinteää käyttäjämäärää, jotta
  // referral-prosentti pysyy testissä ennustettavana.
  batch.set(
    db.collection("stats").doc("global"),
    {
      totalUsers: 1,
    },
  );

  await batch.commit();
}

async function applyReward({
  referredUid,
  miningAmount = 100,
  miningTransactionId,
}) {
  return db.runTransaction(async (transaction) => {
    return applyReferralMiningReward(
      referredUid,
      miningAmount,
      miningTransactionId,
      transaction,
    );
  });
}

async function readUser(uid) {
  const snapshot = await db
    .collection("users")
    .doc(uid)
    .get();

  assert.equal(snapshot.exists, true);

  return snapshot.data();
}

async function readRelationship(referredUid) {
  const snapshot = await db
    .collection("referrals")
    .doc(referredUid)
    .get();

  assert.equal(snapshot.exists, true);

  return snapshot.data();
}

async function countReferralHistory(referrerUid) {
  const snapshot = await db
    .collection("referralHistory")
    .where("referrerUid", "==", referrerUid)
    .get();

  return snapshot.size;
}

async function countUserRewardHistory(referrerUid) {
  const snapshot = await db
    .collection("users")
    .doc(referrerUid)
    .collection("transactions")
    .where("type", "==", "referral_reward")
    .get();

  return snapshot.size;
}

// ============================================================
// CLEANUP
// ============================================================

after(async () => {
  for (const uid of createdTestUsers) {
    const historySnapshot = await db
      .collection("users")
      .doc(uid)
      .collection("transactions")
      .get();

    const batch = db.batch();

    historySnapshot.docs.forEach((document) => {
      batch.delete(document.ref);
    });

    batch.delete(
      db.collection("users").doc(uid),
    );

    await batch.commit();
  }

  for (const referredUid of createdRelationships) {
    await db
      .collection("referrals")
      .doc(referredUid)
      .delete();
  }

  for (const markerRef of createdBonusMarkers) {
    await markerRef.delete();
  }

  const referralHistorySnapshot = await db
    .collection("referralHistory")
    .where("referrerUid", ">=", testPrefix)
    .where("referrerUid", "<", `${testPrefix}\uf8ff`)
    .get();

  const batch = db.batch();

  referralHistorySnapshot.docs.forEach((document) => {
    batch.delete(document.ref);
  });

  if (!referralHistorySnapshot.empty) {
    await batch.commit();
  }
});

// ============================================================
// TEST 1: SAME EVENT TWICE
// ============================================================

test(
  "same mining event cannot pay referral bonus twice",
  async () => {
    const {
      referrerUid,
      referredUid,
    } = createTestCase("duplicate");

    await seedTestUsers({
      referrerUid,
      referredUid,
    });

    const miningTransactionId =
      `${testPrefix}-duplicate-event`;

    createBonusMarkerRef(miningTransactionId);

    const first = await applyReward({
      referredUid,
      miningAmount: 100,
      miningTransactionId,
    });

    const second = await applyReward({
      referredUid,
      miningAmount: 100,
      miningTransactionId,
    });

    assert.equal(first.applied, true);
    assert.equal(first.bonus, 24);

    assert.equal(second.applied, false);
    assert.equal(second.alreadyProcessed, true);
    assert.equal(second.reason, "ALREADY_PROCESSED");

    const referrer = await readUser(referrerUid);
    const relationship = await readRelationship(referredUid);

    assert.equal(referrer.miningBalance, 24);
    assert.equal(referrer.referralTotalEarned, 24);

    assert.equal(relationship.referralBonusTotal, 24);
    assert.equal(
      relationship.referralBonusTotalInitialized,
      true,
    );

    assert.equal(
      await countReferralHistory(referrerUid),
      1,
    );

    assert.equal(
      await countUserRewardHistory(referrerUid),
      1,
    );
  },
);

// ============================================================
// TEST 2: SAME EVENT CONCURRENTLY
// ============================================================

test(
  "concurrent requests for the same event pay only once",
  async () => {
    const {
      referrerUid,
      referredUid,
    } = createTestCase("concurrent-duplicate");

    await seedTestUsers({
      referrerUid,
      referredUid,
    });

    const miningTransactionId =
      `${testPrefix}-concurrent-duplicate-event`;

    createBonusMarkerRef(miningTransactionId);

    const results = await Promise.all(
      Array.from(
        { length: 5 },
        () => applyReward({
          referredUid,
          miningAmount: 100,
          miningTransactionId,
        }),
      ),
    );

    const appliedResults = results.filter(
      (result) => result.applied === true,
    );

    assert.equal(appliedResults.length, 1);

    const referrer = await readUser(referrerUid);
    const relationship = await readRelationship(referredUid);

    assert.equal(referrer.miningBalance, 24);
    assert.equal(referrer.referralTotalEarned, 24);
    assert.equal(relationship.referralBonusTotal, 24);

    assert.equal(
      await countReferralHistory(referrerUid),
      1,
    );

    assert.equal(
      await countUserRewardHistory(referrerUid),
      1,
    );
  },
);

// ============================================================
// TEST 3: DIFFERENT EVENTS CONCURRENTLY
// ============================================================

test(
  "different concurrent mining events preserve every bonus",
  async () => {
    const {
      referrerUid,
      referredUid,
    } = createTestCase("concurrent-distinct");

    await seedTestUsers({
      referrerUid,
      referredUid,
    });

    const miningTransactionIds = [
      `${testPrefix}-event-a`,
      `${testPrefix}-event-b`,
      `${testPrefix}-event-c`,
      `${testPrefix}-event-d`,
      `${testPrefix}-event-e`,
    ];

    miningTransactionIds.forEach(
      createBonusMarkerRef,
    );

    const results = await Promise.all(
      miningTransactionIds.map(
        (miningTransactionId) =>
          applyReward({
            referredUid,
            miningAmount: 100,
            miningTransactionId,
          }),
      ),
    );

    assert.equal(
      results.filter((result) => result.applied).length,
      5,
    );

    const referrer = await readUser(referrerUid);
    const relationship = await readRelationship(referredUid);

    // 5 × 100 STL × 24 % = 120 STL.
    assert.equal(referrer.miningBalance, 120);
    assert.equal(referrer.referralTotalEarned, 120);
    assert.equal(relationship.referralBonusTotal, 120);

    assert.equal(
      await countReferralHistory(referrerUid),
      5,
    );

    assert.equal(
      await countUserRewardHistory(referrerUid),
      5,
    );
  },
);

// ============================================================
// TEST 4: LEGACY SUMMARY
// ============================================================

test(
  "legacy relationship includes old history before new bonus",
  async () => {
    const {
      referrerUid,
      referredUid,
    } = createTestCase("legacy");

    await seedTestUsers({
      referrerUid,
      referredUid,
    });

    // Poistetaan uuden yhteenvedon kentät:
    // simuloidaan vanhaa referral-suhdetta.
    await db
      .collection("referrals")
      .doc(referredUid)
      .update({
        referralBonusTotal:
          require("firebase-admin/firestore").FieldValue.delete(),
        referralBonusTotalInitialized:
          require("firebase-admin/firestore").FieldValue.delete(),
      });

    // Vanha referral-historia.
    await db
      .collection("users")
      .doc(referrerUid)
      .collection("transactions")
      .doc("legacy-history-1")
      .set({
        type: "referral_reward",
        referredUid,
        amount: 10,
      });

    await db
      .collection("users")
      .doc(referrerUid)
      .collection("transactions")
      .doc("legacy-history-2")
      .set({
        type: "referral_reward",
        referredUid,
        amount: 5,
      });

    const miningTransactionId =
      `${testPrefix}-legacy-event`;

    createBonusMarkerRef(miningTransactionId);

    const result = await applyReward({
      referredUid,
      miningAmount: 100,
      miningTransactionId,
    });

    assert.equal(result.applied, true);
    assert.equal(result.bonus, 24);

    const relationship = await readRelationship(referredUid);

    // Vanha historia 15 + uusi bonus 24.
    assert.equal(relationship.referralBonusTotal, 39);
    assert.equal(
      relationship.referralBonusTotalInitialized,
      true,
    );
  },
);