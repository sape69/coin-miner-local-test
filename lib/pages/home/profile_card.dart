import 'package:flutter/material.dart';

import '../../widgets/cat_avatar.dart';

// ============================================================
// 🐱 STELLURIINI COLORS
// ============================================================

const Color profileAccentColor = Color(0xFFB58CFF);
const Color profilePinkColor = Color(0xFFFFB7E8);
const Color profileCardColor = Color(0xFF21113B);

// ============================================================
// 🐱 STELLA PROFILE CARD
// ============================================================

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
          color: profileAccentColor.withValues(
            alpha: 0.32,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: profileAccentColor.withValues(
              alpha: 0.10,
            ),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          // ==================================================
          // 🐾 TOP PAWS
          // ==================================================

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(
                Icons.pets,
                color: profilePinkColor.withValues(
                  alpha: 0.45,
                ),
                size: 28,
              ),
              Icon(
                Icons.pets,
                color: profilePinkColor.withValues(
                  alpha: 0.45,
                ),
                size: 28,
              ),
            ],
          ),

          const SizedBox(height: 8),

          // ==================================================
          // 🐱 STELLA IMAGE
          // ==================================================

          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: profilePinkColor,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: profileAccentColor.withValues(
                    alpha: 0.25,
                  ),
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

          // ==================================================
          // 🐱 NAME
          // ==================================================

          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 8),

          // ==================================================
          // 🐾 STELLA LABEL
          // ==================================================

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: profileAccentColor.withValues(
                alpha: 0.12,
              ),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: profilePinkColor.withValues(
                  alpha: 0.18,
                ),
              ),
            ),
            child: const Text(
              '🐾 STELLURIINI CAT 🐾',
              style: TextStyle(
                color: profilePinkColor,
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
              color: Colors.white.withValues(
                alpha: 0.60,
              ),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}