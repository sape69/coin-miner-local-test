"use strict";

// ============================================================
// 🐱 STELLURIINI - MINING FUNCTIONS
// ============================================================
//
// Stella Mining.
//
// AdMob ei anna suoraan STL-tokenia.
//
// AdMob vahvistaa:
// - Mining Start
// - Power Boost
//
// Mining:
// Hash Rate × STL / Hash / Hour × elapsed time.
//
// Achievement reward:
// Achievementin avautuminen maksaa achievementin reward-arvon
// käyttäjän miningBalance-saldoon.
//
// Referral reward:
// Kutsujalle maksetaan referralConfig.js:n mukainen bonus
// vain kutsutun käyttäjän hyväksytystä mining-tuotosta.
//
// ============================================================

const {
onCall,
HttpsError,
} = require("firebase-functions/v2/https");

const {
db,
FieldValue,
} = require("../firebase/firebase");

const {
DAILY_HASH_RATE_START,
DAILY_HASH_RATE_STEP,
MAX_DAILY_HASH_RATE,
MINING_DURATION_MS,
MINING_PER_HASH_PER_HOUR,
AD_HASH_RATE_BONUS,
AD_BOOST_DURATION_MS,
MAX_ADS_PER_DAY,
AD_COOLDOWN_MS,
} = require("../config/miningConfig");

const {
getUtcDateString,
} = require("../utils/dateUtils");

const {
getUserRef,
getHistoryCollection,
getAdMobRewardRef,
} = require("../utils/userUtils");

const {
calculateMiningStatus,
getMiningStartTime,
getMiningEndTime,
calculateMining,
} = require("../utils/miningUtils");

const {
getVerifiedMiningStartReward,
getVerifiedPowerBoostReward,
validateVerifiedRewardDocument,
} = require("../services/admobRewardService");

// ============================================================
// 🏆 ACHIEVEMENTS
// ============================================================

const {
getAchievementDefinition,
} = require("./achievementFunctions");

// ============================================================
// 🔗 REFERRAL
// ============================================================

const {
processReferralMiningReward,
} = require("./referralFunctions");

// ============================================================
// VALUE HELPERS
// ============================================================

function number(value, fallback = 0) {
const result = Number(value);

return Number.isFinite(result)
? result
: fallback;
}

function nonNegative(value, fallback = 0) {
const result = Number(value);

return Number.isFinite(result) && result >= 0
? result
: fallback;
}

function positive(value, fallback = 0) {
const result = Number(value);

return Number.isFinite(result) && result > 0
? result
: fallback;
}

// ============================================================
// ADMOB ERROR MAPPING
// ============================================================

function toRewardHttpsError(
error,
fallbackMessage
) {
if (error instanceof HttpsError) {
return error;
}

const code =
typeof error?.code === "string"
? error.code
: "";

switch (code) {
case "ADMOB_REWARD_NOT_FOUND":
return new HttpsError(
"failed-precondition",
"🐱 AdMob-palkinnon vahvistusta odotetaan. Yritä hetken kuluttua uudelleen."
);

case "ADMOB_REWARD_ALREADY_CLAIMED":
  return new HttpsError(
    "already-exists",
    "🐱 Tämä AdMob-palkinto on jo käytetty."
  );

case "ADMOB_REWARD_EXPIRED":
  return new HttpsError(
    "failed-precondition",
    "🐱 AdMob-palkinto on vanhentunut."
  );

case "ADMOB_REWARD_NOT_VERIFIED":
  return new HttpsError(
    "failed-precondition",
    "🐱 AdMob-palkintoa ei ole vielä vahvistettu."
  );

case "ADMOB_TRANSACTION_ID_MISMATCH":
case "ADMOB_REWARD_UID_MISMATCH":
case "ADMOB_REWARD_PURPOSE_MISMATCH":
  return new HttpsError(
    "permission-denied",
    "🐱 AdMob-palkinnon tiedot eivät täsmää."
  );

case "ADMOB_REWARD_TIMESTAMP_MISSING":
case "ADMOB_REWARD_TIMESTAMP_INVALID":
case "ADMOB_REWARD_UID_MISSING":
case "ADMOB_REWARD_PURPOSE_MISSING":
case "ADMOB_REWARD_TRANSACTION_ID_MISSING":
  return new HttpsError(
    "failed-precondition",
    "🐱 AdMob-palkinnon vahvistustiedot ovat puutteelliset."
  );

case "ADMOB_INVALID_UID":
case "ADMOB_INVALID_REWARD_PURPOSE":
case "ADMOB_INVALID_CLAIM_FIELD":
  return new HttpsError(
    "invalid-argument",
    "🐱 AdMob-palkinnon tiedot ovat virheelliset."
  );

default:
  return new HttpsError(
    "failed-precondition",
    fallbackMessage
  );

}
}

// ============================================================
// TIMESTAMP HELPERS
// ============================================================

