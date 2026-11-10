
"use strict";

// ============================================================
// 🐱 STELLURIINI - POWER BOOST
// ============================================================
//
// Stella Power Boost.
//
// Premium-käyttäjät voivat aktivoida Power Boostin ilman AdMob-mainosta.
// Premium-oikeus tarkistetaan aina palvelimella Firestore-profiilista.
//
// Tavallisten käyttäjien AdMob SSV -vahvistus säilyy ennallaan.
// Päivittäinen Boost-raja ja cooldown koskevat kaikkia käyttäjiä.
//
// ============================================================

// ------------------------------------------------------------
// VERIFIED PREMIUM CHECK
// ------------------------------------------------------------

function hasActiveVerifiedPremium(data, referenceNowMs) {
  if (
    data.premium !== true ||
    data.premiumVerified !== true
  ) {
    return false;
  }

  const expiry = data.premiumExpiryTime;
  let expiryMs = 0;

  if (
    expiry &&
    typeof expiry.toMillis === "function"
  ) {
    expiryMs = expiry.toMillis();
  } else if (
    expiry &&
    typeof expiry.toDate === "function"
  ) {
    expiryMs = expiry.toDate().getTime();
  } else if (expiry instanceof Date) {
    expiryMs = expiry.getTime();
  } else if (
    typeof expiry === "number" &&
    Number.isFinite(expiry)
  ) {
    expiryMs = expiry;
  } else if (typeof expiry === "string") {
    expiryMs = Date.parse(expiry) || 0;
  } else if (
    expiry &&
    typeof expiry === "object"
  ) {
    const seconds =
      expiry._seconds ?? expiry.seconds;

    const nanos =
      expiry._nanoseconds ??
      expiry.nanoseconds ??
      0;

    if (typeof seconds === "number") {
      expiryMs =
        seconds * 1000 +
        Math.floor(nanos / 1000000);
    }
  }

  return expiryMs > referenceNowMs;
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

        // Päivittäinen käyttöraja koskee myös Premium-käyttäjiä.
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
        // Premium ohittaa tämän vaiheen kokonaan.
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
            "🐱 ADMOB_TEST_MODE: Power Boost " +
            "SSV verification bypassed."
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

            // Tarkistetaan Premium uudelleen transaktion sisällä.
            const premiumActive =
              hasActiveVerifiedPremium(
                data,
                nowMs
              );

            // Jos Premium ehti vanhentua tarkistusten välissä,
            // Premium-ohitusta ei hyväksytä.
            if (
              earlyPremiumActive &&
              !premiumActive
            ) {
              throw new HttpsError(
                "failed-precondition",
                "🐱 Premium-tilaus ei ole enää voimassa. Tarkista tilauksesi ja yritä uudelleen."
              );
            }

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
            // Premium ei tarvitse AdMob-vahvistusta.
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
            // Koskevat kaikkia käyttäjiä.
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

            const boostStartedAt = now;

            const actualEndMs = Math.min(
              nowMs + AD_BOOST_DURATION_MS,
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
            // Lasketaan Boostin käyttökerrat,
            // ei pelkästään katsottuja mainoksia.
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
            // ADMOB REWARD CONSUMPTION
            // Premium ei kuluta AdMob-palkintoa.
            // --------------------------------------------------

            if (
              !premiumActive &&
              ADMOB_TEST_MODE !== true &&
              rewardRef
            ) {
              transaction.set(
                rewardRef,
                {
                  powerBoostClaimed: true,

                  powerBoostClaimedAt:
                    FieldValue.serverTimestamp(),

                  powerBoostClaimedBy: uid,

                  powerBoostTransactionId:
                    authoritativeId,

                  consumedAt:
                    FieldValue.serverTimestamp(),

                  consumedBy: uid,

                  rewardConsumed: true,
                },
                {
                  merge: true,
                }
              );
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

                adHashRateBonus:
                  AD_HASH_RATE_BONUS,

                boostStartedAt,

                boostEndsAt,

                boostDurationMs: durationMs,

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

              configuredBoostDurationMs:
                AD_BOOST_DURATION_MS,

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
                durationMs < AD_BOOST_DURATION_MS
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
