"use strict";

// ============================================================
// 🐱 STELLURIINI - ADMOB FUNCTIONS
// ============================================================
//
// Vastuu:
//
// 📺 Vastaanottaa AdMob Rewarded SSV callbackin
// 🔐 Käyttää admobService.js:n kryptografista varmennusta
// 🆔 Käyttää vain varmennettua UID:tä
// 🎯 Tunnistaa reward purposen
// 💾 Tallentaa varmennetun AdMob-tapahtuman
// 🛡️ Estää transaction_id:n uudelleenkäytön
// 📜 Säilyttää audit-historian johdonmukaisena
//
// TÄMÄ TIEDOSTO EI:
//
// ❌ käynnistä Mining Startia
// ❌ aktivoi Power Boostia
// ❌ lisää STL-saldoa
// ❌ muuta miningBalancea
// ❌ muuta adsToday-arvoa
// ❌ muuta cooldownia
// ❌ muuta mining-tilaa
//
// ============================================================


// ============================================================
// 🔥 FIREBASE FUNCTIONS
// ============================================================

const {
  onRequest,
} = require(
  "firebase-functions/v2/https",
);


// ============================================================
// 🔥 FIREBASE
// ============================================================

const {
  db,
  FieldValue,
} = require(
  "../firebase/firebase",
);


// ============================================================
// ⚙️ ADMOB SERVICE
// ============================================================

const {
  verifyAdMobCallback,

  getExpectedAdMobConfig,

  validateTransactionId,

  validateUid,

  validateRewardPurpose,

} = require(
  "../services/admobService",
);


// ============================================================
// 👤 USER UTILITIES
// ============================================================

const {
  getHistoryCollection,
  getAdMobRewardRef,
} = require(
  "../utils/userUtils",
);


// ============================================================
// 🛡️ ERROR HELPERS
// ============================================================

function createError(
  code,
  message,
) {
  const error =
    new Error(
      message,
    );

  error.code =
    code;

  return error;
}


// ============================================================
// 🔐 NORMALIZE STRING
// ============================================================

function normalizeString(
  value,
) {
  if (
    typeof value !==
    "string"
  ) {
    return "";
  }

  return value.trim();
}


// ============================================================
// 🛡️ CLIENT VALIDATION ERRORS
// ============================================================
//
// Näissä tapauksissa callback on vastaanotettu,
// mutta sitä ei pidä yrittää uudelleen serverivirheenä.
//
// ============================================================

const CLIENT_VALIDATION_ERROR_CODES =
  new Set([
    "ADMOB_INVALID_SIGNATURE",
    "ADMOB_INVALID_KEY_ID",
    "ADMOB_REQUEST_MISSING",
    "ADMOB_QUERY_STRING_MISSING",
    "ADMOB_QUERY_STRING_TOO_LARGE",
    "ADMOB_INVALID_UID",
    "ADMOB_INVALID_REWARD_PURPOSE",
    "ADMOB_INVALID_TRANSACTION_ID",
    "ADMOB_INVALID_TIMESTAMP",
    "ADMOB_INVALID_AD_NETWORK",
    "ADMOB_REQUIRED_PARAMETER_MISSING",
    "ADMOB_VERIFIED_DATA_MISSING",
    "ADMOB_USER_ID_MISMATCH",
    "ADMOB_CUSTOM_DATA_MISSING",
    "ADMOB_CUSTOM_DATA_INVALID",
    "ADMOB_CUSTOM_DATA_INVALID_ENCODING",
    "ADMOB_CUSTOM_DATA_MISMATCH",
    "ADMOB_INVALID_AD_UNIT",
    "ADMOB_INVALID_REWARD_ITEM",
    "ADMOB_INVALID_REWARD_AMOUNT",
    "ADMOB_TRANSACTION_CONFLICT",
    "ADMOB_INVALID_REWARD_CONFIGURATION",
  ]);


