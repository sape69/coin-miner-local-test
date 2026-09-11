import 'package:flutter/material.dart';

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
  // EMAIL FIELD
  // ==========================================================

  Widget _emailField() {
    return SizedBox(
      height: 58,
      child: TextField(
        controller: _emailController,

        keyboardType: TextInputType.emailAddress,

        textInputAction: TextInputAction.next,

        autocorrect: false,

        enableSuggestions: false,

        cursorColor: const Color(0xFFB58CFF),

        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
        ),

        decoration: InputDecoration(
          hintText: 'Sähköposti',

          hintStyle: const TextStyle(
            color: Color(0xFF9B91AD),
          ),

          prefixIcon: const Icon(
            Icons.email_outlined,
            color: Color(0xFFB58CFF),
            size: 30,
          ),

          filled: true,

          fillColor: const Color(0xFF18102D),

          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),

          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(
              color: Color(0xFF352653),
              width: 2,
            ),
          ),

          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(
              color: Color(0xFF352653),
              width: 2,
            ),
          ),

          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(
              color: Color(0xFFB58CFF),
              width: 3,
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // PASSWORD FIELD
  // ==========================================================

  Widget _passwordField() {
    return SizedBox(
      height: 58,
      child: TextField(
        controller: _passwordController,

        obscureText: _obscurePassword,

        textInputAction: TextInputAction.done,

        autocorrect: false,

        enableSuggestions: false,

        cursorColor: const Color(0xFFB58CFF),

        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
        ),

        decoration: InputDecoration(
          hintText: 'Salasana',

          hintStyle: const TextStyle(
            color: Color(0xFF9B91AD),
          ),

          prefixIcon: const Icon(
            Icons.lock_outline,
            color: Color(0xFFB58CFF),
            size: 30,
          ),

          suffixIcon: IconButton(
            onPressed: () {
              setState(() {
                _obscurePassword = !_obscurePassword;
              });
            },

            icon: Icon(
              _obscurePassword
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,

              color: const Color(0xFFB58CFF),

              size: 30,
            ),
          ),

          filled: true,

          fillColor: const Color(0xFF18102D),

          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),

          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(
              color: Color(0xFF352653),
              width: 2,
            ),
          ),

          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(
              color: Color(0xFF352653),
              width: 2,
            ),
          ),

          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(
              color: Color(0xFFB58CFF),
              width: 3,
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // TEST BUTTON
  // ==========================================================

  void _testFields() {
    FocusScope.of(context).unfocus();

    final email = _emailController.text;
    final password = _passwordController.text;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF21113B),
        content: Text(
          'Sähköposti: $email\n'
          'Salasana: $password',
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            24,
            40,
            24,
            40,
          ),

          child: Column(
            children: [
              const SizedBox(
                height: 20,
              ),

              // ==================================================
              // LOGO
              // ==================================================

              Container(
                width: 120,
                height: 120,

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
                    size: 62,
                  ),
                ),
              ),

              const SizedBox(
                height: 24,
              ),

              // ==================================================
              // TITLE
              // ==================================================

              const Text(
                'Stelluriini',

                style: TextStyle(
                  color: Color(0xFFF8F4FF),
                  fontSize: 38,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(
                height: 8,
              ),

              const Text(
                'STL',

                style: TextStyle(
                  color: Color(0xFFFFD166),
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                ),
              ),

              const SizedBox(
                height: 40,
              ),

              // ==================================================
              // LOGIN CARD
              // ==================================================

              Container(
                width: double.infinity,

                padding: const EdgeInsets.all(28),

                decoration: BoxDecoration(
                  color: const Color(0xFF21113B),

                  borderRadius: BorderRadius.circular(26),

                  border: Border.all(
                    color: const Color(0xFFB58CFF)
                        .withValues(alpha: 0.35),

                    width: 1.5,
                  ),
                ),

                child: Column(
                  children: [
                    // ============================================
                    // LOGIN TITLE
                    // ============================================

                    const Text(
                      'KIRJAUDU SISÄÄN',

                      textAlign: TextAlign.center,

                      style: TextStyle(
                        color: Color(0xFFF8F4FF),
                        fontSize: 27,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(
                      height: 30,
                    ),

                    // ============================================
                    // EMAIL
                    // ============================================

                    _emailField(),

                    const SizedBox(
                      height: 20,
                    ),

                    // ============================================
                    // PASSWORD
                    // ============================================

                    _passwordField(),

                    const SizedBox(
                      height: 28,
                    ),

                    // ============================================
                    // TEST BUTTON
                    // ============================================

                    SizedBox(
                      width: double.infinity,
                      height: 56,

                      child: ElevatedButton(
                        onPressed: _testFields,

                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color(0xFFB58CFF),

                          foregroundColor:
                              const Color(0xFF120B24),

                          elevation: 0,

                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(18),
                          ),
                        ),

                        child: const Text(
                          'TESTAA KENTÄT',

                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 24,
                    ),

                    const Text(
                      'Tämä on puhdas tekstikenttätesti.',

                      textAlign: TextAlign.center,

                      style: TextStyle(
                        color: Color(0xFFBDB4D1),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                height: 30,
              ),

              const Text(
                'STELLA • STELLURIINI • STL • SOLANA',

                textAlign: TextAlign.center,

                style: TextStyle(
                  color: Color(0xFFBDB4D1),
                  fontSize: 12,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}