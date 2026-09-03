import 'package:flutter/material.dart';

const Color backgroundColor = Color(0xFF0B1112);
const Color cardColor = Color(0xFF151B1C);
const Color balanceAccentColor = Color(0xFF35D0A0);

class BalanceCard extends StatelessWidget {
  final double miningBalance;
  final double unclaimedMining;
  final double hashRate;
  final double miningPerHour;

  final String title;
  final String subtitle;

  final bool claimLoading;
  final VoidCallback? onClaimPressed;

  const BalanceCard({
    super.key,
    required this.miningBalance,
    required this.unclaimedMining,
    required this.hashRate,
    required this.miningPerHour,
    required this.title,
    required this.subtitle,
    required this.claimLoading,
    required this.onClaimPressed,
  });

  double get totalBalance =>
      miningBalance + unclaimedMining;

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

          // ================================================
          // HEADER
          // ================================================

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

              Text(
                title.toUpperCase(),
                style: TextStyle(
                  color: Colors.white.withValues(
                    alpha: 0.70,
                  ),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
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

          // ================================================
          // MINING ICON
          // ================================================

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
                  fontSize: 38,
                ),
              ),
            ),
          ),

          const SizedBox(height: 18),

          // ================================================
          // TOTAL BALANCE
          // ================================================

          Text(
            totalBalance.toStringAsFixed(2),
            style: const TextStyle(
              fontSize: 52,
              height: 1,
              fontWeight: FontWeight.bold,
              color: balanceAccentColor,
              letterSpacing: 1,
            ),
          ),

          const SizedBox(height: 8),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: balanceAccentColor.withValues(
                alpha: 0.14,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: balanceAccentColor.withValues(
                  alpha: 0.25,
                ),
              ),
            ),
            child: const Text(
              'STL MINING',
              style: TextStyle(
                color: balanceAccentColor,
                fontSize: 15,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ),

          const SizedBox(height: 22),

          // ================================================
          // DIVIDER
          // ================================================

          Container(
            width: double.infinity,
            height: 1,
            color: Colors.white.withValues(
              alpha: 0.08,
            ),
          ),

          const SizedBox(height: 18),

          // ================================================
          // HASH RATE
          // ================================================

          _StatRow(
            icon: '⚡',
            label: 'Hash Rate',
            value: hashRate.toStringAsFixed(1),
          ),

          const SizedBox(height: 12),

          // ================================================
          // MINING SPEED
          // ================================================

          _StatRow(
            icon: '⛏️',
            label: 'Mining / hour',
            value:
                '${miningPerHour.toStringAsFixed(2)} STL',
          ),

          const SizedBox(height: 12),

          // ================================================
          // UNCLAIMED
          // ================================================

          _StatRow(
            icon: '💰',
            label: 'Ready to claim',
            value:
                '${unclaimedMining.toStringAsFixed(2)} STL',
          ),

          const SizedBox(height: 22),

          // ================================================
          // CLAIM BUTTON
          // ================================================

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed:
                  claimLoading
                      ? null
                      : onClaimPressed,

              icon:
                  claimLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        )
                      : const Icon(
                          Icons.account_balance_wallet,
                        ),

              label: Text(
                claimLoading
                    ? 'CLAIMING...'
                    : 'CLAIM MINING',
              ),

              style: ElevatedButton.styleFrom(
                backgroundColor:
                    balanceAccentColor,
                foregroundColor:
                    Colors.black,

                padding:
                    const EdgeInsets.symmetric(
                  vertical: 15,
                ),

                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(16),
                ),

                textStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ================================================
          // SUBTITLE
          // ================================================

          Row(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.info_outline,
                color: Colors.white54,
                size: 17,
              ),

              const SizedBox(width: 7),

              Flexible(
                child: Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(
                      alpha: 0.55,
                    ),
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Text(
            'Stella is mining treasures 🐱⛏️✨',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: balanceAccentColor.withValues(
                alpha: 0.75,
              ),
              fontSize: 13,
              fontWeight: FontWeight.w600,
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
  final String icon;
  final String label;
  final String value;

  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [

        Text(
          icon,
          style: const TextStyle(
            fontSize: 20,
          ),
        ),

        const SizedBox(width: 12),

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

        Text(
          value,
          style: const TextStyle(
            color: balanceAccentColor,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}