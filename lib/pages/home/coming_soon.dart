import 'package:flutter/material.dart';

// ============================================================
// 🐱 STELLURIINI COMING SOON
// ============================================================

void showComingSoon(
  BuildContext context,
  String pageName,
) {
  Navigator.pop(context);

  Future.delayed(
    const Duration(milliseconds: 250),
    () {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Text(
                  '🐱',
                  style: TextStyle(
                    fontSize: 22,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '$pageName – Coming Soon 🚀',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFF21113B),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
    },
  );
}