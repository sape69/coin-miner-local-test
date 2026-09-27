"use strict";

// ============================================================
// 🐱 STELLURIINI - REFERRAL REWARD SERVICE
// ============================================================
//
// Stella Referral System.
//
// Tämän palvelun tehtävä:
//
// 1. Selvittää kutsutun käyttäjän kutsuja.
// 2. Tarkistaa referral-suhteen.
// 3. Laskea referral-bonus hyväksytystä louhintatuotosta.
// 4. Kirjata referral-tapahtuma Firestoreen.
// 5. Lisätä referral-bonus kutsujan STL-saldoon.
//
// TÄRKEÄÄ:
//
// Referral-bonusta EI makseta:
//
// - rekisteröitymisestä
// - AdMob-mainoksesta
// - Power Boostista
// - referral-koodin käyttämisestä
//
// Referral-bonus syntyy AINOASTAAN kutsutun käyttäjän
// hyväksytystä mining-tuotosta.
//
// Kaikki laskenta tapahtuu backendissä.
//
// ============================================================

const {
  FieldValue,
} = require("../firebase/firebase");

const {
  getReferralBonusRate,
  calculateReferralBonus,
  isValidReferralBonus,
  REFERRAL_BONUS_SOURCE,
  REFERRAL_HISTORY_COLLECTION,
  REFERRAL_DATA_FIELD,
  ONE_REFERRER_PER_USER,
  ALLOW_SELF_REFERRAL,
} = require("../config/referralConfig");

const {
  getUserRef,
} = require("../utils/userUtils");


// ============================================================
// 🔢 VALUE HELPERS
// ============================================================

function safeNumber(
  value,
  fallback = 0
) {
  const number =
    Number(value);

  return Number.isFinite(number)
    ? number
    : fallback;
}


function positiveNumber(
  value,
  fallback = 0
) {
  const number =
    Number(value);

  return Number.isFinite(number) &&
    number > 0
    ? number
    : fallback;
}


// ============================================================
// 👤 REFERRER ID
// ============================================================
//
// Referral-suhde voidaan tallentaa:
//
// users/{uid}.referral.referrerId
//
// tai:
//
// users/{uid}.referrerId
//
// Tämä palvelu tukee molempia muotoja, mutta uusi järjestelmä
// käyttää ensisijaisesti referral.referrerId-kenttää.
//
// ============================================================

function getReferrerId(
  userData
) {
  const data =
    userData || {};

  const referral =
    data[REFERRAL_DATA_FIELD];

  if (
    referral &&
    typeof referral === "object" &&
    typeof referral.referrerId ===
      "string"
  ) {
    const referrerId =
      referral.referrerId.trim();

    if (referrerId) {
      return referrerId;
    }
  }

  if (
    typeof data.referrerId ===
    "string"
  ) {
    const referrerId =
      data.referrerId.trim();

    if (referrerId) {
      return referrerId;
    }
  }

  return null;
}


// ============================================================
// 🔐 REFERRAL RELATIONSHIP VALIDATION
// ============================================================

function validateReferralRelationship(
  referredUserId,
  referrerId
) {
  if (
    typeof referredUserId !==
      "string" ||
    !referredUserId.trim()
  ) {
    return {
      valid: false,
      reason:
        "REFERRED_USER_ID_MISSING",
    };
  }

  if (
    typeof referrerId !==
      "string" ||
    !referrerId.trim()
  ) {
    return {
      valid: false,
      reason:
        "REFERRER_ID_MISSING",
    };
  }

  const referred =
    referredUserId.trim();

  const referrer =
    referrerId.trim();

  if (
    !ALLOW_SELF_REFERRAL &&
    referred === referrer
  ) {
    return {
      valid: false,
      reason:
        "SELF_REFERRAL",
    };
  }

  return {
    valid: true,
    reason: null,
  };
}


// ============================================================
// 📊 REFERRAL RATE
// ============================================================
//
// Referral-prosentti määräytyy järjestelmän käyttäjämäärän
// perusteella.
//
// Tämä palvelu ei hyväksy clientin lähettämää prosenttia.
//
// ============================================================

function getServerReferralRate(
  totalUsers
) {
  return getReferralBonusRate(
    totalUsers
  );
}


// ============================================================
// 🧮 CALCULATE REFERRAL REWARD
// ============================================================
//
// Laskee kutsujalle maksettavan referral-bonuksen.
//
// amount = kutsutun käyttäjän hyväksytty mining-tuotto.
//
// ============================================================

function calculateReward(
  miningAmount,
  totalUsers
) {
  const amount =
    positiveNumber(
      miningAmount
    );

  if (amount <= 0) {
    return 0;
  }

  const bonus =
    calculateReferralBonus(
      amount,
      totalUsers
    );

  return positiveNumber(
    bonus
  );
}


// ============================================================
// 📜 REFERRAL HISTORY REF
// ============================================================

