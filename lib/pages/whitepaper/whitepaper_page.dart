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
          'White Paper',
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

                    const SizedBox(height: 10),

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
              number: '1',
              icon: Icons.auto_awesome_outlined,
              title: 'Introduction',
              text:
                  'Stelluriini is a community-driven digital project '
                  'built around Stella, a curious cat, and the growing '
                  'Stelluriini ecosystem.\n\n'
                  'The project combines community, entertainment and '
                  'digital experiences into a unique universe that can '
                  'develop gradually over time.',
            ),

            const SizedBox(height: 16),

            // ==================================================
            // 2. VISION
            // ==================================================

            const _WhitePaperSection(
              number: '2',
              icon: Icons.visibility_outlined,
              title: 'Vision',
              text:
                  'The vision of Stelluriini is to create a fun, '
                  'recognizable and community-focused ecosystem.\n\n'
                  'The project aims to grow together with its community '
                  'through new features, experiences and future digital '
                  'possibilities.',
            ),

            const SizedBox(height: 16),

            // ==================================================
            // 3. MISSION
            // ==================================================

            const _WhitePaperSection(
              number: '3',
              icon: Icons.rocket_launch_outlined,
              title: 'Mission',
              text:
                  'The mission of Stelluriini is to create an enjoyable '
                  'digital experience around the Stelluriini identity '
                  'and build a strong foundation for future ecosystem '
                  'development.\n\n'
                  'Community participation, creativity and continuous '
                  'development are important parts of the project.',
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
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    _SectionHeader(
                      number: '4',
                      icon: Icons.monetization_on_outlined,
                      title: 'STL Token',
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
              number: '5',
              icon: Icons.account_tree_outlined,
              title: 'STL Ecosystem',
              text:
                  'The Stelluriini ecosystem is designed to develop '
                  'step by step.\n\n'
                  'The mobile application provides a central place for '
                  'project information, community experiences, daily '
                  'activities and future ecosystem features.',
            ),

            const SizedBox(height: 16),

            // ==================================================
            // 6. APPLICATION
            // ==================================================

            const _WhitePaperSection(
              number: '6',
              icon: Icons.phone_android_outlined,
              title: 'Stelluriini Application',
              text:
                  'The Stelluriini application is being developed as '
                  'an interactive digital home for the community.\n\n'
                  'Features can include daily activities, rewards, '
                  'Stella facts, project information, roadmap updates '
                  'and future Stelluriini experiences.\n\n'
                  'The application may continue to evolve as new '
                  'features are developed.',
            ),

            const SizedBox(height: 16),

            // ==================================================
            // 7. DAILY REWARDS
            // ==================================================

            const _WhitePaperSection(
              number: '7',
              icon: Icons.card_giftcard_outlined,
              title: 'Daily Rewards',
              text:
                  'The Stelluriini application can include daily '
                  'activities and reward systems.\n\n'
                  'Users may receive virtual in-app points by '
                  'participating in eligible activities.\n\n'
                  'Reward systems, limits and conditions may change '
                  'as the application develops.',
            ),

            const SizedBox(height: 16),

            // ==================================================
            // 8. REWARD SYSTEM
            // ==================================================

            const _WhitePaperSection(
              number: '8',
              icon: Icons.play_circle_outline,
              title: 'Reward System',
              text:
                  'The application may include optional reward '
                  'activities, including rewarded advertisements.\n\n'
                  'Eligible activities may provide virtual in-app '
                  'points inside the application.\n\n'
                  'Limits and cooldown periods may be used to create '
                  'a balanced experience.',
            ),

            const SizedBox(height: 16),

            // ==================================================
            // 9. COMMUNITY
            // ==================================================

            const _WhitePaperSection(
              number: '9',
              icon: Icons.groups_outlined,
              title: 'Community',
              text:
                  'Community is an important part of Stelluriini.\n\n'
                  'The project aims to grow together with its users '
                  'and supporters. Community feedback, creativity and '
                  'participation may help shape future development.',
            ),

            const SizedBox(height: 16),

            // ==================================================
            // 10. DEVELOPMENT
            // ==================================================

            const _WhitePaperSection(
              number: '10',
              icon: Icons.construction_outlined,
              title: 'Development',
              text:
                  'Stelluriini is an evolving project.\n\n'
                  'New features and improvements may be introduced '
                  'gradually based on development priorities, '
                  'technical requirements and future ideas.\n\n'
                  'The roadmap represents the general direction of '
                  'the project and may evolve over time.',
            ),

            const SizedBox(height: 16),

            // ==================================================
            // 11. FUTURE
            // ==================================================

            const _WhitePaperSection(
              number: '11',
              icon: Icons.auto_graph_outlined,
              title: 'The Future',
              text:
                  'The future of Stelluriini may include new '
                  'application features, community activities and '
                  'additional ecosystem experiences.\n\n'
                  'The project is designed to remain flexible and '
                  'develop gradually as new opportunities emerge.',
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
                    const _SectionHeader(
                      number: '!',
                      icon: Icons.info_outline,
                      title: 'Important Information',
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
                          alpha: 0.70,
                        ),
                        fontSize: 15,
                        height: 1.55,
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
              child: const Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Row(
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

                    SizedBox(height: 16),

                    Text(
                      'This document is provided for general '
                      'information purposes only and does not '
                      'constitute financial, investment or legal '
                      'advice.\n\n'
                      'Cryptocurrency and digital assets can involve '
                      'significant risks. Always do your own research '
                      'before making financial decisions.',
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 15,
                        height: 1.55,
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
  final String number;
  final IconData icon;
  final String title;
  final String text;

  const _WhitePaperSection({
    required this.number,
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
            _SectionHeader(
              number: number,
              icon: icon,
              title: title,
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
// SECTION HEADER
// ============================================================

class _SectionHeader extends StatelessWidget {
  final String number;
  final IconData icon;
  final String title;

  const _SectionHeader({
    required this.number,
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: whitePaperAccentColor.withValues(
              alpha: 0.12,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: whitePaperAccentColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),

        const SizedBox(width: 10),

        Icon(
          icon,
          color: whitePaperAccentColor,
          size: 28,
        ),

        const SizedBox(width: 10),

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
          flex: 3,
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 15,
            ),
          ),
        ),

        const SizedBox(width: 16),

        Expanded(
          flex: 5,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: whitePaperAccentColor,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}