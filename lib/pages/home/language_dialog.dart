import 'package:flutter/material.dart';

import '../../localization.dart';

const Color languageAccentColor = Color(0xFF35D0A0);

class LanguageDialog extends StatelessWidget {
  final String currentLanguageCode;
  final Future<void> Function(String) changeLanguage;

  const LanguageDialog({
    super.key,
    required this.currentLanguageCode,
    required this.changeLanguage,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations(currentLanguageCode);

    return AlertDialog(
      title: Text(
        t.get('selectLanguage'),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView(
          shrinkWrap: true,
          children: AppLocalizations.supportedLanguages.entries.map(
            (entry) {
              return ListTile(
                title: Text(
                  entry.value,
                ),
                trailing: currentLanguageCode == entry.key
                    ? const Icon(
                        Icons.check,
                        color: languageAccentColor,
                      )
                    : null,
                onTap: () async {
                  await changeLanguage(entry.key);

                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                },
              );
            },
          ).toList(),
        ),
      ),
    );
  }
}