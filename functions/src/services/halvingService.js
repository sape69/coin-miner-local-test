
"use strict";

// ============================================================
// 🐱 STELLURIINI - HALVING SERVICE
// ============================================================
//
// Halving perustuu kaikkiin rekisteröityneisiin käyttäjiin.
//
// Firestore:
// users/{uid}
//
// Mukaan lasketaan:
// - Aktiiviset käyttäjät
// - Ei-aktiiviset käyttäjät
//
// Poistetut käyttäjätilit eivät kuulu laskentaan.
//
// Tämä palvelu ei muuta käyttäjien saldoja eikä louhintajaksoja.
// ============================================================

const {
  db,
} = require("../firebase/firebase");

const {
  HALVING_ENABLED,
  HALVING_MILESTONES,
  MINING_PER_HASH_PER_HOUR,
} = require("../config/miningConfig");


// ============================================================
// 🔢 SAFE NUMBER
// ============================================================

function safeNumber(value, fallback = 0) {
  const result = Number(value);

  return Number.isFinite(result)
    ? result
    : fallback;
}


// ============================================================
// 📊 GET HALVING LEVEL
// ============================================================

function getHalvingLevel(registeredUserCount) {
  const userCount = Math.max(
    0,
    Math.floor(
      safeNumber(registeredUserCount),
    ),
  );

  const milestones = Array.isArray(
    HALVING_MILESTONES,
  )
    ? [...HALVING_MILESTONES]
        .filter((item) => {
          return (
            item &&
            Number.isFinite(Number(item.users)) &&
            Number.isFinite(Number(item.multiplier)) &&
            Number(item.users) >= 0 &&
            Number(item.multiplier) > 0
          );
        })
        .sort(
          (a, b) =>
            Number(a.users) - Number(b.users),
        )
    : [];

  if (milestones.length === 0) {
    throw new Error(
      "Halving milestones are missing or invalid.",
    );
  }

  let current = milestones[0];
  let next = null;

  for (const milestone of milestones) {
    if (userCount >= Number(milestone.users)) {
      current = milestone;
    } else {
      next = milestone;
      break;
    }
  }

  return {
    registeredUserCount: userCount,

    halvingEnabled:
      HALVING_ENABLED === true,

    level: milestones.indexOf(current),

    currentMilestone: {
      users: Number(current.users),
      multiplier: Number(current.multiplier),
      label: String(current.label || ""),
    },

    nextMilestone: next
      ? {
          users: Number(next.users),
          multiplier: Number(next.multiplier),
          label: String(next.label || ""),
          usersRemaining: Math.max(
            0,
            Number(next.users) - userCount,
          ),
        }
      : null,

    multiplier:
      HALVING_ENABLED === true
        ? Number(current.multiplier)
        : 1,

    miningPerHashPerHour:
      safeNumber(MINING_PER_HASH_PER_HOUR),

    effectiveMiningPerHashPerHour:
      safeNumber(MINING_PER_HASH_PER_HOUR) *
      (
        HALVING_ENABLED === true
          ? Number(current.multiplier)
          : 1
      ),
  };
}


// ============================================================
// 👥 COUNT REGISTERED USERS
// ============================================================
//
// Firestore users-kokoelman dokumentit ovat käyttäjätilejä.
//
// Käytetään count()-aggregaatiota:
// - Ei ladata kaikkia käyttäjädokumentteja.
// - Ei lueta käyttäjien henkilökohtaisia tietoja.
// - Palautetaan vain dokumenttien lukumäärä.
//
// ============================================================

async function getRegisteredUserCount() {
  const snapshot = await db
    .collection("users")
    .count()
    .get();

  const count = Number(
    snapshot.data().count,
  );

  if (
    !Number.isFinite(count) ||
    count < 0
  ) {
    throw new Error(
      "Unable to determine registered user count.",
    );
  }

  return Math.floor(count);
}


// ============================================================
// 📉 GET CURRENT HALVING STATUS
// ============================================================

async function getHalvingStatus() {
  const registeredUserCount =
    await getRegisteredUserCount();

  return getHalvingLevel(
    registeredUserCount,
  );
}


// ============================================================
// 📦 EXPORTS
// ============================================================

module.exports = {
  getRegisteredUserCount,
  getHalvingLevel,
  getHalvingStatus,
};
