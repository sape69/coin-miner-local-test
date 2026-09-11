import 'package:flutter/material.dart';

import 'pages/input_test_page.dart';

void main() {
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
            const Color(0xFF120B24),
        colorScheme:
            ColorScheme.fromSeed(
          seedColor:
              const Color(0xFFB58CFF),
          brightness:
              Brightness.dark,
          primary:
              const Color(0xFFB58CFF),
          secondary:
              const Color(0xFFFFB7E8),
          tertiary:
              const Color(0xFFFFD166),
        ),
      ),
      home:
          const InputTestPage(),
    );
  }
}