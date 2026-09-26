"use strict";

// ============================================================
// 🐱 STELLURIINI - REFERRAL SERVICE
// ============================================================
//
// Stella Referral System.
//
// Tämän service-kerroksen tehtävät:
//
// - luoda käyttäjälle referral-koodi
// - varmistaa referral-koodin yksilöllisyys
// - löytää kutsuja referral-koodilla
// - liittää käyttäjä kutsujaan
// - estää self-referral
// - estää referral-suhteen vaihtaminen
// - laskea referral-bonus hyväksytystä mining-tuotosta
//
// TÄRKEÄÄ:
//
// Referral ei anna rekisteröitymispalkkiota.
//
// Referral-bonus syntyy vasta hyväksytystä mining-tuotosta.
//
// Tämä tiedosto EI vielä muuta käyttäjän STL-balancea.
// Varsinainen bonuskirjaus liitetään myöhemmin
// mining-järjestelmään.
//
// ============================================================

const {
  db,
  FieldValue,
} = require("../firebase/firebase");

const {
  REFERRAL_HISTORY_COLLECTION,
  REFERRAL_DATA_FIELD,
  MAX_CODE_GENERATION_ATTEMPTS,
  calculateReferralBonus,
  getReferralBonusPercent,
  getReferralBonusRate,
} = require("../config/referralConfig");

const {
  getUserRef,
} = require("../utils/userUtils");

const {
  normalizeReferralCode,
  isValidReferralCode,
  generateReferralCode,
  getReferralData,
  getUserReferralCode,
  getReferrerUid,
  getReferralCodeUsed,
  hasReferrer,
  canSetReferrer,
  isSelfReferral,
  validateReferrerRelationship,
  buildReferralData,
  getReferralCodeFromInput,
  validateReferralCodeInput,
} = require("../utils/referralUtils");

// ============================================================
// COLLECTIONS
// ============================================================
//
// Referral-koodit tallennetaan omaan collectioniin.
//
// Dokumentin ID on referral-koodi.
//
// Esimerkiksi:
//
// referralCodes/
//   ABC123XY
//
// Tämä mahdollistaa suoran lookupin ilman collection scania.
//
// ============================================================

const REFERRAL_CODES_COLLECTION =
  "referralCodes";

// ============================================================
// INTERNAL HELPERS
// ============================================================

function safeString(
  value,
  fallback = ""
) {
  return typeof value === "string"
    ? value.trim()
    : fallback;
}

function positiveNumber(
  value,
  fallback = 0
) {
  const result =
    Number(value);

  return Number.isFinite(result) &&
    result > 0
    ? result
    : fallback;
}

function nonNegativeNumber(
  value,
  fallback = 0
) {
  const result =
    Number(value);

  return Number.isFinite(result) &&
    result >= 0
    ? result
    : fallback;
}

// ============================================================
// REFERRAL CODE REFERENCE
// ============================================================

function getReferralCodeRef(
  code
) {
  const normalized =
    normalizeReferralCode(
      code
    );

  if (
    !isValidReferralCode(
      normalized
    )
  ) {
    return null;
  }

  return db
    .collection(
      REFERRAL_CODES_COLLECTION
    )
    .doc(normalized);
}

// ============================================================
// REFERRAL HISTORY REFERENCE
// ============================================================

function getReferralHistoryRef(
  uid
) {
  const userUid =
    safeString(uid);

  if (!userUid) {
    return null;
  }

  return getUserRef(userUid)
    .collection(
      REFERRAL_HISTORY_COLLECTION
    );
}

// ============================================================
// FIND REFERRER BY CODE
// ============================================================
//
// Palauttaa referral-koodin omistajan.
//
// Paluuarvo:
//
// {
//   found: true,
//   referralCode: "ABC123XY",
//   referrerUid: "...",
//   snapshot: ...
// }
//
// ============================================================

