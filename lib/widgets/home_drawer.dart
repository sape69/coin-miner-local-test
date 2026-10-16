import 'package:flutter/material.dart';

import '../localization.dart';
import '../localization/achievements/achievements_localization.dart';
import '../pages/achievements/achievements_service.dart';
import '../services/stella_level_service.dart';
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
// - Account Deletion
// - avaa erillisen tilin poistamisen näkymän
//
// Stella Level:
// - perustuu saavutettujen saavutusten määrään
// - ei vaikuta louhintaan
// - ei vaikuta STL-määrään
// - ei vaikuta hash rateen
// - ei vaikuta Power Boostiin
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

class HomeDrawer extends StatefulWidget {
  final String languageCode;

  final VoidCallback onLanguagePressed;
  final VoidCallback onAboutPressed;
  final VoidCallback onWhitePaperPressed;
  final VoidCallback onRoadmapPressed;
  final VoidCallback onAchievementsPressed;
  final VoidCallback onTransactionHistoryPressed;
  final VoidCallback onReferralPressed;

  // ----------------------------------------------------------
  // 🗑️ ACCOUNT DELETION
  //
  // Tämä callback avaa AccountDeletionPage.
  //
  // Varsinainen tilin poistaminen tapahtuu vasta
  // AccountDeletionPage -> HomePage -> Firebase Function.
  // ----------------------------------------------------------

  final VoidCallback onAccountDeletionPressed;

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
  final AchievementsService _achievementsService =
      AchievementsService();

  int _completedAchievements = 0;

  bool _loadingStellaLevel = true;

  // ==========================================================
  // 🚀 INIT
  // ==========================================================

  @override
  void initState() {
    super.initState();

    _loadStellaLevel();
  }

  // ==========================================================
  // 🏆 LOAD ACHIEVEMENT COUNT
  // ==========================================================

  Future<void> _loadStellaLevel() async {
    try {
      final int completed =
          await _achievementsService.getCompletedCount();

      if (!mounted) {
        return;
      }

      setState(() {
        _completedAchievements = completed;
        _loadingStellaLevel = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _completedAchievements = 0;
        _loadingStellaLevel = false;
      });
    }
  }

  // ==========================================================
  // 🌟 STELLA LEVEL
  // ==========================================================

  StellaLevelInfo get _stellaLevel {
    return StellaLevelService.calculate(
      _completedAchievements,
    );
  }

  // ==========================================================
  // 🌍 MAIN LOCALIZATION
  // ==========================================================

  AppLocalizations get _localization =>
      AppLocalizations(widget.languageCode);

  String _t(String key) {
    return _localization.get(key);
  }

  // ==========================================================
  // ⭐ STELLA LEVEL NAME LOCALIZATION
  // ==========================================================

  String _stellaLevelName(StellaLevelInfo level) {
    switch (level.level) {
      case 6:
        return _t('stellaLevelLegend');

      case 5:
        return _t('stellaLevelMaster');

      case 4:
        return _t('stellaLevelPower');

      case 3:
        return _t('stellaLevelMining');

      case 2:
        return _t('stellaLevelCurious');

      default:
        return _t('stellaLevelLittle');
    }
  }

  // ==========================================================
  // 🏆 STELLA LEVEL PROGRESS TEXT
  // ==========================================================

  String _stellaLevelProgressText(
    StellaLevelInfo level,
  ) {
    if (level.isMaxLevel) {
      return _t('stellaMaxLevel');
    }

    return _t(
      'stellaAchievementsToNextLevel',
    ).replaceAll(
      '{count}',
      level.achievementsToNextLevel.toString(),
    );
  }

  // ==========================================================
  // 🏆 ACHIEVEMENTS LOCALIZATION
  // ==========================================================

  AchievementsLocalization get _achievementsLocalization =>
      AchievementsLocalization(
        widget.languageCode,
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
    final Color currentIconColor =
        iconColor ?? pinkAccentColor;

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
          splashColor:
              accentColor.withValues(alpha: 0.10),
          highlightColor:
              pinkAccentColor.withValues(alpha: 0.05),
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
                      color: currentIconColor.withValues(
                        alpha: 0.20,
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: currentIconColor.withValues(
                          alpha: 0.08,
                        ),
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
                      color:
                          goldAccentColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color:
                            goldAccentColor.withValues(alpha: 0.15),
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
                  color:
                      Colors.white.withValues(alpha: 0.30),
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
      onTap: widget.onReferralPressed,
    );
  }

