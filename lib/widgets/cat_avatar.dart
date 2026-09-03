import 'package:flutter/material.dart';

// ============================================================
// CAT AVATAR
//
// Käyttää kaikkialla samaa Stelluriini-logo-kuvaa.
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
        color: const Color(0xFF151B1C),
        border: Border.all(
          color: const Color(0xFF35D0A0),
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF35D0A0)
                .withValues(alpha: 0.18),
            blurRadius: 18,
            spreadRadius: 2,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: EdgeInsets.all(size * 0.06),
        child: Image.asset(
          'assets/images/stelluriini_logo.png',
          fit: BoxFit.contain,
          errorBuilder: (
            context,
            error,
            stackTrace,
          ) {
            return const Center(
              child: Icon(
                Icons.pets,
                color: Color(0xFF35D0A0),
              ),
            );
          },
        ),
      ),
    );
  }
}