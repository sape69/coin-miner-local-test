import 'package:flutter/material.dart';

// ============================================================
// 🐱 STELLURIINI - STELLA STATUS CARD
// ============================================================
//
// Näyttää vain yhden aktiivisen Stellan kerrallaan.
//
// ⛏️ MINING
// 😴 SLEEPING
// ⚡ BOOSTING
//
// HomePage antaa komponentille aktiivisen tilan.
//
// Esimerkiksi:
//
// StellaStatusCard(
//   status: StellaStatus.mining,
// )
//
// ============================================================

enum StellaStatus {
  mining,
  sleeping,
  boosting,
}

class StellaStatusCard extends StatefulWidget {
  final StellaStatus status;

  const StellaStatusCard({
    super.key,
    required this.status,
  });

  @override
  State<StellaStatusCard> createState() =>
      _StellaStatusCardState();
}

class _StellaStatusCardState
    extends State<StellaStatusCard>
    with SingleTickerProviderStateMixin {
  // ==========================================================
  // 🎨 STELLA COLORS
  // ==========================================================

  static const Color cardColor =
      Color(0xFF21113B);

  static const Color accentColor =
      Color(0xFFB58CFF);

  static const Color pinkColor =
      Color(0xFFFFB7E8);

  static const Color goldColor =
      Color(0xFFFFD166);

  static const Color primaryTextColor =
      Color(0xFFF8F4FF);

  static const Color secondaryTextColor =
      Color(0xFFBDB4D1);

  // ==========================================================
  // ✨ ANIMATION
  // ==========================================================

  late final AnimationController _animationController;

  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 1800,
      ),
    )..repeat(
        reverse: true,
      );

    _scaleAnimation = Tween<double>(
      begin: 0.97,
      end: 1.03,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();

    super.dispose();
  }

  // ==========================================================
  // 🔄 UPDATE ANIMATION
  // ==========================================================

  @override
  void didUpdateWidget(
    covariant StellaStatusCard oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.status != widget.status) {
      _animationController
        ..stop()
        ..reset()
        ..repeat(
          reverse: true,
        );
    }
  }

  // ==========================================================
  // 🏷️ STATUS TITLE
  // ==========================================================

  String get _title {
    switch (widget.status) {
      case StellaStatus.mining:
        return 'Stella louhii';

      case StellaStatus.sleeping:
        return 'Stella nukkuu';

      case StellaStatus.boosting:
        return 'Stella boostaa';
    }
  }

  // ==========================================================
  // 💬 STATUS DESCRIPTION
  // ==========================================================

  String get _description {
    switch (widget.status) {
      case StellaStatus.mining:
        return 'Stella työskentelee puolestasi. 🐱⛏️';

      case StellaStatus.sleeping:
        return 'Stella lepää ennen seuraavaa louhintaa. 🐱💤';

      case StellaStatus.boosting:
        return 'Stella käyttää Power Boostia! 🐱⚡';
    }
  }

  // ==========================================================
  // 🎨 STATUS COLOR
  // ==========================================================

  Color get _statusColor {
    switch (widget.status) {
      case StellaStatus.mining:
        return goldColor;

      case StellaStatus.sleeping:
        return accentColor;

      case StellaStatus.boosting:
        return pinkColor;
    }
  }

  // ==========================================================
  // 🐱 STATUS IMAGE
  // ==========================================================
  //
  // Näytetään vain yksi aktiivinen Stella-kuva kerrallaan.
  //
  // ⛏️ assets/images/stella_mining.png
  // 😴 assets/images/stella_sleeping.png
  // ⚡ assets/images/stella_boosting.png
  //
  // ==========================================================

  String get _imagePath {
    switch (widget.status) {
      case StellaStatus.mining:
        return 'assets/images/stella_mining.png';

      case StellaStatus.sleeping:
        return 'assets/images/stella_sleeping.png';

      case StellaStatus.boosting:
        return 'assets/images/stella_boosting.png';
    }
  }

  // ==========================================================
  // 🔰 STATUS ICON
  // ==========================================================

  IconData get _statusIcon {
    switch (widget.status) {
      case StellaStatus.mining:
        return Icons.hardware_rounded;

      case StellaStatus.sleeping:
        return Icons.nightlight_round;

      case StellaStatus.boosting:
        return Icons.bolt_rounded;
    }
  }

  // ==========================================================
  // 🖼️ STELLA IMAGE
  // ==========================================================

  Widget _buildStellaImage() {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (
        BuildContext context,
        Widget? child,
      ) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: Container(
        width: 220,
        height: 220,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: _statusColor.withValues(
              alpha: 0.55,
            ),
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: _statusColor.withValues(
                alpha: 0.30,
              ),
              blurRadius: 35,
              spreadRadius: 5,
            ),
          ],
        ),
        child: ClipOval(
          child: Image.asset(
            _imagePath,
            fit: BoxFit.cover,
            errorBuilder: (
              BuildContext context,
              Object error,
              StackTrace? stackTrace,
            ) {
              return Container(
                color: const Color(0xFF170D2B),
                child: Icon(
                  Icons.pets_rounded,
                  color: _statusColor,
                  size: 90,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // ✨ PARTICLE EFFECT
  // ==========================================================

  Widget _buildGlowParticle({
    required double size,
    required Alignment alignment,
    required Color color,
  }) {
    return Align(
      alignment: alignment,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (
          BuildContext context,
          Widget? child,
        ) {
          final double opacity =
              0.25 +
              (_animationController.value * 0.55);

          return Opacity(
            opacity: opacity,
            child: child,
          );
        },
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            boxShadow: [
              BoxShadow(
                color: color.withValues(
                  alpha: 0.7,
                ),
                blurRadius: 12,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // 🏷️ STATUS BADGE
  // ==========================================================

  Widget _buildStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: _statusColor.withValues(
          alpha: 0.14,
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: _statusColor.withValues(
            alpha: 0.55,
          ),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: _statusColor.withValues(
              alpha: 0.16,
            ),
            blurRadius: 18,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _statusIcon,
            color: _statusColor,
            size: 18,
          ),
          const SizedBox(width: 7),
          Text(
            _title,
            style: TextStyle(
              color: _statusColor,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // 🏠 BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        20,
        22,
        20,
        24,
      ),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: _statusColor.withValues(
            alpha: 0.32,
          ),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: _statusColor.withValues(
              alpha: 0.10,
            ),
            blurRadius: 30,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          // ====================================================
          // ✨ IMAGE AREA
          // ====================================================

          SizedBox(
            width: 260,
            height: 240,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Background glow
                Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        _statusColor.withValues(
                          alpha: 0.16,
                        ),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),

                _buildGlowParticle(
                  size: 7,
                  alignment: Alignment.topLeft,
                  color: _statusColor,
                ),

                _buildGlowParticle(
                  size: 5,
                  alignment: Alignment.topRight,
                  color: pinkColor,
                ),

                _buildGlowParticle(
                  size: 6,
                  alignment: Alignment.bottomLeft,
                  color: goldColor,
                ),

                _buildGlowParticle(
                  size: 4,
                  alignment: Alignment.bottomRight,
                  color: _statusColor,
                ),

                _buildStellaImage(),
              ],
            ),
          ),

          const SizedBox(height: 4),

          // ====================================================
          // 🏷️ STATUS
          // ====================================================

          _buildStatusBadge(),

          const SizedBox(height: 14),

          // ====================================================
          // TITLE
          // ====================================================

          Text(
            _title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: primaryTextColor,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
          ),

          const SizedBox(height: 7),

          // ====================================================
          // DESCRIPTION
          // ====================================================

          AnimatedSwitcher(
            duration: const Duration(
              milliseconds: 300,
            ),
            child: Text(
              _description,
              key: ValueKey<String>(
                _description,
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: secondaryTextColor,
                fontSize: 15,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}