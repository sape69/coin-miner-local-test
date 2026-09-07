import 'package:flutter/material.dart';

class MiningProgressCard extends StatelessWidget {
  final bool miningActive;
  final int miningRemainingMs;
  final int miningDurationMs;

  final String title;
  final String stlPerHourText;
  final String dailyHashRateText;
  final String dailyHashRateDayText;
  final String hashRateBonusText;
  final String effectiveHashRateText;

  static const Color backgroundColor = Color(0xFF120B24);
  static const Color cardColor = Color(0xFF21113B);
  static const Color accentColor = Color(0xFFB58CFF);
  static const Color pinkColor = Color(0xFFFFB7E8);
  static const Color goldColor = Color(0xFFFFD166);
  static const Color secondaryTextColor = Color(0xFFBFAEDB);

  const MiningProgressCard({
    super.key,
    required this.miningActive,
    required this.miningRemainingMs,
    required this.miningDurationMs,
    required this.title,
    required this.stlPerHourText,
    required this.dailyHashRateText,
    required this.dailyHashRateDayText,
    required this.hashRateBonusText,
    required this.effectiveHashRateText,
  });

  @override
  Widget build(BuildContext context) {
    double progress = 0.0;

    if (miningActive && miningDurationMs > 0) {
      progress =
          1.0 -
          (miningRemainingMs / miningDurationMs);

      progress = progress
          .clamp(
            0.0,
            1.0,
          )
          .toDouble();
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: accentColor.withValues(
            alpha: 0.10,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                '${(progress * 100).toStringAsFixed(1)}%',
                style: const TextStyle(
                  color: goldColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 12,
              backgroundColor: backgroundColor,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(
                accentColor,
              ),
            ),
          ),

          const SizedBox(height: 12),

          Text(
            stlPerHourText,
            style: const TextStyle(
              color: secondaryTextColor,
            ),
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              const Text(
                '🎁',
                style: TextStyle(
                  fontSize: 14,
                ),
              ),

              const SizedBox(width: 6),

              Expanded(
                child: Text(
                  dailyHashRateText,
                  style: const TextStyle(
                    color: pinkColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 5),

          Text(
            dailyHashRateDayText,
            style: const TextStyle(
              color: Color(0xFF9F8CB8),
              fontSize: 11,
            ),
          ),

          if (hashRateBonusText.isNotEmpty) ...[
            const SizedBox(height: 8),

            Text(
              hashRateBonusText,
              style: const TextStyle(
                color: goldColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              effectiveHashRateText,
              style: const TextStyle(
                color: goldColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }
}