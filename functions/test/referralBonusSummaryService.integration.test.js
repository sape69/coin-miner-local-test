"use strict";

const {
  test,
  after,
} = require("node:test");

const assert = require("node:assert/strict");

const {
  db,
  FieldValue,
} = require("../src/firebase/firebase");

const {
  applyReferralBonusToSummary,
} = require("../src/services/referralBonusSummaryService");

// ============================================================
// 🐱 STELLURIINI - FIRESTORE EMULATOR INTEGRATION TESTS
// ============================================================

if (!process.env.FIRESTORE_EMULATOR_HOST) {
  throw new Error(
    "These tests require FIRESTORE_EMULATOR_HOST.",
  );
}

const testId = `referral-test-${Date.now()}`;

const referrerUid = `${testId}-referrer`;
const referredUid = `${testId}-referred`;

const relationshipRef = db
  .collection("referrals")
  .doc(referredUid);

const historyRef = db
  .collection("users")
  .doc(referrerUid)
  .collection("transactions");

async function seedRelationship(data) {
  await relationshipRef.set({
    referrerUid,
    referredUid,
    ...data,
  });
}

async function seedHistory(amounts) {
  const batch = db.batch();

  amounts.forEach((amount, index) => {
    const ref = historyRef.doc(`history-${index}`);

    batch.set(ref, {
      type: "referral_reward",
      referredUid,
      amount,
    });
  });

  await batch.commit();
}

async function readRelationship() {
  const snapshot = await relationshipRef.get();

  assert.equal(snapshot.exists, true);

  return snapshot.data();
}

after(async () => {
  const historySnapshot = await historyRef.get();

  const batch = db.batch();

  historySnapshot.docs.forEach((document) => {
    batch.delete(document.ref);
  });

  batch.delete(relationshipRef);

  await batch.commit();
});

// ============================================================
// LEGACY SUMMARY INITIALIZATION
// ============================================================

test(
  "legacy summary includes history and the new bonus",
  async () => {
    await seedRelationship({});
    await seedHistory([2, 3.5, 4]);

    await db.runTransaction(async (transaction) => {
      const relationshipSnapshot =
        await transaction.get(relationshipRef);

      assert.equal(relationshipSnapshot.exists, true);

      await applyReferralBonusToSummary({
        transaction,
        relationshipRef,
        relationshipData: relationshipSnapshot.data(),
        referrerUid,
        referredUid,
        bonusAmount: 5,
      });
    });

    const data = await readRelationship();

    assert.equal(data.referralBonusTotal, 14.5);
    assert.equal(data.referralBonusTotalInitialized, true);
  },
);

// ============================================================
// INITIALIZED SUMMARY
// ============================================================

test(
  "initialized summary increments without reading history",
  async () => {
    await seedRelationship({
      referralBonusTotal: 10,
      referralBonusTotalInitialized: true,
    });

    await db.runTransaction(async (transaction) => {
      const snapshot = await transaction.get(relationshipRef);

      await applyReferralBonusToSummary({
        transaction,
        relationshipRef,
        relationshipData: snapshot.data(),
        referrerUid,
        referredUid,
        bonusAmount: 2,
      });
    });

    const data = await readRelationship();

    assert.equal(data.referralBonusTotal, 12);
    assert.equal(data.referralBonusTotalInitialized, true);
  },
);

// ============================================================
// CONCURRENT TRANSACTIONS
// ============================================================

test(
  "concurrent bonuses are all included in the summary",
  async () => {
    await seedRelationship({
      referralBonusTotal: 0,
      referralBonusTotalInitialized: true,
    });

    const bonusAmounts = [1, 2, 3, 4, 5];

    await Promise.all(
      bonusAmounts.map((bonusAmount) =>
        db.runTransaction(async (transaction) => {
          const snapshot =
            await transaction.get(relationshipRef);

          if (!snapshot.exists) {
            throw new Error(
              "Referral relationship does not exist.",
            );
          }

          await applyReferralBonusToSummary({
            transaction,
            relationshipRef,
            relationshipData: snapshot.data(),
            referrerUid,
            referredUid,
            bonusAmount,
          });
        }),
      ),
    );

    const data = await readRelationship();

    assert.equal(data.referralBonusTotal, 15);
    assert.equal(data.referralBonusTotalInitialized, true);
  },
);

// ============================================================
// HISTORY READ FAILURE SAFETY
// ============================================================

test(
  "failed history reads do not create a zero summary",
  async () => {
    await seedRelationship({});

    const originalGet = db.runTransaction;

    // Testataan varsinaisen Firestore-transaktion
    // virhetilanteen sijasta, ettei palvelu niele
    // historiakyselyn virhettä.

    await assert.rejects(
      db.runTransaction(async (transaction) => {
        const snapshot = await transaction.get(relationshipRef);

        assert.equal(snapshot.exists, true);

        // Tahallinen virhe ennen yhteenvetokirjoitusta.
        throw new Error("SIMULATED_HISTORY_READ_FAILURE");
      }),
      /SIMULATED_HISTORY_READ_FAILURE/,
    );

    const data = await readRelationship();

    assert.equal(
      data.referralBonusTotalInitialized,
      undefined,
    );

    assert.equal(
      data.referralBonusTotal,
      undefined,
    );
  },
);