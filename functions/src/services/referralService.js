"use strict";

// ============================================================
// 🐱 STELLURIINI - REFERRAL SERVICE
// ============================================================
//
// Stella Referral System.
//
// Tämän palvelun vastuulla on:
//
// - referral-koodien luonti
// - referral-koodien etsiminen
// - kutsujan liittäminen käyttäjään
// - referral-suhteen lukitseminen
// - itsensä kutsumisen estäminen
// - referral-bonuksen laskeminen
//
// TÄRKEÄÄ:
//
// Tämä palvelu EI vielä muuta käyttäjän STL-saldoa.
//
// Varsinainen referral-bonus kirjataan myöhemmin
// yhdessä mining-järjestelmän kanssa.
//
// ============================================================

const crypto = require("crypto");

const {
  db,
  FieldValue,
} = require("../firebase/firebase");

const {
  getReferralBonusRate,
  isValidReferralBonus,
  ALLOW_SELF_REFERRAL,
  ALLOW_REFERRER_CHANGE,
  ONE_REFERRER_PER_USER,
} = require("../config/referralConfig");


// ============================================================
// 📁 FIRESTORE COLLECTIONS
// ============================================================

const USERS_COLLECTION = "users";

const REFERRAL_CODES_COLLECTION =
  "referralCodes";

const REFERRALS_COLLECTION =
  "referrals";


// ============================================================
// 🔢 REFERRAL CODE SETTINGS
// ============================================================

const REFERRAL_CODE_LENGTH = 8;

const MAX_CODE_GENERATION_ATTEMPTS = 10;


// ============================================================
// 🧹 NORMALIZE REFERRAL CODE
// ============================================================

function normalizeReferralCode(
  referralCode,
) {
  if (
    typeof referralCode !== "string"
  ) {
    return "";
  }

  return referralCode
    .trim()
    .toUpperCase();
}


// ============================================================
// 🔤 GENERATE RANDOM REFERRAL CODE
// ============================================================
//
// Käytetään helposti luettavaa merkistöä.
//
// Poistetaan helposti sekoittuvat merkit:
//
// - 0
// - O
// - I
// - 1
//
// ============================================================

function generateRandomReferralCode() {
  const characters =
    "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";

  const randomBytes =
    crypto.randomBytes(
      REFERRAL_CODE_LENGTH,
    );

  let code = "";

  for (
    let index = 0;
    index < REFERRAL_CODE_LENGTH;
    index += 1
  ) {
    code +=
      characters[
        randomBytes[index] %
          characters.length
      ];
  }

  return code;
}


// ============================================================
// 🔍 FIND REFERRAL CODE
// ============================================================
//
// Palauttaa referral-koodin omistajan.
//
// Paluuarvo:
//
// {
//   referralCode,
//   referrerUid
// }
//
// tai null.
//
// ============================================================

async function findReferralCode(
  referralCode,
) {
  const normalizedCode =
    normalizeReferralCode(
      referralCode,
    );

  if (!normalizedCode) {
    return null;
  }

  const snapshot =
    await db
      .collection(
        REFERRAL_CODES_COLLECTION,
      )
      .doc(normalizedCode)
      .get();

  if (!snapshot.exists) {
    return null;
  }

  const data =
    snapshot.data() || {};

  if (
    typeof data.referrerUid !==
    "string"
  ) {
    return null;
  }

  return {
    referralCode:
      normalizedCode,
    referrerUid:
      data.referrerUid,
  };
}


// ============================================================
// 🪪 GET OR CREATE USER REFERRAL CODE
// ============================================================
//
// Palauttaa käyttäjän olemassa olevan
// referral-koodin.
//
// Jos käyttäjällä ei vielä ole koodia,
// luodaan uusi yksilöllinen koodi.
//
// ============================================================

