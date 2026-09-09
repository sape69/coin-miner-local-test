import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../localization.dart';
import '../../widgets/cat_avatar.dart';
import '../../widgets/stelluriini_logo.dart';

// ============================================================
// STELLA THEME COLORS
// ============================================================

const Color tokenomicsBackgroundColor = Color(0xFF120B24);
const Color tokenomicsCardColor = Color(0xFF21113B);
const Color tokenomicsAccentColor = Color(0xFFB58CFF);
const Color tokenomicsPinkColor = Color(0xFFFFB7E8);
const Color tokenomicsGoldColor = Color(0xFFFFD166);

// ============================================================
// TOKENOMICS PAGE
// ============================================================

class TokenomicsPage extends StatelessWidget {
  final String languageCode;

  const TokenomicsPage({
    super.key,
    this.languageCode = 'fi',
  });

  // ==========================================================
  // TOTAL SUPPLY
  // ==========================================================

  static const int totalSupply = 17602539062;

  // ==========================================================
  // TOKEN ALLOCATIONS
  // ==========================================================

  static const int communityRewards = 7041015625;
  static const int liquidity = 3520507812;
  static const int ecosystem = 2640380859;
  static const int development = 2640380859;
  static const int marketing = 1760253907;

  // ==========================================================
  // ALLOCATED TOTAL
  // ==========================================================

  static const int allocatedTotal =
      communityRewards +
      liquidity +
      ecosystem +
      development +
      marketing;

  // ==========================================================
  // SECTION
  // ==========================================================

  Widget _section({
    required IconData icon,
    required String title,
    required Widget child,
    Color accent = tokenomicsAccentColor,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: tokenomicsCardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: accent.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: accent,
                  size: 25,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }

  // ==========================================================
  // FORMAT NUMBER
  // ==========================================================

  String _formatNumber(int number) {
    final String text = number.toString();
    final StringBuffer buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      final int position = text.length - i;

      buffer.write(text[i]);

      if (position > 1 && position % 3 == 1) {
        buffer.write(' ');
      }
    }

    return buffer.toString();
  }

  // ==========================================================
  // PARAGRAPH
  // ==========================================================

