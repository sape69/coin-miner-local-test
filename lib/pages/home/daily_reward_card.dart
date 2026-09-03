import 'package:flutter/material.dart';

// ============================================================
// COLORS
// ============================================================

const Color dailyCardColor = Color(0xFF151B1C);
const Color dailyAccentColor = Color(0xFF35D0A0);

// ============================================================
// DAILY HASH RATE CARD
// ============================================================

class DailyRewardCard extends StatelessWidget {
  final String title;
  final String rewardText;
  final String streakText;

  final bool dailyLoading;
  final bool dailyClaimed;

  final VoidCallback? onPressed;

  const DailyRewardCard({
    super.key,
    required this.title,
    required this.rewardText,
    required this.streakText,
    required this.dailyLoading,
    required this.dailyClaimed,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: dailyCardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: dailyAccentColor.withValues(
            alpha: 0.25,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: dailyAccentColor.withValues(
              alpha: 0.06,
            ),
            blurRadius: 20,
            spreadRadius: 1,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ================================================
          // HEADER
          // ================================================

          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: dailyAccentColor.withValues(
                    alpha: 0.15,
                  ),
                  border: Border.all(
                    color: dailyAccentColor.withValues(
                      alpha: 0.35,
                    ),
                  ),
                ),
                child: const Center(
                  child: Text(
                    '⚡',
                    style: TextStyle(
                      fontSize: 26,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 14),

              // ============================================
              // TITLE
              // ============================================

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
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      'Boost Stella’s mining power 🐱⛏️',
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

              // ============================================
              // CLAIMED STATUS
              // ============================================

              if (dailyClaimed)
                Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: dailyAccentColor.withValues(
                      alpha: 0.15,
                    ),
                    borderRadius:
                        BorderRadius.circular(20),
                    border: Border.all(
                      color: dailyAccentColor.withValues(
                        alpha: 0.25,
                      ),
                    ),
                  ),
                  child: const Text(
                    '✓ DONE',
                    style: TextStyle(
                      color: dailyAccentColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 20),

          // ================================================
          // HASH RATE REWARD
          // ================================================

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withValues(
                alpha: 0.18,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.white.withValues(
                  alpha: 0.06,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: dailyAccentColor.withValues(
                      alpha: 0.12,
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.bolt,
                      color: dailyAccentColor,
                      size: 26,
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
                        rewardText,
                        style: const TextStyle(
                          color: dailyAccentColor,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 3),

                      Text(
                        'Daily mining power boost',
                        style: TextStyle(
                          color: Colors.white.withValues(
                            alpha: 0.45,
                          ),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ================================================
          // STREAK
          // ================================================

          Container(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(
                alpha: 0.035,
              ),
              borderRadius:
                  BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(
                  alpha: 0.04,
                ),
              ),
            ),
            child: Row(
              children: [
                const Text(
                  '🔥',
                  style: TextStyle(
                    fontSize: 20,
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: Text(
                    streakText,
                    style: TextStyle(
                      color: Colors.white.withValues(
                        alpha: 0.75,
                      ),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // ================================================
          // CLAIM BUTTON
          // ================================================

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed:
                  dailyLoading || dailyClaimed
                      ? null
                      : onPressed,

              icon: dailyLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child:
                          CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                  : Icon(
                      dailyClaimed
                          ? Icons.check_circle
                          : Icons.bolt,
                    ),

              label: Text(
                dailyLoading
                    ? 'CLAIMING...'
                    : dailyClaimed
                        ? 'CLAIMED TODAY'
                        : 'CLAIM +1 HASH RATE',
              ),

              style: ElevatedButton.styleFrom(
                backgroundColor:
                    dailyAccentColor,

                foregroundColor:
                    Colors.black,

                disabledBackgroundColor:
                    Colors.white.withValues(
                  alpha: 0.08,
                ),

                disabledForegroundColor:
                    Colors.white.withValues(
                  alpha: 0.35,
                ),

                padding:
                    const EdgeInsets.symmetric(
                  vertical: 15,
                ),

                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(16),
                ),

                textStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ================================================
          // INFO
          // ================================================

          Row(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              Icon(
                Icons.info_outline,
                size: 14,
                color: Colors.white.withValues(
                  alpha: 0.35,
                ),
              ),

              const SizedBox(width: 6),

              Flexible(
                child: Text(
                  dailyClaimed
                      ? 'Come back tomorrow for another Hash Rate boost 🐱'
                      : 'Claim your daily bonus to increase mining power',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(
                      alpha: 0.38,
                    ),
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}