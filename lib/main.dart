import 'package:flutter/material.dart';

import 'pages/login_page.dart';

const Color backgroundColor = Color(0xFF120B24);

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
      title: 'Stelluriini',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        scaffoldBackgroundColor: backgroundColor,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFB58CFF),
          brightness: Brightness.dark,
        ),
      ),
      home: LoginPage(
        languageCode: 'fi',
        changeLanguage: (String language) async {},
      ),
    );
  }
}