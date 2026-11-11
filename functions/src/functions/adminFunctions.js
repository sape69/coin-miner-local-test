"use strict";

// ============================================================
// 🐱 STELLURIINI - ADMIN DASHBOARD FUNCTIONS
// ============================================================
//
// Kaikki hallintanäkymän käyttäjätiedot haetaan palvelimelta.
// Firestore-sääntöjä ei avata Flutter-sovellukselle.
//
// Pääsynhallinta:
// - Firebase Authentication vaaditaan.
// - Firebase Custom Claim: admin === true vaaditaan.
// - UID:tä tai ylläpitäjälistaa ei luoteta asiakkaan lähettämänä.
//
// Palautetaan vain hallintanäkymässä tarvittavat tiedot.
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
  return Number.isFinite(parsed) ? parsed : fallback;
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

  const isMiningActive = Boolean(
    startedAt &&
    endsAt &&
    startedAt.getTime() <= nowMs &&
    endsAt.getTime() > nowMs
  );

  const endsInMs = endsAt
    ? endsAt.getTime() - nowMs
    : null;

  return {
    uid: document.id,
    username:
      typeof data.username === "string" && data.username.trim()
        ? data.username.trim()
        : "—",
    miningActive: isMiningActive,
    miningStartedAt: toIso(data.miningStartedAt),
    miningEndsAt: toIso(data.miningEndsAt),
    hashRate: safeNumber(
      data.miningHashRate ?? data.hashRate,
      0
    ),
    miningBalance: safeNumber(data.miningBalance, 0),
    premium: data.premium === true,
    premiumVerified: data.premiumVerified === true,
    premiumTier:
      typeof data.premiumTier === "string"
        ? data.premiumTier
        : "free",
    autoMiningLastRunAt: toIso(data.autoMiningLastRunAt),
    endingSoon: Boolean(
      isMiningActive &&
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

    try {
      const usersQuery = db
        .collection("users")
        .orderBy("updatedAt", "desc")
        .limit(pageSize);

      const [usersSnapshot, totalUsersResult, premiumPlusResult] =
        await Promise.all([
          usersQuery.get(),
          db.collection("users").count().get(),
          db.collection("users")
            .where("premium", "==", true)
            .where("premiumVerified", "==", true)
            .where("premiumTier", "==", "premium_plus")
            .where("premiumExpiryTime", ">", now)
            .count()
            .get(),
        ]);

      const users = usersSnapshot.docs.map((document) =>
        buildUserRow(document, nowMs)
      );

      const activeMiners = users.filter(
        (user) => user.miningActive
      );

      const endingSoon = users.filter(
        (user) => user.endingSoon
      );

      return {
        success: true,
        generatedAt: now.toDate().toISOString(),
        pageSize,
        totalUsers: totalUsersResult.data().count,
        premiumPlusUsers: premiumPlusResult.data().count,
        activeMinersOnPage: activeMiners.length,
        endingSoonOnPage: endingSoon.length,
        users,
        nextPageCursor: usersSnapshot.docs.length === pageSize
          ? usersSnapshot.docs[usersSnapshot.docs.length - 1].id
          : null,
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
