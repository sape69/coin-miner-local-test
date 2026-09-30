"use strict";

// ============================================================
// 🐱 STELLURIINI - REFERRAL SERVICE
// ============================================================
//
// Stella Referral System.
//
// Server-side referral-liiketoimintalogiikka.
//
// TÄRKEÄÄ:
//
// Referral-bonusta ei koskaan hyväksytä clientin lähettämän
// bonusmäärän perusteella.
//
// Backend määrittää:
//
// - kutsujan
// - referral-suhteen
// - käyttäjämäärän
// - referral-prosentin
// - bonusmäärän
// - bonus-historian
// - referralTotalEarned-arvon
//
// Referral-bonus syntyy vain hyväksytystä mining-tuotosta.
//
// ============================================================

const {
  db,
  FieldValue,
} = require("../firebase/firebase");

const {
  getUserRef,
  getHistoryCollection,
} = require("../utils/userUtils");

const {
  getReferralBonusPercent,
  calculateReferralBonus,
  isValidReferralBonus,
  MAX_CODE_GENERATION_ATTEMPTS,
  REFERRAL_HISTORY_COLLECTION,
} = require("../config/referralConfig");

const {
  normalizeReferralCode,
  isValidReferralCode,
  generateReferralCode,
  getReferralData,
  getReferralCode,
  getReferrerUid,
  getReferralCount,
  validateReferralRelationship,
  buildReferralRelationship,
} = require("../utils/referralUtils");


// ============================================================
// 📁 COLLECTION HELPERS
// ============================================================

function referralCodesCollection() {
  return db.collection("referralCodes");
}

function referralsCollection() {
  return db.collection("referrals");
}


// ============================================================
// 🧮 NUMBER HELPERS
// ============================================================

function safeNumber(
  value,
  fallback = 0,
) {
  const result = Number(value);

  return Number.isFinite(result)
    ? result
    : fallback;
}


function positiveNumber(value) {
  const result = Number(value);

  return Number.isFinite(result) && result > 0
    ? result
    : 0;
}


// ============================================================
// 🔗 REFERRAL CODE DOCUMENT
// ============================================================
//
// referralCodes/{CODE}
//
// Dokumentti yhdistää referral-koodin käyttäjän UID:hen.
//
// ============================================================

function getReferralCodeRef(referralCode) {
  const code = normalizeReferralCode(
    referralCode,
  );

  if (!isValidReferralCode(code)) {
    return null;
  }

  return referralCodesCollection().doc(code);
}


// ============================================================
// 👤 REFERRAL RELATIONSHIP DOCUMENT
// ============================================================
//
// referrals/{referredUid}
//
// Yksi kutsuttu käyttäjä voi kuulua vain yhteen
// Referral-suhteeseen.
//
// ============================================================

function getReferralRelationshipRef(
  referredUid,
) {
  if (
    typeof referredUid !== "string" ||
    !referredUid.trim()
  ) {
    return null;
  }

  return referralsCollection().doc(
    referredUid.trim(),
  );
}


// ============================================================
// 📊 USER COUNT
// ============================================================
//
// Referral-milestonet perustuvat käyttäjämäärään.
//
// Ensisijaisesti käytetään stats/global.totalUsers-arvoa.
//
// Jos sitä ei ole saatavilla, lasketaan users-kokoelman
// dokumentit.
//
// Huom:
//
// Tätä fallbackia käytetään vain tilanteessa, jossa
// keskitetty totalUsers-arvo puuttuu.
//
// ============================================================

async function getTotalUsers(
  transaction = null,
) {
  const statsRef = db
    .collection("stats")
    .doc("global");

  // ----------------------------------------------------------
  // TRANSACTION READ
  // ----------------------------------------------------------

  if (transaction) {
    const statsSnapshot =
      await transaction.get(statsRef);

    if (statsSnapshot.exists) {
      const statsData =
        statsSnapshot.data() || {};

      const storedCount =
        positiveNumber(
          statsData.totalUsers,
        );

      if (storedCount > 0) {
        return Math.floor(storedCount);
      }
    }

    // --------------------------------------------------------
    // FALLBACK
    // --------------------------------------------------------
    //
    // Tämä pidetään yhteensopivuuden vuoksi.
    // Varsinaisessa tuotannossa stats/global.totalUsers
    // pitäisi olla aina ylläpidettynä.
    //
    // --------------------------------------------------------

    const usersSnapshot =
      await transaction.get(
        db.collection("users"),
      );

    return usersSnapshot.size;
  }

  // ----------------------------------------------------------
  // NORMAL READ
  // ----------------------------------------------------------

  const statsSnapshot =
    await statsRef.get();

  if (statsSnapshot.exists) {
    const statsData =
      statsSnapshot.data() || {};

    const storedCount =
      positiveNumber(
        statsData.totalUsers,
      );

    if (storedCount > 0) {
      return Math.floor(storedCount);
    }
  }

  // ----------------------------------------------------------
  // FALLBACK
  // ----------------------------------------------------------

  const usersSnapshot =
    await db
      .collection("users")
      .get();

  return usersSnapshot.size;
}


