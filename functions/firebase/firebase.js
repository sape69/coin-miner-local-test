"use strict";


// ============================================================
// 🔥 STELLURIINI FIREBASE
// ============================================================
//
// Tämä tiedosto alustaa Firebase Admin SDK:n.
//
// Kaikki Cloud Functions -tiedostot käyttävät
// samaa Firestore-yhteyttä tämän tiedoston kautta.
//
// ============================================================


const {
  initializeApp,
  getApps,
} = require("firebase-admin/app");

const {
  getFirestore,
  FieldValue,
} = require("firebase-admin/firestore");


// ============================================================
// 🔥 INITIALIZE FIREBASE
// ============================================================
//
// getApps() estää Firebasea alustumasta useita kertoja.
//

if (getApps().length === 0) {

  initializeApp();

}


// ============================================================
// 🗄️ FIRESTORE
// ============================================================

const db =
  getFirestore();


// ============================================================
// 📤 EXPORTS
// ============================================================

module.exports = {

  db,

  FieldValue,

};