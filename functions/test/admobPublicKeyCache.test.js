
"use strict";

// ============================================================
// 🐱 STELLURIINI - ADMOB PUBLIC KEY CACHE TESTS
// ============================================================
//
// Tests:
// 1. Public keys are cached after the first successful fetch.
// 2. forceRefresh fetches fresh keys.
// 3. Concurrent requests share one fetch operation.
// 4. Expired cache entries are refreshed.
//
// No Google production keys or live requests are used.
//
// ============================================================

const test = require("node:test");
const assert = require("node:assert/strict");

const crypto = require("node:crypto");
const https = require("node:https");
const EventEmitter = require("node:events");

// ============================================================
// 🔐 TEST KEY
// ============================================================

const { publicKey } =
  crypto.generateKeyPairSync("ec", {
    namedCurve: "prime256v1",
  });

const publicKeyPem = publicKey.export({
  type: "spki",
  format: "pem",
});

const TEST_KEY_ID = "987654321";

const CACHE_DURATION_MS =
  23 * 60 * 60 * 1000;

// ============================================================
// 🧪 TEST HARNESS
// ============================================================

function createHarness() {
  const originalHttpsGet = https.get;
  const originalDateNow = Date.now;

  const modulePath =
    require.resolve("../src/services/admobService");

  delete require.cache[modulePath];

  let requestCount = 0;

  https.get = (_url, _options, callback) => {
    requestCount += 1;

    const request = new EventEmitter();

    request.destroy = () => {};

    const response = new EventEmitter();

    response.statusCode = 200;

    response.setEncoding = () => {};

    process.nextTick(() => {
      callback(response);

      response.emit(
        "data",
        JSON.stringify({
          keys: [
            {
              keyId: Number(TEST_KEY_ID),
              pem: publicKeyPem,
            },
          ],
        }),
      );

      response.emit("end");
    });

    return request;
  };

  const service =
    require("../src/services/admobService");

  function restore() {
    https.get = originalHttpsGet;
    Date.now = originalDateNow;

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
// 🔐 TEST 1: CACHE REUSE
// ============================================================

test(
  "getAdMobPublicKeys reuses cached keys",
  async () => {
    const harness = createHarness();

    try {
      const first =
        await harness.service.getAdMobPublicKeys();

      const second =
        await harness.service.getAdMobPublicKeys();

      assert.equal(
        harness.requestCount,
        1,
        "Only one HTTP request should be made",
      );

      assert.equal(
        first,
        second,
        "Cached Map should be reused",
      );

      assert.equal(
        first.get(TEST_KEY_ID).pem,
        publicKeyPem,
      );
    } finally {
      harness.restore();
    }
  },
);

// ============================================================
// 🔄 TEST 2: FORCE REFRESH
// ============================================================

test(
  "getAdMobPublicKeys forceRefresh fetches fresh keys",
  async () => {
    const harness = createHarness();

    try {
      await harness.service.getAdMobPublicKeys();

      await harness.service.getAdMobPublicKeys(true);

      assert.equal(
        harness.requestCount,
        2,
        "Force refresh should make a second HTTP request",
      );
    } finally {
      harness.restore();
    }
  },
);

// ============================================================
// ⚡ TEST 3: CONCURRENT REQUESTS
// ============================================================

test(
  "getAdMobPublicKeys shares one fetch between concurrent requests",
  async () => {
    const harness = createHarness();

    try {
      const firstPromise =
        harness.service.getAdMobPublicKeys();

      const secondPromise =
        harness.service.getAdMobPublicKeys();

      const thirdPromise =
        harness.service.getAdMobPublicKeys();

      assert.equal(
        harness.requestCount,
        1,
        "Concurrent requests should start only one HTTP request",
      );

      const [
        first,
        second,
        third,
      ] = await Promise.all([
        firstPromise,
        secondPromise,
        thirdPromise,
      ]);

      assert.equal(first, second);
      assert.equal(second, third);

      assert.equal(
        first.get(TEST_KEY_ID).pem,
        publicKeyPem,
      );
    } finally {
      harness.restore();
    }
  },
);

// ============================================================
// ⏰ TEST 4: CACHE EXPIRATION
// ============================================================

test(
  "getAdMobPublicKeys refreshes expired cache",
  async () => {
    const harness = createHarness();

    try {
      let fakeNow = 1_800_000_000_000;

      Date.now = () => fakeNow;

      await harness.service.getAdMobPublicKeys();

      assert.equal(
        harness.requestCount,
        1,
      );

      // Move time beyond the 23-hour cache duration.
      fakeNow += CACHE_DURATION_MS + 1;

      await harness.service.getAdMobPublicKeys();

      assert.equal(
        harness.requestCount,
        2,
        "Expired cache should trigger a new HTTP request",
      );
    } finally {
      harness.restore();
    }
  },
);