function getReferralHistoryCollection(
  referrerId
) {
  return getUserRef(
    referrerId
  ).collection(
    REFERRAL_HISTORY_COLLECTION
  );
}


// ============================================================
// 🧾 REFERRAL HISTORY DATA
// ============================================================

function buildReferralHistory(
  {
    referredUserId,
    referrerId,
    miningAmount,
    bonusAmount,
    bonusRate,
    totalUsers,
    miningTransactionId = null,
    now,
  }
) {
  return {
    type:
      "referral_reward",

    title:
      "Stella Referral Reward 🐱🤝✨",

    referralBonusSource:
      REFERRAL_BONUS_SOURCE,

    referredUserId,

    referrerId,

    miningAmount,

    bonusAmount,

    bonusRate,

    bonusPercent:
      bonusRate * 100,

    totalUsers,

    miningTransactionId,

    createdAt:
      now ||
      FieldValue.serverTimestamp(),
  };
}


// ============================================================
// 💰 BUILD REFERRER BALANCE UPDATE
// ============================================================
//
// Referral-bonus lisätään kutsujan miningBalance-saldoon.
//
// Käytetään Firestore atomic increment -operaatiota.
//
// ============================================================

function buildBalanceUpdate(
  bonusAmount
) {
  return {
    miningBalance:
      FieldValue.increment(
        bonusAmount
      ),

    updatedAt:
      FieldValue.serverTimestamp(),
  };
}


// ============================================================
// 🔎 FIND REFERRAL RELATIONSHIP
// ============================================================
//
// Hakee kutsutun käyttäjän dokumentin ja selvittää kutsujan.
//
// transaction voidaan antaa mukaan, jotta toiminto voidaan
// suorittaa osana olemassa olevaa Firestore transactionia.
//
// ============================================================

async function getReferralRelationship(
  transaction,
  referredUserId
) {
  if (
    typeof referredUserId !==
      "string" ||
    !referredUserId.trim()
  ) {
    return {
      found: false,

      referredUserId:
        referredUserId || null,

      referrerId: null,

      userData: {},
    };
  }

  const userRef =
    getUserRef(
      referredUserId
    );

  const snapshot =
    transaction
      ? await transaction.get(
          userRef
        )
      : await userRef.get();

  if (!snapshot.exists) {
    return {
      found: false,

      referredUserId,

      referrerId: null,

      userData: {},
    };
  }

  const userData =
    snapshot.data() || {};

  const referrerId =
    getReferrerId(
      userData
    );

  return {
    found: true,

    referredUserId,

    referrerId,

    userData,

    userRef,
  };
}


// ============================================================
// 🎁 PREPARE REFERRAL REWARD
// ============================================================
//
// Tämä funktio tekee kaiken laskennan mutta EI vielä kirjoita
// Firestoreen.
//
// Tämä on tarkoitettu erityisesti miningFunctions.js:n
// transaction-käyttöön.
//
// ============================================================

async function prepareReferralReward(
  transaction,
  {
    referredUserId,
    miningAmount,
    totalUsers,
    miningTransactionId = null,
  }
) {
  const amount =
    positiveNumber(
      miningAmount
    );

  if (amount <= 0) {
    return {
      eligible: false,

      reason:
        "MINING_AMOUNT_ZERO",

      bonusAmount: 0,

      referrerId: null,

      referredUserId,

      miningAmount: 0,

      bonusRate:
        getServerReferralRate(
          totalUsers
        ),
    };
  }

  const relationship =
    await getReferralRelationship(
      transaction,
      referredUserId
    );

  if (
    !relationship.found
  ) {
    return {
      eligible: false,

      reason:
        "REFERRED_USER_NOT_FOUND",

      bonusAmount: 0,

      referrerId: null,

      referredUserId,

      miningAmount: amount,

      bonusRate:
        getServerReferralRate(
          totalUsers
        ),
    };
  }

  const referrerId =
    relationship.referrerId;

  if (!referrerId) {
    return {
      eligible: false,

      reason:
        "NO_REFERRER",

      bonusAmount: 0,

      referrerId: null,

      referredUserId,

      miningAmount: amount,

      bonusRate:
        getServerReferralRate(
          totalUsers
        ),
    };
  }

  const relationshipValidation =
    validateReferralRelationship(
      referredUserId,
      referrerId
    );

  if (
    !relationshipValidation.valid
  ) {
    return {
      eligible: false,

      reason:
        relationshipValidation.reason,

      bonusAmount: 0,

      referrerId,

      referredUserId,

      miningAmount: amount,

      bonusRate:
        getServerReferralRate(
          totalUsers
        ),
    };
  }

  const bonusRate =
    getServerReferralRate(
      totalUsers
    );

  const bonusAmount =
    calculateReward(
      amount,
      totalUsers
    );

  if (
    !isValidReferralBonus(
      bonusAmount
    )
  ) {
    return {
      eligible: false,

      reason:
        "BONUS_ZERO",

      bonusAmount: 0,

      referrerId,

      referredUserId,

      miningAmount: amount,

      bonusRate,
    };
  }

  return {
    eligible: true,

    reason: null,

    bonusAmount,

    referrerId,

    referredUserId,

    miningAmount: amount,

    bonusRate,

    totalUsers:
      safeNumber(
        totalUsers
      ),

    miningTransactionId,
  };
}


