import 'package:flutter/material.dart';

import 'mining_progress_card.dart';
import 'stella_mining_days_card.dart';

// ============================================================
// 🐱 STELLURIINI STELLA MINING CARD
// ============================================================
//
// Stella Mining Card.
//
// Stella käyttää aktiivisen tilan mukaista oikeaa kuvaa:
//
// 😴 stella_sleeping.png
// ⛏️ stella_mining.png
// ⚡ stella_boosting.png
//
// VAIN YKSI STELLA-KUVA NÄKYY KERRALLA.
//
// Tilajärjestys:
//
// 1. Power Boost aktiivinen
//    → stella_boosting.png
//
// 2. Louhinta aktiivinen
//    → stella_mining.png
//
// 3. Muulloin
//    → stella_sleeping.png
//
// Mukana:
// - Stellan tilakohtainen animaatio
// - Boost-animaatio
// - kultainen boost-hehku
// - kipinät
// - STL badge louhinnan aikana
// - Stella Mining Days
// - Mining Progress
//
// ============================================================

class StellaMiningCard extends StatefulWidget {
  final double unclaimedMining;
  final String miningTitle;
  final String miningSubtitle;
  final String timerText;
  final String timerLabel;
  final Animation<double> catAnimation;

  final String languageCode;

  final bool miningActive;
  final int miningRemainingMs;
  final int miningDurationMs;

  final String miningProgressTitle;
  final String stlPerHourText;
  final String dailyHashRateText;
  final String dailyHashRateDayText;

  final int dailyStreak;

  // ------------------------------------------------------------
  // ⚡ POWER BOOST
  // ------------------------------------------------------------

  final bool boostActive;

  // ------------------------------------------------------------
  // ⛏️ MINING BUTTON
  // ------------------------------------------------------------

  final Widget miningButton;

  const StellaMiningCard({
    super.key,
    required this.unclaimedMining,
    required this.miningTitle,
    required this.miningSubtitle,
    required this.timerText,
    required this.timerLabel,
    required this.catAnimation,
    required this.languageCode,
    required this.miningActive,
    required this.miningRemainingMs,
    required this.miningDurationMs,
    required this.miningProgressTitle,
    required this.stlPerHourText,
    required this.dailyHashRateText,
    required this.dailyHashRateDayText,
    required this.dailyStreak,
    required this.boostActive,
    required this.miningButton,
  });

  @override
  State<StellaMiningCard> createState() =>
      _StellaMiningCardState();
}

// ============================================================
// 🐱 STELLA MINING CARD STATE
// ============================================================

