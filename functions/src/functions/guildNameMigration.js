
"use strict";

// ============================================================
// 🐱 STELLURIINI - GUILD NAME MIGRATION
// ============================================================
//
// One-time admin migration.
//
// Registers existing Guild names into:
// guildNames/{sha256(normalizedName)}
//
// Safety:
// - Admin-only
// - Duplicate detection before writes
// - Existing reservations are never overwritten
// - Idempotent
// - Firestore writes in batches of max 450
//
// ============================================================

const {
  onCall,
  HttpsError,
} = require("firebase-functions/v2/https");

const crypto = require("crypto");

const {
  db,
  FieldValue,
} = require("../firebase/firebase");

const REGION = "us-central1";
const BATCH_SIZE = 450;

const MIGRATION_REF = db
  .collection("guildSystem")
  .doc("guildNameMigration");

const GUILDS_COLLECTION = "guilds";
const NAMES_COLLECTION = "guildNames";

// ============================================================
// 🔐 ADMIN CHECK
// ============================================================

function requireAdmin(request) {
  if (!request.auth) {
    throw new HttpsError(
      "unauthenticated",
      "Kirjautuminen vaaditaan.",
    );
  }

  if (request.auth.token?.admin !== true) {
    throw new HttpsError(
      "permission-denied",
      "Vain admin voi suorittaa Guild-nimien migraation.",
    );
  }
}

// ============================================================
// 🔤 NAME NORMALIZATION
// ============================================================

function normalizeGuildName(name) {
  if (typeof name !== "string") {
    return "";
  }

  return name
    .trim()
    .normalize("NFKC")
    .toLowerCase()
    .replace(/\s+/g, " ");
}

function getGuildNameKey(normalizedName) {
  return crypto
    .createHash("sha256")
    .update(normalizedName, "utf8")
    .digest("hex");
}

// ============================================================
// 📦 CHUNK HELPER
// ============================================================

function chunkArray(items, chunkSize) {
  const chunks = [];

  for (
    let index = 0;
    index < items.length;
    index += chunkSize
  ) {
    chunks.push(
      items.slice(index, index + chunkSize),
    );
  }

  return chunks;
}

// ============================================================
// 🚀 MIGRATION
// ============================================================

