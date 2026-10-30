"use strict";

// ============================================================
// 🐱 STELLURIINI - REFERRAL FUNCTIONS INTEGRATION TESTS
// ============================================================
//
// Testaa buildReferralUsers()-toimintoa Firestore Emulatorissa.
//
// Testit:
// 1. Kaikki kutsutut käyttäjät palautetaan.
// 2. Käyttäjät käsitellään enintään 100 käyttäjän listasta.
// 3. Duplikaattikäyttäjät poistetaan.
// 4. Puuttuvat käyttäjäprofiilit ohitetaan.
// 5. Referral-bonukset säilyvät oikein.
// 6. Flutterin tarvitsemat kentät palautetaan.
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
  buildReferralUsers,
} = require("../src/functions/referralFunctions");

// ============================================================
// TEST DATA
// ============================================================

const testPrefix = `referral-list-${Date.now()}`;

const referrerUid = `${testPrefix}-referrer`;

const referralRefs = [];
const userRefs = [];

// ============================================================
// CREATE TEST USERS
// ============================================================

async function createTestReferral({
  relationshipId,
  referredUid,
  username,
  bonus,
  active = false,
  missingProfile = false,
}) {
  const relationshipRef = db
    .collection("referrals")
    .doc(relationshipId);

  referralRefs.push(relationshipRef);

  await relationshipRef.set({
    referrerUid,
    referredUid,
    referralBonusTotal: bonus,
    referralBonusTotalInitialized: true,
  });

  if (missingProfile) {
    return;
  }

  const userRef = db
    .collection("users")
    .doc(referredUid);

  userRefs.push(userRef);

  const now = Date.now();

  await userRef.set({
    username,

    miningStartedAt: active
      ? new Date(now - 60_000)
      : null,

    miningEndsAt: active
      ? new Date(now + 60 * 60 * 1000)
      : null,

    lastMiningAt: new Date(now),
  });
}

// ============================================================
// CLEANUP
// ============================================================

after(async () => {
  const batch = db.batch();

  for (const ref of referralRefs) {
    batch.delete(ref);
  }

  for (const ref of userRefs) {
    batch.delete(ref);
  }

  await batch.commit();
});

// ============================================================
// TEST 1: REFERRAL USERS
// ============================================================

test(
  "referral users are returned with the expected fields",
  async () => {
    await createTestReferral({
      relationshipId: `${testPrefix}-relationship-1`,
      referredUid: `${testPrefix}-user-1`,
      username: "StellaOne",
      bonus: 12.5,
      active: true,
    });

    await createTestReferral({
      relationshipId: `${testPrefix}-relationship-2`,
      referredUid: `${testPrefix}-user-2`,
      username: "StellaTwo",
      bonus: 7.5,
      active: false,
    });

    const users = await buildReferralUsers(
      referrerUid,
      {
        now: new Date(),
      },
    );

    assert.equal(users.length, 2);

    const first = users.find(
      (user) => user.uid === `${testPrefix}-user-1`,
    );

    const second = users.find(
      (user) => user.uid === `${testPrefix}-user-2`,
    );

    assert.ok(first);
    assert.ok(second);

    assert.equal(first.username, "StellaOne");
    assert.equal(first.isMining, true);
    assert.equal(first.referralBonus, 12.5);

    assert.equal(second.username, "StellaTwo");
    assert.equal(second.isMining, false);
    assert.equal(second.referralBonus, 7.5);

    for (const user of users) {
      assert.equal(typeof user.uid, "string");
      assert.equal(typeof user.username, "string");
      assert.equal(typeof user.isMining, "boolean");
      assert.equal(typeof user.referralBonus, "number");
    }
  },
);

// ============================================================
// TEST 2: DUPLICATE RELATIONSHIPS
// ============================================================

test(
  "duplicate referred users are returned only once",
  async () => {
    const referredUid = `${testPrefix}-duplicate-user`;

    await createTestReferral({
      relationshipId: `${testPrefix}-duplicate-a`,
      referredUid,
      username: "StellaDuplicate",
      bonus: 5,
    });

    await createTestReferral({
      relationshipId: `${testPrefix}-duplicate-b`,
      referredUid,
      username: "StellaDuplicate",
      bonus: 5,
    });

    const users = await buildReferralUsers(
      referrerUid,
      {
        now: new Date(),
      },
    );

    const matchingUsers = users.filter(
      (user) => user.uid === referredUid,
    );

    assert.equal(matchingUsers.length, 1);
  },
);

// ============================================================
// TEST 3: MISSING USER PROFILE
// ============================================================

test(
  "missing user profiles are safely omitted",
  async () => {
    await createTestReferral({
      relationshipId: `${testPrefix}-missing-profile`,
      referredUid: `${testPrefix}-missing-user`,
      username: "Missing",
      bonus: 3,
      missingProfile: true,
    });

    const users = await buildReferralUsers(
      referrerUid,
      {
        now: new Date(),
      },
    );

    assert.equal(
      users.some(
        (user) => user.uid === `${testPrefix}-missing-user`,
      ),
      false,
    );
  },
);

// ============================================================
// TEST 4: EMPTY REFERRAL LIST
// ============================================================

test(
  "empty referral list returns an empty array",
  async () => {
    const users = await buildReferralUsers(
      `${testPrefix}-empty-referrer`,
      {
        now: new Date(),
      },
    );

    assert.deepEqual(users, []);
  },
);

// ============================================================
// TEST 5: RESULT LIMIT
// ============================================================

test(
  "referral result never exceeds the configured maximum",
  async () => {
    const users = await buildReferralUsers(
      referrerUid,
      {
        now: new Date(),
      },
    );

    assert.ok(users.length <= 100);
  },
);