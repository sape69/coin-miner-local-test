import 'package:flutter/material.dart';

// ============================================================
// 🐱 STELLURIINI - ROADMAP PAGE
// ============================================================
//
// Stella • Stelluriini • STL • Solana
//
// Roadmap:
// 1. Foundation & App
// 2. Community & Referral
// 3. Mining Economy Balance
// 4. Solana Testnet Preparation
// 5. Solana Testnet
// 6. Long-Term Development
// 7. Solana Mainnet & STL Withdrawals
// 8. Exchange & Ecosystem
//
// IMPORTANT:
// - Mainnet is NOT currently active.
// - Withdrawals are NOT currently active.
// - 100 STL is a planned minimum withdrawal model.
// - Roadmap items may change during development.
//
// ============================================================

class RoadmapPage extends StatefulWidget {
  // ==========================================================
  // 🌍 LANGUAGE
  // ==========================================================

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

  final List<_RoadmapItem> _roadmapItems = const [
    _RoadmapItem(
      phase: 'Phase 1 – Foundation',
      title: 'Building Stelluriini',
      description:
          'Building the Stelluriini project, STL token and Stella ecosystem.',
      status: 'In Progress',
      icon: Icons.pets_rounded,
      color: pinkColor,
    ),
    _RoadmapItem(
      phase: 'Phase 2 – App',
      title: 'Stelluriini App Development',
      description:
          'Mining, Stella Power Boost, user progress and transaction history.',
      status: 'In Progress',
      icon: Icons.groups_rounded,
      color: purpleColor,
    ),
    _RoadmapItem(
      phase: 'Phase 3 – Community',
      title: 'Growing the Community',
      description:
          'Building the community, collecting feedback and developing the Stelluriini brand.',
      status: 'Planned',
      icon: Icons.balance_rounded,
      color: goldColor,
    ),
    _RoadmapItem(
      phase: 'Phase 4 – Ecosystem',
      title: 'Expanding the STL Ecosystem',
      description:
          'Developing STL token use cases and expanding the Stelluriini ecosystem.',
      status: 'Planned',
      icon: Icons.science_rounded,
      color: purpleColor,
    ),
    _RoadmapItem(
      phase: 'Phase 5 – Testnet',
      title: 'Solana Testnet',
      description:
          'Testing STL transfers, wallet connections, transactions and withdrawal functionality before Mainnet.',
      status: 'Testing',
      icon: Icons.science_outlined,
      color: purpleColor,
    ),
    _RoadmapItem(
      phase: 'Phase 6 – Long-Term Development',
      title: 'The Next Stage of Stelluriini',
      description:
          'Continuous development of the Stelluriini ecosystem, new features and responses to community needs.',
      status: 'Future',
      icon: Icons.lock_open_rounded,
      color: pinkColor,
    ),
    _RoadmapItem(
      phase: 'Phase 7 – Mainnet',
      title: 'Solana Mainnet & STL Withdrawals',
      description:
          'Opening the Stelluriini Solana Mainnet phase and introducing STL withdrawals after testing and security checks.',
      status: 'Future',
      icon: Icons.rocket_launch_rounded,
      color: goldColor,
    ),
    _RoadmapItem(
      phase: 'Phase 8 – Ecosystem',
      title: 'Exchange & Ecosystem',
      description:
          'Exploring DEX and CEX opportunities, liquidity solutions, partnerships and future STL use cases.',
      status: 'Future',
      icon: Icons.account_balance_rounded,
      color: purpleColor,
    ),
  ];

  // ==========================================================
  // 🏷️ STATUS COLOR
  // ==========================================================

  Color _statusColor(
    String status,
  ) {
    switch (status) {
      case 'In Progress':
        return pinkColor;

      case 'Testing':
        return goldColor;

      case 'Planned':
        return purpleColor;

      case 'Future':
        return goldColor;

      default:
        return purpleColor;
    }
  }

  // ==========================================================
  // 🏷️ STATUS ICON
  // ==========================================================

  IconData _statusIcon(
    String status,
  ) {
    switch (status) {
      case 'In Progress':
        return Icons.play_circle_fill_rounded;

      case 'Testing':
        return Icons.science_rounded;

      case 'Planned':
        return Icons.schedule_rounded;

      case 'Future':
        return Icons.auto_awesome_rounded;

      default:
        return Icons.circle;
    }
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
                'Phase 7 – Mainnet') ...[
              const SizedBox(height: 18),
              _buildMainnetNotice(),
            ],