const migrateGuildNames = onCall(
  {
    region: REGION,
    timeoutSeconds: 540,
    memory: "512MiB",
  },
  async (request) => {
    requireAdmin(request);

    try {
      // ------------------------------------------------------
      // CHECK MIGRATION STATUS
      // ------------------------------------------------------

      const statusSnapshot =
        await MIGRATION_REF.get();

      if (
        statusSnapshot.exists &&
        statusSnapshot.data()?.status === "completed"
      ) {
        return {
          success: true,
          alreadyCompleted: true,
          message: "Guild-nimien migraatio on jo suoritettu.",
        };
      }

      if (
        statusSnapshot.exists &&
        statusSnapshot.data()?.status === "running"
      ) {
        throw new HttpsError(
          "failed-precondition",
          "Guild-nimien migraatio on jo käynnissä.",
        );
      }

      // ------------------------------------------------------
      // LOCK MIGRATION
      // ------------------------------------------------------

      await db.runTransaction(
        async (transaction) => {
          const current =
            await transaction.get(MIGRATION_REF);

          if (
            current.exists &&
            current.data()?.status === "completed"
          ) {
            throw new HttpsError(
              "already-exists",
              "Migraatio on jo suoritettu.",
            );
          }

          if (
            current.exists &&
            current.data()?.status === "running"
          ) {
            throw new HttpsError(
              "failed-precondition",
              "Migraatio on jo käynnissä.",
            );
          }

          transaction.set(
            MIGRATION_REF,
            {
              status: "running",
              startedAt: FieldValue.serverTimestamp(),
              updatedAt: FieldValue.serverTimestamp(),
            },
          );
        },
      );

      // ------------------------------------------------------
      // LOAD ALL GUILDS
      // ------------------------------------------------------

      const guildSnapshot =
        await db
          .collection(GUILDS_COLLECTION)
          .get();

      const guilds = guildSnapshot.docs;

      // ------------------------------------------------------
      // VALIDATE GUILD NAMES
      // ------------------------------------------------------

      const normalizedNames = new Map();
      const reservations = [];

      for (const guildDocument of guilds) {
        const guildData =
          guildDocument.data() || {};

        const originalName =
          typeof guildData.name === "string"
            ? guildData.name.trim()
            : "";

        const normalizedName =
          normalizeGuildName(originalName);

        if (
          normalizedName.length < 3 ||
          normalizedName.length > 24
        ) {
          throw new Error(
            `Guild ${guildDocument.id} has an invalid name.`,
          );
        }

        const nameKey =
          getGuildNameKey(normalizedName);

        // Duplicate check
        const existingGuildId =
          normalizedNames.get(nameKey);

        if (existingGuildId) {
          throw new Error(
            `Duplicate Guild name detected: "${originalName}"`,
          );
        }

        normalizedNames.set(
          nameKey,
          guildDocument.id,
        );

        reservations.push({
          guildId: guildDocument.id,
          name: originalName,
          normalizedName,
          nameKey,
        });
      }

      // ------------------------------------------------------
      // CHECK EXISTING NAME RESERVATIONS
      // ------------------------------------------------------

      const nameReferences =
        reservations.map((reservation) =>
          db
            .collection(NAMES_COLLECTION)
            .doc(reservation.nameKey),
        );

      const existingReservations = [];

      for (const referenceChunk of chunkArray(
        nameReferences,
        BATCH_SIZE,
      )) {
        const snapshots =
          await db.getAll(...referenceChunk);

        existingReservations.push(...snapshots);
      }

      for (
        let index = 0;
        index < reservations.length;
        index++
      ) {
        const reservation =
          reservations[index];

        const existing =
          existingReservations[index];

        if (!existing.exists) {
          continue;
        }

        const existingData =
          existing.data() || {};

        if (
          existingData.guildId !==
          reservation.guildId
        ) {
          throw new Error(
            `Guild name reservation conflict: "${reservation.name}"`,
          );
        }
      }

      // ------------------------------------------------------
      // WRITE NAME RESERVATIONS
      // ------------------------------------------------------

      let registeredCount = 0;

      const missingReservations =
        reservations.filter(
          (reservation, index) =>
            !existingReservations[index].exists,
        );

      for (const reservationChunk of chunkArray(
        missingReservations,
        BATCH_SIZE,
      )) {
        const batch =
          db.batch();

        for (const reservation of reservationChunk) {
          const reference =
            db
              .collection(NAMES_COLLECTION)
              .doc(reservation.nameKey);

          batch.set(reference, {
            guildId: reservation.guildId,
            name: reservation.name,
            normalizedName:
              reservation.normalizedName,
            createdAt:
              FieldValue.serverTimestamp(),
            migratedAt:
              FieldValue.serverTimestamp(),
          });

          registeredCount += 1;
        }

        await batch.commit();
      }

      // ------------------------------------------------------
      // MARK MIGRATION COMPLETE
      // ------------------------------------------------------

      await MIGRATION_REF.set(
        {
          status: "completed",
          guildCount: guilds.length,
          registeredCount,
          completedAt:
            FieldValue.serverTimestamp(),
          updatedAt:
            FieldValue.serverTimestamp(),
        },
        { merge: true },
      );

      return {
        success: true,
        guildCount: guilds.length,
        registeredCount,
        alreadyRegistered:
          guilds.length - registeredCount,
        message:
          "Guild-nimien migraatio suoritettiin onnistuneesti.",
      };
    } catch (error) {
      console.error(
        "migrateGuildNames error:",
        error,
      );

      // ------------------------------------------------------
      // MARK MIGRATION FAILED
      // ------------------------------------------------------

      try {
        await MIGRATION_REF.set(
          {
            status: "failed",
            error:
              String(error.message || error)
                .slice(0, 500),
            failedAt:
              FieldValue.serverTimestamp(),
            updatedAt:
              FieldValue.serverTimestamp(),
          },
          { merge: true },
        );
      } catch (statusError) {
        console.error(
          "Could not update Guild migration status:",
          statusError,
        );
      }

      if (error instanceof HttpsError) {
        throw error;
      }

      throw new HttpsError(
        "internal",
        error.message ||
          "Guild-nimien migraatio epäonnistui.",
      );
    }
  },
);

// ============================================================
// 📦 EXPORTS
// ============================================================

module.exports = {
  migrateGuildNames,
};
