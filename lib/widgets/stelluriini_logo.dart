import 'package:flutter/material.dart';

// ============================================================
// 🐱 STELLURIINI / STELLA LOGO
// ============================================================

const Color stelluriiniLogoCardColor = Color(0xFF21113B);
const Color stelluriiniLogoAccentColor = Color(0xFFB58CFF);
const Color stelluriiniLogoPinkColor = Color(0xFFFFB7E8);

// ============================================================
// 🐱 STELLURIINI LOGO
// ============================================================

class StelluriiniLogo extends StatelessWidget {
  final double size;

  const StelluriiniLogo({
    super.key,
    this.size = 100,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.025),
      decoration: BoxDecoration(
        color: stelluriiniLogoCardColor,
        borderRadius: BorderRadius.circular(
          size * 0.22,
        ),
        border: Border.all(
          color: stelluriiniLogoAccentColor.withValues(
            alpha: 0.45,
          ),
          width: size * 0.025,
        ),
        boxShadow: [
          BoxShadow(
            color: stelluriiniLogoAccentColor.withValues(
              alpha: 0.16,
            ),
            blurRadius: size * 0.18,
            spreadRadius: size * 0.015,
          ),
          BoxShadow(
            color: stelluriiniLogoPinkColor.withValues(
              alpha: 0.08,
            ),
            blurRadius: size * 0.28,
            spreadRadius: size * 0.005,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(
          size * 0.18,
        ),
        child: Image.asset(
          'assets/images/stelluriini_logo.png',
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (
            context,
            error,
            stackTrace,
          ) {
            return Center(
              child: Icon(
                Icons.pets_rounded,
                color: stelluriiniLogoAccentColor,
                size: size * 0.45,
              ),
            );
          },
        ),
      ),
    );
  }
}