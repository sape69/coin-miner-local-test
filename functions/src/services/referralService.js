"use strict";

// ============================================================
// 🐱 STELLURIINI - REFERRAL SERVICE
// ============================================================
//
// Stella Referral System.
//
// Tämä palvelu vastaa:
//
// - referral-koodin luomisesta
// - referral-koodin yksilöllisyyden varmistamisesta
// - referral-koodin hakemisesta
// - referral-suhteen luomisesta
// - referral-suhteen lukitsemisesta
// - self-referralin estämisestä
// - referral-bonuksen server-side laskemisesta
// - referral-bonuksen validoinnista
// - referral-historian tallentamisesta
//
// TÄRKEÄÄ:
//
// Referral-bonus EI synny rekisteröitymisestä.
//
// Referral-bonus syntyy vain hyväksytystä mining-tuotosta.
//
// Client ei saa päättää:
//
// - kutsujaa
// - referral-prosenttia
// - bonusmäärää
// - referral-suhdetta
//
// ============================================================

const crypto = require("crypto");

const {
  db,
  FieldValue,
} = require("../firebase/firebase");

const {
  getUserRef,
} = require("../utils/userUtils");

const {
  DEFAULT_REFERRAL_BONUS_PERCENT,
  REFERRAL_MILESTONES,
  ONE_REFERRER_PER_USER,
  ALLOW_REFERRER_CHANGE,
  ALLOW_SELF_REFERRAL,
  REFERRAL_CODE_LENGTH,
  REFERRAL_CODE_CHARACTERS,
  MAX_CODE_GENERATION_ATTEMPTS,
  MIN_REFERRAL_BONUS,
  REFERRAL_BONUS_SOURCE,
  REFERRAL_CALCULATION_SERVER_SIDE,
  REFERRAL_HISTORY_COLLECTION,
  REFERRAL_DATA_FIELD,
  getReferralBonusPercent,
  getReferralBonusRate,
  calculateReferralBonus,
  isValidReferralBonus,
} = require("../config/referralConfig");

// ============================================================
// FIRESTORE COLLECTIONS
// ============================================================

const REFERRAL_CODES_COLLECTION =
  "referralCodes";

// ============================================================
// VALUE HELPERS
// ============================================================

function safeString(value) {
  return typeof value === "string"
    ? value.trim()
    : "";
}

function safeNumber(
  value,
  fallback = 0,
) {
  const result =
    Number(value);

  return Number.isFinite(result)
    ? result
    : fallback;
}

function positiveNumber(
  value,
  fallback = 0,
) {
  const result =
    Number(value);

  return Number.isFinite(result) &&
    result > 0
    ? result
    : fallback;
}

// ============================================================
// UID VALIDATION
// ============================================================

function validateUid(uid) {
  const value =
    safeString(uid);

  if (!value) {
    throw new Error(
      "REFERRAL_UID_REQUIRED",
    );
  }

  return value;
}

// ============================================================
// REFERRAL CODE NORMALIZATION
// ============================================================

function normalizeReferralCode(code) {
  return safeString(code)
    .toUpperCase();
}

// ============================================================
// REFERRAL CODE VALIDATION
// ============================================================

function isValidReferralCode(code) {
  const normalized =
    normalizeReferralCode(code);

  if (
    normalized.length !==
    REFERRAL_CODE_LENGTH
  ) {
    return false;
  }

  for (
    const character of normalized
  ) {
    if (
      !REFERRAL_CODE_CHARACTERS.includes(
        character,
      )
    ) {
      return false;
    }
  }

  return true;
}

// ============================================================
// REFERRAL CODE GENERATION
// ============================================================
//
// crypto.randomInt() käyttää Node.js:n kryptografisesti
// turvallista satunnaislukugeneraattoria.
//
// ============================================================

function generateReferralCode() {
  let code = "";

  const characters =
    REFERRAL_CODE_CHARACTERS;

  for (
    let index = 0;
    index < REFERRAL_CODE_LENGTH;
    index++
  ) {
    const position =
      crypto.randomInt(
        0,
        characters.length,
      );

    code +=
      characters[position];
  }

  return code;
}

// ============================================================
// FIRESTORE REFERENCES
// ============================================================

function getReferralCodeRef(code) {
  const normalized =
    normalizeReferralCode(code);

  if (
    !isValidReferralCode(
      normalized,
    )
  ) {
    return null;
  }

  return db
    .collection(
      REFERRAL_CODES_COLLECTION,
    )
    .doc(normalized);
}

