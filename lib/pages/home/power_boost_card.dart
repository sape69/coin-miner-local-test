import 'package:flutter/material.dart';

import '../../localization.dart';

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

  static const Color cardColor = Color(0xFF21113B);
  static const Color pinkColor = Color(0xFFFFB7E8);
  static const Color goldColor = Color(0xFFFFD166);
  static const Color secondaryTextColor = Color(0xFFBFAEDB);

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

  // ==========================================================
  // LOCALIZATION
  // ==========================================================

  String _t(
    BuildContext context,
    String key,
  ) {
    return AppLocalizations.of(context).get(key);
  }

  // ==========================================================
  // LOCALIZED TITLE
  // ==========================================================

  String _localizedTitle(
    BuildContext context,
  ) {
    final localized =
        _t(context, 'powerBoost');

    // Fallback for safety if the localization key
    // is missing from a language.
    if (localized.isEmpty ||
        localized == 'powerBoost') {
      return title;
    }

    return localized;
  }

  // ==========================================================
  // LOCALIZED ACTIVE TITLE
  // ==========================================================

  String _localizedActiveTitle(
    BuildContext context,
  ) {
    final localized =
        _t(context, 'powerBoostActiveTitle');

    // Fallback for safety if the localization key
    // is missing from a language.
    if (localized.isEmpty ||
        localized == 'powerBoostActiveTitle') {
      return activeTitle;
    }

    return localized;
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: boostActive
              ? goldColor.withValues(alpha: 0.40)
              : pinkColor.withValues(alpha: 0.30),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                boostActive ? '⚡' : '📺',
                style: const TextStyle(
                  fontSize: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      _localizedTitle(context),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      boostActive
                          ? activeText
                          : subtitle,
                      style: const TextStyle(
                        color: secondaryTextColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          if (boostActive)
            _buildActiveBoost(context)
          else
            _buildWatchButton(),

          const SizedBox(height: 10),

          Text(
            adsTodayText,
            style: const TextStyle(
              color: Color(0xFF8D7BA8),
              fontSize: 11,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            maxBoostsInfoText,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF6F5C84),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // ACTIVE BOOST
  // ==========================================================

  Widget _buildActiveBoost(
    BuildContext context,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: goldColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: goldColor.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        children: [
          Text(
            _localizedActiveTitle(context),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: goldColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),

          const SizedBox(height: 7),

          Text(
            remainingText,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            hashRateBonusText,
            style: const TextStyle(
              color: pinkColor,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            effectiveHashRateText,
            style: const TextStyle(
              color: goldColor,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            nextAdAfterBoostText,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(
                alpha: 0.50,
              ),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // WATCH BUTTON
  // ==========================================================

  Widget _buildWatchButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: canUse ? onPressed : null,
        style: OutlinedButton.styleFrom(
          foregroundColor: pinkColor,
          disabledForegroundColor:
              Colors.white.withValues(alpha: 0.35),
          side: const BorderSide(
            color: pinkColor,
          ),
          padding: const EdgeInsets.symmetric(
            vertical: 15,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          watchAdText,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}