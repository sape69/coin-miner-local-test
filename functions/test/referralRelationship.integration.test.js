
"use strict";

// ============================================================
// 🐱 STELLURIINI - REFERRAL RELATIONSHIP INTEGRATION TESTS
// ============================================================
//
// Testaa createReferralRelationship()-toimintoa
// Firestore Emulatorissa.
//
// Testit:
// 1. Kelvollinen referral-suhde luodaan.
// 2. Käyttäjälle ei luoda kahta referral-suhdetta.
// 3. Omaa referral-koodia ei voi käyttää.
// 4. Virheellistä referral-koodia ei hyväksytä.
// 5. Tuntematonta referral-koodia ei hyväksytä.
// 6. Käyttäjää, jota ei löydy, ei voi liittää.
// 7. Aiemmin asetettua kutsujaa ei voi vaihtaa.
// 8. Olemassa oleva suhde ei kasvata kutsujan määrää.
// 9. Kaksi samanaikaista kutsua luo vain yhden suhteen.
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
  createReferralRelationship,
  getReferralCodeRef,
} = require("../src/services/referralService");

if (!process.env.FIRESTORE_EMULATOR_HOST) {
  throw new Error(
    "These tests require FIRESTORE_EMULATOR_HOST.",
  );
}

const testPrefix =
  `referral-relationship-${Date.now()}`;

const createdUserUids = new Set();
const createdReferralUids = new Set();
const createdReferralCodes = new Set();

// ============================================================
// TEST HELPERS
// ============================================================

function createTestCase(name, code) {
  const id = `${testPrefix}-${name}`;

  const referrerUid = `${id}-referrer`;
  const referredUid = `${id}-referred`;

  createdUserUids.add(referrerUid);
  createdUserUids.add(referredUid);

  createdReferralUids.add(referredUid);
  createdReferralCodes.add(code);

  return {
    referrerUid,
    referredUid,
    code,
  };
}

async function seedReferrer({
  referrerUid,
  code,
}) {
  const userRef = db
    .collection("users")
    .doc(referrerUid);

  const codeRef = getReferralCodeRef(code);

  assert.ok(
    codeRef,
    "Test referral code must be valid.",
  );

  await db.runTransaction(async (transaction) => {
    const userSnapshot =
      await transaction.get(userRef);

    const codeSnapshot =
      await transaction.get(codeRef);

    assert.equal(userSnapshot.exists, false);
    assert.equal(codeSnapshot.exists, false);

    transaction.set(userRef, {
      username: "StellaTestReferrer",
      miningBalance: 0,
      referralCount: 0,
      referralTotalEarned: 0,
      referralCode: code,
    });

    transaction.create(codeRef, {
      code,
      uid: referrerUid,
    });
  });
}

async function seedReferredUser({
  referredUid,
  referrerUid = null,
}) {
  await db
    .collection("users")
    .doc(referredUid)
    .set({
      username: "StellaTestReferred",
      ...(referrerUid
        ? { referrerUid }
        : {}),
    });
}

