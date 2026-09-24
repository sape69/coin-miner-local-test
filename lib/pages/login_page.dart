import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../localization.dart';
import 'register_page.dart';

// ============================================================
// 🐱 STELLURIINI LOGIN PAGE
// ============================================================
//
// LoginPage
//     ↓
// FirebaseAuth
//     ↓
// AuthGate
//     ↓
// HomePage
//
// Kielivalinta toimii jo kirjautumissivulla.
// Ensimmäisellä asennuksella main.dart antaa oletuskieleksi
// englannin.
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
  // FIREBASE
  // ==========================================================

  final FirebaseAuth _auth = FirebaseAuth.instance;

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
  bool _loginLoading = false;
  bool _resetPasswordLoading = false;

  // ==========================================================
  // LOCALIZATION
  // ==========================================================

  AppLocalizations get _t =>
      AppLocalizations(widget.languageCode);

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
  // LOGIN
  // ==========================================================

  Future<void> _login() async {
    if (_loginLoading || _resetPasswordLoading) {
      return;
    }

    final String email =
        _emailController.text.trim();

    final String password =
        _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showMessage(
        _t.get('loginFillFields'),
      );
      return;
    }

    setState(() {
      _loginLoading = true;
    });

    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (error) {
      debugPrint(
        'Firebase login error: '
        '${error.code} - ${error.message}',
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        _firebaseLoginErrorMessage(
          error.code,
        ),
      );
    } catch (error) {
      debugPrint(
        'Login error: $error',
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        _t.get('loginFailed'),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loginLoading = false;
        });
      }
    }
  }

  // ==========================================================
  // RESET PASSWORD
  // ==========================================================

  Future<void> _resetPassword() async {
    if (_loginLoading || _resetPasswordLoading) {
      return;
    }

    final String email =
        _emailController.text.trim();

    if (email.isEmpty) {
      _showMessage(
        _t.get('passwordResetDescription'),
      );
      return;
    }

    if (!_isValidEmail(email)) {
      _showMessage(
        _t.get('loginInvalidEmail'),
      );
      return;
    }

    setState(() {
      _resetPasswordLoading = true;
    });

    try {
      await _auth.sendPasswordResetEmail(
        email: email,
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        _t.get('passwordResetSent'),
      );
    } on FirebaseAuthException catch (error) {
      debugPrint(
        'Firebase password reset error: '
        '${error.code} - ${error.message}',
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        _firebaseResetErrorMessage(
          error.code,
        ),
      );
    } catch (error) {
      debugPrint(
        'Password reset error: $error',
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        _t.get('passwordResetFailed'),
      );
    } finally {
      if (mounted) {
        setState(() {
          _resetPasswordLoading = false;
        });
      }
    }
  }

  // ==========================================================
  // EMAIL VALIDATION
  // ==========================================================

  bool _isValidEmail(String email) {
    final RegExp emailRegex = RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    );

    return emailRegex.hasMatch(email);
  }

  // ==========================================================
  // REGISTER
  // ==========================================================

  Future<void> _openRegisterPage() async {
    if (_loginLoading || _resetPasswordLoading) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          return RegisterPage(
            languageCode: widget.languageCode,
            changeLanguage: widget.changeLanguage,
          );
        },
      ),
    );
  }

  // ==========================================================
  // LANGUAGE
  // ==========================================================

  Future<void> _changeLanguage(
    String languageCode,
  ) async {
    if (_loginLoading || _resetPasswordLoading) {
      return;
    }

    await widget.changeLanguage(languageCode);
  }

  // ==========================================================
  // LANGUAGE MENU
  // ==========================================================

  Widget _buildLanguageSelector() {
    final String currentLanguage =
        AppLocalizations.supportedLanguages[
              widget.languageCode,
            ] ??
            'English';

    return Align(
      alignment: Alignment.centerRight,
      child: PopupMenuButton<String>(
        enabled:
            !_loginLoading &&
            !_resetPasswordLoading,
        onSelected: _changeLanguage,
        color: const Color(0xFF21113B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        itemBuilder: (BuildContext context) {
          return AppLocalizations
              .supportedLanguages
              .entries
              .map(
                (
                  MapEntry<String, String> entry,
                ) {
                  final bool selected =
                      entry.key ==
                      widget.languageCode;

                  return PopupMenuItem<String>(
                    value: entry.key,
                    child: Row(
                      children: [
                        Icon(
                          selected
                              ? Icons.check_circle
                              : Icons.language,
                          size: 20,
                          color: selected
                              ? const Color(
                                  0xFFFFB7E8,
                                )
                              : const Color(
                                  0xFFB58CFF,
                                ),
                        ),
                        const SizedBox(
                          width: 12,
                        ),
                        Text(
                          entry.value,
                          style: TextStyle(
                            color: const Color(
                              0xFFF8F4FF,
                            ),
                            fontWeight: selected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              )
              .toList();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF21113B),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFFB58CFF),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.language,
                color: Color(0xFFB58CFF),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                currentLanguage,
                style: const TextStyle(
                  color: Color(0xFFF8F4FF),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.keyboard_arrow_down,
                color: Color(0xFFFFB7E8),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // LOGIN ERRORS
  // ==========================================================

  String _firebaseLoginErrorMessage(
    String code,
  ) {
    switch (code) {
      case 'invalid-email':
        return _t.get('loginInvalidEmail');

      case 'user-disabled':
        return _t.get('loginUserDisabled');

      case 'user-not-found':
        return _t.get('loginUserNotFound');

      case 'wrong-password':
      case 'invalid-credential':
        return _t.get('loginInvalidCredentials');

      case 'too-many-requests':
        return _t.get('loginTooManyRequests');

      case 'network-request-failed':
        return _t.get('loginNetworkError');

      case 'operation-not-allowed':
        return _t.get('loginFailed');

      default:
        return _t.get('loginFailed');
    }
  }

  // ==========================================================
  // RESET PASSWORD ERRORS
  // ==========================================================

  String _firebaseResetErrorMessage(
    String code,
  ) {
    switch (code) {
      case 'invalid-email':
        return _t.get('loginInvalidEmail');

      case 'user-not-found':
        return _t.get(
          'passwordResetUserNotFound',
        );

      case 'user-disabled':
        return _t.get('loginUserDisabled');

      case 'too-many-requests':
        return _t.get('loginTooManyRequests');

      case 'network-request-failed':
        return _t.get('loginNetworkError');

      case 'operation-not-allowed':
        return _t.get(
          'passwordResetNotAllowed',
        );

      default:
        return _t.get('passwordResetFailed');
    }
  }

  // ==========================================================
  // MESSAGE
  // ==========================================================

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor:
              const Color(0xFF21113B),
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(14),
          ),
        ),
      );
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    final bool interactionLocked =
        _loginLoading ||
        _resetPasswordLoading;

    return Scaffold(
      backgroundColor:
          const Color(0xFF120B24),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior:
              ScrollViewKeyboardDismissBehavior
                  .onDrag,
          physics:
              const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            24,
            20,
            24,
            50,
          ),
          child: Column(
            children: [
              // ==================================================
              // LANGUAGE SELECTOR
              // ==================================================

              _buildLanguageSelector(),

              const SizedBox(height: 10),

              // ==================================================
              // LOGO
              // ==================================================

              Container(
                width: 190,
                height: 190,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(
                        0xFFB58CFF,
                      ).withValues(
                        alpha: 0.25,
                      ),
                      blurRadius: 25,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/stelluriini_logo.png',
                    width: 190,
                    height: 190,
                    fit: BoxFit.cover,
                    errorBuilder: (
                      BuildContext context,
                      Object error,
                      StackTrace? stackTrace,
                    ) {
                      return const Icon(
                        Icons.pets,
                        color: Color(
                          0xFFB58CFF,
                        ),
                        size: 80,
                      );
                    },
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
                  color: Color(0xFFB58CFF),
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                ),
              ),

              const SizedBox(height: 35),

              // ==================================================
              // LOGIN TITLE
              // ==================================================

              Text(
                _t.get('login'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFF8F4FF),
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 28),

              // ==================================================
              // EMAIL
              // ==================================================

              TextField(
                controller: _emailController,
                enabled: !interactionLocked,
                keyboardType:
                    TextInputType.emailAddress,
                textInputAction:
                    TextInputAction.next,
                onSubmitted: (_) {
                  if (!interactionLocked) {
                    FocusScope.of(context)
                        .nextFocus();
                  }
                },
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                ),
                decoration: InputDecoration(
                  hintText: _t.get('email'),
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
                      color: Color(0xFFFFB7E8),
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
                controller:
                    _passwordController,
                enabled: !interactionLocked,
                obscureText:
                    _obscurePassword,
                keyboardType:
                    TextInputType.visiblePassword,
                textInputAction:
                    TextInputAction.done,
                onSubmitted: (_) {
                  if (!interactionLocked) {
                    _login();
                  }
                },
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                ),
                decoration: InputDecoration(
                  hintText: _t.get('password'),
                  hintStyle: const TextStyle(
                    color: Color(0xFFBDB4D1),
                    fontSize: 18,
                  ),
                  prefixIcon: const Icon(
                    Icons.lock_outline,
                    color: Color(0xFFB58CFF),
                  ),
                  suffixIcon: IconButton(
                    onPressed:
                        interactionLocked
                            ? null
                            : () {
                                setState(() {
                                  _obscurePassword =
                                      !_obscurePassword;
                                });
                              },
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons
                              .visibility_off_outlined,
                      color: const Color(
                        0xFFB58CFF,
                      ),
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
                      color: Color(0xFFFFB7E8),
                      width: 3,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // ==================================================
              // FORGOT PASSWORD
              // ==================================================

              Align(
                alignment:
                    Alignment.centerRight,
                child: TextButton(
                  onPressed:
                      interactionLocked
                          ? null
                          : _resetPassword,
                  style: TextButton.styleFrom(
                    foregroundColor:
                        const Color(0xFFFFB7E8),
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 8,
                    ),
                  ),
                  child:
                      _resetPasswordLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(
                                  0xFFFFB7E8,
                                ),
                              ),
                            )
                          : Text(
                              _t.get(
                                'forgotPassword',
                              ),
                              style:
                                  const TextStyle(
                                fontSize: 15,
                                fontWeight:
                                    FontWeight.w600,
                              ),
                            ),
                ),
              ),

              const SizedBox(height: 18),

              // ==================================================
              // LOGIN BUTTON
              // ==================================================

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed:
                      interactionLocked
                          ? null
                          : _login,
                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color(0xFFB58CFF),
                    foregroundColor:
                        const Color(0xFF120B24),
                    disabledBackgroundColor:
                        const Color(0xFF5E5274),
                    disabledForegroundColor:
                        const Color(0xFFD9D0E5),
                    elevation: 0,
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(16),
                    ),
                  ),
                  child:
                      _loginLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Color(
                                  0xFF120B24,
                                ),
                              ),
                            )
                          : Text(
                              _t.get('login'),
                              style:
                                  const TextStyle(
                                fontSize: 17,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                ),
              ),

              const SizedBox(height: 16),

              // ==================================================
              // REGISTER
              // ==================================================

              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed:
                      interactionLocked
                          ? null
                          : _openRegisterPage,
                  style:
                      OutlinedButton.styleFrom(
                    foregroundColor:
                        const Color(0xFFFFB7E8),
                    side: const BorderSide(
                      color: Color(0xFFFFB7E8),
                      width: 2,
                    ),
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    _t.get('createAccount'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 70),

              // ==================================================
              // FOOTER
              // ==================================================

              const Text(
                'STELLA • STELLURIINI • STL',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFFBDB4D1),
                  fontSize: 12,
                  letterSpacing: 1,
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}