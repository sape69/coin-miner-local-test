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

const {
  db,
} = require("../firebase/firebase");

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

// ============================================================
// SSV WAIT
// ============================================================

const SSV_WAIT_TIMEOUT_MS =
  15000;

const SSV_INITIAL_RETRY_DELAY_MS =
  250;

const SSV_MAX_RETRY_DELAY_MS =
  1000;

// ============================================================
// FALLBACK LIMIT
// ============================================================
//
// Tämä rajoittaa käsiteltävien uusimpien ehdokkaiden määrää.
//
// HUOM:
//
// Rewardit haetaan ensin kaikilta käyttäjän dokumenteilta,
// minkä jälkeen ne järjestetään timestampin perusteella.
// Näin limit ei vahingossa rajaa pois uusinta rewardia
// Firestore-dokumentin ID-järjestyksen vuoksi.
//
// ============================================================

const MAX_FALLBACK_REWARD_DOCS =
  50;

// ============================================================
// VALIDATION LIMITS
// ============================================================

const MAX_UID_LENGTH =
  128;

const MAX_TRANSACTION_ID_LENGTH =
  256;

// ============================================================
// VALID REWARD PURPOSES
// ============================================================

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

function number(value, fallback = 0) {
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
// UID VALIDATION
// ============================================================

function validateUid(value) {
  const uid =
    normalizeString(value);

  if (
    !uid ||
    uid.length > MAX_UID_LENGTH
  ) {
    return "";
  }

  return uid;
}

// ============================================================
// TRANSACTION ID VALIDATION
// ============================================================
//
// AdMob transaction_id:tä ei käsitellä hex-arvona.
//
// Transaction ID on ulkoinen tunniste.
//
// ============================================================

function validateTransactionId(value) {
  const transactionId =
    normalizeString(value);

  if (
    !transactionId ||
    transactionId.length >
      MAX_TRANSACTION_ID_LENGTH
  ) {
    return "";
  }

  // Firestore document ID ei voi sisältää "/".
  if (
    transactionId.includes("/")
  ) {
    return "";
  }

  // Estetään kontrollimerkit.
  if (
    /[\u0000-\u001F\u007F]/.test(
      transactionId,
    )
  ) {
    return "";
  }

  return transactionId;
}

// ============================================================
// OPTIONAL TRANSACTION ID
// ============================================================

function getOptionalTransactionId(
  value,
) {
  if (
    value === undefined ||
    value === null
  ) {
    return "";
  }

  if (
    typeof value !== "string"
  ) {
    return "";
  }

  const normalized =
    normalizeString(value);

  if (!normalized) {
    return "";
  }

  return validateTransactionId(
    normalized,
  );
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
  if (
    value === undefined ||
    value === null
  ) {
    return 0;
  }

  // Firestore Timestamp.
  if (
    typeof value.toMillis ===
    "function"
  ) {
    try {
      const result =
        value.toMillis();

      return Number.isFinite(
        result,
      ) && result > 0
        ? result
        : 0;
    } catch (_) {
      return 0;
    }
  }

  // Date-like object.
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
        ) &&
        date.getTime() > 0
      ) {
        return date.getTime();
      }
    } catch (_) {
      return 0;
    }
  }

  // Native Date.
  if (
    value instanceof Date
  ) {
    const result =
      value.getTime();

    return Number.isFinite(
      result,
    ) && result > 0
      ? result
      : 0;
  }

  // String.
  if (
    typeof value === "string"
  ) {
    const normalized =
      value.trim();

    if (!normalized) {
      return 0;
    }

    // Epoch milliseconds.
    if (
      /^\d+$/.test(
        normalized,
      )
    ) {
      const epoch =
        Number(normalized);

      return Number.isSafeInteger(
        epoch,
      ) && epoch > 0
        ? epoch
        : 0;
    }

    // ISO/date string.
    const parsed =
      new Date(
        normalized,
      ).getTime();

    return Number.isFinite(
      parsed,
    ) && parsed > 0
      ? parsed
      : 0;
  }

  // Epoch milliseconds.
  if (
    typeof value === "number" &&
    Number.isFinite(value) &&
    value > 0
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

  return timestampMs(
    data.timestamp,
  );
}

// ============================================================
// REWARD TIMING VALIDATION
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

  if (
    !Number.isFinite(
      referenceNowMs,
    ) ||
    referenceNowMs <= 0
  ) {
    throw createError(
      "ADMOB_REWARD_REFERENCE_TIME_INVALID",
      "Reward reference time is invalid.",
    );
  }

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

  const ageMs =
    referenceNowMs -
    rewardCreatedAtMs;

  if (
    ageMs >
    REWARD_MAX_AGE_MS
  ) {
    throw createError(
      "ADMOB_REWARD_EXPIRED",
      "AdMob reward has expired.",
    );
  }

  if (
    ageMs < 0
  ) {
    throw createError(
      "ADMOB_REWARD_TIMESTAMP_INVALID",
      "AdMob reward timestamp is invalid.",
    );
  }

  return {
    rewardCreatedAtMs,
    ageMs,
  };
}

