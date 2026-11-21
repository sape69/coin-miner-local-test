
"use strict";

// ============================================================
// 🐱 STELLURIINI - GUILD FUNCTIONS
// ============================================================
//
// Callable functions:
// - createGuild
// - joinGuild
//
// Rules:
// - Unique Guild names (case-insensitive)
// - Maximum 20 members
// - One Guild per user
// - 24h Guild creation cooldown
// - 24h Guild switch cooldown
// - Guild name migration must be completed before creation
// - Firestore transaction-based name reservation
//
// ============================================================

const {
  onCall,
  HttpsError,
} = require("firebase-functions/v2/https");

const crypto = require("crypto");

const {
  db,
  FieldValue,
} = require("../firebase/firebase");

const {
  GUILD_MAX_MEMBERS,
  GUILD_LEADER_ROLE,
  GUILD_MEMBER_ROLE,
  GUILD_INVITE_CODE_LENGTH,
  GUILD_INVITE_CODE_CHARACTERS,
  GUILD_CREATION_COOLDOWN_MS,
  GUILD_SWITCH_COOLDOWN_MS,
} = require("../config/guildConfig");

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
// 📦 MIGRATION REFERENCE
// ============================================================

const guildNameMigrationRef = db
  .collection("guildSystem")
  .doc("guildNameMigration");

// ============================================================
// 🎟️ INVITE CODE
// ============================================================

function generateInviteCode() {
  const characters =
    GUILD_INVITE_CODE_CHARACTERS;

  if (
    typeof characters !== "string" ||
    characters.length < 2
  ) {
    throw new Error(
      "Invalid Guild invite characters configuration.",
    );
  }

  let code = "";

  for (
    let i = 0;
    i < GUILD_INVITE_CODE_LENGTH;
    i++
  ) {
    code += characters[
      crypto.randomInt(0, characters.length)
    ];
  }

  return code;
}

// ============================================================
// 🔤 GUILD NAME NORMALIZATION
// ============================================================

function normalizeGuildName(name) {
  return name
    .trim()
    .normalize("NFKC")
    .toLowerCase()
    .replace(/\s+/g, " ");
}

function getGuildNameKey(normalizedName) {
  return crypto
    .createHash("sha256")
    .update(normalizedName, "utf8")
    .digest("hex");
}

// ============================================================
// 🛡️ AUTH
// ============================================================

function requireAuthenticatedUid(request) {
  if (!request.auth) {
    throw new HttpsError(
      "unauthenticated",
      "Kirjautuminen vaaditaan.",
    );
  }

  const uid = request.auth.uid;

  if (
    typeof uid !== "string" ||
    !uid.trim()
  ) {
    throw new HttpsError(
      "unauthenticated",
      "Käyttäjän tunniste puuttuu.",
    );
  }

  return uid.trim();
}

// ============================================================
// ⏰ TIMESTAMP
// ============================================================

