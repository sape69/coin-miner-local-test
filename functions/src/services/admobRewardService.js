"use strict";

// ============================================================
// 🐱 STELLURIINI - ADMOB REWARD SERVICE
// ============================================================
//
// Vastuu:
//
// - AdMob SSV:n jälkeen tallennetun rewardin validointi
// - UID:n validointi
// - transaction_id:n validointi
// - reward purpose -validointi
// - rewardin aikarajan tarkistus
// - claim/replay-suojauksen tarkistus
// - SSV:n ja clientin claim-pyynnön ajoituseron käsittely
//
// Tämä service EI:
//
// - muuta STL-saldoa
// - käynnistä louhintaa
// - aktivoi Power Boostia
// - varmista AdMob SSV:n allekirjoitusta
//
// AdMob SSV:n varsinainen varmennus kuuluu:
//
// functions/src/services/admobService.js
//
// ============================================================

const { db } =
  require("../firebase/firebase");

const {
  getAdMobRewardRef,
} = require("../utils/userUtils");

// ============================================================
// CONFIG
// ============================================================

const REWARD_MAX_AGE_MS =
  24 * 60 * 60 * 1000;

const REWARD_FUTURE_TOLERANCE_MS =
  5 * 60 * 1000;

// AdMob SSV ja Flutterin rewarded-ad callback
// ovat kaksi erillistä tapahtumaa.
//
// Flutter voi kutsua claimMining / powerBoost
// ennen kuin SSV on ehtinyt kirjoittaa reward-dokumentin.
//
// Odotetaan vain lyhyesti.
//
// Rewardia EI koskaan hyväksytä ilman:
//
// verified === true
//
// ============================================================

const SSV_WAIT_TIMEOUT_MS =
  5000;

const SSV_RETRY_DELAY_MS =
  250;

// Fallback-hakua käytetään vain, jos client ei toimita
// transaction_id:tä.
//
// Direct transaction_id -haku on aina ensisijainen.
//
// Rajataan fallback-haku, jotta käyttäjän koko reward-historiaa
// ei lueta tarpeettomasti.
//
// ============================================================

const MAX_FALLBACK_REWARD_DOCS =
  50;

const MAX_UID_LENGTH =
  128;

const MAX_TRANSACTION_ID_LENGTH =
  256;

const VALID_REWARD_PURPOSES =
  new Set([
    "mining_start",
    "power_boost",
  ]);

// ============================================================
// HELPERS
// ============================================================

function normalizeString(value) {
  return typeof value === "string"
    ? value.trim()
    : "";
}

function number(
  value,
  fallback = 0,
) {
  const result =
    Number(value);

  return Number.isFinite(result)
    ? result
    : fallback;
}

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

function sleep(milliseconds) {
  return new Promise(
    (resolve) => {
      setTimeout(
        resolve,
        milliseconds,
      );
    },
  );
}

// ============================================================
// UID
// ============================================================

function validateUid(value) {
  const uid =
    normalizeString(value);

  if (
    !uid ||
    uid.length >
      MAX_UID_LENGTH
  ) {
    return "";
  }

  return /^[A-Za-z0-9._-]+$/.test(
    uid,
  )
    ? uid
    : "";
}

// ============================================================
// TRANSACTION ID
// ============================================================

function validateTransactionId(
  value,
) {
  const transactionId =
    normalizeString(value);

  if (
    !transactionId ||
    transactionId.length >
      MAX_TRANSACTION_ID_LENGTH
  ) {
    return "";
  }

  // Estetään kontrollimerkit.
  //
  // Tämä pidetään yhdenmukaisena
  // admobService.js:n transaction_id-validoinnin kanssa.

  if (
    /[\x00-\x1F\x7F]/.test(
      transactionId,
    )
  ) {
    return "";
  }

  return transactionId;
}

// ============================================================
// REWARD PURPOSE
// ============================================================

function validateRewardPurpose(
  value,
) {
  const purpose =
    normalizeString(value);

  return VALID_REWARD_PURPOSES.has(
    purpose,
  )
    ? purpose
    : "";
}

// ============================================================
// TIMESTAMP
// ============================================================

