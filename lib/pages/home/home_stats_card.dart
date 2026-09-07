import 'package:flutter/material.dart';

class HomeStatsCard extends StatelessWidget {
  final String hashRateTitle;
  final String hashRateValue;
  final String totalStlTitle;
  final String totalStlValue;

  static const Color cardColor = Color(0xFF21113B);
  static const Color pinkColor = Color(0xFFFFB7E8);

  const HomeStatsCard({
    super.key,
    required this.hashRateTitle,
    required this.hashRateValue,
    required this.totalStlTitle,
    required this.totalStlValue,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.bolt_rounded,
            title: hashRateTitle,
            value: hashRateValue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.currency_bitcoin_rounded,
            title: totalStlTitle,
            value: totalStlValue,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: pinkColor,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFFBFAEDB),
              fontSize: 10,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}