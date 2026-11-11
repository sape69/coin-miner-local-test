
"use strict";

// ============================================================
// 🐱 STELLURIINI - ADMIN DASHBOARD FUNCTIONS
// ============================================================
//
// Hallintatiedot haetaan palvelimelta.
//
// Pääsynhallinta:
// - Firebase Authentication vaaditaan.
// - Firebase Custom Claim: admin === true vaaditaan.
// - Firestore-sääntöjä ei avata Flutter-sovellukselle.
//
// Käyttäjänimen hakujärjestys:
// 1. Firestore username
// 2. Firestore displayName
// 3. Firebase Authentication displayName
// 4. Lyhennetty UID
//
// Sähköpostiosoitteita ei palauteta hallintanäkymään.
// ============================================================

const {
  onCall,
  HttpsError,
} = require("firebase-functions/v2/https");

const {
  Timestamp,
} = require("firebase-admin/firestore");

const {
  db,
  auth,
} = require("../firebase/firebase");

const REGION = "us-central1";
const DEFAULT_PAGE_SIZE = 50;
const MAX_PAGE_SIZE = 100;
const ENDING_SOON_MS = 60 * 60 * 1000;

// ============================================================
// DATE HELPERS
// ============================================================

function toDate(value) {
  if (!value) return null;

  if (value instanceof Date) {
    return Number.isFinite(value.getTime()) ? value : null;
  }

  if (typeof value.toDate === "function") {
    const date = value.toDate();
    return Number.isFinite(date.getTime()) ? date : null;
  }

  if (typeof value === "number" || typeof value === "string") {
    const date = new Date(value);
    return Number.isFinite(date.getTime()) ? date : null;
  }

  return null;
}

function toIso(value) {
  const date = toDate(value);
  return date ? date.toISOString() : null;
}

// ============================================================
// NUMBER HELPER
// ============================================================

function safeNumber(value, fallback = 0) {
  const parsed = Number(value);

  return Number.isFinite(parsed) && parsed >= 0
    ? parsed
    : fallback;
}

// ============================================================
// ADMIN ACCESS
// ============================================================

function requireAdmin(request) {
  if (!request.auth) {
    throw new HttpsError(
      "unauthenticated",
      "Kirjautuminen vaaditaan."
    );
  }

  if (request.auth.token?.admin !== true) {
    throw new HttpsError(
      "permission-denied",
      "Sinulla ei ole oikeutta käyttää hallintanäkymää."
    );
  }
}

// ============================================================
// USERNAME HELPERS
// ============================================================

function cleanName(value) {
  if (typeof value !== "string") {
    return "";
  }

  return value.trim();
}

function fallbackUsername(uid) {
  const shortUid = String(uid || "")
    .replace(/[^a-zA-Z0-9]/g, "")
    .slice(0, 6)
    .toUpperCase();

  return shortUid
    ? `Käyttäjä ${shortUid}`
    : "Tuntematon käyttäjä";
}

// ============================================================
// FIREBASE AUTH DISPLAY NAME
// ============================================================
//
// Haetaan displayName vain silloin, kun Firestore-profiilista
// ei löydy käyttäjänimeä eikä displayName-arvoa.
//
// Virhe yksittäisen käyttäjän Auth-haussa ei estä
// koko hallintanäkymän lataamista.
// ============================================================

async function getAuthDisplayName(uid) {
  try {
    const userRecord = await auth.getUser(uid);

    return cleanName(userRecord.displayName);
  } catch (error) {
    console.warn(
      `Could not read Auth displayName for user ${uid}:`,
      error.code || error.message
    );

    return "";
  }
}

// ============================================================
// USER ROW
// ============================================================

function buildUserRow(document, nowMs, authDisplayName = "") {
  const data = document.data() || {};

  const startedAt = toDate(data.miningStartedAt);
  const endsAt = toDate(data.miningEndsAt);

  const miningActive = Boolean(
    startedAt &&
    endsAt &&
    startedAt.getTime() <= nowMs &&
    endsAt.getTime() > nowMs
  );

  const endsInMs = endsAt
    ? endsAt.getTime() - nowMs
    : null;

  const username =
    cleanName(data.username) ||
    cleanName(data.displayName) ||
    cleanName(authDisplayName) ||
    fallbackUsername(document.id);

  return {
    username,
    displayName: username,

    miningActive,

    miningStartedAt: toIso(data.miningStartedAt),
    miningEndsAt: toIso(data.miningEndsAt),

    hashRate: safeNumber(data.miningHashRate, 0),
    miningBalance: safeNumber(data.miningBalance, 0),

    premium: data.premium === true,
    premiumVerified: data.premiumVerified === true,

    premiumTier:
      typeof data.premiumTier === "string"
        ? data.premiumTier
        : "free",

    premiumExpiryTime: toIso(data.premiumExpiryTime),

    endingSoon: Boolean(
      miningActive &&
      endsInMs !== null &&
      endsInMs <= ENDING_SOON_MS
    ),
  };
}

// ============================================================
// RESOLVE USER NAMES
// ============================================================
//
// Yhdistetään käyttäjälistan ja aktiivisten louhijoiden
// dokumentit. Auth-haut tehdään vain käyttäjille, joiden
// Firestore-profiilista puuttuu nimi.
//
// Sähköpostiosoitteita ei palauteta.
// ============================================================

