import 'package:flutter/material.dart';

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
    // ============================================================
    // 🧪 DIAGNOSTIIKKATESTI
    // ============================================================
    //
    // FirebaseAuth on tarkoituksella pois käytöstä tässä testissä.
    //
    // Jos LoginPage toimii tämän jälkeen:
    //
    // → ongelma liittyy AuthGate/Firebase Auth -ketjuun.
    //
    // Jos harmaa alue näkyy edelleen:
    //
    // → ongelma ei ole Firebase Authissa.
    //
    // ============================================================

    return LoginPage(
      languageCode: languageCode,
      changeLanguage: changeLanguage,
    );
  }
}