function timestampMs(value) {
if (!value) {
return 0;
}

if (typeof value.toMillis === "function") {
try {
const milliseconds = value.toMillis();

  return Number.isFinite(milliseconds)
    ? milliseconds
    : 0;
} catch (_) {
  return 0;
}

}

if (typeof value.toDate === "function") {
try {
const date = value.toDate();

  return date instanceof Date &&
    Number.isFinite(date.getTime())
    ? date.getTime()
    : 0;
} catch (_) {
  return 0;
}

}

if (value instanceof Date) {
return Number.isFinite(value.getTime())
? value.getTime()
: 0;
}

if (typeof value === "string") {
const milliseconds =
new Date(value).getTime();

return Number.isFinite(milliseconds)
  ? milliseconds
  : 0;

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
// DAILY HASH RATE
// ============================================================

function dailyHashRate(streak) {
const day =
Math.max(
1,
Math.floor(
number(streak, 1)
)
);

const start =
positive(
DAILY_HASH_RATE_START,
1
);

const step =
Math.max(
0,
number(
DAILY_HASH_RATE_STEP,
0
)
);

const maximum =
Math.max(
start,
positive(
MAX_DAILY_HASH_RATE,
start
)
);

const calculated =
start +
(day - 1) * step;

return Math.min(
maximum,
Math.max(
start,
calculated
)
);
}

function dailyHashRateBonus(streak) {
return Math.max(
0,
dailyHashRate(streak) -
dailyHashRate(1)
);
}

function dailyStreak(data) {
return Math.max(
0,
Math.floor(
number(
data.dailyStreak ??
data.streak,
0
)
)
);
}

// ============================================================
// DAILY CLAIM
// ============================================================

function nextDailyClaim(
data,
today
) {
const last =
typeof data.lastDailyDate === "string"
? data.lastDailyDate
: "";

const current =
dailyStreak(data);

if (last === today) {
const streak =
Math.max(
1,
current
);

return {
  claimedToday: true,
  streak,
  dailyHashRate:
    dailyHashRate(streak),
};

}

const yesterday =
new Date(
"${today}T00:00:00.000Z"
);

yesterday.setUTCDate(
yesterday.getUTCDate() - 1
);

const yesterdayString =
yesterday
.toISOString()
.slice(0, 10);

const streak =
last === yesterdayString &&
current > 0
? current + 1
: 1;

return {
claimedToday: false,
streak,
dailyHashRate:
dailyHashRate(streak),
};
}

function nextDailyHashRate(
data,
today
) {
const daily =
nextDailyClaim(
data,
today
);

if (!daily.claimedToday) {
return daily.dailyHashRate;
}

return dailyHashRate(
daily.streak + 1
);
}

function nextDailyStreak(
data,
today
) {
const daily =
nextDailyClaim(
data,
today
);

return daily.claimedToday
? daily.streak + 1
: daily.streak;
}

// ============================================================
// MINING WINDOW
// ============================================================

function miningWindow(data) {
const start =
getMiningStartTime(data);

const end =
getMiningEndTime(data);

const startMs =
start?.getTime() || 0;

const endMs =
end?.getTime() || 0;

const valid =
startMs > 0 &&
endMs > startMs;

return {
miningStartedAt:
valid ? start : null,

miningEndsAt:
  valid ? end : null,

miningStartMs:
  valid ? startMs : 0,

miningEndMs:
  valid ? endMs : 0,

valid,

};
}

function miningActive(
data,
nowMs
) {
const window =
miningWindow(data);

return (
window.valid &&
nowMs >= window.miningStartMs &&
nowMs < window.miningEndMs
);
}

function miningHashRate(
data,
fallback = DAILY_HASH_RATE_START
) {
const stored =
positive(
data.miningHashRate
);

if (
stored >= DAILY_HASH_RATE_START &&
stored <= MAX_DAILY_HASH_RATE
) {
return stored;
}

const safeFallback =
positive(
fallback,
DAILY_HASH_RATE_START
);

return Math.min(
MAX_DAILY_HASH_RATE,
Math.max(
DAILY_HASH_RATE_START,
safeFallback
)
);
}

function historicalHashRate(data) {
const rate =
positive(
data.miningHashRate ??
data.hashRate
);

return (
rate >= DAILY_HASH_RATE_START &&
rate <= MAX_DAILY_HASH_RATE
)
? rate
: 0;
}

// ============================================================
// AD STATUS
// ============================================================

function adStatus(
data,
nowMs,
today
) {
const lastDate =
typeof data.lastAdDate === "string"
? data.lastAdDate
: "";

const adsToday =
lastDate === today
? Math.max(
0,
Math.floor(
number(data.adsToday)
)
)
: 0;

const lastRewardMs =
timestampMs(
data.lastAdRewardAt
);

const cooldownRemainingMs =
lastRewardMs > 0
? Math.max(
0,
lastRewardMs +
AD_COOLDOWN_MS -
nowMs
)
: 0;

const boostStartMs =
timestampMs(
data.adBoostStartedAt
);

const boostEndMs =
timestampMs(
data.adBoostEndsAt
);

const window =
miningWindow(data);

const active =
window.valid &&
nowMs >= window.miningStartMs &&
nowMs < window.miningEndMs;

const boostInsideMining =
active &&
boostStartMs >= window.miningStartMs &&
boostStartMs < window.miningEndMs;

const effectiveEnd =
boostInsideMining &&
boostEndMs > boostStartMs
? Math.min(
boostEndMs,
window.miningEndMs
)
: 0;

const boostActive =
active &&
effectiveEnd > nowMs;

return {
adsToday,

maxAdsPerDay:
  MAX_ADS_PER_DAY,

cooldownRemainingMs,

canWatchAd:
  active &&
  adsToday < MAX_ADS_PER_DAY &&
  cooldownRemainingMs === 0 &&
  !boostActive,

adBoostActive:
  boostActive,

adBoostRemainingMs:
  boostActive
    ? effectiveEnd - nowMs
    : 0,

adBoostStartedAt:
  boostActive
    ? new Date(boostStartMs)
    : null,

adBoostEndsAt:
  boostActive
    ? new Date(effectiveEnd)
    : null,

};
}

// ============================================================
// BOOST HISTORY
// ============================================================

function maxBoostHistoryEntries() {
const dayMs =
24 * 60 * 60 * 1000;

const days =
Math.max(
1,
Math.ceil(
MINING_DURATION_MS / dayMs
)
);

return Math.max(
MAX_ADS_PER_DAY,
(days + 1) *
MAX_ADS_PER_DAY +
10
);
}

async function getAdBoostHistory(
uid,
startMs,
endMs,
transaction = null
) {
if (
!startMs ||
!endMs ||
endMs <= startMs
) {
return [];
}

const query =
getHistoryCollection(uid)
.where(
"boostStartedAt",
">=",
new Date(startMs)
)
.where(
"boostStartedAt",
"<",
new Date(endMs)
)
.orderBy(
"boostStartedAt",
"asc"
)
.limit(
maxBoostHistoryEntries()
);

const snapshot =
transaction
? await transaction.get(query)
: await query.get();

const boosts = [];

snapshot.forEach((doc) => {
const data =
doc.data() || {};

if (
  data.type !== "ad_reward" ||
  data.rewardPurpose !==
    "power_boost"
) {
  return;
}

const start =
  timestampMs(
    data.boostStartedAt
  );

const end =
  timestampMs(
    data.boostEndsAt
  );

if (
  start <= 0 ||
  end <= start ||
  start < startMs ||
  start >= endMs ||
  end <= startMs
) {
  return;
}

boosts.push({
  boostStartedMs:
    Math.max(
      start,
      startMs
    ),

  boostEndsMs:
    Math.min(
      end,
      endMs
    ),
});

});

return boosts;
}

function boostMilliseconds(
boosts,
startMs,
endMs
) {
if (
!Array.isArray(boosts) ||
!startMs ||
!endMs ||
endMs <= startMs
) {
return 0;
}

const intervals =
boosts
.map((boost) => {
const start =
Math.max(
startMs,
number(
boost.boostStartedMs
)
);

    const end =
      Math.min(
        endMs,
        number(
          boost.boostEndsMs
        )
      );

    return end > start
      ? { start, end }
      : null;
  })
  .filter(Boolean)
  .sort(
    (a, b) =>
      a.start - b.start
  );

if (!intervals.length) {
return 0;
}

let total = 0;

let start =
intervals[0].start;

let end =
intervals[0].end;

for (
let i = 1;
i < intervals.length;
i++
) {
const current =
intervals[i];

if (
  current.start <= end
) {
  end =
    Math.max(
      end,
      current.end
    );
} else {
  total +=
    end - start;

  start =
    current.start;

  end =
    current.end;
}

}

return Math.max(
0,
total + end - start
);
}

// ============================================================
// MINING CALCULATION
// ============================================================

async function calculateMiningCycle(
uid,
startMs,
endMs,
hashRate,
transaction = null
) {
if (
!startMs ||
!endMs ||
endMs <= startMs
) {
return {
baseMining: 0,
adBoostMining: 0,
boostMilliseconds: 0,
totalMining: 0,
};
}

const rate =
positive(hashRate);

const duration =
endMs - startMs;

const baseMining =
rate > 0
? Math.max(
0,
number(
calculateMining(
rate,
duration
)
)
)
: 0;

const boosts =
await getAdBoostHistory(
uid,
startMs,
endMs,
transaction
);

const boostMs =
boostMilliseconds(
boosts,
startMs,
endMs
);

const adBoostMining =
boostMs > 0 &&
AD_HASH_RATE_BONUS > 0
? Math.max(
0,
number(
calculateMining(
AD_HASH_RATE_BONUS,
boostMs
)
)
)
: 0;

return {
baseMining,
adBoostMining,
boostMilliseconds:
boostMs,
totalMining:
Math.max(
0,
baseMining +
adBoostMining
),
};
}

async function currentUnclaimedMining(
uid,
data,
nowMs,
transaction = null
) {
const window =
miningWindow(data);

if (!window.valid) {
return {
unclaimedMining: 0,
baseMining: 0,
adBoostMining: 0,
boostMilliseconds: 0,
};
}

const endMs =
Math.min(
window.miningEndMs,
nowMs
);

if (
endMs <=
window.miningStartMs
) {
return {
unclaimedMining: 0,
baseMining: 0,
adBoostMining: 0,
boostMilliseconds: 0,
};
}

const rate =
historicalHashRate(data);

if (rate <= 0) {
return {
unclaimedMining: 0,
baseMining: 0,
adBoostMining: 0,
boostMilliseconds: 0,
};
}

const cycle =
await calculateMiningCycle(
uid,
window.miningStartMs,
endMs,
rate,
transaction
);

return {
unclaimedMining:
cycle.totalMining,

baseMining:
  cycle.baseMining,

adBoostMining:
  cycle.adBoostMining,

boostMilliseconds:
  cycle.boostMilliseconds,

};
}

// ============================================================
// 🏆 ACHIEVEMENT HELPERS
// ============================================================

function achievementCollection(uid) {
return getUserRef(uid)
.collection("achievements");
}

async function readAchievementData(
transaction,
uid,
definitions
) {
const items = [];

for (
const definition of definitions
) {
const ref =
achievementCollection(uid)
.doc(definition.id);

const snapshot =
  await transaction.get(ref);

items.push({
  definition,
  ref,
  data:
    snapshot.exists
      ? snapshot.data() || {}
      : {},
});

}

return items;
}

function achievementUpdate(
definition,
progress,
existing,
now
) {
const oldProgress =
Math.max(
0,
number(
existing.progress
)
);

const safeTarget =
Math.max(
0,
number(
definition.target
)
);

const safeReward =
Math.max(
0,
number(
definition.reward
)
);

const safeProgress =
Math.min(
safeTarget,
Math.max(
oldProgress,
nonNegative(progress)
)
);

const alreadyUnlocked =
existing.unlocked === true;

const unlocked =
alreadyUnlocked ||
(
safeTarget > 0 &&
safeProgress >= safeTarget
);

const rewardClaimed =
existing.rewardClaimed === true;

const update = {
achievementId:
definition.id,

progress:
  safeProgress,

target:
  safeTarget,

reward:
  safeReward,

unlocked,

rewardClaimed,

updatedAt:
  now,

};

if (
unlocked &&
!alreadyUnlocked &&
!existing.unlockedAt
) {
update.unlockedAt =
now;
} else if (
existing.unlockedAt
) {
update.unlockedAt =
existing.unlockedAt;
}

if (
existing.rewardClaimedAt
) {
update.rewardClaimedAt =
existing.rewardClaimedAt;
}

return update;
}

// ============================================================
// 🏆 ACHIEVEMENT RESULT BUILDER
// ============================================================

function buildAchievementResult(
items,
progressById,
now
) {
const updates = [];

let totalReward = 0;

for (
const item of items
) {
const {
definition,
ref,
data,
} = item;

const progress =
  progressById[definition.id] ??
  data.progress ??
  0;

const wasUnlocked =
  data.unlocked === true;

const wasRewardClaimed =
  data.rewardClaimed === true;

const update =
  achievementUpdate(
    definition,
    progress,
    data,
    now
  );

const newlyRewardable =
  update.unlocked === true &&
  wasRewardClaimed === false;

let reward = 0;

if (newlyRewardable) {
  reward =
    Math.max(
      0,
      number(
        definition.reward
      )
    );

  update.rewardClaimed =
    true;

  update.rewardClaimedAt =
    now;

  totalReward +=
    reward;
}

updates.push({
  ref,
  update,

  achievementId:
    definition.id,

  reward,

  newlyUnlocked:
    !wasUnlocked &&
    update.unlocked === true,
});

}

return {
updates,

totalReward,

rewards:
  updates
    .filter(
      (item) =>
        item.reward > 0
    )
    .map(
      (item) => ({
        achievementId:
          item.achievementId,

        reward:
          item.reward,

        newlyUnlocked:
          item.newlyUnlocked,
      })
    ),

};
}

// ============================================================
// 🏆 PREPARE MINING ACHIEVEMENTS
// ============================================================
//
// Mining achievements:
// - First Paw
// - Little Miner
// - STL Hunter
// - Growing Miner
// - STL Collector
// - STL Master
// - Dedicated Miner
// - Hot Streak
// - Stella on Fire
// - Stella Legend
// - Stella's Friend
//
// TÄRKEÄ FIRESTORE-KORJAUS:
//
// Kaikki achievement READ-operaatiot tehdään ensin.
// Vasta niiden jälkeen tehdään transaction WRITE-operaatiot.
//
// ============================================================

async function prepareMiningAchievements(
transaction,
uid,
collected,
started,
dailyClaimedToday,
dailyStreakValue,
data,
now
) {
const definitions = [
getAchievementDefinition("first_paw"),
getAchievementDefinition("little_miner"),
getAchievementDefinition("stl_hunter"),
getAchievementDefinition("growing_miner"),
getAchievementDefinition("stl_collector"),
getAchievementDefinition("stl_master"),
getAchievementDefinition("dedicated_miner"),
getAchievementDefinition("hot_streak"),
getAchievementDefinition("stella_on_fire"),
getAchievementDefinition("stella_legend"),
getAchievementDefinition("stellas_friend"),
].filter(Boolean);

const items =
await readAchievementData(
transaction,
uid,
definitions
);

const collectedAmount =
nonNegative(collected);

const oldMiningCycles =
nonNegative(
data.miningCycles
);

const newMiningCycles =
oldMiningCycles +
(started ? 1 : 0);

const oldDailyCheckIns =
nonNegative(
data.dailyCheckIns
);

const newDailyCheckIns =
oldDailyCheckIns +
(
!dailyClaimedToday
? 1
: 0
);

const safeDailyStreak =
Math.max(
0,
Math.floor(
number(
dailyStreakValue
)
)
);

const progressById = {
first_paw:
started
? 1
: 0,

little_miner:
  collectedAmount,

stl_hunter:
  collectedAmount,

growing_miner:
  collectedAmount,

stl_collector:
  collectedAmount,

stl_master:
  collectedAmount,

dedicated_miner:
  newMiningCycles,

hot_streak:
  safeDailyStreak,

stella_on_fire:
  safeDailyStreak,

stella_legend:
  safeDailyStreak,

stellas_friend:
  newDailyCheckIns,

};

return {
...buildAchievementResult(
items,
progressById,
now
),

miningCycles:
  newMiningCycles,

dailyCheckIns:
  newDailyCheckIns,

};
}

// ============================================================
// 🏆 PREPARE POWER BOOST ACHIEVEMENTS
// ============================================================

async function preparePowerBoostAchievements(
transaction,
uid,
data,
now
) {
const definitions = [
getAchievementDefinition("power_paws"),
getAchievementDefinition("super_paws"),
].filter(Boolean);

const items =
await readAchievementData(
transaction,
uid,
definitions
);

const oldPowerBoostCount =
nonNegative(
data.powerBoostCount
);

const newPowerBoostCount =
oldPowerBoostCount + 1;

const progressById = {
power_paws:
newPowerBoostCount,

super_paws:
  newPowerBoostCount,

};

return {
...buildAchievementResult(
items,
progressById,
now
),

powerBoostCount:
  newPowerBoostCount,

};
}

function writeMiningAchievements(
transaction,
achievementResult
) {
for (
const item of
achievementResult.updates
) {
transaction.set(
item.ref,
item.update,
{
merge: true,
}
);
}
}

// ============================================================
// GET MINING STATUS
// ============================================================

const getMiningStatus =
onCall(
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

    const uid =
      request.auth.uid;

    const snapshot =
      await getUserRef(uid)
        .get();

    const data =
      snapshot.exists
        ? snapshot.data() || {}
        : {};

    const now =
      new Date();

    const nowMs =
      now.getTime();

    const today =
      getUtcDateString(now);

    const daily =
      nextDailyClaim(
        data,
        today
      );

    const window =
      miningWindow(data);

    const storedRate =
      historicalHashRate(data);

    const rate =
      window.valid &&
      storedRate > 0
        ? storedRate
        : miningHashRate(
            data,
            daily.dailyHashRate
          );

    const status =
      calculateMiningStatus(
        {
          ...data,
          hashRate: rate,
        },
        now
      );

    const current =
      await currentUnclaimedMining(
        uid,
        data,
        nowMs
      );

    const ads =
      adStatus(
        data,
        nowMs,
        today
      );

    const effectiveRate =
      ads.adBoostActive
        ? rate +
          AD_HASH_RATE_BONUS
        : rate;

    const balance =
      nonNegative(
        data.miningBalance
      );

    const estimatedTotal =
      Math.max(
        0,
        balance +
          current.unclaimedMining
      );

    const miningPerHour =
      rate *
      MINING_PER_HASH_PER_HOUR;

    const activeMiningPerHour =
      effectiveRate *
      MINING_PER_HASH_RATE_PER_HOUR;

    const nextRate =
      nextDailyHashRate(
        data,
        today
      );

    const nextStreak =
      nextDailyStreak(
        data,
        today
      );

    return {
      success: true,

      message:
        status.miningActive
          ? "🐱⛏️ Stella louhii STL:ää!"
          : status.miningFinished
            ? "🐱✨ Louhinta on valmis kerättäväksi!"
            : "🐱 Stella odottaa seuraavaa louhintaa.",

      hashRate: rate,

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
          ? window.miningStartedAt
              .toISOString()
          : null,

      miningEndsAt:
        window.valid
          ? window.miningEndsAt
              .toISOString()
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

    if (
      error instanceof HttpsError
    ) {
      throw error;
    }

    throw new HttpsError(
      "internal",
      "Mining Status -tietojen lataaminen epäonnistui."
    );
  }
}

);

// ============================================================
// CLAIM / START MINING
// ============================================================

const claimMining =
onCall(
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

    const uid =
      request.auth.uid;

    const userRef =
      getUserRef(uid);

    const requestedTransactionId =
      typeof request.data
        ?.adMobTransactionId ===
      "string"
        ? request.data.adMobTransactionId.trim()
        : "";

    const earlyNow =
      new Date();

    const earlyNowMs =
      earlyNow.getTime();

    const earlySnapshot =
      await userRef.get();

    const earlyData =
      earlySnapshot.exists
        ? earlySnapshot.data() || {}
        : {};

    const earlyWindow =
      miningWindow(
        earlyData
      );

    const earlyRate =
      earlyWindow.valid
        ? historicalHashRate(
            earlyData
          )
        : miningHashRate(
            earlyData,
            dailyHashRate(
              dailyStreak(
                earlyData
              ) || 1
            )
          );

    const earlyStatus =
      calculateMiningStatus(
        {
          ...earlyData,
          hashRate:
            earlyRate,
        },
        earlyNow
      );

    if (
      earlyStatus.miningActive
    ) {
      const current =
        await currentUnclaimedMining(
          uid,
          earlyData,
          earlyNowMs
        );

      const today =
        getUtcDateString(
          earlyNow
        );

      const daily =
        nextDailyClaim(
          earlyData,
          today
        );

      return {
        success: true,

        started: false,

        collected: 0,

        miningActive: true,

        hashRate:
          earlyRate,

        miningHashRate:
          earlyRate,

        miningDay:
          daily.streak,

        dailyHashRate:
          daily.dailyHashRate,

        dailyHashRateBonus:
          dailyHashRateBonus(
            daily.streak
          ),

        dailyStreak:
          daily.streak,

        streak:
          daily.streak,

        nextDailyHashRate:
          nextDailyHashRate(
            earlyData,
            today
          ),

        nextDailyStreak:
          nextDailyStreak(
            earlyData,
            today
          ),

        unclaimedMining:
          current.unclaimedMining,

        baseMining:
          current.baseMining,

        adBoostMining:
          current.adBoostMining,

        boostMilliseconds:
          current.boostMilliseconds,

        miningRemainingMs:
          Math.max(
            0,
            number(
              earlyStatus
                .miningRemainingMs
            )
          ),

        rewardConsumed:
          false,

        adRewardTransactionId:
          requestedTransactionId ||
          null,

        message:
          requestedTransactionId
            ? "🐱⛏️ Stella louhii jo STL:ää. Uutta Mining Start -palkintoa ei kulutettu."
            : "🐱⛏️ Stella louhii jo STL:ää.",
      };
    }

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

    const transactionId =
      typeof verified?.transactionId ===
      "string"
        ? verified.transactionId.trim()
        : "";

    if (!transactionId) {
      throw new HttpsError(
        "failed-precondition",
        "🐱 AdMob Mining Start -tapahtuman transaction ID puuttuu."
      );
    }

    const rewardRef =
      getAdMobRewardRef(
        transactionId
      );

    if (!rewardRef) {
      throw new HttpsError(
        "failed-precondition",
        "🐱 AdMob-tapahtuman tunnistaminen epäonnistui."
      );
    }

    return await db.runTransaction(
      async (transaction) => {
        const now =
          new Date();

        const nowMs =
          now.getTime();

        const today =
          getUtcDateString(now);

        const userSnapshot =
          await transaction.get(
            userRef
          );

        const rewardSnapshot =
          await transaction.get(
            rewardRef
          );

        const data =
          userSnapshot.exists
            ? userSnapshot.data() || {}
            : {};

        const currentStreak =
          dailyStreak(data);

        const fallbackRate =
          dailyHashRate(
            currentStreak || 1
          );

        const previous =
          miningWindow(data);

        const existingRate =
          previous.valid
            ? historicalHashRate(data)
            : miningHashRate(
                data,
                fallbackRate
              );

        const status =
          calculateMiningStatus(
            {
              ...data,
              hashRate:
                existingRate,
            },
            now
          );

        if (
          status.miningActive
        ) {
          const current =
            await currentUnclaimedMining(
              uid,
              data,
              nowMs,
              transaction
            );

          const daily =
            nextDailyClaim(
              data,
              today
            );

          return {
            success: true,

            started: false,

            collected: 0,

            miningActive: true,

            hashRate:
              existingRate,

            miningHashRate:
              existingRate,

            miningDay:
              daily.streak,

            dailyHashRate:
              daily.dailyHashRate,

            dailyHashRateBonus:
              dailyHashRateBonus(
                daily.streak
              ),

            dailyStreak:
              daily.streak,

            streak:
              daily.streak,

            nextDailyHashRate:
              nextDailyHashRate(
                data,
                today
              ),

            nextDailyStreak:
              nextDailyStreak(
                data,
                today
              ),

            unclaimedMining:
              current.unclaimedMining,

            baseMining:
              current.baseMining,

            adBoostMining:
              current.adBoostMining,

            boostMilliseconds:
              current.boostMilliseconds,

            miningRemainingMs:
              Math.max(
                0,
                number(
                  status.miningRemainingMs
                )
              ),

            rewardConsumed:
              false,

            adRewardTransactionId:
              transactionId,

            message:
              "🐱⛏️ Stella louhii jo STL:ää. Mainospalkintoa ei kulutettu.",
          };
        }

        let validated;

        try {
          validated =
            validateVerifiedRewardDocument(
              rewardSnapshot,
              uid,
              "mining_start",
              "miningStartClaimed",
              {
                referenceNowMs:
                  nowMs,

                transactionId,
              }
            );
        } catch (error) {
          throw toRewardHttpsError(
            error,
            "🐱 AdMob Mining Start -palkinnon vahvistaminen epäonnistui."
          );
        }

        const authoritativeId =
          validated.transactionId;

        const daily =
          nextDailyClaim(
            data,
            today
          );

        const rate =
          daily.dailyHashRate;

        const oldBalance =
          nonNegative(
            data.miningBalance
          );

        let newBalance =
          oldBalance;

        let collected = 0;

        let previousBase = 0;
        let previousBoost = 0;
        let previousBoostMs = 0;
        let completedPrevious = false;

        // ------------------------------------------------
        // COMPLETE PREVIOUS MINING CYCLE
        // ------------------------------------------------

        if (
          previous.valid &&
          previous.miningEndMs <=
            nowMs
        ) {
          const previousRate =
            historicalHashRate(
              data
            );

          if (
            previousRate <= 0
          ) {
            throw new HttpsError(
              "failed-precondition",
              "🐱 Edellisen mining-cyclen Hash Rate on virheellinen."
            );
          }

          const cycle =
            await calculateMiningCycle(
              uid,
              previous.miningStartMs,
              previous.miningEndMs,
              previousRate,
              transaction
            );

          previousBase =
            cycle.baseMining;

          previousBoost =
            cycle.adBoostMining;

          previousBoostMs =
            cycle.boostMilliseconds;

          collected =
            Math.max(
              0,
              cycle.totalMining
            );

          if (
            collected > 0
          ) {
            newBalance =
              oldBalance +
              collected;

            completedPrevious =
              true;
          }
        }

        // ------------------------------------------------
        // 🏆 ACHIEVEMENTS - READ PHASE
        // ------------------------------------------------

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

        const achievementReward =
          Math.max(
            0,
            number(
              achievementResult
                .totalReward
            )
          );

        // ------------------------------------------------
        // 🔗 REFERRAL REWARD
        // ------------------------------------------------

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
            getHistoryCollection(uid)
              .doc()
              .id;

          referralResult =
            await processReferralMiningReward(
              uid,
              collected,
              miningTransactionId,
              transaction
            );
        }

        // ------------------------------------------------
        // ACHIEVEMENT WRITE PHASE
        // ------------------------------------------------

        writeMiningAchievements(
          transaction,
          achievementResult
        );

        // ------------------------------------------------
        // ACHIEVEMENT REWARDS
        // ------------------------------------------------

        if (
          achievementReward > 0
        ) {
          newBalance +=
            achievementReward;

          for (
            const reward
            of achievementResult.rewards
          ) {
            transaction.set(
              getHistoryCollection(uid)
                .doc(),
              {
                type:
                  "achievement_reward",

                title:
                  "Stella Achievement Reward 🐱🏆✨",

                achievementId:
                  reward.achievementId,

                amount:
                  reward.reward,

                balanceAfter:
                  newBalance,

                reward:
                  reward.reward,

                createdAt:
                  FieldValue.serverTimestamp(),
              }
            );
          }
        }

        // ------------------------------------------------
        // NEW MINING CYCLE
        // ------------------------------------------------

        const startedAt =
          now;

        const endsAt =
          new Date(
            nowMs +
              MINING_DURATION_MS
          );

        transaction.set(
          userRef,
          {
            hashRate:
              rate,

            dailyStreak:
              daily.streak,

            streak:
              daily.streak,

            lastDailyDate:
              today,

            miningHashRate:
              rate,

            miningBalance:
              newBalance,

            miningStartedAt:
              startedAt,

            miningEndsAt:
              endsAt,

            miningCycles:
              achievementResult
                .miningCycles,

            dailyCheckIns:
              achievementResult
                .dailyCheckIns,

            adBoostStartedAt:
              null,

            adBoostEndsAt:
              null,

            powerBoostTransactionId:
              null,

            updatedAt:
              FieldValue.serverTimestamp(),
          },
          {
            merge: true,
          }
        );

        // ------------------------------------------------
        // CONSUME ADMOB MINING START REWARD
        // ------------------------------------------------

        transaction.set(
          rewardRef,
          {
            miningClaimed:
              true,

            miningClaimedAt:
              FieldValue.serverTimestamp(),

            miningStartClaimed:
              true,

            miningStartClaimedAt:
              FieldValue.serverTimestamp(),

            miningStartClaimedBy:
              uid,

            consumedAt:
              FieldValue.serverTimestamp(),

            consumedBy:
              uid,

            rewardConsumed:
              true,
          },
          {
            merge: true,
          }
        );

        // ------------------------------------------------
        // DAILY HASH RATE HISTORY
        // ------------------------------------------------

        if (
          !daily.claimedToday
        ) {
          transaction.set(
            getHistoryCollection(uid)
              .doc(),
            {
              type:
                "dailyHashRate",

              title:
                "Stella Daily Hash Rate 🐱✨",

              amount:
                rate,

              hashRate:
                rate,

              dailyHashRate:
                rate,

              hashRateBefore:
                historicalHashRate(
                  data
                ),

              hashRateAfter:
                rate,

              dailyHashRateBonus:
                dailyHashRateBonus(
                  daily.streak
                ),

              dailyStreak:
                daily.streak,

              streak:
                daily.streak,

              miningDay:
                daily.streak,

              previousDailyDate:
                typeof data.lastDailyDate ===
                "string"
                  ? data.lastDailyDate
                  : null,

              currentDailyDate:
                today,

              createdAt:
                FieldValue.serverTimestamp(),
            }
          );
        }

        // ------------------------------------------------
        // PREVIOUS MINING REWARD
        // ------------------------------------------------

        if (
          completedPrevious
        ) {
          transaction.set(
            getHistoryCollection(uid)
              .doc(
                miningTransactionId
              ),
            {
              type:
                "mining_reward",

              title:
                "Stella Mining Complete 🐱⛏️✨",

              amount:
                collected,

              balanceAfter:
                newBalance,

              hashRate:
                historicalHashRate(
                  data
                ),

              miningHashRate:
                historicalHashRate(
                  data
                ),

              baseMining:
                previousBase,

              adBoostMining:
                previousBoost,

              boostMilliseconds:
                previousBoostMs,

              miningStartedAt:
                previous.miningStartedAt,

              miningEndsAt:
                previous.miningEndsAt,

              miningTransactionId:
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

        // ------------------------------------------------
        // NEW MINING HISTORY
        // ------------------------------------------------

        transaction.set(
          getHistoryCollection(uid)
            .doc(),
          {
            type:
              "mining",

            title:
              "Stella Mining Started 🐱⛏️",

            amount: 0,

            hashRate:
              rate,

            miningHashRate:
              rate,

            dailyHashRate:
              rate,

            dailyHashRateBonus:
              dailyHashRateBonus(
                daily.streak
              ),

            dailyStreak:
              daily.streak,

            streak:
              daily.streak,

            miningDay:
              daily.streak,

            miningDurationMs:
              MINING_DURATION_MS,

            miningStartedAt:
              startedAt,

            miningEndsAt:
              endsAt,

            adRewardTransactionId:
              authoritativeId,

            rewardPurpose:
              "mining_start",

            createdAt:
              FieldValue.serverTimestamp(),
          }
        );

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
            referralResult.referrerUid ||
            null,

          referralBonusPercent:
            referralResult.bonusPercent ||
            0,

          referralBonusRate:
            referralResult.bonusRate ||
            0,

          completedPreviousCycle:
            completedPrevious,

          miningBalance:
            newBalance,

          hashRate:
            rate,

          miningDay:
            daily.streak,

          dailyHashRate:
            rate,

          dailyHashRateBonus:
            dailyHashRateBonus(
              daily.streak
            ),

          dailyStreak:
            daily.streak,

          streak:
            daily.streak,

          nextDailyHashRate:
            nextDailyHashRate(
              data,
              today
            ),

          nextDailyStreak:
            nextDailyStreak(
              data,
              today
            ),

          miningHashRate:
            rate,

          miningDurationMs:
            MINING_DURATION_MS,

          miningRemainingMs:
            MINING_DURATION_MS,

          miningStartedAt:
            startedAt.toISOString(),

          miningEndsAt:
            endsAt.toISOString(),

          adBoostActive:
            false,

          adBoostRemainingMs:
            0,

          adHashRateBonus:
            AD_HASH_RATE_BONUS,

          effectiveHashRate:
            rate,

          adRewardTransactionId:
            authoritativeId,

          rewardConsumed:
            true,

          message:
            referralResult.rewarded
              ? `🐱🔗✨ Referral-bonus ${referralResult.bonus.toFixed(4)} STL maksettiin kutsujalle.`
              : achievementReward > 0
                ? `🐱🏆✨ Stella avasi achievement-palkinnon! +${achievementReward} STL.`
                : completedPrevious
                  ? `🐱✨ Stella keräsi STL:t ja aloitti uuden louhinnan! Päivä ${daily.streak}, Hash Rate: ${rate.toFixed(4)} HR.`
                  : `🐱✨ Stella aloitti louhinnan! Päivä ${daily.streak}, Hash Rate: ${rate.toFixed(4)} HR.`,
        };
      }
    );
  } catch (error) {
    console.error(
      "claimMining error:",
      error
    );

    if (
      error instanceof HttpsError
    ) {
      throw error;
    }

    throw new HttpsError(
      "internal",
      "🐱 Stella Miningin käynnistäminen epäonnistui."
    );
  }
}

);