function getReferralHistoryCollection(
  uid,
) {
  return getUserRef(
    validateUid(uid),
  ).collection(
    REFERRAL_HISTORY_COLLECTION,
  );
}

// ============================================================
// REFERRAL DATA
// ============================================================

function getReferralData(userData) {
  if (
    !userData ||
    typeof userData !== "object"
  ) {
    return {};
  }

  const referral =
    userData[
      REFERRAL_DATA_FIELD
    ];

  return referral &&
    typeof referral === "object"
    ? referral
    : {};
}

// ============================================================
// GET REFERRAL CODE OWNER
// ============================================================

async function getReferralCodeOwner(
  code,
  transaction = null,
) {
  const normalized =
    normalizeReferralCode(code);

  if (
    !isValidReferralCode(
      normalized,
    )
  ) {
    return null;
  }

  const ref =
    getReferralCodeRef(
      normalized,
    );

  const snapshot =
    transaction
      ? await transaction.get(ref)
      : await ref.get();

  if (!snapshot.exists) {
    return null;
  }

  const data =
    snapshot.data() || {};

  const uid =
    safeString(data.uid);

  if (!uid) {
    return null;
  }

  return {
    uid,

    referralCode:
      normalized,

    ref,

    data,
  };
}

// ============================================================
// CREATE UNIQUE REFERRAL CODE
// ============================================================
//
// Luo käyttäjälle yksilöllisen referral-koodin.
//
// Jos käyttäjällä on jo validi koodi:
//
// - tarkistetaan myös sen Firestore-omistaja
// - koodia ei vaihdeta
//
// Jos koodi on ristiriidassa toisen käyttäjän kanssa,
// operation epäonnistuu eikä käyttäjän referral-suhdetta
// muuteta.
//
// ============================================================

async function createReferralCode(
  uid,
) {
  const userId =
    validateUid(uid);

  const userRef =
    getUserRef(userId);

  return db.runTransaction(
    async (transaction) => {
      const userSnapshot =
        await transaction.get(
          userRef,
        );

      const userData =
        userSnapshot.exists
          ? userSnapshot.data() || {}
          : {};

      const existingReferral =
        getReferralData(
          userData,
        );

      const existingCode =
        normalizeReferralCode(
          existingReferral.code,
        );

      // --------------------------------------------------------
      // EXISTING VALID CODE
      // --------------------------------------------------------

      if (
        isValidReferralCode(
          existingCode,
        )
      ) {
        const existingCodeRef =
          getReferralCodeRef(
            existingCode,
          );

        const existingCodeSnapshot =
          await transaction.get(
            existingCodeRef,
          );

        if (
          existingCodeSnapshot.exists
        ) {
          const existingCodeData =
            existingCodeSnapshot.data() ||
            {};

          const ownerUid =
            safeString(
              existingCodeData.uid,
            );

          // ----------------------------------------------------
          // CODE BELONGS TO THIS USER
          // ----------------------------------------------------

          if (
            ownerUid === userId
          ) {
            return {
              success: true,

              created: false,

              referralCode:
                existingCode,
            };
          }

          // ----------------------------------------------------
          // CODE BELONGS TO SOMEONE ELSE
          // ----------------------------------------------------

          throw new Error(
            "REFERRAL_CODE_OWNERSHIP_CONFLICT",
          );
        }

        // ------------------------------------------------------
        // EXISTING USER CODE BUT MISSING INDEX
        // ------------------------------------------------------

        transaction.set(
          existingCodeRef,
          {
            uid: userId,

            referralCode:
              existingCode,

            createdAt:
              existingReferral.createdAt ||
              FieldValue.serverTimestamp(),

            updatedAt:
              FieldValue.serverTimestamp(),
          },
          {
            merge: true,
          },
        );

        return {
          success: true,

          created: false,

          referralCode:
            existingCode,
        };
      }

      // --------------------------------------------------------
      // GENERATE NEW CODE
      // --------------------------------------------------------

      for (
        let attempt = 0;
        attempt <
        MAX_CODE_GENERATION_ATTEMPTS;
        attempt++
      ) {
        const code =
          generateReferralCode();

        const codeRef =
          getReferralCodeRef(
            code,
          );

        const codeSnapshot =
          await transaction.get(
            codeRef,
          );

        if (
          codeSnapshot.exists
        ) {
          continue;
        }

        transaction.set(
          codeRef,
          {
            uid: userId,

            referralCode:
              code,

            createdAt:
              FieldValue.serverTimestamp(),

            updatedAt:
              FieldValue.serverTimestamp(),
          },
        );

        transaction.set(
          userRef,
          {
            referral: {
              code,

              createdAt:
                FieldValue.serverTimestamp(),

              updatedAt:
                FieldValue.serverTimestamp(),
            },

            updatedAt:
              FieldValue.serverTimestamp(),
          },
          {
            merge: true,
          },
        );

        return {
          success: true,

          created: true,

          referralCode:
            code,
        };
      }

      throw new Error(
        "REFERRAL_CODE_GENERATION_FAILED",
      );
    },
  );
}

