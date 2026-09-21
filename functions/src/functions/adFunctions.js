"use strict";

// ============================================================
// 🐱 STELLURIINI - AD FUNCTIONS
// ============================================================
//
// AdMob Rewarded SSV callback.
//
// Vastuu:
//
// 📺 Vastaanottaa AdMob SSV callbackin
// 🔐 Varmistaa callbackin admobService.js:n kautta
// 🆔 Käyttää vain varmennettua UID:tä
// 🎯 Tunnistaa reward purposen
// 💾 Tallentaa varmennetun rewardin Firestoreen
// 🛡️ Estää transaction_id:n uudelleenkäytön
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
// Varsinainen Mining/Power Boost -business-logiikka
// kuuluu miningService.js:lle.
//
// AdMob SSV:n kryptografinen varmennus kuuluu:
//
// services/admobService.js
//
// History-referenceihin liittyvä logiikka kuuluu:
//
// services/historyService.js
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
// ⚙️ MINING CONFIG
// ============================================================

const {
  ADMOB_MINING_SSV_AD_UNIT_ID,

  ADMOB_POWER_BOOST_SSV_AD_UNIT_ID,

  ADMOB_MINING_SSV_REWARD_AMOUNT,

  ADMOB_MINING_SSV_REWARD_ITEM,

  ADMOB_POWER_BOOST_SSV_REWARD_AMOUNT,

  ADMOB_POWER_BOOST_SSV_REWARD_ITEM,
} = require(
  "../config/miningConfig",
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
// 🔐 ADMOB SERVICE
// ============================================================
//
// admobService.js vastaa:
//
// 🔐 SSV-signature verification
// 🔑 public key verification
// 🎯 reward purpose validation
// 📺 ad unit validation
// 🎁 reward metadata validation
// 🆔 UID validation
// 🧾 transaction_id validation
// ⏱️ timestamp validation
//
// ============================================================

const {
  verifyAdMobCallback,
} = require(
  "../services/admobService",
);


// ============================================================
// 🎯 VALID REWARD PURPOSES
// ============================================================

const VALID_REWARD_PURPOSES =
  new Set([
    "mining_start",
    "power_boost",
  ]);


// ============================================================
// 🛡️ VALIDATE UID
// ============================================================

function validateUid(
  value,
) {
  if (
    typeof value !==
    "string"
  ) {
    return "";
  }

  const uid =
    value.trim();

  if (
    uid.length === 0 ||
    uid.length > 128
  ) {
    return "";
  }

  if (
    !/^[A-Za-z0-9._-]+$/.test(
      uid,
    )
  ) {
    return "";
  }

  return uid;
}


// ============================================================
// 🆔 VALIDATE TRANSACTION ID
// ============================================================

function validateTransactionId(
  value,
) {
  if (
    typeof value !==
    "string"
  ) {
    return "";
  }

  const transactionId =
    value.trim();

  if (
    transactionId.length === 0 ||
    transactionId.length > 256
  ) {
    return "";
  }

  if (
    !/^[A-Za-z0-9._:-]+$/.test(
      transactionId,
    )
  ) {
    return "";
  }

  return transactionId;
}


// ============================================================
// 🎯 VALIDATE REWARD PURPOSE
// ============================================================

function validateRewardPurpose(
  value,
) {
  if (
    typeof value !==
    "string"
  ) {
    return "";
  }

  const rewardPurpose =
    value.trim();

  if (
    !VALID_REWARD_PURPOSES.has(
      rewardPurpose,
    )
  ) {
    return "";
  }

  return rewardPurpose;
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
// 🎯 GET EXPECTED ADMOB CONFIG
// ============================================================

function getExpectedAdMobConfig(
  rewardPurpose,
) {
  if (
    rewardPurpose ===
    "mining_start"
  ) {
    return {
      adUnit:
        ADMOB_MINING_SSV_AD_UNIT_ID,

      rewardAmount:
        ADMOB_MINING_SSV_REWARD_AMOUNT,

      rewardItem:
        ADMOB_MINING_SSV_REWARD_ITEM,
    };
  }

  if (
    rewardPurpose ===
    "power_boost"
  ) {
    return {
      adUnit:
        ADMOB_POWER_BOOST_SSV_AD_UNIT_ID,

      rewardAmount:
        ADMOB_POWER_BOOST_SSV_REWARD_AMOUNT,

      rewardItem:
        ADMOB_POWER_BOOST_SSV_REWARD_ITEM,
    };
  }

  const error =
    new Error(
      "Unknown AdMob reward purpose.",
    );

  error.code =
    "ADMOB_INVALID_REWARD_PURPOSE";

  throw error;
}


// ============================================================
// 🔐 VALIDATE VERIFIED AD DATA
// ============================================================
//
// Defense-in-depth.
//
// admobService.js on jo varmistanut kryptografisen
// allekirjoituksen ennen kuin data saapuu tähän.
//
// Täällä tarkistetaan vielä kaikki Firestoreen
// kirjoitettava kriittinen metadata.
//
// ============================================================

function validateVerifiedAdData(
  verifiedAd,
) {
  if (
    !verifiedAd
  ) {
    const error =
      new Error(
        "Verified AdMob data is missing.",
      );

    error.code =
      "ADMOB_VERIFIED_DATA_MISSING";

    throw error;
  }


  // ----------------------------------------------------------
  // VERIFIED FLAG
  // ----------------------------------------------------------

  if (
    verifiedAd.verified !==
    true
  ) {
    const error =
      new Error(
        "AdMob data is not cryptographically verified.",
      );

    error.code =
      "ADMOB_VERIFIED_DATA_MISSING";

    throw error;
  }


  // ----------------------------------------------------------
  // UID
  // ----------------------------------------------------------

  const uid =
    validateUid(
      verifiedAd.uid,
    );

  if (
    !uid
  ) {
    const error =
      new Error(
        "Verified AdMob UID is invalid.",
      );

    error.code =
      "ADMOB_INVALID_UID";

    throw error;
  }


  // ----------------------------------------------------------
  // REWARD PURPOSE
  // ----------------------------------------------------------

  const rewardPurpose =
    validateRewardPurpose(
      verifiedAd.rewardPurpose,
    );

  if (
    !rewardPurpose
  ) {
    const error =
      new Error(
        "Verified AdMob reward purpose is invalid.",
      );

    error.code =
      "ADMOB_INVALID_REWARD_PURPOSE";

    throw error;
  }


  // ----------------------------------------------------------
  // EXPECTED CONFIG
  // ----------------------------------------------------------

  const expectedAdMob =
    getExpectedAdMobConfig(
      rewardPurpose,
    );


  // ----------------------------------------------------------
  // TRANSACTION ID
  // ----------------------------------------------------------

  const transactionId =
    validateTransactionId(
      verifiedAd.transactionId,
    );

  if (
    !transactionId
  ) {
    const error =
      new Error(
        "Verified AdMob transaction_id is invalid.",
      );

    error.code =
      "ADMOB_INVALID_TRANSACTION_ID";

    throw error;
  }


  // ----------------------------------------------------------
  // REWARD AMOUNT
  // ----------------------------------------------------------

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
      expectedAdMob.rewardAmount,
    )
  ) {
    const error =
      new Error(
        "Verified AdMob reward amount is invalid.",
      );

    error.code =
      "ADMOB_INVALID_REWARD_AMOUNT";

    throw error;
  }


  // ----------------------------------------------------------
  // REWARD ITEM
  // ----------------------------------------------------------

  const rewardItem =
    normalizeString(
      verifiedAd.rewardItem,
    );

  if (
    rewardItem !==
    normalizeString(
      expectedAdMob.rewardItem,
    )
  ) {
    const error =
      new Error(
        "Verified AdMob reward item is invalid.",
      );

    error.code =
      "ADMOB_INVALID_REWARD_ITEM";

    throw error;
  }


  // ----------------------------------------------------------
  // AD UNIT
  // ----------------------------------------------------------

  const adUnit =
    normalizeString(
      verifiedAd.adUnit,
    );

  if (
    adUnit.length === 0 ||
    adUnit !==
    normalizeString(
      expectedAdMob.adUnit,
    )
  ) {
    const error =
      new Error(
        "Verified AdMob ad unit is invalid.",
      );

    error.code =
      "ADMOB_INVALID_AD_UNIT";

    throw error;
  }


  // ----------------------------------------------------------
  // AD NETWORK
  // ----------------------------------------------------------

  const adNetwork =
    normalizeString(
      verifiedAd.adNetwork,
    );

  if (
    adNetwork.length === 0 ||
    adNetwork.length > 32 ||
    !/^\d+$/.test(
      adNetwork,
    )
  ) {
    const error =
      new Error(
        "Verified AdMob ad network is invalid.",
      );

    error.code =
      "ADMOB_INVALID_AD_NETWORK";

    throw error;
  }


  // ----------------------------------------------------------
  // TIMESTAMP
  // ----------------------------------------------------------

  const timestamp =
    Number(
      verifiedAd.timestamp,
    );

  if (
    !Number.isSafeInteger(
      timestamp,
    ) ||
    timestamp <= 0
  ) {
    const error =
      new Error(
        "Verified AdMob timestamp is invalid.",
      );

    error.code =
      "ADMOB_INVALID_TIMESTAMP";

    throw error;
  }


  // ----------------------------------------------------------
  // KEY ID
  // ----------------------------------------------------------

  const keyId =
    normalizeString(
      verifiedAd.keyId,
    );

  if (
    keyId.length === 0 ||
    !/^\d+$/.test(
      keyId,
    )
  ) {
    const error =
      new Error(
        "Verified AdMob key_id is invalid.",
      );

    error.code =
      "ADMOB_INVALID_KEY_ID";

    throw error;
  }


  // ----------------------------------------------------------
  // SIGNATURE
  // ----------------------------------------------------------

  const signature =
    normalizeString(
      verifiedAd.signature,
    );

  if (
    signature.length === 0
  ) {
    const error =
      new Error(
        "Verified AdMob signature is missing.",
      );

    error.code =
      "ADMOB_INVALID_SIGNATURE";

    throw error;
  }


  // ----------------------------------------------------------
  // CUSTOM DATA
  // ----------------------------------------------------------

  const customData =
    normalizeString(
      verifiedAd.customData,
    );

  if (
    customData.length === 0 ||
    customData.length > 256
  ) {
    const error =
      new Error(
        "Verified AdMob custom_data is invalid.",
      );

    error.code =
      "ADMOB_CUSTOM_DATA_MISSING";

    throw error;
  }


  // ----------------------------------------------------------
  // USER ID
  // ----------------------------------------------------------

  const userId =
    normalizeString(
      verifiedAd.userId,
    );

  if (
    userId
  ) {
    const validatedUserId =
      validateUid(
        userId,
      );

    if (
      !validatedUserId
    ) {
      const error =
        new Error(
          "Verified AdMob user_id is invalid.",
        );

      error.code =
        "ADMOB_INVALID_UID";

      throw error;
    }

    if (
      validatedUserId !==
      uid
    ) {
      const error =
        new Error(
          "AdMob user_id does not match verified UID.",
        );

      error.code =
        "ADMOB_USER_ID_MISMATCH";

      throw error;
    }
  }


  // ----------------------------------------------------------
  // RETURN NORMALIZED DATA
  // ----------------------------------------------------------

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
// 💾 SAVE VERIFIED ADMOB REWARD
// ============================================================
//
// Tämä EI suorita rewardia.
//
// Se tallentaa ainoastaan kryptografisesti varmennetun
// AdMob-tapahtuman.
//
// Varsinainen Mining Start / Power Boost:
//
// services/miningService.js
//
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


  // ----------------------------------------------------------
  // REWARD REFERENCE
  // ----------------------------------------------------------

  const rewardRef =
    getAdMobRewardRef(
      transactionId,
    );

  if (
    !rewardRef
  ) {
    const error =
      new Error(
        "Unable to create AdMob reward reference.",
      );

    error.code =
      "ADMOB_REWARD_REFERENCE_ERROR";

    throw error;
  }


  // ----------------------------------------------------------
  // HISTORY COLLECTION
  // ----------------------------------------------------------

  const historyCollection =
    getHistoryCollection(
      uid,
    );

  if (
    !historyCollection
  ) {
    const error =
      new Error(
        "Unable to create user history collection.",
      );

    error.code =
      "ADMOB_HISTORY_REFERENCE_ERROR";

    throw error;
  }


  // ----------------------------------------------------------
  // FIRESTORE TRANSACTION
  // ----------------------------------------------------------

  return db.runTransaction(
    async (
      transaction,
    ) => {
      const existingSnapshot =
        await transaction.get(
          rewardRef,
        );


      // ======================================================
      // 🔐 DUPLICATE / CONFLICT
      // ======================================================

      if (
        existingSnapshot.exists
      ) {
        const existingData =
          existingSnapshot.data() ||
          {};


        const existingUid =
          normalizeString(
            existingData.uid,
          );


        const existingPurpose =
          normalizeString(
            existingData.rewardPurpose,
          );


        const existingTransactionId =
          normalizeString(
            existingData.transactionId,
          );


        if (
          existingUid !==
          uid ||
          existingPurpose !==
          rewardPurpose ||
          (
            existingTransactionId &&
            existingTransactionId !==
            transactionId
          )
        ) {
          const error =
            new Error(
              "AdMob transaction_id is already associated with different reward data.",
            );

          error.code =
            "ADMOB_TRANSACTION_CONFLICT";

          throw error;
        }


        console.log(
          "🐱 AdMob transaction already processed.",
          {
            transactionId,

            uid,

            rewardPurpose,
          },
        );


        return {
          success:
            true,

          verified:
            true,

          rewarded:
            false,

          duplicate:
            true,

          transactionId,

          rewardPurpose,

          message:
            "🐱📺 Tämä AdMob-palkinto on jo vastaanotettu.",
        };
      }


      // ======================================================
      // 💾 SAVE VERIFIED REWARD
      // ======================================================

      transaction.set(
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

          // --------------------------------------------------
          // ⛏️ MINING START STATE
          // --------------------------------------------------

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

          // --------------------------------------------------
          // ⚡ POWER BOOST STATE
          // --------------------------------------------------

          powerBoostClaimed:
            false,

          powerBoostClaimedAt:
            null,

          powerBoostClaimedBy:
            null,

          powerBoostTransactionId:
            null,

          // --------------------------------------------------
          // 🕒 TIMESTAMPS
          // --------------------------------------------------

          createdAt:
            FieldValue.serverTimestamp(),

          updatedAt:
            FieldValue.serverTimestamp(),
        },
      );


      // ======================================================
      // 📜 HISTORY
      // ======================================================

      const historyRef =
        historyCollection.doc();


      transaction.set(
        historyRef,
        {
          type:
            "admob_verified",

          title:
            rewardPurpose ===
            "power_boost"
              ? "Stella Power Boost Ad Verified 🐱📺⚡"
              : "Stella Mining Start Ad Verified 🐱📺⛏️",

          // AdMob rewardAmount ei ole STL-token.
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

        rewarded:
          true,

        duplicate:
          false,

        transactionId,

        rewardPurpose,

        rewardAmount,

        rewardItem,

        message:
          rewardPurpose ===
          "power_boost"
            ? "🐱📺 Power Boost -mainos vahvistettu ja palkkio tallennettu."
            : "🐱📺 Mining Start -mainos vahvistettu ja palkkio tallennettu.",
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
        // ======================================================
        // 🔐 METHOD
        // ======================================================

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

            rewarded:
              false,

            error:
              "Method not allowed.",
          });

          return;
        }


        // ======================================================
        // 🔎 QUERY
        // ======================================================

        const queryKeys =
          Object.keys(
            req.query || {},
          );


        // ======================================================
        // 🩺 HEALTH CHECK
        // ======================================================

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

            endpoint:
              "adMobReward",

            rewarded:
              false,

            message:
              "Stelluriini AdMob SSV endpoint is reachable.",
          });

          return;
        }


        // ======================================================
        // 🔐 VERIFY CALLBACK
        // ======================================================

        console.log(
          "🐱 AdMob SSV callback received.",
        );


        console.log(
          "🐱 AdMob SSV query keys:",
          queryKeys,
        );


        const verifiedAd =
          await verifyAdMobCallback(
            req,
          );


        // ======================================================
        // 🛡️ VERIFY RESULT
        // ======================================================

        if (
          !verifiedAd ||
          verifiedAd.verified !==
          true
        ) {
          console.error(
            "❌ AdMob SSV verification failed.",
          );


          res.status(
            400,
          ).json({
            success:
              false,

            verified:
              false,

            rewarded:
              false,

            error:
              "Invalid AdMob SSV callback.",
          });

          return;
        }


        // ======================================================
        // 🔐 CRYPTOGRAPHICALLY VERIFIED
        // ======================================================

        ssvVerified =
          true;


        // ======================================================
        // 🛡️ FINAL VALIDATION
        // ======================================================

        const validatedAd =
          validateVerifiedAdData(
            verifiedAd,
          );


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


        // ======================================================
        // 💾 SAVE
        // ======================================================

        const result =
          await saveVerifiedAdMobReward(
            validatedAd,
          );


        // ======================================================
        // 📤 SUCCESS
        // ======================================================

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
        // ======================================================
        // ❌ ERROR LOG
        // ======================================================

        console.error(
          "❌ AdMob reward processing failed.",
          {
            code:
              error &&
              error.code
                ? error.code
                : "UNKNOWN",

            message:
              error &&
              error.message
                ? error.message
                : "Unknown AdMob error.",
          },
        );


        // ======================================================
        // 🔐 TRANSACTION CONFLICT
        // ======================================================

        if (
          error &&
          error.code ===
          "ADMOB_TRANSACTION_CONFLICT"
        ) {
          res.status(
            409,
          ).json({
            success:
              false,

            verified:
              ssvVerified,

            rewarded:
              false,

            error:
              "AdMob transaction conflict.",
          });

          return;
        }


        // ======================================================
        // 🔐 KNOWN VALIDATION ERRORS
        // ======================================================

        const knownValidationCodes =
          new Set([
            "ADMOB_PUBLIC_KEY_FETCH_ERROR",

            "ADMOB_PUBLIC_KEY_HTTP_ERROR",

            "ADMOB_PUBLIC_KEY_JSON_ERROR",

            "ADMOB_PUBLIC_KEY_RESPONSE_INVALID",

            "ADMOB_PUBLIC_KEYS_EMPTY",

            "ADMOB_PUBLIC_KEY_NOT_FOUND",

            "ADMOB_CRYPTO_VERIFICATION_ERROR",

            "ADMOB_INVALID_SIGNATURE",

            "ADMOB_INVALID_KEY_ID",

            "ADMOB_REQUEST_MISSING",

            "ADMOB_QUERY_STRING_MISSING",

            "ADMOB_INVALID_UID",

            "ADMOB_INVALID_REWARD_PURPOSE",

            "ADMOB_INVALID_TRANSACTION_ID",

            "ADMOB_INVALID_REWARD_AMOUNT",

            "ADMOB_INVALID_REWARD_ITEM",

            "ADMOB_INVALID_AD_UNIT",

            "ADMOB_INVALID_TIMESTAMP",

            "ADMOB_INVALID_AD_NETWORK",

            "ADMOB_REQUIRED_PARAMETER_MISSING",

            "ADMOB_VERIFIED_DATA_MISSING",

            "ADMOB_REWARD_REFERENCE_ERROR",

            "ADMOB_HISTORY_REFERENCE_ERROR",

            "ADMOB_USER_ID_MISMATCH",

            "ADMOB_CUSTOM_DATA_MISSING",
          ]);


        if (
          error &&
          knownValidationCodes.has(
            error.code,
          )
        ) {
          res.status(
            400,
          ).json({
            success:
              false,

            verified:
              ssvVerified,

            rewarded:
              false,

            error:
              ssvVerified
                ? "Verified AdMob callback failed final validation."
                : "Invalid AdMob SSV callback.",
          });

          return;
        }


        // ======================================================
        // ❌ INTERNAL ERROR
        // ======================================================
        //
        // Jos AdMob SSV oli kryptografisesti validi mutta
        // Firestore-tallennus epäonnistui, palautetaan 500.
        //
        // Näin callback voidaan yrittää uudelleen.
        //
        // ======================================================

        res.status(
          500,
        ).json({
          success:
            false,

          verified:
            ssvVerified,

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
};