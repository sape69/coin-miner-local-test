import 'package:flutter/material.dart';

const Color dailyAccentColor = Color(0xFF35D0A0);

class DailyRewardCard extends StatelessWidget {
  final String title;
  final String streakText;

  final bool dailyLoading;
  final bool dailyAdLoading;
  final bool dailyClaimed;
  final bool adReady;

  final VoidCallback? onPressed;

  const DailyRewardCard({
    super.key,
    required this.title,
    required this.streakText,
    required this.dailyLoading,
    required this.dailyAdLoading,
    required this.dailyClaimed,
    required this.adReady,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    String buttonText;

    if (dailyLoading) {
      buttonText = 'PALKKIOTA HAETAAN...';
    } else if (dailyAdLoading) {
      buttonText = 'MAINOSTA LADATAAN...';
    } else if (dailyClaimed) {
      buttonText = 'LUNASTETTU';
    } else if (!adReady) {
      buttonText = 'MAINOSTA LADATAAN...';
    } else {
      buttonText = 'KATSO MAINOS JA LUNASTA';
    }

    final bool isLoading =
        dailyLoading || dailyAdLoading;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(
              Icons.card_giftcard,
              size: 42,
              color: dailyAccentColor,
            ),

            const SizedBox(height: 10),

            Text(
              title,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              streakText,
              style: const TextStyle(
                color: Colors.white70,
              ),
            ),

            const SizedBox(height: 15),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: onPressed,
                icon: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : const Icon(
                        Icons.play_arrow,
                      ),
                label: Text(buttonText),
              ),
            ),
          ],
        ),
      ),
    );
  }
}