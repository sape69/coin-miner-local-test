"use strict";

// ============================================================
// 🐱 STELLURIINI - USER UTILITIES
// ============================================================
//
// Keskitetyt käyttäjä- ja Firestore-apufunktiot.
//
// Vastaa:
//
// 👤 Käyttäjän Firestore-referenssistä
// 📜 Käyttäjän tapahtumahistoriasta
// 🎁 AdMob Reward -referenssistä
//
// Firestore-polut pidetään tässä tiedostossa keskitetysti,
// jotta kaikki backend-palvelut käyttävät samoja polkuja.
//
// TÄMÄ TIEDOSTO EI:
//
// ❌ muuta käyttäjän saldoa
// ❌ aktivoi Power Boostia
// ❌ käynnistä Mining Startia
// ❌ käsittele AdMob SSV:tä
// ❌ muuta mining-tilaa
//
// ============================================================


// ============================================================
// 🔥 FIREBASE
// ============================================================

const {
  db,
} = require(
  "../firebase/firebase"
);


// ============================================================
// 🔐 VALIDATE FIRESTORE DOCUMENT ID
// ============================================================
//
// Firestore-dokumentin ID ei saa olla tyhjä.
//
// UID:t ja transactionId:t validoidaan varsinaisessa
// business/service-kerroksessa.
//
// Tämä tarkistus estää kuitenkin yleiset ohjelmointivirheet,
// kuten undefined/null/tyhjä ID.
//
// ============================================================

function validateDocumentId(
  value,
  name
) {
  if (
    typeof value !== "string"
  ) {
    throw new Error(
      `${name} must be a string.`
    );
  }

  const id =
    value.trim();

  if (
    id.length === 0
  ) {
    throw new Error(
      `${name} cannot be empty.`
    );
  }

  return id;
}


// ============================================================
// 👤 USER DOCUMENT
// ============================================================
//
// Firestore:
//
// users/{uid}
//
// ============================================================

function getUserRef(
  uid
) {
  const validUid =
    validateDocumentId(
      uid,
      "uid"
    );

  return db
    .collection("users")
    .doc(validUid);
}


// ============================================================
// 📜 TRANSACTION HISTORY COLLECTION
// ============================================================
//
// Firestore:
//
// users/{uid}/transactions
//
// Käytetään käyttäjän reward-, mining- ja muiden
// tapahtumien historian tallentamiseen.
//
// ============================================================

function getHistoryCollection(
  uid
) {
  return getUserRef(uid)
    .collection("transactions");
}


// ============================================================
// 🎁 ADMOB REWARD DOCUMENT
// ============================================================
//
// Firestore:
//
// admobRewards/{transactionId}
//
// AdMob transaction_id toimii dokumentin ID:nä.
//
// Tämä mahdollistaa atomisen duplicate-tarkistuksen:
//
//   transactionId
//        ↓
// admobRewards/{transactionId}
//
// Jos sama transaction_id vastaanotetaan uudelleen,
// backend voi tunnistaa sen jo käsitellyksi.
//
// ============================================================

function getAdMobRewardRef(
  transactionId
) {
  const validTransactionId =
    validateDocumentId(
      transactionId,
      "transactionId"
    );

  return db
    .collection("admobRewards")
    .doc(validTransactionId);
}


// ============================================================
// 📦 EXPORTS
// ============================================================

module.exports = {
  getUserRef,
  getHistoryCollection,
  getAdMobRewardRef,
};