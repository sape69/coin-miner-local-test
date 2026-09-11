import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const StelluriiniTestApp());
}

// ============================================================
// STELLURIINI - MINIMAL TEXTFIELD TEST
// ============================================================

class StelluriiniTestApp extends StatelessWidget {
  const StelluriiniTestApp({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
      ),

      home: const MinimalTestPage(),
    );
  }
}

// ============================================================
// MINIMAL TEST PAGE
// ============================================================

class MinimalTestPage extends StatefulWidget {
  const MinimalTestPage({
    super.key,
  });

  @override
  State<MinimalTestPage> createState() =>
      _MinimalTestPageState();
}

class _MinimalTestPageState
    extends State<MinimalTestPage> {
  final TextEditingController _controller =
      TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF120B24),

      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'STELLURIINI TEST',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 40),

                // ==================================================
                // AINOA TEXTFIELD KOKO SOVELLUKSESSA
                // ==================================================

                TextField(
                  controller: _controller,

                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                  ),

                  decoration: InputDecoration(
                    hintText: 'NAPAUTA JA KIRJOITA',

                    hintStyle: const TextStyle(
                      color: Colors.white70,
                      fontSize: 18,
                    ),

                    filled: true,

                    fillColor: const Color(0xFF21113B),

                    enabledBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(16),

                      borderSide:
                          const BorderSide(
                        color: Color(0xFFB58CFF),
                        width: 2,
                      ),
                    ),

                    focusedBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(16),

                      borderSide:
                          const BorderSide(
                        color: Colors.white,
                        width: 3,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(
                      SnackBar(
                        content: Text(
                          'Kirjoitit: ${_controller.text}',
                        ),
                      ),
                    );
                  },
                  child: const Text(
                    'TESTAA',
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