
"use strict";

// ============================================================
// 🐱 STELLURIINI - GET MINING STATUS
// ============================================================
//
// Stella Mining.
//
// Tämä tiedosto sisältää getMiningStatus Firebase Callable
// -toiminnon erillään miningFunctions.js-tiedostosta.
//
// Guild-bonus luetaan käyttäjän nykyisestä louhintajaksosta.
// Bonus ei lasketa uudelleen status-haun aikana.
//
// ============================================================

function createGetMiningStatus({
  onCall,
  HttpsError,
  getUserRef,
  getUtcDateString,
  getMiningDailyClaim,
  miningWindow,
  historicalHashRate,
  miningHashRate,
  calculateMiningStatus,
  currentUnclaimedMining,
  adStatus,
  AD_HASH_RATE_BONUS,
  AD_BOOST_DURATION_MS,
  MINING_PER_HASH_PER_HOUR,
  MINING_DURATION_MS,
  getMiningHalvingMultiplier,
  getNextMiningDailyHashRate,
  getNextMiningDailyStreak,
  dailyHashRateBonus,
  number,
  nonNegative,
}) {
  // ============================================================
  // 🕒 SAFE TIMESTAMP CONVERSION
  // ============================================================

  function timestampToIsoString(value) {
    try {
      if (!value) {
        return null;
      }

      if (
        typeof value.toDate === "function"
      ) {
        const date = value.toDate();

        return date instanceof Date &&
                !Number.isNaN(date.getTime())
            ? date.toISOString()
            : null;
      }

      if (value instanceof Date) {
        return !Number.isNaN(value.getTime())
            ? value.toISOString()
            : null;
      }

      if (typeof value === "string") {
        const date = new Date(value);

        return !Number.isNaN(date.getTime())
            ? date.toISOString()
            : null;
      }

      if (typeof value === "number") {
        const date = new Date(value);

        return !Number.isNaN(date.getTime())
            ? date.toISOString()
            : null;
      }

      if (
        typeof value === "object" &&
        value !== null
      ) {
        const seconds =
          value.seconds ??
          value._seconds;

        const nanoseconds =
          value.nanoseconds ??
          value._nanoseconds ??
          0;

        if (
          typeof seconds === "number" &&
          typeof nanoseconds === "number"
        ) {
          const milliseconds =
            seconds * 1000 +
            Math.floor(
              nanoseconds / 1000000
            );

          const date =
            new Date(milliseconds);

          return !Number.isNaN(date.getTime())
              ? date.toISOString()
              : null;
        }
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  // ============================================================
  // ⛏️ GET MINING STATUS
  // ============================================================

  return onCall(
    {
      region: "us-central1",
    },
    async (request) => {
      try {
        // ======================================================
        // 🔐 AUTHENTICATION
        // ======================================================

        if (!request.auth) {
          throw new HttpsError(
            "unauthenticated",
            "🐱 Kirjaudu sisään jatkaaksesi Stella Miningia."
          );
        }

        const uid =
          request.auth.uid;

        // ======================================================
        // 👤 USER DATA
        // ======================================================

        const snapshot =
          await getUserRef(uid).get();

        const data =
          snapshot.exists
              ? snapshot.data() || {}
              : {};

        // ======================================================
        // 🕒 TIME
        // ======================================================

        const now =
          new Date();

        const nowMs =
          now.getTime();

        const today =
          getUtcDateString(now);

        // ======================================================
        // 📅 DAILY MINING CLAIM
        // ======================================================

        const daily =
          getMiningDailyClaim(
            data,
            today,
            nowMs
          );

        // ======================================================
        // ⛏️ MINING WINDOW
        // ======================================================

        const window =
          miningWindow(data);

        const storedRate =
          historicalHashRate(data);

        const rate =
          window.valid && storedRate > 0
              ? storedRate
              : miningHashRate(
                  data,
                  daily.dailyHashRate
                );

        // ======================================================
        // 📊 MINING STATUS
        // ======================================================

        const status =
          calculateMiningStatus(
            {
              ...data,
              hashRate: rate,
            },
            now
          );

        // ======================================================
        // 💰 CURRENT UNCLAIMED MINING
        // ======================================================

        const current =
          await currentUnclaimedMining(
            uid,
            data,
            nowMs
          );

        // ======================================================
        // 📺 AD STATUS
        // ======================================================

        const ads =
          adStatus(
            data,
            nowMs,
            today
          );

        // ======================================================
        // ⚡ EFFECTIVE HASH RATE
        // ======================================================

        const effectiveRate =
          ads.adBoostActive
              ? rate + AD_HASH_RATE_BONUS
              : rate;

        // ======================================================
        // 💎 BALANCE
        // ======================================================

        const balance =
          nonNegative(
            data.miningBalance
          );

        const estimatedTotal =
          Math.max(
            0,
            balance + current.unclaimedMining
          );

        // ======================================================
        // 🔻 HALVING
        // ======================================================

        const halvingMultiplier =
          getMiningHalvingMultiplier(data);

        // ======================================================
        // ⛏️ MINING RATE
        // ======================================================

        const miningPerHour =
          rate *
          MINING_PER_HASH_PER_HOUR *
          halvingMultiplier;

        const activeMiningPerHour =
          effectiveRate *
          MINING_PER_HASH_PER_HOUR *
          halvingMultiplier;

        // ======================================================
        // 📅 NEXT DAILY HASH RATE
        // ======================================================

        const nextRate =
          getNextMiningDailyHashRate(
            data,
            today,
            nowMs
          );

        const nextStreak =
          getNextMiningDailyStreak(
            data,
            today,
            nowMs
          );

        // ======================================================
        // 🏰 GUILD BONUS - LOCKED MINING CYCLE
        // ======================================================
        //
        // Bonus luetaan nykyisestä louhintajaksosta.
        // Sitä ei lasketa uudelleen status-haun aikana.
        //
        // ======================================================

        const guildBonusPercent =
          window.valid
              ? Math.max(
                  0,
                  number(
                    data.guildMiningBonusPercent
                  )
                )
              : 0;

        const guildActiveMembers =
          window.valid
              ? Math.max(
                  0,
                  Math.floor(
                    number(
                      data.guildActiveMembers
                    )
                  )
                )
              : 0;

        const guildId =
          window.valid &&
          typeof data.guildId === "string" &&
          data.guildId.trim()
              ? data.guildId.trim()
              : null;

        const guildBonusLockedAt =
          window.valid
              ? timestampToIsoString(
                  data.guildBonusLockedAt
                )
              : null;

        const guildBonusActive =
          window.valid &&
          guildId !== null &&
          guildBonusPercent > 0;

        // ======================================================
        // 📤 RESPONSE
        // ======================================================

        return {
          success: true,

          message:
            status.miningActive
                ? "🐱⛏️ Stella louhii STL:ää!"
                : status.miningFinished
                    ? "🐱✨ Louhinta on valmis kerättäväksi!"
                    : "🐱 Stella odottaa seuraavaa louhintaa.",

          // ====================================================
          // ⚡ HASH RATE
          // ====================================================

          hashRate:
            rate,

          miningHalvingMultiplier:
            halvingMultiplier,

          // ====================================================
          // 🏰 GUILD BONUS
          // ====================================================

          guildId:
            guildId,

          guildBonusActive:
            guildBonusActive,

          guildMiningBonusPercent:
            guildBonusPercent,

          guildActiveMembers:
            guildActiveMembers,

          guildBonusLockedAt:
            guildBonusLockedAt,

          // ====================================================
          // 💎 BALANCE
          // ====================================================

          miningBalance:
            balance,

          unclaimedMining:
            current.unclaimedMining,

          baseMining:
            current.baseMining,

          adBoostMining:
            current.adBoostMining,

          boostMilliseconds:
            current.boostMilliseconds,

          estimatedTotal,

          // ====================================================
          // ⛏️ MINING STATUS
          // ====================================================

          miningActive:
            status.miningActive === true,

          miningFinished:
            status.miningFinished === true,

          miningRemainingMs:
            Math.max(
              0,
              number(
                status.miningRemainingMs
              )
            ),

          elapsedMs:
            Math.max(
              0,
              number(
                status.elapsedMs
              )
            ),

          miningDurationMs:
            MINING_DURATION_MS,

          miningStartedAt:
            window.valid
                ? window.miningStartedAt.toISOString()
                : null,

          miningEndsAt:
            window.valid
                ? window.miningEndsAt.toISOString()
                : null,

          // ====================================================
          // 📈 MINING ESTIMATES
          // ====================================================

          miningPerHour:
            miningPerHour,

          miningPerMinute:
            miningPerHour / 60,

          miningPerSecond:
            miningPerHour / 3600,

          activeMiningPerHour:
            activeMiningPerHour,

          // ====================================================
          // 📅 DAILY STREAK
          // ====================================================

          dailyClaimed:
            daily.claimedToday,

          miningDay:
            daily.streak,

          streak:
            daily.streak,

          dailyStreak:
            daily.streak,

          dailyHashRate:
            daily.dailyHashRate,

          dailyHashRateBonus:
            dailyHashRateBonus(
              daily.streak
            ),

          nextDailyHashRate:
            nextRate,

          nextDailyStreak:
            nextStreak,

          // ====================================================
          // 📺 ADS
          // ====================================================

          adsToday:
            ads.adsToday,

          maxAdsPerDay:
            ads.maxAdsPerDay,

          adHashRateBonus:
            AD_HASH_RATE_BONUS,

          adBoostDurationMs:
            AD_BOOST_DURATION_MS,

          adBoostActive:
            ads.adBoostActive,

          adBoostRemainingMs:
            ads.adBoostRemainingMs,

          adBoostStartedAt:
            ads.adBoostStartedAt
                ?.toISOString() || null,

          adBoostEndsAt:
            ads.adBoostEndsAt
                ?.toISOString() || null,

          canWatchAd:
            ads.canWatchAd,

          cooldownRemainingMs:
            ads.cooldownRemainingMs,

          // ====================================================
          // ⚡ EFFECTIVE HASH RATE
          // ====================================================

          effectiveHashRate:
            effectiveRate,
        };
      } catch (error) {
        console.error(
          "getMiningStatus error:",
          error
        );

        if (error instanceof HttpsError) {
          throw error;
        }

        throw new HttpsError(
          "internal",
          "Mining Status -tietojen lataaminen epäonnistui."
        );
      }
    }
  );
}

// ============================================================
// 📦 EXPORT
// ============================================================

module.exports = {
  createGetMiningStatus,
};
