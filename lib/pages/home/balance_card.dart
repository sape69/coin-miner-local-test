import 'package:flutter/material.dart';

// ============================================================
// COLORS
// ============================================================

const Color cardColor = Color(0xFF151B1C);
const Color balanceAccentColor = Color(0xFF35D0A0);

// ============================================================
// BALANCE CARD
// ============================================================

class BalanceCard extends StatelessWidget {
  final double stl;
  final String title;
  final String subtitle;

  const BalanceCard({
    super.key,
    required this.stl,
    required this.title,
    required this.subtitle,
  });

  // ==========================================================
  // FORMAT BALANCE
  // ==========================================================

  String _formatBalance() {
    if (stl >= 1000000) {
      return stl.toStringAsFixed(0);
    }

    if (stl >= 1000) {
      return stl.toStringAsFixed(2);
    }

    return stl.toStringAsFixed(4);
  }

  @override
  Widget build(BuildContext context) {
    final balanceText = _formatBalance();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: balanceAccentColor.withValues(
            alpha: 0.25,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: balanceAccentColor.withValues(
              alpha: 0.08,
            ),
            blurRadius: 24,
            spreadRadius: 1,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // ==================================================
          // HEADER
          // ==================================================

          Row(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              const Text(
                '⛏️',
                style: TextStyle(
                  fontSize: 26,
                ),
              ),

              const SizedBox(width: 10),

              Flexible(
                child: Text(
                  title.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(
                      alpha: 0.70,
                    ),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ),

              const SizedBox(width: 10),

              const Text(
                '🐱',
                style: TextStyle(
                  fontSize: 26,
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),

          // ==================================================
          // MINING ICON
          // ==================================================

          Container(
            width: 86,
            height: 86,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: balanceAccentColor.withValues(
                alpha: 0.15,
              ),
              border: Border.all(
                color: balanceAccentColor.withValues(
                  alpha: 0.40,
                ),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: balanceAccentColor.withValues(
                    alpha: 0.20,
                  ),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.precision_manufacturing,
                color: balanceAccentColor,
                size: 42,
              ),
            ),
          ),

          const SizedBox(height: 18),

          // ==================================================
          // MINING BALANCE
          // ==================================================

          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              balanceText,
              style: const TextStyle(
                fontSize: 52,
                height: 1,
                fontWeight: FontWeight.bold,
                color: balanceAccentColor,
                letterSpacing: 1,
              ),
            ),
          ),

          const SizedBox(height: 10),

          // ==================================================
          // STL LABEL
          // ==================================================

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: balanceAccentColor.withValues(
                alpha: 0.14,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: balanceAccentColor.withValues(
                  alpha: 0.25,
                ),
              ),
            ),
            child: const Text(
              'STL',
              style: TextStyle(
                color: balanceAccentColor,
                fontSize: 17,
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
              ),
            ),
          ),

          const SizedBox(height: 18),

          // ==================================================
          // DIVIDER
          // ==================================================

          Container(
            width: double.infinity,
            height: 1,
            color: Colors.white.withValues(
              alpha: 0.08,
            ),
          ),

          const SizedBox(height: 16),

          // ==================================================
          // MINING INFO
          // ==================================================

          Row(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.bolt,
                color: balanceAccentColor,
                size: 18,
              ),

              const SizedBox(width: 7),

              Flexible(
                child: Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(
                      alpha: 0.65,
                    ),
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // ==================================================
          // STELLA MESSAGE
          // ==================================================

          Text(
            'Stella is mining treasures 🐱⛏️✨',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: balanceAccentColor.withValues(
                alpha: 0.75,
              ),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}