import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'pages/home_page.dart';
import 'pages/loading_page.dart';
import 'pages/login_page.dart';

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
      builder: (context, snapshot) {
        // Firebase Authenticationin tila latautuu.
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const LoadingPage();
        }

        // Käyttäjä on kirjautunut sisään.
        if (snapshot.hasData &&
            snapshot.data != null) {
          return const HomePage();
        }

        // Käyttäjä ei ole kirjautunut sisään.
        return LoginPage(
          languageCode: languageCode,
          changeLanguage: changeLanguage,
        );
      },
    );
  }
}