async function getOrCreateReferralCode(
  userId,
) {
  if (
    typeof userId !== "string" ||
    !userId.trim()
  ) {
    throw new Error(
      "Invalid userId.",
    );
  }

  const userRef =
    db
      .collection(
        USERS_COLLECTION,
      )
      .doc(userId);

  const userSnapshot =
    await userRef.get();

  if (!userSnapshot.exists) {
    throw new Error(
      "User profile not found.",
    );
  }

  const userData =
    userSnapshot.data() || {};

  const existingCode =
    normalizeReferralCode(
      userData.referralCode,
    );

  if (existingCode) {
    return existingCode;
  }

  for (
    let attempt = 0;
    attempt <
    MAX_CODE_GENERATION_ATTEMPTS;
    attempt += 1
  ) {
    const referralCode =
      generateRandomReferralCode();

    const codeRef =
      db
        .collection(
          REFERRAL_CODES_COLLECTION,
        )
        .doc(referralCode);

    const created =
      await db.runTransaction(
        async (transaction) => {
          // ----------------------------------------------------
          // 🔍 READ CODE
          // ----------------------------------------------------

          const codeSnapshot =
            await transaction.get(
              codeRef,
            );

          if (codeSnapshot.exists) {
            return false;
          }

          // ----------------------------------------------------
          // 📝 WRITE CODE
          // ----------------------------------------------------

          transaction.set(
            codeRef,
            {
              referrerUid:
                userId,
              referralCode,
              createdAt:
                FieldValue.serverTimestamp(),
            },
          );

          // ----------------------------------------------------
          // 👤 WRITE USER
          // ----------------------------------------------------

          transaction.update(
            userRef,
            {
              referralCode,
            },
          );

          return true;
        },
      );

    if (created) {
      return referralCode;
    }
  }

  throw new Error(
    "Unable to generate a unique referral code.",
  );
}


// ============================================================
// 👥 GET USER REFERRAL DATA
// ============================================================

async function getReferralData(
  userId,
) {
  if (
    typeof userId !== "string" ||
    !userId.trim()
  ) {
    throw new Error(
      "Invalid userId.",
    );
  }

  const referralRef =
    db
      .collection(
        REFERRALS_COLLECTION,
      )
      .doc(userId);

  const snapshot =
    await referralRef.get();

  if (!snapshot.exists) {
    return null;
  }

  return snapshot.data() || null;
}


// ============================================================
// 🔗 APPLY REFERRAL
// ============================================================
//
// Liittää uuden käyttäjän kutsujaan.
//
// Tärkeät säännöt:
//
// 1. Käyttäjällä voi olla vain yksi kutsuja.
// 2. Referral-suhdetta ei voi vaihtaa.
// 3. Käyttäjä ei voi kutsua itseään.
// 4. Referral-koodin täytyy olla olemassa.
// 5. Toiminto tehdään Firestore-transaktiona.
// 6. Kaikki transaktion lukemiset tehdään ennen kirjoituksia.
//
// ============================================================

