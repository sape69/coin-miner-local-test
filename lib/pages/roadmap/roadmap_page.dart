import 'package:flutter/material.dart';

import '../../localization/roadmap/roadmap_localization.dart';
import '../../widgets/stelluriini_logo.dart';

// ============================================================
// 🐱 STELLURIINI - ROADMAP PAGE
// ============================================================
//
// Stella • Stelluriini • STL • Solana
//
// Lokalisoitu Roadmap.
//
// HomePage antaa sivulle aktiivisen languageCode-arvon.
//
// ============================================================

class RoadmapPage extends StatefulWidget {
  final String languageCode;

  const RoadmapPage({
    super.key,
    this.languageCode = 'en',
  });

  @override
  State<RoadmapPage> createState() =>
      _RoadmapPageState();
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
  // 🌍 LOCALIZATION
  // ==========================================================

  RoadmapLocalization get _localization =>
      RoadmapLocalization(
        widget.languageCode,
      );

  // ==========================================================
  // ✨ ANIMATION
  // ==========================================================

  late final AnimationController _animationController;

  late final Animation<double> _glowAnimation;

  // ==========================================================
  // 🚀 INIT
  // ==========================================================

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

  // ==========================================================
  // 🧹 DISPOSE
  // ==========================================================

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
        phase: _localization.get(
          'phase1',
        ),
        title: _localization.get(
          'phase1Title',
        ),
        description: _localization.get(
          'phase1Description',
        ),
        status: _localization.get(
          'statusInProgress',
        ),
        icon: Icons.pets_rounded,
        color: pinkColor,

