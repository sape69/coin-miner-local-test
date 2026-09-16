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
// Stella-teema säilytetään kaikissa käännöksissä. 🐱💜
//
// Sovelluksen pääasiallinen kieli voidaan antaa
// languageCode-arvona sivuille.
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

    final String? translatedValue = languageTranslations?[key];

    if (translatedValue != null && translatedValue.isNotEmpty) {
      return translatedValue;
    }

    // ----------------------------------------------------------
    // English fallback
    // ----------------------------------------------------------

    final String? englishValue = _translations['en']?[key];

    if (englishValue != null && englishValue.isNotEmpty) {
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
    final String normalizedCode = _extractLanguageCode(code);

    return supportedLanguages.containsKey(
      normalizedCode,
    );
  }

  // ============================================================
  // 🌍 SAFE LANGUAGE CODE
  // ============================================================

  static String normalizeLanguageCode(
    String? code,
  ) {
    final String normalizedCode = _extractLanguageCode(code);

    if (supportedLanguages.containsKey(normalizedCode)) {
      return normalizedCode;
    }

    return 'fi';
  }

  // ============================================================
  // 🌍 LANGUAGE CODE EXTRACTION
  // ============================================================
  //
  // Tukee esimerkiksi:
  //
  // fi
  // fi-FI
  // en
  // en-US
  // de-DE
  //
  // Näin laitteen Locale ei aiheuta turhaa fallbackia.
  // ============================================================

  static String _extractLanguageCode(
    String? code,
  ) {
    if (code == null || code.trim().isEmpty) {
      return '';
    }

    final String normalized = code
        .trim()
        .toLowerCase()
        .replaceAll('_', '-');

    final int separatorIndex = normalized.indexOf('-');

    if (separatorIndex == -1) {
      return normalized;
    }

    return normalized.substring(
      0,
      separatorIndex,
    );
  }

  // ============================================================
  // 🌍 BUILD CONTEXT FALLBACK
  // ============================================================
  //
  // Tätä voidaan käyttää widgeteissä, jotka eivät vielä
  // saa languageCodea suoraan konstruktorissa.
  //
  // Uusissa pääsivuissa suositellaan edelleen:
  //
  // AppLocalizations(widget.languageCode)
  //
  // Tämä metodi käyttää Flutterin Locale-arvoa fallbackina.
  // ============================================================

  static AppLocalizations of(
    BuildContext context,
  ) {
    final Locale locale = Localizations.localeOf(context);

    final String code = normalizeLanguageCode(
      locale.languageCode,
    );

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