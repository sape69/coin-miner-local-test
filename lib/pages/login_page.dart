import 'package:flutter/material.dart';

// ============================================================
// STELLURIINI - PUHDAS ANDROID TEXTFIELD TESTI
// ============================================================

class LoginPage extends StatefulWidget {
  final String languageCode;
  final Future<void> Function(String) changeLanguage;

  const LoginPage({
    super.key,
    required this.languageCode,
    required this.changeLanguage,
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController =
      TextEditingController();

  final TextEditingController _passwordController =
      TextEditingController();

  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _testFields() {
    final email = _emailController.text;
    final password = _passwordController.text;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Email: $email\nPassword: $password',
        ),
      ),
    );
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
                const Icon(
                  Icons.pets,
                  color: Color(0xFFFFB7E8),
                  size: 70,
                ),

                const SizedBox(height: 20),

                const Text(
                  'STELLURIINI',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 35),

                // ==================================================
                // EMAIL
                // ==================================================

                TextField(
                  controller: _emailController,

                  enabled: true,
                  readOnly: false,

                  keyboardType: TextInputType.emailAddress,

                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                  ),

                  decoration: InputDecoration(
                    hintText: 'Sähköposti',

                    hintStyle: const TextStyle(
                      color: Colors.white54,
                    ),

                    prefixIcon: const Icon(
                      Icons.email,
                      color: Color(0xFFB58CFF),
                    ),

                    filled: true,

                    fillColor: const Color(0xFF21113B),

                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: Color(0xFFB58CFF),
                        width: 2,
                      ),
                    ),

                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: Colors.white,
                        width: 3,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ==================================================
                // PASSWORD
                // ==================================================

                TextField(
                  controller: _passwordController,

                  enabled: true,
                  readOnly: false,

                  obscureText: _obscurePassword,

                  keyboardType: TextInputType.visiblePassword,

                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                  ),

                  decoration: InputDecoration(
                    hintText: 'Salasana',

                    hintStyle: const TextStyle(
                      color: Colors.white54,
                    ),

                    prefixIcon: const Icon(
                      Icons.lock,
                      color: Color(0xFFB58CFF),
                    ),

                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          _obscurePassword =
                              !_obscurePassword;
                        });
                      },
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: const Color(0xFFB58CFF),
                      ),
                    ),

                    filled: true,

                    fillColor: const Color(0xFF21113B),

                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: Color(0xFFB58CFF),
                        width: 2,
                      ),
                    ),

                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: Colors.white,
                        width: 3,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                // ==================================================
                // TEST BUTTON
                // ==================================================

                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _testFields,
                    child: const Text(
                      'TESTAA KENTÄT',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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