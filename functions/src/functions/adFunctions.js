"use strict";

// ============================================================
// 🐱 STELLA AD FUNCTIONS
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
// ============================================================
//
// ARKKITEHTUURI:
//
// AdMob
//   ↓
// adMobReward()
//   ↓
// admobService.verifyAdMobCallback()
//   ↓
// kryptografinen SSV-varmennus
//   ↓
// reward-parametrien validointi
//   ↓
// Firestore transaction
//   ↓
// admobRewards/{transactionId}
//
// Varsinainen rewardin käyttäminen tapahtuu myöhemmin
// erillisessä palvelu-/function-kerroksessa.
//
// ============================================================


// ============================================================
// 🔥 FIREBASE FUNCTIONS
// ============================================================

const {
  onRequest,
} = require(
  "firebase-functions/v2/https"
);


// ============================================================
// 🔥 FIREBASE
// ============================================================

const {
  db,
  FieldValue,
} = require(
  "../firebase/firebase"
);


// ============================================================
// 👤 USER UTILITIES
// ============================================================

const {
  getHistoryCollection,
  getAdMobRewardRef,
} = require(
  "../utils/userUtils"
);


// ============================================================
// 🔐 ADMOB SERVICE
// ============================================================
//
// Kaikki AdMob SSV:n kryptografinen tarkistus tehdään
// tässä palvelussa.
//
// ============================================================

