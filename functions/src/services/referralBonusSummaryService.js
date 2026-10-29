
"use strict";

// ============================================================
// 🐱 STELLURIINI - REFERRAL BONUS SUMMARY SERVICE
// ============================================================
//
// Tarkoitus:
// - Vähentää referral-bonushistorian turhia lukukertoja.
// - Säilyttää vanhojen referral-suhteiden tiedot.
// - Päivittää yhteenveto vain, jos se on alustettu luotettavasti.
//
// TÄRKEÄÄ:
// Vanhojen referral-suhteiden puuttuvaa yhteenvetoa ei
// tulkita nollaksi. Niiden historiatiedot pitää käsitellä
// erikseen ennen kuin historiahaut voidaan ohittaa.
//
// ============================================================

const {
  FieldValue,
} = require("../firebase/firebase");

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
// READ SUMMARY FROM RELATIONSHIP DATA
// ============================================================
//
// Palauttaa null, jos yhteenvetoa ei ole alustettu.
// null tarkoittaa, että kutsujan pitää käyttää vanhaa
// historiapohjaista laskentaa.
//
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
// UPDATE INITIALIZED SUMMARY IN TRANSACTION
// ============================================================
//
// Kutsu tätä Firestore-transaktion sisällä.
//
// relationshipRef:
//   referrals/{referredUid}
//
// Päivitys tehdään vain, kun yhteenveto on alustettu.
// Vanhoja, alustamattomia suhteita ei muuteta, koska niiden
// aikaisempaa kokonaispalkkiota ei välttämättä tunneta.
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
      referralBonusTotal:
        FieldValue.increment(amount),
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
  incrementInitializedReferralBonusTotal,
};