// ============================================================
// ENSURE REFERRAL CODE
// ============================================================

async function ensureReferralCode(
  uid,
) {
  return createReferralCode(
    uid,
  );
}

// ============================================================
// SET REFERRER
// ============================================================
//
// Asettaa kutsujan käyttäjälle.
//
// Referral-suhde voidaan asettaa vain kerran,
// ellei ALLOW_REFERRER_CHANGE ole true.
//
// ============================================================

async function setReferrer(
  referredUid,
  referralCode,
) {
  const userId =
    validateUid(
      referredUid,
    );

  const normalizedCode =
    normalizeReferralCode(
      referralCode,
    );

  if (
    !isValidReferralCode(
      normalizedCode,
    )
  ) {
    throw new Error(
      "REFERRAL_CODE_INVALID",
    );
  }

  const userRef =
    getUserRef(userId);

  const codeRef =
    getReferralCodeRef(
      normalizedCode,
    );

  return db.runTransaction(
    async (transaction) => {
      // ------------------------------------------------------
      // ALL READS FIRST
      // ------------------------------------------------------

      const userSnapshot =
        await transaction.get(
          userRef,
        );

      const codeSnapshot =
        await transaction.get(
          codeRef,
        );

      const userData =
        userSnapshot.exists
          ? userSnapshot.data() || {}
          : {};

      const existingReferral =
        getReferralData(
          userData,
        );

      const existingReferrerUid =
        safeString(
          existingReferral.referrerUid,
        );

      // ------------------------------------------------------
      // EXISTING REFERRER
      // ------------------------------------------------------

      if (
        existingReferrerUid &&
        !ALLOW_REFERRER_CHANGE
      ) {
        if (
          existingReferrerUid ===
          userId
        ) {
          throw new Error(
            "REFERRAL_SELF_REFERRAL",
          );
        }

        return {
          success: true,

          created: false,

          alreadySet: true,

          referrerUid:
            existingReferrerUid,

          referralCode:
            safeString(
              existingReferral.referralCode,
            ),
        };
      }

      // ------------------------------------------------------
      // CODE MUST EXIST
      // ------------------------------------------------------

      if (
        !codeSnapshot.exists
      ) {
        throw new Error(
          "REFERRAL_CODE_NOT_FOUND",
        );
      }

      const codeData =
        codeSnapshot.data() || {};

      const referrerUid =
        safeString(
          codeData.uid,
        );

      if (!referrerUid) {
        throw new Error(
          "REFERRAL_OWNER_INVALID",
        );
      }

      // ------------------------------------------------------
      // SELF REFERRAL
      // ------------------------------------------------------

      if (
        referrerUid === userId &&
        !ALLOW_SELF_REFERRAL
      ) {
        throw new Error(
          "REFERRAL_SELF_REFERRAL",
        );
      }

      // ------------------------------------------------------
      // ONE REFERRER PER USER
      // ------------------------------------------------------

      if (
        ONE_REFERRER_PER_USER &&
        existingReferrerUid &&
        existingReferrerUid !==
          referrerUid &&
        !ALLOW_REFERRER_CHANGE
      ) {
        throw new Error(
          "REFERRAL_ALREADY_ASSIGNED",
        );
      }

      // ------------------------------------------------------
      // USER UPDATE
      // ------------------------------------------------------

      transaction.set(
        userRef,
        {
          referral: {
            ...existingReferral,

            referralCode:
              normalizedCode,

            referrerUid,

            assignedAt:
              existingReferral.assignedAt ||
              FieldValue.serverTimestamp(),

            updatedAt:
              FieldValue.serverTimestamp(),
          },

          updatedAt:
            FieldValue.serverTimestamp(),
        },
        {
          merge: true,
        },
      );

      // ------------------------------------------------------
      // REFERRER COUNTER
      // ------------------------------------------------------

      const referrerRef =
        getUserRef(
          referrerUid,
        );

      transaction.set(
        referrerRef,
        {
          referral: {
            referralCount:
              FieldValue.increment(
                1,
              ),

            updatedAt:
              FieldValue.serverTimestamp(),
          },

          updatedAt:
            FieldValue.serverTimestamp(),
        },
        {
          merge: true,
        },
      );

      return {
        success: true,

        created: true,

        alreadySet: false,

        referrerUid,

        referralCode:
          normalizedCode,
      };
    },
  );
}

