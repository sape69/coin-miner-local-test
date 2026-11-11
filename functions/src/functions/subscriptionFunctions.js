"use strict";

// ============================================================
// 🐱 STELLURIINI - GOOGLE PLAY PREMIUM SUBSCRIPTIONS
// ============================================================

const crypto = require("crypto");

const {
  onCall,
  HttpsError,
} = require("firebase-functions/v2/https");

const {
  onSchedule,
} = require("firebase-functions/v2/scheduler");

const {
  Timestamp,
  FieldValue,
} = require("firebase-admin/firestore");

const {
  google,
} = require("googleapis");

const {
  db,
} = require("../firebase/firebase");

const {
  getUserRef,
} = require("../utils/userUtils");

// ============================================================
// CONFIGURATION
// ============================================================

const REGION = "us-central1";

const PACKAGE_NAME = "com.stelluriini.app";

const EXPECTED_BASE_PLAN_ID = "monthly";

const PREMIUM_PRODUCTS = Object.freeze({
  stelluriini_premium_monthly: "premium",
  stelluriini_premium_plus_monthly: "premium_plus",
});

const ALLOWED_SUBSCRIPTION_STATES = new Set([
  "SUBSCRIPTION_STATE_ACTIVE",
  "SUBSCRIPTION_STATE_IN_GRACE_PERIOD",
  "SUBSCRIPTION_STATE_CANCELED",
]);

const EXPIRY_BATCH_SIZE = 200;

let publisherClientPromise = null;

// ============================================================
// GOOGLE PLAY API CLIENT
// ============================================================

function getPublisherClient() {
  if (!publisherClientPromise) {
    publisherClientPromise = (async () => {
      const auth = new google.auth.GoogleAuth({
        scopes: [
          "https://www.googleapis.com/auth/androidpublisher",
        ],
      });

      return google.androidpublisher({
        version: "v3",
        auth,
      });
    })().catch((error) => {
      publisherClientPromise = null;
      throw error;
    });
  }

  return publisherClientPromise;
}

// ============================================================
// INPUT VALIDATION
// ============================================================

function validateRequestData(data) {
  const productId =
    typeof data?.productId === "string"
      ? data.productId.trim()
      : "";

  const purchaseToken =
    typeof data?.purchaseToken === "string"
      ? data.purchaseToken.trim()
      : "";

  if (
    !Object.prototype.hasOwnProperty.call(
      PREMIUM_PRODUCTS,
      productId
    )
  ) {
    throw new HttpsError(
      "invalid-argument",
      "Tuntematon Premium-tuote."
    );
  }

  if (
    purchaseToken.length < 20 ||
    purchaseToken.length > 8192
  ) {
    throw new HttpsError(
      "invalid-argument",
      "Google Play -ostotunniste puuttuu tai on virheellinen."
    );
  }

  return {
    productId,
    purchaseToken,
    tier: PREMIUM_PRODUCTS[productId],
  };
}

// ============================================================
// PURCHASE TOKEN HASH
// ============================================================

function hashPurchaseToken(purchaseToken) {
  return crypto
    .createHash("sha256")
    .update(purchaseToken, "utf8")
    .digest("hex");
}

// ============================================================
// GOOGLE PLAY SUBSCRIPTION LOOKUP
// ============================================================

async function getVerifiedSubscription(purchaseToken) {
  try {
    const publisher = await getPublisherClient();

    const response =
      await publisher.purchases.subscriptionsv2.get({
        packageName: PACKAGE_NAME,
        token: purchaseToken,
      });

    return response.data || {};
  } catch (error) {
    console.error(
      "Google Play subscription verification failed:",
      error?.response?.data || error?.message || error
    );

    throw new HttpsError(
      "failed-precondition",
      "Google Play -tilausta ei voitu varmentaa. Tarkista ostos ja yritä uudelleen."
    );
  }
}

// ============================================================
// SUBSCRIPTION VALIDATION
// ============================================================

