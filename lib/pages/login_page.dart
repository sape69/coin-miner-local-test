import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'register_page.dart';

// ============================================================
// 🐱 STELLURIINI LOGIN PAGE
// ============================================================
//
// Firebase-kirjautuminen:
//
// LoginPage
//     ↓
// FirebaseAuth.signInWithEmailAndPassword()
//     ↓
// onnistunut kirjautuminen
//     ↓
// AuthGate huomaa kirjautumisen
//     ↓
// HomePage
//
// Lisäksi:
//
// UNOHTUITKO SALASANA?
//     ↓
// FirebaseAuth.sendPasswordResetEmail()
//     ↓
// Firebase lähettää palautuslinkin sähköpostiin
//
// LUO UUSI TILI
//     ↓
// RegisterPage
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
  // 🔥 FIREBASE AUTH
  // ==========================================================

  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ==========================================================
  // 📝 CONTROLLERS
  // ==========================================================

  final TextEditingController _emailController =
      TextEditingController();

  final TextEditingController _passwordController =
      TextEditingController();

  // ==========================================================
  // 🔄 STATE
  // ==========================================================

  bool _obscurePassword = true;
  bool _loginLoading = false;
  bool _resetPasswordLoading = false;

  // ==========================================================
  // 🎨 STELLA COLORS
  // ==========================================================

  static const Color backgroundColor =
      Color(0xFF120B24);

  static const Color surfaceColor =
      Color(0xFF1A0E31);

  static const Color cardColor =
      Color(0xFF21113B);

  static const Color purpleColor =
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
  // 🧹 DISPOSE
  // ==========================================================

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();

    super.dispose();
  }

  // ==========================================================
  // 🔥 FIREBASE LOGIN
  // ==========================================================

  Future<void> _login() async {
    if (_loginLoading ||
        _resetPasswordLoading) {
      return;
    }

    final String email =
        _emailController.text.trim();

    final String password =
        _passwordController.text;

    // ========================================================
    // 📧 EMAIL CHECK
    // ========================================================

    if (email.isEmpty) {
      _showMessage(
        'Kirjoita sähköpostiosoite.',
      );

      return;
    }

    // ========================================================
    // 🔐 PASSWORD CHECK
    // ========================================================

    if (password.isEmpty) {
      _showMessage(
        'Kirjoita salasana.',
      );

      return;
    }

    // ========================================================
    // 🔄 START LOGIN
    // ========================================================

    setState(() {
      _loginLoading = true;
    });

    try {
      // ======================================================
      // 🔥 FIREBASE EMAIL/PASSWORD LOGIN
      // ======================================================

      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // ======================================================
      // ✅ LOGIN SUCCESS
      // ======================================================
      //
      // AuthGate siirtyy HomePageen automaattisesti.
      //
      // ======================================================

      if (mounted) {
        _showMessage(
          'Kirjautuminen onnistui!',
        );
      }
    } on FirebaseAuthException catch (error) {
      debugPrint(
        'Firebase login error: '
        '${error.code} - ${error.message}',
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        _firebaseErrorMessage(
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
        'Kirjautuminen epäonnistui. '
        'Yritä uudelleen.',
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
  // 🔐 FORGOT PASSWORD
  // ==========================================================

  Future<void> _resetPassword() async {
    if (_loginLoading ||
        _resetPasswordLoading) {
      return;
    }

    final String email =
        _emailController.text.trim();

    // ========================================================
    // 📧 EMAIL REQUIRED
    // ========================================================

    if (email.isEmpty) {
      _showMessage(
        'Kirjoita sähköpostiosoitteesi ensin.',
      );

      return;
    }

    // ========================================================
    // 🔄 START PASSWORD RESET
    // ========================================================

    setState(() {
      _resetPasswordLoading = true;
    });

    try {
      // ======================================================
      // 🔥 FIREBASE PASSWORD RESET
      // ======================================================

      await _auth.sendPasswordResetEmail(
        email: email,
      );

      // ======================================================
      // ✅ SUCCESS
      // ======================================================

      if (mounted) {
        _showMessage(
          'Salasanan palautuslinkki lähetettiin '
          'sähköpostiisi.',
        );
      }
    } on FirebaseAuthException catch (error) {
      debugPrint(
        'Firebase password reset error: '
        '${error.code} - ${error.message}',
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        _passwordResetErrorMessage(
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
        'Salasanan palautus epäonnistui. '
        'Yritä uudelleen.',
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
  // 👤 OPEN REGISTER PAGE
  // ==========================================================

  Future<void> _openRegisterPage() async {
    if (_loginLoading ||
        _resetPasswordLoading) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (
          BuildContext context,
        ) {
          return RegisterPage(
            languageCode:
                widget.languageCode,
            changeLanguage:
                widget.changeLanguage,
          );
        },
      ),
    );
  }

  // ==========================================================
  // 🔥 FIREBASE LOGIN ERROR MESSAGES
  // ==========================================================

  String _firebaseErrorMessage(
    String code,
  ) {
    switch (code) {
      case 'invalid-email':
        return 'Sähköpostiosoite ei ole kelvollinen.';

      case 'user-disabled':
        return 'Tämä käyttäjätili on poistettu käytöstä.';

      case 'user-not-found':
        return 'Käyttäjää ei löytynyt.';

      case 'wrong-password':
      case 'invalid-credential':
        return 'Sähköposti tai salasana on väärin.';

      case 'too-many-requests':
        return 'Liian monta kirjautumisyritystä. '
            'Yritä myöhemmin uudelleen.';

      case 'network-request-failed':
        return 'Verkkoyhteys epäonnistui. '
            'Tarkista internetyhteys.';

      case 'operation-not-allowed':
        return 'Sähköposti- ja salasanakirjautuminen '
            'ei ole käytössä.';

      default:
        return 'Kirjautuminen epäonnistui. '
            'Yritä uudelleen.';
    }
  }

  // ==========================================================
  // 🔐 PASSWORD RESET ERROR MESSAGES
  // ==========================================================

  String _passwordResetErrorMessage(
    String code,
  ) {
    switch (code) {
      case 'invalid-email':
        return 'Sähköpostiosoite ei ole kelvollinen.';

      case 'user-not-found':
        return 'Sähköpostiosoitteelle ei löytynyt '
            'käyttäjätiliä.';

      case 'user-disabled':
        return 'Tämä käyttäjätili on poistettu käytöstä.';

      case 'too-many-requests':
        return 'Liian monta palautusyritystä. '
            'Yritä myöhemmin uudelleen.';

      case 'network-request-failed':
        return 'Verkkoyhteys epäonnistui. '
            'Tarkista internetyhteys.';

      case 'operation-not-allowed':
        return 'Salasanan palautus ei ole käytössä.';

      default:
        return 'Salasanan palautus epäonnistui. '
            'Yritä uudelleen.';
    }
  }

  // ==========================================================
  // 💬 MESSAGE
  // ==========================================================

  void _showMessage(
    String message,
  ) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
          ),
          behavior:
              SnackBarBehavior.floating,
          backgroundColor:
              cardColor,
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              14,
            ),
          ),
        ),
      );
  }

  // ==========================================================
  // 🖥️ BUILD
  // ==========================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final bool interactionDisabled =
        _loginLoading ||
        _resetPasswordLoading;

    return Scaffold(
      backgroundColor:
          backgroundColor,

      resizeToAvoidBottomInset:
          true,

      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior:
              ScrollViewKeyboardDismissBehavior.onDrag,

          physics:
              const AlwaysScrollableScrollPhysics(),

          padding:
              const EdgeInsets.fromLTRB(
            24,
            35,
            24,
            60,
          ),

          child: Column(
            children: [
              // ==================================================
              // 🐱 STELLURIINI LOGO
              // ==================================================

              Container(
                width: 190,
                height: 190,

                decoration:
                    BoxDecoration(
                  shape:
                      BoxShape.circle,

                  boxShadow: [
                    BoxShadow(
                      color:
                          purpleColor.withValues(
                        alpha: 0.28,
                      ),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                    BoxShadow(
                      color:
                          pinkColor.withValues(
                        alpha: 0.12,
                      ),
                      blurRadius: 50,
                      spreadRadius: 2,
                    ),
                  ],
                ),

                child:
                    ClipOval(
                  child:
                      Image.asset(
                    'assets/images/stelluriini_logo.png',

                    width: 190,
                    height: 190,

                    fit:
                        BoxFit.cover,

                    errorBuilder:
                        (
                      BuildContext context,
                      Object error,
                      StackTrace? stackTrace,
                    ) {
                      return const Icon(
                        Icons.pets,
                        color:
                            purpleColor,
                        size: 80,
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(
                height: 20,
              ),

              // ==================================================
              // 🌟 TITLE
              // ==================================================

              const Text(
                'Stelluriini',

                style:
                    TextStyle(
                  color:
                      primaryTextColor,
                  fontSize: 36,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(
                height: 6,
              ),

              const Text(
                'STL',

                style:
                    TextStyle(
                  color:
                      goldColor,
                  fontSize: 21,
                  fontWeight:
                      FontWeight.bold,
                  letterSpacing: 4,
                ),
              ),

              const SizedBox(
                height: 35,
              ),

              // ==================================================
              // 🔐 LOGIN TITLE
              // ==================================================

              const Text(
                'KIRJAUDU SISÄÄN',

                textAlign:
                    TextAlign.center,

                style:
                    TextStyle(
                  color:
                      primaryTextColor,
                  fontSize: 25,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(
                height: 28,
              ),

              // ==================================================
              // 📧 EMAIL
              // ==================================================

              TextField(
                controller:
                    _emailController,

                enabled:
                    !interactionDisabled,

                keyboardType:
                    TextInputType.emailAddress,

                textInputAction:
                    TextInputAction.next,

                onSubmitted:
                    (_) {
                  if (!interactionDisabled) {
                    FocusScope.of(
                      context,
                    ).nextFocus();
                  }
                },

                style:
                    const TextStyle(
                  color:
                      Colors.white,
                  fontSize: 18,
                ),

                decoration:
                    InputDecoration(
                  hintText:
                      'Sähköposti',

                  hintStyle:
                      const TextStyle(
                    color:
                        secondaryTextColor,
                    fontSize: 18,
                  ),

                  prefixIcon:
                      const Icon(
                    Icons.email_outlined,
                    color:
                        purpleColor,
                  ),

                  filled:
                      true,

                  fillColor:
                      cardColor,

                  enabledBorder:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(
                      16,
                    ),

                    borderSide:
                        const BorderSide(
                      color:
                          purpleColor,
                      width: 2,
                    ),
                  ),

                  focusedBorder:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(
                      16,
                    ),

                    borderSide:
                        const BorderSide(
                      color:
                          pinkColor,
                      width: 3,
                    ),
                  ),
                ),
              ),

              const SizedBox(
                height: 20,
              ),

              // ==================================================
              // 🔐 PASSWORD
              // ==================================================

              TextField(
                controller:
                    _passwordController,

                enabled:
                    !interactionDisabled,

                obscureText:
                    _obscurePassword,

                keyboardType:
                    TextInputType.visiblePassword,

                textInputAction:
                    TextInputAction.done,

                onSubmitted:
                    (_) {
                  if (!interactionDisabled) {
                    _login();
                  }
                },

                style:
                    const TextStyle(
                  color:
                      Colors.white,
                  fontSize: 18,
                ),

                decoration:
                    InputDecoration(
                  hintText:
                      'Salasana',

                  hintStyle:
                      const TextStyle(
                    color:
                        secondaryTextColor,
                    fontSize: 18,
                  ),

                  prefixIcon:
                      const Icon(
                    Icons.lock_outline,
                    color:
                        purpleColor,
                  ),

                  suffixIcon:
                      IconButton(
                    onPressed:
                        interactionDisabled
                            ? null
                            : () {
                                setState(() {
                                  _obscurePassword =
                                      !_obscurePassword;
                                });
                              },

                    icon:
                        Icon(
                      _obscurePassword
                          ? Icons
                              .visibility_outlined
                          : Icons
                              .visibility_off_outlined,

                      color:
                          purpleColor,
                    ),
                  ),

                  filled:
                      true,

                  fillColor:
                      cardColor,

                  enabledBorder:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(
                      16,
                    ),

                    borderSide:
                        const BorderSide(
                      color:
                          purpleColor,
                      width: 2,
                    ),
                  ),

                  focusedBorder:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(
                      16,
                    ),

                    borderSide:
                        const BorderSide(
                      color:
                          pinkColor,
                      width: 3,
                    ),
                  ),
                ),
              ),

              const SizedBox(
                height: 10,
              ),

              // ==================================================
              // 🔐 FORGOT PASSWORD
              // ==================================================

              Align(
                alignment:
                    Alignment.centerRight,

                child:
                    TextButton(
                  onPressed:
                      interactionDisabled
                          ? null
                          : _resetPassword,

                  style:
                      TextButton.styleFrom(
                    foregroundColor:
                        pinkColor,

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
                                strokeWidth:
                                    2.2,
                                color:
                                    pinkColor,
                              ),
                            )
                          : const Text(
                              'UNOHTUIKO SALASANA?',
                              style:
                                  TextStyle(
                                fontSize: 14,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                ),
              ),

              const SizedBox(
                height: 12,
              ),

              // ==================================================
              // 🔐 LOGIN BUTTON
              // ==================================================

              SizedBox(
                width:
                    double.infinity,

                height: 55,

                child:
                    ElevatedButton(
                  onPressed:
                      interactionDisabled
                          ? null
                          : _login,

                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        purpleColor,

                    foregroundColor:
                        backgroundColor,

                    disabledBackgroundColor:
                        const Color(
                      0xFF5E5275,
                    ),

                    disabledForegroundColor:
                        const Color(
                      0xFFD9D0E5,
                    ),

                    elevation:
                        0,

                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        16,
                      ),
                    ),
                  ),

                  child:
                      _loginLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth:
                                    2.5,
                                color:
                                    backgroundColor,
                              ),
                            )
                          : const Text(
                              'KIRJAUDU SISÄÄN',

                              style:
                                  TextStyle(
                                fontSize:
                                    17,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                ),
              ),

              const SizedBox(
                height: 18,
              ),

              // ==================================================
              // ✨ DIVIDER
              // ==================================================

              Row(
                children: [
                  Expanded(
                    child:
                        Divider(
                      color:
                          purpleColor.withValues(
                        alpha: 0.25,
                      ),
                    ),
                  ),

                  const Padding(
                    padding:
                        EdgeInsets.symmetric(
                      horizontal: 14,
                    ),
                    child:
                        Text(
                      'TAI',
                      style:
                          TextStyle(
                        color:
                            secondaryTextColor,
                        fontSize: 12,
                        fontWeight:
                            FontWeight.bold,
                        letterSpacing:
                            1.5,
                      ),
                    ),
                  ),

                  Expanded(
                    child:
                        Divider(
                      color:
                          purpleColor.withValues(
                        alpha: 0.25,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height: 18,
              ),

              // ==================================================
              // 👤 CREATE ACCOUNT
              // ==================================================
              //
              // Tämä on AINA näkyvissä.
              //
              // Ei SharedPreferences-tarkistusta.
              //
              // ==================================================

              SizedBox(
                width:
                    double.infinity,

                height: 52,

                child:
                    OutlinedButton.icon(
                  onPressed:
                      interactionDisabled
                          ? null
                          : _openRegisterPage,

                  icon:
                      const Icon(
                    Icons.person_add_alt_1,
                    size: 21,
                  ),

                  label:
                      const Text(
                    'LUO UUSI TILI',
                    style:
                        TextStyle(
                      fontSize: 16,
                      fontWeight:
                          FontWeight.bold,
                      letterSpacing:
                          0.3,
                    ),
                  ),

                  style:
                      OutlinedButton.styleFrom(
                    foregroundColor:
                        pinkColor,

                    disabledForegroundColor:
                        const Color(
                      0xFF756A87,
                    ),

                    side:
                        const BorderSide(
                      color:
                          pinkColor,
                      width: 2,
                    ),

                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        16,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(
                height: 70,
              ),

              // ==================================================
              // 🐱 FOOTER
              // ==================================================

              const Text(
                '🐱  STELLA • STELLURIINI • STL  ✨',

                textAlign:
                    TextAlign.center,

                style:
                    TextStyle(
                  color:
                      secondaryTextColor,
                  fontSize: 12,
                  letterSpacing: 1,
                ),
              ),

              const SizedBox(
                height: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}