"use strict";

// ============================================================
// 🐱 STELLURIINI - ACCOUNT FUNCTIONS
// ============================================================
//
// Vastuu:
//
// - Käyttäjän oman tilin poistaminen
// - Firebase Authentication -käyttäjän poistaminen
// - users/{uid}-dokumentin poistaminen
// - users/{uid}-alikokoelmien poistaminen
// - käyttäjän admobRewards-dokumenttien poistaminen
//
// TÄRKEÄÄ:
//
// UID otetaan aina request.auth.uid-arvosta.
// Asiakas ei saa itse määrittää poistettavaa UID:tä.
//
// ============================================================

const {
onCall,
HttpsError,
} = require("firebase-functions/v2/https");

const {
auth,
db,
} = require("../firebase/firebase");

// ============================================================
// DELETE ACCOUNT
// ============================================================

const deleteAccount =
onCall(
{
region:
"us-central1",

  timeoutSeconds:
    540,
},
async (
  request,
) => {
  // ======================================================
  // AUTHENTICATION
  // ======================================================

  if (
    !request.auth ||
    !request.auth.uid
  ) {
    throw new HttpsError(
      "unauthenticated",
      "You must be signed in to delete your account.",
    );
  }

  // ======================================================
  // AUTHORITATIVE UID
  // ======================================================

  const uid =
    request.auth.uid;

  try {
    // ====================================================
    // USER DOCUMENT
    // ====================================================

    const userRef =
      db
        .collection("users")
        .doc(uid);

    // ====================================================
    // ADMOB REWARD DOCUMENTS
    // ====================================================
    //
    // admobRewards/{transactionId} ei sijaitse
    // users/{uid}-puussa.
    //
    // Siksi recursiveDelete(userRef) ei löydä niitä.
    //
    // adMobFunctions.js tallentaa UID:n reward-dokumenttiin:
    //
    // admobRewards/{transactionId}
    //   uid: uid
    //
    // Haetaan käyttäjän kaikki AdMob rewardit ennen
    // niiden poistamista.
    //
    // ====================================================

    const adMobRewardsSnapshot =
      await db
        .collection("admobRewards")
        .where(
          "uid",
          "==",
          uid,
        )
        .get();

    // ====================================================
    // DELETE ADMOB REWARDS
    // ====================================================
    //
    // Käytetään recursiveDeletea myös reward-dokumenteille,
    // jotta mahdolliset tulevat alikokoelmat eivät jää
    // vahingossa poistamatta.
    //
    // ====================================================

    if (
      !adMobRewardsSnapshot.empty
    ) {
      await Promise.all(
        adMobRewardsSnapshot.docs.map(
          async (
            rewardDoc,
          ) => {
            await db.recursiveDelete(
              rewardDoc.ref,
            );
          },
        ),
      );
    }

    // ====================================================
    // DELETE USER TREE
    // ====================================================
    //
    // Poistaa:
    //
    // users/{uid}
    // users/{uid}/transactions/*
    // sekä mahdolliset tulevat users/{uid}-alikokoelmat.
    //
    // ====================================================

    await db.recursiveDelete(
      userRef,
    );

    // ====================================================
    // DELETE FIREBASE AUTH USER
    // ====================================================

    await auth.deleteUser(
      uid,
    );

    // ====================================================
    // SUCCESS
    // ====================================================

    console.log(
      "🐱 Stelluriini account deleted successfully.",
      {
        uid,
        deletedAdMobRewards:
          adMobRewardsSnapshot.size,
      },
    );

    return {
      success:
        true,

      message:
        "Account deleted successfully.",
    };
  } catch (
    error
  ) {
    // ====================================================
    // ERROR LOG
    // ====================================================

    console.error(
      "❌ Stelluriini account deletion failed.",
      {
        uid,
        error:
          error?.message ||
          String(error),
      },
    );

    // ====================================================
    // PRESERVE EXPECTED HTTPS ERRORS
    // ====================================================

    if (
      error instanceof
      HttpsError
    ) {
      throw error;
    }

    // ====================================================
    // GENERIC ERROR
    // ====================================================

    throw new HttpsError(
      "internal",
      "Account deletion failed. Please try again.",
    );
  }
},

);

// ============================================================
// EXPORTS
// ============================================================

module.exports = {
deleteAccount,
};