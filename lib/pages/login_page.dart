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

  // ============================================================
  // 🐱 STELLURIINI COLORS
  // ============================================================

  static const Color backgroundColor =
      Color(0xFF120B24);

  static const Color cardColor =
      Color(0xFF21113B);

  static const Color fieldColor =
      Color(0xFF18102D);

  static const Color purple =
      Color(0xFFB58CFF);

  static const Color pink =
      Color(0xFFFFB7E8);

  static const Color gold =
      Color(0xFFFFD166);

  static const Color white =
      Color(0xFFF8F4FF);

  static const Color secondary =
      Color(0xFFBDB4D1);

  // ============================================================
  // ✉️ EMAIL FIELD
  // ============================================================

  Widget _buildEmailField() {
    return TextField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      autocorrect: false,
      enableSuggestions: false,
      cursorColor: purple,
      style: const TextStyle(
        color: white,
        fontSize: 17,
      ),
      decoration: InputDecoration(
        hintText: 'Sähköposti',
        hintStyle: const TextStyle(
          color: secondary,
          fontSize: 17,
        ),
        prefixIcon: const Icon(
          Icons.email_outlined,
          color: purple,
        ),
        filled: true,
        fillColor: fieldColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(
            color: Color(0xFF352653),
            width: 1.5,
          ),
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
            color: purple,
            width: 2,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // 🔐 PASSWORD FIELD
  // ============================================================

  Widget _buildPasswordField() {
    return TextField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      textInputAction: TextInputAction.done,
      autocorrect: false,
      enableSuggestions: false,
      cursorColor: purple,
      style: const TextStyle(
        color: white,
        fontSize: 17,
      ),
      decoration: InputDecoration(
        hintText: 'Salasana',
        hintStyle: const TextStyle(
          color: secondary,
          fontSize: 17,
        ),
        prefixIcon: const Icon(
          Icons.lock_outline,
          color: purple,
        ),
        suffixIcon: IconButton(
          onPressed: () {
            setState(() {
              _obscurePassword =
                  !_obscurePassword;
            });
          },
          color: purple,
          icon: Icon(
            _obscurePassword
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
          ),
        ),
        filled: true,
        fillColor: fieldColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(
            color: Color(0xFF352653),
            width: 1.5,
          ),
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
            color: purple,
            width: 2,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // 🖥️ BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      resizeToAvoidBottomInset: true,

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
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
                  // 🐾 STELLA LOGO
                  // ==================================================

                  const SizedBox(height: 20),

                  Center(
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: fieldColor,
                        border: Border.all(
                          color: purple,
                          width: 2,
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.pets,
                          size: 70,
                          color: pink,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ==================================================
                  // TITLE
                  // ==================================================

                  const Text(
                    'Stelluriini',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: white,
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'STL',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: gold,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ==================================================
                  // LOGIN CARD
                  // ==================================================

                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius:
                          BorderRadius.circular(24),
                      border: Border.all(
                        color: purple.withValues(
                          alpha: 0.30,
                        ),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.stretch,
                      children: [

                        const Text(
                          'KIRJAUDU SISÄÄN',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: white,
                            fontSize: 26,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 28),

                        // EMAIL

                        _buildEmailField(),

                        const SizedBox(height: 18),

                        // PASSWORD

                        _buildPasswordField(),

                        const SizedBox(height: 24),

                        // ==================================================
                        // TEST BUTTON
                        // ==================================================

                        SizedBox(
                          height: 56,
                          child: ElevatedButton(
                            onPressed: () {
                              FocusScope.of(context)
                                  .unfocus();

                              ScaffoldMessenger.of(
                                context,
                              ).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Kentät toimivat.',
                                  ),
                                ),
                              );
                            },
                            style:
                                ElevatedButton.styleFrom(
                              backgroundColor:
                                  purple,
                              foregroundColor:
                                  backgroundColor,
                              elevation: 0,
                              shape:
                                  RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  18,
                                ),
                              ),
                            ),
                            child: const Text(
                              'TESTAA KIRJAUTUMISTA',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        const Text(
                          'Tämä on väliaikainen '
                          'diagnostiikkaversio.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: secondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    'STELLA • STELLURIINI • STL • SOLANA',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: secondary,
                      fontSize: 11,
                      letterSpacing: 1.1,
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}