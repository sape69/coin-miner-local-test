
"use strict";

const { onCall } = require("firebase-functions/v2/https");
const { HttpsError } = require("firebase-functions/v2/https");

const { db, FieldValue } = require("../firebase/firebase");

const REGION = "us-central1";
const MAX_GUILD_MEMBERS = 20;
const SWITCH_COOLDOWN_MS = 24 * 60 * 60 * 1000;

// ============================================================
// VALIDATION
// ============================================================

function requireAuth(request) {
  if (!request.auth || !request.auth.uid) {
    throw new HttpsError(
      "unauthenticated",
      "Kirjautuminen vaaditaan."
    );
  }

  return request.auth.uid;
}

function validateGuildId(guildId) {
  if (
    typeof guildId !== "string" ||
    guildId.trim().length === 0 ||
    guildId.length > 128
  ) {
    throw new HttpsError(
      "invalid-argument",
      "Virheellinen Guild ID."
    );
  }

  return guildId.trim();
}

function validateTargetUid(targetUid) {
  if (
    typeof targetUid !== "string" ||
    targetUid.trim().length === 0 ||
    targetUid.length > 128
  ) {
    throw new HttpsError(
      "invalid-argument",
      "Virheellinen jäsen."
    );
  }

  return targetUid.trim();
}

// ============================================================
// REFERENCES
// ============================================================

function guildRef(guildId) {
  return db.collection("guilds").doc(guildId);
}

function memberRef(guildId, uid) {
  return guildRef(guildId)
    .collection("members")
    .doc(uid);
}

function userRef(uid) {
  return db.collection("users").doc(uid);
}

// ============================================================
// LEAVE GUILD
// ============================================================

exports.leaveGuild = onCall(
  { region: REGION },
  async (request) => {
    const uid = requireAuth(request);

    return db.runTransaction(async (transaction) => {
      const userReference = userRef(uid);
      const userSnapshot = await transaction.get(userReference);

      if (!userSnapshot.exists) {
        throw new HttpsError(
          "not-found",
          "Käyttäjää ei löytynyt."
        );
      }

      const userData = userSnapshot.data();
      const guildId = userData.guildId;

      if (!guildId) {
        throw new HttpsError(
          "failed-precondition",
          "Et kuulu Guildiin."
        );
      }

      const guildReference = guildRef(guildId);
      const memberReference = memberRef(guildId, uid);

      const guildSnapshot = await transaction.get(guildReference);
      const memberSnapshot = await transaction.get(memberReference);

      if (!guildSnapshot.exists || !memberSnapshot.exists) {
        throw new HttpsError(
          "not-found",
          "Guildin jäsenyyttä ei löytynyt."
        );
      }

      const guildData = guildSnapshot.data();

      // Leader cannot leave without transferring leadership.
      if (guildData.leaderUid === uid) {
        throw new HttpsError(
          "failed-precondition",
          "Guildin johtaja ei voi poistua ennen johtajuuden siirtoa."
        );
      }

      const memberCount = Number(guildData.memberCount || 0);

      transaction.delete(memberReference);

      transaction.update(guildReference, {
        memberCount: Math.max(0, memberCount - 1),
        updatedAt: FieldValue.serverTimestamp(),
      });

      transaction.update(userReference, {
        guildId: null,
        guildRole: null,
        guildJoinedAt: null,
        guildLastSwitchAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      });

      return {
        success: true,
        message: "Poistuit Guildista.",
      };
    });
  }
);

// ============================================================
// KICK MEMBER
// ============================================================

exports.kickGuildMember = onCall(
  { region: REGION },
  async (request) => {
    const leaderUid = requireAuth(request);

    const targetUid = validateTargetUid(
      request.data?.targetUid
    );

    if (targetUid === leaderUid) {
      throw new HttpsError(
        "invalid-argument",
        "Et voi poistaa itseäsi tällä toiminnolla."
      );
    }

    return db.runTransaction(async (transaction) => {
      const leaderUserReference = userRef(leaderUid);
      const targetUserReference = userRef(targetUid);

      const leaderUserSnapshot =
        await transaction.get(leaderUserReference);

      const targetUserSnapshot =
        await transaction.get(targetUserReference);

      if (!leaderUserSnapshot.exists) {
        throw new HttpsError(
          "not-found",
          "Johtajan käyttäjää ei löytynyt."
        );
      }

      if (!targetUserSnapshot.exists) {
        throw new HttpsError(
          "not-found",
          "Kohdekäyttäjää ei löytynyt."
        );
      }

      const leaderUserData = leaderUserSnapshot.data();
      const targetUserData = targetUserSnapshot.data();

      const guildId = leaderUserData.guildId;

      if (!guildId) {
        throw new HttpsError(
          "failed-precondition",
          "Et kuulu Guildiin."
        );
      }

      if (targetUserData.guildId !== guildId) {
        throw new HttpsError(
          "failed-precondition",
          "Käyttäjä ei kuulu samaan Guildiin."
        );
      }

      const guildReference = guildRef(guildId);
      const leaderMemberReference = memberRef(
        guildId,
        leaderUid
      );
      const targetMemberReference = memberRef(
        guildId,
        targetUid
      );

      const guildSnapshot = await transaction.get(guildReference);
      const leaderMemberSnapshot =
        await transaction.get(leaderMemberReference);
      const targetMemberSnapshot =
        await transaction.get(targetMemberReference);

      if (
        !guildSnapshot.exists ||
        !leaderMemberSnapshot.exists ||
        !targetMemberSnapshot.exists
      ) {
        throw new HttpsError(
          "not-found",
          "Guildin jäsen tietoja ei löytynyt."
        );
      }

      const guildData = guildSnapshot.data();
      const leaderMemberData = leaderMemberSnapshot.data();

      if (guildData.leaderUid !== leaderUid) {
        throw new HttpsError(
          "permission-denied",
          "Vain Guildin johtaja voi poistaa jäseniä."
        );
      }

      if (leaderMemberData.role !== "leader") {
        throw new HttpsError(
          "permission-denied",
          "Johtajan jäsenrooli ei ole kelvollinen."
        );
      }

      if (targetUserData.guildRole === "leader") {
        throw new HttpsError(
          "failed-precondition",
          "Guildin johtajaa ei voi poistaa."
        );
      }

      const memberCount = Number(
        guildData.memberCount || 0
      );

      transaction.delete(targetMemberReference);

      transaction.update(guildReference, {
        memberCount: Math.max(0, memberCount - 1),
        updatedAt: FieldValue.serverTimestamp(),
      });

      transaction.update(targetUserReference, {
        guildId: null,
        guildRole: null,
        guildJoinedAt: null,
        guildLastSwitchAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      });

      return {
        success: true,
        message: "Jäsen poistettiin Guildista.",
      };
    });
  }
);

