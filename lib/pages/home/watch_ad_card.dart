import 'package:flutter/material.dart';

// ============================================================
// STELLA THEME
// ============================================================

const Color backgroundColor = Color(0xFF120B24);
const Color cardColor = Color(0xFF21113B);

const Color watchAdAccentColor = Color(0xFFB58CFF);
const Color watchAdPinkColor = Color(0xFFFFB7E8);
const Color watchAdGoldColor = Color(0xFFFFD166);

// ============================================================
// WATCH AD CARD
// ============================================================

class WatchAdCard extends StatelessWidget {
  // ==========================================================
  // AD / BOOST CONSTANTS
  // ==========================================================

  static const double adHashRateBonus = 0.5833;
  static const int adBoostDurationHours = 4;

  // ==========================================================
  // REQUIRED DATA
  // ==========================================================

  final String title;
  final String dailyLimitText;

  final int adsToday;
  final int maxAdsPerDay;

  final bool canWatch;
  final String nextAdText;

  final bool adLoading;
  final bool adReady;

  final String loadingText;
  final String limitReachedText;
  final String unavailableText;
  final String watchButtonText;

  final VoidCallback? onPressed;

  // ==========================================================
  // OPTIONAL BOOST DATA
  // ==========================================================

  /// True when Stella currently has an active 4-hour boost.
  final bool adBoostActive;

  /// Remaining duration of the active boost.
  final Duration adBoostRemaining;

  /// Current advertisement Hash Rate bonus.
  final double adBoostHashRate;

  const WatchAdCard({
    super.key,
    required this.title,
    required this.dailyLimitText,
    required this.adsToday,
    required this.maxAdsPerDay,
    required this.canWatch,
    required this.nextAdText,
    required this.adLoading,
    required this.adReady,
    required this.loadingText,
    required this.limitReachedText,
    required this.unavailableText,
    required this.watchButtonText,
    required this.onPressed,
    this.adBoostActive = false,
    this.adBoostRemaining = Duration.zero,
    this.adBoostHashRate = adHashRateBonus,
  });

  // ==========================================================
  // ⏳ FORMAT BOOST TIME
  // ==========================================================

