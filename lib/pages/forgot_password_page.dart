import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../localization.dart';
import '../widgets/cat_avatar.dart';

// ============================================================
// 🐱 STELLURIINI / FORGOT PASSWORD PAGE
// ============================================================
//
// Firebase Authentication - salasanan palautus.
//
// Tämä sivu:
// - käyttää Stelluriinin Stella-teemaa
// - käyttää keskitettyä lokalisaatiojärjestelmää
// - tukee Firebase Password Reset -toimintoa
// - tukee kaikkia sovelluksen kieliä
// - sisältää kielivalinnan
// - käsittelee yleisimmät Firebase Auth -virheet
//
// ============================================================

class ForgotPasswordPage extends StatefulWidget {
  final String languageCode;

  final Future<void> Function(String)? changeLanguage;

  const ForgotPasswordPage({
    super.key,
    this.languageCode = 'fi',
    this.changeLanguage,
  });

  @override
  State<ForgotPasswordPage> createState() =>
      _ForgotPasswordPageState();
}

// ============================================================
// STATE
// ============================================================

class _ForgotPasswordPageState
    extends State<ForgotPasswordPage> {
  final TextEditingController emailController =
      TextEditingController();

  bool loading = false;

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
  // 🌍 LOCALIZATION
  // ==========================================================

  AppLocalizations get localization =>
      AppLocalizations(widget.languageCode);

  String _t(String key) {
    return localization.get(key);
  }

  // ==========================================================
  // DISPOSE
  // ==========================================================

  @override
  void dispose() {
    emailController.dispose();

    super.dispose();
  }

  // ==========================================================
  // 💬 MESSAGE
  // ==========================================================

  void _message(String text) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            text,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );
  }

  // ==========================================================
  // 🔐 RESET PASSWORD
  // ==========================================================

  Future<void> _resetPassword() async {
    final String email =
        emailController.text.trim();

    // --------------------------------------------------------
    // EMPTY EMAIL
    // --------------------------------------------------------

    if (email.isEmpty) {
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
          .sendPasswordResetEmail(
        email: email,
      );

      if (!mounted) {
        return;
      }

      _message(
        _t('passwordResetSent'),
      );
    } on FirebaseAuthException catch (error) {
      String message;

      switch (error.code) {
        case 'invalid-email':
          message = _t(
            'loginInvalidEmail',
          );
          break;

        case 'user-not-found':
          message = _t(
            'passwordResetUserNotFound',
          );
          break;

        case 'user-disabled':
          message = _t(
            'loginUserDisabled',
          );
          break;

        case 'too-many-requests':
          message = _t(
            'loginTooManyRequests',
          );
          break;

        case 'network-request-failed':
          message = _t(
            'loginNetworkError',
          );
          break;

        case 'operation-not-allowed':
          message = _t(
            'passwordResetNotAllowed',
          );
          break;

        default:
          message =
              '${_t('passwordResetFailed')}: '
              '${error.message ?? error.code}';
      }

      _message(message);
    } catch (_) {
      _message(
        _t('passwordResetFailed'),
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

  Future<void> _openLanguageDialog() async {
    if (widget.changeLanguage == null) {
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(
            '🐱 ${_t('language')}',
            style: const TextStyle(
              color: primaryTextColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: AppLocalizations
                  .supportedLanguages
                  .entries
                  .map(
                (entry) {
                  final bool selected =
                      widget.languageCode ==
                          entry.key;

                  return Padding(
                    padding:
                        const EdgeInsets.only(
                      bottom: 10,
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: loading
                            ? null
                            : () async {
                                await widget
                                    .changeLanguage!(
                                  entry.key,
                                );

                                if (dialogContext
                                    .mounted) {
                                  Navigator.pop(
                                    dialogContext,
                                  );
                                }
                              },
                        style:
                            ElevatedButton.styleFrom(
                          backgroundColor:
                              selected
                                  ? accentColor
                                  : const Color(
                                      0xFF35204F,
                                    ),
                          foregroundColor:
                              Colors.white,
                          padding:
                              const EdgeInsets
                                  .symmetric(
                            vertical: 14,
                          ),
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(
                              14,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                entry.value,
                                textAlign:
                                    TextAlign.center,
                                style: TextStyle(
                                  fontWeight:
                                      selected
                                          ? FontWeight
                                              .bold
                                          : FontWeight
                                              .normal,
                                ),
                              ),
                            ),
                            if (selected)
                              const Icon(
                                Icons
                                    .check_circle_rounded,
                                color: goldColor,
                                size: 20,
                              ),
                          ],
                        ),
                      ),
                    ),
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
      backgroundColor: backgroundColor,

      // ======================================================
      // APP BAR
      // ======================================================

      appBar: AppBar(
        backgroundColor: backgroundColor,
        foregroundColor: primaryTextColor,
        centerTitle: true,
        elevation: 0,
        title: Text(
          _t('forgotPassword'),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (widget.changeLanguage != null)
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

      // ======================================================
      // BODY
      // ======================================================

      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.all(24),
            child: Card(
              color: cardColor,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(24),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize:
                      MainAxisSize.min,
                  children: [
                    // ==================================================
                    // 🐱 STELLA
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
                        color:
                            primaryTextColor,
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
                        color: pinkColor,
                        fontSize: 16,
                        fontWeight:
                            FontWeight.w600,
                        letterSpacing: 4,
                      ),
                    ),

                    const SizedBox(
                      height: 18,
                    ),

                    // ==================================================
                    // TITLE
                    // ==================================================

                    Text(
                      _t('forgotPassword'),
                      textAlign:
                          TextAlign.center,
                      style: const TextStyle(
                        color:
                            primaryTextColor,
                        fontSize: 22,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(
                      height: 10,
                    ),

                    // ==================================================
                    // DESCRIPTION
                    // ==================================================

                    Text(
                      _t(
                        'passwordResetDescription',
                      ),
                      textAlign:
                          TextAlign.center,
                      style: const TextStyle(
                        color:
                            secondaryTextColor,
                        fontSize: 15,
                        height: 1.4,
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
                      enabled:
                          !loading,
                      keyboardType:
                          TextInputType.emailAddress,
                      textInputAction:
                          TextInputAction.done,
                      onSubmitted: (_) {
                        if (!loading) {
                          _resetPassword();
                        }
                      },
                      style:
                          const TextStyle(
                        color:
                            primaryTextColor,
                      ),
                      decoration:
                          InputDecoration(
                        labelText:
                            _t('email'),
                        prefixIcon:
                            const Icon(
                          Icons
                              .email_outlined,
                        ),
                        filled: true,
                        fillColor:
                            const Color(
                          0xFF18102D,
                        ),
                        border:
                            OutlineInputBorder(
                          borderRadius:
                              BorderRadius
                                  .circular(
                            16,
                          ),
                          borderSide:
                              BorderSide.none,
                        ),
                        enabledBorder:
                            OutlineInputBorder(
                          borderRadius:
                              BorderRadius
                                  .circular(
                            16,
                          ),
                          borderSide:
                              BorderSide(
                            color:
                                accentColor
                                    .withValues(
                              alpha: 0.25,
                            ),
                          ),
                        ),
                        focusedBorder:
                            OutlineInputBorder(
                          borderRadius:
                              BorderRadius
                                  .circular(
                            16,
                          ),
                          borderSide:
                              const BorderSide(
                            color:
                                accentColor,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 24,
                    ),

                    // ==================================================
                    // RESET BUTTON
                    // ==================================================

                    SizedBox(
                      width:
                          double.infinity,
                      height: 56,
                      child:
                          ElevatedButton.icon(
                        onPressed: loading
                            ? null
                            : _resetPassword,
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
                                Icons
                                    .mark_email_read_rounded,
                              ),
                        label: Text(
                          loading
                              ? _t(
                                  'sending',
                                )
                              : _t(
                                  'sendPasswordReset',
                                ),
                          style:
                              const TextStyle(
                            fontWeight:
                                FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    // ==================================================
                    // BACK TO LOGIN
                    // ==================================================

                    TextButton.icon(
                      onPressed:
                          loading
                              ? null
                              : () {
                                  Navigator.of(
                                    context,
                                  ).pop();
                                },
                      icon:
                          const Icon(
                        Icons
                            .arrow_back_rounded,
                      ),
                      label:
                          Text(
                        _t('login'),
                      ),
                    ),

                    const SizedBox(
                      height: 8,
                    ),

                    // ==================================================
                    // STELLA FOOTER
                    // ==================================================

                    const Text(
                      '🐱💜',
                      style: TextStyle(
                        fontSize: 24,
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