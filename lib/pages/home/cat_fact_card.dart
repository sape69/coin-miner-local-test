import 'package:flutter/material.dart';

// ============================================================
// 🐱 STELLURIINI / STELLA CAT FACT CARD
// ============================================================
//
// Päivittäinen kissafakta Stelluriini-sovelluksessa.
//
// Lokalisaatio hoidetaan HomePagessa.
// Tämä widget vastaanottaa valmiin title + fact -tekstin.
//
// Widget:
// - toimii kaikilla 8 tuetulla kielellä
// - ei sisällä käännöslogiikkaa
// - käyttää Stelluriinin violetti/pinkki-teemaa
// - mukautuu pitkiin käännöksiin
// - toimii pienillä Android-näytöillä
// ============================================================

// ============================================================
// 🎨 STELLURIINI COLORS
// ============================================================

const Color catFactBackgroundColor =
    Color(0xFF120B24);

const Color catFactCardColor =
    Color(0xFF21113B);

const Color catFactPurple =
    Color(0xFFB58CFF);

const Color catFactPink =
    Color(0xFFFFB7E8);

const Color catFactGold =
    Color(0xFFFFD166);

// ============================================================
// 🐱 STELLA CAT FACT CARD
// ============================================================

class CatFactCard extends StatelessWidget {
  final String title;
  final String fact;

  const CatFactCard({
    super.key,
    required this.title,
    required this.fact,
  });

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Container(
      width:
          double.infinity,
      padding:
          const EdgeInsets.all(20),
      decoration:
          BoxDecoration(
        color:
            catFactCardColor,
        borderRadius:
            BorderRadius.circular(24),
        border:
            Border.all(
          color:
              catFactPurple.withValues(
            alpha: 0.30,
          ),
          width:
              1.2,
        ),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withValues(
              alpha: 0.28,
            ),
            blurRadius:
                18,
            offset:
                const Offset(
              0,
              8,
            ),
          ),
        ],
      ),
      child:
          Column(
        crossAxisAlignment:
            CrossAxisAlignment.stretch,
        children: [
          // ====================================================
          // 🐱 HEADER
          // ====================================================

          Row(
            crossAxisAlignment:
                CrossAxisAlignment.center,
            children: [
              // ------------------------------------------------
              // STELLA ICON
              // ------------------------------------------------

              Container(
                width:
                    56,
                height:
                    56,
                decoration:
                    BoxDecoration(
                  gradient:
                      LinearGradient(
                    begin:
                        Alignment.topLeft,
                    end:
                        Alignment.bottomRight,
                    colors: [
                      catFactPurple.withValues(
                        alpha: 0.24,
                      ),
                      catFactPink.withValues(
                        alpha: 0.12,
                      ),
                    ],
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    18,
                  ),
                  border:
                      Border.all(
                    color:
                        catFactPink.withValues(
                      alpha: 0.25,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color:
                          catFactPurple.withValues(
                        alpha: 0.12,
                      ),
                      blurRadius:
                          12,
                      offset:
                          const Offset(
                        0,
                        4,
                      ),
                    ),
                  ],
                ),
                child:
                    const Center(
                  child:
                      Text(
                    '🐱',
                    style:
                        TextStyle(
                      fontSize:
                          30,
                    ),
                  ),
                ),
              ),

              const SizedBox(
                width: 14,
              ),

              // ------------------------------------------------
              // TITLE
              // ------------------------------------------------

              Expanded(
                child:
                    Text(
                  title,
                  maxLines:
                      3,
                  overflow:
                      TextOverflow.ellipsis,
                  style:
                      const TextStyle(
                    color:
                        Colors.white,
                    fontSize:
                        19,
                    height:
                        1.2,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
              ),

              const SizedBox(
                width: 8,
              ),

              // ------------------------------------------------
              // PAW
              // ------------------------------------------------

              const Text(
                '🐾',
                style:
                    TextStyle(
                  fontSize:
                      24,
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 18,
          ),

          // ====================================================
          // ✨ DIVIDER
          // ====================================================

          Container(
            height:
                1,
            decoration:
                BoxDecoration(
              gradient:
                  LinearGradient(
                colors: [
                  Colors.transparent,
                  catFactPurple.withValues(
                    alpha: 0.35,
                  ),
                  catFactPink.withValues(
                    alpha: 0.35,
                  ),
                  Colors.transparent,
                ],
              ),
            ),
          ),

          const SizedBox(
            height: 18,
          ),

          // ====================================================
          // 💬 FACT BUBBLE
          // ====================================================

          Container(
            width:
                double.infinity,
            padding:
                const EdgeInsets.fromLTRB(
              18,
              20,
              18,
              20,
            ),
            decoration:
                BoxDecoration(
              color:
                  catFactBackgroundColor.withValues(
                alpha: 0.72,
              ),
              borderRadius:
                  BorderRadius.circular(
                20,
              ),
              border:
                  Border.all(
                color:
                    catFactPurple.withValues(
                  alpha: 0.18,
                ),
              ),
            ),
            child:
                Column(
              children: [
                // ------------------------------------------------
                // SPEECH ICON
                // ------------------------------------------------

                Container(
                  width:
                      52,
                  height:
                      52,
                  decoration:
                      BoxDecoration(
                    color:
                        catFactPurple.withValues(
                      alpha: 0.12,
                    ),
                    shape:
                        BoxShape.circle,
                    border:
                        Border.all(
                      color:
                          catFactGold.withValues(
                        alpha: 0.20,
                      ),
                    ),
                  ),
                  child:
                      const Center(
                    child:
                        Text(
                      '💬',
                      style:
                          TextStyle(
                        fontSize:
                            27,
                      ),
                    ),
                  ),
                ),

                const SizedBox(
                  height: 14,
                ),

                // ------------------------------------------------
                // DAILY FACT
                // ------------------------------------------------

                Text(
                  fact,
                  textAlign:
                      TextAlign.center,
                  style:
                      TextStyle(
                    color:
                        Colors.white.withValues(
                      alpha: 0.88,
                    ),
                    fontSize:
                        16,
                    height:
                        1.55,
                    fontWeight:
                        FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(
            height: 16,
          ),

          // ====================================================
          // 🐾 STELLA SIGNATURE
          // ====================================================

          Row(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              Text(
                '🐾',
                style:
                    TextStyle(
                  fontSize:
                      17,
                  color:
                      catFactPink.withValues(
                    alpha: 0.90,
                  ),
                ),
              ),

              const SizedBox(
                width: 7,
              ),

              Flexible(
                child:
                    Text(
                  'STELLA • STELLURIINI',
                  textAlign:
                      TextAlign.center,
                  overflow:
                      TextOverflow.ellipsis,
                  style:
                      TextStyle(
                    color:
                        catFactPink.withValues(
                      alpha: 0.90,
                    ),
                    fontSize:
                        12,
                    letterSpacing:
                        0.8,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
              ),

              const SizedBox(
                width: 7,
              ),

              Text(
                '🐾',
                style:
                    TextStyle(
                  fontSize:
                      17,
                  color:
                      catFactPink.withValues(
                    alpha: 0.90,
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