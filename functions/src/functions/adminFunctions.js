
"use strict";

// ============================================================
// 🐱 STELLURIINI - ADMIN DASHBOARD FUNCTIONS
// ============================================================
//
// Hallintatiedot haetaan aina palvelimelta.
// Firestore-sääntöjä ei avata Flutter-sovellukselle.
//
// Pääsynhallinta:
// - Firebase Authentication vaaditaan.
// - Firebase Custom Claim: admin === true vaaditaan.
// - Asiakkaan lähettämää UID:tä ei käytetä oikeuksien tarkistamiseen.
//
// Palautetaan vain hallintanäkymän tarvitsemat tiedot.
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
} = require("../firebase/firebase");

const REGION = "us-central1";
const DEFAULT_PAGE_SIZE = 50;
const MAX_PAGE_SIZE = 100;
const ENDING_SOON_MS = 60 * 60 * 1000;

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

function safeNumber(value, fallback = 0) {
  const parsed = Number(value);

  return Number.isFinite(parsed) && parsed >= 0
    ? parsed
    : fallback;
}

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

function buildUserRow(document, nowMs) {
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

  return {
    username:
      typeof data.username === "string" && data.username.trim()
        ? data.username.trim()
        : "—",

    displayName:
      typeof data.displayName === "string" && data.displayName.trim()
        ? data.displayName.trim()
        : "",

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
      ? Math.min(Math.max(requestedLimit, 1), MAX_PAGE_SIZE)
      : DEFAULT_PAGE_SIZE;

    const now = Timestamp.now();
    const nowMs = now.toMillis();

    const endingSoonAt = Timestamp.fromMillis(
      nowMs + ENDING_SOON_MS
    );

    try {
      const usersQuery = db
        .collection("users")
        .orderBy("updatedAt", "desc")
        .limit(pageSize);

      const premiumPlusQuery = db
        .collection("users")
        .where("premium", "==", true)
        .where("premiumVerified", "==", true)
        .where("premiumTier", "==", "premium_plus")
        .where("premiumExpiryTime", ">", now);

      // Louhintajakson pitää olla jo alkanut
      // ja sen päättymisajan pitää olla tulevaisuudessa.
      const activeMiningQuery = db
        .collection("users")
        .where("miningStartedAt", "<=", now)
        .where("miningEndsAt", ">", now);

      // Sama aktiivisuusehto sekä päättymisaika
      // seuraavan tunnin sisällä.
      const endingSoonQuery = db
        .collection("users")
        .where("miningStartedAt", "<=", now)
        .where("miningEndsAt", ">", now)
        .where("miningEndsAt", "<=", endingSoonAt);

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

        activeMiningQuery.limit(MAX_PAGE_SIZE).get(),

        endingSoonQuery.count().get(),
      ]);

      const users = usersSnapshot.docs.map((document) =>
        buildUserRow(document, nowMs)
      );

      const activeMinerList = activeMinersSnapshot.docs
        .map((document) => buildUserRow(document, nowMs))
        .filter((user) => user.miningActive);

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
      console.error("getAdminDashboard failed:", error);

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

module.exports = {
  getAdminDashboard,
};
