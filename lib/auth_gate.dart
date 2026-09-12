import 'package:flutter/material.dart';

import 'pages/login_page.dart';

// ============================================================
// 🐱 STELLURIINI AUTH GATE
// ============================================================
//
// VAIHE 5
//
// Tässä vaiheessa:
//
// - LoginPage on testattu toimivaksi
// - HomePage on olemassa
// - LoginPage toimii käyttöliittymänä
// - HomePage ei saa enää aueta suoraan
//
// TÄRKEÄÄ:
//
// AuthGate näyttää nyt kirjautumissivun.
//
// Seuraavassa vaiheessa LoginPage yhdistetään oikeaan
// Firebase Authentication -kirjautumiseen.
//
// Kun Firebase-kirjautuminen on valmis:
//
// kirjautumaton käyttäjä
//        ↓
//     LoginPage
//        ↓
// onnistunut Firebase-kirjautuminen
//        ↓
//      HomePage
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
    // 🔐 LOGIN PAGE
    // ==========================================================
    //
    // ÄLÄ AVAA HOMEPAGEA SUORAAN.
    //
    // Tässä vaiheessa AuthGate näyttää aina LoginPagen.
    //
    // Firebase Authentication liitetään seuraavassa vaiheessa
    // LoginPageen.
    //
    // ==========================================================

    return LoginPage(
      languageCode: languageCode,
      changeLanguage: changeLanguage,
    );
  }
}