async function applyRelationship({
  referredUid,
  code,
}) {
  return db.runTransaction(async (transaction) => {
    return createReferralRelationship(
      referredUid,
      code,
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

  return snapshot.exists
    ? snapshot.data()
    : null;
}

async function assertNoRelationship(referredUid) {
  const relationship =
    await readRelationship(referredUid);

  assert.equal(
    relationship,
    null,
    "Referral relationship must not exist.",
  );
}

// ============================================================
// CLEANUP
// ============================================================

after(async () => {
  for (const uid of createdUserUids) {
    const userRef = db
      .collection("users")
      .doc(uid);

    const subcollections = [
      "transactions",
      "achievements",
    ];

    for (const collectionName of subcollections) {
      const snapshot = await userRef
        .collection(collectionName)
        .get();

      for (const document of snapshot.docs) {
        await document.ref.delete();
      }
    }

    await userRef.delete();
  }

  for (const uid of createdReferralUids) {
    await db
      .collection("referrals")
      .doc(uid)
      .delete();
  }

  for (const code of createdReferralCodes) {
    const codeRef = getReferralCodeRef(code);

    if (codeRef) {
      await codeRef.delete();
    }
  }
});

// ============================================================
// TEST 1: VALID RELATIONSHIP
// ============================================================

test(
  "valid referral relationship is created",
  async () => {
    const data = createTestCase(
      "valid",
      "A2B3C4D5",
    );

    await seedReferrer(data);

    await seedReferredUser({
      referredUid: data.referredUid,
    });

    const result = await applyRelationship({
      referredUid: data.referredUid,
      code: data.code,
    });

    assert.equal(result.created, true);
    assert.equal(result.alreadyExists, false);
    assert.equal(result.referrerUid, data.referrerUid);
    assert.equal(result.referralCode, data.code);

    const user = await readUser(data.referredUid);
    const referrer = await readUser(data.referrerUid);
    const relationship =
      await readRelationship(data.referredUid);

    assert.equal(
      user.referrerUid,
      data.referrerUid,
    );

    assert.equal(
      user.referralCodeUsed,
      data.code,
    );

    assert.equal(
      relationship.referrerUid,
      data.referrerUid,
    );

    assert.equal(
      relationship.referredUid,
      data.referredUid,
    );

    assert.equal(
      relationship.referralBonusTotal,
      0,
    );

    assert.equal(
      relationship.referralBonusTotalInitialized,
      true,
    );

    assert.equal(
      referrer.referralCount,
      1,
    );
  },
);

// ============================================================
// TEST 2: SELF REFERRAL
// ============================================================

test(
  "user cannot use their own referral code",
  async () => {
    const data = createTestCase(
      "self-referral",
      "B2C3D4E5",
    );

    await seedReferrer(data);

    await assert.rejects(
      applyRelationship({
        referredUid: data.referrerUid,
        code: data.code,
      }),
      /REFERRAL_SELF_REFERRAL/,
    );

    const user = await readUser(data.referrerUid);

    assert.equal(
      user.referrerUid,
      undefined,
    );

    assert.equal(
      user.referralCount,
      0,
    );

    await assertNoRelationship(data.referrerUid);
  },
);

// ============================================================
// TEST 3: INVALID REFERRAL CODE
// ============================================================

test(
  "invalid referral code is rejected",
  async () => {
    const data = createTestCase(
      "invalid-code",
      "C2D3E4F5",
    );

    await seedReferredUser({
      referredUid: data.referredUid,
    });

    await assert.rejects(
      applyRelationship({
        referredUid: data.referredUid,
        code: "INVALID!",
      }),
      /REFERRAL_INVALID_CODE/,
    );

    const user = await readUser(data.referredUid);

    assert.equal(
      user.referrerUid,
      undefined,
    );

    await assertNoRelationship(data.referredUid);
  },
);

// ============================================================
// TEST 4: UNKNOWN REFERRAL CODE
// ============================================================

test(
  "unknown referral code is rejected",
  async () => {
    const data = createTestCase(
      "unknown-code",
      "D2E3F4G5",
    );

    await seedReferredUser({
      referredUid: data.referredUid,
    });

    await assert.rejects(
      applyRelationship({
        referredUid: data.referredUid,
        code: data.code,
      }),
      /REFERRAL_CODE_NOT_FOUND/,
    );

    const user = await readUser(data.referredUid);

    assert.equal(
      user.referrerUid,
      undefined,
    );

    await assertNoRelationship(data.referredUid);
  },
);

// ============================================================
// TEST 5: MISSING USER
// ============================================================

test(
  "missing referred user cannot create relationship",
  async () => {
    const data = createTestCase(
      "missing-user",
      "E2F3G4H5",
    );

    await seedReferrer(data);

    await assert.rejects(
      applyRelationship({
        referredUid: data.referredUid,
        code: data.code,
      }),
      /REFERRAL_USER_NOT_FOUND/,
    );

    await assertNoRelationship(data.referredUid);

    const referrer = await readUser(data.referrerUid);

    assert.equal(
      referrer.referralCount,
      0,
    );
  },
);

// ============================================================
// TEST 6: EXISTING REFERRER CANNOT BE CHANGED
// ============================================================

test(
  "user with existing referrer cannot change referrer",
  async () => {
    const data = createTestCase(
      "existing-referrer",
      "F2G3H4J5",
    );

    const oldReferrerUid =
      `${testPrefix}-old-referrer`;

    createdUserUids.add(oldReferrerUid);

    await seedReferrer(data);

    await seedReferredUser({
      referredUid: data.referredUid,
      referrerUid: oldReferrerUid,
    });

    await assert.rejects(
      applyRelationship({
        referredUid: data.referredUid,
        code: data.code,
      }),
      /REFERRAL_REFERRER_ALREADY_SET/,
    );

    const user = await readUser(data.referredUid);

    assert.equal(
      user.referrerUid,
      oldReferrerUid,
    );

    const referrer = await readUser(data.referrerUid);

    assert.equal(
      referrer.referralCount,
      0,
    );

    await assertNoRelationship(data.referredUid);
  },
);

// ============================================================
// TEST 7: EXISTING RELATIONSHIP IS NOT COUNTED AGAIN
// ============================================================

test(
  "existing relationship is not created or counted twice",
  async () => {
    const data = createTestCase(
      "existing-relationship",
      "G2H3J4K5",
    );

    await seedReferrer(data);

    await seedReferredUser({
      referredUid: data.referredUid,
    });

    const first = await applyRelationship({
      referredUid: data.referredUid,
      code: data.code,
    });

    assert.equal(first.created, true);

    const second = await applyRelationship({
      referredUid: data.referredUid,
      code: data.code,
    });

    assert.equal(second.created, false);
    assert.equal(second.alreadyExists, true);
    assert.equal(second.referrerUid, data.referrerUid);

    const referrer = await readUser(data.referrerUid);

    assert.equal(
      referrer.referralCount,
      1,
    );

    const relationship =
      await readRelationship(data.referredUid);

    assert.equal(
      relationship.referrerUid,
      data.referrerUid,
    );
  },
);

// ============================================================
// TEST 8: CONCURRENT REFERRAL REQUESTS
// ============================================================

test(
  "concurrent requests create only one referral relationship",
  async () => {
    const data = createTestCase(
      "concurrent",
      "H2J3K4M5",
    );

    await seedReferrer(data);

    await seedReferredUser({
      referredUid: data.referredUid,
    });

    const results = await Promise.all(
      Array.from(
        { length: 5 },
        () => applyRelationship({
          referredUid: data.referredUid,
          code: data.code,
        }),
      ),
    );

    const createdResults = results.filter(
      (result) => result.created === true,
    );

    const existingResults = results.filter(
      (result) => result.alreadyExists === true,
    );

    assert.equal(
      createdResults.length,
      1,
    );

    assert.equal(
      existingResults.length,
      4,
    );

    const referrer = await readUser(data.referrerUid);

    assert.equal(
      referrer.referralCount,
      1,
    );

    const relationship =
      await readRelationship(data.referredUid);

    assert.equal(
      relationship.referrerUid,
      data.referrerUid,
    );

    assert.equal(
      relationship.referredUid,
      data.referredUid,
    );
  },
);

// ============================================================
// TEST 9: REFERRAL CODE NORMALIZATION
// ============================================================

test(
  "lowercase referral code is normalized",
  async () => {
    const data = createTestCase(
      "normalization",
      "J2K3M4N5",
    );

    await seedReferrer(data);

    await seedReferredUser({
      referredUid: data.referredUid,
    });

    const result = await applyRelationship({
      referredUid: data.referredUid,
      code: data.code.toLowerCase(),
    });

    assert.equal(result.created, true);

    assert.equal(
      result.referralCode,
      data.code,
    );

    const user = await readUser(data.referredUid);

    assert.equal(
      user.referralCodeUsed,
      data.code,
    );
  },
);
