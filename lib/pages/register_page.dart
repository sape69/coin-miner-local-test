import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
// - Referral-koodi
// - Firebase Auth
// - Referral Cloud Function
// - kielenvaihto
// - Firebase-virheiden käsittely
//
// Referral:
// - käyttäjä voi syöttää olemassa olevan referral-koodin
// - koodi on valinnainen
// - koodi normalisoidaan isoiksi kirjaimiksi
// - backend vahvistaa koodin
//
// Ensimmäisen asennuksen oletuskieli on englanti.
// LoginPage välittää nykyisen kielivalinnan tänne.
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
  // 👥 REFERRAL CODE
  // ==========================================================
  //
  // Referral-koodit ovat nykyisen järjestelmän mukaisesti
  // 8-merkkisiä ja tallennetaan uppercase-muodossa.
  //
  // Esimerkiksi:
  //
  // jj6hdnv4
  //
  // muuttuu:
  //
  // JJ6HDNV4
  //
  // ==========================================================

  String _normalizedReferralCode() {
    return referralController.text
        .trim()
        .toUpperCase()
        .replaceAll(RegExp(r'\s+'), '');
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
        _normalizedReferralCode();

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
    // REFERRAL FORMAT
    // --------------------------------------------------------
    //
    // Referral on valinnainen.
    //
    // Jos käyttäjä antaa koodin, sen täytyy olla täsmälleen
    // 8 merkkiä ja sisältää vain A-Z / 0-9.
    //
    // Backend tarkistaa lopullisesti, onko koodi olemassa.
    // --------------------------------------------------------

    if (referralCode.isNotEmpty) {
      final bool validReferralFormat =
          RegExp(r'^[A-Z0-9]{8}$')
              .hasMatch(referralCode);

      if (!validReferralFormat) {
        _message(
          'Referral code must contain exactly 8 letters or numbers.',
        );
        return;
      }
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

      final User? user = credential.user;

      if (user == null) {
        throw FirebaseAuthException(
          code: 'registration-failed',
          message: 'Firebase user was not created.',
        );
      }

      await user.updateDisplayName(username);
      await user.reload();

      // ------------------------------------------------------
      // 👥 APPLY REFERRAL
      // ------------------------------------------------------
      //
      // Referral käsitellään backendissä.
      //
      // Backend:
      // - tarkistaa referralCodes/{CODE}
      // - tarkistaa referrerin
      // - estää self-referralin
      // - lukitsee referrer-suhteen
      // - tallentaa referral-suhteen
      //
      // Callable:
      // applyReferralCode
      //
      // Referral on täysin vapaaehtoinen.
      // Ilman koodia tätä kutsua ei tehdä.
      // ------------------------------------------------------

      if (referralCode.isNotEmpty) {
        try {
          final HttpsCallable applyReferralCode =
              FirebaseFunctions.instanceFor(
            region: 'us-central1',
          ).httpsCallable(
            'applyReferralCode',
          );

          await applyReferralCode.call(
            <String, dynamic>{
              'referralCode': referralCode,
            },
          );

          debugPrint(
            'Referral applied successfully: '
            '$referralCode',
          );
        } on FirebaseFunctionsException catch (error) {
          debugPrint(
            'Referral error: '
            '${error.code} - ${error.message}',
          );

          // --------------------------------------------------
          // TILI ON JO LUOTU.
          //
          // Referral-ongelma ei poisteta juuri luotua tiliä.
          // Näin vältetään tilin ja referral-datan
          // epäjohdonmukainen rollback.
          // --------------------------------------------------

          String referralMessage =
              'Account created, but the referral code '
              'could not be applied.';

          switch (error.code) {
            case 'invalid-argument':
              referralMessage =
                  'The referral code is invalid.';
              break;

            case 'not-found':
              referralMessage =
                  'The referral code was not found.';
              break;

            case 'already-exists':
              referralMessage =
                  'This referral has already been applied.';
              break;

            case 'failed-precondition':
              referralMessage =
                  'This referral code cannot be used.';
              break;

            case 'permission-denied':
              referralMessage =
                  'The referral code could not be applied.';
              break;

            case 'unauthenticated':
              referralMessage =
                  'Your account was created, but the '
                  'referral could not be connected.';
              break;

            case 'internal':
              referralMessage =
                  'Your account was created, but the '
                  'referral service is temporarily unavailable.';
              break;
          }

          _message(
            referralMessage,
          );

          await Future<void>.delayed(
            const Duration(milliseconds: 1200),
          );

          if (!mounted) {
            return;
          }

          Navigator.of(context).pop();
          return;
        } catch (error) {
          debugPrint(
            'Unexpected referral error: $error',
          );

          _message(
            'Account created, but the referral '
            'could not be applied.',
          );

          await Future<void>.delayed(
            const Duration(milliseconds: 1200),
          );

          if (!mounted) {
            return;
          }

          Navigator.of(context).pop();
          return;
        }
      }

      // ------------------------------------------------------
      // REGISTRATION SUCCESS
      // ------------------------------------------------------

      if (!mounted) {
        return;
      }

      _message(
        _t('accountCreated'),
        isError: false,
      );

      await Future<void>.delayed(
        const Duration(milliseconds: 700),
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
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: inputColor,
      labelStyle: const TextStyle(
        color: secondaryTextColor,
      ),
      hintStyle: TextStyle(
        color: secondaryTextColor.withValues(
          alpha: 0.65,
        ),
      ),
      prefixIconColor: accentColor,
      suffixIconColor: secondaryTextColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: accentColor.withValues(
            alpha: 0.25,
          ),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: accentColor,
          width: 1.5,
        ),
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
                        icon: Icons
                            .person_outline_rounded,
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
                        label: _t(
                          'confirmPassword',
                        ),
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

                    const SizedBox(height: 16),

                    // ==================================================
                    // 👥 REFERRAL CODE
                    // ==================================================
                    //
                    // Käyttäjän kutsukoodi.
                    //
                    // Valinnainen:
                    // käyttäjä voi jättää kentän tyhjäksi.
                    //
                    // ==================================================

                    Container(
                      decoration: BoxDecoration(
                        borderRadius:
                            BorderRadius.circular(18),
                        gradient:
                            LinearGradient(
                          begin:
                              Alignment.topLeft,
                          end:
                              Alignment.bottomRight,
                          colors: [
                            accentColor.withValues(
                              alpha: 0.08,
                            ),
                            pinkColor.withValues(
                              alpha: 0.035,
                            ),
                          ],
                        ),
                        border: Border.all(
                          color:
                              accentColor.withValues(
                            alpha: 0.16,
                          ),
                        ),
                      ),
                      padding:
                          const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          // --------------------------------------------
                          // HEADER
                          // --------------------------------------------

                          Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration:
                                    BoxDecoration(
                                  gradient:
                                      LinearGradient(
                                    begin:
                                        Alignment.topLeft,
                                    end:
                                        Alignment.bottomRight,
                                    colors: [
                                      accentColor
                                          .withValues(
                                        alpha: 0.24,
                                      ),
                                      pinkColor
                                          .withValues(
                                        alpha: 0.16,
                                      ),
                                    ],
                                  ),
                                  borderRadius:
                                      BorderRadius
                                          .circular(
                                    13,
                                  ),
                                ),
                                child: const Icon(
                                  Icons
                                      .groups_rounded,
                                  color:
                                      pinkColor,
                                  size: 22,
                                ),
                              ),

                              const SizedBox(
                                width: 12,
                              ),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment
                                          .start,
                                  children: [
                                    const Text(
                                      'Referral code',
                                      style:
                                          TextStyle(
                                        color:
                                            primaryTextColor,
                                        fontSize: 15,
                                        fontWeight:
                                            FontWeight
                                                .w700,
                                      ),
                                    ),
                                    const SizedBox(
                                      height: 2,
                                    ),
                                    Text(
                                      'Optional • invite a Stella friend',
                                      style:
                                          TextStyle(
                                        color:
                                            secondaryTextColor
                                                .withValues(
                                          alpha: 0.78,
                                        ),
                                        fontSize: 11,
                                        fontWeight:
                                            FontWeight
                                                .w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const Text(
                                '🐾',
                                style:
                                    TextStyle(
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(
                            height: 12,
                          ),

                          // --------------------------------------------
                          // CODE INPUT
                          // --------------------------------------------

                          TextField(
                            controller:
                                referralController,
                            enabled: !loading,
                            keyboardType:
                                TextInputType
                                    .text,
                            textInputAction:
                                TextInputAction
                                    .done,
                            textCapitalization:
                                TextCapitalization
                                    .characters,
                            autocorrect: false,
                            enableSuggestions: false,
                            maxLength: 8,
                            inputFormatters: [
                              FilteringTextInputFormatter
                                  .allow(
                                RegExp(
                                  r'[A-Za-z0-9]',
                                ),
                              ),
                              LengthLimitingTextInputFormatter(
                                8,
                              ),
                            ],
                            style:
                                const TextStyle(
                              color:
                                  primaryTextColor,
                              fontSize: 17,
                              fontWeight:
                                  FontWeight.bold,
                              letterSpacing: 2.5,
                            ),
                            decoration:
                                _inputDecoration(
                              label:
                                  'Referral code',
                              icon: Icons
                                  .card_giftcard_rounded,
                            ).copyWith(
                              hintText:
                                  'Example JJ6HDNV4',
                              counterText: '',
                            ),
                            onChanged:
                                (String value) {
                              final String normalized =
                                  value
                                      .toUpperCase();

                              if (value !=
                                  normalized) {
                                referralController
                                    .value =
                                    referralController
                                        .value
                                        .copyWith(
                                  text:
                                      normalized,
                                  selection:
                                      TextSelection
                                          .collapsed(
                                    offset:
                                        normalized
                                            .length,
                                  ),
                                );
                              }
                            },
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