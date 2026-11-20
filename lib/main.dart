
import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth_gate.dart';
import 'services/mining_notification_service.dart';

// ============================================================
// 🐱 STELLURIINI - FAST STARTUP
// ============================================================
//
// 1. Flutter UI opens immediately.
// 2. Firebase initializes in the background.
// 3. AuthGate opens after Firebase is ready.
// 4. Optional services initialize after the first UI frame.
//
// ============================================================

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Open Flutter UI immediately.
  runApp(
    const StelluriiniBootstrapApp(),
  );
}

// ============================================================
// BACKGROUND SERVICES
// ============================================================

Future<void> initializeBackgroundServices() async {
  // GOOGLE ANALYTICS
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

  // GOOGLE MOBILE ADS
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

  // MINING NOTIFICATIONS
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
// BOOTSTRAP APP
// ============================================================

class StelluriiniBootstrapApp extends StatefulWidget {
  const StelluriiniBootstrapApp({
    super.key,
  });

  @override
  State<StelluriiniBootstrapApp> createState() =>
      _StelluriiniBootstrapAppState();
}

class _StelluriiniBootstrapAppState
    extends State<StelluriiniBootstrapApp> {
  bool _firebaseReady = false;
  String? _startupError;

  @override
  void initState() {
    super.initState();

    // Firebase initialization starts after Flutter UI is launched.
    unawaited(
      _initializeFirebase(),
    );
  }

  Future<void> _initializeFirebase() async {
    try {
      await Firebase.initializeApp();

      debugPrint(
        '🐱 Stelluriini: Firebase initialized successfully.',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _firebaseReady = true;
      });
    } catch (error, stackTrace) {
      debugPrint(
        '🐱 Stelluriini: Firebase initialization failed: $error',
      );
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) {
        return;
      }

      setState(() {
        _startupError = error.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_startupError != null) {
      return StartupErrorApp(
        message: _startupError!,
      );
    }

    if (!_firebaseReady) {
      return const StelluriiniLoadingApp();
    }

    return const StelluriiniApp();
  }
}

// ============================================================
// IMMEDIATE LOADING SCREEN
// ============================================================

class StelluriiniLoadingApp extends StatelessWidget {
  const StelluriiniLoadingApp({
    super.key,
  });

  static const Color backgroundColor = Color(0xFF120B24);
  static const Color purpleColor = Color(0xFFB58CFF);
  static const Color pinkColor = Color(0xFFFFB7E8);
  static const Color textColor = Color(0xFFF8F4FF);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Stelluriini',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: backgroundColor,
        colorScheme: ColorScheme.fromSeed(
          seedColor: purpleColor,
          brightness: Brightness.dark,
        ),
      ),
      home: Scaffold(
        backgroundColor: backgroundColor,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.pets,
                  size: 76,
                  color: purpleColor,
                ),
                const SizedBox(height: 18),
                const Text(
                  'Stelluriini',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Preparing Stella...',
                  style: TextStyle(
                    color: pinkColor,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 32),
                const SizedBox(
                  width: 30,
                  height: 30,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: purpleColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
                    'Application startup failed.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      color: Color(0xFFFFB7E8),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Firebase could not be initialized. '
                    'Check your connection and try again.',
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
  // LANGUAGE
  String _languageCode = 'en';

  static const String _languageKey =
      'stelluriini_language';

  // ANALYTICS
  late final FirebaseAnalyticsObserver _analyticsObserver =
      FirebaseAnalyticsObserver(
    analytics: FirebaseAnalytics.instance,
  );

  @override
  void initState() {
    super.initState();

    _loadLanguage();

    // Initialize optional services after the first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(
        initializeBackgroundServices(),
      );
    });
  }

  // LOAD LANGUAGE
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

  // CHANGE LANGUAGE
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

  // BUILD
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
