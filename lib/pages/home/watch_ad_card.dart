import 'package:flutter/material.dart';

// ============================================================
// STELLA THEME
// ============================================================

const Color backgroundColor = Color(0xFF120B24);
const Color cardColor = Color(0xFF21113B);

const Color watchAdAccentColor = Color(0xFFB58CFF);
const Color watchAdPinkColor = Color(0xFFFFB7E8);
const Color watchAdGoldColor = Color(0xFFFFD166);
const Color watchAdSecondaryTextColor = Color(0xFFBFAEDB);

// ============================================================
// WATCH AD CARD
// ============================================================

class WatchAdCard extends StatelessWidget {
  // ==========================================================
  // DEFAULT POWER BOOST VALUES
  // ==========================================================

  static const double defaultAdHashRateBonus = 0.5833;
  static const int defaultAdBoostDurationHours = 4;

  // ==========================================================
  // BASIC TEXT
  // ==========================================================

  final String title;
  final String dailyLimitText;

  final String watchButtonText;
  final String loadingText;
  final String limitReachedText;
  final String unavailableText;
  final String nextAdText;

  // ==========================================================
  // STATUS / DESCRIPTION TEXT
  // ==========================================================

  final String powerBoostActiveText;
  final String powerBoostOfferText;
  final String powerBoostActiveTitleText;
  final String remainingText;
  final String nextAdAfterBoostText;

  final String adsTodayText;
  final String maxBoostsInfoText;

  // ==========================================================
  // POWER BOOST STATE
  // ==========================================================

  final int adsToday;
  final int maxAdsPerDay;

  final bool canWatch;

  final bool adLoading;
  final bool adReady;

  final bool adBoostActive;

  final Duration adBoostRemaining;

  final Duration cooldownRemaining;

  final double adHashRateBonus;

  // ==========================================================
  // CALLBACK
  // ==========================================================

  final VoidCallback? onPressed;

  const WatchAdCard({
    super.key,

    // Basic text
    required this.title,
    required this.dailyLimitText,
    required this.watchButtonText,
    required this.loadingText,
    required this.limitReachedText,
    required this.unavailableText,
    required this.nextAdText,

    // Status text
    required this.powerBoostActiveText,
    required this.powerBoostOfferText,
    required this.powerBoostActiveTitleText,
    required this.remainingText,
    required this.nextAdAfterBoostText,
    required this.adsTodayText,
    required this.maxBoostsInfoText,

    // State
    required this.adsToday,
    required this.maxAdsPerDay,
    required this.canWatch,
    required this.adLoading,
    required this.adReady,
    required this.adBoostActive,
    required this.adBoostRemaining,
    required this.cooldownRemaining,

    // Boost
    this.adHashRateBonus = defaultAdHashRateBonus,

    // Callback
    required this.onPressed,
  });

  // ==========================================================
  // BOOST ACTIVE
  // ==========================================================

  bool get boostActive =>
      adBoostActive &&
      adBoostRemaining > Duration.zero;

  // ==========================================================
  // DAILY LIMIT
  // ==========================================================

  bool get limitReached =>
      adsToday >= maxAdsPerDay;

  // ==========================================================
  // BUTTON AVAILABLE
  // ==========================================================

  bool get canUseButton =>
      !adLoading &&
      !limitReached &&
      canWatch &&
      adReady &&
      !boostActive &&
      cooldownRemaining <= Duration.zero &&
      onPressed != null;

  // ==========================================================
  // FORMAT BOOST TIME
  // ==========================================================

  String formatBoostRemaining(
    Duration duration,
  ) {
    if (duration <= Duration.zero) {
      return '00:00:00';
    }

    final int totalSeconds =
        duration.inSeconds;

    final int hours =
        totalSeconds ~/ 3600;

    final int minutes =
        (totalSeconds % 3600) ~/ 60;

    final int seconds =
        totalSeconds % 60;

    final String hoursText =
        hours.toString().padLeft(2, '0');

    final String minutesText =
        minutes.toString().padLeft(2, '0');

    final String secondsText =
        seconds.toString().padLeft(2, '0');

    return '$hoursText:$minutesText:$secondsText';
  }

  // ==========================================================
  // PROGRESS
  // ==========================================================

  double get dailyProgress {
    if (maxAdsPerDay <= 0) {
      return 0.0;
    }

    return (adsToday / maxAdsPerDay)
        .clamp(0.0, 1.0)
        .toDouble();
  }