// ============================================================
// 📈 CURRENT REFERRAL BONUS
// ============================================================

async function getCurrentReferralBonusPercent(
  transaction = null,
) {
  const totalUsers =
    await getTotalUsers(
      transaction,
    );

  return {
    totalUsers,

    bonusPercent:
      getReferralBonusPercent(
        totalUsers,
      ),
  };
}


// ============================================================
// 🔍 FIND REFERRAL CODE
// ============================================================
//
// Hakee referral-koodin omistajan.
//
// ============================================================

async function findReferralCode(
  referralCode,
  transaction = null,
) {
  const normalized =
    normalizeReferralCode(
      referralCode,
    );

  if (!isValidReferralCode(normalized)) {
    return null;
  }

  const ref =
    getReferralCodeRef(
      normalized,
    );

  if (!ref) {
    return null;
  }

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
    typeof data.uid === "string"
      ? data.uid.trim()
      : "";

  if (!uid) {
    return null;
  }

  return {
    ref,
    code: normalized,
    uid,
    data,
  };
}


// ============================================================
// 🎲 CREATE UNIQUE REFERRAL CODE
// ============================================================
//
// Luo käyttäjälle uniikin referral-koodin.
//
// Uniikkius varmistetaan Firestore-transaktion avulla.
//
// ============================================================

async function createReferralCode(
  uid,
  transaction,
) {
  if (
    typeof uid !== "string" ||
    !uid.trim()
  ) {
    throw new Error(
      "REFERRAL_INVALID_UID",
    );
  }

  if (!transaction) {
    throw new Error(
      "REFERRAL_TRANSACTION_REQUIRED",
    );
  }

  const safeUid =
    uid.trim();

  for (
    let attempt = 0;
    attempt < MAX_CODE_GENERATION_ATTEMPTS;
    attempt += 1
  ) {
    const code =
      generateReferralCode();

    const codeRef =
      getReferralCodeRef(
        code,
      );

    if (!codeRef) {
      continue;
    }

    const snapshot =
      await transaction.get(
        codeRef,
      );

    if (snapshot.exists) {
      continue;
    }

    transaction.create(
      codeRef,
      {
        code,

        uid:
          safeUid,

        createdAt:
          FieldValue.serverTimestamp(),
      },
    );

    return {
      code,
      ref: codeRef,
    };
  }

  throw new Error(
    "REFERRAL_CODE_GENERATION_FAILED",
  );
}


// ============================================================
// 🔗 ENSURE USER REFERRAL CODE
// ============================================================
//
// Varmistaa, että olemassa oleva käyttäjä saa referral-koodin.
//
// Jos käyttäjällä on jo validi koodi, sitä ei vaihdeta.
//
// Jos käyttäjää ei ole olemassa, toimintoa ei suoriteta.
//
// ============================================================

