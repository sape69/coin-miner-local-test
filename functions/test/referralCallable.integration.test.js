
"use strict";

// ============================================================
// 🐱 STELLURIINI - REFERRAL CALLABLE INTEGRATION TESTS
// ============================================================
//
// Testaa Firebase Callable -rajapintaa:
// applyReferralCode()
//
// Testit suoritetaan Firestore Emulatorissa.
//
// 1. Kirjautumaton käyttäjä hylätään.
// 2. Puuttuva referral-koodi hylätään.
// 3. Virheellinen referral-koodi hylätään.
// 4. Tuntematon referral-koodi hylätään.
// 5. Oma referral-koodi hylätään.
// 6. Asiakkaan UID-arvoja ei hyväksytä kutsujan UID:ksi.
// 7. Kelvollinen referral-koodi voidaan liittää.
// 8. Käyttäjä ei voi vaihtaa kutsujaa.
// 9. Rinnakkaiset pyynnöt eivät luo kaksoissuhdetta.
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
  getHistoryCollection,
} = require("../src/utils/userUtils");

const {
  getReferralCodeRef,
} = require("../src/services/referralService");

const {
  applyReferralCode,
} = require("../src/functions/referralFunctions");

// ============================================================
// EMULATOR REQUIREMENT
// ============================================================

if (!process.env.FIRESTORE_EMULATOR_HOST) {
  throw new Error(
    "These tests require FIRESTORE_EMULATOR_HOST.",
  );
}

// ============================================================
// TEST DATA
// ============================================================

const testPrefix =
  `referral-callable-${Date.now()}`;

const createdUserUids = new Set();
const createdReferralCodes = new Set();
const createdReferralUids = new Set();
const createdHistoryUids = new Set();

// ============================================================
// HELPERS
// ============================================================

function createTestCase(name, code) {
  const id = `${testPrefix}-${name}`;

  const data = {
    referrerUid: `${id}-referrer`,
    referredUid: `${id}-referred`,
    code,
  };

  createdUserUids.add(data.referrerUid);
  createdUserUids.add(data.referredUid);

  createdReferralCodes.add(code);
  createdReferralUids.add(data.referredUid);

  return data;
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
      username: "StellaCallableReferrer",
      referralCode: code,
      referralCount: 0,
      miningBalance: 0,
      referralTotalEarned: 0,
    });

    transaction.create(codeRef, {
      code,
      uid: referrerUid,
    });
  });
}

async function seedUser({
  uid,
  referrerUid,
  referralCode,
}) {
  const data = {
    username: "StellaCallableUser",
  };

  if (referrerUid) {
    data.referrerUid = referrerUid;
  }

  if (referralCode) {
    data.referralCode = referralCode;
  }

  await db
    .collection("users")
    .doc(uid)
    .set(data);

  createdUserUids.add(uid);
}

async function callApplyReferralCode({
  uid,
  code,
  authenticated = true,
  extraData = {},
}) {
  return applyReferralCode.run({
    auth: authenticated
      ? { uid }
      : null,

    data: {
      referralCode: code,
      ...extraData,
    },
  });
}

async function readUser(uid) {
  const snapshot = await db
    .collection("users")
    .doc(uid)
    .get();

  assert.equal(
    snapshot.exists,
    true,
    `User ${uid} must exist.`,
  );

  return snapshot.data();
}

async function readRelationship(uid) {
  const snapshot = await db
    .collection("referrals")
    .doc(uid)
    .get();

  return snapshot.exists
    ? snapshot.data()
    : null;
}

async function countJoinedHistory(uid) {
  const snapshot = await getHistoryCollection(uid).get();

  return snapshot.docs.filter(
    (document) =>
      document.data().type === "referral_joined",
  ).length;
}

async function assertNoRelationship(uid) {
  assert.equal(
    await readRelationship(uid),
    null,
    "Referral relationship must not exist.",
  );
}

// ============================================================
// CLEANUP
// ============================================================

