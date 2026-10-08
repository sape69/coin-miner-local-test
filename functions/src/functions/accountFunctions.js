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
// - käyttäjän referralCode-dokumentin poistaminen
// - käyttäjän referral-suhteiden poistaminen
// - käyttäjään liittyvien referral-viittausten siivoaminen
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
  FieldValue,
} = require("../firebase/firebase");

// ============================================================
// REFERRAL CLEANUP
// ============================================================
//
// Referral-data sijaitsee erillisissä kokoelmissa:
//
// referralCodes/{CODE}
// referrals/{referredUid}
//
// Siksi users/{uid}-dokumentin recursiveDelete ei poista
// näitä tietoja.
//
// Tilin poistamisen yhteydessä:
//
// 1. poistetaan käyttäjän oma referralCode
// 2. poistetaan käyttäjän referral-suhde
// 3. poistetaan kaikki suhteet, joissa käyttäjä on kutsuja
// 4. poistetaan kutsuttujen käyttäjien vanhat viittaukset
// 5. korjataan kutsujan referralCount
//
// ============================================================

async function cleanupReferralData(
  uid,
) {
  const safeUid =
    typeof uid === "string"
      ? uid.trim()
      : "";

  if (!safeUid) {
    return {
      deletedReferralRelationships:
        0,

      deletedReferralCodes:
        0,

      cleanedReferredUsers:
        0,
    };
  }

  let deletedReferralRelationships =
    0;

  let deletedReferralCodes =
    0;

  let cleanedReferredUsers =
    0;

  // ==========================================================
  // 1. FIND USER'S OWN REFERRAL RELATIONSHIPS
  // ==========================================================
  //
  // Normaalisti referrals/{referredUid} käyttää referred UID:tä
  // dokumentin ID:nä.
  //
  // Haetaan kuitenkin queryllä kaikki mahdolliset vanhat
  // duplicate-dokumentitkin.
  //
  // ==========================================================

  const referredRelationshipSnapshot =
    await db
      .collection("referrals")
      .where(
        "referredUid",
        "==",
        safeUid,
      )
      .get();

  // ==========================================================
  // 2. FIND RELATIONSHIPS WHERE USER IS REFERRER
  // ==========================================================

  const referrerRelationshipSnapshot =
    await db
      .collection("referrals")
      .where(
        "referrerUid",
        "==",
        safeUid,
      )
      .get();

  // ==========================================================
  // 3. GROUP REFERRER COUNTS
  // ==========================================================
  //
  // Jos käyttäjällä on referral-suhde kutsujan kautta, kutsujan
  // referralCount pienenee, kun käyttäjä poistetaan.
  //
  // Jos vanhoja duplicate-suhteita löytyy, huomioidaan nekin.
  //
  // ==========================================================

  const referrerDecrements =
    new Map();

  for (
    const relationshipDocument
      of referredRelationshipSnapshot.docs
  ) {
    const relationshipData =
      relationshipDocument.data() ||
      {};

    const referrerUid =
      typeof relationshipData.referrerUid ===
          "string"
        ? relationshipData.referrerUid.trim()
        : "";

    if (
      !referrerUid ||
      referrerUid === safeUid
    ) {
      continue;
    }

    const current =
      referrerDecrements.get(
        referrerUid,
      ) || 0;

    referrerDecrements.set(
      referrerUid,
      current + 1,
    );
  }

  // ==========================================================
  // 4. DELETE USER'S OWN REFERRAL RELATIONSHIPS
  // ==========================================================

  for (
    const relationshipDocument
      of referredRelationshipSnapshot.docs
  ) {
    await db.recursiveDelete(
      relationshipDocument.ref,
    );

    deletedReferralRelationships +=
      1;
  }

  // ==========================================================
  // 5. CLEAN USERS REFERRED BY THIS USER
  // ==========================================================
  //
  // Jos poistettava käyttäjä oli kutsuja, muiden käyttäjien
  // users/{uid}-dokumenteissa voi olla:
  //
  // referrerUid
  // referralCodeUsed
  // referralJoinedAt
  //
  // Näitä ei jätetä osoittamaan poistettuun käyttäjään.
  //
  // ==========================================================

  for (
    const relationshipDocument
      of referrerRelationshipSnapshot.docs
  ) {
    const relationshipData =
      relationshipDocument.data() ||
      {};

    const referredUid =
      typeof relationshipData.referredUid ===
          "string"
        ? relationshipData.referredUid.trim()
        : relationshipDocument.id;

    if (
      !referredUid ||
      referredUid === safeUid
    ) {
      continue;
    }

    const referredUserRef =
      db
        .collection("users")
        .doc(referredUid);

    const referredUserSnapshot =
      await referredUserRef.get();

    if (
      referredUserSnapshot.exists
    ) {
      await referredUserRef.update({
        referrerUid:
          FieldValue.delete(),

        referralCodeUsed:
          FieldValue.delete(),

        referralJoinedAt:
          FieldValue.delete(),

        updatedAt:
          FieldValue.serverTimestamp(),
      });

      cleanedReferredUsers +=
        1;
    }

    await db.recursiveDelete(
      relationshipDocument.ref,
    );

    deletedReferralRelationships +=
      1;
  }

  // ==========================================================
  // 6. CORRECT REFERRER COUNTS
  // ==========================================================

  for (
    const [
      referrerUid,
      decrement,
    ] of referrerDecrements.entries()
  ) {
    const referrerRef =
      db
        .collection("users")
        .doc(referrerUid);

    const referrerSnapshot =
      await referrerRef.get();

    if (
      !referrerSnapshot.exists
    ) {
      continue;
    }

    const referrerData =
      referrerSnapshot.data() || {};

    const currentCount =
      Number(
        referrerData.referralCount,
      );

    const safeCurrentCount =
      Number.isFinite(
        currentCount,
      ) &&
          currentCount >= 0
        ? Math.floor(
            currentCount,
          )
        : 0;

    const newCount =
      Math.max(
        0,
        safeCurrentCount -
          decrement,
      );

    await referrerRef.update({
      referralCount:
        newCount,

      updatedAt:
        FieldValue.serverTimestamp(),
    });
  }

  // ==========================================================
  // 7. DELETE USER'S REFERRAL CODE
  // ==========================================================

  const referralCodeSnapshot =
    await db
      .collection("referralCodes")
      .where(
        "uid",
        "==",
        safeUid,
      )
      .get();

  for (
    const referralCodeDocument
      of referralCodeSnapshot.docs
  ) {
    await db.recursiveDelete(
      referralCodeDocument.ref,
    );

    deletedReferralCodes +=
      1;
  }

  return {
    deletedReferralRelationships,

    deletedReferralCodes,

    cleanedReferredUsers,
  };
}

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
        // DELETE REFERRAL DATA
        // ====================================================
        //
        // Tämä on tärkeä erityisesti testauksessa.
        //
        // Kun testitili poistetaan ja tehdään uusi tili,
        // vanha referral-suhde ei jää Firestoreen.
        //
        // ====================================================

        const referralCleanup =
          await cleanupReferralData(
            uid,
          );

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

            deletedReferralRelationships:
              referralCleanup
                .deletedReferralRelationships,

            deletedReferralCodes:
              referralCleanup
                .deletedReferralCodes,

            cleanedReferredUsers:
              referralCleanup
                .cleanedReferredUsers,
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