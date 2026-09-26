"use strict";

// ============================================================
// 🐱 STELLURIINI - REFERRAL REWARD SERVICE
// ============================================================
//
// Stella Referral Rewards.
//
// Tämän palvelun vastuulla on:
//
// - referral-suhteen tarkistaminen
// - referral-bonusprosentin määrittäminen
// - mining-tuotosta syntyvän referral-bonuksen laskeminen
// - referral-bonuksen kirjaaminen kutsujalle
// - referral-bonuksen historian kirjoittaminen
// - duplikaattibonusten estäminen
//
// TÄRKEÄÄ:
//
// Referral-bonus EI ole käyttäjän oma mining-tuotto.
//
// Bonus syntyy vain, kun serveri on hyväksynyt kutsutun
// käyttäjän todellisen mining-tuoton.
//
// Tämä palvelu ei luota clientin lähettämään bonusmäärään.
//
// ============================================================

const {
  FieldValue,
} = require("../firebase/firebase");

const {
  getUserRef,
  getHistoryCollection,
} = require("../utils/userUtils");

const {
  getReferralData,
  calculateReferralBonus,
} = require("./referralService");


// ============================================================
// 📊 REFERRAL BONUS TYPE
// ============================================================

const REFERRAL_BONUS_TYPE =
  "referral_bonus";

const REFERRAL_BONUS_TITLE =
  "Stella Referral Bonus 🐱💜";


// ============================================================
// 🔢 VALUE HELPERS
// ============================================================

function positiveNumber(
  value,
) {
  const result =
    Number(value);

  if (
    !Number.isFinite(result) ||
    result <= 0
  ) {
    return 0;
  }

  return result;
}


// ============================================================
// 🆔 REFERRAL REWARD ID
// ============================================================
//
// Luodaan deterministinen tunniste yhdelle mining-cyclelle.
//
// Jos sama mining-tuotto käsitellään uudelleen,
// sama reward ID estää uuden referral-bonuksen.
//
// ============================================================

function createReferralRewardId(
  miningId,
  miningStartedAt,
  miningEndsAt,
) {
  const explicitId =
    typeof miningId === "string"
      ? miningId.trim()
      : "";

  if (explicitId) {
    return `referral_${explicitId}`;
  }

  const start =
    miningStartedAt instanceof Date
      ? miningStartedAt.getTime()
      : new Date(
          miningStartedAt || 0,
        ).getTime();

  const end =
    miningEndsAt instanceof Date
      ? miningEndsAt.getTime()
      : new Date(
          miningEndsAt || 0,
        ).getTime();

  if (
    !Number.isFinite(start) ||
    !Number.isFinite(end) ||
    start <= 0 ||
    end <= start
  ) {
    return "";
  }

  return `referral_${start}_${end}`;
}


// ============================================================
// 🔍 GET REFERRAL REWARD RECORD
// ============================================================

async function getReferralRewardRecord(
  transaction,
  referrerUid,
  rewardId,
) {
  if (
    !transaction ||
    typeof referrerUid !== "string" ||
    !referrerUid.trim() ||
    typeof rewardId !== "string" ||
    !rewardId.trim()
  ) {
    return null;
  }

  const rewardRef =
    getUserRef(referrerUid)
      .collection("referralRewards")
      .doc(rewardId);

  const snapshot =
    await transaction.get(
      rewardRef,
    );

  if (!snapshot.exists) {
    return null;
  }

  return {
    ref: rewardRef,
    data:
      snapshot.data() || {},
  };
}


// ============================================================
// 💰 APPLY REFERRAL REWARD
// ============================================================
//
// Kirjaa referral-bonuksen kutsujalle.
//
// PARAMETRIT:
//
// transaction
// userId
// miningAmount
// miningId
// miningStartedAt
// miningEndsAt
// now
//
// `miningAmount` on serverin laskema hyväksytty mining-tuotto.
//
// Client ei saa määrätä tätä arvoa.
//
// ============================================================

