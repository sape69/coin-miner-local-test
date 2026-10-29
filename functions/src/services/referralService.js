
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
// - referral-saavutukset
//
// Referral-bonus syntyy vain hyväksytystä mining-tuotosta.
//
// Referral-achievementit syntyvät vain hyväksytystä
// referral-suhteen luomisesta.
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
  incrementInitializedReferralBonusTotal,
} = require("./referralBonusSummaryService");

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

const {
  applyAchievementProgress,
} = require("../functions/achievementFunctions");

// ============================================================
// COLLECTION HELPERS
// ============================================================

function referralCodesCollection() {
  return db.collection("referralCodes");
}

function referralsCollection() {
  return db.collection("referrals");
}

// ============================================================
// NUMBER HELPERS
// ============================================================

function safeNumber(value, fallback = 0) {
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
// REFERRAL CODE DOCUMENT
// ============================================================

function getReferralCodeRef(referralCode) {
  const code = normalizeReferralCode(referralCode);

  if (!isValidReferralCode(code)) {
    return null;
  }

  return referralCodesCollection().doc(code);
}

// ============================================================
// REFERRAL RELATIONSHIP DOCUMENT
// ============================================================

function getReferralRelationshipRef(referredUid) {
  if (
    typeof referredUid !== "string" ||
    !referredUid.trim()
  ) {
    return null;
  }

  return referralsCollection().doc(referredUid.trim());
}

// ============================================================
// USER COUNT
// ============================================================

async function getTotalUsers(transaction = null) {
  const statsRef = db.collection("stats").doc("global");

  if (transaction) {
    const statsSnapshot = await transaction.get(statsRef);

    if (statsSnapshot.exists) {
      const statsData = statsSnapshot.data() || {};
      const storedCount = positiveNumber(statsData.totalUsers);

      if (storedCount > 0) {
        return Math.floor(storedCount);
      }
    }

    const usersSnapshot = await transaction.get(
      db.collection("users"),
    );

    return usersSnapshot.size;
  }

  const statsSnapshot = await statsRef.get();

  if (statsSnapshot.exists) {
    const statsData = statsSnapshot.data() || {};
    const storedCount = positiveNumber(statsData.totalUsers);

    if (storedCount > 0) {
      return Math.floor(storedCount);
    }
  }

  const usersSnapshot = await db.collection("users").get();

  return usersSnapshot.size;
}

// ============================================================
// CURRENT REFERRAL BONUS
// ============================================================

async function getCurrentReferralBonusPercent(
  transaction = null,
) {
  const totalUsers = await getTotalUsers(transaction);

  return {
    totalUsers,
    bonusPercent: getReferralBonusPercent(totalUsers),
  };
}

// ============================================================
// FIND REFERRAL CODE
// ============================================================

async function findReferralCode(
  referralCode,
  transaction = null,
) {
  const normalized = normalizeReferralCode(referralCode);

  if (!isValidReferralCode(normalized)) {
    return null;
  }

  const ref = getReferralCodeRef(normalized);

  if (!ref) {
    return null;
  }

  const snapshot = transaction
    ? await transaction.get(ref)
    : await ref.get();

  if (!snapshot.exists) {
    return null;
  }

  const data = snapshot.data() || {};
  const uid = typeof data.uid === "string"
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
// CREATE UNIQUE REFERRAL CODE
// ============================================================

async function createReferralCode(uid, transaction) {
  if (typeof uid !== "string" || !uid.trim()) {
    throw new Error("REFERRAL_INVALID_UID");
  }

  if (!transaction) {
    throw new Error("REFERRAL_TRANSACTION_REQUIRED");
  }

  const safeUid = uid.trim();

  for (
    let attempt = 0;
    attempt < MAX_CODE_GENERATION_ATTEMPTS;
    attempt += 1
  ) {
    const code = generateReferralCode();
    const codeRef = getReferralCodeRef(code);

    if (!codeRef) {
      continue;
    }

    const snapshot = await transaction.get(codeRef);

    if (snapshot.exists) {
      continue;
    }

    transaction.create(codeRef, {
      code,
      uid: safeUid,
      createdAt: FieldValue.serverTimestamp(),
    });

    return {
      code,
      ref: codeRef,
    };
  }

  throw new Error("REFERRAL_CODE_GENERATION_FAILED");
}

// ============================================================
// ENSURE USER REFERRAL CODE
// ============================================================

async function ensureReferralCode(uid, transaction) {
  if (typeof uid !== "string" || !uid.trim()) {
    throw new Error("REFERRAL_INVALID_UID");
  }

  if (!transaction) {
    throw new Error("REFERRAL_TRANSACTION_REQUIRED");
  }

  const safeUid = uid.trim();
  const userRef = getUserRef(safeUid);
  const userSnapshot = await transaction.get(userRef);

  if (!userSnapshot.exists) {
    throw new Error("REFERRAL_USER_NOT_FOUND");
  }

  const userData = userSnapshot.data() || {};
  const existingCode = getReferralCode(userData);

  if (
    existingCode &&
    isValidReferralCode(existingCode)
  ) {
    const existingCodeRef = getReferralCodeRef(existingCode);

    if (!existingCodeRef) {
      throw new Error("REFERRAL_INVALID_EXISTING_CODE");
    }

    const codeSnapshot = await transaction.get(existingCodeRef);

    if (!codeSnapshot.exists) {
      transaction.create(existingCodeRef, {
        code: existingCode,
        uid: safeUid,
        createdAt: FieldValue.serverTimestamp(),
      });

      return {
        code: existingCode,
        created: false,
        repaired: true,
        userData,
      };
    }

    const codeData = codeSnapshot.data() || {};
    const codeUid = typeof codeData.uid === "string"
      ? codeData.uid.trim()
      : "";

    if (codeUid !== safeUid) {
      throw new Error("REFERRAL_CODE_OWNER_MISMATCH");
    }

    return {
      code: existingCode,
      created: false,
      repaired: false,
      userData,
    };
  }

  const created = await createReferralCode(
    safeUid,
    transaction,
  );

  transaction.set(
    userRef,
    {
      referralCode: created.code,
      updatedAt: FieldValue.serverTimestamp(),
    },
    { merge: true },
  );

  return {
    code: created.code,
    created: true,
    repaired: false,
    userData,
  };
}

// ============================================================
// APPLY REFERRAL ACHIEVEMENTS
// ============================================================

async function applyReferralAchievements(
  referrerUid,
  referralCount,
  achievementData,
  transaction,
) {
  const safeUid = typeof referrerUid === "string"
    ? referrerUid.trim()
    : "";

  const safeCount = Math.max(
    0,
    Math.floor(safeNumber(referralCount, 0)),
  );

  if (!safeUid || !transaction) {
    return [];
  }

  const achievementIds = [
    "first_invitation",
    "friend_circle",
    "stellas_community",
  ];

  const results = [];

  for (const achievementId of achievementIds) {
    const existingData = achievementData[achievementId] || {};

    const result = applyAchievementProgress(
      transaction,
      safeUid,
      achievementId,
      existingData,
      safeCount,
      new Date(),
    );

    results.push(result);
  }

  return results;
}

// ============================================================
// CREATE REFERRAL RELATIONSHIP
// ============================================================

async function createReferralRelationship(
  referredUid,
  referralCode,
  transaction,
) {
  const safeUid = typeof referredUid === "string"
    ? referredUid.trim()
    : "";

  const normalizedCode = normalizeReferralCode(referralCode);

  if (!safeUid) {
    throw new Error("REFERRAL_INVALID_REFERRED_UID");
  }

  if (!transaction) {
    throw new Error("REFERRAL_TRANSACTION_REQUIRED");
  }

  if (!isValidReferralCode(normalizedCode)) {
    throw new Error("REFERRAL_INVALID_CODE");
  }

  const userRef = getUserRef(safeUid);
  const relationshipRef = getReferralRelationshipRef(safeUid);

  if (!relationshipRef) {
    throw new Error("REFERRAL_INVALID_RELATIONSHIP_REF");
  }

  // READS: all reads before the first write.

  const userSnapshot = await transaction.get(userRef);

  if (!userSnapshot.exists) {
    throw new Error("REFERRAL_USER_NOT_FOUND");
  }

  const relationshipSnapshot = await transaction.get(
    relationshipRef,
  );

  const userData = userSnapshot.data() || {};

  if (relationshipSnapshot.exists) {
    const existing = relationshipSnapshot.data() || {};

    const existingReferrerUid =
      typeof existing.referrerUid === "string"
        ? existing.referrerUid.trim()
        : "";

    const existingReferralCode =
      typeof existing.referralCode === "string"
        ? normalizeReferralCode(existing.referralCode)
        : "";

    const userReferrerUid = getReferrerUid(userData);

    if (
      userReferrerUid &&
      existingReferrerUid &&
      userReferrerUid !== existingReferrerUid
    ) {
      throw new Error("REFERRAL_RELATIONSHIP_MISMATCH");
    }

    return {
      created: false,
      alreadyExists: true,
      referrerUid: existingReferrerUid,
      referralCode: existingReferralCode,
    };
  }

  const referrer = await findReferralCode(
    normalizedCode,
    transaction,
  );

  if (!referrer) {
    throw new Error("REFERRAL_CODE_NOT_FOUND");
  }

  const referrerRef = getUserRef(referrer.uid);
  const referrerSnapshot = await transaction.get(referrerRef);

  if (!referrerSnapshot.exists) {
    throw new Error("REFERRAL_REFERRER_NOT_FOUND");
  }

  const validation = validateReferralRelationship(
    safeUid,
    referrer.uid,
    userData,
  );

  if (!validation.valid) {
    throw new Error(`REFERRAL_${validation.reason}`);
  }

  const achievementIds = [
    "first_invitation",
    "friend_circle",
    "stellas_community",
  ];

  const achievementData = {};

  for (const achievementId of achievementIds) {
    const achievementRef = referrerRef
      .collection("achievements")
      .doc(achievementId);

    const achievementSnapshot = await transaction.get(
      achievementRef,
    );

    achievementData[achievementId] =
      achievementSnapshot.exists
        ? achievementSnapshot.data() || {}
        : {};
  }

  const referrerData = referrerSnapshot.data() || {};
  const oldReferralCount = getReferralCount(referrerData);
  const newReferralCount = oldReferralCount + 1;

  const relationship = buildReferralRelationship(
    referrer.uid,
    normalizedCode,
  );

  const now = FieldValue.serverTimestamp();

  transaction.set(
    userRef,
    {
      referrerUid: relationship.referrerUid,
      referralCodeUsed: relationship.referralCodeUsed,
      referralJoinedAt: now,
      updatedAt: now,
    },
    { merge: true },
  );

  transaction.create(relationshipRef, {
    referredUid: safeUid,
    referrerUid: referrer.uid,
    referralCode: normalizedCode,

    // Uusi suhde alkaa tunnetusta nollasummasta.
    referralBonusTotal: 0,
    referralBonusTotalInitialized: true,

    createdAt: now,
  });

  transaction.set(
    referrerRef,
    {
      referralCount: FieldValue.increment(1),
      updatedAt: now,
    },
    { merge: true },
  );

  const achievementResults = await applyReferralAchievements(
    referrer.uid,
    newReferralCount,
    achievementData,
    transaction,
  );

  return {
    created: true,
    alreadyExists: false,
    referrerUid: referrer.uid,
    referralCode: normalizedCode,
    referralCount: newReferralCount,
    achievements: achievementResults.map((achievement) => ({
      id: achievement.achievementId,
      progress: achievement.progress,
      target: achievement.target,
      unlocked: achievement.unlocked,
      newlyUnlocked: achievement.newlyUnlocked,
      reward: achievement.rewardToCredit,
    })),
  };
}

// ============================================================
// CALCULATE REFERRAL REWARD
// ============================================================

async function calculateReferralReward(
  miningAmount,
  transaction = null,
) {
  const amount = positiveNumber(miningAmount);

  if (amount <= 0) {
    return {
      miningAmount: 0,
      totalUsers: 0,
      bonusPercent: 0,
      bonus: 0,
    };
  }

  const rate = await getCurrentReferralBonusPercent(transaction);

  const bonus = calculateReferralBonus(
    amount,
    rate.totalUsers,
  );

  return {
    miningAmount: amount,
    totalUsers: rate.totalUsers,
    bonusPercent: rate.bonusPercent,
    bonus: isValidReferralBonus(bonus) ? bonus : 0,
  };
}

// ============================================================
// REFERRAL BONUS ID
// ============================================================

function createReferralBonusId(miningHistoryId) {
  const value = typeof miningHistoryId === "string"
    ? miningHistoryId.trim()
    : "";

  if (!value) {
    return "";
  }

  return `referral_${value}`;
}

// ============================================================
// CHECK BONUS ALREADY PROCESSED
// ============================================================

async function referralBonusAlreadyProcessed(
  bonusId,
  transaction = null,
) {
  if (!bonusId) {
    return false;
  }

  const ref = referralsCollection().doc(`_bonus_${bonusId}`);

  const snapshot = transaction
    ? await transaction.get(ref)
    : await ref.get();

  return snapshot.exists;
}

// ============================================================
// APPLY REFERRAL MINING REWARD
// ============================================================

async function applyReferralMiningReward(
  referredUid,
  miningAmount,
  miningTransactionId,
  transaction,
) {
  const safeUid = typeof referredUid === "string"
    ? referredUid.trim()
    : "";

  if (!safeUid) {
    return {
      applied: false,
      reason: "INVALID_REFERRED_UID",
      bonus: 0,
    };
  }

  if (!transaction) {
    throw new Error("REFERRAL_TRANSACTION_REQUIRED");
  }

  const bonusId = createReferralBonusId(miningTransactionId);

  if (!bonusId) {
    return {
      applied: false,
      reason: "INVALID_MINING_TRANSACTION_ID",
      bonus: 0,
    };
  }

  // READS: all reads must happen before any transaction write.

  const alreadyProcessed = await referralBonusAlreadyProcessed(
    bonusId,
    transaction,
  );

  if (alreadyProcessed) {
    return {
      applied: false,
      alreadyProcessed: true,
      reason: "ALREADY_PROCESSED",
      bonus: 0,
    };
  }

  const referredUserRef = getUserRef(safeUid);
  const referredSnapshot = await transaction.get(referredUserRef);

  if (!referredSnapshot.exists) {
    return {
      applied: false,
      reason: "REFERRED_USER_NOT_FOUND",
      bonus: 0,
    };
  }

  const referredData = referredSnapshot.data() || {};
  const referrerUid = getReferrerUid(referredData);

  if (!referrerUid) {
    return {
      applied: false,
      reason: "NO_REFERRER",
      bonus: 0,
    };
  }

  if (referrerUid === safeUid) {
    return {
      applied: false,
      reason: "SELF_REFERRAL",
      bonus: 0,
    };
  }

  const referrerRef = getUserRef(referrerUid);
  const referrerSnapshot = await transaction.get(referrerRef);

  const relationshipRef = getReferralRelationshipRef(safeUid);

  const relationshipSnapshot = relationshipRef
    ? await transaction.get(relationshipRef)
    : null;

  if (!referrerSnapshot.exists) {
    return {
      applied: false,
      reason: "REFERRER_NOT_FOUND",
      bonus: 0,
    };
  }

  const reward = await calculateReferralReward(
    miningAmount,
    transaction,
  );

  if (reward.bonus <= 0) {
    return {
      applied: false,
      reason: "NO_BONUS",
      bonus: 0,
      ...reward,
    };
  }

  const referrerData = referrerSnapshot.data() || {};

  const oldBalance = Math.max(
    0,
    safeNumber(referrerData.miningBalance),
  );

  const oldReferralTotal = Math.max(
    0,
    safeNumber(referrerData.referralTotalEarned),
  );

  const newBalance = oldBalance + reward.bonus;
  const newReferralTotal = oldReferralTotal + reward.bonus;
  const now = FieldValue.serverTimestamp();

  const relationshipData =
    relationshipSnapshot && relationshipSnapshot.exists
      ? relationshipSnapshot.data() || {}
      : null;

  if (
    relationshipData &&
    relationshipData.referrerUid === referrerUid &&
    relationshipData.referredUid === safeUid
  ) {
    incrementInitializedReferralBonusTotal(
      transaction,
      relationshipRef,
      relationshipData,
      reward.bonus,
    );
  }

  // WRITES begin only after all reads and bonus calculation.

  transaction.set(
    referrerRef,
    {
      miningBalance: newBalance,
      referralTotalEarned: newReferralTotal,
      updatedAt: now,
    },
    { merge: true },
  );

  const historyRef = getHistoryCollection(referrerUid).doc();

  transaction.set(historyRef, {
    type: "referral_reward",
    title: "Stella Referral Reward 🐱🤝✨",
    amount: reward.bonus,
    balanceAfter: newBalance,
    referredUid: safeUid,
    referrerUid,
    miningAmount: reward.miningAmount,
    bonusPercent: reward.bonusPercent,
    bonusRate: reward.bonusPercent / 100,
    totalUsers: reward.totalUsers,
    miningTransactionId,
    referralBonusId: bonusId,
    source: "mining",
    createdAt: now,
  });

  const referralHistoryRef = db
    .collection(REFERRAL_HISTORY_COLLECTION)
    .doc();

  transaction.set(referralHistoryRef, {
    type: "referral_reward",
    amount: reward.bonus,
    referredUid: safeUid,
    referrerUid,
    miningAmount: reward.miningAmount,
    bonusPercent: reward.bonusPercent,
    bonusRate: reward.bonusPercent / 100,
    totalUsers: reward.totalUsers,
    miningTransactionId,
    referralBonusId: bonusId,
    createdAt: now,
  });

  const processedRef = referralsCollection().doc(`_bonus_${bonusId}`);

  transaction.create(processedRef, {
    type: "referral_bonus_processed",
    referralBonusId: bonusId,
    miningTransactionId,
    referredUid: safeUid,
    referrerUid,
    amount: reward.bonus,
    createdAt: now,
  });

  return {
    applied: true,
    alreadyProcessed: false,
    reason: "APPLIED",
    bonus: reward.bonus,
    miningAmount: reward.miningAmount,
    bonusPercent: reward.bonusPercent,
    totalUsers: reward.totalUsers,
    referrerUid,
    referredUid: safeUid,
    referralBonusId: bonusId,
    referralTotalEarned: newReferralTotal,
    miningBalance: newBalance,
  };
}

// ============================================================
// GET USER REFERRAL SUMMARY
// ============================================================

async function getReferralSummary(uid, transaction = null) {
  const safeUid = typeof uid === "string"
    ? uid.trim()
    : "";

  if (!safeUid) {
    throw new Error("REFERRAL_INVALID_UID");
  }

  const userRef = getUserRef(safeUid);

  const snapshot = transaction
    ? await transaction.get(userRef)
    : await userRef.get();

  if (!snapshot.exists) {
    return {
      exists: false,
      referralCode: "",
      referrerUid: "",
      referralCodeUsed: "",
      referralJoinedAt: null,
      referralCount: 0,
      referralTotalEarned: 0,
    };
  }

  const data = snapshot.data() || {};
  const referral = getReferralData(data);

  return {
    exists: true,
    referralCode: referral.referralCode,
    referrerUid: referral.referrerUid,
    referralCodeUsed: referral.referralCodeUsed,
    referralJoinedAt: referral.referralJoinedAt,
    referralCount: getReferralCount(data),
    referralTotalEarned: Math.max(
      0,
      safeNumber(data.referralTotalEarned),
    ),
  };
}

// ============================================================
// EXPORTS
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
