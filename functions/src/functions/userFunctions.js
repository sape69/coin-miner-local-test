"use strict";

// ============================================================
// 🐱 STELLURIINI - USER FUNCTIONS
// ============================================================
//
// Stella User Profile.
//
// Flutter
//    ↓
// ensureUserProfile()
//    ↓
// Firebase Admin SDK
//    ↓
// users/{uid}
//
// TÄRKEÄÄ:
//
// Flutter EI kirjoita users-kokoelmaan suoraan.
//
// Firestore Security Rules sallivat asiakkaalle:
//
//    allow write: if false;
//
// Siksi uuden käyttäjän perusprofiili luodaan tämän
// Cloud Functionin kautta Admin SDK:lla.
//
// ============================================================


const {
  onCall,
  HttpsError,
} = require("firebase-functions/v2/https");

const {
  db,
  FieldValue,
} = require("../firebase/firebase");

const {
  getUserRef,
} = require("../utils/userUtils");


// ============================================================
// 🔢 DEFAULT USER PROFILE
// ============================================================
//
// Nämä ovat vain uuden käyttäjän turvalliset lähtöarvot.
//
// Referral-, mining-, Daily Hash Rate- ja Power Boost
// -tiedot voidaan lisätä myöhemmin omissa backend-toiminnoissaan.
//
// ============================================================

function buildDefaultUserProfile(
  request,
) {
  const email =
    typeof request.auth.token?.email === "string"
      ? request.auth.token.email
      : "";

  const displayName =
    typeof request.auth.token?.name === "string"
      ? request.auth.token.name
      : "";

  return {
    // ----------------------------------------------------------
    // 👤 BASIC USER
    // ----------------------------------------------------------

    email,

    displayName,

    username:
      displayName,

    // ----------------------------------------------------------
    // 💰 LEGACY / BASIC BALANCE
    // ----------------------------------------------------------

    stlBalance:
      0,

    // ----------------------------------------------------------
    // ⛏️ MINING
    // ----------------------------------------------------------

    miningBalance:
      0,

    miningHashRate:
      0,

    miningStartedAt:
      null,

    miningEndsAt:
      null,

    // ----------------------------------------------------------
    // ⚡ POWER BOOST
    // ----------------------------------------------------------

    adBoostHashRate:
      0,

    adBoostStartedAt:
      null,

    adBoostEndsAt:
      null,

    // ----------------------------------------------------------
    // 🎁 DAILY
    // ----------------------------------------------------------

    dailyHashRate:
      0,

    dailyStreak:
      0,

    streak:
      0,

    lastDailyDate:
      "",

    // ----------------------------------------------------------
    // 📺 ADS
    // ----------------------------------------------------------

    adsToday:
      0,

    adDate:
      "",

    lastAdTime:
      null,

    // ----------------------------------------------------------
    // 🔗 REFERRAL
    // ----------------------------------------------------------

    referralCode:
      "",

    referrerUid:
      "",

    referralCodeUsed:
      "",

    referralJoinedAt:
      null,

    referralCount:
      0,

    referralTotalEarned:
      0,

    // ----------------------------------------------------------
    // 🕐 TIMESTAMPS
    // ----------------------------------------------------------

    createdAt:
      FieldValue.serverTimestamp(),

    updatedAt:
      FieldValue.serverTimestamp(),
  };
}


// ============================================================
// 🔗 ENSURE USER PROFILE
// ============================================================
//
// Luo users/{uid}-dokumentin vain jos sitä ei vielä ole.
//
// Jos dokumentti on jo olemassa:
//
//    EI ylikirjoiteta mitään.
//
// Tämä on tärkeää referral-rekisteröinnissä:
//
// Firebase Auth
//      ↓
// ensureUserProfile
//      ↓
// users/{uid}
//      ↓
// applyReferralCode
//
// ============================================================

const ensureUserProfile =
  onCall(
    {
      region:
        "us-central1",
    },

    async (
      request,
    ) => {
      try {
        // ======================================================
        // 🔐 AUTHENTICATION
        // ======================================================

        if (!request.auth) {
          throw new HttpsError(
            "unauthenticated",
            "🐱 Kirjautuminen vaaditaan.",
          );
        }

        const uid =
          request.auth.uid;

        if (
          typeof uid !== "string" ||
          !uid.trim()
        ) {
          throw new HttpsError(
            "invalid-argument",
            "🐱 Käyttäjän UID puuttuu.",
          );
        }

        // ======================================================
        // 👤 USER REFERENCE
        // ======================================================

        const userRef =
          getUserRef(
            uid,
          );

        // ======================================================
        // 🔍 CHECK EXISTING PROFILE
        // ======================================================

        const snapshot =
          await userRef.get();

        // ------------------------------------------------------
        // PROFILE ALREADY EXISTS
        // ------------------------------------------------------

        if (snapshot.exists) {
          return {
            success:
              true,

            created:
              false,

            exists:
              true,

            uid,

            message:
              "🐱 Stella-käyttäjäprofiili on jo olemassa.",
          };
        }

        // ======================================================
        // 🆕 CREATE PROFILE
        // ======================================================

        const profile =
          buildDefaultUserProfile(
            request,
          );

        await userRef.create(
          profile,
        );

        // ======================================================
        // ✅ SUCCESS
        // ======================================================

        return {
          success:
            true,

          created:
            true,

          exists:
            true,

          uid,

          message:
            "🐱✨ Stella-käyttäjäprofiili luotiin onnistuneesti.",
        };
      } catch (
        error
      ) {
        // ======================================================
        // ❌ ERROR LOG
        // ======================================================

        console.error(
          "ensureUserProfile error:",
          error,
        );

        // ------------------------------------------------------
        // PRESERVE HttpsError
        // ------------------------------------------------------

        if (
          error instanceof
          HttpsError
        ) {
          throw error;
        }

        // ------------------------------------------------------
        // FIRESTORE ALREADY EXISTS
        // ------------------------------------------------------
        //
        // create() voi teoriassa saada ALREADY_EXISTS-tilanteen,
        // jos kaksi kutsua osuu samaan käyttäjään samanaikaisesti.
        //
        // Tässä tapauksessa profiili on kuitenkin olemassa,
        // joten sitä voidaan käsitellä onnistuneena tilanteena.
        //
        // ------------------------------------------------------

        if (
          error?.code ===
          6
        ) {
          return {
            success:
              true,

            created:
              false,

            exists:
              true,

            uid:
              request.auth.uid,

            message:
              "🐱 Stella-käyttäjäprofiili on jo olemassa.",
          };
        }

        // ------------------------------------------------------
        // GENERIC ERROR
        // ------------------------------------------------------

        throw new HttpsError(
          "internal",
          "🐱 Stella-käyttäjäprofiilin luominen epäonnistui.",
        );
      }
    },
  );


// ============================================================
// 📦 EXPORTS
// ============================================================

module.exports = {
  ensureUserProfile,
};