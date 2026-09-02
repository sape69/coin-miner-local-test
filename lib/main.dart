import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth_gate.dart';
import 'pages/loading_page.dart';


// ============================================================
// STELLA'S WORLD THEME COLORS
// ============================================================

// Syvä avaruustausta.
const Color backgroundColor = Color(0xFF090B1A);

// Hieman vaaleampi avaruuspinta.
const Color surfaceColor = Color(0xFF12162B);

// Korttien taustaväri.
const Color cardColor = Color(0xFF171C35);

// Stella-purppura.
const Color stellaPurple = Color(0xFF9B6CFF);

// Stella-vaaleanpunainen.
const Color stellaPink = Color(0xFFFF79C6);

// Tähtien kultainen väri.
const Color starGold = Color(0xFFFFD166);

// STL-kolikon mint-väri.
const Color accentColor = Color(0xFF35D0A0);

// Vaalea teksti.
const Color primaryTextColor = Color(0xFFF5F3FF);

// Toissijainen teksti.
const Color secondaryTextColor = Color(0xFFB7B4C9);


// ============================================================
// MAIN
// ============================================================

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase alustetaan ennen sovelluksen käynnistämistä.
  await Firebase.initializeApp();

  // Google Mobile Ads alustetaan.
  await MobileAds.instance.initialize();

  runApp(const StelluriiniApp());
}


// ============================================================
// STELLURIINI APP
// ============================================================

class StelluriiniApp extends StatefulWidget {
  const StelluriiniApp({super.key});

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
      title: 'Stella\'s World',

      debugShowCheckedModeBanner: false,


      // ======================================================
      // STELLA'S WORLD THEME
      // ======================================================

      theme: ThemeData(

        brightness: Brightness.dark,

        useMaterial3: true,


        // ====================================================
        // BACKGROUND
        // ====================================================

        scaffoldBackgroundColor:
            backgroundColor,


        // ====================================================
        // COLOR SCHEME
        // ====================================================

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


        // ====================================================
        // APP BAR
        // ====================================================

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


        // ====================================================
        // CARDS
        // ====================================================

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


        // ====================================================
        // ELEVATED BUTTON
        // ====================================================

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


        // ====================================================
        // OUTLINED BUTTON
        // ====================================================

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


        // ====================================================
        // TEXT
        // ====================================================

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


        // ====================================================
        // SNACKBAR
        // ====================================================

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


        // ====================================================
        // PROGRESS INDICATOR
        // ====================================================

        progressIndicatorTheme:
            const ProgressIndicatorThemeData(

          color:
              stellaPurple,
        ),


        // ====================================================
        // DIVIDERS
        // ====================================================

        dividerTheme:
            const DividerThemeData(

          color:
              Color(0xFF292E4A),

          thickness:
              1,
        ),
      ),


      // ======================================================
      // HOME
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