        // 🐱 Stelluriini-logo
        useStelluriiniLogo: true,
      ),

      // ========================================================
      // 👥 PHASE 2
      // ========================================================
      //
      // TÄMÄ JÄTETÄÄN RYHMÄKUVAKKEEKSI.
      //

      _RoadmapItem(
        phase: _localization.get(
          'phase2',
        ),
        title: _localization.get(
          'phase2Title',
        ),
        description: _localization.get(
          'phase2Description',
        ),
        status: _localization.get(
          'statusInProgress',
        ),
        icon: Icons.groups_rounded,
        color: purpleColor,
      ),

      _RoadmapItem(
        phase: _localization.get(
          'phase3',
        ),
        title: _localization.get(
          'phase3Title',
        ),
        description: _localization.get(
          'phase3Description',
        ),
        status: _localization.get(
          'statusPlanned',
        ),
        icon: Icons.balance_rounded,
        color: goldColor,
      ),

      _RoadmapItem(
        phase: _localization.get(
          'phase4',
        ),
        title: _localization.get(
          'phase4Title',
        ),
        description: _localization.get(
          'phase4Description',
        ),
        status: _localization.get(
          'statusPlanned',
        ),
        icon: Icons.science_rounded,
        color: purpleColor,
      ),

      _RoadmapItem(
        phase: _localization.get(
          'phase5',
        ),
        title: _localization.get(
          'phase5Title',
        ),
        description: _localization.get(
          'phase5Description',
        ),
        status: _localization.get(
          'statusTesting',
        ),
        icon: Icons.science_outlined,
        color: purpleColor,
      ),

      _RoadmapItem(
        phase: _localization.get(
          'phase6',
        ),
        title: _localization.get(
          'phase6Title',
        ),
        description: _localization.get(
          'phase6Description',
        ),
        status: _localization.get(
          'statusFuture',
        ),
        icon: Icons.lock_open_rounded,
        color: pinkColor,
      ),

      _RoadmapItem(
        phase: _localization.get(
          'phase7',
        ),
        title: _localization.get(
          'phase7Title',
        ),
        description: _localization.get(
          'phase7Description',
        ),
        status: _localization.get(
          'statusFuture',
        ),
        icon: Icons.rocket_launch_rounded,
        color: goldColor,
      ),

      _RoadmapItem(
        phase: _localization.get(
          'phase8',
        ),
        title: _localization.get(
          'phase8Title',
        ),
        description: _localization.get(
          'phase8Description',
        ),
        status: _localization.get(
          'statusFuture',
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
    if (status ==
        _localization.get(
          'statusInProgress',
        )) {
      return pinkColor;
    }

    if (status ==
        _localization.get(
          'statusTesting',
        )) {
      return goldColor;
    }

    if (status ==
        _localization.get(
          'statusPlanned',
        )) {
      return purpleColor;
    }

    if (status ==
        _localization.get(
          'statusFuture',
        )) {
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
    if (status ==
        _localization.get(
          'statusInProgress',
        )) {
      return Icons.play_circle_fill_rounded;
    }

    if (status ==
        _localization.get(
          'statusTesting',
        )) {
      return Icons.science_rounded;
    }

    if (status ==
        _localization.get(
          'statusPlanned',
        )) {
      return Icons.schedule_rounded;
    }

    if (status ==
        _localization.get(
          'statusFuture',
        )) {
      return Icons.auto_awesome_rounded;
    }

    return Icons.circle;
  }

  // ==========================================================
  // 🌟 ANIMATED GLOW
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

            // ==================================================
            // 🐱 STELLURIINI LOGO
            // ==================================================

            child: item.useStelluriiniLogo
                ? const Center(
                    child: StelluriiniLogo(
                      size: 52,
                    ),
                  )
                : Icon(
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
              fontWeight: FontWeight.w800,
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
                                color: item.color,
                                fontSize: 15,
                                fontWeight:
                                    FontWeight.w800,
                                letterSpacing: 0.7,
                              ),
                            ),
                          ),

                          const SizedBox(
                            width: 8,
                          ),

                          Flexible(
                            child:
                                _buildStatusBadge(
                              item.status,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(
                        height: 12,
                      ),

                      Text(
                        item.title,
                        style: const TextStyle(
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

            const SizedBox(
              height: 18,
            ),

            Text(
              item.description,
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
    );
  }

  // ==========================================================
  // ⚖️ MINING BALANCE
  // ==========================================================

  Widget _buildMiningBalanceCard() {
    return _buildSimpleSectionCard(
      icon: Icons.speed_rounded,
      iconColor: goldColor,
      title: _localization.get(
        'miningBalanceTitle',
      ),
      children: [
        Text(
          _localization.get(
            'miningBalanceDescription',
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
          title: _localization.get(
            'hashRateTitle',
          ),
          text: _localization.get(
            'hashRateDescription',
          ),
          color: purpleColor,
        ),

        const SizedBox(height: 18),

        _buildInfoRow(
          icon: Icons.flash_on_rounded,
          title: _localization.get(
            'powerBoostTitle',
          ),
          text: _localization.get(
            'powerBoostDescription',
          ),
          color: pinkColor,
        ),

        const SizedBox(height: 18),

        _buildInfoRow(
          icon: Icons.groups_rounded,
          title: _localization.get(
            'referralTitle',
          ),
          text: _localization.get(
            'referralDescription',
          ),
          color: goldColor,
        ),
      ],
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
                  color:
                      secondaryTextColor,
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
    return _buildSimpleSectionCard(
      icon:
          Icons.account_balance_wallet_rounded,
      iconColor: goldColor,
      title: _localization.get(
        'withdrawalTitle',
      ),
      children: [
        Text(
          _localization.get(
            'withdrawalDescription',
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
          padding:
              const EdgeInsets.all(15),
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
                _localization.get(
                  'plannedMinimumWithdrawal',
                ),
                textAlign:
                    TextAlign.center,
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
                _localization.get(
                  'networkFee',
                ),
                textAlign:
                    TextAlign.center,
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
    );
  }

  // ==========================================================
  // 🐾 STELLA JOURNEY
  // ==========================================================

  Widget _buildStellaJourney() {
    return _buildSimpleSectionCard(
      icon: Icons.pets_rounded,
      iconColor: pinkColor,

      // 🐱 Stelluriini-logo tassun tilalle
      customIcon: const StelluriiniLogo(
        size: 38,
      ),

      title: _localization.get(
        'stellaJourneyTitle',
      ),

      children: [
        Text(
          _localization.get(
            'stellaJourneyDescription',
          ),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: secondaryTextColor,
            fontSize: 16,
            height: 1.55,
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // 🛡️ DEVELOPMENT PRINCIPLES
  // ==========================================================

  Widget _buildDevelopmentPrinciples() {
    return _buildSimpleSectionCard(
      icon: Icons.rocket_launch_rounded,
      iconColor: goldColor,
      title: _localization.get(
        'developmentPrinciplesTitle',
      ),
      children: [
        _buildInfoRow(
          icon: Icons.groups_rounded,
          title: _localization.get(
            'communityTitle',
          ),
          text: _localization.get(
            'communityDescription',
          ),
          color: purpleColor,
        ),

        const SizedBox(height: 20),

        _buildInfoRow(
          icon: Icons.security_rounded,
          title: _localization.get(
            'securityTitle',
          ),
          text: _localization.get(
            'securityDescription',
          ),
          color: purpleColor,
        ),

        const SizedBox(height: 20),

        _buildInfoRow(
          icon: Icons.shield_rounded,
          title: _localization.get(
            'antiBotTitle',
          ),
          text: _localization.get(
            'antiBotDescription',
          ),
          color: pinkColor,
        ),

        const SizedBox(height: 20),

        _buildInfoRow(
          icon: Icons.auto_awesome_rounded,
          title: _localization.get(
            'innovationTitle',
          ),
          text: _localization.get(
            'innovationDescription',
          ),
          color: purpleColor,
        ),

        const SizedBox(height: 20),

        _buildInfoRow(
          icon: Icons.trending_up_rounded,
          title: _localization.get(
            'longTermGrowthTitle',
          ),
          text: _localization.get(
            'longTermGrowthDescription',
          ),
          color: goldColor,
        ),
      ],
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
      padding:
          const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(
          0xFF211827,
        ),
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
            _localization.get(
              'importantNoticeTitle',
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
            _localization.get(
              'importantNoticeDescription',
            ),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color:
                  secondaryTextColor,
              fontSize: 15,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // 📦 SIMPLE SECTION CARD
  // ==========================================================

  Widget _buildSimpleSectionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required List<Widget> children,
    Widget? customIcon,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(
        bottom: 22,
      ),
      padding:
          const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius:
            BorderRadius.circular(28),
        border: Border.all(
          color: iconColor.withValues(
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
                  color:
                      iconColor.withValues(
                    alpha: 0.10,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    18,
                  ),
                ),

                child: Center(
                  child: customIcon ??
                      Icon(
                        icon,
                        color: iconColor,
                        size: 30,
                      ),
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color:
                        primaryTextColor,
                    fontSize: 24,
                    fontWeight:
                        FontWeight.w800,
                    height: 1.15,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          ...children,
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
            color:
                primaryTextColor,
            size: 30,
          ),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),

        title: Text(
          _localization.get(
            'pageTitle',
          ),
          style: const TextStyle(
            color:
                primaryTextColor,
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
                    const EdgeInsets.all(
                  22,
                ),

                decoration:
                    BoxDecoration(
                  color: cardColor,
                  borderRadius:
                      BorderRadius.circular(
                    28,
                  ),
                  border: Border.all(
                    color:
                        purpleColor
                            .withValues(
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
                                purpleColor
                                    .withValues(
                              alpha: 0.10,
                            ),
                            borderRadius:
                                BorderRadius
                                    .circular(
                              18,
                            ),
                          ),
                          child:
                              const Icon(
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
                            _localization.get(
                              'journeyTitle',
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
                      _localization.get(
                        'journeyDescription',
                      ),
                      style:
                          const TextStyle(
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

              const SizedBox(
                height: 8,
              ),

              // ==================================================
              // 🐾 FOOTER
              // ==================================================

              Text(
                _localization.get(
                  'footer',
                ),
                textAlign:
                    TextAlign.center,
                style: const TextStyle(
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

  // 🐱 Näytetäänkö Stelluriini-logo kuvakkeena?
  final bool useStelluriiniLogo;

  const _RoadmapItem({
    required this.phase,
    required this.title,
    required this.description,
    required this.status,
    required this.icon,
    required this.color,
    this.useStelluriiniLogo = false,
  });
}