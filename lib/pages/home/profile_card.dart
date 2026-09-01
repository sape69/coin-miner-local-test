import 'package:flutter/material.dart';

import '../../widgets/cat_avatar.dart';

const Color profileAccentColor = Color(0xFF35D0A0);
const Color profileCardColor = Color(0xFF151B1C);

class ProfileCard extends StatelessWidget {
  final String title;

  const ProfileCard({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: profileCardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: profileAccentColor.withValues(alpha: 0.30),
        ),
        boxShadow: [
          BoxShadow(
            color: profileAccentColor.withValues(alpha: 0.08),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          // 🐾 TOP PAWS
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(
                Icons.pets,
                color: profileAccentColor.withValues(alpha: 0.35),
                size: 28,
              ),
              Icon(
                Icons.pets,
                color: profileAccentColor.withValues(alpha: 0.35),
                size: 28,
              ),
            ],
          ),

          const SizedBox(height: 8),

          // 🐱 STELLA IMAGE
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: profileAccentColor,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: profileAccentColor.withValues(alpha: 0.25),
                  blurRadius: 18,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const CatAvatar(
              size: 125,
            ),
          ),

          const SizedBox(height: 16),

          // 🐱 NAME
          Text(
            title,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 8),

          // STELLA LABEL
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: profileAccentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Text(
              '🐾 STELLURIINI CAT 🐾',
              style: TextStyle(
                color: profileAccentColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ),

          const SizedBox(height: 14),

          Text(
            'Earn STL treats with Stella! 🐱',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.60),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}