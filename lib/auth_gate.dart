import 'package:flutter/material.dart';

import 'pages/home/home_page.dart';
import 'pages/login_page.dart';

// ============================================================
// 🐱 STELLURIINI AUTH GATE
// ============================================================
//
// Tässä vaiheessa:
// - LoginPage toimii
// - HomePage on olemassa
// - HomePage sijaitsee kansiossa pages/home/
// - Firebase Auth voidaan ottaa käyttöön seuraavassa vaiheessa
//
// Tärkeä korjaus:
// HomePage sijaitsee:
//
// lib/pages/home/home_page.dart
//
// eikä:
//
// lib/pages/home_page.dart
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
    // Kirjautuminen on juuri testattu onnistuneesti.
    //
    // Seuraavassa vaiheessa voidaan palauttaa FirebaseAuth-
    // kuuntelu tähän kohtaan.
    //
    // ==========================================================

    return HomePage(
      languageCode: languageCode,
      changeLanguage: changeLanguage,
    );
  }
}