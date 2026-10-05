import 'package:flutter/material.dart';

import '../../localization.dart';

// ============================================================
// 🐱 STELLURIINI - ACCOUNT DELETION PAGE
// ============================================================
//
// Account deletion page.
//
// Account deletion is available only to authenticated users
// inside the Stelluriini application.
//
// The actual Firebase account deletion is handled by HomePage.
// This page only presents the account deletion action.
//
// ============================================================

class AccountDeletionPage extends StatelessWidget {
  // ============================================================
  // 🎨 STELLA THEME
  // ============================================================

  static const Color backgroundColor = Color(0xFF120B24);
  static const Color surfaceColor = Color(0xFF1A0E31);
  static const Color cardColor = Color(0xFF21113B);

  static const Color purpleAccentColor = Color(0xFFB58CFF);
  static const Color pinkAccentColor = Color(0xFFFFB7E8);
  static const Color goldAccentColor = Color(0xFFFFD166);

  static const Color primaryTextColor = Color(0xFFF8F4FF);
  static const Color secondaryTextColor = Color(0xFFBDB4D1);

  static const Color deleteAccountColor = Color(0xFFFF6B7A);

  // ============================================================
  // 🌐 LANGUAGE
  // ============================================================

  final String languageCode;

  // ============================================================
  // 🔧 CALLBACK
  // ============================================================

  final VoidCallback onDeleteAccountPressed;

  const AccountDeletionPage({
    super.key,
    required this.languageCode,
    required this.onDeleteAccountPressed,
  });

  // ============================================================
  // 🌐 LOCALIZATION
  // ============================================================

  AppLocalizations get _localization =>
      AppLocalizations(languageCode);

  String _t(String key) {
    return _localization.get(key);
  }

  // ============================================================
  // 🐱 STELLA ICON
  // ============================================================

  Widget _buildStellaHeader() {
    return Container(
      width: 86,
      height: 86,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: cardColor,
        border: Border.all(
          color: purpleAccentColor.withValues(
            alpha: 0.55,
          ),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: purpleAccentColor.withValues(
              alpha: 0.18,
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
    );
  }

  // ============================================================
  // 🗑️ DELETE CARD
  // ============================================================

  Widget _buildInAppDeleteCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: deleteAccountColor.withValues(
            alpha: 0.35,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: deleteAccountColor.withValues(
                    alpha: 0.12,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.delete_forever_rounded,
                  color: deleteAccountColor,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  _t('deleteYourAccount'),
                  style: const TextStyle(
                    color: primaryTextColor,
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _t('deleteAccountDescription'),
            style: const TextStyle(
              color: secondaryTextColor,
              fontSize: 14,
              height: 1.5,
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
              label: Text(
                _t('deleteAccountButton'),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: deleteAccountColor,
                foregroundColor: Colors.white,
                minimumSize: const Size(
                  double.infinity,
                  52,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ⚠️ INFORMATION CARD
  // ============================================================

  Widget _buildInformationCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: goldAccentColor.withValues(
            alpha: 0.20,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: goldAccentColor,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _t('accountDeletionPermanent'),
              style: const TextStyle(
                color: secondaryTextColor,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 🖥️ BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        foregroundColor: primaryTextColor,
        elevation: 0,
        title: Text(
          _t('accountDeletionAppTitle'),
          style: const TextStyle(
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
            children: [
              _buildStellaHeader(),
              const SizedBox(height: 18),
              Text(
                _t('accountDeletionTitle'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: primaryTextColor,
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _t('accountDeletionSubtitle'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: secondaryTextColor,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 28),
              _buildInAppDeleteCard(),
              const SizedBox(height: 18),
              _buildInformationCard(),
            ],
          ),
        ),
      ),
    );
  }
}