  Widget _paragraph(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white70,
        fontSize: 15,
        height: 1.6,
      ),
    );
  }

  // ==========================================================
  // ALLOCATION CARD
  // ==========================================================

  Widget _allocationCard({
    required String emoji,
    required String title,
    required String percentage,
    required double chartValue,
    required int amount,
    required String description,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: tokenomicsBackgroundColor.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: color.withValues(alpha: 0.28),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Center(
                  child: Text(
                    emoji,
                    style: const TextStyle(
                      fontSize: 25,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_formatNumber(amount)} STL',
                      style: const TextStyle(
                        color: Color.fromRGBO(
                          255,
                          255,
                          255,
                          0.60,
                        ),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  percentage,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: chartValue,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(
                alpha: 0.06,
              ),
              valueColor: AlwaysStoppedAnimation<Color>(
                color,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            description,
            style: const TextStyle(
              color: Color.fromRGBO(
                255,
                255,
                255,
                0.65,
              ),
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // DONUT CHART
  // ==========================================================

  Widget _donutChart(AppLocalizations l) {
    return SizedBox(
      width: 230,
      height: 230,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(230, 230),
            painter: _TokenomicsChartPainter(),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l.get('tokenomicsTotalSupply'),
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.3,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '17.6B',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 3),
              const Text(
                'STL',
                style: TextStyle(
                  color: tokenomicsPinkColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // LEGEND ROW
  // ==========================================================

  Widget _legendRow({
    required Color color,
    required String title,
    required String percentage,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ),
          Text(
            percentage,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // PRINCIPLE
  // ==========================================================

  Widget _principle(
    IconData icon,
    String title,
    String description, {
    Color accent = tokenomicsAccentColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: accent,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                  color: Color.fromRGBO(
                    255,
                    255,
                    255,
                    0.60,
                  ),
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

  // ==========================================================
  // VERIFICATION ROW
  // ==========================================================

  Widget _verificationRow(
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_rounded,
            color: tokenomicsAccentColor,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations(
      languageCode,
    );

    return Scaffold(
      backgroundColor: tokenomicsBackgroundColor,

      // ========================================================
      // APP BAR
      // ========================================================

      appBar: AppBar(
        backgroundColor: tokenomicsBackgroundColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        title: Text(
          l.get('tokenomics'),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
      ),

      // ========================================================
      // BODY
      // ========================================================

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            16,
            8,
            16,
            32,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ==================================================
              // STELLA HEADER
              // ==================================================

              Container(
                width: double.infinity,
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
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(
                    color: tokenomicsAccentColor.withValues(
                      alpha: 0.30,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: tokenomicsAccentColor.withValues(
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
                      style: TextStyle(
                        color: tokenomicsPinkColor,
                        fontSize: 27,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l.get('officialStlTokenomics'),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 7),
                    const Text(
                      'STL • SOLANA',
                      style: TextStyle(
                        color: tokenomicsAccentColor,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: tokenomicsGoldColor.withValues(
                          alpha: 0.09,
                        ),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: tokenomicsGoldColor.withValues(
                            alpha: 0.20,
                          ),
                        ),
                      ),
                      child: const Text(
                        '🐾 17 602 539 062 STL 🐾',
                        style: TextStyle(
                          color: tokenomicsGoldColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ==================================================
              // OVERVIEW
              // ==================================================

              _section(
                icon: Icons.info_outline_rounded,
                title: l.get('tokenomicsOverview'),
                child: _paragraph(
                  l.get('tokenomicsOverviewDescription'),
                ),
              ),

              // ==================================================
              // TOKEN DISTRIBUTION
              // ==================================================

              _section(
                icon: Icons.pie_chart_rounded,
                title: l.get('tokenDistribution'),
                child: Column(
                  children: [
                    Center(
                      child: _donutChart(l),
                    ),
                    const SizedBox(height: 24),
                    _legendRow(
                      color: tokenomicsAccentColor,
                      title: l.get('communityRewards'),
                      percentage: '40%',
                    ),
                    _legendRow(
                      color: const Color(0xFF72B7FF),
                      title: l.get('liquidity'),
                      percentage: '20%',
                    ),
                    _legendRow(
                      color: const Color(0xFFC084FC),
                      title: l.get('ecosystem'),
                      percentage: '15%',
                    ),
                    _legendRow(
                      color: tokenomicsGoldColor,
                      title: l.get('development'),
                      percentage: '15%',
                    ),
                    _legendRow(
                      color: tokenomicsPinkColor,
                      title: l.get('marketing'),
                      percentage: '10%',
                    ),
                  ],
                ),
              ),

              // ==================================================
              // TOTAL SUPPLY
              // ==================================================

              _section(
                icon: Icons.account_balance_wallet_rounded,
                title: l.get('totalSupply'),
                accent: tokenomicsGoldColor,
                child: Column(
                  children: [
                    Text(
                      _formatNumber(totalSupply),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: tokenomicsGoldColor,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l.get('stlTokens'),
                      style: const TextStyle(
                        color: Color.fromRGBO(
                          255,
                          255,
                          255,
                          0.50,
                        ),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 18),
                    _paragraph(
                      l.get('totalSupplyDescription'),
                    ),
                  ],
                ),
              ),

              // ==================================================
              // TOKEN ALLOCATION
              // ==================================================

              _section(
                icon: Icons.account_tree_rounded,
                title: l.get('tokenAllocation'),
                child: Column(
                  children: [
                    _allocationCard(
                      emoji: '🐾',
                      title: l.get('communityRewards'),
                      percentage: '40%',
                      chartValue: 0.40,
                      amount: communityRewards,
                      color: tokenomicsAccentColor,
                      description: l.get(
                        'communityRewardsDescription',
                      ),
                    ),
                    _allocationCard(
                      emoji: '💧',
                      title: l.get('liquidity'),
                      percentage: '20%',
                      chartValue: 0.20,
                      amount: liquidity,
                      color: const Color(0xFF72B7FF),
                      description: l.get(
                        'liquidityDescription',
                      ),
                    ),
                    _allocationCard(
                      emoji: '🚀',
                      title: l.get('ecosystem'),
                      percentage: '15%',
                      chartValue: 0.15,
                      amount: ecosystem,
                      color: const Color(0xFFC084FC),
                      description: l.get(
                        'ecosystemDescription',
                      ),
                    ),
                    _allocationCard(
                      emoji: '🔧',
                      title: l.get('development'),
                      percentage: '15%',
                      chartValue: 0.15,
                      amount: development,
                      color: tokenomicsGoldColor,
                      description: l.get(
                        'developmentDescription',
                      ),
                    ),
                    _allocationCard(
                      emoji: '📢',
                      title: l.get('marketing'),
                      percentage: '10%',
                      chartValue: 0.10,
                      amount: marketing,
                      color: tokenomicsPinkColor,
                      description: l.get(
                        'marketingDescription',
                      ),
                    ),
                  ],
                ),
              ),

              // ==================================================
              // ALLOCATION VERIFICATION
              // ==================================================

              _section(
                icon: Icons.verified_rounded,
                title: l.get('allocationVerification'),
                child: Column(
                  children: [
                    _verificationRow(
                      l.get('communityRewards'),
                      _formatNumber(communityRewards),
                    ),
                    _verificationRow(
                      l.get('liquidity'),
                      _formatNumber(liquidity),
                    ),
                    _verificationRow(
                      l.get('ecosystem'),
                      _formatNumber(ecosystem),
                    ),
                    _verificationRow(
                      l.get('development'),
                      _formatNumber(development),
                    ),
                    _verificationRow(
                      l.get('marketing'),
                      _formatNumber(marketing),
                    ),
                    const Divider(
                      color: Colors.white24,
                      height: 24,
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.account_balance_wallet_rounded,
                          color: tokenomicsGoldColor,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            l.get('totalAllocated'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          _formatNumber(allocatedTotal),
                          style: const TextStyle(
                            color: tokenomicsGoldColor,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: tokenomicsAccentColor.withValues(
                          alpha: 0.08,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: tokenomicsAccentColor.withValues(
                            alpha: 0.20,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle_rounded,
                            color: tokenomicsAccentColor,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              allocatedTotal == totalSupply
                                  ? l.get(
                                      'allocationVerified',
                                    )
                                  : l.get(
                                      'allocationRequiresVerification',
                                    ),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                height: 1.45,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ==================================================
              // ALLOCATION PRINCIPLES
              // ==================================================

              _section(
                icon: Icons.workspace_premium_rounded,
                title: l.get('allocationPrinciples'),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    _paragraph(
                      l.get(
                        'allocationPrinciplesDescription',
                      ),
                    ),
                    const SizedBox(height: 18),
                    _principle(
                      Icons.groups_rounded,
                      l.get('communityFirst'),
                      l.get(
                        'communityFirstDescription',
                      ),
                      accent: tokenomicsPinkColor,
                    ),
                    const SizedBox(height: 16),
                    _principle(
                      Icons.trending_up_rounded,
                      l.get('longTermGrowth'),
                      l.get(
                        'longTermGrowthDescription',
                      ),
                      accent: tokenomicsAccentColor,
                    ),
                    const SizedBox(height: 16),
                    _principle(
                      Icons.public_rounded,
                      l.get('accessibility'),
                      l.get(
                        'accessibilityDescription',
                      ),
                      accent: tokenomicsGoldColor,
                    ),
                  ],
                ),
              ),

              // ==================================================
              // STELLA
              // ==================================================

              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: tokenomicsCardColor,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: tokenomicsPinkColor.withValues(
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
                      '🐱 ${l.get('stellaStlCommunity')}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: tokenomicsPinkColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l.get('communityCuriosityDevelopmentSolana'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              // ==================================================
              // IMPORTANT NOTICE
              // ==================================================

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.orangeAccent.withValues(
                    alpha: 0.08,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.orangeAccent.withValues(
                      alpha: 0.25,
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
                      l.get('importantNotice'),
                      style: const TextStyle(
                        color: Colors.orangeAccent,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      l.get('tokenomicsImportantNotice'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white60,
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
                '🐾 ${l.get('stellaStelluriiniStlSolana')} 🐾',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: tokenomicsPinkColor,
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
                  color: tokenomicsGoldColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// TOKENOMICS DONUT CHART PAINTER
// ============================================================

class _TokenomicsChartPainter extends CustomPainter {
  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final Offset center = Offset(
      size.width / 2,
      size.height / 2,
    );

    final double radius = size.width / 2 - 18;

    final Rect rect = Rect.fromCircle(
      center: center,
      radius: radius,
    );

    // ==========================================================
    // BACKGROUND RING
    // ==========================================================

    final Paint backgroundPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 24;

    canvas.drawCircle(
      center,
      radius,
      backgroundPaint,
    );

    // ==========================================================
    // DISTRIBUTION
    // ==========================================================

    const List<double> values = [
      0.40,
      0.20,
      0.15,
      0.15,
      0.10,
    ];

    // ==========================================================
    // STELLA THEME COLORS
    // ==========================================================

    const List<Color> colors = [
      tokenomicsAccentColor,
      Color(0xFF72B7FF),
      Color(0xFFC084FC),
      tokenomicsGoldColor,
      tokenomicsPinkColor,
    ];

    // ==========================================================
    // DRAW
    // ==========================================================

    double startAngle = -math.pi / 2;

    const double fullCircle = math.pi * 2;
    const double gap = 0.035;

    for (int i = 0; i < values.length; i++) {
      final double sweepAngle =
          (values[i] * fullCircle) - gap;

      final Paint paint = Paint()
        ..color = colors[i]
        ..style = PaintingStyle.stroke
        ..strokeWidth = 24
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        rect,
        startAngle,
        sweepAngle,
        false,
        paint,
      );

      startAngle += values[i] * fullCircle;
    }
  }

  @override
  bool shouldRepaint(
    covariant CustomPainter oldDelegate,
  ) {
    return false;
  }
}