import 'package:flutter/material.dart';

void showComingSoon(
  BuildContext context,
  String pageName,
) {
  Navigator.pop(context);

  Future.delayed(
    const Duration(milliseconds: 250),
    () {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              '$pageName – Coming Soon 🚀',
            ),
          ),
        );
    },
  );
}