// ============================================================
// 🔄 SERVER / RETRY ERRORS
// ============================================================

const SERVER_RETRY_ERROR_CODES =
  new Set([
    "ADMOB_PUBLIC_KEY_FETCH_ERROR",
    "ADMOB_PUBLIC_KEY_HTTP_ERROR",
    "ADMOB_PUBLIC_KEY_JSON_ERROR",
    "ADMOB_PUBLIC_KEY_RESPONSE_INVALID",
    "ADMOB_PUBLIC_KEYS_EMPTY",
    "ADMOB_CRYPTO_VERIFICATION_ERROR",
    "ADMOB_REWARD_REFERENCE_ERROR",
    "ADMOB_HISTORY_REFERENCE_ERROR",
    "ADMOB_AUDIT_CONSISTENCY_ERROR",
  ]);


// ============================================================
// 🎯 VALIDATE VERIFIED AD DATA
// ============================================================
//
// admobService.js tekee varsinaisen SSV-validoinnin.
//
// Tämä funktio toimii kevyenä defense-in-depth -kerroksena
// ennen Firestore-kirjoitusta.
//
// ============================================================

function validateVerifiedAdData(
  verifiedAd,
) {
  if (
    !verifiedAd ||
    typeof verifiedAd !==
      "object" ||
    verifiedAd.verified !==
      true
  ) {
    throw createError(
      "ADMOB_VERIFIED_DATA_MISSING",
      "AdMob data is not cryptographically verified.",
    );
  }


  const uid =
    validateUid(
      verifiedAd.uid,
    );

  if (
    !uid
  ) {
    throw createError(
      "ADMOB_INVALID_UID",
      "Verified AdMob UID is invalid.",
    );
  }


  const rewardPurpose =
    validateRewardPurpose(
      verifiedAd.rewardPurpose,
    );

  if (
    !rewardPurpose
  ) {
    throw createError(
      "ADMOB_INVALID_REWARD_PURPOSE",
      "Verified AdMob reward purpose is invalid.",
    );
  }


  const transactionId =
    validateTransactionId(
      verifiedAd.transactionId,
    );

  if (
    !transactionId
  ) {
    throw createError(
      "ADMOB_INVALID_TRANSACTION_ID",
      "Verified AdMob transaction_id is invalid.",
    );
  }


  const expectedConfig =
    getExpectedAdMobConfig(
      rewardPurpose,
    );


  const rewardAmount =
    Number(
      verifiedAd.rewardAmount,
    );

  if (
    !Number.isSafeInteger(
      rewardAmount,
    ) ||
    rewardAmount !==
      Number(
        expectedConfig.rewardAmount,
      )
  ) {
    throw createError(
      "ADMOB_INVALID_REWARD_AMOUNT",
      "Verified reward amount does not match server configuration.",
    );
  }


  const rewardItem =
    normalizeString(
      verifiedAd.rewardItem,
    );

  if (
    rewardItem !==
    normalizeString(
      expectedConfig.rewardItem,
    )
  ) {
    throw createError(
      "ADMOB_INVALID_REWARD_ITEM",
      "Verified reward item does not match server configuration.",
    );
  }


  const adUnit =
    normalizeString(
      verifiedAd.adUnit,
    );

  if (
    adUnit !==
    normalizeString(
      expectedConfig.adUnit,
    )
  ) {
    throw createError(
      "ADMOB_INVALID_AD_UNIT",
      "Verified ad unit does not match server configuration.",
    );
  }


  const adNetwork =
    normalizeString(
      verifiedAd.adNetwork,
    );

  if (
    !adNetwork
  ) {
    throw createError(
      "ADMOB_INVALID_AD_NETWORK",
      "Verified ad network is missing.",
    );
  }


  const timestamp =
    Number(
      verifiedAd.timestamp,
    );

  if (
    !Number.isSafeInteger(
      timestamp,
    ) ||
    timestamp <=
      0
  ) {
    throw createError(
      "ADMOB_INVALID_TIMESTAMP",
      "Verified timestamp is invalid.",
    );
  }


  const keyId =
    normalizeString(
      verifiedAd.keyId,
    );

  const signature =
    normalizeString(
      verifiedAd.signature,
    );

  if (
    !keyId
  ) {
    throw createError(
      "ADMOB_INVALID_KEY_ID",
      "Verified key_id is missing.",
    );
  }

  if (
    !signature
  ) {
    throw createError(
      "ADMOB_INVALID_SIGNATURE",
      "Verified signature is missing.",
    );
  }


  const customData =
    normalizeString(
      verifiedAd.customData,
    );

  const expectedCustomData =
    `${uid}:${rewardPurpose}`;

  if (
    customData !==
    expectedCustomData
  ) {
    throw createError(
      "ADMOB_CUSTOM_DATA_MISMATCH",
      "Verified custom_data does not match UID and reward purpose.",
    );
  }


  const userId =
    normalizeString(
      verifiedAd.userId,
    );

  if (
    userId &&
    userId !==
      uid
  ) {
    throw createError(
      "ADMOB_USER_ID_MISMATCH",
      "AdMob user_id does not match verified UID.",
    );
  }


  return {
    uid,

    rewardPurpose,

    transactionId,

    rewardAmount,

    rewardItem,

    adUnit,

    adNetwork,

    timestamp,

    keyId,

    signature,

    customData,

    userId,
  };
}


