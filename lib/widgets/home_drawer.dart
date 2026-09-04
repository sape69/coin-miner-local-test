import 'package:flutter/material.dart';

import 'cat_avatar.dart';

// ============================================================
// 🐱 STELLA THEME COLORS
// ============================================================

const Color backgroundColor = Color(0xFF120B24);
const Color cardColor = Color(0xFF21113B);
const Color accentColor = Color(0xFFB58CFF);
const Color pinkAccentColor = Color(0xFFFFB7E8);
const Color goldAccentColor = Color(0xFFFFD166);

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
  // 🐾 MENU ITEM
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
          child: Container(
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
                    gradient: LinearGradient(
                      colors: [
                        accentColor.withValues(alpha: 0.28),
                        pinkAccentColor.withValues(alpha: 0.16),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(
                      color: accentColor.withValues(alpha: 0.20),
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: pinkAccentColor,
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
                      color: goldAccentColor.withValues(
                        alpha: 0.15,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      badge,
                      style: const TextStyle(
                        color: goldAccentColor,
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
                    alpha: 0.30,
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
                  color: accentColor.withValues(
                    alpha: 0.45,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withValues(
                      alpha: 0.14,
                    ),
                    blurRadius: 24,
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
                       