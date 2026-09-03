import 'package:flutter/material.dart';

// ============================================================
// COLORS
// ============================================================

const Color backgroundColor = Color(0xFF0B1112);
const Color cardColor = Color(0xFF151B1C);
const Color watchAdAccentColor = Color(0xFF35D0A0);

// ============================================================
// WATCH AD CARD
// ============================================================

class WatchAdCard extends StatelessWidget {
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
  });

  @override
  Widget build(BuildContext context) {
    // ========================================================
    // STATUS
    // ========================================================

    final limitReached =
        adsToday >= maxAdsPerDay;

    final isDisabled =
        adLoading ||
        limitReached ||
        !canWatch ||
        !adReady ||
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

    final progress =
        maxAdsPerDay > 0
            ? adsToday / maxAdsPerDay
            : 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),

        border: Border.all(
          color: watchAdAccentColor.withValues(
            alpha: 0.22,
          ),
        ),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.20,
            ),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.stretch,

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
                  color:
                      watchAdAccentColor.withValues(
                    alpha: 0.14,
                  ),

                  borderRadius:
                      BorderRadius.circular(18),

                  border: Border.all(
                    color:
                        watchAdAccentColor.withValues(
                      alpha: 0.30,
                    ),
                  ),
                ),

                child: const Center(
                  child: Text(
                    '📺',
                    style: TextStyle(
                      fontSize: 30,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [

                    Text(
                      title.toUpperCase(),

                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight:
                            FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      'Boost Stella’s Hash Rate ⚡🐱',

                      style: TextStyle(
                        color: Colors.white.withValues(
                          alpha: 0.55,
                        ),

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
          // HASH RATE INFO
          // ==================================================

          Container(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 15,
            ),

            decoration: BoxDecoration(
              color: Colors.black.withValues(
                alpha: 0.18,
              ),

              borderRadius:
                  BorderRadius.circular(18),

              border: Border.all(
                color: Colors.white.withValues(
                  alpha: 0.05,
                ),
              ),
            ),

            child: Row(
              children: [

                Container(
                  width: 42,
                  height: 42,

                  decoration: BoxDecoration(
                    shape: BoxShape.circle,

                    color:
                        watchAdAccentColor.withValues(
                      alpha: 0.14,
                    ),
                  ),

                  child: const Center(
                    child: Text(
                      '⚡',
                      style: TextStyle(
                        fontSize: 22,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,

                    children: [

                      const Text(
                        'MINING POWER BOOST',

                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight:
                              FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        'Watch an ad to increase Hash Rate',

                        style: TextStyle(
                          color:
                              Colors.white.withValues(
                            alpha: 0.50,
                          ),

                          fontSize: 11,
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
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,

            children: [

              Text(
                '$dailyLimitText: '
                '$adsToday / $maxAdsPerDay',

                style: TextStyle(
                  color: Colors.white.withValues(
                    alpha: 0.75,
                  ),

                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),

              Text(
                '$adsToday/$maxAdsPerDay',

                style: const TextStyle(
                  color: watchAdAccentColor,
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
            borderRadius:
                BorderRadius.circular(20),

            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),

              minHeight: 8,

              backgroundColor:
                  Colors.white.withValues(
                alpha: 0.07,
              ),

              valueColor:
                  const AlwaysStoppedAnimation<Color>(
                watchAdAccentColor,
              ),
            ),
          ),

          // ==================================================
          // COOLDOWN
          // ==================================================

          if (adsToday < maxAdsPerDay &&
              !canWatch) ...[

            const SizedBox(height: 16),

            Container(
              padding:
                  const EdgeInsets.all(14),

              decoration: BoxDecoration(
                color: Colors.orange.withValues(
                  alpha: 0.10,
                ),

                borderRadius:
                    BorderRadius.circular(16),

                border: Border.all(
                  color: Colors.orange.withValues(
                    alpha: 0.25,
                  ),
                ),
              ),

              child: Row(
                children: [

                  const Text(
                    '😺',
                    style: TextStyle(
                      fontSize: 22,
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: Text(
                      nextAdText,

                      style: const TextStyle(
                        color: Colors.orangeAccent,
                        fontSize: 13,
                        fontWeight:
                            FontWeight.bold,
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
                onTap:
                    isDisabled
                        ? null
                        : onPressed,

                borderRadius:
                    BorderRadius.circular(18),

                child: Ink(
                  decoration: BoxDecoration(
                    color: isDisabled
                        ? Colors.grey.withValues(
                            alpha: 0.18,
                          )
                        : watchAdAccentColor,

                    borderRadius:
                        BorderRadius.circular(18),

                    boxShadow: isDisabled
                        ? []
                        : [
                            BoxShadow(
                              color:
                                  watchAdAccentColor
                                      .withValues(
                                alpha: 0.28,
                              ),

                              blurRadius: 18,
                              offset:
                                  const Offset(0, 7),
                            ),
                          ],
                  ),

                  child: Center(
                    child: adLoading

                        ? const SizedBox(
                            width: 26,
                            height: 26,

                            child:
                                CircularProgressIndicator(
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
                                style: const TextStyle(
                                  fontSize: 25,
                                ),
                              ),

                              const SizedBox(width: 10),

                              Flexible(
                                child: Text(
                                  buttonText,

                                  textAlign:
                                      TextAlign.center,

                                  overflow:
                                      TextOverflow.ellipsis,

                                  style: TextStyle(
                                    color: isDisabled
                                        ? Colors.white
                                            .withValues(
                                            alpha: 0.40,
                                          )
                                        : backgroundColor,

                                    fontSize: 14,

                                    fontWeight:
                                        FontWeight.bold,

                                    letterSpacing: 0.7,
                                  ),
                                ),
                              ),

                              const SizedBox(width: 10),

                              Text(
                                rightEmoji,
                                style: const TextStyle(
                                  fontSize: 24,
                                ),
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
                  : canWatch && adReady
                      ? 'Stella is ready to boost her mining power! ⚡🐱'
                      : cooldownRemainingText(),

              textAlign: TextAlign.center,

              style: TextStyle(
                color:
                    watchAdAccentColor.withValues(
                  alpha: 0.75,
                ),

                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
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
}