import 'package:flutter/material.dart';

// ============================================================
// 📊 STELLURIINI HOME STATS CARD
// ============================================================
//
// Responsive statistics cards for the Stelluriini HomePage.
//
// IMPORTANT:
// - Keeps the existing constructor API.
// - Does not change mining or Firebase logic.
// - Designed for narrow Android screens.
// ============================================================

class HomeStatsCard extends StatelessWidget {
  final String hashRateTitle;
  final String hashRateValue;
  final String totalStlTitle;
  final String totalStlValue;

  // ============================================================
  // 🎨 STELLA COLORS
  // ============================================================

  static const Color backgroundColor = Color(0xFF120B24);
  static const Color cardColor = Color(0xFF21113B);
  static const Color accentColor = Color(0xFFB58CFF);
  static const Color pinkColor = Color(0xFFFFB7E8);
  static const Color goldColor = Color(0xFFFFD166);
  static const Color secondaryTextColor = Color(0xFFBFAEDB);

  // ============================================================
  // CONSTRUCTOR
  // ============================================================

  const HomeStatsCard({
    super.key,
    required this.hashRateTitle,
    required this.hashRateValue,
    required this.totalStlTitle,
    required this.totalStlValue,
  });

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double cardSpacing =
            constraints.maxWidth < 340 ? 8 : 12;

        final double cardPadding =
            constraints.maxWidth < 340 ? 12 : 16;

        return Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.bolt_rounded,
                iconColor: goldColor,
                title: hashRateTitle,
                value: hashRateValue,
                padding: cardPadding,
              ),
            ),
            SizedBox(width: cardSpacing),
            Expanded(
              child: _buildStatCard(
                icon: Icons.pets_rounded,
                iconColor: pinkColor,
                title: totalStlTitle,
                value: totalStlValue,
                padding: cardPadding,
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // 📊 STAT CARD
  // ============================================================

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required double padding,
  }) {
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ICON

          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 21,
            ),
          ),

          const SizedBox(height: 12),

          // TITLE

          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: secondaryTextColor,
              fontSize: 10,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),

          const SizedBox(height: 6),

          // VALUE

          SizedBox(
            width: double.infinity,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                maxLines: 1,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),

          const SizedBox(height: 2),

          // SUBTLE ACCENT

          Container(
            width: 32,
            height: 3,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ],
      ),
    );
  }
}