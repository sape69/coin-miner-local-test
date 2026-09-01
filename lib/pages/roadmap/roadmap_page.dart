import 'package:flutter/material.dart';

const Color roadmapBackgroundColor = Color(0xFF0B1112);
const Color roadmapCardColor = Color(0xFF151B1C);
const Color roadmapAccentColor = Color(0xFF35D0A0);

class RoadmapPage extends StatelessWidget {
  const RoadmapPage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: roadmapBackgroundColor,

      appBar: AppBar(
        title: const Text(
          'Stelluriini Roadmap',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ================================================
            // HEADER
            // ================================================

            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: roadmapCardColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: roadmapAccentColor.withValues(
                    alpha: 0.25,
                  ),
                ),
              ),
              child: const Column(
                children: [
                  Text(
                    '🐾',
                    style: TextStyle(
                      fontSize: 55,
                    ),
                  ),

                  SizedBox(height: 12),

                  Text(
                    'STELLURIINI ROADMAP',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      color: roadmapAccentColor,
                    ),
                  ),

                  SizedBox(height: 10),

                  Text(
                    'Follow Stella’s journey into the future.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ================================================
            // PHASE 1
            // ================================================

            _RoadmapStep(
              phase: 'PHASE 1',
              title: 'The Beginning',
              description:
                  '🐱 Create the Stelluriini identity\n'
                  '🎨 Develop the Stella visual style\n'
                  '📱 Build the Stelluriini application\n'
                  '🪙 Prepare STL token information',
              status: 'IN PROGRESS',
              completed: false,
            ),

            const _RoadmapLine(),

            // ================================================
            // PHASE 2
            // ================================================

            _RoadmapStep(
              phase: 'PHASE 2',
              title: 'Community',
              description:
                  '🐾 Grow the Stelluriini community\n'
                  '🌍 Improve language support\n'
                  '🎁 Develop rewards and daily activities\n'
                  '💬 Build community features',
              status: 'PLANNED',
              completed: false,
            ),

            const _RoadmapLine(),

            // ================================================
            // PHASE 3
            // ================================================

            _RoadmapStep(
              phase: 'PHASE 3',
              title: 'STL Ecosystem',
              description:
                  '🪙 Develop the STL ecosystem\n'
                  '🔗 Connect blockchain information\n'
                  '📊 Add token statistics\n'
                  '🚀 Expand Stelluriini features',
              status: 'FUTURE',
              completed: false,
            ),

            const _RoadmapLine(),

            // ================================================
            // PHASE 4
            // ================================================

            _RoadmapStep(
              phase: 'PHASE 4',
              title: 'The Future',
              description:
                  '🌟 Continue ecosystem development\n'
                  '🐱 Introduce new Stella experiences\n'
                  '🤝 Expand community participation\n'
                  '🚀 Explore new possibilities for STL',
              status: 'FUTURE',
              completed: false,
            ),

            const SizedBox(height: 30),

            // ================================================
            // FOOTER
            // ================================================

            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: roadmapAccentColor.withValues(
                  alpha: 0.08,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: roadmapAccentColor.withValues(
                    alpha: 0.20,
                  ),
                ),
              ),
              child: const Column(
                children: [
                  Text(
                    '🐾',
                    style: TextStyle(
                      fontSize: 30,
                    ),
                  ),

                  SizedBox(height: 8),

                  Text(
                    'The roadmap may evolve as the Stelluriini project grows.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 13,
                      height: 1.4,
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
// ROADMAP STEP
// ============================================================

class _RoadmapStep extends StatelessWidget {
  final String phase;
  final String title;
  final String description;
  final String status;
  final bool completed;

  const _RoadmapStep({
    required this.phase,
    required this.title,
    required this.description,
    required this.status,
    required this.completed,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor =
        completed
            ? Colors.greenAccent
            : roadmapAccentColor;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // PAW

        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: statusColor.withValues(
              alpha: 0.15,
            ),
            shape: BoxShape.circle,
            border: Border.all(
              color: statusColor.withValues(
                alpha: 0.50,
              ),
            ),
          ),
          child: Center(
            child: Text(
              completed ? '✓' : '🐾',
              style: TextStyle(
                fontSize: completed ? 24 : 25,
                color: statusColor,
              ),
            ),
          ),
        ),

        const SizedBox(width: 14),

        // CARD

        Expanded(
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: roadmapCardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: statusColor.withValues(
                  alpha: 0.15,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      phase,
                      style: const TextStyle(
                        color: roadmapAccentColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),

                    const Spacer(),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(
                          alpha: 0.12,
                        ),
                        borderRadius:
                            BorderRadius.circular(10),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  description,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 14,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// ROADMAP LINE
// ============================================================

class _RoadmapLine extends StatelessWidget {
  const _RoadmapLine();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(
        left: 26,
        top: 4,
        bottom: 4,
      ),
      width: 2,
      height: 35,
      color: roadmapAccentColor.withValues(
        alpha: 0.25,
      ),
    );
  }
}