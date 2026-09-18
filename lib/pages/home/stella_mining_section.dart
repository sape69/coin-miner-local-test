import 'package:flutter/material.dart';

import 'stella_mining_card.dart';

// ============================================================
// 🐱 STELLURIINI STELLA MINING SECTION
// ============================================================

class StellaMiningSection extends StatelessWidget {
  // ============================================================
  // 🌍 LANGUAGE
  // ============================================================

  final String languageCode;

  // ============================================================
  // ⛏️ MINING STATE
  // ============================================================

  final bool miningActive;
  final double unclaimedMining;
  final int miningRemainingMs;
  final int miningDurationMs;

  // ============================================================
  // 🎁 DAILY STREAK
  // ============================================================

  final int dailyStreak;

  // ============================================================
  // ⚡ POWER BOOST
  // ============================================================

  final bool boostActive;

  // ============================================================
  // 📊 MINING PROGRESS TEXTS
  // ============================================================

  final String miningProgressTitle;
  final String stlPerHourText;
  final String dailyHashRateText;
  final String dailyHashRateDayText;

  // ============================================================
  // 📝 MINING STATUS TEXTS
  // ============================================================

  final String miningActiveTitle;
  final String miningActiveSubtitle;

  final String miningCompleteTitle;
  final String miningCompleteSubtitle;

  final String restingTitle;
  final String restingSubtitle;

  final String timeRemainingLabel;
  final String miningFinishedLabel;
  final String readyText;
  final String waitingForStellaLabel;

  // ============================================================
  // ⛏️ MINING BUTTON
  // ============================================================

  final Widget miningButton;

  // ============================================================
  // ⏱️ FORMATTER
  // ============================================================

  final String Function(int) formatDuration;

  // ============================================================
  // 🐱 STELLA ANIMATION
  // ============================================================

  final Animation<double> catAnimation;

  // ============================================================
  // CONSTRUCTOR
  // ============================================================

  const StellaMiningSection({
    super.key,

    // ==========================================================
    // 🌍 LANGUAGE
    // ==========================================================

    required this.languageCode,

    // ==========================================================
    // ⛏️ MINING
    // ==========================================================

    required this.miningActive,
    required this.unclaimedMining,
    required this.miningRemainingMs,
    required this.miningDurationMs,

    // ==========================================================
    // 🎁 DAILY STREAK
    // ==========================================================

    required this.dailyStreak,

    // ==========================================================
    // ⚡ POWER BOOST
    // ==========================================================

    required this.boostActive,

    // ==========================================================
    // 📊 MINING PROGRESS
    // ==========================================================

    required this.miningProgressTitle,
    required this.stlPerHourText,
    required this.dailyHashRateText,
    required this.dailyHashRateDayText,

    // ==========================================================
    // 📝 STATUS TEXTS
    // ==========================================================

    required this.miningActiveTitle,
    required this.miningActiveSubtitle,
    required this.miningCompleteTitle,
    required this.miningCompleteSubtitle,
    required this.restingTitle,
    required this.restingSubtitle,
    required this.timeRemainingLabel,
    required this.miningFinishedLabel,
    required this.readyText,
    required this.waitingForStellaLabel,

    // ==========================================================
    // ⛏️ MINING BUTTON
    // ==========================================================

    required this.miningButton,

    // ==========================================================
    // ⏱️ FORMATTER
    // ==========================================================

    required this.formatDuration,

    // ==========================================================
    // 🐱 ANIMATION
    // ==========================================================

    required this.catAnimation,
  });

  // ============================================================
  // 🏗️ BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final bool completed =
        !miningActive &&
        unclaimedMining > 0;

    final String title;
    final String subtitle;
    final String timerText;
    final String timerLabel;

    // ==========================================================
    // ⛏️ MINING ACTIVE
    // ==========================================================

    if (miningActive) {
      title = miningActiveTitle;
      subtitle = miningActiveSubtitle;

      timerText = formatDuration(
        miningRemainingMs,
      );

      timerLabel = timeRemainingLabel;
    }

    // ==========================================================
    // ✅ MINING COMPLETE
    // ==========================================================

    else if (completed) {
      title = miningCompleteTitle;
      subtitle = miningCompleteSubtitle;

      timerText = '00:00:00';

      timerLabel = miningFinishedLabel;
    }

    // ==========================================================
    // 💤 RESTING
    // ==========================================================

    else {
      title = restingTitle;
      subtitle = restingSubtitle;

      timerText = readyText;

      timerLabel = waitingForStellaLabel;
    }

    // ============================================================
    // 🐱 STELLA MINING CARD
    // ============================================================

    return StellaMiningCard(
      unclaimedMining:
          unclaimedMining,

      miningTitle:
          title,

      miningSubtitle:
          subtitle,

      timerText:
          timerText,

      timerLabel:
          timerLabel,

      catAnimation:
          catAnimation,

      // ========================================================
      // 🌍 LANGUAGE
      // ========================================================

      languageCode:
          languageCode,

      // ========================================================
      // ⛏️ 24H MINING PROGRESS
      // ========================================================

      miningActive:
          miningActive,

      miningRemainingMs:
          miningRemainingMs,

      miningDurationMs:
          miningDurationMs,

      // ========================================================
      // 🎁 DAILY STREAK
      // ========================================================

      dailyStreak:
          dailyStreak,

      // ========================================================
      // ⚡ POWER BOOST
      // ========================================================

      boostActive:
          boostActive,

      // ========================================================
      // 📊 MINING TEXTS
      // ========================================================

      miningProgressTitle:
          miningProgressTitle,

      stlPerHourText:
          stlPerHourText,

      dailyHashRateText:
          dailyHashRateText,

      dailyHashRateDayText:
          dailyHashRateDayText,

      // ========================================================
      // ⛏️ MINING BUTTON
      // ========================================================

      miningButton:
          miningButton,
    );
  }
}