function validateGoogleSubscription(
  subscription,
  expectedProductId
) {
  const state =
    typeof subscription.subscriptionState === "string"
      ? subscription.subscriptionState
      : "";

  if (!ALLOWED_SUBSCRIPTION_STATES.has(state)) {
    throw new HttpsError(
      "failed-precondition",
      "Google Play -tilaus ei ole aktiivinen."
    );
  }

  const lineItems = Array.isArray(subscription.lineItems)
    ? subscription.lineItems
    : [];

  const matchingItems = lineItems.filter((item) => {
    return (
      item?.productId === expectedProductId &&
      item?.offerDetails?.basePlanId === EXPECTED_BASE_PLAN_ID
    );
  });

  if (matchingItems.length === 0) {
    throw new HttpsError(
      "failed-precondition",
      "Ostettu tuote tai kuukausitilaus ei vastaa Premium-tuotetta."
    );
  }

  const now = Date.now();

  const validExpiries = matchingItems
    .map((item) => Date.parse(item.expiryTime || ""))
    .filter((expiry) => {
      return Number.isFinite(expiry) && expiry > now;
    });

  if (validExpiries.length === 0) {
    throw new HttpsError(
      "failed-precondition",
      "Premium-tilaus on päättynyt."
    );
  }

  return {
    state,
    expiryTime: Math.max(...validExpiries),
  };
}

// ============================================================
// SAVE VERIFIED SUBSCRIPTION
// ============================================================

async function saveVerifiedSubscription({
  uid,
  productId,
  tier,
  purchaseTokenHash,
  state,
  expiryTime,
}) {
  const userRef = getUserRef(uid);

  const tokenRef = db
    .collection("playPurchaseTokens")
    .doc(purchaseTokenHash);

  const expiryTimestamp =
    Timestamp.fromMillis(expiryTime);

  await db.runTransaction(async (transaction) => {
    const tokenSnapshot =
      await transaction.get(tokenRef);

    const userSnapshot =
      await transaction.get(userRef);

    if (!userSnapshot.exists) {
      throw new HttpsError(
        "not-found",
        "Käyttäjäprofiilia ei löytynyt."
      );
    }

    if (
      tokenSnapshot.exists &&
      tokenSnapshot.data()?.uid !== uid
    ) {
      throw new HttpsError(
        "permission-denied",
        "Tämä Google Play -ostos on jo liitetty toiseen käyttäjätiliin."
      );
    }

    // The incoming purchase has just been verified directly with
    // Google Play and its productId was matched against the actual
    // subscription line item. It is therefore the authoritative tier.
    //
    // Do not preserve a stale premium_plus value from the user document:
    // doing so can incorrectly grant Premium Plus benefits to a regular
    // Premium subscriber and can prevent premiumProductId from being saved.
    const updates = {
      premium: true,
      premiumVerified: true,
      premiumTier: tier,
      premiumProductId: productId,
      premiumExpiryTime: expiryTimestamp,
      premiumSubscriptionState: state,
      premiumPurchaseTokenHash: purchaseTokenHash,
      premiumUpdatedAt: FieldValue.serverTimestamp(),
    };

    transaction.set(
      userRef,
      updates,
      { merge: true }
    );

    transaction.set(
      tokenRef,
      {
        uid,
        productId,
        tier,
        expiryTime: expiryTimestamp,
        subscriptionState: state,
        status: "active",
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true }
    );
  });
}

// ============================================================
// VERIFY PLAY SUBSCRIPTION
// ============================================================

const verifyPlaySubscription = onCall(
  {
    region: REGION,
    timeoutSeconds: 30,
    memory: "256MiB",
  },
  async (request) => {
    if (!request.auth?.uid) {
      throw new HttpsError(
        "unauthenticated",
        "Kirjaudu sisään ennen Premium-tilauksen varmennusta."
      );
    }

    const uid = request.auth.uid;

    const {
      productId,
      purchaseToken,
      tier,
    } = validateRequestData(request.data);

    const purchaseTokenHash =
      hashPurchaseToken(purchaseToken);

    const subscription =
      await getVerifiedSubscription(purchaseToken);

    const verified =
      validateGoogleSubscription(
        subscription,
        productId
      );

    await saveVerifiedSubscription({
      uid,
      productId,
      tier,
      purchaseTokenHash,
      state: verified.state,
      expiryTime: verified.expiryTime,
    });

    return {
      success: true,
      verified: true,
      premium: true,
      tier,
      productId,
      expiryTime: new Date(
        verified.expiryTime
      ).toISOString(),
      subscriptionState: verified.state,
    };
  }
);

