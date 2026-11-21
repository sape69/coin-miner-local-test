"use strict";

// ============================================================
// 🐱 STELLURIINI - GUILD MEMBER FUNCTIONS
// ============================================================
//
// Functions:
// - leaveGuild
// - kickGuildMember
// - transferGuildLeadership
//
// Rules:
// - Maximum 20 members
// - Leader cannot leave without transferring leadership
// - Only leader can kick members
// - Only leader can transfer leadership
// - Kicked / leaving members receive 24h Guild switch cooldown
// - All operations use Firestore transactions
//
// ============================================================


// ============================================================
// 🔥 FIREBASE
// ============================================================

const {
  onCall,
  HttpsError,
} = require("firebase-functions/v2/https");

const {
  db,
  FieldValue,
} = require("../firebase/firebase");


// ============================================================
// ⚙️ GUILD CONFIG
// ============================================================

const {
  GUILD_MAX_MEMBERS,
  GUILD_LEADER_ROLE,
  GUILD_MEMBER_ROLE,
  GUILD_SWITCH_COOLDOWN_MS,
} = require("../config/guildConfig");


// ============================================================
// 🛡️ AUTHENTICATION
// ============================================================

function requireAuth(request) {
  if (
    !request.auth ||
    !request.auth.uid
  ) {
    throw new HttpsError(
      "unauthenticated",
      "Kirjautuminen vaaditaan.",
    );
  }

  return request.auth.uid;
}


// ============================================================
// 🔍 UID VALIDATION
// ============================================================

function validateUid(uid) {
  if (
    typeof uid !== "string" ||
    !uid.trim() ||
    uid.length > 128 ||
    !/^[A-Za-z0-9._-]+$/.test(uid)
  ) {
    throw new HttpsError(
      "invalid-argument",
      "Virheellinen käyttäjätunniste.",
    );
  }

  return uid.trim();
}


// ============================================================
// 🔍 GUILD ID VALIDATION
// ============================================================

function validateGuildId(guildId) {
  if (
    typeof guildId !== "string" ||
    !guildId.trim() ||
    guildId.length > 128
  ) {
    throw new HttpsError(
      "invalid-argument",
      "Virheellinen Guild ID.",
    );
  }

  return guildId.trim();
}


// ============================================================
// REFERENCES
// ============================================================

function guildRef(guildId) {
  return db
    .collection("guilds")
    .doc(
      validateGuildId(guildId),
    );
}


function memberRef(guildId, uid) {
  return guildRef(guildId)
    .collection("members")
    .doc(
      validateUid(uid),
    );
}


function userRef(uid) {
  return db
    .collection("users")
    .doc(
      validateUid(uid),
    );
}


// ============================================================
// ⏰ TIMESTAMP HELPER
// ============================================================

function timestampToMs(value) {
  if (!value) {
    return 0;
  }

  if (
    typeof value.toMillis === "function"
  ) {
    return value.toMillis();
  }

  if (
    value instanceof Date
  ) {
    return value.getTime();
  }

  if (
    typeof value === "number" &&
    Number.isFinite(value)
  ) {
    return value;
  }

  return 0;
}


// ============================================================
// ⏳ GUILD SWITCH COOLDOWN
// ============================================================

function getSwitchCooldownRemaining(
  lastSwitchAt,
) {
  const lastSwitchMs =
    timestampToMs(lastSwitchAt);

  if (
    lastSwitchMs <= 0
  ) {
    return 0;
  }

  const elapsed =
    Date.now() - lastSwitchMs;

  if (
    elapsed >=
    GUILD_SWITCH_COOLDOWN_MS
  ) {
    return 0;
  }

  return (
    GUILD_SWITCH_COOLDOWN_MS -
    elapsed
  );
}


// ============================================================
// 🔢 MEMBER COUNT VALIDATION
// ============================================================

