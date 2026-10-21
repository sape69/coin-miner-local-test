import 'package:flutter/material.dart';

class MiningStatsSection extends StatelessWidget {
  final double hashRate;
  final double effectiveHashRate;
  final double unclaimedMining;
  final double estimatedTotal;
  final int streak;

  final String hashRateLabel;
  final String effectiveHashRateLabel;
  final String unclaimedLabel;
  final String estimatedTotalLabel;
  final String streakLabel;

  const MiningStatsSection({
    super.key,
    required this.hashRate,
    required this.effectiveHashRate,
    required this.unclaimedMining,
    required this.estimatedTotal,
    required this.streak,
    required this.hashRateLabel,
    required this.effectiveHashRateLabel,
    required this.unclaimedLabel,
    required this.estimatedTotalLabel,
    required this.streakLabel,
  });

  static const Color cardColor = Color(0xFF21113B);
  static const Color accentColor = Color(0xFFB58CFF);
  static const Color pinkColor = Color(0xFFFFB7E8);
  static const Color goldColor = Color(0xFFFFD166);
  static const Color primaryTextColor = Color(0xFFF8F4FF);
  static const Color secondaryTextColor = Color(0xFFBDB4D1);

  String _formatNumber(double value) {
    if (!value.isFinite) {
      return '0.0000';
    }

    return value.toStringAsFixed(4);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.insights_rounded,
                  color: accentColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'STELLURIINI',
                  style: const TextStyle(
                    color: primaryTextColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (streak > 0)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '🔥',
                      style: TextStyle(fontSize: 17),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$streak',
                      style: const TextStyle(
                        color: goldColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  icon: Icons.speed_rounded,
                  label: hashRateLabel,
                  value: '${_formatNumber(hashRate)} H/s',
                  iconColor: accentColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatItem(
                  icon: Icons.bolt_rounded,
                  label: effectiveHashRateLabel,
                  value: '${_formatNumber(effectiveHashRate)} H/s',
                  iconColor: goldColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  icon: Icons.pending_actions_rounded,
                  label: unclaimedLabel,
                  value: _formatNumber(unclaimedMining),
                  iconColor: pinkColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatItem(
                  icon: Icons.auto_awesome_rounded,
                  label: estimatedTotalLabel,
                  value: _formatNumber(estimatedTotal),
                  iconColor: accentColor,
                ),
              ),
            ],
          ),
          if (streak > 0) ...[
            const SizedBox(height: 12),
            Text(
              '$streakLabel: $streak',
              style: const TextStyle(
                color: secondaryTextColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
  });

  static const Color primaryTextColor = Color(0xFFF8F4FF);
  static const Color secondaryTextColor = Color(0xFFBDB4D1);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.035),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: iconColor,
            size: 20,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: secondaryTextColor,
              fontSize: 11,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: primaryTextColor,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}