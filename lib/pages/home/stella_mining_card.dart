import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'mining_progress_card.dart';
import 'stella_mining_days_card.dart';

// ============================================================
// 🐱 STELLURIINI STELLA MINING CARD
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
  // Mining-painike
  // ------------------------------------------------------------
  final Widget miningButton;

  // ------------------------------------------------------------
  // 🐾 POWER BOOST
  // ------------------------------------------------------------
  // Kun arvo muuttuu false -> true, bonus-animaatio käynnistyy.
  final bool boostActive;

  // Teksti näytetään bonusanimaation aikana.
  final String boostLabel;

  static const Color backgroundColor = Color(0xFF120B24);
  static const Color cardColor = Color(0xFF21113B);
  static const Color accentColor = Color(0xFFB58CFF);
  static const Color goldColor = Color(0xFFFFD166);
  static const Color pinkColor = Color(0xFFFFB7E8);
  static const Color secondaryTextColor = Color(0xFFBFAEDB);

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
    required this.miningButton,

    // Power Boost
    this.boostActive = false,
    this.boostLabel = 'POWER BOOST!',
  });

  @override
  State<StellaMiningCard> createState() =>
      _StellaMiningCardState();
}

// ============================================================
// 🐱 STATE
// ============================================================

class _StellaMiningCardState extends State<StellaMiningCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _boostController;

  late final Animation<double> _boostScale;
  late final Animation<double> _boostRotation;
  late final Animation<double> _boostGlow;
  late final Animation<double> _boostParticles;
  late final Animation<double> _boostOpacity;

  @override
  void initState() {
    super.initState();

    _boostController = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 1500,
      ),
    );

    _boostScale = Tween<double>(
      begin: 1.0,
      end: 1.18,
    ).animate(
      CurvedAnimation(
        parent: _boostController,
        curve: Curves.elasticOut,
      ),
    );

    _boostRotation = Tween<double>(
      begin: -0.04,
      end: 0.04,
    ).animate(
      CurvedAnimation(
        parent: _boostController,
        curve: Curves.easeOutBack,
      ),
    );

    _boostGlow = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _boostController,
        curve: Curves.easeOut,
      ),
    );

    _boostParticles = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _boostController,
        curve: Curves.easeOutCubic,
      ),
    );

    _boostOpacity = TweenSequence<double>(
      [
        TweenSequenceItem(
          tween: Tween<double>(
            begin: 0.0,
            end: 1.0,
          ),
          weight: 20,
        ),
        TweenSequenceItem(
          tween: ConstantTween<double>(1.0),
          weight: 45,
        ),
        TweenSequenceItem(
          tween: Tween<double>(
            begin: 1.0,
            end: 0.0,
          ),
          weight: 35,
        ),
      ],
    ).animate(
      CurvedAnimation(
        parent: _boostController,
        curve: Curves.easeInOut,
      ),
    );

    // Jos boost on jo aktiivinen kortin ensimmäisessä
    // rakentumisessa, näytetään animaatio kerran.
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

  @override
  void didUpdateWidget(
    covariant StellaMiningCard oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);

    // Käynnistetään animaatio vain, kun Power Boost
    // muuttuu pois päältä -> päälle.
    if (!oldWidget.boostActive &&
        widget.boostActive) {
      _playBoostAnimation();
    }
  }

  void _playBoostAnimation() {
    _boostController.forward(
      from: 0.0,
    );
  }

  @override
  void dispose() {
    _boostController.dispose();
    super.dispose();
  }

  String _formatStl(double value) {
    return value.toStringAsFixed(4);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2D174D),
            Color(0xFF1B1033),
          ],
        ),
        border: Border.all(
          color: accentColor.withValues(
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
          // 🐱 STELLA + BOOST ANIMATION
          // ----------------------------------------------------

          AnimatedBuilder(
            animation: Listenable.merge([
              widget.catAnimation,
              _boostController,
            ]),
            builder: (context, child) {
              final double normalMovement =
                  widget.catAnimation.value;

              final double boostScale =
                  _boostScale.value;

              final double boostRotation =
                  _boostRotation.value *
                  _boostController.value;

              return SizedBox(
                width: 150,
                height: 150,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // ------------------------------------------
                    // ✨ BOOST GLOW
                    // ------------------------------------------

                    if (_boostController.value > 0)
                      Opacity(
                        opacity:
                            _boostGlow.value *
                            0.65,
                        child: Container(
                          width:
                              120 +
                              (25 *
                                  _boostGlow.value),
                          height:
                              120 +
                              (25 *
                                  _boostGlow.value),
                          decoration:
                              BoxDecoration(
                            shape:
                                BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color:
                                    goldColor
                                        .withValues(
                                  alpha:
                                      0.45 *
                                      _boostGlow.value,
                                ),
                                blurRadius:
                                    35 *
                                    _boostGlow.value,
                                spreadRadius:
                                    8 *
                                    _boostGlow.value,
                              ),
                              BoxShadow(
                                color:
                                    pinkColor
                                        .withValues(
                                  alpha:
                                      0.35 *
                                      _boostGlow.value,
                                ),
                                blurRadius:
                                    50 *
                                    _boostGlow.value,
                                spreadRadius:
                                    5 *
                                    _boostGlow.value,
                              ),
                            ],
                          ),
                        ),
                      ),

                    // ------------------------------------------
                    // ✨ STAR PARTICLES
                    // ------------------------------------------

                    if (_boostController.value > 0)
                      ..._buildBoostParticles(),

                    // ------------------------------------------
                    // 🟣 STELLA CIRCLE
                    // ------------------------------------------

                    Transform.translate(
                      offset: Offset(
                        0,
                        -normalMovement,
                      ),
                      child: Transform.rotate(
                        angle:
                            boostRotation,
                        child: Transform.scale(
                          scale:
                              boostScale,
                          child:
                              Container(
                            width: 110,
                            height: 110,
                            decoration:
                                BoxDecoration(
                              shape:
                                  BoxShape.circle,
                              color:
                                  accentColor
                                      .withValues(
                                alpha:
                                    0.15,
                              ),
                              border:
                                  Border.all(
                                color:
                                    _boostController
                                                .value >
                                            0
                                        ? goldColor
                                            .withValues(
                                          alpha:
                                              0.65,
                                        )
                                        : accentColor
                                            .withValues(
                                          alpha:
                                              0.10,
                                        ),
                                width:
                                    _boostController
                                                .value >
                                            0
                                        ? 2
                                        : 1,
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
                      ),
                    ),

                    // ------------------------------------------
                    // ⚡ BOOST LABEL
                    // ------------------------------------------

                    if (_boostController.value > 0.05)
                      Positioned(
                        bottom: 2,
                        child: Opacity(
                          opacity:
                              _boostOpacity
                                  .value,
                          child:
                              Transform.scale(
                            scale:
                                0.85 +
                                (_boostScale
                                        .value -
                                    1.0),
                            child:
                                Container(
                              padding:
                                  const EdgeInsets
                                      .symmetric(
                                horizontal:
                                    12,
                                vertical: 6,
                              ),
                              decoration:
                                  BoxDecoration(
                                gradient:
                                    const LinearGradient(
                                  colors: [
                                    goldColor,
                                    pinkColor,
                                  ],
                                ),
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  14,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        goldColor
                                            .withValues(
                                      alpha:
                                          0.35,
                                    ),
                                    blurRadius:
                                        12,
                                  ),
                                ],
                              ),
                              child:
                                  Text(
                                widget.boostLabel,
                                style:
                                    const TextStyle(
                                  color:
                                      Color(
                                    0xFF120B24,
                                  ),
                                  fontSize:
                                      10,
                                  fontWeight:
                                      FontWeight
                                          .w900,
                                  letterSpacing:
                                      1,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 8),

          // ----------------------------------------------------
          // Mining title
          // ----------------------------------------------------

          Text(
            widget.miningTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),

          const SizedBox(height: 8),

          // ----------------------------------------------------
          // Mining subtitle
          // ----------------------------------------------------

          Text(
            widget.miningSubtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: secondaryTextColor,
              fontSize: 14,
            ),
          ),

          const SizedBox(height: 24),

          // ----------------------------------------------------
          // Unclaimed STL
          // ----------------------------------------------------

          Text(
            _formatStl(
              widget.unclaimedMining,
            ),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: goldColor,
              fontSize: 38,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 4),

          const Text(
            'STL',
            style: TextStyle(
              color: secondaryTextColor,
              letterSpacing: 2,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 24),

          // ----------------------------------------------------
          // Mining time remaining
          // ----------------------------------------------------

          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(
              vertical: 15,
              horizontal: 20,
            ),
            decoration: BoxDecoration(
              color:
                  backgroundColor.withValues(
                alpha: 0.55,
              ),
              borderRadius:
                  BorderRadius.circular(18),
              border: Border.all(
                color:
                    accentColor.withValues(
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
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 27,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  widget.timerLabel,
                  textAlign:
                      TextAlign.center,
                  style: const TextStyle(
                    color:
                        secondaryTextColor,
                    fontSize: 11,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ----------------------------------------------------
          // 🐾 START MINING / MINING ACTIVE
          // ----------------------------------------------------

          widget.miningButton,

          const SizedBox(height: 20),

          // ----------------------------------------------------
          // Stella Mining Days
          // ----------------------------------------------------

          StellaMiningDaysCard(
            languageCode:
                widget.languageCode,
            dailyStreak:
                widget.dailyStreak,
          ),

          const SizedBox(height: 20),

          // ----------------------------------------------------
          // Mining progress
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

  // ============================================================
  // ✨ BOOST PARTICLES
  // ============================================================

  List<Widget> _buildBoostParticles() {
    const List<IconData> icons = [
      Icons.auto_awesome,
      Icons.star_rounded,
      Icons.bolt_rounded,
      Icons.pets_rounded,
      Icons.auto_awesome,
      Icons.star_rounded,
    ];

    const List<double> angles = [
      0.0,
      math.pi / 3,
      2 * math.pi / 3,
      math.pi,
      4 * math.pi / 3,
      5 * math.pi / 3,
    ];

    return List.generate(
      icons.length,
      (index) {
        final double progress =
            _boostParticles.value;

        final double radius =
            42 + (35 * progress);

        final double x =
            math.cos(angles[index]) *
            radius;

        final double y =
            math.sin(angles[index]) *
            radius;

        final double scale =
            0.5 +
            (0.8 *
                (1 -
                    progress));

        return Transform.translate(
          offset: Offset(x, y),
          child: Opacity(
            opacity:
                (1 - progress)
                    .clamp(
                      0.0,
                      1.0,
                    ),
            child: Transform.scale(
              scale: scale,
              child: Icon(
                icons[index],
                color:
                    index.isEven
                        ? goldColor
                        : pinkColor,
                size: 18,
              ),
            ),
          ),
        );
      },
    );
  }
}