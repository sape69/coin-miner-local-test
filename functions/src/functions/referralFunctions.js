"use strict";

// ============================================================
// 🐱 STELLURIINI - REFERRAL FUNCTIONS
// ============================================================
//
// Stella Referral System.
//
// Referral-järjestelmä toimii kokonaan backendissä.
//
// Client EI päätä:
// - referral-bonusprosenttia
// - bonusmäärää
// - referreria
// - aktiivisuustilaa
// - referral-palkkion maksamista
//
// Client voi pyytää:
// - oman referral-koodin
// - kutsuttujen käyttäjien listan
// - aktiivisten kutsuttujen määrän
// - referral-bonusten kokonaismäärän
//
// ============================================================
//
// AKTIIVISUUS:
//
// 🟢 ACTIVE
//     = käyttäjän mining-jakso on tällä hetkellä käynnissä.
//
// 🔴 INACTIVE
//     = käyttäjä ei tällä hetkellä louhi.
//
// TÄRKEÄÄ:
//
// "Aktiivinen" EI tarkoita:
// - viimeksi kirjautunutta
// - äskettäin sovellusta käyttänyttä
// - viimeksi päivitettyä käyttäjää
//
// Aktiivinen tarkoittaa tässä referral-järjestelmässä
// nimenomaan sitä, että käyttäjä louhii parhaillaan.
//
// ============================================================
//
// Referral mining reward:
// - maksetaan kutsujalle vain hyväksytystä mining-tuotosta
// - käsitellään Firestore-transaktion sisällä
// - käytetään miningTransactionId:tä idempotenssin varmistamiseen
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
  getUtcDateString,
} = require("../utils/dateUtils");

const {
  DEFAULT_REFERRAL_BONUS_PERCENT,
  REFERRAL_MILESTONES,
  REFERRAL_CODE_LENGTH:
    CONFIG_REFERRAL_CODE_LENGTH,
  REFERRAL_CODE_CHARACTERS,
  MAX_CODE_GENERATION_ATTEMPTS,
  getReferralBonusPercent,
  getReferralBonusRate,
  calculateReferralBonus,
  isValidReferralBonus,
} = require("../config/referralConfig");

// ============================================================
// CONSTANTS
// ============================================================

const MAX_REFERRAL_LIST = 100;

const REFERRAL_CODE_LENGTH =
  Number.isFinite(
    Number(CONFIG_REFERRAL_CODE_LENGTH)
  )
    ? Number(CONFIG_REFERRAL_CODE_LENGTH)
    : 8;

const REFERRAL_CODE_ALPHABET =
  typeof REFERRAL_CODE_CHARACTERS ===
      "string" &&
    REFERRAL_CODE_CHARACTERS.length > 0
    ? REFERRAL_CODE_CHARACTERS
    : "ABCDEFGHJKMNPQRSTUVWXYZ23456789";

const MAX_CODE_ATTEMPTS =
  Number.isFinite(
    Number(MAX_CODE_GENERATION_ATTEMPTS)
  )
    ? Math.max(
        1,
        Math.floor(
          Number(
            MAX_CODE_GENERATION_ATTEMPTS
          )
        )
      )
    : 20;

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

// ============================================================
// TIMESTAMP HELPERS
// ============================================================

function timestampMs(value) {
  if (!value) {
    return 0;
  }

  if (
    typeof value.toMillis ===
    "function"
  ) {
    try {
      const result =
        value.toMillis();

      return Number.isFinite(result)
        ? result
        : 0;
    } catch (_) {
      return 0;
    }
  }

  if (
    typeof value.toDate ===
    "function"
  ) {
    try {
      const date =
        value.toDate();

      return date instanceof Date &&
          Number.isFinite(
            date.getTime()
          )
        ? date.getTime()
        : 0;
    } catch (_) {
      return 0;
    }
  }

  if (
    value instanceof Date
  ) {
    return Number.isFinite(
      value.getTime()
    )
      ? value.getTime()
      : 0;
  }

  if (
    typeof value ===
    "string"
  ) {
    const result =
      new Date(value).getTime();

    return Number.isFinite(result)
      ? result
      : 0;
  }

  if (
    typeof value ===
        "number" &&
    Number.isFinite(value)
  ) {
    return value;
  }

  return 0;
}

// ============================================================
// REFERRAL BONUS CONFIG
// ============================================================

