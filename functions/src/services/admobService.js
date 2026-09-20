"use strict";

const crypto = require("crypto");

// ============================================================
// 🐱 STELLURIINI - ADMOB SERVICE
// ============================================================
//
// Vastuu:
//
// 🔐 AdMob Rewarded SSV -allekirjoituksen tarkistamisesta
// 🔑 AdMob public key -avainten lataamisesta ja välimuistista
// 🧩 SSV-parametrien lukemisesta
// 🛡️ Rewardin validoinnista
// 👤 UID:n validoinnista
// 🆔 Transaction ID:n validoinnista
//
// TÄMÄ TIEDOSTO EI:
//
// ❌ lisää STL-saldoa
// ❌ aktivoi Power Boostia
// ❌ käynnistä Mining Startia
// ❌ muuta adsToday-arvoa
// ❌ muuta cooldownia
// ❌ muuta mining-tilaa
// ❌ kirjoita Firestoreen
//
// ============================================================

// ============================================================
// ⚙️ MINING CONFIG
// ============================================================
//
// AdMob-asetukset pidetään keskitetysti
// miningConfig.js-tiedostossa.
//
// ============================================================

const {
ADMOB_MINING_SSV_AD_UNIT_ID,
ADMOB_POWER_BOOST_SSV_AD_UNIT_ID,

ADMOB_MINING_SSV_REWARD_AMOUNT,
ADMOB_MINING_SSV_REWARD_ITEM,

ADMOB_POWER_BOOST_SSV_REWARD_AMOUNT,
ADMOB_POWER_BOOST_SSV_REWARD_ITEM,
} = require(
"../config/miningConfig",
);

// ============================================================
// 🔐 ADMOB PUBLIC KEY URL
// ============================================================

const ADMOB_SSV_KEYS_URL =
"https://www.gstatic.com/admob/reward/verifier-keys.json";

// ============================================================
// ⏱️ PUBLIC KEY CACHE
// ============================================================
//
// AdMobin julkisia avaimia voidaan välimuistittaa.
//
// Cache on tarkoituksella alle 24 tuntia,
// jotta avainten rotaatio voidaan huomioida.
//
// ============================================================

const PUBLIC_KEY_CACHE_MS =
23 * 60 * 60 * 1000;

let cachedPublicKeys = null;
let cachedPublicKeysAt = 0;

// ============================================================
// 📺 ADMOB AD UNITS
// ============================================================
//
// AdMob SSV lähettää ad_unit-arvon ilman
// "ca-app-pub-..."-alkua.
//
// ============================================================

const ADMOB_AD_UNITS = {
mining_start:
ADMOB_MINING_SSV_AD_UNIT_ID,

power_boost:
ADMOB_POWER_BOOST_SSV_AD_UNIT_ID,
};

// ============================================================
// 🎁 EXPECTED REWARDS
// ============================================================
//
// Nämä ovat AdMobin reward metadata-arvot.
//
// NE EIVÄT OLE STL-TOKENIPALKINTOJA.
//
// Varsinainen Stelluriini-toiminto käsitellään
// erillisessä service/business-kerroksessa.
//
// ============================================================

const REWARD_DEFINITIONS = {
mining_start: {
rewardItem:
ADMOB_MINING_SSV_REWARD_ITEM,

rewardAmount:
  ADMOB_MINING_SSV_REWARD_AMOUNT,

},

power_boost: {
rewardItem:
ADMOB_POWER_BOOST_SSV_REWARD_ITEM,

rewardAmount:
  ADMOB_POWER_BOOST_SSV_REWARD_AMOUNT,

},
};

// ============================================================
// 🌐 FETCH JSON
// ============================================================

