import 'package:flutter/material.dart';

import 'pages/text_input_test_page.dart';

// ============================================================
// 🐱 STELLURIINI / TEXT INPUT TEST
// ============================================================
//
// Tämä main.dart on VÄLIAIKAINEN vianmääritystesti.
//
// Tällä testillä poistamme kokonaan käytöstä:
// - Firebase
// - Firebase Auth
// - Firestore
// - Cloud Functions
// - Google Mobile Ads
// - AuthGate
// - LoginPage
// - RegisterPage
//
// Näin näemme, toimivatko Flutterin TextField-kentät
// puhtaassa Flutter-näkymässä tällä Samsung-laitteella.
//
// ÄLÄ POISTA MUITA TIEDOSTOJA.
// Tämä tiedosto palautetaan myöhemmin Stelluriinin
// varsinaiseksi main.dart-tiedostoksi.
//
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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    const StelluriiniTestApp(),
  );
}

class StelluriiniTestApp extends StatelessWidget {
  const StelluriiniTestApp({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stelluriini Input Test',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
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
        appBarTheme:
            const AppBarTheme(
          backgroundColor:
              backgroundColor,
          foregroundColor:
              primaryTextColor,
          centerTitle: true,
          elevation: 0,
          titleTextStyle:
              TextStyle(
            color:
                primaryTextColor,
            fontSize: 20,
            fontWeight:
                FontWeight.bold,
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
            elevation: 0,
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
              fontSize: 16,
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
          thickness: 1,
        ),
      ),
      home:
          const TextInputTestPage(),
    );
  }
}