function getValidMemberCount(
  guildData,
) {
  const count =
    Number(guildData.memberCount);

  if (
    !Number.isFinite(count) ||
    count < 0
  ) {
    throw new HttpsError(
      "failed-precondition",
      "Guildin jäsenmäärä on virheellinen.",
    );
  }

  return Math.floor(count);
}


// ============================================================
// ⏳ COOLDOWN ERROR
// ============================================================

function throwCooldownError(
  remainingMs,
) {
  const remainingHours =
    Math.ceil(
      remainingMs / 3600000,
    );

  throw new HttpsError(
    "failed-precondition",
    `Guildin vaihtaminen ei ole vielä mahdollista. Odota ${remainingHours} tuntia.`,
  );
}


// ============================================================
// 🚪 LEAVE GUILD
// ============================================================

const leaveGuild = onCall(
  {
    region: "us-central1",
  },
  async (request) => {
    const uid =
      requireAuth(request);

    return db.runTransaction(
      async (transaction) => {
        // ----------------------------------------------------
        // READ USER
        // ----------------------------------------------------

        const userReference =
          userRef(uid);

        const userSnapshot =
          await transaction.get(
            userReference,
          );

        if (
          !userSnapshot.exists
        ) {
          throw new HttpsError(
            "not-found",
            "Käyttäjää ei löytynyt.",
          );
        }

        const userData =
          userSnapshot.data() || {};

        const guildId =
          userData.guildId;

        if (
          typeof guildId !== "string" ||
          !guildId.trim()
        ) {
          throw new HttpsError(
            "failed-precondition",
            "Et kuulu Guildiin.",
          );
        }

        // ----------------------------------------------------
        // REFERENCES
        // ----------------------------------------------------

        const guildReference =
          guildRef(guildId);

        const memberReference =
          memberRef(
            guildId,
            uid,
          );

        // ----------------------------------------------------
        // READ GUILD
        // ----------------------------------------------------

        const guildSnapshot =
          await transaction.get(
            guildReference,
          );

        // ----------------------------------------------------
        // READ MEMBER
        // ----------------------------------------------------

        const memberSnapshot =
          await transaction.get(
            memberReference,
          );

        if (
          !guildSnapshot.exists ||
          !memberSnapshot.exists
        ) {
          throw new HttpsError(
            "not-found",
            "Guildin jäsenyyttä ei löytynyt.",
          );
        }

        const guildData =
          guildSnapshot.data() || {};

        const memberData =
          memberSnapshot.data() || {};

        // ----------------------------------------------------
        // LEADER CHECK
        // ----------------------------------------------------

        if (
          guildData.leaderUid === uid ||
          memberData.role === GUILD_LEADER_ROLE
        ) {
          throw new HttpsError(
            "failed-precondition",
            "Guildin johtaja ei voi poistua ennen johtajuuden siirtoa.",
          );
        }

        // ----------------------------------------------------
        // MEMBER COUNT
        // ----------------------------------------------------

        const memberCount =
          getValidMemberCount(
            guildData,
          );

        // ----------------------------------------------------
        // DELETE MEMBER
        // ----------------------------------------------------

        transaction.delete(
          memberReference,
        );

        // ----------------------------------------------------
        // UPDATE GUILD
        // ----------------------------------------------------

        transaction.update(
          guildReference,
          {
            memberCount:
              Math.max(
                0,
                memberCount - 1,
              ),

            updatedAt:
              FieldValue.serverTimestamp(),
          },
        );

        // ----------------------------------------------------
        // UPDATE USER
        // ----------------------------------------------------

        transaction.update(
          userReference,
          {
            guildId: null,
            guildRole: null,
            guildJoinedAt: null,

            guildLastSwitchAt:
              FieldValue.serverTimestamp(),

            updatedAt:
              FieldValue.serverTimestamp(),
          },
        );

        // ----------------------------------------------------
        // RESULT
        // ----------------------------------------------------

        return {
          success: true,

          message:
            "Poistuit Guildista. Uuteen Guildiin liittyminen on mahdollista 24 tunnin kuluttua.",
        };
      },
    );
  },
);


