"use strict";

// ============================================================
// 🐱 STELLURIINI - REFERRAL CALLABLE INTEGRATION TESTS
// ============================================================
//
// Testaa Firebase Callable -rajapintaa.
//
// Testit suoritetaan Firestore Emulatorissa.
//
// TESTIT 1–9:
// applyReferralCode-toiminta.
//
// TESTIT 10–20:
// Referral-lukutoiminnot, kirjautumisvaatimukset,
// kutsuttujen käyttäjien aktiivisuus ja bonuskertymät.
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
  getReferralProfile,
  getReferredUsers,
  getReferralStatus,
  getReferralDashboard,
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

async function callReferralReadFunction(
  callable,
  uid,
  authenticated = true,
) {
  return callable.run({
    auth: authenticated ? { uid } : null,
    data: {},
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
// HELPER: SEED REFERRAL USER WITH RELATIONSHIP
// ============================================================

async function seedReferredUser({
  uid,
  referrerUid,
  referralCode,
  active,
  bonus,
}) {
  const now = Date.now();

  const miningStartedAt = active
    ? new Date(now - 60 * 60 * 1000)
    : new Date(now - 3 * 60 * 60 * 1000);

  const miningEndsAt = active
    ? new Date(now + 60 * 60 * 1000)
    : new Date(now - 60 * 60 * 1000);

  await seedUser({ uid });

  await db
    .collection("users")
    .doc(uid)
    .set({
      miningStartedAt,
      miningEndsAt,
      lastMiningAt: new Date(now - 30 * 60 * 1000),
      email: "must-not-be-returned@example.test",
      privateProfileNote: "must-not-be-returned",
    }, { merge: true });

  createdReferralUids.add(uid);

  await db
    .collection("referrals")
    .doc(uid)
    .set({
      referredUid: uid,
      referrerUid,
      referralCode,
      referralBonusTotal: bonus,
      referralBonusTotalInitialized: true,
      createdAt: new Date(now - 24 * 60 * 60 * 1000),
    });
}

async function seedReferralGroup(name) {
  const suffix = Date.now().toString(36).slice(-5);
  const code = `${suffix}${name.slice(0, 3)}`.toUpperCase();

  const data = createTestCase(name, code);

  const activeUid = `${testPrefix}-${name}-active`;
  const inactiveUid = `${testPrefix}-${name}-inactive`;

  createdUserUids.add(activeUid);
  createdUserUids.add(inactiveUid);

  createdReferralUids.add(activeUid);
  createdReferralUids.add(inactiveUid);

  await seedReferrer(data);

  await db
    .collection("users")
    .doc(data.referrerUid)
    .set({
      referralCount: 2,
      referralTotalEarned: 3.75,
    }, { merge: true });

  await seedReferredUser({
    uid: activeUid,
    referrerUid: data.referrerUid,
    referralCode: data.code,
    active: true,
    bonus: 1.25,
  });

  await seedReferredUser({
    uid: inactiveUid,
    referrerUid: data.referrerUid,
    referralCode: data.code,
    active: false,
    bonus: 2.50,
  });

  return {
    ...data,
    activeUid,
    inactiveUid,
  };
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

    // Poistetaan automaattisesti luotu referral-koodi
    // vain silloin, kun koodi kuuluu tälle testikäyttäjälle.
    const userSnapshot = await userRef.get();

    if (userSnapshot.exists) {
      const userData = userSnapshot.data() || {};
      const generatedCode = userData.referralCode;

      if (
        typeof generatedCode === "string" &&
        generatedCode.trim()
      ) {
        const generatedCodeRef =
          getReferralCodeRef(generatedCode);

        if (generatedCodeRef) {
          const generatedCodeSnapshot =
            await generatedCodeRef.get();

          if (
            generatedCodeSnapshot.exists &&
            generatedCodeSnapshot.data()?.uid === uid
          ) {
            await generatedCodeRef.delete();
          }
        }
      }
    }

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
        assert.equal(error.code, "unauthenticated");
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
    const uid = `${testPrefix}-missing-code-user`;

    await seedUser({ uid });

    await assert.rejects(
      callApplyReferralCode({
        uid,
        code: undefined,
      }),
      (error) => {
        assert.equal(error.code, "invalid-argument");
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
    const uid = `${testPrefix}-invalid-code-user`;

    await seedUser({ uid });

    await assert.rejects(
      callApplyReferralCode({
        uid,
        code: "INVALID!",
      }),
      (error) => {
        assert.equal(error.code, "invalid-argument");
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
        assert.equal(error.code, "not-found");
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
        assert.equal(error.code, "invalid-argument");
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

    assert.equal(result.referrerUid, data.referrerUid);

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

    assert.equal(result.referrerUid, data.referrerUid);
    assert.equal(result.referralCode, data.code);

    const user = await readUser(data.referredUid);

    assert.equal(user.referrerUid, data.referrerUid);
    assert.equal(user.referralCodeUsed, data.code);

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
        assert.equal(error.code, "already-exists");
        return true;
      },
    );

    const user = await readUser(data.referredUid);

    assert.equal(user.referrerUid, oldReferrerUid);

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

    assert.equal(user.referrerUid, data.referrerUid);

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

// ============================================================
// TEST 10: GET REFERRAL PROFILE
// ============================================================

test(
  "getReferralProfile returns the authenticated user's referral profile",
  async () => {
    const uid = `${testPrefix}-profile-user`;

    await seedUser({ uid });

    const result = await callReferralReadFunction(
      getReferralProfile,
      uid,
    );

    assert.equal(result.success, true);
    assert.equal(typeof result.referralCode, "string");
    assert.ok(result.referralCode.length > 0);
    assert.equal(typeof result.referralBonusPercent, "number");
    assert.equal(typeof result.referralBonusRate, "number");
    assert.equal(typeof result.totalUsers, "number");
    assert.ok(Array.isArray(result.referralMilestones));
    assert.equal(result.totalReferralRewards, 0);
  },
);

// ============================================================
// TEST 11: GET REFERRAL PROFILE REQUIRES AUTH
// ============================================================

test(
  "getReferralProfile rejects unauthenticated users",
  async () => {
    await assert.rejects(
      callReferralReadFunction(
        getReferralProfile,
        `${testPrefix}-profile-unauthenticated`,
        false,
      ),
      (error) => {
        assert.equal(error.code, "unauthenticated");
        return true;
      },
    );
  },
);

// ============================================================
// TEST 12: GET REFERRED USERS
// ============================================================

test(
  "getReferredUsers returns an empty list for a user without referrals",
  async () => {
    const uid = `${testPrefix}-referred-users-user`;

    await seedUser({ uid });

    const result = await callReferralReadFunction(
      getReferredUsers,
      uid,
    );

    assert.equal(result.success, true);
    assert.equal(typeof result.referralCode, "string");
    assert.ok(result.referralCode.length > 0);
    assert.equal(typeof result.referralBonusPercent, "number");
    assert.equal(typeof result.referralBonusRate, "number");
    assert.equal(typeof result.totalUsers, "number");
    assert.equal(result.invitedCount, 0);
    assert.equal(result.activeCount, 0);
    assert.equal(result.inactiveCount, 0);
    assert.ok(result.referralSummary !== null);
    assert.equal(typeof result.referralSummary, "object");
    assert.ok(Array.isArray(result.users));
    assert.equal(result.users.length, 0);
    assert.equal(typeof result.generatedAt, "string");
    assert.equal(typeof result.utcDate, "string");
  },
);

// ============================================================
// TEST 13: GET REFERRED USERS REQUIRES AUTH
// ============================================================

test(
  "getReferredUsers rejects unauthenticated users",
  async () => {
    await assert.rejects(
      callReferralReadFunction(
        getReferredUsers,
        `${testPrefix}-referred-users-unauthenticated`,
        false,
      ),
      (error) => {
        assert.equal(error.code, "unauthenticated");
        return true;
      },
    );
  },
);

// ============================================================
// TEST 14: GET REFERRAL STATUS
// ============================================================

test(
  "getReferralStatus returns an empty referral status for a new user",
  async () => {
    const uid = `${testPrefix}-status-user`;

    await seedUser({ uid });

    const result = await callReferralReadFunction(
      getReferralStatus,
      uid,
    );

    assert.equal(result.success, true);
    assert.equal(typeof result.referralCode, "string");
    assert.ok(result.referralCode.length > 0);
    assert.equal(typeof result.referralBonusPercent, "number");
    assert.equal(typeof result.referralBonusRate, "number");
    assert.equal(typeof result.totalUsers, "number");
    assert.equal(result.referralCount, 0);
    assert.equal(result.activeCount, 0);
    assert.equal(result.inactiveCount, 0);
    assert.ok(Array.isArray(result.referrals));
    assert.equal(result.referrals.length, 0);
    assert.equal(result.totalReferralRewards, 0);
    assert.equal(typeof result.generatedAt, "string");
  },
);

// ============================================================
// TEST 15: GET REFERRAL STATUS REQUIRES AUTH
// ============================================================

test(
  "getReferralStatus rejects unauthenticated users",
  async () => {
    await assert.rejects(
      callReferralReadFunction(
        getReferralStatus,
        `${testPrefix}-status-unauthenticated`,
        false,
      ),
      (error) => {
        assert.equal(error.code, "unauthenticated");
        return true;
      },
    );
  },
);

// ============================================================
// TEST 16: GET REFERRAL DASHBOARD
// ============================================================

test(
  "getReferralDashboard returns an empty dashboard for a new user",
  async () => {
    const uid = `${testPrefix}-dashboard-user`;

    await seedUser({ uid });

    const result = await callReferralReadFunction(
      getReferralDashboard,
      uid,
    );

    assert.equal(result.success, true);
    assert.equal(typeof result.referralCode, "string");
    assert.ok(result.referralCode.length > 0);
    assert.equal(typeof result.referralBonusPercent, "number");
    assert.equal(typeof result.referralBonusRate, "number");
    assert.equal(typeof result.totalUsers, "number");
    assert.equal(result.invitedCount, 0);
    assert.equal(result.activeCount, 0);
    assert.equal(result.inactiveCount, 0);
    assert.equal(result.totalReferralRewards, 0);
    assert.ok(Array.isArray(result.users));
    assert.equal(result.users.length, 0);
    assert.equal(typeof result.generatedAt, "string");
  },
);

// ============================================================
// TEST 17: GET REFERRAL DASHBOARD REQUIRES AUTH
// ============================================================

test(
  "getReferralDashboard rejects unauthenticated users",
  async () => {
    await assert.rejects(
      callReferralReadFunction(
        getReferralDashboard,
        `${testPrefix}-dashboard-unauthenticated`,
        false,
      ),
      (error) => {
        assert.equal(error.code, "unauthenticated");
        return true;
      },
    );
  },
);

// ============================================================
// TEST 18: GET REFERRED USERS WITH REFERRALS
// ============================================================

test(
  "getReferredUsers returns referred users with correct activity and bonus data",
  async () => {
    const data = await seedReferralGroup("referred-users-populated");

    const result = await callReferralReadFunction(
      getReferredUsers,
      data.referrerUid,
    );

    assert.equal(result.success, true);
    assert.equal(result.invitedCount, 2);
    assert.equal(result.activeCount, 1);
    assert.equal(result.inactiveCount, 1);
    assert.equal(result.totalReferralRewards, 3.75);
    assert.ok(Array.isArray(result.users));
    assert.equal(result.users.length, 2);

    const activeUser = result.users.find(
      (user) => user.uid === data.activeUid,
    );

    const inactiveUser = result.users.find(
      (user) => user.uid === data.inactiveUid,
    );

    assert.ok(activeUser);
    assert.ok(inactiveUser);

    assert.equal(activeUser.active, true);
    assert.equal(activeUser.miningActive, true);
    assert.equal(activeUser.isMining, true);
    assert.equal(activeUser.referralBonusEarned, 1.25);
    assert.equal(activeUser.referralBonus, 1.25);

    assert.equal(inactiveUser.active, false);
    assert.equal(inactiveUser.miningActive, false);
    assert.equal(inactiveUser.isMining, false);
    assert.equal(inactiveUser.referralBonusEarned, 2.5);
    assert.equal(inactiveUser.referralBonus, 2.5);

    const expectedUserKeys = [
      "uid",
      "displayName",
      "username",
      "active",
      "miningActive",
      "isMining",
      "lastActivityAt",
      "referralJoinedAt",
      "referralBonusEarned",
      "referralBonus",
    ].sort();

    for (const user of result.users) {
      assert.deepEqual(
        Object.keys(user).sort(),
        expectedUserKeys,
      );

      assert.equal(Object.hasOwn(user, "email"), false);
      assert.equal(Object.hasOwn(user, "privateProfileNote"), false);
    }
  },
);

// ============================================================
// TEST 19: GET REFERRAL STATUS WITH REFERRALS
// ============================================================

test(
  "getReferralStatus returns compact referral data and correct counts",
  async () => {
    const data = await seedReferralGroup("referral-status-populated");

    const result = await callReferralReadFunction(
      getReferralStatus,
      data.referrerUid,
    );

    assert.equal(result.success, true);
    assert.equal(result.referralCount, 2);
    assert.equal(result.activeCount, 1);
    assert.equal(result.inactiveCount, 1);
    assert.equal(result.totalReferralRewards, 3.75);
    assert.ok(Array.isArray(result.referrals));
    assert.equal(result.referrals.length, 2);

    const activeUser = result.referrals.find(
      (user) => user.uid === data.activeUid,
    );

    const inactiveUser = result.referrals.find(
      (user) => user.uid === data.inactiveUid,
    );

    assert.ok(activeUser);
    assert.ok(inactiveUser);

    assert.equal(activeUser.isMining, true);
    assert.equal(activeUser.referralBonus, 1.25);
    assert.equal(inactiveUser.isMining, false);
    assert.equal(inactiveUser.referralBonus, 2.5);

    const expectedKeys = [
      "uid",
      "username",
      "isMining",
      "referralBonus",
    ].sort();

    for (const user of result.referrals) {
      assert.deepEqual(
        Object.keys(user).sort(),
        expectedKeys,
      );

      assert.equal(Object.hasOwn(user, "email"), false);
    }
  },
);

// ============================================================
// TEST 20: GET REFERRAL DASHBOARD WITH REFERRALS
// ============================================================

test(
  "getReferralDashboard returns correct referral totals and user details",
  async () => {
    const data = await seedReferralGroup("referral-dashboard-populated");

    const result = await callReferralReadFunction(
      getReferralDashboard,
      data.referrerUid,
    );

    assert.equal(result.success, true);
    assert.equal(result.invitedCount, 2);
    assert.equal(result.activeCount, 1);
    assert.equal(result.inactiveCount, 1);
    assert.equal(result.totalReferralRewards, 3.75);
    assert.ok(Array.isArray(result.users));
    assert.equal(result.users.length, 2);

    const activeUser = result.users.find(
      (user) => user.uid === data.activeUid,
    );

    const inactiveUser = result.users.find(
      (user) => user.uid === data.inactiveUid,
    );

    assert.ok(activeUser);
    assert.ok(inactiveUser);

    assert.equal(activeUser.active, true);
    assert.equal(activeUser.referralBonusEarned, 1.25);
    assert.equal(inactiveUser.active, false);
    assert.equal(inactiveUser.referralBonusEarned, 2.5);

    for (const user of result.users) {
      assert.equal(Object.hasOwn(user, "email"), false);
      assert.equal(Object.hasOwn(user, "privateProfileNote"), false);
    }
  },
);