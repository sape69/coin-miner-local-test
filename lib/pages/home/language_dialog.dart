import 'package:flutter/material.dart';

import '../../localization.dart';

// ============================================================
// 🐱 STELLURIINI COLORS
// ============================================================

const Color languageDialogColor = Color(0xFF21113B);
const Color languageAccentColor = Color(0xFFB58CFF);
const Color languagePinkColor = Color(0xFFFFB7E8);

// ============================================================
// 🌍 STELLA LANGUAGE DIALOG
// ============================================================

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
    final AppLocalizations t =
        AppLocalizations(currentLanguageCode);

    return AlertDialog(
      backgroundColor: languageDialogColor,
      title: Text(
        t.get('selectLanguage'),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView(
          shrinkWrap: true,
          children: AppLocalizations.supportedLanguages.entries.map(
            (entry) {
              final bool selected =
                  currentLanguageCode == entry.key;

              return Container(
                margin: const EdgeInsets.only(
                  bottom: 8,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? languageAccentColor.withValues(
                          alpha: 0.12,
                        )
                      : Colors.white.withValues(
                          alpha: 0.04,
                        ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selected
                        ? languagePinkColor.withValues(
                            alpha: 0.30,
                          )
                        : Colors.white.withValues(
                            alpha: 0.06,
                          ),
                  ),
                ),
                child: ListTile(
                  title: Text(
                    entry.value,
                    style: TextStyle(
                      color: selected
                          ? Colors.white
                          : Colors.white.withValues(
                              alpha: 0.78,
                            ),
                      fontWeight: selected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  trailing: selected
                      ? const Icon(
                          Icons.check_circle,
                          color: languagePinkColor,
                        )
                      : Icon(
                          Icons.language,
                          color: Colors.white.withValues(
                            alpha: 0.35,
                          ),
                        ),
                  onTap: () async {
                    await changeLanguage(entry.key);

                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  },
                ),
              );
            },
          ).toList(),
        ),
      ),
    );
  }
}