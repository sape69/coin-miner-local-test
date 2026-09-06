import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../widgets/cat_avatar.dart';
import '../../widgets/stelluriini_logo.dart';

const Color tokenBackgroundColor = Color(0xFF120B24);
const Color tokenCardColor = Color(0xFF21113B);
const Color tokenAccentColor = Color(0xFFB58CFF);
const Color tokenPinkColor = Color(0xFFFFB7E8);
const Color tokenGoldColor = Color(0xFFFFD166);

class StlTokenPage extends StatelessWidget {
  const StlTokenPage({
    super.key,
  });

  // ==========================================================
  // TOKEN INFORMATION
  // ==========================================================

  static const String tokenName = 'Stelluriini';
  static const String tokenSymbol = 'STL';

  static const String mintAddress =
      'AyZun5s9tEJDeHTNPrVbaYpqjWdSKHx25M3kfVFjbdas';

  static const String totalSupply =
      '17 602 539 062';

  static const String decimals = '9';

  // ==========================================================
  // COPY MINT ADDRESS
  // ==========================================================

  Future<void> _copyAddress(BuildContext context) async {
    await Clipboard.setData(
      const ClipboardData(
        text: mintAddress,
      ),
    );

    if (!context.mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          backgroundColor: tokenCardColor,
          content: Text(
            'Mint address copied! 🐱',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
  }

  // ==========================================================
  // OPEN SOLSCAN
  // ==========================================================

  Future<void> _openSolscan(BuildContext context) async {
    final Uri url = Uri.parse(
      'https://solscan.io/token/$mintAddress',
    );

    try {
      final bool opened = await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );

      if (!opened && context.mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              backgroundColor: tokenCardColor,
              content: Text(
                'Could not open Solscan.',
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
            ),
          );
      }
    } catch (_) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            backgroundColor: tokenCardColor,
            content: Text(
              'Could not open Solscan.',
              style: TextStyle(
                color: Colors.white,
              ),
            ),
          ),
        );
    }
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: tokenBackgroundColor,

      // ========================================================
      // APP BAR
      // ========================================================

      appBar: AppBar(
        backgroundColor: tokenBackgroundColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'STL Token',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),

      // ========================================================
      // BODY
      // ========================================================

      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            // ==================================================
            // STELLA HEADER
            // ==================================================

            Container(
              padding: const EdgeInsets.fromLTRB(
                24,
                28,
                24,
                26,
              ),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF21113B),
                    Color(0xFF2A1648),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(
                  color: tokenAccentColor.withValues(
                    alpha: 0.30,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: tokenAccentColor.withValues(
                      alpha: 0.10,
                    ),
                    blurRadius: 24,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Column(
                children: [
                  const CatAvatar(
                    size: 120,
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    'STELLURIINI',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 3,
                      color: tokenPinkColor,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'STL',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: tokenAccentColor.withValues(
                        alpha: 0.10,
                      ),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: tokenAccentColor.withValues(
                          alpha: 0.22,
                        ),
                      ),
                    ),
                    child: const Text(
                      '🐾 SOLANA COMMUNITY TOKEN 🐾',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: tokenAccentColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ==================================================
            // TOKEN INFORMATION
            // ==================================================

            _TokenCard(
              title: 'Token Information',
              icon: Icons.monetization_on_outlined,
              accent: tokenAccentColor,
              child: const Column(
                children: [
                  _TokenInfoRow(
                    icon: Icons.label_outline,
                    label: 'Name',
                    value: tokenName,
                  ),

                  SizedBox(height: 16),

                  _TokenInfoRow(
                    icon: Icons.short_text,
                    label: 'Symbol',
                    value: tokenSymbol,
                  ),

                  SizedBox(height: 16),

                  _TokenInfoRow(
                    icon: Icons.account_tree_outlined,
                    label: 'Blockchain',
                    value: 'Solana',
                  ),

                  SizedBox(height: 16),

                  _TokenInfoRow(
                    icon: Icons.numbers,
                    label: 'Decimals',
                    value: decimals,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ==================================================
            // TOTAL SUPPLY
            // ==================================================

            _TokenCard(
              title: 'Token Supply',
              icon: Icons.inventory_2_outlined,
              accent: tokenGoldColor,
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 26,
                    ),
                    decoration: BoxDecoration(
                      color: tokenGoldColor.withValues(
                        alpha: 0.07,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: tokenGoldColor.withValues(
                          alpha: 0.20,
                        ),
                      ),
                    ),
                    child: const Column(
                      children: [
                        Text(
                          'TOTAL SUPPLY',
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),

                        SizedBox(height: 14),

                        Text(
                          totalSupply,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: tokenGoldColor,
                          ),
                        ),

                        SizedBox(height: 8),

                        Text(
                          'STL',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 3,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  const Text(
                    'Stelluriini has a fixed total supply of '
                    '17 602 539 062 STL tokens.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white65,
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ==================================================
            // MINT ADDRESS
            // ==================================================

            _TokenCard(
              title: 'Official Mint Address',
              icon: Icons.vpn_key_outlined,
              accent: tokenPinkColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'This is the official public mint address '
                    'for the Stelluriini token.',
                    style: TextStyle(
                      color: Colors.white65,
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 18),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(
                        alpha: 0.22,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: tokenPinkColor.withValues(
                          alpha: 0.15,
                        ),
                      ),
                    ),
                    child: const SelectableText(
                      mintAddress,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: tokenPinkColor,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ------------------------------------------------
                  // COPY
                  // ------------------------------------------------

                  SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () => _copyAddress(context),
                      icon: const Icon(
                        Icons.copy_outlined,
                      ),
                      label: const Text(
                        'COPY MINT ADDRESS',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: tokenAccentColor,
                        foregroundColor: tokenBackgroundColor,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ------------------------------------------------
                  // SOLSCAN
                  // ------------------------------------------------

                  SizedBox(
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: () => _openSolscan(context),
                      icon: const Icon(
                        Icons.open_in_new,
                      ),
                      label: const Text(
                        'VIEW ON SOLSCAN',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: tokenPinkColor,
                        side: BorderSide(
                          color: tokenPinkColor.withValues(
                            alpha: 0.55,
                          ),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ==================================================
            // STELLA TOKEN CARD
            // ==================================================

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: tokenCardColor,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: tokenPinkColor.withValues(
                    alpha: 0.18,
                  ),
                ),
              ),
              child: Column(
                children: [
                  const StelluriiniLogo(
                    size: 72,
                  ),

                  const SizedBox(height: 14),

                  const Text(
                    '🐱 Stella & STL',
                    style: TextStyle(
                      color: tokenPinkColor,
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Community • Curiosity • Solana',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ==================================================
            // IMPORTANT INFORMATION
            // ==================================================

            _TokenCard(
              title: 'Important Information',
              icon: Icons.info_outline,
              accent: tokenGoldColor,
              child: const Text(
                'STL shown inside the Stelluriini application '
                'currently represents virtual in-app points. '
                'These points are not automatically connected '
                'to a withdrawable cryptocurrency balance.',
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 15,
                  height: 1.6,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ==================================================
            // FOOTER
            // ==================================================

            const Text(
              '🐾 STELLURIINI • STL • SOLANA 🐾',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: tokenPinkColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              '17 602 539 062 STL',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: tokenGoldColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// TOKEN CARD
// ============================================================

class _TokenCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final Color accent;

  const _TokenCard({
    required this.title,
    required this.icon,
    required this.child,
    this.accent = tokenAccentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: tokenCardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: accent.withValues(
            alpha: 0.16,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accent.withValues(
                    alpha: 0.10,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: accent,
                  size: 25,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          child,
        ],
      ),
    );
  }
}

// ============================================================
// TOKEN INFO ROW
// ============================================================

class _TokenInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _TokenInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          color: tokenAccentColor,
          size: 22,
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 15,
            ),
          ),
        ),

        const SizedBox(width: 12),

        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}