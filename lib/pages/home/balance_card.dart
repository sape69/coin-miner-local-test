import 'package:flutter/material.dart';

// ============================================================
// 🐱 STELLURIINI / STELLA THEME
// ============================================================

const Color backgroundColor = Color(0xFF120B24);
const Color cardColor = Color(0xFF21113B);

const Color balanceAccentColor = Color(0xFFB58CFF);
const Color balancePinkColor = Color(0xFFFFB7E8);
const Color balanceGoldColor = Color(0xFFFFD166);

// ============================================================
// 🐱 STELLA BALANCE CARD
// ============================================================

class BalanceCard extends StatelessWidget {
  final String title;

  /// Kokonaismäärä tällä hetkellä.
  final double estimatedTotal;

  /// Jo louhittu ja tallennettu määrä.
  final double miningBalance;

  /// Vielä lunastamaton louhinta.
  final double unclaimedMining;

  /// Nykyinen Hash Rate.
  final double hashRate;

  /// Louhinta tunnissa.
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
  // 🔢 NUMBER FORMAT
  // ==========================================================

  String _formatNumber(double value) {
    final safeValue =
        value.isFinite ? value : 0.0;

    if (safeValue >= 1000000) {
      return safeValue.toStringAsFixed(0);
    }

    if (safeValue >= 1000) {
      return safeValue.toStringAsFixed(1);
    }

    return safeValue.toStringAsFixed(2);
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    final bool hasUnclaimed =
        unclaimedMining > 0;

    final bool hasMining =
        miningPerHour > 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius:
            BorderRadius.circular(24),
        border: Border.all(
          color:
              balanceAccentColor.withValues(
            alpha: 0.32,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color:
                balanceAccentColor.withValues(
              alpha: 0.10,
            ),
            blurRadius: 24,
            spreadRadius: 1,
            offset:
                const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // ==================================================
          // 🐱 HEADER
          // ==================================================

          Row(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              const Text(
                '🐱',
                style: TextStyle(
                  fontSize: 26,
                ),
              ),

              const SizedBox(
                width: 10,
              ),

              Flexible(
                child: Text(
                  title.toUpperCase(),
                  textAlign:
                      TextAlign.center,
                  overflow:
                      TextOverflow.ellipsis,
                  style: TextStyle(
                    color:
                        Colors.white.withValues(
                      alpha: 0.82,
                    ),
                    fontSize: 14,
                    fontWeight:
                        FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ),

              const SizedBox(
                width: 10,
              ),

              const Text(
                '⛏️',
                style: TextStyle(
                  fontSize: 24,
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 22,
          ),

          // ==================================================
          // ⛏️ STELLA MINING ICON
          // ==================================================

          Container(
            width: 86,
            height: 86,
            decoration:
                BoxDecoration(
              shape:
                  BoxShape.circle,
              gradient:
                  LinearGradient(
                colors: [
                  balanceAccentColor
                      .withValues(
                    alpha: 0.18,
                  ),
                  balancePinkColor
                      .withValues(
                    alpha: 0.08,
                  ),
                ],
                begin:
                    Alignment.topLeft,
                end:
                    Alignment.bottomRight,
              ),
              border:
                  Border.all(
                color:
                    balancePinkColor
                        .withValues(
                  alpha: 0.42,
                ),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color:
                      balanceAccentColor
                          .withValues(
                    alpha: 0.18,
                  ),
                  blurRadius: 22,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Center(
              child: Text(
                '⛏️',
                style:
                    TextStyle(
                  fontSize: 38,
                ),
              ),
            ),
          ),

          const SizedBox(
            height: 18,
          ),

          // ==================================================
          // 💜 ESTIMATED TOTAL
          // ==================================================

          Text(
            _formatNumber(
              estimatedTotal,
            ),
            textAlign:
                TextAlign.center,
            style:
                const TextStyle(
              fontSize: 46,
              height: 1,
              fontWeight:
                  FontWeight.bold,
              color:
                  balanceAccentColor,
              letterSpacing: 1,
            ),
          ),

          const SizedBox(
            height: 8,
          ),

          // ==================================================
          // 🪙 STL LABEL
          // ==================================================

          Container(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 7,
            ),
            decoration:
                BoxDecoration(
              gradient:
                  LinearGradient(
                colors: [
                  balanceAccentColor
                      .withValues(
                    alpha: 0.14,
                  ),
                  balancePinkColor
                      .withValues(
                    alpha: 0.08,
                  ),
                ],
              ),
              borderRadius:
                  BorderRadius.circular(
                20,
              ),
              border:
                  Border.all(
                color:
                    balancePinkColor
                        .withValues(
                  alpha: 0.30,
                ),
              ),
            ),
            child: const Text(
              'ESTIMATED STL',
              style:
                  TextStyle(
                color:
                    balancePinkColor,
                fontSize: 13,
                fontWeight:
                    FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ),

          const SizedBox(
            height: 22,
          ),

          // ==================================================
          // DIVIDER
          // ==================================================

          Container(
            width: double.infinity,
            height: 1,
            color:
                Colors.white.withValues(
              alpha: 0.08,
            ),
          ),

          const SizedBox(
            height: 18,
          ),

          // ==================================================
          // 💰 MINING BALANCE
          // ==================================================

          _MiningInfoRow(
            icon: Icons
                .account_balance_wallet_outlined,
            label: 'Louhittu saldo',
            value:
                '${_formatNumber(miningBalance)} STL',
          ),

          const SizedBox(
            height: 14,
          ),

          // ==================================================
          // 📦 UNCLAIMED MINING
          // ==================================================

          _MiningInfoRow(
            icon:
                Icons.inventory_2_outlined,
            label:
                'Valmiina louhittavaksi',
            value:
                '${_formatNumber(unclaimedMining)} STL',
            highlight:
                hasUnclaimed,
          ),

          const SizedBox(
            height: 14,
          ),

          // ==================================================
          // ⚡ HASH RATE
          // ==================================================

          _MiningInfoRow(
            icon:
                Icons.bolt_rounded,
            label:
                'Hash Rate',
            value:
                '${_formatNumber(hashRate)} HR',
          ),

          const SizedBox(
            height: 14,
          ),

          // ==================================================
          // 📈 MINING SPEED
          // ==================================================

          _MiningInfoRow(
            icon:
                Icons.trending_up_rounded,
            label:
                'Louhinta nopeus',
            value:
                '${_formatNumber(miningPerHour)} STL / h',
          ),

          const SizedBox(
            height: 22,
          ),

          // ==================================================
          // 🐱 STATUS
          // ==================================================

          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            decoration:
                BoxDecoration(
              color:
                  balanceAccentColor
                      .withValues(
                alpha: 0.08,
              ),
              borderRadius:
                  BorderRadius.circular(
                16,
              ),
              border:
                  Border.all(
                color:
                    balanceAccentColor
                        .withValues(
                  alpha: 0.12,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.circle,
                  size: 10,
                  color:
                      hasMining
                          ? balanceAccentColor
                          : Colors.white
                              .withValues(
                            alpha: 0.35,
                          ),
                ),

                const SizedBox(
                  width: 8,
                ),

                Flexible(
                  child: Text(
                    hasMining
                        ? 'STELLA MINING ACTIVE 🐱⛏️'
                        : 'STELLA MINING READY 🐱',
                    textAlign:
                        TextAlign.center,
                    overflow:
                        TextOverflow.ellipsis,
                    style:
                        TextStyle(
                      color:
                          hasMining
                              ? balanceAccentColor
                              : Colors.white
                                  .withValues(
                                alpha: 0.55,
                              ),
                      fontSize: 12,
                      fontWeight:
                          FontWeight.bold,
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
// 📊 MINING INFO ROW
// ============================================================

class _MiningInfoRow
    extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool highlight;

  const _MiningInfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color valueColor =
        highlight
            ? balancePinkColor
            : Colors.white;

    return Row(
      children: [
        // ------------------------------------------------------
        // ICON
        // ------------------------------------------------------

        Container(
          width: 40,
          height: 40,
          decoration:
              BoxDecoration(
            gradient:
                LinearGradient(
              colors: [
                balanceAccentColor
                    .withValues(
                  alpha: 0.12,
                ),
                balancePinkColor
                    .withValues(
                  alpha: 0.06,
                ),
              ],
            ),
            borderRadius:
                BorderRadius.circular(
              12,
            ),
            border:
                Border.all(
              color:
                  balanceAccentColor
                      .withValues(
                alpha: 0.08,
              ),
            ),
          ),
          child: Icon(
            icon,
            color:
                balanceAccentColor,
            size: 21,
          ),
        ),

        const SizedBox(
          width: 12,
        ),

        // ------------------------------------------------------
        // LABEL
        // ------------------------------------------------------

        Expanded(
          child: Text(
            label,
            maxLines: 2,
            overflow:
                TextOverflow.ellipsis,
            style: TextStyle(
              color:
                  Colors.white.withValues(
                alpha: 0.62,
              ),
              fontSize: 13,
            ),
          ),
        ),

        const SizedBox(
          width: 10,
        ),

        // ------------------------------------------------------
        // VALUE
        // ------------------------------------------------------

        Flexible(
          child: Text(
            value,
            textAlign:
                TextAlign.right,
            maxLines: 2,
            overflow:
                TextOverflow.ellipsis,
            style:
                TextStyle(
              color: valueColor,
              fontSize: 14,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}