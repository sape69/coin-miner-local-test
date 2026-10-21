import 'package:flutter/material.dart';

class DeleteAccountDialog extends StatelessWidget {
  final String title;
  final String message;
  final String cancelLabel;
  final String confirmLabel;

  const DeleteAccountDialog({
    super.key,
    required this.title,
    required this.message,
    required this.cancelLabel,
    required this.confirmLabel,
  });

  static const Color cardColor = Color(0xFF21113B);
  static const Color deleteAccountColor = Color(0xFFFF6B7A);
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
          color: deleteAccountColor.withValues(alpha: 0.30),
        ),
      ),
      title: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: deleteAccountColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.delete_forever_rounded,
              color: deleteAccountColor,
              size: 27,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
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
        message,
        style: const TextStyle(
          color: secondaryTextColor,
          fontSize: 15,
          height: 1.45,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(false);
          },
          child: Text(
            cancelLabel,
            style: const TextStyle(
              color: secondaryTextColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: deleteAccountColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () {
            Navigator.of(context).pop(true);
          },
          child: Text(
            confirmLabel,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}