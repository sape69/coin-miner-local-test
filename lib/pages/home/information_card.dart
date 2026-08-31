import 'package:flutter/material.dart';

const Color informationAccentColor = Color(0xFF35D0A0);

class InformationCard extends StatelessWidget {
  final String title;
  final String solanaTokenText;
  final String companyText;

  const InformationCard({
    super.key,
    required this.title,
    required this.solanaTokenText,
    required this.companyText,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(
              Icons.info_outline,
              size: 38,
              color: informationAccentColor,
            ),

            const SizedBox(height: 10),

            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 19,
              ),
            ),

            const SizedBox(height: 12),

            Text(
              solanaTokenText,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              companyText,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white60,
              ),
            ),
          ],
        ),
      ),
    );
  }
}