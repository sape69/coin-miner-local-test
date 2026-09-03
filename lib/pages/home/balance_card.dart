import 'package:flutter/material.dart';

// ============================================================
// COLORS
// ============================================================

const Color cardColor = Color(0xFF151B1C);
const Color balanceAccentColor = Color(0xFF35D0A0);

// ============================================================
// BALANCE CARD
// ============================================================

class BalanceCard extends StatelessWidget {
  final String title;

  /// Kokonaismäärä:
  /// Mining Balance + Unclaimed Mining
  final double estimatedTotal;

  /// Firestoreen jo tallennettu louhittu määrä.
  final double miningBalance;

  /// Tällä hetkellä louhittu mutta vielä claimamatta oleva määrä.
  final double unclaimedMining;

  /// Käyttäjän nykyinen Hash Rate.
  final double hashRate;

  /// Louhintanopeus tunnissa.
  final double miningPerHour;

  const BalanceCard({
    super.key,
    required this.title,
    required this.estimatedTotal,
    required this.miningBalance,
    required this.unclaimedMining,
    required this.hashRate,
    required this.miningPerHour,
  });

  // ==========================================================
  // NUMBER FORMAT
  // ==========================================================

  String _formatNumber(
    double value, {
    int decimals = 2,
  }) {
    return value.toStringAsFixed(decimals);
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),

      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),

        border: Border.all(
          color: balanceAccentColor.withValues(
            alpha: 0.25,
          ),
        ),

        boxShadow: [
          BoxShadow(
            color: balanceAccentColor.withValues(
              alpha: 0.08,
            ),
            blurRadius: 24,
            spreadRadius: 1,
            offset: const Offset(0, 8),
          ),
        ],
      ),

      child: Column(
        children: [
          // ==================================================
          // HEADER
          // ==================================================

          Row(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              const Text(
                '🐱',
                style: TextStyle(
                  fontSize: 28,
                ),
              ),

              const SizedBox(width: 10),

              Flexible(
                child: Text(
                  title.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(
                      alpha: 0.70,
                    ),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ),

              const SizedBox(width: 10),

              const Text(
                '⛏️',
                style: TextStyle(
                  fontSize: 24,
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),

          // ==================================================
          // MINING ICON
          // ==================================================

          Container(
            width: 86,
            height: 86,

            decoration: BoxDecoration(
              shape: BoxShape.circle,

              color: balanceAccentColor.withValues(
                alpha: 0.15,
              ),

              border: Border.all(
                color: balanceAccentColor.withValues(
                  alpha: 0.40,
                ),
                width: 2,
              ),

              boxShadow: [
                BoxShadow(
                  color: balanceAccentColor.withValues(
                    alpha: 0.20,
                  ),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),

            child: const Center(
              child: Text(
                '⛏️',
                style: TextStyle(
                  fontSize: 40,
                ),
              ),
            ),
          ),

          const SizedBox(height: 18),

          // ==================================================
          // ESTIMATED TOTAL
          // ==================================================

          Text(
            _formatNumber(
              estimatedTotal,
              decimals: 2,
            ),

            textAlign: TextAlign.center,

            style: const TextStyle(
              fontSize: 48,
              height: 1,
              fontWeight: FontWeight.bold,
              color: balanceAccentColor,
              letterSpacing: 1,
            ),
          ),

          const SizedBox(height: 8),

          // ==================================================
          // ESTIMATED STL LABEL
          // ==================================================

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 7,
            ),

            decoration: BoxDecoration(
              color: balanceAccentColor.withValues(
                alpha: 0.14,
              ),

              borderRadius:
                  BorderRadius.circular(20),

              border: Border.all(
                color: balanceAccentColor.withValues(
                  alpha: 0.25,
                ),
              ),
            ),

            child: const Text(
              'ESTIMATED STL',
              style: TextStyle(
                color: balanceAccentColor,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ==================================================
          // DIVIDER
          // ==================================================

          Container(
            width: double.infinity,
            height: 1,
            color: Colors.white.withValues(
              alpha: 0.08,
            ),
          ),

          const SizedBox(height: 18),

          // ==================================================
          // MINING BALANCE
          // ==================================================

          _StatRow(
            icon: Icons.account_balance_wallet_outlined,
            label: 'Mining Balance',
            value:
                '${_formatNumber(miningBalance)} STL',
          ),

          const SizedBox(height: 14),

          // ==================================================
          // UNCLAIMED MINING
          // ==================================================

          _StatRow(
            icon: Icons.inventory_2_outlined,
            label: 'Unclaimed Mining',
            value:
                '${_formatNumber(unclaimedMining)} STL',
            highlight: true,
          ),

          const SizedBox(height: 14),

          // ==================================================
          // HASH RATE
          // ==================================================

          _StatRow(
            icon: Icons.bolt,
            label: 'Hash Rate',
            value:
                '${_formatNumber(hashRate)} HR',
          ),

          const SizedBox(height: 14),

          // ==================================================
          // MINING SPEED
          // ==================================================

          _StatRow(
            icon: Icons.trending_up,
            label: 'Mining Speed',
            value:
                '${_formatNumber(miningPerHour)} STL/h',
          ),

          const SizedBox(height: 20),

          // ==================================================
          // MINING ACTIVE STATUS
          // ==================================================

          Container(
            width: double.infinity,

            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),

            decoration: BoxDecoration(
              color: balanceAccentColor.withValues(
                alpha: 0.08,
              ),

              borderRadius:
                  BorderRadius.circular(16),

              border: Border.all(
                color: balanceAccentColor.withValues(
                  alpha: 0.18,
                ),
              ),
            ),

            child: const Row(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.circle,
                  color: balanceAccentColor,
                  size: 10,
                ),

                SizedBox(width: 8),

                Flexible(
                  child: Text(
                    'STELLA MINING ACTIVE 🐱⛏️',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: balanceAccentColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// STAT ROW
// ============================================================

class _StatRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool highlight;

  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final valueColor =
        highlight
            ? balanceAccentColor
            : Colors.white;

    return Row(
      children: [
        // ====================================================
        // ICON
        // ====================================================

        Container(
          width: 38,
          height: 38,

          decoration: BoxDecoration(
            color: balanceAccentColor.withValues(
              alpha: 0.10,
            ),

            borderRadius:
                BorderRadius.circular(12),
          ),

          child: Icon(
            icon,
            color: balanceAccentColor,
            size: 20,
          ),
        ),

        const SizedBox(width: 12),

        // ====================================================
        // LABEL
        // ====================================================

        Expanded(
          child: Text(
            label,

            style: TextStyle(
              color: Colors.white.withValues(
                alpha: 0.65,
              ),
              fontSize: 14,
            ),
          ),
        ),

        const SizedBox(width: 8),

        // ====================================================
        // VALUE
        // ====================================================

        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,

            style: TextStyle(
              color: valueColor,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}