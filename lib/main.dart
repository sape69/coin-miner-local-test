import 'package:flutter/material.dart';

import 'pages/login_page.dart';

// ============================================================
// STELLURIINI - LOGIN PAGE TEST
// ============================================================
//
// Tässä vaiheessa testataan vain LoginPagea.
//
// EI:
// - Firebasea
// - AdMobia
// - SharedPreferencesia
// - AuthGatea
// - LoadingPagea
//
// ============================================================

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    const StelluriiniApp(),
  );
}

// ============================================================
// APP
// ============================================================

class StelluriiniApp extends StatelessWidget {
  const StelluriiniApp({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      title: 'Stelluriini',

      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,

        scaffoldBackgroundColor:
            const Color(0xFF120B24),

        colorScheme:
            ColorScheme.fromSeed(
          seedColor:
              const Color(0xFFB58CFF),

          brightness:
              Brightness.dark,

          primary:
              const Color(0xFFB58CFF),

          secondary:
              const Color(0xFFFFB7E8),
        ),
      ),

      // ========================================================
      // SUORAAN LOGINPAGEEN
      // ========================================================

      home: LoginPage(
        languageCode: 'fi',

        changeLanguage:
            (String language) async {
          // Kielenvaihto otetaan käyttöön myöhemmin.
        },
      ),
    );
  }
}