function timestampToMs(value) {
  if (!value) return 0;

  if (typeof value.toMillis === "function") {
    return value.toMillis();
  }

  if (value instanceof Date) {
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
// ⏳ COOLDOWN
// ============================================================

function getCooldownRemaining(
  lastTimestamp,
  cooldownMs,
  now,
) {
  const lastTime =
    timestampToMs(lastTimestamp);

  if (lastTime <= 0) return 0;

  const elapsed = now - lastTime;

  if (elapsed >= cooldownMs) return 0;

  return cooldownMs - elapsed;
}

// ============================================================
// 🐱 CREATE GUILD
// ============================================================

const createGuild = onCall(
  { region: "us-central1" },
  async (request) => {
    try {
      const uid =
        requireAuthenticatedUid(request);

      // ------------------------------------------------------
      // VALIDATE NAME
      // ------------------------------------------------------

      const rawName =
        request.data?.name;

      if (typeof rawName !== "string") {
        throw new HttpsError(
          "invalid-argument",
          "Guildin nimi puuttuu.",
        );
      }

      const guildName = rawName
        .trim()
        .normalize("NFKC")
        .replace(/\s+/g, " ");

      if (
        guildName.length < 3 ||
        guildName.length > 24
      ) {
        throw new HttpsError(
          "invalid-argument",
          "Guildin nimen tulee olla 3–24 merkkiä.",
        );
      }

      const normalizedName =
        normalizeGuildName(guildName);

      const nameKey =
        getGuildNameKey(normalizedName);

      const nameRef =
        db.collection("guildNames").doc(nameKey);

      const guildRef =
        db.collection("guilds").doc();

      const userRef =
        getUserRef(uid);

      const memberRef =
        getGuildMemberRef(guildRef.id, uid);

      // ------------------------------------------------------
      // FIND AVAILABLE INVITE CODE
      // ------------------------------------------------------

      let inviteCode = "";
      let inviteRef = null;

      for (
        let attempt = 0;
        attempt < 20;
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

      if (!inviteCode || !inviteRef) {
        throw new HttpsError(
          "resource-exhausted",
          "Kutsukoodin luominen epäonnistui. Yritä uudelleen.",
        );
      }

      // ------------------------------------------------------
      // TRANSACTION
      // ------------------------------------------------------

      const result =
        await db.runTransaction(
          async (transaction) => {
            // ALL TRANSACTION READS BEFORE WRITES

            const migrationSnapshot =
              await transaction.get(
                guildNameMigrationRef,
              );

            const userSnapshot =
              await transaction.get(userRef);

            const inviteSnapshot =
              await transaction.get(inviteRef);

            const memberSnapshot =
              await transaction.get(memberRef);

            const nameSnapshot =
              await transaction.get(nameRef);

            // --------------------------------------------------
            // MIGRATION MUST BE COMPLETED
            // --------------------------------------------------

            if (
              !migrationSnapshot.exists ||
              migrationSnapshot.data()?.status !==
                "completed"
            ) {
              throw new HttpsError(
                "failed-precondition",
                "Guildien nimirekisteriä ei ole vielä alustettu. Guildin luonti ei ole tällä hetkellä käytössä.",
              );
            }

            // --------------------------------------------------
            // USER VALIDATION
            // --------------------------------------------------

            if (!userSnapshot.exists) {
              throw new HttpsError(
                "not-found",
                "Käyttäjäprofiilia ei löytynyt.",
              );
            }

            const userData =
              userSnapshot.data() || {};

            const now = Date.now();

            // --------------------------------------------------
            // UNIQUE NAME CHECK
            // --------------------------------------------------

            if (nameSnapshot.exists) {
              throw new HttpsError(
                "already-exists",
                "Tämä Guildin nimi on jo käytössä. Valitse toinen nimi.",
              );
            }

            // --------------------------------------------------
            // ALREADY IN GUILD
            // --------------------------------------------------

            if (
              typeof userData.guildId === "string" &&
              userData.guildId.trim()
            ) {
              throw new HttpsError(
                "failed-precondition",
                "Olet jo Guildissa. Poistu nykyisestä Guildista ennen uuden luomista.",
              );
            }

            if (memberSnapshot.exists) {
              throw new HttpsError(
                "already-exists",
                "Guild-jäsenyys on jo olemassa.",
              );
            }

            if (inviteSnapshot.exists) {
              throw new HttpsError(
                "already-exists",
                "Kutsukoodi on jo käytössä. Yritä uudelleen.",
              );
            }

            // --------------------------------------------------
            // CREATION COOLDOWN
            // --------------------------------------------------

            const lastGuildCreatedAt =
              timestampToMs(
                userData.guildCreatedAt,
              );

            const creationElapsed =
              now - lastGuildCreatedAt;

            if (
              lastGuildCreatedAt > 0 &&
              creationElapsed <
                GUILD_CREATION_COOLDOWN_MS
            ) {
              const remainingHours =
                Math.ceil(
                  (
                    GUILD_CREATION_COOLDOWN_MS -
                    creationElapsed
                  ) / 3600000,
                );

              throw new HttpsError(
                "failed-precondition",
                `Uuden Guildin luonti ei ole vielä mahdollista. Odota ${remainingHours} tuntia.`,
              );
            }

            // --------------------------------------------------
            // SWITCH COOLDOWN
            // --------------------------------------------------

            const switchRemaining =
              getCooldownRemaining(
                userData.guildLastSwitchAt,
                GUILD_SWITCH_COOLDOWN_MS,
                now,
              );

            if (switchRemaining > 0) {
              const remainingHours =
                Math.ceil(
                  switchRemaining / 3600000,
                );

              throw new HttpsError(
                "failed-precondition",
                `Guildin vaihtaminen ei ole vielä mahdollista. Odota ${remainingHours} tuntia.`,
              );
            }

            // --------------------------------------------------
            // CREATE DATA
            // --------------------------------------------------

            const guildData =
              createGuildData({
                name: guildName,
                leaderUid: uid,
                inviteCode,
              });

            const memberData =
              createGuildMemberData({
                uid,
                role: GUILD_LEADER_ROLE,
              });

            const inviteData =
              createGuildInviteData({
                guildId: guildRef.id,
              });

            // --------------------------------------------------
            // CREATE GUILD
            // --------------------------------------------------

            transaction.set(guildRef, {
              ...guildData,
              normalizedName,
              nameKey,
            });

            // --------------------------------------------------
            // RESERVE NAME
            // --------------------------------------------------

            transaction.set(nameRef, {
              guildId: guildRef.id,
              name: guildName,
              normalizedName,
              createdAt:
                FieldValue.serverTimestamp(),
            });

            // --------------------------------------------------
            // CREATE LEADER MEMBER
            // --------------------------------------------------

            transaction.set(
              memberRef,
              memberData,
            );

            // --------------------------------------------------
            // CREATE INVITE
            // --------------------------------------------------

            transaction.set(
              inviteRef,
              inviteData,
            );

            // --------------------------------------------------
            // UPDATE USER
            // --------------------------------------------------

            transaction.update(userRef, {
              guildId: guildRef.id,
              guildRole: GUILD_LEADER_ROLE,
              guildJoinedAt:
                FieldValue.serverTimestamp(),
              guildCreatedAt:
                FieldValue.serverTimestamp(),
              updatedAt:
                FieldValue.serverTimestamp(),
            });

            return {
              guildId: guildRef.id,
              guildName,
              inviteCode,
              role: GUILD_LEADER_ROLE,
              memberCount: 1,
            };
          },
        );

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

      if (error instanceof HttpsError) {
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
  { region: "us-central1" },
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
        rawInviteCode
          .trim()
          .toUpperCase();

      const validCharacters =
        new RegExp(
          `^[${GUILD_INVITE_CODE_CHARACTERS}]+$`,
        );

      if (
        inviteCode.length !==
          GUILD_INVITE_CODE_LENGTH ||
        !validCharacters.test(inviteCode)
      ) {
        throw new HttpsError(
          "invalid-argument",
          "Kutsukoodin muoto ei ole kelvollinen.",
        );
      }

      const inviteRef =
        getGuildInviteRef(inviteCode);

      const userRef =
        getUserRef(uid);

      // ------------------------------------------------------
      // TRANSACTION
      // ------------------------------------------------------

      const result =
        await db.runTransaction(
          async (transaction) => {
            const inviteSnapshot =
              await transaction.get(inviteRef);

            if (!inviteSnapshot.exists) {
              throw new HttpsError(
                "not-found",
                "Kutsukoodia ei löytynyt.",
              );
            }

            const inviteData =
              inviteSnapshot.data() || {};

            if (
              inviteData.active !== true ||
              typeof inviteData.guildId !== "string" ||
              !inviteData.guildId.trim()
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

            const userSnapshot =
              await transaction.get(userRef);

            const guildSnapshot =
              await transaction.get(guildRef);

            const memberSnapshot =
              await transaction.get(memberRef);

            // --------------------------------------------------
            // VALIDATE DOCUMENTS
            // --------------------------------------------------

            if (!userSnapshot.exists) {
              throw new HttpsError(
                "not-found",
                "Käyttäjäprofiilia ei löytynyt.",
              );
            }

            if (!guildSnapshot.exists) {
              throw new HttpsError(
                "not-found",
                "Guildia ei löytynyt.",
              );
            }

            const userData =
              userSnapshot.data() || {};

            const guildData =
              guildSnapshot.data() || {};

            const now = Date.now();

            // --------------------------------------------------
            // ALREADY IN GUILD
            // --------------------------------------------------

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
                "Olet jo toisen Guildin jäsen. Poistu nykyisestä Guildista ensin.",
              );
            }

            if (memberSnapshot.exists) {
              throw new HttpsError(
                "already-exists",
                "Guild-jäsenyys on jo olemassa.",
              );
            }

            // --------------------------------------------------
            // SWITCH COOLDOWN
            // --------------------------------------------------

            const switchRemaining =
              getCooldownRemaining(
                userData.guildLastSwitchAt,
                GUILD_SWITCH_COOLDOWN_MS,
                now,
              );

            if (switchRemaining > 0) {
              const remainingHours =
                Math.ceil(
                  switchRemaining / 3600000,
                );

              throw new HttpsError(
                "failed-precondition",
                `Guildiin liittyminen ei ole vielä mahdollista. Odota ${remainingHours} tuntia.`,
              );
            }

            // --------------------------------------------------
            // MEMBER COUNT
            // --------------------------------------------------

            const rawMemberCount =
              Number(guildData.memberCount);

            const memberCount =
              Number.isFinite(rawMemberCount)
                ? Math.max(
                    0,
                    Math.floor(rawMemberCount),
                  )
                : 0;

            if (
              memberCount >= GUILD_MAX_MEMBERS
            ) {
              throw new HttpsError(
                "resource-exhausted",
                "Guild on täynnä (20/20 jäsentä).",
              );
            }

            // --------------------------------------------------
            // CREATE MEMBER
            // --------------------------------------------------

            transaction.set(
              memberRef,
              createGuildMemberData({
                uid,
                role: GUILD_MEMBER_ROLE,
              }),
            );

            // --------------------------------------------------
            // UPDATE GUILD COUNT
            // --------------------------------------------------

            transaction.update(guildRef, {
              memberCount:
                memberCount + 1,
              updatedAt:
                FieldValue.serverTimestamp(),
            });

            // --------------------------------------------------
            // UPDATE USER
            // --------------------------------------------------

            transaction.update(userRef, {
              guildId,
              guildRole:
                GUILD_MEMBER_ROLE,
              guildJoinedAt:
                FieldValue.serverTimestamp(),
              updatedAt:
                FieldValue.serverTimestamp(),
            });

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

      if (error instanceof HttpsError) {
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
