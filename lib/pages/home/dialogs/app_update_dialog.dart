import 'package:flutter/material.dart';

import '../../../services/app_update_service.dart';

class AppUpdateDialog extends StatelessWidget {
  final AppUpdateInfo updateInfo;
  final Map<String, String> texts;
  final Future<bool> Function(String url) onOpenUpdate;
  final VoidCallback onOpenError;

  const AppUpdateDialog({
    super.key,
    required this.updateInfo,
    required this.texts,
    required this.onOpenUpdate,
    required this.onOpenError,
  });

  static const Color backgroundColor = Color(0xFF120B24);
  static const Color cardColor = Color(0xFF21113B);
  static const Color accentColor = Color(0xFFB58CFF);
  static const Color primaryTextColor = Color(0xFFF8F4FF);
  static const Color secondaryTextColor = Color(0xFFBDB4D1);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: cardColor,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: accentColor.withValues(alpha: 0.35),
        ),
      ),
      title: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.system_update_rounded,
              color: accentColor,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              texts['title'] ?? 'Update available',
              style: const TextStyle(
                color: primaryTextColor,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      content: Text(
        texts['message'] ??
            'A new version of Stelluriini is available.',
        style: const TextStyle(
          color: secondaryTextColor,
          fontSize: 15,
          height: 1.45,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text(
            texts['later'] ?? 'Later',
            style: const TextStyle(
              color: secondaryTextColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: accentColor,
            foregroundColor: backgroundColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () async {
            final bool opened = await onOpenUpdate(
              updateInfo.updateUrl,
            );

            if (!context.mounted) {
              return;
            }

            if (opened) {
              Navigator.of(context).pop();
            } else {
              onOpenError();
            }
          },
          child: Text(
            texts['update'] ?? 'Update',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}