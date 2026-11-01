
"use strict";

// ============================================================
// 🐱 STELLURIINI - ADMOB PUBLIC KEY ERROR TESTS
// ============================================================
//
// Tests:
// 1. Network failure while fetching public keys.
// 2. Invalid JSON response.
// 3. Empty public key list.
// 4. Invalid response structure.
//
// No Google production keys or live requests are used.
//
// ============================================================

const test = require("node:test");
const assert = require("node:assert/strict");

const https = require("node:https");
const EventEmitter = require("node:events");

// ============================================================
// 🧪 TEST HARNESS
// ============================================================

function createHarness(mode) {
  const originalHttpsGet = https.get;

  const modulePath =
    require.resolve("../src/services/admobService");

  delete require.cache[modulePath];

  let requestCount = 0;

  https.get = (_url, _options, callback) => {
    requestCount += 1;

    const request = new EventEmitter();

    request.destroy = () => {};

    if (mode === "network_error") {
      process.nextTick(() => {
        request.emit(
          "error",
          new Error("Simulated network failure"),
        );
      });

      return request;
    }

    const response = new EventEmitter();

    response.statusCode = 200;
    response.setEncoding = () => {};

    response.resume = () => {};

    process.nextTick(() => {
      callback(response);

      if (mode === "invalid_json") {
        response.emit(
          "data",
          "{ invalid json response",
        );
      }

      if (mode === "empty_keys") {
        response.emit(
          "data",
          JSON.stringify({
            keys: [],
          }),
        );
      }

      if (mode === "invalid_structure") {
        response.emit(
          "data",
          JSON.stringify({
            unexpected: true,
          }),
        );
      }

      response.emit("end");
    });

    return request;
  };

  const service =
    require("../src/services/admobService");

  function restore() {
    https.get = originalHttpsGet;

    delete require.cache[modulePath];
  }

  return {
    service,

    get requestCount() {
      return requestCount;
    },

    restore,
  };
}

// ============================================================
// 🌐 TEST 1: NETWORK FAILURE
// ============================================================

test(
  "getAdMobPublicKeys handles network failure",
  async () => {
    const harness =
      createHarness("network_error");

    try {
      await assert.rejects(
        () => harness.service.getAdMobPublicKeys(),
        {
          code: "ADMOB_PUBLIC_KEY_FETCH_ERROR",
        },
      );

      assert.equal(
        harness.requestCount,
        1,
        "One network request should be attempted",
      );
    } finally {
      harness.restore();
    }
  },
);

// ============================================================
// 📄 TEST 2: INVALID JSON
// ============================================================

test(
  "getAdMobPublicKeys rejects invalid JSON",
  async () => {
    const harness =
      createHarness("invalid_json");

    try {
      await assert.rejects(
        () => harness.service.getAdMobPublicKeys(),
        {
          code: "ADMOB_PUBLIC_KEY_JSON_ERROR",
        },
      );

      assert.equal(
        harness.requestCount,
        1,
      );
    } finally {
      harness.restore();
    }
  },
);

// ============================================================
// 🔑 TEST 3: EMPTY KEY LIST
// ============================================================

test(
  "getAdMobPublicKeys rejects an empty key list",
  async () => {
    const harness =
      createHarness("empty_keys");

    try {
      await assert.rejects(
        () => harness.service.getAdMobPublicKeys(),
        {
          code: "ADMOB_PUBLIC_KEYS_EMPTY",
        },
      );

      assert.equal(
        harness.requestCount,
        1,
      );
    } finally {
      harness.restore();
    }
  },
);

// ============================================================
// 🧱 TEST 4: INVALID RESPONSE STRUCTURE
// ============================================================

test(
  "getAdMobPublicKeys rejects an invalid response structure",
  async () => {
    const harness =
      createHarness("invalid_structure");

    try {
      await assert.rejects(
        () => harness.service.getAdMobPublicKeys(),
        {
          code: "ADMOB_PUBLIC_KEY_RESPONSE_INVALID",
        },
      );

      assert.equal(
        harness.requestCount,
        1,
      );
    } finally {
      harness.restore();
    }
  },
);
