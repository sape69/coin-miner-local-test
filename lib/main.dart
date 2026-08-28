import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth_gate.dart';
import 'pages/loading_page.dart';

const Color backgroundColor = Color(0xFF0B1112);
const Color cardColor = Color(0xFF151B1C);
const Color accentColor = Color(0xFF35D0A0);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase alustetaan ennen sovelluksen käynnistämistä.
  await Firebase.initializeApp();

  // Google Mobile Ads alustetaan.
  await MobileAds.instance.initialize();

  runApp(const StelluriiniApp());
}

class StelluriiniApp extends StatefulWidget {
  const StelluriiniApp({super.key});

  @override
  State<StelluriiniApp> createState() =>
      _StelluriiniAppState();
}

class _StelluriiniAppState
    extends State<StelluriiniApp> {
  String languageCode = 'fi';

  bool languageLoaded = false;

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
      final prefs =
          await SharedPreferences.getInstance();

      final savedLanguage =
          prefs.getString('language') ?? 'fi';

      if (!mounted) return;

      setState(() {
        languageCode = savedLanguage;
        languageLoaded = true;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        languageCode = 'fi';
        languageLoaded = true;
      });
    }
  }

  // ==========================================================
  // CHANGE LANGUAGE
  // ==========================================================

  Future<void> changeLanguage(
    String language,
  ) async {
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.setString(
      'language',
      language,
    );

    if (!mounted) return;

    setState(() {
      languageCode = language;
    });
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return MaterialApp(
      title: 'Stelluriini',

      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        brightness: Brightness.dark,

        useMaterial3: true,

        scaffoldBackgroundColor:
            backgroundColor,

        colorScheme:
            ColorScheme.fromSeed(
          seedColor: accentColor,
          brightness: Brightness.dark,
        ),

        cardTheme: const CardThemeData(
          color: cardColor,
          elevation: 2,
          margin: EdgeInsets.zero,
        ),

        appBarTheme: const AppBarTheme(
          backgroundColor: backgroundColor,
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 0,
        ),

        elevatedButtonTheme:
            ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: accentColor,
            foregroundColor: Colors.black,
            elevation: 0,
            textStyle: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        snackBarTheme:
            const SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
        ),

        progressIndicatorTheme:
            const ProgressIndicatorThemeData(
          color: accentColor,
        ),
      ),

      home: languageLoaded
          ? AuthGate(
              languageCode: languageCode,
              changeLanguage: changeLanguage,
            )
          : const LoadingPage(),
    );
  }
}