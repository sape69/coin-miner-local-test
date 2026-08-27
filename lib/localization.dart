class AppLocalizations {
  final String languageCode;

  const AppLocalizations(this.languageCode);

  static const Map<String, String> supportedLanguages = {
    'fi': '🇫🇮 Suomi',
    'en': '🇬🇧 English',
  };

  String get(String key) {
    final language =
        _translations[languageCode] ?? _translations['fi']!;

    return language[key] ??
        _translations['fi']![key] ??
        key;
  }

  static const Map<String, Map<String, String>> _translations = {
    'fi': {
      'selectLanguage': 'Valitse kieli',

      'yourBalance': 'SALDOSI',

      'dailyClaim': 'PÄIVITTÄINEN PALKINTO',

      'watchEarn': 'KATSO JA ANSAITSE',

      'watchAd': 'Katso mainos +3 STL',

      'dailyLimit': 'PÄIVÄRAJA',

      'dailyLimitReached':
          'Päivän mainosraja 5/5 on täynnä.',

      'stella': '🐱 Stella',

      'stellaFacts': 'STELLAN KISSAFAKTA',

      'streak': 'PUTKI',

      'info': 'TIETOJA',

      'solanaToken':
          'Stelluriini on Solana-verkossa oleva yhteisötokeni.',

      'stellaCompany':
          '🐱 Stella pitää sinulle seuraa Stelluriinin parissa!',

      'claimed': 'KÄYTETTY',

      'dailyReward': 'HAE PÄIVÄN PALKINTO',

      'pointsAdded': '+3 STL! 🐱',

      'virtualPoints':
          'Virtuaalisia sovelluspisteitä',

      'adLoading':
          'MAINOSTA LADATAAN...',

      'adUnavailable':
          'MAINOS EI SAATAVILLA',

      'nextAd':
          'Seuraava mainos',

      'logout':
          'Kirjaudu ulos',

      'language':
          'Vaihda kieli',
    },

    'en': {
      'selectLanguage': 'Select language',

      'yourBalance': 'YOUR BALANCE',

      'dailyClaim': 'DAILY CLAIM',

      'watchEarn': 'WATCH & EARN',

      'watchAd': 'Watch ad +3 STL',

      'dailyLimit': 'DAILY LIMIT',

      'dailyLimitReached':
          'The daily ad limit of 5/5 has been reached.',

      'stella': '🐱 Stella',

      'stellaFacts': "STELLA'S CAT FACT",

      'streak': 'STREAK',

      'info': 'INFORMATION',

      'solanaToken':
          'Stelluriini is a community token on the Solana network.',

      'stellaCompany':
          '🐱 Stella keeps you company while using Stelluriini!',

      'claimed': 'CLAIMED',

      'dailyReward': 'CLAIM DAILY REWARD',

      'pointsAdded': '+3 STL! 🐱',

      'virtualPoints':
          'Virtual in-app points',

      'adLoading':
          'LOADING AD...',

      'adUnavailable':
          'AD NOT AVAILABLE',

      'nextAd':
          'Next ad',

      'logout':
          'Log out',

      'language':
          'Change language',
    },
  };
}