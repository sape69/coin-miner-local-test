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
            // 1. INTRODUCTION
            // ==================================================

            const _WhitePaperSection(
              icon: Icons.auto_awesome_outlined,
              title: '1. Introduction',
              text:
                  'Stelluriini is a community-driven project built '
                  'around Stella, a curious cat, and an ambitious '
                  'community.\n\n'
                  'The goal of Stelluriini is to create a fun, '
                  'recognizable and community-focused ecosystem '
                  'around the STL token and the Stelluriini universe.',
            ),

            const SizedBox(height: 16),

            // ==================================================
            // 2. VISION
            // ==================================================

            const _WhitePaperSection(
              icon: Icons.visibility_outlined,
              title: '2. Vision',
              text:
                  'The vision of Stelluriini is to build a fun, '
                  'recognizable and community-focused ecosystem.\n\n'
                  'The project aims to grow together with its '
                  'community through new features, digital '
                  'experiences and community participation.',
            ),

            const SizedBox(height: 16),

            // ==================================================
            // 3. MISSION
            // ==================================================

            const _WhitePaperSection(
              icon: Icons.rocket_launch_outlined,
              title: '3. Mission',
              text:
                  'Our mission is to create an enjoyable digital '
                  'experience around the Stelluriini identity and '
                  'build a strong foundation for the future of '
                  'the STL ecosystem.\n\n'
                  'Development is intended to happen gradually as '
                  'the project and its community grow.',
            ),

            const SizedBox(height: 16),

            // ==================================================
            // 4. STL TOKEN
            // ==================================================

            Card(
              color: whitePaperCardColor,
              child: const Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                          '4. STL Token',
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

                    SizedBox(height: 14),

                    _WhitePaperInfoRow(
                      label: 'Symbol',
                      value: 'STL',
                    ),

                    SizedBox(height: 14),

                    _WhitePaperInfoRow(
                      label: 'Blockchain',
                      value: 'Solana',
                    ),

                    SizedBox(height: 14),

                    _WhitePaperInfoRow(
                      label: 'Total Supply',
                      value: '17 602 539 062 STL',
                      accent: true,
                    ),

                    SizedBox(height: 14),

                    _WhitePaperInfoRow(
                      label: 'Decimals',
                      value: '9',
                    ),

                    SizedBox(height: 14),

                    _WhitePaperInfoRow(
                      label: 'Mint Address',
                      value:
                          'AyZun5s9tEJDeHTNPrVbaYpqjWdSKHx25M3kfVFjbdas',
                      small: true,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ==================================================
            // 5. STL ECOSYSTEM
            // ==================================================

            const _WhitePaperSection(
              icon: Icons.account_tree_outlined,
              title: '5. STL Ecosystem',
              text:
                  'The Stelluriini ecosystem is designed to grow '
                  'step by step.\n\n'
                  'The mobile application provides a central place '
                  'for community experiences, project information, '
                  'daily activities, rewards and future ecosystem '
                  'features.',
            ),

            const SizedBox(height: 16),

            // ==================================================
            // 6. STELLURIINI APPLICATION
            // ==================================================

            const _WhitePaperSection(
              icon: Icons.phone_android_outlined,
              title: '6. Stelluriini Application',
              text:
                  'The Stelluriini application is being developed '
                  'as an interactive home for the community.\n\n'
                  'Features may include daily activities, virtual '
                  'rewards, Stella facts, project information and '
                  'future ecosystem experiences.',
            ),

            const SizedBox(height: 16),

            // ==================================================
            // 7. DAILY REWARDS
            // ==================================================

            const _WhitePaperSection(
              icon: Icons.card_giftcard_outlined,
              title: '7. Daily Rewards',
              text:
                  'The application includes a daily reward system '
                  'based on consecutive daily activity.\n\n'
                  'Day 1: 1 STL\n'
                  'Day 2: 2 STL\n'
                  'Day 3: 3 STL\n'
                  'Day 4: 4 STL\n'
                  'Day 5: 5 STL\n'
                  'Day 6: 6 STL\n'
                  'Day 7: 7 STL\n\n'
                  'After reaching Day 7, the reward can remain at '
                  'the maximum daily reward level. Missing a day '
                  'may reset the streak.',
            ),

            const SizedBox(height: 16),

            // ==================================================
            // 8. REWARD SYSTEM
            // ==================================================

            const _WhitePaperSection(
              icon: Icons.play_circle_outline,
              title: '8. Reward System',
              text:
                  'The application may include optional rewarded '
                  'advertisements.\n\n'
                  'Watching an eligible rewarded advertisement can '
                  'provide virtual STL points inside the '
                  'application.\n\n'
                  'Daily limits and cooldown periods may apply to '
                  'maintain a balanced user experience.',
            ),

            const SizedBox(height: 16),

            // ==================================================
            // 9. COMMUNITY
            // ==================================================

            const _WhitePaperSection(
              icon: Icons.groups_outlined,
              title: '9. Community',
              text:
                  'Community is an important part of Stelluriini.\n\n'
                  'The project aims to grow together with users and '
                  'supporters. Community feedback and participation '
                  'may help shape future ideas and development.',
            ),

            const SizedBox(height: 16),

            // ==================================================
            // 10. DEVELOPMENT
            // ==================================================

            const _WhitePaperSection(
              icon: Icons.construction_outlined,
              title: '10. Development',
              text:
                  'Stelluriini is an evolving project. New features '
                  'and improvements may be introduced gradually.\n\n'
                  'The roadmap represents the general direction of '
                  'development and may evolve as technical '
                  'requirements, opportunities and community needs '
                  'change.',
            ),

            const SizedBox(height: 16),

            // ==================================================
            // 11. FUTURE
            // ==================================================

            const _WhitePaperSection(
              icon: Icons.rocket_launch_outlined,
              title: '11. The Future',
              text:
                  'Future development may include new application '
                  'features, community activities, ecosystem tools '
                  'and additional experiences for STL supporters.\n\n'
                  'Stelluriini intends to explore new possibilities '
                  'while continuing to develop its identity and '
                  'community.',
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
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                      'application currently represents virtual '
                      'in-app points unless explicitly stated '
                      'otherwise. These points are not automatically '
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
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ==================================================
            // DISCLAIMER
            // ==================================================

            Card(
              color: whitePaperCardColor,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.warning_amber_outlined,
                          color: Colors.orangeAccent,
                          size: 30,
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Disclaimer',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    Text(
                      'This document is provided for general '
                      'information purposes only and does not '
                      'constitute financial, investment or legal '
                      'advice.\n\n'
                      'Cryptocurrency and digital assets can involve '
                      'significant risks. Always do your own research '
                      'before making financial decisions.',
                      style: TextStyle(
                        color: Colors.orangeAccent.withValues(
                          alpha: 0.80,
                        ),
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

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
          crossAxisAlignment: CrossAxisAlignment.start,
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
  final bool accent;
  final bool small;

  const _WhitePaperInfoRow({
    required this.label,
    required this.value,
    this.accent = false,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 105,
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 15,
            ),
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: accent
                  ? whitePaperAccentColor
                  : Colors.white,
              fontSize: small ? 12 : 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}