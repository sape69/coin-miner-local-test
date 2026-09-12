import 'package:flutter/material.dart';

import '../localization.dart';
import 'cat_avatar.dart';

// ============================================================
// 🐱 STELLURIINI / STELLA HOME DRAWER
// ============================================================
//
// Sovelluksen päävalikko.
//
// Tämä widget:
// - käyttää Stelluriinin violetti/pinkki-teemaa
// - käyttää samaa languageCode-arvoa kuin HomePage
// - käyttää keskitettyä AppLocalizations-järjestelmää
// - tukee kaikkia nykyisiä kieliä
// - sisältää navigoinnit:
//   • Language
//   • About Stelluriini
//   • White Paper
//   • Roadmap
//   • Transaction History
//   • Logout
// - käyttää samaa Stella-visuaalista ilmettä kuin HomePage
//
// ============================================================

// ============================================================
// 🎨 STELLURIINI COLORS
// ============================================================

const Color backgroundColor =
    Color(0xFF120B24);

const Color cardColor =
    Color(0xFF21113B);

const Color accentColor =
    Color(0xFFB58CFF);

const Color pinkAccentColor =
    Color(0xFFFFB7E8);

const Color goldAccentColor =
    Color(0xFFFFD166);

const Color logoutColor =
    Color(0xFFFF8A8A);

// ============================================================
// 🐱 HOME DRAWER
// ============================================================

class HomeDrawer extends StatelessWidget {
  final String languageCode;

  final VoidCallback onLanguagePressed;
  final VoidCallback onAboutPressed;
  final VoidCallback onWhitePaperPressed;
  final VoidCallback onRoadmapPressed;
  final VoidCallback onTransactionHistoryPressed;
  final VoidCallback onLogoutPressed;

  const HomeDrawer({
    super.key,
    required this.languageCode,
    required this.onLanguagePressed,
    required this.onAboutPressed,
    required this.onWhitePaperPressed,
    required this.onRoadmapPressed,
    required this.onTransactionHistoryPressed,
    required this.onLogoutPressed,
  });

  // ==========================================================
  // 🌍 LOCALIZATION
  // ==========================================================

  AppLocalizations get _localization =>
      AppLocalizations(languageCode);

