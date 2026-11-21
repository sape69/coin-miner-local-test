
"use strict";

// ============================================================
// 🐱 STELLURIINI - GUILD ACTIVITY SERVICE
// ============================================================
//
// Features:
// - Server-verified mining activity
// - Active miner detection (30 minutes)
// - Guild mining bonus calculation
// - Transaction-safe Guild bonus snapshot
// - Transaction-safe membership validation
//
// Rules:
// - Activity must be recorded by trusted backend code
// - Never expose recordGuildMiningActivity directly to clients
// - Guild bonus increases mining power
// - Guild bonus does NOT award direct STL
// - Guild bonus snapshot is calculated server-side
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
// TIMESTAMP HELPER
// ============================================================

function timestampToMillis(timestamp) {
  if (!timestamp) {
    return null;
  }

  if (
    typeof timestamp.toMillis === "function"
  ) {
    return timestamp.toMillis();
  }

  if (
    timestamp instanceof Date
  ) {
    return timestamp.getTime();
  }

  return null;
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

      const cleanGuildId =
        guildId.trim();

      // --------------------------------------------------------
      // REFERENCES
      // --------------------------------------------------------

      const guildRef =
        getGuildRef(
          cleanGuildId,
        );

      const memberRef =
        getGuildMemberRef(
          cleanGuildId,
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
        guildId: cleanGuildId,
      };
    },
  );
}


// ============================================================
// TRANSACTION-SAFE GUILD MINING BONUS SNAPSHOT
// ============================================================
//
// This function is intended to be called from an existing
// Firestore transaction.
//
// IMPORTANT:
// - userSnapshot must be read from the same transaction.
// - All reads must happen before transaction writes.
// - This function does not write any documents.
// - The mining starter is counted as active when its verified
//   mining start is being processed.
// - The bonus is returned as a snapshot for the new cycle.
//
// ============================================================

async function getGuildMiningBonusSnapshot(
  transaction,
  userSnapshot,
  nowMs = Date.now(),
  activeUid = null,
) {
  // ----------------------------------------------------------
  // VALIDATE INPUT
  // ----------------------------------------------------------

  if (
    !transaction ||
    typeof transaction.get !== "function"
  ) {
    return {
      success: false,
      reason: "invalid_transaction",
      guildId: null,
      activeMembers: 0,
      totalMembers: 0,
      bonusPercent: 0,
    };
  }

  if (
    !userSnapshot ||
    !userSnapshot.exists
  ) {
    return {
      success: false,
      reason: "user_not_found",
      guildId: null,
      activeMembers: 0,
      totalMembers: 0,
      bonusPercent: 0,
    };
  }

  const safeNowMs =
    Number.isFinite(nowMs)
      ? nowMs
      : Date.now();

  const userData =
    userSnapshot.data() || {};

  const guildId =
    userData.guildId;

  // ----------------------------------------------------------
  // USER NOT IN GUILD
  // ----------------------------------------------------------

  if (
    typeof guildId !== "string" ||
    !guildId.trim()
  ) {
    return {
      success: true,
      inGuild: false,
      guildId: null,
      activeMembers: 0,
      totalMembers: 0,
      bonusPercent: 0,
      checkedAt:
        new Date(safeNowMs).toISOString(),
    };
  }

  const cleanGuildId =
    guildId.trim();

  // ----------------------------------------------------------
  // REFERENCES
  // ----------------------------------------------------------

  const guildRef =
    getGuildRef(
      cleanGuildId,
    );

  const membersRef =
    guildRef.collection("members");

  // ----------------------------------------------------------
  // TRANSACTION READS
  // ----------------------------------------------------------
  //
  // All reads are performed before any writes by the caller.
  //
  // ----------------------------------------------------------

  const guildSnapshot =
    await transaction.get(
      guildRef,
    );

  const membersSnapshot =
    await transaction.get(
      membersRef,
    );

  // ----------------------------------------------------------
  // VALIDATE GUILD
  // ----------------------------------------------------------

  if (
    !guildSnapshot.exists
  ) {
    return {
      success: false,
      inGuild: true,
      reason: "guild_not_found",
      guildId: cleanGuildId,
      activeMembers: 0,
      totalMembers: 0,
      bonusPercent: 0,
    };
  }

  // ----------------------------------------------------------
  // COUNT ACTIVE MEMBERS
  // ----------------------------------------------------------

  const activeThreshold =
    safeNowMs -
    GUILD_ACTIVE_WINDOW_MS;

  let activeMembers = 0;

  let totalMembers = 0;

  let currentUserIsMember = false;

  membersSnapshot.forEach(
    (memberDocument) => {
      totalMembers++;

      const memberUid =
        memberDocument.id;

      const memberData =
        memberDocument.data() || {};

      const lastActiveAt =
        memberData.lastActiveAt;

      const lastActiveMs =
        timestampToMillis(
          lastActiveAt,
        );

      const isCurrentUser =
        typeof activeUid === "string" &&
        activeUid.trim() === memberUid;

      if (isCurrentUser) {
        currentUserIsMember = true;
      }

      // --------------------------------------------------------
      // VERIFIED ACTIVE MEMBER
      // --------------------------------------------------------

      const isRecentlyActive =
        lastActiveMs !== null &&
        lastActiveMs >=
          activeThreshold;

      // --------------------------------------------------------
      // COUNT MEMBER
      // --------------------------------------------------------

      if (
        isRecentlyActive ||
        isCurrentUser
      ) {
        activeMembers++;
      }
    },
  );

  // ----------------------------------------------------------
  // VALIDATE CURRENT USER MEMBERSHIP
  // ----------------------------------------------------------

  if (
    typeof activeUid === "string" &&
    activeUid.trim() &&
    !currentUserIsMember
  ) {
    return {
      success: false,
      inGuild: true,
      reason: "guild_membership_not_found",
      guildId: cleanGuildId,
      activeMembers: 0,
      totalMembers,
      bonusPercent: 0,
    };
  }

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
    inGuild: true,

    guildId:
      cleanGuildId,

    activeMembers,

    totalMembers,

    bonusPercent,

    checkedAt:
      new Date(safeNowMs).toISOString(),
  };
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

      const lastActiveMs =
        timestampToMillis(
          lastActiveAt,
        );

      if (
        lastActiveMs !== null &&
        lastActiveMs >=
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
  getGuildMiningBonusSnapshot,
  calculateGuildBonus,
  GUILD_ACTIVE_WINDOW_MS,
};
