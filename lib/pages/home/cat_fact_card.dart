import 'package:flutter/material.dart';

const Color catFactAccentColor = Color(0xFF35D0A0);

class CatFactCard extends StatelessWidget {
  final String title;
  final String fact;

  const CatFactCard({
    super.key,
    required this.title,
    required this.fact,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 14),

            const Icon(
              Icons.pets,
              size: 45,
              color: catFactAccentColor,
            ),

            const SizedBox(height: 14),

            Text(
              fact,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white70,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}