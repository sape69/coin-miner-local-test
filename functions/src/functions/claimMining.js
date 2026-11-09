"use strict";

// ============================================================
// 🐱 STELLURIINI - CLAIM / START MINING
// ============================================================
//
// Stella Mining.
//
// Tämä moduuli sisältää claimMining Firebase Callable
// -toiminnon erillään miningFunctions.js-tiedostosta.
//
// Premium-käyttäjän mainosvapaa Mining Start tarkistetaan
// palvelimella Firestoresta.
//
// ============================================================

// ------------------------------------------------------------
// VERIFIED PREMIUM ENTITLEMENT
// ------------------------------------------------------------

function hasActiveVerifiedPremium(data, referenceNowMs) {
  if (
    !data ||
    data.premium !== true ||
    data.premiumVerified !== true
  ) {
    return false;
  }

  const expiry = data.premiumExpiryTime;
  let expiryMs = NaN;

  if (expiry && typeof expiry.toMillis === "function") {
    expiryMs = expiry.toMillis();
  } else if (expiry && typeof expiry.toDate === "function") {
    expiryMs = expiry.toDate().getTime();
  } else if (expiry instanceof Date) {
    expiryMs = expiry.getTime();
  } else if (typeof expiry === "number") {
    expiryMs = expiry;
  } else if (typeof expiry === "string") {
    expiryMs = Date.parse(expiry);
  }

  return (
    Number.isFinite(expiryMs) &&
    expiryMs > referenceNowMs
  );
}

