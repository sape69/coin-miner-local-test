import 'package:flutter/material.dart';

import 'mining_progress_card.dart';

// ============================================================
// 🐱 STELLURIINI STELLA MINING CARD
// ============================================================

class StellaMiningCard extends StatelessWidget {
  final double unclaimedMining;
  final String miningTitle;
  final String miningSubtitle;
  final String timerText;
  final String timerLabel;
  final Animation<double> catAnimation;

  // ============================================================
  // ⛏️ MINING PROGRESS
  // ============================================================

  final bool miningActive;
  final int miningRemainingMs;
  final int miningDurationMs;

  final String miningProgressTitle;
  final String stlPerHourText;
  final String dailyHashRateText;
  final String dailyHashRateDayText;

  // ============================================================
  // 🎁 DAILY STREAK
  // ============================================================

  final int dailyStreak;

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
  // CONSTRUCTOR
  // ============================================================

  const StellaMiningCard({
    super.key,
    required this.unclaimedMining,
    required this.miningTitle,
    required this.miningSubtitle,
    required this.timerText,
    required this.timerLabel,
    required this.catAnimation,
    required this.miningActive,
    required this.miningRemainingMs,
    required this.miningDurationMs,
    required this.miningProgressTitle,
    required this.stlPerHourText,
    required this.dailyHashRateText,
    required this.dailyHashRateDayText,
    required this.dailyStreak,
  });

  // ============================================================
  // FORMAT STL
  // ============================================================

  String _formatStl(
    double value,
  ) {
    return value.toStringAsFixed(4);
  }

  // ============================================================
  // BUILD HR DAY GRID
  // ============================================================

