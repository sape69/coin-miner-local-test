import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'pages/home/home_page.dart';
import 'pages/login_page.dart';

// ============================================================
// 🐱 STELLURIINI AUTH GATE
// ============================================================
//
// AuthGate päättää näytetäänkö LoginPage vai HomePage.
//
// EI KIRJAUTUNUT
//      ↓
// LoginPage
//
// KIRJAUTUNUT
//      ↓
// HomePage
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
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (
        BuildContext context,
        AsyncSnapshot<User?> snapshot,
      ) {
        // ========================================================
        // ⏳ TARKISTETAAN KIRJAUTUMISTILA
        // ========================================================

        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF120B24),
            body: Center(
              child: CircularProgressIndicator(
                color: Color(0xFFB58CFF),
              ),
            ),
          );
        }

        // ========================================================
        // 🔐 EI KIRJAUTUNUT → LOGIN PAGE
        // ========================================================

        if (!snapshot.hasData ||
            snapshot.data == null) {
          return LoginPage(
            languageCode: languageCode,
            changeLanguage: changeLanguage,
          );
        }

        // ========================================================
        // 🏠 KIRJAUTUNUT → HOME PAGE
        // ========================================================

        return HomePage(
          languageCode: languageCode,
          changeLanguage: changeLanguage,
        );
      },
    );
  }
}