// ============================================================
// AUTOMATIC PREMIUM EXPIRY
// ============================================================
//
// Tarkistaa kerran tunnissa päättyneet tilaukset.
//
// Tämä tarkistus käyttää palvelimelle tallennettua
// tilauksen voimassaoloaikaa.
//
// Se ei yksin tunnista Google Playn uusimista.
// Uusiminen päivitetään uudella varmennuksella tai
// myöhemmin lisättävällä Google Play RTDN -integraatiolla.
//
// ============================================================

const expirePremiumSubscriptions = onSchedule(
  {
    region: REGION,
    schedule: "every 60 minutes",
    timeZone: "UTC",
    timeoutSeconds: 300,
    memory: "256MiB",
  },
  async () => {
    // Tämä lokimerkintä auttaa varmistamaan,
    // että ajastusfunktio käynnistyy.
    console.log("Premium expiry scheduler started.");

    const now = Timestamp.now();

    let lastDocument = null;
    let expiredCount = 0;

    while (true) {
      let query = db
        .collection("playPurchaseTokens")
        .where("expiryTime", "<=", now)
        .orderBy("expiryTime")
        .limit(EXPIRY_BATCH_SIZE);

      if (lastDocument) {
        query = query.startAfter(lastDocument);
      }

      const snapshot = await query.get();

      if (snapshot.empty) {
        break;
      }

      for (const tokenDocument of snapshot.docs) {
        const tokenData = tokenDocument.data();

        if (tokenData.status === "expired") {
          continue;
        }

        const uid = tokenData.uid;

        if (typeof uid !== "string" || !uid) {
          console.error(
            "Expired subscription has no valid UID:",
            tokenDocument.id
          );
          continue;
        }

        const userRef = getUserRef(uid);

        await db.runTransaction(async (transaction) => {
          const currentTokenSnapshot =
            await transaction.get(tokenDocument.ref);

          const userSnapshot =
            await transaction.get(userRef);

          if (!currentTokenSnapshot.exists) {
            return;
          }

          const currentToken =
            currentTokenSnapshot.data();

          if (currentToken.status === "expired") {
            return;
          }

          const currentExpiry =
            currentToken.expiryTime;

          const currentExpiryMs =
            currentExpiry &&
            typeof currentExpiry.toMillis === "function"
              ? currentExpiry.toMillis()
              : 0;

          if (currentExpiryMs > Date.now()) {
            return;
          }

          transaction.set(
            tokenDocument.ref,
            {
              status: "expired",
              processedAt: FieldValue.serverTimestamp(),
            },
            { merge: true }
          );

          if (!userSnapshot.exists) {
            return;
          }

          const userData = userSnapshot.data() || {};

          const currentUserTokenHash =
            userData.premiumPurchaseTokenHash;

          const userExpiry =
            userData.premiumExpiryTime;

          const userExpiryMs =
            userExpiry &&
            typeof userExpiry.toMillis === "function"
              ? userExpiry.toMillis()
              : 0;

          // Poistetaan Premium vain, jos vanhentunut
          // ostotunniste on käyttäjän nykyinen tilaus.
          if (
            currentUserTokenHash === tokenDocument.id &&
            userExpiryMs <= Date.now()
          ) {
            transaction.set(
              userRef,
              {
                premium: false,
                premiumVerified: false,
                premiumTier: FieldValue.delete(),
                premiumProductId: FieldValue.delete(),
                premiumExpiryTime: FieldValue.delete(),
                premiumSubscriptionState: "EXPIRED",
                premiumPurchaseTokenHash: FieldValue.delete(),
                premiumUpdatedAt: FieldValue.serverTimestamp(),
              },
              { merge: true }
            );
          }
        });

        expiredCount++;
      }

      lastDocument =
        snapshot.docs[snapshot.docs.length - 1];

      if (snapshot.size < EXPIRY_BATCH_SIZE) {
        break;
      }
    }

    console.log(
      `Premium expiry check completed. Processed: ${expiredCount}`
    );
  }
);

// ============================================================
// EXPORTS
// ============================================================

module.exports = {
  verifyPlaySubscription,
  expirePremiumSubscriptions,
};
