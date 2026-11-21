
"use strict";

// ============================================================
// 🐱 STELLURIINI - GUILD FUNCTIONS
// ============================================================
//
// Guilds / Teams / Clans.
//
// Callable functions:
// - createGuild
// - joinGuild
//
// Security:
// - Firebase Authentication required
// - UID comes from Firebase Auth
// - Firestore transactions
// - Maximum 20 members
// - One Guild per user
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
  GUILD_INVITE_CODE_LENGTH,
  GUILD_INVITE_CODE_CHARACTERS,
  GUILD_CREATION_COOLDOWN_MS,
} = require("../config/guildConfig");


// ============================================================
// 🛠️ GUILD SERVICE
// ============================================================

const {
  getGuildRef,
  getGuildMemberRef,
  getGuildInviteRef,
  getUserRef,
  createGuildData,
  createGuildMemberData,
  createGuildInviteData,
} = require("../services/guildService");


// ============================================================
// 🎟️ INVITE CODE GENERATOR
// ============================================================

function generateInviteCode() {
  const characters =
    GUILD_INVITE_CODE_CHARACTERS;

  let code = "";

  for (
    let i = 0;
    i < GUILD_INVITE_CODE_LENGTH;
    i++
  ) {
    const index =
      Math.floor(
        Math.random() * characters.length,
      );

    code += characters[index];
  }

  return code;
}


// ============================================================
// 🛡️ AUTHENTICATION
// ============================================================

