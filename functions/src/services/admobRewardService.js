"use strict";

// ============================================================
// 🐱 STELLURIINI - ADMOB REWARD SERVICE
// ============================================================
//
// Vastuu:
//
// 🔐 AdMob SSV reward -validointi
// 🔑 transaction_id -validointi
// 🕒 reward timestamp -validointi
// 🔎 verifioidyn rewardin haku
// ⏳ SSV rewardin odottaminen
//
// AdMob reward EI ole STL-token reward.
//
// AdMob ainoastaan valtuuttaa:
// - Mining Start
// - Power Boost
//
// Tämä tiedosto ei muuta mining-balancea.
// Tämä tiedosto ei kirjoita mining-tilaa.
// ============================================================

const {
db,
} = require("../firebase/firebase");

const {
ADMOB_MINING_AD_UNIT_ID,
ADMOB_POWER_BOOST_AD_UNIT_ID,

ADMOB_MINING_SSV_AD_UNIT_ID,
ADMOB_POWER_BOOST_SSV_AD_UNIT_ID,

ADMOB_MINING_SSV_REWARD_AMOUNT,
ADMOB_MINING_SSV_REWARD_ITEM,

ADMOB_POWER_BOOST_SSV_REWARD_AMOUNT,
ADMOB_POWER_BOOST_SSV_REWARD_ITEM,
} = require("../config/miningConfig");

// ============================================================
// 🔐 TIMING
// ============================================================

const ADMOB_REWARD_REQUEST_GRACE_MS =
5 * 60 * 1000;

const ADMOB_REWARD_MAX_AGE_MS =
15 * 60 * 1000;

const ADMOB_REWARD_FUTURE_TOLERANCE_MS =
2 * 60 * 1000;

const ADMOB_REWARD_QUERY_LIMIT =
100;

const ADMOB_SSV_WAIT_TIMEOUT_MS =
90 * 1000;

const ADMOB_SSV_POLL_INTERVAL_MS =
2 * 1000;

// ============================================================
// 🔢 SAFE NUMBERS
// ============================================================

function getSafeNumber(
value,
fallback = 0
) {
const number = Number(value);

return Number.isFinite(number)
? number
: fallback;
}

function getSafeNonNegativeNumber(
value,
fallback = 0
) {
const number = Number(value);

return Number.isFinite(number) &&
number >= 0
? number
: fallback;
}

function getSafePositiveNumber(
value,
fallback = 0
) {
const number = Number(value);

return Number.isFinite(number) &&
number > 0
? number
: fallback;
}

// ============================================================
// 🕒 TIMESTAMP
// ============================================================

function getTimestampMilliseconds(
value
) {
if (!value) {
return 0;
}

if (
typeof value.toDate ===
"function"
) {
try {
const date =
value.toDate();

  return date instanceof Date &&
    Number.isFinite(
      date.getTime()
    )
    ? date.getTime()
    : 0;
} catch (_) {
  return 0;
}

}

if (
value instanceof Date
) {
return Number.isFinite(
value.getTime()
)
? value.getTime()
: 0;
}

if (
typeof value ===
"string"
) {
const date =
new Date(value);

return Number.isFinite(
  date.getTime()
)
  ? date.getTime()
  : 0;

}

if (
typeof value ===
"number" &&
Number.isFinite(value)
) {
return value;
}

return 0;
}

// ============================================================
// 🔑 TRANSACTION ID
// ============================================================

function validateAdMobTransactionId(
value
) {
if (
typeof value !==
"string"
) {
return "";
}

const transactionId =
value.trim();

if (
!transactionId ||
transactionId.length > 256
) {
return "";
}

// AdMob SSV transaction_id:
// unique hex encoded identifier.
if (
!/^[a-fA-F0-9]+$/.test(
transactionId
)
) {
return "";
}

return transactionId;
}

// ============================================================
// 🕒 REWARD TIMESTAMP
// ============================================================

function getRewardTimestampMs(
rewardData
) {
if (!rewardData) {
return 0;
}

const candidates = [
rewardData.timestamp,
rewardData.rewardedAt,
rewardData.receivedAt,
rewardData.createdAt,
];

for (
const value of candidates
) {
const timestamp =
getTimestampMilliseconds(
value
);

if (timestamp > 0) {
  return timestamp;
}

}

return 0;
}

// ============================================================
// 🕒 CREATED AT
// ============================================================

