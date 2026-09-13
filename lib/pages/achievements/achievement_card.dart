import 'package:flutter/material.dart';

import 'achievement_model.dart';

// ============================================================
// 🏆 STELLURIINI ACHIEVEMENT CARD
// ============================================================

class AchievementCard extends StatelessWidget {
  final Achievement achievement;
  final int progress;
  final bool unlocked;

  const AchievementCard({
    super.key,
    required this.achievement,
    required this.progress,
    required this.unlocked,
  });

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

  // ============================================================
  // 📊 SAFE PROGRESS
  // ============================================================

  double get _progressValue {
    if (unlocked) {
      return 1.0;
    }

    if (achievement.target <= 0) {
      return 0.0;
    }

    final double value =
        progress / achievement.target;

    return value.clamp(0.0, 1.0);
  }

  int get _displayProgress {
    if (unlocked) {
      return achievement.target;
    }

    if (progress < 0) {
      return 0;
    }

    if (progress > achievement.target) {
      return achievement.target;
    }

    return progress;
  }

  // ============================================================
  // 🏆 BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 14,
      ),
      padding:
          const EdgeInsets.all(18),
      decoration:
          BoxDecoration(
        borderRadius:
            BorderRadius.circular(24),
        gradient:
            LinearGradient(
          begin:
              Alignment.topLeft,
          end:
              Alignment.bottomRight,
          colors: unlocked
              ? [
                  const Color(0xFF34204F),
                  const Color(0xFF21113B),
                ]
              : [
                  cardColor,
                  backgroundColor,
                ],
        ),
        border:
            Border.all(
          color: unlocked
              ? goldColor.withValues(
                  alpha: 0.45,
                )
              : accentColor.withValues(
                  alpha: 0.16,
                ),
        ),
        boxShadow:
            [
          BoxShadow(
            color: unlocked
                ? goldColor.withValues(
                    alpha: 0.10,
                  )
                : Colors.black.withValues(
                    alpha: 0.20,
                  ),
            blurRadius:
                unlocked ? 18 : 12,
            offset:
                const Offset(
              0,
              6,
            ),
          ),
        ],
      ),
      child:
          Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          // ====================================================
          // 🐾 TOP ROW
          // ====================================================

          Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              // ==================================================
              // ICON
              // ==================================================

              Container(
                width: 62,
                height: 62,
                decoration:
                    BoxDecoration(
                  shape:
                      BoxShape.circle,
                  color: unlocked
                      ? goldColor.withValues(
                          alpha: 0.14,
                        )
                      : accentColor.withValues(
                          alpha: 0.10,
                        ),
                  border:
                      Border.all(
                    color: unlocked
                        ? goldColor.withValues(
                            alpha: 0.35,
                          )
                        : accentColor.withValues(
                            alpha: 0.15,
                          ),
                  ),
                ),
                child:
                    Center(
                  child:
                      Text(
                    unlocked
                        ? achievement.icon
                        : '🔒',
                    style:
                        const TextStyle(
                      fontSize: 30,
                    ),
                  ),
                ),
              ),

              const SizedBox(
                width: 14,
              ),

              // ==================================================
              // TITLE + DESCRIPTION
              // ==================================================

              Expanded(
                child:
                    Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      achievement.title,
                      maxLines: 2,
                      overflow:
                          TextOverflow.ellipsis,
                      style:
                          TextStyle(
                        color: unlocked
                            ? goldColor
                            : Colors.white,
                        fontSize: 17,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(
                      height: 5,
                    ),

                    Text(
                      achievement.description,
                      style:
                          const TextStyle(
                        color:
                            secondaryTextColor,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                width: 8,
              ),

              // ==================================================
              // STATUS
              // ==================================================

              if (unlocked)
                const Icon(
                  Icons.check_circle,
                  color:
                      goldColor,
                  size: 25,
                )
              else
                Icon(
                  Icons.lock_outline,
                  color:
                      secondaryTextColor.withValues(
                    alpha: 0.65,
                  ),
                  size: 22,
                ),
            ],
          ),

          const SizedBox(
            height: 18,
          ),

          // ====================================================
          // 📊 PROGRESS
          // ====================================================

          Row(
            children: [
              Expanded(
                child:
                    ClipRRect(
                  borderRadius:
                      BorderRadius.circular(
                    20,
                  ),
                  child:
                      LinearProgressIndicator(
                    minHeight: 9,
                    value:
                        _progressValue,
                    backgroundColor:
                        Colors.white.withValues(
                      alpha: 0.08,
                    ),
                    valueColor:
                        AlwaysStoppedAnimation<
                            Color>(
                      unlocked
                          ? goldColor
                          : accentColor,
                    ),
                  ),
                ),
              ),

              const SizedBox(
                width: 10,
              ),

              Text(
                '$_displayProgress/${achievement.target}',
                style:
                    TextStyle(
                  color: unlocked
                      ? goldColor
                      : secondaryTextColor,
                  fontSize: 12,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 14,
          ),

          // ====================================================
          // 🎁 REWARD
          // ====================================================

          Row(
            children: [
              const Text(
                '🎁',
                style:
                    TextStyle(
                  fontSize: 17,
                ),
              ),

              const SizedBox(
                width: 7,
              ),

              Text(
                unlocked
                    ? 'Achievement unlocked!'
                    : 'Reward',
                style:
                    const TextStyle(
                  color:
                      secondaryTextColor,
                  fontSize: 12,
                ),
              ),

              const Spacer(),

              Text(
                '+${achievement.reward} STL',
                style:
                    TextStyle(
                  color: unlocked
                      ? goldColor
                      : pinkColor,
                  fontSize: 14,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}