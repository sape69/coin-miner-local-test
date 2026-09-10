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

  InputDecoration _emailDecoration() {
    return InputDecoration(
      labelText: 'Sähköposti',
      hintText: 'Sähköposti',
      labelStyle: const TextStyle(
        color: Color(0xFFBDB4D1),
      ),
      floatingLabelStyle: const TextStyle(
        color: Color(0xFFFFB7E8),
      ),
      hintStyle: const TextStyle(
        color: Color(0xFF766B89),
      ),
      prefixIcon: const Icon(
        Icons.email_outlined,
        color: Color(0xFFB58CFF),
      ),
      filled: true,
      fillColor: const Color(0xFF18102D),
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
    );
  }

  InputDecoration _passwordDecoration() {
    return InputDecoration(
      labelText: 'Salasana',
      hintText: 'Salasana',
      labelStyle: const TextStyle(
        color: Color(0xFFBDB4D1),
      ),
      floatingLabelStyle: const TextStyle(
        color: Color(0xFFFFB7E8),
      ),
      hintStyle: const TextStyle(
        color: Color(0xFF766B89),
      ),
      prefixIcon: const Icon(
        Icons.lock_outline,
        color: Color(0xFFB58CFF),
      ),
      suffixIcon: IconButton(
        onPressed: () {
          setState(() {
            _obscurePassword = !_obscurePassword;
          });
        },
        color: const Color(0xFFB58CFF),
        icon: Icon(
          _obscurePassword
              ? Icons.visibility_outlined
              : Icons.visibility_off_outlined,
        ),
      ),
      filled: true,
      fillColor: const Color(0xFF18102D),
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
    );
  }

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
                  // STELLA LOGO
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

                  const SizedBox(height: 22),

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

                  const SizedBox(height: 6),

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

                  const SizedBox(height: 30),

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
                      borderRadius: BorderRadius.circular(24),
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
                        const Text(
                          'KIRJAUDU SISÄÄN',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFFF8F4FF),
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 24),

                        // ==================================================
                        // EMAIL
                        // ==================================================

                        TextField(
                          controller: _emailController,
                          keyboardType:
                              TextInputType.emailAddress,
                          textInputAction:
                              TextInputAction.next,
                          autocorrect: false,
                          enableSuggestions: false,
                          cursorColor:
                              const Color(0xFFB58CFF),
                          style: const TextStyle(
                            color: Color(0xFFF8F4FF),
                            fontSize: 16,
                          ),
                          decoration: _emailDecoration(),
                        ),

                        const SizedBox(height: 18),

                        // ==================================================
                        // PASSWORD
                        // ==================================================

                        TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          textInputAction:
                              TextInputAction.done,
                          autocorrect: false,
                          enableSuggestions: false,
                          cursorColor:
                              const Color(0xFFB58CFF),
                          style: const TextStyle(
                            color: Color(0xFFF8F4FF),
                            fontSize: 16,
                          ),
                          decoration:
                              _passwordDecoration(),
                        ),

                        const SizedBox(height: 24),

                        // ==================================================
                        // TEST BUTTON
                        // ==================================================

                        SizedBox(
                          height: 54,
                          child: ElevatedButton(
                            onPressed: () {
                              FocusScope.of(context).unfocus();

                              ScaffoldMessenger.of(context)
                                  .showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Sähköposti: ${_emailController.text}\n'
                                    'Salasana: ${_passwordController.text.isEmpty ? "ei syötetty" : "syötetty"}',
                                  ),
                                  backgroundColor:
                                      const Color(0xFF21113B),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color(0xFFB58CFF),
                              foregroundColor:
                                  const Color(0xFF120B24),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text(
                              'TESTAA KENTÄT',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
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
                      color: Color(0xFFBDB4D1),
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