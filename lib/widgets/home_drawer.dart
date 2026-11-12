
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../localization.dart';
import '../localization/achievements/achievements_localization.dart';
import '../pages/admin/admin_dashboard_page.dart';
import 'cat_avatar.dart';

// ============================================================
// 🐱 STELLURIINI / STELLA HOME DRAWER
// ============================================================

const Color backgroundColor = Color(0xFF120B24);
const Color cardColor = Color(0xFF21113B);
const Color accentColor = Color(0xFFB58CFF);
const Color pinkAccentColor = Color(0xFFFFB7E8);
const Color goldAccentColor = Color(0xFFFFD166);
const Color logoutColor = Color(0xFFFF8A8A);
const Color deleteAccountColor = Color(0xFFFF6B7A);

// ============================================================
// 🐱 HOME DRAWER
// ============================================================

class HomeDrawer extends StatefulWidget {
  final String languageCode;

  final VoidCallback onLanguagePressed;
  final VoidCallback onAboutPressed;
  final VoidCallback onWhitePaperPressed;
  final VoidCallback onRoadmapPressed;

  final VoidCallback? onHalvingPressed;
  final VoidCallback? onPremiumPressed;

  final VoidCallback? onStellaWorldPressed;
  final VoidCallback onAchievementsPressed;
  final VoidCallback onTransactionHistoryPressed;
  final VoidCallback onReferralPressed;
  final VoidCallback onAccountDeletionPressed;
  final VoidCallback onLogoutPressed;

  const HomeDrawer({
    super.key,
    required this.languageCode,
    required this.onLanguagePressed,
    required this.onAboutPressed,
    required this.onWhitePaperPressed,
    required this.onRoadmapPressed,
    this.onHalvingPressed,
    this.onPremiumPressed,
    this.onStellaWorldPressed,
    required this.onAchievementsPressed,
    required this.onTransactionHistoryPressed,
    required this.onReferralPressed,
    required this.onAccountDeletionPressed,
    required this.onLogoutPressed,
  });

  @override
  State<HomeDrawer> createState() => _HomeDrawerState();
}

// ============================================================
// 🐱 HOME DRAWER STATE
// ============================================================

class _HomeDrawerState extends State<HomeDrawer> {
  bool _adminAccess = false;
  bool _checkingAdmin = true;

  AppLocalizations get _localization =>
      AppLocalizations(widget.languageCode);

  String _t(String key) {
    return _localization.get(key);
  }

  AchievementsLocalization get _achievementsLocalization =>
      AchievementsLocalization(widget.languageCode);

  @override
  void initState() {
    super.initState();
    _checkAdminAccess();
  }

  // ==========================================================
  // 🔐 ADMIN CLAIM CHECK
  // ==========================================================

  Future<void> _checkAdminAccess() async {
    try {
      final User? user =
          FirebaseAuth.instance.currentUser;

      if (user == null) {
        if (mounted) {
          setState(() {
            _adminAccess = false;
            _checkingAdmin = false;
          });
        }
        return;
      }

      // Haetaan tuore ID-token, jotta uusi admin-claim
      // tulee varmasti näkyviin.
      final IdTokenResult tokenResult =
          await user.getIdTokenResult(true);

      final bool isAdmin =
          tokenResult.claims?['admin'] == true;

      if (!mounted) return;

      setState(() {
        _adminAccess = isAdmin;
        _checkingAdmin = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _adminAccess = false;
        _checkingAdmin = false;
      });
    }
  }

  // ==========================================================
  // 🛡️ OPEN ADMIN DASHBOARD
  // ==========================================================

