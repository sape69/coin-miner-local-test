const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");

initializeApp();

const db = getFirestore();

/**
 * Päivittäinen STL Check-in.
 *
 * Palkinto:
 * Päivät 1–6 = 3 STL
 * Päivä 7 = 7 STL
 */
exports.dailyCheckIn = onCall(async (request) => {
  // Käyttäjän täytyy olla kirjautunut.
  if (!request.auth) {
    throw new HttpsError(
      "unauthenticated",
      "Käyttäjän täytyy olla kirjautunut."
    );
  }

  const uid = request.auth.uid;
  const userRef = db.collection("users").doc(uid);

  // Käytetään palvelimen UTC-päivämäärää.
  const now = new Date();

  const today = now.toISOString().substring(0, 10);

  const yesterdayDate = new Date(now);
  yesterdayDate.setUTCDate(
    yesterdayDate.getUTCDate() - 1
  );

  const yesterday =
    yesterdayDate.toISOString().substring(0, 10);

  const result = await db.runTransaction(
    async (transaction) => {
      const snapshot = await transaction.get(userRef);

      const data = snapshot.exists
        ? snapshot.data()
        : {};

      const oldBalance =
        Number(data.stlBalance || 0);

      const oldStreak =
        Number(data.streak || 0);

      const lastDaily =
        data.lastDaily || "";

      // Estetään saman päivän toinen palkinto.
      if (lastDaily === today) {
        return {
          alreadyClaimed: true,
          balance: oldBalance,
          streak: oldStreak,
          reward: 0,
        };
      }

      let newStreak;

      // Jos käyttäjä haki palkinnon eilen,
      // streak jatkuu.
      if (lastDaily === yesterday) {
        newStreak = oldStreak + 1;
      } else {
        newStreak = 1;
      }

      // Maksimi 7 päivän streak.
      if (newStreak > 7) {
        newStreak = 7;
      }

      // Päivän palkinto.
      const reward =
        newStreak >= 7 ? 7 : 3;

      const newBalance =
        oldBalance + reward;

      transaction.set(
        userRef,
        {
          stlBalance: newBalance,
          streak: newStreak,
          lastDaily: today,

          updatedAt:
            FieldValue.serverTimestamp(),
        },
        { merge: true }
      );

      return {
        alreadyClaimed: false,
        balance: newBalance,
        streak: newStreak,
        reward: reward,
      };
    }
  );

  return result;
});