async function ensureReferralCode(
  uid,
  transaction,
) {
  if (
    typeof uid !== "string" ||
    !uid.trim()
  ) {
    throw new Error(
      "REFERRAL_INVALID_UID",
    );
  }

  if (!transaction) {
    throw new Error(
      "REFERRAL_TRANSACTION_REQUIRED",
    );
  }

  const safeUid =
    uid.trim();

  const userRef =
    getUserRef(
      safeUid,
    );

  const userSnapshot =
    await transaction.get(
      userRef,
    );

  if (!userSnapshot.exists) {
    throw new Error(
      "REFERRAL_USER_NOT_FOUND",
    );
  }

  const userData =
    userSnapshot.data() || {};

  const existingCode =
    getReferralCode(
      userData,
    );

  if (
    existingCode &&
    isValidReferralCode(
      existingCode,
    )
  ) {
    const existingCodeRef =
      getReferralCodeRef(
        existingCode,
      );

    if (!existingCodeRef) {
      throw new Error(
        "REFERRAL_INVALID_EXISTING_CODE",
      );
    }

    const codeSnapshot =
      await transaction.get(
        existingCodeRef,
      );

    if (!codeSnapshot.exists) {
      transaction.create(
        existingCodeRef,
        {
          code:
            existingCode,

          uid:
            safeUid,

          createdAt:
            FieldValue.serverTimestamp(),
        },
      );

      return {
        code:
          existingCode,

        created:
          false,

        repaired:
          true,

        userData,
      };
    }

    const codeData =
      codeSnapshot.data() || {};

    const codeUid =
      typeof codeData.uid === "string"
        ? codeData.uid.trim()
        : "";

    if (codeUid !== safeUid) {
      throw new Error(
        "REFERRAL_CODE_OWNER_MISMATCH",
      );
    }

    return {
      code:
        existingCode,

      created:
        false,

      repaired:
        false,

      userData,
    };
  }

  const created =
    await createReferralCode(
      safeUid,
      transaction,
    );

  transaction.set(
    userRef,
    {
      referralCode:
        created.code,

      updatedAt:
        FieldValue.serverTimestamp(),
    },
    {
      merge: true,
    },
  );

  return {
    code:
      created.code,

    created:
      true,

    repaired:
      false,

    userData,
  };
}


// ============================================================
// 🤝 CREATE REFERRAL RELATIONSHIP
// ============================================================
//
// Liittää käyttäjän referral-koodin omistajaan.
//
// TÄRKEÄÄ:
//
// Kaikki transaction-readit tehdään ennen write-operaatioita.
//
// Referral-suhdetta ei voi vaihtaa myöhemmin.
//
// ============================================================

async function createReferralRelationship(
  referredUid,
  referralCode,
  transaction,
) {
  const safeUid =
    typeof referredUid === "string"
      ? referredUid.trim()
      : "";

  const normalizedCode =
    normalizeReferralCode(
      referralCode,
    );

  if (!safeUid) {
    throw new Error(
      "REFERRAL_INVALID_REFERRED_UID",
    );
  }

  if (!transaction) {
    throw new Error(
      "REFERRAL_TRANSACTION_REQUIRED",
    );
  }

  if (
    !isValidReferralCode(
      normalizedCode,
    )
  ) {
    throw new Error(
      "REFERRAL_INVALID_CODE",
    );
  }

  const userRef =
    getUserRef(
      safeUid,
    );

  const relationshipRef =
    getReferralRelationshipRef(
      safeUid,
    );

  if (!relationshipRef) {
    throw new Error(
      "REFERRAL_INVALID_RELATIONSHIP_REF",
    );
  }

  // ----------------------------------------------------------
  // READS
  // ----------------------------------------------------------

  const userSnapshot =
    await transaction.get(
      userRef,
    );

  if (!userSnapshot.exists) {
    throw new Error(
      "REFERRAL_USER_NOT_FOUND",
    );
  }

  const relationshipSnapshot =
    await transaction.get(
      relationshipRef,
    );

  const userData =
    userSnapshot.data() || {};

  // ----------------------------------------------------------
  // EXISTING RELATIONSHIP
  // ----------------------------------------------------------

  if (relationshipSnapshot.exists) {
    const existing =
      relationshipSnapshot.data() || {};

    const existingReferrerUid =
      typeof existing.referrerUid === "string"
        ? existing.referrerUid.trim()
        : "";

    const existingReferralCode =
      typeof existing.referralCode === "string"
        ? normalizeReferralCode(
            existing.referralCode,
          )
        : "";

    // --------------------------------------------------------
    // Varmistetaan, ettei olemassa oleva suhde ole ristiriidassa
    // käyttäjän oman referral-datan kanssa.
    // --------------------------------------------------------

    const userReferrerUid =
      getReferrerUid(
        userData,
      );

    if (
      userReferrerUid &&
      existingReferrerUid &&
      userReferrerUid !==
        existingReferrerUid
    ) {
      throw new Error(
        "REFERRAL_RELATIONSHIP_MISMATCH",
      );
    }

    return {
      created:
        false,

      alreadyExists:
        true,

      referrerUid:
        existingReferrerUid,

      referralCode:
        existingReferralCode,
    };
  }

  // ----------------------------------------------------------
  // FIND REFERRER
  // ----------------------------------------------------------

  const referrer =
    await findReferralCode(
      normalizedCode,
      transaction,
    );

  if (!referrer) {
    throw new Error(
      "REFERRAL_CODE_NOT_FOUND",
    );
  }

  // ----------------------------------------------------------
  // REFERRER USER MUST EXIST
  // ----------------------------------------------------------

  const referrerRef =
    getUserRef(
      referrer.uid,
    );

  const referrerSnapshot =
    await transaction.get(
      referrerRef,
    );

  if (!referrerSnapshot.exists) {
    throw new Error(
      "REFERRAL_REFERRER_NOT_FOUND",
    );
  }

  // ----------------------------------------------------------
  // SELF-REFERRAL / EXISTING REFERRER VALIDATION
  // ----------------------------------------------------------

  const validation =
    validateReferralRelationship(
      safeUid,
      referrer.uid,
      userData,
    );

  if (!validation.valid) {
    throw new Error(
      `REFERRAL_${validation.reason}`,
    );
  }

  // ----------------------------------------------------------
  // BUILD RELATIONSHIP
  // ----------------------------------------------------------

  const relationship =
    buildReferralRelationship(
      referrer.uid,
      normalizedCode,
    );

  const now =
    FieldValue.serverTimestamp();

  // ----------------------------------------------------------
  // USER
  // ----------------------------------------------------------

  transaction.set(
    userRef,
    {
      referrerUid:
        relationship.referrerUid,

      referralCodeUsed:
        relationship.referralCodeUsed,

      referralJoinedAt:
        now,

      updatedAt:
        now,
    },
    {
      merge: true,
    },
  );

  // ----------------------------------------------------------
  // RELATIONSHIP
  // ----------------------------------------------------------

  transaction.create(
    relationshipRef,
    {
      referredUid:
        safeUid,

      referrerUid:
        referrer.uid,

      referralCode:
        normalizedCode,

      createdAt:
        now,
    },
  );

  // ----------------------------------------------------------
  // REFERRER COUNT
  // ----------------------------------------------------------

  transaction.set(
    referrerRef,
    {
      referralCount:
        FieldValue.increment(1),

      updatedAt:
        now,
    },
    {
      merge: true,
    },
  );

  return {
    created:
      true,

    alreadyExists:
      false,

    referrerUid:
      referrer.uid,

    referralCode:
      normalizedCode,
  };
}


