import 'package:flutter/material.dart';

const Color backgroundColor = Color(0xFF0B1112);
const Color cardColor = Color(0xFF151B1C);
const Color accentColor = Color(0xFF35D0A0);

class WhitePaperPage extends StatelessWidget {
  const WhitePaperPage({super.key});

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

  Widget _bullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 5),
            child: Icon(
              Icons.pets,
              color: accentColor,
              size: 16,
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

  Widget _tokenRow(
    String title,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
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
          Text(
            value,
            style: const TextStyle(
              color: accentColor,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,

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

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ==========================================
              // HEADER
              // ==========================================

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
                      'White Paper • STL • Solana',
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

              // ==========================================
              // INTRODUCTION
              // ==========================================

              _section(
                icon: Icons.pets_rounded,
                title: 'What is Stelluriini?',
                child: _paragraph(
                  'Stelluriini (STL) is a community-driven token built on '
                  'the Solana blockchain. The project is inspired by Stella, '
                  'a curious cat and the heart of the Stelluriini community.',
                ),
              ),

              // ==========================================
              // VISION
              // ==========================================

              _section(
                icon: Icons.visibility_rounded,
                title: 'Our Vision',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _paragraph(
                      'The vision of Stelluriini is to create a fun, friendly '
                      'and community-focused digital ecosystem around STL.',
                    ),
                    const SizedBox(height: 16),
                    _bullet(
                      'Build a welcoming community around Stelluriini.',
                    ),
                    _bullet(
                      'Develop useful and entertaining digital experiences.',
                    ),
                    _bullet(
                      'Create a recognizable identity around Stella.',
                    ),
                    _bullet(
                      'Explore future opportunities within the Solana ecosystem.',
                    ),
                  ],
                ),
              ),

              // ==========================================
              // TOKEN
              // ==========================================

              _section(
                icon: Icons.monetization_on_rounded,
                title: 'STL Token',
                child: Column(
                  children: [
                    _tokenRow(
                      'Token Name',
                      'Stelluriini',
                    ),

                    Divider(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),

                    _tokenRow(
                      'Symbol',
                      'STL',
                    ),

                    Divider(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),

                    _tokenRow(
                      'Blockchain',
                      'Solana',
                    ),

                    Divider(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),

                    _tokenRow(
                      'Type',
                      'Community Token',
                    ),
                  ],
                ),
              ),

              // ==========================================
              // COMMUNITY
              // ==========================================

              _section(
                icon: Icons.groups_rounded,
                title: 'Community',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _paragraph(
                      'The Stelluriini project is built around the idea that '
                      'a strong community is an important part of every '
                      'successful ecosystem.',
                    ),
                    const SizedBox(height: 16),
                    _bullet(
                      'Community participation and feedback.',
                    ),
                    _bullet(
                      'A friendly and recognizable cat-themed identity.',
                    ),
                    _bullet(
                      'Future development based on community interest.',
                    ),
                  ],
                ),
              ),

              // ==========================================
              // STELLA
              // ==========================================

              _section(
                icon: Icons.favorite_rounded,
                title: 'Meet Stella',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _paragraph(
                      'Stella is the inspiration behind Stelluriini. '
                      'Her curious personality and cat-themed identity '
                      'represent the playful spirit of the project.',
                    ),
                    const SizedBox(height: 16),
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

              // ==========================================
              // FUTURE
              // ==========================================

              _section(
                icon: Icons.rocket_launch_rounded,
                title: 'The Future',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _paragraph(
                      'Stelluriini is designed as a growing project. '
                      'Future development may include new community features, '
                      'applications, games and other digital experiences.',
                    ),
                    const SizedBox(height: 16),
                    _bullet('Community growth.'),
                    _bullet('Application development.'),
                    _bullet('Games and digital experiences.'),
                    _bullet('Expansion of the Stelluriini ecosystem.'),
                  ],
                ),
              ),

              // ==========================================
              // DISCLAIMER
              // ==========================================

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
                      'purposes only. Nothing in this document should be '
                      'considered financial or investment advice. '
                      'Cryptocurrency involves risk.',
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