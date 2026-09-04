"use strict";

const crypto = require("crypto");


// ============================================================
// 🔐 ADMOB SERVER-SIDE VERIFICATION SERVICE
// ============================================================
//
// Tämä palvelu tarkistaa Google AdMob SSV callbackin.
//
// Google lähettää palkinnon palvelimelle,
// ja allekirjoitus varmistetaan Googlen julkisilla avaimilla.
//
// ============================================================


// ============================================================
// 🌐 ADMOB PUBLIC KEYS
// ============================================================

const ADMOB_KEY_URL =
  "https://www.gstatic.com/admob/reward/verifier-keys.json";


// ============================================================
// ⏱️ KEY CACHE
// ============================================================
//
// Avaimia ei tarvitse hakea jokaisella callbackilla.
//

const ADMOB_KEY_CACHE_MS =
  60 * 60 * 1000;


// ============================================================
// 🔐 MEMORY CACHE
// ============================================================

let cachedAdMobKeys = null;

let adMobKeysCachedAt = 0;


// ============================================================
// 🔑 GET ADMOB PUBLIC KEYS
// ============================================================

async function getAdMobPublicKeys() {

  const now =
    Date.now();


  // ==========================================================
  // CACHE
  // ==========================================================

  if (
    cachedAdMobKeys &&
    now - adMobKeysCachedAt <
      ADMOB_KEY_CACHE_MS
  ) {

    return cachedAdMobKeys;
  }


  // ==========================================================
  // DOWNLOAD KEYS
  // ==========================================================

  const response =
    await fetch(
      ADMOB_KEY_URL
    );


  if (!response.ok) {

    throw new Error(
      "AdMob public keys could not be loaded."
    );
  }


  const data =
    await response.json();


  // ==========================================================
  // VALIDATE RESPONSE
  // ==========================================================

  if (
    !data ||
    !Array.isArray(data.keys)
  ) {

    throw new Error(
      "Invalid AdMob public key response."
    );
  }


  // ==========================================================
  // CREATE KEY MAP
  // ==========================================================

  const keys =
    new Map();


  for (
    const key of data.keys
  ) {

    if (
      key &&
      key.keyId !== undefined &&
      key.pem
    ) {

      keys.set(
        String(key.keyId),
        key.pem
      );
    }
  }


  // ==========================================================
  // SAVE CACHE
  // ==========================================================

  cachedAdMobKeys =
    keys;

  adMobKeysCachedAt =
    now;


  return keys;
}


// ============================================================
// 🔓 BASE64 URL DECODE
// ============================================================

function base64UrlDecode(value) {

  let base64 =
    String(value)
      .replace(/-/g, "+")
      .replace(/_/g, "/");


  while (
    base64.length % 4 !== 0
  ) {

    base64 += "=";
  }


  return Buffer.from(
    base64,
    "base64"
  );
}


// ============================================================
// 🧾 BUILD SIGNED QUERY STRING
// ============================================================

function buildSignedQueryString(
  originalUrl
) {

  const questionMarkIndex =
    originalUrl.indexOf("?");


  if (
    questionMarkIndex === -1
  ) {

    throw new Error(
      "Missing AdMob query string."
    );
  }


  const queryString =
    originalUrl.substring(
      questionMarkIndex + 1
    );


  const parts =
    queryString.split("&");


  const signedParts =
    [];


  for (
    const part of parts
  ) {

    if (
      part.startsWith("signature=") ||
      part.startsWith("key_id=")
    ) {

      continue;
    }


    signedParts.push(part);
  }


  return Buffer.from(
    signedParts.join("&"),
    "utf8"
  );
}


// ============================================================
// 🔐 VERIFY ADMOB CALLBACK
// ============================================================

async function verifyAdMobCallback(req) {

  const signature =
    req.query.signature;

  const keyId =
    req.query.key_id;


  if (
    !signature ||
    !keyId
  ) {

    throw new Error(
      "Missing AdMob signature."
    );
  }


  const publicKeys =
    await getAdMobPublicKeys();


  const pem =
    publicKeys.get(
      String(keyId)
    );


  if (!pem) {

    throw new Error(
      "Unknown AdMob key ID."
    );
  }


  const signedData =
    buildSignedQueryString(
      req.originalUrl
    );


  const signatureBuffer =
    base64UrlDecode(
      signature
    );


  const verifier =
    crypto.createVerify(
      "SHA256"
    );


  verifier.update(
    signedData
  );

  verifier.end();


  const valid =
    verifier.verify(
      pem,
      signatureBuffer
    );


  if (!valid) {

    throw new Error(
      "Invalid AdMob signature."
    );
  }


  return true;
}


// ============================================================
// 📦 EXPORTS
// ============================================================

module.exports = {

  getAdMobPublicKeys,

  verifyAdMobCallback,

};