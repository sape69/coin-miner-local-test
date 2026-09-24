"use strict";

// ============================================================
// 🐱 STELLURIINI - ADMOB SSV FUNCTION
// ============================================================
//
// Vastuu:
//
// - Vastaanottaa AdMob Rewarded SSV callbackin
// - Käyttää admobService.js:n kryptografista varmennusta
// - Validoi varmennetun AdMob-datan
// - Tallentaa varmennetun rewardin admobRewards-kokoelmaan
// - Tallentaa erillisen audit-historian
// - Estää transaction_id:n uudelleenkäytön
//
// EI:
//
// - käynnistä louhintaa
// - aktivoi Power Boostia
// - muuta mining-tilaa
// - lisää STL-saldoa
//
// AdMob reward toimii ainoastaan valtuutuksena:
//
// - Mining Start
// - Power Boost
//
// Varsinainen mining-logiikka tapahtuu
// miningFunctions.js-tiedostossa.
//
// ============================================================

const {
  onRequest,
} = require("firebase-functions/v2/https");

const {
  db,
  FieldValue,
} = require("../firebase/firebase");

const {
  verifyAdMobCallback,
  getExpectedAdMobConfig,
  validateTransactionId,
  validateUid,
  validateRewardPurpose,
  validateTimestamp,
  validateAdNetwork,
  validateKeyId,
  validateSignature,
} = require("../services/admobService");

const {
  getHistoryCollection,
  getAdMobRewardRef,
} = require("../utils/userUtils");

// ============================================================
// CONSTANTS
// ============================================================

const MAX_QUERY_PARAMETERS = 20;

const MAX_TRANSACTION_ID_BYTES = 1500;

const MAX_USER_ID_BYTES = 1500;

const MAX_CUSTOM_DATA_BYTES = 1500;

// ============================================================
// HELPERS
// ============================================================

function createError(
  code,
  message,
) {
  const error =
    new Error(message);

  error.code =
    code;

  return error;
}

function normalizeString(
  value,
) {
  return typeof value === "string"
    ? value.trim()
    : "";
}

function getUtf8ByteLength(
  value,
) {
  return Buffer.byteLength(
    value,
    "utf8",
  );
}

// ============================================================
// FIRESTORE DOCUMENT ID VALIDATION
// ============================================================
//
// Firestore document ID:
//
// - ei saa olla tyhjä
// - ei saa olla pelkkää whitespacea
// - ei saa sisältää "/"
// - "." ja ".." eivät ole sallittuja
// - koko on rajoitettu
//
// transaction_id on ensin validoitu admobService.js:ssä
// AdMobin transaction_id-säännöillä.
//
// ============================================================

function isValidFirestoreDocumentId(
  value,
  name,
  maxBytes = MAX_TRANSACTION_ID_BYTES,
) {
  const parameterName =
    normalizeString(name) ||
    "documentId";

  if (
    typeof value !== "string"
  ) {
    throw createError(
      "ADMOB_INVALID_TRANSACTION_ID",
      `${parameterName} must be a string.`,
    );
  }

  if (
    value.length === 0
  ) {
    throw createError(
      "ADMOB_INVALID_TRANSACTION_ID",
      `${parameterName} cannot be empty.`,
    );
  }

  if (
    value.trim().length === 0
  ) {
    throw createError(
      "ADMOB_INVALID_TRANSACTION_ID",
      `${parameterName} cannot contain only whitespace.`,
    );
  }

  if (
    value.includes("/")
  ) {
    throw createError(
      "ADMOB_INVALID_TRANSACTION_ID",
      `${parameterName} cannot contain "/".`,
    );
  }

  if (
    value === "." ||
    value === ".."
  ) {
    throw createError(
      "ADMOB_INVALID_TRANSACTION_ID",
      `${parameterName} cannot be "." or "..".`,
    );
  }

  // Firestore dokumentaatio varaa "." ja "..".
  //
  // Aikaisempi koodi käytti:
  //
  // /^.*$/
  //
  // joka täsmää käytännössä kaikkiin merkkijonoihin
  // ja aiheutti sen, että jokainen transaction_id hylättiin.
  //
  // Tarkistus tehdään siksi eksplisiittisesti yllä.

  const byteLength =
    getUtf8ByteLength(value);

  if (
    byteLength > maxBytes
  ) {
    throw createError(
      "ADMOB_INVALID_TRANSACTION_ID",
      `${parameterName} exceeds the Firestore document ID size limit.`,
    );
  }

  return value;
}

