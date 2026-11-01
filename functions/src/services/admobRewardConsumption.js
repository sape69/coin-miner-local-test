
"use strict";

// ============================================================
// 🐱 STELLURIINI - ADMOB REWARD CONSUMPTION
// ============================================================
//
// Käsittelee vahvistetun AdMob Power Boost -palkinnon
// kertakäyttöisen kulutuksen Firestore-transaktiossa.
//
// TÄRKEÄÄ:
// - Palkinto validoidaan ennen kulutusta.
// - Reward-dokumentti luetaan saman transaktion sisällä.
// - Kulutusmerkinnät kirjoitetaan samaan transaktioon.
// - Jo käytettyä palkintoa ei voi käyttää uudelleen.
// - Samanaikaiset lunastukset ratkaistaan Firestoren
//   transaktiokonfliktien avulla.
//
// ============================================================

const {
  validateVerifiedRewardDocument,
} = require("./admobRewardService");

// ============================================================
// POWER BOOST REWARD CONSUMPTION
// ============================================================

function consumePowerBoostReward({
  transaction,
  rewardSnapshot,
  uid,
  transactionId,
  referenceNowMs,
  FieldValue,
}) {
  if (!transaction) {
    throw new Error(
      "Firestore transaction is required.",
    );
  }

  if (
    !rewardSnapshot ||
    typeof rewardSnapshot.exists !== "boolean"
  ) {
    throw new Error(
      "AdMob reward snapshot is required.",
    );
  }

  if (
    !FieldValue ||
    typeof FieldValue.serverTimestamp !== "function"
  ) {
    throw new Error(
      "Firestore FieldValue is required.",
    );
  }

  const validated =
    validateVerifiedRewardDocument(
      rewardSnapshot,
      uid,
      "power_boost",
      "powerBoostClaimed",
      {
        referenceNowMs,
        transactionId,
      },
    );

  const authoritativeId =
    validated.transactionId;

  transaction.set(
    rewardSnapshot.ref,
    {
      powerBoostClaimed: true,

      powerBoostClaimedAt:
        FieldValue.serverTimestamp(),

      powerBoostClaimedBy:
        uid,

      powerBoostTransactionId:
        authoritativeId,

      consumedAt:
        FieldValue.serverTimestamp(),

      consumedBy:
        uid,

      rewardConsumed: true,
    },
    {
      merge: true,
    },
  );

  return {
    success: true,

    transactionId:
      authoritativeId,

    uid,

    rewardPurpose:
      "power_boost",

    rewardConsumed: true,
  };
}

// ============================================================
// EXPORTS
// ============================================================

module.exports = {
  consumePowerBoostReward,
};