// ============================================================
// 👢 KICK MEMBER
// ============================================================

const kickGuildMember = onCall(
  {
    region: "us-central1",
  },
  async (request) => {
    const leaderUid =
      requireAuth(request);

    const targetUid =
      validateUid(
        request.data?.targetUid,
      );

    if (
      targetUid === leaderUid
    ) {
      throw new HttpsError(
        "invalid-argument",
        "Et voi poistaa itseäsi tällä toiminnolla.",
      );
    }

    return db.runTransaction(
      async (transaction) => {
        // ----------------------------------------------------
        // REFERENCES
        // ----------------------------------------------------

        const leaderUserReference =
          userRef(leaderUid);

        const targetUserReference =
          userRef(targetUid);

        // ----------------------------------------------------
        // READ LEADER
        // ----------------------------------------------------

        const leaderUserSnapshot =
          await transaction.get(
            leaderUserReference,
          );

        // ----------------------------------------------------
        // READ TARGET
        // ----------------------------------------------------

        const targetUserSnapshot =
          await transaction.get(
            targetUserReference,
          );

        if (
          !leaderUserSnapshot.exists
        ) {
          throw new HttpsError(
            "not-found",
            "Johtajan käyttäjää ei löytynyt.",
          );
        }

        if (
          !targetUserSnapshot.exists
        ) {
          throw new HttpsError(
            "not-found",
            "Kohdekäyttäjää ei löytynyt.",
          );
        }

        const leaderUserData =
          leaderUserSnapshot.data() || {};

        const targetUserData =
          targetUserSnapshot.data() || {};

        // ----------------------------------------------------
        // GUILD ID
        // ----------------------------------------------------

        const guildId =
          leaderUserData.guildId;

        if (
          typeof guildId !== "string" ||
          !guildId.trim()
        ) {
          throw new HttpsError(
            "failed-precondition",
            "Et kuulu Guildiin.",
          );
        }

        // ----------------------------------------------------
        // TARGET GUILD CHECK
        // ----------------------------------------------------

        if (
          targetUserData.guildId !== guildId
        ) {
          throw new HttpsError(
            "failed-precondition",
            "Käyttäjä ei kuulu samaan Guildiin.",
          );
        }

        // ----------------------------------------------------
        // REFERENCES
        // ----------------------------------------------------

        const guildReference =
          guildRef(guildId);

        const leaderMemberReference =
          memberRef(
            guildId,
            leaderUid,
          );

        const targetMemberReference =
          memberRef(
            guildId,
            targetUid,
          );

        // ----------------------------------------------------
        // READ GUILD
        // ----------------------------------------------------

        const guildSnapshot =
          await transaction.get(
            guildReference,
          );

        // ----------------------------------------------------
        // READ LEADER MEMBER
        // ----------------------------------------------------

        const leaderMemberSnapshot =
          await transaction.get(
            leaderMemberReference,
          );

        // ----------------------------------------------------
        // READ TARGET MEMBER
        // ----------------------------------------------------

        const targetMemberSnapshot =
          await transaction.get(
            targetMemberReference,
          );

        if (
          !guildSnapshot.exists ||
          !leaderMemberSnapshot.exists ||
          !targetMemberSnapshot.exists
        ) {
          throw new HttpsError(
            "not-found",
            "Guildin jäsen tietoja ei löytynyt.",
          );
        }

        const guildData =
          guildSnapshot.data() || {};

        const leaderMemberData =
          leaderMemberSnapshot.data() || {};

        const targetMemberData =
          targetMemberSnapshot.data() || {};

        // ----------------------------------------------------
        // LEADER PERMISSION
        // ----------------------------------------------------

        if (
          guildData.leaderUid !== leaderUid ||
          leaderMemberData.role !==
            GUILD_LEADER_ROLE
        ) {
          throw new HttpsError(
            "permission-denied",
            "Vain Guildin johtaja voi poistaa jäseniä.",
          );
        }

        // ----------------------------------------------------
        // CANNOT KICK LEADER
        // ----------------------------------------------------

        if (
          targetUserData.guildRole ===
            GUILD_LEADER_ROLE ||
          targetMemberData.role ===
            GUILD_LEADER_ROLE ||
          guildData.leaderUid === targetUid
        ) {
          throw new HttpsError(
            "failed-precondition",
            "Guildin johtajaa ei voi poistaa.",
          );
        }

        // ----------------------------------------------------
        // MEMBER COUNT
        // ----------------------------------------------------

        const memberCount =
          getValidMemberCount(
            guildData,
          );

        // ----------------------------------------------------
        // DELETE MEMBER
        // ----------------------------------------------------

        transaction.delete(
          targetMemberReference,
        );

        // ----------------------------------------------------
        // UPDATE GUILD COUNT
        // ----------------------------------------------------

        transaction.update(
          guildReference,
          {
            memberCount:
              Math.max(
                0,
                memberCount - 1,
              ),

            updatedAt:
              FieldValue.serverTimestamp(),
          },
        );

        // ----------------------------------------------------
        // UPDATE TARGET USER
        // ----------------------------------------------------

        transaction.update(
          targetUserReference,
          {
            guildId: null,
            guildRole: null,
            guildJoinedAt: null,

            guildLastSwitchAt:
              FieldValue.serverTimestamp(),

            updatedAt:
              FieldValue.serverTimestamp(),
          },
        );

        // ----------------------------------------------------
        // RESULT
        // ----------------------------------------------------

        return {
          success: true,

          message:
            "Jäsen poistettiin Guildista. Hän voi liittyä uuteen Guildiin 24 tunnin kuluttua.",
        };
      },
    );
  },
);


