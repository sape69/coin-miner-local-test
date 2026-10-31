
"use strict";

// ============================================================
// 🐱 STELLURIINI - REFERRAL CALLABLE INTEGRATION TESTS
// ============================================================
//
// Testaa applyReferralCode()-Firebase Callable -rajapintaa.
//
// Testit:
// 1. Kirjautumaton käyttäjä hylätään.
// 2. Virheellinen referral-koodi hylätään.
// 3. Tuntematon referral-koodi hylätään.
// 4. Oma referral-koodi hylätään.
// 5. Asiakkaan lähettämää referrerUid-arvoa ei käytetä.
// 6. Kirjautunut käyttäjä voi käyttää kelvollista koodia.
// 7. Käyttäjä ei voi vaihtaa aikaisempaa kutsujaa.
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
  getHistoryCollection,
} = require("../src/utils/userUtils");

const {
  getReferralCodeRef,
} = require("../src/services/referralService");

const {
  applyReferralCode,
} = require("../src/functions/referralFunctions");

// ============================================================
// TEST DATA
// ============================================================

const testPrefix =
  `referral-callable-${Date.now()}`;

const createdUserUids = new Set();
const createdCodes = new Set();
const createdHistoryUids = new Set();

// ============================================================
// HELPERS
// ============================================================

function createTestCase(name, code) {
  const id = `${testPrefix}-${name}`;

  const referrerUid = `${id}-referrer`;
  const referredUid = `${id}-referred`;

  createdUserUids.add(referrerUid);
  createdUserUids.add(referredUid);

  createdCodes.add(code);

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

  assert.ok(codeRef);

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
    data.referral = {
      referrerUid,
    };
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

  assert.equal(snapshot.exists, true);

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

async function readHistory(uid) {
  const snapshot = await getHistoryCollection(uid).get();

  return snapshot.docs.map(
    (document) => document.data(),
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

    await db
      .collection("referrals")
      .doc(uid)
      .delete();
  }

  for (const code of createdCodes) {
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

    assert.equal(
      await readRelationship(data.referredUid),
      null,
    );

    const referrer = await readUser(data.referrerUid);

    assert.equal(referrer.referralCount, 0);
  },
);

// ============================================================
// TEST 2: INVALID CODE
// ============================================================

test(
  "invalid referral code is rejected by callable",
  async () => {
    const uid = `${testPrefix}-invalid-user`;

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

    assert.equal(
      await readRelationship(uid),
      null,
    );
  },
);

// ============================================================
// TEST 3: UNKNOWN CODE
// ============================================================

test(
  "unknown referral code returns not-found",
  async () => {
    const data = createTestCase(
      "unknown",
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

    assert.equal(
      await readRelationship(data.referredUid),
      null,
    );
  },
);

// ============================================================
// TEST 4: SELF REFERRAL
// ============================================================

test(
  "user cannot apply their own referral code",
  async () => {
    const data = createTestCase(
      "self",
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

    assert.equal(
      await readRelationship(data.referrerUid),
      null,
    );
  },
);

// ============================================================
// TEST 5: CLIENT CANNOT CHOOSE REFERRER UID
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

      // Asiakas yrittää antaa oman UID-arvonsa.
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

    assert.equal(
      await readRelationship(maliciousUid),
      null,
    );

    const referrer = await readUser(data.referrerUid);

    assert.equal(referrer.referralCount, 1);
  },
);

// ============================================================
// TEST 6: SUCCESSFUL APPLICATION
// ============================================================

test(
  "authenticated user can successfully apply valid code",
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

    const relationship =
      await readRelationship(data.referredUid);

    assert.equal(
      relationship.referrerUid,
      data.referrerUid,
    );

    const referrer = await readUser(data.referrerUid);

    assert.equal(
      referrer.referralCount,
      1,
    );

    const history = await readHistory(data.referredUid);

    assert.equal(
      history.filter(
        (item) => item.type === "referral_joined",
      ).length,
      1,
    );
  },
);

// ============================================================
// TEST 7: EXISTING REFERRER
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

    assert.equal(
      user.referrerUid,
      oldReferrerUid,
    );

    const referrer = await readUser(data.referrerUid);

    assert.equal(
      referrer.referralCount,
      0,
    );

    assert.equal(
      await readRelationship(data.referredUid),
      null,
    );
  },
);
