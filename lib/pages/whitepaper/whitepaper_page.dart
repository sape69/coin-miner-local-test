import 'package:flutter/material.dart';

import '../../localization.dart';
import '../../widgets/cat_avatar.dart';
import '../../widgets/stelluriini_logo.dart';

import '../../localization/whitepaper/whitepaper_fi.dart';
import '../../localization/whitepaper/whitepaper_en.dart';
import '../../localization/whitepaper/whitepaper_de.dart';
import '../../localization/whitepaper/whitepaper_es.dart';
import '../../localization/whitepaper/whitepaper_fr.dart';
import '../../localization/whitepaper/whitepaper_zh.dart';
import '../../localization/whitepaper/whitepaper_vi.dart';
import '../../localization/whitepaper/whitepaper_ja.dart';

// ============================================================
// STELLA THEME COLORS
// ============================================================

const Color whitePaperBackgroundColor = Color(0xFF120B24);
const Color whitePaperCardColor = Color(0xFF21113B);
const Color whitePaperAccentColor = Color(0xFFB58CFF);
const Color whitePaperPinkColor = Color(0xFFFFB7E8);
const Color whitePaperGoldColor = Color(0xFFFFD166);

// ============================================================
// WHITE PAPER PAGE
// ============================================================

class WhitePaperPage extends StatelessWidget {
  const WhitePaperPage({
    super.key,
  });

  static const String tokenName = 'Stelluriini';
  static const String tokenSymbol = 'STL';
  static const String blockchain = 'Solana';
  static const String totalSupply = '17 602 539 062';
  static const String decimals = '9';

  static const String mintAddress =
      'AyZun5s9tEJDeHTNPrVbaYpqjWdSKHx25M3kfVFjbdas';

  // ==========================================================
  // LANGUAGE MAP
  // ==========================================================

  Map<String, String> _languageMap(String languageCode) {
    switch (languageCode) {
      case 'fi':
        return whitepaperFi;

      case 'de':
        return whitepaperDe;

      case 'es':
        return whitepaperEs;

      case 'fr':
        return whitepaperFr;

      case 'zh':
        return whitepaperZh;

      case 'vi':
        return whitepaperVi;

      case 'ja':
        return whitepaperJa;

      case 'en':
      default:
        return whitepaperEn;
    }
  }

  // ==========================================================
  // TRANSLATION HELPER
  // ==========================================================

  String _t(
    String languageCode,
    String key,
  ) {
    final current = _languageMap(languageCode);

    return current[key] ??
        whitepaperEn[key] ??
        key;
  }

  // ==========================================================
  // SECTION
  // ==========================================================

  Widget _section({
    required String number,
    required IconData icon,
    required String title,
    required Widget child,
    Color accent = whitePaperAccentColor,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(
        bottom: 18,
      ),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: whitePaperCardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: accent.withValues(
            alpha: 0.18,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accent.withValues(
                    alpha: 0.11,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: accent.withValues(
                      alpha: 0.15,
                    ),
                  ),
                ),
                child: Icon(
                  icon,
                  color: accent,
                  size: 23,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      number,
                      style: TextStyle(
                        color: accent,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }

  // ==========================================================
  // PARAGRAPH
  // ==========================================================

  Widget _paragraph(
    String text,
  ) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white70,
        fontSize: 14,
        height: 1.65,
      ),
    );
  }

  // ==========================================================
  // BULLET
  // ==========================================================

