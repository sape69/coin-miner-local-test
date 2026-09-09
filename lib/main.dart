import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth_gate.dart';
import 'pages/loading_page.dart';

// ============================================================
// 🐱 STELLURIINI / STELLA THEME
// ============================================================
//
// Keskitetty sovelluksen pääteema.
//
// Värit vastaavat nykyistä Stelluriini UI -ilmettä:
// - syvä violetti tausta
// - tumma violetti korttipinta
// - Stella purple
// - Stella pink
// - kultainen korostus
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

  // ==========================================================
  // FIREBASE
  // ==========================================================

  await Firebase.initializeApp();

  // ==========================================================
  // GOOGLE MOBILE ADS
  // ==========================================================

  await MobileAds.instance.initialize();

  // ==========================================================
  // START APP
  // ==========================================================

  runApp(
    const StelluriiniApp(),
  );
}

// ============================================================
// 🐱 STELLURIINI APP
// ============================================================

class StelluriiniApp extends StatefulWidget {
  const StelluriiniApp({
    super.key,
  });

  @override
  State<StelluriiniApp> createState() =>
      _StelluriiniAppState();
}

// ============================================================
// APP STATE
// ============================================================

class _StelluriiniAppState
    extends State<StelluriiniApp> {
  String languageCode = 'fi';

  bool languageLoaded = false;

  // ==========================================================
  // INIT STATE
  // ==========================================================

  @override
  void initState() {
    super.initState();

    _loadLanguage();
  }

  // ==========================================================
  // 🌍 LOAD LANGUAGE
  // ==========================================================

  Future<void> _loadLanguage() async {
    try {
      final prefs =
          await SharedPreferences.getInstance();

      final savedLanguage =
          prefs.getString('language') ?? 'fi';

      // Varmistetaan, että tallennettu kieli
      // kuuluu tuettuihin kieliin.
      const supportedLanguages = {
        'fi',
        'en',
        'de',
        'es',
        'fr',
        'zh',
        'vi',
        'ja',
      };

      final validLanguage =
          supportedLanguages.contains(savedLanguage)
              ? savedLanguage
              : 'fi';

      if (!mounted) {
        return;
      }

      setState(() {
        languageCode = validLanguage;
        languageLoaded = true;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        languageCode = 'fi';
        languageLoaded = true;
      });
    }
  }

  // ==========================================================
  // 🌍 CHANGE LANGUAGE
  // ==========================================================

  Future<void> changeLanguage(
    String language,
  ) async {
    const supportedLanguages = {
      'fi',
      'en',
      'de',
      'es',
      'fr',
      'zh',
      'vi',
      'ja',
    };

    // Jos joku komponentti yrittää asettaa
    // tuntemattoman kielen, palataan suomeen.
    final validLanguage =
        supportedLanguages.contains(language)
            ? language
            : 'fi';

    final prefs =
        await SharedPreferences.getInstance();

    await prefs.setString(
      'language',
      validLanguage,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      languageCode = validLanguage;
    });
  }

  // ==========================================================
  // 🌍 SUPPORTED LOCALES
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
  // 🎨 BUILD
  // ==========================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return MaterialApp(
      // ======================================================
      // APP INFORMATION
      // ======================================================

      title: 'Stelluriini',

      debugShowCheckedModeBanner: false,

      // ======================================================
      // 🌍 CURRENT APP LOCALE
      // ======================================================
      //
      // Tämä on tärkeä lisäys.
      //
      // languageCode tulee SharedPreferencesista ja
      // päivittyy heti, kun käyttäjä vaihtaa kieltä.
      //
      // Tämän ansiosta:
      //
      // AppLocalizations.of(context)
      //
      // saa saman aktiivisen kielen kuin muu sovellus.
      //
      // ======================================================

      locale: Locale(languageCode),

      supportedLocales: supportedLocales,

      // ======================================================
      // 🌌 STELLURIINI THEME
      // ======================================================

      theme: ThemeData(
        brightness: Brightness.dark,

        useMaterial3: true,

        // ----------------------------------------------------
        // BACKGROUND
        // ----------------------------------------------------

        scaffoldBackgroundColor:
            backgroundColor,

        // ----------------------------------------------------
        // COLOR SCHEME
        // ----------------------------------------------------

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

        // ----------------------------------------------------
        // APP BAR
        // ----------------------------------------------------

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

        // ----------------------------------------------------
        // CARDS
        // ----------------------------------------------------

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

        // ----------------------------------------------------
        // ELEVATED BUTTON
        // ----------------------------------------------------

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

        // ----------------------------------------------------
        // OUTLINED BUTTON
        // ----------------------------------------------------

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

        // ----------------------------------------------------
        // TEXT THEME
        // ----------------------------------------------------

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

        // ----------------------------------------------------
        // SNACKBAR
        // ----------------------------------------------------

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

        // ----------------------------------------------------
        // PROGRESS INDICATOR
        // ----------------------------------------------------

        progressIndicatorTheme:
            const ProgressIndicatorThemeData(
          color:
              stellaPurple,
        ),

        // ----------------------------------------------------
        // DIVIDERS
        // ----------------------------------------------------

        dividerTheme:
            const DividerThemeData(
          color:
              Color(0xFF352653),

          thickness:
              1,
        ),
      ),

      // ======================================================
      // 🏠 START PAGE
      // ======================================================

      home:
          languageLoaded
              ? AuthGate(
                  languageCode:
                      languageCode,

                  changeLanguage:
                      changeLanguage,
                )
              : const LoadingPage(),
    );
  }
}