async function findReferrerByCode(
  code,
  transaction = null
) {
  const normalizedCode =
    normalizeReferralCode(
      code
    );

  if (
    !isValidReferralCode(
      normalizedCode
    )
  ) {
    return {
      found: false,
      referralCode:
        normalizedCode,
      referrerUid: "",
      snapshot: null,
    };
  }

  const ref =
    getReferralCodeRef(
      normalizedCode
    );

  if (!ref) {
    return {
      found: false,
      referralCode:
        normalizedCode,
      referrerUid: "",
      snapshot: null,
    };
  }

  const snapshot =
    transaction
      ? await transaction.get(ref)
      : await ref.get();

  if (!snapshot.exists) {
    return {
      found: false,
      referralCode:
        normalizedCode,
      referrerUid: "",
      snapshot,
    };
  }

  const data =
    snapshot.data() || {};

  const referrerUid =
    safeString(
      data.uid ??
      data.referrerUid
    );

  if (!referrerUid) {
    return {
      found: false,
      referralCode:
        normalizedCode,
      referrerUid: "",
      snapshot,
    };
  }

  return {
    found: true,
    referralCode:
      normalizedCode,
    referrerUid,
    snapshot,
  };
}

// ============================================================
// CREATE UNIQUE REFERRAL CODE
// ============================================================
//
// Luo referral-koodin käyttäjälle.
//
// TÄRKEÄÄ:
//
// Jos transaction annetaan, kaikki read-operaatiot tehdään
// ennen write-operaatioita.
//
// Firestore transaction voi suorittaa callbackin uudelleen,
// joten funktio ei muuta ulkoista application statea.
//
// ============================================================

async function createReferralCode(
  uid,
  transaction = null
) {
  const userUid =
    safeString(uid);

  if (!userUid) {
    throw new Error(
      "REFERRAL_UID_MISSING"
    );
  }

  const userRef =
    getUserRef(
      userUid
    );

  const existingSnapshot =
    transaction
      ? await transaction.get(
          userRef
        )
      : await userRef.get();

  const existingData =
    existingSnapshot.exists
      ? existingSnapshot.data() || {}
      : {};

  const existingCode =
    getUserReferralCode(
      existingData
    );

  // ----------------------------------------------------------
  // EXISTING CODE
  // ----------------------------------------------------------

  if (
    existingCode &&
    isValidReferralCode(
      existingCode
    )
  ) {
    return {
      created: false,
      existing: true,
      code:
        existingCode,
      referrerUid:
        getReferrerUid(
          existingData
        ),
    };
  }

  // ----------------------------------------------------------
  // CODE GENERATION
  // ----------------------------------------------------------

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
        code
      );

    if (!codeRef) {
      continue;
    }

    const codeSnapshot =
      transaction
        ? await transaction.get(
            codeRef
          )
        : await codeRef.get();

    if (
      codeSnapshot.exists
    ) {
      continue;
    }

    const referralData =
      buildReferralData({
        code,
      });

    // --------------------------------------------------------
    // CODE INDEX
    // --------------------------------------------------------

    const codeDocument = {
      uid:
        userUid,

      referralCode:
        code,

      createdAt:
        FieldValue.serverTimestamp(),

      updatedAt:
        FieldValue.serverTimestamp(),
    };

    if (transaction) {
      transaction.set(
        codeRef,
        codeDocument
      );

      transaction.set(
        userRef,
        {
          [REFERRAL_DATA_FIELD]:
            referralData,

          updatedAt:
            FieldValue.serverTimestamp(),
        },
        {
          merge: true,
        }
      );
    } else {
      await db.runTransaction(
        async (tx) => {
          const latestUser =
            await tx.get(
              userRef
            );

          const latestCode =
            getUserReferralCode(
              latestUser.exists
                ? latestUser.data() || {}
                : {}
            );

          if (
            latestCode &&
            isValidReferralCode(
              latestCode
            )
          ) {
            return;
          }

          const latestCodeSnapshot =
            await tx.get(
              codeRef
            );

          if (
            latestCodeSnapshot.exists
          ) {
            throw new Error(
              "REFERRAL_CODE_COLLISION"
            );
          }

          tx.set(
            codeRef,
            codeDocument
          );

          tx.set(
            userRef,
            {
              [REFERRAL_DATA_FIELD]:
                referralData,

              updatedAt:
                FieldValue.serverTimestamp(),
            },
            {
              merge: true,
            }
          );
        }
      );
    }

    return {
      created: true,
      existing: false,
      code,
      referrerUid: "",
    };
  }

  throw new Error(
    "REFERRAL_CODE_GENERATION_FAILED"
  );
}

// ============================================================
// GET OR CREATE REFERRAL CODE
// ============================================================