async function fetchJson(
url,
) {
let response;

try {
response =
await fetch(
url,
);
} catch (
error
) {
const fetchError =
new Error(
"Unable to fetch AdMob public keys: ${error.message}",
);

fetchError.code =
  "ADMOB_PUBLIC_KEY_FETCH_ERROR";

throw fetchError;

}

if (
!response.ok
) {
const error =
new Error(
"AdMob public key server returned HTTP ${response.status}.",
);

error.code =
  "ADMOB_PUBLIC_KEY_HTTP_ERROR";

throw error;

}

try {
return await response.json();
} catch (
error
) {
const jsonError =
new Error(
"AdMob public key response is not valid JSON: ${error.message}",
);

jsonError.code =
  "ADMOB_PUBLIC_KEY_JSON_ERROR";

throw jsonError;

}
}

// ============================================================
// 🔑 LOAD ADMOB PUBLIC KEYS
// ============================================================

async function getAdMobPublicKeys(
forceRefresh = false,
) {
const now =
Date.now();

if (
!forceRefresh &&
cachedPublicKeys &&
now - cachedPublicKeysAt <
PUBLIC_KEY_CACHE_MS
) {
return cachedPublicKeys;
}

const data =
await fetchJson(
ADMOB_SSV_KEYS_URL,
);

if (
!data ||
!Array.isArray(
data.keys,
)
) {
const error =
new Error(
"AdMob public key response is invalid.",
);

error.code =
  "ADMOB_PUBLIC_KEY_RESPONSE_INVALID";

throw error;

}

const keys =
new Map();

for (
const key of data.keys
) {
if (
key &&
key.keyId !== undefined &&
typeof key.pem ===
"string" &&
key.pem.trim().length > 0
) {
keys.set(
String(
key.keyId,
),
key.pem.trim(),
);
}
}

if (
keys.size === 0
) {
const error =
new Error(
"No usable AdMob public keys were returned.",
);

error.code =
  "ADMOB_PUBLIC_KEYS_EMPTY";

throw error;

}

cachedPublicKeys =
keys;

cachedPublicKeysAt =
now;

console.log(
"🐱 AdMob public keys loaded.",
{
count:
keys.size,

  keyIds:
    Array.from(
      keys.keys(),
    ),
},

);

return keys;
}

// ============================================================
// 🔎 EXTRACT QUERY STRING FROM URL
// ============================================================

function extractQueryStringFromUrl(
value,
) {
if (
typeof value !== "string" ||
value.length === 0
) {
return "";
}

const questionMark =
value.indexOf("?");

if (
questionMark < 0
) {
return "";
}

return value.substring(
questionMark + 1,
);
}

// ============================================================
// 🔎 GET RAW QUERY STRING
// ============================================================
//
// TÄRKEÄÄ:
//
// AdMob allekirjoittaa alkuperäisen query stringin.
//
// Siksi emme:
//
// ❌ järjestä parametreja uudelleen
// ❌ rakenna query stringiä uudelleen
// ❌ dekoodaa signed dataa ennen verifiointia
// ❌ käytä URLSearchParamsia signed datan
//    muodostamiseen
//
// URLSearchParamsia käytetään vasta
// allekirjoituksen onnistuneen tarkistamisen jälkeen.
//
// ============================================================

function getRawQueryString(
req,
) {
if (
!req
) {
const error =
new Error(
"Missing HTTP request.",
);

error.code =
  "ADMOB_REQUEST_MISSING";

throw error;

}

const candidates = [
req.rawUrl,
req.originalUrl,
req.url,
];

for (
const value of candidates
) {
const query =
extractQueryStringFromUrl(
value,
);

if (
  query.length > 0
) {
  return query;
}

}

if (
req._parsedUrl &&
typeof req._parsedUrl.search ===
"string"
) {
const search =
req._parsedUrl.search;

if (
  search.startsWith("?") &&
  search.length > 1
) {
  return search.substring(
    1,
  );
}

}

const error =
new Error(
"AdMob SSV query string is missing.",
);

error.code =
"ADMOB_QUERY_STRING_MISSING";

throw error;
}

// ============================================================
// 🔐 DECODE ADMOB BASE64URL SIGNATURE
// ============================================================

