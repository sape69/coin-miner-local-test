import 'package:flutter/material.dart';

// ============================================================
// 🐱 STELLURIINI STELLA MINING DAYS CARD
// ============================================================

class StellaMiningDaysCard extends StatelessWidget {
  // ============================================================
  // 🌍 LANGUAGE
  // ============================================================

  final String languageCode;

  // ============================================================
  // 🎁 DAILY STREAK
  // ============================================================

  final int dailyStreak;

  // ============================================================
  // 🎨 STELLA COLORS
  // ============================================================

  static const Color backgroundColor =
      Color(0xFF120B24);

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

  const StellaMiningDaysCard({
    super.key,
    required this.languageCode,
    required this.dailyStreak,
  });

  // ============================================================
  // 🌍 NORMALIZE LANGUAGE
  // ============================================================

  String _getLanguageCode() {
    final String normalizedCode =
        languageCode
            .trim()
            .toLowerCase()
            .split('-')
            .first;

    switch (normalizedCode) {
      case 'fi':
      case 'en':
      case 'de':
      case 'es':
      case 'fr':
      case 'zh':
      case 'vi':
      case 'ja':
        return normalizedCode;

      default:
        return 'en';
    }
  }

  // ============================================================
  // LOCALIZED DAY
  // ============================================================

  String _dayText(
    String language,
    int day,
  ) {
    switch (language) {
      case 'fi':
        return 'PÄIVÄ $day';

      case 'de':
        return 'TAG $day';

      case 'es':
        return 'DÍA $day';

      case 'fr':
        return 'JOUR $day';

      case 'zh':
        return '第 $day 天';

      case 'vi':
        return 'NGÀY $day';

      case 'ja':
        return 'DAY $day';

      case 'en':
      default:
        return 'DAY $day';
    }
  }

  // ============================================================
  // LOCALIZED CURRENT DAY
  // ============================================================

  String _currentDayText(
    String language,
    int day,
  ) {
    switch (language) {
      case 'fi':
        return 'NYKYINEN PÄIVÄ: $day / 7';

      case 'de':
        return 'AKTUELLER TAG: $day / 7';

      case 'es':
        return 'DÍA ACTUAL: $day / 7';

      case 'fr':
        return 'JOUR ACTUEL : $day / 7';

      case 'zh':
        return '当前天数：$day / 7';

      case 'vi':
        return 'NGÀY HIỆN TẠI: $day / 7';

      case 'ja':
        return '現在の日: $day / 7';

      case 'en':
      default:
        return 'CURRENT DAY: $day / 7';
    }
  }

  // ============================================================
  // LOCALIZED TITLE
  // ============================================================

  String _miningDaysTitle(
    String language,
  ) {
    switch (language) {
      case 'fi':
        return 'STELLAN LOUHINTAPÄIVÄT';

      case 'de':
        return 'STELLAS MINING-TAGE';

      case 'es':
        return 'DÍAS DE MINERÍA DE STELLA';

      case 'fr':
        return 'JOURS DE MINAGE DE STELLA';

      case 'zh':
        return 'STELLA 挖矿天数';

      case 'vi':
        return 'NGÀY ĐÀO CỦA STELLA';

      case 'ja':
        return 'STELLA MINING DAYS';

      case 'en':
      default:
        return 'STELLA MINING DAYS';
    }
  }

  // ============================================================
  // LOCALIZED DAY INDICATOR
  // ============================================================