  // ==========================================================
  // BUTTON TEXT
  // ==========================================================

  String get _buttonText {
    if (adLoading) {
      return loadingText;
    }

    if (limitReached) {
      return limitReachedText;
    }

    if (boostActive) {
      return formatBoostRemaining(
        adBoostRemaining,
      );
    }

    if (!canWatch) {
      return nextAdText;
    }

    if (!adReady) {
      return unavailableText;
    }

    return watchButtonText;
  }

  // ==========================================================
  // BUTTON EMOJI
  // ==========================================================

  String get _leftEmoji {
    if (adLoading) {
      return '⏳';
    }

    if (limitReached) {
      return '😿';
    }

    if (boostActive) {
      return '⚡';
    }

    if (!canWatch) {
      return '⏰';
    }

    if (!adReady) {
      return '🐱';
    }

    return '📺';
  }

  String get _rightEmoji {
    if (adLoading) {
      return '🐾';
    }

    if (limitReached) {
      return '🐾';
    }

    if (boostActive) {
      return '🐱';
    }

    if (!canWatch) {
      return '🐱';
    }

    if (!adReady) {
      return '💤';
    }

    return '⚡';
  }

  // ==========================================================
  // STATUS TEXT
  // ==========================================================

  String get _statusText {
    if (limitReached) {
      return limitReachedText;
    }

    if (boostActive) {
      return powerBoostActiveText;
    }

    if (cooldownRemaining > Duration.zero) {
      return nextAdText;
    }

    if (canWatch && adReady) {
      return powerBoostOfferText;
    }

    return unavailableText;
  }

  // ==========================================================
  // HEADER SUBTITLE
  // ==========================================================

