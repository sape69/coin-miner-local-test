import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
// 🌍 Ensimmäisellä asennuksella oletuskieli = ENGLISH.
//
// Käyttäjä voi vaihtaa kielen suoraan kirjautumissivulta.
// Ensimmäinen asennus tallennetaan SharedPreferencesiin,
// joten englanti asetetaan automaattisesti vain ensimmäisellä
// käyttökerralla.
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
  // CONSTANTS
  // ==========================================================

  static const String _firstInstallLanguageKey =
      'stelluriini_first_install_language_initialized';

  // ==========================================================
  // 🎨 STELLA COLORS
  // ==========================================================

  static const Color backgroundColor =
      Color(0xFF120B24);

  static const Color cardColor =
      Color(0xFF21113B);

  static const Color accentColor =
      Color(0xFFB58CFF);

  static const Color pinkColor =
      Color(0xFFFFB7E8);

  static const Color goldColor =
      Color(0xFFFFD166);

  static const Color primaryTextColor =
      Color(0xFFF8F4FF);

  static const Color secondaryTextColor =
      Color(0xFFBDB4D1);

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
  // INIT
  // ==========================================================

  @override
  void initState() {
    super.initState();

    _initializeFirstInstallLanguage();
  }

  // ==========================================================
  // FIRST INSTALL LANGUAGE
  // ==========================================================

  Future<void> _initializeFirstInstallLanguage() async {
    try {
      final SharedPreferences preferences =
          await SharedPreferences.getInstance();

      final bool initialized =
          preferences.getBool(
                _firstInstallLanguageKey,
              ) ??
              false;

      if (initialized) {
        return;
      }

      await preferences.setBool(
        _firstInstallLanguageKey,
        true,
      );

      if (!mounted) {
        return;
      }

      if (widget.languageCode != 'en') {
        await widget.changeLanguage('en');
      }
    } catch (error) {
      debugPrint(
        'First install language initialization error: $error',
      );
    }
  }

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
  // 💬 MESSAGE
  // ==========================================================
  //
  // Selkeä Stella-tyylinen ilmoituskortti.
  //
  // Tarkoitus:
  // - ei huku tummaan taustaan
  // - onnistuminen näkyy kultaisena
  // - virhe näkyy pinkkinä
  // - teksti on helposti luettava
  // ==========================================================

  void _showMessage(
    String message, {
    bool isError = true,
  }) {
    if (!mounted) {
      return;
    }

    final ScaffoldMessengerState messenger =
        ScaffoldMessenger.of(context);

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: Duration(
            seconds: isError ? 4 : 3,
          ),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(
            16,
            0,
            16,
            24,
          ),
          padding: EdgeInsets.zero,
          elevation: 16,
          backgroundColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(
              16,
              14,
              10,
              14,
            ),
            decoration: BoxDecoration(
              color: isError
                  ? const Color(0xFF35152D)
                  : const Color(0xFF30251A),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isError
                    ? const Color(0xFFFF7FAF)
                    : goldColor,
                width: 1.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: isError
                      ? const Color(0x99FF7FAF)
                      : const Color(0x99FFD166),
                  blurRadius: 22,
                  spreadRadius: 2,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment:
                  CrossAxisAlignment.center,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: isError
                        ? const Color(0x44FF7FAF)
                        : const Color(0x44FFD166),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isError
                          ? const Color(0xFFFF7FAF)
                          : goldColor,
                      width: 1.2,
                    ),
                  ),
                  child: Icon(
                    isError
                        ? Icons.error_outline_rounded
                        : Icons.check_circle_rounded,
                    color: isError
                        ? const Color(0xFFFFB8D0)
                        : goldColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: primaryTextColor,
                      fontSize: 15,
                      height: 1.35,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  visualDensity:
                      VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(
                    minWidth: 34,
                    minHeight: 34,
                  ),
                  icon: const Icon(
                    Icons.close_rounded,
                    color: secondaryTextColor,
                    size: 21,
                  ),
                  onPressed: () {
                    messenger.hideCurrentSnackBar();
                  },
                ),
              ],
            ),
          ),
        ),
      );
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
        isError: false,
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

    if (languageCode == widget.languageCode) {
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
        color: cardColor,
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
                          ? pinkColor
                          : accentColor,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      entry.value,
                      style: TextStyle(
                        color: primaryTextColor,
                        fontWeight: selected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              );
            },
          ).toList();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: accentColor,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.language,
                color: accentColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                currentLanguage,
                style: const TextStyle(
                  color: primaryTextColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.keyboard_arrow_down,
                color: pinkColor,
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
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    final bool interactionLocked =
        _loginLoading ||
        _resetPasswordLoading;

    return Scaffold(
      backgroundColor: backgroundColor,
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
                      color: accentColor.withValues(
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
                        color: accentColor,
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
                  color: primaryTextColor,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 6),

              const Text(
                'STL',
                style: TextStyle(
                  color: accentColor,
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
                  color: primaryTextColor,
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
                    color: secondaryTextColor,
                    fontSize: 18,
                  ),
                  prefixIcon: const Icon(
                    Icons.email_outlined,
                    color: accentColor,
                  ),
                  filled: true,
                  fillColor: cardColor,
                  enabledBorder:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(16),
                    borderSide:
                        const BorderSide(
                      color: accentColor,
                      width: 2,
                    ),
                  ),
                  focusedBorder:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(16),
                    borderSide:
                        const BorderSide(
                      color: pinkColor,
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
                    color: secondaryTextColor,
                    fontSize: 18,
                  ),
                  prefixIcon: const Icon(
                    Icons.lock_outline,
                    color: accentColor,
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
                          ? Icons
                              .visibility_outlined
                          : Icons
                              .visibility_off_outlined,
                      color: accentColor,
                    ),
                  ),
                  filled: true,
                  fillColor: cardColor,
                  enabledBorder:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(16),
                    borderSide:
                        const BorderSide(
                      color: accentColor,
                      width: 2,
                    ),
                  ),
                  focusedBorder:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(16),
                    borderSide:
                        const BorderSide(
                      color: pinkColor,
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
                    foregroundColor: pinkColor,
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
                                color: pinkColor,
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
                    backgroundColor: accentColor,
                    foregroundColor:
                        backgroundColor,
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
                                color:
                                    backgroundColor,
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
                    foregroundColor: pinkColor,
                    side: const BorderSide(
                      color: pinkColor,
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
                  color: secondaryTextColor,
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