            if (item.phase ==
                'Phase 8 – Ecosystem') ...[
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
              Icon(
                Icons.rocket_launch_rounded,
                color: goldColor,
                size: 23,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Mainnet = tuleva julkaisu • Ei vielä käytössä',
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
          const Text(
            'Ennen käyttöönottoa Solana-integraatio, '
            'lompakot, STL-siirrot, nostot ja '
            'turvallisuusratkaisut testataan.',
            style: TextStyle(
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
    const List<String> points = [
      'DEX- ja CEX-mahdollisuuksien tutkiminen',
      'Likviditeettiratkaisujen valmistelu',
      'STL-ekosysteemin laajentaminen',
      'Kumppanuuksien kehittäminen',
      'Uusien Stella-kokemusten esittely',
      'STL:n tulevien käyttötapojen tutkiminen',
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
          const Text(
            'Pörssi ja ekosysteemi',
            style: TextStyle(
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
              const Expanded(
                child: Text(
                  'Louhintatalouden tasapaino',
                  style: TextStyle(
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

          const Text(
            'Louhintajärjestelmän tavoitteena ei ole '
            'kasvattaa päivittäistä STL-määrää '
            'rajattomasti. Hash Rate, Power Boost '
            'ja Referral-bonukset suunnitellaan '
            'yhdessä niin, että kokonaisuus pysyy '
            'hallittavana.',
            style: TextStyle(
              color: secondaryTextColor,
              fontSize: 16,
              height: 1.55,
            ),
          ),

          const SizedBox(height: 22),

          _buildInfoRow(
            icon: Icons.bolt_rounded,
            title: 'Hash Rate',
            text:
                'Peruslouhinta muodostaa käyttäjän normaalin Hash Rate -tason.',
            color: purpleColor,
          ),

          const SizedBox(height: 18),

          _buildInfoRow(
            icon: Icons.flash_on_rounded,
            title: 'Power Boost',
            text:
                'Power Boost tarjoaa määräaikaisen lisäyksen käyttäjän louhintatehoon.',
            color: pinkColor,
          ),

          const SizedBox(height: 18),

          _buildInfoRow(
            icon: Icons.groups_rounded,
            title: 'Referral',
            text:
                'Referral-bonukset suunnitellaan kasvun mukana tasapainottuviksi.',
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
          const Text(
            'Potential Future Withdrawals',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: goldColor,
              fontSize: 23,
              fontWeight:
                  FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'A possible future withdrawal system '
            'will be designed separately and its '
            'terms will be announced before implementation.',
            textAlign: TextAlign.center,
            style: TextStyle(
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
            child: const Column(
              children: [
                Text(
                  'Planned minimum withdrawal',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color:
                        secondaryTextColor,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  '100 STL',
                  style: TextStyle(
                    color: goldColor,
                    fontSize: 25,
                    fontWeight:
                        FontWeight.w900,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'User pays the Solana network fee.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
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
          const Text(
            'Stella’s Journey 🐾',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: pinkColor,
              fontSize: 25,
              fontWeight:
                  FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'The Stelluriini ecosystem will be developed '
            'step by step around the community, app and STL token.',
            textAlign: TextAlign.center,
            style: TextStyle(
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
              const Expanded(
                child: Text(
                  'Development Principles',
                  style: TextStyle(
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
            title: 'Community',
            text:
                'The community is at the heart of Stelluriini development. Feedback and user ideas help guide future development.',
            color: purpleColor,
          ),

          const SizedBox(height: 20),

          _buildInfoRow(
            icon: Icons.security_rounded,
            title: 'Security',
            text:
                'Security, server infrastructure and application reliability will be continuously improved.',
            color: purpleColor,
          ),

          const SizedBox(height: 20),

          _buildInfoRow(
            icon: Icons.shield_rounded,
            title: 'Botintorjunta',
            text:
                'Järjestelmässä huomioidaan botit, automaatio ja väärinkäytösten tunnistaminen.',
            color: pinkColor,
          ),

          const SizedBox(height: 20),

          _buildInfoRow(
            icon: Icons.auto_awesome_rounded,
            title: 'Innovation',
            text:
                'New use cases, features and technologies will be explored as the project develops.',
            color: purpleColor,
          ),

          const SizedBox(height: 20),

          _buildInfoRow(
            icon: Icons.trending_up_rounded,
            title: 'Long-Term Growth',
            text:
                'The goal is to build a sustainable and gradually evolving Stelluriini ecosystem.',
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
          const Text(
            'Important Notice',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: goldColor,
              fontSize: 23,
              fontWeight:
                  FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'The roadmap describes the planned '
            'development direction of Stelluriini. '
            'Phases, features and timelines may '
            'change during project development.',
            textAlign: TextAlign.center,
            style: TextStyle(
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
        title: const Text(
          'Stelluriini Roadmap',
          style: TextStyle(
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
                        const Expanded(
                          child: Text(
                            'The Stelluriini Journey',
                            style:
                                TextStyle(
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
                    const Text(
                      'Stelluriini development progresses '
                      'step by step toward a broader '
                      'community, ecosystem and new use cases.',
                      style: TextStyle(
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
                (
                  _RoadmapItem item,
                ) {
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

              // ==================================================
              // 🐾 FOOTER
              // ==================================================

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