// ============================================================
// GET USER REFERRER
// ============================================================

async function getUserReferrer(
  uid,
) {
  const userId =
    validateUid(uid);

  const snapshot =
    await getUserRef(
      userId,
    ).get();

  if (!snapshot.exists) {
    return null;
  }

  const data =
    snapshot.data() || {};

  const referral =
    getReferralData(data);

  const referrerUid =
    safeString(
      referral.referrerUid,
    );

  if (!referrerUid) {
    return null;
  }

  return {
    referrerUid,

    referralCode:
      safeString(
        referral.referralCode,
      ),

    assignedAt:
      referral.assignedAt ||
      null,
  };
}

// ============================================================
// REFERRAL BONUS PERCENT
// ============================================================

function getServerReferralBonusPercent(
  totalUsers,
) {
  if (
    !REFERRAL_CALCULATION_SERVER_SIDE
  ) {
    throw new Error(
      "REFERRAL_SERVER_CALCULATION_DISABLED",
    );
  }

  return getReferralBonusPercent(
    totalUsers,
  );
}

// ============================================================
// REFERRAL BONUS RATE
// ============================================================

function getServerReferralBonusRate(
  totalUsers,
) {
  if (
    !REFERRAL_CALCULATION_SERVER_SIDE
  ) {
    throw new Error(
      "REFERRAL_SERVER_CALCULATION_DISABLED",
    );
  }

  return getReferralBonusRate(
    totalUsers,
  );
}

// ============================================================
// CALCULATE SERVER REFERRAL BONUS
// ============================================================
//
// Tämä on ainoa normaali tapa laskea referral-bonus.
//
// ============================================================

function calculateServerReferralBonus(
  miningAmount,
  totalUsers,
) {
  if (
    !REFERRAL_CALCULATION_SERVER_SIDE
  ) {
    throw new Error(
      "REFERRAL_SERVER_CALCULATION_DISABLED",
    );
  }

  const amount =
    positiveNumber(
      miningAmount,
    );

  const bonusPercent =
    getReferralBonusPercent(
      totalUsers,
    );

  const bonusRate =
    getReferralBonusRate(
      totalUsers,
    );

  if (amount <= 0) {
    return {
      bonus: 0,

      bonusPercent,

      bonusRate,

      source:
        REFERRAL_BONUS_SOURCE,
    };
  }

  const bonus =
    calculateReferralBonus(
      amount,
      totalUsers,
    );

  return {
    bonus:
      Math.max(
        0,
        safeNumber(
          bonus,
        ),
      ),

    bonusPercent,

    bonusRate,

    source:
      REFERRAL_BONUS_SOURCE,
  };
}

// ============================================================
// VALIDATE SERVER REFERRAL BONUS
// ============================================================

function validateReferralBonus(
  bonus,
) {
  if (
    !REFERRAL_CALCULATION_SERVER_SIDE
  ) {
    return false;
  }

  return isValidReferralBonus(
    bonus,
  );
}

// ============================================================
// RECORD REFERRAL BONUS
// ============================================================
//
// TÄRKEÄÄ:
//
// Tämä funktio EI hyväksy clientin lähettämää
// referralBonus- tai referralPercent-arvoa
// totuutena.
//
// Bonus lasketaan täällä uudelleen:
//
// miningAmount
//      +
// totalUsers
//      ↓
// server-side percentage
//      ↓
// server-side referral bonus
//
// ============================================================

