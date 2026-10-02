"use strict";

// ============================================================
// 🐱 STELLURIINI - ACCOUNT DELETION REQUEST FUNCTIONS
// ============================================================
//
// External account deletion request.
//
// This function does NOT immediately delete an account.
//
// It creates a deletion request in Firestore so that the
// request can be reviewed and processed safely.
//
// Google Play requires an external web resource where users
// can request account deletion.
//
// ============================================================

const { onRequest } = require("firebase-functions/v2/https");
const { db, FieldValue } = require("../firebase/firebase");

// ============================================================
// CONFIG
// ============================================================

const REGION = "us-central1";

const REQUEST_COLLECTION = "accountDeletionRequests";

// Only the Stelluriini Firebase Hosting site is allowed
// to call this endpoint from browser JavaScript.
const ALLOWED_ORIGIN = "https://stelluriini.web.app";

// ============================================================
// EMAIL VALIDATION
// ============================================================

function isValidEmail(email) {
  if (typeof email !== "string") {
    return false;
  }

  const normalizedEmail = email.trim().toLowerCase();

  if (normalizedEmail.length === 0) {
    return false;
  }

  if (normalizedEmail.length > 254) {
    return false;
  }

  const emailPattern =
      /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

  return emailPattern.test(normalizedEmail);
}

// ============================================================
// NORMALIZE EMAIL
// ============================================================

function normalizeEmail(email) {
  return email.trim().toLowerCase();
}

// ============================================================
// HTTP FUNCTION
// ============================================================

const requestAccountDeletion = onRequest(
  {
    region: REGION,
    cors: [ALLOWED_ORIGIN],
    timeoutSeconds: 60,
  },
  async (req, res) => {
    // ----------------------------------------------------------
    // OPTIONS / CORS PREFLIGHT
    // ----------------------------------------------------------

    if (req.method === "OPTIONS") {
      res.status(204).send("");

      return;
    }

    // ----------------------------------------------------------
    // ONLY POST IS ALLOWED
    // ----------------------------------------------------------

    if (req.method !== "POST") {
      res.status(405).json({
        success: false,
        message: "Only POST requests are allowed.",
      });

      return;
    }

    // ----------------------------------------------------------
    // READ REQUEST BODY
    // ----------------------------------------------------------

    const body = req.body || {};

    const email =
        typeof body.email === "string"
          ? body.email
          : "";

    // ----------------------------------------------------------
    // VALIDATE EMAIL
    // ----------------------------------------------------------

    if (!isValidEmail(email)) {
      res.status(400).json({
        success: false,
        message: "Please provide a valid email address.",
      });

      return;
    }

    const normalizedEmail =
        normalizeEmail(email);

    // ----------------------------------------------------------
    // CREATE REQUEST
    // ----------------------------------------------------------

    try {
      const requestRef =
          db.collection(REQUEST_COLLECTION).doc();

      await requestRef.set({
        email: normalizedEmail,

        status: "pending",

        source: "external_web",

        createdAt: FieldValue.serverTimestamp(),

        updatedAt: FieldValue.serverTimestamp(),
      });

      console.log(
        "Account deletion request created:",
        requestRef.id,
      );

      // --------------------------------------------------------
      // RESPONSE
      // --------------------------------------------------------

      res.status(200).json({
        success: true,
        message:
          "Your account deletion request has been received.",
      });
    } catch (error) {
      console.error(
        "requestAccountDeletion failed:",
        error,
      );

      res.status(500).json({
        success: false,
        message:
          "Unable to submit the deletion request. Please try again later.",
      });
    }
  },
);

// ============================================================
// EXPORTS
// ============================================================

module.exports = {
  requestAccountDeletion,
};