function requireAuthenticatedUid(request) {
  if (!request.auth) {
    throw new HttpsError(
      "unauthenticated",
      "Kirjautuminen vaaditaan.",
    );
  }

  const uid =
    request.auth.uid;

  if (
    typeof uid !== "string" ||
    !uid.trim()
  ) {
    throw new HttpsError(
      "unauthenticated",
      "Käyttäjän tunniste puuttuu.",
    );
  }

  return uid;
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
// 🐱 CREATE GUILD
// ============================================================

const createGuild = onCall(
  {
    region: "us-central1",
  },
  async (request) => {
    try {
      const uid =
        requireAuthenticatedUid(request);

      const rawName =
        request.data?.name;

      if (
        typeof rawName !== "string"
      ) {
        throw new HttpsError(
          "invalid-argument",
          "Guildin nimi puuttuu.",
        );
      }

      const guildName =
        rawName.trim();

      if (
        guildName.length < 3 ||
        guildName.length > 24
      ) {
        throw new HttpsError(
          "invalid-argument",
          "Guildin nimen tulee olla 3–24 merkkiä.",
        );
      }

      // --------------------------------------------------------
      // GUILD ID
      // --------------------------------------------------------

      const guildRef =
        db.collection("guilds").doc();

      // --------------------------------------------------------
      // INVITE CODE
      // --------------------------------------------------------

      let inviteCode = "";

      let inviteRef = null;

      // --------------------------------------------------------
      // GENERATE UNIQUE INVITE
      // --------------------------------------------------------

      for (
        let attempt = 0;
        attempt < 10;
        attempt++
      ) {
        const candidate =
          generateInviteCode();

        const candidateRef =
          getGuildInviteRef(candidate);

        const existing =
          await candidateRef.get();

        if (!existing.exists) {
          inviteCode = candidate;
          inviteRef = candidateRef;
          break;
        }
      }

      if (
        !inviteCode ||
        !inviteRef
      ) {
        throw new HttpsError(
          "resource-exhausted",
          "Kutsukoodin luominen epäonnistui. Yritä uudelleen.",
        );
      }

      // --------------------------------------------------------
      // REFERENCES
      // --------------------------------------------------------

      const userRef =
        getUserRef(uid);

      const memberRef =
        getGuildMemberRef(
          guildRef.id,
          uid,
        );

      // --------------------------------------------------------
      // TRANSACTION
      // --------------------------------------------------------

      const result =
        await db.runTransaction(
          async (transaction) => {
            const userSnapshot =
              await transaction.get(userRef);

            const inviteSnapshot =
              await transaction.get(inviteRef);

            const memberSnapshot =
              await transaction.get(memberRef);

            // ----------------------------------------------------
            // USER PROFILE
            // ----------------------------------------------------

            if (!userSnapshot.exists) {
              throw new HttpsError(
                "not-found",
                "Käyttäjäprofiilia ei löytynyt.",
              );
            }

            const userData =
              userSnapshot.data() || {};

            const now =
              Date.now();

            // ----------------------------------------------------
            // ALREADY IN GUILD
            // ----------------------------------------------------

            if (
              typeof userData.guildId === "string" &&
              userData.guildId.trim()
            ) {
              throw new HttpsError(
                "failed-precondition",
                "Olet jo Guildissa. Poistu nykyisestä Guildista ennen uuden luomista.",
              );
            }

            // ----------------------------------------------------
            // EXISTING MEMBER DOCUMENT
            // ----------------------------------------------------

            if (
              memberSnapshot.exists
            ) {
              throw new HttpsError(
                "already-exists",
                "Guild-jäsenyys on jo olemassa.",
              );
            }

            // ----------------------------------------------------
            // INVITE CODE COLLISION
            // ----------------------------------------------------

            if (
              inviteSnapshot.exists
            ) {
              throw new HttpsError(
                "already-exists",
                "Kutsukoodi on jo käytössä. Yritä uudelleen.",
              );
            }

            // ----------------------------------------------------
            // CREATION COOLDOWN
            // ----------------------------------------------------

            const lastGuildCreatedAt =
              timestampToMs(
                userData.guildCreatedAt,
              );

            if (
              lastGuildCreatedAt > 0 &&
              now - lastGuildCreatedAt <
                GUILD_CREATION_COOLDOWN_MS
            ) {
              const remainingMs =
                GUILD_CREATION_COOLDOWN_MS -
                (now - lastGuildCreatedAt);

              throw new HttpsError(
                "failed-precondition",
                `Uuden Guildin luonti ei ole vielä mahdollista. Odota ${Math.ceil(remainingMs / 3600000)} tuntia.`,
              );
            }

            // ----------------------------------------------------
            // GUILD DATA
            // ----------------------------------------------------

            const guildData =
              createGuildData({
                name: guildName,
                leaderUid: uid,
                inviteCode,
              });

            // ----------------------------------------------------
            // LEADER DATA
            // ----------------------------------------------------

            const memberData =
              createGuildMemberData({
                uid,
                role: GUILD_LEADER_ROLE,
              });

            // ----------------------------------------------------
            // INVITE DATA
            // ----------------------------------------------------

            const inviteData =
              createGuildInviteData({
                guildId: guildRef.id,
              });

            // ----------------------------------------------------
            // WRITE GUILD
            // ----------------------------------------------------

            transaction.set(
              guildRef,
              guildData,
            );

            // ----------------------------------------------------
            // WRITE LEADER
            // ----------------------------------------------------

            transaction.set(
              memberRef,
              memberData,
            );

            // ----------------------------------------------------
            // WRITE INVITE
            // ----------------------------------------------------

            transaction.set(
              inviteRef,
              inviteData,
            );

            // ----------------------------------------------------
            // UPDATE USER
            // ----------------------------------------------------

            transaction.update(
              userRef,
              {
                guildId:
                  guildRef.id,

                guildRole:
                  GUILD_LEADER_ROLE,

                guildJoinedAt:
                  FieldValue.serverTimestamp(),

                guildCreatedAt:
                  FieldValue.serverTimestamp(),

                guildLastSwitchAt:
                  FieldValue.serverTimestamp(),

                updatedAt:
                  FieldValue.serverTimestamp(),
              },
            );

            return {
              guildId:
                guildRef.id,

              guildName,

              inviteCode,

              role:
                GUILD_LEADER_ROLE,

              memberCount:
                1,
            };
          },
        );

      // ----------------------------------------------------------
      // SUCCESS
      // ----------------------------------------------------------

      return {
        success: true,

        ...result,

        message:
          "Guild luotu onnistuneesti! 🐱",
      };
    } catch (error) {
      console.error(
        "createGuild error:",
        error,
      );

      if (
        error instanceof HttpsError
      ) {
        throw error;
      }

      throw new HttpsError(
        "internal",
        "Guildin luominen epäonnistui.",
      );
    }
  },
);


// ============================================================
// 👥 JOIN GUILD
// ============================================================

const joinGuild = onCall(
  {
    region: "us-central1",
  },
  async (request) => {
    try {
      const uid =
        requireAuthenticatedUid(request);

      const rawInviteCode =
        request.data?.inviteCode;

      if (
        typeof rawInviteCode !== "string"
      ) {
        throw new HttpsError(
          "invalid-argument",
          "Kutsukoodi puuttuu.",
        );
      }

      const inviteCode =
        rawInviteCode.trim().toUpperCase();

      if (
        inviteCode.length !==
          GUILD_INVITE_CODE_LENGTH ||
        !new RegExp(
          `^[${GUILD_INVITE_CODE_CHARACTERS}]+$`,
        ).test(inviteCode)
      ) {
        throw new HttpsError(
          "invalid-argument",
          "Kutsukoodi muoto ei ole kelvollinen.",
        );
      }

      // --------------------------------------------------------
      // REFERENCES
      // --------------------------------------------------------

      const inviteRef =
        getGuildInviteRef(
          inviteCode,
        );

      const userRef =
        getUserRef(uid);

      // --------------------------------------------------------
      // TRANSACTION
      // --------------------------------------------------------

      const result =
        await db.runTransaction(
          async (transaction) => {
            // ----------------------------------------------------
            // READ INVITE
            // ----------------------------------------------------

            const inviteSnapshot =
              await transaction.get(
                inviteRef,
              );

            if (
              !inviteSnapshot.exists
            ) {
              throw new HttpsError(
                "not-found",
                "Kutsukoodia ei löytynyt.",
              );
            }

            const inviteData =
              inviteSnapshot.data() || {};

            if (
              inviteData.active !== true ||
              typeof inviteData.guildId !== "string"
            ) {
              throw new HttpsError(
                "failed-precondition",
                "Kutsukoodi ei ole aktiivinen.",
              );
            }

            const guildId =
              inviteData.guildId;

            const guildRef =
              getGuildRef(guildId);

            const memberRef =
              getGuildMemberRef(
                guildId,
                uid,
              );

            // ----------------------------------------------------
            // READ USER
            // ----------------------------------------------------

            const userSnapshot =
              await transaction.get(
                userRef,
              );

            // ----------------------------------------------------
            // READ GUILD
            // ----------------------------------------------------

            const guildSnapshot =
              await transaction.get(
                guildRef,
              );

            // ----------------------------------------------------
            // READ MEMBER
            // ----------------------------------------------------

            const memberSnapshot =
              await transaction.get(
                memberRef,
              );

            // ----------------------------------------------------
            // VALIDATE USER
            // ----------------------------------------------------

            if (
              !userSnapshot.exists
            ) {
              throw new HttpsError(
                "not-found",
                "Käyttäjäprofiilia ei löytynyt.",
              );
            }

            const userData =
              userSnapshot.data() || {};

            // ----------------------------------------------------
            // VALIDATE GUILD
            // ----------------------------------------------------

            if (
              !guildSnapshot.exists
            ) {
              throw new HttpsError(
                "not-found",
                "Guildia ei löytynyt.",
              );
            }

            const guildData =
              guildSnapshot.data() || {};

            // ----------------------------------------------------
            // ALREADY IN GUILD
            // ----------------------------------------------------

            if (
              typeof userData.guildId === "string" &&
              userData.guildId.trim()
            ) {
              if (
                userData.guildId === guildId
              ) {
                throw new HttpsError(
                  "already-exists",
                  "Olet jo tämän Guildin jäsen.",
                );
              }

              throw new HttpsError(
                "failed-precondition",
                "Olet jo toisen Guildin jäsen.",
              );
            }

            // ----------------------------------------------------
            // EXISTING MEMBER
            // ----------------------------------------------------

            if (
              memberSnapshot.exists
            ) {
              throw new HttpsError(
                "already-exists",
                "Guild-jäsenyys on jo olemassa.",
              );
            }

            // ----------------------------------------------------
            // MEMBER LIMIT
            // ----------------------------------------------------

            const memberCount =
              Number.isFinite(
                Number(guildData.memberCount),
              )
                ? Math.max(
                    0,
                    Math.floor(
                      Number(guildData.memberCount),
                    ),
                  )
                : 0;

            if (
              memberCount >=
              GUILD_MAX_MEMBERS
            ) {
              throw new HttpsError(
                "resource-exhausted",
                "Guild on täynnä (20/20 jäsentä).",
              );
            }

            // ----------------------------------------------------
            // JOIN
            // ----------------------------------------------------

            transaction.set(
              memberRef,
              createGuildMemberData({
                uid,
                role: GUILD_MEMBER_ROLE,
              }),
            );

            // ----------------------------------------------------
            // UPDATE GUILD COUNT
            // ----------------------------------------------------

            transaction.update(
              guildRef,
              {
                memberCount:
                  memberCount + 1,

                updatedAt:
                  FieldValue.serverTimestamp(),
              },
            );

            // ----------------------------------------------------
            // UPDATE USER
            // ----------------------------------------------------

            transaction.update(
              userRef,
              {
                guildId,

                guildRole:
                  GUILD_MEMBER_ROLE,

                guildJoinedAt:
                  FieldValue.serverTimestamp(),

                guildLastSwitchAt:
                  FieldValue.serverTimestamp(),

                updatedAt:
                  FieldValue.serverTimestamp(),
              },
            );

            return {
              guildId,

              guildName:
                typeof guildData.name === "string"
                  ? guildData.name
                  : "Guild",

              memberCount:
                memberCount + 1,

              role:
                GUILD_MEMBER_ROLE,
            };
          },
        );

      // ----------------------------------------------------------
      // SUCCESS
      // ----------------------------------------------------------

      return {
        success: true,

        ...result,

        message:
          "Liityit Guildiin onnistuneesti! 🐱",
      };
    } catch (error) {
      console.error(
        "joinGuild error:",
        error,
      );

      if (
        error instanceof HttpsError
      ) {
        throw error;
      }

      throw new HttpsError(
        "internal",
        "Guildiin liittyminen epäonnistui.",
      );
    }
  },
);


// ============================================================
// 📦 EXPORTS
// ============================================================

module.exports = {
  createGuild,
  joinGuild,
};
