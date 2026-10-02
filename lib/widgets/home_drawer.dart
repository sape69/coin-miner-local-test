import 'package:flutter/material.dart';

import '../localization.dart';
import '../localization/achievements/achievements_localization.dart';
import 'cat_avatar.dart';

// ============================================================
// 🐱 STELLURIINI / STELLA HOME DRAWER
// ============================================================
//
// Sovelluksen päävalikko.
//
// Stella-teema:
// - violetti / pinkki / kulta
// - pehmeä tähtihehku
// - Stella-avatar
// - STELLA-merkintä
//
// Referral-osio:
// - näyttää kutsutut käyttäjät
// - näyttää aktiiviset / ei-aktiiviset kutsutut
// - avaa erillisen Referral-näkymän
//
// Account:
// - Delete Account
// - avaa tilin poistamisen vahvistuksen
//
// ============================================================

// ============================================================
// 🎨 STELLURIINI COLORS
// ============================================================

const Color backgroundColor = Color(0xFF120B24);

const Color cardColor = Color(0xFF21113B);

const Color accentColor = Color(0xFFB58CFF);

const Color pinkAccentColor = Color(0xFFFFB7E8);

const Color goldAccentColor = Color(0xFFFFD166);

const Color stellaGlowColor = Color(0xFFDCCBFF);

const Color inactiveColor = Color(0xFF8D879F);

const Color logoutColor = Color(0xFFFF8A8A);

const Color deleteAccountColor = Color(0xFFFF6B7A);

// ============================================================
// 🐱 HOME DRAWER
// ============================================================

class HomeDrawer extends StatelessWidget {
  final String languageCode;

  final VoidCallback onLanguagePressed;
  final VoidCallback onAboutPressed;
  final VoidCallback onWhitePaperPressed;
  final VoidCallback onRoadmapPressed;
  final VoidCallback onAchievementsPressed;
  final VoidCallback onTransactionHistoryPressed;
  final VoidCallback onReferralPressed;
  final VoidCallback onDeleteAccountPressed;
  final VoidCallback onLogoutPressed;

  const HomeDrawer({
    super.key,
    required this.languageCode,
    required this.onLanguagePressed,
    required this.onAboutPressed,
    required this.onWhitePaperPressed,
    required this.onRoadmapPressed,
    required this.onAchievementsPressed,
    required this.onTransactionHistoryPressed,
    required this.onReferralPressed,
    required this.onDeleteAccountPressed,
    required this.onLogoutPressed,
  });

  // ==========================================================
  // 🌍 MAIN LOCALIZATION
  // ==========================================================

  AppLocalizations get _localization => AppLocalizations(languageCode);

  String _t(String key) {
    return _localization.get(key);
  }

  // ==========================================================
  // 🏆 ACHIEVEMENTS LOCALIZATION
  // ==========================================================

  AchievementsLocalization get _achievementsLocalization =>
      AchievementsLocalization(
        languageCode,
      );

  // ==========================================================
  // ✨ STELLA STAR
  // ==========================================================

  Widget _stellaStar({
    double size = 16,
    Color? color,
  }) {
    return Icon(
      Icons.auto_awesome_rounded,
      color: color ?? goldAccentColor,
      size: size,
    );
  }

  // ==========================================================
  // 📋 MENU ITEM
  // ==========================================================