  String _dayIndicator(
    String language,
    int currentDay,
  ) {
    switch (language) {
      case 'fi':
        return 'PÄIVÄ $currentDay / 7';

      case 'de':
        return 'TAG $currentDay / 7';

      case 'es':
        return 'DÍA $currentDay / 7';

      case 'fr':
        return 'JOUR $currentDay / 7';

      case 'zh':
        return '第 $currentDay / 7 天';

      case 'vi':
        return 'NGÀY $currentDay / 7';

      case 'ja':
        return 'DAY $currentDay / 7';

      case 'en':
      default:
        return 'DAY $currentDay / 7';
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    // ----------------------------------------------------------
    // Stella's 7 daily HR levels
    // ----------------------------------------------------------

    const List<double> rates = [
      0.5,
      1.0,
      1.5,
      2.0,
      2.5,
      3.0,
      3.5,
    ];

    final String language =
        _getLanguageCode();

    final int currentDay =
        dailyStreak <= 0
            ? 1
            : dailyStreak
                .clamp(
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
                fontSize: 16,
              ),
            ),

            const SizedBox(
              width: 7,
            ),

            Expanded(
              child: Text(
                _miningDaysTitle(
                  language,
                ),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight:
                      FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
            ),

            Text(
              _dayIndicator(
                language,
                currentDay,
              ),
              style: const TextStyle(
                color: goldColor,
                fontSize: 10,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ],
        ),

        const SizedBox(
          height: 9,
        ),

        // ======================================================
        // DAY 1–7 GRID
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
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 2.55,
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
                milliseconds: 200,
              ),

              padding:
                  const EdgeInsets.symmetric(
                horizontal: 9,
                vertical: 6,
              ),

              decoration:
                  BoxDecoration(
                color:
                    isCurrentDay
                        ? accentColor.withValues(
                            alpha: 0.20,
                          )
                        : isCompletedDay
                            ? pinkColor.withValues(
                                alpha: 0.07,
                              )
                            : backgroundColor.withValues(
                                alpha: 0.42,
                              ),

                borderRadius:
                    BorderRadius.circular(
                  11,
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
                                  alpha: 0.20,
                                )
                              : accentColor.withValues(
                                  alpha: 0.10,
                                ),

                  width:
                      isCurrentDay
                          ? 1.5
                          : 1,
                ),
              ),

              child:
                  Row(
                children: [
                  // --------------------------------------------
                  // DAY NUMBER
                  // --------------------------------------------

                  Container(
                    width: 27,
                    height: 27,
                    decoration:
                        BoxDecoration(
                      shape:
                          BoxShape.circle,

                      color:
                          isCurrentDay
                              ? goldColor
                              : isCompletedDay
                                  ? pinkColor.withValues(
                                      alpha: 0.16,
                                    )
                                  : accentColor.withValues(
                                      alpha: 0.09,
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
                          fontSize: 11,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(
                    width: 7,
                  ),

                  // --------------------------------------------
                  // DAY + HR
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
                          _dayText(
                            language,
                            day,
                          ),
                          maxLines: 1,
                          overflow:
                              TextOverflow.ellipsis,
                          style:
                              TextStyle(
                            color:
                                isCurrentDay
                                    ? goldColor
                                    : secondaryTextColor,
                            fontSize: 8,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),

                        const SizedBox(
                          height: 1,
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
                            fontSize: 11,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // --------------------------------------------
                  // STATUS
                  // --------------------------------------------

                  if (isCurrentDay)
                    const Text(
                      '🐱',
                      style:
                          TextStyle(
                        fontSize: 13,
                      ),
                    )
                  else if (isCompletedDay)
                    const Icon(
                      Icons.check_circle_rounded,
                      color: pinkColor,
                      size: 14,
                    ),
                ],
              ),
            );
          },
        ),

        const SizedBox(
          height: 9,
        ),

        // ======================================================
        // CURRENT DAY
        // ======================================================

        Container(
          width:
              double.infinity,

          padding:
              const EdgeInsets.symmetric(
            horizontal: 11,
            vertical: 8,
          ),

          decoration:
              BoxDecoration(
            color:
                goldColor.withValues(
              alpha: 0.07,
            ),

            borderRadius:
                BorderRadius.circular(
              11,
            ),

            border:
                Border.all(
              color:
                  goldColor.withValues(
                alpha: 0.18,
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
                  fontSize: 17,
                ),
              ),

              const SizedBox(
                width: 7,
              ),

              Expanded(
                child:
                    Text(
                  _currentDayText(
                    language,
                    currentDay,
                  ),
                  style:
                      const TextStyle(
                    color:
                        Colors.white,
                    fontSize:
                        10,
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
                      11,
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
}