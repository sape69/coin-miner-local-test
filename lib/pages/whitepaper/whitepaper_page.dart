import 'package:flutter/material.dart';

import '../../widgets/cat_avatar.dart';
import '../../widgets/stelluriini_logo.dart';

// ============================================================
// STELLA THEME COLORS
// ============================================================

const Color whitePaperBackgroundColor = Color(0xFF120B24);
const Color whitePaperCardColor = Color(0xFF21113B);
const Color whitePaperAccentColor = Color(0xFFB58CFF);
const Color whitePaperPinkColor = Color(0xFFFFB7E8);
const Color whitePaperGoldColor = Color(0xFFFFD166);

// ============================================================
// WHITE PAPER PAGE
// ============================================================

class WhitePaperPage extends StatelessWidget {
  const WhitePaperPage({
    super.key,
  });

  // ==========================================================
  // TOKEN INFORMATION
  // ==========================================================

  static const String tokenName = 'Stelluriini';
  static const String tokenSymbol = 'STL';
  static const String blockchain = 'Solana';
  static const String totalSupply = '17 602 539 062';
  static const String decimals = '9';

  static const String mintAddress =
      'AyZun5s9tEJDeHTNPrVbaYpqjWdSKHx25M3kfVFjbdas';

  // ==========================================================
  // SECTION
  // ==========================================================