  Future<void> _openAdminDashboard() async {
    // Tarkistetaan claim vielä ennen sivun avaamista.
    try {
      final User? user =
          FirebaseAuth.instance.currentUser;

      if (user == null) return;

      final IdTokenResult tokenResult =
          await user.getIdTokenResult(true);

      if (tokenResult.claims?['admin'] != true) {
        if (!mounted) return;

        setState(() {
          _adminAccess = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.languageCode.toLowerCase().startsWith('fi')
                  ? 'Ylläpitäjän oikeutta ei löytynyt.'
                  : 'Administrator access was not found.',
            ),
            backgroundColor: cardColor,
          ),
        );

        return;
      }

      if (!mounted) return;

      Navigator.of(context).pop();

      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => AdminDashboardPage(
            languageCode: widget.languageCode,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.languageCode.toLowerCase().startsWith('fi')
                ? 'Hallintasivun avaaminen epäonnistui.'
                : 'Could not open the admin dashboard.',
          ),
          backgroundColor: cardColor,
        ),
      );
    }
  }

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
  // 📋 COMPACT MENU ITEM
  // ==========================================================

  Widget _menuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    final Color currentIconColor =
        iconColor ?? pinkAccentColor;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 2,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          splashColor: accentColor.withValues(alpha: 0.10),
          highlightColor: pinkAccentColor.withValues(alpha: 0.05),
          onTap: onTap,
          child: Container(
            height: 58,
            padding: const EdgeInsets.symmetric(horizontal: 12),
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
                        accentColor.withValues(alpha: 0.25),
                        currentIconColor.withValues(alpha: 0.14),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(
                      color: currentIconColor.withValues(alpha: 0.20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: currentIconColor.withValues(alpha: 0.07),
                        blurRadius: 9,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    color: currentIconColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white.withValues(alpha: 0.28),
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // 🛡️ ADMIN MENU ITEM
  // ==========================================================

  Widget _adminMenuItem() {
    final bool isFinnish =
        widget.languageCode.toLowerCase().startsWith('fi');

    return _menuItem(
      icon: Icons.admin_panel_settings_rounded,
      title: isFinnish
          ? 'Stelluriini Hallinta'
          : 'Stelluriini Admin',
      onTap: _openAdminDashboard,
      iconColor: goldAccentColor,
    );
  }

  // ==========================================================
  // 📉 HALVING MENU ITEM
  // ==========================================================

  Widget _halvingItem() {
    final bool isFinnish =
        widget.languageCode.toLowerCase() == 'fi';

    return _menuItem(
      icon: Icons.show_chart_rounded,
      title: isFinnish
          ? 'Puoliintuminen ja louhintanopeus'
          : 'Halving & Mining Rate',
      onTap: widget.onHalvingPressed!,
      iconColor: goldAccentColor,
    );
  }

  // ==========================================================
  // ⭐ PREMIUM MENU ITEM
  // ==========================================================

  Widget _premiumItem() {
    final bool isFinnish =
        widget.languageCode.toLowerCase() == 'fi';

    return _menuItem(
      icon: Icons.workspace_premium_rounded,
      title: isFinnish
          ? 'Stelluriini Premium'
          : 'Stelluriini Premium',
      onTap: widget.onPremiumPressed!,
      iconColor: goldAccentColor,
    );
  }

  // ==========================================================
  // 👥 REFERRAL
  // ==========================================================

  Widget _referralItem() {
    return _menuItem(
      icon: Icons.groups_rounded,
      title: _t('referrals'),
      onTap: widget.onReferralPressed,
    );
  }

  // ==========================================================
  // 🗑️ ACCOUNT DELETION
  // ==========================================================

  Widget _accountDeletionItem() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 2,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          splashColor: deleteAccountColor.withValues(alpha: 0.10),
          highlightColor: deleteAccountColor.withValues(alpha: 0.05),
          onTap: widget.onAccountDeletionPressed,
          child: Container(
            height: 58,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: deleteAccountColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(
                      color: deleteAccountColor.withValues(alpha: 0.20),
                    ),
                  ),
                  child: const Icon(
                    Icons.delete_forever_rounded,
                    color: deleteAccountColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Text(
                    _t('deleteAccount'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: deleteAccountColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: deleteAccountColor.withValues(alpha: 0.40),
                  size: 24,
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
        horizontal: 10,
        vertical: 2,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          splashColor: logoutColor.withValues(alpha: 0.10),
          highlightColor: logoutColor.withValues(alpha: 0.05),
          onTap: widget.onLogoutPressed,
          child: Container(
            height: 58,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: logoutColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(
                      color: logoutColor.withValues(alpha: 0.18),
                    ),
                  ),
                  child: const Icon(
                    Icons.logout_rounded,
                    color: logoutColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Text(
                    _t('logout'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white.withValues(alpha: 0.28),
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // 🐱 COMPACT STELLA AVATAR
  // ==========================================================

  Widget _stellaAvatar() {
    return Container(
      width: 76,
      height: 76,
      padding: const EdgeInsets.all(3),
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
            color: accentColor.withValues(alpha: 0.24),
            blurRadius: 18,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: const BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
        ),
        child: const CatAvatar(size: 66),
      ),
    );
  }

  // ==========================================================
  // ✨ COMPACT HEADER
  // ==========================================================

  Widget _header() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(10, 10, 10, 8),
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
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
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.38),
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.12),
            blurRadius: 20,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              _stellaAvatar(),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          '🐱',
                          style: TextStyle(fontSize: 17),
                        ),
                        const SizedBox(width: 5),
                        _stellaStar(
                          size: 11,
                          color: goldAccentColor,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'STELLA',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: goldAccentColor.withValues(alpha: 0.95),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'STELLURIINI',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _t('stellaCommunity'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: pinkAccentColor.withValues(alpha: 0.82),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 25,
                height: 1,
                color: accentColor.withValues(alpha: 0.22),
              ),
              const SizedBox(width: 8),
              _stellaStar(
                size: 12,
                color: goldAccentColor.withValues(alpha: 0.80),
              ),
              const SizedBox(width: 7),
              Text(
                '🐾 STL • SOLANA 🐾',
                style: TextStyle(
                  color: pinkAccentColor.withValues(alpha: 0.82),
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(width: 7),
              _stellaStar(
                size: 12,
                color: goldAccentColor.withValues(alpha: 0.80),
              ),
              const SizedBox(width: 8),
              Container(
                width: 25,
                height: 1,
                color: accentColor.withValues(alpha: 0.22),
              ),
            ],
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
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 10),
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF21113B),
            Color(0xFF1A0E31),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🐾', style: TextStyle(fontSize: 13)),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  _t('footerTagline'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.58),
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              const Text('🐾', style: TextStyle(fontSize: 13)),
            ],
          ),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 18,
                height: 1,
                color: accentColor.withValues(alpha: 0.20),
              ),
              const SizedBox(width: 6),
              _stellaStar(
                size: 10,
                color: goldAccentColor.withValues(alpha: 0.75),
              ),
              const SizedBox(width: 6),
              Container(
                width: 18,
                height: 1,
                color: accentColor.withValues(alpha: 0.20),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            _t('footerToken'),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: pinkAccentColor.withValues(alpha: 0.68),
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
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
            _header(),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(
                  top: 2,
                  bottom: 4,
                ),
                children: [
                  // LANGUAGE
                  _menuItem(
                    icon: Icons.language_rounded,
                    title: _t('language'),
                    onTap: widget.onLanguagePressed,
                  ),

                  // ABOUT
                  _menuItem(
                    icon: Icons.info_outline_rounded,
                    title: _t('aboutStelluriini'),
                    onTap: widget.onAboutPressed,
                  ),

                  // WHITE PAPER
                  _menuItem(
                    icon: Icons.description_outlined,
                    title: _t('whitePaper'),
                    onTap: widget.onWhitePaperPressed,
                  ),

                  // ROADMAP
                  _menuItem(
                    icon: Icons.map_outlined,
                    title: _t('roadmap'),
                    onTap: widget.onRoadmapPressed,
                  ),

                  // HALVING
                  if (widget.onHalvingPressed != null)
                    _halvingItem(),

                  // PREMIUM
                  if (widget.onPremiumPressed != null)
                    _premiumItem(),

                  // ADMIN
                  if (!_checkingAdmin && _adminAccess)
                    _adminMenuItem(),

                  // STELLA WORLD
                  if (widget.onStellaWorldPressed != null)
                    _menuItem(
                      icon: Icons.auto_awesome_rounded,
                      title: widget.languageCode
                              .toLowerCase()
                              .startsWith('fi')
                          ? 'Stella-maailma'
                          : 'Stella World',
                      onTap: widget.onStellaWorldPressed!,
                      iconColor: accentColor,
                    ),

                  // REFERRALS
                  _referralItem(),

                  // ACHIEVEMENTS
                  _menuItem(
                    icon: Icons.emoji_events_rounded,
                    title: _achievementsLocalization.get(
                      'achievementsTitle',
                    ),
                    onTap: widget.onAchievementsPressed,
                    iconColor: goldAccentColor,
                  ),

                  // TRANSACTION HISTORY
                  _menuItem(
                    icon: Icons.history_rounded,
                    title: _t('transactionHistory'),
                    onTap: widget.onTransactionHistoryPressed,
                  ),

                  // ACCOUNT DELETION
                  _accountDeletionItem(),

                  // LOGOUT
                  _logoutItem(),
                ],
              ),
            ),

            _footer(),
          ],
        ),
      ),
    );
  }
}
