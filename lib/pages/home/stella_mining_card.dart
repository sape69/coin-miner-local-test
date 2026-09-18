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
  // ⚡ POWER BOOST
  // ------------------------------------------------------------
  final bool boostActive;

  // ------------------------------------------------------------
  // Mining-painike
  // ------------------------------------------------------------
  // HomePage rakentaa varsinaisen painikkeen ja sen toiminnallisuuden.
  // StellaMiningCard vain sijoittaa sen oikeaan kohtaan käyttöliittymässä.
  final Widget miningButton;

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
  // ⚡ POWER BOOST ANIMATION
  // ============================================================

  late final AnimationController _boostAnimationController;

  late final Animation<double> _boostScale;

  late final Animation<double> _boostRotation;

  late final Animation<double> _boostGlow;

  late final Animation<double> _boostOpacity;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _boostAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 1100,
      ),
    );

    _boostScale = TweenSequence<double>(
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

    _boostRotation = TweenSequence<double>(
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

    _boostGlow = TweenSequence<double>(
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
  // 🔄 DID UPDATE WIDGET
  // ============================================================

  @override
  void didUpdateWidget(
    covariant StellaMiningCard oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);

    // Bonus aktivoitui juuri nyt.
    if (!oldWidget.boostActive &&
        widget.boostActive) {
      _playBoostAnimation();
    }
  }

  // ============================================================
  // ⚡ PLAY BOOST ANIMATION
  // ============================================================

  void _playBoostAnimation() {
    _boostAnimationController.forward(
      from: 0.0,
    );
  }

  // ============================================================
  // DISPOSE
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
  // 🐱 STELLA ICON
  // ============================================================

  Widget _buildStellaIcon() {
    return AnimatedBuilder(
      animation: Listenable.merge([
        widget.catAnimation,
        _boostAnimationController,
      ]),
      builder: (
        BuildContext context,
        Widget? child,
      ) {
        final double floatingOffset =
            -widget.catAnimation.value;

        final double boostScale =
            _boostScale.value;

        final double boostRotation =
            _boostRotation.value;

        final double glow =
            _boostGlow.value;

        return Transform.translate(
          offset: Offset(
            0,
            floatingOffset,
          ),
          child: Transform.rotate(
            angle: boostRotation,
            child: Transform.scale(
              scale: boostScale,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  // ------------------------------------------------
                  // 🌟 POWER GLOW
                  // ------------------------------------------------
                  if (glow > 0)
                    Container(
                      width: 135,
                      height: 135,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color:
                                goldColor.withValues(
                              alpha: 0.55 * glow,
                            ),
                            blurRadius:
                                28 * glow,
                            spreadRadius:
                                8 * glow,
                          ),
                          BoxShadow(
                            color:
                                pinkColor.withValues(
                              alpha: 0.35 * glow,
                            ),
                            blurRadius:
                                45 * glow,
                            spreadRadius:
                                5 * glow,
                          ),
                        ],
                      ),
                    ),

                  // ------------------------------------------------
                  // 🐱 STELLA CIRCLE
                  // ------------------------------------------------
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color:
                          accentColor.withValues(
                        alpha: 0.15,
                      ),
                      border: Border.all(
                        color:
                            accentColor.withValues(
                          alpha: 0.10,
                        ),
                      ),
                    ),
                    child: const Center(
                      child: Text(
                        '🐱⛏️',
                        style: TextStyle(
                          fontSize: 55,
                        ),
                      ),
                    ),
                  ),

                  // ------------------------------------------------
                  // ✨ BOOST SPARKLES
                  // ------------------------------------------------
                  if (_boostAnimationController
                          .value >
                      0)
                    Positioned(
                      top: -12,
                      right: -12,
                      child: Opacity(
                        opacity:
                            _boostOpacity.value,
                        child: Transform.scale(
                          scale:
                              0.7 +
                              (_boostScale.value -
                                      1.0)
                                  .abs() *
                                  2,
                          child: const Text(
                            '✨',
                            style: TextStyle(
                              fontSize: 30,
                            ),
                          ),
                        ),
                      ),
                    ),

                  if (_boostAnimationController
                          .value >
                      0)
                    Positioned(
                      bottom: -8,
                      left: -18,
                      child: Opacity(
                        opacity:
                            _boostOpacity.value,
                        child: const Text(
                          '⚡',
                          style: TextStyle(
                            fontSize: 27,
                          ),
                        ),
                      ),
                    ),

                  if (_boostAnimationController
                          .value >
                      0)
                    Positioned(
                      top: 5,
                      left: -20,
                      child: Opacity(
                        opacity:
                            _boostOpacity.value,
                        child: const Text(
                          '💫',
                          style: TextStyle(
                            fontSize: 24,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
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
          // 🐱 STELLA / MINING ICON
          // ----------------------------------------------------
          _buildStellaIcon(),

          const SizedBox(
            height: 18,
          ),

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

          const SizedBox(
            height: 8,
          ),

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

          const SizedBox(
            height: 24,
          ),

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

          const SizedBox(
            height: 4,
          ),

          const Text(
            'STL',
            style: TextStyle(
              color: secondaryTextColor,
              letterSpacing: 2,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(
            height: 24,
          ),

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
                  BorderRadius.circular(
                18,
              ),
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
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 27,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(
                  height: 5,
                ),
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

          const SizedBox(
            height: 14,
          ),

          // ----------------------------------------------------
          // 🐾 START MINING / MINING ACTIVE
          // ----------------------------------------------------
          widget.miningButton,

          const SizedBox(
            height: 20,
          ),

          // ----------------------------------------------------
          // Stella Mining Days
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
}