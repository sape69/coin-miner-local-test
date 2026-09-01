import 'package:flutter/material.dart';

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
              child: const Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(
                      Icons.description_outlined,
                      size: 70,
                      color: whitePaperAccentColor,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'STELLURIINI',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 3,
                        color: whitePaperAccentColor,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'White Paper',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white70,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'STL • Solana',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.white54,
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

            _buildSection(
              icon: Icons.pets_outlined,
              title: '1. Introduction',
              child: const Text(
                'Stelluriini is a community-driven project '
                'built around a curious cat and an ambitious '
                'community.\n\n'
                'The goal of Stelluriini is to create a fun, '
                'recognizable and community-focused ecosystem '
                'around the STL token.',
              ),
            ),

            const SizedBox(height: 16),

            // ==================================================
            // VISION
            // ==================================================

            _buildSection(
              icon: Icons.visibility_outlined,
              title: '2. Vision',
              child: const Text(
                'The vision of Stelluriini is to grow together '
                'with its community.\n\n'
                'The project aims to combine entertainment, '
                'community participation and future digital '
                'experiences around the Stelluriini ecosystem.',
              ),
            ),

            const SizedBox(height: 16),

            // ==================================================
            // STL TOKEN
            // ==================================================

            _buildSection(
              icon: Icons.monetization_on_outlined,
              title: '3. STL Token',
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InfoRow(
                    label: 'Name',
                    value: 'Stelluriini',
                  ),
                  SizedBox(height: 12),
                  _InfoRow(
                    label: 'Symbol',
                    value: 'STL',
                  ),
                  SizedBox(height: 12),
                  _InfoRow(
                    label: 'Blockchain',
                    value: 'Solana',
                  ),
                  SizedBox(height: 12),
                  _InfoRow(
                    label: 'Total Supply',
                    value: '100,000,000,000 STL',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ==================================================
            // COMMUNITY
            // ==================================================

            _buildSection(
              icon: Icons.groups_outlined,
              title: '4. Community',
              child: const Text(
                'Community is at the heart of Stelluriini.\n\n'
                'The project is designed to grow through '
                'participation, creativity and support from '
                'people who want to be part of the STL journey.',
              ),
            ),

            const SizedBox(height: 16),

            // ==================================================
            // APPLICATION
            // ==================================================

            _buildSection(
              icon: Icons.phone_android_outlined,
              title: '5. Stelluriini Application',
              child: const Text(
                'The Stelluriini application is designed to '
                'provide a fun way to interact with the '
                'Stelluriini ecosystem.\n\n'
                'Users can collect virtual STL points through '
                'daily rewards and other in-app activities.\n\n'
                'Virtual STL points shown inside the application '
                'are currently in-app points and are not '
                'automatically withdrawable cryptocurrency.',
              ),
            ),

            const SizedBox(height: 16),

            // ==================================================
            // DAILY REWARDS
            // ==================================================

            _buildSection(
              icon: Icons.card_giftcard_outlined,
              title: '6. Daily Rewards',
              child: const Text(
                'The application includes a daily reward system.\n\n'
                'Day 1: 1 STL\n'
                'Day 2: 2 STL\n'
                'Day 3: 3 STL\n'
                'Day 4: 4 STL\n'
                'Day 5: 5 STL\n'
                'Day 6: 6 STL\n'
                'Day 7: 7 STL\n\n'
                'After reaching Day 7, the daily reward remains '
                'at 7 STL per day.\n\n'
                'If a daily reward is missed, the streak starts '
                'again from Day 1.',
              ),
            ),

            const SizedBox(height: 16),

            // ==================================================
            // AD REWARDS
            // ==================================================

            _buildSection(
              icon: Icons.play_circle_outline,
              title: '7. Reward System',
              child: const Text(
                'The application may include optional rewarded '
                'advertisements.\n\n'
                'Watching an eligible rewarded advertisement can '
                'provide virtual STL points inside the '
                'application.\n\n'
                'Reward limits and cooldown periods may apply to '
                'maintain a balanced experience.',
              ),
            ),

            const SizedBox(height: 16),

            // ==================================================
            // FUTURE
            // ==================================================

            _buildSection(
              icon: Icons.rocket_launch_outlined,
              title: '8. Future',
              child: const Text(
                'Stelluriini is intended to develop gradually.\n\n'
                'Future development may include new application '
                'features, community activities, ecosystem tools '
                'and additional experiences for STL supporters.\n\n'
                'Development priorities may change based on '
                'technical requirements and community feedback.',
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.warning_amber_outlined,
                          color: Colors.orange,
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
                      'Cryptocurrency and digital assets can '
                      'involve significant risk. Always do your '
                      'own research before making financial '
                      'decisions.',
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 15,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
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
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DefaultTextStyle(
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
                height: 1.5,
              ),
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            '$label:',
            style: const TextStyle(
              color: Colors.white54,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: whitePaperAccentColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}