// ============================================================
// OPTIONAL USER ID
// ============================================================

function validateOptionalUserId(
  value,
) {
  if (
    value === undefined ||
    value === null
  ) {
    return "";
  }

  const userId =
    normalizeString(value);

  if (!userId) {
    return "";
  }

  if (
    getUtf8ByteLength(userId) >
    MAX_USER_ID_BYTES
  ) {
    throw createError(
      "ADMOB_INVALID_UID",
      "Verified AdMob user_id is too large.",
    );
  }

  if (
    !validateUid(userId)
  ) {
    throw createError(
      "ADMOB_INVALID_UID",
      "Verified AdMob user_id is invalid.",
    );
  }

  return userId;
}

// ============================================================
// CUSTOM DATA
// ============================================================

function validateCustomData(
  value,
  expected,
) {
  const customData =
    normalizeString(value);

  if (!customData) {
    throw createError(
      "ADMOB_CUSTOM_DATA_MISSING",
      "Verified AdMob custom_data is missing.",
    );
  }

  if (
    getUtf8ByteLength(customData) >
    MAX_CUSTOM_DATA_BYTES
  ) {
    throw createError(
      "ADMOB_CUSTOM_DATA_INVALID",
      "Verified AdMob custom_data is too large.",
    );
  }

  if (
    customData !== expected
  ) {
    throw createError(
      "ADMOB_CUSTOM_DATA_MISMATCH",
      "Verified custom_data does not match.",
    );
  }

  return customData;
}

// ============================================================
// VALIDATE VERIFIED DATA
// ============================================================

