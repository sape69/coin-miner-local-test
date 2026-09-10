import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../localization.dart';
import 'forgot_password_page.dart';
import 'register_page.dart';

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

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  AppLocalizations get _l10n =>
      AppLocalizations(widget.languageCode);

  Future<void> _login() async {
    FocusScope.of(context).unfocus();

    final String email = _emailController.text.trim();
    final String password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showMessage(
        _l10n.get('loginFillFields'),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      String message = _l10n.get('loginFailed');

      switch (e.code) {
        case 'user-not-found':
          message = _l10n.get('loginUserNotFound');
          break;

        case 'wrong-password':
        case 'invalid-credential':
          message = _l10n.get(
            'loginInvalidCredentials',
          );
          break;

        case 'invalid-email':
          message = _l10n.get(
            'loginInvalidEmail',
          );
          break;

        case 'user-disabled':
          message = _l10n.get(
            'loginUserDisabled',
          );
          break;

        case 'too-many-requests':
          message = _l10n.get(
            'loginTooManyRequests',
          );
          break;

        case 'network-request-failed':
          message = _l10n.get(
            'loginNetworkError',
          );
          break;
      }

      _showMessage(message);
    } catch (_) {
      _showMessage(
        _l10n.get('loginFailed'),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Color(0xFFF8F4FF),
          ),
        ),
        backgroundColor: const Color(0xFF21113B),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _openRegister() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RegisterPage(
          languageCode: widget.languageCode,
          changeLanguage: widget.changeLanguage,
        ),
      ),
    );
  }

  Future<void> _openForgotPassword() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ForgotPasswordPage(
          languageCode: widget.languageCode,
          changeLanguage: widget.changeLanguage,
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration({
    required String label,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        color: Color(0xFFBDB4D1),
      ),
      floatingLabelStyle: const TextStyle(
        color: Color(0xFFFFB7E8),
      ),
      prefixIcon: Icon(
        icon,
        color: Color(0xFFB58CFF),
      ),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFF120B24),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: const Color(0xFFB58CFF)
              .withValues(alpha: 0.30),
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: Color(0xFFFFB7E8),
          width: 1.5,
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
        child: Center(
          child: SingleChildScrollView(
            keyboardDismissBehavior:
                ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(
              24,
              28,
              24,
              32,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 480,
              ),
              child: Column(
                children: [
                  // ==================================================
                  // STELLA LOGO
                  // ==================================================

                  Container(
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
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x331A0E31),
                          blurRadius: 18,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _l10n.get('login'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFFF8F4FF),
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 24),

                        // ==================================================
                        // EMAIL
                        // ==================================================

                        SizedBox(
                          height: 58,
                          child: TextField(
                            controller: _emailController,
                            keyboardType:
                                TextInputType.emailAddress,
                            textInputAction:
                                TextInputAction.next,
                            autocorrect: false,
                            enableSuggestions: false,
                            style: const TextStyle(
                              color: Color(0xFFF8F4FF),
                              fontSize: 16,
                            ),
                            decoration: _fieldDecoration(
                              label: _l10n.get('email'),
                              icon: Icons.email_outlined,
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // ==================================================
                        // PASSWORD
                        // ==================================================

                        SizedBox(
                          height: 58,
                          child: TextField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            textInputAction:
                                TextInputAction.done,
                            autocorrect: false,
                            enableSuggestions: false,
                            style: const TextStyle(
                              color: Color(0xFFF8F4FF),
                              fontSize: 16,
                            ),
                            onSubmitted: (_) {
                              if (!_isLoading) {
                                _login();
                              }
                            },
                            decoration: _fieldDecoration(
                              label: _l10n.get('password'),
                              icon: Icons.lock_outline,
                              suffixIcon: IconButton(
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword =
                                        !_obscurePassword;
                                  });
                                },
                                color: const Color(0xFFB58CFF),
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons
                                          .visibility_outlined
                                      : Icons
                                          .visibility_off_outlined,
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 6),

                        // ==================================================
                        // FORGOT PASSWORD
                        // ==================================================

                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _isLoading
                                ? null
                                : _openForgotPassword,
                            style: TextButton.styleFrom(
                              foregroundColor:
                                  const Color(0xFFFFB7E8),
                              padding:
                                  const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 4,
                              ),
                            ),
                            child: Text(
                              _l10n.get('forgotPassword'),
                              style: const TextStyle(
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        // ==================================================
                        // LOGIN BUTTON
                        // ==================================================

                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed:
                                _isLoading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color(0xFFB58CFF),
                              foregroundColor:
                                  const Color(0xFF120B24),
                              disabledBackgroundColor:
                                  const Color(0xFF6E6380),
                              disabledForegroundColor:
                                  const Color(0xFFD8D0E2),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(16),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child:
                                        CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      valueColor:
                                          AlwaysStoppedAnimation<
                                              Color>(
                                        Color(0xFF120B24),
                                      ),
                                    ),
                                  )
                                : Text(
                                    _l10n.get('login'),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight:
                                          FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 18),

                        // ==================================================
                        // CREATE ACCOUNT
                        // ==================================================

                        Text(
                          _l10n.get('createAccount'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFFBDB4D1),
                            fontSize: 14,
                          ),
                        ),

                        const SizedBox(height: 4),

                        TextButton(
                          onPressed:
                              _isLoading ? null : _openRegister,
                          style: TextButton.styleFrom(
                            foregroundColor:
                                const Color(0xFFFFD166),
                          ),
                          child: Text(
                            _l10n.get('createAccount'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
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