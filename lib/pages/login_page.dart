import 'package:flutter/material.dart';

// ============================================================
// 🐱 STELLURIINI LOGIN PAGE
// ============================================================
//
// VIANMÄÄRITYSVERSIO
//
// Tässä versiossa:
//
// ❌ Firebase Auth
// ❌ Localization
// ❌ Forgot Password -navigointi
// ❌ Register-navigointi
// ❌ SharedPreferences
// ❌ AdMob
//
// ✅ Stella
// ✅ Stelluriini-ulkoasu
// ✅ Sähköpostikenttä
// ✅ Salasanakenttä
// ✅ Salasanan näyttäminen/piilottaminen
// ✅ Kirjautumispainike
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
  final TextEditingController emailController =
      TextEditingController();

  final TextEditingController passwordController =
      TextEditingController();

  bool obscurePassword = true;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // ==========================================================
  // EMAIL FIELD
  // ==========================================================

  Widget _emailField() {
    return TextField(
      controller: emailController,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      autocorrect: false,
      enableSuggestions: false,
      cursorColor: const Color(0xFFB58CFF),
      style: const TextStyle(
        color: Color(0xFFF8F4FF),
        fontSize: 16,
      ),
      decoration: InputDecoration(
        hintText: 'Sähköposti',
        hintStyle: const TextStyle(
          color: Color(0xFF766B89),
          fontSize: 16,
        ),
        prefixIcon: const Icon(
          Icons.email_outlined,
          color: Color(0xFFB58CFF),
        ),
        filled: true,
        fillColor: const Color(0xFF18102D),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(
            color: Color(0xFF352653),
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(
            color: Color(0xFFB58CFF),
            width: 2,
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // PASSWORD FIELD
  // ==========================================================

  Widget _passwordField() {
    return TextField(
      controller: passwordController,
      obscureText: obscurePassword,
      textInputAction: TextInputAction.done,
      autocorrect: false,
      enableSuggestions: false,
      cursorColor: const Color(0xFFB58CFF),
      style: const TextStyle(
        color: Color(0xFFF8F4FF),
        fontSize: 16,
      ),
      decoration: InputDecoration(
        hintText: 'Salasana',
        hintStyle: const TextStyle(
          color: Color(0xFF766B89),
          fontSize: 16,
        ),
        prefixIcon: const Icon(
          Icons.lock_outline,
          color: Color(0xFFB58CFF),
        ),
        suffixIcon: IconButton(
          onPressed: () {
            setState(() {
              obscurePassword = !obscurePassword;
            });
          },
          color: const Color(0xFFB58CFF),
          icon: Icon(
            obscurePassword
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
          ),
        ),
        filled: true,
        fillColor: const Color(0xFF18102D),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(
            color: Color(0xFF352653),
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(
            color: Color(0xFFB58CFF),
            width: 2,
          ),
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
            28,
            24,
            32,
          ),

          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 480,
              ),

              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.stretch,

                children: [
                  // ==================================================
                  // STELLA
                  // ==================================================

                  Center(
                    child: Container(
                      width: 110,
                      height: 110,

                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF1A0E31),

                        border: Border.all(
                          color: const Color(0xFFB58CFF),
                          width: 2,
                        ),

                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x55211B3B),
                            blurRadius: 20,
                            spreadRadius: 4,
                          ),
                        ],
                      ),

                      child: ClipOval(
                        child: Image.asset(
                          'assets/stella.jpg',
                          fit: BoxFit.cover,

                          errorBuilder: (
                            context,
                            error,
                            stackTrace,
                          ) {
                            return const Icon(
                              Icons.pets,
                              size: 56,
                              color: Color(0xFFFFB7E8),
                            );
                          },
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 22,
                  ),

                  // ==================================================
                  // TITLE
                  // ==================================================

                  const Text(
                    'Stelluriini',

                    textAlign: TextAlign.center,

                    style: TextStyle(
                      color: Color(0xFFF8F4FF),
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),

                  const SizedBox(
                    height: 6,
                  ),

                  const Text(
                    'STL',

                    textAlign: TextAlign.center,

                    style: TextStyle(
                      color: Color(0xFFFFD166),
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 3,
                    ),
                  ),

                  const SizedBox(
                    height: 30,
                  ),

                  // ==================================================
                  // LOGIN CARD
                  // ==================================================

                  Container(
                    width: double.infinity,

                    padding: const EdgeInsets.fromLTRB(
                      20,
                      24,
                      20,
                      22,
                    ),

                    decoration: BoxDecoration(
                      color: const Color(0xFF21113B),

                      borderRadius:
                          BorderRadius.circular(24),

                      border: Border.all(
                        color: const Color(0xFFB58CFF)
                            .withValues(alpha: 0.30),

                        width: 1,
                      ),
                    ),

                    child: Column(
                      mainAxisSize: MainAxisSize.min,

                      crossAxisAlignment:
                          CrossAxisAlignment.stretch,

                      children: [
                        // ==========================================
                        // LOGIN TITLE
                        // ==========================================

                        const Text(
                          'KIRJAUDU SISÄÄN',

                          textAlign:
                              TextAlign.center,

                          style: TextStyle(
                            color:
                                Color(0xFFF8F4FF),

                            fontSize: 25,

                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),

                        const SizedBox(
                          height: 24,
                        ),

                        // ==========================================
                        // EMAIL
                        // ==========================================

                        _emailField(),

                        const SizedBox(
                          height: 18,
                        ),

                        // ==========================================
                        // PASSWORD
                        // ==========================================

                        _passwordField(),

                        const SizedBox(
                          height: 24,
                        ),

                        // ==========================================
                        // LOGIN BUTTON
                        // ==========================================

                        SizedBox(
                          width: double.infinity,
                          height: 54,

                          child: ElevatedButton(
                            onPressed: () {},

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
                                fontSize: 16,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(
                          height: 18,
                        ),

                        // ==========================================
                        // FORGOT PASSWORD
                        // ==========================================

                        TextButton(
                          onPressed: () {},

                          style:
                              TextButton.styleFrom(
                            foregroundColor:
                                const Color(0xFFFFB7E8),
                          ),

                          child: const Text(
                            'Unohditko salasanan?',
                          ),
                        ),

                        const SizedBox(
                          height: 4,
                        ),

                        // ==========================================
                        // CREATE ACCOUNT
                        // ==========================================

                        TextButton(
                          onPressed: () {},

                          style:
                              TextButton.styleFrom(
                            foregroundColor:
                                const Color(0xFFFFD166),
                          ),

                          child: const Text(
                            'Ei vielä tiliä? Luo uusi tili',

                            style: TextStyle(
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(
                    height: 24,
                  ),

                  // ==================================================
                  // FOOTER
                  // ==================================================

                  const Text(
                    'STELLA • STELLURIINI • STL • SOLANA',

                    textAlign:
                        TextAlign.center,

                    style: TextStyle(
                      color:
                          Color(0xFFBDB4D1),

                      fontSize: 11,

                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}