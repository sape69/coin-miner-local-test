import 'package:flutter/material.dart';

// ============================================================
// 🐱 STELLURIINI COLORS
// ============================================================

const Color informationCardColor = Color(0xFF21113B);
const Color informationAccentColor = Color(0xFFB58CFF);
const Color informationPinkColor = Color(0xFFFFB7E8);

// ============================================================
// 🐱 STELLA INFORMATION CARD
// ============================================================

class InformationCard extends StatelessWidget {
  final String title;
  final String solanaTokenText;
  final String companyText;

  const InformationCard({
    super.key,
    required this.title,
    required this.solanaTokenText,
    required this.companyText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: informationCardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: informationAccentColor.withValues(
            alpha: 0.28,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: informationAccentColor.withValues(
              alpha: 0.08,
            ),
            blurRadius: 20,
            spreadRadius: 1,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // ==================================================
          // 🐱 ICON
          // ==================================================

          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: informationAccentColor.withValues(
                alpha: 0.14,
              ),
              border: Border.all(
                color: informationPinkColor.withValues(
                  alpha: 0.30,
                ),
              ),
            ),
            child: const Center(
              child: Icon(
                Icons.info_outline,
                size: 34,
                color: informationAccentColor,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ==================================================
          // TITLE
          // ==================================================

          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 19,
              letterSpacing: 0.4,
            ),
          ),

          const SizedBox(height: 14),

          // ==================================================
          // SOLANA TOKEN INFORMATION
          // ==================================================

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withValues(
                alpha: 0.18,
              ),
              borderRadius: BorderRadius.circular(17),
              border: Border.all(
                color: informationAccentColor.withValues(
                  alpha: 0.12,
                ),
              ),
            ),
            child: Column(
              children: [
                const Text(
                  '🐱💜 SOLANA',
                  style: TextStyle(
                    color: informationPinkColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    letterSpacing: 1,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  solanaTokenText,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(
                      alpha: 0.78,
                    ),
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ==================================================
          // STELLURIINI INFORMATION
          // ==================================================

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: informationPinkColor.withValues(
                alpha: 0.04,
              ),
              borderRadius: BorderRadius.circular(17),
              border: Border.all(
                color: informationPinkColor.withValues(
                  alpha: 0.08,
                ),
              ),
            ),
            child: Column(
              children: [
                const Text(
                  '🐾 STELLURIINI • STL',
                  style: TextStyle(
                    color: informationAccentColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    letterSpacing: 1,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  companyText,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(
                      alpha: 0.62,
                    ),
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}