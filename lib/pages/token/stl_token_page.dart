import 'package:flutter/material.dart';

import '../../widgets/cat_avatar.dart';

const Color tokenBackgroundColor = Color(0xFF0B1112);
const Color tokenCardColor = Color(0xFF151B1C);
const Color tokenAccentColor = Color(0xFF35D0A0);

class StlTokenPage extends StatelessWidget {
  const StlTokenPage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: tokenBackgroundColor,

      appBar: AppBar(
        backgroundColor: tokenBackgroundColor,
        elevation: 0,
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
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 5,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: tokenAccentColor.withValues(
                        alpha: 0.12,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      '🐱 SOLANA TOKEN',
                      style: TextStyle(
                        color: tokenAccentColor,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
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

            _SectionCard(
              title: 'Token Information',
              icon: Icons.monetization_on_outlined,
              child: const Column(
                children: [
                  _TokenInfoRow(
                    icon: Icons.label_outline,
                    label: 'Name',
                    value: 'Stelluriini',
                  ),

                  SizedBox(height: 16),

                  _TokenInfoRow(
                    icon: Icons.short_text,
                    label: 'Symbol',
                    value: 'STL',
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
                    value: '9',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ==================================================
            // TOKEN SUPPLY
            // ==================================================

            _SectionCard(
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
                      borderRadius: BorderRadius.circular(20),
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
                          '17 602 539 062',
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
                            letterSpacing: 4,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: tokenAccentColor.withValues(
                        alpha: 0.08,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.lock_outline,
                          color: tokenAccentColor,
                        ),

                        SizedBox(width: 12),

                        Expanded(
                          child: Text(
                            'Fixed total supply: '
                            '17 602 539 062 STL',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ==================================================
            // TOKENOMICS
            // ==================================================

            _SectionCard(
              title: 'Tokenomics',
              icon: Icons.pie_chart_outline,
              child: Column(
                children: [
                  _TokenomicsRow(
                    icon: Icons.inventory_2_outlined,
                    title: 'Total Supply',
                    value: '17 602 539 062 STL',
                  ),

                  const SizedBox(height: 16),

                  _TokenomicsRow(
                    icon: Icons.lock_outline,
                    title: 'Supply Type',
                    value: 'Fixed',
                  ),

                  const SizedBox(height: 16),

                  _TokenomicsRow(
                    icon: Icons.account_tree_outlined,
                    title: 'Network',
                    value: 'Solana',
                  ),

                  const SizedBox(height: 16),

                  _TokenomicsRow(
                    icon: Icons.numbers,
                    title: 'Decimals',
                    value: '9',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ==================================================
            // TOKEN ADDRESS
            // ==================================================

            _SectionCard(
              title: 'Token Address',
              icon: Icons.vpn_key_outlined,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'The official STL token mint address will '
                    'appear here when it is available.',
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
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(
                        alpha: 0.20,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.orangeAccent.withValues(
                          alpha: 0.30,
                        ),
                      ),
                    ),
                    child: const Column(
                      children: [
                        Icon(
                          Icons.hourglass_top,
                          color: Colors.orangeAccent,
                          size: 28,
                        ),

                        SizedBox(height: 10),

                        Text(
                          'COMING SOON',
                          style: TextStyle(
                            color: Colors.orangeAccent,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ==================================================
            // IMPORTANT INFORMATION
            // ==================================================

            _SectionCard(
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
// SECTION CARD
// ============================================================

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
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
            alpha: 0.12,
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
                size: 28,
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

// ============================================================
// TOKENOMICS ROW
// ============================================================

class _TokenomicsRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _TokenomicsRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withValues(
          alpha: 0.15,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: tokenAccentColor,
            size: 24,
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: Colors.white.withValues(
                  alpha: 0.65,
                ),
                fontSize: 14,
              ),
            ),
          ),

          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}