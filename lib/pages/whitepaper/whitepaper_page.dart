import 'package:flutter/material.dart';

const Color backgroundColor = Color(0xFF0B1112);
const Color cardColor = Color(0xFF151B1C);
const Color accentColor = Color(0xFF35D0A0);

class WhitePaperPage extends StatelessWidget {
  const WhitePaperPage({super.key});

  // ============================================================
  // SECTION
  // ============================================================

  Widget _section({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
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

  // ============================================================
  // PARAGRAPH
  // ============================================================

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

  // ============================================================
  // BULLET
  // ============================================================

  Widget _bullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Icon(
              Icons.check_circle_rounded,
              color: accentColor,
              size: 17,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.72),
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
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: accentColor,
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
      backgroundColor: backgroundColor,

      // ========================================================
      // APP BAR
      // ========================================================

      appBar: AppBar(
        backgroundColor: cardColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
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
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                    color: accentColor.withValues(alpha: 0.30),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.08),
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
                        color: accentColor.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.description_rounded,
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
                      'Official White Paper • STL • Solana',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.65),
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(height: 18),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Text(
                        '🐾 Community-driven token 🐾',
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
              // EXECUTIVE SUMMARY
              // ==================================================

              _section(
                icon: Icons.article_rounded,
                title: 'Executive Summary',
                child: _paragraph(
                  'Stelluriini (STL) is a community-focused digital token '
                  'built on the Solana blockchain. The project combines a '
                  'recognizable cat-themed identity with the goal of building '
                  'a growing digital ecosystem and an engaged community.',
                ),
              ),

              // ==================================================
              // WHAT IS STELLURIINI
              // ==================================================

              _section(
                icon: Icons.pets_rounded,
                title: 'What is Stelluriini?',
                child: _paragraph(
                  'Stelluriini is a community-driven token created on the '
                  'Solana blockchain. The project is inspired by Stella, '
                  'a curious cat whose identity represents the playful, '
                  'friendly and community-oriented spirit of the project.',
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
                child: Column(
                  children: [
                    _tokenRow(
                      'Token Name',
                      'Stelluriini',
                    ),

                    _divider(),

                    _tokenRow(
                      'Symbol',
                      'STL',
                    ),

                    _divider(),

                    _tokenRow(
                      'Blockchain',
                      'Solana',
                    ),

                    _divider(),

                    _tokenRow(
                      'Token Type',
                      'Community Token',
                    ),

                    _divider(),

                    _tokenRow(
                      'Total Supply',
                      '17,602,539,062 STL',
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _paragraph(
                      'The total supply of Stelluriini is fixed at '
                      '17,602,539,062 STL tokens.',
                    ),

                    const SizedBox(height: 18),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: accentColor.withValues(alpha: 0.20),
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
                              color: accentColor,
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
                      'Community participation is an important part of the '
                      'Stelluriini ecosystem. The project aims to develop '
                      'through community interest, feedback and participation.',
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
              // STELLA
              // ==================================================

              _section(
                icon: Icons.favorite_rounded,
                title: 'Meet Stella',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _paragraph(
                      'Stella is the inspiration behind Stelluriini. '
                      'Her curious personality represents exploration, '
                      'playfulness and the unique identity of the project.',
                    ),

                    const SizedBox(height: 18),

                    Center(
                      child: Text(
                        '🐱 🐾 STELLA 🐾 🐱',
                        style: TextStyle(
                          color: accentColor.withValues(alpha: 0.85),
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
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
                      'The Stelluriini project is designed with the potential '
                      'to expand into a broader digital ecosystem over time.',
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
              // DEVELOPMENT DIRECTION
              // ==================================================

              _section(
                icon: Icons.rocket_launch_rounded,
                title: 'Development Direction',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _paragraph(
                      'Stelluriini is intended to develop gradually. '
                      'Future milestones may evolve depending on technical '
                      'development, community growth and available resources.',
                    ),

                    const SizedBox(height: 16),

                    _bullet('Community development.'),

                    _bullet('Expansion of the digital ecosystem.'),

                    _bullet('Development of applications and games.'),

                    _bullet(
                      'Exploration of new opportunities on Solana.',
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
                  'developments clearly to its community. Future information '
                  'and updates may be published through the official '
                  'communication channels of the project.',
                ),
              ),

              // ==================================================
              // DISCLAIMER
              // ==================================================

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.orangeAccent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.orangeAccent.withValues(alpha: 0.25),
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
                      'This White Paper is provided for informational '
                      'purposes only. Nothing in this document constitutes '
                      'financial, investment, legal or tax advice. '
                      'Cryptocurrencies and digital assets involve risk.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.65),
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              Center(
                child: Text(
                  '🐾 STELLURIINI • STL • SOLANA 🐾',
                  style: TextStyle(
                    color: accentColor.withValues(alpha: 0.75),
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