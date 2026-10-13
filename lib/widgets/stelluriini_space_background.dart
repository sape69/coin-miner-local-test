import 'package:flutter/material.dart';

// ============================================================
// 🌌 STELLURIINI — SPACE BACKGROUND
// ============================================================
//
// Yhtenäinen realistinen avaruustausta Stelluriini-sovellukseen.
//
// Kuva:
// assets/images/stelluriini_space_background.png
//
// Tumma violetti peite auttaa säilyttämään tekstien
// luettavuuden. Tausta ei muuta louhinnan toimintaa.
//
// ============================================================

class StelluriiniSpaceBackground extends StatelessWidget {
  final Widget child;
  final double overlayOpacity;

  const StelluriiniSpaceBackground({
    super.key,
    required this.child,
    this.overlayOpacity = 0.48,
  });

  static const String imagePath =
      'assets/images/stelluriini_space_background.png';

  static const Color overlayColor = Color(0xFF120B24);

  @override
  Widget build(BuildContext context) {
    final double safeOpacity =
        overlayOpacity.clamp(0.0, 1.0).toDouble();

    return Stack(
      fit: StackFit.expand,
      children: [
        // 🌌 Avaruuskuva
        Image.asset(
          imagePath,
          fit: BoxFit.cover,
          alignment: Alignment.center,
          errorBuilder: (
            BuildContext context,
            Object error,
            StackTrace? stackTrace,
          ) {
            return const ColoredBox(
              color: overlayColor,
            );
          },
        ),

        // 💜 Tumma peite tekstien luettavuutta varten
        ColoredBox(
          color: overlayColor.withValues(
            alpha: safeOpacity,
          ),
        ),

        // 📱 Sivun sisältö
        child,
      ],
    );
  }
}