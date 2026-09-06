import 'package:flutter/material.dart';

import '../../widgets/cat_avatar.dart';
import '../../widgets/stelluriini_logo.dart';

const Color whitePaperBackgroundColor = Color(0xFF120B24);
const Color whitePaperCardColor = Color(0xFF21113B);
const Color whitePaperAccentColor = Color(0xFFB58CFF);
const Color whitePaperPinkColor = Color(0xFFFFB7E8);
const Color whitePaperGoldColor = Color(0xFFFFD166);

class WhitePaperPage extends StatelessWidget {
  const WhitePaperPage({super.key});

  // ============================================================
  // SECTION
  // ============================================================

  Widget _section({
    required IconData icon,
    required String title,
    required Widget child,
    Color? accent,
  }) {
    final Color sectionAccent =
        accent ?? whitePaperAccentColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: whitePaperCardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: sectionAccent.withValues(alpha: 0.18),
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
                  color: sectionAccent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: sectionAccent,
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

  // ============================================================
  // PARAGRAPH
  // ============================================================

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

  // ============================================================
  // BULLET
  // ============================================================

  Widget _bullet(
    String text, {
    Color accent = whitePaperAccentColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Icon(
              Icons.check_circle_rounded,
              color: accent,
              size: 17,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 15,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TOKEN INFORMATION ROW
  // ============================================================

  Widget _tokenRow(
    String title,
    String value, {
    Color accent = whitePaperAccentColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: accent,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DIVIDER
  // ============================================================

  Widget _divider() {
    return Divider(
      color: Colors.white.withValues(alpha: 0.08),
      height: 1,
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: whitePaperBackgroundColor,

      // ========================================================
      // APP BAR
      // ========================================================

      appBar: AppBar(
        backgroundColor: whitePaperBackgroundColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'WHITE PAPER',
          style: TextStyle(
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
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
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
                    color: whitePaperAccentColor.withValues(
                      alpha: 0.30,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: whitePaperAccentColor.withValues(
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
                        color: whitePaperPinkColor,
                        fontSize: 27,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 3,
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      'Official White Paper',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 15,
                      ),
                    ),

                    const SizedBox(height: 6),

                    const Text(
                      'STL • SOLANA',
                      style: TextStyle(
                        color: whitePaperAccentColor,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),

                    const SizedBox(height: 18),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: whitePaperPinkColor.withValues(
                          alpha: 0.10,
                        ),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: whitePaperPinkColor.withValues(
                            alpha: 0.20,
                          ),
                        ),
                      ),
                      child: const Text(
                        '🐾 Stella • Community • Solana 🐾',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: whitePaperPinkColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ==================================================
              // EXECUTIVE SUMMARY
              // ==================================================

              _section(
                icon: Icons.article_rounded,
                title: 'Executive Summary',
                child: _paragraph(
                  'Stelluriini (STL) is a community-focused digital '
                  'token project built around a recognizable cat-themed '
                  'identity and the Solana ecosystem. The project aims '
                  'to combine community participation, entertainment '
                  'and future digital applications into one ecosystem.',
              ),

              // ==================================================
              // WHAT IS STELLURIINI
              // ==================================================

              _section(
                icon: Icons.pets_rounded,
                title: 'What is Stelluriini?',
                accent: whitePaperPinkColor,
                child: _paragraph(
                  'Stelluriini is a community-driven project inspired '
                  'by Stella, a curious cat representing the playful, '
                  'friendly and exploratory spirit of the project. '
                  'STL is the token associated with the Stelluriini '
                  'ecosystem on Solana.',
                ),
              ),

              // ==================================================
              // STELLA
              // ==================================================

              _section(
                icon: Icons.favorite_rounded,
                title: 'Meet Stella',
                accent: whitePaperPinkColor,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(
                      child: StelluriiniLogo(
                        size: 80,
                      ),
                    ),

                    const SizedBox(height: 16),

                    const Text(
                      '🐱 Stella is the heart of Stelluriini.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: whitePaperPinkColor,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 14),

                    _paragraph(
                      'Stella represents curiosity, community and '
                      'the fun side of the Stelluriini ecosystem. '
                      'Her identity is used throughout the application '
                      'to make the project recognizable and welcoming.',
                    ),
                  ],
                ),
              ),

              // ==================================================
              // VISION
              // ==================================================

              _section(
                icon: Icons.visibility_rounded,
                title: 'Vision',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _paragraph(
                      'The long-term vision of Stelluriini is to develop '
                      'a recognizable digital ecosystem where community, '
                      'technology and entertainment can come together.',
                    ),

                    const SizedBox(height: 16),

                    _bullet(
                      'Build a strong and welcoming Stelluriini community.',
                    ),

                    _bullet(
                      'Develop useful digital applications and experiences.',
                    ),

                    _bullet(
                      'Create entertaining projects and games.',
                    ),

                    _bullet(
                      'Explore future opportunities within the Solana ecosystem.',
                    ),
                  ],
                ),
              ),

              // ==================================================
              // TOKEN INFORMATION
              // ==================================================

              _section(
                icon: Icons.monetization_on_rounded,
                title: 'Token Information',
                accent: whitePaperGoldColor,
                child: Column(
                  children: [
                    _tokenRow(
                      'Token Name',
                      'Stelluriini',
                      accent: whitePaperPinkColor,
                    ),

                    _divider(),

                    _tokenRow(
                      'Symbol',
                      'STL',
                      accent: whitePaperPinkColor,
                    ),

                    _divider(),

                    _tokenRow(
                      'Blockchain',
                      'Solana',
                      accent: whitePaperAccentColor,
                    ),

                    _divider(),

                    _tokenRow(
                      'Token Type',
                      'Community Token',
                      accent: whitePaperAccentColor,
                    ),

                    _divider(),

                    _tokenRow(
                      'Total Supply',
                      '17,602,539,062 STL',
                      accent: whitePaperGoldColor,
                    ),
                  ],
                ),
              ),

              // ==================================================
              // TOKEN SUPPLY
              // ==================================================

              _section(
                icon: Icons.account_balance_wallet_rounded,
                title: 'Token Supply',
                accent: whitePaperGoldColor,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _paragraph(
                      'The total supply of Stelluriini is '
                      '17,602,539,062 STL tokens.',
                    ),

                    const SizedBox(height: 18),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: whitePaperGoldColor.withValues(
                          alpha: 0.07,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: whitePaperGoldColor.withValues(
                            alpha: 0.20,
                          ),
                        ),
                      ),
                      child: const Column(
                        children: [
                          Text(
                            'TOTAL SUPPLY',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),

                          SizedBox(height: 12),

                          Text(
                            '17,602,539,062',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: whitePaperGoldColor,
                              fontSize: 27,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          SizedBox(height: 5),

                          Text(
                            'STL',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ==================================================
              // COMMUNITY
              // ==================================================

              _section(
                icon: Icons.groups_rounded,
                title: 'Community',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _paragraph(
                      'Community participation is an important part '
                      'of the Stelluriini ecosystem. The project aims '
                      'to develop through community interest, feedback '
                      'and participation.',
                    ),

                    const SizedBox(height: 16),

                    _bullet(
                      'Community participation and feedback.',
                    ),

                    _bullet(
                      'A friendly and recognizable project identity.',
                    ),

                    _bullet(
                      'Future development based on community interest.',
                    ),
                  ],
                ),
              ),

              // ==================================================
              // FUTURE ECOSYSTEM
              // ==================================================

              _section(
                icon: Icons.hub_rounded,
                title: 'Future Ecosystem',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _paragraph(
                      'The Stelluriini project is designed with the '
                      'potential to expand into a broader digital '
                      'ecosystem over time.',
                    ),

                    const SizedBox(height: 16),

                    _bullet(
                      'Community-focused features.',
                    ),

                    _bullet(
                      'Mobile applications.',
                    ),

                    _bullet(
                      'Games and digital experiences.',
                    ),

                    _bullet(
                      'Additional ecosystem integrations.',
                    ),

                    _bullet(
                      'Future development based on resources and community interest.',
                    ),
                  ],
                ),
              ),

              // ==================================================
              // DEVELOPMENT ROADMAP
              // ==================================================

              _section(
                icon: Icons.rocket_launch_rounded,
                title: 'Development Direction',
                accent: whitePaperPinkColor,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _paragraph(
                      'Stelluriini is intended to develop gradually. '
                      'Future milestones may evolve depending on '
                      'technical development, community growth and '
                      'available resources.',
                    ),

                    const SizedBox(height: 16),

                    _bullet(
                      'Community development.',
                      accent: whitePaperPinkColor,
                    ),

                    _bullet(
                      'Expansion of the digital ecosystem.',
                      accent: whitePaperPinkColor,
                    ),

                    _bullet(
                      'Development of applications and games.',
                      accent: whitePaperPinkColor,
                    ),

                    _bullet(
                      'Exploration of new opportunities on Solana.',
                      accent: whitePaperPinkColor,
                    ),
                  ],
                ),
              ),

              // ==================================================
              // TRANSPARENCY
              // ==================================================

              _section(
                icon: Icons.verified_rounded,
                title: 'Transparency',
                child: _paragraph(
                  'Stelluriini aims to communicate important project '
                  'developments clearly to its community. Future '
                  'information and updates may be published through '
                  'the official communication channels of the project.',
                ),
              ),

              // ==================================================
              // DISCLAIMER
              // ==================================================

              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.orangeAccent.withValues(
                    alpha: 0.07,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.orangeAccent.withValues(
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

                    const Text(
                      'Important Notice',
                      style: TextStyle(
                        color: Colors.orangeAccent,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 10),

                    const Text(
                      'This White Paper is provided for informational '
                      'purposes only. Nothing in this document constitutes '
                      'financial, investment, legal or tax advice. '
                      'Cryptocurrencies and digital assets involve risk.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
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
                'Community-driven • Inspired by Stella',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 11,
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                '17 602 539 062 STL',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: whitePaperGoldColor,
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