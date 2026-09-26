import 'package:flutter/material.dart';

import '../../localization.dart';
import '../../widgets/cat_avatar.dart';
import '../../widgets/stelluriini_logo.dart';

// ============================================================
// STELLA THEME COLORS
// ============================================================

const Color roadmapBackgroundColor = Color(0xFF120B24);
const Color roadmapSurfaceColor = Color(0xFF1A0E31);
const Color roadmapCardColor = Color(0xFF21113B);

const Color roadmapAccentColor = Color(0xFFB58CFF);
const Color roadmapPinkColor = Color(0xFFFFB7E8);
const Color roadmapGoldColor = Color(0xFFFFD166);

const Color roadmapTextColor = Color(0xFFF8F4FF);
const Color roadmapSecondaryTextColor = Color(0xFFBDB4D1);

// ============================================================
// ROADMAP PAGE
// ============================================================

class RoadmapPage extends StatelessWidget {
  final String languageCode;

  const RoadmapPage({
    super.key,
    this.languageCode = 'fi',
  });

  // ============================================================
  // LOCALIZATION HELPER
  // ============================================================

  String _t(
    AppLocalizations localization,
    String key, {
    required String fallback,
  }) {
    final String value = localization.get(key);

    if (value == key) {
      return fallback;
    }

    return value;
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations localization =
        AppLocalizations(languageCode);

    // ==========================================================
    // TRANSLATED TEXT
    // ==========================================================

    final String roadmapTitle = _t(
      localization,
      'roadmapTitle',
      fallback: 'Stelluriinin tiekartta',
    );

    final String journeyTitle = _t(
      localization,
      'roadmapJourney',
      fallback: 'Matkamme',
    );

    final String journeyDescription = _t(
      localization,
      'roadmapJourneyDescription',
      fallback:
          'Stelluriinin tiekartta kuvaa projektin suunniteltua '
          'suuntaa. Kehitys tapahtuu vaiheittain ja järjestelmiä '
          'testataan ennen seuraavaan vaiheeseen siirtymistä.',
    );

    // ==========================================================
    // PHASE 1
    // ==========================================================

    final String phase1Title = _t(
      localization,
      'roadmapPhase1Title',
      fallback: 'Stella Mining',
    );

    final String phase1Description = _t(
      localization,
      'roadmapPhase1Description',
      fallback:
          '🐱 Stelluriini-identiteetin rakentaminen\n'
          '🎨 Stellan visuaalisen tyylin luominen\n'
          '📱 Stelluriini-sovelluksen kehittäminen\n'
          '⛏️ Stella Mining -järjestelmän käyttöönotto\n'
          '⚡ Hash Rate -järjestelmä\n'
          '📺 Power Boost -järjestelmä\n'
          '⏱️ Louhintajaksojen hallinta\n'
          '📜 Louhinta- ja tapahtumahistoria',
    );

    // ==========================================================
    // PHASE 2
    // ==========================================================

    final String phase2Title = _t(
      localization,
      'roadmapPhase2Title',
      fallback: 'Yhteisö ja Referral',
    );

    final String phase2Description = _t(
      localization,
      'roadmapPhase2Description',
      fallback:
          '🐾 Stelluriini-yhteisön kasvattaminen\n'
          '👥 Referral-järjestelmän käyttöönotto\n'
          '🎁 Kutsujalle suunniteltu bonus kutsutun käyttäjän '
          'louhintatuotosta\n'
          '📉 Referral-bonusten tasapainottaminen kasvun mukana\n'
          '🛡️ Bottien ja väärinkäytösten torjunta\n'
          '🌍 Kielituen laajentaminen\n'
          '💬 Yhteisöominaisuuksien valmistelu',
    );

    // ==========================================================
    // PHASE 3
    // ==========================================================

    final String phase3Title = _t(
      localization,
      'roadmapPhase3Title',
      fallback: 'Louhinnan tasapainotus',
    );

    final String phase3Description = _t(
      localization,
      'roadmapPhase3Description',
      fallback:
          '📊 Hash Rate -talouden tarkempi tasapainotus\n'
          '⛏️ Louhintatuoton säätäminen käyttäjämäärän mukaan\n'
          '⚡ Power Boost -järjestelmän kehittäminen\n'
          '👥 Referral-järjestelmän käyttäjämäärärajat\n'
          '📉 Bonusprosenttien asteittainen laskeminen kasvun mukana\n'
          '🤖 Bot- ja monikäyttäjäväärinkäytösten tunnistaminen\n'
          '🔐 Backend- ja turvallisuusjärjestelmien vahvistaminen',
    );

    // ==========================================================
    // PHASE 4 - TESTNET PREPARATION
    // ==========================================================

    final String phase4Title = _t(
      localization,
      'roadmapPhase4Title',
      fallback: 'Testnet-valmistelu',
    );

    final String phase4Description = _t(
      localization,
      'roadmapPhase4Description',
      fallback:
          '🧪 Solana Testnet -ympäristön valmistelu\n'
          '🔗 Blockchain-integraation rakentaminen\n'
          '👛 Testilompakoiden käyttöönotto\n'
          '🪙 STL-tokenin Testnet-testauksen valmistelu\n'
          '📤 STL-siirtojen testausympäristö\n'
          '⛽ Solana-testiverkon transaktiomaksujen testaus\n'
          '🔐 Turvallisuus- ja backend-testit\n'
          '📊 Testnet-louhinnan ja blockchain-datan yhteensopivuuden tarkistus',
    );

    // ==========================================================
    // PHASE 5 - SOLANA TESTNET
    // ==========================================================

    final String phase5Title = _t(
      localization,
      'roadmapPhase5Title',
      fallback: 'Solana Testnet',
    );

    final String phase5Description = _t(
      localization,
      'roadmapPhase5Description',
      fallback:
          '🧪 Stelluriinin Testnet-vaiheen käynnistäminen\n'
          '🔗 Solana Testnet -integraation käyttöönotto\n'
          '👛 Testilompakon yhdistäminen\n'
          '🪙 STL-siirtojen testaaminen Testnetissä\n'
          '📤 Testinostojen suorittaminen\n'
          '⛽ Testiverkon transaktiokulujen käsittely\n'
          '🛡️ Turvallisuus- ja väärinkäytöstestit\n'
          '📱 Sovelluksen blockchain-toimintojen testaaminen oikeassa testiverkossa',
    );

    // ==========================================================
    // PHASE 6 - MAINNET PREPARATION
    // ==========================================================

    final String phase6Title = _t(
      localization,
      'roadmapPhase6Title',
      fallback: 'Mainnet-valmistelu',
    );

    final String phase6Description = _t(
      localization,
      'roadmapPhase6Description',
      fallback:
          '🔐 Mainnet-infrastruktuurin valmistelu\n'
          '🔗 Solana Mainnet -integraation viimeistely\n'
          '👛 Mainnet-lompakkoratkaisun valmistelu\n'
          '🪙 STL-tokenin Mainnet-konfiguraation tarkistus\n'
          '📤 STL-nostojärjestelmän valmistelu\n'
          '🧪 Testnet-tulosten tarkistus ennen Mainnetiä\n'
          '🛡️ Turvallisuus- ja transaktiotarkastus\n'
          '🚦 Mainnet-julkaisun viimeinen hyväksyntä',
    );

    // ==========================================================
    // PHASE 7 - MAINNET
    // ==========================================================

    final String phase7Title = _t(
      localization,
      'roadmapPhase7Title',
      fallback: 'Mainnet ja STL-nostot',
    );

    final String phase7Description = _t(
      localization,
      'roadmapPhase7Description',
      fallback:
          '🚀 Stelluriinin Mainnet-vaiheen avaaminen\n'
          '🔗 Solana Mainnet -integraation käyttöönotto\n'
          '👛 Mainnet-lompakon yhdistäminen\n'
          '📤 STL-nostojen käyttöönotto\n'
          '💎 Suunniteltu vähimmäisnosto: 100 STL\n'
          '⛽ Käyttäjä maksaa oman Solana-verkkokulunsa\n'
          '🪙 STL-siirto käyttäjän lompakkoon\n'
          '📊 Mainnet-transaktioiden seuranta ja turvallisuusvalvonta',
    );

    // ==========================================================
    // PHASE 8 - ECOSYSTEM
    // ==========================================================

    final String phase8Title = _t(
      localization,
      'roadmapPhase8Title',
      fallback: 'Pörssi ja ekosysteemi',
    );

    final String phase8Description = _t(
      localization,
      'roadmapPhase8Description',
      fallback:
          '🌟 DEX- ja CEX-mahdollisuuksien tutkiminen\n'
          '💧 Likviditeettiratkaisujen valmistelu\n'
          '📈 STL-ekosysteemin laajentaminen\n'
          '🤝 Kumppanuuksien kehittäminen\n'
          '🐱 Uusien Stella-kokemusten esittely\n'
          '🚀 STL:n tulevien käyttötapojen tutkiminen',
    );

    // ==========================================================
    // STATUS TEXT
    // ==========================================================

    final String inProgressText = _t(
      localization,
      'roadmapInProgress',
      fallback: 'KÄYNNISSÄ',
    );

    final String plannedText = _t(
      localization,
      'roadmapPlanned',
      fallback: 'SUUNNITELTU',
    );

    final String testnetText = _t(
      localization,
      'roadmapTestnet',
      fallback: 'TESTNET',
    );

    final String futureText = _t(
      localization,
      'roadmapFuture',
      fallback: 'TULEVAISUUS',
    );

    final String mainnetText = _t(
      localization,
      'roadmapMainnet',
      fallback: 'MAINNET',
    );

    // ==========================================================
    // REFERRAL CARD
    // ==========================================================

    final String referralTitle = _t(
      localization,
      'roadmapReferralTitle',
      fallback: 'Referral-järjestelmä',
    );

    final String referralDescription = _t(
      localization,
      'roadmapReferralDescription',
      fallback:
          'Stelluriiniin suunnitellaan referral-järjestelmää, '
          'jossa käyttäjä voi kutsua uusia käyttäjiä mukaan. '
          'Kutsujalle voidaan antaa suunniteltu bonusosuus '
          'kutsutun käyttäjän louhintatuotosta.',
    );

    final String referralBalanceTitle = _t(
      localization,
      'roadmapReferralBalanceTitle',
      fallback: 'Kasvun mukana tasapainottuva bonus',
    );

    final String referralBalanceText = _t(
      localization,
      'roadmapReferralBalanceText',
      fallback:
          'Referral-bonusta ei ole tarkoitus pitää jatkuvasti '
          'samalla tasolla. Kun Stelluriinin käyttäjämäärä kasvaa, '
          'bonusprosenttia voidaan pienentää vaiheittain.',
    );

    final String referralMilestoneTitle = _t(
      localization,
      'roadmapReferralMilestoneTitle',
      fallback: 'Käyttäjämäärän vaikutus',
    );

    final String referralMilestoneText = _t(
      localization,
      'roadmapReferralMilestoneText',
      fallback:
          'Tarkat käyttäjämäärärajat ja bonusprosentit määritellään '
          'ennen referral-järjestelmän lopullista julkaisua.',
    );

    // ==========================================================
    // MINING BALANCE CARD
    // ==========================================================

    final String miningBalanceTitle = _t(
      localization,
      'roadmapMiningBalanceTitle',
      fallback: 'Louhintatalouden tasapaino',
    );

    final String miningBalanceText = _t(
      localization,
      'roadmapMiningBalanceText',
      fallback:
          'Louhintajärjestelmän tavoitteena ei ole kasvattaa '
          'päivittäistä STL-määrää rajattomasti. Hash Rate, '
          'Power Boost ja Referral-bonukset suunnitellaan '
          'yhdessä niin, että kokonaisuus pysyy hallittavana.',
    );

    final String miningRateTitle = _t(
      localization,
      'roadmapMiningRateTitle',
      fallback: 'Hash Rate',
    );

    final String miningRateText = _t(
      localization,
      'roadmapMiningRateText',
      fallback:
          'Peruslouhinta muodostaa käyttäjän normaalin Hash Rate '
          '-tason. Käyttäjä voi kehittää omaa louhintatehoaan '
          'sovelluksen sisäisten järjestelmien kautta.',
    );

    final String boostTitle = _t(
      localization,
      'roadmapBoostTitle',
      fallback: 'Power Boost',
    );

    final String boostText = _t(
      localization,
      'roadmapBoostText',
      fallback:
          'Power Boost tarjoaa määräaikaisen lisäyksen käyttäjän '
          'louhintatehoon. Boostin nykyinen suunniteltu kesto on '
          '4 tuntia.',
    );

    // ==========================================================
    // TESTNET CARD
    // ==========================================================

    final String testnetCardTitle = _t(
      localization,
      'roadmapTestnetCardTitle',
      fallback: '🧪 Stelluriini Testnet',
    );

    final String testnetCardText = _t(
      localization,
      'roadmapTestnetCardText',
      fallback:
          'Testnet-vaiheen tarkoituksena on testata Stelluriinin '
          'blockchain-toiminnot turvallisessa Solana-testiverkossa '
          'ennen Mainnet-julkaisua. Testnetissä voidaan testata '
          'lompakoita, STL-siirtoja, transaktioita ja nostoprosessia '
          'ilman Mainnet-varojen käyttämistä.',
    );

    final String testnetFlowTitle = _t(
      localization,
      'roadmapTestnetFlowTitle',
      fallback: 'Testnet → Mainnet',
    );

    final String testnetFlowText = _t(
      localization,
      'roadmapTestnetFlowText',
      fallback:
          'Testnetin jälkeen tulokset tarkistetaan. Vasta kun '
          'blockchain-integraatio, turvallisuus, lompakot ja '
          'STL-siirrot toimivat suunnitellusti, siirrytään '
          'Mainnet-valmisteluun.',
    );

    // ==========================================================
    // WITHDRAWAL
    // ==========================================================

    final String futureWithdrawalsTitle = _t(
      localization,
      'futureWithdrawalsTitle',
      fallback: 'Tulevat STL-nostot',
    );

    final String futureWithdrawalsDescription = _t(
      localization,
      'futureWithdrawals',
      fallback:
          'STL-nostot eivät ole käytettävissä nykyisessä '
          'louhintaversiossa. Ne on suunniteltu myöhempään '
          'Mainnet-vaiheeseen sen jälkeen, kun lompakko-, '
          'turvallisuus- ja blockchain-infrastruktuuri on '
          'rakennettu ja testattu.',
    );

    final String plannedWithdrawalModel = _t(
      localization,
      'plannedWithdrawalModel',
      fallback:
          '🐱 Suunniteltu malli: 100 STL vähimmäisnosto • '
          'Käyttäjä maksaa Solana-verkkokulun',
    );

    // ==========================================================
    // DEVELOPMENT PRINCIPLES
    // ==========================================================

    final String developmentPrinciplesTitle = _t(
      localization,
      'developmentPrinciples',
      fallback: 'Kehitysperiaatteet',
    );

    final String communityTitle = _t(
      localization,
      'roadmapCommunity',
      fallback: 'Yhteisö',
    );

    final String communityText = _t(
      localization,
      'roadmapCommunityDescription',
      fallback: 'Rakennetaan Stelluriini-yhteisöä vaiheittain.',
    );

    final String stellaTitle = _t(
      localization,
      'roadmapStella',
      fallback: 'Stella',
    );

    final String stellaText = _t(
      localization,
      'roadmapStellaDescription',
      fallback:
          'Pidetään Stella projektin identiteetin sydämessä.',
    );

    final String securityTitle = _t(
      localization,
      'roadmapSecurity',
      fallback: 'Turvallisuus',
    );

    final String securityText = _t(
      localization,
      'roadmapSecurityDescription',
      fallback:
          'Louhinta-, referral-, lompakko- ja blockchain-ominaisuudet '
          'kehitetään ja testataan ennen julkaisua.',
    );

    final String antiBotTitle = _t(
      localization,
      'roadmapAntiBot',
      fallback: 'Botintorjunta',
    );

    final String antiBotText = _t(
      localization,
      'roadmapAntiBotDescription',
      fallback:
          'Järjestelmässä huomioidaan bottien, automaation ja '
          'väärinkäytösten tunnistaminen.',
    );

    final String innovationTitle = _t(
      localization,
      'roadmapInnovation',
      fallback: 'Innovaatio',
    );

    final String innovationText = _t(
      localization,
      'roadmapInnovationDescription',
      fallback:
          'Tutkitaan uusia sovelluksia, pelejä ja digitaalisia '
          'Stella-kokemuksia.',
    );

    final String growthTitle = _t(
      localization,
      'roadmapLongTermGrowth',
      fallback: 'Pitkän aikavälin kasvu',
    );

    final String growthText = _t(
      localization,
      'roadmapLongTermGrowthDescription',
      fallback:
          'Ekosysteemiä kasvatetaan vaiheittain ja louhintataloutta '
          'tasapainotetaan käyttäjämäärän mukaan.',
    );

    // ==========================================================
    // NOTICE
    // ==========================================================

    final String noticeTitle = _t(
      localization,
      'roadmapNotice',
      fallback: 'Tiekarttahuomautus',
    );

    final String noticeText = _t(
      localization,
      'roadmapNoticeDescription',
      fallback:
          'Tiekartta kuvaa Stelluriinin tämänhetkistä suunniteltua '
          'suuntaa. Päivämäärät, ominaisuudet, bonusprosentit, '
          'käyttäjämäärärajat, Testnet- ja Mainnet-vaiheet sekä '
          'julkaisusuunnitelmat voivat muuttua projektin kehittyessä.',
    );

    final String stellaJourneyText = _t(
      localization,
      'roadmapStellaJourney',
      fallback:
          '🐱 Stella kulkee mukana tällä matkalla!',
    );

    final String ecosystemText = _t(
      localization,
      'roadmapEcosystemDescription',
      fallback:
          'Jokainen vaihe on uusi askel kohti '
          'Stelluriini-ekosysteemiä.',
    );

    // ============================================================
    // UI
    // ============================================================

    return Scaffold(
      backgroundColor: roadmapBackgroundColor,

      // ========================================================
      // APP BAR
      // ========================================================

      appBar: AppBar(
        backgroundColor: roadmapBackgroundColor,
        foregroundColor: roadmapTextColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          roadmapTitle,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),

      // ========================================================
      // BODY
      // ========================================================

      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            16,
            8,
            16,
            32,
          ),
          children: [
            // ==================================================
            // STELLA HEADER
            // ==================================================

            Container(
              padding: const EdgeInsets.fromLTRB(
                24,
                28,
                24,
                26,
              ),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF21113B),
                    Color(0xFF2A1648),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius:
                    BorderRadius.circular(26),
                border: Border.all(
                  color:
                      roadmapAccentColor.withValues(
                    alpha: 0.30,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color:
                        roadmapAccentColor.withValues(
                      alpha: 0.10,
                    ),
                    blurRadius: 24,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Column(
                children: [
                  const CatAvatar(
                    size: 110,
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'STELLURIINI',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: roadmapPinkColor,
                      fontSize: 27,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'STL • SOLANA',
                    style: TextStyle(
                      color: roadmapAccentColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    '🐾 ${_t(
                      localization,
                      'roadmapStellaIntro',
                      fallback:
                          'Seuraa Stellan matkaa kohti tulevaisuutta.',
                    )} 🐾',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: roadmapSecondaryTextColor,
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ==================================================
            // INTRODUCTION
            // ==================================================

            _RoadmapInfoCard(
              icon: Icons.map_rounded,
              title: journeyTitle,
              accent: roadmapAccentColor,
              child: Text(
                journeyDescription,
                style: const TextStyle(
                  color: roadmapSecondaryTextColor,
                  fontSize: 15,
                  height: 1.6,
                ),
              ),
            ),

            const SizedBox(height: 18),

            // ==================================================
            // PHASE 1
            // ==================================================

            _RoadmapStep(
              phase: _t(
                localization,
                'roadmapPhase1',
                fallback: 'VAIHE 1',
              ),
              title: phase1Title,
              description: phase1Description,
              status: inProgressText,
              accent: roadmapPinkColor,
              icon: '🐱',
            ),

            const _RoadmapLine(),

            // ==================================================
            // PHASE 2
            // ==================================================

            _RoadmapStep(
              phase: _t(
                localization,
                'roadmapPhase2',
                fallback: 'VAIHE 2',
              ),
              title: phase2Title,
              description: phase2Description,
              status: plannedText,
              accent: roadmapAccentColor,
              icon: '👥',
            ),

            const _RoadmapLine(),

            // ==================================================
            // PHASE 3
            // ==================================================

            _RoadmapStep(
              phase: _t(
                localization,
                'roadmapPhase3',
                fallback: 'VAIHE 3',
              ),
              title: phase3Title,
              description: phase3Description,
              status: plannedText,
              accent: roadmapGoldColor,
              icon: '⚖️',
            ),

            const _RoadmapLine(),

            // ==================================================
            // PHASE 4 - TESTNET PREPARATION
            // ==================================================

            _RoadmapStep(
              phase: _t(
                localization,
                'roadmapPhase4',
                fallback: 'VAIHE 4',
              ),
              title: phase4Title,
              description: phase4Description,
              status: plannedText,
              accent: roadmapAccentColor,
              icon: '🧪',
            ),

            const _RoadmapLine(),

            // ==================================================
            // PHASE 5 - SOLANA TESTNET
            // ==================================================

            _RoadmapStep(
              phase: _t(
                localization,
                'roadmapPhase5',
                fallback: 'VAIHE 5',
              ),
              title: phase5Title,
              description: phase5Description,
              status: testnetText,
              accent: roadmapGoldColor,
              icon: '🧪',
            ),

            const _RoadmapLine(),

            // ==================================================
            // PHASE 6 - MAINNET PREPARATION
            // ==================================================

            _RoadmapStep(
              phase: _t(
                localization,
                'roadmapPhase6',
                fallback: 'VAIHE 6',
              ),
              title: phase6Title,
              description: phase6Description,
              status: futureText,
              accent: roadmapPinkColor,
              icon: '🔐',
            ),

            const _RoadmapLine(),

            // ==================================================
            // PHASE 7 - MAINNET
            // ==================================================

            _RoadmapStep(
              phase: _t(
                localization,
                'roadmapPhase7',
                fallback: 'VAIHE 7',
              ),
              title: phase7Title,
              description: phase7Description,
              status: mainnetText,
              accent: roadmapGoldColor,
              icon: '🚀',
            ),

            const _RoadmapLine(),

            // ==================================================
            // PHASE 8 - ECOSYSTEM
            // ==================================================

            _RoadmapStep(
              phase: _t(
                localization,
                'roadmapPhase8',
                fallback: 'VAIHE 8',
              ),
              title: phase8Title,
              description: phase8Description,
              status: futureText,
              accent: roadmapPinkColor,
              icon: '🌟',
            ),

            const SizedBox(height: 20),

            // ==================================================
            // TESTNET → MAINNET CARD
            // ==================================================

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF21113B),
                    Color(0xFF281746),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius:
                    BorderRadius.circular(22),
                border: Border.all(
                  color:
                      roadmapGoldColor.withValues(
                    alpha: 0.24,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color:
                        roadmapGoldColor.withValues(
                      alpha: 0.06,
                    ),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    '🧪  →  🚀',
                    style: TextStyle(
                      fontSize: 34,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    testnetCardTitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: roadmapAccentColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    testnetCardText,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: roadmapSecondaryTextColor,
                      fontSize: 13,
                      height: 1.55,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding:
                        const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color:
                          roadmapGoldColor.withValues(
                        alpha: 0.07,
                      ),
                      borderRadius:
                          BorderRadius.circular(16),
                      border: Border.all(
                        color:
                            roadmapGoldColor.withValues(
                          alpha: 0.16,
                        ),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          testnetFlowTitle,
                          textAlign:
                              TextAlign.center,
                          style: const TextStyle(
                            color:
                                roadmapGoldColor,
                            fontSize: 16,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          testnetFlowText,
                          textAlign:
                              TextAlign.center,
                          style:
                              const TextStyle(
                            color:
                                roadmapSecondaryTextColor,
                            fontSize: 12.5,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // ==================================================
            // REFERRAL SYSTEM
            // ==================================================

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: roadmapCardColor,
                borderRadius:
                    BorderRadius.circular(22),
                border: Border.all(
                  color:
                      roadmapAccentColor.withValues(
                    alpha: 0.22,
                  ),
                ),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.group_add_rounded,
                    color: roadmapAccentColor,
                    size: 34,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    referralTitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: roadmapAccentColor,
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    referralDescription,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: roadmapSecondaryTextColor,
                      fontSize: 13,
                      height: 1.55,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _ReferralInfoRow(
                    icon: Icons.auto_awesome_rounded,
                    title: referralBalanceTitle,
                    text: referralBalanceText,
                  ),
                  const SizedBox(height: 14),
                  _ReferralInfoRow(
                    icon: Icons.people_alt_rounded,
                    title: referralMilestoneTitle,
                    text: referralMilestoneText,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // ==================================================
            // MINING ECONOMY
            // ==================================================

            _RoadmapInfoCard(
              icon: Icons.speed_rounded,
              title: miningBalanceTitle,
              accent: roadmapGoldColor,
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    miningBalanceText,
                    style: const TextStyle(
                      color: roadmapSecondaryTextColor,
                      fontSize: 14,
                      height: 1.55,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _PrincipleRow(
                    icon: Icons.bolt_rounded,
                    title: miningRateTitle,
                    text: miningRateText,
                  ),
                  const SizedBox(height: 14),
                  _PrincipleRow(
                    icon: Icons.flash_on_rounded,
                    title: boostTitle,
                    text: boostText,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ==================================================
            // WITHDRAWAL EXPLANATION
            // ==================================================

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: roadmapCardColor,
                borderRadius:
                    BorderRadius.circular(22),
                border: Border.all(
                  color:
                      roadmapGoldColor.withValues(
                    alpha: 0.20,
                  ),
                ),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.account_balance_wallet_rounded,
                    color: roadmapGoldColor,
                    size: 32,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    futureWithdrawalsTitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: roadmapGoldColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    futureWithdrawalsDescription,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: roadmapSecondaryTextColor,
                      fontSize: 13,
                      height: 1.55,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color:
                          roadmapGoldColor.withValues(
                        alpha: 0.08,
                      ),
                      borderRadius:
                          BorderRadius.circular(14),
                      border: Border.all(
                        color:
                            roadmapGoldColor.withValues(
                          alpha: 0.15,
                        ),
                      ),
                    ),
                    child: Text(
                      plannedWithdrawalModel,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color:
                            roadmapSecondaryTextColor,
                        fontSize: 12,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ==================================================
            // STELLA CARD
            // ==================================================

            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: roadmapCardColor,
                borderRadius:
                    BorderRadius.circular(22),
                border: Border.all(
                  color:
                      roadmapPinkColor.withValues(
                    alpha: 0.20,
                  ),
                ),
              ),
              child: Column(
                children: [
                  const StelluriiniLogo(
                    size: 72,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    stellaJourneyText,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: roadmapPinkColor,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    ecosystemText,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color:
                          roadmapSecondaryTextColor,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // ==================================================
            // DEVELOPMENT PRINCIPLES
            // ==================================================

            _RoadmapInfoCard(
              icon: Icons.rocket_launch_rounded,
              title: developmentPrinciplesTitle,
              accent: roadmapGoldColor,
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  _PrincipleRow(
                    icon: Icons.groups_rounded,
                    title: communityTitle,
                    text: communityText,
                  ),
                  const SizedBox(height: 14),
                  _PrincipleRow(
                    icon: Icons.pets_rounded,
                    title: stellaTitle,
                    text: stellaText,
                  ),
                  const SizedBox(height: 14),
                  _PrincipleRow(
                    icon: Icons.security_rounded,
                    title: securityTitle,
                    text: securityText,
                  ),
                  const SizedBox(height: 14),
                  _PrincipleRow(
                    icon: Icons.shield_rounded,
                    title: antiBotTitle,
                    text: antiBotText,
                  ),
                  const SizedBox(height: 14),
                  _PrincipleRow(
                    icon: Icons.auto_awesome_rounded,
                    title: innovationTitle,
                    text: innovationText,
                  ),
                  const SizedBox(height: 14),
                  _PrincipleRow(
                    icon: Icons.trending_up_rounded,
                    title: growthTitle,
                    text: growthText,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // ==================================================
            // IMPORTANT NOTICE
            // ==================================================

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color:
                    Colors.orangeAccent.withValues(
                  alpha: 0.07,
                ),
                borderRadius:
                    BorderRadius.circular(20),
                border: Border.all(
                  color:
                      Colors.orangeAccent.withValues(
                    alpha: 0.22,
                  ),
                ),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: Colors.orangeAccent,
                    size: 30,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    noticeTitle,
                    style: const TextStyle(
                      color: Colors.orangeAccent,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    noticeText,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color:
                          roadmapSecondaryTextColor,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ==================================================
            // FOOTER
            // ==================================================

            Text(
              _t(
                localization,
                'roadmapFooter',
                fallback:
                    '🐾 STELLA • STELLURIINI • STL • SOLANA 🐾',
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: roadmapPinkColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              '17 602 539 062 STL',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: roadmapGoldColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// ROADMAP STEP
// ============================================================

class _RoadmapStep extends StatelessWidget {
  final String phase;
  final String title;
  final String description;
  final String status;
  final Color accent;
  final String icon;

  const _RoadmapStep({
    required this.phase,
    required this.title,
    required this.description,
    required this.status,
    required this.accent,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        // ======================================================
        // MARKER
        // ======================================================

        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color:
                accent.withValues(alpha: 0.12),
            shape: BoxShape.circle,
            border: Border.all(
              color:
                  accent.withValues(alpha: 0.45),
            ),
            boxShadow: [
              BoxShadow(
                color:
                    accent.withValues(alpha: 0.08),
                blurRadius: 12,
              ),
            ],
          ),
          child: Center(
            child: Text(
              icon,
              style: const TextStyle(
                fontSize: 25,
              ),
            ),
          ),
        ),

        const SizedBox(width: 14),

        // ======================================================
        // CARD
        // ======================================================

        Expanded(
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: roadmapCardColor,
              borderRadius:
                  BorderRadius.circular(20),
              border: Border.all(
                color:
                    accent.withValues(alpha: 0.17),
              ),
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        phase,
                        style: TextStyle(
                          color: accent,
                          fontSize: 12,
                          fontWeight:
                              FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color:
                            accent.withValues(
                          alpha: 0.12,
                        ),
                        borderRadius:
                            BorderRadius.circular(10),
                        border: Border.all(
                          color:
                              accent.withValues(
                            alpha: 0.15,
                          ),
                        ),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          color: accent,
                          fontSize: 9,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 9),

                Text(
                  title,
                  style: const TextStyle(
                    color: roadmapTextColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  description,
                  style: const TextStyle(
                    color:
                        roadmapSecondaryTextColor,
                    fontSize: 14,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// ROADMAP LINE
// ============================================================

class _RoadmapLine extends StatelessWidget {
  const _RoadmapLine();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(
        left: 26,
        top: 4,
        bottom: 4,
      ),
      width: 2,
      height: 35,
      decoration: BoxDecoration(
        color:
            roadmapAccentColor.withValues(
          alpha: 0.25,
        ),
        borderRadius:
            BorderRadius.circular(2),
      ),
    );
  }
}

// ============================================================
// INFORMATION CARD
// ============================================================

class _RoadmapInfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color accent;
  final Widget child;

  const _RoadmapInfoCard({
    required this.icon,
    required this.title,
    required this.accent,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: roadmapCardColor,
        borderRadius:
            BorderRadius.circular(22),
        border: Border.all(
          color:
              accent.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color:
                      accent.withValues(
                    alpha: 0.11,
                  ),
                  borderRadius:
                      BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: accent,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: roadmapTextColor,
                    fontSize: 20,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

// ============================================================
// REFERRAL INFO ROW
// ============================================================

class _ReferralInfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;

  const _ReferralInfoRow({
    required this.icon,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: roadmapSurfaceColor,
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color:
              roadmapAccentColor.withValues(
            alpha: 0.10,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: roadmapAccentColor,
            size: 21,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: roadmapTextColor,
                    fontSize: 14,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  text,
                  style: const TextStyle(
                    color:
                        roadmapSecondaryTextColor,
                    fontSize: 12.5,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// PRINCIPLE ROW
// ============================================================

class _PrincipleRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;

  const _PrincipleRow({
    required this.icon,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: roadmapAccentColor,
          size: 20,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: roadmapTextColor,
                  fontSize: 15,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                text,
                style: const TextStyle(
                  color:
                      roadmapSecondaryTextColor,
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}