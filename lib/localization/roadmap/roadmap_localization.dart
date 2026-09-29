import 'roadmap_de.dart';
import 'roadmap_en.dart';
import 'roadmap_es.dart';
import 'roadmap_fi.dart';
import 'roadmap_fr.dart';
import 'roadmap_ja.dart';
import 'roadmap_vi.dart';
import 'roadmap_zh.dart';

// ============================================================
// 🐱 STELLURIINI ROADMAP LOCALIZATION
// ============================================================
//
// Supported languages:
//
// 🇫🇮 Finnish
// 🇬🇧 English
// 🇩🇪 German
// 🇪🇸 Spanish
// 🇫🇷 French
// 🇨🇳 Chinese
// 🇻🇳 Vietnamese
// 🇯🇵 Japanese
//
// ============================================================

class RoadmapLocalization {
  final String languageCode;

  const RoadmapLocalization(
    this.languageCode,
  );

  // ==========================================================
  // 🌍 TRANSLATIONS
  // ==========================================================

  Map<String, String> get _translations {
    switch (languageCode.toLowerCase()) {
      case 'fi':
        return roadmapFi;

      case 'de':
        return roadmapDe;

      case 'es':
        return roadmapEs;

      case 'fr':
        return roadmapFr;

      case 'zh':
        return roadmapZh;

      case 'vi':
        return roadmapVi;

      case 'ja':
        return roadmapJa;

      case 'en':
      default:
        return roadmapEn;
    }
  }

  // ==========================================================
  // 🔤 GET TRANSLATION
  // ==========================================================

  String get(
    String key,
  ) {
    return _translations[key] ??
        roadmapEn[key] ??
        key;
  }
}