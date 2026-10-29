"use strict";

// ============================================================
// 🐱 STELLURIINI - REFERRAL BONUS SUMMARY SERVICE
// ============================================================
//
// Tarkoitus:
// - Vähentää turhia referral-bonushistorian lukukertoja.
// - Säilyttää vanhojen suosittelusuhteiden bonusmäärät.
// - Alustaa vanhan yhteenvetotiedon turvallisesti.
// - Estää historian lukemisen virheen tulkitsemisen nollaksi.
// - Käsitellä uuden bonuksen yhteenvetopäivitys transaktiossa.
//
// Uudet suosittelusuhteet voivat aloittaa summasta 0.
// Vanhojen suhteiden puuttuvaa yhteenvetoa ei tulkita nollaksi.
//
// ============================================================

const {
  db,
  FieldValue,
} = require("../firebase/firebase");

const {
  getHistoryCollection,
} = require("../utils/userUtils");

// ============================================================
// VALIDATION
// ============================================================

function normalizeBonusAmount(value) {
  const amount = Number(value);

  if (!Number.isFinite(amount) || amount <= 0) {
    return 0;
  }

  return amount;
}

// ============================================================
// READ INITIALIZED SUMMARY
// ============================================================

function getInitializedReferralBonusTotal(
  relationshipData,
) {
  if (
    !relationshipData ||
    relationshipData.referralBonusTotalInitialized !== true
  ) {
    return null;
  }

  const total = Number(
    relationshipData.referralBonusTotal,
  );

  if (!Number.isFinite(total) || total < 0) {
    return null;
  }

  return total;
}

// ============================================================
// CALCULATE HISTORICAL BONUS TOTAL
// ============================================================
//
// Kutsutaan Firestore-transaktion sisältä.
// Historian lukemisen virhe välitetään eteenpäin.
//
// ============================================================

async function calculateHistoricalReferralBonusTotal(
  transaction,
  referrerUid,
  referredUid,
) {
  const historyQuery =
    getHistoryCollection(referrerUid)
      .where("referredUid", "==", referredUid)
      .where("type", "==", "referral_reward");

  const historySnapshot =
    await transaction.get(historyQuery);

  let total = 0;

  historySnapshot.forEach((document) => {
    const data = document.data() || {};

    total += normalizeBonusAmount(data.amount);
  });

  return total;
}

// ============================================================
// GET OR INITIALIZE SUMMARY
// ============================================================
//
// Vanhan suosittelusuhteen yhteenveto lasketaan historiasta
// ja tallennetaan suhteen dokumenttiin.
//
// ============================================================

async function getOrInitializeReferralBonusTotal({
  referrerUid,
  referredUid,
  relationshipRef,
}) {
  if (
    !referrerUid ||
    !referredUid ||
    !relationshipRef
  ) {
    throw new Error(
      "Referral bonus summary is missing required parameters.",
    );
  }

  return db.runTransaction(async (transaction) => {
    const relationshipSnapshot =
      await transaction.get(relationshipRef);

    if (!relationshipSnapshot.exists) {
      throw new Error(
        "Referral relationship does not exist.",
      );
    }

    const relationshipData =
      relationshipSnapshot.data() || {};

    if (
      relationshipData.referrerUid !== referrerUid ||
      relationshipData.referredUid !== referredUid
    ) {
      throw new Error(
        "Referral relationship does not match the requested users.",
      );
    }

    const initializedTotal =
      getInitializedReferralBonusTotal(
        relationshipData,
      );

    if (initializedTotal !== null) {
      return initializedTotal;
    }

    const total =
      await calculateHistoricalReferralBonusTotal(
        transaction,
        referrerUid,
        referredUid,
      );

    transaction.set(
      relationshipRef,
      {
        referralBonusTotal: total,
        referralBonusTotalInitialized: true,
      },
      {
        merge: true,
      },
    );

    return total;
  });
}

// ============================================================
// APPLY BONUS TO SUMMARY
// ============================================================
//
// Kutsutaan uuden referral-bonuksen maksavan Firestore-
// transaktion sisältä.
//
// Alustettu yhteenveto:
//   kasvatetaan bonuksen määrällä.
//
// Alustamaton yhteenveto:
//   lasketaan vanha historia ja lisätään juuri käsiteltävä
//   bonus ennen yhteenvedon alustamista.
//
// Kaikki tarvittavat lukemiset on tehtävä ennen ensimmäistä
// transaktiokirjoitusta.
//
// ============================================================

async function applyReferralBonusToSummary({
  transaction,
  relationshipRef,
  relationshipData,
  referrerUid,
  referredUid,
  bonusAmount,
}) {
  if (
    !transaction ||
    !relationshipRef ||
    !relationshipData ||
    !referrerUid ||
    !referredUid
  ) {
    throw new Error(
      "Referral bonus summary update is missing required parameters.",
    );
  }

  if (
    relationshipData.referrerUid !== referrerUid ||
    relationshipData.referredUid !== referredUid
  ) {
    throw new Error(
      "Referral relationship does not match the bonus recipients.",
    );
  }

  const amount = normalizeBonusAmount(bonusAmount);

  if (amount <= 0) {
    return false;
  }

  const initializedTotal =
    getInitializedReferralBonusTotal(
      relationshipData,
    );

  if (initializedTotal !== null) {
    transaction.set(
      relationshipRef,
      {
        referralBonusTotal: FieldValue.increment(amount),
      },
      {
        merge: true,
      },
    );

    return true;
  }

  // Vanha yhteenveto puuttuu tai on virheellinen.
  // Lasketaan aiemmat bonukset samassa transaktiossa.

  const historicalTotal =
    await calculateHistoricalReferralBonusTotal(
      transaction,
      referrerUid,
      referredUid,
    );

  transaction.set(
    relationshipRef,
    {
      referralBonusTotal: historicalTotal + amount,
      referralBonusTotalInitialized: true,
    },
    {
      merge: true,
    },
  );

  return true;
}

// ============================================================
// LEGACY HELPER
// ============================================================
//
// Säilytetään yhteensopivuus nykyisten kutsujen kanssa.
// Uuden bonuksen käsittelyssä käytetään kuitenkin
// applyReferralBonusToSummary()-funktiota.
//
// ============================================================

function incrementInitializedReferralBonusTotal(
  transaction,
  relationshipRef,
  relationshipData,
  bonusAmount,
) {
  if (!transaction || !relationshipRef) {
    return false;
  }

  const currentTotal =
    getInitializedReferralBonusTotal(
      relationshipData,
    );

  if (currentTotal === null) {
    return false;
  }

  const amount =
    normalizeBonusAmount(bonusAmount);

  if (amount <= 0) {
    return false;
  }

  transaction.set(
    relationshipRef,
    {
      referralBonusTotal: FieldValue.increment(amount),
    },
    {
      merge: true,
    },
  );

  return true;
}

// ============================================================
// EXPORTS
// ============================================================

module.exports = {
  normalizeBonusAmount,
  getInitializedReferralBonusTotal,
  getOrInitializeReferralBonusTotal,
  calculateHistoricalReferralBonusTotal,
  applyReferralBonusToSummary,
  incrementInitializedReferralBonusTotal,
};