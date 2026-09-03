import 'package:flutter/material.dart';

// ============================================================
// COLORS
// ============================================================

const Color miningCardColor = Color(0xFF151B1C);
const Color miningAccentColor = Color(0xFF35D0A0);
const Color miningBackgroundColor = Color(0xFF0B1112);

// ============================================================
// MINING CLAIM CARD
// ============================================================

class MiningClaimCard extends StatelessWidget {
  final double unclaimedMining;
  final double miningBalance;
  final double hashRate;
  final double miningPerHour;

  final bool loading;
  final VoidCallback? onPressed;

  const MiningClaimCard({
    super.key,
    required this.unclaimedMining,
    required this.miningBalance,
    required this.hashRate,
    required this.miningPerHour,
    required this.loading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final hasMining = unclaimedMining > 0.000001;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color: miningCardColor,
        borderRadius: BorderRadius.circular(24),

        border: Border.all(
          color: miningAccentColor.withValues(
            alpha: 0.25,
          ),
        ),

        boxShadow: [
          BoxShadow(
            color: miningAccentColor.withValues(
              alpha: 0.06,
            ),
            blurRadius: 20,
            spreadRadius: 1,
            offset: const Offset(0, 8),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [

          // ==================================================
          // HEADER
          // ==================================================

          Row(
            children: [

              Container(
                width: 58,
                height: 58,

                decoration: BoxDecoration(
                  color: miningAccentColor.withValues(
                    alpha: 0.14,
                  ),

                  borderRadius: BorderRadius.circular(18),

                  border: Border.all(
                    color: miningAccentColor.withValues(
                      alpha: 0.30,
                    ),
                  ),
                ),

                child: const Center(
                  child: Text(
                    '⛏️',
                    style: TextStyle(
                      fontSize: 30,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [

                    const Text(
                      'STELLA MINING',

                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      hasMining
                          ? 'Mining rewards are ready 🐱'
                          : 'Stella is mining... ⛏️🐱',

                      style: TextStyle(
                        color: Colors.white.withValues(
                          alpha: 0.55,
                        ),

                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              // ==============================================
              // LIVE BADGE
              // ==============================================

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),

                decoration: BoxDecoration(
                  color: miningAccentColor.withValues(
                    alpha: 0.14,
                  ),

                  borderRadius:
                      BorderRadius.circular(20),

                  border: Border.all(
                    color: miningAccentColor.withValues(
                      alpha: 0.25,
                    ),
                  ),
                ),

                child: const Text(
                  '● LIVE',

                  style: TextStyle(
                    color: miningAccentColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),

          // ==================================================
          // UNCLAIMED MINING
          // ==================================================

          Container(
            padding: const EdgeInsets.all(18),

            decoration: BoxDecoration(
              color: Colors.black.withValues(
                alpha: 0.18,
              ),

              borderRadius: BorderRadius.circular(20),

              border: Border.all(
                color: miningAccentColor.withValues(
                  alpha: 0.12,
                ),
              ),
            ),

            child: Column(
              children: [

                Text(
                  'UNCLAIMED MINING',

                  style: TextStyle(
                    color: Colors.white.withValues(
                      alpha: 0.50,
                    ),

                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  '${unclaimedMining.toStringAsFixed(4)} STL',

                  style: const TextStyle(
                    color: miningAccentColor,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  hasMining
                      ? 'Ready to add to your Mining Balance'
                      : 'Keep mining to collect STL',

                  textAlign: TextAlign.center,

                  style: TextStyle(
                    color: Colors.white.withValues(
                      alpha: 0.42,
                    ),

                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ==================================================
          // MINING STATS
          // ==================================================

          Row(
            children: [

              Expanded(
                child: _StatBox(
                  emoji: '⚡',
                  label: 'HASH RATE',
                  value:
                      hashRate.toStringAsFixed(0),
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: _StatBox(
                  emoji: '📈',
                  label: 'PER HOUR',
                  value:
                      '${miningPerHour.toStringAsFixed(2)} STL',
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ==================================================
          // CLAIM BUTTON
          // ==================================================

          SizedBox(
            height: 62,

            child: Material(
              color: Colors.transparent,

              child: InkWell(
                onTap:
                    loading
                        ? null
                        : onPressed,

                borderRadius:
                    BorderRadius.circular(18),

                child: Ink(
                  decoration: BoxDecoration(
                    color: loading
                        ? Colors.grey.withValues(
                            alpha: 0.18,
                          )
                        : miningAccentColor,

                    borderRadius:
                        BorderRadius.circular(18),

                    boxShadow: loading
                        ? []
                        : [
                            BoxShadow(
                              color: miningAccentColor.withValues(
                                alpha: 0.28,
                              ),
                              blurRadius: 18,
                              offset: const Offset(0, 7),
                            ),
                          ],
                  ),

                  child: Center(
                    child: loading
                        ? const SizedBox(
                            width: 26,
                            height: 26,
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 3,
                              color: miningBackgroundColor,
                            ),
                          )
                        : Row(
                            mainAxisAlignment:
                                MainAxisAlignment.center,

                            children: [

                              const Icon(
                                Icons.download_rounded,
                                color: miningBackgroundColor,
                              ),

                              const SizedBox(width: 10),

                              Text(
                                hasMining
                                    ? 'CLAIM MINING REWARDS'
                                    : 'START STELLA MINING',

                                style: const TextStyle(
                                  color:
                                      miningBackgroundColor,

                                  fontSize: 14,

                                  fontWeight:
                                      FontWeight.bold,

                                  letterSpacing: 0.8,
                                ),
                              ),

                              const SizedBox(width: 10),

                              const Text(
                                '🐱',
                                style: TextStyle(
                                  fontSize: 22,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 14),

          // ==================================================
          // INFO
          // ==================================================

          Center(
            child: Text(
              'Mining Balance: ${miningBalance.toStringAsFixed(2)} STL',

              style: TextStyle(
                color: Colors.white.withValues(
                  alpha: 0.40,
                ),

                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// STAT BOX
// ============================================================

class _StatBox extends StatelessWidget {
  final String emoji;
  final String label;
  final String value;

  const _StatBox({
    required this.emoji,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 14,
      ),

      decoration: BoxDecoration(
        color: Colors.white.withValues(
          alpha: 0.035,
        ),

        borderRadius: BorderRadius.circular(16),

        border: Border.all(
          color: Colors.white.withValues(
            alpha: 0.05,
          ),
        ),
      ),

      child: Column(
        children: [

          Text(
            emoji,
            style: const TextStyle(
              fontSize: 20,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            label,

            textAlign: TextAlign.center,

            style: TextStyle(
              color: Colors.white.withValues(
                alpha: 0.42,
              ),

              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            value,

            textAlign: TextAlign.center,

            maxLines: 1,

            overflow: TextOverflow.ellipsis,

            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}