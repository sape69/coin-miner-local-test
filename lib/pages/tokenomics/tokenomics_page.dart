import 'package:flutter/material.dart';

// ============================================================
// COLORS
// ============================================================

const Color backgroundColor = Color(0xFF0B1112);
const Color cardColor = Color(0xFF151B1C);
const Color accentColor = Color(0xFF35D0A0);

// ============================================================
// TOKENOMICS PAGE
// ============================================================

class TokenomicsPage extends StatelessWidget {
  const TokenomicsPage({super.key});

  // ==========================================================
  // TOTAL SUPPLY
  // ==========================================================

  static const int totalSupply = 17602539062;

  // ==========================================================
  // TOKEN ALLOCATIONS
  //
  // These amounts add up exactly to:
  //
  // 17 602 539 062 STL
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
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.18),
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
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: accentColor,
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
    final text = number.toString();
    final buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      final position = text.length - i;

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
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.72),
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
        color: backgroundColor.withValues(alpha: 0.45),
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
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
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
                      style: TextStyle(
                        color: Colors.white.withValues(
                          alpha: 0.58,
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
              valueColor:
                  AlwaysStoppedAnimation<Color>(
                color,
              ),
            ),
          ),

          const SizedBox(height: 14),

          Text(
            description,
            style: TextStyle(
              color: Colors.white.withValues(
                alpha: 0.65,
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

  Widget _donutChart() {
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
                'TOTAL SUPPLY',
                style: TextStyle(
                  color: Colors.white.withValues(
                    alpha: 0.50,
                  ),
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
                  color: accentColor,
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
              style: TextStyle(
                color: Colors.white.withValues(
                  alpha: 0.72,
                ),
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
    String description,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: accentColor,
            size: 22,
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
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
                style: TextStyle(
                  color: Colors.white.withValues(
                    alpha: 0.60,
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
          Icon(
            Icons.check_circle_rounded,
            color: accentColor,
            size: 20,
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(
                  alpha: 0.70,
                ),
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
    return Scaffold(
      backgroundColor: backgroundColor,

      // ======================================================
      // APP BAR
      // ======================================================

      appBar: AppBar(
        backgroundColor: cardColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        title: const Text(
          'TOKENOMICS',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
      ),

      // ======================================================
      // BODY
      // ======================================================

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [

              // ==================================================
              // HEADER
              // ==================================================

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(
                    color: accentColor.withValues(
                      alpha: 0.30,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withValues(
                        alpha: 0.08,
                      ),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: accentColor.withValues(
                          alpha: 0.12,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.pie_chart_rounded,
                        color: accentColor,
                        size: 42,
                      ),
                    ),

                    const SizedBox(height: 18),

                    const Text(
                      'STELLURIINI',
                      style: TextStyle(
                        color: accentColor,
                        fontSize: 27,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 3,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'Official STL Tokenomics',
                      style: TextStyle(
                        color: Colors.white.withValues(
                          alpha: 0.65,
                        ),
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(height: 20),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(
                          alpha: 0.10,
                        ),
                        borderRadius:
                            BorderRadius.circular(30),
                      ),
                      child: const Text(
                        '🪙 17 602 539 062 STL',
                        style: TextStyle(
                          color: accentColor,
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
                title: 'Tokenomics Overview',
                child: _paragraph(
                  'The Stelluriini tokenomics structure describes '
                  'the planned allocation of the total STL supply '
                  'across community rewards, liquidity, ecosystem '
                  'growth, development and marketing.',
                ),
              ),

              // ==================================================
              // TOKEN DISTRIBUTION
              // ==================================================

              _section(
                icon: Icons.pie_chart_rounded,
                title: 'Token Distribution',
                child: Column(
                  children: [
                    Center(
                      child: _donutChart(),
                    ),

                    const SizedBox(height: 24),

                    _legendRow(
                      color: accentColor,
                      title: 'Community & Rewards',
                      percentage: '40%',
                    ),

                    _legendRow(
                      color: Colors.blueAccent,
                      title: 'Liquidity',
                      percentage: '20%',
                    ),

                    _legendRow(
                      color: Colors.purpleAccent,
                      title: 'Ecosystem',
                      percentage: '15%',
                    ),

                    _legendRow(
                      color: Colors.orangeAccent,
                      title: 'Development',
                      percentage: '15%',
                    ),

                    _legendRow(
                      color: Colors.pinkAccent,
                      title: 'Marketing',
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
                title: 'Total Supply',
                child: Column(
                  children: [
                    Text(
                      _formatNumber(totalSupply),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: accentColor,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      'STL TOKENS',
                      style: TextStyle(
                        color: Colors.white.withValues(
                          alpha: 0.50,
                        ),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),

                    const SizedBox(height: 18),

                    _paragraph(
                      'The total supply of Stelluriini is '
                      '17 602 539 062 STL. The allocation '
                      'structure below accounts for the complete '
                      'planned token supply.',
                    ),
                  ],
                ),
              ),

              // ==================================================
              // TOKEN ALLOCATION
              // ==================================================

              _section(
                icon: Icons.account_tree_rounded,
                title: 'Token Allocation',
                child: Column(
                  children: [
                    // ============================================
                    // COMMUNITY
                    // ============================================

                    _allocationCard(
                      emoji: '🐾',
                      title: 'Community & Rewards',
                      percentage: '40%',
                      chartValue: 0.40,
                      amount: communityRewards,
                      color: accentColor,
                      description:
                          'Allocated to community initiatives, '
                          'user rewards, engagement programs and '
                          'future community-focused activities.',
                    ),

                    // ============================================
                    // LIQUIDITY
                    // ============================================

                    _allocationCard(
                      emoji: '💧',
                      title: 'Liquidity',
                      percentage: '20%',
                      chartValue: 0.20,
                      amount: liquidity,
                      color: Colors.blueAccent,
                      description:
                          'Reserved to support liquidity and help '
                          'create a healthier and more accessible '
                          'market environment for STL.',
                    ),

                    // ============================================
                    // ECOSYSTEM
                    // ============================================

                    _allocationCard(
                      emoji: '🚀',
                      title: 'Ecosystem',
                      percentage: '15%',
                      chartValue: 0.15,
                      amount: ecosystem,
                      color: Colors.purpleAccent,
                      description:
                          'Reserved for future ecosystem growth, '
                          'applications, games, integrations and '
                          'new digital experiences.',
                    ),

                    // ============================================
                    // DEVELOPMENT
                    // ============================================

                    _allocationCard(
                      emoji: '🔧',
                      title: 'Development',
                      percentage: '15%',
                      chartValue: 0.15,
                      amount: development,
                      color: Colors.orangeAccent,
                      description:
                          'Allocated to technical development, '
                          'application development, infrastructure '
                          'and future improvements.',
                    ),

                    // ============================================
                    // MARKETING
                    // ============================================

                    _allocationCard(
                      emoji: '📢',
                      title: 'Marketing',
                      percentage: '10%',
                      chartValue: 0.10,
                      amount: marketing,
                      color: Colors.pinkAccent,
                      description:
                          'Allocated to marketing, awareness, '
                          'community growth and promotional '
                          'activities.',
                    ),
                  ],
                ),
              ),

              // ==================================================
              // ALLOCATION VERIFICATION
              // ==================================================

              _section(
                icon: Icons.verified_rounded,
                title: 'Allocation Verification',
                child: Column(
                  children: [
                    _verificationRow(
                      'Community & Rewards',
                      _formatNumber(communityRewards),
                    ),

                    _verificationRow(
                      'Liquidity',
                      _formatNumber(liquidity),
                    ),

                    _verificationRow(
                      'Ecosystem',
                      _formatNumber(ecosystem),
                    ),

                    _verificationRow(
                      'Development',
                      _formatNumber(development),
                    ),

                    _verificationRow(
                      'Marketing',
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
                          color: accentColor,
                          size: 22,
                        ),

                        const SizedBox(width: 10),

                        const Expanded(
                          child: Text(
                            'Total Allocated',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        Text(
                          _formatNumber(allocatedTotal),
                          style: const TextStyle(
                            color: accentColor,
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
                        color: accentColor.withValues(
                          alpha: 0.08,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: accentColor.withValues(
                            alpha: 0.20,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle_rounded,
                            color: accentColor,
                          ),

                          const SizedBox(width: 10),

                          Expanded(
                            child: Text(
                              allocatedTotal == totalSupply
                                  ? 'Allocation verified: the total allocation matches the complete STL supply.'
                                  : 'Allocation requires verification.',
                              style: TextStyle(
                                color: Colors.white.withValues(
                                  alpha: 0.78,
                                ),
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
                title: 'Allocation Principles',
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    _paragraph(
                      'The token allocation structure is designed '
                      'to support the community, ecosystem growth '
                      'and long-term development of Stelluriini.',
                    ),

                    const SizedBox(height: 18),

                    _principle(
                      Icons.groups_rounded,
                      'Community First',
                      'A significant portion of the planned supply '
                      'is allocated to community initiatives and '
                      'rewards.',
                    ),

                    const SizedBox(height: 16),

                    _principle(
                      Icons.trending_up_rounded,
                      'Long-Term Growth',
                      'Ecosystem and development allocations are '
                      'intended to support future expansion and '
                      'new projects.',
                    ),

                    const SizedBox(height: 16),

                    _principle(
                      Icons.public_rounded,
                      'Accessibility',
                      'Liquidity allocation is intended to support '
                      'accessibility and market participation for '
                      'the STL token.',
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

                    const Text(
                      'Important Notice',
                      style: TextStyle(
                        color: Colors.orangeAccent,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      'The token allocation structure describes '
                      'the planned Stelluriini ecosystem model. '
                      'Nothing on this page should be considered '
                      'financial, investment or legal advice.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(
                          alpha: 0.65,
                        ),
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // ==================================================
              // FOOTER
              // ==================================================

              Center(
                child: Text(
                  '🐾 STELLURIINI • STL • SOLANA 🐾',
                  style: TextStyle(
                    color: accentColor.withValues(
                      alpha: 0.75,
                    ),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),

              const SizedBox(height: 30),
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
    final center = Offset(
      size.width / 2,
      size.height / 2,
    );

    final radius =
        size.width / 2 - 18;

    final rect = Rect.fromCircle(
      center: center,
      radius: radius,
    );

    // ==========================================================
    // BACKGROUND
    // ==========================================================

    final backgroundPaint = Paint()
      ..color = Colors.white.withValues(
        alpha: 0.06,
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = 24;

    canvas.drawCircle(
      center,
      radius,
      backgroundPaint,
    );

    // ==========================================================
    // VALUES
    // ==========================================================

    const values = [
      0.40,
      0.20,
      0.15,
      0.15,
      0.10,
    ];

    // ==========================================================
    // COLORS
    // ==========================================================

    const colors = [
      accentColor,
      Colors.blueAccent,
      Colors.purpleAccent,
      Colors.orangeAccent,
      Colors.pinkAccent,
    ];

    // ==========================================================
    // DRAW CHART
    // ==========================================================

    double startAngle = -1.5708;

    const gap = 0.035;

    for (int i = 0; i < values.length; i++) {
      final sweepAngle =
          (values[i] * 6.283185) - gap;

      final paint = Paint()
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

      startAngle +=
          values[i] * 6.283185;
    }
  }

  @override
  bool shouldRepaint(
    covariant CustomPainter oldDelegate,
  ) {
    return false;
  }
}