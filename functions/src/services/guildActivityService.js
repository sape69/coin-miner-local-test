
"use strict";

// ============================================================
// 🐱 STELLURIINI - GUILD ACTIVITY SERVICE
// ============================================================
//
// Features:
// - Server-verified mining activity
// - Active miner detection (30 minutes)
// - Guild mining bonus calculation
// - Transaction-safe membership validation
//
// Rules:
// - Activity must be recorded by trusted backend code
// - Never expose recordGuildMiningActivity directly to clients
// - Guild bonus increases mining power
// - Guild bonus does NOT award direct STL
//
// ============================================================


// ============================================================
// 🔥 FIREBASE
// ============================================================

const {
  db,
  FieldValue,
} = require("../firebase/firebase");


// ============================================================
// ⚙️ GUILD CONFIG
// ============================================================

const {
  GUILD_ACTIVE_WINDOW_MS,
  GUILD_BONUS_TIERS,
} = require("../config/guildConfig");


// ============================================================
// REFERENCES
// ============================================================

function getUserRef(uid) {
  return db
    .collection("users")
    .doc(uid);
}


function getGuildRef(guildId) {
  return db
    .collection("guilds")
    .doc(guildId);
}


function getGuildMemberRef(
  guildId,
  uid,
) {
  return getGuildRef(guildId)
    .collection("members")
    .doc(uid);
}


// ============================================================
// RECORD VERIFIED MINING ACTIVITY
// ============================================================
//
// IMPORTANT:
//
// Call ONLY from trusted server-side mining functions,
// after mining activity has been successfully verified.
//
// Never expose this function directly as a callable
// client function.
//
// ============================================================

async function recordGuildMiningActivity(uid) {
  if (
    typeof uid !== "string" ||
    !uid.trim() ||
    uid.length > 128
  ) {
    return {
      success: false,
      reason: "invalid_uid",
    };
  }

  const cleanUid =
    uid.trim();

  const userRef =
    getUserRef(cleanUid);

  // ----------------------------------------------------------
  // TRANSACTION
  // ----------------------------------------------------------

  return db.runTransaction(
    async (transaction) => {
      // --------------------------------------------------------
      // READ USER
      // --------------------------------------------------------

      const userSnapshot =
        await transaction.get(
          userRef,
        );

      if (
        !userSnapshot.exists
      ) {
        return {
          success: false,
          reason: "user_not_found",
        };
      }

      const userData =
        userSnapshot.data() || {};

      const guildId =
        userData.guildId;

      if (
        typeof guildId !== "string" ||
        !guildId.trim()
      ) {
        return {
          success: false,
          reason: "not_in_guild",
        };
      }

      // --------------------------------------------------------
      // REFERENCES
      // --------------------------------------------------------

      const guildRef =
        getGuildRef(guildId);

      const memberRef =
        getGuildMemberRef(
          guildId,
          cleanUid,
        );

      // --------------------------------------------------------
      // READ GUILD
      // --------------------------------------------------------

      const guildSnapshot =
        await transaction.get(
          guildRef,
        );

      // --------------------------------------------------------
      // READ MEMBER
      // --------------------------------------------------------

      const memberSnapshot =
        await transaction.get(
          memberRef,
        );

      // --------------------------------------------------------
      // VALIDATE GUILD
      // --------------------------------------------------------

      if (
        !guildSnapshot.exists
      ) {
        return {
          success: false,
          reason: "guild_not_found",
        };
      }

      // --------------------------------------------------------
      // VALIDATE MEMBERSHIP
      // --------------------------------------------------------

      if (
        !memberSnapshot.exists
      ) {
        return {
          success: false,
          reason: "guild_membership_not_found",
        };
      }

      // --------------------------------------------------------
      // UPDATE VERIFIED ACTIVITY
      // --------------------------------------------------------

      transaction.update(
        memberRef,
        {
          lastActiveAt:
            FieldValue.serverTimestamp(),

          updatedAt:
            FieldValue.serverTimestamp(),
        },
      );

      // --------------------------------------------------------
      // RESULT
      // --------------------------------------------------------

      return {
        success: true,
        guildId,
      };
    },
  );
}


// ============================================================
// GET GUILD ACTIVITY
// ============================================================
//
// Counts Guild members whose verified mining activity
// occurred within the configured active window.
//
// Read-only.
//
// ============================================================

async function getGuildActivity(guildId) {
  if (
    typeof guildId !== "string" ||
    !guildId.trim() ||
    guildId.length > 128
  ) {
    throw new Error(
      "Invalid guildId",
    );
  }

  const cleanGuildId =
    guildId.trim();

  const guildRef =
    getGuildRef(
      cleanGuildId,
    );

  // ----------------------------------------------------------
  // READ GUILD
  // ----------------------------------------------------------

  const guildSnapshot =
    await guildRef.get();

  if (
    !guildSnapshot.exists
  ) {
    return {
      success: false,
      reason: "guild_not_found",
      activeMembers: 0,
      totalMembers: 0,
      bonusPercent: 0,
    };
  }

  // ----------------------------------------------------------
  // READ MEMBERS
  // ----------------------------------------------------------

  const membersSnapshot =
    await guildRef
      .collection("members")
      .get();

  const now =
    Date.now();

  const activeThreshold =
    now - GUILD_ACTIVE_WINDOW_MS;

  let activeMembers = 0;

  let totalMembers = 0;

  // ----------------------------------------------------------
  // COUNT ACTIVE MEMBERS
  // ----------------------------------------------------------

  membersSnapshot.forEach(
    (memberDocument) => {
      totalMembers++;

      const memberData =
        memberDocument.data() || {};

      const lastActiveAt =
        memberData.lastActiveAt;

      if (
        lastActiveAt &&
        typeof lastActiveAt.toMillis === "function" &&
        lastActiveAt.toMillis() >=
          activeThreshold
      ) {
        activeMembers++;
      }
    },
  );

  // ----------------------------------------------------------
  // CALCULATE BONUS
  // ----------------------------------------------------------

  const bonusPercent =
    calculateGuildBonus(
      activeMembers,
    );

  // ----------------------------------------------------------
  // RESULT
  // ----------------------------------------------------------

  return {
    success: true,

    guildId:
      cleanGuildId,

    activeMembers,

    totalMembers,

    bonusPercent,

    checkedAt:
      new Date(now).toISOString(),
  };
}


// ============================================================
// GUILD BONUS CALCULATION
// ============================================================

function calculateGuildBonus(
  activeMembers,
) {
  const count =
    Math.max(
      0,
      Math.floor(
        Number(activeMembers) || 0,
      ),
    );

  let bonusPercent = 0;

  for (
    const tier of GUILD_BONUS_TIERS
  ) {
    if (
      count >= tier.minActiveMembers
    ) {
      bonusPercent =
        tier.bonusPercent;
    }
  }

  return bonusPercent;
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
