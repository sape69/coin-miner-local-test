import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// ============================================================
// 🐱 STELLURIINI LOGIN PAGE
// ============================================================
//
// OIKEA FIREBASE-KIRJAUTUMINEN
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
  // FIREBASE AUTH
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
  // FIREBASE LOGIN
  // ==========================================================

  Future<void> _login() async {
    if (_loginLoading) {
      return;
    }

    final String email =
        _emailController.text.trim();

    final String password =
        _passwordController.text;

    // ========================================================
    // EMAIL CHECK
    // ========================================================

    if (email.isEmpty) {
      _showMessage(
        'Kirjoita sähköpostiosoite.',
      );

      return;
    }

    // ========================================================
    // PASSWORD CHECK
    // ========================================================

    if (password.isEmpty) {
      _showMessage(
        'Kirjoita salasana.',
      );

      return;
    }

    // ========================================================
    // START LOGIN
    // ========================================================

    setState(() {
      _loginLoading = true;
    });

    try {
      // ======================================================
      // FIREBASE EMAIL/PASSWORD LOGIN
      // ======================================================

      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // ======================================================
      // SUCCESS
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
  // FIREBASE ERROR MESSAGES
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
  // MESSAGE
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
              const Color(0xFF21113B),
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
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFF120B24),

      resizeToAvoidBottomInset:
          true,

      body: SafeArea(
        child: LayoutBuilder(
          builder: (
            BuildContext context,
            BoxConstraints constraints,
          ) {
            return SingleChildScrollView(
              keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,

              physics:
                  const AlwaysScrollableScrollPhysics(),

              padding:
                  const EdgeInsets.all(
                24,
              ),

              child: ConstrainedBox(
                constraints:
                    BoxConstraints(
                  minHeight:
                      constraints.maxHeight - 48,
                ),

                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      const Spacer(),

                      // ==================================================
                      // STELLURIINI LOGO
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
                                  const Color(
                                0xFF35D0A0,
                              ).withValues(
                                alpha: 0.25,
                              ),
                              blurRadius: 25,
                              spreadRadius: 4,
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
                                    Color(
                                  0xFF35D0A0,
                                ),
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
                      // TITLE
                      // ==================================================

                      const Text(
                        'Stelluriini',

                        style:
                            TextStyle(
                          color:
                              Color(
                            0xFFF8F4FF,
                          ),
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
                              Color(
                            0xFF35D0A0,
                          ),
                          fontSize: 21,
                          fontWeight:
                              FontWeight.bold,
                          letterSpacing: 4,
                        ),
                      ),

                      const SizedBox(
                        height: 30,
                      ),

                      // ==================================================
                      // LOGIN TITLE
                      // ==================================================

                      const Text(
                        'KIRJAUDU SISÄÄN',

                        textAlign:
                            TextAlign.center,

                        style:
                            TextStyle(
                          color:
                              Color(
                            0xFFF8F4FF,
                          ),
                          fontSize: 25,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(
                        height: 25,
                      ),

                      // ==================================================
                      // EMAIL
                      // ==================================================

                      TextField(
                        controller:
                            _emailController,

                        enabled:
                            !_loginLoading,

                        keyboardType:
                            TextInputType.emailAddress,

                        textInputAction:
                            TextInputAction.next,

                        onSubmitted:
                            (_) {
                          if (!_loginLoading) {
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
                                Color(
                              0xFFBDB4D1,
                            ),
                            fontSize: 18,
                          ),

                          prefixIcon:
                              const Icon(
                            Icons.email_outlined,
                            color:
                                Color(
                              0xFF35D0A0,
                            ),
                          ),

                          filled:
                              true,

                          fillColor:
                              const Color(
                            0xFF21113B,
                          ),

                          enabledBorder:
                              OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(
                              16,
                            ),

                            borderSide:
                                const BorderSide(
                              color:
                                  Color(
                                0xFF35D0A0,
                              ),
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
                                  Colors.white,
                              width: 3,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 18,
                      ),

                      // ==================================================
                      // PASSWORD
                      // ==================================================

                      TextField(
                        controller:
                            _passwordController,

                        enabled:
                            !_loginLoading,

                        obscureText:
                            _obscurePassword,

                        keyboardType:
                            TextInputType.visiblePassword,

                        textInputAction:
                            TextInputAction.done,

                        onSubmitted:
                            (_) {
                          if (!_loginLoading) {
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
                                Color(
                              0xFFBDB4D1,
                            ),
                            fontSize: 18,
                          ),

                          prefixIcon:
                              const Icon(
                            Icons.lock_outline,
                            color:
                                Color(
                              0xFF35D0A0,
                            ),
                          ),

                          suffixIcon:
                              IconButton(
                            onPressed:
                                _loginLoading
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
                                  const Color(
                                0xFF35D0A0,
                              ),
                            ),
                          ),

                          filled:
                              true,

                          fillColor:
                              const Color(
                            0xFF21113B,
                          ),

                          enabledBorder:
                              OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(
                              16,
                            ),

                            borderSide:
                                const BorderSide(
                              color:
                                  Color(
                                0xFF35D0A0,
                              ),
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
                                  Colors.white,
                              width: 3,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 25,
                      ),

                      // ==================================================
                      // LOGIN BUTTON
                      // ==================================================

                      SizedBox(
                        width:
                            double.infinity,

                        height: 55,

                        child:
                            ElevatedButton(
                          onPressed:
                              _loginLoading
                                  ? null
                                  : _login,

                          style:
                              ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color(
                              0xFF35D0A0,
                            ),

                            foregroundColor:
                                const Color(
                              0xFF120B24,
                            ),

                            disabledBackgroundColor:
                                const Color(
                              0xFF587D72,
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
                                            Color(
                                          0xFF120B24,
                                        ),
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
                        height: 20,
                      ),

                      // ==================================================
                      // FOOTER
                      // ==================================================

                      const Text(
                        'STELLA • STELLURIINI • STL',

                        textAlign:
                            TextAlign.center,

                        style:
                            TextStyle(
                          color:
                              Color(
                            0xFFBDB4D1,
                          ),
                          fontSize: 12,
                          letterSpacing: 1,
                        ),
                      ),

                      const SizedBox(
                        height: 40,
                      ),

                      const Spacer(),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}