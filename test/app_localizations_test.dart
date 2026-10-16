import 'package:flutter_test/flutter_test.dart';

import 'package:stelluriini/localization.dart';

void main() {
  group('AppLocalizations', () {
    test('supports all eight application languages', () {
      expect(
        AppLocalizations.supportedLanguages.keys,
        containsAll(<String>[
          'fi',
          'en',
          'de',
          'es',
          'fr',
          'zh',
          'vi',
          'ja',
        ]),
      );

      expect(AppLocalizations.supportedLanguages.length, 8);
    });

    test('normalizes language codes with region suffixes', () {
      expect(AppLocalizations.normalizeLanguageCode('fi-FI'), 'fi');
      expect(AppLocalizations.normalizeLanguageCode('en-US'), 'en');
      expect(AppLocalizations.normalizeLanguageCode('de-DE'), 'de');
      expect(AppLocalizations.normalizeLanguageCode('ja_JP'), 'ja');
    });

    test('falls back to Finnish for unsupported language codes', () {
      expect(AppLocalizations.normalizeLanguageCode('xx'), 'fi');
      expect(AppLocalizations.normalizeLanguageCode(null), 'fi');
      expect(AppLocalizations.normalizeLanguageCode(''), 'fi');
    });

    test('parameter replacement works', () {
      final AppLocalizations localization =
          AppLocalizations.forLanguage('en');

      final String result = localization.getWithParams(
        'welcomeUser',
        params: <String, dynamic>{
          'username': 'Stella',
        },
      );

      expect(result, isNot(contains('{username}')));
    });
  });
}