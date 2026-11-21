"use strict";

// ============================================================
// 🐱 STELLURIINI - GUILD NAME MIGRATION
// ============================================================
//
// One-time admin migration for existing Guild names.
//
// Registry:
// guildNames/{sha256(normalizedName)}
//
// Safety:
// - Admin-only
// - Dry-run preview supported
// - Duplicate name detection
// - Existing reservations are never overwritten
// - Transaction-based migration lock
// - Expired locks can be recovered
// - Idempotent migration
// - Firestore batches max 450 documents
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
const LOCK_TIMEOUT_MS = 15 * 60 * 1000;

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
// 📋 LOAD AND VALIDATE GUILD NAMES
// ============================================================

async function inspectGuildNames() {
  const guildSnapshot = await db
    .collection(GUILDS_COLLECTION)
    .get();

  const guilds = guildSnapshot.docs;
  const normalizedNames = new Map();
  const reservations = [];
  const conflicts = [];

  for (const guildDocument of guilds) {
    const guildData = guildDocument.data() || {};

    const originalName =
      typeof guildData.name === "string"
        ? guildData.name.trim()
        : "";

    // FIX: use the correctly defined originalName variable.
    const normalizedName =
      normalizeGuildName(originalName);

    if (
      normalizedName.length < 3 ||
      normalizedName.length > 24
    ) {
      conflicts.push({
        type: "invalid_name",
        guildId: guildDocument.id,
        name: originalName,
        message:
          "Guild-nimen pituus ei ole sallittu.",
      });

      continue;
    }

    const nameKey =
      getGuildNameKey(normalizedName);

    const existingGuildId =
      normalizedNames.get(nameKey);

    if (existingGuildId) {
      conflicts.push({
        type: "duplicate_name",
        guildId: guildDocument.id,
        otherGuildId: existingGuildId,
        name: originalName,
        message:
          "Guild-nimi on käytössä toisella Guildilla.",
      });

      continue;
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

  // ----------------------------------------------------------
  // CHECK EXISTING NAME RESERVATIONS
  // ----------------------------------------------------------

  const nameReferences = reservations.map(
    (reservation) =>
      db
        .collection(NAMES_COLLECTION)
        .doc(reservation.nameKey),
  );

  const existingReservations = [];

  for (const referenceChunk of chunkArray(
    nameReferences,
    BATCH_SIZE,
  )) {
    const snapshots = await db.getAll(
      ...referenceChunk,
    );

    existingReservations.push(...snapshots);
  }

  for (
    let index = 0;
    index < reservations.length;
    index++
  ) {
    const reservation = reservations[index];
    const existing = existingReservations[index];

    if (!existing || !existing.exists) {
      continue;
    }

    const existingData = existing.data() || {};

    if (
      existingData.guildId !==
      reservation.guildId
    ) {
      conflicts.push({
        type: "reservation_conflict",
        guildId: reservation.guildId,
        existingGuildId: existingData.guildId || null,
        name: reservation.name,
        message:
          "Guild-nimen rekisterivarauksessa on ristiriita.",
      });
    }
  }

  return {
    guilds,
    reservations,
    existingReservations,
    conflicts,
  };
}

// ============================================================
// 🔍 DRY RUN
// ============================================================

async function previewGuildNameMigration() {
  const inspection =
    await inspectGuildNames();

  const {
    guilds,
    reservations,
    existingReservations,
    conflicts,
  } = inspection;

  const alreadyRegistered =
    existingReservations.filter(
      (snapshot) => snapshot && snapshot.exists,
    ).length;

  const missingReservations =
    reservations.filter(
      (reservation, index) =>
        !existingReservations[index] ||
        !existingReservations[index].exists,
    );

  return {
    success: conflicts.length === 0,
    dryRun: true,
    guildCount: guilds.length,
    validGuildNames: reservations.length,
    alreadyRegistered,
    missingReservations: missingReservations.length,
    conflictCount: conflicts.length,
    conflicts,
    message:
      conflicts.length === 0
        ? "Esitarkistus onnistui. Migraatio voidaan suorittaa."
        : "Esitarkistuksessa löytyi ongelmia. Migraatiota ei pidä suorittaa.",
  };
}

// ============================================================
// 🔒 ACQUIRE MIGRATION LOCK
// ============================================================

async function acquireMigrationLock(lockId) {
  await db.runTransaction(
    async (transaction) => {
      const snapshot =
        await transaction.get(MIGRATION_REF);

      const data =
        snapshot.exists
          ? snapshot.data() || {}
          : {};

      if (data.status === "completed") {
        throw new HttpsError(
          "already-exists",
          "Guild-nimien migraatio on jo suoritettu.",
        );
      }

      if (data.status === "running") {
        const lockedAt =
          data.lockedAt &&
          typeof data.lockedAt.toMillis === "function"
            ? data.lockedAt.toMillis()
            : 0;

        const lockExpired =
          !lockedAt ||
          Date.now() - lockedAt >
            LOCK_TIMEOUT_MS;

        if (!lockExpired) {
          throw new HttpsError(
            "failed-precondition",
            "Guild-nimien migraatio on jo käynnissä. Yritä myöhemmin.",
          );
        }
      }

      transaction.set(
        MIGRATION_REF,
        {
          status: "running",
          lockId,
          lockedAt: FieldValue.serverTimestamp(),
          startedAt: FieldValue.serverTimestamp(),
          updatedAt: FieldValue.serverTimestamp(),
          error: FieldValue.delete(),
        },
        { merge: true },
      );
    },
  );
}

// ============================================================
// 🔓 RELEASE / UPDATE MIGRATION STATUS
// ============================================================

async function updateMigrationStatus(
  lockId,
  data,
) {
  await db.runTransaction(
    async (transaction) => {
      const snapshot =
        await transaction.get(MIGRATION_REF);

      if (!snapshot.exists) {
        return;
      }

      const current =
        snapshot.data() || {};

      // Never update a migration lock owned by another run.
      if (current.lockId !== lockId) {
        return;
      }

      transaction.set(
        MIGRATION_REF,
        {
          ...data,
          lockId: FieldValue.delete(),
          lockedAt: FieldValue.delete(),
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
    },
  );
}

// ============================================================
// 🚀 MIGRATION CALLABLE
// ============================================================

const migrateGuildNames = onCall(
  {
    region: REGION,
    timeoutSeconds: 540,
    memory: "512MiB",
  },
  async (request) => {
    requireAdmin(request);

    // --------------------------------------------------------
    // DRY RUN - NO WRITES TO THE NAME REGISTRY
    // --------------------------------------------------------

    if (request.data?.dryRun === true) {
      return await previewGuildNameMigration();
    }

    const lockId = crypto.randomUUID();

    let lockAcquired = false;

    try {
      // ------------------------------------------------------
      // ACQUIRE LOCK
      // ------------------------------------------------------

      await acquireMigrationLock(lockId);
      lockAcquired = true;

      // ------------------------------------------------------
      // INSPECT ALL GUILDS
      // ------------------------------------------------------

      const inspection =
        await inspectGuildNames();

      const {
        guilds,
        reservations,
        existingReservations,
        conflicts,
      } = inspection;

      // ------------------------------------------------------
      // STOP IF ANY CONFLICTS
      // ------------------------------------------------------

      if (conflicts.length > 0) {
        await updateMigrationStatus(
          lockId,
          {
            status: "failed",
            error:
              "Guild-nimien tarkistuksessa löytyi ristiriitoja.",
            conflictCount: conflicts.length,
            conflicts,
            failedAt:
              FieldValue.serverTimestamp(),
          },
        );

        return {
          success: false,
          dryRun: false,
          guildCount: guilds.length,
          conflictCount: conflicts.length,
          conflicts,
          message:
            "Migraatio keskeytettiin. Guild-nimien ristiriidat on korjattava ennen uudelleen yrittämistä.",
        };
      }

      // ------------------------------------------------------
      // WRITE MISSING RESERVATIONS
      // ------------------------------------------------------

      let registeredCount = 0;

      const missingReservations =
        reservations.filter(
          (reservation, index) =>
            !existingReservations[index] ||
            !existingReservations[index].exists,
        );

      for (const reservationChunk of chunkArray(
        missingReservations,
        BATCH_SIZE,
      )) {
        const batch = db.batch();

        for (const reservation of reservationChunk) {
          const reference =
            db
              .collection(NAMES_COLLECTION)
              .doc(reservation.nameKey);

          batch.create(reference, {
            guildId: reservation.guildId,
            name: reservation.name,
            normalizedName:
              reservation.normalizedName,
            createdAt:
              FieldValue.serverTimestamp(),
            migratedAt:
              FieldValue.serverTimestamp(),
          });

          registeredCount++;
        }

        await batch.commit();
      }

      // ------------------------------------------------------
      // MARK MIGRATION COMPLETE
      // ------------------------------------------------------

      await updateMigrationStatus(
        lockId,
        {
          status: "completed",
          guildCount: guilds.length,
          registeredCount,
          alreadyRegistered:
            guilds.length - registeredCount,
          completedAt:
            FieldValue.serverTimestamp(),
          error: FieldValue.delete(),
        },
      );

      return {
        success: true,
        dryRun: false,
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
      // MARK FAILED ONLY IF WE OWN THE LOCK
      // ------------------------------------------------------

      if (lockAcquired) {
        try {
          await updateMigrationStatus(
            lockId,
            {
              status: "failed",
              error:
                String(error.message || error)
                  .slice(0, 500),
              failedAt:
                FieldValue.serverTimestamp(),
            },
          );
        } catch (statusError) {
          console.error(
            "Could not update Guild migration status:",
            statusError,
          );
        }
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