import 'achievements_de.dart';
import 'achievements_en.dart';
import 'achievements_es.dart';
import 'achievements_fi.dart';
import 'achievements_fr.dart';
import 'achievements_ja.dart';
import 'achievements_vi.dart';
import 'achievements_zh.dart';

// ============================================================
// 🏆 STELLURIINI ACHIEVEMENTS LOCALIZATION
// ============================================================

class AchievementsLocalization {
  final String languageCode;

  const AchievementsLocalization(
    this.languageCode,
  );

  // ==========================================================
  // 🌍 TRANSLATIONS
  // ==========================================================

  Map<String, String> get _translations {
    switch (languageCode.toLowerCase()) {
      case 'fi':
        return achievementsFi;

      case 'de':
        return achievementsDe;

      case 'es':
        return achievementsEs;

      case 'fr':
        return achievementsFr;

      case 'zh':
        return achievementsZh;

      case 'vi':
        return achievementsVi;

      case 'ja':
        return achievementsJa;

      case 'en':
      default:
        return achievementsEn;
    }
  }

  // ==========================================================
  // 🔤 GET TRANSLATION
  // ==========================================================

  String get(
    String key,
  ) {
    return _translations[key] ??
        achievementsEn[key] ??
        key;
  }

  // ==========================================================
  // 🏆 ACHIEVEMENT TITLE
  // ==========================================================

  String achievementTitle(
    String achievementId,
  ) {
    return get(
      'achievement_${achievementId}_title',
    );
  }

  // ==========================================================
  // 📝 ACHIEVEMENT DESCRIPTION
  // ==========================================================

  String achievementDescription(
    String achievementId,
  ) {
    return get(
      'achievement_${achievementId}_description',
    );
  }
}