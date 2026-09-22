"use strict";

// ============================================================
// 🐱 STELLURIINI - USER UTILITIES
// ============================================================
//
// Keskitetyt käyttäjä- ja Firestore-apufunktiot.
//
// Vastuu:
//
// 👤 Käyttäjän Firestore-referenssistä
// 📜 Käyttäjän tapahtumahistoriasta
// 🎁 AdMob Reward -referenssistä
// 🔐 Firestore Document ID -validoinnista
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
// ❌ muuta Daily Streakia
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
// Tämä on tärkeää Unicode-merkkien kanssa, koska yksi
// merkki voi käyttää useamman tavun.
//
// ============================================================

const MAX_DOCUMENT_ID_BYTES = 1500;


// ============================================================
// 🔐 VALIDATE FIRESTORE DOCUMENT ID
// ============================================================
//
// Validointi tehdään ennen Firestore-referenssin luomista.
//
// Sallittu:
//
// ✅ merkkijono
// ✅ vähintään yksi merkki
// ✅ Unicode-merkit
// ✅ välilyönnit osana ID:tä
//
// Hylätään:
//
// ❌ undefined
// ❌ null
// ❌ muu kuin string
// ❌ tyhjä string
// ❌ pelkkää whitespacea sisältävä string
// ❌ "/" sisältävä ID
// ❌ "."
// ❌ ".."
// ❌ Firestoren reserved "__.*__" -muoto
// ❌ yli 1 500 tavun ID
//
// ID:tä EI trimmailla automaattisesti.
//
// Tämä on tärkeää, koska UID:tä tai transaction ID:tä
// ei saa muuttaa hiljaisesti toiseksi arvoksi.
//
// ============================================================

function validateDocumentId(
  value,
  name,
) {
  const parameterName =
    typeof name === "string" &&
    name.length > 0
      ? name
      : "documentId";


  // ==========================================================
  // TYPE
  // ==========================================================

  if (
    typeof value !== "string"
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


  // ==========================================================
  // EMPTY ID
  // ==========================================================

  if (
    value.length === 0
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


  // ==========================================================
  // WHITESPACE-ONLY ID
  // ==========================================================
  //
  // ID:tä ei trimmailla.
  //
  // Pelkästään whitespacea sisältävä ID kuitenkin
  // hylätään, koska se on käytännössä aina virheellinen
  // ohjelmointitilanne.
  //
  // ==========================================================

  if (
    value.trim().length === 0
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


  // ==========================================================
  // INVALID FIRESTORE PATH CHARACTER
  // ==========================================================
  //
  // "/" erottaa Firestoressa collection- ja document-polut.
  //
  // Siksi sitä ei saa esiintyä yhden document ID:n sisällä.
  //
  // ==========================================================

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


  // ==========================================================
  // RESERVED DOT IDS
  // ==========================================================
  //
  // "." ja ".." eivät ole sallittuja document ID -arvoja.
  //
  // ==========================================================

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


  // ==========================================================
  // FIRESTORE RESERVED ID PATTERN
  // ==========================================================
  //
  // Firestore varaa ID:t, jotka vastaavat muotoa:
  //
  // __.*__
  //
  // Esimerkiksi:
  //
  // __name__
  // __example__
  //
  // ==========================================================

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


  // ==========================================================
  // FIRESTORE DOCUMENT ID SIZE
  // ==========================================================
  //
  // Firestore käyttää tavukokoa.
  //
  // Buffer.byteLength(..., "utf8") huomioi tämän oikein
  // myös Unicode-merkkien kanssa.
  //
  // ==========================================================

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

    error.byteLength =
      byteLength;

    error.maxBytes =
      MAX_DOCUMENT_ID_BYTES;

    throw error;
  }


  return value;
}


// ============================================================
// 👤 GET USER REFERENCE
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
// 📜 GET HISTORY COLLECTION
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
// 🎁 GET ADMOB REWARD REFERENCE
// ============================================================
//
// Firestore:
//
// admobRewards/{transactionId}
//
// AdMob transaction_id toimii dokumentin ID:nä.
//
// Tämä mahdollistaa duplicate-tarkistuksen:
//
// transactionId
//      ↓
// admobRewards/{transactionId}
//
// Sama transaction_id voidaan tunnistaa jo käsitellyksi
// ilman, että transaction ID:n sisältöä tarvitsee muuttaa.
//
// Varsinainen atominen käsittely kuuluu kuitenkin
// AdMob/SSV business- tai service-kerrokseen.
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