import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../localization.dart';
import '../widgets/cat_avatar.dart';
import 'forgot_password_page.dart';
import 'register_page.dart';

// ============================================================
// 🐱 STELLURIINI / LOGIN PAGE
// ============================================================
//
// Firebase Authentication -kirjautuminen.
//
// Tämä sivu:
// - käyttää Stelluriinin Stella-teemaa
// - tukee nykyistä lokalisaatiojärjestelmää
// - käyttää Firebase Email/Password -kirjautumista
// - sisältää salasanan palautuksen
// - sisältää uuden käyttäjätilin luonnin
// - sisältää kielivalinnan
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

// ============================================================
// STATE
// ============================================================

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController =
      TextEditingController();

  final TextEditingController passwordController =
      TextEditingController();

  bool loading = false;
  bool showPassword = false;

  // ==========================================================
  // LOCALIZATION
  // ==========================================================

  AppLocalizations get t =>
      AppLocalizations(widget.languageCode);

  String _t(String key) {
    return t.get(key);
  }

  // ==========================================================
  // DISPOSE
  // ==========================================================

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();

    super.dispose();
  }

  // ==========================================================
  // MESSAGE
  // ==========================================================

  void _message(String text) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(text),
        ),
      );
  }

  // ==========================================================
  // LOGIN
  // ==========================================================

  Future<void> _login() async {
    final email =
        emailController.text.trim();

    final password =
        passwordController.text;

    if (email.isEmpty ||
        password.isEmpty) {
      _message(
        _t('loginFillFields'),
      );

      return;
    }

    setState(() {
      loading = true;
    });

    try {
      await FirebaseAuth.instance
          .signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // AuthGate huomaa automaattisesti
      // Firebase Authentication -tilan muutoksen
      // ja avaa HomePage-sivun.
    } on FirebaseAuthException catch (error) {
      String message;

      switch (error.code) {
        case 'invalid-email':
          message =
              _t('loginInvalidEmail');
          break;

        case 'user-not-found':
          message =
              _t('loginUserNotFound');
          break;

        case 'wrong-password':
        case 'invalid-credential':
          message =
              _t('loginInvalidCredentials');
          break;

        case 'user-disabled':
          message =
              _t('loginUserDisabled');
          break;

        case 'too-many-requests':
          message =
              _t('loginTooManyRequests');
          break;

        case 'network-request-failed':
          message =
              _t('loginNetworkError');
          break;

        default:
          message =
              '${_t('loginFailed')}: '
              '${error.message ?? error.code}';
      }

      _message(message);
    } catch (_) {
      _message(
        _t('loginFailed'),
      );
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  // ==========================================================
  // 🌍 LANGUAGE
  // ==========================================================

  void _openLanguageDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            _t('language'),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: AppLocalizations
                  .supportedLanguages
                  .entries
                  .map(
                (entry) {
                  return ListTile(
                    title: Text(
                      entry.value,
                    ),
                    trailing:
                        widget.languageCode ==
                                entry.key
                            ? const Icon(
                                Icons.check,
                              )
                            : null,
                    onTap: () async {
                      await widget.changeLanguage(
                        entry.key,
                      );

                      if (dialogContext.mounted) {
                        Navigator.pop(
                          dialogContext,
                        );
                      }
                    },
                  );
                },
              ).toList(),
            ),
          ),
        );
      },
    );
  }

  // ==========================================================
  // 🏠 BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            tooltip: _t('language'),
            icon: const Icon(
              Icons.language,
            ),
            onPressed: loading
                ? null
                : _openLanguageDialog,
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.all(24),
            child: Card(
              child: Padding(
                padding:
                    const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize:
                      MainAxisSize.min,
                  children: [
                    // ==================================================
                    // STELLA
                    // ==================================================

                    const CatAvatar(
                      size: 120,
                    ),

                    const SizedBox(
                      height: 20,
                    ),

                    // ==================================================
                    // APP NAME
                    // ==================================================

                    const Text(
                      'STELLURIINI',
                      textAlign:
                          TextAlign.center,
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight:
                            FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),

                    const SizedBox(
                      height: 8,
                    ),

                    const Text(
                      'STL',
                      style: TextStyle(
                        fontSize: 16,
                        color:
                            Colors.white60,
                        letterSpacing: 4,
                      ),
                    ),

                    const SizedBox(
                      height: 28,
                    ),

                    // ==================================================
                    // EMAIL
                    // ==================================================

                    TextField(
                      controller:
                          emailController,
                      keyboardType:
                          TextInputType.emailAddress,
                      textInputAction:
                          TextInputAction.next,
                      enabled:
                          !loading,
                      decoration:
                          InputDecoration(
                        labelText:
                            _t('email'),
                        prefixIcon:
                            const Icon(
                          Icons.email_outlined,
                        ),
                        border:
                            const OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(
                      height: 16,
                    ),

                    // ==================================================
                    // PASSWORD
                    // ==================================================

                    TextField(
                      controller:
                          passwordController,
                      obscureText:
                          !showPassword,
                      textInputAction:
                          TextInputAction.done,
                      enabled:
                          !loading,
                      onSubmitted: (_) {
                        if (!loading) {
                          _login();
                        }
                      },
                      decoration:
                          InputDecoration(
                        labelText:
                            _t('password'),
                        prefixIcon:
                            const Icon(
                          Icons.lock_outline,
                        ),
                        border:
                            const OutlineInputBorder(),
                        suffixIcon:
                            IconButton(
                          icon: Icon(
                            showPassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed:
                              loading
                                  ? null
                                  : () {
                                      setState(() {
                                        showPassword =
                                            !showPassword;
                                      });
                                    },
                        ),
                      ),
                    ),

                    // ==================================================
                    // FORGOT PASSWORD
                    // ==================================================

                    Align(
                      alignment:
                          Alignment.centerRight,
                      child: TextButton(
                        onPressed: loading
                            ? null
                            : () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const ForgotPasswordPage(),
                                  ),
                                );
                              },
                        child: Text(
                          _t(
                            'forgotPassword',
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    // ==================================================
                    // LOGIN BUTTON
                    // ==================================================

                    SizedBox(
                      width:
                          double.infinity,
                      height: 55,
                      child:
                          ElevatedButton.icon(
                        onPressed: loading
                            ? null
                            : _login,
                        icon: loading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color:
                                      Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons.login,
                              ),
                        label: Text(
                          loading
                              ? _t(
                                  'loggingIn',
                                )
                              : _t(
                                  'login',
                                ),
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 10,
                    ),

                    // ==================================================
                    // REGISTER
                    // ==================================================

                    TextButton(
                      onPressed: loading
                          ? null
                          : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const RegisterPage(),
                                ),
                              );
                            },
                      child: Text(
                        _t(
                          'createAccount',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}