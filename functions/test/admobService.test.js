
"use strict";

// ============================================================
// 🐱 STELLURIINI - ADMOB SERVICE TESTS
// ============================================================
//
// Tests:
// - UID validation
// - Transaction ID validation
// - Reward purpose validation
// - Ad network validation
// - Timestamp validation
// - Key ID validation
// - Signature format validation
// - Custom data parsing
// - Reward configuration
// - Signed query validation
//
// These tests do not contact Google's production servers.
// ============================================================

const test = require("node:test");
const assert = require("node:assert/strict");

const {
  REWARD_CONFIG,
  validateUid,
  validateTransactionId,
  validateRewardPurpose,
  validateTimestamp,
  validateAdNetwork,
  validateKeyId,
  validateSignature,
  parseCustomData,
  getExpectedAdMobConfig,
  verifyAdMobSignature,
} = require("../src/services/admobService");

// ============================================================
// 👤 UID VALIDATION
// ============================================================

test("validateUid accepts a valid UID", () => {
  assert.equal(validateUid("test-user-123"), "test-user-123");
});

test("validateUid trims whitespace", () => {
  assert.equal(validateUid("  test-user  "), "test-user");
});

test("validateUid rejects an empty UID", () => {
  assert.equal(validateUid(""), "");
});

test("validateUid rejects non-string values", () => {
  assert.equal(validateUid(12345), "");
});

test("validateUid rejects control characters", () => {
  assert.equal(validateUid("test\nuser"), "");
});

test("validateUid rejects excessively long values", () => {
  assert.equal(validateUid("a".repeat(129)), "");
});

// ============================================================
// 🧾 TRANSACTION ID VALIDATION
// ============================================================

test("validateTransactionId accepts a valid transaction ID", () => {
  assert.equal(
    validateTransactionId("transaction-123"),
    "transaction-123",
  );
});

test("validateTransactionId accepts non-hexadecimal IDs", () => {
  assert.equal(
    validateTransactionId("AdMob.Transaction_123"),
    "AdMob.Transaction_123",
  );
});

test("validateTransactionId trims whitespace", () => {
  assert.equal(
    validateTransactionId("  transaction-123  "),
    "transaction-123",
  );
});

test("validateTransactionId rejects an empty value", () => {
  assert.equal(validateTransactionId(""), "");
});

test("validateTransactionId rejects slash characters", () => {
  assert.equal(validateTransactionId("transaction/123"), "");
});

test("validateTransactionId rejects control characters", () => {
  assert.equal(validateTransactionId("transaction\n123"), "");
});

test("validateTransactionId rejects excessively long values", () => {
  assert.equal(validateTransactionId("a".repeat(257)), "");
});

// ============================================================
// 🎁 REWARD PURPOSE VALIDATION
// ============================================================

test("validateRewardPurpose accepts mining_start", () => {
  assert.equal(validateRewardPurpose("mining_start"), "mining_start");
});

test("validateRewardPurpose accepts power_boost", () => {
  assert.equal(validateRewardPurpose("power_boost"), "power_boost");
});

test("validateRewardPurpose rejects unknown purposes", () => {
  assert.equal(validateRewardPurpose("unknown_reward"), "");
});

test("validateRewardPurpose rejects incorrect casing", () => {
  assert.equal(validateRewardPurpose("POWER_BOOST"), "");
});

// ============================================================
// 📡 AD NETWORK VALIDATION
// ============================================================

test("validateAdNetwork accepts numeric network IDs", () => {
  assert.equal(validateAdNetwork("123456"), "123456");
});

test("validateAdNetwork trims whitespace", () => {
  assert.equal(validateAdNetwork("  123456  "), "123456");
});

test("validateAdNetwork rejects alphabetic values", () => {
  assert.equal(validateAdNetwork("google"), "");
});

test("validateAdNetwork rejects empty values", () => {
  assert.equal(validateAdNetwork(""), "");
});

test("validateAdNetwork rejects excessively long values", () => {
  assert.equal(validateAdNetwork("1".repeat(65)), "");
});

// ============================================================
// 🕒 TIMESTAMP VALIDATION
// ============================================================

test("validateTimestamp accepts a current timestamp", () => {
  const timestamp = Date.now();

  assert.equal(validateTimestamp(String(timestamp)), timestamp);
});

test("validateTimestamp accepts a timestamp within future tolerance", () => {
  const timestamp = Date.now() + 60_000;

  assert.equal(validateTimestamp(String(timestamp)), timestamp);
});

