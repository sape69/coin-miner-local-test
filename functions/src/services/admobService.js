"use strict";

const crypto = require("crypto");

// ============================================================
// 🐱 STELLA ADMOB SERVER-SIDE VERIFICATION SERVICE
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
// Välimuisti on 1 tunti.
// Google suosittelee, ettei avaimia välimuistita
// yli 24 tunnin ajan.
// ============================================================

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
  // PROTECT AGAINST EMPTY KEY SET
  // ==========================================================

  if (
    keys.size === 0
  ) {

    throw new Error(
      "No AdMob public keys are available."
    );
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
//
// AdMob käyttää base64url-muotoista allekirjoitusta.
//
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
//
// Google AdMob SSV:
//
// 1. Allekirjoitettava sisältö alkaa ?-merkin jälkeen.
// 2. Parametrien järjestystä EI saa muuttaa.
// 3. signature on toiseksi viimeinen parametri.
// 4. key_id on viimeinen parametri.
//
// Otetaan siis allekirjoitettava sisältö täsmälleen
// ennen "&signature="-osuutta.
//
// ============================================================

function buildSignedQueryString(
  originalUrl
) {

  if (
    typeof originalUrl !== "string"
  ) {

    throw new Error(
      "Invalid AdMob callback URL."
    );
  }


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


  // ==========================================================
  // FIND SIGNATURE
  // ==========================================================

  const signatureMarker =
    "&signature=";


  const signatureIndex =
    queryString.indexOf(
      signatureMarker
    );


  if (
    signatureIndex === -1
  ) {

    throw new Error(
      "Missing AdMob signature parameter."
    );
  }


  // ==========================================================
  // SIGNED CONTENT
  // ==========================================================
  //
  // Otetaan kaikki ennen signature-parametria.
  //
  // Parametrien alkuperäinen järjestys säilyy.
  //
  // ==========================================================

  const signedQuery =
    queryString.substring(
      0,
      signatureIndex
    );


  if (
    signedQuery.length === 0
  ) {

    throw new Error(
      "Missing AdMob signed query content."
    );
  }


  return Buffer.from(
    signedQuery,
    "utf8"
  );
}


// ============================================================
// 🔐 VERIFY ADMOB CALLBACK
// ============================================================

async function verifyAdMobCallback(req) {

  if (
    !req ||
    typeof req.originalUrl !== "string"
  ) {

    throw new Error(
      "Invalid AdMob callback request."
    );
  }


  const signature =
    req.query?.signature;

  const keyId =
    req.query?.key_id;


  // ==========================================================
  // VALIDATE PARAMETERS
  // ==========================================================

  if (
    typeof signature !== "string" ||
    typeof keyId !== "string" ||
    signature.length === 0 ||
    keyId.length === 0
  ) {

    throw new Error(
      "Missing AdMob signature or key ID."
    );
  }


  // ==========================================================
  // GET PUBLIC KEYS
  // ==========================================================

  const publicKeys =
    await getAdMobPublicKeys();


  // ==========================================================
  // FIND KEY
  // ==========================================================

  const pem =
    publicKeys.get(
      String(keyId)
    );


  if (!pem) {

    throw new Error(
      "Unknown AdMob key ID."
    );
  }


  // ==========================================================
  // GET SIGNED DATA
  // ==========================================================

  const signedData =
    buildSignedQueryString(
      req.originalUrl
    );


  // ==========================================================
  // DECODE SIGNATURE
  // ==========================================================

  const signatureBuffer =
    base64UrlDecode(
      signature
    );


  if (
    signatureBuffer.length === 0
  ) {

    throw new Error(
      "Invalid AdMob signature encoding."
    );
  }


  // ==========================================================
  // VERIFY ECDSA SHA-256
  // ==========================================================

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


  // ==========================================================
  // RESULT
  // ==========================================================

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