function createClaimMining({
  onCall,
  HttpsError,
  db,
  FieldValue,

  getUserRef,
  getHistoryCollection,
  getAdMobRewardRef,

  getUtcDateString,

  miningWindow,
  historicalHashRate,
  miningHashRate,
  calculateMiningStatus,
  currentUnclaimedMining,
  calculateMiningCycle,

  miningDailyStreak,
  getMiningDailyClaim,
  getNextMiningDailyHashRate,
  getNextMiningDailyStreak,

  dailyHashRate,
  dailyHashRateBonus,

  getMiningHalvingMultiplier,
  getHalvingMultiplier,
  getRegisteredUserCount,

  getVerifiedMiningStartReward,
  validateVerifiedRewardDocument,
  toRewardHttpsError,

  prepareMiningAchievements,
  writeMiningAchievements,

  processReferralMiningReward,

  number,
  nonNegative,

  ADMOB_TEST_MODE,
  MINING_DURATION_MS,
  AD_HASH_RATE_BONUS,
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
            "🐱 Kirjaudu sisään aloittaaksesi Stella Miningin."
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

        const earlySnapshot = await userRef.get();

        const earlyData = earlySnapshot.exists
          ? earlySnapshot.data() || {}
          : {};

        const earlyWindow = miningWindow(
          earlyData
        );

        const earlyRate = earlyWindow.valid
          ? historicalHashRate(earlyData)
          : miningHashRate(
              earlyData,
              dailyHashRate(
                miningDailyStreak(earlyData) || 1
              )
            );

        const earlyStatus = calculateMiningStatus(
          {
            ...earlyData,
            hashRate: earlyRate,
          },
          earlyNow
        );

        // ------------------------------------------------------
        // MINING ALREADY ACTIVE
        // ------------------------------------------------------

        if (earlyStatus.miningActive) {
          const current = await currentUnclaimedMining(
            uid,
            earlyData,
            earlyNowMs
          );

          const today = getUtcDateString(
            earlyNow
          );

          const daily = getMiningDailyClaim(
            earlyData,
            today,
            earlyNowMs
          );

          return {
            success: true,

            started: false,

            collected: 0,

            miningActive: true,

            hashRate: earlyRate,

            miningHashRate: earlyRate,

            miningDay: daily.streak,

            dailyHashRate: daily.dailyHashRate,

            dailyHashRateBonus:
              dailyHashRateBonus(daily.streak),

            dailyStreak: daily.streak,

            streak: daily.streak,

            nextDailyHashRate:
              getNextMiningDailyHashRate(
                earlyData,
                today,
                earlyNowMs
              ),

            nextDailyStreak:
              getNextMiningDailyStreak(
                earlyData,
                today,
                earlyNowMs
              ),

            unclaimedMining:
              current.unclaimedMining,

            baseMining:
              current.baseMining,

            adBoostMining:
              current.adBoostMining,

            boostMilliseconds:
              current.boostMilliseconds,

            miningRemainingMs: Math.max(
              0,
              number(earlyStatus.miningRemainingMs)
            ),

            rewardConsumed: false,

            adRewardTransactionId:
              requestedTransactionId || null,

            message: requestedTransactionId
              ? "🐱⛏️ Stella louhii jo STL:ää. Uutta Mining Start -palkintoa ei kulutettu."
              : "🐱⛏️ Stella louhii jo STL:ää.",
          };
        }

        // ------------------------------------------------------
        // PREMIUM / ADMOB REWARD
        // ------------------------------------------------------

        const earlyPremiumMining =
          hasActiveVerifiedPremium(
            earlyData,
            earlyNowMs
          );

        let transactionId = "";
        let rewardRef = null;

        if (earlyPremiumMining) {
          transactionId =
            `premium-mining-start-${uid}-${earlyNowMs}`;

          console.log(
            "🐱 Premium entitlement verified: Mining Start ad bypassed."
          );
        } else if (ADMOB_TEST_MODE === true) {
          transactionId =
            requestedTransactionId ||
            `test-mining-start-${uid}-${earlyNowMs}`;

          console.log(
            "🐱 ADMOB_TEST_MODE: Mining Start " +
            "SSV verification bypassed."
          );
        } else {
          let verified;

          try {
            verified =
              await getVerifiedMiningStartReward(
                uid,
                {
                  transactionId:
                    requestedTransactionId,
                }
              );
          } catch (error) {
            throw toRewardHttpsError(
              error,
              "🐱 AdMob Mining Start -palkinnon vahvistaminen epäonnistui."
            );
          }

          transactionId =
            typeof verified?.transactionId === "string"
              ? verified.transactionId.trim()
              : "";

          if (!transactionId) {
            throw new HttpsError(
              "failed-precondition",
              "🐱 AdMob Mining Start -tapahtuman transaction ID puuttuu."
            );
          }

          rewardRef = getAdMobRewardRef(
            transactionId
          );

          if (!rewardRef) {
            throw new HttpsError(
              "failed-precondition",
              "🐱 AdMob-tapahtuman tunnistaminen epäonnistui."
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

            const currentStreak =
              miningDailyStreak(data);

            const fallbackRate = dailyHashRate(
              currentStreak || 1
            );

            const previous = miningWindow(data);

            const existingRate = previous.valid
              ? historicalHashRate(data)
              : miningHashRate(
                  data,
                  fallbackRate
                );

            const status = calculateMiningStatus(
              {
                ...data,
                hashRate: existingRate,
              },
              now
            );

            // --------------------------------------------------
            // MINING ALREADY STARTED DURING REQUEST
            // --------------------------------------------------

            if (status.miningActive) {
              const current = await currentUnclaimedMining(
                uid,
                data,
                nowMs,
                transaction
              );

              const daily = getMiningDailyClaim(
                data,
                today,
                nowMs
              );

              return {
                success: true,

                started: false,

                collected: 0,

                miningActive: true,

                hashRate: existingRate,

                miningHashRate: existingRate,

                miningDay: daily.streak,

                dailyHashRate: daily.dailyHashRate,

                dailyHashRateBonus:
                  dailyHashRateBonus(daily.streak),

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

                unclaimedMining:
                  current.unclaimedMining,

                baseMining:
                  current.baseMining,

                adBoostMining:
                  current.adBoostMining,

                boostMilliseconds:
                  current.boostMilliseconds,

                miningRemainingMs: Math.max(
                  0,
                  number(status.miningRemainingMs)
                ),

                rewardConsumed: false,

                adRewardTransactionId:
                  transactionId,

                message:
                  "🐱⛏️ Stella louhii jo STL:ää. Mainospalkintoa ei kulutettu.",
              };
            }

            // --------------------------------------------------
            // PREMIUM ENTITLEMENT / ADMOB VALIDATION
            // --------------------------------------------------

            const premiumMining =
              hasActiveVerifiedPremium(
                data,
                nowMs
              );

            if (
              earlyPremiumMining &&
              !premiumMining
            ) {
              throw new HttpsError(
                "failed-precondition",
                "🐱 Premium-tilaus ei ole enää voimassa. Päivitä tilaus tai katso mainos aloittaaksesi louhinnan."
              );
            }

            let authoritativeId = transactionId;

            if (
              !premiumMining &&
              ADMOB_TEST_MODE !== true
            ) {
              let validated;

              try {
                validated =
                  validateVerifiedRewardDocument(
                    rewardSnapshot,
                    uid,
                    "mining_start",
                    "miningStartClaimed",
                    {
                      referenceNowMs: nowMs,
                      transactionId,
                    }
                  );
              } catch (error) {
                throw toRewardHttpsError(
                  error,
                  "🐱 AdMob Mining Start -palkinnon vahvistaminen epäonnistui."
                );
              }

              authoritativeId =
                validated.transactionId;
            }

            // --------------------------------------------------
            // DAILY MINING
            // --------------------------------------------------

            const daily = getMiningDailyClaim(
              data,
              today,
              nowMs
            );

            const rate = daily.dailyHashRate;

            const oldBalance = nonNegative(
              data.miningBalance
            );

            let newBalance = oldBalance;

            let collected = 0;

            let previousBase = 0;
            let previousBoost = 0;
            let previousBoostMs = 0;

            let completedPrevious = false;

            // --------------------------------------------------
            // COLLECT PREVIOUS MINING CYCLE
            // --------------------------------------------------

            if (
              previous.valid &&
              previous.miningEndMs <= nowMs
            ) {
              const previousRate =
                historicalHashRate(data);

              if (previousRate <= 0) {
                throw new HttpsError(
                  "failed-precondition",
                  "🐱 Edellisen mining-cyclen Hash Rate on virheellinen."
                );
              }

              const cycle = await calculateMiningCycle(
                uid,
                previous.miningStartMs,
                previous.miningEndMs,
                previousRate,
                transaction,
                getMiningHalvingMultiplier(data)
              );

              previousBase = cycle.baseMining;

              previousBoost = cycle.adBoostMining;

              previousBoostMs =
                cycle.boostMilliseconds;

              collected = Math.max(
                0,
                cycle.totalMining
              );

              if (collected > 0) {
                newBalance = oldBalance + collected;

                completedPrevious = true;
              }
            }

            // --------------------------------------------------
            // HALVING
            // --------------------------------------------------

            const registeredUserCount =
              await getRegisteredUserCount();

            const newMiningHalvingMultiplier =
              getHalvingMultiplier(
                registeredUserCount
              );

            // --------------------------------------------------
            // ACHIEVEMENTS
            // --------------------------------------------------

            const achievementResult =
              await prepareMiningAchievements(
                transaction,
                uid,
                collected,
                true,
                daily.claimedToday,
                daily.streak,
                data,
                now
              );

            const achievementReward = Math.max(
              0,
              number(achievementResult.totalReward)
            );

            // --------------------------------------------------
            // REFERRAL REWARD
            // --------------------------------------------------

            let referralResult = {
              rewarded: false,
              duplicate: false,
              bonus: 0,
            };

            let miningTransactionId = "";

            if (
              completedPrevious &&
              collected > 0
            ) {
              miningTransactionId =
                getHistoryCollection(uid).doc().id;

              referralResult =
                await processReferralMiningReward(
                  uid,
                  collected,
                  miningTransactionId,
                  transaction
                );
            }

            writeMiningAchievements(
              transaction,
              achievementResult
            );

            // --------------------------------------------------
            // ACHIEVEMENT REWARDS
            // --------------------------------------------------

            if (achievementReward > 0) {
              newBalance += achievementReward;

              for (
                const reward of achievementResult.rewards
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
            // NEW MINING CYCLE
            // --------------------------------------------------

            const startedAt = now;

            const endsAt = new Date(
              nowMs + MINING_DURATION_MS
            );

            transaction.set(
              userRef,
              {
                hashRate: rate,

                // Mining streak is independent from Daily Check-In.
                miningStreak: daily.streak,

                lastMiningDate: today,

                miningHashRate: rate,

                miningHalvingMultiplier:
                  newMiningHalvingMultiplier,

                miningBalance: newBalance,

                // Count only STL produced by mining.
                // Achievement and referral rewards are excluded.
                totalMined:
                  FieldValue.increment(collected),

                miningStartedAt: startedAt,

                miningEndsAt: endsAt,

                miningCycles:
                  achievementResult.miningCycles,

                adBoostStartedAt: null,

                adBoostEndsAt: null,

                lastAdRewardAt: null,

                powerBoostTransactionId: null,

                updatedAt:
                  FieldValue.serverTimestamp(),
              },
              {
                merge: true,
              }
            );

            // --------------------------------------------------
            // ADMOB REWARD CONSUMPTION
            // --------------------------------------------------

            if (
              !premiumMining &&
              ADMOB_TEST_MODE !== true &&
              rewardRef
            ) {
              transaction.set(
                rewardRef,
                {
                  miningClaimed: true,

                  miningClaimedAt:
                    FieldValue.serverTimestamp(),

                  miningStartClaimed: true,

                  miningStartClaimedAt:
                    FieldValue.serverTimestamp(),

                  miningStartClaimedBy: uid,

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
            // DAILY HASH RATE HISTORY
            // --------------------------------------------------

            if (!daily.claimedToday) {
              transaction.set(
                getHistoryCollection(uid).doc(),
                {
                  type: "dailyHashRate",

                  title:
                    "Stella Daily Hash Rate 🐱✨",

                  amount: rate,

                  hashRate: rate,

                  dailyHashRate: rate,

                  hashRateBefore:
                    historicalHashRate(data),

                  hashRateAfter: rate,

                  dailyHashRateBonus:
                    dailyHashRateBonus(daily.streak),

                  dailyStreak: daily.streak,

                  streak: daily.streak,

                  miningDay: daily.streak,

                  previousDailyDate:
                    typeof data.lastMiningDate === "string"
                      ? data.lastMiningDate
                      : typeof data.lastDailyDate === "string"
                        ? data.lastDailyDate
                        : null,

                  currentDailyDate: today,

                  createdAt:
                    FieldValue.serverTimestamp(),
                }
              );
            }

            // --------------------------------------------------
            // PREVIOUS MINING REWARD HISTORY
            // --------------------------------------------------

            if (completedPrevious) {
              transaction.set(
                getHistoryCollection(uid).doc(
                  miningTransactionId
                ),
                {
                  type: "mining_reward",

                  title:
                    "Stella Mining Complete 🐱⛏️✨",

                  amount: collected,

                  balanceAfter: newBalance,

                  hashRate:
                    historicalHashRate(data),

                  miningHashRate:
                    historicalHashRate(data),

                  baseMining: previousBase,

                  adBoostMining: previousBoost,

                  boostMilliseconds: previousBoostMs,

                  miningStartedAt:
                    previous.miningStartedAt,

                  miningEndsAt:
                    previous.miningEndsAt,

                  miningTransactionId,

                  referralReward:
                    referralResult.rewarded
                      ? referralResult.bonus
                      : 0,

                  createdAt:
                    FieldValue.serverTimestamp(),
                }
              );
            }

            // --------------------------------------------------
            // NEW MINING HISTORY
            // --------------------------------------------------

            transaction.set(
              getHistoryCollection(uid).doc(),
              {
                type: "mining",

                title:
                  "Stella Mining Started 🐱⛏️",

                amount: 0,

                hashRate: rate,

                miningHashRate: rate,

                dailyHashRate: rate,

                dailyHashRateBonus:
                  dailyHashRateBonus(daily.streak),

                dailyStreak: daily.streak,

                streak: daily.streak,

                miningDay: daily.streak,

                miningDurationMs:
                  MINING_DURATION_MS,

                miningStartedAt: startedAt,

                miningEndsAt: endsAt,

                adRewardTransactionId:
                  authoritativeId,

                rewardPurpose: "mining_start",

                premiumAdFreeMining:
                  premiumMining,

                admobTestMode:
                  ADMOB_TEST_MODE === true,

                createdAt:
                  FieldValue.serverTimestamp(),
              }
            );

            // --------------------------------------------------
            // RESPONSE
            // --------------------------------------------------

            return {
              success: true,

              started: true,

              miningActive: true,

              collected,

              achievementReward,

              achievementRewards:
                achievementResult.rewards,

              referralReward:
                referralResult.rewarded
                  ? referralResult.bonus
                  : 0,

              referralRewarded:
                referralResult.rewarded === true,

              referralDuplicate:
                referralResult.duplicate === true,

              referralUid:
                referralResult.referrerUid || null,

              referralBonusPercent:
                referralResult.bonusPercent || 0,

              referralBonusRate:
                referralResult.bonusRate || 0,

              completedPreviousCycle:
                completedPrevious,

              miningBalance: newBalance,

              hashRate: rate,

              miningDay: daily.streak,

              dailyHashRate: rate,

              dailyHashRateBonus:
                dailyHashRateBonus(daily.streak),

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

              miningHashRate: rate,

              miningDurationMs:
                MINING_DURATION_MS,

              miningRemainingMs:
                MINING_DURATION_MS,

              miningStartedAt:
                startedAt.toISOString(),

              miningEndsAt:
                endsAt.toISOString(),

              adBoostActive: false,

              adBoostRemainingMs: 0,

              adHashRateBonus:
                AD_HASH_RATE_BONUS,

              effectiveHashRate: rate,

              adRewardTransactionId:
                authoritativeId,

              rewardConsumed:
                !premiumMining &&
                ADMOB_TEST_MODE !== true,

              premiumAdFreeMining:
                premiumMining,

              admobTestMode:
                ADMOB_TEST_MODE === true,

              message:
                referralResult.rewarded
                  ? `🐱🔗✨ Referral-bonus ${referralResult.bonus.toFixed(4)} STL maksettiin kutsujalle.`
                  : achievementReward > 0
                    ? `🐱🏆✨ Stella avasi achievement-palkinnon! +${achievementReward} STL.`
                    : completedPrevious
                      ? `🐱✨ Stella keräsi STL:t ja aloitti uuden louhinnan! Päivä ${daily.streak}, Hash Rate: ${rate.toFixed(4)} HR.`
                      : premiumMining
                        ? `🐱✨ Stella aloitti mainosvapaan Premium-louhinnan! Päivä ${daily.streak}, Hash Rate: ${rate.toFixed(4)} HR.`
                        : `🐱✨ Stella aloitti louhinnan! Päivä ${daily.streak}, Hash Rate: ${rate.toFixed(4)} HR.`,
            };
          }
        );
      } catch (error) {
        console.error(
          "claimMining error:",
          error
        );

        if (error instanceof HttpsError) {
          throw error;
        }

        const referralErrorCodes = [
          "REFERRAL_RELATIONSHIP_NOT_FOUND",
          "REFERRAL_RELATIONSHIP_MISMATCH",
        ];

        if (
          error &&
          referralErrorCodes.includes(error.message)
        ) {
          throw new HttpsError(
            "failed-precondition",
            "🐱 Referral-tiedoissa on ongelma. Louhinnan lunastus keskeytettiin turvallisesti. Ota yhteyttä tukeen."
          );
        }

        throw new HttpsError(
          "internal",
          "🐱 Stella Miningin käynnistäminen epäonnistui."
        );
      }
    }
  );
}

module.exports = {
  createClaimMining,
};