test("validateTimestamp rejects an empty value", () => {
  assert.equal(validateTimestamp(""), 0);
});

test("validateTimestamp rejects alphabetic values", () => {
  assert.equal(validateTimestamp("invalid"), 0);
});

test("validateTimestamp rejects negative values", () => {
  assert.equal(validateTimestamp("-12345"), 0);
});

test("validateTimestamp rejects zero", () => {
  assert.equal(validateTimestamp("0"), 0);
});

test("validateTimestamp rejects excessively future timestamps", () => {
  const timestamp = Date.now() + 10 * 60 * 1000;

  assert.equal(validateTimestamp(String(timestamp)), 0);
});

test("validateTimestamp rejects unsafe integers", () => {
  assert.equal(validateTimestamp("999999999999999999999"), 0);
});

// ============================================================
// 🔑 KEY ID VALIDATION
// ============================================================

test("validateKeyId accepts a numeric string", () => {
  assert.equal(validateKeyId("123456"), "123456");
});

test("validateKeyId accepts a numeric value", () => {
  assert.equal(validateKeyId(123456), "123456");
});

test("validateKeyId rejects alphabetic values", () => {
  assert.equal(validateKeyId("abc123"), "");
});

test("validateKeyId rejects negative values", () => {
  assert.equal(validateKeyId(-123), "");
});

test("validateKeyId rejects empty values", () => {
  assert.equal(validateKeyId(""), "");
});

// ============================================================
// 🔐 SIGNATURE FORMAT VALIDATION
// ============================================================

test("validateSignature accepts a valid Base64URL signature", () => {
  assert.equal(validateSignature("YWJjZGVm"), "YWJjZGVm");
});

test("validateSignature accepts valid URL-safe characters", () => {
  assert.equal(validateSignature("YWJj-ZGV"), "YWJj-ZGV");
});

test("validateSignature rejects empty values", () => {
  assert.equal(validateSignature(""), "");
});

test("validateSignature rejects invalid characters", () => {
  assert.equal(validateSignature("signature!"), "");
});

test("validateSignature rejects invalid Base64URL length", () => {
  assert.equal(validateSignature("abcde"), "");
});

test("validateSignature rejects excessively long values", () => {
  assert.equal(validateSignature("a".repeat(8193)), "");
});

// ============================================================
// 🧩 CUSTOM DATA
// ============================================================

test("parseCustomData accepts mining_start data", () => {
  const result = parseCustomData("test-user:mining_start");

  assert.deepEqual(result, {
    uid: "test-user",
    rewardPurpose: "mining_start",
    customData: "test-user:mining_start",
  });
});

test("parseCustomData accepts power_boost data", () => {
  const result = parseCustomData("test-user:power_boost");

  assert.deepEqual(result, {
    uid: "test-user",
    rewardPurpose: "power_boost",
    customData: "test-user:power_boost",
  });
});

test("parseCustomData accepts URL-encoded data", () => {
  const result = parseCustomData(
    encodeURIComponent("test-user:power_boost"),
  );

  assert.equal(result.uid, "test-user");
  assert.equal(result.rewardPurpose, "power_boost");
});

test("parseCustomData trims surrounding whitespace", () => {
  const result = parseCustomData("  test-user:power_boost  ");

  assert.equal(result.customData, "test-user:power_boost");
});

test("parseCustomData rejects empty data", () => {
  assert.throws(
    () => parseCustomData(""),
    { code: "ADMOB_CUSTOM_DATA_INVALID" },
  );
});

test("parseCustomData rejects missing separator", () => {
  assert.throws(
    () => parseCustomData("test-user"),
    { code: "ADMOB_CUSTOM_DATA_MISSING" },
  );
});

test("parseCustomData rejects missing UID", () => {
  assert.throws(
    () => parseCustomData(":power_boost"),
    { code: "ADMOB_CUSTOM_DATA_MISSING" },
  );
});

test("parseCustomData rejects unknown reward purpose", () => {
  assert.throws(
    () => parseCustomData("test-user:unknown"),
    { code: "ADMOB_INVALID_REWARD_PURPOSE" },
  );
});

test("parseCustomData rejects multiple separators", () => {
  assert.throws(
    () => parseCustomData("test-user:power_boost:extra"),
    { code: "ADMOB_CUSTOM_DATA_MISSING" },
  );
});

