import 'package:flutter/material.dart';

class HomeGreeting extends StatelessWidget {
  final String greeting;
  final String subtitle;
  final Color primaryTextColor;
  final Color secondaryTextColor;

  const HomeGreeting({
    super.key,
    required this.greeting,
    required this.subtitle,
    required this.primaryTextColor,
    required this.secondaryTextColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 22,
        vertical: 6,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            greeting,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: primaryTextColor,
              fontSize: 23,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: secondaryTextColor,
              fontSize: 14,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}