// ============================================================
// 💰 CALCULATE REFERRAL REWARD
// ============================================================
//
// Laskee referral-bonuksen hyväksytystä mining-tuotosta.
//
// miningAmount tulee backendin hyväksymästä mining-tuloksesta.
//
// Clientin ilmoittamaa bonusmäärää ei käytetä.
//
// ============================================================

async function calculateReferralReward(
  miningAmount,
  transaction = null,
) {
  const amount =
    positiveNumber(
      miningAmount,
    );

  if (amount <= 0) {
    return {
      miningAmount:
        0,

      totalUsers:
        0,

      bonusPercent:
        0,

      bonus:
        0,
    };
  }

  const rate =
    await getCurrentReferralBonusPercent(
      transaction,
    );

  const bonus =
    calculateReferralBonus(
      amount,
      rate.totalUsers,
    );

  return {
    miningAmount:
      amount,

    totalUsers:
      rate.totalUsers,

    bonusPercent:
      rate.bonusPercent,

    bonus:
      isValidReferralBonus(
        bonus,
      )
        ? bonus
        : 0,
  };
}


// ============================================================
// 🛡️ REFERRAL BONUS ID
// ============================================================
//
// Jokainen hyväksytty mining-cycle saa yksilöllisen
// referral transaction ID:n.
//
// ============================================================

function createReferralBonusId(
  miningHistoryId,
) {
  const value =
    typeof miningHistoryId === "string"
      ? miningHistoryId.trim()
      : "";

  if (!value) {
    return "";
  }

  return `referral_${value}`;
}


// ============================================================
// 🔍 CHECK BONUS ALREADY PROCESSED
// ============================================================

async function referralBonusAlreadyProcessed(
  bonusId,
  transaction = null,
) {
  if (!bonusId) {
    return false;
  }

  const ref =
    referralsCollection().doc(
      `_bonus_${bonusId}`,
    );

  const snapshot =
    transaction
      ? await transaction.get(ref)
      : await ref.get();

  return snapshot.exists;
}


