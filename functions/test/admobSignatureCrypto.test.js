
"use strict";

// ============================================================
// 🐱 STELLURIINI - ADMOB SSV CRYPTOGRAPHIC TESTS
// ============================================================
//
// Tests real ECDSA/SHA-256 signature verification using a
// generated test key pair.
//
// No Google production keys or live AdMob requests are used.
//
// ============================================================

const test = require("node:test");
const assert = require("node:assert/strict");

const crypto = require("node:crypto");
const https = require("node:https");
const EventEmitter = require("node:events");

const {
  verifyAdMobSignature,
} = require("../src/services/admobService");

// ============================================================
// 🔐 TEST KEY PAIR
// ============================================================

const {
  publicKey,
  privateKey,
} = crypto.generateKeyPairSync("ec", {
  namedCurve: "prime256v1",
});

const publicKeyPem = publicKey.export({
  type: "spki",
  format: "pem",
});

const TEST_KEY_ID = "987654321";

// ============================================================
// 🌐 MOCK GOOGLE PUBLIC KEY RESPONSE
// ============================================================

function mockAdMobPublicKeyServer() {
  const originalGet = https.get;

  https.get = (_url, _options, callback) => {
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

  return () => {
    https.get = originalGet;
  };
}

// ============================================================
// ✍️ SIGN TEST QUERY
// ============================================================

function createSignedQuery(
  signedQueryString,
) {
  const signature = crypto.sign(
    "sha256",
    Buffer.from(signedQueryString, "utf8"),
    {
      key: privateKey,
      dsaEncoding: "der",
    },
  );

  const signatureBase64Url =
    signature.toString("base64url");

  return (
    `${encodeURIComponent(signedQueryString)}` +
    `&signature=${signatureBase64Url}` +
    `&key_id=${TEST_KEY_ID}`
  );
}

// ============================================================
// 🔐 CRYPTOGRAPHIC VERIFICATION
// ============================================================

test(
  "verifyAdMobSignature accepts a valid ECDSA signature and rejects a tampered query",
  async () => {
    const restoreHttps = mockAdMobPublicKeyServer();

    try {
      const signedQueryString =
        "ad_network=123456&custom_data=test-user%3Apower_boost";

      const rawQueryString =
        createSignedQuery(signedQueryString);

      // ------------------------------------------------------
      // 1. VALID SIGNATURE MUST BE ACCEPTED
      // ------------------------------------------------------

      const result =
        await verifyAdMobSignature(rawQueryString);

      assert.equal(
        result.verified,
        true,
      );

      assert.equal(
        result.keyId,
        TEST_KEY_ID,
      );

      assert.equal(
        result.signedQueryString,
        decodeURIComponent(signedQueryString),
      );

      assert.ok(
        result.signature,
        "Verified result must contain the signature",
      );

      // ------------------------------------------------------
      // 2. MODIFIED QUERY MUST BE REJECTED
      // ------------------------------------------------------

      const tamperedQuery =
        rawQueryString.replace(
          "ad_network=123456",
          "ad_network=999999",
        );

      await assert.rejects(
        () => verifyAdMobSignature(tamperedQuery),
        {
          code: "ADMOB_INVALID_SIGNATURE",
        },
      );
    } finally {
      restoreHttps();
    }
  },
);
