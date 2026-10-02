import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ============================================================
// 🐱 STELLURIINI - ACCOUNT DELETION PAGE
// ============================================================
//
// Account deletion hub.
//
// Sisältää kaksi poistotapaa:
//
// 1. 🗑️ Tilin poistaminen suoraan sovelluksessa
// 2. ✉️ Poistopyyntö sähköpostilla, jos sovellukseen ei pääse
//
// Varsinainen Firebase-tilin poisto tehdään HomePage-kutsun
// kautta. Tämä sivu ei itse käsittele Firebasea.
//
// ============================================================

class AccountDeletionPage extends StatelessWidget {
  const AccountDeletionPage({
    super.key,
    required this.onDeleteAccountPressed,
  });

  // ==========================================================
  // CALLBACK
  // ==========================================================

  final VoidCallback onDeleteAccountPressed;

  // ==========================================================
  // STELLA THEME
  // ==========================================================

  static const Color backgroundColor = Color(0xFF120B24);
  static const Color surfaceColor = Color(0xFF1A0E31);
  static const Color cardColor = Color(0xFF21113B);

  static const Color purpleColor = Color(0xFFB58CFF);
  static const Color pinkColor = Color(0xFFFFB7E8);
  static const Color goldColor = Color(0xFFFFD166);

  static const Color primaryTextColor = Color(0xFFF8F4FF);
  static const Color secondaryTextColor = Color(0xFFBDB4D1);

  static const Color deleteColor = Color(0xFFFF6B7A);
  static const Color successColor = Color(0xFF8FF0C8);

  static const String deletionEmail =
      'stelluriini.app@gmail.com';

  // ==========================================================
  // COPY EMAIL
  // ==========================================================

  Future<void> _copyEmail(BuildContext context) async {
    await Clipboard.setData(
      const ClipboardData(
        text: deletionEmail,
      ),
    );

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          '✉️ Email address copied.',
        ),
        duration: Duration(seconds: 2),
      ),
    );
  }

  // ==========================================================
  // DELETE ACCOUNT CARD
  // ==========================================================

  Widget _buildInAppDeletionCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: deleteColor.withValues(alpha: 0.30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: deleteColor.withValues(alpha: 0.12),
                ),
                child: const Icon(
                  Icons.delete_forever_rounded,
                  color: deleteColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Text(
                  'Delete your account',
                  style: TextStyle(
                    color: primaryTextColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          const Text(
            'If you can access the Stelluriini app, '
            'you can permanently delete your account '
            'and associated account data directly '
            'from the app.',
            style: TextStyle(
              color: secondaryTextColor,
              fontSize: 15,
              height: 1.6,
            ),
          ),

          const SizedBox(height: 18),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: deleteColor.withValues(alpha: 0.18),
              ),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: goldColor,
                  size: 22,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Account deletion is permanent '
                    'and cannot be undone.',
                    style: TextStyle(
                      color: secondaryTextColor,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onDeleteAccountPressed,
              icon: const Icon(
                Icons.delete_forever_rounded,
              ),
              label: const Text(
                'Delete Account',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: deleteColor,
                foregroundColor: backgroundColor,
                padding: const EdgeInsets.symmetric(
                  vertical: 15,
                  horizontal: 20,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // EXTERNAL REQUEST CARD
  // ==========================================================

  Widget _buildExternalRequestCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: purpleColor.withValues(alpha: 0.22),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: purpleColor.withValues(alpha: 0.12),
                ),
                child: const Icon(
                  Icons.mail_outline_rounded,
                  color: pinkColor,
                  size: 27,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Text(
                  'Cannot access the app?',
                  style: TextStyle(
                    color: primaryTextColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          const Text(
            'If you cannot access your Stelluriini '
            'account, you can request account deletion '
            'by contacting us by email.',
            style: TextStyle(
              color: secondaryTextColor,
              fontSize: 15,
              height: 1.6,
            ),
          ),

          const SizedBox(height: 18),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: purpleColor.withValues(alpha: 0.20),
              ),
            ),
            child: Column(
              children: [
                const Text(
                  'Account deletion requests',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: secondaryTextColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 8),

                const SelectableText(
                  deletionEmail,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: goldColor,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 12),

                TextButton.icon(
                  onPressed: () => _copyEmail(context),
                  icon: const Icon(
                    Icons.copy_rounded,
                    size: 18,
                  ),
                  label: const Text(
                    'Copy email address',
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: purpleColor,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          const Text(
            'Please include the email address associated '
            'with your Stelluriini account in your request.',
            style: TextStyle(
              color: secondaryTextColor,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,

      appBar: AppBar(
        backgroundColor: backgroundColor,
        foregroundColor: primaryTextColor,
        elevation: 0,

        title: const Text(
          'Account Deletion',
          style: TextStyle(
            color: primaryTextColor,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            20,
            12,
            20,
            32,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // =================================================
              // STELLA HEADER
              // =================================================

              Center(
                child: Container(
                  width: 82,
                  height: 82,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [
                        purpleColor,
                        pinkColor,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: purpleColor.withValues(
                          alpha: 0.30,
                        ),
                        blurRadius: 24,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      '🐱',
                      style: TextStyle(
                        fontSize: 42,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              const Center(
                child: Text(
                  'Stelluriini Account Deletion',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: primaryTextColor,
                    fontSize: 27,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              const Center(
                child: Text(
                  'Manage the deletion of your Stelluriini '
                  'account and associated account data.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: secondaryTextColor,
                    fontSize: 15,
                    height: 1.6,
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // =================================================
              // IN-APP DELETION
              // =================================================

              _buildInAppDeletionCard(context),

              const SizedBox(height: 20),

              // =================================================
              // EXTERNAL DELETION REQUEST
              // =================================================

              _buildExternalRequestCard(context),

              const SizedBox(height: 24),

              // =================================================
              // FINAL WARNING
              // =================================================

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: deleteColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: deleteColor.withValues(alpha: 0.25),
                  ),
                ),
                child: const Text(
                  'Important: Account deletion is permanent '
                  'and cannot be undone. When an account is '
                  'deleted, associated Stelluriini account '
                  'data is deleted according to the application '
                  'deletion process.',
                  style: TextStyle(
                    color: secondaryTextColor,
                    fontSize: 14,
                    height: 1.6,
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // =================================================
              // FOOTER
              // =================================================

              const Center(
                child: Column(
                  children: [
                    Text(
                      'Stelluriini',
                      style: TextStyle(
                        color: purpleColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Stella-powered virtual mining experience.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: secondaryTextColor,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}