function timestampMs(value) {
  if (!value) {
    return 0;
  }

  // Firestore Timestamp

  if (
    typeof value.toMillis ===
    "function"
  ) {
    try {
      const result =
        value.toMillis();

      return Number.isFinite(
        result,
      )
        ? result
        : 0;
    } catch (_) {
      return 0;
    }
  }

  // Firestore Timestamp / Date-like object

  if (
    typeof value.toDate ===
    "function"
  ) {
    try {
      const date =
        value.toDate();

      if (
        date instanceof Date &&
        Number.isFinite(
          date.getTime(),
        )
      ) {
        return date.getTime();
      }
    } catch (_) {
      return 0;
    }
  }

  // Native Date

  if (
    value instanceof Date
  ) {
    return Number.isFinite(
      value.getTime(),
    )
      ? value.getTime()
      : 0;
  }

  // ISO date string

  if (
    typeof value === "string"
  ) {
    const result =
      new Date(value).getTime();

    return Number.isFinite(
      result,
    )
      ? result
      : 0;
  }

  // Epoch milliseconds

  if (
    typeof value === "number" &&
    Number.isFinite(value)
  ) {
    return value;
  }

  return 0;
}

// ============================================================
// REWARD CREATED TIME
// ============================================================

function getRewardCreatedAtMs(
  data,
) {
  if (
    !data ||
    typeof data !== "object"
  ) {
    return 0;
  }

  const candidates = [
    data.verifiedAt,
    data.ssvVerifiedAt,
    data.createdAt,
    data.timestamp,
  ];

  for (
    const value of candidates
  ) {
    const milliseconds =
      timestampMs(value);

    if (
      milliseconds > 0
    ) {
      return milliseconds;
    }
  }

  return 0;
}

// ============================================================
// REWARD TIMING
// ============================================================

function validateRewardTiming(
  data,
  options = {},
) {
  const referenceNowMs =
    number(
      options.referenceNowMs,
      Date.now(),
    );

  const rewardCreatedAtMs =
    getRewardCreatedAtMs(
      data,
    );

  if (
    rewardCreatedAtMs <= 0
  ) {
    throw createError(
      "ADMOB_REWARD_TIMESTAMP_MISSING",
      "AdMob reward timestamp is missing.",
    );
  }

  if (
    rewardCreatedAtMs >
    referenceNowMs +
      REWARD_FUTURE_TOLERANCE_MS
  ) {
    throw createError(
      "ADMOB_REWARD_TIMESTAMP_INVALID",
      "AdMob reward timestamp is in the future.",
    );
  }

  if (
    referenceNowMs -
      rewardCreatedAtMs >
    REWARD_MAX_AGE_MS
  ) {
    throw createError(
      "ADMOB_REWARD_EXPIRED",
      "AdMob reward has expired.",
    );
  }
}

// ============================================================
// DOCUMENT VALUES
// ============================================================

function getDocumentTransactionId(
  data,
) {
  if (
    !data ||
    typeof data !== "object"
  ) {
    return "";
  }

  const candidates = [
    data.transactionId,
    data.adMobTransactionId,
    data.adRewardTransactionId,
    data.transaction_id,
  ];

  for (
    const value of candidates
  ) {
    const transactionId =
      validateTransactionId(
        value,
      );

    if (transactionId) {
      return transactionId;
    }
  }

  return "";
}

function getDocumentRewardPurpose(
  data,
) {
  if (
    !data ||
    typeof data !== "object"
  ) {
    return "";
  }

  const candidates = [
    data.rewardPurpose,
    data.reward_purpose,
  ];

  for (
    const value of candidates
  ) {
    const purpose =
      validateRewardPurpose(
        value,
      );

    if (purpose) {
      return purpose;
    }
  }

  return "";
}

function getDocumentUid(
  data,
) {
  if (
    !data ||
    typeof data !== "object"
  ) {
    return "";
  }

  const candidates = [
    data.uid,
    data.userId,
    data.user_id,
  ];

  for (
    const value of candidates
  ) {
    const uid =
      validateUid(value);

    if (uid) {
      return uid;
    }
  }

  return "";
}

// ============================================================
// CLAIM FIELD
// ============================================================

function getClaimField(
  rewardPurpose,
) {
  const purpose =
    validateRewardPurpose(
      rewardPurpose,
    );

  switch (purpose) {
    case "mining_start":
      return "miningStartClaimed";

    case "power_boost":
      return "powerBoostClaimed";

    default:
      throw createError(
        "ADMOB_INVALID_REWARD_PURPOSE",
        "Unknown AdMob reward purpose.",
      );
  }
}

// ============================================================
// REPLAY / CLAIM CHECK
// ============================================================

function isRewardAlreadyClaimed(
  data,
  rewardPurpose,
) {
  if (
    !data ||
    typeof data !== "object"
  ) {
    return false;
  }

  const claimField =
    getClaimField(
      rewardPurpose,
    );

  return (
    data[claimField] === true ||
    data.rewardConsumed === true
  );
}