// ============================================================
// 📜 COMPARE STORED REWARD
// ============================================================

function isSameVerifiedReward(
  existingData,
  validatedAd,
) {
  if (
    !existingData ||
    !validatedAd
  ) {
    return false;
  }

  return (
    normalizeString(
      existingData.uid,
    ) ===
      validatedAd.uid &&

    normalizeString(
      existingData.rewardPurpose,
    ) ===
      validatedAd.rewardPurpose &&

    normalizeString(
      existingData.transactionId,
    ) ===
      validatedAd.transactionId &&

    normalizeString(
      existingData.adUnit,
    ) ===
      validatedAd.adUnit &&

    normalizeString(
      existingData.adNetwork,
    ) ===
      validatedAd.adNetwork &&

    Number(
      existingData.rewardAmount,
    ) ===
      validatedAd.rewardAmount &&

    normalizeString(
      existingData.rewardItem,
    ) ===
      validatedAd.rewardItem &&

    Number(
      existingData.timestamp,
    ) ===
      validatedAd.timestamp &&

    normalizeString(
      existingData.keyId,
    ) ===
      validatedAd.keyId &&

    normalizeString(
      existingData.signature,
    ) ===
      validatedAd.signature &&

    normalizeString(
      existingData.customData,
    ) ===
      validatedAd.customData &&

    normalizeString(
      existingData.userId,
    ) ===
      validatedAd.userId
  );
}


// ============================================================
// 📜 COMPARE STORED AUDIT HISTORY
// ============================================================

function isSameVerifiedHistory(
  existingData,
  validatedAd,
) {
  if (
    !existingData ||
    !validatedAd
  ) {
    return false;
  }

  return (
    normalizeString(
      existingData.uid,
    ) ===
      validatedAd.uid &&

    normalizeString(
      existingData.type,
    ) ===
      "admob_verified" &&

    normalizeString(
      existingData.rewardType,
    ) ===
      "admob" &&

    normalizeString(
      existingData.rewardPurpose,
    ) ===
      validatedAd.rewardPurpose &&

    normalizeString(
      existingData.adMobTransactionId,
    ) ===
      validatedAd.transactionId &&

    normalizeString(
      existingData.transactionId,
    ) ===
      validatedAd.transactionId &&

    normalizeString(
      existingData.adNetwork,
    ) ===
      validatedAd.adNetwork &&

    normalizeString(
      existingData.adUnit,
    ) ===
      validatedAd.adUnit &&

    Number(
      existingData.rewardAmount,
    ) ===
      validatedAd.rewardAmount &&

    normalizeString(
      existingData.rewardItem,
    ) ===
      validatedAd.rewardItem &&

    Number(
      existingData.amount,
    ) ===
      0 &&

    Number(
      existingData.timestamp,
    ) ===
      validatedAd.timestamp &&

    normalizeString(
      existingData.keyId,
    ) ===
      validatedAd.keyId &&

    normalizeString(
      existingData.signature,
    ) ===
      validatedAd.signature &&

    normalizeString(
      existingData.customData,
    ) ===
      validatedAd.customData &&

    normalizeString(
      existingData.userId,
    ) ===
      validatedAd.userId
  );
}


