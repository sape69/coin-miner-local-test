import 'package:flutter/material.dart';

import '../../widgets/cat_avatar.dart';

// ============================================================
// COLORS
// ============================================================

const Color backgroundColor = Color(0xFF0B1112);
const Color cardColor = Color(0xFF151B1C);
const Color accentColor = Color(0xFF35D0A0);

// ============================================================
// HOME DRAWER
// ============================================================

class HomeDrawer extends StatelessWidget {
  final VoidCallback onLanguagePressed;
  final VoidCallback onAboutPressed;
  final VoidCallback onWhitePaperPressed;
  final VoidCallback onTokenPressed;
  final VoidCallback onTokenomicsPressed;
  final VoidCallback onRoadmapPressed;

  const HomeDrawer({
    super.key,
    required this.onLanguagePressed,
    required this.onAboutPressed,
    required this.onWhitePaperPressed,
    required this.onTokenPressed,
    required this.onTokenomicsPressed,
    required this.onRoadmapPressed,
  });

  // ==========================================================
  // MENU ITEM
  // ==========================================================

  Widget _menuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    String? badge,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 4,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 13,
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(
                    icon,
                    color: accentColor,
                    size: 23,
                  ),
                ),

                const SizedBox(width: 14),

                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(
                        alpha: 0.12,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      badge,
                      style: const TextStyle(
                        color: accentColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),

                const SizedBox(width: 4),

                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white.withValues(
                    alpha: 0.25,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: backgroundColor,

      child: SafeArea(
        child: Column(
          children: [
            // ==================================================
            // STELLA HEADER
            // ==================================================

            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 22,
              ),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(24),
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
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(
                        Icons.pets,
                        color: accentColor.withValues(
                          alpha: 0.35,
                        ),
                        size: 25,
                      ),
                      Icon(
                        Icons.pets,
                        color: accentColor.withValues(
                          alpha: 0.35,
                        ),
                        size: 25,
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: accentColor,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: accentColor.withValues(
                            alpha: 0.25,
                          ),
                          blurRadius: 18,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const CatAvatar(
                      size: 100,
                    ),
                  ),

                  const SizedBox(height: 14),

                  const Text(
                    'STELLURIINI',
                    style: TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.5,
                      color: accentColor,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(
                        alpha: 0.10,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      '🐾 STL • SOLANA 🐾',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ==================================================
            // MENU
            // ==================================================

            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(
                  top: 4,
                  bottom: 8,
                ),
                children: [
                  // ==============================================
                  // HOME
                  // ==============================================

                  _menuItem(
                    icon: Icons.home_outlined,
                    title: 'Home',
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),

                  // ==============================================
                  // ABOUT
                  // ==============================================

                  _menuItem(
                    icon: Icons.pets_outlined,
                    title: 'About Stelluriini',
                    onTap: () {
                      Navigator.pop(context);
                      onAboutPressed();
                    },
                  ),

                  // ==============================================
                  // STL TOKEN
                  // ==============================================

                  _menuItem(
                    icon: Icons.monetization_on_outlined,
                    title: 'STL Token',
                    onTap: () {
                      Navigator.pop(context);
                      onTokenPressed();
                    },
                  ),

                  // ==============================================
                  // TOKENOMICS
                  // ==============================================

                  _menuItem(
                    icon: Icons.pie_chart_outline_rounded,
                    title: 'Tokenomics',
                    badge: 'NEW',
                    onTap: () {
                      Navigator.pop(context);
                      onTokenomicsPressed();
                    },
                  ),

                  // ==============================================
                  // WHITE PAPER
                  // ==============================================

                  _menuItem(
                    icon: Icons.description_outlined,
                    title: 'White Paper',
                    onTap: () {
                      Navigator.pop(context);
                      onWhitePaperPressed();
                    },
                  ),

                  // ==============================================
                  // ROADMAP
                  // ==============================================

                  _menuItem(
                    icon: Icons.map_outlined,
                    title: 'Roadmap',
                    onTap: () {
                      Navigator.pop(context);
                      onRoadmapPressed();
                    },
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 26,
                      vertical: 12,
                    ),
                    child: Divider(
                      color: Colors.white24,
                    ),
                  ),

                  // ==============================================
                  // LANGUAGE
                  // ==============================================

                  _menuItem(
                    icon: Icons.language,
                    title: 'Language',
                    onTap: () {
                      Navigator.pop(context);
                      onLanguagePressed();
                    },
                  ),
                ],
              ),
            ),

            // ==================================================
            // FOOTER
            // ==================================================

            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: accentColor.withValues(alpha: 0.12),
                ),
              ),
              child: Column(
                children: [
                  const Text(
                    '🐾 STELLURIINI • STL 🐾',
                    style: TextStyle(
                      color: accentColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    '17 602 539 062 STL',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    'Community-driven • Solana',
                    style: TextStyle(
                      color: Colors.white.withValues(
                        alpha: 0.38,
                      ),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}