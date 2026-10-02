"use strict";

// ============================================================
// 🐱 STELLURIINI - ACCOUNT DELETION REQUEST
// ============================================================
//
// External Google Play account deletion request.
//
// Flow:
// 1. User enters their email on the public deletion page.
// 2. A pending deletion request is stored in Firestore.
// 3. A confirmation email is sent through Gmail SMTP.
// 4. The account is NOT deleted by this request alone.
//
// IMPORTANT:
// Email ownership verification will be added before any
// external request is allowed to delete a Firebase account.
//
// Gmail App Password is stored securely in Google Cloud
// Secret Manager and is never stored in this source file.
// ============================================================

const { onRequest } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const nodemailer = require("nodemailer");

const { db, FieldValue } = require("../firebase/firebase");

// ============================================================
// CONFIGURATION
// ============================================================

const REGION = "us-central1";

const REQUEST_COLLECTION = "accountDeletionRequests";

const ALLOWED_ORIGIN = "https://stelluriini.web.app";

const GMAIL_ADDRESS = "stelluriini.app@gmail.com";

const GMAIL_APP_PASSWORD = defineSecret(
  "STELLURIINI_GMAIL_APP_PASSWORD",
);

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

  const emailPattern = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

  return emailPattern.test(normalizedEmail);
}

// ============================================================
// EMAIL NORMALIZATION
// ============================================================

function normalizeEmail(email) {
  return email.trim().toLowerCase();
}

// ============================================================
// GMAIL TRANSPORTER
// ============================================================
//
// The App Password is read only when the function executes.
// It is never hardcoded into the source code.
//

function createTransporter() {
  return nodemailer.createTransport({
    service: "gmail",
    auth: {
      user: GMAIL_ADDRESS,
      pass: GMAIL_APP_PASSWORD.value(),
    },
  });
}

// ============================================================
// CONFIRMATION EMAIL
// ============================================================

async function sendDeletionRequestEmail(email, requestId) {
  const transporter = createTransporter();

  await transporter.sendMail({
    from: `"Stelluriini" <${GMAIL_ADDRESS}>`,
    to: email,
    subject: "Stelluriini account deletion request received",
    text: [
      "Hello,",
      "",
      "We have received your Stelluriini account deletion request.",
      "",
      "Your request has been registered and will be processed",
      "according to the Stelluriini account deletion process.",
      "",
      `Request ID: ${requestId}`,
      "",
      "IMPORTANT:",
      "Your account has NOT been deleted by this request.",
      "",
      "If you did not make this request, you can safely ignore",
      "this email.",
      "",
      "Stelluriini",
    ].join("\n"),
    html: `
      <div
        style="
          margin:0;
          padding:32px 16px;
          background:#120B24;
          font-family:Arial,Helvetica,sans-serif;
          color:#F8F4FF;
        "
      >
        <div
          style="
            max-width:600px;
            margin:0 auto;
            padding:32px;
            background:#21113B;
            border-radius:20px;
          "
        >
          <h1
            style="
              margin-top:0;
              color:#B58CFF;
            "
          >
            🐱 Stelluriini
          </h1>

          <h2
            style="
              color:#FFB7E8;
            "
          >
            Account deletion request received
          </h2>

          <p>
            We have received your Stelluriini account deletion request.
          </p>

          <p>
            Your request has been registered and will be processed
            according to the Stelluriini account deletion process.
          </p>

          <div
            style="
              margin:24px 0;
              padding:16px;
              background:#1A0E31;
              border-radius:12px;
            "
          >
            <strong style="color:#FFD166;">
              Request ID
            </strong>

            <br />

            <span>
              ${requestId}
            </span>
          </div>

          <p>
            <strong style="color:#FFD166;">
              Important:
            </strong>
            Your account has <strong>NOT</strong> been deleted by
            this request.
          </p>

          <p style="color:#BDB4D1;">
            If you did not make this request, you can safely ignore
            this email.
          </p>

          <p
            style="
              margin-top:32px;
              color:#BDB4D1;
            "
          >
            Stelluriini 🐾
          </p>
        </div>
      </div>
    `,
  });
}

// ============================================================
// HTTP FUNCTION
// ============================================================

const requestAccountDeletion = onRequest(
  {
    region: REGION,
    cors: [ALLOWED_ORIGIN],
    timeoutSeconds: 60,
    secrets: [GMAIL_APP_PASSWORD],
  },
  async (req, res) => {
    // ----------------------------------------------------------
    // CORS PREFLIGHT
    // ----------------------------------------------------------

    if (req.method === "OPTIONS") {
      res.status(204).send("");
      return;
    }

    // ----------------------------------------------------------
    // METHOD CHECK
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

    const normalizedEmail = normalizeEmail(email);

    // ----------------------------------------------------------
    // CREATE FIRESTORE REQUEST
    // ----------------------------------------------------------

    let requestId = "";

    try {
      const requestRef =
        db.collection(REQUEST_COLLECTION).doc();

      requestId = requestRef.id;

      await requestRef.set({
        email: normalizedEmail,
        status: "pending",
        source: "external_web",
        createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      });

      console.log(
        "Account deletion request created:",
        requestId,
      );
    } catch (error) {
      console.error(
        "Failed to create account deletion request:",
        error,
      );

      res.status(500).json({
        success: false,
        message:
          "Unable to submit the deletion request. Please try again later.",
      });

      return;
    }

    // ----------------------------------------------------------
    // SEND CONFIRMATION EMAIL
    // ----------------------------------------------------------

    try {
      await sendDeletionRequestEmail(
        normalizedEmail,
        requestId,
      );

      await db
        .collection(REQUEST_COLLECTION)
        .doc(requestId)
        .update({
          emailSent: true,
          emailSentAt: FieldValue.serverTimestamp(),
          updatedAt: FieldValue.serverTimestamp(),
        });

      console.log(
        "Account deletion confirmation email sent:",
        requestId,
      );

      res.status(200).json({
        success: true,
        message:
          "Your account deletion request has been received. A confirmation email has been sent.",
      });
    } catch (error) {
      console.error(
        "Failed to send account deletion confirmation email:",
        error,
      );

      await db
        .collection(REQUEST_COLLECTION)
        .doc(requestId)
        .update({
          emailSent: false,
          emailError: true,
          updatedAt: FieldValue.serverTimestamp(),
        })
        .catch((updateError) => {
          console.error(
            "Failed to update email error status:",
            updateError,
          );
        });

      res.status(500).json({
        success: false,
        message:
          "The deletion request was received, but the confirmation email could not be sent. Please try again later.",
      });
    }
  },
);

// ============================================================
// EXPORT
// ============================================================

module.exports = {
  requestAccountDeletion,
};