import 'package:flutter/material.dart';

import '../../localization.dart';

class StellaFooter extends StatelessWidget {
  final AppLocalizations localization;

  const StellaFooter({
    super.key,
    required this.localization,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          const Text(
            '🐱💜⛏️',
            style: TextStyle(
              fontSize: 28,
            ),
          ),
          const SizedBox(
            height: 8,
          ),
          Text(
            localization.get(
              'footerTagline',
            ),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF8D7BA8),
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(
            height: 4,
          ),
          Text(
            localization.get(
              'footerToken',
            ),
            style: const TextStyle(
              color: Color(0xFF5F4D70),
              fontSize: 11,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }
}