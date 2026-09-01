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

    if (dailyAdLoading || !adReady) {
      return 'LOADING AD...';
    }

    return 'CLAIM REWARD';
  }

  @override
  Widget build(BuildContext context) {
    final isDisabled =
        dailyClaimed ||
        dailyLoading ||
        dailyAdLoading ||
        !adReady ||
        onPressed == null;

    final isLoading =
        dailyLoading || dailyAdLoading;

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
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
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
                const Text(
                  '✨',
                  style: TextStyle(
                    fontSize: 25,
                  ),
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

                const Text(
                  '🐾',
                  style: TextStyle(
                    fontSize: 24,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ==================================================
          // STREAK
          // ==================================================

          Row(
            children: [
              const Text(
                '🔥',
                style: TextStyle(
                  fontSize: 20,
                ),
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

          const SizedBox(height: 22),

          // ==================================================
          // CAT PAW BUTTON
          // ==================================================

          SizedBox(
            width: double.infinity,
            height: 72,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: isDisabled ? null : onPressed,
                borderRadius: BorderRadius.circular(36),
                child: Ink(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(36),
                    color: isDisabled
                        ? Colors.grey.withValues(alpha: 0.20)
                        : accentColor,
                    boxShadow: isDisabled
                        ? []
                        : [
                            BoxShadow(
                              color:
                                  accentColor.withValues(alpha: 0.30),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                  ),
                  child: Center(
                    child: isLoading
                        ? const CircularProgressIndicator(
                            color: backgroundColor,
                            strokeWidth: 3,
                          )
                        : Row(
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            children: [
                              Text(
                                dailyClaimed ? '😺' : '🐾',
                                style: const TextStyle(
                                  fontSize: 34,
                                ),
                              ),

                              const SizedBox(width: 12),

                              Text(
                                _buttonText,
                                style: TextStyle(
                                  color: isDisabled
                                      ? Colors.white.withValues(
                                          alpha: 0.45,
                                        )
                                      : backgroundColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.8,
                                ),
                              ),

                              const SizedBox(width: 12),

                              Text(
                                dailyClaimed ? '🐾' : '🐱',
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
          // CLAIMED MESSAGE
          // ==================================================

          if (dailyClaimed) ...[
            const SizedBox(height: 14),

            Center(
              child: Text(
                'Stella is happy! Come back tomorrow 🐱💚',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: accentColor.withValues(alpha: 0.85),
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