// ============================================================
// VERIFIED REWARD VALIDATION
// ============================================================

function validateVerifiedRewardDocument(
  rewardSnapshot,
  uid,
  expectedPurpose,
  claimField,
  options = {},
) {
  if (
    !rewardSnapshot ||
    typeof rewardSnapshot.exists !==
      "boolean"
  ) {
    throw createError(
      "ADMOB_REWARD_DOCUMENT_MISSING",
      "AdMob reward document is missing.",
    );
  }

  if (
    !rewardSnapshot.exists
  ) {
    throw createError(
      "ADMOB_REWARD_NOT_FOUND",
      "Verified AdMob reward was not found.",
    );
  }

  const data =
    rewardSnapshot.data() || {};

  // ----------------------------------------------------------
  // UID
  // ----------------------------------------------------------

  const validatedUid =
    validateUid(uid);

  if (!validatedUid) {
    throw createError(
      "ADMOB_INVALID_UID",
      "UID is invalid.",
    );
  }

  // ----------------------------------------------------------
  // PURPOSE
  // ----------------------------------------------------------

  const purpose =
    validateRewardPurpose(
      expectedPurpose,
    );

  if (!purpose) {
    throw createError(
      "ADMOB_INVALID_REWARD_PURPOSE",
      "Reward purpose is invalid.",
    );
  }

  // ----------------------------------------------------------
  // CLAIM FIELD
  // ----------------------------------------------------------

  const expectedClaimField =
    getClaimField(
      purpose,
    );

  if (
    claimField &&
    claimField !==
      expectedClaimField
  ) {
    throw createError(
      "ADMOB_INVALID_CLAIM_FIELD",
      "Reward claim field does not match reward purpose.",
    );
  }

  // ----------------------------------------------------------
  // SSV VERIFICATION
  // ----------------------------------------------------------

  if (
    data.verified !== true
  ) {
    throw createError(
      "ADMOB_REWARD_NOT_VERIFIED",
      "AdMob reward has not been verified.",
    );
  }

  // ----------------------------------------------------------
  // DOCUMENT UID
  // ----------------------------------------------------------

  const documentUid =
    getDocumentUid(data);

  if (!documentUid) {
    throw createError(
      "ADMOB_REWARD_UID_MISSING",
      "Verified AdMob reward does not contain a valid UID.",
    );
  }

  if (
    documentUid !==
    validatedUid
  ) {
    throw createError(
      "ADMOB_REWARD_UID_MISMATCH",
      "Verified AdMob reward UID does not match the authenticated user.",
    );
  }

  // ----------------------------------------------------------
  // DOCUMENT PURPOSE
  // ----------------------------------------------------------

  const documentPurpose =
    getDocumentRewardPurpose(
      data,
    );

  if (!documentPurpose) {
    throw createError(
      "ADMOB_REWARD_PURPOSE_MISSING",
      "Verified AdMob reward does not contain a valid reward purpose.",
    );
  }

  if (
    documentPurpose !==
    purpose
  ) {
    throw createError(
      "ADMOB_REWARD_PURPOSE_MISMATCH",
      "Verified AdMob reward purpose does not match the requested operation.",
    );
  }

  // ----------------------------------------------------------
  // DOCUMENT TRANSACTION ID
  // ----------------------------------------------------------

  const documentTransactionId =
    getDocumentTransactionId(
      data,
    );

  if (!documentTransactionId) {
    throw createError(
      "ADMOB_REWARD_TRANSACTION_ID_MISSING",
      "Verified AdMob reward does not contain a valid transaction_id.",
    );
  }

  // ----------------------------------------------------------
  // REQUESTED TRANSACTION ID
  // ----------------------------------------------------------

  const requestedTransactionId =
    validateTransactionId(
      options.transactionId,
    );

  if (
    requestedTransactionId &&
    documentTransactionId !==
      requestedTransactionId
  ) {
    throw createError(
      "ADMOB_TRANSACTION_ID_MISMATCH",
      "AdMob transaction_id does not match the verified reward.",
    );
  }

  // ----------------------------------------------------------
  // TIMING
  // ----------------------------------------------------------

  validateRewardTiming(
    data,
    options,
  );

  // ----------------------------------------------------------
  // REPLAY / CLAIM PROTECTION
  // ----------------------------------------------------------

  if (
    isRewardAlreadyClaimed(
      data,
      purpose,
    )
  ) {
    throw createError(
      "ADMOB_REWARD_ALREADY_CLAIMED",
      "This AdMob reward has already been consumed.",
    );
  }

  // ----------------------------------------------------------
  // VERIFIED RESULT
  // ----------------------------------------------------------

  return {
    verified: true,

    rewardRef:
      rewardSnapshot.ref,

    uid:
      validatedUid,

    rewardPurpose:
      purpose,

    transactionId:
      documentTransactionId,

    claimField:
      expectedClaimField,

    data,
  };
}

