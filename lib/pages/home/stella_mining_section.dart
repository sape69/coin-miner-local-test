import 'package:flutter/material.dart';

import 'stella_mining_card.dart';

// ============================================================
// 🐱 STELLURIINI STELLA MINING SECTION
// ============================================================

class StellaMiningSection extends StatelessWidget {
  // ============================================================
  // ⛏️ MINING STATE
  // ============================================================

  final bool miningActive;
  final double unclaimedMining;
  final int miningRemainingMs;
  final int miningDurationMs;

  // ============================================================
  // 📊 MINING PROGRESS TEXTS
  // ============================================================

  final String miningProgressTitle;
  final String stlPerHourText;
  final String dailyHashRateText;
  final String dailyHashRateDayText;
  final String hashRateBonusText;
  final String effectiveHashRateText;

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
    required this.miningActive,
    required this.unclaimedMining,
    required this.miningRemainingMs,
    required this.miningDurationMs,
    required this.miningProgressTitle,
    required this.stlPerHourText,
    required this.dailyHashRateText,
    required this.dailyHashRateDayText,
    required this.hashRateBonusText,
    required this.effectiveHashRateText,
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
    required this.formatDuration,
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

    // ==========================================================
    // 🐱 STELLA MINING CARD
    // ==========================================================

    return StellaMiningCard(
      unclaimedMining: unclaimedMining,
      miningTitle: title,
      miningSubtitle: subtitle,
      timerText: timerText,
      timerLabel: timerLabel,
      catAnimation: catAnimation,

      // ========================================================
      // ⛏️ 24H MINING PROGRESS
      // ========================================================

      miningActive: miningActive,
      miningRemainingMs: miningRemainingMs,
      miningDurationMs: miningDurationMs,

      miningProgressTitle:
          miningProgressTitle,

      stlPerHourText:
          stlPerHourText,

      dailyHashRateText:
          dailyHashRateText,

      dailyHashRateDayText:
          dailyHashRateDayText,

      hashRateBonusText:
          hashRateBonusText,

      effectiveHashRateText:
          effectiveHashRateText,
    );
  }
}