function getRewardCreatedAtMs(
rewardData
) {
if (!rewardData) {
return 0;
}

const candidates = [
rewardData.createdAt,
rewardData.receivedAt,
rewardData.timestamp,
rewardData.rewardedAt,
];

for (
const value of candidates
) {
const timestamp =
getTimestampMilliseconds(
value
);

if (timestamp > 0) {
  return timestamp;
}

}

return 0;
}

// ============================================================
// 🎁 REWARD CONFIGURATION
// ============================================================

function getRewardConfiguration(
rewardPurpose
) {
switch (
rewardPurpose
) {
case "mining_start":
return {
rewardedAdUnitId:
ADMOB_MINING_AD_UNIT_ID,

    // IMPORTANT:
    // AdMob SSV sends the numeric
    // ad unit ID, not the full
    // ca-app-pub-.../... value.
    ssvAdUnitId:
      ADMOB_MINING_SSV_AD_UNIT_ID,

    rewardAmount:
      ADMOB_MINING_SSV_REWARD_AMOUNT,

    rewardItem:
      ADMOB_MINING_SSV_REWARD_ITEM,
  };

case "power_boost":
  return {
    rewardedAdUnitId:
      ADMOB_POWER_BOOST_AD_UNIT_ID,

    // IMPORTANT:
    // AdMob SSV sends the numeric
    // ad unit ID, not the full
    // ca-app-pub-.../... value.
    ssvAdUnitId:
      ADMOB_POWER_BOOST_SSV_AD_UNIT_ID,

    rewardAmount:
      ADMOB_POWER_BOOST_SSV_REWARD_AMOUNT,

    rewardItem:
      ADMOB_POWER_BOOST_SSV_REWARD_ITEM,
  };

default:
  return null;

}
}

// ============================================================
// 🔑 REWARD TRANSACTION
// ============================================================

function validateRewardTransactionId(
rewardSnapshot
) {
if (
!rewardSnapshot ||
!rewardSnapshot.exists
) {
return "";
}

const transactionId =
validateAdMobTransactionId(
rewardSnapshot.id
);

if (!transactionId) {
return "";
}

const data =
rewardSnapshot.data() ||
{};

if (
data.transactionId !==
undefined &&
data.transactionId !==
null
) {
const stored =
validateAdMobTransactionId(
data.transactionId
);

if (
  !stored ||
  stored.toLowerCase() !==
    transactionId.toLowerCase()
) {
  return "";
}

}

return transactionId;
}

// ============================================================
// 🕒 TIMESTAMP VALIDATION
// ============================================================

function isRewardTimestampAcceptable(
rewardData,
referenceNowMs,
requestStartedAtMs
) {
const rewardTimestampMs =
getRewardTimestampMs(
rewardData
);

if (
rewardTimestampMs <= 0
) {
return false;
}

if (
rewardTimestampMs >
referenceNowMs +
ADMOB_REWARD_FUTURE_TOLERANCE_MS
) {
return false;
}

if (
referenceNowMs -
rewardTimestampMs >
ADMOB_REWARD_MAX_AGE_MS
) {
return false;
}

if (
requestStartedAtMs > 0 &&
rewardTimestampMs <
requestStartedAtMs -
ADMOB_REWARD_REQUEST_GRACE_MS
) {
return false;
}

return true;
}

// ============================================================
// 🔐 COMMON REWARD VALIDATION
// ============================================================

