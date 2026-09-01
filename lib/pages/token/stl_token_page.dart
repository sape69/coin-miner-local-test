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

            Card(
              color: tokenCardColor,
              child: Padding(
                padding: const EdgeInsets.all(24),
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

                    const SizedBox(height: 8),

                    Text(
                      'Solana Token 🐱',
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
            ),

            const SizedBox(height: 16),

            // ==================================================
            // TOKEN INFORMATION
            // ==================================================

            Card(
              color: tokenCardColor,
              child: const Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.monetization_on_outlined,
                          color: tokenAccentColor,
                          size: 30,
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Token Information',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 20),

                    _TokenInfoRow(
                      icon: Icons.label_outline,
                      label: 'Name',
                      value: 'Stelluriini',
                    ),

                    SizedBox(height: 14),

                    _TokenInfoRow(
                      icon: Icons.short_text,
                      label: 'Symbol',
                      value: 'STL',
                    ),

                    SizedBox(height: 14),

                    _TokenInfoRow(
                      icon: Icons.account_tree_outlined,
                      label: 'Blockchain',
                      value: 'Solana',
                    ),

                    SizedBox(height: 14),

                    _TokenInfoRow(
                      icon: Icons.numbers,
                      label: 'Decimals',
                      value: '9',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ==================================================
            // SUPPLY
            // ==================================================

            Card(
              color: tokenCardColor,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          color: tokenAccentColor,
                          size: 30,
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Token Supply',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 22,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(
                          alpha: 0.20,
                        ),
                        borderRadius:
                            BorderRadius.circular(18),
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

                          SizedBox(height: 12),

                          Text(
                            '17 602 539 062',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              color: tokenAccentColor,
                            ),
                          ),

                          SizedBox(height: 6),

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

                    const SizedBox(height: 16),

                    Text(
                      'Stelluriini has a fixed total supply of '
                      '17 602 539 062 STL tokens.',
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
            ),

            const SizedBox(height: 16),

            // ==================================================
            // TOKEN ADDRESS
            // ==================================================

            Card(
              color: tokenCardColor,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.vpn_key_outlined,
                          color: tokenAccentColor,
                          size: 30,
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Token Address',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    Text(
                      'The official STL token address will appear here.',
                      style: TextStyle(
                        color: Colors.white.withValues(
                          alpha: 0.65,
                        ),
                        fontSize: 15,
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 16),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(
                          alpha: 0.20,
                        ),
                        borderRadius:
                            BorderRadius.circular(14),
                      ),
                      child: const Text(
                        'COMING SOON',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.orangeAccent,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ==================================================
            // IMPORTANT INFORMATION
            // ==================================================

            Card(
              color: tokenCardColor,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: tokenAccentColor,
                          size: 30,
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Important Information',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    Text(
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
                  ],
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