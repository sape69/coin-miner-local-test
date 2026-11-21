"use strict";

// ============================================================
// 🐱 STELLURIINI - GUILD READ FUNCTIONS
// ============================================================
//
// Callable:
// - getGuildData
//
// Returns:
// - Guild information
// - Leader
// - Member list
// - Member roles
// - Verified active member count
// - Guild mining bonus
// - Invite code
//
// Security:
// - Authenticated users only
// - User can only read their own Guild
// - Firestore server-side reads
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
} = require("../firebase/firebase");


// ============================================================
// ⚙️ GUILD ACTIVITY
// ============================================================

const {
  getGuildActivity,
  GUILD_ACTIVE_WINDOW_MS,
} = require("../services/guildActivityService");


// ============================================================
// 🔐 AUTHENTICATION
// ============================================================

function requireAuthenticatedUid(request) {
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
// 🔍 VALIDATE UID
// ============================================================

function validateUid(uid) {
  if (
    typeof uid !== "string" ||
    !uid.trim() ||
    uid.trim().length > 128 ||
    !/^[A-Za-z0-9._-]+$/.test(
      uid.trim(),
    )
  ) {
    throw new HttpsError(
      "invalid-argument",
      "Virheellinen käyttäjätunniste.",
    );
  }

  return uid.trim();
}


// ============================================================
// 📦 REFERENCES
// ============================================================

function getUserRef(uid) {
  return db
    .collection("users")
    .doc(
      validateUid(uid),
    );
}


function getGuildRef(guildId) {
  return db
    .collection("guilds")
    .doc(guildId);
}


// ============================================================
// 👤 MEMBER DISPLAY DATA
// ============================================================

function getMemberDisplayName(
  userData,
  uid,
) {
  const username =
    typeof userData.username === "string"
      ? userData.username.trim()
      : "";

  const displayName =
    typeof userData.displayName === "string"
      ? userData.displayName.trim()
      : "";

  if (username) {
    return username;
  }

  if (displayName) {
    return displayName;
  }

  return `Miner ${uid.substring(0, 6)}`;
}


// ============================================================
// 👥 BUILD MEMBER LIST
// ============================================================

async function buildGuildMemberList(
  guildId,
  membersSnapshot,
) {
  const now = Date.now();

  const activeThreshold =
    now - GUILD_ACTIVE_WINDOW_MS;

  const memberDocuments =
    membersSnapshot.docs || [];

  // ----------------------------------------------------------
  // READ USER PROFILES
  // ----------------------------------------------------------

  const memberDataList =
    await Promise.all(
      memberDocuments.map(
        async (memberDocument) => {
          const memberData =
            memberDocument.data() || {};

          const uid =
            memberDocument.id;

          let userData = {};

          try {
            const userSnapshot =
              await getUserRef(uid).get();

            if (userSnapshot.exists) {
              userData =
                userSnapshot.data() || {};
            }
          } catch (error) {
            console.error(
              "Guild member profile read failed:",
              uid,
              error,
            );
          }

          const lastActiveAt =
            memberData.lastActiveAt || null;

          let lastActiveAtMs = 0;

          if (
            lastActiveAt &&
            typeof lastActiveAt.toMillis ===
              "function"
          ) {
            lastActiveAtMs =
              lastActiveAt.toMillis();
          }

          const isActive =
            lastActiveAtMs >=
            activeThreshold;

          return {
            uid,

            username:
              getMemberDisplayName(
                userData,
                uid,
              ),

            role:
              memberData.role || "member",

            joinedAt:
              memberData.joinedAt || null,

            lastActiveAt,

            active:
              isActive,
          };
        },
      ),
    );

  // ----------------------------------------------------------
  // SORT
  // ----------------------------------------------------------
  // Leader first, then active members, then username.
  // ----------------------------------------------------------

  memberDataList.sort(
    (a, b) => {
      if (
        a.role === "leader" &&
        b.role !== "leader"
      ) {
        return -1;
      }

      if (
        b.role === "leader" &&
        a.role !== "leader"
      ) {
        return 1;
      }

      if (
        a.active !== b.active
      ) {
        return a.active ? -1 : 1;
      }

      return a.username.localeCompare(
        b.username,
      );
    },
  );

  return memberDataList;
}


// ============================================================
// 🐱 GET GUILD DATA
// ============================================================

const getGuildData = onCall(
  {
    region: "us-central1",
  },
  async (request) => {
    try {
      // ------------------------------------------------------
      // AUTH
      // ------------------------------------------------------

      const uid =
        requireAuthenticatedUid(
          request,
        );

      // ------------------------------------------------------
      // READ USER
      // ------------------------------------------------------

      const userRef =
        getUserRef(uid);

      const userSnapshot =
        await userRef.get();

      if (!userSnapshot.exists) {
        throw new HttpsError(
          "not-found",
          "Käyttäjäprofiilia ei löytynyt.",
        );
      }

      const userData =
        userSnapshot.data() || {};

      // ------------------------------------------------------
      // GUILD MEMBERSHIP
      // ------------------------------------------------------

      const guildId =
        userData.guildId;

      if (
        typeof guildId !== "string" ||
        !guildId.trim()
      ) {
        return {
          success: true,
          inGuild: false,
          guild: null,
          members: [],
          activeMembers: 0,
          totalMembers: 0,
          bonusPercent: 0,
          message:
            "Et kuulu vielä Guildiin.",
        };
      }

      const cleanGuildId =
        guildId.trim();

      // ------------------------------------------------------
      // READ GUILD
      // ------------------------------------------------------

      const guildRef =
        getGuildRef(
          cleanGuildId,
        );

      const guildSnapshot =
        await guildRef.get();

      if (!guildSnapshot.exists) {
        throw new HttpsError(
          "not-found",
          "Guildia ei löytynyt.",
        );
      }

      const guildData =
        guildSnapshot.data() || {};

      // ------------------------------------------------------
      // READ MEMBERS
      // ------------------------------------------------------

      const membersSnapshot =
        await guildRef
          .collection("members")
          .get();

      // ------------------------------------------------------
      // ACTIVITY + BONUS
      // ------------------------------------------------------

      const activity =
        await getGuildActivity(
          cleanGuildId,
        );

      if (
        !activity.success
      ) {
        throw new HttpsError(
          "internal",
          "Guildin aktiivisuuden tarkistaminen epäonnistui.",
        );
      }

      // ------------------------------------------------------
      // MEMBER LIST
      // ------------------------------------------------------

      const members =
        await buildGuildMemberList(
          cleanGuildId,
          membersSnapshot,
        );

      // ------------------------------------------------------
      // VERIFY CURRENT MEMBERSHIP
      // ------------------------------------------------------

      const currentMember =
        members.find(
          (member) =>
            member.uid === uid,
        );

      if (!currentMember) {
        throw new HttpsError(
          "failed-precondition",
          "Guild-jäsenyyttä ei löytynyt. Päivitä käyttäjäprofiilisi.",
        );
      }

      // ------------------------------------------------------
      // RESULT
      // ------------------------------------------------------

      return {
        success: true,

        inGuild: true,

        guild: {
          id:
            cleanGuildId,

          name:
            guildData.name || "Guild",

          leaderUid:
            guildData.leaderUid || "",

          inviteCode:
            guildData.inviteCode || "",

          memberCount:
            members.length,

          maxMembers:
            20,

          createdAt:
            guildData.createdAt || null,

          updatedAt:
            guildData.updatedAt || null,
        },

        members,

        activeMembers:
          activity.activeMembers,

        totalMembers:
          activity.totalMembers,

        bonusPercent:
          activity.bonusPercent,

        activeWindowMinutes:
          GUILD_ACTIVE_WINDOW_MS /
          60000,

        currentUserRole:
          currentMember.role,

        checkedAt:
          activity.checkedAt,

        message:
          "Guild tiedot haettu onnistuneesti.",
      };
    } catch (error) {
      console.error(
        "getGuildData error:",
        error,
      );

      if (
        error instanceof HttpsError
      ) {
        throw error;
      }

      throw new HttpsError(
        "internal",
        "Guildin tietojen hakeminen epäonnistui.",
      );
    }
  },
);


// ============================================================
// 📦 EXPORTS
// ============================================================

module.exports = {
  getGuildData,
};