  String _t(String key) {
    return _localization.get(key);
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
        borderRadius:
            BorderRadius.circular(16),
        child: InkWell(
          borderRadius:
              BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 13,
            ),
            child: Row(
              children: [
                // ==================================================
                // ICON
                // ==================================================

                Container(
                  width: 44,
                  height: 44,
                  decoration:
                      BoxDecoration(
                    gradient:
                        LinearGradient(
                      begin:
                          Alignment.topLeft,
                      end:
                          Alignment.bottomRight,
                      colors: [
                        accentColor.withValues(
                          alpha: 0.28,
                        ),
                        currentIconColor.withValues(
                          alpha: 0.16,
                        ),
                      ],
                    ),
                    borderRadius:
                        BorderRadius.circular(
                      13,
                    ),
                    border:
                        Border.all(
                      color:
                          currentIconColor.withValues(
                        alpha: 0.20,
                      ),
                    ),
                  ),
                  child: Icon(
                    icon,
                    color:
                        currentIconColor,
                    size: 23,
                  ),
                ),

                const SizedBox(
                  width: 14,
                ),

                // ==================================================
                // TITLE
                // ==================================================

                Expanded(
                  child: Text(
                    title,
                    maxLines: 2,
                    overflow:
                        TextOverflow.ellipsis,
                    style:
                        const TextStyle(
                      color:
                          Colors.white,
                      fontSize: 16,
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                ),

                // ==================================================
                // OPTIONAL BADGE
                // ==================================================

                if (badge != null) ...[
                  const SizedBox(
                    width: 8,
                  ),
                  Container(
                    padding:
                        const EdgeInsets
                            .symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration:
                        BoxDecoration(
                      color:
                          goldAccentColor
                              .withValues(
                        alpha: 0.15,
                      ),
                      borderRadius:
                          BorderRadius.circular(
                        20,
                      ),
                    ),
                    child: Text(
                      badge,
                      style:
                          const TextStyle(
                        color:
                            goldAccentColor,
                        fontSize: 10,
                        fontWeight:
                            FontWeight.bold,
                        letterSpacing:
                            0.5,
                      ),
                    ),
                  ),
                ],

                const SizedBox(
                  width: 4,
                ),

                // ==================================================
                // CHEVRON
                // ==================================================

                Icon(
                  Icons
                      .chevron_right_rounded,
                  color:
                      Colors.white
                          .withValues(
                    alpha: 0.30,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // 🚪 LOGOUT MENU ITEM
  // ==========================================================

  Widget _logoutItem() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 4,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius:
            BorderRadius.circular(16),
        child: InkWell(
          borderRadius:
              BorderRadius.circular(16),
          onTap: onLogoutPressed,
          child: Container(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 13,
            ),
            child: Row(
              children: [
                // ==================================================
                // LOGOUT ICON
                // ==================================================

                Container(
                  width: 44,
                  height: 44,
                  decoration:
                      BoxDecoration(
                    color:
                        logoutColor.withValues(
                      alpha: 0.10,
                    ),
                    borderRadius:
                        BorderRadius.circular(
                      13,
                    ),
                    border:
                        Border.all(
                      color:
                          logoutColor.withValues(
                        alpha: 0.20,
                      ),
                    ),
                  ),
                  child: const Icon(
                    Icons.logout_rounded,
                    color:
                        logoutColor,
                    size: 23,
                  ),
                ),

                const SizedBox(
                  width: 14,
                ),

                // ==================================================
                // LOGOUT TITLE
                // ==================================================

                Expanded(
                  child: Text(
                    _t('logout'),
                    maxLines: 2,
                    overflow:
                        TextOverflow.ellipsis,
                    style:
                        const TextStyle(
                      color:
                          Colors.white,
                      fontSize: 16,
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                ),

                const SizedBox(
                  width: 4,
                ),

                const Icon(
                  Icons
                      .chevron_right_rounded,
                  color:
                      Colors.white30,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // 🏠 BUILD
  // ==========================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Drawer(
      backgroundColor:
          backgroundColor,
      child: SafeArea(
        child: Column(
          children: [
            // ==================================================
            // 🐱 STELLA HEADER
            // ==================================================

            Container(
              width:
                  double.infinity,
              margin:
                  const EdgeInsets.all(12),
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 22,
              ),
              decoration:
                  BoxDecoration(
                gradient:
                    const LinearGradient(
                  begin:
                      Alignment.topLeft,
                  end:
                      Alignment.bottomRight,
                  colors: [
                    Color(0xFF2D174D),
                    Color(0xFF1B1033),
                  ],
                ),
                borderRadius:
                    BorderRadius.circular(
                  24,
                ),
                border:
                    Border.all(
                  color:
                      accentColor.withValues(
                    alpha: 0.45,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color:
                        accentColor.withValues(
                      alpha: 0.14,
                    ),
                    blurRadius: 24,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                children: [
                  // ==================================================
                  // HEADER DECORATION
                  // ==================================================

                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment
                            .spaceBetween,
                    children: [
                      const Text(
                        '🐱',
                        style:
                            TextStyle(
                          fontSize: 28,
                        ),
                      ),
                      Text(
                        '🐾 STL • SOLANA 🐾',
                        style:
                            TextStyle(
                          color:
                              pinkAccentColor
                                  .withValues(
                            alpha: 0.90,
                          ),
                          fontSize: 11,
                          fontWeight:
                              FontWeight.bold,
                          letterSpacing:
                              1,
                        ),
                      ),
                      const Text(
                        '🐱',
                        style:
                            TextStyle(
                          fontSize: 28,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 18,
                  ),

                  // ==================================================
                  // STELLA AVATAR
                  // ==================================================

                  const CatAvatar(
                    size: 105,
                  ),

                  const SizedBox(
                    height: 14,
                  ),

                  // ==================================================
                  // APP NAME
                  // ==================================================

                  const Text(
                    'STELLURIINI',
                    textAlign:
                        TextAlign.center,
                    style:
                        TextStyle(
                      color:
                          Colors.white,
                      fontSize: 24,
                      fontWeight:
                          FontWeight.bold,
                      letterSpacing: 3,
                    ),
                  ),

                  const SizedBox(
                    height: 6,
                  ),

                  // ==================================================
                  // COMMUNITY TEXT
                  // ==================================================

                  Text(
                    _t(
                      'stellaCommunity',
                    ),
                    textAlign:
                        TextAlign.center,
                    style:
                        TextStyle(
                      color:
                          pinkAccentColor
                              .withValues(
                        alpha: 0.85,
                      ),
                      fontSize: 13,
                      fontWeight:
                          FontWeight.w600,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),

            // ==================================================
            // 📋 MENU
            // ==================================================

            Expanded(
              child: ListView(
                padding:
                    const EdgeInsets.only(
                  top: 4,
                  bottom: 8,
                ),
                children: [
                  // ------------------------------------------------
                  // LANGUAGE
                  // ------------------------------------------------

                  _menuItem(
                    icon:
                        Icons.language_rounded,
                    title: _t(
                      'language',
                    ),
                    onTap:
                        onLanguagePressed,
                  ),

                  // ------------------------------------------------
                  // ABOUT
                  // ------------------------------------------------

                  _menuItem(
                    icon:
                        Icons.info_outline_rounded,
                    title: _t(
                      'aboutStelluriini',
                    ),
                    onTap:
                        onAboutPressed,
                  ),

                  // ------------------------------------------------
                  // WHITE PAPER
                  // ------------------------------------------------

                  _menuItem(
                    icon:
                        Icons.description_outlined,
                    title: _t(
                      'whitePaper',
                    ),
                    onTap:
                        onWhitePaperPressed,
                  ),

                  // ------------------------------------------------
                  // ROADMAP
                  // ------------------------------------------------

                  _menuItem(
                    icon:
                        Icons.map_outlined,
                    title: _t(
                      'roadmap',
                    ),
                    onTap:
                        onRoadmapPressed,
                  ),

                  // ------------------------------------------------
                  // TRANSACTION HISTORY
                  // ------------------------------------------------

                  _menuItem(
                    icon:
                        Icons.history_rounded,
                    title: _t(
                      'transactionHistory',
                    ),
                    onTap:
                        onTransactionHistoryPressed,
                  ),

                  // ------------------------------------------------
                  // LOGOUT
                  // ------------------------------------------------

                  _logoutItem(),
                ],
              ),
            ),

            // ==================================================
            // 🐾 FOOTER
            // ==================================================

            Container(
              width:
                  double.infinity,
              margin:
                  const EdgeInsets.fromLTRB(
                16,
                4,
                16,
                16,
              ),
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              decoration:
                  BoxDecoration(
                color:
                    cardColor,
                borderRadius:
                    BorderRadius.circular(
                  18,
                ),
                border:
                    Border.all(
                  color:
                      accentColor.withValues(
                    alpha: 0.16,
                  ),
                ),
              ),
              child: Column(
                children: [
                  // ==================================================
                  // FOOTER TAGLINE
                  // ==================================================

                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment
                            .center,
                    children: [
                      const Text(
                        '🐾',
                        style:
                            TextStyle(
                          fontSize: 16,
                        ),
                      ),

                      const SizedBox(
                        width: 7,
                      ),

                      Flexible(
                        child: Text(
                          _t(
                            'footerTagline',
                          ),
                          textAlign:
                              TextAlign.center,
                          style:
                              TextStyle(
                            color:
                                Colors.white
                                    .withValues(
                              alpha: 0.60,
                            ),
                            fontSize: 11,
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),
                      ),

                      const SizedBox(
                        width: 7,
                      ),

                      const Text(
                        '🐾',
                        style:
                            TextStyle(
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 7,
                  ),

                  // ==================================================
                  // TOKEN FOOTER
                  // ==================================================

                  Text(
                    _t(
                      'footerToken',
                    ),
                    textAlign:
                        TextAlign.center,
                    style:
                        TextStyle(
                      color:
                          pinkAccentColor
                              .withValues(
                        alpha: 0.72,
                      ),
                      fontSize: 10,
                      fontWeight:
                          FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}