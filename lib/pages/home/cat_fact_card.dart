import 'package:flutter/material.dart';

const Color backgroundColor = Color(0xFF0B1112);
const Color cardColor = Color(0xFF151B1C);
const Color catFactAccentColor = Color(0xFF35D0A0);

class CatFactCard extends StatelessWidget {
  final String title;
  final String fact;

  const CatFactCard({
    super.key,
    required this.title,
    required this.fact,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: catFactAccentColor.withValues(
            alpha: 0.20,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.20,
            ),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // ================================================
          // HEADER
          // ================================================

          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: catFactAccentColor.withValues(
                    alpha: 0.15,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Text(
                    '🐱',
                    style: TextStyle(
                      fontSize: 30,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const Text(
                '🐾',
                style: TextStyle(
                  fontSize: 25,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ================================================
          // FACT BUBBLE
          // ================================================

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.black.withValues(
                alpha: 0.20,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: catFactAccentColor.withValues(
                  alpha: 0.12,
                ),
              ),
            ),
            child: Column(
              children: [
                const Text(
                  '💬',
                  style: TextStyle(
                    fontSize: 30,
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  fact,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    color: Colors.white.withValues(
                      alpha: 0.80,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ================================================
          // STELLA FOOTER
          // ================================================

          Row(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              const Text(
                '🐾',
                style: TextStyle(
                  fontSize: 18,
                ),
              ),

              const SizedBox(width: 8),

              Text(
                'A little fact from Stella 🐱',
                style: TextStyle(
                  color: catFactAccentColor.withValues(
                    alpha: 0.80,
                  ),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(width: 8),

              const Text(
                '🐾',
                style: TextStyle(
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}