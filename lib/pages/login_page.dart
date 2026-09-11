import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// ============================================================
// 🐱 STELLURIINI LOGIN PAGE
// ============================================================
//
// VAIHE 3 - FIREBASE AUTHENTICATION
//
// Tässä versiossa:
// - Firebase Authentication
// - Sähköposti + salasana
// - Salasanan näyttäminen/piilottaminen
// - Kirjautumisen lataustila
// - Selkeät virheilmoitukset
//
// Ei vielä:
// - AdMob
// - Firestore
// - Cloud Functions
// - Stack
// - Overlay
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

  bool _isLoading = false;

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
    if (_isLoading) {
      return;
    }

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    // ----------------------------------------------------------
    // VALIDATE EMAIL
    // ----------------------------------------------------------

    if (email.isEmpty) {
      _showMessage(
        'Kirjoita sähköpostiosoite.',
      );

      return;
    }

    // ----------------------------------------------------------
    // VALIDATE PASSWORD
    // ----------------------------------------------------------

    if (password.isEmpty) {
      _showMessage(
        'Kirjoita salasana.',
      );

      return;
    }

    // ----------------------------------------------------------
    // START LOADING
    // ----------------------------------------------------------

    setState(() {
      _isLoading = true;
    });

    try {
      // --------------------------------------------------------
      // FIREBASE AUTH
      // --------------------------------------------------------

      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (!mounted) {
        return;
      }

      // --------------------------------------------------------
      // SUCCESS
      // --------------------------------------------------------

      _showMessage(
        'Kirjautuminen onnistui!',
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) {
        return;
      }

      _showFirebaseError(e);
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Kirjautuminen epäonnistui.',
      );
    } finally {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });
    }
  }

  // ==========================================================
  // FIREBASE ERROR
  // ==========================================================

  void _showFirebaseError(
    FirebaseAuthException error,
  ) {
    String message;

    switch (error.code) {
      case 'invalid-email':
        message =
            'Sähköpostiosoite ei ole kelvollinen.';
        break;

      case 'user-disabled':
        message =
            'Tämä käyttäjätili on poistettu käytöstä.';
        break;

      case 'user-not-found':
        message =
            'Käyttäjää ei löytynyt.';
        break;

      case 'wrong-password':
      case 'invalid-credential':
        message =
            'Sähköposti tai salasana on väärin.';
        break;

      case 'too-many-requests':
        message =
            'Liian monta yritystä. Yritä myöhemmin uudelleen.';
        break;

      case 'network-request-failed':
        message =
            'Verkkoyhteys epäonnistui.';
        break;

      case 'operation-not-allowed':
        message =
            'Sähköposti- ja salasanakirjautuminen ei ole käytössä Firebase Consolessa.';
        break;

      default:
        message =
            'Kirjautuminen epäonnistui.\n'
            'Virhe: ${error.code}';
    }

    _showMessage(message);
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
        child: Center(
          child: Padding(
            padding:
                const EdgeInsets.all(24),

            child: Column(
              mainAxisSize:
                  MainAxisSize.min,

              children: [
                // ==================================================
                // LOGO
                // ==================================================

                Container(
                  width: 100,
                  height: 100,

                  decoration:
                      BoxDecoration(
                    shape:
                        BoxShape.circle,

                    color:
                        const Color(
                      0xFF1A0E31,
                    ),

                    border:
                        Border.all(
                      color:
                          const Color(
                        0xFFB58CFF,
                      ),
                      width: 3,
                    ),
                  ),

                  child:
                      const Center(
                    child:
                        Icon(
                      Icons.pets,

                      color:
                          Color(
                        0xFFFFB7E8,
                      ),

                      size: 58,
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

                    fontSize:
                        36,

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
                      0xFFFFD166,
                    ),

                    fontSize:
                        21,

                    fontWeight:
                        FontWeight.bold,

                    letterSpacing:
                        4,
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

                    fontSize:
                        25,

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
                      !_isLoading,

                  readOnly:
                      false,

                  keyboardType:
                      TextInputType.emailAddress,

                  textInputAction:
                      TextInputAction.next,

                  style:
                      const TextStyle(
                    color:
                        Colors.white,

                    fontSize:
                        18,
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

                      fontSize:
                          18,
                    ),

                    prefixIcon:
                        const Icon(
                      Icons.email_outlined,

                      color:
                          Color(
                        0xFFB58CFF,
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
                          0xFFB58CFF,
                        ),

                        width:
                            2,
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

                        width:
                            3,
                      ),
                    ),

                    disabledBorder:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(
                        16,
                      ),

                      borderSide:
                          const BorderSide(
                        color:
                            Color(
                          0xFF6F6382,
                        ),

                        width:
                            2,
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
                      !_isLoading,

                  readOnly:
                      false,

                  obscureText:
                      _obscurePassword,

                  keyboardType:
                      TextInputType.visiblePassword,

                  textInputAction:
                      TextInputAction.done,

                  onSubmitted:
                      (_) {
                    _login();
                  },

                  style:
                      const TextStyle(
                    color:
                        Colors.white,

                    fontSize:
                        18,
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

                      fontSize:
                          18,
                    ),

                    prefixIcon:
                        const Icon(
                      Icons.lock_outline,

                      color:
                          Color(
                        0xFFB58CFF,
                      ),
                    ),

                    suffixIcon:
                        IconButton(
                      onPressed:
                          _isLoading
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
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,

                        color:
                            const Color(
                          0xFFB58CFF,
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
                          0xFFB58CFF,
                        ),

                        width:
                            2,
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

                        width:
                            3,
                      ),
                    ),

                    disabledBorder:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(
                        16,
                      ),

                      borderSide:
                          const BorderSide(
                        color:
                            Color(
                          0xFF6F6382,
                        ),

                        width:
                            2,
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

                  height:
                      55,

                  child:
                      ElevatedButton(
                    onPressed:
                        _isLoading
                            ? null
                            : _login,

                    style:
                        ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color(
                        0xFFB58CFF,
                      ),

                      disabledBackgroundColor:
                          const Color(
                        0xFF66547D,
                      ),

                      foregroundColor:
                          const Color(
                        0xFF120B24,
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
                        _isLoading
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

                    fontSize:
                        12,

                    letterSpacing:
                        1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}