async function getOrCreateReferralCode(
  uid,
  transaction = null
) {
  const userUid =
    safeString(uid);

  if (!userUid) {
    throw new Error(
      "REFERRAL_UID_MISSING"
    );
  }

  const userRef =
    getUserRef(
      userUid
    );

  const snapshot =
    transaction
      ? await transaction.get(
          userRef
        )
      : await userRef.get();

  const data =
    snapshot.exists
      ? snapshot.data() || {}
      : {};

  const existingCode =
    getUserReferralCode(
      data
    );

  if (
    existingCode &&
    isValidReferralCode(
      existingCode
    )
  ) {
    return {
      created: false,
      code:
        existingCode,
      referrerUid:
        getReferrerUid(
          data
        ),
    };
  }

  return createReferralCode(
    userUid,
    transaction
  );
}

// ============================================================
// APPLY REFERRAL CODE
// ============================================================
//
// Liittää kutsutun käyttäjän kutsujaan.
//
// TÄMÄ FUNKTIO EI:
//
// - anna STL-palkkiota
// - muuta miningBalancea
// - muuta referral-prosenttia
//
// ============================================================

async function applyReferralCode(
  uid,
  referralCode,
  transaction = null
) {
  const userUid =
    safeString(uid);

  if (!userUid) {
    throw new Error(
      "REFERRAL_UID_MISSING"
    );
  }

  const validation =
    validateReferralCodeInput(
      referralCode
    );

  if (
    !validation.valid
  ) {
    throw new Error(
      validation.reason
    );
  }

  const code =
    validation.code;

  const userRef =
    getUserRef(
      userUid
    );

  // ----------------------------------------------------------
  // ALL READS FIRST
  // ----------------------------------------------------------

  const userSnapshot =
    transaction
      ? await transaction.get(
          userRef
        )
      : await userRef.get();

  const userData =
    userSnapshot.exists
      ? userSnapshot.data() || {}
      : {};

  const existingReferrerUid =
    getReferrerUid(
      userData
    );

  if (
    existingReferrerUid
  ) {
    if (
      existingReferrerUid ===
      userUid
    ) {
      throw new Error(
        "SELF_REFERRAL_NOT_ALLOWED"
      );
    }

    if (
      !existingReferrerUid
    ) {
      // Defensive fallback.
      throw new Error(
        "REFERRER_ALREADY_SET"
      );
    }

    throw new Error(
      "REFERRER_CHANGE_NOT_ALLOWED"
    );
  }

  const referralLookup =
    await findReferrerByCode(
      code,
      transaction
    );

  if (
    !referralLookup.found
  ) {
    throw new Error(
      "REFERRAL_CODE_NOT_FOUND"
    );
  }

  const referrerUid =
    referralLookup.referrerUid;

  if (
    !referrerUid
  ) {
    throw new Error(
      "REFERRER_UID_MISSING"
    );
  }

  if (
    !ALLOW_SELF_REFERRAL_CHECK(
      userUid,
      referrerUid
    )
  ) {
    throw new Error(
      "SELF_REFERRAL_NOT_ALLOWED"
    );
  }

  const relationship =
    validateReferrerRelationship(
      userUid,
      userData,
      referrerUid
    );

  if (
    !relationship.valid
  ) {
    throw new Error(
      relationship.reason
    );
  }

  const ownCode =
    getUserReferralCode(
      userData
    );

  if (
    ownCode &&
    ownCode === code
  ) {
    throw new Error(
      "SELF_REFERRAL_NOT_ALLOWED"
    );
  }

  const referralData =
    buildReferralData({
      code:
        ownCode || undefined,

      referrerUid,

      referralCodeUsed:
        code,

      referredAt:
        FieldValue.serverTimestamp(),
    });

  const update = {
    [REFERRAL_DATA_FIELD]:
      referralData,

    updatedAt:
      FieldValue.serverTimestamp(),
  };

  if (transaction) {
    transaction.set(
      userRef,
      update,
      {
        merge: true,
      }
    );
  } else {
    await userRef.set(
      update,
      {
        merge: true,
      }
    );
  }

  return {
    success: true,

    uid:
      userUid,

    referrerUid,

    referralCode:
      code,

    referralCodeUsed:
      code,

    referralBonusEnabled:
      true,
  };
}

