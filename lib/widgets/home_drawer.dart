import 'package:flutter/material.dart';

import 'cat_avatar.dart';

// ============================================================
// 🐱 STELLA COLORS
// ============================================================

const Color backgroundColor = Color(0xFF120B24);
const Color cardColor = Color(0xFF21113B);

const Color stellaPurple = Color(0xFFB58CFF);
const Color stellaPink = Color(0xFFFFB7E8);
const Color stellaGold = Color(0xFFFFD166);
const Color stellaTextSoft = Color(0xFFBFAEDB);

// ============================================================
// 🐱 HOME DRAWER
// ============================================================

class HomeDrawer extends StatelessWidget {
  final VoidCallback onLanguagePressed;
  final VoidCallback onAboutPressed;
  final VoidCallback onWhitePaperPressed;
  final VoidCallback onTokenPressed;
  final VoidCallback onTokenomicsPressed;
  final VoidCallback onRoadmapPressed;
  final VoidCallback onTransactionHistoryPressed;

  const HomeDrawer({
    super.key,
    required this.onLanguagePressed,
    required this.onAboutPressed,
    required this.onWhitePaperPressed,
    required this.onTokenPressed,
    required this.onTokenomicsPressed,
    required this.onRoadmapPressed,
    required this.onTransactionHistoryPressed,
  });

  // ==========================================================
  // 🐱 MENU ITEM
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
          splashColor: stellaPurple.withValues(
            alpha: 0.12,
          ),
          highlightColor: stellaPink.withValues(
            alpha: 0.05,
          ),
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(
                  alpha: 0.035,
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 13,
              ),
              child: Row(
                children: [
                  // ============================================
                  // ICON
                  // ============================================

                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          stellaPurple.withValues(
                            alpha: 0.22,
                          ),
                          stellaPink.withValues(
                            alpha: 0.12,
                          ),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(
                        color: stellaPurple.withValues(
                          alpha: 0.16,
                        ),
                      ),
                    ),
                    child: Icon(
                      icon,
                      color: stellaPink,
                      size: 23,
                    ),
                  ),

                  const SizedBox(width: 14),

                  // ============================================
                  // TITLE
                  // ============================================

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

                  // ============================================
                  // BADGE
                  // ============================================

                  if (badge != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: stellaGold.withValues(
                          alpha: 0.15,
                        ),
                        borderRadius: BorderRadius.circular(
                          20,
                        ),
                        border: Border.all(
                          color: stellaGold.withValues(
                            alpha: 0.25,
                          ),
                        ),
                      ),
                      child: Text(
                        badge,
                        style: const TextStyle(
                          color: stellaGold,
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
      ),
    );
  }

  // ==========================================================
  // 🐱 BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: backgroundColor,
      child: SafeArea(
        child: Column(
          children: [
            // ==================================================
            // 🐱 STELLA HEADER
            // ==================================================

            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 22,
              ),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF2D174D),
                    Color(0xFF1B1033),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: stellaPurple.withValues(
                    alpha: 0.45,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: stellaPurple.withValues(
                      alpha: 0.14,
                    ),
                    blurRadius: 25,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                children: [
                  // ============================================
                  // PAWS
                  // ============================================

                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(
                        Icons.pets,
                        color: stellaPink.withValues(
                          alpha: 0.40,
                        ),
                        size: 25,
                      ),
                      Icon(
                        Icons.pets,
                        color: stellaPink.withValues(
                          alpha: 0.40,
                        ),
                        size: 25,
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // ============================================
                  // CAT AVATAR
                  // ============================================

                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: stellaPink,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: stellaPurple.withValues(
                            alpha: 0.30,
                          ),
                          blurRadius: 22,
                          spreadRadius: 3,
                        ),
                      ],
                    ),
                    child: const CatAvatar(
                      size: 100,
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ============================================
                  // TITLE
                  // ============================================

                  const Text(
                    'STELLURIINI',
                    style: TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.5,
                      color: stellaPink,
                    ),
                  ),

                  const SizedBox(height: 6),

                  const Text(
                    '🐱 Stella Mining the Future ✨',
                    style: TextStyle(
                      color: stellaTextSoft,
                      fontSize: 12,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ============================================
                  // TOKEN BADGE
                  // ============================================

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: stellaPurple.withValues(
                        alpha: 0.15,
                      ),
                      borderRadius: BorderRadius.circular(
                        20,
                      ),
                      border: Border.all(
                        color: stellaPurple.withValues(
                          alpha: 0.28,
                        ),
                      ),
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
            // 🐱 MENU
            // ==================================================

            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(
                  top: 4,
                  bottom: 8,
                ),
                children: [
                  _menuItem(
                    icon: Icons.home_rounded,
                    title: 'Home',
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),

                  // ============================================
                  // TRANSACTION HISTORY
                  // ============================================

                  _menuItem(
                    icon: Icons.history_rounded,
                    title: 'Transaction History',
                    onTap: () {
                      Navigator.pop(context);
                      onTransactionHistoryPressed();
                    },
                  ),

                  // ============================================
                  // ABOUT
                  // ============================================

                  _menuItem(
                    icon: Icons.pets_outlined,
                    title: 'About Stelluriini',
                    onTap: () {
                      Navigator.pop(context);
                      onAboutPressed();
                    },
                  ),

                  // ============================================
                  // TOKEN
                  // ============================================

                  _menuItem(
                    icon: Icons.monetization_on_outlined,
                    title: 'STL Token',
                    onTap: () {
                      Navigator.pop(context);
                      onTokenPressed();
                    },
                  ),

                  // ============================================
                  // TOKENOMICS
                  // ============================================

                  _menuItem(
                    icon: Icons.pie_chart_outline_rounded,
                    title: 'Tokenomics',
                    onTap: () {
                      Navigator.pop(context);
                      onTokenomicsPressed();
                    },
                  ),

                  // ============================================
                  // WHITE PAPER
                  // ============================================

                  _menuItem(
                    icon: Icons.description_outlined,
                    title: 'White Paper',
                    onTap: () {
                      Navigator.pop(context);
                      onWhitePaperPressed();
                    },
                  ),

                  // ============================================
                  // ROADMAP
                  // ============================================

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
                      color: Color(0x335F4D70),
                    ),
                  ),

                  // ============================================
                  // LANGUAGE
                  // ============================================

                  _menuItem(
                    icon: Icons.language_rounded,
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
            // 🐱 STELLA FOOTER
            // ==================================================

            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: stellaPurple.withValues(
                    alpha: 0.20,
                  ),
                ),
              ),
              child: Column(
                children: [
                  const Text(
                    '🐱 STELLURIINI • STL 🐾',
                    style: TextStyle(
                      color: stellaPink,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    '17 602 539 062 STL',
                    style: TextStyle(
                      color: Colors.white.withValues(
                        alpha: 0.78,
                      ),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 5),

                  const Text(
                    '🐾 Community-driven • Solana 🐾',
                    style: TextStyle(
                      color: Color(0xFF8D7BA8),
                      fontSize: 11,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Stella is mining the future. ✨',
                    style: TextStyle(
                      color: Colors.white.withValues(
                        alpha: 0.32,
                      ),
                      fontSize: 10,
                      fontStyle: FontStyle.italic,
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