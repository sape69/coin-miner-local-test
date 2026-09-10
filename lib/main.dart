import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'pages/login_page.dart';

// ============================================================
// 🐱 STELLURIINI / LOGIN ISOLATION TEST
// ============================================================
//
// VÄLIAIKAINEN VIANMÄÄRITYSTESTI
//
// Tässä testissä:
// - Firebase alustetaan
// - AdMobia EI alusteta
// - SharedPreferencesia EI käytetä
// - AuthGatea EI käytetä
// - LoadingPagea EI käytetä
//
// LoginPage avataan SUORAAN.
//
// Tämän avulla selvitetään, tuleeko harmaa alue:
// 1. AuthGate-rakenteesta
// 2. Firebase-alustuksesta
// 3. vai LoginPageen liittyvästä muusta rakenteesta.
//
// ============================================================

// ============================================================
// 🎨 STELLURIINI COLORS
// ============================================================

const Color backgroundColor =
    Color(0xFF120B24);

const Color surfaceColor =
    Color(0xFF1A0E31);

const Color cardColor =
    Color(0xFF21113B);

const Color stellaPurple =
    Color(0xFFB58CFF);

const Color stellaPink =
    Color(0xFFFFB7E8);

const Color starGold =
    Color(0xFFFFD166);

const Color primaryTextColor =
    Color(0xFFF8F4FF);

const Color secondaryTextColor =
    Color(0xFFBDB4D1);

// ============================================================
// 🚀 MAIN
// ============================================================

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase pidetään mukana testissä.
  await Firebase.initializeApp();

  // AdMobia EI alusteta.
  // SharedPreferencesia EI alusteta.
  // AuthGatea EI käytetä.

  runApp(
    const StelluriiniLoginTestApp(),
  );
}

// ============================================================
// APP
// ============================================================

class StelluriiniLoginTestApp
    extends StatelessWidget {
  const StelluriiniLoginTestApp({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stelluriini',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness:
            Brightness.dark,
        useMaterial3:
            true,
        scaffoldBackgroundColor:
            backgroundColor,
        colorScheme:
            ColorScheme.fromSeed(
          seedColor:
              stellaPurple,
          brightness:
              Brightness.dark,
          primary:
              stellaPurple,
          secondary:
              stellaPink,
          tertiary:
              starGold,
          surface:
              surfaceColor,
        ),
        appBarTheme:
            const AppBarTheme(
          backgroundColor:
              backgroundColor,
          foregroundColor:
              primaryTextColor,
          centerTitle:
              true,
          elevation:
              0,
          titleTextStyle:
              TextStyle(
            color:
                primaryTextColor,
            fontSize:
                20,
            fontWeight:
                FontWeight.bold,
          ),
        ),
        cardTheme:
            const CardThemeData(
          color:
              cardColor,
          elevation:
              0,
          margin:
              EdgeInsets.zero,
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.all(
              Radius.circular(24),
            ),
          ),
        ),
        elevatedButtonTheme:
            ElevatedButtonThemeData(
          style:
              ElevatedButton.styleFrom(
            backgroundColor:
                stellaPurple,
            foregroundColor:
                Colors.white,
            elevation:
                0,
            minimumSize:
                const Size(
              double.infinity,
              54,
            ),
            shape:
                RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(18),
            ),
            textStyle:
                const TextStyle(
              fontWeight:
                  FontWeight.bold,
              fontSize:
                  16,
            ),
          ),
        ),
        textTheme:
            const TextTheme(
          headlineLarge:
              TextStyle(
            color:
                primaryTextColor,
            fontWeight:
                FontWeight.bold,
          ),
          headlineMedium:
              TextStyle(
            color:
                primaryTextColor,
            fontWeight:
                FontWeight.bold,
          ),
          titleLarge:
              TextStyle(
            color:
                primaryTextColor,
            fontWeight:
                FontWeight.bold,
          ),
          titleMedium:
              TextStyle(
            color:
                primaryTextColor,
            fontWeight:
                FontWeight.w600,
          ),
          bodyLarge:
              TextStyle(
            color:
                primaryTextColor,
          ),
          bodyMedium:
              TextStyle(
            color:
                secondaryTextColor,
          ),
          bodySmall:
              TextStyle(
            color:
                secondaryTextColor,
          ),
        ),
        snackBarTheme:
            SnackBarThemeData(
          behavior:
              SnackBarBehavior.floating,
          backgroundColor:
              cardColor,
          contentTextStyle:
              const TextStyle(
            color:
                primaryTextColor,
          ),
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(16),
          ),
        ),
        progressIndicatorTheme:
            const ProgressIndicatorThemeData(
          color:
              stellaPurple,
        ),
        dividerTheme:
            const DividerThemeData(
          color:
              Color(0xFF352653),
          thickness:
              1,
        ),
      ),

      // ========================================================
      // LOGIN AVATAAN SUORAAN
      // ========================================================

      home: LoginPage(
        languageCode: 'fi',
        changeLanguage:
            _testChangeLanguage,
      ),
    );
  }

  static Future<void> _testChangeLanguage(
    String language,
  ) async {
    // Ei tehdä mitään.
    //
    // Tämä on vain testin vuoksi.
    // SharedPreferences ei ole mukana tässä testissä.
  }
}