test("parseCustomData rejects invalid URL encoding", () => {
  assert.throws(
    () => parseCustomData("%E0%A4%A"),
    { code: "ADMOB_CUSTOM_DATA_INVALID" },
  );
});

test("parseCustomData rejects control characters", () => {
  assert.throws(
    () => parseCustomData("test-user\n:power_boost"),
    { code: "ADMOB_CUSTOM_DATA_INVALID" },
  );
});

// ============================================================
// ⚙️ REWARD CONFIGURATION
// ============================================================

test("REWARD_CONFIG contains mining_start configuration", () => {
  assert.ok(REWARD_CONFIG.mining_start);

  assert.equal(
    typeof REWARD_CONFIG.mining_start.adUnit,
    "string",
  );

  assert.equal(
    Number.isSafeInteger(REWARD_CONFIG.mining_start.rewardAmount),
    true,
  );

  assert.equal(
    typeof REWARD_CONFIG.mining_start.rewardItem,
    "string",
  );
});

test("REWARD_CONFIG contains power_boost configuration", () => {
  assert.ok(REWARD_CONFIG.power_boost);

  assert.equal(
    typeof REWARD_CONFIG.power_boost.adUnit,
    "string",
  );

  assert.equal(
    Number.isSafeInteger(REWARD_CONFIG.power_boost.rewardAmount),
    true,
  );

  assert.equal(
    typeof REWARD_CONFIG.power_boost.rewardItem,
    "string",
  );
});

test("getExpectedAdMobConfig returns mining_start configuration", () => {
  const result = getExpectedAdMobConfig("mining_start");

  assert.deepEqual(result, REWARD_CONFIG.mining_start);
});

test("getExpectedAdMobConfig returns power_boost configuration", () => {
  const result = getExpectedAdMobConfig("power_boost");

  assert.deepEqual(result, REWARD_CONFIG.power_boost);
});

test("getExpectedAdMobConfig rejects unknown purposes", () => {
  assert.throws(
    () => getExpectedAdMobConfig("unknown"),
    { code: "ADMOB_INVALID_REWARD_PURPOSE" },
  );
});

// ============================================================
// 🔐 SIGNED QUERY VALIDATION
// ============================================================

test("verifyAdMobSignature rejects a missing query string", async () => {
  await assert.rejects(
    () => verifyAdMobSignature(""),
    { code: "ADMOB_QUERY_STRING_MISSING" },
  );
});

test("verifyAdMobSignature rejects a missing signature parameter", async () => {
  await assert.rejects(
    () => verifyAdMobSignature(
      "ad_network=123&transaction_id=test",
    ),
    { code: "ADMOB_INVALID_SIGNATURE" },
  );
});

test("verifyAdMobSignature rejects an incorrectly ordered signature parameter", async () => {
  await assert.rejects(
    () => verifyAdMobSignature(
      "ad_network=123&signature=YWJjZGVm&transaction_id=test&key_id=123",
    ),
    { code: "ADMOB_INVALID_SIGNATURE" },
  );
});

test("verifyAdMobSignature rejects a missing key ID", async () => {
  await assert.rejects(
    () => verifyAdMobSignature(
      "ad_network=123&signature=YWJjZGVm",
    ),
    { code: "ADMOB_INVALID_SIGNATURE" },
  );
});

test("verifyAdMobSignature rejects an invalid signature format", async () => {
  await assert.rejects(
    () => verifyAdMobSignature(
      "ad_network=123&signature=invalid!&key_id=123",
    ),
    { code: "ADMOB_INVALID_SIGNATURE" },
  );
});

test("verifyAdMobSignature rejects duplicate signature parameters", async () => {
  await assert.rejects(
    () => verifyAdMobSignature(
      "ad_network=123&signature=YWJjZGVm&signature=YWJjZGVm&key_id=123",
    ),
    { code: "ADMOB_INVALID_SIGNATURE" },
  );
});

test("verifyAdMobSignature rejects duplicate key ID parameters", async () => {
  await assert.rejects(
    () => verifyAdMobSignature(
      "ad_network=123&signature=YWJjZGVm&key_id=123&key_id=456",
    ),
    { code: "ADMOB_INVALID_SIGNATURE" },
  );
});

test("verifyAdMobSignature rejects an excessively long query", async () => {
  await assert.rejects(
    () => verifyAdMobSignature(
      `data=${"a".repeat(17000)}`,
    ),
    { code: "ADMOB_QUERY_STRING_TOO_LARGE" },
  );
});

// ============================================================
// 🐱 END OF TESTS
// ============================================================