  Widget _section({
    required String number,
    required IconData icon,
    required String title,
    required Widget child,
    Color accent = whitePaperAccentColor,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(
        bottom: 18,
      ),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: whitePaperCardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: accent.withValues(
            alpha: 0.18,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accent.withValues(
                    alpha: 0.11,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: accent.withValues(
                      alpha: 0.15,
                    ),
                  ),
                ),
                child: Icon(
                  icon,
                  color: accent,
                  size: 23,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      number,
                      style: TextStyle(
                        color: accent,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.4,
                      ),
                    ),

                    const SizedBox(height: 2),

                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
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
  // PARAGRAPH
  // ==========================================================

  Widget _paragraph(
    String text,
  ) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white70,
        fontSize: 14,
        height: 1.65,
      ),
    );
  }

  // ==========================================================
  // BULLET
  // ==========================================================

  Widget _bullet(
    String text, {
    Color accent = whitePaperAccentColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 10,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            width: 7,
            height: 7,
            margin: const EdgeInsets.only(
              top: 7,
            ),
            decoration: BoxDecoration(
              color: accent,
              shape: BoxShape.circle,
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                height: 1.55,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // FEATURE ROW
  // ==========================================================

  Widget _featureRow({
    required IconData icon,
    required String title,
    required String description,
    Color accent = whitePaperAccentColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 16,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accent.withValues(
                alpha: 0.10,
              ),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              icon,
              color: accent,
              size: 21,
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
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 13,
                    height: 1.5,
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
  // TOKEN INFO ROW
  // ==========================================================

  Widget _tokenInfoRow(
    String label,
    String value, {
    Color accent = whitePaperAccentColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 12,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 13,
              ),
            ),
          ),

          const SizedBox(width: 12),

          Flexible(
            flex: 2,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: accent,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // ALLOCATION ROW
  // ==========================================================

  Widget _allocationRow({
    required String title,
    required String percentage,
    required String amount,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(
        bottom: 10,
      ),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: whitePaperBackgroundColor.withValues(
          alpha: 0.45,
        ),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: color.withValues(
            alpha: 0.16,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 38,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(5),
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
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  amount,
                  style: const TextStyle(
                    color: Colors.white50,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          Text(
            percentage,
            style: TextStyle(
              color: color,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // PHASE ROW
  // ==========================================================

  Widget _phaseRow({
    required String phase,
    required String title,
    required String status,
    required String description,
    required Color accent,
  }) {
    return Container(
      margin: const EdgeInsets.only(
        bottom: 14,
      ),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: whitePaperBackgroundColor.withValues(
          alpha: 0.42,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: accent.withValues(
            alpha: 0.18,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: accent.withValues(
                alpha: 0.11,
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: accent.withValues(
                  alpha: 0.28,
                ),
              ),
            ),
            child: Center(
              child: Text(
                phase,
                style: TextStyle(
                  color: accent,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          const SizedBox(width: 13),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    Container(
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: accent.withValues(
                          alpha: 0.10,
                        ),
                        borderRadius:
                            BorderRadius.circular(8),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          color: accent,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 7),

                Text(
                  description,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                    height: 1.5,
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
  // BUILD
  // ==========================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          whitePaperBackgroundColor,

      // ========================================================
      // APP BAR
      // ========================================================

      appBar: AppBar(
        backgroundColor:
            whitePaperBackgroundColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'WHITE PAPER',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.8,
            fontSize: 16,
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
            36,
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              // ==================================================
              // COVER
              // ==================================================

              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(
                  24,
                  30,
                  24,
                  28,
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
                      BorderRadius.circular(28),
                  border: Border.all(
                    color:
                        whitePaperAccentColor.withValues(
                      alpha: 0.30,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color:
                          whitePaperAccentColor.withValues(
                        alpha: 0.10,
                      ),
                      blurRadius: 26,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const CatAvatar(
                      size: 125,
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      'STELLURIINI',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: whitePaperPinkColor,
                        fontSize: 29,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 3.2,
                      ),
                    ),

                    const SizedBox(height: 7),

                    const Text(
                      'STL',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 4,
                      ),
                    ),

                    const SizedBox(height: 13),

                    Container(
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color:
                            whitePaperAccentColor.withValues(
                          alpha: 0.10,
                        ),
                        borderRadius:
                            BorderRadius.circular(30),
                        border: Border.all(
                          color:
                              whitePaperAccentColor.withValues(
                            alpha: 0.22,
                          ),
                        ),
                      ),
                      child: const Text(
                        '🐾 SOLANA COMMUNITY TOKEN 🐾',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color:
                              whitePaperAccentColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    const Text(
                      'WHITE PAPER',
                      style: TextStyle(
                        color: whitePaperGoldColor,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),

                    const SizedBox(height: 5),

                    const Text(
                      'Version 1.0',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ==================================================
              // 01 EXECUTIVE SUMMARY
              // ==================================================

              _section(
                number: '01',
                icon: Icons.auto_awesome_rounded,
                title: 'Executive Summary',
                child: _paragraph(
                  'Stelluriini is a community-driven digital '
                  'project built around Stella, a curious cat '
                  'representing creativity, community and '
                  'exploration. STL is the project token on the '
                  'Solana blockchain. The Stelluriini application '
                  'combines Stella branding, mining-style reward '
                  'mechanics, daily activities and information '
                  'about the STL ecosystem.',
                ),
              ),

              // ==================================================
              // 02 VISION
              // ==================================================

              _section(
                number: '02',
                icon: Icons.visibility_rounded,
                title: 'Vision',
                accent: whitePaperPinkColor,
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    _paragraph(
                      'The vision of Stelluriini is to create a '
                      'recognizable and community-focused digital '
                      'ecosystem where Stella is at the center of '
                      'the experience.',
                    ),

                    const SizedBox(height: 18),

                    _bullet(
                      'Build a strong and recognizable Stella identity.',
                      accent: whitePaperPinkColor,
                    ),

                    _bullet(
                      'Create engaging applications and digital experiences.',
                      accent: whitePaperPinkColor,
                    ),

                    _bullet(
                      'Grow an active and welcoming community.',
                      accent: whitePaperPinkColor,
                    ),

                    _bullet(
                      'Develop useful and entertaining STL ecosystem features.',
                      accent: whitePaperPinkColor,
                    ),

                    _bullet(
                      'Explore games, applications and future Solana integrations.',
                      accent: whitePaperPinkColor,
                    ),
                  ],
                ),
              ),

              // ==================================================
              // 03 WHAT IS STELLURIINI
              // ==================================================

              _section(
                number: '03',
                icon: Icons.pets_rounded,
                title: 'What is Stelluriini?',
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    _paragraph(
                      'Stelluriini is more than a token name. '
                      'It is a project identity built around Stella '
                      'and a community-oriented digital experience.',
                    ),

                    const SizedBox(height: 18),

                    _featureRow(
                      icon: Icons.pets_rounded,
                      title: 'Stella',
                      description:
                          'The visual mascot and recognizable identity of the project.',
                      accent: whitePaperPinkColor,
                    ),

                    _featureRow(
                      icon: Icons.currency_bitcoin_rounded,
                      title: 'STL',
                      description:
                          'The Stelluriini token associated with the Solana ecosystem.',
                      accent: whitePaperGoldColor,
                    ),

                    _featureRow(
                      icon: Icons.phone_android_rounded,
                      title: 'Application',
                      description:
                          'A mobile experience containing mining-style rewards, daily activities and project information.',
                      accent: whitePaperAccentColor,
                    ),

                    _featureRow(
                      icon: Icons.groups_rounded,
                      title: 'Community',
                      description:
                          'A community-focused environment where future features can be developed together.',
                      accent: whitePaperPinkColor,
                    ),
                  ],
                ),
              ),

              // ==================================================
              // 04 STELLA
              // ==================================================

              _section(
                number: '04',
                icon: Icons.favorite_rounded,
                title: 'Stella',
                accent: whitePaperPinkColor,
                child: Column(
                  children: [
                    const StelluriiniLogo(
                      size: 80,
                    ),

                    const SizedBox(height: 14),

                    const Text(
                      'Stella is the heart of Stelluriini.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: whitePaperPinkColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 12),

                    _paragraph(
                      'Stella represents curiosity, friendliness '
                      'and exploration. Her role is to make the '
                      'Stelluriini experience recognizable while '
                      'providing a consistent identity for the '
                      'application, community and future ecosystem.',
                    ),
                  ],
                ),
              ),

              // ==================================================
              // 05 STL TOKEN
              // ==================================================

              _section(
                number: '05',
                icon: Icons.monetization_on_rounded,
                title: 'STL Token',
                accent: whitePaperGoldColor,
                child: Column(
                  children: [
                    _tokenInfoRow(
                      'Token Name',
                      tokenName,
                      accent: whitePaperPinkColor,
                    ),

                    _tokenInfoRow(
                      'Symbol',
                      tokenSymbol,
                      accent: whitePaperPinkColor,
                    ),

                    _tokenInfoRow(
                      'Blockchain',
                      blockchain,
                    ),

                    _tokenInfoRow(
                      'Total Supply',
                      totalSupply,
                      accent: whitePaperGoldColor,
                    ),

                    _tokenInfoRow(
                      'Decimals',
                      decimals,
                    ),

                    const SizedBox(height: 5),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color:
                            whitePaperBackgroundColor
                                .withValues(
                          alpha: 0.45,
                        ),
                        borderRadius:
                            BorderRadius.circular(15),
                        border: Border.all(
                          color:
                              whitePaperGoldColor.withValues(
                            alpha: 0.16,
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Mint Address',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 11,
                            ),
                          ),

                          const SizedBox(height: 8),

                          const SelectableText(
                            mintAddress,
                            style: TextStyle(
                              color:
                                  whitePaperPinkColor,
                              fontSize: 12,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ==================================================
              // 06 TOKENOMICS
              // ==================================================

              _section(
                number: '06',
                icon: Icons.pie_chart_rounded,
                title: 'Tokenomics',
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    _paragraph(
                      'The planned STL allocation is designed '
                      'to support community rewards, liquidity, '
                      'ecosystem growth, development and marketing.',
                    ),

                    const SizedBox(height: 18),

                    _allocationRow(
                      title: 'Community & Rewards',
                      percentage: '40%',
                      amount: '7 041 015 625 STL',
                      color: whitePaperAccentColor,
                    ),

                    _allocationRow(
                      title: 'Liquidity',
                      percentage: '20%',
                      amount: '3 520 507 812 STL',
                      color: const Color(0xFF72B7FF),
                    ),

                    _allocationRow(
                      title: 'Ecosystem',
                      percentage: '15%',
                      amount: '2 640 380 859 STL',
                      color: const Color(0xFFC084FC),
                    ),

                    _allocationRow(
                      title: 'Development',
                      percentage: '15%',
                      amount: '2 640 380 859 STL',
                      color: whitePaperGoldColor,
                    ),

                    _allocationRow(
                      title: 'Marketing',
                      percentage: '10%',
                      amount: '1 760 253 907 STL',
                      color: whitePaperPinkColor,
                    ),

                    const SizedBox(height: 6),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color:
                            whitePaperAccentColor.withValues(
                          alpha: 0.07,
                        ),
                        borderRadius:
                            BorderRadius.circular(14),
                        border: Border.all(
                          color:
                              whitePaperAccentColor.withValues(
                            alpha: 0.16,
                          ),
                        ),
                      ),
                      child: const Text(
                        'Total allocation: 17 602 539 062 STL',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: whitePaperGoldColor,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ==================================================
              // 07 STELLA MINING
              // ==================================================

              _section(
                number: '07',
                icon: Icons.bolt_rounded,
                title: 'Stella Mining',
                accent: whitePaperAccentColor,
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    _paragraph(
                      'The Stelluriini application includes a '
                      'mining-style reward system. The system is '
                      'designed as an in-app progression mechanic '
                      'where users accumulate virtual STL points '
                      'over a mining cycle.',
                    ),

                    const SizedBox(height: 18),

                    _featureRow(
                      icon: Icons.speed_rounded,
                      title: 'Hash Rate',
                      description:
                          'A user hash rate determines the rate at which virtual mining points accumulate.',
                    ),

                    _featureRow(
                      icon: Icons.timer_rounded,
                      title: 'Mining Cycle',
                      description:
                          'A mining cycle runs for a defined period before its accumulated reward can be claimed.',
                    ),

                    _featureRow(
                      icon: Icons.calculate_rounded,
                      title: 'Reward Calculation',
                      description:
                          'The virtual reward is calculated from hash rate and elapsed mining time.',
                    ),

                    _featureRow(
                      icon: Icons.lock_clock_rounded,
                      title: 'Locked Mining Rate',
                      description:
                          'The hash rate used by an active mining cycle is kept stable during that cycle.',
                    ),
                  ],
                ),
              ),

              // ==================================================
              // 08 DAILY BONUS
              // ==================================================

              _section(
                number: '08',
                icon: Icons.card_giftcard_rounded,
                title: 'Daily Bonus',
                accent: whitePaperGoldColor,
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    _paragraph(
                      'The Daily Bonus encourages regular '
                      'participation in the Stelluriini application. '
                      'A successful daily check-in can increase the '
                      'user hash rate and contribute to a consecutive '
                      'daily streak.',
                    ),

                    const SizedBox(height: 16),

                    _bullet(
                      'Daily check-in is limited to one successful claim per day.',
                      accent: whitePaperGoldColor,
                    ),

                    _bullet(
                      'A consecutive streak can be maintained by returning on following days.',
                      accent: whitePaperGoldColor,
                    ),

                    _bullet(
                      'The bonus affects the user hash rate used for future mining cycles.',
                      accent: whitePaperGoldColor,
                    ),
                  ],
                ),
              ),

              // ==================================================
              // 09 STELLA POWER BOOST
              // ==================================================

              _section(
                number: '09',
                icon: Icons.flash_on_rounded,
                title: 'Stella Power Boost',
                accent: whitePaperPinkColor,
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    _paragraph(
                      'The Stella Power Boost system allows users '
                      'to receive an additional hash-rate bonus '
                      'through rewarded advertising. The system '
                      'contains limits and cooldown rules to help '
                      'prevent abuse.',
                    ),

                    const SizedBox(height: 16),

                    _featureRow(
                      icon: Icons.ondemand_video_rounded,
                      title: 'Rewarded Ads',
                      description:
                          'Users can receive an in-app hash-rate bonus after a qualifying rewarded advertisement.',
                      accent: whitePaperPinkColor,
                    ),

                    _featureRow(
                      icon: Icons.av_timer_rounded,
                      title: 'Cooldown',
                      description:
                          'A cooldown period limits how frequently an ad reward can be claimed.',
                      accent: whitePaperPinkColor,
                    ),

                    _featureRow(
                      icon: Icons.today_rounded,
                      title: 'Daily Limit',
                      description:
                          'A maximum number of rewarded advertisements can be counted per day.',
                      accent: whitePaperPinkColor,
                    ),
                  ],
                ),
              ),

              // ==================================================
              // 10 APPLICATION ARCHITECTURE
              // ==================================================

              _section(
                number: '10',
                icon: Icons.account_tree_rounded,
                title: 'Application Architecture',
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    _paragraph(
                      'The Stelluriini application is designed '
                      'around a mobile client and server-side '
                      'services that handle authenticated reward '
                      'operations and transaction history.',
                    ),

                    const SizedBox(height: 18),

                    _architectureBox(
                      icon: Icons.phone_android_rounded,
                      title: 'Flutter Application',
                      description:
                          'User interface, Stella experience, mining dashboard and project information.',
                      color: whitePaperPinkColor,
                    ),

                    _architectureArrow(),

                    _architectureBox(
                      icon: Icons.cloud_rounded,
                      title: 'Firebase Services',
                      description:
                          'Authentication, Firestore data and server-side Cloud Functions.',
                      color: whitePaperAccentColor,
                    ),

                    _architectureArrow(),

                    _architectureBox(
                      icon: Icons.security_rounded,
                      title: 'Server-Side Validation',
                      description:
                          'Reward limits, cooldowns, duplicate protection and authenticated operations.',
                      color: whitePaperGoldColor,
                    ),

                    _architectureArrow(),

                    _architectureBox(
                      icon: Icons.link_rounded,
                      title: 'Solana / STL',
                      description:
                          'The Stelluriini token exists as an asset on the Solana blockchain.',
                      color: whitePaperPinkColor,
                    ),
                  ],
                ),
              ),

              // ==================================================
              // 11 TRANSACTION HISTORY
              // ==================================================

              _section(
                number: '11',
                icon: Icons.history_rounded,
                title: 'Transaction History',
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    _paragraph(
                      'The application provides a transaction '
                      'history view where recorded reward activity '
                      'can be displayed to the user.',
                    ),

                    const SizedBox(height: 16),

                    _bullet(
                      'Mining reward activity.',
                    ),

                    _bullet(
                      'Daily reward activity.',
                    ),

                    _bullet(
                      'Rewarded advertisement activity.',
                    ),

                    _bullet(
                      'Balance after a recorded reward.',
                    ),

                    _bullet(
                      'Transaction date and activity type.',
                    ),
                  ],
                ),
              ),

              // ==================================================
              // 12 SECURITY
              // ==================================================

              _section(
                number: '12',
                icon: Icons.security_rounded,
                title: 'Security & Anti-Abuse',
                accent: whitePaperGoldColor,
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    _paragraph(
                      'The Stelluriini application uses server-side '
                      'validation to reduce manipulation of reward '
                      'operations. Security mechanisms are intended '
                      'to protect the integrity of the application '
                      'and its reward system.',
                    ),

                    const SizedBox(height: 18),

                    _featureRow(
                      icon: Icons.verified_user_rounded,
                      title: 'Authentication',
                      description:
                          'Reward operations require an authenticated user session.',
                      accent: whitePaperGoldColor,
                    ),

                    _featureRow(
                      icon: Icons.block_rounded,
                      title: 'Duplicate Protection',
                      description:
                          'Reward transactions can be protected against repeated processing.',
                      accent: whitePaperGoldColor,
                    ),

                    _featureRow(
                      icon: Icons.speed_rounded,
                      title: 'Rate Limits',
                      description:
                          'Daily limits and cooldown periods help reduce automated abuse.',
                      accent: whitePaperGoldColor,
                    ),

                    _featureRow(
                      icon: Icons.verified_rounded,
                      title: 'Reward Validation',
                      description:
                          'Server-side logic validates important reward conditions before recording them.',
                      accent: whitePaperGoldColor,
                    ),
                  ],
                ),
              ),

              // ==================================================
              // 13 COMMUNITY
              // ==================================================

              _section(
                number: '13',
                icon: Icons.groups_rounded,
                title: 'Community',
                accent: whitePaperPinkColor,
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    _paragraph(
                      'Community participation is an important '
                      'part of the Stelluriini vision. The project '
                      'aims to develop an environment where users '
                      'can follow progress, provide feedback and '
                      'participate in future ecosystem activities.',
                    ),

                    const SizedBox(height: 18),

                    _bullet(
                      'Community feedback can influence future development.',
                      accent: whitePaperPinkColor,
                    ),

                    _bullet(
                      'Future community features may expand the role of STL.',
                      accent: whitePaperPinkColor,
                    ),

                    _bullet(
                      'Transparency is intended to remain an important project principle.',
                      accent: whitePaperPinkColor,
                    ),
                  ],
                ),
              ),

              // ==================================================
              // 14 FUTURE ECOSYSTEM
              // ==================================================

              _section(
                number: '14',
                icon: Icons.rocket_launch_rounded,
                title: 'Future Ecosystem',
                accent: whitePaperAccentColor,
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    _paragraph(
                      'The future Stelluriini ecosystem may expand '
                      'beyond the current application. Potential '
                      'directions include new Stella experiences, '
                      'games, applications, community features and '
                      'additional Solana integrations.',
                    ),

                    const SizedBox(height: 18),

                    _featureRow(
                      icon: Icons.sports_esports_rounded,
                      title: 'Stella Games',
                      description:
                          'Explore games and interactive experiences featuring Stella.',
                      accent: whitePaperPinkColor,
                    ),

                    _featureRow(
                      icon: Icons.apps_rounded,
                      title: 'New Applications',
                      description:
                          'Develop additional digital products and services around the Stelluriini identity.',
                      accent: whitePaperAccentColor,
                    ),

                    _featureRow(
                      icon: Icons.link_rounded,
                      title: 'STL Integrations',
                      description:
                          'Explore useful integrations involving STL and the Solana ecosystem.',
                      accent: whitePaperGoldColor,
                    ),

                    _featureRow(
                      icon: Icons.emoji_events_rounded,
                      title: 'Community Activities',
                      description:
                          'Potential events, challenges and community-focused reward experiences.',
                      accent: whitePaperPinkColor,
                    ),
                  ],
                ),
              ),

              // ==================================================
              // 15 ROADMAP
              // ==================================================

              _section(
                number: '15',
                icon: Icons.map_rounded,
                title: 'Roadmap',
                child: Column(
                  children: [
                    _phaseRow(
                      phase: '01',
                      title: 'The Beginning',
                      status: 'IN PROGRESS',
                      description:
                          'Establish the Stelluriini identity, '
                          'develop Stella branding, build the '
                          'application and prepare STL information.',
                      accent: whitePaperPinkColor,
                    ),

                    _phaseRow(
                      phase: '02',
                      title: 'Community',
                      status: 'PLANNED',
                      description:
                          'Grow the community, improve language '
                          'support, develop daily activities and '
                          'community features.',
                      accent: whitePaperAccentColor,
                    ),

                    _phaseRow(
                      phase: '03',
                      title: 'STL Ecosystem',
                      status: 'FUTURE',
                      description:
                          'Expand STL ecosystem functionality, '
                          'blockchain information, statistics and '
                          'additional Stelluriini features.',
                      accent: whitePaperGoldColor,
                    ),

                    _phaseRow(
                      phase: '04',
                      title: 'The Future',
                      status: 'FUTURE',
                      description:
                          'Continue ecosystem development, introduce '
                          'new Stella experiences and explore new '
                          'possibilities for STL.',
                      accent: whitePaperPinkColor,
                    ),
                  ],
                ),
              ),

              // ==================================================
              // 16 TRANSPARENCY
              // ==================================================

              _section(
                number: '16',
                icon: Icons.visibility_rounded,
                title: 'Transparency',
                accent: whitePaperGoldColor,
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    _paragraph(
                      'Stelluriini aims to clearly distinguish '
                      'existing functionality from future plans. '
                      'The project documentation is intended to '
                      'describe the current state of the project '
                      'and its planned direction as accurately as '
                      'possible.',
                    ),

                    const SizedBox(height: 18),

                    _bullet(
                      'The STL total supply is documented.',
                      accent: whitePaperGoldColor,
                    ),

                    _bullet(
                      'The token allocation structure is documented.',
                      accent: whitePaperGoldColor,
                    ),

                    _bullet(
                      'The current application functionality is described separately from future plans.',
                      accent: whitePaperGoldColor,
                    ),

                    _bullet(
                      'Roadmap priorities may change as development continues.',
                      accent: whitePaperGoldColor,
                    ),
                  ],
                ),
              ),

              // ==================================================
              // 17 RISKS
              // ==================================================

              _section(
                number: '17',
                icon: Icons.warning_amber_rounded,
                title: 'Risks & Limitations',
                accent: Colors.orangeAccent,
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    _paragraph(
                      'Digital assets and software projects involve '
                      'technical, market, regulatory and operational '
                      'risks. Users should understand these risks '
                      'before interacting with any blockchain-based '
                      'asset or application.',
                    ),

                    const SizedBox(height: 18),

                    _bullet(
                      'Cryptocurrency markets can be highly volatile.',
                      accent: Colors.orangeAccent,
                    ),

                    _bullet(
                      'Blockchain transactions may involve irreversible actions.',
                      accent: Colors.orangeAccent,
                    ),

                    _bullet(
                      'Software may contain bugs or technical limitations.',
                      accent: Colors.orangeAccent,
                    ),

                    _bullet(
                      'Blockchain and regulatory environments may change.',
                      accent: Colors.orangeAccent,
                    ),

                    _bullet(
                      'Future roadmap items are not guaranteed.',
                      accent: Colors.orangeAccent,
                    ),

                    _bullet(
                      'In-app virtual rewards should not be interpreted as guaranteed financial returns.',
                      accent: Colors.orangeAccent,
                    ),
                  ],
                ),
              ),

              // ==================================================
              // 18 DISCLAIMER
              // ==================================================

              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(
                  bottom: 18,
                ),
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.orangeAccent.withValues(
                    alpha: 0.07,
                  ),
                  borderRadius:
                      BorderRadius.circular(22),
                  border: Border.all(
                    color: Colors.orangeAccent.withValues(
                      alpha: 0.24,
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.gavel_rounded,
                      color: Colors.orangeAccent,
                      size: 32,
                    ),

                    const SizedBox(height: 12),

                    const Text(
                      '18 • DISCLAIMER',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.orangeAccent,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),

                    const SizedBox(height: 12),

                    const Text(
                      'Stelluriini and STL are presented as a '
                      'community-driven digital project. Information '
                      'in this document is provided for informational '
                      'purposes only and does not constitute '
                      'financial, investment, legal or tax advice.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 13,
                        height: 1.55,
                      ),
                    ),

                    const SizedBox(height: 12),

                    const Text(
                      'Virtual points displayed in the application '
                      'should not be interpreted as guaranteed '
                      'cryptocurrency value or guaranteed financial '
                      'returns.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        height: 1.55,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              // ==================================================
              // 19 OFFICIAL INFORMATION
              // ==================================================

              _section(
                number: '19',
                icon: Icons.link_rounded,
                title: 'Official Information',
                accent: whitePaperPinkColor,
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    _paragraph(
                      'The official Stelluriini application should '
                      'be used together with verified project '
                      'information. Always verify token addresses '
                      'before interacting with blockchain assets.',
                    ),

                    const SizedBox(height: 18),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color:
                            whitePaperBackgroundColor
                                .withValues(
                          alpha: 0.45,
                        ),
                        borderRadius:
                            BorderRadius.circular(15),
                        border: Border.all(
                          color:
                              whitePaperPinkColor.withValues(
                            alpha: 0.15,
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'STELLURIINI MINT',
                            style: TextStyle(
                              color:
                                  whitePaperPinkColor,
                              fontSize: 11,
                              fontWeight:
                                  FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),

                          const SizedBox(height: 8),

                          const SelectableText(
                            mintAddress,
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ==================================================
              // STELLA CLOSING CARD
              // ==================================================

              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(
                  22,
                  24,
                  22,
                  24,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF21113B),
                      Color(0xFF281540),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius:
                      BorderRadius.circular(24),
                  border: Border.all(
                    color:
                        whitePaperPinkColor.withValues(
                      alpha: 0.20,
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    const CatAvatar(
                      size: 82,
                    ),

                    const SizedBox(height: 14),

                    const Text(
                      '🐱 Stella is just getting started.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: whitePaperPinkColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      'Community • Curiosity • Creativity • Solana',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ==================================================
              // FOOTER
              // ==================================================

              const Text(
                '🐾 STELLA • STELLURIINI • STL • SOLANA 🐾',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: whitePaperPinkColor,
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
                  color: whitePaperGoldColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 6),

              const Text(
                'WHITE PAPER v1.0',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 10,
                  letterSpacing: 1.2,
                ),
              ),

              const SizedBox(height: 18),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // ARCHITECTURE BOX
  // ==========================================================

  Widget _architectureBox({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: whitePaperBackgroundColor.withValues(
          alpha: 0.42,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(
            alpha: 0.18,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(
                alpha: 0.10,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 21,
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
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  description,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
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

  // ==========================================================
  // ARCHITECTURE ARROW
  // ==========================================================

  Widget _architectureArrow() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 7,
      ),
      child: Icon(
        Icons.arrow_downward_rounded,
        color: whitePaperAccentColor.withValues(
          alpha: 0.45,
        ),
        size: 20,
      ),
    );
  }
}