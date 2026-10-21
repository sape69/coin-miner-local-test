import 'package:flutter/material.dart';

class HomeGreeting extends StatelessWidget {
  final String username;
  final String greeting;
  final Color accentColor;
  final Color primaryTextColor;
  final Color secondaryTextColor;

  const HomeGreeting({
    super.key,
    required this.username,
    required this.greeting,
    required this.accentColor,
    required this.primaryTextColor,
    required this.secondaryTextColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            greeting,
            style: TextStyle(
              color: secondaryTextColor,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            username.isEmpty ? 'Stelluriini' : username,
            style: TextStyle(
              color: primaryTextColor,
              fontSize: 24,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '🐱',
            style: TextStyle(
              color: accentColor,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }
}