// ============================================================
// DOCUMENT TRANSACTION ID
// ============================================================
//
// TÄRKEÄ KORJAUS:
//
// Jos reward-dokumentissa ei ole transactionId-kenttää,
// käytetään Firestore-dokumentin ID:tä.
//
// AdMob SSV:n pitäisi normaalisti tallentaa transactionId,
// mutta olemassa olevissa dokumenteissa kenttä voi puuttua.
//
// ============================================================

function getDocumentTransactionId(
  data,
  fallbackDocumentId = "",
) {
  if (
    data &&
    typeof data === "object"
  ) {
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

      if (
        transactionId
      ) {
        return transactionId;
      }
    }
  }

  // ----------------------------------------------------------
  // FIRESTORE DOCUMENT ID FALLBACK
  // ----------------------------------------------------------

  const documentId =
    validateTransactionId(
      fallbackDocumentId,
    );

  return documentId || "";
}

// ============================================================
// DOCUMENT REWARD PURPOSE
// ============================================================

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

    if (
      purpose
    ) {
      return purpose;
    }
  }

  return "";
}

// ============================================================
// DOCUMENT UID
// ============================================================

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

    if (
      uid
    ) {
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
// VERIFIED REWARD DOCUMENT VALIDATION
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

  if (
    !validatedUid
  ) {
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

  if (
    !purpose
  ) {
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
    getDocumentUid(
      data,
    );

  if (
    !documentUid
  ) {
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

  if (
    !documentPurpose
  ) {
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
  //
  // TÄRKEÄ:
  //
  // Firestore document ID toimii fallbackina, jos
  // transactionId-kenttä puuttuu.
  //
  // ----------------------------------------------------------

  const documentTransactionId =
    getDocumentTransactionId(
      data,
      rewardSnapshot.id,
    );

  if (
    !documentTransactionId
  ) {
    throw createError(
      "ADMOB_REWARD_TRANSACTION_ID_MISSING",
      "Verified AdMob reward does not contain a valid transaction_id.",
    );
  }

  // ----------------------------------------------------------
  // DOCUMENT ID / TRANSACTION ID
  // ----------------------------------------------------------

  const documentId =
    rewardSnapshot.id;

  if (
    typeof documentId !== "string" ||
    !documentId
  ) {
    throw createError(
      "ADMOB_REWARD_DOCUMENT_ID_MISSING",
      "AdMob reward document ID is missing.",
    );
  }

  if (
    documentId !==
    documentTransactionId
  ) {
    throw createError(
      "ADMOB_TRANSACTION_ID_MISMATCH",
      "AdMob reward document ID does not match transaction_id.",
    );
  }

  // ----------------------------------------------------------
  // REQUESTED TRANSACTION ID
  // ----------------------------------------------------------

  const hasRequestedTransactionId =
    options.transactionId !==
      undefined &&
    options.transactionId !==
      null &&
    normalizeString(
      options.transactionId,
    ) !== "";

  const requestedTransactionId =
    hasRequestedTransactionId
      ? validateTransactionId(
          options.transactionId,
        )
      : "";

  if (
    hasRequestedTransactionId &&
    !requestedTransactionId
  ) {
    throw createError(
      "ADMOB_INVALID_TRANSACTION_ID",
      "Requested AdMob transaction_id is invalid.",
    );
  }

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

  const timing =
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

    rewardCreatedAtMs:
      timing.rewardCreatedAtMs,

    rewardAgeMs:
      timing.ageMs,

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

  if (
    !validatedUid
  ) {
    throw createError(
      "ADMOB_INVALID_UID",
      "Authenticated UID is invalid.",
    );
  }

  // ----------------------------------------------------------
  // OPTIONAL TRANSACTION ID
  // ----------------------------------------------------------

  const rawTransactionId =
    options.transactionId;

  const hasTransactionIdValue =
    rawTransactionId !==
      undefined &&
    rawTransactionId !==
      null &&
    normalizeString(
      rawTransactionId,
    ) !== "";

  const transactionId =
    hasTransactionIdValue
      ? getOptionalTransactionId(
          rawTransactionId,
        )
      : "";

  if (
    hasTransactionIdValue &&
    !transactionId
  ) {
    throw createError(
      "ADMOB_INVALID_TRANSACTION_ID",
      "AdMob transaction_id is invalid.",
    );
  }

  // ==========================================================
  // DIRECT TRANSACTION LOOKUP
  // ==========================================================

  if (
    transactionId
  ) {
    const rewardRef =
      getAdMobRewardRef(
        transactionId,
      );

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

    const rewardData =
      rewardSnapshot.data() || {};

    if (
      rewardData.verified !== true
    ) {
      throw createError(
        "ADMOB_REWARD_NOT_FOUND",
        "AdMob reward exists but SSV verification is not ready yet.",
      );
    }

    return {
      rewardRef,

      rewardSnapshot,

      transactionId,
    };
  }

  // ==========================================================
  // FALLBACK
  // ==========================================================

  const purpose =
    validateRewardPurpose(
      options.rewardPurpose,
    );

  if (
    !purpose
  ) {
    throw createError(
      "ADMOB_INVALID_REWARD_PURPOSE",
      "Reward purpose is required.",
    );
  }

  const referenceNowMs =
    number(
      options.referenceNowMs,
      Date.now(),
    );

  if (
    !Number.isFinite(
      referenceNowMs,
    ) ||
    referenceNowMs <= 0
  ) {
    throw createError(
      "ADMOB_REWARD_REFERENCE_TIME_INVALID",
      "Reward reference time is invalid.",
    );
  }

  // ==========================================================
  // FALLBACK QUERY
  // ==========================================================
  //
  // HomePage ei tällä hetkellä lähetä transaction ID:tä
  // Power Boost -kutsussa.
  //
  // SSV tallentaa rewardin admobRewards-kokoelmaan UID:n
  // perusteella.
  //
  // Haetaan käyttäjän kaikki reward-dokumentit.
  //
  // Sen jälkeen:
  //
  // 1. suodatetaan kelvolliset rewardit
  // 2. järjestetään timestampin mukaan
  // 3. otetaan uusimmat ehdokkaat
  //
  // Näin Firestore-dokumentin ID-järjestys ei vaikuta siihen,
  // mikä reward valitaan.
  //
  // ==========================================================

  const snapshot =
    await db
      .collection(
        "admobRewards",
      )
      .where(
        "uid",
        "==",
        validatedUid,
      )
      .get();

  // ==========================================================
  // FALLBACK CANDIDATES
  // ==========================================================

  const candidates =
    snapshot.docs
      .filter((doc) => {
        const data =
          doc.data() || {};

        const documentUid =
          getDocumentUid(
            data,
          );

        const documentPurpose =
          getDocumentRewardPurpose(
            data,
          );

        // ----------------------------------------------------
        // TÄRKEÄ:
        //
        // transactionId voi tulla document ID:stä.
        // ----------------------------------------------------

        const documentTransactionId =
          getDocumentTransactionId(
            data,
            doc.id,
          );

        if (
          data.verified !== true
        ) {
          return false;
        }

        if (
          documentUid !==
          validatedUid
        ) {
          return false;
        }

        if (
          documentPurpose !==
          purpose
        ) {
          return false;
        }

        if (
          !documentTransactionId
        ) {
          return false;
        }

        if (
          documentTransactionId !==
          doc.id
        ) {
          return false;
        }

        if (
          isRewardAlreadyClaimed(
            data,
            purpose,
          )
        ) {
          return false;
        }

        const rewardCreatedAtMs =
          getRewardCreatedAtMs(
            data,
          );

        if (
          rewardCreatedAtMs <= 0
        ) {
          return false;
        }

        if (
          rewardCreatedAtMs >
          referenceNowMs +
            REWARD_FUTURE_TOLERANCE_MS
        ) {
          return false;
        }

        if (
          referenceNowMs -
            rewardCreatedAtMs >
          REWARD_MAX_AGE_MS
        ) {
          return false;
        }

        return true;
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
      })
      .slice(
        0,
        MAX_FALLBACK_REWARD_DOCS,
      );

  if (
    candidates.length === 0
  ) {
    throw createError(
      "ADMOB_REWARD_NOT_FOUND",
      "No verified unconsumed AdMob reward is available yet.",
    );
  }

  // ==========================================================
  // VALIDATE CANDIDATES
  // ==========================================================

  let lastValidationError =
    null;

  for (
    const candidate of candidates
  ) {
    try {
      const candidateData =
        candidate.data() || {};

      const candidateTransactionId =
        getDocumentTransactionId(
          candidateData,
          candidate.id,
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
          referenceNowMs,

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

async function getVerifiedRewardWithRetry(
  uid,
  options = {},
) {
  const startedAt =
    Date.now();

  let lastError =
    null;

  let retryDelay =
    SSV_INITIAL_RETRY_DELAY_MS;

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
        retryDelay,
        remaining,
      ),
    );

    retryDelay =
      Math.min(
        retryDelay * 2,
        SSV_MAX_RETRY_DELAY_MS,
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

  SSV_INITIAL_RETRY_DELAY_MS,

  SSV_MAX_RETRY_DELAY_MS,

  MAX_FALLBACK_REWARD_DOCS,

  validateUid,

  validateTransactionId,

  getOptionalTransactionId,

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