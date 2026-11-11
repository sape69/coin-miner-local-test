
"use strict";

// ============================================================
// 🐱 STELLURIINI - POWER BOOST
// ============================================================
//
// Power Boost duration:
// FREE         = 4 hours
// PREMIUM      = 4 hours
// PREMIUM_PLUS = 24 hours
//
// Premium users can activate without AdMob.
// Premium Plus gets the extended 24-hour duration.
//
// ============================================================

const PREMIUM_PLUS_BOOST_DURATION_MS =
  24 * 60 * 60 * 1000;

// ------------------------------------------------------------
// VERIFIED PREMIUM CHECK
// ------------------------------------------------------------

const PREMIUM_PRODUCT_IDS = new Set([
  "stelluriini_premium_monthly",
  "stelluriini_premium_plus_monthly",
]);

const PREMIUM_PLUS_PRODUCT_ID =
  "stelluriini_premium_plus_monthly";

const VALID_PLAY_SUBSCRIPTION_STATES = new Set([
  "SUBSCRIPTION_STATE_ACTIVE",
  "SUBSCRIPTION_STATE_IN_GRACE_PERIOD",
  "SUBSCRIPTION_STATE_CANCELED",
]);

function timestampMs(value) {
  if (!value) return 0;

  if (typeof value.toMillis === "function") {
    return value.toMillis();
  }

  if (typeof value.toDate === "function") {
    return value.toDate().getTime();
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

  if (typeof value === "string") {
    return Date.parse(value) || 0;
  }

  if (typeof value === "object") {
    const seconds =
      value._seconds ?? value.seconds;

    const nanos =
      value._nanoseconds ??
      value.nanoseconds ??
      0;

    if (typeof seconds === "number") {
      return (
        seconds * 1000 +
        Math.floor(nanos / 1000000)
      );
    }
  }

  return 0;
}

// ------------------------------------------------------------
// VERIFIED PREMIUM CHECK
// ------------------------------------------------------------

function hasActiveVerifiedPremium(
  data,
  referenceNowMs
) {
  if (
    !data ||
    data.premium !== true ||
    data.premiumVerified !== true ||
    !PREMIUM_PRODUCT_IDS.has(
      data.premiumProductId
    ) ||
    !VALID_PLAY_SUBSCRIPTION_STATES.has(
      data.premiumSubscriptionState
    )
  ) {
    return false;
  }

  const expectedTier =
    data.premiumProductId === PREMIUM_PLUS_PRODUCT_ID
      ? "premium_plus"
      : "premium";

  if (data.premiumTier !== expectedTier) {
    return false;
  }

  return (
    timestampMs(data.premiumExpiryTime) >
    referenceNowMs
  );
}

// ------------------------------------------------------------
// VERIFIED PREMIUM PLUS CHECK
// ------------------------------------------------------------

function hasActiveVerifiedPremiumPlus(
  data,
  referenceNowMs
) {
  return (
    hasActiveVerifiedPremium(
      data,
      referenceNowMs
    ) &&
    data.premiumProductId ===
      PREMIUM_PLUS_PRODUCT_ID &&
    data.premiumTier === "premium_plus"
  );
}

// ============================================================
// POWER BOOST FACTORY
// ============================================================

function createPowerBoost({
  onCall,
  HttpsError,
  db,
  FieldValue,

  getUserRef,
  getHistoryCollection,
  getAdMobRewardRef,

  getUtcDateString,

  miningActive,
  miningWindow,
  historicalHashRate,
  calculateMiningStatus,

  adStatus,
  getMiningDailyClaim,
  getNextMiningDailyHashRate,
  getNextMiningDailyStreak,

  getVerifiedPowerBoostReward,
  validateVerifiedRewardDocument,

  preparePowerBoostAchievements,
  writeMiningAchievements,

  toRewardHttpsError,
  number,
  nonNegative,
  dailyHashRateBonus,

  ADMOB_TEST_MODE,
  AD_BOOST_DURATION_MS,
  AD_HASH_RATE_BONUS,
  MAX_ADS_PER_DAY,
}) {
  return onCall(
    {
      region: "us-central1",
      timeoutSeconds: 120,
    },
    async (request) => {
      try {
        if (!request.auth) {
          throw new HttpsError(
            "unauthenticated",
            "🐱 Kirjaudu sisään käyttääksesi Power Boostia."
          );
        }

        const uid = request.auth.uid;
        const userRef = getUserRef(uid);

        const requestedTransactionId =
          typeof request.data?.adMobTransactionId === "string"
            ? request.data.adMobTransactionId.trim()
            : "";

        const earlyNow = new Date();
        const earlyNowMs = earlyNow.getTime();

        const earlyToday = getUtcDateString(
          earlyNow
        );

        const earlySnapshot = await userRef.get();

        const earlyData = earlySnapshot.exists
          ? earlySnapshot.data() || {}
          : {};

        // ------------------------------------------------------
        // PREMIUM CHECK
        // ------------------------------------------------------

        const earlyPremiumActive =
          hasActiveVerifiedPremium(
            earlyData,
            earlyNowMs
          );

        // ------------------------------------------------------
        // MINING VALIDATION
        // ------------------------------------------------------

        if (
          !miningActive(
            earlyData,
            earlyNowMs
          )
        ) {
          throw new HttpsError(
            "failed-precondition",
            "🐱⚡ Power Boostia voi käyttää vain aktiivisen louhinnan aikana."
          );
        }

        const earlyRate = historicalHashRate(
          earlyData
        );

        if (earlyRate <= 0) {
          throw new HttpsError(
            "failed-precondition",
            "🐱⚡ Nykyisen louhintasyklin Hash Rate ei ole kelvollinen."
          );
        }

        const earlyAds = adStatus(
          earlyData,
          earlyNowMs,
          earlyToday
        );

        // ------------------------------------------------------
        // DAILY LIMIT
        // ------------------------------------------------------

        if (
          earlyAds.adsToday >= MAX_ADS_PER_DAY
        ) {
          throw new HttpsError(
            "resource-exhausted",
            "🐱 Päivän Power Boost -käyttöraja on täynnä."
          );
        }

        if (earlyAds.adBoostActive) {
          throw new HttpsError(
            "failed-precondition",
            "🐱 Power Boost on jo aktiivinen."
          );
        }

        if (
          earlyAds.cooldownRemainingMs > 0
        ) {
          throw new HttpsError(
            "failed-precondition",
            "🐱 Power Boost ei ole vielä valmis käytettäväksi uudelleen."
          );
        }

        // ------------------------------------------------------
        // ADMOB REWARD
        // ------------------------------------------------------

        let transactionId = "";
        let rewardRef = null;

        if (earlyPremiumActive) {
          transactionId =
            `premium-power-boost-${uid}-${earlyNowMs}`;

          console.log(
            "🐱 Premium: Power Boost AdMob verification bypassed."
          );
        } else if (ADMOB_TEST_MODE === true) {
          transactionId =
            requestedTransactionId ||
            `test-power-boost-${uid}-${earlyNowMs}`;

          console.log(
            "🐱 ADMOB_TEST_MODE: Power Boost SSV verification bypassed."
          );
        } else {
          let verified;

          try {
            verified =
              await getVerifiedPowerBoostReward(
                uid,
                {
                  transactionId:
                    requestedTransactionId,
                }
              );
          } catch (error) {
            throw toRewardHttpsError(
              error,
              "🐱 Power Boost -AdMob-palkinnon vahvistaminen epäonnistui."
            );
          }

          transactionId =
            typeof verified?.transactionId === "string"
              ? verified.transactionId.trim()
              : "";

          if (!transactionId) {
            throw new HttpsError(
              "failed-precondition",
              "🐱 Power Boost -tapahtuman transaction ID puuttuu."
            );
          }

          rewardRef = getAdMobRewardRef(
            transactionId
          );

          if (!rewardRef) {
            throw new HttpsError(
              "failed-precondition",
              "🐱 Power Boost -AdMob-tapahtuman tunnistaminen epäonnistui."
            );
          }
        }

        // ------------------------------------------------------
        // FIRESTORE TRANSACTION
        // ------------------------------------------------------

        return await db.runTransaction(
          async (transaction) => {
            const now = new Date();
            const nowMs = now.getTime();

            const today = getUtcDateString(
              now
            );

            const userSnapshot =
              await transaction.get(userRef);

            let rewardSnapshot = null;

            if (rewardRef) {
              rewardSnapshot =
                await transaction.get(rewardRef);
            }

            const data = userSnapshot.exists
              ? userSnapshot.data() || {}
              : {};

            // --------------------------------------------------
            // VERIFIED PREMIUM
            // --------------------------------------------------

            const premiumActive =
              hasActiveVerifiedPremium(
                data,
                nowMs
              );

            const premiumPlusActive =
              hasActiveVerifiedPremiumPlus(
                data,
                nowMs
              );

            if (
              earlyPremiumActive &&
              !premiumActive
            ) {
              throw new HttpsError(
                "failed-precondition",
                "🐱 Premium-tilaus ei ole enää voimassa. Tarkista tilauksesi ja yritä uudelleen."
              );
            }

            // --------------------------------------------------
            // MINING VALIDATION
            // --------------------------------------------------

            const window = miningWindow(data);

            if (
              !window.valid ||
              nowMs < window.miningStartMs ||
              nowMs >= window.miningEndMs
            ) {
              throw new HttpsError(
                "failed-precondition",
                "🐱⚡ Power Boostia voi käyttää vain aktiivisen louhinnan aikana."
              );
            }

            const rate = historicalHashRate(
              data
            );

            if (rate <= 0) {
              throw new HttpsError(
                "failed-precondition",
                "🐱⚡ Nykyisen louhintasyklin Hash Rate ei ole kelvollinen."
              );
            }

            const status = calculateMiningStatus(
              {
                ...data,
                hashRate: rate,
              },
              now
            );

            if (!status.miningActive) {
              throw new HttpsError(
                "failed-precondition",
                "🐱⚡ Stella Mining ei ole enää aktiivinen."
              );
            }

            // --------------------------------------------------
            // ADMOB VALIDATION
            // --------------------------------------------------

            let authoritativeId = transactionId;

            if (
              !premiumActive &&
              ADMOB_TEST_MODE !== true
            ) {
              let validated;

              try {
                validated =
                  validateVerifiedRewardDocument(
                    rewardSnapshot,
                    uid,
                    "power_boost",
                    "powerBoostClaimed",
                    {
                      referenceNowMs: nowMs,
                      transactionId,
                    }
                  );
              } catch (error) {
                throw toRewardHttpsError(
                  error,
                  "🐱 Power Boost -AdMob-palkinnon vahvistaminen epäonnistui."
                );
              }

              authoritativeId =
                validated.transactionId;
            }

            // --------------------------------------------------
            // DAILY LIMIT AND COOLDOWN
            // --------------------------------------------------

            const currentAds = adStatus(
              data,
              nowMs,
              today
            );

            if (
              currentAds.adsToday >= MAX_ADS_PER_DAY
            ) {
              throw new HttpsError(
                "resource-exhausted",
                "🐱 Päivän Power Boost -käyttöraja on täynnä."
              );
            }

            if (currentAds.adBoostActive) {
              throw new HttpsError(
                "failed-precondition",
                "🐱 Power Boost on jo aktiivinen."
              );
            }

            if (
              currentAds.cooldownRemainingMs > 0
            ) {
              throw new HttpsError(
                "failed-precondition",
                "🐱 Power Boost ei ole vielä valmis käytettäväksi uudelleen."
              );
            }

            // --------------------------------------------------
            // ACHIEVEMENTS - READ PHASE
            // --------------------------------------------------

            const powerBoostAchievementResult =
              await preparePowerBoostAchievements(
                transaction,
                uid,
                data,
                now
              );

            const powerBoostAchievementReward =
              Math.max(
                0,
                number(
                  powerBoostAchievementResult.totalReward
                )
              );

            const oldBalance = nonNegative(
              data.miningBalance
            );

            const newBalance =
              oldBalance +
              powerBoostAchievementReward;

            // --------------------------------------------------
            // POWER BOOST DURATION
            // --------------------------------------------------

            const configuredBoostDurationMs =
              premiumPlusActive
                ? PREMIUM_PLUS_BOOST_DURATION_MS
                : AD_BOOST_DURATION_MS;

            const boostStartedAt = now;

            const actualEndMs = Math.min(
              nowMs + configuredBoostDurationMs,
              window.miningEndMs
            );

            const boostEndsAt = new Date(
              actualEndMs
            );

            const durationMs = Math.max(
              0,
              actualEndMs - nowMs
            );

            if (durationMs <= 0) {
              throw new HttpsError(
                "failed-precondition",
                "🐱⚡ Louhintaa ei ole enää tarpeeksi jäljellä Power Boostia varten."
              );
            }

            // --------------------------------------------------
            // DAILY BOOST COUNTER
            // --------------------------------------------------

            const storedDate =
              typeof data.lastAdDate === "string"
                ? data.lastAdDate
                : "";

            const oldAds =
              storedDate === today
                ? Math.max(
                    0,
                    Math.floor(
                      number(data.adsToday)
                    )
                  )
                : 0;

            const newAdsToday = oldAds + 1;

            // --------------------------------------------------
            // USER UPDATE
            // --------------------------------------------------

            transaction.set(
              userRef,
              {
                miningBalance: newBalance,

                powerBoostCount:
                  powerBoostAchievementResult.powerBoostCount,

                adsToday: newAdsToday,

                lastAdDate: today,

                lastAdRewardAt:
                  FieldValue.serverTimestamp(),

                adBoostStartedAt:
                  boostStartedAt,

                adBoostEndsAt:
                  boostEndsAt,

                powerBoostTransactionId:
                  authoritativeId,

                updatedAt:
                  FieldValue.serverTimestamp(),
              },
              {
                merge: true,
              }
            );

            // --------------------------------------------------
            // ACHIEVEMENT WRITE PHASE
            // --------------------------------------------------

            writeMiningAchievements(
              transaction,
              powerBoostAchievementResult
            );

            // --------------------------------------------------
            // ACHIEVEMENT REWARD HISTORY
            // --------------------------------------------------

            if (
              powerBoostAchievementReward > 0
            ) {
              for (
                const reward of
                powerBoostAchievementResult.rewards
              ) {
                transaction.set(
                  getHistoryCollection(uid).doc(),
                  {
                    type: "achievement_reward",

                    title:
                      "Stella Achievement Reward 🐱🏆✨",

                    achievementId:
                      reward.achievementId,

                    amount: reward.reward,

                    balanceAfter: newBalance,

                    reward: reward.reward,

                    createdAt:
                      FieldValue.serverTimestamp(),
                  }
                );
              }
            }

            // --------------------------------------------------
            // POWER BOOST HISTORY
            // --------------------------------------------------

            transaction.set(
              getHistoryCollection(uid).doc(),
              {
                type: premiumActive
                  ? "premium_power_boost"
                  : "ad_reward",

                title: premiumActive
                  ? "Stelluriini Premium Power Boost 🐱⚡"
                  : "Stella Power Boost 🐱⚡",

                amount: 0,

                adRewardTransactionId:
                  authoritativeId,

                rewardPurpose: "power_boost",

                premiumAdFreePowerBoost:
                  premiumActive,

                premiumTier: premiumPlusActive
                  ? "premium_plus"
                  : premiumActive
                    ? "premium"
                    : "free",

                adHashRateBonus:
                  AD_HASH_RATE_BONUS,

                boostStartedAt,

                boostEndsAt,

                boostDurationMs: durationMs,

                configuredBoostDurationMs,

                miningStartedAt:
                  window.miningStartedAt,

                miningEndsAt:
                  window.miningEndsAt,

                miningHashRate: rate,

                adsToday: newAdsToday,

                maxAdsPerDay:
                  MAX_ADS_PER_DAY,

                admobTestMode:
                  !premiumActive &&
                  ADMOB_TEST_MODE === true,

                createdAt:
                  FieldValue.serverTimestamp(),
              }
            );

            // --------------------------------------------------
            // RESPONSE
            // --------------------------------------------------

            const daily = getMiningDailyClaim(
              data,
              today,
              nowMs
            );

            return {
              success: true,

              boostActive: true,

              active: true,

              alreadyActivated: false,

              adsToday: newAdsToday,

              maxAdsPerDay: MAX_ADS_PER_DAY,

              adHashRateBonus:
                AD_HASH_RATE_BONUS,

              boostRemainingMs: durationMs,

              remainingBoostMs: durationMs,

              adBoostDurationMs: durationMs,

              configuredBoostDurationMs,

              premiumTier: premiumPlusActive
                ? "premium_plus"
                : premiumActive
                  ? "premium"
                  : "free",

              premiumPlusBoost:
                premiumPlusActive,

              adBoostStartedAt:
                boostStartedAt.toISOString(),

              adBoostEndsAt:
                boostEndsAt.toISOString(),

              miningStartedAt:
                window.miningStartedAt.toISOString(),

              miningEndsAt:
                window.miningEndsAt.toISOString(),

              miningHashRate: rate,

              effectiveHashRate:
                rate + AD_HASH_RATE_BONUS,

              miningDay: daily.streak,

              dailyHashRate:
                daily.dailyHashRate,

              dailyHashRateBonus:
                dailyHashRateBonus(
                  daily.streak
                ),

              dailyStreak: daily.streak,

              streak: daily.streak,

              nextDailyHashRate:
                getNextMiningDailyHashRate(
                  data,
                  today,
                  nowMs
                ),

              nextDailyStreak:
                getNextMiningDailyStreak(
                  data,
                  today,
                  nowMs
                ),

              transactionId:
                authoritativeId,

              rewardConsumed:
                !premiumActive &&
                ADMOB_TEST_MODE !== true,

              premiumAdFreePowerBoost:
                premiumActive,

              admobTestMode:
                !premiumActive &&
                ADMOB_TEST_MODE === true,

              achievementReward:
                powerBoostAchievementReward,

              achievementRewards:
                powerBoostAchievementResult.rewards,

              miningBalance: newBalance,

              powerBoostCount:
                powerBoostAchievementResult.powerBoostCount,

              message:
                durationMs < configuredBoostDurationMs
                  ? "🐱⚡ Stella Power Boost on aktiivinen louhinnan loppuun asti!"
                  : powerBoostAchievementReward > 0
                    ? `🐱⚡ Stella Power Boost on aktiivinen! Stella avasi achievement-palkinnon +${powerBoostAchievementReward} STL.`
                    : "🐱⚡ Stella Power Boost on aktiivinen!",
            };
          }
        );
      } catch (error) {
        console.error(
          "powerBoost error:",
          error
        );

        if (error instanceof HttpsError) {
          throw error;
        }

        throw new HttpsError(
          "internal",
          "🐱 Power Boostin aktivointi epäonnistui."
        );
      }
    }
  );
}

module.exports = {
  createPowerBoost,
};
