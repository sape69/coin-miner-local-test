"use strict";

// ============================================================
// 🐱 STELLURIINI - AD FUNCTIONS
// ============================================================
//
// Stelluriini AdMob Rewarded SSV -vastaanotto.
//
// Vastuu:
//
// 📺 Vastaanottaa AdMob SSV callbackin
// 🔐 Varmistaa AdMob SSV:n admobService.js:n kautta
// 🆔 Käyttää vain varmennettua UID:tä
// 🎯 Tunnistaa rewardin käyttötarkoituksen
// 💾 Tallentaa varmennetun rewardin Firestoreen
// 🛡️ Estää saman transaction_id:n uudelleenkäytön
//
// TÄMÄ TIEDOSTO EI:
//
// ❌ aktivoi Power Boostia
// ❌ käynnistä Mining Startia
// ❌ lisää STL-saldoa
// ❌ muuta adsToday-arvoa
// ❌ muuta cooldownia
// ❌ muuta mining-tilaa
//
// Varsinainen reward-toiminto tehdään erillisessä
// mining/business/service-kerroksessa.
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
//
// AdMob transaction_id:n defense-in-depth-validointi.
//
// Transaction ID käsitellään tunnisteena.
// Sitä ei oleteta heksadesimaaliseksi.
//
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
//
// Valitsee rewardPurpose-arvon perusteella:
//
// ⛏️ Mining Start
// ⚡ Power Boost
//
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
// admobService.js:n oletetaan jo varmistaneen:
//
// 🔐 kryptografisen allekirjoituksen
// 🔑 public keyn
// 🎯 reward purposen
// 📺 ad unitin
// 🎁 reward metadata-arvot
// 🆔 UID:n
// 🧾 transaction_id:n
// ⏱️ timestampin
//
// Tässä tehdään vielä defense-in-depth-validointi
// ennen Firestore-kirjoitusta.
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
  // EXPECTED ADMOB CONFIG
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
    expectedAdMob.rewardAmount
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
    expectedAdMob.rewardItem
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
    expectedAdMob.adUnit
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
  // VERIFIED DATA
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
// Tämä funktio EI anna käyttäjälle STL:ää.
//
// Se:
//
// 1. tarkistaa varmennetun datan
// 2. tarkistaa transaction_id:n
// 3. tallentaa AdMob reward -tapahtuman
// 4. tallentaa historian
//
// Varsinainen Mining Start / Power Boost käsitellään
// erillisessä business/service-kerroksessa.
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
  // REWARD DOCUMENT REFERENCE
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
      // ======================================================
      // 🔐 DUPLICATE CHECK
      // ======================================================

      const existingSnapshot =
        await transaction.get(
          rewardRef,
        );


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


        // ----------------------------------------------------
        // CONFLICT DETECTION
        // ----------------------------------------------------

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


        // ----------------------------------------------------
        // DUPLICATE
        // ----------------------------------------------------

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
          // --------------------------------------------------
          // IDENTITY
          // --------------------------------------------------

          uid,

          transactionId,


          // --------------------------------------------------
          // REWARD METADATA
          // --------------------------------------------------

          rewardType:
            "admob",

          rewardPurpose,

          rewardAmount,

          rewardItem,


          // --------------------------------------------------
          // ADMOB METADATA
          // --------------------------------------------------

          adNetwork,

          adUnit,

          timestamp,

          keyId,

          signature,

          customData,

          userId,


          // --------------------------------------------------
          // ⛏️ MINING START CLAIM STATE
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
          // ⚡ POWER BOOST CLAIM STATE
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
          // 🕒 SERVER TIMESTAMPS
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

          // --------------------------------------------------
          // AdMob reward metadata ei ole STL-token.
          // --------------------------------------------------

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
        // 🔐 METHOD HANDLING
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
        // 🔎 QUERY KEYS
        // ======================================================

        const queryKeys =
          Object.keys(
            req.query || {},
          );


        // ======================================================
        // 🩺 BASIC ENDPOINT CHECK
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
        // 🔐 VERIFY ADMOB CALLBACK
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


        // ------------------------------------------------------
        // SSV CRYPTOGRAPHICALLY VERIFIED
        // ------------------------------------------------------

        ssvVerified =
          true;


        // ======================================================
        // 🛡️ FINAL VERIFIED DATA
        // ======================================================

        const validatedAd =
          validateVerifiedAdData(
            verifiedAd,
          );


        const uid =
          validatedAd.uid;


        const rewardPurpose =
          validatedAd.rewardPurpose;


        const transactionId =
          validatedAd.transactionId;


        // ======================================================
        // 📝 VERIFIED LOG
        // ======================================================

        console.log(
          "🐱✅ Verified AdMob reward ready for Firestore.",
          {
            uid,

            transactionId,

            rewardPurpose,

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
        // 💾 SAVE VERIFIED REWARD
        // ======================================================

        const result =
          await saveVerifiedAdMobReward(
            verifiedAd,
          );


        // ======================================================
        // 📤 SUCCESS RESPONSE
        // ======================================================

        console.log(
          "🐱 AdMob SSV processed successfully.",
          {
            uid,

            transactionId,

            rewardPurpose,

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
        // 🔐 KNOWN ADMOB VALIDATION ERROR
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
        // ❌ INTERNAL SERVER / FIRESTORE ERROR
        // ======================================================
        //
        // Jos SSV oli validi mutta Firestore-tallennus
        // epäonnistui, emme väitä callbackia virheelliseksi.
        //
        // HTTP 500 antaa AdMobille mahdollisuuden yrittää
        // callbackia uudelleen.
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