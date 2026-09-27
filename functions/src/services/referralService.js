"use strict";

// ============================================================
// 🐱 STELLURIINI - REFERRAL SERVICE
// ============================================================
//
// Stella Referral System.
//
// Tämä service hoitaa Referral-järjestelmän server-side
// liiketoimintalogiikan.
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
  return db.collection(
    "referralCodes",
  );
}

function referralsCollection() {
  return db.collection(
    "referrals",
  );
}


// ============================================================
// 🧮 NUMBER HELPERS
// ============================================================

function safeNumber(
  value,
  fallback = 0,
) {
  const result =
    Number(value);

  return Number.isFinite(
    result,
  )
    ? result
    : fallback;
}

function positiveNumber(
  value,
) {
  const result =
    Number(value);

  return Number.isFinite(
    result,
  ) &&
    result > 0
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
// Esimerkki:
//
// referralCodes/ABC7K2MP
//
// {
//   code: "ABC7K2MP",
//   uid: "...",
//   createdAt: ...
// }
//
// ============================================================

function getReferralCodeRef(
  referralCode,
) {
  const code =
    normalizeReferralCode(
      referralCode,
    );

  if (
    !isValidReferralCode(
      code,
    )
  ) {
    return null;
  }

  return referralCodesCollection()
    .doc(code);
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
    typeof referredUid !==
      "string" ||
    !referredUid.trim()
  ) {
    return null;
  }

  return referralsCollection()
    .doc(
      referredUid.trim(),
    );
}


// ============================================================
// 📊 USER COUNT
// ============================================================
//
// Referral-milestonet perustuvat järjestelmän
// käyttäjämäärään.
//
// Käytetään users-kokoelman dokumenttien määrää.
//
// ============================================================

async function getTotalUsers(
  transaction = null,
) {
  const usersQuery =
    db.collection("users");

  // ----------------------------------------------------------
  // Firestore count aggregation ei ole kaikissa ympäristöissä
  // käytettävissä samalla tavalla.
  //
  // Referral-järjestelmässä käytetään ensisijaisesti keskitettyä
  // stats-dokumenttia, jos sellainen on olemassa.
  // ----------------------------------------------------------

  const statsRef =
    db.collection("stats")
      .doc("global");

  if (transaction) {
    const statsSnapshot =
      await transaction.get(
        statsRef,
      );

    if (
      statsSnapshot.exists
    ) {
      const statsData =
        statsSnapshot.data() || {};

      const storedCount =
        positiveNumber(
          statsData.totalUsers,
        );

      if (
        storedCount > 0
      ) {
        return Math.floor(
          storedCount,
        );
      }
    }

    // --------------------------------------------------------
    // Jos globaalia käyttäjälaskuria ei ole vielä olemassa,
    // käytetään users-kokoelman lukumäärää.
    // --------------------------------------------------------

    const snapshot =
      await transaction.get(
        usersQuery,
      );

    return snapshot.size;
  }

  const statsSnapshot =
    await statsRef.get();

  if (
    statsSnapshot.exists
  ) {
    const statsData =
      statsSnapshot.data() || {};

    const storedCount =
      positiveNumber(
        statsData.totalUsers,
      );

    if (
      storedCount > 0
    ) {
      return Math.floor(
        storedCount,
      );
    }
  }

  const snapshot =
    await usersQuery.get();

  return snapshot.size;
}


// ============================================================
// 📈 REFERRAL BONUS RATE
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

  if (!ref) {
    return null;
  }

  const snapshot =
    transaction
      ? await transaction.get(
          ref,
        )
      : await ref.get();

  if (
    !snapshot.exists
  ) {
    return null;
  }

  const data =
    snapshot.data() || {};

  const uid =
    typeof data.uid ===
      "string"
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
// Uniikkius varmistetaan Firestore-transaktion sisällä
// ennen kirjoitusta.
//
// ============================================================

