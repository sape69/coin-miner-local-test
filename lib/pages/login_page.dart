import 'package:flutter/material.dart';

// ============================================================
// 🐱 STELLURIINI LOGIN PAGE
// ============================================================
//
// VAIHE 2 - TOIMIVA KIRJAUTUMISKENTTÄ
//
// Tämä versio käyttää samaa yksinkertaista rakennetta kuin
// juuri onnistuneesti testattu MinimalTestPage.
//
// Ei:
// - Firebasea
// - AdMobiä
// - Stackia
// - Overlayta
// - GestureDetectoria
// - SingleChildScrollViewia
// - FocusNodeja
//
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
  // ==========================================================
  // CONTROLLERS
  // ==========================================================

  final TextEditingController _emailController =
      TextEditingController();

  final TextEditingController _passwordController =
      TextEditingController();

  // ==========================================================
  // STATE
  // ==========================================================

  bool _obscurePassword = true;

  // ==========================================================
  // DISPOSE
  // ==========================================================

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ==========================================================
  // TEST LOGIN
  // ==========================================================

  void _testLogin() {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Kirjoita sähköpostiosoite.',
          ),
        ),
      );

      return;
    }

    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Kirjoita salasana.',
          ),
        ),
      );

      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Kentät toimivat!\n'
          'Sähköposti: $email',
        ),
      ),
    );
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF120B24),

      resizeToAvoidBottomInset: true,

      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),

            child: Column(
              mainAxisSize: MainAxisSize.min,

              children: [
                // ==================================================
                // LOGO
                // ==================================================

                Container(
                  width: 100,
                  height: 100,

                  decoration: BoxDecoration(
                    shape: BoxShape.circle,

                    color: const Color(0xFF1A0E31),

                    border: Border.all(
                      color: const Color(0xFFB58CFF),
                      width: 3,
                    ),
                  ),

                  child: const Center(
                    child: Icon(
                      Icons.pets,
                      color: Color(0xFFFFB7E8),
                      size: 58,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ==================================================
                // TITLE
                // ==================================================

                const Text(
                  'Stelluriini',

                  style: TextStyle(
                    color: Color(0xFFF8F4FF),
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 6),

                const Text(
                  'STL',

                  style: TextStyle(
                    color: Color(0xFFFFD166),
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                  ),
                ),

                const SizedBox(height: 30),

                // ==================================================
                // LOGIN TITLE
                // ==================================================

                const Text(
                  'KIRJAUDU SISÄÄN',

                  textAlign: TextAlign.center,

                  style: TextStyle(
                    color: Color(0xFFF8F4FF),
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 25),

                // ==================================================
                // EMAIL
                // ==================================================

                TextField(
                  controller: _emailController,

                  enabled: true,
                  readOnly: false,

                  keyboardType:
                      TextInputType.emailAddress,

                  textInputAction:
                      TextInputAction.next,

                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                  ),

                  decoration: InputDecoration(
                    hintText: 'Sähköposti',

                    hintStyle: const TextStyle(
                      color: Color(0xFFBDB4D1),
                      fontSize: 18,
                    ),

                    prefixIcon: const Icon(
                      Icons.email_outlined,
                      color: Color(0xFFB58CFF),
                    ),

                    filled: true,

                    fillColor:
                        const Color(0xFF21113B),

                    enabledBorder:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(16),

                      borderSide:
                          const BorderSide(
                        color: Color(0xFFB58CFF),
                        width: 2,
                      ),
                    ),

                    focusedBorder:
                        OutlineInputBorder(
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

                const SizedBox(height: 18),

                // ==================================================
                // PASSWORD
                // ==================================================

                TextField(
                  controller: _passwordController,

                  enabled: true,
                  readOnly: false,

                  obscureText:
                      _obscurePassword,

                  keyboardType:
                      TextInputType.visiblePassword,

                  textInputAction:
                      TextInputAction.done,

                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                  ),

                  decoration: InputDecoration(
                    hintText: 'Salasana',

                    hintStyle: const TextStyle(
                      color: Color(0xFFBDB4D1),
                      fontSize: 18,
                    ),

                    prefixIcon: const Icon(
                      Icons.lock_outline,
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
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,

                        color:
                            const Color(0xFFB58CFF),
                      ),
                    ),

                    filled: true,

                    fillColor:
                        const Color(0xFF21113B),

                    enabledBorder:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(16),

                      borderSide:
                          const BorderSide(
                        color: Color(0xFFB58CFF),
                        width: 2,
                      ),
                    ),

                    focusedBorder:
                        OutlineInputBorder(
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

                const SizedBox(height: 25),

                // ==================================================
                // LOGIN BUTTON
                // ==================================================

                SizedBox(
                  width: double.infinity,
                  height: 55,

                  child: ElevatedButton(
                    onPressed: _testLogin,

                    style:
                        ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color(0xFFB58CFF),

                      foregroundColor:
                          const Color(0xFF120B24),

                      elevation: 0,

                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(16),
                      ),
                    ),

                    child: const Text(
                      'KIRJAUDU SISÄÄN',

                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  'STELLA • STELLURIINI • STL',

                  textAlign: TextAlign.center,

                  style: TextStyle(
                    color: Color(0xFFBDB4D1),
                    fontSize: 12,
                    letterSpacing: 1,
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