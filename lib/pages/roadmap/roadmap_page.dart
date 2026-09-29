import 'package:flutter/material.dart';

// ============================================================
// 🐱 STELLURIINI - ROADMAP PAGE
// ============================================================
//
// Stella • Stelluriini • STL • Solana
//
// Roadmap tukee HomePagen languageCode-parametria.
//
// ============================================================

class RoadmapPage extends StatefulWidget {
  final String languageCode;

  const RoadmapPage({
    super.key,
    this.languageCode = 'en',
  });

  @override
  State<RoadmapPage> createState() => _RoadmapPageState();
}

class _RoadmapPageState extends State<RoadmapPage>
    with SingleTickerProviderStateMixin {
  // ==========================================================
  // 🎨 STELLURIINI COLORS
  // ==========================================================

  static const Color backgroundColor =
      Color(0xFF120B24);

  static const Color surfaceColor =
      Color(0xFF1A0E31);

  static const Color cardColor =
      Color(0xFF21113B);

  static const Color purpleColor =
      Color(0xFFB58CFF);

  static const Color pinkColor =
      Color(0xFFFFB7E8);

  static const Color goldColor =
      Color(0xFFFFD166);

  static const Color primaryTextColor =
      Color(0xFFF8F4FF);

  static const Color secondaryTextColor =
      Color(0xFFBDB4D1);

  // ==========================================================
  // 🌍 LANGUAGE
  // ==========================================================

  bool get _isFinnish {
    return widget.languageCode.toLowerCase().startsWith('fi');
  }

  bool get _isGerman {
    return widget.languageCode.toLowerCase().startsWith('de');
  }

  bool get _isSpanish {
    return widget.languageCode.toLowerCase().startsWith('es');
  }

  bool get _isFrench {
    return widget.languageCode.toLowerCase().startsWith('fr');
  }

  bool get _isChinese {
    return widget.languageCode.toLowerCase().startsWith('zh');
  }

  bool get _isVietnamese {
    return widget.languageCode.toLowerCase().startsWith('vi');
  }

  bool get _isJapanese {
    return widget.languageCode.toLowerCase().startsWith('ja');
  }

  String _text({
    required String en,
    String? fi,
    String? de,
    String? es,
    String? fr,
    String? zh,
    String? vi,
    String? ja,
  }) {
    if (_isFinnish) {
      return fi ?? en;
    }

    if (_isGerman) {
      return de ?? en;
    }

    if (_isSpanish) {
      return es ?? en;
    }

    if (_isFrench) {
      return fr ?? en;
    }

    if (_isChinese) {
      return zh ?? en;
    }

    if (_isVietnamese) {
      return vi ?? en;
    }

    if (_isJapanese) {
      return ja ?? en;
    }

    return en;
  }

  // ==========================================================
  // ✨ ANIMATION
  // ==========================================================

  late final AnimationController _animationController;

  late final Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 2400,
      ),
    )..repeat(
        reverse: true,
      );

    _glowAnimation = Tween<double>(
      begin: 0.55,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // ==========================================================
  // 🧱 ROADMAP DATA
  // ==========================================================

  List<_RoadmapItem> get _roadmapItems {
    return [
      _RoadmapItem(
        phase: _text(
          en: 'Phase 1 – Foundation',
          fi: 'Vaihe 1 – Perusta',
        ),
        title: _text(
          en: 'Building Stelluriini',
          fi: 'Stelluriinin rakentaminen',
        ),
        description: _text(
          en:
              'Building the Stelluriini project, STL token and Stella ecosystem.',
          fi:
              'Stelluriini-projektin, STL-tokenin ja Stella-ekosysteemin rakentaminen.',
        ),
        status: _text(
          en: 'In Progress',
          fi: 'Käynnissä',
        ),
        icon: Icons.pets_rounded,
        color: pinkColor,
      ),
      _RoadmapItem(
        phase: _text(
          en: 'Phase 2 – App',
          fi: 'Vaihe 2 – Sovellus',
        ),
        title: _text(
          en: 'Stelluriini App Development',
          fi: 'Stelluriini-sovelluksen kehitys',
        ),
        description: _text(
          en:
              'Mining, Stella Power Boost, user progress and transaction history.',
          fi:
              'Louhinta, Stella Power Boost, käyttäjän eteneminen ja tapahtumahistoria.',
        ),
        status: _text(
          en: 'In Progress',
          fi: 'Käynnissä',
        ),
        icon: Icons.groups_rounded,
        color: purpleColor,
      ),
      _RoadmapItem(
        phase: _text(
          en: 'Phase 3 – Community',
          fi: 'Vaihe 3 – Yhteisö',
        ),
        title: _text(
          en: 'Growing the Community',
          fi: 'Yhteisön kasvattaminen',
        ),
        description: _text(
          en:
              'Building the community, collecting feedback and developing the Stelluriini brand.',
          fi:
              'Yhteisön rakentaminen, palautteen kerääminen ja Stelluriini-brändin kehittäminen.',
        ),
        status: _text(
          en: 'Planned',
          fi: 'Suunniteltu',
        ),
        icon: Icons.balance_rounded,
        color: goldColor,
      ),
      _RoadmapItem(
        phase: _text(
          en: 'Phase 4 – Ecosystem',
          fi: 'Vaihe 4 – Ekosysteemi',
        ),
        title: _text(
          en: 'Expanding the STL Ecosystem',
          fi: 'STL-ekosysteemin laajentaminen',
        ),
        description: _text(
          en:
              'Developing STL token use cases and expanding the Stelluriini ecosystem.',
          fi:
              'STL-tokenin käyttötapojen kehittäminen ja Stelluriini-ekosysteemin laajentaminen.',
        ),
        status: _text(
          en: 'Planned',
          fi: 'Suunniteltu',
        ),
        icon: Icons.science_rounded,
        color: purpleColor,
      ),
      _RoadmapItem(
        phase: _text(
          en: 'Phase 5 – Testnet',
          fi: 'Vaihe 5 – Testnet',
        ),
        title: _text(
          en: 'Solana Testnet',
          fi: 'Solana Testnet',
        ),
        description: _text(
          en:
              'Testing STL transfers, wallet connections, transactions and withdrawal functionality before Mainnet.',
          fi:
              'STL-siirtojen, lompakkoyhteyksien, transaktioiden ja nostotoimintojen testaaminen ennen Mainnet-vaihetta.',
        ),
        status: _text(
          en: 'Testing',
          fi: 'Testauksessa',
        ),
        icon: Icons.science_outlined,
        color: purpleColor,
      ),
      _RoadmapItem(
        phase: _text(
          en: 'Phase 6 – Long-Term Development',
          fi: 'Vaihe 6 – Pitkän aikavälin kehitys',
        ),
        title: _text(
          en: 'The Next Stage of Stelluriini',
          fi: 'Stelluriinin seuraava vaihe',
        ),
        description: _text(
          en:
              'Continuous development of the Stelluriini ecosystem, new features and responses to community needs.',
          fi:
              'Stelluriini-ekosysteemin jatkuva kehittäminen, uudet ominaisuudet ja yhteisön tarpeisiin vastaaminen.',
        ),
        status: _text(
          en: 'Future',
          fi: 'Tulevaisuus',
        ),
        icon: Icons.lock_open_rounded,
        color: pinkColor,
      ),
      _RoadmapItem(
        phase: _text(
          en: 'Phase 7 – Mainnet',
          fi: 'Vaihe 7 – Mainnet',
        ),
        title: _text(
          en: 'Solana Mainnet & STL Withdrawals',
          fi: 'Solana Mainnet ja STL-nostot',
        ),
        description: _text(
          en:
              'Opening the Stelluriini Solana Mainnet phase and introducing STL withdrawals after testing and security checks.',
          fi:
              'Stelluriinin Solana Mainnet -vaiheen avaaminen ja STL-nostojen käyttöönotto testauksen ja turvallisuustarkistusten jälkeen.',
        ),
        status: _text(
          en: 'Future',
          fi: 'Tulevaisuus',
        ),
        icon: Icons.rocket_launch_rounded,
        color: goldColor,
      ),
      _RoadmapItem(
        phase: _text(
          en: 'Phase 8 – Ecosystem',
          fi: 'Vaihe 8 – Ekosysteemi',
        ),
        title: _text(
          en: 'Exchange & Ecosystem',
          fi: 'Pörssi ja ekosysteemi',
        ),
        description: _text(
          en:
              'Exploring DEX and CEX opportunities, liquidity solutions, partnerships and future STL use cases.',
          fi:
              'DEX- ja CEX-mahdollisuuksien, likviditeettiratkaisujen, kumppanuuksien ja STL:n tulevien käyttötapojen tutkiminen.',
        ),
        status: _text(
          en: 'Future',
          fi: 'Tulevaisuus',
        ),
        icon: Icons.account_balance_rounded,
        color: purpleColor,
      ),
    ];
  }

  // ==========================================================
  // 🏷️ STATUS COLOR
  // ==========================================================

  Color _statusColor(
    String status,
  ) {
    if (status == 'In Progress' ||
        status == 'Käynnissä') {
      return pinkColor;
    }

    if (status == 'Testing' ||
        status == 'Testauksessa') {
      return goldColor;
    }

    if (status == 'Planned' ||
        status == 'Suunniteltu') {
      return purpleColor;
    }

    if (status == 'Future' ||
        status == 'Tulevaisuus') {
      return goldColor;
    }

    return purpleColor;
  }

  // ==========================================================
  // 🏷️ STATUS ICON
  // ==========================================================

  IconData _statusIcon(
    String status,
  ) {
    if (status == 'In Progress' ||
        status == 'Käynnissä') {
      return Icons.play_circle_fill_rounded;
    }

    if (status == 'Testing' ||
        status == 'Testauksessa') {
      return Icons.science_rounded;
    }

    if (status == 'Planned' ||
        status == 'Suunniteltu') {
      return Icons.schedule_rounded;
    }

    if (status == 'Future' ||
        status == 'Tulevaisuus') {
      return Icons.auto_awesome_rounded;
    }

    return Icons.circle;
  }

  // ==========================================================
  // 🌟 GLOW
  // ==========================================================

  Widget _buildAnimatedGlow(
    Color color,
  ) {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (
        BuildContext context,
        Widget? child,
      ) {
        final double value =
            _glowAnimation.value;

        return Container(
          width: 95 + (value * 10),
          height: 95 + (value * 10),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                color.withValues(
                  alpha: 0.18 * value,
                ),
                color.withValues(
                  alpha: 0.06 * value,
                ),
                Colors.transparent,
              ],
              stops: const [
                0.0,
                0.55,
                1.0,
              ],
            ),
          ),
        );
      },
    );
  }

  // ==========================================================
  // 🟣 PHASE ICON
  // ==========================================================

  Widget _buildPhaseIcon(
    _RoadmapItem item,
  ) {
    return SizedBox(
      width: 92,
      height: 92,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _buildAnimatedGlow(
            item.color,
          ),
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: surfaceColor,
              border: Border.all(
                color: item.color.withValues(
                  alpha: 0.55,
                ),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: item.color.withValues(
                    alpha: 0.20,
                  ),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              item.icon,
              color: item.color,
              size: 36,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // 🏷️ STATUS BADGE
  // ==========================================================

  Widget _buildStatusBadge(
    String status,
  ) {
    final Color color =
        _statusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: color.withValues(
          alpha: 0.12,
        ),
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(
            alpha: 0.35,
          ),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _statusIcon(status),
            color: color,
            size: 15,
          ),
          const SizedBox(width: 6),
          Text(
            status,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight:
                  FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // 📦 ROADMAP CARD
  // ==========================================================

  Widget _buildRoadmapCard(
    _RoadmapItem item,
  ) {
    return Container(
      margin: const EdgeInsets.only(
        bottom: 22,
      ),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius:
            BorderRadius.circular(28),
        border: Border.all(
          color: item.color.withValues(
            alpha: 0.22,
          ),
          width: 1.3,
        ),
        boxShadow: [
          BoxShadow(
            color: item.color.withValues(
              alpha: 0.07,
            ),
            blurRadius: 25,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          20,
          20,
          20,
          22,
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                _buildPhaseIcon(item),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              item.phase,
                              style: TextStyle(
                                color:
                                    item.color,
                                fontSize: 15,
                                fontWeight:
                                    FontWeight.w800,
                                letterSpacing:
                                    0.7,
                              ),
                            ),
                          ),
                          const SizedBox(
                            width: 8,
                          ),
                          _buildStatusBadge(
                            item.status,
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 12,
                      ),
                      Text(
                        item.title,
                        style:
                            const TextStyle(
                          color:
                              primaryTextColor,
                          fontSize: 25,
                          fontWeight:
                              FontWeight.w800,
                          height: 1.15,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              item.description,
              style: const TextStyle(
                color:
                    secondaryTextColor,
                fontSize: 16,
                height: 1.55,
              ),
            ),
            if (item.phase ==
                    _text(
                      en: 'Phase 7 – Mainnet',
                      fi: 'Vaihe 7 – Mainnet',
                    )) ...[
              const SizedBox(height: 18),
              _buildMainnetNotice(),
            ],
            if (item.phase ==
                    _text(
                      en: 'Phase 8 – Ecosystem',
                      fi: 'Vaihe 8 – Ekosysteemi',
                    )) ...[
              const SizedBox(height: 18),
              _buildEcosystemPoints(),
            ],
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // 🚀 MAINNET NOTICE
  // ==========================================================

  Widget _buildMainnetNotice() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: goldColor.withValues(
          alpha: 0.08,
        ),
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: goldColor.withValues(
            alpha: 0.28,
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.rocket_launch_rounded,
                color: goldColor,
                size: 23,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _text(
                    en:
                        'Mainnet = future release • Not active yet',
                    fi:
                        'Mainnet = tuleva julkaisu • Ei vielä käytössä',
                  ),
                  style: const TextStyle(
                    color: goldColor,
                    fontSize: 14,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _text(
              en:
                  'Before launch, Solana integration, wallets, STL transfers, withdrawals and security solutions will be tested.',
              fi:
                  'Ennen käyttöönottoa Solana-integraatio, lompakot, STL-siirrot, nostot ja turvallisuusratkaisut testataan.',
            ),
            style: const TextStyle(
              color: secondaryTextColor,
              fontSize: 14,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // 🌌 ECOSYSTEM POINTS
  // ==========================================================

  Widget _buildEcosystemPoints() {
    final List<String> points = [
      _text(
        en: 'Exploring DEX and CEX opportunities',
        fi: 'DEX- ja CEX-mahdollisuuksien tutkiminen',
      ),
      _text(
        en: 'Preparing liquidity solutions',
        fi: 'Likviditeettiratkaisujen valmistelu',
      ),
      _text(
        en: 'Expanding the STL ecosystem',
        fi: 'STL-ekosysteemin laajentaminen',
      ),
      _text(
        en: 'Developing partnerships',
        fi: 'Kumppanuuksien kehittäminen',
      ),
      _text(
        en: 'Introducing new Stella experiences',
        fi: 'Uusien Stella-kokemusten esittely',
      ),
      _text(
        en: 'Exploring future STL use cases',
        fi: 'STL:n tulevien käyttötapojen tutkiminen',
      ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: purpleColor.withValues(
            alpha: 0.18,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            _text(
              en: 'Exchange & Ecosystem',
              fi: 'Pörssi ja ekosysteemi',
            ),
            style: const TextStyle(
              color: primaryTextColor,
              fontSize: 18,
              fontWeight:
                  FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          ...points.map(
            (String point) {
              return Padding(
                padding:
                    const EdgeInsets.only(
                  bottom: 9,
                ),
                child: Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '✦',
                      style: TextStyle(
                        color: purpleColor,
                        fontSize: 17,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        point,
                        style:
                            const TextStyle(
                          color:
                              secondaryTextColor,
                          fontSize: 14,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // ⚖️ MINING ECONOMY
  // ==========================================================

  Widget _buildMiningBalanceCard() {
    return Container(
      margin: const EdgeInsets.only(
        bottom: 22,
      ),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius:
            BorderRadius.circular(28),
        border: Border.all(
          color: goldColor.withValues(
            alpha: 0.22,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: goldColor.withValues(
                    alpha: 0.10,
                  ),
                  borderRadius:
                      BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.speed_rounded,
                  color: goldColor,
                  size: 30,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  _text(
                    en: 'Mining Economy Balance',
                    fi: 'Louhintatalouden tasapaino',
                  ),
                  style: const TextStyle(
                    color: primaryTextColor,
                    fontSize: 25,
                    fontWeight:
                        FontWeight.w800,
                    height: 1.15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            _text(
              en:
                  'The mining system is designed so that daily STL generation does not grow without limits. Hash Rate, Power Boost and Referral bonuses are designed together to keep the system manageable.',
              fi:
                  'Louhintajärjestelmän tavoitteena ei ole kasvattaa päivittäistä STL-määrää rajattomasti. Hash Rate, Power Boost ja Referral-bonukset suunnitellaan yhdessä niin, että kokonaisuus pysyy hallittavana.',
            ),
            style: const TextStyle(
              color: secondaryTextColor,
              fontSize: 16,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 22),
          _buildInfoRow(
            icon: Icons.bolt_rounded,
            title: 'Hash Rate',
            text: _text(
              en:
                  'Base mining determines the user\'s normal Hash Rate level.',
              fi:
                  'Peruslouhinta muodostaa käyttäjän normaalin Hash Rate -tason.',
            ),
            color: purpleColor,
          ),
          const SizedBox(height: 18),
          _buildInfoRow(
            icon: Icons.flash_on_rounded,
            title: 'Power Boost',
            text: _text(
              en:
                  'Power Boost provides a temporary increase in mining power.',
              fi:
                  'Power Boost tarjoaa määräaikaisen lisäyksen käyttäjän louhintatehoon.',
            ),
            color: pinkColor,
          ),
          const SizedBox(height: 18),
          _buildInfoRow(
            icon: Icons.groups_rounded,
            title: 'Referral',
            text: _text(
              en:
                  'Referral bonuses are designed to remain balanced as the community grows.',
              fi:
                  'Referral-bonukset suunnitellaan kasvun mukana tasapainottuviksi.',
            ),
            color: goldColor,
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // ℹ️ INFO ROW
  // ==========================================================

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String text,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: color,
          size: 25,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: primaryTextColor,
                  fontSize: 17,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                text,
                style: const TextStyle(
                  color: secondaryTextColor,
                  fontSize: 14,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // 💎 WITHDRAWAL CARD
  // ==========================================================

  Widget _buildWithdrawalCard() {
    return Container(
      margin: const EdgeInsets.only(
        bottom: 22,
      ),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius:
            BorderRadius.circular(28),
        border: Border.all(
          color: goldColor.withValues(
            alpha: 0.24,
          ),
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.account_balance_wallet_rounded,
            color: goldColor,
            size: 44,
          ),
          const SizedBox(height: 14),
          Text(
            _text(
              en: 'Potential Future Withdrawals',
              fi: 'Mahdolliset tulevat nostot',
            ),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: goldColor,
              fontSize: 23,
              fontWeight:
                  FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _text(
              en:
                  'A possible future withdrawal system will be designed separately and its terms will be announced before implementation.',
              fi:
                  'Mahdollinen tuleva nostojärjestelmä suunnitellaan erikseen ja sen ehdot ilmoitetaan ennen käyttöönottoa.',
            ),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: secondaryTextColor,
              fontSize: 15,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius:
                  BorderRadius.circular(18),
              border: Border.all(
                color: goldColor.withValues(
                  alpha: 0.18,
                ),
              ),
            ),
            child: Column(
              children: [
                Text(
                  _text(
                    en: 'Planned minimum withdrawal',
                    fi: 'Suunniteltu vähimmäisnosto',
                  ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color:
                        secondaryTextColor,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  '100 STL',
                  style: TextStyle(
                    color: goldColor,
                    fontSize: 25,
                    fontWeight:
                        FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _text(
                    en:
                        'User pays the Solana network fee.',
                    fi:
                        'Käyttäjä maksaa Solana-verkon kulun.',
                  ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color:
                        secondaryTextColor,
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // 🐾 STELLA JOURNEY
  // ==========================================================

  Widget _buildStellaJourney() {
    return Container(
      margin: const EdgeInsets.only(
        bottom: 22,
      ),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius:
            BorderRadius.circular(28),
        border: Border.all(
          color: pinkColor.withValues(
            alpha: 0.22,
          ),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: surfaceColor,
              border: Border.all(
                color: pinkColor.withValues(
                  alpha: 0.35,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: pinkColor.withValues(
                    alpha: 0.12,
                  ),
                  blurRadius: 24,
                ),
              ],
            ),
            child: const Icon(
              Icons.pets_rounded,
              color: pinkColor,
              size: 48,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _text(
              en: 'Stella\'s Journey 🐾',
              fi: 'Stellan matka 🐾',
            ),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: pinkColor,
              fontSize: 25,
              fontWeight:
                  FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _text(
              en:
                  'The Stelluriini ecosystem will be developed step by step around the community, app and STL token.',
              fi:
                  'Stelluriini-ekosysteemiä kehitetään askel askeleelta yhteisön, sovelluksen ja STL-tokenin ympärille.',
            ),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: secondaryTextColor,
              fontSize: 16,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // 🛡️ DEVELOPMENT PRINCIPLES
  // ==========================================================

  Widget _buildDevelopmentPrinciples() {
    return Container(
      margin: const EdgeInsets.only(
        bottom: 22,
      ),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius:
            BorderRadius.circular(28),
        border: Border.all(
          color: purpleColor.withValues(
            alpha: 0.22,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: goldColor.withValues(
                    alpha: 0.10,
                  ),
                  borderRadius:
                      BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.rocket_launch_rounded,
                  color: goldColor,
                  size: 30,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  _text(
                    en: 'Development Principles',
                    fi: 'Kehitysperiaatteet',
                  ),
                  style: const TextStyle(
                    color: primaryTextColor,
                    fontSize: 24,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildInfoRow(
            icon: Icons.groups_rounded,
            title: _text(
              en: 'Community',
              fi: 'Yhteisö',
            ),
            text: _text(
              en:
                  'The community is at the heart of Stelluriini development. Feedback and user ideas help guide future development.',
              fi:
                  'Yhteisö on Stelluriinin kehityksen ytimessä. Palaute ja käyttäjien ideat auttavat ohjaamaan tulevaa kehitystä.',
            ),
            color: purpleColor,
          ),
          const SizedBox(height: 20),
          _buildInfoRow(
            icon: Icons.security_rounded,
            title: _text(
              en: 'Security',
              fi: 'Turvallisuus',
            ),
            text: _text(
              en:
                  'Security, server infrastructure and application reliability will be continuously improved.',
              fi:
                  'Turvallisuutta, palvelininfrastruktuuria ja sovelluksen luotettavuutta kehitetään jatkuvasti.',
            ),
            color: purpleColor,
          ),
          const SizedBox(height: 20),
          _buildInfoRow(
            icon: Icons.shield_rounded,
            title: _text(
              en: 'Anti-Bot Protection',
              fi: 'Botintorjunta',
            ),
            text: _text(
              en:
                  'The system considers bots, automation and abuse detection.',
              fi:
                  'Järjestelmässä huomioidaan botit, automaatio ja väärinkäytösten tunnistaminen.',
            ),
            color: pinkColor,
          ),
          const SizedBox(height: 20),
          _buildInfoRow(
            icon: Icons.auto_awesome_rounded,
            title: _text(
              en: 'Innovation',
              fi: 'Innovaatio',
            ),
            text: _text(
              en:
                  'New use cases, features and technologies will be explored as the project develops.',
              fi:
                  'Uusia käyttötapoja, ominaisuuksia ja teknologioita tutkitaan projektin kehittyessä.',
            ),
            color: purpleColor,
          ),
          const SizedBox(height: 20),
          _buildInfoRow(
            icon: Icons.trending_up_rounded,
            title: _text(
              en: 'Long-Term Growth',
              fi: 'Pitkän aikavälin kasvu',
            ),
            text: _text(
              en:
                  'The goal is to build a sustainable and gradually evolving Stelluriini ecosystem.',
              fi:
                  'Tavoitteena on rakentaa kestävä ja asteittain kehittyvä Stelluriini-ekosysteemi.',
            ),
            color: goldColor,
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // ⚠️ IMPORTANT NOTICE
  // ==========================================================

  Widget _buildImportantNotice() {
    return Container(
      margin: const EdgeInsets.only(
        bottom: 22,
      ),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF211827),
        borderRadius:
            BorderRadius.circular(28),
        border: Border.all(
          color: goldColor.withValues(
            alpha: 0.28,
          ),
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: goldColor,
            size: 42,
          ),
          const SizedBox(height: 14),
          Text(
            _text(
              en: 'Important Notice',
              fi: 'Tärkeä huomautus',
            ),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: goldColor,
              fontSize: 23,
              fontWeight:
                  FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _text(
              en:
                  'The roadmap describes the planned development direction of Stelluriini. Phases, features and timelines may change during project development.',
              fi:
                  'Roadmap kuvaa Stelluriinin suunniteltua kehityssuuntaa. Vaiheet, ominaisuudet ja aikataulut voivat muuttua projektin kehityksen aikana.',
            ),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: secondaryTextColor,
              fontSize: 15,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // 🏠 BUILD
  // ==========================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          backgroundColor,
      appBar: AppBar(
        backgroundColor:
            surfaceColor,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: primaryTextColor,
            size: 30,
          ),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: Text(
          _text(
            en: 'Stelluriini Roadmap',
            fi: 'Stelluriini Roadmap',
          ),
          style: const TextStyle(
            color: primaryTextColor,
            fontSize: 25,
            fontWeight:
                FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics:
              const BouncingScrollPhysics(),
          padding:
              const EdgeInsets.fromLTRB(
            20,
            22,
            20,
            40,
          ),
          child: Column(
            children: [
              // ==================================================
              // 🗺️ JOURNEY HEADER
              // ==================================================

              Container(
                width: double.infinity,
                margin:
                    const EdgeInsets.only(
                  bottom: 22,
                ),
                padding:
                    const EdgeInsets.all(22),
                decoration:
                    BoxDecoration(
                  color: cardColor,
                  borderRadius:
                      BorderRadius.circular(
                    28,
                  ),
                  border: Border.all(
                    color:
                        purpleColor.withValues(
                      alpha: 0.24,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 58,
                          height: 58,
                          decoration:
                              BoxDecoration(
                            color:
                                purpleColor.withValues(
                              alpha: 0.10,
                            ),
                            borderRadius:
                                BorderRadius
                                    .circular(
                              18,
                            ),
                          ),
                          child: const Icon(
                            Icons.map_rounded,
                            color:
                                purpleColor,
                            size: 31,
                          ),
                        ),
                        const SizedBox(
                          width: 14,
                        ),
                        Expanded(
                          child: Text(
                            _text(
                              en:
                                  'The Stelluriini Journey',
                              fi:
                                  'Stelluriinin matka',
                            ),
                            style:
                                const TextStyle(
                              color:
                                  primaryTextColor,
                              fontSize: 24,
                              fontWeight:
                                  FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 18,
                    ),
                    Text(
                      _text(
                        en:
                            'Stelluriini development progresses step by step toward a broader community, ecosystem and new use cases.',
                        fi:
                            'Stelluriinin kehitys etenee askel askeleelta kohti laajempaa yhteisöä, ekosysteemiä ja uusia käyttötapoja.',
                      ),
                      style: const TextStyle(
                        color:
                            secondaryTextColor,
                        fontSize: 16,
                        height: 1.55,
                      ),
                    ),
                  ],
                ),
              ),

              // ==================================================
              // 🐾 ROADMAP PHASES
              // ==================================================

              ..._roadmapItems.map(
                (_RoadmapItem item) {
                  return _buildRoadmapCard(
                    item,
                  );
                },
              ),

              // ==================================================
              // ⚖️ MINING BALANCE
              // ==================================================

              _buildMiningBalanceCard(),

              // ==================================================
              // 💎 WITHDRAWALS
              // ==================================================

              _buildWithdrawalCard(),

              // ==================================================
              // 🐱 STELLA JOURNEY
              // ==================================================

              _buildStellaJourney(),

              // ==================================================
              // 🚀 DEVELOPMENT PRINCIPLES
              // ==================================================

              _buildDevelopmentPrinciples(),

              // ==================================================
              // ⚠️ NOTICE
              // ==================================================

              _buildImportantNotice(),

              const SizedBox(height: 8),

              const Text(
                'STELLA • STELLURIINI • STL • SOLANA',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: pinkColor,
                  fontSize: 14,
                  fontWeight:
                      FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// 📦 ROADMAP MODEL
// ============================================================

class _RoadmapItem {
  final String phase;
  final String title;
  final String description;
  final String status;
  final IconData icon;
  final Color color;

  const _RoadmapItem({
    required this.phase,
    required this.title,
    required this.description,
    required this.status,
    required this.icon,
    required this.color,
  });
}