const {
  verifyAdMobCallback,
} = require(
  "../services/admobService"
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
// 🔢 SAFE NUMBER
// ============================================================

function getSafeNumber(
  value,
  fallback = 0,
) {
  const number =
    Number(value);

  if (
    !Number.isFinite(number)
  ) {
    return fallback;
  }

  return number;
}


// ============================================================
// 🛡️ VALIDATE UID
// ============================================================
//
// admobService.js on jo validoinut UID:n.
//
// Tämä toinen tarkistus pidetään täällä puolustuskerroksena
// ennen Firestore-kirjoitusta.
//
// ============================================================

function validateUid(
  value,
) {
  if (
    typeof value !== "string"
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
// 🔐 VALIDATE TRANSACTION ID
// ============================================================
//
// AdMob transaction_id käsitellään hex-merkkijonona.
//
// ============================================================

function validateTransactionId(
  value,
) {
  if (
    typeof value !== "string"
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
    !/^[a-fA-F0-9]+$/.test(
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
    typeof value !== "string"
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
    typeof value !== "string"
  ) {
    return "";
  }

  return value.trim();
}


// ============================================================
// 💾 SAVE VERIFIED ADMOB REWARD
// ============================================================
//
// Tämä funktio tekee vain:
//
// AdMob SSV
//      ↓
// Firestore admobRewards/{transactionId}
//
// Se EI käytä rewardia.
//
// ============================================================

async function saveVerifiedAdMobReward(
  uid,
  transactionId,
  verifiedAd,
  rewardPurpose,
) {
  const rewardRef =
    getAdMobRewardRef(
      transactionId,
    );

  const historyCollection =
    getHistoryCollection(
      uid,
    );

  const now =
    new Date();

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
          existingSnapshot.data() || {};

        const existingUid =
          normalizeString(
            existingData.uid,
          );

        const existingPurpose =
          normalizeString(
            existingData.rewardPurpose,
          );

        /**
         * Sama transaction_id saa kuulua vain yhdelle
         * käyttäjälle ja yhdelle reward-tyypille.
         *
         * Jos joku yrittää käyttää jo olemassa olevaa
         * transaction_id:tä eri UID:llä tai eri tarkoitukseen,
         * kyseessä ei ole normaali duplicate.
         */
        if (
          existingUid !== uid ||
          existingPurpose !==
            rewardPurpose
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
          success: true,

          rewarded: false,

          duplicate: true,

          transactionId,

          rewardPurpose,

          message:
            "🐱📺 Tämä AdMob-palkinto on jo vastaanotettu.",
        };
      }


      // ======================================================
      // 🎁 VERIFIED REWARD DATA
      // ======================================================

      const rewardAmount =
        getSafeNumber(
          verifiedAd.rewardAmount,
          0,
        );

      const rewardItem =
        normalizeString(
          verifiedAd.rewardItem,
        );

      const adUnit =
        normalizeString(
          verifiedAd.adUnit,
        );

      const adNetwork =
        normalizeString(
          verifiedAd.adNetwork,
        ) || "admob";

      const timestamp =
        getSafeNumber(
          verifiedAd.timestamp,
          now.getTime(),
        );

      const keyId =
        normalizeString(
          verifiedAd.keyId,
        );

      const customData =
        normalizeString(
          verifiedAd.customData,
        );

      const userId =
        normalizeString(
          verifiedAd.userId,
        );


      // ======================================================
      // 🛡️ FINAL DATA CHECK
      // ======================================================

      if (
        rewardAmount <= 0
      ) {
        const error =
          new Error(
            "Verified AdMob reward amount is invalid.",
          );

        error.code =
          "ADMOB_INVALID_REWARD_AMOUNT";

        throw error;
      }

      if (
        rewardItem.length === 0
      ) {
        const error =
          new Error(
            "Verified AdMob reward item is missing.",
          );

        error.code =
          "ADMOB_INVALID_REWARD_ITEM";

        throw error;
      }

      if (
        adUnit.length === 0
      ) {
        const error =
          new Error(
            "Verified AdMob ad unit is missing.",
          );

        error.code =
          "ADMOB_INVALID_AD_UNIT";

        throw error;
      }


      // ======================================================
      // 💾 SAVE ADMOB REWARD
      // ======================================================
      //
      // Tämä dokumentti tarkoittaa:
      //
      // "AdMob reward on kryptografisesti varmennettu."
      //
      // Se EI tarkoita:
      //
      // "Power Boost on aktivoitu."
      //
      // tai:
      //
      // "Mining Start on käynnistetty."
      //
      // ======================================================

      transaction.set(
        rewardRef,
        {
          uid,

          transactionId,

          rewardType:
            "admob",

          rewardPurpose,

          adNetwork,

          adUnit,

          rewardAmount,

          rewardItem,

          timestamp,

          keyId,

          customData,

          userId,

          // --------------------------------------------------
          // ⛏️ MINING START
          // --------------------------------------------------

          miningClaimed:
            false,

          miningClaimedAt:
            null,

          miningStartClaimed:
            false,

          miningStartClaimedAt:
            null,

          miningStartClaimedBy:
            null,

          // --------------------------------------------------
          // ⚡ POWER BOOST
          // --------------------------------------------------

          powerBoostClaimed:
            false,

          powerBoostClaimedAt:
            null,

          powerBoostClaimedBy:
            null,

          // --------------------------------------------------
          // 🕒 SERVER TIME
          // --------------------------------------------------

          createdAt:
            FieldValue.serverTimestamp(),
        },
      );


      // ======================================================
      // 📜 HISTORY
      // ======================================================
      //
      // Historia kertoo vain, että AdMob reward vastaanotettiin
      // ja varmennettiin.
      //
      // Se ei tarkoita, että reward olisi jo käytetty.
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
        success: true,

        rewarded: true,

        duplicate: false,

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
//
// AdMob kutsuu tätä HTTP endpointia.
//
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
      try {
        // ======================================================
        // 🔐 ALLOW ONLY GET + HEAD
        // ======================================================

        if (
          req.method !== "GET" &&
          req.method !== "HEAD"
        ) {
          res.status(
            405,
          ).json({
            success: false,

            verified: false,

            rewarded: false,

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
        //
        // Tyhjä GET näyttää vain, että endpoint on saavutettavissa.
        //
        // Se EI käsittele rewardia.
        //
        // ======================================================

        if (
          queryKeys.length === 0
        ) {
          console.log(
            "🐱 AdMob SSV endpoint health check.",
          );

          res.status(
            200,
          ).json({
            success: true,

            endpoint:
              "adMobReward",

            message:
              "Stelluriini AdMob SSV endpoint is reachable.",
          });

          return;
        }


        // ======================================================
        // 🔐 VERIFY ADMOB CALLBACK
        // ======================================================
        //
        // TÄRKEÄÄ:
        //
        // admobService tarkistaa ensin kryptografisen
        // allekirjoituksen ja kaikki reward-parametrit.
        //
        // Vasta onnistuneen varmennuksen jälkeen jatketaan.
        //
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
          verifiedAd.verified !== true
        ) {
          console.error(
            "❌ AdMob SSV verification failed.",
          );

          res.status(
            400,
          ).json({
            success: false,

            verified: false,

            rewarded: false,

            error:
              "Invalid AdMob SSV callback.",
          });

          return;
        }


        // ======================================================
        // 👤 VERIFIED UID
        // ======================================================

        const uid =
          validateUid(
            verifiedAd.uid,
          );

        if (
          !uid
        ) {
          console.error(
            "❌ Verified AdMob UID is invalid.",
          );

          res.status(
            400,
          ).json({
            success: false,

            verified: true,

            rewarded: false,

            error:
              "Invalid verified user ID.",
          });

          return;
        }


        // ======================================================
        // 🎯 VERIFIED REWARD PURPOSE
        // ======================================================

        const rewardPurpose =
          validateRewardPurpose(
            verifiedAd.rewardPurpose,
          );

        if (
          !rewardPurpose
        ) {
          console.error(
            "❌ Verified AdMob reward purpose is invalid.",
            {
              rewardPurpose:
                verifiedAd.rewardPurpose,
            },
          );

          res.status(
            400,
          ).json({
            success: false,

            verified: true,

            rewarded: false,

            error:
              "Invalid AdMob reward purpose.",
          });

          return;
        }


        // ======================================================
        // 🔐 VERIFIED TRANSACTION ID
        // ======================================================

        const transactionId =
          validateTransactionId(
            verifiedAd.transactionId,
          );

        if (
          !transactionId
        ) {
          console.error(
            "❌ Verified AdMob transaction_id is invalid.",
          );

          res.status(
            400,
          ).json({
            success: false,

            verified: true,

            rewarded: false,

            error:
              "Invalid AdMob transaction_id.",
          });

          return;
        }


        // ======================================================
        // 👤 USER ID CONSISTENCY
        // ======================================================
        //
        // user_id on SSV is optional.
        //
        // Jos se on mukana, sen täytyy vastata custom_data
        // UID:tä, jonka admobService on jo varmistanut.
        //
        // ======================================================

        const callbackUserId =
          normalizeString(
            verifiedAd.userId,
          );

        if (
          callbackUserId &&
          callbackUserId !== uid
        ) {
          console.error(
            "❌ AdMob user_id does not match verified UID.",
            {
              uid,
              callbackUserId,
            },
          );

          res.status(
            400,
          ).json({
            success: false,

            verified: true,

            rewarded: false,

            error:
              "AdMob user identity mismatch.",
          });

          return;
        }


        // ======================================================
        // 🧩 VERIFIED CUSTOM DATA
        // ======================================================
        //
        // admobService on jo parsinnut custom_data-arvosta
        // UID:n ja rewardPurposen.
        //
        // Täällä emme rakenna custom_dataa uudelleen emmekä
        // käytä sitä allekirjoituksen tarkistamiseen.
        //
        // ======================================================

        const customData =
          normalizeString(
            verifiedAd.customData,
          );

        if (
          customData.length === 0
        ) {
          console.error(
            "❌ Verified AdMob custom_data is missing.",
          );

          res.status(
            400,
          ).json({
            success: false,

            verified: true,

            rewarded: false,

            error:
              "Missing AdMob custom_data.",
          });

          return;
        }


        // ======================================================
        // 📺 NORMALIZED VERIFIED AD
        // ======================================================
        //
        // Tähän kopioidaan vain jo varmennetut arvot.
        //
        // Allekirjoitettavaa query-stringiä ei enää käsitellä.
        //
        // ======================================================

        const normalizedVerifiedAd = {
          verified: true,

          uid,

          rewardPurpose,

          transactionId,

          customData,

          userId:
            callbackUserId || uid,

          rewardAmount:
            verifiedAd.rewardAmount,

          rewardItem:
            normalizeString(
              verifiedAd.rewardItem,
            ),

          adUnit:
            normalizeString(
              verifiedAd.adUnit,
            ),

          adNetwork:
            normalizeString(
              verifiedAd.adNetwork,
            ),

          timestamp:
            verifiedAd.timestamp,

          keyId:
            normalizeString(
              verifiedAd.keyId,
            ),
        };


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
              normalizedVerifiedAd.adUnit,

            rewardAmount:
              normalizedVerifiedAd.rewardAmount,

            rewardItem:
              normalizedVerifiedAd.rewardItem,

            keyId:
              normalizedVerifiedAd.keyId,
          },
        );


        // ======================================================
        // 💾 SAVE VERIFIED REWARD
        // ======================================================

        const result =
          await saveVerifiedAdMobReward(
            uid,

            transactionId,

            normalizedVerifiedAd,

            rewardPurpose,
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
        // ❌ ERROR
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
                : "Unknown error.",
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
            success: false,

            verified: true,

            rewarded: false,

            error:
              "AdMob transaction conflict.",
          });

          return;
        }


        // ======================================================
        // ❌ GENERAL SSV ERROR
        // ======================================================
        //
        // Emme paljasta asiakkaalle sisäisiä virhetietoja.
        //
        // ======================================================

        res.status(
          400,
        ).json({
          success: false,

          verified: false,

          rewarded: false,

          error:
            "Invalid AdMob SSV callback.",
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