async function applyReferralReward(
  transaction,
  userId,
  miningAmount,
  options = {},
) {
  if (
    !transaction
  ) {
    throw new Error(
      "Firestore transaction is required.",
    );
  }

  if (
    typeof userId !== "string" ||
    !userId.trim()
  ) {
    throw new Error(
      "Invalid userId.",
    );
  }

  const amount =
    positiveNumber(
      miningAmount,
    );

  // ----------------------------------------------------------
  // NO MINING REWARD
  // ----------------------------------------------------------

  if (amount <= 0) {
    return {
      applied: false,
      reason:
        "NO_MINING_REWARD",
      bonus: 0,
    };
  }

  // ----------------------------------------------------------
  // REFERRAL DATA
  // ----------------------------------------------------------

  const referralData =
    await getReferralData(
      userId,
    );

  if (!referralData) {
    return {
      applied: false,
      reason:
        "NO_REFERRER",
      bonus: 0,
    };
  }

  const referrerUid =
    typeof referralData.referrerUid ===
    "string"
      ? referralData.referrerUid.trim()
      : "";

  if (!referrerUid) {
    return {
      applied: false,
      reason:
        "INVALID_REFERRER",
      bonus: 0,
    };
  }

  // ----------------------------------------------------------
  // SELF REFERRAL PROTECTION
  // ----------------------------------------------------------

  if (
    referrerUid === userId
  ) {
    return {
      applied: false,
      reason:
        "SELF_REFERRAL",
      bonus: 0,
    };
  }

  // ----------------------------------------------------------
  // REWARD ID
  // ----------------------------------------------------------

  const rewardId =
    createReferralRewardId(
      options.miningId,
      options.miningStartedAt,
      options.miningEndsAt,
    );

  if (!rewardId) {
    throw new Error(
      "Unable to create referral reward ID.",
    );
  }

  // ----------------------------------------------------------
  // DUPLICATE CHECK
  // ----------------------------------------------------------

  const existingReward =
    await getReferralRewardRecord(
      transaction,
      referrerUid,
      rewardId,
    );

  if (existingReward) {
    return {
      applied: false,
      alreadyApplied: true,
      reason:
        "ALREADY_APPLIED",
      bonus:
        positiveNumber(
          existingReward.data
            ?.bonus,
        ),
      referrerUid,
      rewardId,
    };
  }

  // ----------------------------------------------------------
  // REFERRER USER
  // ----------------------------------------------------------

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
      applied: false,
      reason:
        "REFERRER_NOT_FOUND",
      bonus: 0,
      referrerUid,
      rewardId,
    };
  }

  const referrerData =
    referrerSnapshot.data() || {};

  // ----------------------------------------------------------
  // REFERRAL COUNT
  // ----------------------------------------------------------

  const referralCount =
    Number.isFinite(
      Number(
        referrerData.referralCount,
      ),
    )
      ? Math.max(
          0,
          Math.floor(
            Number(
              referrerData.referralCount,
            ),
          ),
        )
      : 0;

  // ----------------------------------------------------------
  // CALCULATE BONUS
  // ----------------------------------------------------------

  const bonus =
    positiveNumber(
      calculateReferralBonus(
        amount,
        referralCount,
      ),
    );

  if (bonus <= 0) {
    return {
      applied: false,
      reason:
        "BONUS_ZERO",
      bonus: 0,
      referrerUid,
      rewardId,
    };
  }

  // ----------------------------------------------------------
  // CURRENT REFERRER BALANCE
  // ----------------------------------------------------------

  const currentBalance =
    positiveNumber(
      referrerData.miningBalance,
    );

  const newBalance =
    currentBalance +
    bonus;

  const now =
    options.now instanceof Date
      ? options.now
      : new Date();

  // ----------------------------------------------------------
  // REFERRER BALANCE UPDATE
  // ----------------------------------------------------------

  transaction.set(
    referrerRef,
    {
      miningBalance:
        newBalance,

      referralEarnings:
        FieldValue.increment(
          bonus,
        ),

      referralBonusCount:
        FieldValue.increment(
          1,
        ),

      updatedAt:
        FieldValue.serverTimestamp(),
    },
    {
      merge: true,
    },
  );

  // ----------------------------------------------------------
  // REFERRAL REWARD RECORD
  // ----------------------------------------------------------

  const rewardRef =
    referrerRef
      .collection(
        "referralRewards",
      )
      .doc(rewardId);

  transaction.set(
    rewardRef,
    {
      rewardId,

      type:
        REFERRAL_BONUS_TYPE,

      title:
        REFERRAL_BONUS_TITLE,

      userId,

      referrerUid,

      miningAmount:
        amount,

      referralCount,

      bonus,

      balanceBefore:
        currentBalance,

      balanceAfter:
        newBalance,

      miningId:
        typeof options.miningId ===
        "string"
          ? options.miningId
          : null,

      miningStartedAt:
        options.miningStartedAt ||
        null,

      miningEndsAt:
        options.miningEndsAt ||
        null,

      createdAt:
        FieldValue.serverTimestamp(),

      processedAt:
        now,
    },
    {
      merge: false,
    },
  );

  // ----------------------------------------------------------
  // REFERRER HISTORY
  // ----------------------------------------------------------

  transaction.set(
    getHistoryCollection(
      referrerUid,
    ).doc(),
    {
      type:
        REFERRAL_BONUS_TYPE,

      title:
        REFERRAL_BONUS_TITLE,

      amount:
        bonus,

      referralBonus:
        bonus,

      referralUserId:
        userId,

      referrerUid,

      referralCount,

      miningAmount:
        amount,

      balanceAfter:
        newBalance,

      miningId:
        typeof options.miningId ===
        "string"
          ? options.miningId
          : null,

      miningStartedAt:
        options.miningStartedAt ||
        null,

      miningEndsAt:
        options.miningEndsAt ||
        null,

      createdAt:
        FieldValue.serverTimestamp(),
    },
  );

  return {
    applied: true,

    alreadyApplied: false,

    reason:
      "APPLIED",

    bonus,

    miningAmount:
      amount,

    referrerUid,

    referralCount,

    rewardId,

    balanceBefore:
      currentBalance,

    balanceAfter:
      newBalance,
  };
}


// ============================================================
// 📤 EXPORTS
// ============================================================

module.exports = {
  REFERRAL_BONUS_TYPE,
  REFERRAL_BONUS_TITLE,

  createReferralRewardId,

  applyReferralReward,
};