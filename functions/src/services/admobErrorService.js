
"use strict";

// ============================================================
// 🐱 STELLURIINI - ADMOB ERROR SERVICE
// ============================================================
//
// Muuntaa AdMob-palvelun virheet Firebase HttpsError -muotoon.
//
// Tämä palvelu ei vahvista eikä käsittele AdMob-palkintoja.
// Se ainoastaan muuntaa virhekoodit turvallisiksi
// Firebase Callable Function -virheiksi.
// ============================================================

const {
  HttpsError,
} = require("firebase-functions/v2/https");

// ============================================================
// ADMOB ERROR MAPPING
// ============================================================

function toRewardHttpsError(
  error,
  fallbackMessage
) {
  if (error instanceof HttpsError) {
    return error;
  }

  const code =
    typeof error?.code === "string"
      ? error.code
      : "";

  switch (code) {
    case "ADMOB_REWARD_NOT_FOUND":
      return new HttpsError(
        "failed-precondition",
        "🐱 AdMob-palkinnon vahvistusta odotetaan. Yritä hetken kuluttua uudelleen."
      );

    case "ADMOB_REWARD_ALREADY_CLAIMED":
      return new HttpsError(
        "already-exists",
        "🐱 Tämä AdMob-palkinto on jo käytetty."
      );

    case "ADMOB_REWARD_EXPIRED":
      return new HttpsError(
        "failed-precondition",
        "🐱 AdMob-palkinto on vanhentunut."
      );

    case "ADMOB_REWARD_NOT_VERIFIED":
      return new HttpsError(
        "failed-precondition",
        "🐱 AdMob-palkintoa ei ole vielä vahvistettu."
      );

    case "ADMOB_TRANSACTION_ID_MISMATCH":
    case "ADMOB_REWARD_UID_MISMATCH":
    case "ADMOB_REWARD_PURPOSE_MISMATCH":
      return new HttpsError(
        "permission-denied",
        "🐱 AdMob-palkinnon tiedot eivät täsmää."
      );

    case "ADMOB_REWARD_TIMESTAMP_MISSING":
    case "ADMOB_REWARD_TIMESTAMP_INVALID":
    case "ADMOB_REWARD_UID_MISSING":
    case "ADMOB_REWARD_PURPOSE_MISSING":
    case "ADMOB_REWARD_TRANSACTION_ID_MISSING":
      return new HttpsError(
        "failed-precondition",
        "🐱 AdMob-palkinnon vahvistustiedot ovat puutteelliset."
      );

    case "ADMOB_INVALID_UID":
    case "ADMOB_INVALID_REWARD_PURPOSE":
    case "ADMOB_INVALID_CLAIM_FIELD":
      return new HttpsError(
        "invalid-argument",
        "🐱 AdMob-palkinnon tiedot ovat virheelliset."
      );

    default:
      return new HttpsError(
        "failed-precondition",
        fallbackMessage
      );
  }
}

// ============================================================
// EXPORTS
// ============================================================

module.exports = {
  toRewardHttpsError,
};