  String get _headerSubtitle {
    if (boostActive) {
      return powerBoostActiveText;
    }

    return powerBoostOfferText;
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius:
            BorderRadius.circular(22),
        border: Border.all(
          color: boostActive
              ? watchAdGoldColor.withValues(
                  alpha: 0.38,
                )
              : watchAdPinkColor.withValues(
                  alpha: 0.24,
                ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.25,
            ),
            blurRadius: 20,
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
                  gradient:
                      LinearGradient(
                    colors: [
                      watchAdAccentColor
                          .withValues(
                        alpha: 0.20,
                      ),
                      watchAdPinkColor
                          .withValues(
                        alpha: 0.12,
                      ),
                    ],
                    begin:
                        Alignment.topLeft,
                    end:
                        Alignment.bottomRight,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    18,
                  ),
                  border: Border.all(
                    color:
                        watchAdAccentColor
                            .withValues(
                      alpha: 0.32,
                    ),
                  ),
                ),
                child: Center(
                  child: Text(
                    boostActive
                        ? '⚡'
                        : '📺',
                    style:
                        const TextStyle(
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
                      title,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style:
                          const TextStyle(
                        color:
                            Colors.white,
                        fontSize: 16,
                        fontWeight:
                            FontWeight.bold,
                        letterSpacing:
                            1.1,
                      ),
                    ),

                    const SizedBox(
                      height: 5,
                    ),

                    Text(
                      _headerSubtitle,
                      maxLines: 2,
                      overflow:
                          TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white
                            .withValues(
                          alpha: 0.58,
                        ),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ==================================================
          // BOOST INFORMATION
          // ==================================================

          Container(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 15,
              vertical: 14,
            ),
            decoration:
                BoxDecoration(
              color: boostActive
                  ? watchAdGoldColor
                      .withValues(
                      alpha: 0.08,
                    )
                  : backgroundColor
                      .withValues(
                      alpha: 0.72,
                    ),
              borderRadius:
                  BorderRadius.circular(
                17,
              ),
              border: Border.all(
                color: boostActive
                    ? watchAdGoldColor
                        .withValues(
                        alpha: 0.25,
                      )
                    : watchAdPinkColor
                        .withValues(
                        alpha: 0.08,
                      ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration:
                      BoxDecoration(
                    shape:
                        BoxShape.circle,
                    gradient:
                        LinearGradient(
                      colors: [
                        watchAdAccentColor
                            .withValues(
                          alpha: 0.20,
                        ),
                        watchAdGoldColor
                            .withValues(
                          alpha: 0.12,
                        ),
                      ],
                    ),
                  ),
                  child: Center(
                    child: Text(
                      boostActive
                          ? '⚡'
                          : '🚀',
                      style:
                          const TextStyle(
                        fontSize: 22,
                      ),
                    ),
                  ),
                ),

                const SizedBox(
                  width: 12,
                ),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        boostActive
                            ? powerBoostActiveTitleText
                            : title,
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,
                        style:
                            const TextStyle(
                          color:
                              Colors.white,
                          fontSize: 13,
                          fontWeight:
                              FontWeight.bold,
                          letterSpacing:
                              0.7,
                        ),
                      ),

                      const SizedBox(
                        height: 4,
                      ),

                      Text(
                        boostActive
                            ? '+${adHashRateBonus.toStringAsFixed(4)} HR • '
                                '${formatBoostRemaining(adBoostRemaining)}'
                            : powerBoostOfferText,
                        maxLines: 2,
                        overflow:
                            TextOverflow.ellipsis,
                        style:
                            TextStyle(
                          color: boostActive
                              ? watchAdGoldColor
                              : Colors.white
                                  .withValues(
                                  alpha: 0.50,
                                ),
                          fontSize: 11,
                          fontWeight:
                              boostActive
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
            children: [
              Expanded(
                child: Text(
                  '$dailyLimitText: '
                  '$adsToday / $maxAdsPerDay',
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style:
                      TextStyle(
                    color: Colors.white
                        .withValues(
                      alpha: 0.78,
                    ),
                    fontSize: 13,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(
                width: 10,
              ),

              Text(
                '$adsToday/$maxAdsPerDay',
                style:
                    const TextStyle(
                  color:
                      watchAdPinkColor,
                  fontSize: 13,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // ==================================================
          // DAILY PROGRESS
          // ==================================================

          ClipRRect(
            borderRadius:
                BorderRadius.circular(
              20,
            ),
            child:
                LinearProgressIndicator(
              value: dailyProgress,
              minHeight: 8,
              backgroundColor:
                  Colors.white
                      .withValues(
                alpha: 0.07,
              ),
              valueColor:
                  const AlwaysStoppedAnimation<
                      Color>(
                watchAdAccentColor,
              ),
            ),
          ),

          // ==================================================
          // ACTIVE BOOST
          // ==================================================

          if (boostActive) ...[
            const SizedBox(height: 14),

            Container(
              padding:
                  const EdgeInsets.all(
                14,
              ),
              decoration:
                  BoxDecoration(
                color:
                    watchAdAccentColor
                        .withValues(
                  alpha: 0.08,
                ),
                borderRadius:
                    BorderRadius.circular(
                  16,
                ),
                border: Border.all(
                  color:
                      watchAdAccentColor
                          .withValues(
                    alpha: 0.24,
                  ),
                ),
              ),
              child: Row(
                children: [
                  const Text(
                    '⚡',
                    style:
                        TextStyle(
                      fontSize: 22,
                    ),
                  ),

                  const SizedBox(
                    width: 10,
                  ),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          powerBoostActiveTitleText,
                          style:
                              const TextStyle(
                            color:
                                watchAdAccentColor,
                            fontSize: 12,
                            fontWeight:
                                FontWeight.bold,
                            letterSpacing:
                                0.7,
                          ),
                        ),

                        const SizedBox(
                          height: 4,
                        ),

                        Text(
                          '$remainingText: '
                          '${formatBoostRemaining(adBoostRemaining)}',
                          style:
                              const TextStyle(
                            color:
                                Colors.white,
                            fontSize: 13,
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),

                        const SizedBox(
                          height: 3,
                        ),

                        Text(
                          '+${adHashRateBonus.toStringAsFixed(4)} HR',
                          style:
                              const TextStyle(
                            color:
                                watchAdGoldColor,
                            fontSize: 11,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),

                        const SizedBox(
                          height: 3,
                        ),

                        Text(
                          nextAdAfterBoostText,
                          maxLines: 2,
                          overflow:
                              TextOverflow.ellipsis,
                          style:
                              TextStyle(
                            color:
                                Colors.white
                                    .withValues(
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
          ]

          // ==================================================
          // COOLDOWN
          // ==================================================

          else if (cooldownRemaining >
                  Duration.zero &&
              adsToday < maxAdsPerDay) ...[
            const SizedBox(height: 14),

            Container(
              padding:
                  const EdgeInsets.all(
                14,
              ),
              decoration:
                  BoxDecoration(
                color:
                    watchAdGoldColor
                        .withValues(
                  alpha: 0.08,
                ),
                borderRadius:
                    BorderRadius.circular(
                  16,
                ),
                border: Border.all(
                  color:
                      watchAdGoldColor
                          .withValues(
                    alpha: 0.22,
                  ),
                ),
              ),
              child: Row(
                children: [
                  const Text(
                    '😺',
                    style:
                        TextStyle(
                      fontSize: 22,
                    ),
                  ),

                  const SizedBox(
                    width: 10,
                  ),

                  Expanded(
                    child: Text(
                      nextAdText,
                      maxLines: 2,
                      overflow:
                          TextOverflow.ellipsis,
                      style:
                          const TextStyle(
                        color:
                            watchAdGoldColor,
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

          const SizedBox(height: 18),

          // ==================================================
          // WATCH BUTTON
          // ==================================================

          SizedBox(
            width: double.infinity,
            height: 60,
            child: Material(
              color:
                  Colors.transparent,
              child: InkWell(
                onTap: canUseButton
                    ? onPressed
                    : null,
                borderRadius:
                    BorderRadius.circular(
                  18,
                ),
                child: Ink(
                  decoration:
                      BoxDecoration(
                    gradient:
                        canUseButton
                            ? const LinearGradient(
                                colors: [
                                  watchAdAccentColor,
                                  watchAdPinkColor,
                                ],
                                begin:
                                    Alignment.centerLeft,
                                end:
                                    Alignment.centerRight,
                              )
                            : null,
                    color: canUseButton
                        ? null
                        : Colors.grey
                            .withValues(
                            alpha: 0.18,
                          ),
                    borderRadius:
                        BorderRadius.circular(
                      18,
                    ),
                    boxShadow:
                        canUseButton
                            ? [
                                BoxShadow(
                                  color:
                                      watchAdAccentColor
                                          .withValues(
                                    alpha:
                                        0.24,
                                  ),
                                  blurRadius:
                                      18,
                                  offset:
                                      const Offset(
                                    0,
                                    7,
                                  ),
                                ),
                              ]
                            : [],
                  ),
                  child: Center(
                    child: adLoading
                        ? const SizedBox(
                            width: 25,
                            height: 25,
                            child:
                                CircularProgressIndicator(
                              strokeWidth:
                                  3,
                              color:
                                  backgroundColor,
                            ),
                          )
                        : Row(
                            mainAxisAlignment:
                                MainAxisAlignment
                                    .center,
                            children: [
                              Text(
                                _leftEmoji,
                                style:
                                    const TextStyle(
                                  fontSize:
                                      23,
                                ),
                              ),

                              const SizedBox(
                                width: 9,
                              ),

                              Flexible(
                                child: Text(
                                  _buttonText,
                                  textAlign:
                                      TextAlign.center,
                                  maxLines: 2,
                                  overflow:
                                      TextOverflow.ellipsis,
                                  style:
                                      TextStyle(
                                    color: canUseButton
                                        ? backgroundColor
                                        : Colors
                                            .white
                                            .withValues(
                                            alpha:
                                                0.40,
                                          ),
                                    fontSize:
                                        13,
                                    fontWeight:
                                        FontWeight.bold,
                                    letterSpacing:
                                        0.5,
                                  ),
                                ),
                              ),

                              const SizedBox(
                                width: 9,
                              ),

                              Text(
                                _rightEmoji,
                                style:
                                    const TextStyle(
                                  fontSize:
                                      22,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ==================================================
          // STATUS
          // ==================================================

          Text(
            _statusText,
            textAlign:
                TextAlign.center,
            maxLines: 2,
            overflow:
                TextOverflow.ellipsis,
            style: TextStyle(
              color: boostActive
                  ? watchAdGoldColor
                      .withValues(
                      alpha: 0.88,
                    )
                  : watchAdAccentColor
                      .withValues(
                      alpha: 0.78,
                    ),
              fontSize: 11,
              fontWeight:
                  FontWeight.w600,
            ),
          ),

          const SizedBox(height: 8),

          // ==================================================
          // FOOTER
          // ==================================================

          Text(
            maxBoostsInfoText,
            textAlign:
                TextAlign.center,
            style:
                const TextStyle(
              color:
                  Color(0xFF6F5C84),
              fontSize: 10,
            ),
          ),

          const SizedBox(height: 3),

          Text(
            '$adsToday/$maxAdsPerDay • '
            '$adsTodayText',
            textAlign:
                TextAlign.center,
            style:
                const TextStyle(
              color:
                  Color(0xFF8D7BA8),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}