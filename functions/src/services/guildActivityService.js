
"use strict";

const { db, FieldValue } = require("../firebase/firebase");

const GUILD_ACTIVE_WINDOW_MS = 30 * 60 * 1000;

// ============================================================
// REFERENCES
// ============================================================

function getUserRef(uid) {
  return db.collection("users").doc(uid);
}

function getGuildRef(guildId) {
  return db.collection("guilds").doc(guildId);
}

function getGuildMemberRef(guildId, uid) {
  return getGuildRef(guildId)
    .collection("members")
    .doc(uid);
}

// ============================================================
// RECORD VERIFIED MINING ACTIVITY
// ============================================================
//
// IMPORTANT:
// Call this helper ONLY from trusted server-side mining
// functions after mining activity has been successfully verified.
//
// Do not expose this helper as a client-callable function.
// ============================================================

async function recordGuildMiningActivity(uid) {
  if (typeof uid !== "string" || !uid.trim()) {
    return {
      success: false,
      reason: "invalid_uid",
    };
  }

  const userSnapshot = await getUserRef(uid).get();

  if (!userSnapshot.exists) {
    return {
      success: false,
      reason: "user_not_found",
    };
  }

  const userData = userSnapshot.data();
  const guildId = userData.guildId;

  if (!guildId) {
    return {
      success: false,
      reason: "not_in_guild",
    };
  }

  const memberRef = getGuildMemberRef(guildId, uid);

  return db.runTransaction(async (transaction) => {
    const memberSnapshot = await transaction.get(memberRef);

    if (!memberSnapshot.exists) {
      return {
        success: false,
        reason: "guild_membership_not_found",
      };
    }

    transaction.update(memberRef, {
      lastActiveAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });

    return {
      success: true,
      guildId,
    };
  });
}

// ============================================================
// GET GUILD ACTIVITY
// ============================================================
//
// Counts members whose last verified mining activity was
// within the last 30 minutes.
//
// This function is read-only.
// ============================================================

async function getGuildActivity(guildId) {
  if (
    typeof guildId !== "string" ||
    !guildId.trim()
  ) {
    throw new Error("Invalid guildId");
  }

  const guildSnapshot = await getGuildRef(guildId).get();

  if (!guildSnapshot.exists) {
    return {
      success: false,
      reason: "guild_not_found",
      activeMembers: 0,
      totalMembers: 0,
      bonusPercent: 0,
    };
  }

  const membersSnapshot = await getGuildRef(guildId)
    .collection("members")
    .get();

  const now = Date.now();
  const activeThreshold = now - GUILD_ACTIVE_WINDOW_MS;

  let activeMembers = 0;
  let totalMembers = 0;

  membersSnapshot.forEach((memberDocument) => {
    totalMembers++;

    const memberData = memberDocument.data();
    const lastActiveAt = memberData.lastActiveAt;

    if (
      lastActiveAt &&
      typeof lastActiveAt.toMillis === "function" &&
      lastActiveAt.toMillis() >= activeThreshold
    ) {
      activeMembers++;
    }
  });

  const bonusPercent = calculateGuildBonus(activeMembers);

  return {
    success: true,
    guildId,
    activeMembers,
    totalMembers,
    bonusPercent,
    checkedAt: new Date(now).toISOString(),
  };
}

// ============================================================
// GUILD BONUS TIERS
// ============================================================

function calculateGuildBonus(activeMembers) {
  if (activeMembers <= 1) return 0;
  if (activeMembers === 2) return 5;
  if (activeMembers <= 4) return 8;
  if (activeMembers <= 7) return 12;
  return 15;
}

// ============================================================
// EXPORTS
// ============================================================

module.exports = {
  recordGuildMiningActivity,
  getGuildActivity,
  calculateGuildBonus,
  GUILD_ACTIVE_WINDOW_MS,
};