function getCurrentReferralBonusPercent(
  totalUsers
) {
  try {
    return Math.max(
      0,
      Number(
        getReferralBonusPercent(
          totalUsers
        )
      )
    );
  } catch (error) {
    console.error(
      "getReferralBonusPercent error:",
      error
    );

    return Math.max(
      0,
      number(
        DEFAULT_REFERRAL_BONUS_PERCENT,
        0
      )
    );
  }
}

function getCurrentReferralBonusRate(
  totalUsers
) {
  try {
    return Math.max(
      0,
      Number(
        getReferralBonusRate(
          totalUsers
        )
      )
    );
  } catch (error) {
    console.error(
      "getReferralBonusRate error:",
      error
    );

    return (
      getCurrentReferralBonusPercent(
        totalUsers
      ) / 100
    );
  }
}

// ============================================================
// REFERRAL CODE
// ============================================================

function normalizeReferralCode(
  value
) {
  if (
    typeof value !==
    "string"
  ) {
    return "";
  }

  return value
    .trim()
    .toUpperCase()
    .replace(
      /[^A-Z0-9]/g,
      ""
    );
}

function generateReferralCode() {
  let code = "";

  for (
    let i = 0;
    i < REFERRAL_CODE_LENGTH;
    i++
  ) {
    const index =
      Math.floor(
        Math.random() *
          REFERRAL_CODE_ALPHABET.length
      );

    code +=
      REFERRAL_CODE_ALPHABET[
        index
      ];
  }

  return code;
}

// ============================================================
// USER DISPLAY NAME
// ============================================================

function safeDisplayName(
  data,
  uid
) {
  const candidates = [
    data.username,
    data.displayName,
    data.name,
  ];

  for (
    const candidate of
      candidates
  ) {
    if (
      typeof candidate ===
          "string" &&
      candidate.trim()
    ) {
      return candidate
        .trim()
        .slice(0, 40);
    }
  }

  if (
    typeof uid ===
        "string" &&
    uid.length > 0
  ) {
    return `Stella Miner ${uid.slice(
      0,
      6
    )}`;
  }

  return "Stella Miner";
}

// ============================================================
// MINING STATUS
// ============================================================
//
// ACTIVE = käyttäjän mining-jakso on juuri nyt käynnissä.
//
// Tämä tarkistetaan:
//
// miningStartedAt <= nyt < miningEndsAt
//
// ============================================================

function miningWindowActive(
  data,
  nowMs
) {
  const startMs =
    timestampMs(
      data.miningStartedAt
    );

  const endMs =
    timestampMs(
      data.miningEndsAt
    );

  return (
    startMs > 0 &&
    endMs > startMs &&
    nowMs >= startMs &&
    nowMs < endMs
  );
}

// ============================================================
// LAST MINING ACTIVITY
// ============================================================
//
// Tätä käytetään vain järjestämiseen ja lisätietona.
//
// Se EI määritä active/inactive-tilaa.
//
// ============================================================

function lastActivityMs(
  data
) {
  const candidates = [
    data.lastMiningAt,
    data.lastMiningActivityAt,
    data.lastActiveAt,
    data.updatedAt,
    data.miningStartedAt,
  ];

  let latest = 0;

  for (
    const value of
      candidates
  ) {
    latest =
      Math.max(
        latest,
        timestampMs(value)
      );
  }

  return latest;
}

// ============================================================
// REFERRAL ACTIVE USER
// ============================================================

function isReferralUserActive(
  data,
  nowMs
) {
  return miningWindowActive(
    data,
    nowMs
  );
}

// ============================================================
// REFERRAL CODE LOOKUP
// ============================================================

async function findUserByReferralCode(
  code,
  transaction = null
) {
  const normalized =
    normalizeReferralCode(
      code
    );

  if (!normalized) {
    return null;
  }

  const query =
    db.collection("users")
      .where(
        "referralCode",
        "==",
        normalized
      )
      .limit(1);

  const snapshot =
    transaction
      ? await transaction.get(
          query
        )
      : await query.get();

  if (
    snapshot.empty
  ) {
    return null;
  }

  const document =
    snapshot.docs[0];

  return {
    uid:
      document.id,

    ref:
      document.ref,

    data:
      document.data() || {},
  };
}

// ============================================================
// ENSURE OWN REFERRAL CODE
// ============================================================