// ============================================================
// 💸 APPLY REFERRAL MINING REWARD
// ============================================================
//
// Maksaa referral-bonuksen kutsujalle.
//
// Kaikki tapahtumat tehdään saman transactionin sisällä:
//
// 1. referrer miningBalance
// 2. referrer referralTotalEarned
// 3. user history
// 4. referralHistory
// 5. idempotency-document
//
// Client ei voi määrittää bonusmäärää.
//
// ============================================================

async function applyReferralMiningReward(
  referredUid,
  miningAmount,
  miningTransactionId,
  transaction,
) {
  const safeUid =
    typeof referredUid === "string"
      ? referredUid.trim()
      : "";

  if (!safeUid) {
    return {
      applied:
        false,

      reason:
        "INVALID_REFERRED_UID",

      bonus:
        0,
    };
  }

  if (!transaction) {
    throw new Error(
      "REFERRAL_TRANSACTION_REQUIRED",
    );
  }

  const bonusId =
    createReferralBonusId(
      miningTransactionId,
    );

  if (!bonusId) {
    return {
      applied:
        false,

      reason:
        "INVALID_MINING_TRANSACTION_ID",

      bonus:
        0,
    };
  }

  // ----------------------------------------------------------
  // READS
  // ----------------------------------------------------------

  const alreadyProcessed =
    await referralBonusAlreadyProcessed(
      bonusId,
      transaction,
    );

  if (alreadyProcessed) {
    return {
      applied:
        false,

      alreadyProcessed:
        true,

      reason:
        "ALREADY_PROCESSED",

      bonus:
        0,
    };
  }

  const referredUserRef =
    getUserRef(
      safeUid,
    );

  const referredSnapshot =
    await transaction.get(
      referredUserRef,
    );

  if (!referredSnapshot.exists) {
    return {
      applied:
        false,

      reason:
        "REFERRED_USER_NOT_FOUND",

      bonus:
        0,
    };
  }

  const referredData =
    referredSnapshot.data() || {};

  const referrerUid =
    getReferrerUid(
      referredData,
    );

  if (!referrerUid) {
    return {
      applied:
        false,

      reason:
        "NO_REFERRER",

      bonus:
        0,
    };
  }

  if (referrerUid === safeUid) {
    return {
      applied:
        false,

      reason:
        "SELF_REFERRAL",

      bonus:
        0,
    };
  }

  const referrerRef =
    getUserRef(
      referrerUid,
    );

  const referrerSnapshot =
    await transaction.get(
      referrerRef,
    );

  if (!referrerSnapshot.exists) {
    return {
      applied:
        false,

      reason:
        "REFERRER_NOT_FOUND",

      bonus:
        0,
    };
  }

  // ----------------------------------------------------------
  // CALCULATE BACKEND BONUS
  // ----------------------------------------------------------

  const reward =
    await calculateReferralReward(
      miningAmount,
      transaction,
    );

  if (reward.bonus <= 0) {
    return {
      applied:
        false,

      reason:
        "NO_BONUS",

      bonus:
        0,

      ...reward,
    };
  }

  const referrerData =
    referrerSnapshot.data() || {};

  const oldBalance =
    Math.max(
      0,
      safeNumber(
        referrerData.miningBalance,
      ),
    );

  const oldReferralTotal =
    Math.max(
      0,
      safeNumber(
        referrerData.referralTotalEarned,
      ),
    );

  const newBalance =
    oldBalance +
    reward.bonus;

  const newReferralTotal =
    oldReferralTotal +
    reward.bonus;

  const now =
    FieldValue.serverTimestamp();

  // ----------------------------------------------------------
  // 💰 REFERRER BALANCE
  // ----------------------------------------------------------

  transaction.set(
    referrerRef,
    {
      miningBalance:
        newBalance,

      referralTotalEarned:
        newReferralTotal,

      updatedAt:
        now,
    },
    {
      merge: true,
    },
  );

  // ----------------------------------------------------------
  // 📜 USER HISTORY
  // ----------------------------------------------------------

  const historyRef =
    getHistoryCollection(
      referrerUid,
    ).doc();

  transaction.set(
    historyRef,
    {
      type:
        "referral_reward",

      title:
        "Stella Referral Reward 🐱🤝✨",

      amount:
        reward.bonus,

      balanceAfter:
        newBalance,

      referredUid:
        safeUid,

      referrerUid:
        referrerUid,

      miningAmount:
        reward.miningAmount,

      bonusPercent:
        reward.bonusPercent,

      bonusRate:
        reward.bonusPercent / 100,

      totalUsers:
        reward.totalUsers,

      miningTransactionId:
        miningTransactionId,

      referralBonusId:
        bonusId,

      source:
        "mining",

      createdAt:
        now,
    },
  );

  // ----------------------------------------------------------
  // 📜 GLOBAL REFERRAL HISTORY
  // ----------------------------------------------------------

  const referralHistoryRef =
    db
      .collection(
        REFERRAL_HISTORY_COLLECTION,
      )
      .doc();

  transaction.set(
    referralHistoryRef,
    {
      type:
        "referral_reward",

      amount:
        reward.bonus,

      referredUid:
        safeUid,

      referrerUid:
        referrerUid,

      miningAmount:
        reward.miningAmount,

      bonusPercent:
        reward.bonusPercent,

      bonusRate:
        reward.bonusPercent / 100,

      totalUsers:
        reward.totalUsers,

      miningTransactionId:
        miningTransactionId,

      referralBonusId:
        bonusId,

      createdAt:
        now,
    },
  );

  // ----------------------------------------------------------
  // 🛡️ IDEMPOTENCY
  // ----------------------------------------------------------

  const processedRef =
    referralsCollection().doc(
      `_bonus_${bonusId}`,
    );

  transaction.create(
    processedRef,
    {
      type:
        "referral_bonus_processed",

      referralBonusId:
        bonusId,

      miningTransactionId:
        miningTransactionId,

      referredUid:
        safeUid,

      referrerUid:
        referrerUid,

      amount:
        reward.bonus,

      createdAt:
        now,
    },
  );

  return {
    applied:
      true,

    alreadyProcessed:
      false,

    reason:
      "APPLIED",

    bonus:
      reward.bonus,

    miningAmount:
      reward.miningAmount,

    bonusPercent:
      reward.bonusPercent,

    totalUsers:
      reward.totalUsers,

    referrerUid:
      referrerUid,

    referredUid:
      safeUid,

    referralBonusId:
      bonusId,

    referralTotalEarned:
      newReferralTotal,

    miningBalance:
      newBalance,
  };
}