// ============================================================
// SELF REFERRAL INTERNAL CHECK
// ============================================================

function ALLOW_SELF_REFERRAL_CHECK(
  userUid,
  referrerUid
) {
  return !isSelfReferral(
    userUid,
    referrerUid
  );
}

// ============================================================
// GET USER REFERRAL
// ============================================================

async function getUserReferral(
  uid,
  transaction = null
) {
  const userUid =
    safeString(uid);

  if (!userUid) {
    throw new Error(
      "REFERRAL_UID_MISSING"
    );
  }

  const userRef =
    getUserRef(
      userUid
    );

  const snapshot =
    transaction
      ? await transaction.get(
          userRef
        )
      : await userRef.get();

  const data =
    snapshot.exists
      ? snapshot.data() || {}
      : {};

  const referral =
    getReferralData(
      data
    );

  return {
    uid:
      userUid,

    referralCode:
      getUserReferralCode(
        data
      ) || null,

    referrerUid:
      getReferrerUid(
        data
      ) || null,

    referralCodeUsed:
      getReferralCodeUsed(
        data
      ) || null,

    hasReferralCode:
      getUserReferralCode(
        data
      ).length > 0,

    hasReferrer:
      hasReferrer(
        data
      ),

    referredAt:
      referral.referredAt ??
      null,
  };
}

// ============================================================
// GET REFERRER UID
// ============================================================

async function getUserReferrerUid(
  uid,
  transaction = null
) {
  const referral =
    await getUserReferral(
      uid,
      transaction
    );

  return referral.referrerUid || "";
}

// ============================================================
// TOTAL USER COUNT
// ============================================================
//
// Referral milestone perustuu järjestelmän käyttäjämäärään.
//
// Firestore count()-aggregation palauttaa vain lukumäärän,
// eikä koko users-kokoelmaa tarvitse siirtää sovellukseen.
//
// ============================================================

async function getTotalUserCount() {
  const snapshot =
    await db
      .collection("users")
      .count()
      .get();

  const count =
    Number(
      snapshot.data()?.count
    );

  return Number.isFinite(count)
    ? Math.max(
        0,
        Math.floor(count)
      )
    : 0;
}

// ============================================================
// GET CURRENT REFERRAL RATE
// ============================================================

async function getCurrentReferralRate() {
  const totalUsers =
    await getTotalUserCount();

  return {
    totalUsers,

    bonusPercent:
      getReferralBonusPercent(
        totalUsers
      ),

    bonusRate:
      getReferralBonusRate(
        totalUsers
      ),
  };
}

// ============================================================
// CALCULATE MINING REFERRAL BONUS
// ============================================================
//
// Laskenta tehdään vain positiivisesta hyväksytystä
// mining-tuotosta.
//
// Tämä funktio ei kirjoita Firestoreen.
//
// ============================================================

async function calculateMiningReferralBonus(
  miningAmount
) {
  const amount =
    nonNegativeNumber(
      miningAmount
    );

  if (
    amount <= 0
  ) {
    return {
      eligible: false,

      miningAmount: 0,

      totalUsers:
        await getTotalUserCount(),

      bonusPercent: 0,

      bonusRate: 0,

      referralBonus: 0,
    };
  }

  const rate =
    await getCurrentReferralRate();

  const bonus =
    calculateReferralBonus(
      amount,
      rate.totalUsers
    );

  return {
    eligible:
      bonus > 0,

    miningAmount:
      amount,

    totalUsers:
      rate.totalUsers,

    bonusPercent:
      rate.bonusPercent,

    bonusRate:
      rate.bonusRate,

    referralBonus:
      Math.max(
        0,
        positiveNumber(
          bonus
        )
      ),
  };
}

// ============================================================
// CREATE REFERRAL HISTORY DATA
// ============================================================
//
// Luo referral-history dokumentin datan.
//
// Tätä voidaan käyttää myöhemmin mining-järjestelmän
// hyväksytyn tuotoksen yhteydessä.
//
// ============================================================