async function ensureReferralCode(
  uid
) {
  const userRef =
    getUserRef(uid);

  const snapshot =
    await userRef.get();

  const data =
    snapshot.exists
      ? snapshot.data() || {}
      : {};

  const existing =
    normalizeReferralCode(
      data.referralCode
    );

  if (existing) {
    return existing;
  }

  for (
    let attempt = 0;
    attempt <
      MAX_CODE_ATTEMPTS;
    attempt++
  ) {
    const code =
      generateReferralCode();

    const existingUser =
      await findUserByReferralCode(
        code
      );

    if (existingUser) {
      continue;
    }

    await userRef.set(
      {
        referralCode:
          code,

        referralCodeCreatedAt:
          FieldValue.serverTimestamp(),

        updatedAt:
          FieldValue.serverTimestamp(),
      },
      {
        merge: true,
      }
    );

    return code;
  }

  throw new HttpsError(
    "resource-exhausted",
    "🐱 Referral-koodin luominen epäonnistui. Yritä uudelleen."
  );
}

// ============================================================
// TOTAL USER COUNT
// ============================================================

async function getTotalUserCount() {
  const snapshot =
    await db
      .collection("users")
      .count()
      .get();

  return Math.max(
    0,
    number(
      snapshot.data().count,
      0
    )
  );
}

// ============================================================
// CALCULATE REFERRAL BONUS FOR USER
// ============================================================

async function getReferralBonusForUser(
  referrerUid,
  referredUid
) {
  let total = 0;

  try {
    const historyQuery =
      getHistoryCollection(
        referrerUid
      )
        .where(
          "referredUid",
          "==",
          referredUid
        )
        .where(
          "type",
          "==",
          "referral_reward"
        );

    const snapshot =
      await historyQuery.get();

    snapshot.forEach(
      (document) => {
        const data =
          document.data() || {};

        total +=
          nonNegative(
            data.amount
          );
      }
    );
  } catch (error) {
    console.error(
      "Referral bonus history error:",
      error
    );
  }

  return Math.max(
    0,
    total
  );
}

// ============================================================
// PROCESS REFERRAL MINING REWARD
// ============================================================
//
// Tätä funktiota kutsuu miningFunctions.js.
//
// Tämä EI käynnistä uutta Firestore-transaktiota.
//
// Se käyttää miningFunctions.js:n olemassa olevaa
// transaction-objektia.
//
// ============================================================