// ============================================================
// 👑 TRANSFER GUILD LEADERSHIP
// ============================================================

const transferGuildLeadership = onCall(
  {
    region: "us-central1",
  },
  async (request) => {
    const currentLeaderUid =
      requireAuth(request);

    const targetUid =
      validateUid(
        request.data?.targetUid,
      );

    if (
      targetUid === currentLeaderUid
    ) {
      throw new HttpsError(
        "invalid-argument",
        "Johtajuutta ei voi siirtää itselleen.",
      );
    }

    return db.runTransaction(
      async (transaction) => {
        // ----------------------------------------------------
        // REFERENCES
        // ----------------------------------------------------

        const currentLeaderUserReference =
          userRef(
            currentLeaderUid,
          );

        const targetUserReference =
          userRef(
            targetUid,
          );

        // ----------------------------------------------------
        // READ CURRENT LEADER
        // ----------------------------------------------------

        const currentLeaderUserSnapshot =
          await transaction.get(
            currentLeaderUserReference,
          );

        // ----------------------------------------------------
        // READ TARGET USER
        // ----------------------------------------------------

        const targetUserSnapshot =
          await transaction.get(
            targetUserReference,
          );

        if (
          !currentLeaderUserSnapshot.exists ||
          !targetUserSnapshot.exists
        ) {
          throw new HttpsError(
            "not-found",
            "Käyttäjää ei löytynyt.",
          );
        }

        const currentLeaderUserData =
          currentLeaderUserSnapshot.data() || {};

        const targetUserData =
          targetUserSnapshot.data() || {};

        // ----------------------------------------------------
        // GUILD ID
        // ----------------------------------------------------

        const guildId =
          currentLeaderUserData.guildId;

        if (
          typeof guildId !== "string" ||
          !guildId.trim()
        ) {
          throw new HttpsError(
            "failed-precondition",
            "Et kuulu Guildiin.",
          );
        }

        // ----------------------------------------------------
        // TARGET MUST BE IN SAME GUILD
        // ----------------------------------------------------

        if (
          targetUserData.guildId !== guildId
        ) {
          throw new HttpsError(
            "failed-precondition",
            "Uuden johtajan täytyy olla saman Guildin jäsen.",
          );
        }

        // ----------------------------------------------------
        // REFERENCES
        // ----------------------------------------------------

        const guildReference =
          guildRef(guildId);

        const currentLeaderMemberReference =
          memberRef(
            guildId,
            currentLeaderUid,
          );

        const targetMemberReference =
          memberRef(
            guildId,
            targetUid,
          );

        // ----------------------------------------------------
        // READ GUILD
        // ----------------------------------------------------

        const guildSnapshot =
          await transaction.get(
            guildReference,
          );

        // ----------------------------------------------------
        // READ CURRENT LEADER MEMBER
        // ----------------------------------------------------

        const currentLeaderMemberSnapshot =
          await transaction.get(
            currentLeaderMemberReference,
          );

        // ----------------------------------------------------
        // READ TARGET MEMBER
        // ----------------------------------------------------

        const targetMemberSnapshot =
          await transaction.get(
            targetMemberReference,
          );

        if (
          !guildSnapshot.exists ||
          !currentLeaderMemberSnapshot.exists ||
          !targetMemberSnapshot.exists
        ) {
          throw new HttpsError(
            "not-found",
            "Guildin jäsen tietoja ei löytynyt.",
          );
        }

        const guildData =
          guildSnapshot.data() || {};

        const currentLeaderMemberData =
          currentLeaderMemberSnapshot.data() || {};

        const targetMemberData =
          targetMemberSnapshot.data() || {};

        // ----------------------------------------------------
        // CURRENT LEADER CHECK
        // ----------------------------------------------------

        if (
          guildData.leaderUid !==
            currentLeaderUid ||
          currentLeaderMemberData.role !==
            GUILD_LEADER_ROLE
        ) {
          throw new HttpsError(
            "permission-denied",
            "Vain nykyinen Guildin johtaja voi siirtää johtajuuden.",
          );
        }

        // ----------------------------------------------------
        // TARGET ROLE CHECK
        // ----------------------------------------------------

        if (
          targetMemberData.role !==
          GUILD_MEMBER_ROLE
        ) {
          throw new HttpsError(
            "failed-precondition",
            "Uuden johtajan täytyy olla tavallinen Guild-jäsen.",
          );
        }

        // ----------------------------------------------------
        // PROMOTE NEW LEADER
        // ----------------------------------------------------

        transaction.update(
          targetMemberReference,
          {
            role:
              GUILD_LEADER_ROLE,

            updatedAt:
              FieldValue.serverTimestamp(),
          },
        );

        // ----------------------------------------------------
        // DEMOTE OLD LEADER
        // ----------------------------------------------------

        transaction.update(
          currentLeaderMemberReference,
          {
            role:
              GUILD_MEMBER_ROLE,

            updatedAt:
              FieldValue.serverTimestamp(),
          },
        );

        // ----------------------------------------------------
        // UPDATE GUILD
        // ----------------------------------------------------

        transaction.update(
          guildReference,
          {
            leaderUid:
              targetUid,

            updatedAt:
              FieldValue.serverTimestamp(),
          },
        );

        // ----------------------------------------------------
        // UPDATE OLD LEADER PROFILE
        // ----------------------------------------------------

        transaction.update(
          currentLeaderUserReference,
          {
            guildRole:
              GUILD_MEMBER_ROLE,

            updatedAt:
              FieldValue.serverTimestamp(),
          },
        );

        // ----------------------------------------------------
        // UPDATE NEW LEADER PROFILE
        // ----------------------------------------------------

        transaction.update(
          targetUserReference,
          {
            guildRole:
              GUILD_LEADER_ROLE,

            updatedAt:
              FieldValue.serverTimestamp(),
          },
        );

        // ----------------------------------------------------
        // RESULT
        // ----------------------------------------------------

        return {
          success: true,

          message:
            "Guildin johtajuus siirrettiin onnistuneesti.",
        };
      },
    );
  },
);


// ============================================================
// 📦 EXPORTS
// ============================================================

module.exports = {
  leaveGuild,
  kickGuildMember,
  transferGuildLeadership,
};