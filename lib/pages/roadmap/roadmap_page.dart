import 'package:flutter/material.dart';

import '../widgets/cat_avatar.dart';
import '../widgets/stelluriini_logo.dart';

// ============================================================
// STELLA THEME COLORS
// ============================================================

const Color roadmapBackgroundColor = Color(0xFF120B24);
const Color roadmapCardColor = Color(0xFF21113B);
const Color roadmapAccentColor = Color(0xFFB58CFF);
const Color roadmapPinkColor = Color(0xFFFFB7E8);
const Color roadmapGoldColor = Color(0xFFFFD166);

// ============================================================
// ROADMAP PAGE
// ============================================================

class RoadmapPage extends StatelessWidget {
  const RoadmapPage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: roadmapBackgroundColor,

      // ========================================================
      // APP BAR
      // ========================================================

      appBar: AppBar(
        backgroundColor: roadmapBackgroundColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Stelluriini Roadmap',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),

      // ========================================================
      // BODY
      // ========================================================

      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            16,
            8,
            16,
            32,
          ),
          children: [
            // ==================================================
            // STELLA HEADER
            // ==================================================

            Container(
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
                  color: roadmapAccentColor.withValues(
                    alpha: 0.30,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: roadmapAccentColor.withValues(
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
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: roadmapPinkColor,
                      fontSize: 27,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 3,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'STL • SOLANA',
                    style: TextStyle(
                      color: roadmapAccentColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),

                  const SizedBox(height: 14),

                  const Text(
                    '🐾 Follow Stella’s journey into the future. 🐾',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ==================================================
            // INTRODUCTION
            // ==================================================

            _RoadmapInfoCard(
              icon: Icons.map_rounded,
              title: 'Our Journey',
              accent: roadmapAccentColor,
              child: const Text(
                'The Stelluriini roadmap describes the planned '
                'direction of the project. Development may evolve '
                'over time as the community, technology and '
                'ecosystem grow.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                  height: 1.6,
                ),
              ),
            ),

            const SizedBox(height: 18),

            // ==================================================
            // ROADMAP
            // ==================================================

            _RoadmapStep(
              phase: 'PHASE 1',
              title: 'The Beginning',
              description:
                  '🐱 Create the Stelluriini identity\n'
                  '🎨 Develop the Stella visual style\n'
                  '📱 Build the Stelluriini application\n'
                  '🪙 Prepare STL token information',
              status: 'IN PROGRESS',
              accent: roadmapPinkColor,
              icon: '🐱',
            ),

            const _RoadmapLine(),

            _RoadmapStep(
              phase: 'PHASE 2',
              title: 'Community',
              description:
                  '🐾 Grow the Stelluriini community\n'
                  '🌍 Improve language support\n'
                  '🎁 Develop rewards and daily activities\n'
                  '💬 Build community features',
              status: 'PLANNED',
              accent: roadmapAccentColor,
              icon: '🐾',
            ),

            const _RoadmapLine(),

            _RoadmapStep(
              phase: 'PHASE 3',
              title: 'STL Ecosystem',
              description:
                  '🪙 Develop the STL ecosystem\n'
                  '🔗 Connect blockchain information\n'
                  '📊 Add token statistics\n'
                  '🚀 Expand Stelluriini features',
              status: 'FUTURE',
              accent: roadmapGoldColor,
              icon: '🪙',
            ),

            const _RoadmapLine(),

            _RoadmapStep(
              phase: 'PHASE 4',
              title: 'The Future',
              description:
                  '🌟 Continue ecosystem development\n'
                  '🐱 Introduce new Stella experiences\n'
                  '🤝 Expand community participation\n'
                  '🚀 Explore new possibilities for STL',
              status: 'FUTURE',
              accent: roadmapPinkColor,
              icon: '🌟',
            ),

            const SizedBox(height: 20),

            // ==================================================
            // STELLA CARD
            // ==================================================

            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: roadmapCardColor,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: roadmapPinkColor.withValues(
                    alpha: 0.20,
                  ),
                ),
              ),
              child: Column(
                children: [
                  const StelluriiniLogo(
                    size: 72,
                  ),

                  const SizedBox(height: 14),

                  const Text(
                    '🐱 Stella is coming along for the journey!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: roadmapPinkColor,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Every phase is another step toward '
                    'the Stelluriini ecosystem.',
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

            const SizedBox(height: 18),

            // ==================================================
            // DEVELOPMENT PRINCIPLES
            // ==================================================

            _RoadmapInfoCard(
              icon: Icons.rocket_launch_rounded,
              title: 'Development Principles',
              accent: roadmapGoldColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  _PrincipleRow(
                    icon: Icons.groups_rounded,
                    title: 'Community',
                    text:
                        'Build together with the Stelluriini community.',
                  ),
                  SizedBox(height: 14),
                  _PrincipleRow(
                    icon: Icons.pets_rounded,
                    title: 'Stella',
                    text:
                        'Keep Stella at the heart of the project identity.',
                  ),
                  SizedBox(height: 14),
                  _PrincipleRow(
                    icon: Icons.auto_awesome_rounded,
                    title: 'Innovation',
                    text:
                        'Explore new applications, games and digital experiences.',
                  ),
                  SizedBox(height: 14),
                  _PrincipleRow(
                    icon: Icons.trending_up_rounded,
                    title: 'Long-Term Growth',
                    text:
                        'Develop the ecosystem gradually and sustainably.',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // ==================================================
            // IMPORTANT NOTICE
            // ==================================================

            Container(
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
                    'Roadmap Notice',
                    style: TextStyle(
                      color: Colors.orangeAccent,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    'The roadmap represents the current planned '
                    'direction of Stelluriini. Dates, features and '
                    'priorities may change as the project develops.',
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
                color: roadmapPinkColor,
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
                color: roadmapGoldColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),
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
  final Color accent;
  final String icon;

  const _RoadmapStep({
    required this.phase,
    required this.title,
    required this.description,
    required this.status,
    required this.accent,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ======================================================
        // STELLA / PAW MARKER
        // ======================================================

        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.12),
            shape: BoxShape.circle,
            border: Border.all(
              color: accent.withValues(alpha: 0.45),
            ),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.08),
                blurRadius: 12,
              ),
            ],
          ),
          child: Center(
            child: Text(
              icon,
              style: const TextStyle(
                fontSize: 25,
              ),
            ),
          ),
        ),

        const SizedBox(width: 14),

        // ======================================================
        // CARD
        // ======================================================

        Expanded(
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: roadmapCardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: accent.withValues(alpha: 0.17),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      phase,
                      style: TextStyle(
                        color: accent,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),

                    const Spacer(),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: accent.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          color: accent,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 9),

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
      decoration: BoxDecoration(
        color: roadmapAccentColor.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

// ============================================================
// INFORMATION CARD
// ============================================================

class _RoadmapInfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color accent;
  final Widget child;

  const _RoadmapInfoCard({
    required this.icon,
    required this.title,
    required this.accent,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: roadmapCardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: accent.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.11),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: accent,
                  size: 24,
                ),
              ),

              const SizedBox(width: 12),

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

          const SizedBox(height: 16),

          child,
        ],
      ),
    );
  }
}

// ============================================================
// PRINCIPLE ROW
// ============================================================

class _PrincipleRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;

  const _PrincipleRow({
    required this.icon,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.check_circle_rounded,
          color: roadmapAccentColor,
          size: 20,
        ),

        const SizedBox(width: 10),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 3),

              Text(
                text,
                style: const TextStyle(
                  color: Colors.white60,
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
}