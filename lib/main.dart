import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth_gate.dart';

// ============================================================
// 🐱 STELLURIINI
// ============================================================
//
// APP STARTUP
//
// 1. Firebase
// 2. Google Analytics
// 3. Google Mobile Ads
// 4. Stelluriini app
//
// ANALYTICS
//
// - Google Analytics alustetaan sovelluksen käynnistyessä.
// - Ruudunäkymien seuranta on käytössä NavigatorObserverilla.
// - Analytics kerää käyttötilastoja raportointia varten.
//
// LANGUAGE
//
// Ensimmäisellä asennuksella oletuskieli on englanti.
// Käyttäjän kielivalinta tallennetaan SharedPreferencesiin.
//
// ============================================================

Future<void> main() async {
WidgetsFlutterBinding.ensureInitialized();

// ==========================================================
// FIREBASE
// ==========================================================

await Firebase.initializeApp();

// ==========================================================
// GOOGLE ANALYTICS
// ==========================================================

try {
await FirebaseAnalytics.instance
.setAnalyticsCollectionEnabled(true);

debugPrint(
  '🐱 Stelluriini: Google Analytics initialized.',
);

} catch (error) {
debugPrint(
'🐱 Stelluriini: Google Analytics initialization error: $error',
);
}

// ==========================================================
// GOOGLE MOBILE ADS
// ==========================================================

try {
await MobileAds.instance.initialize();

debugPrint(
  '🐱 Stelluriini: Google Mobile Ads SDK initialized.',
);

} catch (error) {
debugPrint(
'🐱 Stelluriini: Google Mobile Ads initialization error: $error',
);
}

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
    '🐱 Stelluriini: Language load error: $error',
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
    '🐱 Stelluriini: Language save error: $error',
  );
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

  // ========================================================
  // AUTH GATE
  // ========================================================

  home: AuthGate(
    languageCode: _languageCode,
    changeLanguage: _changeLanguage,
  ),
);

}
}