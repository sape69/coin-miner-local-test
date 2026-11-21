
"use strict";

// ============================================================
// 🐱 STELLURIINI - GUILD SERVICE
// ============================================================
//
// Guilds / Teams / Clans.
//
// Firestore data layer for Guilds.
//
// Responsibilities:
// - Guild references
// - Member references
// - Invite code references
// - User Guild references
//
// This file does NOT modify mining calculations.
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
// 🛡️ VALIDATION
// ============================================================

function validateUid(uid) {
  if (
    typeof uid !== "string"
  ) {
    throw new Error("Guild UID must be a string.");
  }

  const value = uid.trim();

  if (
    value.length === 0 ||
    value.length > 128 ||
    !/^[A-Za-z0-9._-]+$/.test(value)
  ) {
    throw new Error("Guild UID is invalid.");
  }

  return value;
}


function validateGuildId(guildId) {
  if (
    typeof guildId !== "string"
  ) {
    throw new Error("Guild ID must be a string.");
  }

  const value = guildId.trim();

  if (
    value.length === 0 ||
    value.length > 128 ||
    !/^[A-Za-z0-9._-]+$/.test(value)
  ) {
    throw new Error("Guild ID is invalid.");
  }

  return value;
}


function validateInviteCode(inviteCode) {
  if (
    typeof inviteCode !== "string"
  ) {
    throw new Error("Invite code must be a string.");
  }

  const value =
    inviteCode.trim().toUpperCase();

  if (
    value.length === 0 ||
    value.length > 32 ||
    !/^[A-Z0-9]+$/.test(value)
  ) {
    throw new Error("Invite code is invalid.");
  }

  return value;
}


// ============================================================
// 📦 COLLECTION REFERENCES
// ============================================================

function getGuildsCollection() {
  return db.collection("guilds");
}


function getGuildRef(guildId) {
  return getGuildsCollection().doc(
    validateGuildId(guildId),
  );
}


function getGuildMembersCollection(guildId) {
  return getGuildRef(guildId).collection(
    "members",
  );
}


function getGuildMemberRef(guildId, uid) {
  return getGuildMembersCollection(
    guildId,
  ).doc(
    validateUid(uid),
  );
}


function getGuildInviteRef(inviteCode) {
  return db.collection(
    "guildInvites",
  ).doc(
    validateInviteCode(inviteCode),
  );
}


function getUserRef(uid) {
  return db.collection(
    "users",
  ).doc(
    validateUid(uid),
  );
}


// ============================================================
// 📦 GUILD DATA HELPERS
// ============================================================

function createGuildData({
  name,
  leaderUid,
  inviteCode,
}) {
  if (
    typeof name !== "string"
  ) {
    throw new Error("Guild name must be a string.");
  }

  const cleanName =
    name.trim();

  if (
    cleanName.length < 3 ||
    cleanName.length > 24
  ) {
    throw new Error(
      "Guild name must be between 3 and 24 characters.",
    );
  }

  return {
    name: cleanName,

    leaderUid:
      validateUid(leaderUid),

    inviteCode:
      validateInviteCode(inviteCode),

    memberCount:
      1,

    createdAt:
      FieldValue.serverTimestamp(),

    updatedAt:
      FieldValue.serverTimestamp(),
  };
}


// ============================================================
// 👤 MEMBER DATA
// ============================================================

function createGuildMemberData({
  uid,
  role = "member",
}) {
  return {
    uid:
      validateUid(uid),

    role,

    joinedAt:
      FieldValue.serverTimestamp(),

    lastActiveAt:
      null,
  };
}


// ============================================================
// 🎟️ INVITE DATA
// ============================================================

function createGuildInviteData({
  guildId,
}) {
  return {
    guildId:
      validateGuildId(guildId),

    createdAt:
      FieldValue.serverTimestamp(),

    active:
      true,
  };
}


// ============================================================
// 📦 EXPORTS
// ============================================================

module.exports = {
  validateUid,
  validateGuildId,
  validateInviteCode,

  getGuildsCollection,
  getGuildRef,
  getGuildMembersCollection,
  getGuildMemberRef,
  getGuildInviteRef,
  getUserRef,

  createGuildData,
  createGuildMemberData,
  createGuildInviteData,
};
