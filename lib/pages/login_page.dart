import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../localization.dart';
import '../widgets/cat_avatar.dart';
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
  final TextEditingController emailController =
      TextEditingController();

  final TextEditingController passwordController =
      TextEditingController();

  bool loading = false;
  bool showPassword = false;

  AppLocalizations get t =>
      AppLocalizations(widget.languageCode);

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
    if (!mounted) return;

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
        'Anna sähköposti ja salasana.',
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
      // kirjautumisen ja avaa HomePage-sivun.
    } on FirebaseAuthException catch (error) {
      String message;

      switch (error.code) {
        case 'invalid-email':
          message =
              'Sähköpostiosoite ei ole kelvollinen.';
          break;

        case 'user-not-found':
          message =
              'Käyttäjää ei löytynyt.';
          break;

        case 'wrong-password':
        case 'invalid-credential':
          message =
              'Sähköposti tai salasana on väärä.';
          break;

        case 'user-disabled':
          message =
              'Tämä käyttäjätili on poistettu käytöstä.';
          break;

        case 'too-many-requests':
          message =
              'Liian monta yritystä. Yritä myöhemmin uudelleen.';
          break;

        case 'network-request-failed':
          message =
              'Verkkoyhteys epäonnistui.';
          break;

        default:
          message =
              'Kirjautuminen epäonnistui: ${error.message ?? error.code}';
      }

      _message(message);
    } catch (_) {
      _message(
        'Kirjautuminen epäonnistui.',
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
  // LANGUAGE
  // ==========================================================

  void _openLanguageDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Valitse kieli',
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
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            tooltip: 'Vaihda kieli',
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
                    const CatAvatar(
                      size: 120,
                    ),

                    const SizedBox(
                      height: 20,
                    ),

                    const Text(
                      'STELLURIINI',
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
                        color: Colors.white60,
                        letterSpacing: 4,
                      ),
                    ),

                    const SizedBox(
                      height: 28,
                    ),

                    TextField(
                      controller:
                          emailController,
                      keyboardType:
                          TextInputType
                              .emailAddress,
                      textInputAction:
                          TextInputAction.next,
                      enabled: !loading,
                      decoration:
                          const InputDecoration(
                        labelText:
                            'Sähköposti',
                        prefixIcon: Icon(
                          Icons.email_outlined,
                        ),
                        border:
                            OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(
                      height: 16,
                    ),

                    TextField(
                      controller:
                          passwordController,
                      obscureText:
                          !showPassword,
                      textInputAction:
                          TextInputAction.done,
                      enabled: !loading,
                      onSubmitted: (_) {
                        if (!loading) {
                          _login();
                        }
                      },
                      decoration:
                          InputDecoration(
                        labelText:
                            'Salasana',
                        prefixIcon: const Icon(
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
                          onPressed: loading
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
                        child: const Text(
                          'Unohditko salasanan?',
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 12,
                    ),

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
                                  color: Colors.black,
                                ),
                              )
                            : const Icon(
                                Icons.login,
                              ),
                        label: Text(
                          loading
                              ? 'KIRJAUDUTAAN...'
                              : 'KIRJAUDU SISÄÄN',
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 10,
                    ),

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
                      child: const Text(
                        'Ei vielä tiliä? Luo uusi tili',
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