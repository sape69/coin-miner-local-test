
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
//
// Palauttaa:
// - summan, jos yhteenveto on alustettu
// - null, jos yhteenvetoa ei voida luotettavasti käyttää
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
// GET OR INITIALIZE SUMMARY
// ============================================================
//
// Vanhan suosittelusuhteen yhteenveto lasketaan historiasta
// vain kerran ja tallennetaan suosittelusuhteen dokumenttiin.
//
// Historia ja suosittelusuhde luetaan saman Firestore-
// transaktion sisällä. Tämä suojaa yhteenvetoa tilanteessa,
// jossa uusi bonus maksetaan samanaikaisesti.
//
// Jos historian lukeminen epäonnistuu, virhe välitetään
// eteenpäin. Epäonnistunutta lukua ei tallenneta nollaksi.
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
    // Kaikki lukemiset tehdään ennen kirjoituksia.

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

    // Vanha yhteenveto puuttuu tai ei ole luotettava.
    // Lasketaan bonukset varsinaisesta tapahtumahistoriasta.

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

    // Yhteenveto merkitään alustetuksi vasta onnistuneen
    // historiakyselyn ja summan laskemisen jälkeen.

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
// INCREMENT INITIALIZED SUMMARY
// ============================================================
//
// Kutsutaan uuden bonuksen maksavan Firestore-transaktion
// sisältä sen jälkeen, kun relationship-dokumentti on luettu.
//
// Alustamatonta yhteenvetoa ei kasvateta, koska sen vanhaa
// kokonaissummaa ei vielä tunneta. Se voidaan alustaa
// myöhemmin historiasta.
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
  incrementInitializedReferralBonusTotal,
};
