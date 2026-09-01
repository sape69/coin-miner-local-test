import 'package:flutter/material.dart';

const Color backgroundColor = Color(0xFF0B1112);
const Color cardColor = Color(0xFF151B1C);
const Color accentColor = Color(0xFF35D0A0);

class DailyRewardCard extends StatelessWidget {
  final String title;
  final String rewardText;
  final String streakText;

  final bool dailyLoading;
  final bool dailyAdLoading;
  final bool dailyClaimed;
  final bool adReady;

  final VoidCallback? onPressed;

  const DailyRewardCard({
    super.key,
    required this.title,
    required this.rewardText,
    required this.streakText,
    required this.dailyLoading,
    required this.dailyAdLoading,
    required this.dailyClaimed,
    required this.adReady,
    required this.onPressed,
  });

  String get _buttonText {
    if (dailyClaimed) {
      return '✓ CLAIMED';
    }

    if (dailyLoading) {
      return 'CLAIMING...';
    }

    if (dailyAdLoading) {
      return 'LOADING AD...';
    }

    if (!adReady) {
      return 'LOADING AD...';
    }

    return 'WATCH AD & CLAIM';
  }

  IconData get _buttonIcon {
    if (dailyClaimed) {
      return Icons.check_circle;
    }

    if (dailyLoading || dailyAdLoading || !adReady) {
      return Icons.hourglass_top;
    }

    return Icons.play_circle_fill;
  }

  @override
  Widget build(BuildContext context) {
    final isDisabled =
        dailyClaimed ||
        dailyLoading ||
        dailyAdLoading ||
        !adReady ||
        onPressed == null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.20),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.20),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ==================================================
          // HEADER
          // ==================================================

          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(
                  child: Text(
                    '🎁',
                    style: TextStyle(
                      fontSize: 25,
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
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // ==================================================
          // REWARD
          // ==================================================

          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.stars_rounded,
                  color: accentColor,
                  size: 26,
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: Text(
                    rewardText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ==================================================
          // STREAK
          // ==================================================

          Row(
            children: [
              const Icon(
                Icons.local_fire_department,
                color: Colors.orange,
                size: 22,
              ),

              const SizedBox(width: 8),

              Expanded(
                child: Text(
                  streakText,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // ==================================================
          // BUTTON
          // ==================================================

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: isDisabled ? null : onPressed,
              icon: dailyLoading || dailyAdLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Icon(
                      _buttonIcon,
                      size: 22,
                    ),
              label: Text(
                _buttonText,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: backgroundColor,
                disabledBackgroundColor:
                    Colors.grey.withValues(alpha: 0.25),
                disabledForegroundColor:
                    Colors.white.withValues(alpha: 0.45),
                elevation: isDisabled ? 0 : 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),

          // ==================================================
          // CLAIMED MESSAGE
          // ==================================================

          if (dailyClaimed) ...[
            const SizedBox(height: 12),

            Center(
              child: Text(
                'Come back tomorrow for your next reward! 🐱',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: accentColor.withValues(alpha: 0.80),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}