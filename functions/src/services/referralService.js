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
// Tämä palvelu EI muuta käyttäjän STL-saldoa.
//
// Varsinainen referral-bonus kirjataan myöhemmin
// yhdessä hyväksytyn mining-tuoton kanssa.
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
  REFERRAL_CODE_LENGTH,
  REFERRAL_CODE_CHARACTERS,
  MAX_CODE_GENERATION_ATTEMPTS,
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
// Käytetään referralConfig.js:n keskitettyä
// merkkijoukkoa ja pituutta.
//
// ============================================================

function generateRandomReferralCode() {
  const characters =
    REFERRAL_CODE_CHARACTERS;

  if (
    typeof characters !== "string" ||
    characters.length === 0
  ) {
    throw new Error(
      "Referral code character set is invalid.",
    );
  }

  const length =
    Math.max(
      1,
      Math.floor(
        Number(
          REFERRAL_CODE_LENGTH,
        ),
      ),
    );

  const randomBytes =
    crypto.randomBytes(length);

  let code = "";

  for (
    let index = 0;
    index < length;
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

  const codeRef =
    db
      .collection(
        REFERRAL_CODES_COLLECTION,
      )
      .doc(normalizedCode);

  const snapshot =
    await codeRef.get();

  if (!snapshot.exists) {
    return null;
  }

  const data =
    snapshot.data() || {};

  const referrerUid =
    typeof data.referrerUid ===
    "string"
      ? data.referrerUid.trim()
      : "";

  if (!referrerUid) {
    return null;
  }

  // ----------------------------------------------------------
  // 🔒 Varmistetaan referral-koodin eheys.
  // ----------------------------------------------------------

  if (
    data.referralCode != null &&
    normalizeReferralCode(
      data.referralCode,
    ) !== normalizedCode
  ) {
    return null;
  }

  return {
    referralCode:
      normalizedCode,

    referrerUid,
  };
}


// ============================================================
// 🪪 GET OR CREATE USER REFERRAL CODE
// ============================================================
//
// Palauttaa käyttäjän olemassa olevan
// kelvollisen referral-koodin.
//
// Jos käyttäjällä ei ole kelvollista koodia,
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

  const normalizedUserId =
    userId.trim();

  const userRef =
    db
      .collection(
        USERS_COLLECTION,
      )
      .doc(normalizedUserId);

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

  // ----------------------------------------------------------
  // 🔒 VALIDATE EXISTING CODE
  // ----------------------------------------------------------

  if (existingCode) {
    const existingCodeRef =
      db
        .collection(
          REFERRAL_CODES_COLLECTION,
        )
        .doc(existingCode);

    const existingCodeSnapshot =
      await existingCodeRef.get();

    if (
      existingCodeSnapshot.exists
    ) {
      const existingCodeData =
        existingCodeSnapshot.data() ||
        {};

      const existingReferrerUid =
        typeof existingCodeData.referrerUid ===
        "string"
          ? existingCodeData.referrerUid.trim()
          : "";

      const storedCode =
        normalizeReferralCode(
          existingCodeData.referralCode,
        );

      if (
        existingReferrerUid ===
          normalizedUserId &&
        (
          !storedCode ||
          storedCode === existingCode
        )
      ) {
        return existingCode;
      }
    }
  }

  // ----------------------------------------------------------
  // 🆕 GENERATE NEW CODE
  // ----------------------------------------------------------

  const maxAttempts =
    Math.max(
      1,
      Math.floor(
        Number(
          MAX_CODE_GENERATION_ATTEMPTS,
        ),
      ),
    );

  for (
    let attempt = 0;
    attempt < maxAttempts;
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
          // --------------------------------------------------
          // 🔍 READ GENERATED CODE
          // --------------------------------------------------

          const codeSnapshot =
            await transaction.get(
              codeRef,
            );

          if (codeSnapshot.exists) {
            return false;
          }

          // --------------------------------------------------
          // 👤 READ CURRENT USER
          // --------------------------------------------------

          const currentUserSnapshot =
            await transaction.get(
              userRef,
            );

          if (
            !currentUserSnapshot.exists
          ) {
            throw new Error(
              "User profile not found.",
            );
          }

          const currentUserData =
            currentUserSnapshot.data() ||
            {};

          const currentCode =
            normalizeReferralCode(
              currentUserData.referralCode,
            );

          // --------------------------------------------------
          // 🔒 VALIDATE CURRENT USER CODE
          // --------------------------------------------------

          if (currentCode) {
            const currentCodeRef =
              db
                .collection(
                  REFERRAL_CODES_COLLECTION,
                )
                .doc(currentCode);

            const currentCodeSnapshot =
              await transaction.get(
                currentCodeRef,
              );

            if (
              currentCodeSnapshot.exists
            ) {
              const currentCodeData =
                currentCodeSnapshot.data() ||
                {};

              const currentReferrerUid =
                typeof currentCodeData.referrerUid ===
                "string"
                  ? currentCodeData.referrerUid.trim()
                  : "";

              const storedCurrentCode =
                normalizeReferralCode(
                  currentCodeData.referralCode,
                );

              if (
                currentReferrerUid ===
                  normalizedUserId &&
                (
                  !storedCurrentCode ||
                  storedCurrentCode ===
                    currentCode
                )
              ) {
                return currentCode;
              }
            }
          }

          // --------------------------------------------------
          // 📝 WRITE NEW REFERRAL CODE
          // --------------------------------------------------

          transaction.set(
            codeRef,
            {
              referrerUid:
                normalizedUserId,

              referralCode,

              createdAt:
                FieldValue.serverTimestamp(),
            },
          );

          // --------------------------------------------------
          // 👤 WRITE USER
          // --------------------------------------------------

          transaction.update(
            userRef,
            {
              referralCode,
            },
          );

          return referralCode;
        },
      );

    // --------------------------------------------------------
    // Existing valid code or newly created code.
    // --------------------------------------------------------

    if (
      typeof created === "string" &&
      created.length > 0
    ) {
      return created;
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

  const normalizedUserId =
    userId.trim();

  const referralRef =
    db
      .collection(
        REFERRALS_COLLECTION,
      )
      .doc(normalizedUserId);

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
// Liittää käyttäjän kutsujaan.
//
// Tärkeät säännöt:
//
// 1. Käyttäjällä voi olla vain yksi kutsuja.
// 2. Referral-suhdetta ei voi vaihtaa normaalisti.
// 3. Käyttäjä ei voi kutsua itseään.
// 4. Referral-koodin täytyy olla olemassa.
// 5. Kutsujan käyttäjäprofiilin täytyy olla olemassa.
// 6. Toiminto tehdään Firestore-transaktiona.
// 7. Kaikki transaktion lukemiset tehdään ennen kirjoituksia.
// 8. Sama referral ei kasvata referralCount-arvoa uudelleen.
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

  const normalizedUserId =
    userId.trim();

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
      .doc(normalizedUserId);

  const referralRef =
    db
      .collection(
        REFERRALS_COLLECTION,
      )
      .doc(normalizedUserId);

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
        typeof codeData.referrerUid ===
        "string"
          ? codeData.referrerUid.trim()
          : "";

      if (!referrerUid) {
        throw new Error(
          "Invalid referral code.",
        );
      }

      // ------------------------------------------------------
      // 🔒 Varmistetaan referral-koodin eheys.
      // ------------------------------------------------------

      if (
        codeData.referralCode != null &&
        normalizeReferralCode(
          codeData.referralCode,
        ) !== normalizedCode
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

      // ------------------------------------------------------
      // 📊 EXISTING REFERRAL DATA
      // ------------------------------------------------------

      const existingReferrerUid =
        typeof userData.referrerUid ===
        "string"
          ? userData.referrerUid.trim()
          : "";

      const existingReferral =
        referralSnapshot.exists
          ? referralSnapshot.data() || {}
          : {};

      const existingReferralUid =
        typeof existingReferral.referrerUid ===
        "string"
          ? existingReferral.referrerUid.trim()
          : "";

      // ======================================================
      // 🚫 SELF REFERRAL
      // ======================================================

      if (
        !ALLOW_SELF_REFERRAL &&
        referrerUid === normalizedUserId
      ) {
        throw new Error(
          "Self referral is not allowed.",
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
      // 🔒 SAME REFERRAL ALREADY APPLIED
      // ======================================================

      if (
        existingReferrerUid ===
          referrerUid ||
        existingReferralUid ===
          referrerUid
      ) {
        return {
          success: true,

          alreadyApplied: true,

          changedReferrer: false,

          userId:
            normalizedUserId,

          referrerUid,

          referralCode:
            normalizedCode,
        };
      }

      // ======================================================
      // 🔒 EXISTING REFERRAL LOCK
      // ======================================================

      if (
        (
          existingReferrerUid ||
          existingReferralUid
        ) &&
        ONE_REFERRER_PER_USER &&
        !ALLOW_REFERRER_CHANGE
      ) {
        throw new Error(
          "Referral has already been assigned.",
        );
      }

      // ======================================================
      // 📊 CURRENT NEW REFERRER COUNT
      // ======================================================

      const newReferrerData =
        referrerSnapshot.data() ||
        {};

      const newReferrerCount =
        Number.isFinite(
          Number(
            newReferrerData.referralCount,
          ),
        )
          ? Math.max(
              0,
              Number(
                newReferrerData.referralCount,
              ),
            )
          : 0;

      // ======================================================
      // 🔄 OPTIONAL REFERRER CHANGE
      // ======================================================

      let oldReferrerRef = null;

      let oldReferrerSnapshot = null;

      let oldReferrerCount = 0;

      const previousReferrerUid =
        existingReferrerUid ||
        existingReferralUid ||
        "";

      if (
        previousReferrerUid &&
        previousReferrerUid !==
          referrerUid &&
        ALLOW_REFERRER_CHANGE
      ) {
        oldReferrerRef =
          db
            .collection(
              USERS_COLLECTION,
            )
            .doc(
              previousReferrerUid,
            );

        oldReferrerSnapshot =
          await transaction.get(
            oldReferrerRef,
          );

        if (
          oldReferrerSnapshot.exists
        ) {
          const oldReferrerData =
            oldReferrerSnapshot.data() ||
            {};

          oldReferrerCount =
            Number.isFinite(
              Number(
                oldReferrerData.referralCount,
              ),
            )
              ? Math.max(
                  0,
                  Number(
                    oldReferrerData.referralCount,
                  ),
                )
              : 0;
        }
      }

      // ======================================================
      // 🕐 ORIGINAL CREATED AT
      // ======================================================

      const originalCreatedAt =
        existingReferral.createdAt ||
        FieldValue.serverTimestamp();

      // ======================================================
      // 📝 REFERRAL RELATIONSHIP
      // ======================================================

      transaction.set(
        referralRef,
        {
          userId:
            normalizedUserId,

          referrerUid,

          referralCode:
            normalizedCode,

          createdAt:
            originalCreatedAt,

          updatedAt:
            FieldValue.serverTimestamp(),
        },
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
            existingReferral.createdAt ||
            FieldValue.serverTimestamp(),

          referralUpdatedAt:
            FieldValue.serverTimestamp(),
        },
      );

      // ======================================================
      // 📊 UPDATE NEW REFERRER COUNTER
      // ======================================================

      transaction.update(
        referrerRef,
        {
          referralCount:
            newReferrerCount + 1,
        },
      );

      // ======================================================
      // 📉 UPDATE OLD REFERRER COUNTER
      // ======================================================

      if (
        oldReferrerRef &&
        oldReferrerSnapshot?.exists
      ) {
        transaction.update(
          oldReferrerRef,
          {
            referralCount:
              Math.max(
                0,
                oldReferrerCount - 1,
              ),
          },
        );
      }

      // ======================================================
      // ✅ RESULT
      // ======================================================

      return {
        success: true,

        alreadyApplied: false,

        changedReferrer:
          Boolean(
            previousReferrerUid &&
            previousReferrerUid !==
              referrerUid,
          ),

        userId:
          normalizedUserId,

        referrerUid,

        previousReferrerUid:
          previousReferrerUid ||
          null,

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

  const safeUserCount =
    Number.isFinite(
      Number(userCount),
    )
      ? Math.max(
          0,
          Number(userCount),
        )
      : 0;

  const rate =
    Number(
      getReferralBonusRate(
        safeUserCount,
      ),
    );

  if (
    !Number.isFinite(rate) ||
    rate < 0
  ) {
    return 0;
  }

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

  const referrerUid =
    referralData.referrerUid.trim();

  return referrerUid || null;
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