import 'package:flutter/material.dart';

const Color watchAdAccentColor = Color(0xFF35D0A0);

class WatchAdCard extends StatelessWidget {
  final String title;
  final String dailyLimitText;
  final int adsToday;
  final int maxAdsPerDay;

  final bool canWatch;
  final String nextAdText;

  final bool adLoading;
  final bool adReady;

  final String loadingText;
  final String limitReachedText;
  final String unavailableText;
  final String watchButtonText;

  final VoidCallback? onPressed;

  const WatchAdCard({
    super.key,
    required this.title,
    required this.dailyLimitText,
    required this.adsToday,
    required this.maxAdsPerDay,
    required this.canWatch,
    required this.nextAdText,
    required this.adLoading,
    required this.adReady,
    required this.loadingText,
    required this.limitReachedText,
    required this.unavailableText,
    required this.watchButtonText,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    String buttonText;

    if (adLoading) {
      buttonText = loadingText;
    } else if (adsToday >= maxAdsPerDay) {
      buttonText = limitReachedText;
    } else if (!canWatch) {
      buttonText = nextAdText;
    } else if (!adReady) {
      buttonText = unavailableText;
    } else {
      buttonText = watchButtonText;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(
              Icons.play_circle_outline,
              size: 42,
              color: watchAdAccentColor,
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
              '$dailyLimitText: '
              '$adsToday / $maxAdsPerDay',
              style: const TextStyle(
                color: Colors.white70,
              ),
            ),

            const SizedBox(height: 8),

            if (adsToday < maxAdsPerDay && !canWatch)
              Text(
                nextAdText,
                style: const TextStyle(
                  color: Colors.orangeAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),

            const SizedBox(height: 15),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: onPressed,
                icon: adLoading
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