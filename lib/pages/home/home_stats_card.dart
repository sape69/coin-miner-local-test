import 'package:flutter/material.dart';

// ============================================================
// 📊 STELLURIINI HOME STATS CARD
// ============================================================

class HomeStatsCard extends StatelessWidget {
  final String hashRateTitle;
  final String hashRateValue;
  final String totalStlTitle;
  final String totalStlValue;

  // ============================================================
  // 🎨 STELLA COLORS
  // ============================================================

  static const Color backgroundColor =
      Color(0xFF120B24);

  static const Color cardColor =
      Color(0xFF21113B);

  static const Color accentColor =
      Color(0xFFB58CFF);

  static const Color pinkColor =
      Color(0xFFFFB7E8);

  static const Color goldColor =
      Color(0xFFFFD166);

  static const Color secondaryTextColor =
      Color(0xFFBFAEDB);

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
    return Row(
      children: [
        // ======================================================
        // ⚡ HASH RATE
        // ======================================================

        Expanded(
          child:
              _buildStatCard(
            icon:
                Icons.bolt_rounded,
            iconColor:
                goldColor,
            title:
                hashRateTitle,
            value:
                hashRateValue,
          ),
        ),

        const SizedBox(
          width: 12,
        ),

        // ======================================================
        // 💰 STL
        // ======================================================

        Expanded(
          child:
              _buildStatCard(
            icon:
                Icons.currency_bitcoin_rounded,
            iconColor:
                pinkColor,
            title:
                totalStlTitle,
            value:
                totalStlValue,
          ),
        ),
      ],
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
  }) {
    return Container(
      padding:
          const EdgeInsets.all(16),
      decoration:
          BoxDecoration(
        color:
            cardColor,
        borderRadius:
            BorderRadius.circular(20),
        border:
            Border.all(
          color:
              accentColor.withValues(
            alpha: 0.08,
          ),
        ),
      ),
      child:
          Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          // ----------------------------------------------------
          // ICON
          // ----------------------------------------------------

          Container(
            width:
                38,
            height:
                38,
            decoration:
                BoxDecoration(
              color:
                  iconColor.withValues(
                alpha: 0.10,
              ),
              borderRadius:
                  BorderRadius.circular(
                12,
              ),
            ),
            child:
                Icon(
              icon,
              color:
                  iconColor,
              size:
                  21,
            ),
          ),

          const SizedBox(
            height: 12,
          ),

          // ----------------------------------------------------
          // TITLE
          // ----------------------------------------------------

          Text(
            title,
            maxLines:
                1,
            overflow:
                TextOverflow.ellipsis,
            style:
                const TextStyle(
              color:
                  secondaryTextColor,
              fontSize:
                  10,
              letterSpacing:
                  1,
              fontWeight:
                  FontWeight.w500,
            ),
          ),

          const SizedBox(
            height: 5,
          ),

          // ----------------------------------------------------
          // VALUE
          // ----------------------------------------------------

          Text(
            value,
            maxLines:
                1,
            overflow:
                TextOverflow.ellipsis,
            style:
                const TextStyle(
              color:
                  Colors.white,
              fontSize:
                  15,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}