import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../localization.dart';
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
  final TextEditingController _emailController =
      TextEditingController();

  final TextEditingController _passwordController =
      TextEditingController();

  final FocusNode _emailFocusNode =
      FocusNode();

  final FocusNode _passwordFocusNode =
      FocusNode();

  bool _isLoading = false;
  bool _obscurePassword = true;

  static const Color backgroundColor =
      Color(0xFF120B24);

  static const Color surfaceColor =
      Color(0xFF1A0E31);

  static const Color cardColor =
      Color(0xFF21113B);

  static const Color fieldColor =
      Color(0xFF18102D);

  static const Color purple =
      Color(0xFFB58CFF);

  static const Color pink =
      Color(0xFFFFB7E8);

  static const Color gold =
      Color(0xFFFFD166);

  static const Color primaryText =
      Color(0xFFF8F4FF);

  static const Color secondaryText =
      Color(0xFFBDB4D1);

  static const Color borderColor =
      Color(0xFF352653);

  AppLocalizations get _l10n =>
      AppLocalizations(widget.languageCode);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();

    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();

    super.dispose();
  }

  // ============================================================
  // FIREBASE LOGIN
  // ============================================================

  Future<void> _login() async {
    FocusScope.of(context).unfocus();

    final String email =
        _emailController.text.trim();

    final String password =
        _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showMessage(
        _l10n.get('loginFillFields'),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseAuth.instance
          .signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      String message =
          _l10n.get('loginFailed');

      switch (e.code) {
        case 'user-not-found':
          message =
              _l10n.get('loginUserNotFound');
          break;

        case 'wrong-password':
        case 'invalid-credential':
          message =
              _l10n.get(
            'loginInvalidCredentials',
          );
          break;

        case 'invalid-email':
          message =
              _l10n.get(
            'loginInvalidEmail',
          );
          break;

        case 'user-disabled':
          message =
              _l10n.get(
            'loginUserDisabled',
          );
          break;

        case 'too-many-requests':
          message =
              _l10n.get(
            'loginTooManyRequests',
          );
          break;

        case 'network-request-failed':
          message =
              _l10n.get(
            'loginNetworkError',
          );
          break;
      }

      _showMessage(message);
    } catch (_) {
      _showMessage(
        _l10n.get('loginFailed'),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: primaryText,
          ),
        ),
        backgroundColor: cardColor,
        behavior:
            SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(16),
        ),
      ),
    );
  }

  // ============================================================
  // REGISTER
  // ============================================================

  Future<void> _openRegister() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RegisterPage(
          languageCode:
              widget.languageCode,
          changeLanguage:
              widget.changeLanguage,
        ),
      ),
    );
  }

  // ============================================================
  // FORGOT PASSWORD
  // ============================================================

  Future<void> _openForgotPassword() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            ForgotPasswordPage(
          languageCode:
              widget.languageCode,
          changeLanguage:
              widget.changeLanguage,
        ),
      ),
    );
  }

  // ============================================================
  // INPUT FIELD
  // ============================================================

  Widget _inputField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required String hint,
    required IconData icon,
    required TextInputAction textInputAction,
    TextInputType keyboardType =
        TextInputType.text,
    bool obscureText = false,
    Widget? suffix,
    VoidCallback? onSubmitted,
  }) {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: fieldColor,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: focusNode.hasFocus
              ? purple
              : borderColor,
          width: focusNode.hasFocus
              ? 2
              : 1.5,
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),

          Icon(
            icon,
            color: purple,
            size: 28,
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Stack(
              alignment:
                  Alignment.centerLeft,
              children: [
                if (controller.text.isEmpty)
                  IgnorePointer(
                    child: Text(
                      hint,
                      style:
                          const TextStyle(
                        color:
                            Color(0xFF766B89),
                        fontSize: 17,
                      ),
                    ),
                  ),

                EditableText(
                  controller:
                      controller,
                  focusNode:
                      focusNode,
                  style:
                      const TextStyle(
                    color:
                        primaryText,
                    fontSize: 17,
                  ),
                  cursorColor:
                      purple,
                  backgroundCursorColor:
                      Colors.transparent,
                  obscureText:
                      obscureText,
                  keyboardType:
                      keyboardType,
                  textInputAction:
                      textInputAction,
                  autocorrect: false,
                  enableSuggestions:
                      false,
                  maxLines: 1,
                  cursorWidth: 2,
                  onSubmitted: (_) {
                    if (onSubmitted !=
                        null) {
                      onSubmitted();
                    }
                  },
                ),
              ],
            ),
          ),

          if (suffix != null)
            suffix,

          const SizedBox(width: 8),
        ],
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          backgroundColor,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior:
              ScrollViewKeyboardDismissBehavior
                  .onDrag,
          padding:
              const EdgeInsets.fromLTRB(
            24,
            28,
            24,
            32,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints:
                  const BoxConstraints(
                maxWidth: 480,
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.stretch,
                children: [
                  // ==================================================
                  // STELLA LOGO
                  // ==================================================

                  Center(
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration:
                          BoxDecoration(
                        shape:
                            BoxShape.circle,
                        color:
                            surfaceColor,
                        border:
                            Border.all(
                          color: purple,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color:
                                purple.withValues(
                              alpha: 0.10,
                            ),
                            blurRadius: 24,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child:
                            Image.asset(
                          'assets/stella.jpg',
                          fit:
                              BoxFit.cover,
                          errorBuilder:
                              (
                            context,
                            error,
                            stackTrace,
                          ) {
                            return const Icon(
                              Icons.pets,
                              size: 70,
                              color: pink,
                            );
                          },
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 24,
                  ),

                  // ==================================================
                  // TITLE
                  // ==================================================

                  const Text(
                    'Stelluriini',
                    textAlign:
                        TextAlign.center,
                    style:
                        TextStyle(
                      color:
                          primaryText,
                      fontSize: 34,
                      fontWeight:
                          FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),

                  const SizedBox(
                    height: 8,
                  ),

                  const Text(
                    'STL',
                    textAlign:
                        TextAlign.center,
                    style:
                        TextStyle(
                      color: gold,
                      fontSize: 18,
                      fontWeight:
                          FontWeight.bold,
                      letterSpacing: 4,
                    ),
                  ),

                  const SizedBox(
                    height: 32,
                  ),

                  // ==================================================
                  // LOGIN CARD
                  // ==================================================

                  Container(
                    width:
                        double.infinity,
                    padding:
                        const EdgeInsets.fromLTRB(
                      36,
                      28,
                      36,
                      28,
                    ),
                    decoration:
                        BoxDecoration(
                      color: cardColor,
                      borderRadius:
                          BorderRadius.circular(
                        24,
                      ),
                      border:
                          Border.all(
                        color:
                            purple.withValues(
                          alpha: 0.30,
                        ),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .stretch,
                      children: [
                        // ==================================================
                        // LOGIN TITLE
                        // ==================================================

                        Text(
                          _l10n.get('login'),
                          textAlign:
                              TextAlign.center,
                          style:
                              const TextStyle(
                            color:
                                primaryText,
                            fontSize: 27,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),

                        const SizedBox(
                          height: 30,
                        ),

                        // ==================================================
                        // EMAIL
                        // ==================================================

                        _inputField(
                          controller:
                              _emailController,
                          focusNode:
                              _emailFocusNode,
                          label:
                              _l10n.get(
                            'email',
                          ),
                          hint:
                              _l10n.get(
                            'email',
                          ),
                          icon:
                              Icons
                                  .email_outlined,
                          keyboardType:
                              TextInputType
                                  .emailAddress,
                          textInputAction:
                              TextInputAction
                                  .next,
                        ),

                        const SizedBox(
                          height: 18,
                        ),

                        // ==================================================
                        // PASSWORD
                        // ==================================================

                        _inputField(
                          controller:
                              _passwordController,
                          focusNode:
                              _passwordFocusNode,
                          label:
                              _l10n.get(
                            'password',
                          ),
                          hint:
                              _l10n.get(
                            'password',
                          ),
                          icon:
                              Icons
                                  .lock_outline,
                          obscureText:
                              _obscurePassword,
                          textInputAction:
                              TextInputAction
                                  .done,
                          onSubmitted:
                              _login,
                          suffix:
                              IconButton(
                            onPressed:
                                () {
                              setState(() {
                                _obscurePassword =
                                    !_obscurePassword;
                              });
                            },
                            color: purple,
                            icon: Icon(
                              _obscurePassword
                                  ? Icons
                                      .visibility_outlined
                                  : Icons
                                      .visibility_off_outlined,
                            ),
                          ),
                        ),

                        const SizedBox(
                          height: 8,
                        ),

                        // ==================================================
                        // FORGOT PASSWORD
                        // ==================================================

                        Align(
                          alignment:
                              Alignment
                                  .centerRight,
                          child:
                              TextButton(
                            onPressed:
                                _isLoading
                                    ? null
                                    : _openForgotPassword,
                            style:
                                TextButton.styleFrom(
                              foregroundColor:
                                  pink,
                              padding:
                                  const EdgeInsets
                                      .symmetric(
                                horizontal: 4,
                                vertical: 6,
                              ),
                            ),
                            child:
                                Text(
                              _l10n.get(
                                'forgotPassword',
                              ),
                              style:
                                  const TextStyle(
                                fontSize:
                                    14,
                                fontWeight:
                                    FontWeight
                                        .w600,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(
                          height: 10,
                        ),

                        // ==================================================
                        // LOGIN BUTTON
                        // ==================================================

                        SizedBox(
                          width:
                              double.infinity,
                          height: 56,
                          child:
                              ElevatedButton(
                            onPressed:
                                _isLoading
                                    ? null
                                    : _login,
                            style:
                                ElevatedButton.styleFrom(
                              backgroundColor:
                                  purple,
                              foregroundColor:
                                  backgroundColor,
                              disabledBackgroundColor:
                                  const Color(
                                0xFF6E6380,
                              ),
                              disabledForegroundColor:
                                  const Color(
                                0xFFD8D0E2,
                              ),
                              elevation: 0,
                              shape:
                                  RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  18,
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
                                          valueColor:
                                              AlwaysStoppedAnimation<
                                                  Color>(
                                            backgroundColor,
                                          ),
                                        ),
                                      )
                                    : Text(
                                        _l10n.get(
                                          'login',
                                        ),
                                        style:
                                            const TextStyle(
                                          fontSize:
                                              16,
                                          fontWeight:
                                              FontWeight
                                                  .bold,
                                        ),
                                      ),
                          ),
                        ),

                        const SizedBox(
                          height: 22,
                        ),

                        // ==================================================
                        // CREATE ACCOUNT
                        // ==================================================

                        Text(
                          _l10n.get(
                            'createAccount',
                          ),
                          textAlign:
                              TextAlign.center,
                          style:
                              const TextStyle(
                            color:
                                secondaryText,
                            fontSize: 14,
                          ),
                        ),

                        const SizedBox(
                          height: 4,
                        ),

                        TextButton(
                          onPressed:
                              _isLoading
                                  ? null
                                  : _openRegister,
                          style:
                              TextButton.styleFrom(
                            foregroundColor:
                                gold,
                          ),
                          child:
                              Text(
                            _l10n.get(
                              'createAccount',
                            ),
                            textAlign:
                                TextAlign.center,
                            style:
                                const TextStyle(
                              fontWeight:
                                  FontWeight
                                      .bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(
                    height: 24,
                  ),

                  // ==================================================
                  // FOOTER
                  // ==================================================

                  const Text(
                    'STELLA • STELLURIINI • STL • SOLANA',
                    textAlign:
                        TextAlign.center,
                    style:
                        TextStyle(
                      color:
                          secondaryText,
                      fontSize: 11,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}