import 'package:flutter/material.dart';

// ============================================================
// 🐱 STELLURIINI / STELLA LOADING PAGE
// ============================================================
//
// Sovelluksen latausnäkymä.
//
// Käytetään samaa Stelluriini-teemaa kuin muualla sovelluksessa.
// Ei riipu main.dart-tiedostosta.
//
// ============================================================

// ============================================================
// 🎨 STELLURIINI COLORS
// ============================================================

const Color loadingBackgroundColor =
    Color(0xFF120B24);

const Color loadingAccentColor =
    Color(0xFFB58CFF);

// ============================================================
// ⏳ LOADING PAGE
// ============================================================

class LoadingPage extends StatelessWidget {
  const LoadingPage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor:
          loadingBackgroundColor,
      body: Center(
        child: CircularProgressIndicator(
          color:
              loadingAccentColor,
        ),
      ),
    );
  }
}