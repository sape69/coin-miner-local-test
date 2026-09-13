import 'package:flutter/material.dart';

// ============================================================
// ⛏️ STELLURIINI MINING PROGRESS CARD
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

  static const Color mutedTextColor =
      Color(0xFF9F8CB8);

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
    if (!miningActive ||
        miningDurationMs <= 0) {
      return 0.0;
    }

    final double progress =
        1.0 -
        (miningRemainingMs /
            miningDurationMs);

    return progress
        .clamp(
          0.0,
          1.0,
        )
        .toDouble();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final double progress =
        _calculateProgress();

    final String progressText =
        '${(progress * 100).toStringAsFixed(1)}%';

    return Container(
      padding:
          const EdgeInsets.all(20),
      decoration:
          BoxDecoration(
        color:
            cardColor,
        borderRadius:
            BorderRadius.circular(22),
        border:
            Border.all(
          color:
              accentColor.withValues(
            alpha: 0.10,
          ),
        ),
      ),
      child:
          Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          // ====================================================
          // HEADER
          // ====================================================

          Row(
            children: [
              Expanded(
                child:
                    Text(
                  title,
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
              ),

              const SizedBox(
                width: 10,
              ),

              Text(
                progressText,
                style:
                    const TextStyle(
                  color:
                      goldColor,
                  fontSize:
                      13,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 14,
          ),

          // ====================================================
          // MINING PROGRESS
          // ====================================================

          ClipRRect(
            borderRadius:
                BorderRadius.circular(
              20,
            ),
            child:
                LinearProgressIndicator(
              value:
                  progress,
              minHeight:
                  12,
              backgroundColor:
                  backgroundColor,
              valueColor:
                  const AlwaysStoppedAnimation<
                      Color>(
                accentColor,
              ),
            ),
          ),

          const SizedBox(
            height: 12,
          ),

          // ====================================================
          // STL PER HOUR
          // ====================================================

          Text(
            stlPerHourText,
            style:
                const TextStyle(
              color:
                  secondaryTextColor,
              fontSize:
                  13,
              fontWeight:
                  FontWeight.w500,
            ),
          ),

          const SizedBox(
            height: 12,
          ),

          // ====================================================
          // DAILY HASH RATE
          // ====================================================

          Container(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            decoration:
                BoxDecoration(
              color:
                  backgroundColor.withValues(
                alpha: 0.45,
              ),
              borderRadius:
                  BorderRadius.circular(
                14,
              ),
              border:
                  Border.all(
                color:
                    pinkColor.withValues(
                  alpha: 0.08,
                ),
              ),
            ),
            child:
                Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      '🎁',
                      style:
                          TextStyle(
                        fontSize:
                            15,
                      ),
                    ),

                    const SizedBox(
                      width: 7,
                    ),

                    Expanded(
                      child:
                          Text(
                        dailyHashRateText,
                        style:
                            const TextStyle(
                          color:
                              pinkColor,
                          fontSize:
                              12,
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height: 5,
                ),

                Text(
                  dailyHashRateDayText,
                  style:
                      const TextStyle(
                    color:
                        mutedTextColor,
                    fontSize:
                        11,
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