function decodeAdMobSignature(
signature,
) {
if (
typeof signature !==
"string" ||
signature.length === 0
) {
const error =
new Error(
"AdMob SSV signature is missing.",
);

error.code =
  "ADMOB_INVALID_SIGNATURE";

throw error;

}

const normalized =
signature
.replace(
/-/g,
"+",
)
.replace(
/_/g,
"/",
);

if (
normalized.length % 4 ===
1
) {
const error =
new Error(
"AdMob SSV signature has invalid Base64URL length.",
);

error.code =
  "ADMOB_INVALID_SIGNATURE";

throw error;

}

const remainder =
normalized.length % 4;

const padded =
remainder === 0
? normalized
: normalized +
"=".repeat(
4 - remainder,
);

if (
!/^[A-Za-z0-9+/]*={0,2}$/.test(
padded,
)
) {
const error =
new Error(
"AdMob SSV signature contains invalid Base64URL characters.",
);

error.code =
  "ADMOB_INVALID_SIGNATURE";

throw error;

}

const signatureBuffer =
Buffer.from(
padded,
"base64",
);

if (
signatureBuffer.length === 0
) {
const error =
new Error(
"AdMob SSV signature could not be decoded.",
);

error.code =
  "ADMOB_INVALID_SIGNATURE";

throw error;

}

return signatureBuffer;
}

// ============================================================
// 🔎 EXTRACT SIGNATURE DATA
// ============================================================
//
// AdMobin SSV callbackin kaksi viimeistä
// query-parametria ovat:
//
// signature
// key_id
//
// Tässä järjestyksessä.
//
// Allekirjoitettava data on kaikki
// ennen "&signature="-osaa.
//
// ============================================================

function extractSignatureData(
rawQueryString,
) {
if (
typeof rawQueryString !==
"string" ||
rawQueryString.length === 0
) {
const error =
new Error(
"AdMob SSV raw query string is missing.",
);

error.code =
  "ADMOB_QUERY_STRING_MISSING";

throw error;

}

const signatureMarker =
"&signature=";

const signatureIndex =
rawQueryString.indexOf(
signatureMarker,
);

if (
signatureIndex < 0
) {
const error =
new Error(
"AdMob SSV signature parameter was not found.",
);

error.code =
  "ADMOB_INVALID_SIGNATURE";

throw error;

}

const signedQueryString =
rawQueryString.substring(
0,
signatureIndex,
);

if (
signedQueryString.length === 0
) {
const error =
new Error(
"AdMob SSV signed query string is empty.",
);

error.code =
  "ADMOB_INVALID_SIGNATURE";

throw error;

}

const signatureAndKeyId =
rawQueryString.substring(
signatureIndex + 1,
);

const parts =
signatureAndKeyId.split(
"&",
);

if (
parts.length !== 2
) {
const error =
new Error(
"AdMob SSV signature and key_id must be the final two query parameters.",
);

error.code =
  "ADMOB_INVALID_SIGNATURE";

throw error;

}

if (
!parts[0].startsWith(
"signature=",
)
) {
const error =
new Error(
"AdMob SSV signature is not in the expected position.",
);

error.code =
  "ADMOB_INVALID_SIGNATURE";

throw error;

}

if (
!parts[1].startsWith(
"key_id=",
)
) {
const error =
new Error(
"AdMob SSV key_id is not in the expected position.",
);

error.code =
  "ADMOB_INVALID_SIGNATURE";

throw error;

}

let signature;
let keyId;

try {
signature =
decodeURIComponent(
parts[0].substring(
"signature=".length,
),
);

keyId =
  decodeURIComponent(
    parts[1].substring(
      "key_id=".length,
    ),
  );

} catch (
error
) {
const decodingError =
new Error(
"AdMob SSV signature/key_id URL decoding failed: ${error.message}",
);

decodingError.code =
  "ADMOB_INVALID_SIGNATURE";

throw decodingError;

}

if (
signature.length === 0
) {
const error =
new Error(
"AdMob SSV signature value is missing.",
);

error.code =
  "ADMOB_INVALID_SIGNATURE";

throw error;

}

if (
keyId.length === 0
) {
const error =
new Error(
"AdMob SSV key_id value is missing.",
);

error.code =
  "ADMOB_INVALID_KEY_ID";

throw error;

}

if (
!/^\d+$/.test(
keyId,
)
) {
const error =
new Error(
"AdMob SSV key_id is invalid.",
);

error.code =
  "ADMOB_INVALID_KEY_ID";

throw error;

}

return {
signedQueryString,

signature,

keyId,

};
}

