import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth_gate.dart';

// ============================================================
// 🐱 STELLURIINI
// ============================================================
//
// LANGUAGE
//
// Ensimmäisellä asennuksella oletuskieli on englanti.
//
// Jos käyttäjä vaihtaa kieltä:
//    ↓
// valinta tallennetaan SharedPreferencesiin
//
// Seuraavalla käynnistyksellä:
//    ↓
// viimeksi valittu kieli ladataan
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

  // Ensimmäisellä asennuksella englanti.
  String _languageCode = 'en';

  // Käytetään samaa avainta aina kielen tallennukseen.
  static const String _languageKey =
      'stelluriini_language';

  // ==========================================================
  // INIT
  // ==========================================================

  @override
  void initState() {
    super.initState();

    _loadLanguage();
  }

  // ==========================================================
  // LOAD LANGUAGE
  // ==========================================================

  Future<void> _loadLanguage() async {
    try {
      final SharedPreferences preferences =
          await SharedPreferences.getInstance();

      final String savedLanguage =
          preferences.getString(_languageKey) ?? 'en';

      if (!mounted) {
        return;
      }

      setState(() {
        _languageCode = savedLanguage;
      });
    } catch (error) {
      debugPrint(
        'Language load error: $error',
      );
    }
  }

  // ==========================================================
  // CHANGE LANGUAGE
  // ==========================================================

  Future<void> _changeLanguage(
    String language,
  ) async {
    try {
      final SharedPreferences preferences =
          await SharedPreferences.getInstance();

      await preferences.setString(
        _languageKey,
        language,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _languageCode = language;
      });
    } catch (error) {
      debugPrint(
        'Language save error: $error',
      );
    }
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