// ============================================================
// 💰 APPLY REFERRAL REWARD
// ============================================================
//
// Kirjoittaa referral-bonuksen kutsujan saldoon.
//
// Tämä funktio on tarkoitettu käytettäväksi transactionin
// sisällä.
//
// ============================================================

async function applyReferralReward(
  transaction,
  reward,
  now
) {
  if (
    !reward ||
    reward.eligible !== true
  ) {
    return {
      applied: false,

      bonusAmount: 0,

      referrerId:
        reward?.referrerId ||
        null,
    };
  }

  const bonusAmount =
    positiveNumber(
      reward.bonusAmount
    );

  const referrerId =
    typeof reward.referrerId ===
      "string"
      ? reward.referrerId.trim()
      : "";

  if (
    !referrerId ||
    bonusAmount <= 0
  ) {
    return {
      applied: false,

      bonusAmount: 0,

      referrerId:
        referrerId || null,
    };
  }

  const referrerRef =
    getUserRef(
      referrerId
    );

  const referrerSnapshot =
    await transaction.get(
      referrerRef
    );

  if (
    !referrerSnapshot.exists
  ) {
    return {
      applied: false,

      bonusAmount: 0,

      referrerId,

      reason:
        "REFERRER_NOT_FOUND",
    };
  }

  const historyRef =
    getReferralHistoryCollection(
      referrerId
    ).doc();

  const history =
    buildReferralHistory({
      referredUserId:
        reward.referredUserId,

      referrerId,

      miningAmount:
        reward.miningAmount,

      bonusAmount,

      bonusRate:
        reward.bonusRate,

      totalUsers:
        reward.totalUsers,

      miningTransactionId:
        reward.miningTransactionId,

      now,
    });

  transaction.set(
    referrerRef,
    buildBalanceUpdate(
      bonusAmount
    ),
    {
      merge: true,
    }
  );

  transaction.set(
    historyRef,
    history
  );

  return {
    applied: true,

    bonusAmount,

    referrerId,

    historyId:
      historyRef.id,
  };
}


// ============================================================
// 🧩 PROCESS REFERRAL REWARD
// ============================================================
//
// Yhdistetty helper:
//
// 1. Selvittää referral-suhteen.
// 2. Laskee bonuksen.
// 3. Lisää bonuksen kutsujan saldoon.
// 4. Luo referral history -merkinnän.
//
// Kaikki tehdään saman transactionin sisällä.
//
// ============================================================

async function processReferralReward(
  transaction,
  {
    referredUserId,
    miningAmount,
    totalUsers,
    miningTransactionId = null,
    now = new Date(),
  }
) {
  const reward =
    await prepareReferralReward(
      transaction,
      {
        referredUserId,

        miningAmount,

        totalUsers,

        miningTransactionId,
      }
    );

  if (
    !reward.eligible
  ) {
    return {
      ...reward,

      applied: false,
    };
  }

  const applied =
    await applyReferralReward(
      transaction,
      reward,
      now
    );

  return {
    ...reward,

    ...applied,
  };
}


// ============================================================
// 📊 REFERRAL SUMMARY
// ============================================================
//
// Turvallinen yhteenveto clientille tai muille backend
// funktioille.
//
// ============================================================

function buildReferralSummary(
  {
    referrerId = null,
    bonusRate = 0,
    totalUsers = 0,
  }
) {
  return {
    hasReferrer:
      typeof referrerId ===
        "string" &&
      referrerId.trim().length > 0,

    referrerId:
      referrerId || null,

    bonusRate:
      safeNumber(
        bonusRate
      ),

    bonusPercent:
      safeNumber(
        bonusRate
      ) * 100,

    totalUsers:
      Math.max(
        0,
        Math.floor(
          safeNumber(
            totalUsers
          )
        )
      ),

    oneReferrerPerUser:
      ONE_REFERRER_PER_USER,

    selfReferralAllowed:
      ALLOW_SELF_REFERRAL,

    bonusSource:
      REFERRAL_BONUS_SOURCE,
  };
}


// ============================================================
// 📦 EXPORTS
// ============================================================

module.exports = {
  getReferrerId,

  validateReferralRelationship,

  getServerReferralRate,

  calculateReward,

  getReferralRelationship,

  prepareReferralReward,

  applyReferralReward,

  processReferralReward,

  buildReferralSummary,
};