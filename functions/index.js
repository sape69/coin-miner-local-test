"use strict";

// ============================================================
// 🐱 STELLURIINI CLOUD FUNCTIONS
// ============================================================
//
// Stelluriini Cloud Functions -päävientitiedosto.
//
// Firebase käyttää tätä tiedostoa Cloud Functions -entry pointina,
// koska functions/package.json sisältää:
//
// "main": "index.js"
//
// Varsinaiset funktiot sijaitsevat:
//
// functions/src/functions/
//
// Tämä tiedosto toimii keskitettynä export-pisteenä.
//
// ============================================================


// ============================================================
// ⛏️ MINING
// ============================================================

const {
  getMiningStatus,
  claimMining,
  powerBoost,
} = require(
  "./src/functions/miningFunctions",
);


// ============================================================
// 🎁 DAILY CHECK-IN
// ============================================================

const {
  dailyCheckIn,
} = require(
  "./src/functions/dailyFunctions",
);


// ============================================================
// 📺 ADMOB SSV
// ============================================================

const {
  adMobReward,
} = require(
  "./src/functions/adFunctions",
);


// ============================================================
// 📜 TRANSACTION HISTORY
// ============================================================

const {
  getTransactionHistory,
} = require(
  "./src/functions/historyFunctions",
);


// ============================================================
// 🏆 ACHIEVEMENTS
// ============================================================

const {
  getAchievements,
  getAchievementsCompleted,
} = require(
  "./src/functions/achievementFunctions",
);


// ============================================================
// 👤 USER PROFILE
// ============================================================
//
// Stella User Profile.
//
// Flutter käyttää tätä uuden Firebase Auth -käyttäjän
// Firestore-profiilin alustamiseen.
//
// TÄRKEÄÄ:
//
// Flutter EI kirjoita users/{uid}-dokumenttia suoraan.
//
// ensureUserProfile käyttää Firebase Admin SDK:ta
// Cloud Functions -palvelimella.
//
// ============================================================

const {
  ensureUserProfile,
} = require(
  "./src/functions/userFunctions",
);


// ============================================================
// 🗑️ ACCOUNT
// ============================================================
//
// Stella Account Management.
//
// deleteAccount poistaa kirjautuneen käyttäjän Firebase
// Authentication -tilin sekä käyttäjäprofiilin.
//
// Käyttäjän UID saadaan callable-functionin
// request.auth.uid-arvosta.
//
// ============================================================

const {
  deleteAccount,
} = require(
  "./src/functions/accountFunctions",
);


// ============================================================
// 🌐 EXTERNAL ACCOUNT DELETION REQUEST
// ============================================================
//
// Ulkoinen Google Play -tilinpoistopyyntö.
//
// Tämä endpoint vastaanottaa ulkoiselta
// Stelluriini Hosting -sivulta tilinpoistopyynnön.
//
// TÄRKEÄÄ:
//
// Tämä ei vielä poista käyttäjätiliä automaattisesti.
//
// Pyyntö tallennetaan Firestoreen käsiteltäväksi.
//
// ============================================================

const {
  requestAccountDeletion,
} = require(
  "./src/functions/accountDeletionRequestFunctions",
);


// ============================================================
// 🔗 REFERRAL
// ============================================================
//
// Stella Referral System.
//
// Flutter käyttää tällä hetkellä:
//
// getReferralStatus
//
// Lisäksi backendissä ovat:
//
// getReferralProfile
// applyReferralCode
// getReferredUsers
// getReferralDashboard
//
// processReferralMiningReward
// ei ole suoraan clientin callable,
// vaan mining-järjestelmä käyttää sitä referral-bonuksen
// käsittelyyn.
//
// ============================================================

const {
  getReferralProfile,
  applyReferralCode,
  getReferredUsers,
  getReferralStatus,
  getReferralDashboard,
} = require(
  "./src/functions/referralFunctions",
);


// ============================================================
// 🔍 REFERRAL CODE VALIDATION
// ============================================================
//
// Tarkistaa referral-koodin ennen Firebase Auth -tilin
// luomista.
//
// Tämä funktio ei luo käyttäjää eikä referral-suhdetta.
//
// ============================================================

const {
  validateReferralCode,
} = require(
  "./src/functions/validateReferralCode",
);


// ============================================================
// ⛏️ MINING EXPORTS
// ============================================================

exports.getMiningStatus =
  getMiningStatus;

exports.claimMining =
  claimMining;

exports.powerBoost =
  powerBoost;


// ============================================================
// 🎁 DAILY CHECK-IN EXPORT
// ============================================================

exports.dailyCheckIn =
  dailyCheckIn;


// ============================================================
// 📺 ADMOB SSV EXPORT
// ============================================================

exports.adMobReward =
  adMobReward;


// ============================================================
// 📜 TRANSACTION HISTORY EXPORT
// ============================================================

exports.getTransactionHistory =
  getTransactionHistory;


// ============================================================
// 🏆 ACHIEVEMENT EXPORTS
// ============================================================

exports.getAchievements =
  getAchievements;

exports.getAchievementsCompleted =
  getAchievementsCompleted;


// ============================================================
// 👤 USER PROFILE EXPORT
// ============================================================
//
// Flutter voi kutsua:
//
// FirebaseFunctions
//   .httpsCallable('ensureUserProfile')
//
// Käyttäjäprofiili luodaan palvelinpuolella Admin SDK:lla.
//
// ============================================================

exports.ensureUserProfile =
  ensureUserProfile;


// ============================================================
// 🗑️ ACCOUNT EXPORT
// ============================================================
//
// Flutter voi kutsua:
//
// FirebaseFunctions
//   .httpsCallable('deleteAccount')
//
// Poisto tehdään aina kirjautuneen käyttäjän
// authentication UID:n perusteella.
//
// ============================================================

exports.deleteAccount =
  deleteAccount;


// ============================================================
// 🌐 EXTERNAL ACCOUNT DELETION REQUEST EXPORT
// ============================================================
//
// Google Playn ulkoinen tilinpoistopyyntö.
//
// Endpoint vastaanottaa:
//
// POST
//
// Stelluriini Hosting:
// https://stelluriini.web.app
//
// ============================================================

exports.requestAccountDeletion =
  requestAccountDeletion;


// ============================================================
// 🔗 REFERRAL EXPORTS
// ============================================================
//
// Nämä ovat Firebase Cloud Functions -exportteja.
//
// Flutter voi kutsua:
//
// FirebaseFunctions
//   .httpsCallable('getReferralStatus')
//
// FirebaseFunctions
//   .httpsCallable('validateReferralCode')
//
// FirebaseFunctions
//   .httpsCallable('applyReferralCode')
//
// ============================================================

exports.getReferralProfile =
  getReferralProfile;

exports.applyReferralCode =
  applyReferralCode;

exports.getReferredUsers =
  getReferredUsers;

exports.getReferralStatus =
  getReferralStatus;

exports.getReferralDashboard =
  getReferralDashboard;

exports.validateReferralCode =
  validateReferralCode;


// ============================================================
// 🐱 END OF STELLURIINI CLOUD FUNCTIONS
// ============================================================