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

  final FocusNode _emailFocusNode = FocusNode();

  final FocusNode _passwordFocusNode = FocusNode();

  bool _obscurePassword = true;

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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Widget _inputBox({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    Widget? trailing,
    TextInputType keyboardType =
        TextInputType.text,
  }) {
    return Container(
      height: 62,
      decoration: BoxDecoration(
        color: fieldColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: focusNode.hasFocus
              ? purple
              : const Color(0xFF352653),
          width: focusNode.hasFocus ? 2 : 1.5,
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),

          Icon(
            icon,
            color: purple,
            size: 28,
          ),

          const SizedBox(width: 14),

          Expanded(
            child: EditableText(
              controller: controller,
              focusNode: focusNode,
              style: const TextStyle(
                color: white,
                fontSize: 17,
              ),
              cursorColor: purple,
              backgroundCursorColor: Colors.transparent,
              obscureText: obscureText,
              keyboardType: keyboardType,
              textInputAction:
                  TextInputAction.next,
              autocorrect: false,
              enableSuggestions: false,
              maxLines: 1,
              strutStyle: const StrutStyle(
                forceStrutHeight: true,
                height: 1.2,
              ),
              onChanged: (_) {
                setState(() {});
              },
            ),
          ),

          if (trailing != null) trailing,

          const SizedBox(width: 8),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
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
                  const SizedBox(height: 20),

                  // ==================================================
                  // STELLA
                  // ==================================================

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

                        // ==================================================
                        // EMAIL
                        // ==================================================

                        _inputBox(
                          controller:
                              _emailController,
                          focusNode:
                              _emailFocusNode,
                          hint: 'Sähköposti',
                          icon:
                              Icons.email_outlined,
                          keyboardType:
                              TextInputType.emailAddress,
                        ),

                        const SizedBox(height: 18),

                        // ==================================================
                        // PASSWORD
                        // ==================================================

                        _inputBox(
                          controller:
                              _passwordController,
                          focusNode:
                              _passwordFocusNode,
                          hint: 'Salasana',
                          icon:
                              Icons.lock_outline,
                          obscureText:
                              _obscurePassword,
                          trailing:
                              IconButton(
                            onPressed: () {
                              setState(() {
                                _obscurePassword =
                                    !_obscurePassword;
                              });
                            },
                            color: purple,
                            icon: Icon(
                              _obscurePassword
                                  ? Icons
                                      .visibility_outlined
                                  : Icons
                                      .visibility_off_outlined,
                            ),
                          ),
                        ),

                        const SizedBox(height: 28),

                        // ==================================================
                        // TEST BUTTON
                        // ==================================================

                        SizedBox(
                          height: 56,
                          child:
                              ElevatedButton(
                            onPressed: () {
                              FocusScope.of(
                                context,
                              ).unfocus();

                              ScaffoldMessenger
                                  .of(context)
                                  .showSnackBar(
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
                              'TESTAA KENTÄT',
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
                          'Jos molemmat kentät toimivat, '
                          'voimme palauttaa Firebase-kirjautumisen '
                          'seuraavassa vaiheessa.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: secondary,
                            fontSize: 14,
                            height: 1.4,
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}