// ============================================================
// VERIFIED REWARD LOOKUP
// ============================================================

async function getVerifiedReward(
  uid,
  options = {},
) {
  const validatedUid =
    validateUid(uid);

  if (!validatedUid) {
    throw createError(
      "ADMOB_INVALID_UID",
      "Authenticated UID is invalid.",
    );
  }

  const transactionId =
    validateTransactionId(
      options.transactionId,
    );

  // ==========================================================
  // DIRECT TRANSACTION LOOKUP
  // ==========================================================
  //
  // Tämä on ensisijainen reitti.
  //
  // Jos transaction_id tunnetaan,
  // haetaan täsmälleen yksi dokumentti.
  //
  // Puuttuva dokumentti antaa
  // ADMOB_REWARD_NOT_FOUND,
  // jolloin retry voi odottaa SSV:tä.
  //
  // ==========================================================

  if (transactionId) {
    const rewardRef =
      getAdMobRewardRef(
        transactionId,
      );

    if (!rewardRef) {
      throw createError(
        "ADMOB_REWARD_NOT_FOUND",
        "Verified AdMob reward reference was not found.",
      );
    }

    const rewardSnapshot =
      await rewardRef.get();

    if (
      !rewardSnapshot.exists
    ) {
      throw createError(
        "ADMOB_REWARD_NOT_FOUND",
        "Verified AdMob reward was not found yet.",
      );
    }

    return {
      rewardRef,

      rewardSnapshot,

      transactionId,
    };
  }

  // ==========================================================
  // FALLBACK: LATEST VERIFIED REWARD
  // ==========================================================
  //
  // Tätä käytetään vain, jos transaction_id:tä ei ole.
  //
  // Direct transaction_id -reitti on aina turvallisempi,
  // koska silloin tiedetään täsmälleen mikä reward kulutetaan.
  //
  // ==========================================================

  const purpose =
    validateRewardPurpose(
      options.rewardPurpose,
    );

  if (!purpose) {
    throw createError(
      "ADMOB_INVALID_REWARD_PURPOSE",
      "Reward purpose is required.",
    );
  }

  const snapshot =
    await db
      .collection("admobRewards")
      .where(
        "uid",
        "==",
        validatedUid,
      )
      .limit(
        MAX_FALLBACK_REWARD_DOCS,
      )
      .get();

  const candidates =
    snapshot.docs
      .filter((doc) => {
        const data =
          doc.data() || {};

        return (
          data.verified === true &&
          getDocumentRewardPurpose(
            data,
          ) === purpose &&
          !isRewardAlreadyClaimed(
            data,
            purpose,
          )
        );
      })
      .sort((a, b) => {
        const aTime =
          getRewardCreatedAtMs(
            a.data() || {},
          );

        const bTime =
          getRewardCreatedAtMs(
            b.data() || {},
          );

        return bTime - aTime;
      });

  if (
    !candidates.length
  ) {
    throw createError(
      "ADMOB_REWARD_NOT_FOUND",
      "No verified unconsumed AdMob reward is available yet.",
    );
  }

  // ==========================================================
  // VALIDATE CANDIDATES
  // ==========================================================
  //
  // Käydään ehdokkaat läpi järjestyksessä.
  //
  // Vanhentunut tai muuten virheellinen reward ei saa
  // estää seuraavan käyttökelpoisen rewardin löytymistä.
  //
  // ==========================================================

  let lastValidationError =
    null;

  for (
    const candidate of
    candidates
  ) {
    try {
      const candidateData =
        candidate.data() || {};

      const candidateTransactionId =
        getDocumentTransactionId(
          candidateData,
        );

      if (
        !candidateTransactionId
      ) {
        lastValidationError =
          createError(
            "ADMOB_REWARD_TRANSACTION_ID_MISSING",
            "Verified AdMob reward does not contain a valid transaction_id.",
          );

        continue;
      }

      validateVerifiedRewardDocument(
        candidate,
        validatedUid,
        purpose,
        getClaimField(
          purpose,
        ),
        {
          referenceNowMs:
            number(
              options.referenceNowMs,
              Date.now(),
            ),

          transactionId:
            candidateTransactionId,
        },
      );

      return {
        rewardRef:
          candidate.ref,

        rewardSnapshot:
          candidate,

        transactionId:
          candidateTransactionId,
      };
    } catch (error) {
      lastValidationError =
        error;
    }
  }

  if (
    lastValidationError
  ) {
    throw lastValidationError;
  }

  throw createError(
    "ADMOB_REWARD_NOT_FOUND",
    "No verified unconsumed AdMob reward is available yet.",
  );
}

