import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'pages/home_page.dart';
import 'pages/login_page.dart';

// ============================================================
// 🐱 STELLURIINI AUTH GATE
// ============================================================
//
// VAIHE 4
//
// AuthGate tarkistaa Firebase Authentication -tilan.
//
// Ei vielä:
// - AdMob
// - Firestore
// - Cloud Functions
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
        // FIREBASE AUTH TARKISTAA KIRJAUTUMISTILAN
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
        // KIRJAUTUNUT
        // ========================================================

        if (snapshot.hasData) {
          return HomePage(
            languageCode: languageCode,
            changeLanguage: changeLanguage,
          );
        }

        // ========================================================
        // EI KIRJAUTUNUT
        // ========================================================

        return LoginPage(
          languageCode: languageCode,
          changeLanguage: changeLanguage,
        );
      },
    );
  }
}