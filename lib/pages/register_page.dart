import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../localization.dart';
import '../widgets/cat_avatar.dart';

// ============================================================
// 🐱 STELLURIINI REGISTER PAGE
// ============================================================
//
// Firebase Email/Password -tilin luonti.
//
// Ominaisuudet:
// - Stella-teema
// - keskitetty localization
// - käyttäjänimi
// - sähköposti
// - salasana
// - salasanan vahvistus
// - vapaaehtoinen Referral Code
// - Firebase Auth
// - Firebase Functions / Referral
// - kielenvaihto
// - Firebase-virheiden käsittely
//
// Referral toimii näin:
//
// 1. Käyttäjä kirjoittaa Referral Coden.
// 2. Firebase Auth luo käyttäjätilin.
// 3. Backendille lähetetään referral-koodi.
// 4. applyReferralCode tarkistaa koodin serverillä.
// 5. Jos koodi on voimassa, referral-suhde luodaan.
// 6. Jos koodia ei anneta, rekisteröinti toimii normaalisti.
//
// Referral-bonuslaskenta tapahtuu edelleen backendissä.
//
// ============================================================

class RegisterPage extends StatefulWidget {
  final String languageCode;

  final Future<void> Function(String)? changeLanguage;

  const RegisterPage({
    super.key,
    this.languageCode = 'en',
    this.changeLanguage,
  });

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // ==========================================================
  // CONTROLLERS
  // ==========================================================

  final TextEditingController usernameController =
      TextEditingController();

  final TextEditingController emailController =
      TextEditingController();

  final TextEditingController passwordController =
      TextEditingController();

  final TextEditingController confirmController =
      TextEditingController();

  final TextEditingController referralController =
      TextEditingController();

  // ==========================================================
  // STATE
  // ==========================================================

  bool loading = false;
  bool showPassword = false;
  bool showConfirmPassword = false;

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

  static const Color inputColor =
      Color(0xFF18102D);

  // Referral käyttää Stella-teeman värejä.
  static const Color referralColor =
      Color(0xFFB58CFF);

  static const Color referralPinkColor =
      Color(0xFFFFB7E8);

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
    usernameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmController.dispose();
    referralController.dispose();