// ============================================================
// WAIT FOR SSV
// ============================================================
//
// Flutter voi saada rewarded-ad callbackin ennen AdMob SSV:tä.
//
// Tästä syystä claimMining / powerBoost voi saapua ensin.
//
// Retry tehdään VAIN silloin, kun reward-dokumenttia
// ei vielä ole.
//
// Jos dokumentti löytyy mutta sen sisältö on virheellinen,
// virhe palautetaan välittömästi.
//
// ============================================================

async function getVerifiedRewardWithRetry(
  uid,
  options = {},
) {
  const startedAt =
    Date.now();

  let lastError =
    null;

  while (
    Date.now() -
      startedAt <=
    SSV_WAIT_TIMEOUT_MS
  ) {
    try {
      return await getVerifiedReward(
        uid,
        options,
      );
    } catch (error) {
      lastError =
        error;

      // Retry vain puuttuvan SSV-dokumentin tapauksessa.

      if (
        !error ||
        error.code !==
          "ADMOB_REWARD_NOT_FOUND"
      ) {
        throw error;
      }
    }

    const elapsed =
      Date.now() -
      startedAt;

    const remaining =
      SSV_WAIT_TIMEOUT_MS -
      elapsed;

    if (
      remaining <= 0
    ) {
      break;
    }

    await sleep(
      Math.min(
        SSV_RETRY_DELAY_MS,
        remaining,
      ),
    );
  }

  throw (
    lastError ||
    createError(
      "ADMOB_REWARD_NOT_FOUND",
      "No verified unconsumed AdMob reward is available yet.",
    )
  );
}

// ============================================================
// MINING START REWARD
// ============================================================

async function getVerifiedMiningStartReward(
  uid,
  options = {},
) {
  const result =
    await getVerifiedRewardWithRetry(
      uid,
      {
        ...options,

        rewardPurpose:
          "mining_start",
      },
    );

  const validated =
    validateVerifiedRewardDocument(
      result.rewardSnapshot,
      uid,
      "mining_start",
      "miningStartClaimed",
      {
        referenceNowMs:
          number(
            options.referenceNowMs,
            Date.now(),
          ),

        transactionId:
          result.transactionId,
      },
    );

  return {
    ...validated,

    rewardRef:
      result.rewardRef,

    rewardSnapshot:
      result.rewardSnapshot,
  };
}

// ============================================================
// POWER BOOST REWARD
// ============================================================

async function getVerifiedPowerBoostReward(
  uid,
  options = {},
) {
  const result =
    await getVerifiedRewardWithRetry(
      uid,
      {
        ...options,

        rewardPurpose:
          "power_boost",
      },
    );

  const validated =
    validateVerifiedRewardDocument(
      result.rewardSnapshot,
      uid,
      "power_boost",
      "powerBoostClaimed",
      {
        referenceNowMs:
          number(
            options.referenceNowMs,
            Date.now(),
          ),

        transactionId:
          result.transactionId,
      },
    );

  return {
    ...validated,

    rewardRef:
      result.rewardRef,

    rewardSnapshot:
      result.rewardSnapshot,
  };
}

// ============================================================
// EXPORTS
// ============================================================

module.exports = {
  REWARD_MAX_AGE_MS,

  REWARD_FUTURE_TOLERANCE_MS,

  SSV_WAIT_TIMEOUT_MS,

  SSV_RETRY_DELAY_MS,

  MAX_FALLBACK_REWARD_DOCS,

  validateUid,

  validateTransactionId,

  validateRewardPurpose,

  timestampMs,

  getRewardCreatedAtMs,

  validateRewardTiming,

  getDocumentTransactionId,

  getDocumentRewardPurpose,

  getDocumentUid,

  getClaimField,

  isRewardAlreadyClaimed,

  validateVerifiedRewardDocument,

  getVerifiedReward,

  getVerifiedRewardWithRetry,

  getVerifiedMiningStartReward,

  getVerifiedPowerBoostReward,
};