
"use strict";

// ============================================================
// 🐱 STELLURIINI - ADMOB SSV CRYPTOGRAPHIC TESTS
// ============================================================
//
// Tests ECDSA/SHA-256 signature verification using a generated
// test key pair. No Google production keys or live requests.
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
const UNKNOWN_KEY_ID = "987654322";

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
// ✍️ CREATE SIGNED QUERY
// ============================================================

function createSignedQuery(
  rawSignedQueryString,
  keyId = TEST_KEY_ID,
) {
  const signedContent =
    decodeURIComponent(rawSignedQueryString);

  const signature = crypto.sign(
    "sha256",
    Buffer.from(signedContent, "utf8"),
    {
      key: privateKey,
      dsaEncoding: "der",
    },
  );

  const signatureBase64Url =
    signature.toString("base64url");

  return (
    `${rawSignedQueryString}` +
    `&signature=${signatureBase64Url}` +
    `&key_id=${keyId}`
  );
}

// ============================================================
// 🔧 TAMPER SIGNATURE
// ============================================================

function tamperSignature(rawQueryString) {
  const marker = "&signature=";
  const signatureIndex =
    rawQueryString.indexOf(marker);

  assert.notEqual(
    signatureIndex,
    -1,
    "Signature parameter must exist",
  );

  const signedContent =
    rawQueryString.substring(
      0,
      signatureIndex,
    );

  const parameters =
    rawQueryString.substring(
      signatureIndex + 1,
    ).split("&");

  const signatureParameter =
    parameters[0];

  const keyIdParameter =
    parameters[1];

  const signatureValue =
    signatureParameter.substring(
      "signature=".length,
    );

  const signatureBuffer =
    Buffer.from(
      signatureValue,
      "base64url",
    );

  assert.ok(
    signatureBuffer.length > 0,
    "Signature must decode to bytes",
  );

  // Change one byte while keeping a valid Base64URL value.
  signatureBuffer[0] ^= 0x01;

  const tamperedSignature =
    signatureBuffer.toString("base64url");

  return (
    `${signedContent}` +
    `&signature=${tamperedSignature}` +
    `&${keyIdParameter}`
  );
}

// ============================================================
// 🧪 TEST DATA
// ============================================================

function createTestSignedQuery() {
  return createSignedQuery(
    "ad_network=123456&custom_data=test-user%3Apower_boost",
  );
}

// ============================================================
// 🔐 TEST 1: VALID SIGNATURE
// ============================================================

test(
  "verifyAdMobSignature accepts a valid ECDSA signature",
  async () => {
    const restoreHttps =
      mockAdMobPublicKeyServer();

    try {
      const rawQueryString =
        createTestSignedQuery();

      const result =
        await verifyAdMobSignature(rawQueryString);

      assert.equal(result.verified, true);
      assert.equal(result.keyId, TEST_KEY_ID);

      assert.equal(
        result.signedQueryString,
        "ad_network=123456&custom_data=test-user%3Apower_boost",
      );

      assert.ok(
        result.signature,
        "Verified result must contain signature",
      );
    } finally {
      restoreHttps();
    }
  },
);

// ============================================================
// 🔐 TEST 2: TAMPERED QUERY
// ============================================================

test(
  "verifyAdMobSignature rejects a tampered signed query",
  async () => {
    const restoreHttps =
      mockAdMobPublicKeyServer();

    try {
      const rawQueryString =
        createTestSignedQuery();

      const tamperedQuery =
        rawQueryString.replace(
          "ad_network=123456",
          "ad_network=999999",
        );

      assert.notEqual(
        tamperedQuery,
        rawQueryString,
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

// ============================================================
// 🔐 TEST 3: INVALID CRYPTOGRAPHIC SIGNATURE
// ============================================================

test(
  "verifyAdMobSignature rejects an invalid ECDSA signature",
  async () => {
    const restoreHttps =
      mockAdMobPublicKeyServer();

    try {
      const rawQueryString =
        createTestSignedQuery();

      const tamperedSignatureQuery =
        tamperSignature(rawQueryString);

      await assert.rejects(
        () => verifyAdMobSignature(
          tamperedSignatureQuery,
        ),
        {
          code: "ADMOB_INVALID_SIGNATURE",
        },
      );
    } finally {
      restoreHttps();
    }
  },
);

// ============================================================
// 🔐 TEST 4: UNKNOWN KEY ID
// ============================================================

test(
  "verifyAdMobSignature rejects an unknown key ID",
  async () => {
    const restoreHttps =
      mockAdMobPublicKeyServer();

    try {
      const rawSignedQueryString =
        "ad_network=123456&custom_data=test-user%3Apower_boost";

      const rawQueryString =
        createSignedQuery(
          rawSignedQueryString,
          UNKNOWN_KEY_ID,
        );

      await assert.rejects(
        () => verifyAdMobSignature(rawQueryString),
        {
          code: "ADMOB_PUBLIC_KEY_NOT_FOUND",
        },
      );
    } finally {
      restoreHttps();
    }
  },
);

// ============================================================
// 🔐 TEST 5: MISSING SIGNATURE
// ============================================================

test(
  "verifyAdMobSignature rejects a missing signature",
  async () => {
    const rawQueryString =
      "ad_network=123456&custom_data=test-user%3Apower_boost";

    await assert.rejects(
      () => verifyAdMobSignature(rawQueryString),
      {
        code: "ADMOB_INVALID_SIGNATURE",
      },
    );
  },
);

// ============================================================
// 🔐 TEST 6: MISSING QUERY
// ============================================================

test(
  "verifyAdMobSignature rejects a missing query string",
  async () => {
    await assert.rejects(
      () => verifyAdMobSignature(""),
      {
        code: "ADMOB_QUERY_STRING_MISSING",
      },
    );
  },
);