async function buildUserRows(documents, nowMs) {
  const uniqueDocuments = new Map();

  for (const document of documents) {
    uniqueDocuments.set(document.id, document);
  }

  const authNames = new Map();

  const lookups = [];

  for (const [uid, document] of uniqueDocuments.entries()) {
    const data = document.data() || {};

    const firestoreName =
      cleanName(data.username) ||
      cleanName(data.displayName);

    if (!firestoreName) {
      lookups.push(
        (async () => {
          const name = await getAuthDisplayName(uid);
          authNames.set(uid, name);
        })()
      );
    }
  }

  await Promise.all(lookups);

  return documents.map((document) =>
    buildUserRow(
      document,
      nowMs,
      authNames.get(document.id) || ""
    )
  );
}

// ============================================================
// ADMIN DASHBOARD CALLABLE FUNCTION
// ============================================================

const getAdminDashboard = onCall(
  {
    region: REGION,
    timeoutSeconds: 60,
    memory: "256MiB",
  },
  async (request) => {
    requireAdmin(request);

    const requestedLimit = Number(request.data?.pageSize);

    const pageSize = Number.isInteger(requestedLimit)
      ? Math.min(
          Math.max(requestedLimit, 1),
          MAX_PAGE_SIZE
        )
      : DEFAULT_PAGE_SIZE;

    const now = Timestamp.now();
    const nowMs = now.toMillis();

    const endingSoonAt = Timestamp.fromMillis(
      nowMs + ENDING_SOON_MS
    );

    try {
      // ------------------------------------------------------
      // ALL USERS
      // ------------------------------------------------------

      const usersQuery = db
        .collection("users")
        .orderBy("updatedAt", "desc")
        .limit(pageSize);

      // ------------------------------------------------------
      // PREMIUM PLUS USERS
      // ------------------------------------------------------

      const premiumPlusQuery = db
        .collection("users")
        .where("premium", "==", true)
        .where("premiumVerified", "==", true)
        .where("premiumTier", "==", "premium_plus")
        .where("premiumExpiryTime", ">", now);

      // ------------------------------------------------------
      // ACTIVE MINERS
      // ------------------------------------------------------

      const activeMiningQuery = db
        .collection("users")
        .where("miningStartedAt", "<=", now)
        .where("miningEndsAt", ">", now);

      // ------------------------------------------------------
      // MINING ENDING WITHIN ONE HOUR
      // ------------------------------------------------------

      const endingSoonQuery = db
        .collection("users")
        .where("miningStartedAt", "<=", now)
        .where("miningEndsAt", ">", now)
        .where("miningEndsAt", "<=", endingSoonAt);

      // ------------------------------------------------------
      // LOAD DASHBOARD DATA
      // ------------------------------------------------------

      const [
        usersSnapshot,
        totalUsersResult,
        premiumPlusResult,
        activeMinersResult,
        activeMinersSnapshot,
        endingSoonResult,
      ] = await Promise.all([
        usersQuery.get(),

        db.collection("users").count().get(),

        premiumPlusQuery.count().get(),

        activeMiningQuery.count().get(),

        activeMiningQuery
          .limit(MAX_PAGE_SIZE)
          .get(),

        endingSoonQuery.count().get(),
      ]);

      // ------------------------------------------------------
      // RESOLVE USER NAMES
      // ------------------------------------------------------

      const allDocuments = [
        ...usersSnapshot.docs,
        ...activeMinersSnapshot.docs,
      ];

      const resolvedRows = await buildUserRows(
        allDocuments,
        nowMs
      );

      // ------------------------------------------------------
      // MAP RESOLVED ROWS BACK TO DOCUMENT IDS
      // ------------------------------------------------------

      const rowsById = new Map();

      const uniqueIds = new Set();

      for (const document of allDocuments) {
        if (uniqueIds.has(document.id)) {
          continue;
        }

        uniqueIds.add(document.id);
      }

      let rowIndex = 0;

      for (const uid of uniqueIds) {
        rowsById.set(uid, resolvedRows[rowIndex]);
        rowIndex++;
      }

      const users = usersSnapshot.docs.map(
        (document) =>
          rowsById.get(document.id)
      );

      const activeMinerList = activeMinersSnapshot.docs
        .map((document) =>
          rowsById.get(document.id)
        )
        .filter((user) =>
          user && user.miningActive
        );

      // ------------------------------------------------------
      // RESPONSE
      // ------------------------------------------------------

      return {
        success: true,

        generatedAt: now.toDate().toISOString(),

        totalUsers: totalUsersResult.data().count,

        premiumPlusUsers: premiumPlusResult.data().count,

        activeMiners: activeMinersResult.data().count,

        endingSoon: endingSoonResult.data().count,

        activeMinerList,

        pageSize,

        users,
      };
    } catch (error) {
      console.error(
        "getAdminDashboard failed:",
        error
      );

      if (error instanceof HttpsError) {
        throw error;
      }

      throw new HttpsError(
        "internal",
        "Hallintanäkymän tietojen hakeminen epäonnistui."
      );
    }
  }
);

// ============================================================
// EXPORTS
// ============================================================

module.exports = {
  getAdminDashboard,
};
