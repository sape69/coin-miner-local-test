import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../widgets/cat_avatar.dart';

const Color tokenBackgroundColor = Color(0xFF0B1112);
const Color tokenCardColor = Color(0xFF151B1C);
const Color tokenAccentColor = Color(0xFF35D0A0);

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
          content: Text(
            'Mint address copied! 🐱',
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
      final opened = await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );

      if (!opened && context.mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text(
                'Could not open Solscan.',
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
            content: Text(
              'Could not open Solscan.',
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

      appBar: AppBar(
        title: const Text(
          'STL Token',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [

            // ==================================================
            // HEADER
            // ==================================================

            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: tokenCardColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: tokenAccentColor.withValues(
                    alpha: 0.20,
                  ),
                ),
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
                      color: tokenAccentColor,
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

                  const SizedBox(height: 10),

                  Text(
                    '🐱 Solana Community Token',
                    style: TextStyle(
                      color: Colors.white.withValues(
                        alpha: 0.60,
                      ),
                      fontSize: 15,
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
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 24,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(
                        alpha: 0.22,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: tokenAccentColor.withValues(
                          alpha: 0.25,
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
                            color: tokenAccentColor,
                          ),
                        ),

                        SizedBox(height: 8),

                        Text(
                          'STL',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 3,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  Text(
                    'Stelluriini has a fixed total supply of '
                    '$totalSupply STL tokens.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(
                        alpha: 0.65,
                      ),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'This is the official public mint address '
                    'for the Stelluriini token.',
                    style: TextStyle(
                      color: Colors.white.withValues(
                        alpha: 0.65,
                      ),
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
                    ),
                    child: SelectableText(
                      mintAddress,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: tokenAccentColor,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

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
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

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
                        foregroundColor: tokenAccentColor,
                        side: BorderSide(
                          color: tokenAccentColor.withValues(
                            alpha: 0.60,
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
            // IMPORTANT INFORMATION
            // ==================================================

            _TokenCard(
              title: 'Important Information',
              icon: Icons.info_outline,
              child: Text(
                'STL shown inside the Stelluriini application '
                'currently represents virtual in-app points. '
                'These points are not automatically connected '
                'to a withdrawable cryptocurrency balance.',
                style: TextStyle(
                  color: Colors.white.withValues(
                    alpha: 0.60,
                  ),
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
            ),

            const SizedBox(height: 30),
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

  const _TokenCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: tokenCardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: tokenAccentColor.withValues(
            alpha: 0.15,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: tokenAccentColor,
                size: 30,
              ),

              const SizedBox(width: 10),

              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
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
            style: TextStyle(
              color: Colors.white.withValues(
                alpha: 0.60,
              ),
              fontSize: 15,
            ),
          ),
        ),

        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}