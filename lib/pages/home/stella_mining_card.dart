
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'mining_progress_card.dart';
import 'stella_mining_days_card.dart';

// ============================================================
// 🐱 STELLURIINI — STELLA MINING CARD
// ============================================================
//
// Tilat:
// 😴 Sleeping -> stella_sleeping.png
// ⛏️ Mining   -> stella_mining.png
// ⚡ Boost    -> stella_boosting.png
//
// Stella näytetään kokonaisena ilman pyöreää kuvarajausta.
// Animaatiot on rauhoitettu.
// Louhinnan laskentaan tai ajastimiin ei kosketa.
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
  final bool boostActive;
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
  State<StellaMiningCard> createState() => _StellaMiningCardState();
}

class _StellaMiningCardState extends State<StellaMiningCard>
    with TickerProviderStateMixin {
  // ============================================================
  // 🎨 COLORS
  // ============================================================

  static const Color backgroundColor = Color(0xFF120B24);
  static const Color accentColor = Color(0xFFB58CFF);
  static const Color pinkColor = Color(0xFFFFB7E8);
  static const Color goldColor = Color(0xFFFFD166);
  static const Color secondaryTextColor = Color(0xFFBFAEDB);

  // ============================================================
  // 🖼️ IMAGE PATHS
  // ============================================================

  static const String _sleepingImage =
      'assets/images/stella_sleeping.png';

  static const String _miningImage =
      'assets/images/stella_mining.png';

  static const String _boostingImage =
      'assets/images/stella_boosting.png';

  // ============================================================
  // ⚡ BOOST START ANIMATION
  // ============================================================

  late final AnimationController _boostAnimationController;
  late final Animation<double> _boostScale;
  late final Animation<double> _boostRotation;
  late final Animation<double> _boostOpacity;

  // ============================================================
  // 🔄 CONTINUOUS BOOST ANIMATION
  // ============================================================

  late final AnimationController _boostLoopController;
  late final Animation<double> _boostLoopScale;
  late final Animation<double> _boostLoopRotation;
  late final Animation<double> _boostLoopFloat;

  @override
  void initState() {
    super.initState();

    _boostAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    _boostScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.10),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.10, end: 0.97),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.97, end: 1.035),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.035, end: 1.0),
        weight: 35,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _boostAnimationController,
        curve: Curves.easeOut,
      ),
    );

    _boostRotation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: -0.035),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: -0.035, end: 0.035),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.035, end: -0.015),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: -0.015, end: 0.0),
        weight: 35,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _boostAnimationController,
        curve: Curves.easeOut,
      ),
    );

    _boostOpacity = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.0),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.0),
        weight: 55,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _boostAnimationController,
        curve: Curves.easeOut,
      ),
    );

    _boostLoopController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    final CurvedAnimation loopCurve = CurvedAnimation(
      parent: _boostLoopController,
      curve: Curves.easeInOut,
    );

    // Hillitty jatkuva suurennus.
    _boostLoopScale = Tween<double>(
      begin: 0.998,
      end: 1.005,
    ).animate(loopCurve);

    // Hillitty kierto.
    _boostLoopRotation = Tween<double>(
      begin: -0.003,
      end: 0.003,
    ).animate(loopCurve);

    // Erittäin pieni pystysuuntainen liike.
    _boostLoopFloat = Tween<double>(
      begin: -0.5,
      end: 0.5,
    ).animate(loopCurve);

    if (widget.boostActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _startBoostAnimations();
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant StellaMiningCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!oldWidget.boostActive && widget.boostActive) {
      _startBoostAnimations();
    }

    if (oldWidget.boostActive && !widget.boostActive) {
      _stopBoostAnimations();
    }
  }

  void _startBoostAnimations() {
    if (!mounted) return;

    _boostAnimationController.forward(from: 0.0);

    _boostLoopController
      ..stop()
      ..value = 0.0
      ..repeat(reverse: true);
  }

  void _stopBoostAnimations() {
    _boostAnimationController
      ..stop()
      ..value = 0.0;

    _boostLoopController
      ..stop()
      ..value = 0.0;
  }

  @override
  void dispose() {
    _boostAnimationController.dispose();
    _boostLoopController.dispose();
    super.dispose();
  }

  String _formatStl(double value) {
    return value.toStringAsFixed(4);
  }

  String get _activeStellaImage {
    if (widget.boostActive) return _boostingImage;
    if (widget.miningActive) return _miningImage;
    return _sleepingImage;
  }

  // ============================================================
  // 🐱 STELLA IMAGE AND ANIMATION
  // ============================================================

  Widget _buildStellaImage() {
    return AnimatedBuilder(
      animation: Listenable.merge([
        widget.catAnimation,
        _boostAnimationController,
        _boostLoopController,
      ]),
      builder: (BuildContext context, Widget? child) {
        final double animationValue = widget.catAnimation.value;

        // Rauhallinen hengitys nukkuessa.
        final double breathingScale =
            1.0 + (math.sin(animationValue * math.pi) * 0.012);

        // Pienennetty louhintaliike: enintään 0,6 pikseliä.
        final double miningFloat =
            math.sin(animationValue * math.pi * 2) * 0.6;

        double finalScale = 1.0;
        double finalRotation = 0.0;
        double floatingOffset = 0.0;

        if (!widget.miningActive && !widget.boostActive) {
          finalScale = breathingScale;
        } else if (widget.miningActive && !widget.boostActive) {
          // Pienennetty skaalaus louhinnan aikana.
          finalScale =
              1.0 + (math.sin(animationValue * math.pi) * 0.003);
          floatingOffset = miningFloat;
        }

        final double boostScale = _boostScale.value;
        final double boostRotation = _boostRotation.value;
        final double sparkleOpacity = _boostOpacity.value;

        if (widget.boostActive) {
          finalScale = boostScale * _boostLoopScale.value;
          finalRotation = boostRotation + _boostLoopRotation.value;
          floatingOffset = _boostLoopFloat.value;
        }

        return Transform.translate(
          offset: Offset(0, floatingOffset),
          child: Transform.rotate(
            angle: finalRotation,
            child: Transform.scale(
              scale: finalScale,
              child: SizedBox(
                width: 190,
                height: 190,
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    // ✨ BOOST GLOW
                    if (widget.boostActive)
                      Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: goldColor.withValues(
                                alpha: 0.25 +
                                    (0.12 *
                                        _boostLoopController.value),
                              ),
                              blurRadius: 25,
                              spreadRadius: 5,
                            ),
                            BoxShadow(
                              color: pinkColor.withValues(alpha: 0.18),
                              blurRadius: 38,
                              spreadRadius: 3,
                            ),
                            BoxShadow(
                              color: accentColor.withValues(alpha: 0.16),
                              blurRadius: 48,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),

                    // 💜 HILLITTY VIOLETTI TAUSTAHEHKU
                    Container(
                      width: 158,
                      height: 158,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const RadialGradient(
                          colors: [
                            Color(0xFF43266B),
                            Color(0xFF281544),
                          ],
                        ),
                        border: Border.all(
                          color: accentColor.withValues(alpha: 0.35),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: accentColor.withValues(alpha: 0.16),
                            blurRadius: 18,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),

                    // 🐱 KOKO STELLA — EI PYÖREÄÄ RAJAUSTA
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Image.asset(
                        _activeStellaImage,
                        width: 174,
                        height: 174,
                        fit: BoxFit.contain,
                        alignment: Alignment.center,
                        gaplessPlayback: true,
                        errorBuilder: (
                          BuildContext context,
                          Object error,
                          StackTrace? stackTrace,
                        ) {
                          return const Icon(
                            Icons.pets_rounded,
                            size: 86,
                            color: accentColor,
                          );
                        },
                      ),
                    ),

                    // ✨ BOOST SPARKLE
                    if (widget.boostActive && sparkleOpacity > 0)
                      Positioned(
                        top: 0,
                        right: 3,
                        child: Opacity(
                          opacity: sparkleOpacity,
                          child: const Text(
                            '✨',
                            style: TextStyle(fontSize: 30),
                          ),
                        ),
                      ),

                    // ⚡ BOOST LIGHTNING
                    if (widget.boostActive && sparkleOpacity > 0)
                      Positioned(
                        bottom: 5,
                        left: 0,
                        child: Opacity(
                          opacity: sparkleOpacity,
                          child: const Text(
                            '⚡',
                            style: TextStyle(fontSize: 27),
                          ),
                        ),
                      ),

                    // 💫 BOOST STAR
                    if (widget.boostActive && sparkleOpacity > 0)
                      Positioned(
                        top: 25,
                        left: 0,
                        child: Opacity(
                          opacity: sparkleOpacity,
                          child: const Text(
                            '💫',
                            style: TextStyle(fontSize: 24),
                          ),
                        ),
                      ),

                    // 🪙 STL BADGE
                    if (widget.miningActive)
                      Positioned(
                        left: 0,
                        bottom: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: goldColor,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: goldColor.withValues(alpha: 0.30),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: const Text(
                            'STL',
                            style: TextStyle(
                              color: backgroundColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
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
          color: accentColor.withValues(alpha: 0.40),
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
          _buildStellaImage(),

          const SizedBox(height: 18),

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

          Text(
            widget.miningSubtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: secondaryTextColor,
              fontSize: 14,
            ),
          ),

          const SizedBox(height: 24),

          Text(
            _formatStl(widget.unclaimedMining),
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

          // ⏱️ MINING TIME
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              vertical: 15,
              horizontal: 20,
            ),
            decoration: BoxDecoration(
              color: backgroundColor.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: accentColor.withValues(alpha: 0.08),
              ),
            ),
            child: Column(
              children: [
                Text(
                  widget.timerText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 27,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  widget.timerLabel,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: secondaryTextColor,
                    fontSize: 11,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          widget.miningButton,

          const SizedBox(height: 20),

          StellaMiningDaysCard(
            languageCode: widget.languageCode,
            dailyStreak: widget.dailyStreak,
          ),

          const SizedBox(height: 20),

          MiningProgressCard(
            miningActive: widget.miningActive,
            miningRemainingMs: widget.miningRemainingMs,
            miningDurationMs: widget.miningDurationMs,
            title: widget.miningProgressTitle,
            stlPerHourText: widget.stlPerHourText,
            dailyHashRateText: widget.dailyHashRateText,
            dailyHashRateDayText: widget.dailyHashRateDayText,
          ),
        ],
      ),
    );
  }
}
