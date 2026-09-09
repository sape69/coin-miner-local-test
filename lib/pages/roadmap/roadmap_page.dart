import 'package:flutter/material.dart';

import '../../localization.dart';
import '../../widgets/cat_avatar.dart';
import '../../widgets/stelluriini_logo.dart';

// ============================================================
// STELLA THEME COLORS
// ============================================================

const Color roadmapBackgroundColor = Color(0xFF120B24);
const Color roadmapCardColor = Color(0xFF21113B);
const Color roadmapAccentColor = Color(0xFFB58CFF);
const Color roadmapPinkColor = Color(0xFFFFB7E8);
const Color roadmapGoldColor = Color(0xFFFFD166);

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
          'suuntaa. Kehitys voi muuttua ajan myötä yhteisön, '
          'teknologian, turvallisuuden ja ekosysteemin kasvaessa.',
    );

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
          '⛏️ Stella Miningin julkaisu\n'
          '🎁 Päivittäinen Hash Rate -kehitys\n'
          '📺 Stella Power Boost\n'
          '📜 Tapahtumahistoria',
    );

    final String phase2Title = _t(
      localization,
      'roadmapPhase2Title',
      fallback: 'Yhteisö ja testaus',
    );

    final String phase2Description = _t(
      localization,
      'roadmapPhase2Description',
      fallback:
          '🐾 Stelluriini-yhteisön kasvattaminen\n'
          '🌍 Kielituen laajentaminen\n'
          '🧪 Louhinta- ja palkkiojärjestelmien parantaminen\n'
          '🔐 Turvallisuuden ja backend-järjestelmien vahvistaminen\n'
          '📊 Token- ja ekosysteemitietojen parantaminen\n'
          '💬 Tulevien yhteisöominaisuuksien valmistelu',
    );

    final String phase3Title = _t(
      localization,
      'roadmapPhase3Title',
      fallback: 'STL-ekosysteemi',
    );

    final String phase3Description = _t(
      localization,
      'roadmapPhase3Description',
      fallback:
          '🪙 STL-ekosysteemin kehittäminen\n'
          '🔗 Solana-lohkoketjuintegraation valmistelu\n'
          '👛 Lompakkoyhteyden valmistelu\n'
          '📊 Token-tilastojen ja läpinäkyvyyden laajentaminen\n'
          '🧪 Tulevan STL-siirto-ominaisuuden testaaminen\n'
          '🚀 Projektin seuraavaan vaiheeseen valmistautuminen',
    );

    final String phase4Title = _t(
      localization,
      'roadmapPhase4Title',
      fallback: 'Mainnet-valmistelu',
    );

    final String phase4Description = _t(
      localization,
      'roadmapPhase4Description',
      fallback:
          '🔐 Turvallisen Mainnet-infrastruktuurin valmistelu\n'
          '👛 Solana-lompakkointegraation viimeistely\n'
          '📤 STL-nostojärjestelmän kehittäminen\n'
          '🧪 Nostojen testaaminen ennen julkista julkaisua\n'
          '💎 100 STL:n vähimmäisnostorajan valmistelu\n'
          '🛡️ Turvallisuuden ja transaktioiden käsittelyn tarkistus',
    );

    final String phase5Title = _t(
      localization,
      'roadmapPhase5Title',
      fallback: 'Mainnet ja STL-nostot',
    );

    final String phase5Description = _t(
      localization,
      'roadmapPhase5Description',
      fallback:
          '🚀 Stelluriinin Mainnet-vaiheen avaaminen\n'
          '👛 Solana-lompakon yhdistäminen\n'
          '📤 STL-nostojen käyttöönotto\n'
          '💎 Vähimmäisnostotavoite: 100 STL\n'
          '⛽ Käyttäjä maksaa oman Solana-verkkokulunsa\n'
          '🪙 STL-siirto suoraan käyttäjän lompakkoon',
    );

    final String phase6Title = _t(
      localization,
      'roadmapPhase6Title',
      fallback: 'Pörssi ja ekosysteemi',
    );

    final String phase6Description = _t(
      localization,
      'roadmapPhase6Description',
      fallback:
          '🌟 DEX- ja CEX-mahdollisuuksien tutkiminen\n'
          '💧 Sopivien likviditeettiratkaisujen valmistelu\n'
          '📈 STL-ekosysteemin laajentaminen\n'
          '🤝 Kumppanuuksien ja yhteisön osallistumisen kasvattaminen\n'
          '🐱 Uusien Stella-kokemusten esittely\n'
          '🚀 STL:n tulevien käyttötapojen tutkiminen',
    );

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

    final String futureText = _t(
      localization,
      'roadmapFuture',
      fallback: 'TULEVAISUUS',
    );

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
          'Mainnet-vaiheeseen sen jälkeen, kun tarvittava '
          'lompakko-, turvallisuus- ja lohkoketjuinfrastruktuuri '
          'on rakennettu ja testattu.',
    );

    final String plannedWithdrawalModel = _t(
      localization,
      'plannedWithdrawalModel',
      fallback:
          '🐱 Suunniteltu malli: 100 STL vähimmäisnosto • '
          'Käyttäjä maksaa Solana-verkkokulun',
    );

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
      fallback:
          'Rakennetaan yhdessä Stelluriini-yhteisön kanssa.',
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
          'Lohkoketju- ja lompakko-ominaisuudet kehitetään '
          'huolellisesti ja testataan ennen julkaisua.',
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
          'kokemuksia.',
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
          'Ekosysteemiä kehitetään vaiheittain ja kestävästi.',
    );

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
          'suuntaa. Päivämäärät, ominaisuudet, prioriteetit ja '
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

    return Scaffold(
      backgroundColor: roadmapBackgroundColor,

      // ========================================================
      // APP BAR
      // ========================================================

      appBar: AppBar(
        backgroundColor: roadmapBackgroundColor,
        foregroundColor: Colors.white,
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
                    textAlign:
                        TextAlign.center,
                    style: TextStyle(
                      color:
                          roadmapPinkColor,
                      fontSize: 27,
                      fontWeight:
                          FontWeight.bold,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'STL • SOLANA',
                    style: TextStyle(
                      color:
                          roadmapAccentColor,
                      fontSize: 14,
                      fontWeight:
                          FontWeight.bold,
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
                    textAlign:
                        TextAlign.center,
                    style: const TextStyle(
                      color:
                          Colors.white70,
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
              icon:
                  Icons.map_rounded,
              title:
                  journeyTitle,
              accent:
                  roadmapAccentColor,
              child: Text(
                journeyDescription,
                style:
                    const TextStyle(
                  color:
                      Colors.white70,
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
              phase:
                  _t(
                    localization,
                    'roadmapPhase1',
                    fallback: 'VAIHE 1',
                  ),
              title:
                  phase1Title,
              description:
                  phase1Description,
              status:
                  inProgressText,
              accent:
                  roadmapPinkColor,
              icon:
                  '🐱',
            ),

            const _RoadmapLine(),

            // ==================================================
            // PHASE 2
            // ==================================================

            _RoadmapStep(
              phase:
                  _t(
                    localization,
                    'roadmapPhase2',
                    fallback: 'VAIHE 2',
                  ),
              title:
                  phase2Title,
              description:
                  phase2Description,
              status:
                  plannedText,
              accent:
                  roadmapAccentColor,
              icon:
                  '🐾',
            ),

            const _RoadmapLine(),

            // ==================================================
            // PHASE 3
            // ==================================================

            _RoadmapStep(
              phase:
                  _t(
                    localization,
                    'roadmapPhase3',
                    fallback: 'VAIHE 3',
                  ),
              title:
                  phase3Title,
              description:
                  phase3Description,
              status:
                  futureText,
              accent:
                  roadmapGoldColor,
              icon:
                  '🪙',
            ),

            const _RoadmapLine(),

            // ==================================================
            // PHASE 4
            // ==================================================

            _RoadmapStep(
              phase:
                  _t(
                    localization,
                    'roadmapPhase4',
                    fallback: 'VAIHE 4',
                  ),
              title:
                  phase4Title,
              description:
                  phase4Description,
              status:
                  futureText,
              accent:
                  roadmapPinkColor,
              icon:
                  '🔐',
            ),

            const _RoadmapLine(),

            // ==================================================
            // PHASE 5
            // ==================================================

            _RoadmapStep(
              phase:
                  _t(
                    localization,
                    'roadmapPhase5',
                    fallback: 'VAIHE 5',
                  ),
              title:
                  phase5Title,
              description:
                  phase5Description,
              status:
                  futureText,
              accent:
                  roadmapGoldColor,
              icon:
                  '🚀',
            ),

            const _RoadmapLine(),

            // ==================================================
            // PHASE 6
            // ==================================================

            _RoadmapStep(
              phase:
                  _t(
                    localization,
                    'roadmapPhase6',
                    fallback: 'VAIHE 6',
                  ),
              title:
                  phase6Title,
              description:
                  phase6Description,
              status:
                  futureText,
              accent:
                  roadmapPinkColor,
              icon:
                  '🌟',
            ),

            const SizedBox(height: 20),

            // ==================================================
            // WITHDRAWAL EXPLANATION
            // ==================================================

            Container(
              padding:
                  const EdgeInsets.all(20),
              decoration:
                  BoxDecoration(
                color:
                    roadmapCardColor,
                borderRadius:
                    BorderRadius.circular(22),
                border:
                    Border.all(
                  color:
                      roadmapGoldColor.withValues(
                    alpha: 0.20,
                  ),
                ),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons
                        .account_balance_wallet_rounded,
                    color:
                        roadmapGoldColor,
                    size: 32,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    futureWithdrawalsTitle,
                    textAlign:
                        TextAlign.center,
                    style:
                        const TextStyle(
                      color:
                          roadmapGoldColor,
                      fontSize: 18,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    futureWithdrawalsDescription,
                    textAlign:
                        TextAlign.center,
                    style:
                        const TextStyle(
                      color:
                          Colors.white60,
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
                    decoration:
                        BoxDecoration(
                      color:
                          roadmapGoldColor.withValues(
                        alpha: 0.08,
                      ),
                      borderRadius:
                          BorderRadius.circular(
                        14,
                      ),
                      border:
                          Border.all(
                        color:
                            roadmapGoldColor.withValues(
                          alpha: 0.15,
                        ),
                      ),
                    ),
                    child: Text(
                      plannedWithdrawalModel,
                      textAlign:
                          TextAlign.center,
                      style:
                          const TextStyle(
                        color:
                            Colors.white70,
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
              padding:
                  const EdgeInsets.all(22),
              decoration:
                  BoxDecoration(
                color:
                    roadmapCardColor,
                borderRadius:
                    BorderRadius.circular(22),
                border:
                    Border.all(
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
                    textAlign:
                        TextAlign.center,
                    style:
                        const TextStyle(
                      color:
                          roadmapPinkColor,
                      fontSize: 17,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    ecosystemText,
                    textAlign:
                        TextAlign.center,
                    style:
                        const TextStyle(
                      color:
                          Colors.white60,
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
              icon:
                  Icons.rocket_launch_rounded,
              title:
                  developmentPrinciplesTitle,
              accent:
                  roadmapGoldColor,
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  _PrincipleRow(
                    icon:
                        Icons.groups_rounded,
                    title:
                        communityTitle,
                    text:
                        communityText,
                  ),
                  const SizedBox(height: 14),
                  _PrincipleRow(
                    icon:
                        Icons.pets_rounded,
                    title:
                        stellaTitle,
                    text:
                        stellaText,
                  ),
                  const SizedBox(height: 14),
                  _PrincipleRow(
                    icon:
                        Icons.security_rounded,
                    title:
                        securityTitle,
                    text:
                        securityText,
                  ),
                  const SizedBox(height: 14),
                  _PrincipleRow(
                    icon:
                        Icons.auto_awesome_rounded,
                    title:
                        innovationTitle,
                    text:
                        innovationText,
                  ),
                  const SizedBox(height: 14),
                  _PrincipleRow(
                    icon:
                        Icons.trending_up_rounded,
                    title:
                        growthTitle,
                    text:
                        growthText,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // ==================================================
            // IMPORTANT NOTICE
            // ==================================================

            Container(
              padding:
                  const EdgeInsets.all(20),
              decoration:
                  BoxDecoration(
                color:
                    Colors.orangeAccent.withValues(
                  alpha: 0.07,
                ),
                borderRadius:
                    BorderRadius.circular(20),
                border:
                    Border.all(
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
                    color:
                        Colors.orangeAccent,
                    size: 30,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    noticeTitle,
                    style:
                        const TextStyle(
                      color:
                          Colors.orangeAccent,
                      fontSize: 17,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    noticeText,
                    textAlign:
                        TextAlign.center,
                    style:
                        const TextStyle(
                      color:
                          Colors.white60,
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
              textAlign:
                  TextAlign.center,
              style:
                  const TextStyle(
                color:
                    roadmapPinkColor,
                fontSize: 12,
                fontWeight:
                    FontWeight.bold,
                letterSpacing: 1,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              '17 602 539 062 STL',
              textAlign:
                  TextAlign.center,
              style:
                  TextStyle(
                color:
                    roadmapGoldColor,
                fontSize: 12,
                fontWeight:
                    FontWeight.bold,
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
        // STELLA / PAW MARKER
        // ======================================================

        Container(
          width: 54,
          height: 54,
          decoration:
              BoxDecoration(
            color:
                accent.withValues(
              alpha: 0.12,
            ),
            shape:
                BoxShape.circle,
            border:
                Border.all(
              color:
                  accent.withValues(
                alpha: 0.45,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color:
                    accent.withValues(
                  alpha: 0.08,
                ),
                blurRadius: 12,
              ),
            ],
          ),
          child:
              Center(
            child: Text(
              icon,
              style:
                  const TextStyle(
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
          child:
              Container(
            padding:
                const EdgeInsets.all(18),
            decoration:
                BoxDecoration(
              color:
                  roadmapCardColor,
              borderRadius:
                  BorderRadius.circular(
                20,
              ),
              border:
                  Border.all(
                color:
                    accent.withValues(
                  alpha: 0.17,
                ),
              ),
            ),
            child:
                Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child:
                          Text(
                        phase,
                        style:
                            TextStyle(
                          color:
                              accent,
                          fontSize: 12,
                          fontWeight:
                              FontWeight.bold,
                          letterSpacing:
                              1.5,
                        ),
                      ),
                    ),

                    const SizedBox(
                      width: 8,
                    ),

                    Container(
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration:
                          BoxDecoration(
                        color:
                            accent.withValues(
                          alpha: 0.12,
                        ),
                        borderRadius:
                            BorderRadius.circular(
                          10,
                        ),
                        border:
                            Border.all(
                          color:
                              accent.withValues(
                            alpha: 0.15,
                          ),
                        ),
                      ),
                      child:
                          Text(
                        status,
                        style:
                            TextStyle(
                          color:
                              accent,
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
                  style:
                      const TextStyle(
                    color:
                        Colors.white,
                    fontSize: 20,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  description,
                  style:
                      const TextStyle(
                    color:
                        Colors.white60,
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
      margin:
          const EdgeInsets.only(
        left: 26,
        top: 4,
        bottom: 4,
      ),
      width: 2,
      height: 35,
      decoration:
          BoxDecoration(
        color:
            roadmapAccentColor.withValues(
          alpha: 0.25,
        ),
        borderRadius:
            BorderRadius.circular(
          2,
        ),
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
      width:
          double.infinity,
      padding:
          const EdgeInsets.all(20),
      decoration:
          BoxDecoration(
        color:
            roadmapCardColor,
        borderRadius:
            BorderRadius.circular(
          22,
        ),
        border:
            Border.all(
          color:
              accent.withValues(
            alpha: 0.18,
          ),
        ),
      ),
      child:
          Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration:
                    BoxDecoration(
                  color:
                      accent.withValues(
                    alpha: 0.11,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                ),
                child:
                    Icon(
                  icon,
                  color:
                      accent,
                  size: 24,
                ),
              ),

              const SizedBox(
                width: 12,
              ),

              Expanded(
                child:
                    Text(
                  title,
                  style:
                      const TextStyle(
                    color:
                        Colors.white,
                    fontSize: 20,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 16,
          ),

          child,
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
          color:
              roadmapAccentColor,
          size: 20,
        ),

        const SizedBox(
          width: 10,
        ),

        Expanded(
          child:
              Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style:
                    const TextStyle(
                  color:
                      Colors.white,
                  fontSize: 15,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(
                height: 3,
              ),

              Text(
                text,
                style:
                    const TextStyle(
                  color:
                      Colors.white60,
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