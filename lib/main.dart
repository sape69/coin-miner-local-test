import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'pages/login_page.dart';

// ============================================================
// 🐱 STELLURIINI - FIREBASE LOGIN TEST
// ============================================================
//
// VAIHE 3
//
// Tässä vaiheessa käytössä:
// - Firebase Core
// - Firebase Authentication
// - LoginPage
//
// Ei vielä:
// - AdMob
// - Firestore
// - Cloud Functions
// - AuthGate
// - SharedPreferences
//
// ============================================================

Future<void> main() async {
  // ----------------------------------------------------------
  // Flutter alustetaan ensin.
  // ----------------------------------------------------------

  WidgetsFlutterBinding.ensureInitialized();

  // ----------------------------------------------------------
  // Firebase alustetaan ennen LoginPagea.
  // ----------------------------------------------------------

  await Firebase.initializeApp();

  // ----------------------------------------------------------
  // Käynnistetään sovellus.
  // ----------------------------------------------------------

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

          tertiary:
              const Color(0xFFFFD166),
        ),
      ),

      // ========================================================
      // LOGIN PAGE
      // ========================================================

      home: LoginPage(
        languageCode: 'fi',

        changeLanguage:
            (String language) async {
          // Kielenvaihto palautetaan myöhemmin.
        },
      ),
    );
  }
}