function validateReward(
rewardSnapshot,
uid,
rewardPurpose,
claimedField,
options = {}
) {
const configuration =
getRewardConfiguration(
rewardPurpose
);

if (
!configuration ||
!rewardSnapshot ||
!rewardSnapshot.exists
) {
return null;
}

if (
typeof uid !==
"string" ||
!uid.trim()
) {
return null;
}

const data =
rewardSnapshot.data() ||
{};

// ----------------------------------------------------------
// USER
// ----------------------------------------------------------

if (
data.uid !== uid
) {
return null;
}

if (
data.userId !==
undefined &&
data.userId !==
null &&
String(data.userId) !==
uid
) {
return null;
}

// ----------------------------------------------------------
// TYPE
// ----------------------------------------------------------

if (
data.rewardType !==
"admob"
) {
return null;
}

if (
data.rewardPurpose !==
rewardPurpose
) {
return null;
}

// ----------------------------------------------------------
// CONSUMPTION
// ----------------------------------------------------------

if (
data.rewardConsumed ===
true ||
data[claimedField] ===
true
) {
return null;
}

if (
rewardPurpose ===
"mining_start" &&
(
data.miningClaimed ===
true ||
data.miningStartClaimed ===
true ||
data.miningStartClaimedAt
)
) {
return null;
}

if (
rewardPurpose ===
"power_boost" &&
(
data.powerBoostClaimed ===
true ||
data.powerBoostClaimedAt
)
) {
return null;
}

// ----------------------------------------------------------
// AD UNIT
// ----------------------------------------------------------
//
// IMPORTANT:
//
// AdMob SSV callback:
//
// ad_unit=6674097787
//
// NOT:
//
// ad_unit=ca-app-pub-1131012057145658/6674097787
//
// Therefore the authoritative SSV value must match
// configuration.ssvAdUnitId exactly.
//
// ----------------------------------------------------------

if (
typeof data.adUnit !==
"string"
) {
return null;
}

const adUnit =
data.adUnit.trim();

if (
adUnit !==
String(
configuration.ssvAdUnitId
)
) {
return null;
}

// ----------------------------------------------------------
// REWARD ITEM
// ----------------------------------------------------------

if (
typeof data.rewardItem !==
"string"
) {
return null;
}

if (
data.rewardItem.trim() !==
String(
configuration.rewardItem
)
) {
return null;
}

// ----------------------------------------------------------
// REWARD AMOUNT
// ----------------------------------------------------------

const rewardAmount =
Number(
data.rewardAmount
);

if (
!Number.isFinite(
rewardAmount
) ||
rewardAmount !==
Number(
configuration.rewardAmount
)
) {
return null;
}

// ----------------------------------------------------------
// TRANSACTION
// ----------------------------------------------------------

const transactionId =
validateRewardTransactionId(
rewardSnapshot
);

if (!transactionId) {
return null;
}

// ----------------------------------------------------------
// TIMESTAMP
// ----------------------------------------------------------

const referenceNowMs =
getSafePositiveNumber(
options.referenceNowMs,
Date.now()
);

const requestStartedAtMs =
getSafeNonNegativeNumber(
options.requestStartedAtMs,
0
);

if (
!isRewardTimestampAcceptable(
data,
referenceNowMs,
requestStartedAtMs
)
) {
return null;
}

// ----------------------------------------------------------
// REQUESTED TRANSACTION
// ----------------------------------------------------------

const requestedTransactionId =
validateAdMobTransactionId(
options.transactionId
);

if (
requestedTransactionId &&
requestedTransactionId.toLowerCase() !==
transactionId.toLowerCase()
) {
return null;
}

return {
ref:
rewardSnapshot.ref,

data,

transactionId,

rewardTimestampMs:
  getRewardTimestampMs(
    data
  ),

createdAtMs:
  getRewardCreatedAtMs(
    data
  ),

};
}

// ============================================================
// 🔎 FIND VERIFIED REWARD
// ============================================================

async function findVerifiedAdMobReward(
uid,
rewardPurpose,
claimedField,
options = {}
) {
const configuration =
getRewardConfiguration(
rewardPurpose
);

if (!configuration) {
return null;
}

if (
typeof uid !==
"string" ||
!uid.trim()
) {
return null;
}

const referenceNowMs =
getSafePositiveNumber(
options.referenceNowMs,
Date.now()
);

const requestStartedAtMs =
getSafeNonNegativeNumber(
options.requestStartedAtMs,
0
);

const requestedTransactionId =
validateAdMobTransactionId(
options.transactionId
);

// ----------------------------------------------------------
// 🎯 EXACT TRANSACTION
// ----------------------------------------------------------

if (
requestedTransactionId
) {
const ref =
db
.collection(
"admobRewards"
)
.doc(
requestedTransactionId
);

const snapshot =
  await ref.get();

return validateReward(
  snapshot,
  uid,
  rewardPurpose,
  claimedField,
  {
    referenceNowMs,
    requestStartedAtMs,
    transactionId:
      requestedTransactionId,
  }
);

}

// ----------------------------------------------------------
// 🔎 DISCOVERY
// ----------------------------------------------------------

const snapshot =
await db
.collection(
"admobRewards"
)
.where(
"uid",
"==",
uid
)
.where(
"rewardPurpose",
"==",
rewardPurpose
)
.limit(
ADMOB_REWARD_QUERY_LIMIT
)
.get();

if (
snapshot.empty
) {
return null;
}

const candidates = [];

snapshot.forEach(
(document) => {
const reward =
validateReward(
document,
uid,
rewardPurpose,
claimedField,
{
referenceNowMs,
requestStartedAtMs,
}
);

  if (reward) {
    candidates.push(
      reward
    );
  }
}

);

if (
candidates.length ===
0
) {
return null;
}

candidates.sort(
(a, b) => {
if (
b.rewardTimestampMs !==
a.rewardTimestampMs
) {
return (
b.rewardTimestampMs -
a.rewardTimestampMs
);
}

  if (
    b.createdAtMs !==
    a.createdAtMs
  ) {
    return (
      b.createdAtMs -
      a.createdAtMs
    );
  }

  return (
    b.transactionId.localeCompare(
      a.transactionId
    )
  );
}

);

return candidates[0];
}