  Widget _bullet(
    String text, {
    Color accent = whitePaperAccentColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 10,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            width: 7,
            height: 7,
            margin: const EdgeInsets.only(
              top: 7,
            ),
            decoration: BoxDecoration(
              color: accent,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                height: 1.55,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // FEATURE ROW
  // ==========================================================

  Widget _featureRow({
    required IconData icon,
    required String title,
    required String description,
    Color accent = whitePaperAccentColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 16,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accent.withValues(
                alpha: 0.10,
              ),
              borderRadius:
                  BorderRadius.circular(13),
            ),
            child: Icon(
              icon,
              color: accent,
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // TOKEN INFO ROW
  // ==========================================================

  Widget _tokenInfoRow(
    String label,
    String value, {
    Color accent = whitePaperAccentColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 12,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            flex: 2,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: accent,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // ALLOCATION ROW
  // ==========================================================

  Widget _allocationRow({
    required String title,
    required String percentage,
    required String amount,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(
        bottom: 10,
      ),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:
            whitePaperBackgroundColor.withValues(
          alpha: 0.45,
        ),
        borderRadius:
            BorderRadius.circular(15),
        border: Border.all(
          color: color.withValues(
            alpha: 0.16,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 38,
            decoration: BoxDecoration(
              color: color,
              borderRadius:
                  BorderRadius.circular(5),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  amount,
                  style: const TextStyle(
                    color: Color.fromRGBO(
                      255,
                      255,
                      255,
                      0.50,
                    ),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Text(
            percentage,
            style: TextStyle(
              color: color,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // PHASE ROW
  // ==========================================================

  Widget _phaseRow({
    required String phase,
    required String title,
    required String status,
    required String description,
    required Color accent,
  }) {
    return Container(
      margin: const EdgeInsets.only(
        bottom: 14,
      ),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            whitePaperBackgroundColor.withValues(
          alpha: 0.42,
        ),
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: accent.withValues(
            alpha: 0.18,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: accent.withValues(
                alpha: 0.11,
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: accent.withValues(
                  alpha: 0.28,
                ),
              ),
            ),
            child: Center(
              child: Text(
                phase,
                style: TextStyle(
                  color: accent,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style:
                            const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding:
                          const EdgeInsets
                              .symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: accent
                            .withValues(
                          alpha: 0.10,
                        ),
                        borderRadius:
                            BorderRadius.circular(
                          8,
                        ),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          color: accent,
                          fontSize: 8,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                Text(
                  description,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // ARCHITECTURE BOX
  // ==========================================================

  Widget _architectureBox({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color:
            whitePaperBackgroundColor.withValues(
          alpha: 0.42,
        ),
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(
            alpha: 0.18,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(
                alpha: 0.10,
              ),
              borderRadius:
                  BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // ARCHITECTURE ARROW
  // ==========================================================

  Widget _architectureArrow() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 7,
      ),
      child: Icon(
        Icons.arrow_downward_rounded,
        color:
            whitePaperAccentColor.withValues(
          alpha: 0.45,
        ),
        size: 20,
      ),
    );
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final localization =
        AppLocalizations.of(context);

    final languageCode =
        localization.languageCode;

    String t(String key) {
      return _t(
        languageCode,
        key,
      );
    }

    return Scaffold(
      backgroundColor:
          whitePaperBackgroundColor,

      // ========================================================
      // APP BAR
      // ========================================================

      appBar: AppBar(
        backgroundColor:
            whitePaperBackgroundColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          t('pageTitle'),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.8,
            fontSize: 16,
          ),
        ),
      ),

      // ========================================================
      // BODY
      // ========================================================

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            16,
            8,
            16,
            36,
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [

              // ==================================================
              // COVER
              // ==================================================

              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.fromLTRB(
                  24,
                  30,
                  24,
                  28,
                ),
                decoration: BoxDecoration(
                  gradient:
                      const LinearGradient(
                    colors: [
                      Color(0xFF21113B),
                      Color(0xFF2A1648),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius:
                      BorderRadius.circular(28),
                  border: Border.all(
                    color:
                        whitePaperAccentColor
                            .withValues(
                      alpha: 0.30,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color:
                          whitePaperAccentColor
                              .withValues(
                        alpha: 0.10,
                      ),
                      blurRadius: 26,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const CatAvatar(
                      size: 125,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'STELLURIINI',
                      textAlign:
                          TextAlign.center,
                      style: TextStyle(
                        color:
                            whitePaperPinkColor,
                        fontSize: 29,
                        fontWeight:
                            FontWeight.bold,
                        letterSpacing: 3.2,
                      ),
                    ),
                    const SizedBox(height: 7),
                    const Text(
                      'STL',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight:
                            FontWeight.bold,
                        letterSpacing: 4,
                      ),
                    ),
                    const SizedBox(height: 13),
                    Container(
                      padding:
                          const EdgeInsets
                              .symmetric(
                        horizontal: 15,
                        vertical: 8,
                      ),
                      decoration:
                          BoxDecoration(
                        color:
                            whitePaperAccentColor
                                .withValues(
                          alpha: 0.10,
                        ),
                        borderRadius:
                            BorderRadius.circular(
                          30,
                        ),
                        border: Border.all(
                          color:
                              whitePaperAccentColor
                                  .withValues(
                            alpha: 0.22,
                          ),
                        ),
                      ),
                      child: Text(
                        t('communityToken'),
                        textAlign:
                            TextAlign.center,
                        style:
                            const TextStyle(
                          color:
                              whitePaperAccentColor,
                          fontSize: 11,
                          fontWeight:
                              FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      t('whitePaper'),
                      style:
                          const TextStyle(
                        color:
                            whitePaperGoldColor,
                        fontSize: 13,
                        fontWeight:
                            FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      t('version'),
                      style:
                          const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ==================================================
              // 01 — EXECUTIVE SUMMARY
              // ==================================================

              _section(
                number: '01',
                icon:
                    Icons.auto_awesome_rounded,
                title: t('01_title'),
                child: _paragraph(
                  t('01_text'),
                ),
              ),

              // ==================================================
              // 02 — VISION
              // ==================================================

              _section(
                number: '02',
                icon:
                    Icons.visibility_rounded,
                title: t('02_title'),
                accent:
                    whitePaperPinkColor,
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    _paragraph(
                      t('02_text'),
                    ),
                    const SizedBox(height: 18),
                    _bullet(
                      t('02_b1'),
                      accent:
                          whitePaperPinkColor,
                    ),
                    _bullet(
                      t('02_b2'),
                      accent:
                          whitePaperPinkColor,
                    ),
                    _bullet(
                      t('02_b3'),
                      accent:
                          whitePaperPinkColor,
                    ),
                    _bullet(
                      t('02_b4'),
                      accent:
                          whitePaperPinkColor,
                    ),
                    _bullet(
                      t('02_b5'),
                      accent:
                          whitePaperPinkColor,
                    ),
                  ],
                ),
              ),

              // ==================================================
              // 03 — WHAT IS STELLURIINI
              // ==================================================

              _section(
                number: '03',
                icon: Icons.pets_rounded,
                title: t('03_title'),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    _paragraph(
                      t('03_text'),
                    ),
                    const SizedBox(height: 18),
                    _featureRow(
                      icon: Icons.pets_rounded,
                      title:
                          t('03_f1_title'),
                      description:
                          t('03_f1_desc'),
                      accent:
                          whitePaperPinkColor,
                    ),
                    _featureRow(
                      icon: Icons
                          .currency_bitcoin_rounded,
                      title:
                          t('03_f2_title'),
                      description:
                          t('03_f2_desc'),
                      accent:
                          whitePaperGoldColor,
                    ),
                    _featureRow(
                      icon: Icons
                          .phone_android_rounded,
                      title:
                          t('03_f3_title'),
                      description:
                          t('03_f3_desc'),
                      accent:
                          whitePaperAccentColor,
                    ),
                    _featureRow(
                      icon:
                          Icons.groups_rounded,
                      title:
                          t('03_f4_title'),
                      description:
                          t('03_f4_desc'),
                      accent:
                          whitePaperPinkColor,
                    ),
                  ],
                ),
              ),

              // ==================================================
              // 04 — STELLA
              // ==================================================

              _section(
                number: '04',
                icon:
                    Icons.favorite_rounded,
                title: t('04_title'),
                accent:
                    whitePaperPinkColor,
                child: Column(
                  children: [
                    const StelluriiniLogo(
                      size: 80,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      t('04_heading'),
                      textAlign:
                          TextAlign.center,
                      style:
                          const TextStyle(
                        color:
                            whitePaperPinkColor,
                        fontSize: 18,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _paragraph(
                      t('04_text'),
                    ),
                  ],
                ),
              ),

              // ==================================================
              // 05 — TOKEN
              // ==================================================

              _section(
                number: '05',
                icon: Icons
                    .monetization_on_rounded,
                title: t('05_title'),
                accent:
                    whitePaperGoldColor,
                child: Column(
                  children: [
                    _tokenInfoRow(
                      t('05_name'),
                      tokenName,
                      accent:
                          whitePaperPinkColor,
                    ),
                    _tokenInfoRow(
                      t('05_symbol'),
                      tokenSymbol,
                      accent:
                          whitePaperPinkColor,
                    ),
                    _tokenInfoRow(
                      t('05_blockchain'),
                      blockchain,
                    ),
                    _tokenInfoRow(
                      t('05_supply'),
                      totalSupply,
                      accent:
                          whitePaperGoldColor,
                    ),
                    _tokenInfoRow(
                      t('05_decimals'),
                      decimals,
                    ),
                    const SizedBox(height: 5),
                    Container(
                      width: double.infinity,
                      padding:
                          const EdgeInsets.all(
                        15,
                      ),
                      decoration:
                          BoxDecoration(
                        color:
                            whitePaperBackgroundColor
                                .withValues(
                          alpha: 0.45,
                        ),
                        borderRadius:
                            BorderRadius.circular(
                          15,
                        ),
                        border: Border.all(
                          color:
                              whitePaperGoldColor
                                  .withValues(
                            alpha: 0.16,
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                        children: [
                          Text(
                            t('05_mint'),
                            style:
                                const TextStyle(
                              color:
                                  Colors.white54,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(
                            height: 8,
                          ),
                          const SelectableText(
                            mintAddress,
                            style:
                                TextStyle(
                              color:
                                  whitePaperPinkColor,
                              fontSize: 12,
                              fontWeight:
                                  FontWeight
                                      .bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ==================================================
              // 06 — TOKENOMICS
              // ==================================================

              _section(
                number: '06',
                icon:
                    Icons.pie_chart_rounded,
                title: t('06_title'),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    _paragraph(
                      t('06_text'),
                    ),
                    const SizedBox(height: 18),
                    _allocationRow(
                      title: t('06_a1'),
                      percentage: '40%',
                      amount:
                          '7 041 015 625 STL',
                      color:
                          whitePaperAccentColor,
                    ),
                    _allocationRow(
                      title: t('06_a2'),
                      percentage: '20%',
                      amount:
                          '3 520 507 812 STL',
                      color:
                          const Color(
                        0xFF72B7FF,
                      ),
                    ),
                    _allocationRow(
                      title: t('06_a3'),
                      percentage: '15%',
                      amount:
                          '2 640 380 859 STL',
                      color:
                          const Color(
                        0xFFC084FC,
                      ),
                    ),
                    _allocationRow(
                      title: t('06_a4'),
                      percentage: '15%',
                      amount:
                          '2 640 380 859 STL',
                      color:
                          whitePaperGoldColor,
                    ),
                    _allocationRow(
                      title: t('06_a5'),
                      percentage: '10%',
                      amount:
                          '1 760 253 907 STL',
                      color:
                          whitePaperPinkColor,
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding:
                          const EdgeInsets.all(
                        14,
                      ),
                      decoration:
                          BoxDecoration(
                        color:
                            whitePaperAccentColor
                                .withValues(
                          alpha: 0.07,
                        ),
                        borderRadius:
                            BorderRadius.circular(
                          14,
                        ),
                        border: Border.all(
                          color:
                              whitePaperAccentColor
                                  .withValues(
                            alpha: 0.16,
                          ),
                        ),
                      ),
                      child: Text(
                        t('06_total'),
                        textAlign:
                            TextAlign.center,
                        style:
                            const TextStyle(
                          color:
                              whitePaperGoldColor,
                          fontSize: 14,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ==================================================
              // 07 — STELLA MINING
              // ==================================================

              _section(
                number: '07',
                icon: Icons.bolt_rounded,
                title: t('07_title'),
                accent:
                    whitePaperAccentColor,
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    _paragraph(
                      t('07_text'),
                    ),
                    const SizedBox(height: 18),
                    _featureRow(
                      icon: Icons.speed_rounded,
                      title:
                          t('07_f1_title'),
                      description:
                          t('07_f1_desc'),
                    ),
                    _featureRow(
                      icon:
                          Icons.timer_rounded,
                      title:
                          t('07_f2_title'),
                      description:
                          t('07_f2_desc'),
                    ),
                    _featureRow(
                      icon:
                          Icons.calculate_rounded,
                      title:
                          t('07_f3_title'),
                      description:
                          t('07_f3_desc'),
                    ),
                    _featureRow(
                      icon:
                          Icons.lock_clock_rounded,
                      title:
                          t('07_f4_title'),
                      description:
                          t('07_f4_desc'),
                    ),
                  ],
                ),
              ),

              // ==================================================
              // 08 — DAILY BONUS
              // ==================================================

              _section(
                number: '08',
                icon:
                    Icons.card_giftcard_rounded,
                title: t('08_title'),
                accent:
                    whitePaperGoldColor,
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    _paragraph(
                      t('08_text'),
                    ),
                    const SizedBox(height: 16),
                    _bullet(
                      t('08_b1'),
                      accent:
                          whitePaperGoldColor,
                    ),
                    _bullet(
                      t('08_b2'),
                      accent:
                          whitePaperGoldColor,
                    ),
                    _bullet(
                      t('08_b3'),
                      accent:
                          whitePaperGoldColor,
                    ),
                  ],
                ),
              ),

              // ==================================================
              // 09 — POWER BOOST
              // ==================================================

              _section(
                number: '09',
                icon: Icons.flash_on_rounded,
                title: t('09_title'),
                accent:
                    whitePaperPinkColor,
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    _paragraph(
                      t('09_text'),
                    ),
                    const SizedBox(height: 16),
                    _featureRow(
                      icon: Icons
                          .ondemand_video_rounded,
                      title:
                          t('09_f1_title'),
                      description:
                          t('09_f1_desc'),
                      accent:
                          whitePaperPinkColor,
                    ),
                    _featureRow(
                      icon: Icons
                          .av_timer_rounded,
                      title:
                          t('09_f2_title'),
                      description:
                          t('09_f2_desc'),
                      accent:
                          whitePaperPinkColor,
                    ),
                    _featureRow(
                      icon: Icons.today_rounded,
                      title:
                          t('09_f3_title'),
                      description:
                          t('09_f3_desc'),
                      accent:
                          whitePaperPinkColor,
                    ),
                  ],
                ),
              ),

              // ==================================================
              // 10 — ARCHITECTURE
              // ==================================================

              _section(
                number: '10',
                icon:
                    Icons.account_tree_rounded,
                title: t('10_title'),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    _paragraph(
                      t('10_text'),
                    ),
                    const SizedBox(height: 18),
                    _architectureBox(
                      icon: Icons
                          .phone_android_rounded,
                      title:
                          t('10_b1_title'),
                      description:
                          t('10_b1_desc'),
                      color:
                          whitePaperPinkColor,
                    ),
                    _architectureArrow(),
                    _architectureBox(
                      icon: Icons.cloud_rounded,
                      title:
                          t('10_b2_title'),
                      description:
                          t('10_b2_desc'),
                      color:
                          whitePaperAccentColor,
                    ),
                    _architectureArrow(),
                    _architectureBox(
                      icon:
                          Icons.security_rounded,
                      title:
                          t('10_b3_title'),
                      description:
                          t('10_b3_desc'),
                      color:
                          whitePaperGoldColor,
                    ),
                    _architectureArrow(),
                    _architectureBox(
                      icon: Icons.link_rounded,
                      title:
                          t('10_b4_title'),
                      description:
                          t('10_b4_desc'),
                      color:
                          whitePaperPinkColor,
                    ),
                  ],
                ),
              ),

              // ==================================================
              // 11 — HISTORY
              // ==================================================

              _section(
                number: '11',
                icon:
                    Icons.history_rounded,
                title: t('11_title'),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    _paragraph(
                      t('11_text'),
                    ),
                    const SizedBox(height: 16),
                    _bullet(t('11_b1')),
                    _bullet(t('11_b2')),
                    _bullet(t('11_b3')),
                    _bullet(t('11_b4')),
                    _bullet(t('11_b5')),
                  ],
                ),
              ),

              // ==================================================
              // 12 — SECURITY
              // ==================================================

              _section(
                number: '12',
                icon:
                    Icons.security_rounded,
                title: t('12_title'),
                accent:
                    whitePaperGoldColor,
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    _paragraph(
                      t('12_text'),
                    ),
                    const SizedBox(height: 18),
                    _featureRow(
                      icon: Icons
                          .verified_user_rounded,
                      title:
                          t('12_f1_title'),
                      description:
                          t('12_f1_desc'),
                      accent:
                          whitePaperGoldColor,
                    ),
                    _featureRow(
                      icon: Icons.block_rounded,
                      title:
                          t('12_f2_title'),
                      description:
                          t('12_f2_desc'),
                      accent:
                          whitePaperGoldColor,
                    ),
                    _featureRow(
                      icon: Icons.speed_rounded,
                      title:
                          t('12_f3_title'),
                      description:
                          t('12_f3_desc'),
                      accent:
                          whitePaperGoldColor,
                    ),
                    _featureRow(
                      icon:
                          Icons.verified_rounded,
                      title:
                          t('12_f4_title'),
                      description:
                          t('12_f4_desc'),
                      accent:
                          whitePaperGoldColor,
                    ),
                  ],
                ),
              ),

              // ==================================================
              // 13 — COMMUNITY
              // ==================================================

              _section(
                number: '13',
                icon:
                    Icons.groups_rounded,
                title: t('13_title'),
                accent:
                    whitePaperPinkColor,
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    _paragraph(
                      t('13_text'),
                    ),
                    const SizedBox(height: 18),
                    _bullet(
                      t('13_b1'),
                      accent:
                          whitePaperPinkColor,
                    ),
                    _bullet(
                      t('13_b2'),
                      accent:
                          whitePaperPinkColor,
                    ),
                    _bullet(
                      t('13_b3'),
                      accent:
                          whitePaperPinkColor,
                    ),
                  ],
                ),
              ),

              // ==================================================
              // 14 — FUTURE ECOSYSTEM
              // ==================================================

              _section(
                number: '14',
                icon:
                    Icons.rocket_launch_rounded,
                title: t('14_title'),
                accent:
                    whitePaperAccentColor,
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    _paragraph(
                      t('14_text'),
                    ),
                    const SizedBox(height: 18),
                    _featureRow(
                      icon: Icons
                          .sports_esports_rounded,
                      title:
                          t('14_f1_title'),
                      description:
                          t('14_f1_desc'),
                      accent:
                          whitePaperPinkColor,
                    ),
                    _featureRow(
                      icon: Icons.apps_rounded,
                      title:
                          t('14_f2_title'),
                      description:
                          t('14_f2_desc'),
                      accent:
                          whitePaperAccentColor,
                    ),
                    _featureRow(
                      icon: Icons.link_rounded,
                      title:
                          t('14_f3_title'),
                      description:
                          t('14_f3_desc'),
                      accent:
                          whitePaperGoldColor,
                    ),
                    _featureRow(
                      icon:
                          Icons.emoji_events_rounded,
                      title:
                          t('14_f4_title'),
                      description:
                          t('14_f4_desc'),
                      accent:
                          whitePaperPinkColor,
                    ),
                  ],
                ),
              ),

              // ==================================================
              // 15 — ROADMAP
              // ==================================================

              _section(
                number: '15',
                icon: Icons.map_rounded,
                title: t('15_title'),
                child: Column(
                  children: [
                    _phaseRow(
                      phase: '01',
                      title:
                          t('15_p1_title'),
                      status:
                          t('15_p1_status'),
                      description:
                          t('15_p1_desc'),
                      accent:
                          whitePaperPinkColor,
                    ),
                    _phaseRow(
                      phase: '02',
                      title:
                          t('15_p2_title'),
                      status:
                          t('15_p2_status'),
                      description:
                          t('15_p2_desc'),
                      accent:
                          whitePaperAccentColor,
                    ),
                    _phaseRow(
                      phase: '03',
                      title:
                          t('15_p3_title'),
                      status:
                          t('15_p3_status'),
                      description:
                          t('15_p3_desc'),
                      accent:
                          whitePaperGoldColor,
                    ),
                    _phaseRow(
                      phase: '04',
                      title:
                          t('15_p4_title'),
                      status:
                          t('15_p4_status'),
                      description:
                          t('15_p4_desc'),
                      accent:
                          whitePaperPinkColor,
                    ),
                  ],
                ),
              ),

              // ==================================================
              // 16 — TRANSPARENCY
              // ==================================================

              _section(
                number: '16',
                icon:
                    Icons.visibility_rounded,
                title: t('16_title'),
                accent:
                    whitePaperGoldColor,
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    _paragraph(
                      t('16_text'),
                    ),
                    const SizedBox(height: 18),
                    _bullet(
                      t('16_b1'),
                      accent:
                          whitePaperGoldColor,
                    ),
                    _bullet(
                      t('16_b2'),
                      accent:
                          whitePaperGoldColor,
                    ),
                    _bullet(
                      t('16_b3'),
                      accent:
                          whitePaperGoldColor,
                    ),
                    _bullet(
                      t('16_b4'),
                      accent:
                          whitePaperGoldColor,
                    ),
                  ],
                ),
              ),

              // ==================================================
              // 17 — RISKS
              // ==================================================

              _section(
                number: '17',
                icon:
                    Icons.warning_amber_rounded,
                title: t('17_title'),
                accent:
                    Colors.orangeAccent,
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    _paragraph(
                      t('17_text'),
                    ),
                    const SizedBox(height: 18),
                    _bullet(
                      t('17_b1'),
                      accent:
                          Colors.orangeAccent,
                    ),
                    _bullet(
                      t('17_b2'),
                      accent:
                          Colors.orangeAccent,
                    ),
                    _bullet(
                      t('17_b3'),
                      accent:
                          Colors.orangeAccent,
                    ),
                    _bullet(
                      t('17_b4'),
                      accent:
                          Colors.orangeAccent,
                    ),
                    _bullet(
                      t('17_b5'),
                      accent:
                          Colors.orangeAccent,
                    ),
                    _bullet(
                      t('17_b6'),
                      accent:
                          Colors.orangeAccent,
                    ),
                  ],
                ),
              ),

              // ==================================================
              // 18 — DISCLAIMER
              // ==================================================

              Container(
                width: double.infinity,
                margin:
                    const EdgeInsets.only(
                  bottom: 18,
                ),
                padding:
                    const EdgeInsets.all(22),
                decoration:
                    BoxDecoration(
                  color: Colors.orangeAccent
                      .withValues(
                    alpha: 0.07,
                  ),
                  borderRadius:
                      BorderRadius.circular(22),
                  border: Border.all(
                    color:
                        Colors.orangeAccent
                            .withValues(
                      alpha: 0.24,
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.gavel_rounded,
                      color:
                          Colors.orangeAccent,
                      size: 32,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      t('18_title'),
                      textAlign:
                          TextAlign.center,
                      style:
                          const TextStyle(
                        color:
                            Colors.orangeAccent,
                        fontSize: 17,
                        fontWeight:
                            FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      t('18_text'),
                      textAlign:
                          TextAlign.center,
                      style:
                          const TextStyle(
                        color: Colors.white60,
                        fontSize: 13,
                        height: 1.55,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      t('18_text2'),
                      textAlign:
                          TextAlign.center,
                      style:
                          const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        height: 1.55,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              // ==================================================
              // 19 — OFFICIAL INFORMATION
              // ==================================================

              _section(
                number: '19',
                icon: Icons.link_rounded,
                title: t('19_title'),
                accent:
                    whitePaperPinkColor,
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    _paragraph(
                      t('19_text'),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      width: double.infinity,
                      padding:
                          const EdgeInsets.all(
                        15,
                      ),
                      decoration:
                          BoxDecoration(
                        color:
                            whitePaperBackgroundColor
                                .withValues(
                          alpha: 0.45,
                        ),
                        borderRadius:
                            BorderRadius.circular(
                          15,
                        ),
                        border: Border.all(
                          color:
                              whitePaperPinkColor
                                  .withValues(
                            alpha: 0.15,
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                        children: [
                          Text(
                            t('19_mint'),
                            style:
                                const TextStyle(
                              color:
                                  whitePaperPinkColor,
                              fontSize: 11,
                              fontWeight:
                                  FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(
                            height: 8,
                          ),
                          const SelectableText(
                            mintAddress,
                            style:
                                TextStyle(
                              color:
                                  Colors.white70,
                              fontSize: 12,
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ==================================================
              // STELLA CLOSING CARD
              // ==================================================

              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.fromLTRB(
                  22,
                  24,
                  22,
                  24,
                ),
                decoration: BoxDecoration(
                  gradient:
                      const LinearGradient(
                    colors: [
                      Color(0xFF21113B),
                      Color(0xFF281540),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius:
                      BorderRadius.circular(24),
                  border: Border.all(
                    color:
                        whitePaperPinkColor
                            .withValues(
                      alpha: 0.20,
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    const CatAvatar(
                      size: 82,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      t('closing'),
                      textAlign:
                          TextAlign.center,
                      style:
                          const TextStyle(
                        color:
                            whitePaperPinkColor,
                        fontSize: 18,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      t('closingSub'),
                      textAlign:
                          TextAlign.center,
                      style:
                          const TextStyle(
                        color: Colors.white60,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ==================================================
              // FOOTER
              // ==================================================

              Text(
                t('footer'),
                textAlign: TextAlign.center,
                style:
                    const TextStyle(
                  color:
                      whitePaperPinkColor,
                  fontSize: 12,
                  fontWeight:
                      FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                t('footerSupply'),
                textAlign: TextAlign.center,
                style:
                    const TextStyle(
                  color:
                      whitePaperGoldColor,
                  fontSize: 12,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                t('footerVersion'),
                textAlign: TextAlign.center,
                style:
                    const TextStyle(
                  color: Colors.white38,
                  fontSize: 10,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 18),
            ],
          ),
        ),
      ),
    );
  }
}