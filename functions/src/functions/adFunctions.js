"use strict";

// ============================================================
// 🐱 STELLURIINI - ADMOB REWARD FUNCTIONS
// ============================================================
//
// Vastuu:
//
// 📺 Vastaanottaa AdMob SSV callbackin
// 🔐 Varmistaa callbackin admobService.js:n kautta
// 🆔 Käyttää vain varmennettua UID:tä
// 🎯 Tunnistaa reward purposen
// 💾 Tallentaa varmennetun AdMob-tapahtuman
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
// Varsinainen business-logiikka:
//
// functions/src/functions/miningFunctions.js
//
// Kryptografinen AdMob SSV -varmennus:
//
// functions/src/services/admobService.js
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

function validateUid(value) {
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
    !/^[A-Za-z0-9._-]+$/.test(uid)
  ) {
    return "";
  }

  return uid;
}


// ============================================================
// 🆔 VALIDATE TRANSACTION ID
// ============================================================
//
// AdMob määrittelee transaction_id:n:
//
// "Unique hex encoded identifier for each reward grant event."
//
// ============================================================

function validateTransactionId(value) {
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
    !/^[A-Fa-f0-9]+$/.test(
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

function validateRewardPurpose(value) {
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

function normalizeString(value) {
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
        Number(
          ADMOB_MINING_SSV_REWARD_AMOUNT,
        ),

      rewardItem:
        normalizeString(
          ADMOB_MINING_SSV_REWARD_ITEM,
        ),
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
        Number(
          ADMOB_POWER_BOOST_SSV_REWARD_AMOUNT,
        ),

      rewardItem:
        normalizeString(
          ADMOB_POWER_BOOST_SSV_REWARD_ITEM,
        ),
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
// 🔐 CREATE VALIDATION ERROR
// ============================================================
//
// Keskitetään virheiden luonti yhteen paikkaan.
// Tämä pitää callback-koodin selkeämpänä.
//
// ============================================================

function createValidationError(
  code,
  message,
) {
  const error =
    new Error(message);

  error.code =
    code;

  return error;
}


// ============================================================
// 🔐 VALIDATE VERIFIED AD DATA
// ============================================================
//
// admobService.js on jo suorittanut kryptografisen
// SSV-varmennuksen.
//
// Tämä funktio tekee defense-in-depth -tarkistuksen ennen
// Firestore-kirjoitusta.
//
// ============================================================

function validateVerifiedAdData(
  verifiedAd,
) {
  if (
    !verifiedAd ||
    typeof verifiedAd !==
    "object"
  ) {
    throw createValidationError(
      "ADMOB_VERIFIED_DATA_MISSING",
      "Verified AdMob data is missing.",
    );
  }


  // ----------------------------------------------------------
  // VERIFIED FLAG
  // ----------------------------------------------------------

  if (
    verifiedAd.verified !==
    true
  ) {
    throw createValidationError(
      "ADMOB_VERIFIED_DATA_MISSING",
      "AdMob data is not cryptographically verified.",
    );
  }


  // ----------------------------------------------------------
  // UID
  // ----------------------------------------------------------

  const uid =
    validateUid(
      verifiedAd.uid,
    );

  if (!uid) {
    throw createValidationError(
      "ADMOB_INVALID_UID",
      "Verified AdMob UID is invalid.",
    );
  }


  // ----------------------------------------------------------
  // REWARD PURPOSE
  // ----------------------------------------------------------

  const rewardPurpose =
    validateRewardPurpose(
      verifiedAd.rewardPurpose,
    );

  if (!rewardPurpose) {
    throw createValidationError(
      "ADMOB_INVALID_REWARD_PURPOSE",
      "Verified AdMob reward purpose is invalid.",
    );
  }


  // ----------------------------------------------------------
  // EXPECTED CONFIG
  // ----------------------------------------------------------

  const expectedAdMob =
    getExpectedAdMobConfig(
      rewardPurpose,
    );


  if (
    !Number.isSafeInteger(
      expectedAdMob.rewardAmount,
    ) ||
    expectedAdMob.rewardAmount < 0
  ) {
    throw createValidationError(
      "ADMOB_INVALID_REWARD_CONFIG",
      "Configured AdMob reward amount is invalid.",
    );
  }


  if (
    !expectedAdMob.rewardItem
  ) {
    throw createValidationError(
      "ADMOB_INVALID_REWARD_CONFIG",
      "Configured AdMob reward item is invalid.",
    );
  }


  if (
    !normalizeString(
      expectedAdMob.adUnit,
    )
  ) {
    throw createValidationError(
      "ADMOB_INVALID_REWARD_CONFIG",
      "Configured AdMob ad unit is invalid.",
    );
  }


  // ----------------------------------------------------------
  // TRANSACTION ID
  // ----------------------------------------------------------

  const transactionId =
    validateTransactionId(
      verifiedAd.transactionId,
    );

  if (!transactionId) {
    throw createValidationError(
      "ADMOB_INVALID_TRANSACTION_ID",
      "Verified AdMob transaction_id is invalid.",
    );
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
    rewardAmount < 0 ||
    rewardAmount !==
    expectedAdMob.rewardAmount
  ) {
    throw createValidationError(
      "ADMOB_INVALID_REWARD_AMOUNT",
      "Verified AdMob reward amount is invalid.",
    );
  }


  // ----------------------------------------------------------
  // REWARD ITEM
  // ----------------------------------------------------------

  const rewardItem =
    normalizeString(
      verifiedAd.rewardItem,
    );

  if (
    !rewardItem ||
    rewardItem !==
    expectedAdMob.rewardItem
  ) {
    throw createValidationError(
      "ADMOB_INVALID_REWARD_ITEM",
      "Verified AdMob reward item is invalid.",
    );
  }


  // ----------------------------------------------------------
  // AD UNIT
  // ----------------------------------------------------------

  const adUnit =
    normalizeString(
      verifiedAd.adUnit,
    );

  if (
    !adUnit ||
    adUnit !==
    normalizeString(
      expectedAdMob.adUnit,
    )
  ) {
    throw createValidationError(
      "ADMOB_INVALID_AD_UNIT",
      "Verified AdMob ad unit is invalid.",
    );
  }


  // ----------------------------------------------------------
  // AD NETWORK
  // ----------------------------------------------------------
  //
  // AdMobin ad_network on merkkijono.
  // Sitä ei saa muuttaa Number-tyyppiin.
  //
  // ----------------------------------------------------------

  const adNetwork =
    normalizeString(
      verifiedAd.adNetwork,
    );

  if (
    !adNetwork ||
    adNetwork.length > 32 ||
    !/^\d+$/.test(
      adNetwork,
    )
  ) {
    throw createValidationError(
      "ADMOB_INVALID_AD_NETWORK",
      "Verified AdMob ad network is invalid.",
    );
  }


  // ----------------------------------------------------------
  // TIMESTAMP
  // ----------------------------------------------------------
  //
  // AdMob käyttää Epoch time in milliseconds.
  //
  // admobService.js:n vastuulla on varsinainen
  // timestamp-politiikka.
  //
  // Täällä varmistetaan vain muoto ja turvallinen numero.
  //
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
    throw createValidationError(
      "ADMOB_INVALID_TIMESTAMP",
      "Verified AdMob timestamp is invalid.",
    );
  }


  // ----------------------------------------------------------
  // KEY ID
  // ----------------------------------------------------------

  const keyId =
    normalizeString(
      verifiedAd.keyId,
    );

  if (
    !keyId ||
    !/^\d+$/.test(
      keyId,
    )
  ) {
    throw createValidationError(
      "ADMOB_INVALID_KEY_ID",
      "Verified AdMob key_id is invalid.",
    );
  }


  // ----------------------------------------------------------
  // SIGNATURE
  // ----------------------------------------------------------

  const signature =
    normalizeString(
      verifiedAd.signature,
    );

  if (!signature) {
    throw createValidationError(
      "ADMOB_INVALID_SIGNATURE",
      "Verified AdMob signature is missing.",
    );
  }


  // ----------------------------------------------------------
  // CUSTOM DATA
  // ----------------------------------------------------------
  //
  // Google sallii custom_data-parametrin olla teknisesti
  // valinnainen.
  //
  // Stelluriinin arkkitehtuurissa se kuitenkin sitoo
  // AdMob-tapahtuman käyttäjään ja reward purposeen.
  //
  // Siksi admobService.js:n pitää tuottaa verifiedAd.uid
  // ja verifiedAd.rewardPurpose sen perusteella.
  //
  // ----------------------------------------------------------

  const customData =
    normalizeString(
      verifiedAd.customData,
    );

  if (
    !customData ||
    customData.length > 256
  ) {
    throw createValidationError(
      "ADMOB_CUSTOM_DATA_MISSING",
      "Verified AdMob custom_data is invalid.",
    );
  }


  // ----------------------------------------------------------
  // USER ID
  // ----------------------------------------------------------
  //
  // user_id on AdMobissa valinnainen.
  //
  // Jos se kuitenkin lähetetään, sen täytyy täsmätä
  // varmennettuun UID:hen.
  //
  // ----------------------------------------------------------

  const userId =
    normalizeString(
      verifiedAd.userId,
    );

  if (userId) {
    const validatedUserId =
      validateUid(
        userId,
      );

    if (!validatedUserId) {
      throw createValidationError(
        "ADMOB_INVALID_UID",
        "Verified AdMob user_id is invalid.",
      );
    }

    if (
      validatedUserId !==
      uid
    ) {
      throw createValidationError(
        "ADMOB_USER_ID_MISMATCH",
        "AdMob user_id does not match verified UID.",
      );
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
// Tämä EI anna rewardia.
//
// Se tallentaa ainoastaan kryptografisesti varmennetun
// AdMob-tapahtuman.
//
// Varsinainen business-logiikka:
//
// functions/src/functions/miningFunctions.js
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

  if (!rewardRef) {
    throw createValidationError(
      "ADMOB_REWARD_REFERENCE_ERROR",
      "Unable to create AdMob reward reference.",
    );
  }


  // ----------------------------------------------------------
  // HISTORY COLLECTION
  // ----------------------------------------------------------

  const historyCollection =
    getHistoryCollection(
      uid,
    );

  if (!historyCollection) {
    throw createValidationError(
      "ADMOB_HISTORY_REFERENCE_ERROR",
      "Unable to create user history collection.",
    );
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
      // 🔐 EXISTING TRANSACTION
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

        const existingRewardAmount =
          Number(
            existingData.rewardAmount,
          );

        const existingRewardItem =
          normalizeString(
            existingData.rewardItem,
          );

        const existingAdUnit =
          normalizeString(
            existingData.adUnit,
          );


        // ----------------------------------------------------
        // SAME TRANSACTION MUST MEAN SAME EVENT
        // ----------------------------------------------------

        const sameEvent =
          existingUid === uid &&
          existingPurpose ===
            rewardPurpose &&
          existingTransactionId ===
            transactionId &&
          existingRewardAmount ===
            rewardAmount &&
          existingRewardItem ===
            rewardItem &&
          existingAdUnit ===
            adUnit;


        if (!sameEvent) {
          throw createValidationError(
            "ADMOB_TRANSACTION_CONFLICT",
            "AdMob transaction_id is already associated with different reward data.",
          );
        }


        // ----------------------------------------------------
        // DUPLICATE CALLBACK
        // ----------------------------------------------------
        //
        // AdMob SSV callback voi saapua uudelleen.
        //
        // Sama tapahtuma ei saa luoda uutta rewardia,
        // uutta mining-tilaa eikä uutta historiaa.
        //
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
      // 💾 SAVE VERIFIED REWARD EVENT
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

          userId:
            userId || null,


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
      // 📜 AUDIT HISTORY
      // ======================================================
      //
      // amount = 0
      //
      // AdMob rewardAmount ei ole STL.
      //
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
        // 🔐 HTTP METHOD
        // ====================================================

        if (
          req.method ===
          "HEAD"
        ) {
          res
            .status(200)
            .end();

          return;
        }


        if (
          req.method !==
          "GET"
        ) {
          res
            .status(405)
            .json({
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
          req.query || {};

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

          res
            .status(200)
            .json({
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
        // 🔐 VERIFY CALLBACK
        // ====================================================

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


        // ====================================================
        // 🛡️ VERIFY RESULT
        // ====================================================

        if (
          !verifiedAd ||
          verifiedAd.verified !==
          true
        ) {
          console.error(
            "❌ AdMob SSV verification failed.",
          );

          res
            .status(400)
            .json({
              success:
                false,

              verified:
                false,

              recorded:
                false,

              rewarded:
                false,

              error:
                "Invalid AdMob SSV callback.",
            });

          return;
        }


        // ====================================================
        // 🔐 CRYPTOGRAPHICALLY VERIFIED
        // ====================================================

        ssvVerified =
          true;


        // ====================================================
        // 🛡️ FINAL VALIDATION
        // ====================================================

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


        res
          .status(200)
          .json(
            result,
          );
      } catch (
        error
      ) {
        // ====================================================
        // ❌ ERROR LOG
        // ====================================================

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


        // ====================================================
        // 🔐 TRANSACTION CONFLICT
        // ====================================================

        if (
          error &&
          error.code ===
          "ADMOB_TRANSACTION_CONFLICT"
        ) {
          res
            .status(409)
            .json({
              success:
                false,

              verified:
                ssvVerified,

              recorded:
                false,

              rewarded:
                false,

              error:
                "AdMob transaction conflict.",
            });

          return;
        }


        // ====================================================
        // 🔐 KNOWN VALIDATION ERRORS
        // ====================================================

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

            "ADMOB_INVALID_REWARD_CONFIG",
          ]);


        if (
          error &&
          knownValidationCodes.has(
            error.code,
          )
        ) {
          res
            .status(400)
            .json({
              success:
                false,

              verified:
                ssvVerified,

              recorded:
                false,

              rewarded:
                false,

              error:
                ssvVerified
                  ? "Verified AdMob callback failed final validation."
                  : "Invalid AdMob SSV callback.",
            });

          return;
        }


        // ====================================================
        // ❌ INTERNAL ERROR
        // ====================================================
        //
        // Jos SSV oli kryptografisesti validi mutta
        // Firestore-tallennus epäonnistui, palautetaan 500.
        //
        // Tällöin AdMob voi yrittää callbackia uudelleen.
        //
        // ====================================================

        res
          .status(500)
          .json({
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
};