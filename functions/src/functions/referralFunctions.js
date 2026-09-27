"use strict";

// ============================================================
// 🐱 STELLURIINI - REFERRAL FUNCTIONS
// ============================================================
//
// Stella Referral System.
//
// Referral-bonus syntyy VAIN kutsutun käyttäjän hyväksytystä
// mining-tuotosta.
//
// Referral EI maksa STL:ää rekisteröitymisestä.
//
// Kaikki referral-bonuksen laskenta tapahtuu backendissä.
//
// Client ei saa päättää:
// - referral-prosenttia
// - bonusmäärää
// - kutsujaa
// - mining-tuottoa
//
// ============================================================

const {
  onCall,
  HttpsError,
} = require("firebase-functions/v2/https");

const {
  db,
  FieldValue,
} = require("../firebase/firebase");

const {
  getUserRef,
  getHistoryCollection,
} = require("../utils/userUtils");

const {
  DEFAULT_REFERRAL_BONUS_PERCENT,
  REFERRAL_CODE_LENGTH,
  REFERRAL_CODE_CHARACTERS,
  MAX_CODE_GENERATION_ATTEMPTS,
  MIN_REFERRAL_BONUS,
  REFERRAL_BONUS_SOURCE,
  REFERRAL_HISTORY_COLLECTION,
  REFERRAL_DATA_FIELD,
  ONE_REFERRER_PER_USER,
  ALLOW_REFERRER_CHANGE,
  ALLOW_SELF_REFERRAL,
  getReferralBonusPercent,
  getReferralBonusRate,
  calculateReferralBonus,
  isValidReferralBonus,
} = require("../config/referralConfig");

// ============================================================
// VALUE HELPERS
// ============================================================

function number(
  value,
  fallback = 0
) {
  const result =
    Number(value);

  return Number.isFinite(result)
    ? result
    : fallback;
}

