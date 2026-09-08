import 'package:flutter/material.dart';

import 'stella_mining_card.dart';

class StellaMiningSection extends StatelessWidget {
  final bool miningActive;
  final double unclaimedMining;
  final int miningRemainingMs;

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

  final String Function(int) formatDuration;

  final Animation<double> catAnimation;

  const StellaMiningSection({
    super.key,
    required this.miningActive,
    required this.unclaimedMining,
    required this.miningRemainingMs,
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

  @override
  Widget build(BuildContext context) {
    final bool completed =
        !miningActive && unclaimedMining > 0;

    final String title;
    final String subtitle;
    final String timerText;
    final String timerLabel;

    if (miningActive) {
      title = miningActiveTitle;
      subtitle = miningActiveSubtitle;

      timerText = formatDuration(
        miningRemainingMs,
      );

      timerLabel = timeRemainingLabel;
    } else if (completed) {
      title = miningCompleteTitle;
      subtitle = miningCompleteSubtitle;

      timerText = '00:00:00';

      timerLabel = miningFinishedLabel;
    } else {
      title = restingTitle;
      subtitle = restingSubtitle;

      timerText = readyText;

      timerLabel = waitingForStellaLabel;
    }

    return StellaMiningCard(
      unclaimedMining: unclaimedMining,
      miningTitle: title,
      miningSubtitle: subtitle,
      timerText: timerText,
      timerLabel: timerLabel,
      catAnimation: catAnimation,
    );
  }
}