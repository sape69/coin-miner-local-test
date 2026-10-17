// ============================================================
// 🐱 STELLURIINI / STELLA DAILY CAT FACTS
//
// 150 päivittäistä kissafaktaa × 8 kieltä.
//
// Yhteensä 1200 lokalisoitua kissafaktaa.
//
// Kielikohtaiset faktat on jaettu omiin kansioihinsa:
//
//   cat_facts/fi/cat_facts_fi.dart
//   cat_facts/en/cat_facts_en.dart
//   cat_facts/de/cat_facts_de.dart
//   cat_facts/es/cat_facts_es.dart
//   cat_facts/fr/cat_facts_fr.dart
//   cat_facts/zh/cat_facts_zh.dart
//   cat_facts/vi/cat_facts_vi.dart
//   cat_facts/ja/cat_facts_ja.dart
//
// Sama UTC-päivä näyttää saman faktan kaikille käyttäjille.
// Kieli määräytyy sovelluksen nykyisen kielikoodin mukaan.
//
// Tuetut kielet:
// fi = Suomi
// en = English
// de = Deutsch
// es = Español
// fr = Français
// zh = 中文
// vi = Tiếng Việt
// ja = 日本語
//
// Päivän fakta vaihtuu automaattisesti UTC-päivän perusteella.
// ============================================================

import 'cat_facts/de/cat_facts_de.dart';
import 'cat_facts/en/cat_facts_en.dart';
import 'cat_facts/es/cat_facts_es.dart';
import 'cat_facts/fi/cat_facts_fi.dart';
import 'cat_facts/fr/cat_facts_fr.dart';
import 'cat_facts/ja/cat_facts_ja.dart';
import 'cat_facts/vi/cat_facts_vi.dart';
import 'cat_facts/zh/cat_facts_zh.dart';

class CatFacts {
  CatFacts._();

  /// Palauttaa kyseisen UTC-päivän kissafaktan.
  ///
  /// Sama UTC-päivä käyttää samaa faktanumeroa kaikille käyttäjille.
  /// Kielikoodi määrää käytettävän kielilistan.
  static String getDailyFact({
    required String languageCode,
    DateTime? date,
  }) {
    final DateTime inputDate =
        (date ?? DateTime.now()).toUtc();

    final DateTime utcDay = DateTime.utc(
      inputDate.year,
      inputDate.month,
      inputDate.day,
    );

    final DateTime startDay = DateTime.utc(
      2026,
      1,
      1,
    );

    final int dayIndex =
        utcDay.difference(startDay).inDays;

    final List<String> facts =
        _factsForLanguage(languageCode);

    if (facts.isEmpty) {
      return '';
    }

    final int index =
        ((dayIndex % facts.length) + facts.length) %
            facts.length;

    return facts[index];
  }

  /// Palauttaa oikean kielilistan sovelluksen kielikoodin perusteella.
  ///
  /// Kielikoodista huomioidaan vain ensimmäinen osa:
  ///
  /// fi-FI -> fi
  /// en-US -> en
  /// de-DE -> de
  ///
  /// Jos kielikoodia ei tunnisteta, käytetään englantia.
  static List<String> _factsForLanguage(
    String languageCode,
  ) {
    final String normalizedCode =
        languageCode.trim().toLowerCase().split('-').first;

    switch (normalizedCode) {
      case 'fi':
        return CatFactsFi.facts;

      case 'en':
        return CatFactsEn.facts;

      case 'de':
        return CatFactsDe.facts;

      case 'es':
        return CatFactsEs.facts;

      case 'fr':
        return CatFactsFr.facts;

      case 'zh':
        return CatFactsZh.facts;

      case 'vi':
        return CatFactsVi.facts;

      case 'ja':
        return CatFactsJa.facts;

      default:
        return CatFactsEn.facts;
    }
  }
}