// ============================================================
// TRANSFER GUILD LEADERSHIP
// ============================================================

exports.transferGuildLeadership = onCall(
  { region: REGION },
  async (request) => {
    const currentLeaderUid = requireAuth(request);

    const targetUid = validateTargetUid(
      request.data?.targetUid
    );

    if (targetUid === currentLeaderUid) {
      throw new HttpsError(
        "invalid-argument",
        "Johtajuutta ei voi siirtää itselleen."
      );
    }

    return db.runTransaction(async (transaction) => {
      const currentLeaderUserReference =
        userRef(currentLeaderUid);

      const targetUserReference = userRef(targetUid);

      const currentLeaderUserSnapshot =
        await transaction.get(currentLeaderUserReference);

      const targetUserSnapshot =
        await transaction.get(targetUserReference);

      if (
        !currentLeaderUserSnapshot.exists ||
        !targetUserSnapshot.exists
      ) {
        throw new HttpsError(
          "not-found",
          "Käyttäjää ei löytynyt."
        );
      }

      const currentLeaderUserData =
        currentLeaderUserSnapshot.data();

      const targetUserData = targetUserSnapshot.data();

      const guildId = currentLeaderUserData.guildId;

      if (!guildId) {
        throw new HttpsError(
          "failed-precondition",
          "Et kuulu Guildiin."
        );
      }

      if (targetUserData.guildId !== guildId) {
        throw new HttpsError(
          "failed-precondition",
          "Uuden johtajan täytyy olla saman Guildin jäsen."
        );
      }

      const guildReference = guildRef(guildId);

      const currentLeaderMemberReference =
        memberRef(guildId, currentLeaderUid);

      const targetMemberReference =
        memberRef(guildId, targetUid);

      const guildSnapshot = await transaction.get(guildReference);

      const currentLeaderMemberSnapshot =
        await transaction.get(
          currentLeaderMemberReference
        );

      const targetMemberSnapshot =
        await transaction.get(targetMemberReference);

      if (
        !guildSnapshot.exists ||
        !currentLeaderMemberSnapshot.exists ||
        !targetMemberSnapshot.exists
      ) {
        throw new HttpsError(
          "not-found",
          "Guildin jäsen tietoja ei löytynyt."
        );
      }

      const guildData = guildSnapshot.data();

      if (guildData.leaderUid !== currentLeaderUid) {
        throw new HttpsError(
          "permission-denied",
          "Vain nykyinen johtaja voi siirtää johtajuuden."
        );
      }

      const currentLeaderMemberData =
        currentLeaderMemberSnapshot.data();

      if (currentLeaderMemberData.role !== "leader") {
        throw new HttpsError(
          "permission-denied",
          "Nykyisen johtajan rooli ei ole kelvollinen."
        );
      }

      // Promote the new leader.
      transaction.update(targetMemberReference, {
        role: "leader",
        updatedAt: FieldValue.serverTimestamp(),
      });

      // The old leader remains in the Guild as a regular member.
      transaction.update(currentLeaderMemberReference, {
        role: "member",
        updatedAt: FieldValue.serverTimestamp(),
      });

      transaction.update(guildReference, {
        leaderUid: targetUid,
        updatedAt: FieldValue.serverTimestamp(),
      });

      transaction.update(currentLeaderUserReference, {
        guildRole: "member",
        updatedAt: FieldValue.serverTimestamp(),
      });

      transaction.update(targetUserReference, {
        guildRole: "leader",
        updatedAt: FieldValue.serverTimestamp(),
      });

      return {
        success: true,
        message: "Guildin johtajuus siirrettiin onnistuneesti.",
      };
    });
  }
);