// ============================================================
// 🔐 VERIFY RAW QUERY STRING
// ============================================================

async function verifyRawQueryString(
rawQueryString,
) {
const {
signedQueryString,
signature,
keyId,
} =
extractSignatureData(
rawQueryString,
);

const signatureBuffer =
decodeAdMobSignature(
signature,
);

let publicKeys =
await getAdMobPublicKeys(
false,
);

let publicKey =
publicKeys.get(
String(
keyId,
),
);

// ----------------------------------------------------------
// 🔄 KEY ROTATION FALLBACK
// ----------------------------------------------------------

if (
!publicKey
) {
console.log(
"🐱 AdMob key not found in cache. Refreshing public keys.",
{
keyId,
},
);

publicKeys =
  await getAdMobPublicKeys(
    true,
  );

publicKey =
  publicKeys.get(
    String(
      keyId,
    ),
  );

}

if (
!publicKey
) {
const error =
new Error(
"AdMob SSV public key not found for key_id=${keyId}",
);

error.code =
  "ADMOB_PUBLIC_KEY_NOT_FOUND";

error.keyId =
  keyId;

throw error;

}

// ----------------------------------------------------------
// 🔐 ECDSA / SHA-256
// ----------------------------------------------------------

let verified =
false;

try {
verified =
crypto.verify(
"sha256",

    Buffer.from(
      signedQueryString,
      "utf8",
    ),

    {
      key:
        publicKey,
    },

    signatureBuffer,
  );

} catch (
error
) {
const verificationError =
new Error(
"AdMob SSV cryptographic verification failed: ${error.message}",
);

verificationError.code =
  "ADMOB_CRYPTO_VERIFICATION_ERROR";

verificationError.keyId =
  keyId;

throw verificationError;

}

if (
!verified
) {
const error =
new Error(
"AdMob SSV signature verification failed.",
);

error.code =
  "ADMOB_INVALID_SIGNATURE";

error.keyId =
  keyId;

throw error;

}

console.log(
"🐱✅ AdMob ECDSA-SHA256 signature VERIFIED.",
{
keyId,
},
);

return {
verified:
true,

keyId,

signature,

rawQueryString,

signedQueryString,

params:
  new URLSearchParams(
    rawQueryString,
  ),

};
}

// ============================================================
// 🔐 VERIFY ADMOB SIGNATURE
// ============================================================

async function verifyAdMobSignature(
req,
) {
const rawQueryString =
getRawQueryString(
req,
);

console.log(
"🐱 AdMob SSV raw callback received.",
{
length:
rawQueryString.length,

  hasSignature:
    rawQueryString.includes(
      "&signature=",
    ),

  hasKeyId:
    rawQueryString.includes(
      "&key_id=",
    ),
},

);

try {
const verification =
await verifyRawQueryString(
rawQueryString,
);

console.log(
  "🐱✅ AdMob SSV signature VERIFIED.",
  {
    keyId:
      verification.keyId,
  },
);


return verification;

} catch (
error
) {

console.error(
  "🐱❌ AdMob SSV signature verification FAILED.",
  {
    code:
      error &&
      error.code
        ? error.code
        : "UNKNOWN",

    keyId:
      error &&
      error.keyId
        ? error.keyId
        : "",

    message:
      error &&
      error.message
        ? error.message
        : "Unknown AdMob SSV error.",
  },
);

throw error;

}
}

// ============================================================
// 🔎 PARAMETER HELPER
// ============================================================

