import 'package:flutter/material.dart';

import 'mining_progress_card.dart';
import 'stella_mining_days_card.dart';

// ============================================================
// 🐱 STELLURIINI STELLA MINING CARD
// ============================================================

class StellaMiningCard extends StatelessWidget {
  final double unclaimedMining;
  final String miningTitle;
  final String miningSubtitle;
  final String timerText;
  final String timerLabel;
  final Animation<double> catAnimation;

  final String languageCode;

  final bool miningActive;
  final int miningRemainingMs;
  final int miningDurationMs;

  final String miningProgressTitle;
  final String stlPerHourText;
  final String dailyHashRateText;
  final String dailyHashRateDayText;

  final int dailyStreak;

  // ------------------------------------------------------------
  // Mining-painike
  // ------------------------------------------------------------
  // HomePage rakentaa varsinaisen painikkeen ja sen toiminnallisuuden.
  // StellaMiningCard vain sijoittaa sen oikeaan kohtaan käyttöliittymässä.
  final Widget miningButton;

  static const Color backgroundColor = Color(0xFF120B24);
  static const Color cardColor = Color(0xFF21113B);
  static const Color accentColor = Color(0xFFB58CFF);
  static const Color goldColor = Color(0xFFFFD166);
  static const Color secondaryTextColor = Color(0xFFBFAEDB);

  const StellaMiningCard({
    super.key,
    required this.unclaimedMining,
    required this.miningTitle,
    required this.miningSubtitle,
    required this.timerText,
    required this.timerLabel,
    required this.catAnimation,
    required this.languageCode,
    required this.miningActive,
    required this.miningRemainingMs,
    required this.miningDurationMs,
    required this.miningProgressTitle,
    required this.stlPerHourText,
    required this.dailyHashRateText,
    required this.dailyHashRateDayText,
    required this.dailyStreak,
    required this.miningButton,
  });

  String _formatStl(double value) => value.toStringAsFixed(4);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2D174D),
            Color(0xFF1B1033),
          ],
        ),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.40),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x55000000),
            blurRadius: 25,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // ----------------------------------------------------
          // Stella / Mining icon
          // ----------------------------------------------------
          AnimatedBuilder(
            animation: catAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, -catAnimation.value),
                child: child,
              );
            },
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accentColor.withValues(alpha: 0.15),
                border: Border.all(
                  color: accentColor.withValues(alpha: 0.10),
                ),
              ),
              child: const Center(
                child: Text(
                  '🐱⛏️',
                  style: TextStyle(fontSize: 55),
                ),
              ),
            ),
          ),

          const SizedBox(height: 18),

          // ----------------------------------------------------
          // Mining title
          // ----------------------------------------------------
          Text(
            miningTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),

          const SizedBox(height: 8),

          // ----------------------------------------------------
          // Mining subtitle
          // ----------------------------------------------------
          Text(
            miningSubtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: secondaryTextColor,
              fontSize: 14,
            ),
          ),

          const SizedBox(height: 24),

          // ----------------------------------------------------
          // Unclaimed STL
          // ----------------------------------------------------
          Text(
            _formatStl(unclaimedMining),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: goldColor,
              fontSize: 38,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 4),

          const Text(
            'STL',
            style: TextStyle(
              color: secondaryTextColor,
              letterSpacing: 2,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 24),

          // ----------------------------------------------------
          // Mining time remaining
          // ----------------------------------------------------
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              vertical: 15,
              horizontal: 20,
            ),
            decoration: BoxDecoration(
              color: backgroundColor.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: accentColor.withValues(alpha: 0.08),
              ),
            ),
            child: Column(
              children: [
                Text(
                  timerText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 27,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  timerLabel,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: secondaryTextColor,
                    fontSize: 11,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ----------------------------------------------------
          // 🐾 START MINING / MINING ACTIVE
          // ----------------------------------------------------
          // Sama olemassa oleva painike kuin HomePagella,
          // mutta nyt se näkyy suoraan ajan alapuolella.
          miningButton,

          const SizedBox(height: 20),

          // ----------------------------------------------------
          // Stella Mining Days
          // ----------------------------------------------------
          StellaMiningDaysCard(
            languageCode: languageCode,
            dailyStreak: dailyStreak,
          ),

          const SizedBox(height: 20),

          // ----------------------------------------------------
          // Mining progress
          // ----------------------------------------------------
          MiningProgressCard(
            miningActive: miningActive,
            miningRemainingMs: miningRemainingMs,
            miningDurationMs: miningDurationMs,
            title: miningProgressTitle,
            stlPerHourText: stlPerHourText,
            dailyHashRateText: dailyHashRateText,
            dailyHashRateDayText: dailyHashRateDayText,
          ),
        ],
      ),
    );
  }
}