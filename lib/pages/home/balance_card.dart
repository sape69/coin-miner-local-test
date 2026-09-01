import 'package:flutter/material.dart';

const Color backgroundColor = Color(0xFF0B1112);
const Color cardColor = Color(0xFF151B1C);
const Color balanceAccentColor = Color(0xFF35D0A0);

class BalanceCard extends StatelessWidget {
  final int stl;
  final String title;
  final String subtitle;

  const BalanceCard({
    super.key,
    required this.stl,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
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
          // ================================================
          // HEADER
          // ================================================

          Row(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              const Text(
                '🐱',
                style: TextStyle(
                  fontSize: 28,
                ),
              ),

              const SizedBox(width: 10),

              Text(
                title.toUpperCase(),
                style: TextStyle(
                  color: Colors.white.withValues(
                    alpha: 0.70,
                  ),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),

              const SizedBox(width: 10),

              const Text(
                '🐾',
                style: TextStyle(
                  fontSize: 24,
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),

          // ================================================
          // BALANCE ICON
          // ================================================

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
              child: Text(
                '🐾',
                style: TextStyle(
                  fontSize: 42,
                ),
              ),
            ),
          ),

          const SizedBox(height: 18),

          // ================================================
          // STL BALANCE
          // ================================================

          Text(
            '$stl',
            style: const TextStyle(
              fontSize: 58,
              height: 1,
              fontWeight: FontWeight.bold,
              color: balanceAccentColor,
              letterSpacing: 1,
            ),
          ),

          const SizedBox(height: 8),

          // ================================================
          // STL LABEL
          // ================================================

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

          // ================================================
          // DIVIDER
          // ================================================

          Container(
            width: double.infinity,
            height: 1,
            color: Colors.white.withValues(
              alpha: 0.08,
            ),
          ),

          const SizedBox(height: 16),

          // ================================================
          // SUBTITLE
          // ================================================

          Row(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.info_outline,
                color: Colors.white54,
                size: 17,
              ),

              const SizedBox(width: 7),

              Flexible(
                child: Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(
                      alpha: 0.55,
                    ),
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Text(
            'Stella is collecting her treasures 🐱✨',
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