function getParam(
params,
name,
) {
if (
!params ||
typeof params.get !==
"function"
) {
return "";
}

const value =
params.get(
name,
);

if (
value === null ||
value === undefined
) {
return "";
}

return String(
value,
);
}

// ============================================================
// 🔎 REQUIRED PARAMETER HELPER
// ============================================================

function requireParam(
params,
name,
) {
const value =
getParam(
params,
name,
);

if (
value.length === 0
) {
const error =
new Error(
"AdMob SSV required parameter "${name}" is missing.",
);

error.code =
  "ADMOB_REQUIRED_PARAMETER_MISSING";

error.parameter =
  name;

throw error;

}

return value;
}

// ============================================================
// 🔢 INTEGER HELPER
// ============================================================

function parseInteger(
value,
fallback = 0,
) {
const number =
Number(
value,
);

if (
!Number.isFinite(
number,
)
) {
return fallback;
}

return Math.trunc(
number,
);
}

// ============================================================
// 🛡️ UID VALIDATION
// ============================================================

function validateUid(
uid,
) {
if (
typeof uid !== "string"
) {
return false;
}

const trimmed =
uid.trim();

if (
trimmed.length === 0 ||
trimmed.length > 128
) {
return false;
}

return /^[A-Za-z0-9._-]+$/.test(
trimmed,
);
}

// ============================================================
// 🧩 CUSTOM DATA PARSER
// ============================================================
//
// custom_data:
//
//   UID:rewardPurpose
//
// Esimerkiksi:
//
//   abc123:mining_start
//   abc123:power_boost
//
// ============================================================

function parseCustomData(
customData,
) {
if (
typeof customData !==
"string"
) {
return {
uid:
"",

  rewardPurpose:
    "",
};

}

const value =
customData.trim();

// UID voi olla enintään 128 merkkiä.
// Lisäksi tarvitsemme ":" + reward purpose.
//
// 128 + 1 + 20 = turvallisesti alle 256.
//
if (
value.length === 0 ||
value.length > 256
) {
return {
uid:
"",

  rewardPurpose:
    "",
};

}

const separatorIndex =
value.lastIndexOf(
":",
);

if (
separatorIndex <= 0 ||
separatorIndex >=
value.length - 1
) {
return {
uid:
"",

  rewardPurpose:
    "",
};

}

const uid =
value
.substring(
0,
separatorIndex,
)
.trim();

const rewardPurpose =
value
.substring(
separatorIndex + 1,
)
.trim();

if (
!validateUid(
uid,
)
) {
return {
uid:
"",

  rewardPurpose:
    "",
};

}

if (
rewardPurpose !==
"mining_start" &&
rewardPurpose !==
"power_boost"
) {
return {
uid:
"",

  rewardPurpose:
    "",
};

}

return {
uid,

rewardPurpose,

};
}

// ============================================================
// 🔐 TRANSACTION ID VALIDATION
// ============================================================
//
// AdMob dokumentoi transaction_id:n
// hex-enkoodatuksi yksilölliseksi
// reward-tapahtuman tunnisteeksi.
//
// ============================================================

function validateTransactionId(
transactionId,
) {
if (
typeof transactionId !==
"string"
) {
return false;
}

const value =
transactionId.trim();

if (
value.length === 0 ||
value.length > 256
) {
return false;
}

return /^[a-fA-F0-9]+$/.test(
value,
);
}

// ============================================================
// ⏱️ TIMESTAMP VALIDATION
// ============================================================
//
// AdMob lähettää timestampin Epoch milliseconds
// -muodossa.
//
// Sallitaan:
//
// ⏪ enintään 24 h menneisyyteen
// ⏩ enintään 5 min tulevaisuuteen
//
// ============================================================

const TIMESTAMP_PAST_TOLERANCE_MS =
24 * 60 * 60 * 1000;

const TIMESTAMP_FUTURE_TOLERANCE_MS =
5 * 60 * 1000;

