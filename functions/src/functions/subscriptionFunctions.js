
"use strict";

// ============================================================
// 🐱 STELLURIINI - GOOGLE PLAY SUBSCRIPTION VERIFICATION
// ============================================================

const crypto = require("crypto");

const {
  onCall,
  HttpsError,
} = require("firebase-functions/v2/https");

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

const PREMIUM_PRODUCTS = Object.freeze({
  stelluriini_premium_monthly: "premium",
  stelluriini_premium_plus_monthly: "premium_plus",
});

const ALLOWED_SUBSCRIPTION_STATES = new Set([
  "SUBSCRIPTION_STATE_ACTIVE",
  "SUBSCRIPTION_STATE_IN_GRACE_PERIOD",
  "SUBSCRIPTION_STATE_CANCELED",
]);

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

  if (!Object.prototype.hasOwnProperty.call(
    PREMIUM_PRODUCTS,
    productId
  )) {
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

  const matchingItems = lineItems.filter(
    (item) => item?.productId === expectedProductId
  );

  if (matchingItems.length === 0) {
    throw new HttpsError(
      "failed-precondition",
      "Ostettu tuote ei vastaa pyydettyä Premium-tuotetta."
    );
  }

  const now = Date.now();

  const validExpiries = matchingItems
    .map((item) => Date.parse(item.expiryTime || ""))
    .filter(
      (expiry) =>
        Number.isFinite(expiry) &&
        expiry > now
    );

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
// FIRESTORE ENTITLEMENT UPDATE
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

    const userData = userSnapshot.data() || {};

    const currentExpiry = userData.premiumExpiryTime;

    const currentExpiryMs =
      currentExpiry &&
      typeof currentExpiry.toMillis === "function"
        ? currentExpiry.toMillis()
        : 0;

    const currentTier = userData.premiumTier || "";

    const currentIsPlus =
      currentTier === "premium_plus" &&
      currentExpiryMs > Date.now();

    const incomingIsPlus =
      tier === "premium_plus";

    const shouldKeepCurrentPlus =
      currentIsPlus && !incomingIsPlus;

    const updates = {
      premium: true,
      premiumVerified: true,
      premiumUpdatedAt: FieldValue.serverTimestamp(),
    };

    if (!shouldKeepCurrentPlus) {
      updates.premiumTier = tier;
      updates.premiumProductId = productId;
      updates.premiumExpiryTime = expiryTimestamp;
      updates.premiumSubscriptionState = state;
      updates.premiumPurchaseTokenHash = purchaseTokenHash;
    }

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
// EXPORTS
// ============================================================

module.exports = {
  verifyPlaySubscription,
};
