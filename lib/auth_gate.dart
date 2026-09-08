import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'pages/home/home_page.dart';
import 'pages/loading_page.dart';
import 'pages/login_page.dart';

// ============================================================
// 🔐 STELLURIINI / AUTH GATE
// ============================================================
//
// AuthGate päättää, mikä näkymä käyttäjälle näytetään:
//
// 1. Firebase Authentication latautuu
//    → LoadingPage
//
// 2. Käyttäjä on kirjautunut
//    → HomePage
//
// 3. Käyttäjä ei ole kirjautunut
//    → LoginPage
//
// Firebase Auth seuraa kirjautumistilaa reaaliaikaisesti.
// ============================================================

class AuthGate extends StatelessWidget {
  final String languageCode;

  final Future<void> Function(String) changeLanguage;

  const AuthGate({
    super.key,
    required this.languageCode,
    required this.changeLanguage,
  });

  // ==========================================================
  // 🏠 BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (
        BuildContext context,
        AsyncSnapshot<User?> snapshot,
      ) {
        // ====================================================
        // ⏳ FIREBASE AUTH LATAUTUU
        // ====================================================

        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const LoadingPage();
        }

        // ====================================================
        // 🏠 KÄYTTÄJÄ ON KIRJAUTUNUT
        // ====================================================

        if (snapshot.hasData &&
            snapshot.data != null) {
          return HomePage(
            languageCode: languageCode,
            changeLanguage: changeLanguage,
          );
        }

        // ====================================================
        // 🔐 KÄYTTÄJÄ EI OLE KIRJAUTUNUT
        // ====================================================

        return LoginPage(
          languageCode: languageCode,
          changeLanguage: changeLanguage,
        );
      },
    );
  }
}