function positive(
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

function nonNegative(
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

function cleanString(
  value
) {
  return typeof value === "string"
    ? value.trim()
    : "";
}

// ============================================================
// REFERRAL DATA
// ============================================================

function getReferralData(
  data
) {
  const referral =
    data &&
    typeof data[REFERRAL_DATA_FIELD] ===
      "object" &&
    data[REFERRAL_DATA_FIELD] !== null
      ? data[REFERRAL_DATA_FIELD]
      : {};

  return referral;
}

// ============================================================
// REFERRAL CODE NORMALIZATION
// ============================================================

function normalizeReferralCode(
  value
) {
  return cleanString(value)
    .toUpperCase();
}

// ============================================================
// REFERRAL CODE GENERATION
// ============================================================

function randomReferralCode() {
  let code = "";

  const characters =
    REFERRAL_CODE_CHARACTERS;

  const length =
    Math.max(
      1,
      Math.floor(
        number(
          REFERRAL_CODE_LENGTH,
          8
        )
      )
    );

  for (
    let i = 0;
    i < length;
    i++
  ) {
    const index =
      Math.floor(
        Math.random() *
          characters.length
      );

    code +=
      characters[index];
  }

  return code;
}

// ============================================================
// REFERRAL CODE QUERY
// ============================================================
//
// Referral-koodit ovat käyttäjädokumenteissa kentässä:
//
// referral.code
//
// ============================================================

async function findUserByReferralCode(
  code,
  transaction = null
) {
  const normalized =
    normalizeReferralCode(code);

  if (!normalized) {
    return null;
  }

  const query =
    db
      .collection("users")
      .where(
        `${REFERRAL_DATA_FIELD}.code`,
        "==",
        normalized
      )
      .limit(1);

  const snapshot =
    transaction
      ? await transaction.get(query)
      : await query.get();

  if (snapshot.empty) {
    return null;
  }

  const document =
    snapshot.docs[0];

  return {
    ref: document.ref,
    id: document.id,
    data:
      document.data() || {},
  };
}

// ============================================================
// TOTAL USER COUNT
// ============================================================
//
// Referral milestone määräytyy käyttäjämäärän perusteella.
//
// Tämä lasketaan serverillä.
// Client ei voi lähettää käyttäjämäärää.
//
// ============================================================

async function getTotalUserCount(
  transaction = null
) {
  const usersRef =
    db.collection("users");

  const snapshot =
    transaction
      ? await transaction.get(usersRef)
      : await usersRef.get();

  return Math.max(
    0,
    snapshot.size
  );
}

// ============================================================
// REFERRAL BONUS CALCULATION
// ============================================================

async function calculateServerReferralBonus(
  miningAmount,
  transaction = null
) {
  const amount =
    positive(
      miningAmount
    );

  if (amount <= 0) {
    return {
      miningAmount: 0,
      totalUsers: 0,
      bonusPercent:
        DEFAULT_REFERRAL_BONUS_PERCENT,
      bonusRate:
        getReferralBonusRate(0),
      bonus: 0,
    };
  }

  const totalUsers =
    await getTotalUserCount(
      transaction
    );

  const bonusPercent =
    getReferralBonusPercent(
      totalUsers
    );

  const bonusRate =
    getReferralBonusRate(
      totalUsers
    );

  const bonus =
    calculateReferralBonus(
      amount,
      totalUsers
    );

  return {
    miningAmount: amount,

    totalUsers,

    bonusPercent,

    bonusRate,

    bonus:
      Math.max(
        0,
        nonNegative(bonus)
      ),
  };
}

// ============================================================
// REFERRAL HISTORY
// ============================================================

function getReferralHistoryCollection(
  uid
) {
  return getUserRef(uid)
    .collection(
      REFERRAL_HISTORY_COLLECTION
    );
}

// ============================================================
// REFERRAL CODE CREATION
// ============================================================

async function createReferralCodeForUser(
  uid
) {
  if (!uid) {
    throw new HttpsError(
      "invalid-argument",
      "🐱 Käyttäjän tunniste puuttuu."
    );
  }

  const userRef =
    getUserRef(uid);

  return await db.runTransaction(
    async (transaction) => {
      const snapshot =
        await transaction.get(
          userRef
        );

      const data =
        snapshot.exists
          ? snapshot.data() || {}
          : {};

      const referral =
        getReferralData(data);

      const existingCode =
        normalizeReferralCode(
          referral.code
        );

      if (existingCode) {
        return {
          code: existingCode,
          created: false,
        };
      }

      for (
        let attempt = 0;
        attempt <
          MAX_CODE_GENERATION_ATTEMPTS;
        attempt++
      ) {
        const code =
          randomReferralCode();

        const existing =
          await findUserByReferralCode(
            code,
            transaction
          );

        if (existing) {
          continue;
        }

        transaction.set(
          userRef,
          {
            referral: {
              ...referral,

              code,

              createdAt:
                referral.createdAt ||
                FieldValue.serverTimestamp(),

              updatedAt:
                FieldValue.serverTimestamp(),
            },
          },
          {
            merge: true,
          }
        );

        return {
          code,
          created: true,
        };
      }

      throw new HttpsError(
        "aborted",
        "🐱 Referral-koodin luominen epäonnistui. Yritä uudelleen."
      );
    }
  );
}

// ============================================================
// GET REFERRAL INFO
// ============================================================

const getReferralInfo =
  onCall(
    {
      region: "us-central1",
    },
    async (request) => {
      try {
        if (!request.auth) {
          throw new HttpsError(
            "unauthenticated",
            "🐱 Kirjaudu sisään nähdäksesi Referral-tietosi."
          );
        }

        const uid =
          request.auth.uid;

        const userSnapshot =
          await getUserRef(uid)
            .get();

        const data =
          userSnapshot.exists
            ? userSnapshot.data() || {}
            : {};

        const referral =
          getReferralData(data);

        let code =
          normalizeReferralCode(
            referral.code
          );

        if (!code) {
          const created =
            await createReferralCodeForUser(
              uid
            );

          code =
            created.code;
        }

        const totalUsers =
          await getTotalUserCount();

        const bonusPercent =
          getReferralBonusPercent(
            totalUsers
          );

        const bonusRate =
          getReferralBonusRate(
            totalUsers
          );

        const referredUsers =
          Math.max(
            0,
            Math.floor(
              number(
                referral.referredUsers
              )
            )
          );

        const earned =
          nonNegative(
            referral.totalEarned
          );

        return {
          success: true,

          referralCode:
            code,

          hasReferrer:
            Boolean(
              cleanString(
                referral.referrerUid
              )
            ),

          referrerUid:
            cleanString(
              referral.referrerUid
            ) || null,

          referredUsers,

          totalEarned:
            earned,

          totalUsers,

          bonusPercent,

          bonusRate,

          bonusSource:
            REFERRAL_BONUS_SOURCE,

          registrationReward:
            0,
        };
      } catch (error) {
        console.error(
          "getReferralInfo error:",
          error
        );

        if (
          error instanceof HttpsError
        ) {
          throw error;
        }

        throw new HttpsError(
          "internal",
          "🐱 Referral-tietojen lataaminen epäonnistui."
        );
      }
    }
  );

// ============================================================
// CREATE REFERRAL CODE
// ============================================================

const createReferralCode =
  onCall(
    {
      region: "us-central1",
    },
    async (request) => {
      try {
        if (!request.auth) {
          throw new HttpsError(
            "unauthenticated",
            "🐱 Kirjaudu sisään luodaksesi Referral-koodin."
          );
        }

        const uid =
          request.auth.uid;

        const result =
          await createReferralCodeForUser(
            uid
          );

        return {
          success: true,

          referralCode:
            result.code,

          created:
            result.created,
        };
      } catch (error) {
        console.error(
          "createReferralCode error:",
          error
        );

        if (
          error instanceof HttpsError
        ) {
          throw error;
        }

        throw new HttpsError(
          "internal",
          "🐱 Referral-koodin luominen epäonnistui."
        );
      }
    }
  );

// ============================================================
// APPLY REFERRAL CODE
// ============================================================
//
// Käyttäjä voi asettaa kutsujan vain kerran.
//
// Tämä funktio EI maksa STL-palkkiota.
//
// ============================================================

const applyReferralCode =
  onCall(
    {
      region: "us-central1",
    },
    async (request) => {
      try {
        if (!request.auth) {
          throw new HttpsError(
            "unauthenticated",
            "🐱 Kirjaudu sisään käyttääksesi Referral-koodia."
          );
        }

        const uid =
          request.auth.uid;

        const requestedCode =
          normalizeReferralCode(
            request.data?.referralCode
          );

        if (!requestedCode) {
          throw new HttpsError(
            "invalid-argument",
            "🐱 Referral-koodi puuttuu."
          );
        }

        return await db.runTransaction(
          async (transaction) => {
            const userRef =
              getUserRef(uid);

            const userSnapshot =
              await transaction.get(
                userRef
              );

            const userData =
              userSnapshot.exists
                ? userSnapshot.data() || {}
                : {};

            const currentReferral =
              getReferralData(
                userData
              );

            const existingReferrer =
              cleanString(
                currentReferral.referrerUid
              );

            if (
              ONE_REFERRER_PER_USER &&
              existingReferrer
            ) {
              if (
                existingReferrer ===
                uid
              ) {
                throw new HttpsError(
                  "failed-precondition",
                  "🐱 Et voi käyttää omaa Referral-koodiasi."
                );
              }

              if (
                !ALLOW_REFERRER_CHANGE
              ) {
                throw new HttpsError(
                  "already-exists",
                  "🐱 Referral-koodi on jo asetettu eikä sitä voi vaihtaa."
                );
              }
            }

            const referrer =
              await findUserByReferralCode(
                requestedCode,
                transaction
              );

            if (!referrer) {
              throw new HttpsError(
                "not-found",
                "🐱 Referral-koodia ei löytynyt."
              );
            }

            if (
              referrer.id === uid
            ) {
              if (
                !ALLOW_SELF_REFERRAL
              ) {
                throw new HttpsError(
                  "failed-precondition",
                  "🐱 Et voi käyttää omaa Referral-koodiasi."
                );
              }
            }

            const referrerData =
              referrer.data || {};

            const referrerReferral =
              getReferralData(
                referrerData
              );

            const now =
              FieldValue.serverTimestamp();

            transaction.set(
              userRef,
              {
                referral: {
                  ...currentReferral,

                  referrerUid:
                    referrer.id,

                  referrerCode:
                    requestedCode,

                  joinedAt:
                    now,

                  updatedAt:
                    now,
                },
              },
              {
                merge: true,
              }
            );

            const oldReferredUsers =
              Math.max(
                0,
                Math.floor(
                  number(
                    referrerReferral
                      .referredUsers
                  )
                )
              );

            transaction.set(
              referrer.ref,
              {
                referral: {
                  ...referrerReferral,

                  referredUsers:
                    oldReferredUsers + 1,

                  updatedAt:
                    now,
                },
              },
              {
                merge: true,
              }
            );

            return {
              success: true,

              referralApplied:
                true,

              referrerUid:
                referrer.id,

              referralCode:
                requestedCode,

              registrationReward:
                0,

              message:
                "🐱✨ Referral on yhdistetty onnistuneesti. Referral-bonus syntyy kutsutun käyttäjän hyväksytystä louhintatuotosta.",
            };
          }
        );
      } catch (error) {
        console.error(
          "applyReferralCode error:",
          error
        );

        if (
          error instanceof HttpsError
        ) {
          throw error;
        }

        throw new HttpsError(
          "internal",
          "🐱 Referral-koodin käyttäminen epäonnistui."
        );
      }
    }
  );

// ============================================================
// PROCESS REFERRAL MINING REWARD
// ============================================================
//
// Tätä funktiota käytetään backendistä silloin, kun kutsutun
// käyttäjän mining-tuotto on hyväksytty.
//
// TÄRKEÄ:
//
// Tätä ei ole tarkoitettu clientin kutsuttavaksi.
//
// Mining Function kutsuu tätä myöhemmin transactionin sisällä.
//
// ============================================================

async function processReferralMiningReward(
  transaction,
  referredUid,
  miningAmount,
  miningTransactionId
) {
  const amount =
    positive(
      miningAmount
    );

  if (
    !referredUid ||
    amount <= 0
  ) {
    return {
      rewarded: false,
      bonus: 0,
    };
  }

  const transactionId =
    cleanString(
      miningTransactionId
    );

  if (!transactionId) {
    return {
      rewarded: false,
      bonus: 0,
    };
  }

  const referredUserRef =
    getUserRef(
      referredUid
    );

  const referredSnapshot =
    await transaction.get(
      referredUserRef
    );

  if (
    !referredSnapshot.exists
  ) {
    return {
      rewarded: false,
      bonus: 0,
    };
  }

  const referredData =
    referredSnapshot.data() || {};

  const referral =
    getReferralData(
      referredData
    );

  const referrerUid =
    cleanString(
      referral.referrerUid
    );

  if (!referrerUid) {
    return {
      rewarded: false,
      bonus: 0,
    };
  }

  if (
    !ALLOW_SELF_REFERRAL &&
    referrerUid ===
      referredUid
  ) {
    return {
      rewarded: false,
      bonus: 0,
    };
  }

  // ----------------------------------------------------------
  // REFERRAL DUPLICATE PROTECTION
  // ----------------------------------------------------------

  const rewardRef =
    db
      .collection(
        REFERRAL_HISTORY_COLLECTION
      )
      .doc(
        `${referrerUid}_${transactionId}`
      );

  const existingReward =
    await transaction.get(
      rewardRef
    );

  if (
    existingReward.exists
  ) {
    return {
      rewarded: false,
      duplicate: true,
      bonus: 0,
    };
  }

  // ----------------------------------------------------------
  // CALCULATE SERVER-SIDE BONUS
  // ----------------------------------------------------------

  const calculation =
    await calculateServerReferralBonus(
      amount,
      transaction
    );

  const bonus =
    nonNegative(
      calculation.bonus
    );

  if (
    !isValidReferralBonus(
      bonus
    )
  ) {
    return {
      rewarded: false,
      bonus: 0,
    };
  }

  // ----------------------------------------------------------
  // LOAD REFERRER
  // ----------------------------------------------------------

  const referrerRef =
    getUserRef(
      referrerUid
    );

  const referrerSnapshot =
    await transaction.get(
      referrerRef
    );

  if (
    !referrerSnapshot.exists
  ) {
    return {
      rewarded: false,
      bonus: 0,
    };
  }

  const referrerData =
    referrerSnapshot.data() || {};

  const oldBalance =
    nonNegative(
      referrerData.miningBalance
    );

  const newBalance =
    oldBalance +
    bonus;

  const referrerReferral =
    getReferralData(
      referrerData
    );

  const oldTotalEarned =
    nonNegative(
      referrerReferral.totalEarned
    );

  // ----------------------------------------------------------
  // UPDATE REFERRER BALANCE
  // ----------------------------------------------------------

  transaction.set(
    referrerRef,
    {
      miningBalance:
        newBalance,

      referral: {
        ...referrerReferral,

        totalEarned:
          oldTotalEarned +
          bonus,

        updatedAt:
          FieldValue.serverTimestamp(),
      },

      updatedAt:
        FieldValue.serverTimestamp(),
    },
    {
      merge: true,
    }
  );

  // ----------------------------------------------------------
  // REFERRAL HISTORY
  // ----------------------------------------------------------

  transaction.set(
    rewardRef,
    {
      type:
        "referral_reward",

      source:
        REFERRAL_BONUS_SOURCE,

      title:
        "Stella Referral Reward 🐱🔗✨",

      referrerUid,

      referredUid,

      miningTransactionId:
        transactionId,

      miningAmount:
        amount,

      bonusPercent:
        calculation.bonusPercent,

      bonusRate:
        calculation.bonusRate,

      amount:
        bonus,

      balanceBefore:
        oldBalance,

      balanceAfter:
        newBalance,

      totalUsers:
        calculation.totalUsers,

      createdAt:
        FieldValue.serverTimestamp(),
    },
    {
      merge: false,
    }
  );

  // ----------------------------------------------------------
  // REFERRER USER HISTORY
  // ----------------------------------------------------------

  transaction.set(
    getHistoryCollection(
      referrerUid
    ).doc(),
    {
      type:
        "referral_reward",

      title:
        "Stella Referral Reward 🐱🔗✨",

      amount:
        bonus,

      balanceBefore:
        oldBalance,

      balanceAfter:
        newBalance,

      referrerUid,

      referredUid,

      miningTransactionId:
        transactionId,

      miningAmount:
        amount,

      bonusPercent:
        calculation.bonusPercent,

      bonusRate:
        calculation.bonusRate,

      totalUsers:
        calculation.totalUsers,

      createdAt:
        FieldValue.serverTimestamp(),
    }
  );

  return {
    rewarded: true,

    duplicate: false,

    referrerUid,

    referredUid,

    miningAmount:
      amount,

    bonus,

    bonusPercent:
      calculation.bonusPercent,

    bonusRate:
      calculation.bonusRate,

    totalUsers:
      calculation.totalUsers,

    balanceBefore:
      oldBalance,

    balanceAfter:
      newBalance,
  };
}

// ============================================================
// GET REFERRAL STATISTICS
// ============================================================

const getReferralStatistics =
  onCall(
    {
      region: "us-central1",
    },
    async (request) => {
      try {
        if (!request.auth) {
          throw new HttpsError(
            "unauthenticated",
            "🐱 Kirjaudu sisään nähdäksesi Referral-tilastot."
          );
        }

        const uid =
          request.auth.uid;

        const snapshot =
          await getUserRef(uid)
            .get();

        const data =
          snapshot.exists
            ? snapshot.data() || {}
            : {};

        const referral =
          getReferralData(data);

        const totalUsers =
          await getTotalUserCount();

        const bonusPercent =
          getReferralBonusPercent(
            totalUsers
          );

        const bonusRate =
          getReferralBonusRate(
            totalUsers
          );

        return {
          success: true,

          referralCode:
            normalizeReferralCode(
              referral.code
            ) || null,

          referrerUid:
            cleanString(
              referral.referrerUid
            ) || null,

          referredUsers:
            Math.max(
              0,
              Math.floor(
                number(
                  referral.referredUsers
                )
              )
            ),

          totalEarned:
            nonNegative(
              referral.totalEarned
            ),

          totalUsers,

          bonusPercent,

          bonusRate,

          source:
            REFERRAL_BONUS_SOURCE,

          minimumBonus:
            MIN_REFERRAL_BONUS,

          registrationReward:
            0,
        };
      } catch (error) {
        console.error(
          "getReferralStatistics error:",
          error
        );

        if (
          error instanceof HttpsError
        ) {
          throw error;
        }

        throw new HttpsError(
          "internal",
          "🐱 Referral-tilastojen lataaminen epäonnistui."
        );
      }
    }
  );

// ============================================================
// EXPORTS
// ============================================================

module.exports = {
  getReferralInfo,
  createReferralCode,
  applyReferralCode,
  getReferralStatistics,

  // Backend-only function.
  // Tätä käytetään myöhemmin miningFunctions.js:n
  // hyväksytyn mining rewardin yhteydessä.
  processReferralMiningReward,
};