  String formatBoostRemaining(Duration duration) {
    if (duration <= Duration.zero) {
      return '00:00:00';
    }

    final int totalSeconds = duration.inSeconds;

    final int hours = totalSeconds ~/ 3600;
    final int minutes = (totalSeconds % 3600) ~/ 60;
    final int seconds = totalSeconds % 60;

    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  // ==========================================================
  // STATUS TEXT
  // ==========================================================

  String cooldownRemainingText() {
    if (nextAdText.isEmpty) {
      return 'Preparing Stella’s next mining boost 🐱';
    }

    return nextAdText;
  }

  @override
  Widget build(BuildContext context) {
    // ========================================================
    // STATUS
    // ========================================================

    final bool limitReached = adsToday >= maxAdsPerDay;

    final bool boostActive =
        adBoostActive && adBoostRemaining > Duration.zero;

    final bool isDisabled =
        adLoading ||
        limitReached ||
        !canWatch ||
        !adReady ||
        boostActive ||
        onPressed == null;

    String buttonText;
    String leftEmoji;
    String rightEmoji;

    if (adLoading) {
      buttonText = loadingText;
      leftEmoji = '⏳';
      rightEmoji = '🐾';
    } else if (limitReached) {
      buttonText = limitReachedText;
      leftEmoji = '😿';
      rightEmoji = '🐾';
    } else if (boostActive) {
      buttonText = formatBoostRemaining(adBoostRemaining);
      leftEmoji = '⚡';
      rightEmoji = '🐱';
    } else if (!canWatch) {
      buttonText = nextAdText;
      leftEmoji = '⏰';
      rightEmoji = '🐱';
    } else if (!adReady) {
      buttonText = unavailableText;
      leftEmoji = '🐱';
      rightEmoji = '💤';
    } else {
      buttonText = watchButtonText;
      leftEmoji = '📺';
      rightEmoji = '⚡';
    }

    // ========================================================
    // PROGRESS
    // ========================================================

    final double rawProgress = maxAdsPerDay > 0
        ? adsToday / maxAdsPerDay
        : 0.0;

    final double progress =
        rawProgress.clamp(0.0, 1.0).toDouble();

    // ========================================================
    // CARD
    // ========================================================

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: boostActive
              ? watchAdGoldColor.withValues(alpha: 0.38)
              : watchAdAccentColor.withValues(alpha: 0.22),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ==================================================
          // HEADER
          // ==================================================

          Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      watchAdAccentColor.withValues(alpha: 0.20),
                      watchAdPinkColor.withValues(alpha: 0.12),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: watchAdAccentColor.withValues(
                      alpha: 0.32,
                    ),
                  ),
                ),
                child: Center(
                  child: Text(
                    boostActive ? '⚡' : '📺',
                    style: const TextStyle(fontSize: 30),
                  ),
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      boostActive
                          ? 'Stella’s Power Boost is active ⚡🐱'
                          : '+${adHashRateBonus.toStringAsFixed(4)} HR '
                              'for $adBoostDurationHours hours ⚡🐱',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.58),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ==================================================
          // POWER BOOST INFORMATION
          // ==================================================

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 15,
            ),
            decoration: BoxDecoration(
              color: boostActive
                  ? watchAdGoldColor.withValues(alpha: 0.08)
                  : backgroundColor.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: boostActive
                    ? watchAdGoldColor.withValues(alpha: 0.25)
                    : watchAdPinkColor.withValues(alpha: 0.08),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        watchAdAccentColor.withValues(alpha: 0.20),
                        watchAdGoldColor.withValues(alpha: 0.12),
                      ],
                    ),
                  ),
                  child: Center(
                    child: Text(
                      boostActive ? '⚡' : '🚀',
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        boostActive
                            ? 'POWER BOOST ACTIVE'
                            : 'MINING POWER BOOST',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        boostActive
                            ? '+${adBoostHashRate.toStringAsFixed(4)} HR '
                                '• ${formatBoostRemaining(adBoostRemaining)}'
                            : '+${adHashRateBonus.toStringAsFixed(4)} HR '
                                '• $adBoostDurationHours hours',
                        style: TextStyle(
                          color: boostActive
                              ? watchAdGoldColor
                              : Colors.white.withValues(alpha: 0.50),
                          fontSize: 11,
                          fontWeight: boostActive
                              ? FontWeight.w700
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ==================================================
          // DAILY LIMIT
          // ==================================================

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '$dailyLimitText: '
                  '$adsToday / $maxAdsPerDay',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.78),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(width: 12),

              Text(
                '$adsToday/$maxAdsPerDay',
                style: const TextStyle(
                  color: watchAdPinkColor,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // ==================================================
          // PROGRESS BAR
          // ==================================================

          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor:
                  Colors.white.withValues(alpha: 0.07),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(
                watchAdAccentColor,
              ),
            ),
          ),

          // ==================================================
          // ACTIVE BOOST MESSAGE
          // ==================================================

          if (boostActive) ...[
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: watchAdAccentColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: watchAdAccentColor.withValues(alpha: 0.24),
                ),
              ),
              child: Row(
                children: [
                  const Text(
                    '⚡',
                    style: TextStyle(fontSize: 22),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'STELLA POWER BOOST',
                          style: TextStyle(
                            color: watchAdAccentColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.7,
                          ),
                        ),

                        const SizedBox(height: 3),

                        Text(
                          '${formatBoostRemaining(adBoostRemaining)} '
                          'remaining',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        const SizedBox(height: 2),

                        Text(
                          'The next ad is available after this boost ends.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.50),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ]

          // ==================================================
          // COOLDOWN / NEXT AD
          // ==================================================

          else if (adsToday < maxAdsPerDay && !canWatch) ...[
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: watchAdGoldColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: watchAdGoldColor.withValues(alpha: 0.22),
                ),
              ),
              child: Row(
                children: [
                  const Text(
                    '😺',
                    style: TextStyle(fontSize: 22),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: Text(
                      nextAdText,
                      style: const TextStyle(
                        color: watchAdGoldColor,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 22),

          // ==================================================
          // WATCH BUTTON
          // ==================================================

          SizedBox(
            width: double.infinity,
            height: 62,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: isDisabled ? null : onPressed,
                borderRadius: BorderRadius.circular(18),
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: isDisabled
                        ? null
                        : const LinearGradient(
                            colors: [
                              watchAdAccentColor,
                              watchAdPinkColor,
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                    color: isDisabled
                        ? Colors.grey.withValues(alpha: 0.18)
                        : null,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: isDisabled
                        ? []
                        : [
                            BoxShadow(
                              color: watchAdAccentColor.withValues(
                                alpha: 0.25,
                              ),
                              blurRadius: 18,
                              offset: const Offset(0, 7),
                            ),
                          ],
                  ),
                  child: Center(
                    child: adLoading
                        ? const SizedBox(
                            width: 26,
                            height: 26,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: backgroundColor,
                            ),
                          )
                        : Row(
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            children: [
                              Text(
                                leftEmoji,
                                style: const TextStyle(fontSize: 25),
                              ),

                              const SizedBox(width: 10),

                              Flexible(
                                child: Text(
                                  buttonText,
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: isDisabled
                                        ? Colors.white.withValues(
                                            alpha: 0.40,
                                          )
                                        : backgroundColor,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.7,
                                  ),
                                ),
                              ),

                              const SizedBox(width: 10),

                              Text(
                                rightEmoji,
                                style: const TextStyle(fontSize: 24),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 14),

          // ==================================================
          // STATUS TEXT
          // ==================================================

          Center(
            child: Text(
              limitReached
                  ? 'Daily mining boost limit reached 🐱'
                  : boostActive
                      ? 'Stella is mining with Power Boost! ⚡🐱'
                      : canWatch && adReady
                          ? 'Watch an ad for '
                              '+${adHashRateBonus.toStringAsFixed(4)} HR '
                              'for 4 hours! ⚡🐱'
                          : cooldownRemainingText(),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: boostActive
                    ? watchAdGoldColor.withValues(alpha: 0.88)
                    : watchAdAccentColor.withValues(alpha: 0.78),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}