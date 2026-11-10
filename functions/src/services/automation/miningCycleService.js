
"use strict";

// ============================================================
// 🐱 STELLURIINI - SHARED MINING CYCLE SERVICE
// ============================================================
//
// Yhteinen palvelu tavalliselle Mining Startille
// ja Premium Plus -automaattiselle louhinnalle.
//
// Vastuut:
// - Päättyneen louhintajakson tunnistaminen
// - Jakson alkuperäisen Hash Raten lukeminen
// - STL-tuoton laskeminen olemassa olevalla
//   calculateMiningCycle()-funktiolla
// - Louhintajakson tuloksen palauttaminen kutsujalle
//
// Tämä palvelu EI:
// - muuta käyttäjän saldoa
// - käynnistä uutta louhintajaksoa
// - anna Power Boostia
// - muuta Hash Ratea
// - muuta STL-laskentakaavaa
//
// Saldo, achievementit, referral-palkinnot ja
// Firestore-kirjoitukset käsitellään kutsujan
// Firestore-transaktion sisällä.
//
// ============================================================


// ============================================================
// VALUE HELPERS
// ============================================================

function nonNegative(value, fallback = 0) {
  const result = Number(value);

  return Number.isFinite(result) && result >= 0
    ? result
    : fallback;
}


// ============================================================
// CREATE MINING CYCLE SERVICE
// ============================================================

function createMiningCycleService({
  HttpsError,
  miningWindow,
  historicalHashRate,
  calculateMiningCycle,
  getMiningHalvingMultiplier,
}) {
  if (typeof miningWindow !== "function") {
    throw new Error(
      "MINING_CYCLE_SERVICE: miningWindow dependency missing."
    );
  }

  if (typeof historicalHashRate !== "function") {
    throw new Error(
      "MINING_CYCLE_SERVICE: historicalHashRate dependency missing."
    );
  }

  if (typeof calculateMiningCycle !== "function") {
    throw new Error(
      "MINING_CYCLE_SERVICE: calculateMiningCycle dependency missing."
    );
  }

  if (typeof getMiningHalvingMultiplier !== "function") {
    throw new Error(
      "MINING_CYCLE_SERVICE: getMiningHalvingMultiplier dependency missing."
    );
  }


  // ==========================================================
  // COLLECT COMPLETED MINING CYCLE
  // ==========================================================

  async function collectCompletedMiningCycle({
    uid,
    userData,
    nowMs = Date.now(),
    transaction = null,
  }) {
    if (
      typeof uid !== "string" ||
      uid.trim().length === 0
    ) {
      throw new Error(
        "MINING_CYCLE_SERVICE: valid uid required."
      );
    }

    const data =
      userData && typeof userData === "object"
        ? userData
        : {};

    const referenceNowMs = Number(nowMs);

    if (!Number.isFinite(referenceNowMs) || referenceNowMs <= 0) {
      throw new Error(
        "MINING_CYCLE_SERVICE: invalid reference time."
      );
    }

    const previous = miningWindow(data);

    const emptyResult = {
      completed: false,
      collected: 0,
      baseMining: 0,
      adBoostMining: 0,
      boostMilliseconds: 0,
      miningStartMs: previous.miningStartMs || 0,
      miningEndMs: previous.miningEndMs || 0,
      hashRate: 0,
    };

    if (!previous.valid) {
      return emptyResult;
    }

    // Aktiivista tai tulevaa jaksoa ei saa kerätä.
    if (previous.miningEndMs > referenceNowMs) {
      return emptyResult;
    }

    const rate = historicalHashRate(data);

    if (rate <= 0) {
      if (HttpsError) {
        throw new HttpsError(
          "failed-precondition",
          "🐱 Edellisen mining-cyclen Hash Rate on virheellinen."
        );
      }

      throw new Error(
        "MINING_CYCLE_SERVICE: invalid historical hash rate."
      );
    }

    // Käytetään juuri päättyneelle jaksolle
    // tallennettua halving-kerrointa.
    const halvingMultiplier =
      getMiningHalvingMultiplier(data);

    // Varsinainen STL-laskenta tapahtuu aina
    // projektin olemassa olevalla laskentafunktiolla.
    const cycle = await calculateMiningCycle(
      uid,
      previous.miningStartMs,
      previous.miningEndMs,
      rate,
      transaction,
      halvingMultiplier
    );

    const baseMining = nonNegative(
      cycle.baseMining
    );

    const adBoostMining = nonNegative(
      cycle.adBoostMining
    );

    const boostMilliseconds = nonNegative(
      cycle.boostMilliseconds
    );

    const calculatedTotal = nonNegative(
      cycle.totalMining
    );

    // Kokonaistuotto palautetaan laskentafunktion
    // mukaisena. Emme laske sitä uudelleen eri kaavalla.
    return {
      completed: true,

      collected: calculatedTotal,

      baseMining,

      adBoostMining,

      boostMilliseconds,

      miningStartMs: previous.miningStartMs,

      miningEndMs: previous.miningEndMs,

      miningStartedAt: previous.miningStartedAt,

      miningEndsAt: previous.miningEndsAt,

      hashRate: rate,

      halvingMultiplier,
    };
  }


  // ==========================================================
  // EXPORT SERVICE METHODS
  // ==========================================================

  return {
    collectCompletedMiningCycle,
  };
}


// ============================================================
// EXPORTS
// ============================================================

module.exports = {
  createMiningCycleService,
};
