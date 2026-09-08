import 'package:flutter/material.dart';

// ============================================================
// ⚡ STELLURIINI POWER BOOST CARD
// ============================================================

class PowerBoostCard extends StatelessWidget {
  final bool boostActive;
  final int boostRemainingMs;

  final int adsToday;
  final int maxAdsPerDay;

  final bool canUse;
  final String subtitle;

  final String title;
  final String activeText;
  final String activeTitle;
  final String remainingText;
  final String hashRateBonusText;
  final String effectiveHashRateText;
  final String nextAdAfterBoostText;

  final String watchAdText;
  final String adsTodayText;
  final String maxBoostsInfoText;

  final VoidCallback? onPressed;

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
      Color(0xFF8D7BA8);

  static const Color veryMutedTextColor =
      Color(0xFF6F5C84);

  // ============================================================
  // CONSTRUCTOR
  // ============================================================

  const PowerBoostCard({
    super.key,
    required this.boostActive,
    required this.boostRemainingMs,
    required this.adsToday,
    required this.maxAdsPerDay,
    required this.canUse,
    required this.subtitle,
    required this.title,
    required this.activeText,
    required this.activeTitle,
    required this.remainingText,
    required this.hashRateBonusText,
    required this.effectiveHashRateText,
    required this.nextAdAfterBoostText,
    required this.watchAdText,
    required this.adsTodayText,
    required this.maxBoostsInfoText,
    required this.onPressed,
  });

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final bool hasActiveBoost =
        boostActive &&
        boostRemainingMs > 0;

    return Container(
      padding:
          const EdgeInsets.all(18),
      decoration:
          BoxDecoration(
        color:
            cardColor,
        borderRadius:
            BorderRadius.circular(22),
        border:
            Border.all(
          color:
              hasActiveBoost
                  ? goldColor.withValues(
                      alpha: 0.40,
                    )
                  : pinkColor.withValues(
                      alpha: 0.30,
                    ),
        ),
      ),
      child:
          Column(
        children: [
          // ====================================================
          // HEADER
          // ====================================================

          Row(
            children: [
              Text(
                hasActiveBoost
                    ? '⚡'
                    : '📺',
                style:
                    const TextStyle(
                  fontSize:
                      28,
                ),
              ),

              const SizedBox(
                width: 12,
              ),

              Expanded(
                child:
                    Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
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

                    const SizedBox(
                      height: 3,
                    ),

                    Text(
                      hasActiveBoost
                          ? activeText
                          : subtitle,
                      style:
                          const TextStyle(
                        color:
                            secondaryTextColor,
                        fontSize:
                            12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 16,
          ),

          // ====================================================
          // ACTIVE BOOST / WATCH BUTTON
          // ====================================================

          if (hasActiveBoost)
            _buildActiveBoost()
          else
            _buildWatchButton(),

          const SizedBox(
            height: 10,
          ),

          // ====================================================
          // DAILY AD COUNT
          // ====================================================

          Text(
            adsTodayText,
            textAlign:
                TextAlign.center,
            style:
                const TextStyle(
              color:
                  mutedTextColor,
              fontSize:
                  11,
            ),
          ),

          const SizedBox(
            height: 4,
          ),

          // ====================================================
          // DAILY LIMIT INFORMATION
          // ====================================================

          Text(
            maxBoostsInfoText,
            textAlign:
                TextAlign.center,
            style:
                const TextStyle(
              color:
                  veryMutedTextColor,
              fontSize:
                  10,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ⚡ ACTIVE BOOST
  // ============================================================

  Widget _buildActiveBoost() {
    return Container(
      width:
          double.infinity,
      padding:
          const EdgeInsets.all(14),
      decoration:
          BoxDecoration(
        color:
            goldColor.withValues(
          alpha: 0.08,
        ),
        borderRadius:
            BorderRadius.circular(16),
        border:
            Border.all(
          color:
              goldColor.withValues(
            alpha: 0.25,
          ),
        ),
      ),
      child:
          Column(
        children: [
          // ----------------------------------------------------
          // ACTIVE TITLE
          // ----------------------------------------------------

          Text(
            activeTitle,
            textAlign:
                TextAlign.center,
            style:
                const TextStyle(
              color:
                  goldColor,
              fontSize:
                  12,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 7,
          ),

          // ----------------------------------------------------
          // REMAINING TIME
          // ----------------------------------------------------

          Text(
            remainingText,
            textAlign:
                TextAlign.center,
            style:
                const TextStyle(
              color:
                  Colors.white,
              fontSize:
                  18,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 6,
          ),

          // ----------------------------------------------------
          // HASH RATE BONUS
          // ----------------------------------------------------

          Text(
            hashRateBonusText,
            textAlign:
                TextAlign.center,
            style:
                const TextStyle(
              color:
                  pinkColor,
              fontSize:
                  13,
              fontWeight:
                  FontWeight.w700,
            ),
          ),

          const SizedBox(
            height: 6,
          ),

          // ----------------------------------------------------
          // EFFECTIVE HASH RATE
          // ----------------------------------------------------

          Text(
            effectiveHashRateText,
            textAlign:
                TextAlign.center,
            style:
                const TextStyle(
              color:
                  goldColor,
              fontSize:
                  13,
              fontWeight:
                  FontWeight.w700,
            ),
          ),

          const SizedBox(
            height: 6,
          ),

          // ----------------------------------------------------
          // NEXT AD INFORMATION
          // ----------------------------------------------------

          Text(
            nextAdAfterBoostText,
            textAlign:
                TextAlign.center,
            style:
                TextStyle(
              color:
                  Colors.white.withValues(
                alpha: 0.50,
              ),
              fontSize:
                  11,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 📺 WATCH AD BUTTON
  // ============================================================

  Widget _buildWatchButton() {
    return SizedBox(
      width:
          double.infinity,
      child:
          OutlinedButton(
        onPressed:
            canUse
                ? onPressed
                : null,
        style:
            OutlinedButton.styleFrom(
          foregroundColor:
              pinkColor,
          disabledForegroundColor:
              Colors.white.withValues(
            alpha: 0.35,
          ),
          side:
              BorderSide(
            color:
                canUse
                    ? pinkColor
                    : pinkColor.withValues(
                        alpha: 0.25,
                      ),
          ),
          padding:
              const EdgeInsets.symmetric(
            vertical: 15,
            horizontal: 12,
          ),
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              16,
            ),
          ),
        ),
        child:
            Row(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            const Text(
              '📺',
              style:
                  TextStyle(
                fontSize:
                    16,
              ),
            ),

            const SizedBox(
              width: 8,
            ),

            Flexible(
              child:
                  Text(
                watchAdText,
                textAlign:
                    TextAlign.center,
                maxLines:
                    2,
                overflow:
                    TextOverflow.ellipsis,
                style:
                    const TextStyle(
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}