  // ==========================================================
  // ⭐ STELLA LEVEL CARD
  // ==========================================================

  Widget _stellaLevelCard() {
    final StellaLevelInfo level = _stellaLevel;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF321A55),
              Color(0xFF24133F),
              Color(0xFF1A0E31),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: accentColor.withValues(alpha: 0.38),
          ),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: 0.12),
              blurRadius: 18,
              spreadRadius: 1,
            ),
            BoxShadow(
              color: pinkAccentColor.withValues(alpha: 0.06),
              blurRadius: 24,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          children: [
            // --------------------------------------------------
            // TITLE
            // --------------------------------------------------

            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        goldAccentColor,
                        pinkAccentColor,
                        accentColor,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(13),
                    boxShadow: [
                      BoxShadow(
                        color:
                            goldAccentColor.withValues(alpha: 0.18),
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      _loadingStellaLevel
                          ? '🐱'
                          : level.icon,
                      style: const TextStyle(
                        fontSize: 22,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            _t('stellaLevel'),
                            style: TextStyle(
                              color: goldAccentColor
                                  .withValues(alpha: 0.95),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(width: 6),
                          _stellaStar(
                            size: 12,
                            color: goldAccentColor,
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _loadingStellaLevel
                            ? _t('stellaLevelLoading')
                            : _stellaLevelName(level),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!_loadingStellaLevel)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color:
                          accentColor.withValues(alpha: 0.16),
                      borderRadius:
                          BorderRadius.circular(20),
                      border: Border.all(
                        color:
                            accentColor.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Text(
                      'LV ${level.level}',
                      style: const TextStyle(
                        color: accentColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 14),

            // --------------------------------------------------
            // DIVIDER
            // --------------------------------------------------

            Container(
              height: 1,
              color: accentColor.withValues(alpha: 0.12),
            ),

            const SizedBox(height: 13),

            // --------------------------------------------------
            // ACHIEVEMENT PROGRESS
            // --------------------------------------------------

            if (_loadingStellaLevel)
              Row(
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: accentColor.withValues(
                        alpha: 0.70,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _t('stellaLoading'),
                    style: TextStyle(
                      color:
                          Colors.white.withValues(alpha: 0.60),
                      fontSize: 12,
                    ),
                  ),
                ],
              )
            else ...[
              Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.emoji_events_rounded,
                        color: goldAccentColor.withValues(
                          alpha: 0.90,
                        ),
                        size: 17,
                      ),
                      const SizedBox(width: 7),
                      Text(
                        _t('stellaAchievements'),
                        style: TextStyle(
                          color:
                              Colors.white.withValues(alpha: 0.72),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${level.completedAchievements}',
                    style: const TextStyle(
                      color: goldAccentColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 9),

              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: level.progress,
                  minHeight: 7,
                  backgroundColor:
                      Colors.white.withValues(alpha: 0.08),
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(
                    accentColor,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      _stellaLevelProgressText(level),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color:
                            pinkAccentColor.withValues(alpha: 0.72),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (!level.isMaxLevel) ...[
                    const SizedBox(width: 8),
                    Text(
                      '${level.currentLevelRequirement} / ${level.nextLevelRequirement}',
                      style: TextStyle(
                        color:
                            Colors.white.withValues(alpha: 0.42),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // 🗑️ ACCOUNT DELETION ITEM
  // ==========================================================
  //
  // Tämä EI enää käynnistä poistamista suoraan.
  //
  // Se avaa AccountDeletionPage-sivun, jossa käyttäjä voi:
  //
  // 1. Poistaa tilin suoraan sovelluksesta
  // 2. Pyytää poistoa sähköpostilla, jos sovellukseen ei pääse
  //
  // ==========================================================

  Widget _accountDeletionItem() {
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
          splashColor:
              deleteAccountColor.withValues(alpha: 0.12),
          highlightColor:
              deleteAccountColor.withValues(alpha: 0.05),
          onTap: widget.onAccountDeletionPressed,
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
                    color:
                        deleteAccountColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(
                      color:
                          deleteAccountColor.withValues(alpha: 0.22),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color:
                            deleteAccountColor.withValues(alpha: 0.06),
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
                  color:
                      deleteAccountColor.withValues(alpha: 0.45),
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
          splashColor:
              logoutColor.withValues(alpha: 0.10),
          highlightColor:
              logoutColor.withValues(alpha: 0.05),
          onTap: widget.onLogoutPressed,
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
                    color:
                        logoutColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(
                      color:
                          logoutColor.withValues(alpha: 0.20),
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
            color:
                accentColor.withValues(alpha: 0.28),
            blurRadius: 26,
            spreadRadius: 4,
          ),
          BoxShadow(
            color:
                pinkAccentColor.withValues(alpha: 0.14),
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
          color:
              accentColor.withValues(alpha: 0.45),
        ),
        boxShadow: [
          BoxShadow(
            color:
                accentColor.withValues(alpha: 0.16),
            blurRadius: 28,
            spreadRadius: 2,
          ),
          BoxShadow(
            color:
                pinkAccentColor.withValues(alpha: 0.07),
            blurRadius: 40,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
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
                    color:
                        goldAccentColor.withValues(alpha: 0.85),
                  ),
                ],
              ),
              Text(
                '🐾 STL • SOLANA 🐾',
                style: TextStyle(
                  color:
                      pinkAccentColor.withValues(alpha: 0.90),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              Row(
                children: [
                  _stellaStar(
                    size: 13,
                    color:
                        goldAccentColor.withValues(alpha: 0.85),
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
          Row(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              Container(
                width: 34,
                height: 1,
                color:
                    accentColor.withValues(alpha: 0.25),
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
                color:
                    accentColor.withValues(alpha: 0.25),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _stellaAvatar(),
          const SizedBox(height: 14),
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
          Row(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              const Text(
                '🐾',
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(width: 6),
              Text(
                'STELLA',
                style: TextStyle(
                  color:
                      goldAccentColor.withValues(alpha: 0.95),
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
              color:
                  pinkAccentColor.withValues(alpha: 0.85),
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
          color:
              accentColor.withValues(alpha: 0.20),
        ),
        boxShadow: [
          BoxShadow(
            color:
                accentColor.withValues(alpha: 0.07),
            blurRadius: 18,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment:
                MainAxisAlignment.center,
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
                    color:
                        Colors.white.withValues(alpha: 0.60),
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
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              Container(
                width: 20,
                height: 1,
                color:
                    accentColor.withValues(alpha: 0.25),
              ),
              const SizedBox(width: 8),
              _stellaStar(
                size: 12,
                color:
                    goldAccentColor.withValues(alpha: 0.80),
              ),
              const SizedBox(width: 8),
              Container(
                width: 20,
                height: 1,
                color:
                    accentColor.withValues(alpha: 0.25),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _t('footerToken'),
            textAlign: TextAlign.center,
            style: TextStyle(
              color:
                  pinkAccentColor.withValues(alpha: 0.72),
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
      shadowColor:
          accentColor.withValues(alpha: 0.35),
      surfaceTintColor: Colors.transparent,
      child: SafeArea(
        child: Column(
          children: [
            _header(),

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
                    onTap: widget.onLanguagePressed,
                  ),

                  _menuItem(
                    icon: Icons.info_outline_rounded,
                    title: _t('aboutStelluriini'),
                    onTap: widget.onAboutPressed,
                  ),

                  _menuItem(
                    icon: Icons.description_outlined,
                    title: _t('whitePaper'),
                    onTap: widget.onWhitePaperPressed,
                  ),

                  _menuItem(
                    icon: Icons.map_outlined,
                    title: _t('roadmap'),
                    onTap: widget.onRoadmapPressed,
                  ),

                  _referralItem(),

                  _menuItem(
                    icon: Icons.emoji_events_rounded,
                    title: _achievementsLocalization.get(
                      'achievementsTitle',
                    ),
                    onTap: widget.onAchievementsPressed,
                    iconColor: goldAccentColor,
                  ),

                  // ------------------------------------------------
                  // ⭐ STELLA LEVEL
                  // ------------------------------------------------

                  _stellaLevelCard(),

                  _menuItem(
                    icon: Icons.history_rounded,
                    title: _t('transactionHistory'),
                    onTap:
                        widget.onTransactionHistoryPressed,
                  ),

                  // ------------------------------------------------
                  // 🗑️ ACCOUNT DELETION
                  // ------------------------------------------------

                  _accountDeletionItem(),

                  // ------------------------------------------------
                  // 🚪 LOGOUT
                  // ------------------------------------------------

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