class _StellaMiningCardState
    extends State<StellaMiningCard>
    with SingleTickerProviderStateMixin {
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
  // 🖼️ STELLA IMAGE PATHS
  // ============================================================

  static const String _sleepingImage =
      'assets/images/stella_sleeping.png';

  static const String _miningImage =
      'assets/images/stella_mining.png';

  static const String _boostingImage =
      'assets/images/stella_boosting.png';

  // ============================================================
  // ⚡ POWER BOOST ANIMATION
  // ============================================================

  late final AnimationController _boostAnimationController;

  late final Animation<double> _boostScale;

  late final Animation<double> _boostRotation;

  late final Animation<double> _boostGlow;

  late final Animation<double> _boostOpacity;

  // ============================================================
  // 🚀 INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _boostAnimationController =
        AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 1100,
      ),
    );

    // ----------------------------------------------------------
    // SCALE
    // ----------------------------------------------------------

    _boostScale =
        TweenSequence<double>(
      [
        TweenSequenceItem(
          tween: Tween<double>(
            begin: 1.0,
            end: 1.18,
          ),
          weight: 25,
        ),
        TweenSequenceItem(
          tween: Tween<double>(
            begin: 1.18,
            end: 0.94,
          ),
          weight: 20,
        ),
        TweenSequenceItem(
          tween: Tween<double>(
            begin: 0.94,
            end: 1.08,
          ),
          weight: 20,
        ),
        TweenSequenceItem(
          tween: Tween<double>(
            begin: 1.08,
            end: 1.0,
          ),
          weight: 35,
        ),
      ],
    ).animate(
      CurvedAnimation(
        parent: _boostAnimationController,
        curve: Curves.easeOut,
      ),
    );

    // ----------------------------------------------------------
    // ROTATION
    // ----------------------------------------------------------

    _boostRotation =
        TweenSequence<double>(
      [
        TweenSequenceItem(
          tween: Tween<double>(
            begin: 0.0,
            end: -0.08,
          ),
          weight: 20,
        ),
        TweenSequenceItem(
          tween: Tween<double>(
            begin: -0.08,
            end: 0.08,
          ),
          weight: 25,
        ),
        TweenSequenceItem(
          tween: Tween<double>(
            begin: 0.08,
            end: -0.035,
          ),
          weight: 20,
        ),
        TweenSequenceItem(
          tween: Tween<double>(
            begin: -0.035,
            end: 0.0,
          ),
          weight: 35,
        ),
      ],
    ).animate(
      CurvedAnimation(
        parent: _boostAnimationController,
        curve: Curves.easeOut,
      ),
    );

    // ----------------------------------------------------------
    // GLOW
    // ----------------------------------------------------------

    _boostGlow =
        TweenSequence<double>(
      [
        TweenSequenceItem(
          tween: Tween<double>(
            begin: 0.0,
            end: 1.0,
          ),
          weight: 25,
        ),
        TweenSequenceItem(
          tween: Tween<double>(
            begin: 1.0,
            end: 0.35,
          ),
          weight: 30,
        ),
        TweenSequenceItem(
          tween: Tween<double>(
            begin: 0.35,
            end: 0.8,
          ),
          weight: 15,
        ),
        TweenSequenceItem(
          tween: Tween<double>(
            begin: 0.8,
            end: 0.0,
          ),
          weight: 30,
        ),
      ],
    ).animate(
      CurvedAnimation(
        parent: _boostAnimationController,
        curve: Curves.easeOut,
      ),
    );

    // ----------------------------------------------------------
    // ✨ SPARKLE OPACITY
    // ----------------------------------------------------------

    _boostOpacity =
        TweenSequence<double>(
      [
        TweenSequenceItem(
          tween: Tween<double>(
            begin: 0.0,
            end: 1.0,
          ),
          weight: 20,
        ),
        TweenSequenceItem(
          tween: Tween<double>(
            begin: 1.0,
            end: 1.0,
          ),
          weight: 25,
        ),
        TweenSequenceItem(
          tween: Tween<double>(
            begin: 1.0,
            end: 0.0,
          ),
          weight: 55,
        ),
      ],
    ).animate(
      CurvedAnimation(
        parent: _boostAnimationController,
        curve: Curves.easeOut,
      ),
    );

    // ----------------------------------------------------------
    // Jos boost on jo aktiivinen kortin avautuessa,
    // näytetään boost-animaatio kerran.
    // ----------------------------------------------------------

    if (widget.boostActive) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) {
          if (mounted) {
            _playBoostAnimation();
          }
        },
      );
    }
  }

  // ============================================================
  // 🔄 WIDGET UPDATE
  // ============================================================

  @override
  void didUpdateWidget(
    covariant StellaMiningCard oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);

    // ----------------------------------------------------------
    // Power Boost:
    //
    // false → true
    //
    // Stella vaihtuu boosting-kuvaan ja tekee
    // boost-animaation.
    // ----------------------------------------------------------

    if (!oldWidget.boostActive &&
        widget.boostActive) {
      _playBoostAnimation();
    }
  }

  // ============================================================
  // ⚡ PLAY BOOST ANIMATION
  // ============================================================

  void _playBoostAnimation() {
    if (!mounted) {
      return;
    }

    _boostAnimationController.forward(
      from: 0.0,
    );
  }

  // ============================================================
  // 🧹 DISPOSE
  // ============================================================

  @override
  void dispose() {
    _boostAnimationController.dispose();

    super.dispose();
  }

  // ============================================================
  // 🔢 FORMAT STL
  // ============================================================

  String _formatStl(
    double value,
  ) {
    return value.toStringAsFixed(4);
  }

  // ============================================================
  // 🖼️ ACTIVE STELLA IMAGE
  // ============================================================
  //
  // TÄRKEÄ:
  //
  // Tässä valitaan aina vain YKSI kuva.
  //
  // Boostilla:
  //    boosting
  //
  // Muuten louhinnassa:
  //    mining
  //
  // Muuten:
  //    sleeping
  //
  // ============================================================

  String get _activeStellaImage {
    if (widget.boostActive) {
      return _boostingImage;
    }

    if (widget.miningActive) {
      return _miningImage;
    }

    return _sleepingImage;
  }

  // ============================================================
  // 🐱 STELLA IMAGE
  // ============================================================

  Widget _buildStellaImage() {
    return AnimatedBuilder(
      animation: Listenable.merge(
        [
          widget.catAnimation,
          _boostAnimationController,
        ],
      ),
      builder: (
        BuildContext context,
        Widget? child,
      ) {
        final double animationValue =
            widget.catAnimation.value;

        final double boostScale =
            _boostScale.value;

        final double boostRotation =
            _boostRotation.value;

        final double glow =
            _boostGlow.value;

        final double sparkleOpacity =
            _boostOpacity.value;

        // ------------------------------------------------------
        // 😴 SLEEPING
        //
        // Hieman rauhallinen hengitys.
        // ------------------------------------------------------

        double normalScale = 1.0;

        if (!widget.miningActive &&
            !widget.boostActive) {
          normalScale =
              0.985 +
                  (animationValue * 0.015);
        }

        // ------------------------------------------------------
        // ⛏️ MINING
        //
        // Kevyt kelluva liike.
        // ------------------------------------------------------

        double floatingOffset = 0.0;

        if (widget.miningActive &&
            !widget.boostActive) {
          floatingOffset =
              -3.0 * animationValue;
        }

        // ------------------------------------------------------
        // ⚡ BOOST
        //
        // Boost-animaatio korvaa normaalin liikkeen.
        // ------------------------------------------------------

        final double finalScale =
            widget.boostActive
                ? boostScale
                : normalScale;

        final double finalRotation =
            widget.boostActive
                ? boostRotation
                : 0.0;

        return Transform.translate(
          offset: Offset(
            0,
            floatingOffset,
          ),
          child: Transform.rotate(
            angle: finalRotation,
            child: Transform.scale(
              scale: finalScale,
              child: SizedBox(
                width: 150,
                height: 150,
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    // ==================================================
                    // 🌟 BOOST GLOW
                    // ==================================================

                    if (glow > 0)
                      Container(
                        width: 138,
                        height: 138,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color:
                                  goldColor.withValues(
                                alpha:
                                    0.55 * glow,
                              ),
                              blurRadius:
                                  30 * glow,
                              spreadRadius:
                                  8 * glow,
                            ),
                            BoxShadow(
                              color:
                                  pinkColor.withValues(
                                alpha:
                                    0.35 * glow,
                              ),
                              blurRadius:
                                  48 * glow,
                              spreadRadius:
                                  5 * glow,
                            ),
                            BoxShadow(
                              color:
                                  accentColor.withValues(
                                alpha:
                                    0.25 * glow,
                              ),
                              blurRadius:
                                  60 * glow,
                              spreadRadius:
                                  4 * glow,
                            ),
                          ],
                        ),
                      ),

                    // ==================================================
                    // 💜 STELLA BACKGROUND
                    // ==================================================

                    Container(
                      width: 126,
                      height: 126,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient:
                            const RadialGradient(
                          colors: [
                            Color(0xFF43266B),
                            Color(0xFF281544),
                          ],
                        ),
                        border: Border.all(
                          color:
                              accentColor.withValues(
                            alpha: 0.35,
                          ),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color:
                                accentColor.withValues(
                              alpha: 0.16,
                            ),
                            blurRadius: 18,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),

                    // ==================================================
                    // 🐱 ACTIVE STELLA IMAGE
                    // ==================================================
                    //
                    // VAIN YKSI Image.asset.
                    //
                    // Ei AnimatedSwitcheria.
                    // Ei crossfadea.
                    // Näin vanha ja uusi kuva eivät näy
                    // samanaikaisesti.
                    //
                    // ==================================================

                    Container(
                      width: 112,
                      height: 112,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color:
                                Colors.black.withValues(
                              alpha: 0.28,
                            ),
                            blurRadius: 14,
                            offset:
                                const Offset(
                              0,
                              5,
                            ),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          _activeStellaImage,
                          width: 112,
                          height: 112,
                          fit: BoxFit.cover,
                          gaplessPlayback: true,
                        ),
                      ),
                    ),

                    // ==================================================
                    // ✨ BOOST SPARKLE
                    // ==================================================

                    if (widget.boostActive &&
                        sparkleOpacity > 0)
                      Positioned(
                        top: -8,
                        right: 0,
                        child: Opacity(
                          opacity:
                              sparkleOpacity,
                          child: const Text(
                            '✨',
                            style: TextStyle(
                              fontSize: 30,
                            ),
                          ),
                        ),
                      ),

                    // ==================================================
                    // ⚡ BOOST LIGHTNING
                    // ==================================================

                    if (widget.boostActive &&
                        sparkleOpacity > 0)
                      Positioned(
                        bottom: -3,
                        left: -4,
                        child: Opacity(
                          opacity:
                              sparkleOpacity,
                          child: const Text(
                            '⚡',
                            style: TextStyle(
                              fontSize: 27,
                            ),
                          ),
                        ),
                      ),

                    // ==================================================
                    // 💫 BOOST STAR
                    // ==================================================

                    if (widget.boostActive &&
                        sparkleOpacity > 0)
                      Positioned(
                        top: 13,
                        left: -5,
                        child: Opacity(
                          opacity:
                              sparkleOpacity,
                          child: const Text(
                            '💫',
                            style: TextStyle(
                              fontSize: 24,
                            ),
                          ),
                        ),
                      ),

                    // ==================================================
                    // 🪙 STL BADGE
                    // ==================================================

                    if (widget.miningActive)
                      Positioned(
                        left: -8,
                        bottom: 8,
                        child: AnimatedOpacity(
                          opacity:
                              0.75 +
                                  (widget
                                              .catAnimation
                                              .value /
                                          100)
                                      .clamp(
                                    0.0,
                                    0.25,
                                  ),
                          duration:
                              const Duration(
                            milliseconds: 150,
                          ),
                          child: Container(
                            padding:
                                const EdgeInsets
                                    .symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration:
                                BoxDecoration(
                              color:
                                  goldColor,
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                10,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      goldColor
                                          .withValues(
                                    alpha: 0.30,
                                  ),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: const Text(
                              'STL',
                              style:
                                  TextStyle(
                                color:
                                    backgroundColor,
                                fontSize: 10,
                                fontWeight:
                                    FontWeight
                                        .bold,
                                letterSpacing:
                                    1,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // 🖥️ BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius:
            BorderRadius.circular(30),
        gradient:
            const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2D174D),
            Color(0xFF1B1033),
          ],
        ),
        border: Border.all(
          color:
              accentColor.withValues(
            alpha: 0.40,
          ),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x55000000),
            blurRadius: 25,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // ----------------------------------------------------
          // 🐱 STELLA
          // ----------------------------------------------------

          _buildStellaImage(),

          const SizedBox(
            height: 18,
          ),

          // ----------------------------------------------------
          // ⛏️ MINING TITLE
          // ----------------------------------------------------

          Text(
            widget.miningTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight:
                  FontWeight.bold,
              letterSpacing: 1,
            ),
          ),

          const SizedBox(
            height: 8,
          ),

          // ----------------------------------------------------
          // SUBTITLE
          // ----------------------------------------------------

          Text(
            widget.miningSubtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color:
                  secondaryTextColor,
              fontSize: 14,
            ),
          ),

          const SizedBox(
            height: 24,
          ),

          // ----------------------------------------------------
          // STL
          // ----------------------------------------------------

          Text(
            _formatStl(
              widget.unclaimedMining,
            ),
            textAlign:
                TextAlign.center,
            style: const TextStyle(
              color: goldColor,
              fontSize: 38,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 4,
          ),

          const Text(
            'STL',
            style: TextStyle(
              color:
                  secondaryTextColor,
              letterSpacing: 2,
              fontSize: 12,
              fontWeight:
                  FontWeight.w600,
            ),
          ),

          const SizedBox(
            height: 24,
          ),

          // ----------------------------------------------------
          // ⏱️ MINING TIME
          // ----------------------------------------------------

          Container(
            width: double.infinity,
            padding:
                const EdgeInsets
                    .symmetric(
              vertical: 15,
              horizontal: 20,
            ),
            decoration:
                BoxDecoration(
              color:
                  backgroundColor
                      .withValues(
                alpha: 0.55,
              ),
              borderRadius:
                  BorderRadius.circular(
                18,
              ),
              border: Border.all(
                color:
                    accentColor
                        .withValues(
                  alpha: 0.08,
                ),
              ),
            ),
            child: Column(
              children: [
                Text(
                  widget.timerText,
                  textAlign:
                      TextAlign.center,
                  style:
                      const TextStyle(
                    color: Colors.white,
                    fontSize: 27,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                const SizedBox(
                  height: 5,
                ),
                Text(
                  widget.timerLabel,
                  textAlign:
                      TextAlign.center,
                  style:
                      const TextStyle(
                    color:
                        secondaryTextColor,
                    fontSize: 11,
                    letterSpacing:
                        1.5,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(
            height: 14,
          ),

          // ----------------------------------------------------
          // 🐾 MINING BUTTON
          // ----------------------------------------------------

          widget.miningButton,

          const SizedBox(
            height: 20,
          ),

          // ----------------------------------------------------
          // 🐾 STELLA MINING DAYS
          // ----------------------------------------------------

          StellaMiningDaysCard(
            languageCode:
                widget.languageCode,
            dailyStreak:
                widget.dailyStreak,
          ),

          const SizedBox(
            height: 20,
          ),

          // ----------------------------------------------------
          // 📊 MINING PROGRESS
          // ----------------------------------------------------

          MiningProgressCard(
            miningActive:
                widget.miningActive,
            miningRemainingMs:
                widget.miningRemainingMs,
            miningDurationMs:
                widget.miningDurationMs,
            title:
                widget.miningProgressTitle,
            stlPerHourText:
                widget.stlPerHourText,
            dailyHashRateText:
                widget.dailyHashRateText,
            dailyHashRateDayText:
                widget.dailyHashRateDayText,
          ),
        ],
      ),
    );
  }
}