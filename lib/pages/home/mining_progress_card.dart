import 'package:flutter/material.dart';

// ============================================================
// ⛏️ STELLURIINI MINING PROGRESS CARD
// ============================================================
//
// Responsive mining progress card.
//
// IMPORTANT:
// - Keeps the existing constructor API.
// - Uses localized text supplied by the parent widget.
// - Does not change Firebase or mining calculations.
// ============================================================

class MiningProgressCard extends StatelessWidget {
  final bool miningActive;
  final int miningRemainingMs;
  final int miningDurationMs;

  final String title;
  final String stlPerHourText;
  final String dailyHashRateText;
  final String dailyHashRateDayText;

  // ============================================================
  // 🎨 STELLA COLORS
  // ============================================================

  static const Color backgroundColor = Color(0xFF120B24);
  static const Color cardColor = Color(0xFF21113B);
  static const Color accentColor = Color(0xFFB58CFF);
  static const Color pinkColor = Color(0xFFFFB7E8);
  static const Color goldColor = Color(0xFFFFD166);
  static const Color secondaryTextColor = Color(0xFFBFAEDB);
  static const Color mutedTextColor = Color(0xFF9F8CB8);

  // ============================================================
  // CONSTRUCTOR
  // ============================================================

  const MiningProgressCard({
    super.key,
    required this.miningActive,
    required this.miningRemainingMs,
    required this.miningDurationMs,
    required this.title,
    required this.stlPerHourText,
    required this.dailyHashRateText,
    required this.dailyHashRateDayText,
  });

  // ============================================================
  // PROGRESS
  // ============================================================

  double _calculateProgress() {
    if (!miningActive || miningDurationMs <= 0) {
      return 0.0;
    }

    final double progress =
        1.0 - (miningRemainingMs / miningDurationMs);

    return progress.clamp(0.0, 1.0).toDouble();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final double progress = _calculateProgress();

    final String progressText =
        '${(progress * 100).toStringAsFixed(1)}%';

    final Color progressColor =
        miningActive ? accentColor : mutedTextColor;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double padding =
            constraints.maxWidth < 340 ? 14 : 20;

        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: accentColor.withValues(alpha: 0.14),
            ),
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: 0.04),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER

              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      miningActive
                          ? Icons.auto_awesome_rounded
                          : Icons.nightlight_round,
                      color: progressColor,
                      size: 21,
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        height: 1.25,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    progressText,
                    style: const TextStyle(
                      color: goldColor,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // MINING PROGRESS

              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 12,
                  backgroundColor: backgroundColor,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    progressColor,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // STL PER HOUR

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: backgroundColor.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.bolt_rounded,
                      color: goldColor,
                      size: 20,
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        stlPerHourText,
                        style: const TextStyle(
                          color: secondaryTextColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // DAILY HASH RATE BONUS

              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: backgroundColor.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: pinkColor.withValues(alpha: 0.12),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '🎁',
                          style: TextStyle(fontSize: 15),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            dailyHashRateText,
                            style: const TextStyle(
                              color: pinkColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.only(left: 23),
                      child: Text(
                        dailyHashRateDayText,
                        style: const TextStyle(
                          color: mutedTextColor,
                          fontSize: 11,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}