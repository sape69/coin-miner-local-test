import 'package:flutter/material.dart';

import 'pages/login_page.dart';

// ============================================================
// 🐱 STELLURIINI / DIRECT LOGIN TEST
// ============================================================
//
// VIANMÄÄRITYSTESTI
//
// Tässä testissä:
//
// ❌ Firebase EI käynnisty
// ❌ AuthGate EI ole mukana
// ❌ SharedPreferences EI ole mukana
// ❌ AdMob EI ole mukana
//
// ✅ Nykyinen LoginPage avataan suoraan
//
// Tällä selvitetään, tuleeko harmaa alue LoginPage-tiedostosta
// vai Auth/Firebase-ketjusta.
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
  String languageCode = 'fi';

  // ==========================================================
  // LANGUAGE
  // ==========================================================

  Future<void> changeLanguage(
    String language,
  ) async {
    const Set<String> supportedLanguages = {
      'fi',
      'en',
      'de',
      'es',
      'fr',
      'zh',
      'vi',
      'ja',
    };

    final String validLanguage =
        supportedLanguages.contains(language)
            ? language
            : 'fi';

    if (!mounted) {
      return;
    }

    setState(() {
      languageCode = validLanguage;
    });
  }

  // ==========================================================
  // SUPPORTED LOCALES
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
  // BUILD
  // ==========================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return MaterialApp(
      title: 'Stelluriini',

      debugShowCheckedModeBanner: false,

      locale:
          Locale(languageCode),

      supportedLocales:
          supportedLocales,

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
      // 🔬 DIRECT LOGIN PAGE
      // ========================================================
      //
      // Ei AuthGatea.
      // Ei Firebaseä.
      // Ei SharedPreferencesia.
      // Ei AdMobiä.
      //
      // ========================================================

      home: LoginPage(
        languageCode:
            languageCode,

        changeLanguage:
            changeLanguage,
      ),
    );
  }
}