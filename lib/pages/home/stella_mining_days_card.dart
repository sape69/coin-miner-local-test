import 'package:flutter/material.dart';

// ============================================================
// 🐱 STELLURIINI — STELLA MINING DAYS
// ============================================================

class StellaMiningDaysCard extends StatelessWidget {
  final String languageCode;
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
  // ⛏️ DAILY HASH RATES
  // ============================================================

  static const List<double> rates = [
    0.5,
    1.0,
    1.5,
    2.0,
    2.5,
    3.0,
    3.5,
  ];

  // ============================================================
  // CONSTRUCTOR
  // ============================================================

  const StellaMiningDaysCard({
    super.key,
    required this.languageCode,
    required this.dailyStreak,
  });

  // ============================================================
  // 🌍 LANGUAGE
  // ============================================================

  String _language() {
    final String code =
        languageCode
            .trim()
            .toLowerCase()
            .split('-')
            .first;

    switch (code) {
      case 'fi':
      case 'en':
      case 'de':
      case 'es':
      case 'fr':
      case 'zh':
      case 'vi':
      case 'ja':
        return code;

      default:
        return 'en';
    }
  }

  // ============================================================
  // 📝 TITLE
  // ============================================================

  String _title(
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
  // 📅 DAY
  // ============================================================

  String _day(
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
  // 🐱 CURRENT DAY
  // ============================================================

  String _currentDay(
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
  // 🐾 CURRENT DAY LABEL
  // ============================================================

  String _currentLabel(
    String language,
  ) {
    switch (language) {
      case 'fi':
        return 'NYT LOUHITAAN';

      case 'de':
        return 'AKTUELLER MINING-TAG';

      case 'es':
        return 'MINERÍA ACTUAL';

      case 'fr':
        return 'MINAGE ACTUEL';

      case 'zh':
        return '当前挖矿';

      case 'vi':
        return 'ĐANG ĐÀO';

      case 'ja':
        return '現在のマイニング';

      case 'en':
      default:
        return 'MINING NOW';
    }
  }

  // ============================================================
  // 🐾 STATUS
  // ============================================================

  String _status(
    String language,
    int day,
    int currentDay,
  ) {
    if (day == currentDay) {
      return _currentLabel(language);
    }

    if (day < currentDay) {
      switch (language) {
        case 'fi':
          return 'VALMIS';

        case 'de':
          return 'FERTIG';

        case 'es':
          return 'COMPLETADO';

        case 'fr':
          return 'TERMINÉ';

        case 'zh':
          return '已完成';

        case 'vi':
          return 'HOÀN TẤT';

        case 'ja':
          return '完了';

        case 'en':
        default:
          return 'COMPLETED';
      }
    }

    switch (language) {
      case 'fi':
        return 'TULOSSA';

      case 'de':
        return 'KOMMT';

      case 'es':
        return 'PRÓXIMO';

      case 'fr':
        return 'À VENIR';

      case 'zh':
        return '即将开始';

      case 'vi':
        return 'SẮP TỚI';

      case 'ja':
        return 'これから';

      case 'en':
      default:
        return 'UPCOMING';
    }
  }

  // ============================================================
  // 🎯 CURRENT DAY
  // ============================================================

  int _getCurrentDay() {
    if (dailyStreak <= 0) {
      return 1;
    }

    return dailyStreak.clamp(
      1,
      7,
    );
  }

  // ============================================================
  // 🧱 DAY CARD
  // ============================================================

  Widget _buildDayCard({
    required int day,
    required double rate,
    required int currentDay,
    required String language,
  }) {
    final bool isCurrent =
        day == currentDay;

    final bool isCompleted =
        day < currentDay;

    final Color borderColor =
        isCurrent
            ? goldColor
            : isCompleted
                ? pinkColor.withValues(
                    alpha: 0.28,
                  )
                : accentColor.withValues(
                    alpha: 0.12,
                  );

    final Color cardBackground =
        isCurrent
            ? accentColor.withValues(
                alpha: 0.16,
              )
            : isCompleted
                ? pinkColor.withValues(
                    alpha: 0.055,
                  )
                : backgroundColor.withValues(
                    alpha: 0.38,
                  );

    return AnimatedContainer(
      duration:
          const Duration(
        milliseconds: 250,
      ),
      width:
          double.infinity,
      padding:
          const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 8,
      ),
      decoration:
          BoxDecoration(
        color:
            cardBackground,
        borderRadius:
            BorderRadius.circular(
          13,
        ),
        border:
            Border.all(
          color:
              borderColor,
          width:
              isCurrent
                  ? 1.5
                  : 1,
        ),
        boxShadow:
            isCurrent
                ? [
                    BoxShadow(
                      color:
                          goldColor.withValues(
                        alpha: 0.14,
                      ),
                      blurRadius:
                          12,
                      spreadRadius:
                          0,
                    ),
                  ]
                : null,
      ),
      child:
          Row(
        children: [
          // ==================================================
          // DAY CIRCLE
          // ==================================================

          Container(
            width:
                30,
            height:
                30,
            decoration:
                BoxDecoration(
              shape:
                  BoxShape.circle,
              color:
                  isCurrent
                      ? goldColor
                      : isCompleted
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
                      isCurrent
                          ? backgroundColor
                          : Colors.white,
                  fontSize:
                      11,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ),
          ),

          const SizedBox(
            width:
                8,
          ),

          // ==================================================
          // DAY TEXT
          // ==================================================

          Expanded(
            child:
                Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  _day(
                    language,
                    day,
                  ),
                  maxLines:
                      1,
                  overflow:
                      TextOverflow.ellipsis,
                  style:
                      TextStyle(
                    color:
                        isCurrent
                            ? goldColor
                            : secondaryTextColor,
                    fontSize:
                        9,
                    fontWeight:
                        FontWeight.bold,
                    letterSpacing:
                        0.25,
                  ),
                ),

                const SizedBox(
                  height:
                      2,
                ),

                Text(
                  '${rate.toStringAsFixed(4)} HR',
                  maxLines:
                      1,
                  overflow:
                      TextOverflow.ellipsis,
                  style:
                      TextStyle(
                    color:
                        isCurrent
                            ? Colors.white
                            : Colors.white70,
                    fontSize:
                        12,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(
            width:
                5,
          ),

          // ==================================================
          // STATUS ICON
          // ==================================================

          if (isCurrent)
            const Text(
              '🐱',
              style:
                  TextStyle(
                fontSize:
                    14,
              ),
            )
          else if (isCompleted)
            const Icon(
              Icons.check_circle_rounded,
              color:
                  pinkColor,
              size:
                  15,
            )
          else
            Icon(
              Icons.lock_outline_rounded,
              color:
                  accentColor.withValues(
                alpha:
                    0.35,
              ),
              size:
                  14,
            ),
        ],
      ),
    );
  }

  // ============================================================
  // 🏗️ BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final String language =
        _language();

    final int currentDay =
        _getCurrentDay();

    return Container(
      width:
          double.infinity,
      padding:
          const EdgeInsets.all(
        14,
      ),
      decoration:
          BoxDecoration(
        color:
            cardColor.withValues(
          alpha:
              0.55,
        ),
        borderRadius:
            BorderRadius.circular(
          18,
        ),
        border:
            Border.all(
          color:
              accentColor.withValues(
            alpha:
                0.16,
          ),
        ),
      ),
      child:
          Column(
        crossAxisAlignment:
            CrossAxisAlignment.stretch,
        children: [
          // ==================================================
          // HEADER
          // ==================================================

          Row(
            children: [
              Container(
                width:
                    32,
                height:
                    32,
                decoration:
                    BoxDecoration(
                  shape:
                      BoxShape.circle,
                  color:
                      accentColor.withValues(
                    alpha:
                        0.13,
                  ),
                ),
                child:
                    const Center(
                  child:
                      Text(
                    '🐾',
                    style:
                        TextStyle(
                      fontSize:
                          16,
                    ),
                  ),
                ),
              ),

              const SizedBox(
                width:
                    8,
              ),

              Expanded(
                child:
                    Text(
                  _title(
                    language,
                  ),
                  maxLines:
                      1,
                  overflow:
                      TextOverflow.ellipsis,
                  style:
                      const TextStyle(
                    color:
                        Colors.white,
                    fontSize:
                        12,
                    fontWeight:
                        FontWeight.bold,
                    letterSpacing:
                        0.8,
                  ),
                ),
              ),

              const SizedBox(
                width:
                    6,
              ),

              Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal:
                      8,
                  vertical:
                      5,
                ),
                decoration:
                    BoxDecoration(
                  color:
                      goldColor.withValues(
                    alpha:
                        0.10,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    9,
                  ),
                  border:
                      Border.all(
                    color:
                        goldColor.withValues(
                      alpha:
                          0.22,
                    ),
                  ),
                ),
                child:
                    Text(
                  '$currentDay/7',
                  style:
                      const TextStyle(
                    color:
                        goldColor,
                    fontSize:
                        10,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(
            height:
                11,
          ),

          // ==================================================
          // DAY GRID
          // ==================================================

          LayoutBuilder(
            builder: (
              BuildContext context,
              BoxConstraints constraints,
            ) {
              // ------------------------------------------------
              // Small phone screens:
              // Use one column so DAY + HR never get squeezed.
              // ------------------------------------------------

              final bool useSingleColumn =
                  constraints.maxWidth < 310;

              if (useSingleColumn) {
                return Column(
                  children:
                      List<Widget>.generate(
                    rates.length,
                    (
                      int index,
                    ) {
                      final int day =
                          index + 1;

                      return Padding(
                        padding:
                            EdgeInsets.only(
                          bottom:
                              index ==
                                      rates.length - 1
                                  ? 0
                                  : 7,
                        ),
                        child:
                            _buildDayCard(
                          day:
                              day,
                          rate:
                              rates[index],
                          currentDay:
                              currentDay,
                          language:
                              language,
                        ),
                      );
                    },
                  ),
                );
              }

              // ------------------------------------------------
              // Normal phone/tablet width:
              // Two-column layout.
              // ------------------------------------------------

              return GridView.builder(
                shrinkWrap:
                    true,
                physics:
                    const NeverScrollableScrollPhysics(),
                itemCount:
                    rates.length,
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount:
                      2,
                  crossAxisSpacing:
                      7,
                  mainAxisSpacing:
                      7,
                  childAspectRatio:
                      2.45,
                ),
                itemBuilder: (
                  BuildContext context,
                  int index,
                ) {
                  final int day =
                      index + 1;

                  return _buildDayCard(
                    day:
                        day,
                    rate:
                        rates[index],
                    currentDay:
                        currentDay,
                    language:
                        language,
                  );
                },
              );
            },
          ),

          const SizedBox(
            height:
                10,
          ),

          // ==================================================
          // CURRENT DAY INFO
          // ==================================================

          Container(
            width:
                double.infinity,
            padding:
                const EdgeInsets.symmetric(
              horizontal:
                  10,
              vertical:
                  9,
            ),
            decoration:
                BoxDecoration(
              gradient:
                  LinearGradient(
                colors: [
                  goldColor.withValues(
                    alpha:
                        0.09,
                  ),
                  accentColor.withValues(
                    alpha:
                        0.05,
                  ),
                ],
              ),
              borderRadius:
                  BorderRadius.circular(
                11,
              ),
              border:
                  Border.all(
                color:
                    goldColor.withValues(
                  alpha:
                      0.20,
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
                    fontSize:
                        17,
                  ),
                ),

                const SizedBox(
                  width:
                      7,
                ),

                Expanded(
                  child:
                      Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentDay(
                          language,
                          currentDay,
                        ),
                        maxLines:
                            1,
                        overflow:
                            TextOverflow.ellipsis,
                        style:
                            const TextStyle(
                          color:
                              Colors.white,
                          fontSize:
                              9,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(
                        height:
                            2,
                      ),

                      Text(
                        _status(
                          language,
                          currentDay,
                          currentDay,
                        ),
                        maxLines:
                            1,
                        overflow:
                            TextOverflow.ellipsis,
                        style:
                            const TextStyle(
                          color:
                              goldColor,
                          fontSize:
                              8,
                          fontWeight:
                              FontWeight.bold,
                          letterSpacing:
                              0.6,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(
                  width:
                      8,
                ),

                Text(
                  '${rates[currentDay - 1].toStringAsFixed(4)} HR',
                  maxLines:
                      1,
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}