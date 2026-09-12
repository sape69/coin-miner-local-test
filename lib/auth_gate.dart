import 'package:flutter/material.dart';

import 'pages/home/home_page.dart';

// ============================================================
// 🐱 STELLURIINI AUTH GATE
// ============================================================
//
// Tässä vaiheessa:
//
// - LoginPage on testattu toimivaksi
// - HomePage on olemassa
// - HomePage sijaitsee kansiossa pages/home/
// - Firebase Auth palautetaan myöhemmin tähän ketjuun
//
// HomePage:n oikea polku:
//
// lib/pages/home/home_page.dart
//
// ============================================================

class AuthGate extends StatelessWidget {
  final String languageCode;
  final Future<void> Function(String) changeLanguage;

  const AuthGate({
    super.key,
    required this.languageCode,
    required this.changeLanguage,
  });

  @override
  Widget build(BuildContext context) {
    // ==========================================================
    // VÄLIAIKAINEN TESTITILA
    // ==========================================================
    //
    // LoginPage ja tekstikentät on jo testattu onnistuneesti.
    //
    // Nyt siirrytään HomePageen.
    //
    // Firebase Auth voidaan palauttaa myöhemmin tähän kohtaan.
    //
    // ==========================================================

    return HomePage(
      languageCode: languageCode,
      changeLanguage: changeLanguage,
    );
  }
}