function buildReferralMiningHistory({
  referrerUid,
  referredUid,
  miningAmount,
  referralBonus,
  bonusPercent,
  bonusRate,
  sourceMiningHistoryId = null,
} = {}) {
  const safeReferrerUid =
    safeString(
      referrerUid
    );

  const safeReferredUid =
    safeString(
      referredUid
    );

  const safeMiningAmount =
    nonNegativeNumber(
      miningAmount
    );

  const safeBonus =
    nonNegativeNumber(
      referralBonus
    );

  const safePercent =
    nonNegativeNumber(
      bonusPercent
    );

  const safeRate =
    nonNegativeNumber(
      bonusRate
    );

  return {
    type:
      "referral_mining_bonus",

    title:
      "Stella Referral Mining Bonus 🐱✨",

    referrerUid:
      safeReferrerUid,

    referredUid:
      safeReferredUid,

    miningAmount:
      safeMiningAmount,

    referralBonus:
      safeBonus,

    bonusPercent:
      safePercent,

    bonusRate:
      safeRate,

    source:
      "mining",

    sourceMiningHistoryId:
      sourceMiningHistoryId ||
      null,

    createdAt:
      FieldValue.serverTimestamp(),
  };
}

// ============================================================
// WRITE REFERRAL MINING HISTORY
// ============================================================
//
// Tätä kutsutaan myöhemmin hyväksytyn mining-bonuksen
// yhteydessä.
//
// STL-balancea ei muuteta tässä funktiossa.
//
// ============================================================

async function writeReferralMiningHistory(
  data,
  transaction = null
) {
  const referrerUid =
    safeString(
      data?.referrerUid
    );

  if (!referrerUid) {
    throw new Error(
      "REFERRER_UID_MISSING"
    );
  }

  const historyCollection =
    getReferralHistoryRef(
      referrerUid
    );

  if (!historyCollection) {
    throw new Error(
      "REFERRAL_HISTORY_REFERENCE_FAILED"
    );
  }

  const historyRef =
    historyCollection.doc();

  const historyData =
    buildReferralMiningHistory(
      data
    );

  if (transaction) {
    transaction.set(
      historyRef,
      historyData
    );
  } else {
    await historyRef.set(
      historyData
    );
  }

  return {
    id:
      historyRef.id,

    referrerUid,
  };
}

// ============================================================
// GET REFERRAL CODE OWNER
// ============================================================

async function getReferralCodeOwner(
  code,
  transaction = null
) {
  const result =
    await findReferrerByCode(
      code,
      transaction
    );

  if (
    !result.found
  ) {
    return null;
  }

  return {
    referralCode:
      result.referralCode,

    referrerUid:
      result.referrerUid,
  };
}

// ============================================================
// CHECK REFERRAL CODE
// ============================================================

async function checkReferralCode(
  code,
  transaction = null
) {
  const validation =
    validateReferralCodeInput(
      code
    );

  if (
    !validation.valid
  ) {
    return {
      valid: false,

      referralCode:
        validation.code,

      referrerUid:
        null,

      reason:
        validation.reason,
    };
  }

  const owner =
    await getReferralCodeOwner(
      validation.code,
      transaction
    );

  if (!owner) {
    return {
      valid: false,

      referralCode:
        validation.code,

      referrerUid:
        null,

      reason:
        "REFERRAL_CODE_NOT_FOUND",
    };
  }

  return {
    valid: true,

    referralCode:
      owner.referralCode,

    referrerUid:
      owner.referrerUid,

    reason: "",
  };
}

// ============================================================
// EXPORTS
// ============================================================

module.exports = {
  // ----------------------------------------------------------
  // 🔗 CODE
  // ----------------------------------------------------------

  getReferralCodeRef,

  createReferralCode,

  getOrCreateReferralCode,

  findReferrerByCode,

  getReferralCodeOwner,

  checkReferralCode,

  // ----------------------------------------------------------
  // 👤 RELATIONSHIP
  // ----------------------------------------------------------

  applyReferralCode,

  getUserReferral,

  getUserReferrerUid,

  // ----------------------------------------------------------
  // 📊 USERS / RATE
  // ----------------------------------------------------------

  getTotalUserCount,

  getCurrentReferralRate,

  // ----------------------------------------------------------
  // 💰 MINING BONUS
  // ----------------------------------------------------------

  calculateMiningReferralBonus,

  // ----------------------------------------------------------
  // 📜 HISTORY
  // ----------------------------------------------------------

  buildReferralMiningHistory,

  writeReferralMiningHistory,
};