function validateTimestamp(
timestamp,
) {
const timestampMs =
Number(
timestamp,
);

if (
!Number.isFinite(
timestampMs,
) ||
timestampMs <= 0 ||
!Number.isInteger(
timestampMs,
)
) {
return {
valid:
false,

  timestampMs:
    0,
};

}

const now =
Date.now();

if (
timestampMs <
now -
TIMESTAMP_PAST_TOLERANCE_MS
) {
return {
valid:
false,

  timestampMs,
};

}

if (
timestampMs >
now +
TIMESTAMP_FUTURE_TOLERANCE_MS
) {
return {
valid:
false,

  timestampMs,
};

}

return {
valid:
true,

timestampMs,

};
}

// ============================================================
// 🔐 VERIFY ADMOB CALLBACK
// ============================================================

async function verifyAdMobCallback(
req,
) {
// ----------------------------------------------------------
// 1. CRYPTOGRAPHIC VERIFICATION
// ----------------------------------------------------------

const verification =
await verifyAdMobSignature(
req,
);

const params =
verification.params;

// ----------------------------------------------------------
// 2. REQUIRED PARAMETERS
// ----------------------------------------------------------

const adNetwork =
requireParam(
params,
"ad_network",
);

const adUnit =
requireParam(
params,
"ad_unit",
);

const customData =
requireParam(
params,
"custom_data",
);

const rewardAmount =
requireParam(
params,
"reward_amount",
);

const rewardItem =
requireParam(
params,
"reward_item",
);

const timestamp =
requireParam(
params,
"timestamp",
);

const transactionId =
requireParam(
params,
"transaction_id",
);

const userId =
getParam(
params,
"user_id",
);

// ----------------------------------------------------------
// 3. CUSTOM DATA
// ----------------------------------------------------------

const parsedCustomData =
parseCustomData(
customData,
);

const uid =
parsedCustomData.uid;

const rewardPurpose =
parsedCustomData.rewardPurpose;

// ----------------------------------------------------------
// 4. REWARD PURPOSE
// ----------------------------------------------------------

if (
rewardPurpose !==
"mining_start" &&
rewardPurpose !==
"power_boost"
) {
const error =
new Error(
"Invalid AdMob reward purpose: ${rewardPurpose}",
);

error.code =
  "ADMOB_INVALID_REWARD_PURPOSE";

throw error;

}

// ----------------------------------------------------------
// 5. UID
// ----------------------------------------------------------

if (
!validateUid(
uid,
)
) {
const error =
new Error(
"AdMob SSV custom_data does not contain a valid UID.",
);

error.code =
  "ADMOB_INVALID_UID";

throw error;

}

// ----------------------------------------------------------
// 6. AD UNIT
// ----------------------------------------------------------

const expectedAdUnit =
ADMOB_AD_UNITS[
rewardPurpose
];

if (
!expectedAdUnit
) {
const error =
new Error(
"No AdMob ad unit configured for ${rewardPurpose}.",
);

error.code =
  "ADMOB_INVALID_AD_UNIT";

throw error;

}

if (
adUnit !==
expectedAdUnit
) {
const error =
new Error(
"Invalid AdMob ad unit. Expected ${expectedAdUnit}, received ${adUnit}.",
);

error.code =
  "ADMOB_INVALID_AD_UNIT";

throw error;

}

// ----------------------------------------------------------
// 7. REWARD DEFINITION
// ----------------------------------------------------------

const rewardDefinition =
REWARD_DEFINITIONS[
rewardPurpose
];

if (
!rewardDefinition
) {
const error =
new Error(
"No reward definition configured for ${rewardPurpose}.",
);

error.code =
  "ADMOB_INVALID_REWARD_PURPOSE";

throw error;

}

// ----------------------------------------------------------
// 8. REWARD AMOUNT
// ----------------------------------------------------------

const parsedRewardAmount =
parseInteger(
rewardAmount,
-1,
);

if (
parsedRewardAmount !==
rewardDefinition.rewardAmount
) {
const error =
new Error(
"Invalid AdMob reward amount. Expected ${rewardDefinition.rewardAmount}, received ${rewardAmount}.",
);

error.code =
  "ADMOB_INVALID_REWARD_AMOUNT";

throw error;

}

// ----------------------------------------------------------
// 9. REWARD ITEM
// ----------------------------------------------------------

if (
rewardItem !==
rewardDefinition.rewardItem
) {
const error =
new Error(
"Invalid AdMob reward item. Expected "${rewardDefinition.rewardItem}", received "${rewardItem}".",
);

error.code =
  "ADMOB_INVALID_REWARD_ITEM";

throw error;

}

// ----------------------------------------------------------
// 10. TRANSACTION ID
// ----------------------------------------------------------

if (
!validateTransactionId(
transactionId,
)
) {
const error =
new Error(
"AdMob SSV transaction_id is missing or invalid.",
);

error.code =
  "ADMOB_INVALID_TRANSACTION_ID";

throw error;

}

// ----------------------------------------------------------
// 11. TIMESTAMP
// ----------------------------------------------------------

const timestampResult =
validateTimestamp(
timestamp,
);

if (
!timestampResult.valid
) {
const error =
new Error(
"AdMob timestamp is outside the accepted time window.",
);

error.code =
  "ADMOB_INVALID_TIMESTAMP";

throw error;

}

// ----------------------------------------------------------
// 12. USER ID
// ----------------------------------------------------------

if (
userId &&
userId !== uid
) {
const error =
new Error(
"AdMob SSV user_id does not match custom_data UID.",
);

error.code =
  "ADMOB_INVALID_UID";

throw error;

}

// ----------------------------------------------------------
// 13. VERIFIED SIGNATURE
// ----------------------------------------------------------

const signature =
verification.signature;

const keyId =
verification.keyId;

if (
typeof signature !==
"string" ||
signature.length === 0
) {
const error =
new Error(
"AdMob verified signature value is missing.",
);

error.code =
  "ADMOB_INVALID_SIGNATURE";

throw error;

}

if (
typeof keyId !==
"string" ||
keyId.length === 0
) {
const error =
new Error(
"AdMob verified key_id value is missing.",
);

error.code =
  "ADMOB_INVALID_KEY_ID";

throw error;

}

// ----------------------------------------------------------
// 14. NORMALIZED PARAMETERS
// ----------------------------------------------------------

const parameters = {
ad_network:
adNetwork,

ad_unit:
  adUnit,

custom_data:
  customData,

reward_amount:
  rewardAmount,

reward_item:
  rewardItem,

timestamp:
  timestamp,

transaction_id:
  transactionId,

user_id:
  userId,

signature,

key_id:
  keyId,

};

// ----------------------------------------------------------
// 15. VERIFIED LOG
// ----------------------------------------------------------

console.log(
"🐱✅ AdMob SSV callback fully verified.",
{
uid,

  rewardPurpose,

  transactionId,

  keyId,

  adUnit,

  rewardAmount,

  rewardItem,

  timestamp:
    timestampResult.timestampMs,
},

);

// ----------------------------------------------------------
// 16. RETURN
// ----------------------------------------------------------

return {
verified:
true,

uid,

rewardPurpose,

adUnit,

adNetwork,

rewardAmount:
  parsedRewardAmount,

rewardItem,

timestamp:
  timestampResult.timestampMs,

transactionId,

userId,

customData,

keyId,

signature,

rawQueryString:
  verification.rawQueryString,

signedQueryString:
  verification.signedQueryString,

parameters,

};
}

// ============================================================
// 📦 EXPORTS
// ============================================================

module.exports = {
ADMOB_SSV_KEYS_URL,

ADMOB_AD_UNITS,

REWARD_DEFINITIONS,

getAdMobPublicKeys,

verifyAdMobSignature,

verifyAdMobCallback,

parseCustomData,

validateTransactionId,

validateUid,

validateTimestamp,
};