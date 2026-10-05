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
// Referral-flow:
//
// 1. Käyttäjä kirjoittaa referral-koodin.
// 2. Flutter tarkistaa koodin backendiltä ENNEN tilin luomista.
// 3. Jos koodi on väärä:
//    -> tiliä EI luoda
//    -> käyttäjältä kysytään haluaako hän jatkaa ilman koodia.
// 4. Jos käyttäjä jatkaa ilman koodia:
//    -> referral-kenttä tyhjennetään
//    -> tili luodaan normaalisti.
// 5. Jos koodi on oikea:
//    -> Firebase Auth luo tilin
//    -> ensureUserProfile luo users/{uid}-profiilin
//    -> applyReferralCode yhdistää referralin.
//
// TÄRKEÄÄ:
//
// Flutter EI kirjoita users/{uid}-dokumenttia suoraan.
// Firestore Rules estävät client-side write-operaatiot.
//
// Profiili luodaan Cloud Functionin kautta:
//    ensureUserProfile
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
  // 🌍 CURRENT PAGE LANGUAGE
  // ==========================================================

  String currentLanguageCode = 'en';

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

  static const Color referralColor =
      Color(0xFFB58CFF);

  static const Color referralPinkColor =
      Color(0xFFFFB7E8);

  // ==========================================================
  // 🌍 LOCALIZATION
  // ==========================================================

  AppLocalizations get localization =>
      AppLocalizations(currentLanguageCode);

  String _t(String key) {
    return localization.get(key);
  }

  // ==========================================================
  // INIT STATE
  // ==========================================================

  @override
  void initState() {
    super.initState();

    currentLanguageCode = widget.languageCode;
  }

  // ==========================================================
  // WIDGET UPDATE
  // ==========================================================

  @override
  void didUpdateWidget(
    covariant RegisterPage oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.languageCode != widget.languageCode &&
        currentLanguageCode != widget.languageCode) {
      currentLanguageCode = widget.languageCode;
    }
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
  // 🔍 VALIDATE REFERRAL CODE
  // ==========================================================

  Future<bool?> _validateReferralCode(
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
        'validateReferralCode',
      );

      final HttpsCallableResult<dynamic> result =
          await callable.call(
        <String, dynamic>{
          'referralCode': code,
        },
      );

      final dynamic data = result.data;

      if (data is Map) {
        final dynamic success = data['success'];
        final dynamic valid = data['valid'];

        if (success == true && valid == true) {
          return true;
        }

        if (success == true && valid == false) {
          return false;
        }
      }

      debugPrint(
        'Referral validation returned '
        'unexpected response: $data',
      );

      return null;
    } on FirebaseFunctionsException catch (error) {
      debugPrint(
        'Referral validation error: '
        '${error.code} - ${error.message}',
      );

      switch (error.code) {
        case 'not-found':
          return false;

        case 'invalid-argument':
          return false;

        case 'unauthenticated':
          _message(
            _t('loginRequired'),
          );
          return null;

        case 'network-error':
        case 'unavailable':
          _message(
            _t('referralCodeNetworkError'),
          );
          return null;

        default:
          _message(
            _t('referralCodeValidationFailed'),
          );
          return null;
      }
    } catch (error) {
      debugPrint(
        'Referral validation unexpected error: $error',
      );

      _message(
        _t('referralCodeValidationFailed'),
      );

      return null;
    }
  }

  // ==========================================================
  // ❓ INVALID REFERRAL DIALOG
  // ==========================================================

  Future<bool> _askContinueWithoutReferral() async {
    if (!mounted) {
      return false;
    }

    final bool? continueWithoutReferral =
        await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: cardColor,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(24),
          ),
          title: Row(
            children: [
              const Icon(
                Icons.link_off_rounded,
                color: pinkColor,
                size: 28,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _t('referralCodeNotFoundTitle'),
                  style: const TextStyle(
                    color: primaryTextColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 19,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            _t('referralCodeNotFoundMessage'),
            style: const TextStyle(
              color: secondaryTextColor,
              fontSize: 15,
              height: 1.5,
            ),
          ),
          actionsPadding:
              const EdgeInsets.fromLTRB(
            20,
            0,
            20,
            20,
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.of(
                    dialogContext,
                  ).pop(false);
                },
                style:
                    OutlinedButton.styleFrom(
                  foregroundColor: pinkColor,
                  side: const BorderSide(
                    color: pinkColor,
                  ),
                  padding:
                      const EdgeInsets.symmetric(
                    vertical: 13,
                  ),
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  _t('changeReferralCode'),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(
                    dialogContext,
                  ).pop(true);
                },
                style:
                    ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(
                    vertical: 13,
                  ),
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  _t('continueWithoutReferral'),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    return continueWithoutReferral == true;
  }

  // ==========================================================
  // 🧩 ENSURE USER PROFILE
  // ==========================================================
  //
  // Firebase Auth -tili syntyy ensin.
  //
  // Firestore Security Rules estävät Flutteria kirjoittamasta
  // users/{uid}-dokumenttia suoraan.
  //
  // Siksi profiili luodaan palvelinpuolella:
  //
  // Firebase Auth
  //      ↓
  // ensureUserProfile
  //      ↓
  // users/{uid}
  //
  // Tämä metodi odottaa, että Cloud Function onnistuu.
  //
  // ==========================================================

  Future<bool> _ensureBackendProfileReady() async {
    const int maxAttempts = 5;

    const Duration retryDelay =
        Duration(milliseconds: 600);

    for (int attempt = 1;
        attempt <= maxAttempts;
        attempt++) {
      try {
        final User? user =
            FirebaseAuth.instance.currentUser;

        if (user == null) {
          debugPrint(
            'Backend profile attempt '
            '$attempt/$maxAttempts failed: '
            'no authenticated user.',
          );

          return false;
        }

        final FirebaseFunctions functions =
            FirebaseFunctions.instanceFor(
          region: 'us-central1',
        );

        final HttpsCallable callable =
            functions.httpsCallable(
          'ensureUserProfile',
        );

        final HttpsCallableResult<dynamic> result =
            await callable.call();

        final dynamic data = result.data;

        if (data is Map &&
            data['success'] == true) {
          debugPrint(
            'Backend profile ready on attempt '
            '$attempt/$maxAttempts for UID '
            '${user.uid}.',
          );

          return true;
        }

        debugPrint(
          'ensureUserProfile returned unexpected '
          'response on attempt '
          '$attempt/$maxAttempts: $data',
        );
      } on FirebaseFunctionsException catch (error) {
        debugPrint(
          'Backend profile attempt '
          '$attempt/$maxAttempts Functions error: '
          '${error.code} - ${error.message}',
        );
      } catch (error) {
        debugPrint(
          'Backend profile attempt '
          '$attempt/$maxAttempts unexpected error: '
          '$error',
        );
      }

      if (attempt < maxAttempts) {
        await Future<void>.delayed(
          retryDelay,
        );
      }
    }

    return false;
  }

  // ==========================================================
  // 🔗 APPLY REFERRAL CODE
  // ==========================================================
  //
  // Referralin liittäminen tehdään useamman kerran,
  // koska Firebase-yhteydessä voi esiintyä pieni
  // ajoitusero tai väliaikainen verkkovirhe.
  //
  Future<bool> _applyReferralCode(
    String referralCode,
  ) async {
    final String code =
        referralCode.trim().toUpperCase();

    if (code.isEmpty) {
      return true;
    }

    const int maxAttempts = 4;

    const Duration retryDelay =
        Duration(milliseconds: 700);

    String lastErrorMessage =
        _t('referralCodeApplyFailed');

    for (int attempt = 1;
        attempt <= maxAttempts;
        attempt++) {
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

        final dynamic data = result.data;

        if (data is Map) {
          final dynamic success = data['success'];
          final dynamic applied = data['applied'];

          if (success == true || applied == true) {
            debugPrint(
              'Referral applied successfully on '
              'attempt $attempt/$maxAttempts.',
            );

            return true;
          }
        }

        lastErrorMessage =
            _t('referralCodeApplyFailed');

        debugPrint(
          'Referral apply returned unexpected '
          'response on attempt '
          '$attempt/$maxAttempts: $data',
        );
      } on FirebaseFunctionsException catch (error) {
        debugPrint(
          'Referral apply attempt '
          '$attempt/$maxAttempts: '
          '${error.code} - ${error.message}',
        );

        // ----------------------------------------------
        // ALREADY EXISTS
        // ----------------------------------------------

        if (error.code == 'already-exists') {
          debugPrint(
            'Referral already exists. '
            'Treating as successful.',
          );

          return true;
        }

        // ----------------------------------------------
        // RETRYABLE ERRORS
        // ----------------------------------------------

        if (error.code == 'not-found' ||
            error.code == 'unavailable' ||
            error.code == 'network-error') {
          lastErrorMessage =
              _t('referralCodeNetworkError');

          if (attempt < maxAttempts) {
            await Future<void>.delayed(
              retryDelay,
            );

            continue;
          }

          break;
        }

        // ----------------------------------------------
        // NON-RETRYABLE ERRORS
        // ----------------------------------------------

        if (error.code == 'invalid-argument') {
          lastErrorMessage =
              _t('referralCodeInvalid');
        } else if (error.code == 'unauthenticated') {
          lastErrorMessage =
              _t('loginRequired');
        } else {
          lastErrorMessage =
              _t('referralCodeApplyFailed');
        }

        break;
      } catch (error) {
        debugPrint(
          'Referral apply attempt '
          '$attempt/$maxAttempts unexpected error: '
          '$error',
        );

        lastErrorMessage =
            _t('referralCodeApplyFailed');

        if (attempt < maxAttempts) {
          await Future<void>.delayed(
            retryDelay,
          );

          continue;
        }

        break;
      }
    }

    _message(lastErrorMessage);

    return false;
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

    String referralCode =
        referralController.text.trim();

    // --------------------------------------------------------
    // EMPTY FIELDS
    // --------------------------------------------------------

    if (username.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      _message(
        _t('registrationFillFields'),
      );

      return;
    }

    // --------------------------------------------------------
    // USERNAME
    // --------------------------------------------------------

    if (username.length < 3) {
      _message(
        _t('registrationFailed'),
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

    if (referralCode.length > 64) {
      _message(
        _t('referralCodeInvalid'),
      );

      return;
    }

    // --------------------------------------------------------
    // LOADING
    // --------------------------------------------------------

    setState(() {
      loading = true;
    });

    try {
      // ======================================================
      // 🔍 VALIDATE REFERRAL BEFORE ACCOUNT CREATION
      // ======================================================

      if (referralCode.isNotEmpty) {
        final bool? referralValid =
            await _validateReferralCode(
          referralCode,
        );

        if (referralValid == null) {
          if (mounted) {
            setState(() {
              loading = false;
            });
          }

          return;
        }

        if (referralValid == false) {
          if (mounted) {
            setState(() {
              loading = false;
            });
          }

          final bool continueWithoutReferral =
              await _askContinueWithoutReferral();

          if (!continueWithoutReferral) {
            return;
          }

          referralController.clear();
          referralCode = '';
        }

        if (!mounted) {
          return;
        }

        setState(() {
          loading = true;
        });
      }

      // ======================================================
      // 🔐 CREATE FIREBASE ACCOUNT
      // ======================================================

      final UserCredential credential =
          await FirebaseAuth.instance
              .createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // ======================================================
      // 👤 SAVE USERNAME
      // ======================================================

      final User? user = credential.user;

      if (user != null) {
        await user.updateDisplayName(
          username,
        );

        await user.reload();
      }

      // ======================================================
      // 🧩 CREATE USER PROFILE
      // ======================================================
      //
      // TÄRKEÄ:
      //
      // UserService.createUserIfNeeded()
      // EI enää käytetä.
      //
      // Firestore Rules estävät client-side write-operaation.
      //
      // Profiili luodaan Cloud Functionilla:
      //
      // ensureUserProfile
      //
      // ======================================================

      final bool profileReady =
          await _ensureBackendProfileReady();

      if (!profileReady) {
        // ----------------------------------------------------
        // PROFILE CREATION FAILED
        // ----------------------------------------------------

        final User? createdUser =
            FirebaseAuth.instance.currentUser;

        if (createdUser != null) {
          try {
            await createdUser.delete();
          } catch (deleteError) {
            debugPrint(
              'Profile rollback delete error: '
              '$deleteError',
            );
          }
        }

        await FirebaseAuth.instance.signOut();

        if (!mounted) {
          return;
        }

        _message(
          _t('registrationFailed'),
        );

        return;
      }

      // ======================================================
      // 🔗 APPLY VERIFIED REFERRAL
      // ======================================================

      if (referralCode.isNotEmpty) {
        final bool referralApplied =
            await _applyReferralCode(
          referralCode,
        );

        if (!referralApplied) {
          // --------------------------------------------------
          // REFERRAL ROLLBACK
          // --------------------------------------------------

          final User? createdUser =
              FirebaseAuth.instance.currentUser;

          if (createdUser != null) {
            try {
              await createdUser.delete();
            } catch (deleteError) {
              debugPrint(
                'Referral rollback delete error: '
                '$deleteError',
              );
            }
          }

          await FirebaseAuth.instance.signOut();

          if (!mounted) {
            return;
          }

          _message(
            _t('referralCodeApplyFailed'),
          );

          return;
        }
      }

      // ======================================================
      // 🎉 SUCCESS
      // ======================================================

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
          message = _t(
            'registrationFailed',
          );
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
                      currentLanguageCode ==
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

                                if (!mounted) {
                                  return;
                                }

                                setState(() {
                                  currentLanguageCode =
                                      entry.key;
                                });

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
                        label: _t('username'),
                        icon:
                            Icons.person_outline_rounded,
                      ).copyWith(
                        hintText:
                            _t('usernameHint'),
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
                                    Text(
                                      _t('referralCode'),
                                      style:
                                          const TextStyle(
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
                                      _t(
                                        'referralCodeOptional',
                                      ),
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
                                  _t('referralCode'),
                              icon:
                                  Icons
                                      .confirmation_number_outlined,
                              accent:
                                  referralColor,
                            ).copyWith(
                              hintText:
                                  _t(
                                'enterReferralCode',
                              ),
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
                                  _t(
                                    'referralCodeHint',
                                  ),
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