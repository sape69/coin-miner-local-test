import 'package:flutter/material.dart';

// ============================================================
// 🐱 STELLURIINI / STELLA CAT AVATAR
// ============================================================
//
// Yhtenäinen Stella-avatar koko Stelluriini-sovelluksessa.
//
// Käyttää samaa Stelluriini-logo-kuvaa kaikissa näkymissä.
// Jos kuvaa ei löydy, näytetään turvallinen fallback-kuvake.
//
// ============================================================

// ============================================================
// 🎨 STELLURIINI COLORS
// ============================================================

const Color catAvatarBackgroundColor =
    Color(0xFF120B24);

const Color catAvatarCardColor =
    Color(0xFF21113B);

const Color catAvatarAccentColor =
    Color(0xFFB58CFF);

const Color catAvatarPinkColor =
    Color(0xFFFFB7E8);

// ============================================================
// 🐱 CAT AVATAR
// ============================================================

class CatAvatar extends StatelessWidget {
  final double size;

  const CatAvatar({
    super.key,
    this.size = 100,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: catAvatarCardColor,
        border: Border.all(
          color: catAvatarAccentColor,
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: catAvatarAccentColor.withValues(
              alpha: 0.18,
            ),
            blurRadius: 18,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: catAvatarPinkColor.withValues(
              alpha: 0.08,
            ),
            blurRadius: 28,
            spreadRadius: 1,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: EdgeInsets.all(
          size * 0.06,
        ),
        child: Image.asset(
          'assets/images/stelluriini_logo.png',
          fit: BoxFit.contain,
          errorBuilder: (
            BuildContext context,
            Object error,
            StackTrace? stackTrace,
          ) {
            return const Center(
              child: Icon(
                Icons.pets,
                color: catAvatarAccentColor,
              ),
            );
          },
        ),
      ),
    );
  }
}