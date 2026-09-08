import 'package:flutter/material.dart';

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
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
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
        ],
      ),
    );
  }
}