async function processReferralMiningReward(
  transaction,
  referredUid,
  miningAmount,
  miningTransactionId
) {
  const collected =
    nonNegative(
      miningAmount
    );

  if (!transaction) {
    throw new Error(
      "Referral reward requires a Firestore transaction."
    );
  }

  if (!referredUid) {
    return {
      rewarded: false,
      duplicate: false,
      bonus: 0,
    };
  }

  if (collected <= 0) {
    return {
      rewarded: false,
      duplicate: false,
      bonus: 0,
    };
  }

  if (
    typeof miningTransactionId !==
        "string" ||
    !miningTransactionId.trim()
  ) {
    return {
      rewarded: false,
      duplicate: false,
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
      duplicate: false,
      bonus: 0,
    };
  }

  const referredData =
    referredSnapshot.data() ||
    {};

  const referrerUid =
    typeof referredData.referrerUid ===
        "string"
      ? referredData.referrerUid.trim()
      : "";

  if (
    !referrerUid ||
    referrerUid === referredUid
  ) {
    return {
      rewarded: false,
      duplicate: false,
      bonus: 0,
    };
  }

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
      duplicate: false,
      bonus: 0,
      referrerUid,
    };
  }

  const referrerData =
    referrerSnapshot.data() ||
    {};

  // ----------------------------------------------------------
  // IDEMPOTENCY
  // ----------------------------------------------------------

  const historyRef =
    getHistoryCollection(
      referrerUid
    ).doc(
      `referral_${miningTransactionId}`
    );

  const existingHistory =
    await transaction.get(
      historyRef
    );

  if (
    existingHistory.exists
  ) {
    return {
      rewarded: false,
      duplicate: true,
      bonus: 0,
      referrerUid,
    };
  }

  // ----------------------------------------------------------
  // TOTAL USERS
  // ----------------------------------------------------------

  let totalUsers = 0;

  try {
    totalUsers =
      await getTotalUserCount();
  } catch (countError) {
    console.error(
      "Referral user count error:",
      countError
    );

    totalUsers = 0;
  }

  // ----------------------------------------------------------
  // BONUS
  // ----------------------------------------------------------

  const bonusPercent =
    getCurrentReferralBonusPercent(
      totalUsers
    );

  const bonusRate =
    getCurrentReferralBonusRate(
      totalUsers
    );

  let bonus = 0;

  try {
    bonus =
      Number(
        calculateReferralBonus(
          collected,
          totalUsers
        )
      );
  } catch (calculationError) {
    console.error(
      "Referral bonus calculation error:",
      calculationError
    );

    bonus =
      collected *
      bonusRate;
  }

  bonus =
    Math.max(
      0,
      bonus
    );

  if (
    !isValidReferralBonus(
      bonus
    )
  ) {
    return {
      rewarded: false,
      duplicate: false,
      bonus: 0,
      referrerUid,
      bonusPercent,
      bonusRate,
      totalUsers,
    };
  }

  const oldBalance =
    nonNegative(
      referrerData.miningBalance
    );

  const newBalance =
    oldBalance +
    bonus;

  // ----------------------------------------------------------
  // REFERRER BALANCE
  // ----------------------------------------------------------

  transaction.set(
    referrerRef,
    {
      miningBalance:
        newBalance,

      referralTotalEarned:
        FieldValue.increment(
          bonus
        ),

      referralLastRewardAt:
        FieldValue.serverTimestamp(),

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
    historyRef,
    {
      type:
        "referral_reward",

      title:
        "Stella Referral Reward 🐱🔗✨",

      amount:
        bonus,

      balanceAfter:
        newBalance,

      referredUid,

      referrerUid,

      miningAmount:
        collected,

      bonus,

      bonusPercent,

      bonusRate,

      totalUsers,

      miningTransactionId,

      createdAt:
        FieldValue.serverTimestamp(),
    },
    {
      merge: false,
    }
  );

  // ----------------------------------------------------------
  // REFERRER SUMMARY
  // ----------------------------------------------------------

  transaction.set(
    referrerRef,
    {
      referralLastMiningAmount:
        collected,

      referralLastBonus:
        bonus,

      referralLastReferredUid:
        referredUid,

      updatedAt:
        FieldValue.serverTimestamp(),
    },
    {
      merge: true,
    }
  );

  return {
    rewarded: true,

    duplicate: false,

    bonus,

    referrerUid,

    bonusPercent,

    bonusRate,

    totalUsers,
  };
}

// ============================================================
// GET REFERRAL PROFILE
// ============================================================