function validateVerifiedAdData(
  verifiedAd,
) {
  if (
    !verifiedAd ||
    typeof verifiedAd !== "object" ||
    verifiedAd.verified !== true
  ) {
    throw createError(
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
    throw createError(
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
    throw createError(
      "ADMOB_INVALID_REWARD_PURPOSE",
      "Verified AdMob reward purpose is invalid.",
    );
  }

  // ----------------------------------------------------------
  // TRANSACTION ID
  // ----------------------------------------------------------

  const rawTransactionId =
    validateTransactionId(
      verifiedAd.transactionId,
    );

  if (!rawTransactionId) {
    throw createError(
      "ADMOB_INVALID_TRANSACTION_ID",
      "Verified AdMob transaction_id is invalid.",
    );
  }

  const transactionId =
    isValidFirestoreDocumentId(
      rawTransactionId,
      "transactionId",
      MAX_TRANSACTION_ID_BYTES,
    );

  // ----------------------------------------------------------
  // EXPECTED CONFIGURATION
  // ----------------------------------------------------------

  const config =
    getExpectedAdMobConfig(
      rewardPurpose,
    );

  if (
    !config ||
    typeof config !== "object"
  ) {
    throw createError(
      "ADMOB_INVALID_REWARD_CONFIGURATION",
      "AdMob reward configuration is invalid.",
    );
  }

  // ----------------------------------------------------------
  // REWARD AMOUNT
  // ----------------------------------------------------------

  const rewardAmount =
    Number(
      verifiedAd.rewardAmount,
    );

  const expectedRewardAmount =
    Number(
      config.rewardAmount,
    );

  if (
    !Number.isSafeInteger(
      rewardAmount,
    ) ||
    rewardAmount < 0 ||
    !Number.isSafeInteger(
      expectedRewardAmount,
    ) ||
    expectedRewardAmount < 0 ||
    rewardAmount !==
      expectedRewardAmount
  ) {
    throw createError(
      "ADMOB_INVALID_REWARD_AMOUNT",
      "Verified reward amount is invalid.",
    );
  }

  // ----------------------------------------------------------
  // REWARD ITEM
  // ----------------------------------------------------------

  const rewardItem =
    normalizeString(
      verifiedAd.rewardItem,
    );

  const expectedRewardItem =
    normalizeString(
      config.rewardItem,
    );

  if (
    !rewardItem ||
    !expectedRewardItem ||
    rewardItem !==
      expectedRewardItem
  ) {
    throw createError(
      "ADMOB_INVALID_REWARD_ITEM",
      "Verified reward item is invalid.",
    );
  }

  // ----------------------------------------------------------
  // AD UNIT
  // ----------------------------------------------------------

  const adUnit =
    normalizeString(
      verifiedAd.adUnit,
    );

  const expectedAdUnit =
    normalizeString(
      config.adUnit,
    );

  if (
    !adUnit ||
    !expectedAdUnit ||
    adUnit !==
      expectedAdUnit
  ) {
    throw createError(
      "ADMOB_INVALID_AD_UNIT",
      "Verified ad unit is invalid.",
    );
  }

  // ----------------------------------------------------------
  // AD NETWORK
  // ----------------------------------------------------------

  const adNetwork =
    validateAdNetwork(
      verifiedAd.adNetwork,
    );

  if (!adNetwork) {
    throw createError(
      "ADMOB_INVALID_AD_NETWORK",
      "Verified AdMob ad network is invalid.",
    );
  }

  // ----------------------------------------------------------
  // TIMESTAMP
  // ----------------------------------------------------------

  const timestamp =
    validateTimestamp(
      verifiedAd.timestamp,
    );

  if (!timestamp) {
    throw createError(
      "ADMOB_INVALID_TIMESTAMP",
      "Verified AdMob timestamp is invalid.",
    );
  }

  // ----------------------------------------------------------
  // KEY ID
  // ----------------------------------------------------------

  const keyId =
    validateKeyId(
      verifiedAd.keyId,
    );

  if (!keyId) {
    throw createError(
      "ADMOB_INVALID_KEY_ID",
      "Verified AdMob key_id is invalid.",
    );
  }

  // ----------------------------------------------------------
  // SIGNATURE
  // ----------------------------------------------------------

  const signature =
    validateSignature(
      verifiedAd.signature,
    );

  if (!signature) {
    throw createError(
      "ADMOB_INVALID_SIGNATURE",
      "Verified AdMob signature is invalid.",
    );
  }

  // ----------------------------------------------------------
  // CUSTOM DATA
  // ----------------------------------------------------------

  const expectedCustomData =
    `${uid}:${rewardPurpose}`;

  const customData =
    validateCustomData(
      verifiedAd.customData,
      expectedCustomData,
    );

  // ----------------------------------------------------------
  // USER ID
  // ----------------------------------------------------------

  const userId =
    validateOptionalUserId(
      verifiedAd.userId,
    );

  if (
    userId &&
    userId !== uid
  ) {
    throw createError(
      "ADMOB_USER_ID_MISMATCH",
      "AdMob user_id does not match verified UID.",
    );
  }

  // ----------------------------------------------------------
  // FINAL NORMALIZED DATA
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
// DUPLICATE CHECK
// ============================================================

function isSameVerifiedReward(
  existing,
  current,
) {
  if (
    !existing ||
    typeof existing !== "object" ||
    !current ||
    typeof current !== "object"
  ) {
    return false;
  }

  return (
    normalizeString(existing.uid) ===
      current.uid &&

    normalizeString(existing.rewardPurpose) ===
      current.rewardPurpose &&

    normalizeString(existing.transactionId) ===
      current.transactionId &&

    normalizeString(existing.adUnit) ===
      current.adUnit &&

    normalizeString(existing.adNetwork) ===
      current.adNetwork &&

    Number(existing.rewardAmount) ===
      current.rewardAmount &&

    normalizeString(existing.rewardItem) ===
      current.rewardItem &&

    Number(existing.timestamp) ===
      current.timestamp &&

    normalizeString(existing.keyId) ===
      current.keyId &&

    normalizeString(existing.signature) ===
      current.signature &&

    normalizeString(existing.customData) ===
      current.customData &&

    normalizeString(existing.userId) ===
      current.userId
  );
}

// ============================================================
// AUDIT CHECK
// ============================================================

function isSameVerifiedHistory(
  existing,
  current,
) {
  if (
    !existing ||
    typeof existing !== "object" ||
    !current ||
    typeof current !== "object"
  ) {
    return false;
  }

  return (
    normalizeString(existing.uid) ===
      current.uid &&

    normalizeString(existing.type) ===
      "admob_verified" &&

    normalizeString(existing.rewardType) ===
      "admob" &&

    normalizeString(existing.rewardPurpose) ===
      current.rewardPurpose &&

    normalizeString(existing.adMobTransactionId) ===
      current.transactionId &&

    normalizeString(existing.transactionId) ===
      current.transactionId &&

    normalizeString(existing.adNetwork) ===
      current.adNetwork &&

    normalizeString(existing.adUnit) ===
      current.adUnit &&

    Number(existing.rewardAmount) ===
      current.rewardAmount &&

    normalizeString(existing.rewardItem) ===
      current.rewardItem &&

    Number(existing.amount) ===
      0 &&

    Number(existing.timestamp) ===
      current.timestamp &&

    normalizeString(existing.keyId) ===
      current.keyId &&

    normalizeString(existing.signature) ===
      current.signature &&

    normalizeString(existing.customData) ===
      current.customData &&

    normalizeString(existing.userId) ===
      current.userId
  );
}

// ============================================================
// BUILD AUDIT DATA
// ============================================================
//
// Yksi paikka audit-dokumentin rakenteelle.
//
// Tätä käytetään:
//
// - uuden rewardin luonnissa
// - puuttuvan audit-dokumentin korjaamisessa
//
// ============================================================

function buildAuditData(
  data,
) {
  return {
    uid:
      data.uid,

    type:
      "admob_verified",

    title:
      data.rewardPurpose ===
      "power_boost"
        ? "Stella Power Boost Ad Verified 🐱📺⚡"
        : "Stella Mining Start Ad Verified 🐱📺⛏️",

    // AdMob SSV ei itsessään maksa STL:ää.
    amount:
      0,

    rewardType:
      "admob",

    rewardPurpose:
      data.rewardPurpose,

    adMobTransactionId:
      data.transactionId,

    transactionId:
      data.transactionId,

    adNetwork:
      data.adNetwork,

    adUnit:
      data.adUnit,

    rewardAmount:
      data.rewardAmount,

    rewardItem:
      data.rewardItem,

    timestamp:
      data.timestamp,

    keyId:
      data.keyId,

    signature:
      data.signature,

    customData:
      data.customData,

    userId:
      data.userId,

    verified:
      true,

    createdAt:
      FieldValue.serverTimestamp(),
  };
}

// ============================================================
// BUILD REWARD DATA
// ============================================================

function buildRewardData(
  data,
) {
  return {
    // --------------------------------------------------------
    // VERIFICATION STATE
    // --------------------------------------------------------

    verified:
      true,

    verifiedAt:
      FieldValue.serverTimestamp(),

    ssvVerifiedAt:
      FieldValue.serverTimestamp(),

    // --------------------------------------------------------
    // IDENTITY
    // --------------------------------------------------------

    uid:
      data.uid,

    transactionId:
      data.transactionId,

    rewardType:
      "admob",

    rewardPurpose:
      data.rewardPurpose,

    // --------------------------------------------------------
    // REWARD DATA
    // --------------------------------------------------------

    rewardAmount:
      data.rewardAmount,

    rewardItem:
      data.rewardItem,

    // --------------------------------------------------------
    // ADMOB DATA
    // --------------------------------------------------------

    adNetwork:
      data.adNetwork,

    adUnit:
      data.adUnit,

    timestamp:
      data.timestamp,

    keyId:
      data.keyId,

    signature:
      data.signature,

    customData:
      data.customData,

    userId:
      data.userId,

    // --------------------------------------------------------
    // MINING CLAIM STATE
    // --------------------------------------------------------

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

    // --------------------------------------------------------
    // POWER BOOST CLAIM STATE
    // --------------------------------------------------------

    powerBoostClaimed:
      false,

    powerBoostClaimedAt:
      null,

    powerBoostClaimedBy:
      null,

    powerBoostTransactionId:
      null,

    // --------------------------------------------------------
    // GENERIC CONSUMPTION STATE
    // --------------------------------------------------------

    rewardConsumed:
      false,

    consumedAt:
      null,

    consumedBy:
      null,

    // --------------------------------------------------------
    // TIMESTAMPS
    // --------------------------------------------------------

    createdAt:
      FieldValue.serverTimestamp(),

    updatedAt:
      FieldValue.serverTimestamp(),
  };
}

// ============================================================
// SAVE VERIFIED ADMOB REWARD
// ============================================================

async function saveVerifiedAdMobReward(
  verifiedAd,
) {
  const data =
    validateVerifiedAdData(
      verifiedAd,
    );

  const rewardRef =
    getAdMobRewardRef(
      data.transactionId,
    );

  if (
    !rewardRef ||
    typeof rewardRef !== "object"
  ) {
    throw createError(
      "ADMOB_REWARD_REFERENCE_ERROR",
      "Unable to create AdMob reward reference.",
    );
  }

  const historyCollection =
    getHistoryCollection(
      data.uid,
    );

  if (
    !historyCollection ||
    typeof historyCollection.doc !==
      "function"
  ) {
    throw createError(
      "ADMOB_HISTORY_REFERENCE_ERROR",
      "Unable to create history collection.",
    );
  }

  // ----------------------------------------------------------
  // AUDIT DOCUMENT ID
  // ----------------------------------------------------------

  const historyDocumentId =
    `admob_${data.transactionId}`;

  if (
    getUtf8ByteLength(
      historyDocumentId,
    ) >
    MAX_TRANSACTION_ID_BYTES
  ) {
    throw createError(
      "ADMOB_INVALID_TRANSACTION_ID",
      "AdMob audit document ID is too large.",
    );
  }

  const historyRef =
    historyCollection.doc(
      historyDocumentId,
    );

  if (
    !historyRef ||
    typeof historyRef !== "object"
  ) {
    throw createError(
      "ADMOB_HISTORY_REFERENCE_ERROR",
      "Unable to create AdMob history reference.",
    );
  }

  const rewardData =
    buildRewardData(data);

  const auditData =
    buildAuditData(data);

  // ----------------------------------------------------------
  // ATOMIC TRANSACTION
  // ----------------------------------------------------------
  //
  // transaction_id toimii idempotency-avaimena.
  //
  // Kaikki read-operaatiot tehdään ennen write-operaatioita.
  //
  // ----------------------------------------------------------

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
        const existing =
          rewardSnapshot.data() || {};

        // Sama transaction_id ei saa koskaan tarkoittaa
        // eri rewardia.

        if (
          !isSameVerifiedReward(
            existing,
            data,
          )
        ) {
          throw createError(
            "ADMOB_TRANSACTION_CONFLICT",
            "AdMob transaction_id conflict.",
          );
        }

        // ----------------------------------------------------
        // REPAIR / CONFIRM VERIFIED STATE
        // ----------------------------------------------------

        let repairedVerified =
          false;

        if (
          existing.verified !== true
        ) {
          transaction.set(
            rewardRef,
            {
              verified:
                true,

              verifiedAt:
                FieldValue.serverTimestamp(),

              ssvVerifiedAt:
                FieldValue.serverTimestamp(),

              updatedAt:
                FieldValue.serverTimestamp(),
            },
            {
              merge:
                true,
            },
          );

          repairedVerified =
            true;
        }

        // ----------------------------------------------------
        // EXISTING AUDIT
        // ----------------------------------------------------

        if (
          historySnapshot.exists
        ) {
          if (
            !isSameVerifiedHistory(
              historySnapshot.data() || {},
              data,
            )
          ) {
            throw createError(
              "ADMOB_AUDIT_CONSISTENCY_ERROR",
              "AdMob reward and audit history are inconsistent.",
            );
          }

          console.log(
            "🐱 AdMob duplicate SSV ignored.",
            {
              uid:
                data.uid,

              transactionId:
                data.transactionId,

              rewardPurpose:
                data.rewardPurpose,

              repairedVerified,

              repairedAudit:
                false,
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

            repairedVerified,

            repairedAudit:
              false,

            transactionId:
              data.transactionId,

            rewardPurpose:
              data.rewardPurpose,
          };
        }

        // ----------------------------------------------------
        // MISSING AUDIT
        // ----------------------------------------------------
        //
        // Reward on jo varmennettu ja sen transaction_id
        // täsmää täydellisesti.
        //
        // Audit voidaan turvallisesti rakentaa uudelleen
        // saman atomisen Firestore-transaktion sisällä.
        //
        // ----------------------------------------------------

        transaction.create(
          historyRef,
          auditData,
        );

        console.warn(
          "⚠️ AdMob reward existed without audit history. Audit was repaired.",
          {
            uid:
              data.uid,

            transactionId:
              data.transactionId,

            rewardPurpose:
              data.rewardPurpose,
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

          repairedVerified,

          repairedAudit:
            true,

          transactionId:
            data.transactionId,

          rewardPurpose:
            data.rewardPurpose,
        };
      }

      // ======================================================
      // ORPHAN AUDIT
      // ======================================================
      //
      // Audit ei saa olla olemassa ilman authoritative
      // reward-dokumenttia.
      //
      // Tämä on turvallisuussyistä pysyvä ristiriita.
      //
      // ======================================================

      if (
        historySnapshot.exists
      ) {
        throw createError(
          "ADMOB_AUDIT_CONSISTENCY_ERROR",
          "Audit history exists without reward document.",
        );
      }

      // ======================================================
      // AUTHORITATIVE REWARD DOCUMENT
      // ======================================================

      transaction.create(
        rewardRef,
        rewardData,
      );

      // ======================================================
      // AUDIT HISTORY
      // ======================================================

      transaction.create(
        historyRef,
        auditData,
      );

      // ======================================================
      // RESULT
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

        transactionId:
          data.transactionId,

        rewardPurpose:
          data.rewardPurpose,

        rewardAmount:
          data.rewardAmount,

        rewardItem:
          data.rewardItem,
      };
    },
  );
}

// ============================================================
// PERMANENT ERROR CODES
// ============================================================
//
// Näissä tapauksissa AdMob SSV:tä ei pidä käsitellä uudelleen.
//
// HTTP 200 estää tarpeettoman uudelleenyrityksen.
//
// ============================================================

const PERMANENT_ERROR_CODES =
  new Set([
    "ADMOB_INVALID_SIGNATURE",

    "ADMOB_CRYPTO_VERIFICATION_ERROR",

    "ADMOB_INVALID_KEY_ID",

    "ADMOB_PUBLIC_KEY_NOT_FOUND",

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

    "ADMOB_INVALID_REWARD_CONFIGURATION",

    "ADMOB_TRANSACTION_CONFLICT",

    "ADMOB_AUDIT_CONSISTENCY_ERROR",

    "ADMOB_REWARD_REFERENCE_ERROR",

    "ADMOB_HISTORY_REFERENCE_ERROR",
  ]);

// ============================================================
// ADMOB SSV ENDPOINT
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
        // METHOD
        // ====================================================

        if (
          req.method === "HEAD"
        ) {
          res
            .status(200)
            .end();

          return;
        }

        if (
          req.method !== "GET"
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
        // QUERY
        // ====================================================

        const query =
          req.query || {};

        const queryKeys =
          Object.keys(query);

        if (
          queryKeys.length >
          MAX_QUERY_PARAMETERS
        ) {
          throw createError(
            "ADMOB_QUERY_STRING_TOO_LARGE",
            "AdMob query contains too many parameters.",
          );
        }

        // ====================================================
        // HEALTH CHECK
        // ====================================================

        if (
          queryKeys.length === 0
        ) {
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
            });

          return;
        }

        console.log(
          "🐱 AdMob SSV callback received.",
        );

        // ====================================================
        // CRYPTOGRAPHIC VERIFICATION
        // ====================================================

        const verifiedAd =
          await verifyAdMobCallback(
            req,
          );

        if (
          !verifiedAd ||
          verifiedAd.verified !== true
        ) {
          throw createError(
            "ADMOB_INVALID_SIGNATURE",
            "Invalid AdMob SSV callback.",
          );
        }

        ssvVerified =
          true;

        // ====================================================
        // DATA VALIDATION
        // ====================================================

        const validatedAd =
          validateVerifiedAdData(
            verifiedAd,
          );

        console.log(
          "🐱✅ AdMob SSV verified.",
          {
            uid:
              validatedAd.uid,

            transactionId:
              validatedAd.transactionId,

            rewardPurpose:
              validatedAd.rewardPurpose,
          },
        );

        // ====================================================
        // SAVE
        // ====================================================

        const result =
          await saveVerifiedAdMobReward(
            validatedAd,
          );

        console.log(
          "🐱 AdMob reward stored.",
          {
            uid:
              validatedAd.uid,

            transactionId:
              validatedAd.transactionId,

            rewardPurpose:
              validatedAd.rewardPurpose,

            duplicate:
              result.duplicate,

            repairedVerified:
              result.repairedVerified ===
              true,

            repairedAudit:
              result.repairedAudit ===
              true,
          },
        );

        // ====================================================
        // SUCCESS
        // ====================================================

        res
          .status(200)
          .json(result);
      } catch (
        error
      ) {
        const code =
          error?.code
            ? String(error.code)
            : "UNKNOWN";

        const message =
          error?.message ||
          "Unknown AdMob error.";

        console.error(
          "❌ AdMob SSV processing failed.",
          {
            code,
            message,
          },
        );

        // ====================================================
        // PERMANENT ERROR
        // ====================================================

        if (
          PERMANENT_ERROR_CODES.has(
            code,
          )
        ) {
          res
            .status(200)
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
                code,
            });

          return;
        }

        // ====================================================
        // TEMPORARY / INTERNAL ERROR
        // ====================================================
        //
        // HTTP 500 antaa AdMobil­le mahdollisuuden yrittää
        // callbackia uudelleen infrastruktuuri- tai
        // Firestore-ongelman jälkeen.
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
// EXPORTS
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