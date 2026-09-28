import 'package:flutter/material.dart';

// ============================================================
// 🐱 STELLURIINI - STELLA MINING ANIMATION
// ============================================================
//
// Stella näkyy aina vain yhdessä aktiivisessa tilassa:
//
// ⛏️ MINING
// 💤 SLEEPING
// ⚡ BOOSTING
//
// Tilojen vaihto tapahtuu pehmeällä fade-animaatiolla.
//
// Tämä komponentti on tarkoitettu HomePageen, jotta HomePage
// pysyy mahdollisimman selkeänä.
//
// ============================================================

enum StellaMiningState {
  mining,
  sleeping,
  boosting,
}

class StellaMiningAnimation extends StatefulWidget {
  final StellaMiningState state;

  final double size;

  const StellaMiningAnimation({
    super.key,
    required this.state,
    this.size = 220,
  });

  @override
  State<StellaMiningAnimation> createState() =>
      _StellaMiningAnimationState();
}

class _StellaMiningAnimationState
    extends State<StellaMiningAnimation>
    with SingleTickerProviderStateMixin {
  // ==========================================================
  // 🎨 STELLA COLORS
  // ==========================================================

  static const Color purple =
      Color(0xFFB58CFF);

  static const Color pink =
      Color(0xFFFFB7E8);

  static const Color gold =
      Color(0xFFFFD166);

  // ==========================================================
  // 🎞️ ANIMATION
  // ==========================================================

  late final AnimationController _controller;

  late final Animation<double> _breathingAnimation;

  late final Animation<double> _rotationAnimation;

  // ==========================================================
  // INIT
  // ==========================================================

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: _durationForState(
        widget.state,
      ),
    );

    _breathingAnimation = Tween<double>(
      begin: 0.97,
      end: 1.03,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _rotationAnimation = Tween<double>(
      begin: -0.012,
      end: 0.012,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _controller.repeat(
      reverse: true,
    );
  }

  // ==========================================================
  // UPDATE STATE
  // ==========================================================

  @override
  void didUpdateWidget(
    StellaMiningAnimation oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.state != widget.state) {
      _controller
        ..duration = _durationForState(
          widget.state,
        )
        ..repeat(
          reverse: true,
        );
    }
  }

  // ==========================================================
  // ANIMATION SPEED
  // ==========================================================

  Duration _durationForState(
    StellaMiningState state,
  ) {
    switch (state) {
      case StellaMiningState.mining:
        return const Duration(
          milliseconds: 1500,
        );

      case StellaMiningState.sleeping:
        return const Duration(
          milliseconds: 2800,
        );

      case StellaMiningState.boosting:
        return const Duration(
          milliseconds: 900,
        );
    }
  }

  // ==========================================================
  // IMAGE PATH
  // ==========================================================
  //
  // Nämä vaihdetaan myöhemmin oikeisiin Stella-kuviin.
  //
  // ==========================================================

  String _imagePath(
    StellaMiningState state,
  ) {
    switch (state) {
      case StellaMiningState.mining:
        return 'assets/images/stella_mining.png';

      case StellaMiningState.sleeping:
        return 'assets/images/stella_sleeping.png';

      case StellaMiningState.boosting:
        return 'assets/images/stella_boosting.png';
    }
  }

  // ==========================================================
  // GLOW COLOR
  // ==========================================================

  Color _glowColor(
    StellaMiningState state,
  ) {
    switch (state) {
      case StellaMiningState.mining:
        return purple;

      case StellaMiningState.sleeping:
        return pink;

      case StellaMiningState.boosting:
        return gold;
    }
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    final Color glowColor =
        _glowColor(widget.state);

    final bool isBoosting =
        widget.state ==
            StellaMiningState.boosting;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // ====================================================
          // ✨ SOFT GLOW
          // ====================================================

          AnimatedBuilder(
            animation: _breathingAnimation,
            builder: (
              BuildContext context,
              Widget? child,
            ) {
              final double scale =
                  _breathingAnimation.value;

              return Transform.scale(
                scale: scale,
                child: Container(
                  width: widget.size * 0.72,
                  height: widget.size * 0.72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: glowColor.withValues(
                          alpha: isBoosting
                              ? 0.32
                              : 0.18,
                        ),
                        blurRadius:
                            isBoosting ? 38 : 28,
                        spreadRadius:
                            isBoosting ? 8 : 3,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // ====================================================
          // 🐱 STELLA IMAGE
          // ====================================================

          AnimatedSwitcher(
            duration: const Duration(
              milliseconds: 450,
            ),
            switchInCurve:
                Curves.easeOutCubic,
            switchOutCurve:
                Curves.easeInCubic,
            layoutBuilder: (
              Widget? currentChild,
              List<Widget> previousChildren,
            ) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  ...previousChildren,
                  if (currentChild != null)
                    currentChild,
                ],
              );
            },
            child: AnimatedBuilder(
              key: ValueKey(
                widget.state,
              ),
              animation: _controller,
              builder: (
                BuildContext context,
                Widget? child,
              ) {
                final double scale =
                    _breathingAnimation.value;

                return Transform.rotate(
                  angle: _rotationAngle(),
                  child: Transform.scale(
                    scale: scale,
                    child: child,
                  ),
                );
              },
              child: SizedBox(
                width: widget.size * 0.82,
                height: widget.size * 0.82,
                child: Image.asset(
                  _imagePath(
                    widget.state,
                  ),
                  fit: BoxFit.contain,
                  errorBuilder: (
                    BuildContext context,
                    Object error,
                    StackTrace? stackTrace,
                  ) {
                    return _fallbackStella(
                      widget.state,
                    );
                  },
                ),
              ),
            ),
          ),

          // ====================================================
          // ⚡ BOOST EFFECT
          // ====================================================

          if (isBoosting)
            AnimatedBuilder(
              animation: _controller,
              builder: (
                BuildContext context,
                Widget? child,
              ) {
                final double opacity =
                    0.25 +
                    (_controller.value * 0.45);

                return Container(
                  width: widget.size * 0.84,
                  height: widget.size * 0.84,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: gold.withValues(
                        alpha: opacity,
                      ),
                      width: 2,
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // ==========================================================
  // ROTATION
  // ==========================================================

  double _rotationAngle() {
    switch (widget.state) {
      case StellaMiningState.mining:
        return _rotationAnimation.value;

      case StellaMiningState.sleeping:
        return _rotationAnimation.value * 0.25;

      case StellaMiningState.boosting:
        return _rotationAnimation.value * 1.5;
    }
  }

  // ==========================================================
  // FALLBACK
  // ==========================================================
  //
  // Jos asset-kuvaa ei vielä löydy, sovellus ei kaadu.
  //
  // Tämä poistetaan myöhemmin, kun oikeat Stella-kuvat
  // ovat paikallaan.
  //
  // ==========================================================

  Widget _fallbackStella(
    StellaMiningState state,
  ) {
    IconData icon;

    Color color;

    switch (state) {
      case StellaMiningState.mining:
        icon = Icons.construction_rounded;
        color = purple;
        break;

      case StellaMiningState.sleeping:
        icon = Icons.nightlight_round;
        color = pink;
        break;

      case StellaMiningState.boosting:
        icon = Icons.bolt_rounded;
        color = gold;
        break;
    }

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(
          alpha: 0.10,
        ),
        border: Border.all(
          color: color.withValues(
            alpha: 0.35,
          ),
          width: 2,
        ),
      ),
      child: Icon(
        icon,
        color: color,
        size: widget.size * 0.25,
      ),
    );
  }

  // ==========================================================
  // DISPOSE
  // ==========================================================

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}