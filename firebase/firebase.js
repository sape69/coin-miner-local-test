"use strict";

const {
  initializeApp,
  getApps,
} = require("firebase-admin/app");

const {
  getFirestore,
  FieldValue,
} = require("firebase-admin/firestore");


// ============================================================
// 🐱 STELLA FIREBASE INITIALIZATION
// ============================================================

if (getApps().length === 0) {
  initializeApp();
}


// ============================================================
// FIRESTORE
// ============================================================

const db =
  getFirestore();


// ============================================================
// EXPORTS
// ============================================================

module.exports = {
  db,
  FieldValue,
};