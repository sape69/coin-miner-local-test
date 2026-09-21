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
// jotta backend käyttää aina samoja polkuja.
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
  "../firebase/firebase",
);


// ============================================================
// 📏 FIRESTORE DOCUMENT ID LIMIT
// ============================================================
//
// Firestore-dokumentin ID:n enimmäiskoko:
//
// 1 500 bytes
//
// Käytetään byte-pituutta eikä JavaScript-stringin
// character length -arvoa.
//
// Tämä on tärkeää erityisesti Unicode-merkkien kanssa,
// koska yksi merkki voi käyttää useamman tavun.
//
// ============================================================

const MAX_DOCUMENT_ID_BYTES =
  1500;


// ============================================================
// 🔐 VALIDATE FIRESTORE DOCUMENT ID
// ============================================================
//
// Firestore-dokumentin ID:
//
// ✅ täytyy olla merkkijono
// ✅ ei saa olla tyhjä
// ✅ ympäröivät whitespace-merkit poistetaan
// ❌ ei saa sisältää "/"
// ❌ ei saa sisältää "\"
// ❌ ei saa ylittää Firestoren ID-kokorajaa
//
// UID:t ja transactionId:t validoidaan lisäksi
// niiden omissa business/service-kerroksissa.
//
// Tämä funktio estää yleiset ohjelmointivirheet,
// kuten:
//
// undefined
// null
// ""
// "   "
// "abc/def"
// "abc\\def"
// liian pitkä document ID
//
// ============================================================

function validateDocumentId(
  value,
  name,
) {
  if (
    typeof value !==
    "string"
  ) {
    const error =
      new Error(
        `${name} must be a string.`,
      );

    error.code =
      "FIRESTORE_INVALID_DOCUMENT_ID";

    error.parameter =
      name;

    throw error;
  }


  const id =
    value.trim();


  // ----------------------------------------------------------
  // EMPTY ID
  // ----------------------------------------------------------

  if (
    id.length ===
    0
  ) {
    const error =
      new Error(
        `${name} cannot be empty.`,
      );

    error.code =
      "FIRESTORE_INVALID_DOCUMENT_ID";

    error.parameter =
      name;

    throw error;
  }


  // ----------------------------------------------------------
  // INVALID PATH CHARACTERS
  // ----------------------------------------------------------

  if (
    id.includes("/") ||
    id.includes("\\")
  ) {
    const error =
      new Error(
        `${name} cannot contain "/" or "\\".`,
      );

    error.code =
      "FIRESTORE_INVALID_DOCUMENT_ID";

    error.parameter =
      name;

    throw error;
  }


  // ----------------------------------------------------------
  // FIRESTORE SIZE LIMIT
  // ----------------------------------------------------------

  const byteLength =
    Buffer.byteLength(
      id,
      "utf8",
    );


  if (
    byteLength >
    MAX_DOCUMENT_ID_BYTES
  ) {
    const error =
      new Error(
        `${name} exceeds the Firestore document ID size limit.`,
      );

    error.code =
      "FIRESTORE_DOCUMENT_ID_TOO_LONG";

    error.parameter =
      name;

    throw error;
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
  uid,
) {
  const validUid =
    validateDocumentId(
      uid,
      "uid",
    );


  return db
    .collection(
      "users",
    )
    .doc(
      validUid,
    );
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
  uid,
) {
  return getUserRef(
    uid,
  ).collection(
    "transactions",
  );
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
// transactionId
//      ↓
// admobRewards/{transactionId}
//
// Jos sama transaction_id vastaanotetaan uudelleen,
// backend voi tunnistaa sen jo käsitellyksi.
//
// ============================================================

function getAdMobRewardRef(
  transactionId,
) {
  const validTransactionId =
    validateDocumentId(
      transactionId,
      "transactionId",
    );


  return db
    .collection(
      "admobRewards",
    )
    .doc(
      validTransactionId,
    );
}


// ============================================================
// 📦 EXPORTS
// ============================================================

module.exports = {
  getUserRef,

  getHistoryCollection,

  getAdMobRewardRef,

  validateDocumentId,
};