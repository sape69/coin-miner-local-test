import 'package:flutter/material.dart';

import 'localization/languages/de.dart';
import 'localization/languages/en.dart';
import 'localization/languages/es.dart';
import 'localization/languages/fi.dart';
import 'localization/languages/fr.dart';
import 'localization/languages/ja.dart';
import 'localization/languages/vi.dart';
import 'localization/languages/zh.dart';

// ============================================================
// 🌍 STELLURIINI APP LOCALIZATIONS
// ============================================================
//
// Keskitetty Stelluriini-käännösjärjestelmä.
//
// Tuetut kielet:
// • Suomi
// • English
// • Deutsch
// • Español
// • Français
// • 中文
// • Tiếng Việt
// • 日本語
//
// Sovelluksen pääasiallinen kieli tulee main.dartista
// ja kulkee languageCode-arvona sivuille.
//
// Tämä tiedosto sisältää myös BuildContext-pohjaisen
// fallback-menetelmän vanhempia widgettejä varten.
// ============================================================

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
    final Map<String, String>? languageTranslations =
        _translations[languageCode];

    final String? translatedValue =
        languageTranslations?[key];

    if (translatedValue != null) {
      return translatedValue;
    }

    // ----------------------------------------------------------
    // English fallback
    // ----------------------------------------------------------

    final String? englishValue =
        _translations['en']?[key];

    if (englishValue != null) {
      return englishValue;
    }

    // ----------------------------------------------------------
    // Final fallback
    // ----------------------------------------------------------

    return key;
  }

  // ============================================================
  // 🔤 TRANSLATION WITH PARAMETERS
  // ============================================================

  String getWithParams(
    String key, {
    Map<String, dynamic>? params,
  }) {
    String value = get(key);

    if (params == null || params.isEmpty) {
      return value;
    }

    params.forEach(
      (
        String name,
        dynamic replacement,
      ) {
        value = value.replaceAll(
          '{$name}',
          replacement.toString(),
        );
      },
    );

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

    if (params == null || params.isEmpty) {
      return value;
    }

    params.forEach(
      (
        String name,
        String replacement,
      ) {
        value = value.replaceAll(
          '{$name}',
          replacement,
        );
      },
    );

    return value;
  }

  // ============================================================
  // 🌍 LANGUAGE VALIDATION
  // ============================================================

  static bool isSupportedLanguage(
    String? code,
  ) {
    if (code == null) {
      return false;
    }

    return supportedLanguages.containsKey(
      code,
    );
  }

  // ============================================================
  // 🌍 SAFE LANGUAGE CODE
  // ============================================================

  static String normalizeLanguageCode(
    String? code,
  ) {
    if (code != null &&
        supportedLanguages.containsKey(code)) {
      return code;
    }

    return 'fi';
  }

  // ============================================================
  // 🌍 BUILD CONTEXT FALLBACK
  // ============================================================
  //
  // Tätä voidaan käyttää widgeteissä, jotka eivät vielä
  // saa languageCodea suoraan konstruktorissa.
  //
  // HUOM:
  // Stelluriinin uusissa pääsivuissa suositellaan käyttämään:
  //
  // AppLocalizations(widget.languageCode)
  //
  // eikä tätä metodia.
  //
  // Tämä metodi käyttää Flutterin Locale-arvoa vain fallbackina.
  // ============================================================

  static AppLocalizations of(
    BuildContext context,
  ) {
    final Locale locale =
        Localizations.localeOf(context);

    final String code =
        supportedLanguages.containsKey(
          locale.languageCode,
        )
            ? locale.languageCode
            : 'fi';

    return AppLocalizations(code);
  }

  // ============================================================
  // 🌍 DIRECT LANGUAGE ACCESS
  // ============================================================

  static AppLocalizations forLanguage(
    String? code,
  ) {
    return AppLocalizations(
      normalizeLanguageCode(code),
    );
  }
}