after(async () => {
  for (const uid of createdHistoryUids) {
    const history = await getHistoryCollection(uid).get();

    for (const document of history.docs) {
      await document.ref.delete();
    }
  }

  for (const uid of createdUserUids) {
    const userRef = db
      .collection("users")
      .doc(uid);

    const subcollections = [
      "transactions",
      "achievements",
    ];

    for (const name of subcollections) {
      const snapshot = await userRef
        .collection(name)
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
// TEST 1: AUTHENTICATION REQUIRED
// ============================================================

test(
  "unauthenticated user cannot apply referral code",
  async () => {
    const data = createTestCase(
      "unauthenticated",
      "A2B3C4D5",
    );

    await seedReferrer(data);

    await seedUser({
      uid: data.referredUid,
    });

    await assert.rejects(
      callApplyReferralCode({
        uid: data.referredUid,
        code: data.code,
        authenticated: false,
      }),
      (error) => {
        assert.equal(
          error.code,
          "unauthenticated",
        );

        return true;
      },
    );

    await assertNoRelationship(data.referredUid);

    const referrer = await readUser(data.referrerUid);

    assert.equal(referrer.referralCount, 0);
  },
);

// ============================================================
// TEST 2: MISSING CODE
// ============================================================

test(
  "missing referral code is rejected",
  async () => {
    const uid =
      `${testPrefix}-missing-code-user`;

    await seedUser({ uid });

    await assert.rejects(
      callApplyReferralCode({
        uid,
        code: undefined,
      }),
      (error) => {
        assert.equal(
          error.code,
          "invalid-argument",
        );

        return true;
      },
    );

    await assertNoRelationship(uid);
  },
);

// ============================================================
// TEST 3: INVALID CODE
// ============================================================

test(
  "invalid referral code is rejected",
  async () => {
    const uid =
      `${testPrefix}-invalid-code-user`;

    await seedUser({ uid });

    await assert.rejects(
      callApplyReferralCode({
        uid,
        code: "INVALID!",
      }),
      (error) => {
        assert.equal(
          error.code,
          "invalid-argument",
        );

        return true;
      },
    );

    await assertNoRelationship(uid);
  },
);

// ============================================================
// TEST 4: UNKNOWN CODE
// ============================================================

test(
  "unknown referral code returns not-found",
  async () => {
    const data = createTestCase(
      "unknown-code",
      "B2C3D4E5",
    );

    await seedUser({
      uid: data.referredUid,
    });

    await assert.rejects(
      callApplyReferralCode({
        uid: data.referredUid,
        code: data.code,
      }),
      (error) => {
        assert.equal(
          error.code,
          "not-found",
        );

        return true;
      },
    );

    await assertNoRelationship(data.referredUid);
  },
);

// ============================================================
// TEST 5: SELF REFERRAL
// ============================================================

test(
  "user cannot apply their own referral code",
  async () => {
    const data = createTestCase(
      "self-referral",
      "C2D3E4F5",
    );

    await seedReferrer(data);

    await assert.rejects(
      callApplyReferralCode({
        uid: data.referrerUid,
        code: data.code,
      }),
      (error) => {
        assert.equal(
          error.code,
          "invalid-argument",
        );

        return true;
      },
    );

    const user = await readUser(data.referrerUid);

    assert.equal(user.referralCount, 0);

    await assertNoRelationship(data.referrerUid);
  },
);

// ============================================================
// TEST 6: CLIENT CANNOT CHOOSE UID
// ============================================================

test(
  "callable uses authenticated UID instead of client UID",
  async () => {
    const data = createTestCase(
      "client-uid",
      "D2E3F4G5",
    );

    const maliciousUid =
      `${testPrefix}-malicious-client-uid`;

    await seedReferrer(data);

    await seedUser({
      uid: data.referredUid,
    });

    await seedUser({
      uid: maliciousUid,
    });

    const result = await callApplyReferralCode({
      uid: data.referredUid,
      code: data.code,

      extraData: {
        uid: maliciousUid,
        referredUid: maliciousUid,
        referrerUid: maliciousUid,
      },
    });

    assert.equal(result.success, true);
    assert.equal(result.applied, true);

    assert.equal(
      result.referrerUid,
      data.referrerUid,
    );

    const authenticatedUser =
      await readUser(data.referredUid);

    assert.equal(
      authenticatedUser.referrerUid,
      data.referrerUid,
    );

    const maliciousUser =
      await readUser(maliciousUid);

    assert.equal(
      maliciousUser.referrerUid,
      undefined,
    );

    const relationship =
      await readRelationship(data.referredUid);

    assert.equal(
      relationship.referrerUid,
      data.referrerUid,
    );

    await assertNoRelationship(maliciousUid);

    const referrer = await readUser(data.referrerUid);

    assert.equal(referrer.referralCount, 1);

    assert.equal(
      await countJoinedHistory(data.referredUid),
      1,
    );
  },
);

// ============================================================
// TEST 7: SUCCESSFUL APPLICATION
// ============================================================

test(
  "authenticated user can apply valid referral code",
  async () => {
    const data = createTestCase(
      "success",
      "E2F3G4H5",
    );

    await seedReferrer(data);

    await seedUser({
      uid: data.referredUid,
    });

    createdHistoryUids.add(data.referredUid);

    const result = await callApplyReferralCode({
      uid: data.referredUid,
      code: data.code.toLowerCase(),
    });

    assert.equal(result.success, true);
    assert.equal(result.applied, true);

    assert.equal(
      result.referrerUid,
      data.referrerUid,
    );

    assert.equal(
      result.referralCode,
      data.code,
    );

    const user = await readUser(data.referredUid);

    assert.equal(
      user.referrerUid,
      data.referrerUid,
    );

    assert.equal(
      user.referralCodeUsed,
      data.code,
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

    const referrer = await readUser(data.referrerUid);

    assert.equal(referrer.referralCount, 1);

    assert.equal(
      await countJoinedHistory(data.referredUid),
      1,
    );
  },
);

// ============================================================
// TEST 8: EXISTING REFERRER
// ============================================================

test(
  "user cannot apply another referral code after joining",
  async () => {
    const data = createTestCase(
      "already-joined",
      "F2G3H4J5",
    );

    const oldReferrerUid =
      `${testPrefix}-old-referrer`;

    createdUserUids.add(oldReferrerUid);

    await seedReferrer(data);

    await seedUser({
      uid: data.referredUid,
      referrerUid: oldReferrerUid,
    });

    await assert.rejects(
      callApplyReferralCode({
        uid: data.referredUid,
        code: data.code,
      }),
      (error) => {
        assert.equal(
          error.code,
          "already-exists",
        );

        return true;
      },
    );

    const user = await readUser(data.referredUid);

    assert.equal(
      user.referrerUid,
      oldReferrerUid,
    );

    const referrer = await readUser(data.referrerUid);

    assert.equal(referrer.referralCount, 0);

    await assertNoRelationship(data.referredUid);
  },
);

// ============================================================
// TEST 9: CONCURRENT REQUESTS
// ============================================================

test(
  "concurrent callable requests create only one relationship",
  async () => {
    const data = createTestCase(
      "concurrent",
      "G2H3J4K5",
    );

    await seedReferrer(data);

    await seedUser({
      uid: data.referredUid,
    });

    createdHistoryUids.add(data.referredUid);

    const results = await Promise.allSettled(
      Array.from(
        { length: 5 },
        () => callApplyReferralCode({
          uid: data.referredUid,
          code: data.code,
        }),
      ),
    );

    const successful = results.filter(
      (result) => result.status === "fulfilled",
    );

    const rejected = results.filter(
      (result) => result.status === "rejected",
    );

    assert.equal(successful.length, 1);

    assert.equal(rejected.length, 4);

    for (const result of rejected) {
      assert.equal(
        result.reason.code,
        "already-exists",
      );
    }

    const user = await readUser(data.referredUid);

    assert.equal(
      user.referrerUid,
      data.referrerUid,
    );

    const relationship =
      await readRelationship(data.referredUid);

    assert.equal(
      relationship.referrerUid,
      data.referrerUid,
    );

    const referrer = await readUser(data.referrerUid);

    assert.equal(referrer.referralCount, 1);

    assert.equal(
      await countJoinedHistory(data.referredUid),
      1,
    );
  },
);
