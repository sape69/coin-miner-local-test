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

  await Firebase.initializeApp();
  await MobileAds.instance.initialize();

  runApp(const StelluriiniApp());
}

class StelluriiniApp extends StatefulWidget {
  const StelluriiniApp({super.key});

  @override
  State<StelluriiniApp> createState() => _StelluriiniAppState();
}

class _StelluriiniAppState extends State<StelluriiniApp> {
  String languageCode = 'fi';
  bool languageLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();

    final savedLanguage = prefs.getString('language') ?? 'fi';

    if (!mounted) return;

    setState(() {
      languageCode = savedLanguage;
      languageLoaded = true;
    });
  }

  Future<void> changeLanguage(String language) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('language', language);

    if (!mounted) return;

    setState(() {
      languageCode = language;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stelluriini',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        scaffoldBackgroundColor: backgroundColor,
        colorScheme: ColorScheme.fromSeed(
          seedColor: accentColor,
          brightness: Brightness.dark,
        ),
        cardTheme: const CardThemeData(
          color: cardColor,
          elevation: 2,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: backgroundColor,
          foregroundColor: Colors.white,
          centerTitle: true,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: accentColor,
            foregroundColor: Colors.black,
          ),
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