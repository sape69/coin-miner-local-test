"use strict";

// ============================================================
// 🐱 STELLURIINI - ACCOUNT FUNCTIONS
// ============================================================
//
// Account management.
//
// Delete Account:
//
// - User must be authenticated.
// - UID always comes from request.auth.uid.
// - All Firestore data under users/{uid} is deleted recursively.
// - Firebase Authentication account is deleted.
//
// IMPORTANT:
//
// The client must NEVER provide a UID for account deletion.
//
// ============================================================

const {
  onCall,
  HttpsError,
} = require(
  "firebase-functions/v2/https",
);

const {
  auth,
  db,
} = require(
  "../firebase/firebase",
);


// ============================================================
// 🗑️ DELETE ACCOUNT
// ============================================================

const deleteAccount = onCall(
  {
    region: "us-central1",
    timeoutSeconds: 540,
  },

  async (request) => {

    // ----------------------------------------------------------
    // 🔐 AUTHENTICATION CHECK
    // ----------------------------------------------------------

    if (!request.auth) {
      throw new HttpsError(
        "unauthenticated",
        "You must be signed in to delete your account.",
      );
    }


    // ----------------------------------------------------------
    // 👤 CURRENT USER UID
    // ----------------------------------------------------------
    //
    // NEVER accept a UID from request.data.
    //
    // The authenticated Firebase user is the only account
    // that this function is allowed to delete.
    //
    // ----------------------------------------------------------

    const uid =
      request.auth.uid;


    try {

      // --------------------------------------------------------
      // 🗑️ DELETE USER FIRESTORE TREE
      // --------------------------------------------------------
      //
      // Current Stelluriini structure:
      //
      // users/{uid}
      // users/{uid}/transactions/{transactionId}
      //
      // recursiveDelete() removes the user document together
      // with all documents in its subcollections.
      //
      // --------------------------------------------------------

      const userRef =
        db
          .collection("users")
          .doc(uid);

      await db.recursiveDelete(
        userRef,
      );


      // --------------------------------------------------------
      // 🔥 DELETE FIREBASE AUTH ACCOUNT
      // --------------------------------------------------------
      //
      // The UID comes directly from the authenticated request.
      //
      // The client cannot choose another UID.
      //
      // --------------------------------------------------------

      await auth.deleteUser(
        uid,
      );


      // --------------------------------------------------------
      // ✅ SUCCESS
      // --------------------------------------------------------

      return {
        success: true,

        message:
          "Account deleted successfully.",
      };

    } catch (error) {

      // --------------------------------------------------------
      // ❌ ERROR
      // --------------------------------------------------------

      console.error(
        "deleteAccount failed:",
        error,
      );

      throw new HttpsError(
        "internal",
        "Account deletion failed. Please try again.",
      );
    }
  },
);


// ============================================================
// 📤 EXPORT
// ============================================================

module.exports = {
  deleteAccount,
};