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
// Louhintalaskennan apufunktiot annetaan factory-funktion
// kautta. Näin laskentaa ei kopioida eikä muuteta.
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
  return onCall(
    {
      region: "us-central1",
    },
    async (request) => {
      try {
        if (!request.auth) {
          throw new HttpsError(
            "unauthenticated",
            "🐱 Kirjaudu sisään jatkaaksesi Stella Miningia."
          );
        }

        const uid = request.auth.uid;

        const snapshot = await getUserRef(uid).get();

        const data = snapshot.exists
          ? snapshot.data() || {}
          : {};

        const now = new Date();
        const nowMs = now.getTime();
        const today = getUtcDateString(now);

        const daily = getMiningDailyClaim(
          data,
          today,
          nowMs
        );

        const window = miningWindow(data);
        const storedRate = historicalHashRate(data);

        const rate =
          window.valid && storedRate > 0
            ? storedRate
            : miningHashRate(
                data,
                daily.dailyHashRate
              );

        const status = calculateMiningStatus(
          {
            ...data,
            hashRate: rate,
          },
          now
        );

        const current = await currentUnclaimedMining(
          uid,
          data,
          nowMs
        );

        const ads = adStatus(
          data,
          nowMs,
          today
        );

        const effectiveRate = ads.adBoostActive
          ? rate + AD_HASH_RATE_BONUS
          : rate;

        const balance = nonNegative(
          data.miningBalance
        );

        const estimatedTotal = Math.max(
          0,
          balance + current.unclaimedMining
        );

        const halvingMultiplier =
          getMiningHalvingMultiplier(data);

        const miningPerHour =
          rate *
          MINING_PER_HASH_PER_HOUR *
          halvingMultiplier;

        const activeMiningPerHour =
          effectiveRate *
          MINING_PER_HASH_PER_HOUR *
          halvingMultiplier;

        const nextRate = getNextMiningDailyHashRate(
          data,
          today,
          nowMs
        );

        const nextStreak = getNextMiningDailyStreak(
          data,
          today,
          nowMs
        );

        return {
          success: true,

          message: status.miningActive
            ? "🐱⛏️ Stella louhii STL:ää!"
            : status.miningFinished
              ? "🐱✨ Louhinta on valmis kerättäväksi!"
              : "🐱 Stella odottaa seuraavaa louhintaa.",

          hashRate: rate,

          miningHalvingMultiplier:
            halvingMultiplier,

          miningBalance: balance,

          unclaimedMining:
            current.unclaimedMining,

          baseMining:
            current.baseMining,

          adBoostMining:
            current.adBoostMining,

          boostMilliseconds:
            current.boostMilliseconds,

          estimatedTotal,

          miningActive:
            status.miningActive === true,

          miningFinished:
            status.miningFinished === true,

          miningRemainingMs: Math.max(
            0,
            number(status.miningRemainingMs)
          ),

          elapsedMs: Math.max(
            0,
            number(status.elapsedMs)
          ),

          miningDurationMs:
            MINING_DURATION_MS,

          miningStartedAt: window.valid
            ? window.miningStartedAt.toISOString()
            : null,

          miningEndsAt: window.valid
            ? window.miningEndsAt.toISOString()
            : null,

          miningPerHour,

          miningPerMinute:
            miningPerHour / 60,

          miningPerSecond:
            miningPerHour / 3600,

          activeMiningPerHour,

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

module.exports = {
  createGetMiningStatus,
};