import 'package:flutter/material.dart';

const Color balanceAccentColor = Color(0xFF35D0A0);

class BalanceCard extends StatelessWidget {
  final int stl;
  final String title;
  final String subtitle;

  const BalanceCard({
    super.key,
    required this.stl,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white60,
                letterSpacing: 2,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              '$stl',
              style: const TextStyle(
                fontSize: 56,
                fontWeight: FontWeight.bold,
                color: balanceAccentColor,
              ),
            ),

            const Text(
              'STL',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 3,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}