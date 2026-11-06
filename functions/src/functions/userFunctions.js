"use strict";

const {
  onCall,
  HttpsError,
} = require("firebase-functions/v2/https");

const {
  db,
  auth,
  FieldValue,
} = require("../firebase/firebase");

const {
  getUserRef,
  getHistoryCollection,
} = require("../utils/userUtils");

async function getTrustedUserData(uid) {
  try {
    const userRecord = await auth.getUser(uid);
    return {
      displayName:
        typeof userRecord.displayName === "string"
          ? userRecord.displayName.trim()
          : "",
      email:
        typeof userRecord.email === "string"
          ? userRecord.email.trim()
          : "",
    };
  } catch (error) {
    console.error("Failed to read Firebase Auth user:", error);
    throw new HttpsError(
      "internal",
      "Käyttäjän tietojen hakeminen epäonnistui."
    );
  }
}

function getSafeNonNegativeNumber(value) {
  const parsed = Number(value);
  if (!Number.isFinite(parsed) || parsed < 0) return null;
  return parsed;
}

// Palauttaa vain varsinaisten mining_reward-tapahtumien summan.
async function calculateHistoricalTotalMined(transaction, uid) {
  const query = getHistoryCollection(uid)
    .where("type", "==", "mining_reward");
  const snapshot = await transaction.get(query);

  let total = 0;
  for (const document of snapshot.docs) {
    const amount = getSafeNonNegativeNumber(
      (document.data() || {}).amount
    );
    if (amount !== null) total += amount;
  }
  return total;
}

function buildDefaultUserProfile(request, trustedUser) {
  const tokenEmail =
    typeof request.auth.token?.email === "string"
      ? request.auth.token.email
      : "";
  const tokenName =
    typeof request.auth.token?.name === "string"
      ? request.auth.token.name.trim()
      : "";
  const displayName = trustedUser.displayName || tokenName;
  const email = trustedUser.email || tokenEmail;

  return {
    email,
    displayName,
    username: displayName,

    stlBalance: 0,

    miningBalance: 0,
    totalMined: 0,
    totalMinedInitialized: true,
    miningCycles: 0,
    miningHashRate: 0,
    miningStartedAt: null,
    miningEndsAt: null,

    adBoostHashRate: 0,
    adBoostStartedAt: null,
    adBoostEndsAt: null,

    dailyHashRate: 0,
    dailyStreak: 0,
    streak: 0,
    lastDailyDate: "",

    adsToday: 0,
    adDate: "",
    lastAdTime: null,

    referralCode: "",
    referrerUid: "",
    referralCodeUsed: "",
    referralJoinedAt: null,
    referralCount: 0,
    referralTotalEarned: 0,

    createdAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  };
}

const ensureUserProfile = onCall(
  { region: "us-central1" },
  async (request) => {
    try {
      if (!request.auth) {
        throw new HttpsError(
          "unauthenticated",
          "Kirjautuminen vaaditaan."
        );
      }

      const uid = request.auth.uid;
      if (typeof uid !== "string" || !uid.trim()) {
        throw new HttpsError(
          "invalid-argument",
          "Käyttäjän UID puuttuu."
        );
      }

      const trustedUser = await getTrustedUserData(uid);
      const userRef = getUserRef(uid);
      const initialSnapshot = await userRef.get();

      if (initialSnapshot.exists) {
        const result = await db.runTransaction(async (transaction) => {
          const userSnapshot = await transaction.get(userRef);

          if (!userSnapshot.exists) {
            return { profileMissing: true, totalMinedBackfilled: false };
          }

          const existingData = userSnapshot.data() || {};
          const updates = {};

          const existingUsername =
            typeof existingData.username === "string"
              ? existingData.username.trim()
              : "";
          const existingDisplayName =
            typeof existingData.displayName === "string"
              ? existingData.displayName.trim()
              : "";
          const existingEmail =
            typeof existingData.email === "string"
              ? existingData.email.trim()
              : "";

          if (!existingUsername && trustedUser.displayName) {
            updates.username = trustedUser.displayName;
          }
          if (!existingDisplayName && trustedUser.displayName) {
            updates.displayName = trustedUser.displayName;
          }
          if (!existingEmail && trustedUser.email) {
            updates.email = trustedUser.email;
          }

          const existingTotalMined =
            getSafeNonNegativeNumber(existingData.totalMined);
          let totalMinedBackfilled = false;

          if (existingTotalMined === null) {
            updates.totalMined =
              await calculateHistoricalTotalMined(
                transaction,
                uid
              );
            updates.totalMinedInitialized = true;
            totalMinedBackfilled = true;
          } else if (existingData.totalMinedInitialized !== true) {
            // Olemassa oleva kelvollinen totalMined on auktoriteetti.
            // Sitä ei korvata historiasta lasketulla summalla.
            updates.totalMinedInitialized = true;
          }

          if (Object.keys(updates).length > 0) {
            updates.updatedAt = FieldValue.serverTimestamp();
            transaction.update(userRef, updates);
          }

          return { profileMissing: false, totalMinedBackfilled };
        });

        if (result.profileMissing) {
          throw new HttpsError(
            "not-found",
            "Käyttäjäprofiili poistui tarkistuksen aikana. Yritä uudelleen."
          );
        }

        const initialData = initialSnapshot.data() || {};
        const initialUsername =
          typeof initialData.username === "string"
            ? initialData.username.trim()
            : "";

        return {
          success: true,
          created: false,
          exists: true,
          usernameUpdated: !initialUsername &&
            Boolean(trustedUser.displayName),
          totalMinedBackfilled: result.totalMinedBackfilled,
          uid,
          message: result.totalMinedBackfilled
            ? "Käyttäjäprofiili ja historiallinen louhintamäärä täydennettiin."
            : "Käyttäjäprofiili tarkistettu.",
        };
      }

      const profile = buildDefaultUserProfile(request, trustedUser);

      try {
        await userRef.create(profile);
      } catch (error) {
        if (error?.code === 6) {
          return {
            success: true,
            created: false,
            exists: true,
            uid,
            message: "Käyttäjäprofiili on jo olemassa.",
          };
        }
        throw error;
      }

      return {
        success: true,
        created: true,
        exists: true,
        totalMinedBackfilled: false,
        uid,
        message: "Käyttäjäprofiili luotu onnistuneesti.",
      };
    } catch (error) {
      console.error("ensureUserProfile error:", error);
      if (error instanceof HttpsError) throw error;
      throw new HttpsError(
        "internal",
        "Käyttäjäprofiilin luominen epäonnistui."
      );
    }
  }
);

const getUserProfile = onCall(
  { region: "us-central1" },
  async (request) => {
    try {
      if (!request.auth) {
        throw new HttpsError(
          "unauthenticated",
          "Kirjautuminen vaaditaan."
        );
      }

      const uid = request.auth.uid;
      if (typeof uid !== "string" || !uid.trim()) {
        throw new HttpsError(
          "invalid-argument",
          "Käyttäjän UID puuttuu."
        );
      }

      const userRef = getUserRef(uid);
      const snapshot = await userRef.get();

      if (!snapshot.exists) {
        throw new HttpsError(
          "not-found",
          "Käyttäjäprofiilia ei löytynyt."
        );
      }

      return {
        success: true,
        exists: true,
        uid,
        profile: snapshot.data() || {},
      };
    } catch (error) {
      console.error("getUserProfile error:", error);
      if (error instanceof HttpsError) throw error;
      throw new HttpsError(
        "internal",
        "Käyttäjäprofiilin hakeminen epäonnistui."
      );
    }
  }
);

module.exports = {
  ensureUserProfile,
  getUserProfile,
};