// ============================================================
// 📊 GET USER REFERRAL SUMMARY
// ============================================================
//
// Palauttaa käyttäjän Referral-tiedot.
//
// ============================================================

async function getReferralSummary(
  uid,
  transaction = null,
) {
  const safeUid =
    typeof uid === "string"
      ? uid.trim()
      : "";

  if (!safeUid) {
    throw new Error(
      "REFERRAL_INVALID_UID",
    );
  }

  const userRef =
    getUserRef(
      safeUid,
    );

  const snapshot =
    transaction
      ? await transaction.get(
          userRef,
        )
      : await userRef.get();

  if (!snapshot.exists) {
    return {
      exists:
        false,

      referralCode:
        "",

      referrerUid:
        "",

      referralCodeUsed:
        "",

      referralJoinedAt:
        null,

      referralCount:
        0,

      referralTotalEarned:
        0,
    };
  }

  const data =
    snapshot.data() || {};

  const referral =
    getReferralData(
      data,
    );

  return {
    exists:
      true,

    referralCode:
      referral.referralCode,

    referrerUid:
      referral.referrerUid,

    referralCodeUsed:
      referral.referralCodeUsed,

    referralJoinedAt:
      referral.referralJoinedAt,

    referralCount:
      getReferralCount(
        data,
      ),

    referralTotalEarned:
      Math.max(
        0,
        safeNumber(
          data.referralTotalEarned,
        ),
      ),
  };
}


// ============================================================
// 📦 EXPORTS
// ============================================================

module.exports = {
  referralCodesCollection,

  referralsCollection,

  getReferralCodeRef,

  getReferralRelationshipRef,

  getTotalUsers,

  getCurrentReferralBonusPercent,

  findReferralCode,

  createReferralCode,

  ensureReferralCode,

  createReferralRelationship,

  calculateReferralReward,

  createReferralBonusId,

  referralBonusAlreadyProcessed,

  applyReferralMiningReward,

  getReferralSummary,
};