// ============================================================
// 💾 SAVE VERIFIED ADMOB REWARD
// ============================================================

async function saveVerifiedAdMobReward(
  verifiedAd,
) {
  const validatedAd =
    validateVerifiedAdData(
      verifiedAd,
    );


  const {
    uid,
    rewardPurpose,
    transactionId,
    rewardAmount,
    rewardItem,
    adUnit,
    adNetwork,
    timestamp,
    keyId,
    signature,
    customData,
    userId,
  } =
    validatedAd;


  // ==========================================================
  // 🔗 FIRESTORE REFERENCES
  // ==========================================================

  const rewardRef =
    getAdMobRewardRef(
      transactionId,
    );

  if (
    !rewardRef
  ) {
    throw createError(
      "ADMOB_REWARD_REFERENCE_ERROR",
      "Unable to create AdMob reward reference.",
    );
  }


  const historyCollection =
    getHistoryCollection(
      uid,
    );

  if (
    !historyCollection ||
    typeof historyCollection.doc !==
      "function"
  ) {
    throw createError(
      "ADMOB_HISTORY_REFERENCE_ERROR",
      "Unable to create user history collection.",
    );
  }


  const historyRef =
    historyCollection.doc(
      `admob_${transactionId}`,
    );


  // ==========================================================
  // 🔐 FIRESTORE TRANSACTION
  // ==========================================================

  return db.runTransaction(
    async (
      transaction,
    ) => {

      // ======================================================
      // ALL READS FIRST
      // ======================================================

      const rewardSnapshot =
        await transaction.get(
          rewardRef,
        );

      const historySnapshot =
        await transaction.get(
          historyRef,
        );


      // ======================================================
      // EXISTING REWARD
      // ======================================================

      if (
        rewardSnapshot.exists
      ) {
        const existingData =
          rewardSnapshot.data() ||
          {};


        if (
          !isSameVerifiedReward(
            existingData,
            validatedAd,
          )
        ) {
          throw createError(
            "ADMOB_TRANSACTION_CONFLICT",
            "AdMob transaction_id is already associated with different reward data.",
          );
        }


        // ====================================================
        // AUDIT MUST MATCH
        // ====================================================

        if (
          !historySnapshot.exists ||
          !isSameVerifiedHistory(
            historySnapshot.data() ||
            {},
            validatedAd,
          )
        ) {
          throw createError(
            "ADMOB_AUDIT_CONSISTENCY_ERROR",
            "AdMob reward and audit history are inconsistent.",
          );
        }


        console.log(
          "🐱 AdMob transaction already processed.",
          {
            uid,

            transactionId,

            rewardPurpose,

            duplicate:
              true,
          },
        );


        return {
          success:
            true,

          verified:
            true,

          recorded:
            true,

          rewarded:
            false,

          duplicate:
            true,

          transactionId,

          rewardPurpose,

          message:
            "🐱📺 Tämä AdMob-tapahtuma on jo vastaanotettu.",
        };
      }


      // ======================================================
      // HISTORY WITHOUT REWARD
      // ======================================================

      if (
        historySnapshot.exists
      ) {
        throw createError(
          "ADMOB_AUDIT_CONSISTENCY_ERROR",
          "AdMob audit history exists without the corresponding reward document.",
        );
      }


      // ======================================================
      // 💾 VERIFIED REWARD
      // ======================================================

      transaction.create(
        rewardRef,
        {
          uid,

          transactionId,

          rewardType:
            "admob",

          rewardPurpose,

          rewardAmount,

          rewardItem,

          adNetwork,

          adUnit,

          timestamp,

          keyId,

          signature,

          customData,

          userId,

          miningClaimed:
            false,

          miningClaimedAt:
            null,

          miningClaimedBy:
            null,

          miningStartClaimed:
            false,

          miningStartClaimedAt:
            null,

          miningStartClaimedBy:
            null,

          powerBoostClaimed:
            false,

          powerBoostClaimedAt:
            null,

          powerBoostClaimedBy:
            null,

          powerBoostTransactionId:
            null,

          createdAt:
            FieldValue.serverTimestamp(),

          updatedAt:
            FieldValue.serverTimestamp(),
        },
      );


      // ======================================================
      // 📜 AUDIT HISTORY
      // ======================================================

      transaction.create(
        historyRef,
        {
          uid,

          type:
            "admob_verified",

          title:
            rewardPurpose ===
            "power_boost"
              ? "Stella Power Boost Ad Verified 🐱📺⚡"
              : "Stella Mining Start Ad Verified 🐱📺⛏️",

          amount:
            0,

          rewardType:
            "admob",

          rewardPurpose,

          adMobTransactionId:
            transactionId,

          transactionId,

          adNetwork,

          adUnit,

          rewardAmount,

          rewardItem,

          timestamp,

          keyId,

          signature,

          customData,

          userId,

          createdAt:
            FieldValue.serverTimestamp(),
        },
      );


      // ======================================================
      // 📤 RESULT
      // ======================================================

      return {
        success:
          true,

        verified:
          true,

        recorded:
          true,

        rewarded:
          false,

        duplicate:
          false,

        transactionId,

        rewardPurpose,

        rewardAmount,

        rewardItem,

        message:
          rewardPurpose ===
          "power_boost"
            ? "🐱📺 Power Boost -mainos vahvistettu ja tapahtuma tallennettu."
            : "🐱📺 Mining Start -mainos vahvistettu ja tapahtuma tallennettu.",
      };
    },
  );
}