// ============================================================
// ⏳ WAIT FOR SSV
// ============================================================

function sleep(
milliseconds
) {
return new Promise(
(resolve) => {
setTimeout(
resolve,
milliseconds
);
}
);
}

async function waitForVerifiedAdMobReward(
uid,
rewardPurpose,
claimedField,
options = {}
) {
const startedAt =
Date.now();

const requestStartedAtMs =
getSafePositiveNumber(
options.requestStartedAtMs,
startedAt
);

const transactionId =
validateAdMobTransactionId(
options.transactionId
);

while (
Date.now() -
startedAt <
ADMOB_SSV_WAIT_TIMEOUT_MS
) {
const nowMs =
Date.now();

const reward =
  await findVerifiedAdMobReward(
    uid,
    rewardPurpose,
    claimedField,
    {
      referenceNowMs:
        nowMs,

      requestStartedAtMs,

      transactionId,
    }
  );

if (reward) {
  console.log(
    "🐱 AdMob SSV reward verified",
    {
      uid,
      rewardPurpose,
      transactionId:
        reward.transactionId,
    }
  );

  return reward;
}

await sleep(
  ADMOB_SSV_POLL_INTERVAL_MS
);

}

throw new Error(
rewardPurpose ===
"mining_start"
? "🐱 AdMob-mainoksen SSV-vahvistusta ei löytynyt ajoissa."
: "🐱 Power Boost -mainoksen SSV-vahvistusta ei löytynyt ajoissa."
);
}

// ============================================================
// 🔐 AUTHORITATIVE TRANSACTION VALIDATION
// ============================================================

function validateVerifiedRewardDocument(
rewardSnapshot,
uid,
rewardPurpose,
claimedField,
options = {}
) {
const reward =
validateReward(
rewardSnapshot,
uid,
rewardPurpose,
claimedField,
options
);

if (!reward) {
throw new Error(
"🐱 AdMob-palkinnon validointi epäonnistui."
);
}

return {
rewardData:
reward.data,

transactionId:
  reward.transactionId,

rewardTimestampMs:
  reward.rewardTimestampMs,

};
}

// ============================================================
// 🎁 MINING START
// ============================================================

async function getVerifiedMiningStartReward(
uid,
options = {}
) {
return waitForVerifiedAdMobReward(
uid,
"mining_start",
"miningStartClaimed",
options
);
}

// ============================================================
// ⚡ POWER BOOST
// ============================================================

async function getVerifiedPowerBoostReward(
uid,
options = {}
) {
return waitForVerifiedAdMobReward(
uid,
"power_boost",
"powerBoostClaimed",
options
);
}

// ============================================================
// 📦 EXPORTS
// ============================================================

module.exports = {
getSafeNumber,
getSafeNonNegativeNumber,
getSafePositiveNumber,

validateAdMobTransactionId,

getTimestampMilliseconds,
getRewardTimestampMs,
getRewardCreatedAtMs,

getRewardConfiguration,

validateRewardTransactionId,
isRewardTimestampAcceptable,

isValidRewardData: (
rewardSnapshot,
uid,
rewardPurpose,
claimedField,
options = {}
) =>
Boolean(
validateReward(
rewardSnapshot,
uid,
rewardPurpose,
claimedField,
options
)
),

findVerifiedAdMobReward,
waitForVerifiedAdMobReward,

validateVerifiedRewardDocument,

getVerifiedMiningStartReward,
getVerifiedPowerBoostReward,
};