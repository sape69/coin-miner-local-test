import 'package:flutter/material.dart';

const Color backgroundColor = Color(0xFF0B1112);
const Color cardColor = Color(0xFF151B1C);
const Color watchAdAccentColor = Color(0xFF35D0A0);

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
    // ==========================================================
    // BUTTON STATUS
    // ==========================================================

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
      leftEmoji = '🐾';
      rightEmoji = '🐱';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color:
              watchAdAccentColor.withValues(
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
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          // ==================================================
          // HEADER
          // ==================================================

          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color:
                      watchAdAccentColor.withValues(
                    alpha: 0.15,
                  ),
                  borderRadius:
                      BorderRadius.circular(16),
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
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // ==================================================
          // DAILY LIMIT
          // ==================================================

          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            decoration: BoxDecoration(
              color: Colors.black.withValues(
                alpha: 0.18,
              ),
              borderRadius:
                  BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Text(
                  '🐾',
                  style: TextStyle(
                    fontSize: 24,
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: Text(
                    '$dailyLimitText: '
                    '$adsToday / $maxAdsPerDay',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                ),

                Text(
                  '$adsToday/$maxAdsPerDay',
                  style: TextStyle(
                    color: watchAdAccentColor
                        .withValues(alpha: 0.85),
                    fontSize: 13,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // ==================================================
          // COOLDOWN MESSAGE
          // ==================================================

          if (adsToday < maxAdsPerDay &&
              !canWatch) ...[
            const SizedBox(height: 12),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange
                    .withValues(alpha: 0.10),
                borderRadius:
                    BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.orange
                      .withValues(alpha: 0.25),
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
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),

          // ==================================================
          // CAT PAW BUTTON
          // ==================================================

          SizedBox(
            width: double.infinity,
            height: 72,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap:
                    isDisabled ? null : onPressed,
                borderRadius:
                    BorderRadius.circular(36),
                child: Ink(
                  decoration: BoxDecoration(
                    color: isDisabled
                        ? Colors.grey.withValues(
                            alpha: 0.20,
                          )
                        : watchAdAccentColor,
                    borderRadius:
                        BorderRadius.circular(36),
                    boxShadow: isDisabled
                        ? []
                        : [
                            BoxShadow(
                              color: watchAdAccentColor
                                  .withValues(
                                alpha: 0.30,
                              ),
                              blurRadius: 16,
                              offset:
                                  const Offset(0, 6),
                            ),
                          ],
                  ),
                  child: Center(
                    child: adLoading
                        ? const SizedBox(
                            width: 28,
                            height: 28,
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
                                  fontSize: 30,
                                ),
                              ),

                              const SizedBox(width: 12),

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
                                            alpha: 0.45,
                                          )
                                        : backgroundColor,
                                    fontSize: 15,
                                    fontWeight:
                                        FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),

                              const SizedBox(width: 12),

                              Text(
                                rightEmoji,
                                style: const TextStyle(
                                  fontSize: 28,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ),

          // ==================================================
          // READY MESSAGE
          // ==================================================

          if (!isDisabled) ...[
            const SizedBox(height: 14),

            Center(
              child: Text(
                'Stella is ready to earn some STL! 🐱✨',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: watchAdAccentColor
                      .withValues(alpha: 0.85),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}