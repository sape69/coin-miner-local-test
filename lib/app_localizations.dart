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
      'login': 'KIRJAUDU SISÄÄN',
      'register': 'LUO TILI',
      'email': 'Sähköposti',
      'password': 'Salasana',
      'forgotPassword': 'Unohditko salasanan?',
      'yourBalance': 'SALDOSI',
      'dailyClaim': 'PÄIVITTÄINEN PALKINTO',
      'watchEarn': 'KATSO JA ANSAITSE',
      'watchAd': 'Katso mainos +3 STL',
      'dailyLimit': 'PÄIVÄRAJA',
      'streak': 'PUTKI',
      'claimed': 'KÄYTETTY',
      'dailyReward': 'HAE PÄIVÄN PALKINTO',
      'loadingAd': 'MAINOSTA LADATAAN...',
      'adUnavailable': 'MAINOS EI SAATAVILLA',
      'nextAd': 'Seuraava mainos',
      'hourCooldown': 'Mainosten välillä on 1 tunnin odotus.',
      'dailyLimitReached': 'Päivän mainosraja 5/5 on täynnä.',
      'pointsAdded': '+3 STL! 🐱',
      'stellaFacts': 'STELLAN KISSAFAKTA',
      'virtualPoints': 'Virtuaalisia sovelluspisteitä',
    },
    'en': {
      'selectLanguage': 'Select language',
      'login': 'LOGIN',
      'register': 'CREATE ACCOUNT',
      'email': 'Email',
      'password': 'Password',
      'forgotPassword': 'Forgot password?',
      'yourBalance': 'YOUR BALANCE',
      'dailyClaim': 'DAILY REWARD',
      'watchEarn': 'WATCH & EARN',
      'watchAd': 'Watch ad +3 STL',
      'dailyLimit': 'DAILY LIMIT',
      'streak': 'STREAK',
      'claimed': 'CLAIMED',
      'dailyReward': 'CLAIM DAILY REWARD',
      'loadingAd': 'LOADING AD...',
      'adUnavailable': 'AD NOT AVAILABLE',
      'nextAd': 'Next ad',
      'hourCooldown': 'There is a 1 hour wait between ads.',
      'dailyLimitReached': 'The daily ad limit of 5/5 has been reached.',
      'pointsAdded': '+3 STL! 🐱',
      'stellaFacts': "STELLA'S CAT FACT",
      'virtualPoints': 'Virtual in-app points',
    },
  };
}