import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'auth_gate.dart';

const Color backgroundColor =
    Color(0xFF120B24);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  await MobileAds.instance.initialize();

  runApp(
    const StelluriiniApp(),
  );
}

class StelluriiniApp extends StatelessWidget {
  const StelluriiniApp({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
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
          surface:
              const Color(0xFF1A0E31),
        ),
      ),
      home: AuthGate(
        languageCode: 'fi',
        changeLanguage:
            (String language) async {},
      ),
    );
  }
}