async function applyReferral(
  userId,
  referralCode,
) {
  if (
    typeof userId !== "string" ||
    !userId.trim()
  ) {
    throw new Error(
      "Invalid userId.",
    );
  }

  const normalizedCode =
    normalizeReferralCode(
      referralCode,
    );

  if (!normalizedCode) {
    throw new Error(
      "Referral code is required.",
    );
  }

  const codeRef =
    db
      .collection(
        REFERRAL_CODES_COLLECTION,
      )
      .doc(normalizedCode);

  const userRef =
    db
      .collection(
        USERS_COLLECTION,
      )
      .doc(userId);

  const referralRef =
    db
      .collection(
        REFERRALS_COLLECTION,
      )
      .doc(userId);

  return db.runTransaction(
    async (transaction) => {
      // ======================================================
      // 🔍 KAIKKI READIT ENSIN
      // ======================================================

      const codeSnapshot =
        await transaction.get(
          codeRef,
        );

      if (!codeSnapshot.exists) {
        throw new Error(
          "Referral code not found.",
        );
      }

      const codeData =
        codeSnapshot.data() || {};

      const referrerUid =
        codeData.referrerUid;

      if (
        typeof referrerUid !==
        "string" ||
        !referrerUid.trim()
      ) {
        throw new Error(
          "Invalid referral code.",
        );
      }

      // ------------------------------------------------------
      // 👤 USER
      // ------------------------------------------------------

      const userSnapshot =
        await transaction.get(
          userRef,
        );

      if (!userSnapshot.exists) {
        throw new Error(
          "User profile not found.",
        );
      }

      const userData =
        userSnapshot.data() || {};

      // ------------------------------------------------------
      // 🔒 REFERRAL DOCUMENT
      // ------------------------------------------------------

      const referralSnapshot =
        await transaction.get(
          referralRef,
        );

      // ------------------------------------------------------
      // 👥 REFERRER USER
      // ------------------------------------------------------

      const referrerRef =
        db
          .collection(
            USERS_COLLECTION,
          )
          .doc(referrerUid);

      const referrerSnapshot =
        await transaction.get(
          referrerRef,
        );

      // ======================================================
      // 🚫 SELF REFERRAL
      // ======================================================

      if (
        !ALLOW_SELF_REFERRAL &&
        referrerUid === userId
      ) {
        throw new Error(
          "Self referral is not allowed.",
        );
      }

      // ======================================================
      // 🔒 EXISTING REFERRER
      // ======================================================

      const existingReferrerUid =
        typeof userData.referrerUid ===
        "string"
          ? userData.referrerUid
          : null;

      if (
        existingReferrerUid &&
        ONE_REFERRER_PER_USER &&
        !ALLOW_REFERRER_CHANGE
      ) {
        if (
          existingReferrerUid ===
          referrerUid
        ) {
          return {
            success: true,
            alreadyApplied: true,
            userId,
            referrerUid,
            referralCode:
              normalizedCode,
          };
        }

        throw new Error(
          "Referral has already been assigned.",
        );
      }

      // ======================================================
      // 🔒 EXISTING REFERRAL DOCUMENT
      // ======================================================

      if (
        referralSnapshot.exists &&
        ONE_REFERRER_PER_USER &&
        !ALLOW_REFERRER_CHANGE
      ) {
        const existingReferral =
          referralSnapshot.data() ||
          {};

        if (
          existingReferral.referrerUid ===
          referrerUid
        ) {
          return {
            success: true,
            alreadyApplied: true,
            userId,
            referrerUid,
            referralCode:
              normalizedCode,
          };
        }

        throw new Error(
          "Referral has already been assigned.",
        );
      }

      // ======================================================
      // 👤 VERIFY REFERRER
      // ======================================================

      if (!referrerSnapshot.exists) {
        throw new Error(
          "Referrer profile not found.",
        );
      }

      // ======================================================
      // 📊 CURRENT REFERRAL COUNT
      // ======================================================

      const referrerData =
        referrerSnapshot.data() ||
        {};

      const currentCount =
        Number.isFinite(
          Number(
            referrerData.referralCount,
          ),
        )
          ? Number(
              referrerData.referralCount,
            )
          : 0;

      // ======================================================
      // 📝 REFERRAL RELATIONSHIP
      // ======================================================

      const referralData = {
        userId,
        referrerUid,
        referralCode:
          normalizedCode,
        createdAt:
          FieldValue.serverTimestamp(),
      };

      transaction.set(
        referralRef,
        referralData,
        {
          merge: false,
        },
      );

      // ======================================================
      // 👤 UPDATE USER PROFILE
      // ======================================================

      transaction.update(
        userRef,
        {
          referrerUid,
          referralCodeUsed:
            normalizedCode,
          referralJoinedAt:
            FieldValue.serverTimestamp(),
        },
      );

      // ======================================================
      // 📊 UPDATE REFERRER COUNTER
      // ======================================================

      transaction.update(
        referrerRef,
        {
          referralCount:
            currentCount + 1,
        },
      );

      // ======================================================
      // ✅ RESULT
      // ======================================================

      return {
        success: true,
        alreadyApplied: false,
        userId,
        referrerUid,
        referralCode:
          normalizedCode,
      };
    },
  );
}


// ============================================================
// 🧮 CALCULATE REFERRAL BONUS
// ============================================================
//
// Laskee referral-bonuksen kutsutun käyttäjän hyväksytystä
// louhintatuotosta.
//
// Esimerkiksi:
//
// miningAmount = 10
// rate = 0.05
//
// bonus = 0.5
//
// Tämä funktio EI kirjoita Firestoreen.
//
// ============================================================

function calculateReferralBonus(
  miningAmount,
  userCount = 0,
) {
  const amount =
    Number(miningAmount);

  if (
    !Number.isFinite(amount) ||
    amount <= 0
  ) {
    return 0;
  }

  const rate =
    getReferralBonusRate(
      userCount,
    );

  const bonus =
    amount * rate;

  if (
    !isValidReferralBonus(
      bonus,
    )
  ) {
    return 0;
  }

  return bonus;
}


// ============================================================
// 📊 GET REFERRER
// ============================================================

async function getReferrer(
  userId,
) {
  const referralData =
    await getReferralData(
      userId,
    );

  if (!referralData) {
    return null;
  }

  if (
    typeof referralData.referrerUid !==
    "string"
  ) {
    return null;
  }

  return referralData.referrerUid;
}


// ============================================================
// 📤 EXPORTS
// ============================================================

module.exports = {
  normalizeReferralCode,
  generateRandomReferralCode,

  findReferralCode,
  getOrCreateReferralCode,

  getReferralData,
  getReferrer,

  applyReferral,

  calculateReferralBonus,
};