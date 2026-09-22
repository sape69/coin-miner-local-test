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
// ❌ ei saa sisältää "/"
// ❌ ei saa olla "." tai ".."
// ❌ ei saa alkaa kahdella alaviivalla "__"
// ❌ ei saa ylittää 1 500 tavun rajaa
//
// ID:tä EI muuteta automaattisesti trimmaamalla.
//
// Tämä on tärkeää, koska UID:tä tai transaction ID:tä
// ei pidä muuttaa hiljaisesti toiseksi tunnisteeksi.
//
// UID:t ja transactionId:t validoidaan lisäksi niiden
// omissa business/service-kerroksissa.
//
// Tämä funktio estää yleiset ohjelmointivirheet,
// kuten:
//
// undefined
// null
// ""
// "   "
// "abc/def"
// "."
// ".."
// "__example__"
// liian pitkä document ID
//
// ============================================================

function validateDocumentId(
  value,
  name,
) {
  const parameterName =
    typeof name ===
    "string" &&
    name.length > 0
      ? name
      : "documentId";


  // ----------------------------------------------------------
  // TYPE
  // ----------------------------------------------------------

  if (
    typeof value !==
    "string"
  ) {
    const error =
      new Error(
        `${parameterName} must be a string.`,
      );

    error.code =
      "FIRESTORE_INVALID_DOCUMENT_ID";

    error.parameter =
      parameterName;

    throw error;
  }


  // ----------------------------------------------------------
  // EMPTY ID
  // ----------------------------------------------------------

  if (
    value.length ===
    0
  ) {
    const error =
      new Error(
        `${parameterName} cannot be empty.`,
      );

    error.code =
      "FIRESTORE_INVALID_DOCUMENT_ID";

    error.parameter =
      parameterName;

    throw error;
  }


  // ----------------------------------------------------------
  // WHITESPACE-ONLY ID
  // ----------------------------------------------------------
  //
  // ID:tä ei trimmailla, koska tunnistetta ei pidä
  // muuttaa hiljaisesti.
  //
  // Sen sijaan pelkästään whitespacea sisältävä ID
  // hylätään.
  //
  // ----------------------------------------------------------

  if (
    value.trim().length ===
    0
  ) {
    const error =
      new Error(
        `${parameterName} cannot contain only whitespace.`,
      );

    error.code =
      "FIRESTORE_INVALID_DOCUMENT_ID";

    error.parameter =
      parameterName;

    throw error;
  }


  // ----------------------------------------------------------
  // INVALID FIRESTORE PATH CHARACTER
  // ----------------------------------------------------------
  //
  // "/" erottaa Firestoressa collection- ja document-polkuja.
  //
  // Siksi sitä ei saa esiintyä yhden document ID:n sisällä.
  //
  // ----------------------------------------------------------

  if (
    value.includes("/")
  ) {
    const error =
      new Error(
        `${parameterName} cannot contain "/".`,
      );

    error.code =
      "FIRESTORE_INVALID_DOCUMENT_ID";

    error.parameter =
      parameterName;

    throw error;
  }


  // ----------------------------------------------------------
  // RESERVED DOT DOCUMENT IDS
  // ----------------------------------------------------------
  //
  // Firestore ei salli dokumentin ID:ksi pelkkää:
  //
  // "."
  // ".."
  //
  // ----------------------------------------------------------

  if (
    value === "." ||
    value === ".."
  ) {
    const error =
      new Error(
        `${parameterName} cannot be "." or "..".`,
      );

    error.code =
      "FIRESTORE_INVALID_DOCUMENT_ID";

    error.parameter =
      parameterName;

    throw error;
  }


  // ----------------------------------------------------------
  // RESERVED DOUBLE-UNDERSCORE IDS
  // ----------------------------------------------------------
  //
  // Firestore ei salli dokumentin ID:tä, joka vastaa
  // regular expressionia:
  //
  // __.*
  //
  // ----------------------------------------------------------

  if (
    /^__.*__$/.test(
      value,
    )
  ) {
    const error =
      new Error(
        `${parameterName} cannot match the Firestore reserved "__.*__" pattern.`,
      );

    error.code =
      "FIRESTORE_INVALID_DOCUMENT_ID";

    error.parameter =
      parameterName;

    throw error;
  }


  // ----------------------------------------------------------
  // FIRESTORE SIZE LIMIT
  // ----------------------------------------------------------

  const byteLength =
    Buffer.byteLength(
      value,
      "utf8",
    );


  if (
    byteLength >
    MAX_DOCUMENT_ID_BYTES
  ) {
    const error =
      new Error(
        `${parameterName} exceeds the Firestore document ID size limit.`,
      );

    error.code =
      "FIRESTORE_DOCUMENT_ID_TOO_LONG";

    error.parameter =
      parameterName;

    throw error;
  }


  return value;
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