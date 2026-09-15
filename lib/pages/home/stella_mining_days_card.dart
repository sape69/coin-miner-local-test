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
  // 🐱 CURRENT LABEL
  // ============================================================

  String _currentLabel(
    String language,
  ) {
    switch (language) {
      case 'fi':
        return 'LOUHITAAN NYT';

      case 'de':
        return 'JETZT MINING';

      case 'es':
        return 'MINANDO AHORA';

      case 'fr':
        return 'MINAGE EN COURS';

      case 'zh':
        return '正在挖矿';

      case 'vi':
        return 'ĐANG ĐÀO';

      case 'ja':
        return '現在マイニング中';

      case 'en':
      default:
        return 'MINING NOW';
    }
  }

  // ============================================================
  // 🔢 CURRENT DAY
  // ============================================================

  int _getCurrentDay() {
    if (dailyStreak <= 0) {
      return 1;
    }

    return dailyStreak.clamp(
      1,
      rates.length,
    );
  }

  // ============================================================
  // 🐾 DAY CHIP
  // ============================================================

  Widget _buildDayChip({
    required int day,
    required double rate,
    required int currentDay,
  }) {
    final bool isCurrent =
        day == currentDay;

    final bool isCompleted =
        day < currentDay;

    final Color circleColor =
        isCurrent
            ? goldColor
            : isCompleted
                ? pinkColor.withValues(
                    alpha: 0.18,
                  )
                : accentColor.withValues(
                    alpha: 0.08,
                  );

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

    return Expanded(
      child: AnimatedContainer(
        duration:
            const Duration(
          milliseconds: 250,
        ),
        margin:
            const EdgeInsets.symmetric(
          horizontal: 2,
        ),
        padding:
            const EdgeInsets.symmetric(
          vertical: 7,
        ),
        decoration:
            BoxDecoration(
          color:
              isCurrent
                  ? accentColor.withValues(
                      alpha: 0.13,
                    )
                  : backgroundColor.withValues(
                      alpha: 0.30,
                    ),
          borderRadius:
              BorderRadius.circular(
            12,
          ),
          border:
              Border.all(
            color:
                borderColor,
            width:
                isCurrent ? 1.4 : 1,
          ),
          boxShadow:
              isCurrent
                  ? [
                      BoxShadow(
                        color:
                            goldColor.withValues(
                          alpha: 0.12,
                        ),
                        blurRadius:
                            8,
                      ),
                    ]
                  : null,
        ),
        child:
            Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            // ==================================================
            // DAY NUMBER
            // ==================================================

            Container(
              width:
                  28,
              height:
                  28,
              decoration:
                  BoxDecoration(
                shape:
                    BoxShape.circle,
                color:
                    circleColor,
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
              height:
                  4,
            ),

            // ==================================================
            // HASH RATE
            // ==================================================

            Text(
              rate.toStringAsFixed(1),
              style:
                  TextStyle(
                color:
                    isCurrent
                        ? goldColor
                        : secondaryTextColor,
                fontSize:
                    10,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height:
                  2,
            ),

            // ==================================================
            // STATUS
            // ==================================================

            if (isCurrent)
              const Text(
                '🐱',
                style:
                    TextStyle(
                  fontSize:
                      11,
                ),
              )
            else if (isCompleted)
              const Icon(
                Icons.check_rounded,
                color:
                    pinkColor,
                size:
                    12,
              )
            else
              Icon(
                Icons.lock_outline_rounded,
                color:
                    accentColor.withValues(
                  alpha:
                      0.32,
                ),
                size:
                    11,
              ),
          ],
        ),
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

    final double currentRate =
        rates[currentDay - 1];

    return Container(
      width:
          double.infinity,
      padding:
          const EdgeInsets.fromLTRB(
        12,
        11,
        12,
        10,
      ),
      decoration:
          BoxDecoration(
        color:
            cardColor.withValues(
          alpha: 0.62,
        ),
        borderRadius:
            BorderRadius.circular(
          16,
        ),
        border:
            Border.all(
          color:
              accentColor.withValues(
            alpha: 0.16,
          ),
        ),
      ),
      child:
          Column(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          // ==================================================
          // HEADER
          // ==================================================

          Row(
            children: [
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
                      accentColor.withValues(
                    alpha:
                        0.12,
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
                          15,
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
                        11.5,
                    fontWeight:
                        FontWeight.bold,
                    letterSpacing:
                        0.65,
                  ),
                ),
              ),

              const SizedBox(
                width:
                    6,
              ),

              // ==================================================
              // DAY COUNTER
              // ==================================================

              Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal:
                      7,
                  vertical:
                      4,
                ),
                decoration:
                    BoxDecoration(
                  color:
                      goldColor.withValues(
                    alpha:
                        0.09,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    8,
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
                    Text(
                  '$currentDay/7',
                  style:
                      const TextStyle(
                    color:
                        goldColor,
                    fontSize:
                        9,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(
            height:
                9,
          ),

          // ==================================================
          // 7 DAY ROW
          // ==================================================

          Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children:
                List<Widget>.generate(
              rates.length,
              (
                int index,
              ) {
                final int day =
                    index + 1;

                return _buildDayChip(
                  day:
                      day,
                  rate:
                      rates[index],
                  currentDay:
                      currentDay,
                );
              },
            ),
          ),

          const SizedBox(
            height:
                8,
          ),

          // ==================================================
          // CURRENT DAY SUMMARY
          // ==================================================

          Container(
            width:
                double.infinity,
            padding:
                const EdgeInsets.symmetric(
              horizontal:
                  9,
              vertical:
                  7,
            ),
            decoration:
                BoxDecoration(
              gradient:
                  LinearGradient(
                colors: [
                  goldColor.withValues(
                    alpha:
                        0.08,
                  ),
                  accentColor.withValues(
                    alpha:
                        0.05,
                  ),
                ],
              ),
              borderRadius:
                  BorderRadius.circular(
                10,
              ),
              border:
                  Border.all(
                color:
                    goldColor.withValues(
                  alpha:
                      0.16,
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
                        15,
                  ),
                ),

                const SizedBox(
                  width:
                      6,
                ),

                Expanded(
                  child:
                      Text(
                    '${_currentLabel(language)} · DAY $currentDay',
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
                      letterSpacing:
                          0.25,
                    ),
                  ),
                ),

                const SizedBox(
                  width:
                      6,
                ),

                Text(
                  '${currentRate.toStringAsFixed(4)} HR',
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
      ),
    );
  }
}