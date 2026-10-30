"use strict";

const {
  test,
} = require("node:test");

const assert = require("node:assert/strict");

const {
  normalizeBonusAmount,
  getInitializedReferralBonusTotal,
  applyReferralBonusToSummary,
} = require("../src/services/referralBonusSummaryService");

// ============================================================
// 🐱 STELLURIINI - REFERRAL SUMMARY UNIT TESTS
// ============================================================

function createFakeTransaction(historyAmounts = []) {
  const reads = [];
  const writes = [];

  const transaction = {
    async get(reference) {
      reads.push(reference);

      // Historiakyselyn tulos simuloidaan testidatalla.
      return {
        forEach(callback) {
          historyAmounts.forEach((amount, index) => {
            callback({
              id: `history-${index}`,
              data() {
                return {
                  amount,
                };
              },
            });
          });
        },
      };
    },

    set(reference, data, options) {
      writes.push({
        reference,
        data,
        options,
      });
    },
  };

  return {
    transaction,
    reads,
    writes,
  };
}

function createRelationshipData(overrides = {}) {
  return {
    referrerUid: "referrer-123",
    referredUid: "referred-456",
    ...overrides,
  };
}

const relationshipRef = {
  id: "referred-456",
};

// ============================================================
// NORMALIZATION
// ============================================================

test("normalizeBonusAmount accepts positive amounts", () => {
  assert.equal(normalizeBonusAmount(5), 5);
  assert.equal(normalizeBonusAmount("2.5"), 2.5);
});

test("normalizeBonusAmount rejects invalid amounts", () => {
  assert.equal(normalizeBonusAmount(-1), 0);
  assert.equal(normalizeBonusAmount(0), 0);
  assert.equal(normalizeBonusAmount("invalid"), 0);
  assert.equal(normalizeBonusAmount(Infinity), 0);
});

// ============================================================
// INITIALIZED SUMMARY
// ============================================================

test("initialized summary returns its stored total", () => {
  assert.equal(
    getInitializedReferralBonusTotal({
      referralBonusTotal: 12.5,
      referralBonusTotalInitialized: true,
    }),
    12.5,
  );
});

test("missing or invalid summary is not treated as initialized", () => {
  assert.equal(
    getInitializedReferralBonusTotal({
      referralBonusTotal: 12.5,
    }),
    null,
  );

  assert.equal(
    getInitializedReferralBonusTotal({
      referralBonusTotal: -1,
      referralBonusTotalInitialized: true,
    }),
    null,
  );
});

// ============================================================
// LEGACY SUMMARY INITIALIZATION
// ============================================================

test("legacy summary includes historical bonuses and the new bonus", async () => {
  const fake = createFakeTransaction([2, 3.5, 4]);

  const result = await applyReferralBonusToSummary({
    transaction: fake.transaction,
    relationshipRef,
    relationshipData: createRelationshipData(),
    referrerUid: "referrer-123",
    referredUid: "referred-456",
    bonusAmount: 5,
  });

  assert.equal(result, true);
  assert.equal(fake.reads.length, 1);
  assert.equal(fake.writes.length, 1);

  assert.deepEqual(fake.writes[0].data, {
    referralBonusTotal: 14.5,
    referralBonusTotalInitialized: true,
  });

  assert.deepEqual(fake.writes[0].options, {
    merge: true,
  });
});

// ============================================================
// ALREADY INITIALIZED SUMMARY
// ============================================================

test("initialized summary is incremented without reading history", async () => {
  const fake = createFakeTransaction();

  const result = await applyReferralBonusToSummary({
    transaction: fake.transaction,
    relationshipRef,
    relationshipData: createRelationshipData({
      referralBonusTotal: 10,
      referralBonusTotalInitialized: true,
    }),
    referrerUid: "referrer-123",
    referredUid: "referred-456",
    bonusAmount: 2,
  });

  assert.equal(result, true);
  assert.equal(fake.reads.length, 0);
  assert.equal(fake.writes.length, 1);

  assert.ok(
    fake.writes[0].data.referralBonusTotal,
  );

  assert.equal(
    fake.writes[0].data.referralBonusTotalInitialized,
    undefined,
  );
});

// ============================================================
// INVALID BONUS AND RELATIONSHIP
// ============================================================

test("invalid bonus does not write a summary", async () => {
  const fake = createFakeTransaction();

  const result = await applyReferralBonusToSummary({
    transaction: fake.transaction,
    relationshipRef,
    relationshipData: createRelationshipData(),
    referrerUid: "referrer-123",
    referredUid: "referred-456",
    bonusAmount: 0,
  });

  assert.equal(result, false);
  assert.equal(fake.reads.length, 0);
  assert.equal(fake.writes.length, 0);
});

test("mismatched relationship is rejected", async () => {
  const fake = createFakeTransaction();

  await assert.rejects(
    applyReferralBonusToSummary({
      transaction: fake.transaction,
      relationshipRef,
      relationshipData: createRelationshipData({
        referrerUid: "different-user",
      }),
      referrerUid: "referrer-123",
      referredUid: "referred-456",
      bonusAmount: 5,
    }),
    /does not match/,
  );

  assert.equal(fake.reads.length, 0);
  assert.equal(fake.writes.length, 0);
});