// ============================================================
// POWER BOOST
// ============================================================

const powerBoost =
onCall(
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

    const uid =
      request.auth.uid;

    const userRef =
      getUserRef(uid);

    const requestedTransactionId =
      typeof request.data
        ?.adMobTransactionId ===
      "string"
        ? request.data.adMobTransactionId.trim()
        : "";

    const earlyNow =
      new Date();

    const earlyNowMs =
      earlyNow.getTime();

    const earlyToday =
      getUtcDateString(
        earlyNow
      );

    const earlySnapshot =
      await userRef.get();

    const earlyData =
      earlySnapshot.exists
        ? earlySnapshot.data() || {}
        : {};

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

    const earlyRate =
      historicalHashRate(
        earlyData
      );

    if (
      earlyRate <= 0
    ) {
      throw new HttpsError(
        "failed-precondition",
        "🐱⚡ Nykyisen louhintasyklin Hash Rate ei ole kelvollinen."
      );
    }

    const earlyAds =
      adStatus(
        earlyData,
        earlyNowMs,
        earlyToday
      );

    if (
      earlyAds.adsToday >=
      MAX_ADS_PER_DAY
    ) {
      throw new HttpsError(
        "resource-exhausted",
        "🐱 Päivän Power Boost -mainosraja on täynnä."
      );
    }

    if (
      earlyAds.adBoostActive
    ) {
      throw new HttpsError(
        "failed-precondition",
        "🐱 Power Boost on jo aktiivinen."
      );
    }

    if (
      earlyAds.cooldownRemainingMs >
      0
    ) {
      throw new HttpsError(
        "failed-precondition",
        "🐱 Power Boost ei ole vielä valmis käytettäväksi uudelleen."
      );
    }

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

    const transactionId =
      typeof verified?.transactionId ===
      "string"
        ? verified.transactionId.trim()
        : "";

    if (!transactionId) {
      throw new HttpsError(
        "failed-precondition",
        "🐱 Power Boost -tapahtuman transaction ID puuttuu."
      );
    }

    const rewardRef =
      getAdMobRewardRef(
        transactionId
      );

    if (!rewardRef) {
      throw new HttpsError(
        "failed-precondition",
        "🐱 Power Boost -AdMob-tapahtuman tunnistaminen epäonnistui."
      );
    }

    return await db.runTransaction(
      async (transaction) => {
        const now =
          new Date();

        const nowMs =
          now.getTime();

        const today =
          getUtcDateString(now);

        const userSnapshot =
          await transaction.get(
            userRef
          );

        const rewardSnapshot =
          await transaction.get(
            rewardRef
          );

        const data =
          userSnapshot.exists
            ? userSnapshot.data() || {}
            : {};

        const window =
          miningWindow(data);

        if (
          !window.valid ||
          nowMs <
            window.miningStartMs ||
          nowMs >=
            window.miningEndMs
        ) {
          throw new HttpsError(
            "failed-precondition",
            "🐱⚡ Power Boostia voi käyttää vain aktiivisen louhinnan aikana."
          );
        }

        const rate =
          historicalHashRate(data);

        if (rate <= 0) {
          throw new HttpsError(
            "failed-precondition",
            "🐱⚡ Nykyisen louhintasyklin Hash Rate ei ole kelvollinen."
          );
        }

        const status =
          calculateMiningStatus(
            {
              ...data,
              hashRate: rate,
            },
            now
          );

        if (
          !status.miningActive
        ) {
          throw new HttpsError(
            "failed-precondition",
            "🐱⚡ Stella Mining ei ole enää aktiivinen."
          );
        }

        let validated;

        try {
          validated =
            validateVerifiedRewardDocument(
              rewardSnapshot,
              uid,
              "power_boost",
              "powerBoostClaimed",
              {
                referenceNowMs:
                  nowMs,

                transactionId,
              }
            );
        } catch (error) {
          throw toRewardHttpsError(
            error,
            "🐱 Power Boost -AdMob-palkinnon vahvistaminen epäonnistui."
          );
        }

        const authoritativeId =
          validated.transactionId;

        const currentAds =
          adStatus(
            data,
            nowMs,
            today
          );

        if (
          currentAds.adsToday >=
          MAX_ADS_PER_DAY
        ) {
          throw new HttpsError(
            "resource-exhausted",
            "🐱 Päivän Power Boost -mainosraja on täynnä."
          );
        }

        if (
          currentAds.adBoostActive
        ) {
          throw new HttpsError(
            "failed-precondition",
            "🐱 Power Boost on jo aktiivinen."
          );
        }

        if (
          currentAds.cooldownRemainingMs >
          0
        ) {
          throw new HttpsError(
            "failed-precondition",
            "🐱 Power Boost ei ole vielä valmis käytettäväksi uudelleen."
          );
        }

        // ------------------------------------------------
        // 🏆 POWER BOOST ACHIEVEMENTS - READ PHASE
        // ------------------------------------------------

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
              powerBoostAchievementResult
                .totalReward
            )
          );

        const oldBalance =
          nonNegative(
            data.miningBalance
          );

        const newBalance =
          oldBalance +
          powerBoostAchievementReward;

        // ------------------------------------------------
        // POWER BOOST
        // ------------------------------------------------

        const boostStartedAt =
          now;

        const actualEndMs =
          Math.min(
            nowMs +
              AD_BOOST_DURATION_MS,
            window.miningEndMs
          );

        const boostEndsAt =
          new Date(actualEndMs);

        const durationMs =
          Math.max(
            0,
            actualEndMs -
              nowMs
          );

        if (
          durationMs <= 0
        ) {
          throw new HttpsError(
            "failed-precondition",
            "🐱⚡ Louhintaa ei ole enää tarpeeksi jäljellä Power Boostia varten."
          );
        }

        const storedDate =
          typeof data.lastAdDate ===
          "string"
            ? data.lastAdDate
            : "";

        const oldAds =
          storedDate === today
            ? Math.max(
                0,
                Math.floor(
                  number(
                    data.adsToday
                  )
                )
              )
            : 0;

        const newAdsToday =
          oldAds + 1;

        // ------------------------------------------------
        // USER UPDATE
        // ------------------------------------------------

        transaction.set(
          userRef,
          {
            miningBalance:
              newBalance,

            powerBoostCount:
              powerBoostAchievementResult
                .powerBoostCount,

            adsToday:
              newAdsToday,

            lastAdDate:
              today,

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

        // ------------------------------------------------
        // ACHIEVEMENT WRITE PHASE
        // ------------------------------------------------

        writeMiningAchievements(
          transaction,
          powerBoostAchievementResult
        );

        // ------------------------------------------------
        // ACHIEVEMENT REWARDS
        // ------------------------------------------------

        if (
          powerBoostAchievementReward > 0
        ) {
          for (
            const reward
            of powerBoostAchievementResult
              .rewards
          ) {
            transaction.set(
              getHistoryCollection(uid)
                .doc(),
              {
                type:
                  "achievement_reward",

                title:
                  "Stella Achievement Reward 🐱🏆✨",

                achievementId:
                  reward.achievementId,

                amount:
                  reward.reward,

                balanceAfter:
                  newBalance,

                reward:
                  reward.reward,

                createdAt:
                  FieldValue.serverTimestamp(),
              }
            );
          }
        }

        // ------------------------------------------------
        // ADMOB REWARD
        // ------------------------------------------------

        transaction.set(
          rewardSnapshot.ref,
          {
            powerBoostClaimed:
              true,

            powerBoostClaimedAt:
              FieldValue.serverTimestamp(),

            powerBoostClaimedBy:
              uid,

            powerBoostTransactionId:
              authoritativeId,

            consumedAt:
              FieldValue.serverTimestamp(),

            consumedBy:
              uid,

            rewardConsumed:
              true,
          },
          {
            merge: true,
          }
        );

        // ------------------------------------------------
        // POWER BOOST HISTORY
        // ------------------------------------------------

        transaction.set(
          getHistoryCollection(uid)
            .doc(),
          {
            type:
              "ad_reward",

            title:
              "Stella Power Boost 🐱⚡",

            amount: 0,

            adRewardTransactionId:
              authoritativeId,

            rewardPurpose:
              "power_boost",

            adHashRateBonus:
              AD_HASH_RATE_BONUS,

            boostStartedAt,

            boostEndsAt,

            boostDurationMs:
              durationMs,

            miningStartedAt:
              window.miningStartedAt,

            miningEndsAt:
              window.miningEndsAt,

            miningHashRate:
              rate,

            adsToday:
              newAdsToday,

            maxAdsPerDay:
              MAX_ADS_PER_DAY,

            createdAt:
              FieldValue.serverTimestamp(),
          }
        );

        const daily =
          nextDailyClaim(
            data,
            today
          );

        return {
          success: true,

          boostActive: true,

          active: true,

          alreadyActivated:
            false,

          adsToday:
            newAdsToday,

          maxAdsPerDay:
            MAX_ADS_PER_DAY,

          adHashRateBonus:
            AD_HASH_RATE_BONUS,

          boostRemainingMs:
            durationMs,

          remainingBoostMs:
            durationMs,

          adBoostDurationMs:
            durationMs,

          configuredBoostDurationMs:
            AD_BOOST_DURATION_MS,

          adBoostStartedAt:
            boostStartedAt.toISOString(),

          adBoostEndsAt:
            boostEndsAt.toISOString(),

          miningStartedAt:
            window.miningStartedAt
              .toISOString(),

          miningEndsAt:
            window.miningEndsAt
              .toISOString(),

          miningHashRate:
            rate,

          effectiveHashRate:
            rate +
            AD_HASH_RATE_BONUS,

          miningDay:
            daily.streak,

          dailyHashRate:
            daily.dailyHashRate,

          dailyHashRateBonus:
            dailyHashRateBonus(
              daily.streak
            ),

          dailyStreak:
            daily.streak,

          streak:
            daily.streak,

          nextDailyHashRate:
            nextDailyHashRate(
              data,
              today
            ),

          nextDailyStreak:
            nextDailyStreak(
              data,
              today
            ),

          transactionId:
            authoritativeId,

          rewardConsumed:
            true,

          achievementReward:
            powerBoostAchievementReward,

          achievementRewards:
            powerBoostAchievementResult
              .rewards,

          miningBalance:
            newBalance,

          powerBoostCount:
            powerBoostAchievementResult
              .powerBoostCount,

          message:
            durationMs <
            AD_BOOST_DURATION_MS
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

    if (
      error instanceof HttpsError
    ) {
      throw error;
    }

    throw new HttpsError(
      "internal",
      "🐱 Power Boostin aktivointi epäonnistui."
    );
  }
}

);

// ============================================================
// EXPORTS
// ============================================================

module.exports = {
getMiningStatus,
claimMining,
powerBoost,
};