    super.dispose();
  }

  // ==========================================================
  // 💬 MESSAGE
  // ==========================================================

  void _message(
    String text, {
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
            padding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 16,
            ),
            decoration: BoxDecoration(
              color: isError
                  ? const Color(0xFF32162F)
                  : const Color(0xFF171022),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isError
                    ? const Color(0xFFFF8FB8)
                    : goldColor,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: isError
                      ? const Color(0x99FF8FB8)
                      : const Color(0x99FFD166),
                  blurRadius: 24,
                  spreadRadius: 2,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                // ==================================================
                // ICON
                // ==================================================

                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: isError
                        ? const Color(0x44FF8FB8)
                        : const Color(0x44FFD166),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isError
                          ? const Color(0xAAFF8FB8)
                          : const Color(0xAAFFD166),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    isError
                        ? Icons.error_outline_rounded
                        : Icons.check_circle_rounded,
                    color: isError
                        ? const Color(0xFFFFB0C9)
                        : goldColor,
                    size: 28,
                  ),
                ),

                const SizedBox(width: 14),

                // ==================================================
                // TEXT
                // ==================================================

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Stelluriini',
                        style: TextStyle(
                          color: isError
                              ? const Color(0xFFFFB0C9)
                              : goldColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        text,
                        style: const TextStyle(
                          color: primaryTextColor,
                          fontSize: 14,
                          height: 1.4,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // ==================================================
                // CLOSE
                // ==================================================

                IconButton(
                  visualDensity:
                      VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  icon: const Icon(
                    Icons.close_rounded,
                    color: secondaryTextColor,
                    size: 20,
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
  // 🔗 APPLY REFERRAL CODE
  // ==========================================================
  //
  // Referral-koodi lähetetään AINA backendille.
  //
  // Client ei päätä:
  // - onko koodi olemassa
  // - kuka kutsuja on
  // - onko referral sallittu
  // - referral-bonusmäärää
  //
  // Backend:
  //
  // applyReferralCode
  //
  // ==========================================================

  Future<bool> _applyReferralCode(
    String referralCode,
  ) async {
    final String code =
        referralCode.trim().toUpperCase();

    if (code.isEmpty) {
      return true;
    }

    try {
      final FirebaseFunctions functions =
          FirebaseFunctions.instanceFor(
        region: 'us-central1',
      );

      final HttpsCallable callable =
          functions.httpsCallable(
        'applyReferralCode',
      );

      final HttpsCallableResult<dynamic> result =
          await callable.call(
        <String, dynamic>{
          'referralCode': code,
        },
      );

      final dynamic data =
          result.data;

      if (data is Map) {
        final dynamic success =
            data['success'];

        final dynamic applied =
            data['applied'];

        if (success == true ||
            applied == true) {
          return true;
        }
      }

      return false;
    } on FirebaseFunctionsException catch (error) {
      debugPrint(
        'Referral apply error: '
        '${error.code} - ${error.message}',
      );

      String message;

      switch (error.code) {
        case 'not-found':
          message =
              'Referral code was not found.';
          break;

        case 'already-exists':
          message =
              'A referral code is already connected to this account.';
          break;

        case 'invalid-argument':
          message =
              error.message ??
                  'The referral code is not valid.';
          break;

        case 'unauthenticated':
          message =
              'Please sign in again and try again.';
          break;

        case 'network-error':
        case 'unavailable':
          message =
              'Network error. Please try again.';
          break;

        default:
          message =
              error.message ??
                  'The referral code could not be applied.';
      }

      _message(message);

      return false;
    } catch (error) {
      debugPrint(
        'Referral apply unexpected error: $error',
      );

      _message(
        'The referral code could not be applied.',
      );

      return false;
    }
  }

  // ==========================================================
  // 🔐 REGISTER
  // ==========================================================

  Future<void> _register() async {
    if (loading) {
      return;
    }

    final String username =
        usernameController.text.trim();

    final String email =
        emailController.text.trim();

    final String password =
        passwordController.text;

    final String confirmPassword =
        confirmController.text;

    final String referralCode =
        referralController.text.trim();

    // --------------------------------------------------------
    // EMPTY FIELDS
    // --------------------------------------------------------

    if (username.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      _message(
        _t('loginFillFields'),
      );
      return;
    }

    // --------------------------------------------------------
    // USERNAME
    // --------------------------------------------------------

    if (username.length < 3) {
      _message(
        'Username must contain at least 3 characters.',
      );
      return;
    }

    // --------------------------------------------------------
    // EMAIL
    // --------------------------------------------------------

    if (!_isValidEmail(email)) {
      _message(
        _t('loginInvalidEmail'),
      );
      return;
    }

    // --------------------------------------------------------
    // PASSWORD MATCH
    // --------------------------------------------------------

    if (password != confirmPassword) {
      _message(
        _t('passwordsDoNotMatch'),
      );
      return;
    }

    // --------------------------------------------------------
    // PASSWORD LENGTH
    // --------------------------------------------------------

    if (password.length < 6) {
      _message(
        _t('passwordTooShort'),
      );
      return;
    }

    // --------------------------------------------------------
    // REFERRAL CODE FORMAT
    // --------------------------------------------------------
    //
    // Tyhjä = sallittu.
    //
    // Backend tekee varsinaisen tarkistuksen.
    //
    // Tässä tehdään vain turvallinen pituusraja,
    // jotta erittäin pitkää syötettä ei lähetetä.
    //
    // --------------------------------------------------------

    if (referralCode.length > 64) {
      _message(
        'Referral code is too long.',
      );
      return;
    }

    setState(() {
      loading = true;
    });

    try {
      // ------------------------------------------------------
      // CREATE FIREBASE ACCOUNT
      // ------------------------------------------------------

      final UserCredential credential =
          await FirebaseAuth.instance
              .createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // ------------------------------------------------------
      // SAVE USERNAME
      // ------------------------------------------------------

      final User? user =
          credential.user;

      if (user != null) {
        await user.updateDisplayName(
          username,
        );

        await user.reload();
      }

      // ------------------------------------------------------
      // APPLY REFERRAL
      // ------------------------------------------------------
      //
      // Tili on jo luotu tässä vaiheessa.
      //
      // Jos referral-koodi on annettu, backend käsittelee sen.
      //
      // ------------------------------------------------------

      if (referralCode.isNotEmpty) {
        final bool referralApplied =
            await _applyReferralCode(
          referralCode,
        );

        if (!referralApplied) {
          // --------------------------------------------------
          // TÄRKEÄ:
          //
          // Tiliä EI poisteta referral-virheen vuoksi.
          //
          // Käyttäjä voi jatkaa sovellukseen ja referral
          // voidaan käsitellä myöhemmin erillisellä tavalla,
          // jos sellainen flow lisätään.
          // --------------------------------------------------

          if (!mounted) {
            return;
          }

          await Future<void>.delayed(
            const Duration(
              milliseconds: 500,
            ),
          );

          if (!mounted) {
            return;
          }

          Navigator.of(context).pop();

          return;
        }
      }

      // ------------------------------------------------------
      // SUCCESS
      // ------------------------------------------------------

      if (!mounted) {
        return;
      }

      _message(
        _t('accountCreated'),
        isError: false,
      );

      await Future<void>.delayed(
        const Duration(
          milliseconds: 700,
        ),
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop();
    } on FirebaseAuthException catch (error) {
      debugPrint(
        'Firebase registration error: '
        '${error.code} - ${error.message}',
      );

      String message;

      switch (error.code) {
        case 'invalid-email':
          message = _t(
            'loginInvalidEmail',
          );
          break;

        case 'email-already-in-use':
          message = _t(
            'emailAlreadyInUse',
          );
          break;

        case 'weak-password':
          message = _t(
            'passwordTooWeak',
          );
          break;

        case 'operation-not-allowed':
          message = _t(
            'registrationNotAllowed',
          );
          break;

        case 'network-request-failed':
          message = _t(
            'loginNetworkError',
          );
          break;

        case 'too-many-requests':
          message = _t(
            'loginTooManyRequests',
          );
          break;

        default:
          message =
              '${_t('registrationFailed')}: '
              '${error.message ?? error.code}';
      }

      _message(message);
    } catch (error) {
      debugPrint(
        'Registration error: $error',
      );

      _message(
        _t('registrationFailed'),
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
  // 📧 EMAIL VALIDATION
  // ==========================================================

  bool _isValidEmail(String email) {
    final RegExp emailRegex = RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    );

    return emailRegex.hasMatch(email);
  }

  // ==========================================================
  // 🌍 LANGUAGE
  // ==========================================================

  Future<void> _openLanguageDialog() async {
    final Future<void> Function(String)? changeLanguage =
        widget.changeLanguage;

    if (changeLanguage == null || loading) {
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
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
                (
                  MapEntry<String, String> entry,
                ) {
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
                                await changeLanguage(
                                  entry.key,
                                );

                                if (dialogContext
                                    .mounted) {
                                  Navigator.of(
                                    dialogContext,
                                  ).pop();
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
                                          ? FontWeight.bold
                                          : FontWeight.normal,
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
  // 🧱 INPUT DECORATION
  // ==========================================================

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    Widget? suffixIcon,
    Color? accent,
  }) {
    final Color borderColor =
        accent ?? accentColor;

    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(
        icon,
        color: secondaryTextColor,
      ),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: inputColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: borderColor.withValues(
            alpha: 0.25,
          ),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: borderColor,
          width: 1.5,
        ),
      ),
      labelStyle: const TextStyle(
        color: secondaryTextColor,
      ),
      floatingLabelStyle: TextStyle(
        color: borderColor,
        fontWeight: FontWeight.w600,
      ),
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
          _t('createAccount'),
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
            padding: const EdgeInsets.all(24),
            child: Card(
              color: cardColor,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(24),
              ),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ==================================================
                    // 🐱 STELLA
                    // ==================================================

                    const CatAvatar(
                      size: 110,
                    ),

                    const SizedBox(height: 18),

                    const Text(
                      'STELLURIINI',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: primaryTextColor,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),

                    const SizedBox(height: 6),

                    const Text(
                      'STL',
                      style: TextStyle(
                        color: pinkColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 4,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      _t('createAccount'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: secondaryTextColor,
                        fontSize: 15,
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ==================================================
                    // 👤 USERNAME
                    // ==================================================

                    TextField(
                      controller:
                          usernameController,
                      enabled: !loading,
                      keyboardType:
                          TextInputType.text,
                      textInputAction:
                          TextInputAction.next,
                      textCapitalization:
                          TextCapitalization.words,
                      maxLength: 30,
                      style: const TextStyle(
                        color: primaryTextColor,
                      ),
                      decoration:
                          _inputDecoration(
                        label: 'Username',
                        icon:
                            Icons.person_outline_rounded,
                      ).copyWith(
                        hintText:
                            'For example Stella',
                        counterText: '',
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ==================================================
                    // 📧 EMAIL
                    // ==================================================

                    TextField(
                      controller:
                          emailController,
                      enabled: !loading,
                      keyboardType:
                          TextInputType.emailAddress,
                      textInputAction:
                          TextInputAction.next,
                      style: const TextStyle(
                        color: primaryTextColor,
                      ),
                      decoration:
                          _inputDecoration(
                        label: _t('email'),
                        icon:
                            Icons.email_outlined,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ==================================================
                    // 🔐 PASSWORD
                    // ==================================================

                    TextField(
                      controller:
                          passwordController,
                      enabled: !loading,
                      obscureText:
                          !showPassword,
                      textInputAction:
                          TextInputAction.next,
                      style: const TextStyle(
                        color: primaryTextColor,
                      ),
                      decoration:
                          _inputDecoration(
                        label: _t('password'),
                        icon:
                            Icons.lock_outline,
                        suffixIcon:
                            IconButton(
                          icon: Icon(
                            showPassword
                                ? Icons.visibility
                                : Icons
                                    .visibility_off,
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

                    const SizedBox(height: 16),

                    // ==================================================
                    // 🔐 CONFIRM PASSWORD
                    // ==================================================

                    TextField(
                      controller:
                          confirmController,
                      enabled: !loading,
                      obscureText:
                          !showConfirmPassword,
                      textInputAction:
                          TextInputAction.next,
                      style: const TextStyle(
                        color: primaryTextColor,
                      ),
                      decoration:
                          _inputDecoration(
                        label:
                            _t('confirmPassword'),
                        icon:
                            Icons.lock_reset_rounded,
                        suffixIcon:
                            IconButton(
                          icon: Icon(
                            showConfirmPassword
                                ? Icons.visibility
                                : Icons
                                    .visibility_off,
                          ),
                          onPressed: loading
                              ? null
                              : () {
                                  setState(() {
                                    showConfirmPassword =
                                        !showConfirmPassword;
                                  });
                                },
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // ==================================================
                    // 🔗 REFERRAL CODE
                    // ==================================================
                    //
                    // Vapaaehtoinen.
                    //
                    // Stella-teema:
                    // - purple/pink
                    // - link-icon
                    // - selkeä mutta ei liian hallitseva
                    //
                    // ==================================================

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color:
                            referralColor.withValues(
                          alpha: 0.055,
                        ),
                        borderRadius:
                            BorderRadius.circular(18),
                        border: Border.all(
                          color:
                              referralColor.withValues(
                            alpha: 0.18,
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration:
                                    BoxDecoration(
                                  gradient:
                                      LinearGradient(
                                    begin:
                                        Alignment.topLeft,
                                    end:
                                        Alignment.bottomRight,
                                    colors: [
                                      referralColor
                                          .withValues(
                                        alpha: 0.24,
                                      ),
                                      referralPinkColor
                                          .withValues(
                                        alpha: 0.16,
                                      ),
                                    ],
                                  ),
                                  borderRadius:
                                      BorderRadius
                                          .circular(
                                    11,
                                  ),
                                ),
                                child: const Icon(
                                  Icons
                                      .link_rounded,
                                  color:
                                      referralColor,
                                  size: 21,
                                ),
                              ),
                              const SizedBox(
                                width: 11,
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment
                                          .start,
                                  children: [
                                    const Text(
                                      'Referral Code',
                                      style:
                                          TextStyle(
                                        color:
                                            primaryTextColor,
                                        fontSize: 15,
                                        fontWeight:
                                            FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(
                                      height: 2,
                                    ),
                                    Text(
                                      'Optional',
                                      style:
                                          TextStyle(
                                        color:
                                            secondaryTextColor
                                                .withValues(
                                          alpha: 0.85,
                                        ),
                                        fontSize: 11,
                                        fontWeight:
                                            FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(
                            height: 12,
                          ),

                          TextField(
                            controller:
                                referralController,
                            enabled: !loading,
                            keyboardType:
                                TextInputType.text,
                            textInputAction:
                                TextInputAction.done,
                            textCapitalization:
                                TextCapitalization
                                    .characters,
                            autocorrect: false,
                            enableSuggestions: false,
                            maxLength: 64,
                            style:
                                const TextStyle(
                              color:
                                  primaryTextColor,
                              fontWeight:
                                  FontWeight.w700,
                              letterSpacing: 1.2,
                            ),
                            decoration:
                                _inputDecoration(
                              label:
                                  'Referral Code',
                              icon:
                                  Icons
                                      .confirmation_number_outlined,
                              accent:
                                  referralColor,
                            ).copyWith(
                              hintText:
                                  'Enter referral code',
                              counterText: '',
                            ),
                          ),

                          const SizedBox(
                            height: 5,
                          ),

                          Row(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                            children: [
                              Icon(
                                Icons
                                    .info_outline_rounded,
                                color:
                                    referralPinkColor
                                        .withValues(
                                  alpha: 0.75,
                                ),
                                size: 16,
                              ),
                              const SizedBox(
                                width: 7,
                              ),
                              Expanded(
                                child: Text(
                                  'If someone invited you to '
                                  'Stelluriini, enter their code here.',
                                  style:
                                      TextStyle(
                                    color:
                                        secondaryTextColor
                                            .withValues(
                                      alpha: 0.85,
                                    ),
                                    fontSize: 11,
                                    height: 1.35,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ==================================================
                    // CREATE ACCOUNT
                    // ==================================================

                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child:
                          ElevatedButton.icon(
                        onPressed:
                            loading
                                ? null
                                : _register,
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
                                    .person_add_alt_1_rounded,
                              ),
                        label: Text(
                          loading
                              ? _t(
                                  'creatingAccount',
                                )
                              : _t(
                                  'createAccount',
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

                    const SizedBox(height: 12),

                    // ==================================================
                    // BACK TO LOGIN
                    // ==================================================

                    TextButton.icon(
                      onPressed: loading
                          ? null
                          : () {
                              Navigator.of(
                                context,
                              ).pop();
                            },
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                      ),
                      label: Text(
                        _t('login'),
                      ),
                    ),

                    const SizedBox(height: 8),

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