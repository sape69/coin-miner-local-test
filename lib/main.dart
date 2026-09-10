import 'package:flutter/material.dart';

import 'auth_gate.dart';

// ============================================================
// 🐱 STELLURIINI / STELLA THEME
// ============================================================
//
// DIAGNOSTIIKKAVERSIO
//
// Tässä testissä Firebase, AdMob ja SharedPreferences
// eivät ole mukana.
//
// Tarkoitus on selvittää, syntyykö harmaa alue jo
// sovelluksen perusrakenteessa.
//
// Kun testi on valmis, palautamme tarvittavat palvelut
// takaisin yksi kerrallaan.
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

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    const StelluriiniApp(),
  );
}

// ============================================================
// 🐱 STELLURIINI APP
// ============================================================

class StelluriiniApp extends StatelessWidget {
  const StelluriiniApp({
    super.key,
  });

  // ==========================================================
  // 🌍 SUPPORTED LANGUAGES
  // ==========================================================

  List<Locale> get supportedLocales {
    return const [
      Locale('fi'),
      Locale('en'),
      Locale('de'),
      Locale('es'),
      Locale('fr'),
      Locale('zh'),
      Locale('vi'),
      Locale('ja'),
    ];
  }

  // ==========================================================
  // 🌍 TEMPORARY LANGUAGE FUNCTION
  // ==========================================================
  //
  // AuthGate tarvitsee changeLanguage-funktion.
  //
  // Tässä testissä kielenvaihto ei muuta sovellusta,
  // koska testaamme tällä hetkellä vain renderöintiä
  // ja tekstinsyöttöä.
  //
  // ==========================================================

  Future<void> _changeLanguage(
    String language,
  ) async {
    // Diagnostiikkatestissä ei tehdä mitään.
  }

  // ==========================================================
  // 🎨 THEME
  // ==========================================================

  ThemeData get appTheme {
    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,

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

      // ========================================================
      // APP BAR
      // ========================================================

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

      // ========================================================
      // CARD
      // ========================================================

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

      // ========================================================
      // ELEVATED BUTTON
      // ========================================================

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

      // ========================================================
      // OUTLINED BUTTON
      // ========================================================

      outlinedButtonTheme:
          OutlinedButtonThemeData(
        style:
            OutlinedButton.styleFrom(
          foregroundColor:
              primaryTextColor,
          side:
              const BorderSide(
            color:
                stellaPurple,
            width:
                1.5,
          ),
          minimumSize:
              const Size(
            double.infinity,
            52,
          ),
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(18),
          ),
        ),
      ),

      // ========================================================
      // TEXT THEME
      // ========================================================

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

      // ========================================================
      // SNACKBAR
      // ========================================================

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

      // ========================================================
      // PROGRESS INDICATOR
      // ========================================================

      progressIndicatorTheme:
          const ProgressIndicatorThemeData(
        color:
            stellaPurple,
      ),

      // ========================================================
      // DIVIDER
      // ========================================================

      dividerTheme:
          const DividerThemeData(
        color:
            Color(0xFF352653),
        thickness:
            1,
      ),
    );
  }

  // ==========================================================
  // 🖥️ BUILD
  // ==========================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return MaterialApp(
      title:
          'Stelluriini',

      debugShowCheckedModeBanner:
          false,

      // ========================================================
      // 🌍 TEST LANGUAGE
      // ========================================================

      locale:
          const Locale('fi'),

      supportedLocales:
          supportedLocales,

      // ========================================================
      // 🎨 THEME
      // ========================================================

      theme:
          appTheme,

      // ========================================================
      // 🚪 AUTH GATE
      // ========================================================
      //
      // AuthGate on tällä hetkellä diagnostiikkaversio,
      // joka näyttää suoraan LoginPage-sivun.
      //
      // ========================================================

      home:
          AuthGate(
        languageCode:
            'fi',
        changeLanguage:
            _changeLanguage,
      ),
    );
  }
}