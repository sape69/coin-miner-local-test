import 'package:flutter/material.dart';

class MiningStatusSection extends StatelessWidget {
  final bool miningActive;
  final int remainingMs;
  final int durationMs;
  final double hashRate;
  final double unclaimedMining;
  final double estimatedTotal;

  final Color cardColor;
  final Color accentColor;
  final Color primaryTextColor;
  final Color secondaryTextColor;

  const MiningStatusSection({
    super.key,
    required this.miningActive,
    required this.remainingMs,
    required this.durationMs,
    required this.hashRate,
    required this.unclaimedMining,
    required this.estimatedTotal,
    required this.cardColor,
    required this.accentColor,
    required this.primaryTextColor,
    required this.secondaryTextColor,
  });

  double get progress {
    if (durationMs <= 0) {
      return 0;
    }

    final double value =
        1 - (remainingMs / durationMs);

    return value.clamp(0.0, 1.0);
  }

  String _formatDuration(int milliseconds) {
    if (milliseconds <= 0) {
      return '00:00:00';
    }

    final Duration duration =
        Duration(milliseconds: milliseconds);

    final int hours = duration.inHours;
    final int minutes =
        duration.inMinutes.remainder(60);
    final int seconds =
        duration.inSeconds.remainder(60);

    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  String _formatNumber(double value) {
    if (!value.isFinite) {
      return '0.0000';
    }

    return value.toStringAsFixed(4);
  }

  @override
  Widget build(BuildContext context) {
    final String statusText = miningActive
        ? 'MINING ACTIVE'
        : 'MINING INACTIVE';

    final IconData statusIcon = miningActive
        ? Icons.bolt_rounded
        : Icons.pause_circle_outline_rounded;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: accentColor.withValues(
            alpha: 0.18,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: accentColor.withValues(
                    alpha: 0.12,
                  ),
                  borderRadius:
                      BorderRadius.circular(13),
                ),
                child: Icon(
                  statusIcon,
                  color: accentColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusText,
                      style: TextStyle(
                        color: primaryTextColor,
                        fontSize: 16,
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      miningActive
                          ? _formatDuration(
                              remainingMs,
                            )
                          : 'Ready to mine',
                      style: TextStyle(
                        color:
                            secondaryTextColor,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${_formatNumber(hashRate)} H/s',
                style: TextStyle(
                  color: accentColor,
                  fontSize: 13,
                  fontWeight:
                      FontWeight.w700,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          ClipRRect(
            borderRadius:
                BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: miningActive
                  ? progress
                  : 0,
              minHeight: 8,
              backgroundColor:
                  primaryTextColor.withValues(
                alpha: 0.08,
              ),
              valueColor:
                  AlwaysStoppedAnimation<Color>(
                accentColor,
              ),
            ),
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _StatItem(
                  label: 'Unclaimed',
                  value:
                      _formatNumber(
                    unclaimedMining,
                  ),
                  primaryTextColor:
                      primaryTextColor,
                  secondaryTextColor:
                      secondaryTextColor,
                  accentColor: accentColor,
                ),
              ),
              Expanded(
                child: _StatItem(
                  label: 'Estimated total',
                  value:
                      _formatNumber(
                    estimatedTotal,
                  ),
                  primaryTextColor:
                      primaryTextColor,
                  secondaryTextColor:
                      secondaryTextColor,
                  accentColor: accentColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color primaryTextColor;
  final Color secondaryTextColor;
  final Color accentColor;

  const _StatItem({
    required this.label,
    required this.value,
    required this.primaryTextColor,
    required this.secondaryTextColor,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: secondaryTextColor,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            color: primaryTextColor,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}