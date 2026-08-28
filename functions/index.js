const { onCall, onRequest, HttpsError } =
  require("firebase-functions/v2/https");

const { initializeApp } =
  require("firebase-admin/app");

const {
  getFirestore,
  FieldValue,
} = require("firebase-admin/firestore");

initializeApp();

const db = getFirestore();


// ============================================================
// DAILY CHECK-IN
// ============================================================

exports.dailyCheckIn = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError(
      "unauthenticated",
      "Käyttäjän täytyy olla kirjautunut."
    );
  }

  const uid = request.auth.uid;

  const userRef =
    db.collection("users").doc(uid);

  const now = new Date();

  const today =
    now.toISOString().substring(0, 10);

  const yesterdayDate = new Date(now);

  yesterdayDate.setUTCDate(
    yesterdayDate.getUTCDate() - 1
  );

  const yesterday =
    yesterdayDate.toISOString().substring(0, 10);


  const result =
    await db.runTransaction(
      async (transaction) => {

        const snapshot =
          await transaction.get(userRef);

        const data =
          snapshot.exists
            ? snapshot.data()
            : {};

        const oldBalance =
          Number(data.stlBalance || 0);

        const oldStreak =
          Number(data.streak || 0);

        const lastDaily =
          data.lastDaily || "";


        // Estetään saman päivän
        // toinen palkinto.
        if (lastDaily === today) {
          return {
            alreadyClaimed: true,
            balance: oldBalance,
            streak: oldStreak,
            reward: 0,
          };
        }


        let newStreak;

        if (lastDaily === yesterday) {
          newStreak = oldStreak + 1;
        } else {
          newStreak = 1;
        }


        if (newStreak > 7) {
          newStreak = 7;
        }


        const reward =
          newStreak >= 7
            ? 7
            : 3;

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
          {
            merge: true,
          }
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


// ============================================================
// ADMOB SSV CALLBACK
// ============================================================
//
// HUOM!
// Tämä endpoint vastaanottaa AdMobin
// Server-Side Verification -callbackin.
//
// Seuraavassa vaiheessa lisäämme Googlen
// signature-verifioinnin ennen palkinnon
// myöntämistä.
// ============================================================

exports.adMobReward = onRequest(
  async (request, response) => {

    try {

      // Vain GET-kutsut hyväksytään.
      if (request.method !== "GET") {
        response
          .status(405)
          .send("Method not allowed");

        return;
      }


      const userId =
        request.query.user_id;

      const transactionId =
        request.query.transaction_id;

      const rewardAmount =
        request.query.reward_amount;

      const signature =
        request.query.signature;

      const keyId =
        request.query.key_id;


      // Tarkistetaan pakolliset tiedot.
      if (
        !userId ||
        !transactionId ||
        !signature ||
        !keyId
      ) {

        response
          .status(400)
          .send(
            "Missing required SSV parameters"
          );

        return;
      }


      // TÄRKEÄÄ:
      //
      // Tässä vaiheessa emme vielä anna
      // STL-palkintoa ennen kuin Googlen
      // signature on vahvistettu.
      //
      // Seuraavassa vaiheessa lisäämme
      // varsinaisen kryptografisen
      // signature verification -tarkistuksen.


      response
        .status(200)
        .send(
          "SSV callback received"
        );


    } catch (error) {

      console.error(
        "AdMob SSV error:",
        error
      );

      response
        .status(500)
        .send(
          "Internal server error"
        );
    }
  }
);