"use strict";

// ============================================================
// 🐱 STELLURIINI - USER FUNCTIONS
// ============================================================
//
// Flutter
//    ↓
// ensureUserProfile()
//    ↓
// Firebase Admin Authentication + Firestore
//    ↓
// users/{uid}
//
// ============================================================

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
} = require("../utils/userUtils");

// ============================================================
// 👤 GET TRUSTED AUTH USER DATA
// ============================================================

async function getTrustedUserData(uid) {
try {
const userRecord = await auth.getUser(uid);

const displayName =
  typeof userRecord.displayName === "string"
    ? userRecord.displayName.trim()
    : "";

const email =
  typeof userRecord.email === "string"
    ? userRecord.email.trim()
    : "";

return {
  displayName,
  email,
};

} catch (error) {
console.error(
"Failed to read Firebase Auth user:",
error,
);

throw new HttpsError(
  "internal",
  "Käyttäjän tietojen hakeminen epäonnistui.",
);

}
}

// ============================================================
// 🔢 DEFAULT USER PROFILE
// ============================================================

function buildDefaultUserProfile(
request,
trustedUser,
) {
const tokenEmail =
typeof request.auth.token?.email === "string"
? request.auth.token.email
: "";

const tokenName =
typeof request.auth.token?.name === "string"
? request.auth.token.name.trim()
: "";

const displayName =
trustedUser.displayName || tokenName;

const email =
trustedUser.email || tokenEmail;

return {
// 👤 BASIC USER
email,
displayName,
username: displayName,

// 💰 BALANCE
stlBalance: 0,

// ⛏️ MINING
miningBalance: 0,
miningHashRate: 0,
miningStartedAt: null,
miningEndsAt: null,

// ⚡ POWER BOOST
adBoostHashRate: 0,
adBoostStartedAt: null,
adBoostEndsAt: null,

// 🎁 DAILY
dailyHashRate: 0,
dailyStreak: 0,
streak: 0,
lastDailyDate: "",

// 📺 ADS
adsToday: 0,
adDate: "",
lastAdTime: null,

// 🔗 REFERRAL
referralCode: "",
referrerUid: "",
referralCodeUsed: "",
referralJoinedAt: null,
referralCount: 0,
referralTotalEarned: 0,

// 🕐 TIMESTAMPS
createdAt: FieldValue.serverTimestamp(),
updatedAt: FieldValue.serverTimestamp(),

};
}

// ============================================================
// 🔗 ENSURE USER PROFILE
// ============================================================
//
// Luo uuden käyttäjäprofiilin tai täydentää vain puuttuvat
// nimikentät olemassa olevasta profiilista.
//
// Olemassa olevia saldoja, louhintatietoja, kutsukoodeja
// tai referral-palkkioita ei nollata.
//
// ============================================================

const ensureUserProfile = onCall(
{
region: "us-central1",
},
async (request) => {
try {
// 🔐 AUTHENTICATION
if (!request.auth) {
throw new HttpsError(
"unauthenticated",
"Kirjautuminen vaaditaan.",
);
}

  const uid = request.auth.uid;

  if (
    typeof uid !== "string" ||
    !uid.trim()
  ) {
    throw new HttpsError(
      "invalid-argument",
      "Käyttäjän UID puuttuu.",
    );
  }

  // 👤 READ TRUSTED AUTH USER
  const trustedUser =
    await getTrustedUserData(uid);

  const userRef = getUserRef(uid);

  // 🔍 CHECK EXISTING PROFILE
  const snapshot = await userRef.get();

  if (snapshot.exists) {
    const existingData =
      snapshot.data() || {};

    const updates = {};

    const existingUsername =
      typeof existingData.username === "string"
        ? existingData.username.trim()
        : "";

    const existingDisplayName =
      typeof existingData.displayName === "string"
        ? existingData.displayName.trim()
        : "";

    // Täydennä username vain, jos se puuttuu.
    if (
      !existingUsername &&
      trustedUser.displayName
    ) {
      updates.username =
        trustedUser.displayName;
    }

    // Täydennä displayName vain, jos se puuttuu.
    if (
      !existingDisplayName &&
      trustedUser.displayName
    ) {
      updates.displayName =
        trustedUser.displayName;
    }

    // Täydennä sähköposti vain, jos se puuttuu.
    const existingEmail =
      typeof existingData.email === "string"
        ? existingData.email.trim()
        : "";

    if (
      !existingEmail &&
      trustedUser.email
    ) {
      updates.email =
        trustedUser.email;
    }

    if (Object.keys(updates).length > 0) {
      updates.updatedAt =
        FieldValue.serverTimestamp();

      await userRef.update(updates);
    }

    return {
      success: true,
      created: false,
      exists: true,
      usernameUpdated:
        Object.prototype.hasOwnProperty.call(
          updates,
          "username",
        ),
      uid,
      message:
        "Käyttäjäprofiili tarkistettu.",
    };
  }

  // 🆕 CREATE PROFILE
  const profile =
    buildDefaultUserProfile(
      request,
      trustedUser,
    );

  await userRef.create(profile);

  return {
    success: true,
    created: true,
    exists: true,
    uid,
    message:
      "Käyttäjäprofiili luotu onnistuneesti.",
  };
} catch (error) {
  console.error(
    "ensureUserProfile error:",
    error,
  );

  if (error instanceof HttpsError) {
    throw error;
  }

  // Firestore ALREADY_EXISTS
  if (error?.code === 6) {
    return {
      success: true,
      created: false,
      exists: true,
      uid: request.auth.uid,
      message:
        "Käyttäjäprofiili on jo olemassa.",
    };
  }

  throw new HttpsError(
    "internal",
    "Käyttäjäprofiilin luominen epäonnistui.",
  );
}

},
);

// ============================================================
// 👤 GET USER PROFILE
// ============================================================

const getUserProfile = onCall(
{
region: "us-central1",
},
async (request) => {
try {
// 🔐 AUTHENTICATION
if (!request.auth) {
throw new HttpsError(
"unauthenticated",
"Kirjautuminen vaaditaan.",
);
}

  const uid = request.auth.uid;

  if (
    typeof uid !== "string" ||
    !uid.trim()
  ) {
    throw new HttpsError(
      "invalid-argument",
      "Käyttäjän UID puuttuu.",
    );
  }

  // 👤 USER REFERENCE
  const userRef = getUserRef(uid);

  // 🔍 READ PROFILE
  const snapshot = await userRef.get();

  if (!snapshot.exists) {
    throw new HttpsError(
      "not-found",
      "Käyttäjäprofiilia ei löytynyt.",
    );
  }

  const data = snapshot.data() || {};

  return {
    success: true,
    exists: true,
    uid,
    profile: data,
  };
} catch (error) {
  console.error(
    "getUserProfile error:",
    error,
  );

  if (error instanceof HttpsError) {
    throw error;
  }

  throw new HttpsError(
    "internal",
    "Käyttäjäprofiilin hakeminen epäonnistui.",
  );
}

},
);

// ============================================================
// 📦 EXPORTS
// ============================================================

module.exports = {
ensureUserProfile,
getUserProfile,
};