  Widget _menuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    String? badge,
    Color? iconColor,
  }) {
    final Color currentIconColor = iconColor ?? pinkAccentColor;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 4,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          splashColor: accentColor.withValues(alpha: 0.10),
          highlightColor: pinkAccentColor.withValues(alpha: 0.05),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 13,
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        accentColor.withValues(alpha: 0.28),
                        currentIconColor.withValues(alpha: 0.16),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(
                      color: currentIconColor.withValues(alpha: 0.20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: currentIconColor.withValues(alpha: 0.08),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    color: currentIconColor,
                    size: 23,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (badge != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: goldAccentColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: goldAccentColor.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Text(
                      badge,
                      style: const TextStyle(
                        color: goldAccentColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white.withValues(alpha: 0.30),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // 👥 REFERRAL ITEM
  // ==========================================================

  Widget _referralItem() {
    return _menuItem(
      icon: Icons.groups_rounded,
      title: _t('referrals'),
      onTap: onReferralPressed,
    );
  }

  // ==========================================================
  // 🗑️ DELETE ACCOUNT
  // ==========================================================

  Widget _deleteAccountItem() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 4,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          splashColor: deleteAccountColor.withValues(alpha: 0.12),
          highlightColor: deleteAccountColor.withValues(alpha: 0.05),
          onTap: onDeleteAccountPressed,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 13,
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: deleteAccountColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(
                      color: deleteAccountColor.withValues(alpha: 0.22),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: deleteAccountColor.withValues(alpha: 0.06),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.delete_forever_rounded,
                    color: deleteAccountColor,
                    size: 23,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    _t('deleteAccount'),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: deleteAccountColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right_rounded,
                  color: deleteAccountColor.withValues(alpha: 0.45),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // 🚪 LOGOUT
  // ==========================================================

  Widget _logoutItem() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 4,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          splashColor: logoutColor.withValues(alpha: 0.10),
          highlightColor: logoutColor.withValues(alpha: 0.05),
          onTap: onLogoutPressed,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 13,
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: logoutColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(
                      color: logoutColor.withValues(alpha: 0.20),
                    ),
                  ),
                  child: const Icon(
                    Icons.logout_rounded,
                    color: logoutColor,
                    size: 23,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    _t('logout'),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white30,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // 🐱 STELLA AVATAR
  // ==========================================================

  Widget _stellaAvatar() {
    return Container(
      width: 116,
      height: 116,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            pinkAccentColor,
            accentColor,
            goldAccentColor,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.28),
            blurRadius: 26,
            spreadRadius: 4,
          ),
          BoxShadow(
            color: pinkAccentColor.withValues(alpha: 0.14),
            blurRadius: 42,
            spreadRadius: 8,
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: const BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
        ),
        child: const CatAvatar(
          size: 95,
        ),
      ),
    );
  }

  // ==========================================================
  // ✨ STELLA HEADER
  // ==========================================================

  Widget _header() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 22,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF321A55),
            Color(0xFF21113D),
            Color(0xFF170D2C),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.45),
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.16),
            blurRadius: 28,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: pinkAccentColor.withValues(alpha: 0.07),
            blurRadius: 40,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Column(
        children: [
          // ------------------------------------------------------
          // ✨ TOP DECORATION
          // ------------------------------------------------------

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text(
                    '🐱',
                    style: TextStyle(fontSize: 25),
                  ),
                  const SizedBox(width: 5),
                  _stellaStar(
                    size: 13,
                    color: goldAccentColor.withValues(alpha: 0.85),
                  ),
                ],
              ),
              Text(
                '🐾 STL • SOLANA 🐾',
                style: TextStyle(
                  color: pinkAccentColor.withValues(alpha: 0.90),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              Row(
                children: [
                  _stellaStar(
                    size: 13,
                    color: goldAccentColor.withValues(alpha: 0.85),
                  ),
                  const SizedBox(width: 5),
                  const Text(
                    '🐱',
                    style: TextStyle(fontSize: 25),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ------------------------------------------------------
          // ✨ SMALL STELLA STAR
          // ------------------------------------------------------

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 34,
                height: 1,
                color: accentColor.withValues(alpha: 0.25),
              ),
              const SizedBox(width: 10),
              _stellaStar(
                size: 16,
                color: goldAccentColor,
              ),
              const SizedBox(width: 10),
              Container(
                width: 34,
                height: 1,
                color: accentColor.withValues(alpha: 0.25),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // ------------------------------------------------------
          // 🐱 STELLA AVATAR
          // ------------------------------------------------------

          _stellaAvatar(),

          const SizedBox(height: 14),

          // ------------------------------------------------------
          // 🌟 APP NAME
          // ------------------------------------------------------

          const Text(
            'STELLURIINI',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 3,
            ),
          ),

          const SizedBox(height: 7),

          // ------------------------------------------------------
          // 🐾 STELLA LABEL
          // ------------------------------------------------------

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '🐾',
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(width: 6),
              Text(
                'STELLA',
                style: TextStyle(
                  color: goldAccentColor.withValues(alpha: 0.95),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                '🐾',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),

          const SizedBox(height: 7),

          Text(
            _t('stellaCommunity'),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: pinkAccentColor.withValues(alpha: 0.85),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // 🐾 FOOTER
  // ==========================================================

  Widget _footer() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(
        16,
        4,
        16,
        16,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cardColor,
            cardColor.withValues(alpha: 0.82),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.20),
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.07),
            blurRadius: 18,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '🐾',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  _t('footerTagline'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.60),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 7),
              const Text(
                '🐾',
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 20,
                height: 1,
                color: accentColor.withValues(alpha: 0.25),
              ),
              const SizedBox(width: 8),
              _stellaStar(
                size: 12,
                color: goldAccentColor.withValues(alpha: 0.80),
              ),
              const SizedBox(width: 8),
              Container(
                width: 20,
                height: 1,
                color: accentColor.withValues(alpha: 0.25),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Text(
            _t('footerToken'),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: pinkAccentColor.withValues(alpha: 0.72),
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // 🏠 BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: backgroundColor,
      elevation: 18,
      shadowColor: accentColor.withValues(alpha: 0.35),
      surfaceTintColor: Colors.transparent,
      child: SafeArea(
        child: Column(
          children: [
            // ----------------------------------------------------
            // ✨ STELLA HEADER
            // ----------------------------------------------------

            _header(),

            // ----------------------------------------------------
            // 📋 MENU
            // ----------------------------------------------------

            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(
                  top: 4,
                  bottom: 8,
                ),
                children: [
                  _menuItem(
                    icon: Icons.language_rounded,
                    title: _t('language'),
                    onTap: onLanguagePressed,
                  ),

                  _menuItem(
                    icon: Icons.info_outline_rounded,
                    title: _t('aboutStelluriini'),
                    onTap: onAboutPressed,
                  ),

                  _menuItem(
                    icon: Icons.description_outlined,
                    title: _t('whitePaper'),
                    onTap: onWhitePaperPressed,
                  ),

                  _menuItem(
                    icon: Icons.map_outlined,
                    title: _t('roadmap'),
                    onTap: onRoadmapPressed,
                  ),

                  _referralItem(),

                  _menuItem(
                    icon: Icons.emoji_events_rounded,
                    title: _achievementsLocalization.get(
                      'achievementsTitle',
                    ),
                    onTap: onAchievementsPressed,
                    iconColor: goldAccentColor,
                  ),

                  _menuItem(
                    icon: Icons.history_rounded,
                    title: _t('transactionHistory'),
                    onTap: onTransactionHistoryPressed,
                  ),

                  // ------------------------------------------------
                  // 🗑️ DELETE ACCOUNT
                  // ------------------------------------------------

                  _deleteAccountItem(),

                  // ------------------------------------------------
                  // 🚪 LOGOUT
                  // ------------------------------------------------

                  _logoutItem(),
                ],
              ),
            ),

            // ----------------------------------------------------
            // 🐾 FOOTER
            // ----------------------------------------------------

            _footer(),
          ],
        ),
      ),
    );
  }
}