async function recordReferralBonus(
  transaction,
  {
    referrerUid,
    referredUid,
    miningAmount,
    totalUsers,
    miningHistoryId = null,
  },
) {
  const referrerId =
    validateUid(
      referrerUid,
    );

  const referredId =
    validateUid(
      referredUid,
    );

  if (
    referrerId ===
    referredId
  ) {
    throw new Error(
      "REFERRAL_SELF_REFERRAL",
    );
  }

  const amount =
    positiveNumber(
      miningAmount,
    );

  if (amount <= 0) {
    throw new Error(
      "REFERRAL_MINING_AMOUNT_INVALID",
    );
  }

  // ----------------------------------------------------------
  // SERVER-SIDE CALCULATION
  // ----------------------------------------------------------

  const calculation =
    calculateServerReferralBonus(
      amount,
      totalUsers,
    );

  const bonus =
    positiveNumber(
      calculation.bonus,
    );

  if (
    !validateReferralBonus(
      bonus,
    )
  ) {
    throw new Error(
      "REFERRAL_BONUS_INVALID",
    );
  }

  const referralPercent =
    positiveNumber(
      calculation.bonusPercent,
    );

  // ----------------------------------------------------------
  // VERIFY REFERRAL RELATIONSHIP
  // ----------------------------------------------------------
  //
  // Referral-suhde tarkistetaan serveriltä juuri ennen
  // historian kirjoittamista.
  //
  // ----------------------------------------------------------

  const referredUserRef =
    getUserRef(
      referredId,
    );

  const referredSnapshot =
    transaction
      ? await transaction.get(
          referredUserRef,
        )
      : await referredUserRef.get();

  if (
    !referredSnapshot.exists
  ) {
    throw new Error(
      "REFERRAL_REFERRED_USER_NOT_FOUND",
    );
  }

  const referredData =
    referredSnapshot.data() || {};

  const referral =
    getReferralData(
      referredData,
    );

  const actualReferrerUid =
    safeString(
      referral.referrerUid,
    );

  if (
    actualReferrerUid !==
    referrerId
  ) {
    throw new Error(
      "REFERRAL_RELATIONSHIP_INVALID",
    );
  }

  // ----------------------------------------------------------
  // HISTORY
  // ----------------------------------------------------------

  const historyRef =
    getReferralHistoryCollection(
      referrerId,
    ).doc();

  const historyData = {
    type:
      "referral_bonus",

    source:
      REFERRAL_BONUS_SOURCE,

    referrerUid:
      referrerId,

    referredUid:
      referredId,

    miningAmount:
      amount,

    referralBonus:
      bonus,

    referralPercent,

    referralRate:
      calculation.bonusRate,

    miningHistoryId:
      safeString(
        miningHistoryId,
      ) || null,

    createdAt:
      FieldValue.serverTimestamp(),
  };

  if (transaction) {
    transaction.set(
      historyRef,
      historyData,
    );
  } else {
    await historyRef.set(
      historyData,
    );
  }

  return {
    success: true,

    historyId:
      historyRef.id,

    referrerUid:
      referrerId,

    referredUid:
      referredId,

    miningAmount:
      amount,

    referralBonus:
      bonus,

    referralPercent,

    referralRate:
      calculation.bonusRate,

    source:
      REFERRAL_BONUS_SOURCE,
  };
}

// ============================================================
// REFERRAL CONFIG STATUS
// ============================================================

function getReferralConfigStatus() {
  return {
    defaultBonusPercent:
      DEFAULT_REFERRAL_BONUS_PERCENT,

    milestones:
      REFERRAL_MILESTONES,

    oneReferrerPerUser:
      ONE_REFERRER_PER_USER,

    allowReferrerChange:
      ALLOW_REFERRER_CHANGE,

    allowSelfReferral:
      ALLOW_SELF_REFERRAL,

    referralCodeLength:
      REFERRAL_CODE_LENGTH,

    maxCodeGenerationAttempts:
      MAX_CODE_GENERATION_ATTEMPTS,

    minimumReferralBonus:
      MIN_REFERRAL_BONUS,

    bonusSource:
      REFERRAL_BONUS_SOURCE,

    serverSideCalculation:
      REFERRAL_CALCULATION_SERVER_SIDE,
  };
}

// ============================================================
// EXPORTS
// ============================================================

module.exports = {
  // ----------------------------------------------------------
  // CODE
  // ----------------------------------------------------------

  normalizeReferralCode,

  isValidReferralCode,

  generateReferralCode,

  getReferralCodeOwner,

  createReferralCode,

  ensureReferralCode,

  // ----------------------------------------------------------
  // RELATIONSHIP
  // ----------------------------------------------------------

  setReferrer,

  getUserReferrer,

  // ----------------------------------------------------------
  // BONUS
  // ----------------------------------------------------------

  getServerReferralBonusPercent,

  getServerReferralBonusRate,

  calculateServerReferralBonus,

  validateReferralBonus,

  recordReferralBonus,

  // ----------------------------------------------------------
  // CONFIG
  // ----------------------------------------------------------

  getReferralConfigStatus,

  // ----------------------------------------------------------
  // REFERENCES
  // ----------------------------------------------------------

  getReferralCodeRef,

  getReferralHistoryCollection,
};