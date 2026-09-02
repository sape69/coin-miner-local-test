import 'package:flutter/material.dart';

import '../../widgets/cat_avatar.dart';

const Color whitePaperBackgroundColor = Color(0xFF0B1112);
const Color whitePaperCardColor = Color(0xFF151B1C);
const Color whitePaperAccentColor = Color(0xFF35D0A0);

class WhitePaperPage extends StatelessWidget {
  const WhitePaperPage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: whitePaperBackgroundColor,

      appBar: AppBar(
        title: const Text(
          'Stelluriini White Paper',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ==================================================
            // HEADER
            // ==================================================

            Card(
              color: whitePaperCardColor,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const CatAvatar(
                      size: 120,
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      'STELLURIINI',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 3,
                        color: whitePaperAccentColor,
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      'WHITE PAPER',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 3,
                        color: Colors.white70,
                      ),
                    ),

                    const SizedBox(height: 14),

                    Text(
                      'STL • Solana',
                      style: TextStyle(
                        color: Colors.white.withValues(
                          alpha: 0.60,
                        ),
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ==================================================
            // INTRODUCTION
            // ==================================================

            const _WhitePaperSection(
              icon: Icons.auto_awesome_outlined,
              title: 'Introduction',
              text:
                  'Stelluriini is a community-driven project '
                  'built around Stella, a curious cat, and the '
                  'STL ecosystem. The project combines community, '
                  'fun and digital experiences into a growing '
                  'Stelluriini universe.',
            ),

            const SizedBox(height: 16),

            // ==================================================
            // VISION
            // ==================================================

            const _WhitePaperSection(
              icon: Icons.visibility_outlined,
              title: 'Vision',
              text:
                  'The vision of Stelluriini is to build a fun, '
                  'recognizable and community-focused ecosystem. '
                  'The project can evolve over time through new '
                  'features, experiences and community participation.',
            ),

            const SizedBox(height: 16),

            // ==================================================
            // MISSION
            // ==================================================

            const _WhitePaperSection(
              icon: Icons.rocket_launch_outlined,
              title: 'Mission',
              text:
                  'Our mission is to create an enjoyable digital '
                  'experience around the Stelluriini identity and '
                  'develop a strong foundation for the future of '
                  'the STL ecosystem.',
            ),

            const SizedBox(height: 16),

            // ==================================================
            // STL TOKEN
            // ==================================================

            Card(
              color: whitePaperCardColor,
              child: const Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.monetization_on_outlined,
                          color: whitePaperAccentColor,
                          size: 30,
                        ),
                        SizedBox(width: 10),
                        Text(
                          'STL Token',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 20),

                    _WhitePaperInfoRow(
                      label: 'Name',
                      value: 'Stelluriini',
                    ),

                    SizedBox(height: 12),

                    _WhitePaperInfoRow(
                      label: 'Symbol',
                      value: 'STL',
                    ),

                    SizedBox(height: 12),

                    _WhitePaperInfoRow(
                      label: 'Blockchain',
                      value: 'Solana',
                    ),

                    SizedBox(height: 12),

                    _WhitePaperInfoRow(
                      label: 'Total Supply',
                      value: '17 602 539 062 STL',
                    ),

                    SizedBox(height: 12),

                    _WhitePaperInfoRow(
                      label: 'Decimals',
                      value: '9',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ==================================================
            // ECOSYSTEM
            // ==================================================

            const _WhitePaperSection(
              icon: Icons.account_tree_outlined,
              title: 'STL Ecosystem',
              text:
                  'The Stelluriini ecosystem is designed to grow '
                  'step by step. The mobile application provides '
                  'a central place for community experiences, '
                  'daily activities, rewards and future ecosystem '
                  'features.',
            ),

            const SizedBox(height: 16),

            // ==================================================
            // APPLICATION
            // ==================================================

            const _WhitePaperSection(
              icon: Icons.phone_android_outlined,
              title: 'Stelluriini Application',
              text:
                  'The Stelluriini application is being developed '
                  'as an interactive home for the community. '
                  'Features can include daily activities, rewards, '
                  'Stella facts, project information and future '
                  'ecosystem experiences.',
            ),

            const SizedBox(height: 16),

            // ==================================================
            // COMMUNITY
            // ==================================================

            const _WhitePaperSection(
              icon: Icons.groups_outlined,
              title: 'Community',
              text:
                  'Community is an important part of Stelluriini. '
                  'The project aims to grow together with its users '
                  'and supporters. Community feedback may help shape '
                  'future ideas and development.',
            ),

            const SizedBox(height: 16),

            // ==================================================
            // DEVELOPMENT
            // ==================================================

            const _WhitePaperSection(
              icon: Icons.construction_outlined,
              title: 'Development',
              text:
                  'Stelluriini is an evolving project. New features '
                  'and improvements may be introduced gradually. '
                  'The roadmap represents the general direction of '
                  'development and may change as the project grows.',
            ),

            const SizedBox(height: 16),

            // ==================================================
            // IMPORTANT INFORMATION
            // ==================================================

            Card(
              color: whitePaperCardColor,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: whitePaperAccentColor,
                          size: 30,
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Important Information',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    Text(
                      'STL displayed inside the Stelluriini '
                      'application may represent virtual in-app '
                      'points. These points are not automatically '
                      'connected to a withdrawable cryptocurrency '
                      'balance.',
                      style: TextStyle(
                        color: Colors.white.withValues(
                          alpha: 0.65,
                        ),
                        fontSize: 15,
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 16),

                    Text(
                      'Nothing in this document should be considered '
                      'financial or investment advice. Digital assets '
                      'can involve significant risks.',
                      style: TextStyle(
                        color: Colors.orangeAccent.withValues(
                          alpha: 0.85,
                        ),
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            // ==================================================
            // FOOTER
            // ==================================================

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: whitePaperAccentColor.withValues(
                  alpha: 0.08,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: whitePaperAccentColor.withValues(
                    alpha: 0.20,
                  ),
                ),
              ),
              child: const Column(
                children: [
                  Text(
                    '🐱 🐾 🪙',
                    style: TextStyle(
                      fontSize: 30,
                    ),
                  ),

                  SizedBox(height: 12),

                  Text(
                    'The Stelluriini White Paper may evolve as the project develops.',
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

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// WHITE PAPER SECTION
// ============================================================

class _WhitePaperSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;

  const _WhitePaperSection({
    required this.icon,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: whitePaperCardColor,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: whitePaperAccentColor,
                  size: 30,
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Text(
              text,
              style: TextStyle(
                color: Colors.white.withValues(
                  alpha: 0.70,
                ),
                fontSize: 15,
                height: 1.55,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// INFORMATION ROW
// ============================================================

class _WhitePaperInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _WhitePaperInfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 15,
            ),
          ),
        ),

        const SizedBox(width: 16),

        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}