async function createReferralCode(
  uid,
  transaction,
) {
  if (
    typeof uid !==
      "string" ||
    !uid.trim()
  ) {
    throw new Error(
      "REFERRAL_INVALID_UID",
    );
  }

  const safeUid =
    uid.trim();

  for (
    let attempt = 0;
    attempt <
    MAX_CODE_GENERATION_ATTEMPTS;
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

    if (
      snapshot.exists
    ) {
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
// Varmistaa, että käyttäjällä on referral-koodi.
//
// Jos koodi on jo olemassa, sitä ei vaihdeta.
//
// Jos koodia ei ole, luodaan uusi.
//
// ============================================================

async function ensureReferralCode(
  uid,
  transaction,
) {
  const userRef =
    getUserRef(uid);

  const userSnapshot =
    await transaction.get(
      userRef,
    );

  const userData =
    userSnapshot.exists
      ? userSnapshot.data() || {}
      : {};

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
    return {
      code:
        existingCode,

      created:
        false,

      userData,
    };
  }

  const created =
    await createReferralCode(
      uid,
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

    userData,
  };
}


// ============================================================
// 🤝 CREATE REFERRAL RELATIONSHIP
// ============================================================
//
// Liittää käyttäjän referral-koodin omistajaan.
//
// Tämä funktio suoritetaan Firestore-transaktion sisällä.
//
// ============================================================

async function createReferralRelationship(
  referredUid,
  referralCode,
  transaction,
) {
  const safeUid =
    typeof referredUid ===
      "string"
      ? referredUid.trim()
      : "";

  const normalizedCode =
    normalizeReferralCode(
      referralCode,
    );

  if (
    !safeUid
  ) {
    throw new Error(
      "REFERRAL_INVALID_REREFERRED_UID",
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

  const userSnapshot =
    await transaction.get(
      userRef,
    );

  const relationshipSnapshot =
    await transaction.get(
      relationshipRef,
    );

  const userData =
    userSnapshot.exists
      ? userSnapshot.data() || {}
      : {};

  // ----------------------------------------------------------
  // Referral-suhdetta ei voi luoda uudelleen.
  // ----------------------------------------------------------

  if (
    relationshipSnapshot.exists
  ) {
    const existing =
      relationshipSnapshot.data() ||
      {};

    return {
      created:
        false,

      alreadyExists:
        true,

      referrerUid:
        typeof existing.referrerUid ===
        "string"
          ? existing.referrerUid
          : "",
    };
  }

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
  // Self-referral
  // ----------------------------------------------------------

  const validation =
    validateReferralRelationship(
      safeUid,
      referrer.uid,
      userData,
    );

  if (
    !validation.valid
  ) {
    throw new Error(
      `REFERRAL_${validation.reason}`,
    );
  }

  const relationship =
    buildReferralRelationship(
      referrer.uid,
      normalizedCode,
    );

  const now =
    FieldValue.serverTimestamp();

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
  // Kutsujan referralCount kasvaa yhdellä.
  // ----------------------------------------------------------

  const referrerRef =
    getUserRef(
      referrer.uid,
    );

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
// TÄRKEÄÄ:
//
// miningAmount tulee backendin hyväksymästä mining-tuloksesta.
// Clientin lähettämää bonusmäärää ei käytetä.
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

  if (
    amount <= 0
  ) {
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
// Tämä ID estää saman mining-tapahtuman maksamisen
// referral-bonuksena kahdesti.
//
// ============================================================

function createReferralBonusId(
  miningHistoryId,
) {
  const value =
    typeof miningHistoryId ===
      "string"
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
  if (
    !bonusId
  ) {
    return false;
  }

  const ref =
    referralsCollection()
      .doc(
        `_bonus_${bonusId}`,
      );

  const snapshot =
    transaction
      ? await transaction.get(
          ref,
        )
      : await ref.get();

  return snapshot.exists;
}


// ============================================================
// 💸 APPLY REFERRAL MINING REWARD
// ============================================================
//
// Maksaa referral-bonuksen kutsujalle.
//
// Tämä funktio EI hyväksy clientin ilmoittamaa bonusmäärää.
//
// miningAmount on kutsutun käyttäjän hyväksytty mining-tuotto.
//
// ============================================================

async function applyReferralMiningReward(
  referredUid,
  miningAmount,
  miningTransactionId,
  transaction,
) {
  const safeUid =
    typeof referredUid ===
      "string"
      ? referredUid.trim()
      : "";

  if (
    !safeUid
  ) {
    return {
      applied:
        false,

      reason:
        "INVALID_REREFERRED_UID",

      bonus:
        0,
    };
  }

  const bonusId =
    createReferralBonusId(
      miningTransactionId,
    );

  if (
    !bonusId
  ) {
    return {
      applied:
        false,

      reason:
        "INVALID_MINING_TRANSACTION_ID",

      bonus:
        0,
    };
  }

  if (
    await referralBonusAlreadyProcessed(
      bonusId,
      transaction,
    )
  ) {
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

  if (
    !referredSnapshot.exists
  ) {
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
    referredSnapshot.data() ||
    {};

  const referrerUid =
    getReferrerUid(
      referredData,
    );

  if (
    !referrerUid
  ) {
    return {
      applied:
        false,

      reason:
        "NO_REFERRER",

      bonus:
        0,
    };
  }

  if (
    referrerUid ===
    safeUid
  ) {
    return {
      applied:
        false,

      reason:
        "SELF_REFERRAL",

      bonus:
        0,
    };
  }

  const reward =
    await calculateReferralReward(
      miningAmount,
      transaction,
    );

  if (
    reward.bonus <= 0
  ) {
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

  const referrerRef =
    getUserRef(
      referrerUid,
    );

  const referrerSnapshot =
    await transaction.get(
      referrerRef,
    );

  if (
    !referrerSnapshot.exists
  ) {
    return {
      applied:
        false,

      reason:
        "REFERRER_NOT_FOUND",

      bonus:
        0,
    };
  }

  const referrerData =
    referrerSnapshot.data() ||
    {};

  const oldBalance =
    Math.max(
      0,
      safeNumber(
        referrerData.miningBalance,
      ),
    );

  const newBalance =
    oldBalance +
    reward.bonus;

  // ----------------------------------------------------------
  // Kutsujan miningBalance
  // ----------------------------------------------------------

  transaction.set(
    referrerRef,
    {
      miningBalance:
        newBalance,

      updatedAt:
        FieldValue.serverTimestamp(),
    },
    {
      merge: true,
    },
  );

  // ----------------------------------------------------------
  // Referral history
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

      referrerUid,

      miningAmount:
        reward.miningAmount,

      bonusPercent:
        reward.bonusPercent,

      bonusRate:
        reward.bonusPercent /
        100,

      totalUsers:
        reward.totalUsers,

      miningTransactionId,

      referralBonusId:
        bonusId,

      source:
        "mining",

      createdAt:
        FieldValue.serverTimestamp(),
    },
  );

  // ----------------------------------------------------------
  // Erillinen Referral-history
  // ----------------------------------------------------------

  const referralHistoryRef =
    db.collection(
      REFERRAL_HISTORY_COLLECTION,
    ).doc();

  transaction.set(
    referralHistoryRef,
    {
      type:
        "referral_reward",

      amount:
        reward.bonus,

      referredUid:
        safeUid,

      referrerUid,

      miningAmount:
        reward.miningAmount,

      bonusPercent:
        reward.bonusPercent,

      totalUsers:
        reward.totalUsers,

      miningTransactionId,

      referralBonusId:
        bonusId,

      createdAt:
        FieldValue.serverTimestamp(),
    },
  );

  // ----------------------------------------------------------
  // Idempotency document
  // ----------------------------------------------------------

  const processedRef =
    referralsCollection()
      .doc(
        `_bonus_${bonusId}`,
      );

  transaction.create(
    processedRef,
    {
      type:
        "referral_bonus_processed",

      referralBonusId:
        bonusId,

      miningTransactionId,

      referredUid:
        safeUid,

      referrerUid,

      amount:
        reward.bonus,

      createdAt:
        FieldValue.serverTimestamp(),
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

    referrerUid,

    referredUid:
      safeUid,

    referralBonusId:
      bonusId,
  };
}


// ============================================================
// 📊 GET USER REFERRAL SUMMARY
// ============================================================
//
// Palauttaa käyttäjän Referral-tiedot.
//
// Tätä voidaan käyttää myöhemmin esimerkiksi
// getReferralStatus-callable-funktiossa.
//
// ============================================================

async function getReferralSummary(
  uid,
  transaction = null,
) {
  const safeUid =
    typeof uid ===
      "string"
      ? uid.trim()
      : "";

  if (
    !safeUid
  ) {
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

  if (
    !snapshot.exists
  ) {
    return {
      exists:
        false,

      referralCode:
        "",

      referrerUid:
        "",

      referralCodeUsed:
        "",

      referralCount:
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