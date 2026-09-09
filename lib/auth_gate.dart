import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'pages/home/home_page.dart';
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
      builder: (
        BuildContext context,
        AsyncSnapshot<User?> snapshot,
      ) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const LoadingPage();
        }

        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: const Color(0xFF120B24),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Authentication error',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFF8F4FF),
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          );
        }

        final User? user = snapshot.data;

        if (user != null) {
          return HomePage(
            languageCode: languageCode,
            changeLanguage: changeLanguage,
          );
        }

        return LoginPage(
          languageCode: languageCode,
          changeLanguage: changeLanguage,
        );
      },
    );
  }
}