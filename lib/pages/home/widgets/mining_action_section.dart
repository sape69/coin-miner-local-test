import 'package:flutter/material.dart';

class MiningActionSection extends StatelessWidget {
  final bool miningActive;
  final bool actionLoading;
  final bool adLoading;
  final bool canStartMining;
  final VoidCallback? onStartMining;
  final VoidCallback? onClaimMining;

  final String startMiningText;
  final String claimMiningText;
  final String miningActiveText;
  final String loadingText;
  final String subtitle;

  const MiningActionSection({
    super.key,
    required this.miningActive,
    required this.actionLoading,
    required this.adLoading,
    required this.canStartMining,
    required this.onStartMining,
    required this.onClaimMining,
    required this.startMiningText,
    required this.claimMiningText,
    required this.miningActiveText,
    required this.loadingText,
    required this.subtitle,
  });

  static const Color cardColor = Color(0xFF21113B);
  static const Color accentColor = Color(0xFFB58CFF);
  static const Color pinkColor = Color(0xFFFFB7E8);
  static const Color goldColor = Color(0xFFFFD166);
  static const Color primaryTextColor = Color(0xFFF8F4FF);
  static const Color secondaryTextColor = Color(0xFFBDB4D1);

  @override
  Widget build(BuildContext context) {
    final bool busy = actionLoading || adLoading;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  miningActive
                      ? Icons.bolt_rounded
                      : Icons.play_arrow_rounded,
                  color: accentColor,
                  size: 25,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      miningActive
                          ? miningActiveText
                          : startMiningText,
                      style: const TextStyle(
                        color: primaryTextColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: secondaryTextColor,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (busy)
            _buildLoadingButton()
          else if (miningActive)
            _buildClaimButton()
          else
            _buildStartButton(),
        ],
      ),
    );
  }

  Widget _buildLoadingButton() {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: null,
        style: FilledButton.styleFrom(
          disabledBackgroundColor:
              accentColor.withValues(alpha: 0.16),
          disabledForegroundColor:
              secondaryTextColor.withValues(alpha: 0.75),
          padding: const EdgeInsets.symmetric(
            vertical: 15,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 19,
              height: 19,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: accentColor,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              loadingText,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStartButton() {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: canStartMining ? onStartMining : null,
        style: FilledButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: Color(0xFF120B24),
          disabledBackgroundColor:
              accentColor.withValues(alpha: 0.16),
          disabledForegroundColor:
              secondaryTextColor.withValues(alpha: 0.55),
          padding: const EdgeInsets.symmetric(
            vertical: 15,
            horizontal: 16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.play_arrow_rounded,
              size: 21,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                startMiningText,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClaimButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onClaimMining,
        style: OutlinedButton.styleFrom(
          foregroundColor: goldColor,
          side: BorderSide(
            color: goldColor.withValues(alpha: 0.55),
          ),
          padding: const EdgeInsets.symmetric(
            vertical: 15,
            horizontal: 16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.auto_awesome_rounded,
              size: 20,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                claimMiningText,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}