import 'package:flutter/material.dart';

import 'localization/languages/de.dart';
import 'localization/languages/en.dart';
import 'localization/languages/es.dart';
import 'localization/languages/fi.dart';
import 'localization/languages/fr.dart';
import 'localization/languages/ja.dart';
import 'localization/languages/vi.dart';
import 'localization/languages/zh.dart';

class AppLocalizations {
  final String languageCode;

  const AppLocalizations(this.languageCode);

  // ============================================================
  // 🌍 SUPPORTED LANGUAGES
  // ============================================================

  static const Map<String, String> supportedLanguages = {
    'fi': 'Suomi',
    'en': 'English',
    'de': 'Deutsch',
    'es': 'Español',
    'fr': 'Français',
    'zh': '中文',
    'vi': 'Tiếng Việt',
    'ja': '日本語',
  };

  // ============================================================
  // 🗂️ LANGUAGE TRANSLATIONS
  // ============================================================

  static const Map<String, Map<String, String>> _translations = {
    'fi': fiTranslations,
    'en': enTranslations,
    'de': deTranslations,
    'es': esTranslations,
    'fr': frTranslations,
    'zh': zhTranslations,
    'vi': viTranslations,
    'ja': jaTranslations,
  };

  // ============================================================
  // 🔤 BASIC TRANSLATION
  // ============================================================

  String get(String key) {
    return _translations[languageCode]?[key] ??
        _translations['en']?[key] ??
        key;
  }

  // ============================================================
  // 🔤 TRANSLATION WITH PARAMETERS
  // ============================================================

  String getWithParams(
    String key, {
    Map<String, dynamic>? params,
  }) {
    String value = get(key);

    if (params != null) {
      params.forEach((name, replacement) {
        value = value.replaceAll(
          '{$name}',
          replacement.toString(),
        );
      });
    }

    return value;
  }

  // ============================================================
  // 🔤 COMPATIBILITY METHOD
  // ============================================================

  String t(
    String key, {
    Map<String, String>? params,
  }) {
    String value = get(key);

    if (params != null) {
      params.forEach((name, replacement) {
        value = value.replaceAll(
          '{$name}',
          replacement,
        );
      });
    }

    return value;
  }

  // ============================================================
  // 🌍 BUILD CONTEXT
  // ============================================================

  static AppLocalizations of(BuildContext context) {
    final locale = Localizations.localeOf(context);

    final languageCode =
        supportedLanguages.containsKey(
          locale.languageCode,
        )
            ? locale.languageCode
            : 'en';

    return AppLocalizations(languageCode);
  }
}