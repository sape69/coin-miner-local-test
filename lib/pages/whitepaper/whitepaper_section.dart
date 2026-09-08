import 'package:flutter/material.dart';

const Color whitePaperBackgroundColor = Color(0xFF120B24);
const Color whitePaperCardColor = Color(0xFF21113B);
const Color whitePaperAccentColor = Color(0xFFB58CFF);
const Color whitePaperPinkColor = Color(0xFFFFB7E8);
const Color whitePaperGoldColor = Color(0xFFFFD166);

class WhitePaperSection extends StatelessWidget {
  final String number;
  final IconData icon;
  final String title;
  final Widget child;
  final Color accent;

  const WhitePaperSection({
    super.key,
    required this.number,
    required this.icon,
    required this.title,
    required this.child,
    this.accent = whitePaperAccentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(
        bottom: 18,
      ),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: whitePaperCardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: accent.withValues(
            alpha: 0.18,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accent.withValues(
                    alpha: 0.11,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: accent.withValues(
                      alpha: 0.15,
                    ),
                  ),
                ),
                child: Icon(
                  icon,
                  color: accent,
                  size: 23,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      number,
                      style: TextStyle(
                        color: accent,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}