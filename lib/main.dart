import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'auth_gate.dart';

// ============================================================
// 🐱 STELLURIINI
// ============================================================
//
// VAIHE 4
//
// Firebase alustetaan ennen AuthGatea ja HomePagea.
//
// Ketju:
//
// main.dart
//    ↓
// Firebase.initializeApp()
//    ↓
// AuthGate
//    ↓
// HomePage
//
// ============================================================

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ==========================================================
  // FIREBASE
  // ==========================================================

  await Firebase.initializeApp();

  // ==========================================================
  // APP
  // ==========================================================

  runApp(
    const StelluriiniApp(),
  );
}

// ============================================================
// APP
// ============================================================

class StelluriiniApp extends StatefulWidget {
  const StelluriiniApp({
    super.key,
  });

  @override
  State<StelluriiniApp> createState() =>
      _StelluriiniAppState();
}

class _StelluriiniAppState
    extends State<StelluriiniApp> {
  // ==========================================================
  // LANGUAGE
  // ==========================================================

  String _languageCode = 'fi';

  // ==========================================================
  // CHANGE LANGUAGE
  // ==========================================================

  Future<void> _changeLanguage(
    String language,
  ) async {
    if (!mounted) {
      return;
    }

    setState(() {
      _languageCode = language;
    });
  }

  // ==========================================================
  // BUILD
  // ==========================================================

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
      // AUTH GATE
      // ========================================================

      home: AuthGate(
        languageCode:
            _languageCode,

        changeLanguage:
            _changeLanguage,
      ),
    );
  }
}