  Widget _buildHrDayGrid() {
    // ----------------------------------------------------------
    // Stella's 7 daily HR levels.
    //
    // Day 1 = 0.5000 HR
    // Day 2 = 1.0000 HR
    // Day 3 = 1.5000 HR
    // Day 4 = 2.0000 HR
    // Day 5 = 2.5000 HR
    // Day 6 = 3.0000 HR
    // Day 7 = 3.5000 HR
    //
    // Day 8 onward remains at Day 7 / 3.5000 HR.
    // ----------------------------------------------------------

    final List<double> rates = [
      0.5,
      1.0,
      1.5,
      2.0,
      2.5,
      3.0,
      3.5,
    ];

    // ----------------------------------------------------------
    // Current streak is supplied directly by HomePage.
    //
    // 0 means the user has not started a streak yet.
    // We show Day 1 as the starting/current level.
    // ----------------------------------------------------------

    final int currentDay =
        dailyStreak <= 0
            ? 1
            : dailyStreak.clamp(
                1,
                7,
              );

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.stretch,
      children: [
        // ======================================================
        // TITLE
        // ======================================================

        Row(
          children: [
            const Text(
              '🐾',
              style: TextStyle(
                fontSize: 18,
              ),
            ),
            const SizedBox(
              width: 8,
            ),
            const Expanded(
              child: Text(
                'STELLA MINING DAYS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),
            Text(
              'DAY $currentDay / 7',
              style: const TextStyle(
                color: goldColor,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),

        const SizedBox(
          height: 12,
        ),

        // ======================================================
        // DAY GRID
        // ======================================================

        GridView.builder(
          shrinkWrap: true,
          physics:
              const NeverScrollableScrollPhysics(),
          itemCount:
              rates.length,
          gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2.15,
          ),
          itemBuilder: (
            BuildContext context,
            int index,
          ) {
            final int day =
                index + 1;

            final double rate =
                rates[index];

            final bool isCurrentDay =
                day == currentDay;

            final bool isCompletedDay =
                day < currentDay;

            return AnimatedContainer(
              duration:
                  const Duration(
                milliseconds: 250,
              ),
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              decoration:
                  BoxDecoration(
                color:
                    isCurrentDay
                        ? accentColor.withValues(
                            alpha: 0.22,
                          )
                        : isCompletedDay
                            ? pinkColor.withValues(
                                alpha: 0.08,
                              )
                            : backgroundColor.withValues(
                                alpha: 0.45,
                              ),
                borderRadius:
                    BorderRadius.circular(
                  14,
                ),
                border:
                    Border.all(
                  color:
                      isCurrentDay
                          ? goldColor.withValues(
                              alpha: 0.85,
                            )
                          : isCompletedDay
                              ? pinkColor.withValues(
                                  alpha: 0.25,
                                )
                              : accentColor.withValues(
                                  alpha: 0.12,
                                ),
                  width:
                      isCurrentDay
                          ? 2
                          : 1,
                ),
                boxShadow:
                    isCurrentDay
                        ? [
                            BoxShadow(
                              color:
                                  goldColor.withValues(
                                alpha: 0.12,
                              ),
                              blurRadius: 10,
                            ),
                          ]
                        : null,
              ),
              child:
                  Row(
                children: [
                  // --------------------------------------------
                  // DAY NUMBER
                  // --------------------------------------------

                  Container(
                    width: 32,
                    height: 32,
                    decoration:
                        BoxDecoration(
                      shape:
                          BoxShape.circle,
                      color:
                          isCurrentDay
                              ? goldColor
                              : isCompletedDay
                                  ? pinkColor.withValues(
                                      alpha: 0.18,
                                    )
                                  : accentColor.withValues(
                                      alpha: 0.10,
                                    ),
                    ),
                    child:
                        Center(
                      child:
                          Text(
                        '$day',
                        style:
                            TextStyle(
                          color:
                              isCurrentDay
                                  ? backgroundColor
                                  : Colors.white,
                          fontSize: 12,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(
                    width: 9,
                  ),

                  // --------------------------------------------
                  // HR VALUE
                  // --------------------------------------------

                  Expanded(
                    child:
                        Column(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DAY $day',
                          maxLines: 1,
                          overflow:
                              TextOverflow.ellipsis,
                          style:
                              TextStyle(
                            color:
                                isCurrentDay
                                    ? goldColor
                                    : secondaryTextColor,
                            fontSize: 9,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                        const SizedBox(
                          height: 2,
                        ),
                        Text(
                          '${rate.toStringAsFixed(4)} HR',
                          maxLines: 1,
                          overflow:
                              TextOverflow.ellipsis,
                          style:
                              TextStyle(
                            color:
                                isCurrentDay
                                    ? Colors.white
                                    : Colors.white70,
                            fontSize: 13,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // --------------------------------------------
                  // CURRENT / COMPLETED INDICATOR
                  // --------------------------------------------

                  if (isCurrentDay)
                    const Text(
                      '🐱',
                      style:
                          TextStyle(
                        fontSize: 16,
                      ),
                    )
                  else if (isCompletedDay)
                    const Icon(
                      Icons.check_circle_rounded,
                      color: pinkColor,
                      size: 16,
                    ),
                ],
              ),
            );
          },
        ),

        const SizedBox(
          height: 12,
        ),

        // ======================================================
        // CURRENT DAY INFORMATION
        // ======================================================

        Container(
          width:
              double.infinity,
          padding:
              const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 11,
          ),
          decoration:
              BoxDecoration(
            color:
                goldColor.withValues(
              alpha: 0.08,
            ),
            borderRadius:
                BorderRadius.circular(
              14,
            ),
            border:
                Border.all(
              color:
                  goldColor.withValues(
                alpha: 0.22,
              ),
            ),
          ),
          child:
              Row(
            children: [
              const Text(
                '🐱',
                style:
                    TextStyle(
                  fontSize: 20,
                ),
              ),
              const SizedBox(
                width: 9,
              ),
              Expanded(
                child:
                    Text(
                  'CURRENT DAY: $currentDay / 7',
                  style:
                      const TextStyle(
                    color:
                        Colors.white,
                    fontSize:
                        12,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
              Text(
                '${rates[currentDay - 1].toStringAsFixed(4)} HR',
                style:
                    const TextStyle(
                  color:
                      goldColor,
                  fontSize:
                      13,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding:
          const EdgeInsets.all(24),
      decoration:
          BoxDecoration(
        borderRadius:
            BorderRadius.circular(30),
        gradient:
            const LinearGradient(
          begin:
              Alignment.topLeft,
          end:
              Alignment.bottomRight,
          colors: [
            Color(0xFF2D174D),
            Color(0xFF1B1033),
          ],
        ),
        border:
            Border.all(
          color:
              accentColor.withValues(
            alpha: 0.40,
          ),
        ),
        boxShadow:
            const [
          BoxShadow(
            color:
                Color(0x55000000),
            blurRadius:
                25,
            offset:
                Offset(0, 10),
          ),
        ],
      ),
      child:
          Column(
        children: [
          // ====================================================
          // 🐱 STELLA
          // ====================================================

          AnimatedBuilder(
            animation:
                catAnimation,
            builder: (
              context,
              child,
            ) {
              return Transform.translate(
                offset:
                    Offset(
                  0,
                  -catAnimation.value,
                ),
                child:
                    child,
              );
            },
            child:
                Container(
              width:
                  110,
              height:
                  110,
              decoration:
                  BoxDecoration(
                shape:
                    BoxShape.circle,
                color:
                    accentColor.withValues(
                  alpha: 0.15,
                ),
                border:
                    Border.all(
                  color:
                      accentColor.withValues(
                    alpha: 0.10,
                  ),
                ),
              ),
              child:
                  const Center(
                child:
                    Text(
                  '🐱⛏️',
                  style:
                      TextStyle(
                    fontSize:
                        55,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(
            height: 18,
          ),

          // ====================================================
          // MINING TITLE
          // ====================================================

          Text(
            miningTitle,
            textAlign:
                TextAlign.center,
            style:
                const TextStyle(
              color:
                  Colors.white,
              fontSize:
                  20,
              fontWeight:
                  FontWeight.bold,
              letterSpacing:
                  1,
            ),
          ),

          const SizedBox(
            height: 8,
          ),

          // ====================================================
          // MINING SUBTITLE
          // ====================================================

          Text(
            miningSubtitle,
            textAlign:
                TextAlign.center,
            style:
                const TextStyle(
              color:
                  secondaryTextColor,
              fontSize:
                  14,
            ),
          ),

          const SizedBox(
            height: 24,
          ),

          // ====================================================
          // UNCLAIMED STL
          // ====================================================

          Text(
            _formatStl(
              unclaimedMining,
            ),
            textAlign:
                TextAlign.center,
            style:
                const TextStyle(
              color:
                  goldColor,
              fontSize:
                  38,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 4,
          ),

          const Text(
            'STL',
            style:
                TextStyle(
              color:
                  secondaryTextColor,
              letterSpacing:
                  2,
              fontSize:
                  12,
              fontWeight:
                  FontWeight.w600,
            ),
          ),

          const SizedBox(
            height: 24,
          ),

          // ====================================================
          // ⏱️ TIMER
          // ====================================================

          Container(
            width:
                double.infinity,
            padding:
                const EdgeInsets.symmetric(
              vertical: 15,
              horizontal: 20,
            ),
            decoration:
                BoxDecoration(
              color:
                  backgroundColor.withValues(
                alpha: 0.55,
              ),
              borderRadius:
                  BorderRadius.circular(
                18,
              ),
              border:
                  Border.all(
                color:
                    accentColor.withValues(
                  alpha: 0.08,
                ),
              ),
            ),
            child:
                Column(
              children: [
                Text(
                  timerText,
                  textAlign:
                      TextAlign.center,
                  style:
                      const TextStyle(
                    color:
                        Colors.white,
                    fontSize:
                        27,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                const SizedBox(
                  height: 5,
                ),
                Text(
                  timerLabel,
                  textAlign:
                      TextAlign.center,
                  style:
                      const TextStyle(
                    color:
                        secondaryTextColor,
                    fontSize:
                        11,
                    letterSpacing:
                        1.5,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(
            height: 20,
          ),

          // ====================================================
          // ⛏️ STELLA MINING DAYS
          // ====================================================

          _buildHrDayGrid(),

          const SizedBox(
            height: 20,
          ),

          // ====================================================
          // ⛏️ 24 H MINING PROGRESS
          // ====================================================

          MiningProgressCard(
            miningActive:
                miningActive,
            miningRemainingMs:
                miningRemainingMs,
            miningDurationMs:
                miningDurationMs,
            title:
                miningProgressTitle,
            stlPerHourText:
                stlPerHourText,
            dailyHashRateText:
                dailyHashRateText,
            dailyHashRateDayText:
                dailyHashRateDayText,
          ),
        ],
      ),
    );
  }
}