const getReferralProfile =
  onCall(
    {
      region:
        "us-central1",
    },
    async (request) => {
      try {
        if (!request.auth) {
          throw new HttpsError(
            "unauthenticated",
            "🐱 Kirjaudu sisään nähdäksesi referral-tietosi."
          );
        }

        const uid =
          request.auth.uid;

        const code =
          await ensureReferralCode(
            uid
          );

        const totalUsers =
          await getTotalUserCount();

        const snapshot =
          await getUserRef(uid)
            .get();

        const data =
          snapshot.exists
            ? snapshot.data() || {}
            : {};

        const totalEarned =
          nonNegative(
            data.referralTotalEarned
          );

        return {
          success:
            true,

          referralCode:
            code,

          referralBonusPercent:
            getCurrentReferralBonusPercent(
              totalUsers
            ),

          referralBonusRate:
            getCurrentReferralBonusRate(
              totalUsers
            ),

          totalUsers,

          referralMilestones:
            REFERRAL_MILESTONES,

          totalReferralRewards:
            totalEarned,

          message:
            "🐱🔗 Stella Referral on valmis.",
        };
      } catch (error) {
        console.error(
          "getReferralProfile error:",
          error
        );

        if (
          error instanceof
          HttpsError
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
// APPLY REFERRAL CODE
// ============================================================

const applyReferralCode =
  onCall(
    {
      region:
        "us-central1",
    },
    async (request) => {
      try {
        if (!request.auth) {
          throw new HttpsError(
            "unauthenticated",
            "🐱 Kirjaudu sisään käyttääksesi referral-koodia."
          );
        }

        const uid =
          request.auth.uid;

        const code =
          normalizeReferralCode(
            request.data?.referralCode
          );

        if (!code) {
          throw new HttpsError(
            "invalid-argument",
            "🐱 Referral-koodi puuttuu."
          );
        }

        if (
          code.length < 4
        ) {
          throw new HttpsError(
            "invalid-argument",
            "🐱 Referral-koodi on liian lyhyt."
          );
        }

        const userRef =
          getUserRef(uid);

        return await db.runTransaction(
          async (transaction) => {
            const userSnapshot =
              await transaction.get(
                userRef
              );

            const userData =
              userSnapshot.exists
                ? userSnapshot.data() || {}
                : {};

            const alreadyReferred =
              typeof userData.referrerUid ===
                    "string" &&
              userData.referrerUid.trim();

            if (
              alreadyReferred
            ) {
              throw new HttpsError(
                "already-exists",
                "🐱 Referral-koodi on jo liitetty tähän käyttäjään."
              );
            }

            const ownCode =
              normalizeReferralCode(
                userData.referralCode
              );

            if (
              ownCode &&
              ownCode === code
            ) {
              throw new HttpsError(
                "invalid-argument",
                "🐱 Et voi käyttää omaa referral-koodiasi."
              );
            }

            const referrer =
              await findUserByReferralCode(
                code,
                transaction
              );

            if (!referrer) {
              throw new HttpsError(
                "not-found",
                "🐱 Referral-koodia ei löytynyt."
              );
            }

            if (
              referrer.uid === uid
            ) {
              throw new HttpsError(
                "invalid-argument",
                "🐱 Et voi käyttää omaa referral-koodiasi."
              );
            }

            transaction.set(
              userRef,
              {
                referrerUid:
                  referrer.uid,

                referralCodeUsed:
                  code,

                referralJoinedAt:
                  FieldValue.serverTimestamp(),

                updatedAt:
                  FieldValue.serverTimestamp(),
              },
              {
                merge: true,
              }
            );

            transaction.set(
              referrer.ref,
              {
                referralCount:
                  FieldValue.increment(
                    1
                  ),

                updatedAt:
                  FieldValue.serverTimestamp(),
              },
              {
                merge: true,
              }
            );

            transaction.set(
              getHistoryCollection(
                uid
              ).doc(),
              {
                type:
                  "referral_joined",

                title:
                  "Stella Referral Joined 🐱🔗",

                referralCode:
                  code,

                referrerUid:
                  referrer.uid,

                createdAt:
                  FieldValue.serverTimestamp(),
              }
            );

            return {
              success:
                true,

              applied:
                true,

              referralCode:
                code,

              referrerUid:
                referrer.uid,

              referrerName:
                safeDisplayName(
                  referrer.data,
                  referrer.uid
                ),

              message:
                "🐱✨ Referral-koodi liitettiin onnistuneesti!",
            };
          }
        );
      } catch (error) {
        console.error(
          "applyReferralCode error:",
          error
        );

        if (
          error instanceof
          HttpsError
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
// GET REFERRED USERS
// ============================================================

const getReferredUsers =
  onCall(
    {
      region:
        "us-central1",

      timeoutSeconds:
        120,
    },
    async (request) => {
      try {
        if (!request.auth) {
          throw new HttpsError(
            "unauthenticated",
            "🐱 Kirjaudu sisään nähdäksesi kutsutut käyttäjät."
          );
        }

        const uid =
          request.auth.uid;

        const now =
          new Date();

        const nowMs =
          now.getTime();

        const today =
          getUtcDateString(
            now
          );

        const ownSnapshot =
          await getUserRef(uid)
            .get();

        const ownData =
          ownSnapshot.exists
            ? ownSnapshot.data() || {}
            : {};

        const referralCode =
          await ensureReferralCode(
            uid
          );

        const totalUsers =
          await getTotalUserCount();

        const referredQuery =
          db.collection("users")
            .where(
              "referrerUid",
              "==",
              uid
            )
            .limit(
              MAX_REFERRAL_LIST
            );

        const referredSnapshot =
          await referredQuery.get();

        const users = [];

        let activeCount =
          0;

        let inactiveCount =
          0;

        const totalReferralRewards =
          nonNegative(
            ownData.referralTotalEarned
          );

        for (
          const document
            of referredSnapshot.docs
        ) {
          const referredUid =
            document.id;

          const data =
            document.data() ||
            {};

          const miningActive =
            miningWindowActive(
              data,
              nowMs
            );

          const active =
            miningActive;

          const lastActivity =
            lastActivityMs(
              data
            );

          if (active) {
            activeCount++;
          } else {
            inactiveCount++;
          }

          const userReferralBonus =
            await getReferralBonusForUser(
              uid,
              referredUid
            );

          users.push({
            uid:
              referredUid,

            displayName:
              safeDisplayName(
                data,
                referredUid
              ),

            active,

            miningActive,

            lastActivityAt:
              lastActivity > 0
                ? new Date(
                    lastActivity
                  ).toISOString()
                : null,

            referralJoinedAt:
              timestampMs(
                data.referralJoinedAt
              ) > 0
                ? new Date(
                    timestampMs(
                      data.referralJoinedAt
                    )
                  ).toISOString()
                : null,

            referralBonusEarned:
              Math.max(
                0,
                userReferralBonus
              ),
          });
        }

        users.sort(
          (a, b) => {
            if (
              a.active !==
              b.active
            ) {
              return a.active
                ? -1
                : 1;
            }

            const aTime =
              timestampMs(
                a.lastActivityAt
              );

            const bTime =
              timestampMs(
                b.lastActivityAt
              );

            return (
              bTime -
              aTime
            );
          }
        );

        return {
          success:
            true,

          referralCode,

          referralBonusPercent:
            getCurrentReferralBonusPercent(
              totalUsers
            ),

          referralBonusRate:
            getCurrentReferralBonusRate(
              totalUsers
            ),

          totalUsers,

          invitedCount:
            users.length,

          activeCount,

          inactiveCount,

          totalReferralRewards,

          generatedAt:
            now.toISOString(),

          utcDate:
            today,

          users,
        };
      } catch (error) {
        console.error(
          "getReferredUsers error:",
          error
        );

        if (
          error instanceof
          HttpsError
        ) {
          throw error;
        }

        throw new HttpsError(
          "internal",
          "🐱 Kutsuttujen käyttäjien lataaminen epäonnistui."
        );
      }
    }
  );

// ============================================================
// GET REFERRAL STATUS
// ============================================================
//
// Flutter ReferralsPage käyttää tätä callablea.
//
// Flutter odottaa:
//
// {
//   referralCode: "...",
//   referralCount: 5,
//   activeCount: 2,
//   inactiveCount: 3,
//   referrals: [
//     {
//       uid: "...",
//       username: "...",
//       isMining: true,
//       referralBonus: 12.5
//     }
//   ]
// }
//
// ============================================================

const getReferralStatus =
  onCall(
    {
      region:
        "us-central1",

      timeoutSeconds:
        120,
    },
    async (request) => {
      try {
        if (!request.auth) {
          throw new HttpsError(
            "unauthenticated",
            "🐱 Kirjaudu sisään nähdäksesi Stella Referralin."
          );
        }

        const uid =
          request.auth.uid;

        const now =
          new Date();

        const nowMs =
          now.getTime();

        // ------------------------------------------------------
        // OWN USER
        // ------------------------------------------------------

        const ownSnapshot =
          await getUserRef(uid)
            .get();

        const ownData =
          ownSnapshot.exists
            ? ownSnapshot.data() || {}
            : {};

        // ------------------------------------------------------
        // REFERRAL CODE
        // ------------------------------------------------------

        const referralCode =
          await ensureReferralCode(
            uid
          );

        // ------------------------------------------------------
        // FIND REFERRED USERS
        // ------------------------------------------------------

        const referredQuery =
          db.collection("users")
            .where(
              "referrerUid",
              "==",
              uid
            )
            .limit(
              MAX_REFERRAL_LIST
            );

        const referredSnapshot =
          await referredQuery.get();

        const referrals = [];

        let activeCount =
          0;

        let inactiveCount =
          0;

        // ------------------------------------------------------
        // BUILD REFERRAL LIST
        // ------------------------------------------------------

        for (
          const document
            of referredSnapshot.docs
        ) {
          const referredUid =
            document.id;

          const data =
            document.data() ||
            {};

          const isMining =
            isReferralUserActive(
              data,
              nowMs
            );

          if (isMining) {
            activeCount++;
          } else {
            inactiveCount++;
          }

          const referralBonus =
            await getReferralBonusForUser(
              uid,
              referredUid
            );

          referrals.push({
            uid:
              referredUid,

            username:
              safeDisplayName(
                data,
                referredUid
              ),

            isMining,

            referralBonus:
              Math.max(
                0,
                referralBonus
              ),
          });
        }

        // ------------------------------------------------------
        // SORT
        // ------------------------------------------------------
        //
        // Louhivat ensin.
        // Sen jälkeen ei-louhivat.
        //
        // ------------------------------------------------------

        referrals.sort(
          (a, b) => {
            if (
              a.isMining !==
              b.isMining
            ) {
              return a.isMining
                ? -1
                : 1;
            }

            return a.username.localeCompare(
              b.username
            );
          }
        );

        // ------------------------------------------------------
        // RESPONSE
        // ------------------------------------------------------

        return {
          success:
            true,

          referralCode,

          referralCount:
            referrals.length,

          activeCount,

          inactiveCount,

          referrals,

          totalReferralRewards:
            nonNegative(
              ownData.referralTotalEarned
            ),

          generatedAt:
            now.toISOString(),
        };
      } catch (error) {
        console.error(
          "getReferralStatus error:",
          error
        );

        if (
          error instanceof
          HttpsError
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
// GET FULL REFERRAL DASHBOARD
// ============================================================

const getReferralDashboard =
  onCall(
    {
      region:
        "us-central1",

      timeoutSeconds:
        120,
    },
    async (request) => {
      try {
        if (!request.auth) {
          throw new HttpsError(
            "unauthenticated",
            "🐱 Kirjaudu sisään nähdäksesi Stella Referralin."
          );
        }

        const uid =
          request.auth.uid;

        const code =
          await ensureReferralCode(
            uid
          );

        const now =
          new Date();

        const nowMs =
          now.getTime();

        const userSnapshot =
          await getUserRef(uid)
            .get();

        const userData =
          userSnapshot.exists
            ? userSnapshot.data() || {}
            : {};

        const totalUsers =
          await getTotalUserCount();

        const referredQuery =
          db.collection("users")
            .where(
              "referrerUid",
              "==",
              uid
            )
            .limit(
              MAX_REFERRAL_LIST
            );

        const referredSnapshot =
          await referredQuery.get();

        const users = [];

        let activeCount =
          0;

        let inactiveCount =
          0;

        for (
          const document
            of referredSnapshot.docs
        ) {
          const referredUid =
            document.id;

          const data =
            document.data() ||
            {};

          const miningActive =
            miningWindowActive(
              data,
              nowMs
            );

          const active =
            miningActive;

          const lastActivity =
            lastActivityMs(
              data
            );

          if (active) {
            activeCount++;
          } else {
            inactiveCount++;
          }

          users.push({
            uid:
              referredUid,

            displayName:
              safeDisplayName(
                data,
                referredUid
              ),

            active,

            miningActive,

            lastActivityAt:
              lastActivity > 0
                ? new Date(
                    lastActivity
                  ).toISOString()
                : null,

            referralJoinedAt:
              timestampMs(
                data.referralJoinedAt
              ) > 0
                ? new Date(
                    timestampMs(
                      data.referralJoinedAt
                    )
                  ).toISOString()
                : null,
          });
        }

        users.sort(
          (a, b) => {
            if (
              a.active !==
              b.active
            ) {
              return a.active
                ? -1
                : 1;
            }

            return (
              timestampMs(
                b.lastActivityAt
              ) -
              timestampMs(
                a.lastActivityAt
              )
            );
          }
        );

        return {
          success:
            true,

          referralCode:
            code,

          referralBonusPercent:
            getCurrentReferralBonusPercent(
              totalUsers
            ),

          referralBonusRate:
            getCurrentReferralBonusRate(
              totalUsers
            ),

          totalUsers,

          invitedCount:
            users.length,

          activeCount,

          inactiveCount,

          totalReferralRewards:
            nonNegative(
              userData.referralTotalEarned
            ),

          users,

          generatedAt:
            now.toISOString(),
        };
      } catch (error) {
        console.error(
          "getReferralDashboard error:",
          error
        );

        if (
          error instanceof
          HttpsError
        ) {
          throw error;
        }

        throw new HttpsError(
          "internal",
          "🐱 Stella Referral Dashboardin lataaminen epäonnistui."
        );
      }
    }
  );

// ============================================================
// EXPORTS
// ============================================================

module.exports = {
  processReferralMiningReward,

  getReferralProfile,

  applyReferralCode,

  getReferredUsers,

  getReferralStatus,

  getReferralDashboard,
};