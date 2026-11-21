
"use strict";

// ============================================================
// 🐱 STELLURIINI - GUILDS CONFIG
// ============================================================
//
// Guilds / Teams / Clans.
//
// Server-side configuration for:
// - Guild membership limits
// - Active mining member detection
// - Guild mining bonus tiers
// - Invite codes
// - Guild switching cooldown
//
// Guild bonuses increase mining power.
// They do NOT award direct STL tokens.
//
// ============================================================


// ============================================================
// 👥 GUILD MEMBERS
// ============================================================

const GUILD_MAX_MEMBERS = 20;

const GUILD_MIN_MEMBERS = 1;


// ============================================================
// 👑 GUILD LEADERSHIP
// ============================================================

const GUILD_LEADER_ROLE = "leader";

const GUILD_MEMBER_ROLE = "member";


// ============================================================
// ⚡ ACTIVE MEMBER DETECTION
// ============================================================

// User mining activity must have been verified by the server
// within the last 30 minutes.

const GUILD_ACTIVE_WINDOW_MS =
  30 * 60 * 1000;


// ============================================================
// ⚡ GUILD MINING BONUS TIERS
// ============================================================
//
// Bonus is based on the number of verified active miners.
//
// 1 active member  = 0%
// 2 active members = 5%
// 3-4 active      = 8%
// 5-7 active      = 12%
// 8-20 active     = 15%
//
// ============================================================

const GUILD_BONUS_TIERS = [
  {
    minActiveMembers: 1,
    bonusPercent: 0,
  },
  {
    minActiveMembers: 2,
    bonusPercent: 5,
  },
  {
    minActiveMembers: 3,
    bonusPercent: 8,
  },
  {
    minActiveMembers: 5,
    bonusPercent: 12,
  },
  {
    minActiveMembers: 8,
    bonusPercent: 15,
  },
];


// ============================================================
// 🎟️ INVITE CODE
// ============================================================

const GUILD_INVITE_CODE_LENGTH = 8;

const GUILD_INVITE_CODE_CHARACTERS =
  "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";


// ============================================================
// 🔄 GUILD SWITCHING
// ============================================================

// Switching guilds has a 24-hour cooldown.

const GUILD_SWITCH_COOLDOWN_MS =
  24 * 60 * 60 * 1000;


// ============================================================
// 🛡️ SECURITY LIMITS
// ============================================================

// Prevent unlimited guild creation by the same user.

const GUILD_CREATION_COOLDOWN_MS =
  24 * 60 * 60 * 1000;


// ============================================================
// 📦 EXPORTS
// ============================================================

module.exports = {
  GUILD_MAX_MEMBERS,
  GUILD_MIN_MEMBERS,

  GUILD_LEADER_ROLE,
  GUILD_MEMBER_ROLE,

  GUILD_ACTIVE_WINDOW_MS,

  GUILD_BONUS_TIERS,

  GUILD_INVITE_CODE_LENGTH,
  GUILD_INVITE_CODE_CHARACTERS,

  GUILD_SWITCH_COOLDOWN_MS,
  GUILD_CREATION_COOLDOWN_MS,
};
