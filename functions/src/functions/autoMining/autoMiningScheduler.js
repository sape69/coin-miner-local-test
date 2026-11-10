
"use strict";

// ============================================================
// 🐱 STELLURIINI - PREMIUM PLUS AUTO MINING SCHEDULER
// ============================================================
//
// Vastuut:
// - Käynnistää Premium Plus -automaattisen louhinnan ajastetusti.
// - Hakee vain voimassa olevat, varmennetut Premium Plus -tilaukset.
// - Käsittelee käyttäjät pienissä erissä.
// - Yhden käyttäjän virhe ei pysäytä muita käyttäjiä.
//
// Louhinnan laskenta ja saldojen päivitys kuuluvat
// autoMiningService.js-palvelulle.
//
// ============================================================


// ============================================================
// FIREBASE SCHEDULER
// ============================================================

const {
  onSchedule,
} = require("firebase-functions/v2/scheduler");

const {
  Timestamp,
} = require("firebase-admin/firestore");

const {
  db,
} = require("../../firebase/firebase");


// ============================================================
// AUTO MINING SERVICE
// ============================================================

const {
  processAutoMiningUser,
} = require("../miningFunctions");


// ============================================================
// CONFIGURATION
// ============================================================

const REGION = "us-central1";

const SCHEDULE = "every 5 minutes";

const BATCH_SIZE = 100;


// ============================================================
// VALIDATE DEPENDENCIES
// ============================================================

if (typeof processAutoMiningUser !== "function") {
  throw new Error(
    "AUTO_MINING_SCHEDULER: processAutoMiningUser is not available."
  );
}


// ============================================================
// PREMIUM PLUS AUTO MINING SCHEDULER
// ============================================================

const premiumPlusAutoMiningScheduler = onSchedule(
  {
    region: REGION,

    schedule: SCHEDULE,

    timeZone: "UTC",

    timeoutSeconds: 540,

    memory: "512MiB",

    maxInstances: 1,
  },

  async () => {
    console.log(
      "Premium Plus auto mining scheduler started."
    );

    const now = Timestamp.now();

    let lastDocument = null;

    let processedCount = 0;
    let startedCount = 0;
    let skippedCount = 0;
    let failedCount = 0;

    // ========================================================
    // PROCESS USERS IN PAGINATED BATCHES
    // ========================================================

    while (true) {
      let query = db
        .collection("users")

        .where(
          "premium",
          "==",
          true
        )

        .where(
          "premiumVerified",
          "==",
          true
        )

        .where(
          "premiumTier",
          "==",
          "premium_plus"
        )

        .where(
          "premiumExpiryTime",
          ">",
          now
        )

        .orderBy(
          "premiumExpiryTime"
        )

        .limit(BATCH_SIZE);

      if (lastDocument) {
        query = query.startAfter(
          lastDocument
        );
      }

      const snapshot = await query.get();

      if (snapshot.empty) {
        break;
      }

      console.log(
        `Premium Plus batch found: ${snapshot.size}`
      );

      // ======================================================
      // PROCESS EACH USER
      // ======================================================

      for (const userDocument of snapshot.docs) {
        const uid = userDocument.id;

        processedCount++;

        try {
          const result =
            await processAutoMiningUser(uid);

          if (
            result &&
            result.success === true &&
            result.skipped !== true
          ) {
            startedCount++;

            console.log(
              "Automatic mining cycle started:",
              uid,
              {
                collected: result.collected,
                hashRate: result.hashRate,
                miningEndsAt: result.miningEndsAt,
              }
            );
          } else {
            skippedCount++;

            console.log(
              "Automatic mining skipped:",
              uid,
              result?.reason || "unknown_reason"
            );
          }
        } catch (error) {
          failedCount++;

          console.error(
            "Automatic mining failed for user:",
            uid,
            error?.stack || error?.message || error
          );
        }
      }

      // ======================================================
      // PAGINATION
      // ======================================================

      lastDocument =
        snapshot.docs[snapshot.docs.length - 1];

      if (snapshot.size < BATCH_SIZE) {
        break;
      }
    }

    // ========================================================
    // SUMMARY
    // ========================================================

    console.log(
      "Premium Plus auto mining scheduler completed.",
      {
        processedCount,
        startedCount,
        skippedCount,
        failedCount,
      }
    );

    return {
      processedCount,
      startedCount,
      skippedCount,
      failedCount,
    };
  }
);


// ============================================================
// EXPORTS
// ============================================================

module.exports = {
  premiumPlusAutoMiningScheduler,
};