// ============================================================
// 📺 ADMOB REWARD CALLBACK
// ============================================================

const adMobReward =
  onRequest(
    {
      region:
        "us-central1",
    },

    async (
      req,
      res,
    ) => {
      let ssvVerified =
        false;

      try {

        // ====================================================
        // 🔐 METHOD
        // ====================================================

        if (
          req.method ===
          "HEAD"
        ) {
          res.status(
            200,
          ).end();

          return;
        }


        if (
          req.method !==
          "GET"
        ) {
          res.status(
            405,
          ).json({
            success:
              false,

            verified:
              false,

            recorded:
              false,

            rewarded:
              false,

            error:
              "Method not allowed.",
          });

          return;
        }


        // ====================================================
        // 🔎 QUERY
        // ====================================================

        const query =
          req.query ||
          {};

        const queryKeys =
          Object.keys(
            query,
          );


        // ====================================================
        // 🩺 HEALTH CHECK
        // ====================================================

        if (
          queryKeys.length ===
          0
        ) {
          console.log(
            "🐱 AdMob SSV endpoint health check.",
          );

          res.status(
            200,
          ).json({
            success:
              true,

            verified:
              false,

            recorded:
              false,

            rewarded:
              false,

            endpoint:
              "adMobReward",

            message:
              "Stelluriini AdMob SSV endpoint is reachable.",
          });

          return;
        }


        // ====================================================
        // 🔐 VERIFY SSV
        // ====================================================

        console.log(
          "🐱 AdMob SSV callback received.",
        );


        const verifiedAd =
          await verifyAdMobCallback(
            req,
          );


        if (
          !verifiedAd ||
          verifiedAd.verified !==
            true
        ) {
          throw createError(
            "ADMOB_INVALID_SIGNATURE",
            "Invalid AdMob SSV callback.",
          );
        }


        ssvVerified =
          true;


        // ====================================================
        // 🛡️ FINAL DEFENSE-IN-DEPTH VALIDATION
        // ====================================================

        const validatedAd =
          validateVerifiedAdData(
            verifiedAd,
          );


        // ====================================================
        // 📋 SAFE LOGGING
        // ====================================================

        console.log(
          "🐱✅ Verified AdMob reward ready for Firestore.",
          {
            uid:
              validatedAd.uid,

            transactionId:
              validatedAd.transactionId,

            rewardPurpose:
              validatedAd.rewardPurpose,

            adUnit:
              validatedAd.adUnit,

            adNetwork:
              validatedAd.adNetwork,

            rewardAmount:
              validatedAd.rewardAmount,

            rewardItem:
              validatedAd.rewardItem,

            keyId:
              validatedAd.keyId,
          },
        );


        // ====================================================
        // 💾 SAVE
        // ====================================================

        const result =
          await saveVerifiedAdMobReward(
            validatedAd,
          );


        // ====================================================
        // 📤 SUCCESS
        // ====================================================

        console.log(
          "🐱 AdMob SSV processed successfully.",
          {
            uid:
              validatedAd.uid,

            transactionId:
              validatedAd.transactionId,

            rewardPurpose:
              validatedAd.rewardPurpose,

            duplicate:
              result.duplicate,

            recorded:
              result.recorded,
          },
        );


        res.status(
          200,
        ).json(
          result,
        );

      } catch (
        error
      ) {

        const errorCode =
          error &&
          error.code
            ? String(
                error.code,
              )
            : "UNKNOWN";


        const errorMessage =
          error &&
          error.message
            ? String(
                error.message,
              )
            : "Unknown AdMob error.";


        console.error(
          "❌ AdMob reward processing failed.",
          {
            code:
              errorCode,

            message:
              errorMessage,
          },
        );


        // ====================================================
        // 🛡️ PERMANENT / VALIDATION ERROR
        // ====================================================

        if (
          CLIENT_VALIDATION_ERROR_CODES.has(
            errorCode,
          )
        ) {
          res.status(
            200,
          ).json({
            success:
              false,

            verified:
              ssvVerified,

            recorded:
              false,

            rewarded:
              false,

            error:
              errorCode ===
              "ADMOB_TRANSACTION_CONFLICT"
                ? "AdMob transaction conflict."
                : ssvVerified
                  ? "Verified AdMob callback failed final validation."
                  : "Invalid AdMob SSV callback.",
          });

          return;
        }


        // ====================================================
        // 🔄 RETRYABLE SERVER ERROR
        // ====================================================

        if (
          SERVER_RETRY_ERROR_CODES.has(
            errorCode,
          )
        ) {
          res.status(
            500,
          ).json({
            success:
              false,

            verified:
              ssvVerified,

            recorded:
              false,

            rewarded:
              false,

            error:
              "AdMob reward processing failed.",
          });

          return;
        }


        // ====================================================
        // ❌ UNKNOWN INTERNAL ERROR
        // ====================================================

        res.status(
          500,
        ).json({
          success:
            false,

          verified:
            ssvVerified,

          recorded:
            false,

          rewarded:
            false,

          error:
            "AdMob reward processing failed.",
        });
      }
    },
  );


// ============================================================
// 📦 EXPORTS
// ============================================================

module.exports = {
  adMobReward,

  validateUid,

  validateTransactionId,

  validateRewardPurpose,

  validateVerifiedAdData,

  getExpectedAdMobConfig,

  isSameVerifiedReward,

  isSameVerifiedHistory,

  saveVerifiedAdMobReward,
};