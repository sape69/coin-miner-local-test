
import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth_gate.dart';
import 'services/mining_notification_service.dart';

// ============================================================
// 🐱 STELLURIINI
// ============================================================
//
// SAFE STARTUP
//
// 1. Initialize Firebase.
// 2. Open the Stelluriini interface immediately.
// 3. Initialize Analytics in the background.
// 4. Initialize Google Mobile Ads in the background.
// 5. Initialize mining notifications in the background.
//
// Optional services must never prevent the app from opening.
//
// ============================================================

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ==========================================================
  // FIREBASE INITIALIZATION
  // ==========================================================

  try {
    await Firebase.initializeApp();

    debugPrint(
      '🐱 Stelluriini: Firebase initialized successfully.',
    );
  } catch (error, stackTrace) {
    debugPrint(
      '🐱 Stelluriini: Firebase initialization failed: $error',
    );
    debugPrintStack(stackTrace: stackTrace);

    runApp(
      StartupErrorApp(
        message: error.toString(),
      ),
    );

    return;
  }

  // ==========================================================
  // OPEN APP IMMEDIATELY
  // ==========================================================

  runApp(
    const StelluriiniApp(),
  );
}

// ============================================================
// BACKGROUND SERVICE INITIALIZATION
// ============================================================

Future<void> initializeBackgroundServices() async {
  // ==========================================================
  // GOOGLE ANALYTICS
  // ==========================================================

  try {
    await FirebaseAnalytics.instance
        .setAnalyticsCollectionEnabled(true);

    debugPrint(
      '🐱 Stelluriini: Google Analytics initialized.',
    );
  } catch (error, stackTrace) {
    debugPrint(
      '🐱 Stelluriini: Google Analytics error: $error',
    );
    debugPrintStack(stackTrace: stackTrace);
  }

  // ==========================================================
  // GOOGLE MOBILE ADS
  // ==========================================================

  try {
    await MobileAds.instance.initialize();

    debugPrint(
      '🐱 Stelluriini: Google Mobile Ads initialized.',
    );
  } catch (error, stackTrace) {
    debugPrint(
      '🐱 Stelluriini: Google Mobile Ads error: $error',
    );
    debugPrintStack(stackTrace: stackTrace);
  }

  // ==========================================================
  // MINING NOTIFICATIONS
  // ==========================================================

  try {
    await MiningNotificationService.instance.initialize();

    debugPrint(
      '🐱 Stelluriini: Mining notifications initialized.',
    );
  } catch (error, stackTrace) {
    debugPrint(
      '🐱 Stelluriini: Notification initialization error: $error',
    );
    debugPrintStack(stackTrace: stackTrace);
  }
}

// ============================================================
// STARTUP ERROR APP
// ============================================================

class StartupErrorApp extends StatelessWidget {
  final String message;

  const StartupErrorApp({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Stelluriini',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF120B24),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFB58CFF),
          brightness: Brightness.dark,
        ),
      ),
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.pets,
                    size: 64,
                    color: Color(0xFFB58CFF),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Stelluriini',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFF8F4FF),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Sovelluksen käynnistys epäonnistui.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      color: Color(0xFFFFB7E8),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Firebase-palveluun ei saatu yhteyttä. '
                    'Tarkista yhteys ja yritä uudelleen.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFFBDB4D1),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SelectableText(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFFBDB4D1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// STELLURIINI APP
// ============================================================

class StelluriiniApp extends StatefulWidget {
  const StelluriiniApp({
    super.key,
  });

  @override
  State<StelluriiniApp> createState() =>
      _StelluriiniAppState();
}

class _StelluriiniAppState extends State<StelluriiniApp> {
  // ==========================================================
  // LANGUAGE
  // ==========================================================

  String _languageCode = 'en';

  static const String _languageKey =
      'stelluriini_language';

  // ==========================================================
  // ANALYTICS
  // ==========================================================

  final FirebaseAnalyticsObserver _analyticsObserver =
      FirebaseAnalyticsObserver(
    analytics: FirebaseAnalytics.instance,
  );

  // ==========================================================
  // INIT
  // ==========================================================

  @override
  void initState() {
    super.initState();

    _loadLanguage();

    // Start optional services only after the first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(
        initializeBackgroundServices(),
      );
    });
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
    } catch (error, stackTrace) {
      debugPrint(
        '🐱 Stelluriini: Language load error: $error',
      );
      debugPrintStack(stackTrace: stackTrace);
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
    } catch (error, stackTrace) {
      debugPrint(
        '🐱 Stelluriini: Language save error: $error',
      );
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorObservers: <NavigatorObserver>[
        _analyticsObserver,
      ],
      debugShowCheckedModeBanner: false,
      title: 'Stelluriini',
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        scaffoldBackgroundColor:
            const Color(0xFF120B24),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFB58CFF),
          brightness: Brightness.dark,
          primary: const Color(0xFFB58CFF),
          secondary: const Color(0xFFFFB7E8),
        ),
      ),
      home: AuthGate(
        languageCode: _languageCode,
        changeLanguage: _changeLanguage,
      ),
    );
  }
}
