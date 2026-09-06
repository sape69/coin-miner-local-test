class AppLocalizations {
  final String languageCode;

  AppLocalizations(this.languageCode);

  // ==========================================================
  // 🌍 SUPPORTED LANGUAGES
  // ==========================================================

  static const Map<String, String> supportedLanguages = {
    'fi': '🇫🇮 Suomi',
    'en': '🇬🇧 English',
    'de': '🇩🇪 Deutsch',
    'es': '🇪🇸 Español',
    'fr': '🇫🇷 Français',
    'zh': '🇨🇳 中文',
    'vi': '🇻🇳 Tiếng Việt',
    'ja': '🇯🇵 日本語',
  };

  // ==========================================================
  // 🌍 TRANSLATIONS
  // ==========================================================

  static const Map<String, Map<String, String>> _translations = {
    // ========================================================
    // 🇫🇮 SUOMI
    // ========================================================

    'fi': {
      // ------------------------------------------------------
      // General
      // ------------------------------------------------------

      'stella': 'Stella',
      'yourBalance': 'SINUN STL-SALDOSI',
      'virtualPoints': 'Virtuaalisia sovelluspisteitä',
      'selectLanguage': 'Valitse kieli',

      // ------------------------------------------------------
      // Mining
      // ------------------------------------------------------

      'stellaMining': 'Stella Mining',
      'stellaIsMining': 'STELLA LOUHII',
      'miningComplete': 'LOUHINTA VALMIS!',
      'stellaIsResting': 'STELLA LEPÄÄ',
      'stellaMiningNow':
          '🐾 Stella louhii STL:ää juuri nyt',
      'stlReadyToCollect':
          '🐱✨ STL on valmis kerättäväksi!',
      'stellaWaiting':
          '🐱 Stella odottaa seuraavaa louhintaa',
      'stlMined': 'LOUHITTU STL',
      'timeRemaining': 'AIKAA JÄLJELLÄ',
      'miningFinished': 'LOUHINTA PÄÄTTYNYT',
      'waitingForStella': 'ODOTETAAN STELLAA',
      'ready': 'VALMIS',
      'hashRate': 'HASH RATE',
      'totalStl': 'TOTAL STL',
      'stellaMiningProgress':
          '⛏️ STELLAN LOUHINNAN EDISTYMINEN',
      'stlPerHour': '⚡ {amount} STL / tunti',

      // ------------------------------------------------------
      // Mining buttons
      // ------------------------------------------------------

      'stellaIsWorking': 'STELLA TYÖSKENTELEE...',
      'stellaIsMiningButton':
          '🐱 STELLA LOUHII',
      'watchAdCollectRestart':
          '📺 KATSO MAINOS • KERÄÄ & ALOITA UUDELLEEN',
      'watchAdStartMining':
          '📺 KATSO MAINOS • ALOITA LOUHINTA',
      'stellaAlreadyMining':
          '🐱⛏️ Stella louhii jo STL:ää!',
      'prepareAd':
          '📺 Stella valmistelee mainosta...',
      'miningStarted':
          '🐱⛏️📺 Mainos katsottu! Stella aloitti 24 tunnin louhinnan!',
      'miningCollected':
          '🐱✨ Stella keräsi {amount} STL ja aloitti uuden 24h louhinnan! ⛏️',
      'miningStartFailed':
          '🐱 Louhinnan käynnistäminen epäonnistui.',

      // ------------------------------------------------------
      // Power Boost
      // ------------------------------------------------------

      'stellaPowerBoost': 'STELLA POWER BOOST',
      'watchAdHelpStella':
          'Katso mainos ja auta Stellaa ⚡',
      'watchAd': 'KATSO MAINOS',
      'adLoading': 'MAINOSTA LADATAAN...',
      'adUnavailable': 'MAINOS EI SAATAVILLA',
      'powerBoost': 'Power Boost',
      'hashRateBonus': '+{amount} Hash Rate',
      'dailyAds': 'Päivän mainokset',
      'dailyLimit': 'Päivän mainokset',
      'dailyLimitReached':
          'Päivän mainosraja saavutettu',
      'nextAd': 'Seuraava mainos',
      'adsToday': '{current} / {max} Power Boostia tänään',
      'stellaResting':
          '🐱 Stella lepää vielä {time}.',
      'testAdRewardFailed':
          '🐱 Mainospalkinnon tallentaminen epäonnistui.',
      'adRewardDuplicate':
          '🐱📺 Mainospalkinto on jo käsitelty.',
      'powerBoostReward':
          '🐱⚡ Stella sai +{amount} Hash Rate Power Boostin!',
      'powerBoostFailed':
          '🐱 Power Boost epäonnistui.',

      // ------------------------------------------------------
      // Daily Bonus
      // ------------------------------------------------------

      'dailyClaim': 'Päivittäinen palkinto',
      'dailyReward': 'LUNASTA PÄIVÄN PALKINTO',
      'claimed': 'Lunastettu tänään',
      'streak': 'Päiväputki',
      'stellaDailyBonus': 'STELLAN PÄIVÄBONUS',
      'dailyBonusDescription':
          '+{amount} Hash Rate • 🔥 {streak} päivän putki',
      'claimDailyBonus': '🎁 LUNASTA PÄIVÄBONUS',
      'bonusClaimedToday':
          '🐱 BONUS LUNASTETTU TÄNÄÄN',
      'dailyBonusAlreadyClaimed':
          '🐱 Stella Daily Bonus on jo kerätty tänään!',
      'dailyBonusSuccess':
          '🐱🎁 +{amount} Hash Rate! Putki: {streak} 🔥',
      'dailyBonusFailed':
          '🐱 Daily Bonus epäonnistui.',

      // ------------------------------------------------------
      // Cat Fact
      // ------------------------------------------------------

      'stellaFacts': 'Stellan kissafakta 🐱',

      // ------------------------------------------------------
      // Drawer / navigation
      // ------------------------------------------------------

      'menu': 'Stella Menu',
      'about': 'Tietoa Stelluriinista',
      'whitePaper': 'White Paper',
      'token': 'STL Token',
      'tokenomics': 'Tokenomics',
      'roadmap': 'Roadmap',
      'transactionHistory': 'Tapahtumahistoria',
      'comingSoon':
          '🐱✨ {title} tulee Stella-teemalla pian!',

      // ------------------------------------------------------
      // Footer
      // ------------------------------------------------------

      'footerTagline':
          'Stella louhii tulevaisuutta.',
      'footerToken':
          'STELLURIINI • STL',

      // ------------------------------------------------------
      // Existing app strings
      // ------------------------------------------------------

      'watchEarn': 'Katso ja ansaitse',
      'pointsAdded': '+3 STL lisätty!',
      'info': 'Tietoa Stelluriinista',
      'solanaToken':
          'Stelluriini (STL) on Solana-ekosysteemiin liittyvä token-projekti.',
      'stellaCompany':
          'STL-pisteet tässä sovelluksessa ovat sovelluksen sisäisiä virtuaalisia pisteitä.',
      'login': 'Kirjaudu sisään',
      'register': 'Luo tili',
      'email': 'Sähköposti',
      'password': 'Salasana',
      'logout': 'Kirjaudu ulos',
    },

    // ========================================================
    // 🇬🇧 ENGLISH
    // ========================================================

    'en': {
      // ------------------------------------------------------
      // General
      // ------------------------------------------------------

      'stella': 'Stella',
      'yourBalance': 'YOUR STL BALANCE',
      'virtualPoints': 'Virtual in-app points',
      'selectLanguage': 'Select language',

      // ------------------------------------------------------
      // Mining
      // ------------------------------------------------------

      'stellaMining': 'Stella Mining',
      'stellaIsMining': 'STELLA IS MINING',
      'miningComplete': 'MINING COMPLETE!',
      'stellaIsResting': 'STELLA IS RESTING',
      'stellaMiningNow':
          '🐾 Stella is mining STL right now',
      'stlReadyToCollect':
          '🐱✨ STL is ready to collect!',
      'stellaWaiting':
          '🐱 Stella is waiting for the next mining cycle',
      'stlMined': 'STL MINED',
      'timeRemaining': 'TIME REMAINING',
      'miningFinished': 'MINING FINISHED',
      'waitingForStella': 'WAITING FOR STELLA',
      'ready': 'READY',
      'hashRate': 'HASH RATE',
      'totalStl': 'TOTAL STL',
      'stellaMiningProgress':
          '⛏️ STELLA MINING PROGRESS',
      'stlPerHour': '⚡ {amount} STL / hour',

      // ------------------------------------------------------
      // Mining buttons
      // ------------------------------------------------------

      'stellaIsWorking': 'STELLA IS WORKING...',
      'stellaIsMiningButton':
          '🐱 STELLA IS MINING',
      'watchAdCollectRestart':
          '📺 WATCH AD • COLLECT & RESTART',
      'watchAdStartMining':
          '📺 WATCH AD • START MINING',
      'stellaAlreadyMining':
          '🐱⛏️ Stella is already mining STL!',
      'prepareAd':
          '📺 Stella is preparing an ad...',
      'miningStarted':
          '🐱⛏️📺 Ad watched! Stella started a 24-hour mining cycle!',
      'miningCollected':
          '🐱✨ Stella collected {amount} STL and started a new 24-hour mining cycle! ⛏️',
      'miningStartFailed':
          '🐱 Failed to start mining.',

      // ------------------------------------------------------
      // Power Boost
      // ------------------------------------------------------

      'stellaPowerBoost': 'STELLA POWER BOOST',
      'watchAdHelpStella':
          'Watch an ad and help Stella ⚡',
      'watchAd': 'WATCH AD',
      'adLoading': 'LOADING AD...',
      'adUnavailable': 'AD NOT AVAILABLE',
      'powerBoost': 'Power Boost',
      'hashRateBonus': '+{amount} Hash Rate',
      'dailyAds': 'Daily ads',
      'dailyLimit': 'Daily ads',
      'dailyLimitReached':
          'Daily ad limit reached',
      'nextAd': 'Next ad',
      'adsToday':
          '{current} / {max} Power Boosts today',
      'stellaResting':
          '🐱 Stella is resting for {time}.',
      'testAdRewardFailed':
          '🐱 Failed to save the ad reward.',
      'adRewardDuplicate':
          '🐱📺 The ad reward has already been processed.',
      'powerBoostReward':
          '🐱⚡ Stella received +{amount} Hash Rate from Power Boost!',
      'powerBoostFailed':
          '🐱 Power Boost failed.',

      // ------------------------------------------------------
      // Daily Bonus
      // ------------------------------------------------------

      'dailyClaim': 'Daily reward',
      'dailyReward': 'CLAIM DAILY REWARD',
      'claimed': 'Claimed today',
      'streak': 'Daily streak',
      'stellaDailyBonus': 'STELLA DAILY BONUS',
      'dailyBonusDescription':
          '+{amount} Hash Rate • 🔥 {streak} day streak',
      'claimDailyBonus': '🎁 CLAIM DAILY BONUS',
      'bonusClaimedToday':
          '🐱 BONUS CLAIMED TODAY',
      'dailyBonusAlreadyClaimed':
          '🐱 Stella Daily Bonus has already been claimed today!',
      'dailyBonusSuccess':
          '🐱🎁 +{amount} Hash Rate! Streak: {streak} 🔥',
      'dailyBonusFailed':
          '🐱 Daily Bonus failed.',

      // ------------------------------------------------------
      // Cat Fact
      // ------------------------------------------------------

      'stellaFacts': 'Stella’s cat fact 🐱',

      // ------------------------------------------------------
      // Drawer / navigation
      // ------------------------------------------------------

      'menu': 'Stella Menu',
      'about': 'About Stelluriini',
      'whitePaper': 'White Paper',
      'token': 'STL Token',
      'tokenomics': 'Tokenomics',
      'roadmap': 'Roadmap',
      'transactionHistory': 'Transaction History',
      'comingSoon':
          '🐱✨ {title} is coming soon with the Stella theme!',

      // ------------------------------------------------------
      // Footer
      // ------------------------------------------------------

      'footerTagline':
          'Stella is mining the future.',
      'footerToken':
          'STELLURIINI • STL',

      // ------------------------------------------------------
      // Existing app strings
      // ------------------------------------------------------

      'watchEarn': 'Watch and earn',
      'pointsAdded': '+3 STL added!',
      'info': 'About Stelluriini',
      'solanaToken':
          'Stelluriini (STL) is a token project connected to the Solana ecosystem.',
      'stellaCompany':
          'The STL points in this app are virtual in-app points.',
      'login': 'Log in',
      'register': 'Create account',
      'email': 'Email',
      'password': 'Password',
      'logout': 'Log out',
    },

    // ========================================================
    // 🇩🇪 DEUTSCH
    // ========================================================

    'de': {
      'stella': 'Stella',
      'yourBalance': 'DEIN STL-GUTHABEN',
      'virtualPoints': 'Virtuelle Punkte in der App',
      'selectLanguage': 'Sprache auswählen',

      'stellaMining': 'Stella Mining',
      'stellaIsMining': 'STELLA MINING',
      'miningComplete': 'MINING ABGESCHLOSSEN!',
      'stellaIsResting': 'STELLA RUHT',
      'stellaMiningNow':
          '🐾 Stella schürft gerade STL',
      'stlReadyToCollect':
          '🐱✨ STL kann eingesammelt werden!',
      'stellaWaiting':
          '🐱 Stella wartet auf den nächsten Mining-Zyklus',
      'stlMined': 'STL GEMINT',
      'timeRemaining': 'VERBLEIBENDE ZEIT',
      'miningFinished': 'MINING BEENDET',
      'waitingForStella': 'WARTE AUF STELLA',
      'ready': 'BEREIT',
      'hashRate': 'HASH RATE',
      'totalStl': 'GESAMT STL',
      'stellaMiningProgress':
          '⛏️ STELLAS MINING-FORTSCHRITT',
      'stlPerHour': '⚡ {amount} STL / Stunde',

      'stellaIsWorking': 'STELLA ARBEITET...',
      'stellaIsMiningButton':
          '🐱 STELLA MINING',
      'watchAdCollectRestart':
          '📺 WERBUNG • EINSAMMELN & NEU STARTEN',
      'watchAdStartMining':
          '📺 WERBUNG • MINING STARTEN',
      'stellaAlreadyMining':
          '🐱⛏️ Stella schürft bereits STL!',
      'prepareAd':
          '📺 Stella bereitet eine Werbung vor...',
      'miningStarted':
          '🐱⛏️📺 Werbung angesehen! Stella hat einen 24-Stunden-Mining-Zyklus gestartet!',
      'miningCollected':
          '🐱✨ Stella hat {amount} STL gesammelt und einen neuen 24-Stunden-Mining-Zyklus gestartet! ⛏️',
      'miningStartFailed':
          '🐱 Mining konnte nicht gestartet werden.',

      'stellaPowerBoost': 'STELLA POWER BOOST',
      'watchAdHelpStella':
          'Sieh eine Werbung und hilf Stella ⚡',
      'watchAd': 'WERBUNG ANSEHEN',
      'adLoading': 'WERBUNG WIRD GELADEN...',
      'adUnavailable': 'WERBUNG NICHT VERFÜGBAR',
      'powerBoost': 'Power Boost',
      'hashRateBonus': '+{amount} Hash Rate',
      'dailyAds': 'Tägliche Werbung',
      'dailyLimit': 'Tägliche Werbung',
      'dailyLimitReached':
          'Tägliches Werbelimit erreicht',
      'nextAd': 'Nächste Werbung',
      'adsToday':
          '{current} / {max} Power Boosts heute',
      'stellaResting':
          '🐱 Stella ruht noch {time}.',
      'testAdRewardFailed':
          '🐱 Die Werbeprämie konnte nicht gespeichert werden.',
      'adRewardDuplicate':
          '🐱📺 Die Werbeprämie wurde bereits verarbeitet.',
      'powerBoostReward':
          '🐱⚡ Stella erhielt +{amount} Hash Rate durch Power Boost!',
      'powerBoostFailed':
          '🐱 Power Boost fehlgeschlagen.',

      'dailyClaim': 'Tägliche Belohnung',
      'dailyReward': 'TAGESBELOHNUNG ABHOLEN',
      'claimed': 'Heute abgeholt',
      'streak': 'Tagesserie',
      'stellaDailyBonus': 'STELLAS TAGESBONUS',
      'dailyBonusDescription':
          '+{amount} Hash Rate • 🔥 {streak} Tage Serie',
      'claimDailyBonus': '🎁 TAGESBONUS ABHOLEN',
      'bonusClaimedToday':
          '🐱 BONUS HEUTE ABGEHOLT',
      'dailyBonusAlreadyClaimed':
          '🐱 Stellas Tagesbonus wurde heute bereits abgeholt!',
      'dailyBonusSuccess':
          '🐱🎁 +{amount} Hash Rate! Serie: {streak} 🔥',
      'dailyBonusFailed':
          '🐱 Tagesbonus fehlgeschlagen.',

      'stellaFacts': 'Stellas Katzenfakt 🐱',

      'menu': 'Stella Menü',
      'about': 'Über Stelluriini',
      'whitePaper': 'White Paper',
      'token': 'STL Token',
      'tokenomics': 'Tokenomics',
      'roadmap': 'Roadmap',
      'transactionHistory': 'Transaktionsverlauf',
      'comingSoon':
          '🐱✨ {title} kommt bald im Stella-Stil!',

      'footerTagline':
          'Stella schürft die Zukunft.',
      'footerToken':
          'STELLURIINI • STL',

      'watchEarn': 'Ansehen und verdienen',
      'pointsAdded': '+3 STL hinzugefügt!',
      'info': 'Über Stelluriini',
      'solanaToken':
          'Stelluriini (STL) ist ein Token-Projekt im Zusammenhang mit dem Solana-Ökosystem.',
      'stellaCompany':
          'Die STL-Punkte in dieser App sind virtuelle Punkte innerhalb der App.',
      'login': 'Anmelden',
      'register': 'Konto erstellen',
      'email': 'E-Mail',
      'password': 'Passwort',
      'logout': 'Abmelden',
    },

    // ========================================================
    // 🇪🇸 ESPAÑOL
    // ========================================================

    'es': {
      'stella': 'Stella',
      'yourBalance': 'TU SALDO DE STL',
      'virtualPoints': 'Puntos virtuales dentro de la aplicación',
      'selectLanguage': 'Seleccionar idioma',

      'stellaMining': 'Stella Mining',
      'stellaIsMining': 'STELLA ESTÁ MINANDO',
      'miningComplete': '¡MINERÍA COMPLETADA!',
      'stellaIsResting': 'STELLA ESTÁ DESCANSANDO',
      'stellaMiningNow':
          '🐾 Stella está minando STL ahora mismo',
      'stlReadyToCollect':
          '🐱✨ ¡STL listo para recoger!',
      'stellaWaiting':
          '🐱 Stella espera el próximo ciclo de minería',
      'stlMined': 'STL MINADO',
      'timeRemaining': 'TIEMPO RESTANTE',
      'miningFinished': 'MINERÍA TERMINADA',
      'waitingForStella': 'ESPERANDO A STELLA',
      'ready': 'LISTO',
      'hashRate': 'HASH RATE',
      'totalStl': 'TOTAL STL',
      'stellaMiningProgress':
          '⛏️ PROGRESO DE MINERÍA DE STELLA',
      'stlPerHour': '⚡ {amount} STL / hora',

      'stellaIsWorking': 'STELLA ESTÁ TRABAJANDO...',
      'stellaIsMiningButton':
          '🐱 STELLA ESTÁ MINANDO',
      'watchAdCollectRestart':
          '📺 VER ANUNCIO • RECOGER Y REINICIAR',
      'watchAdStartMining':
          '📺 VER ANUNCIO • INICIAR MINERÍA',
      'stellaAlreadyMining':
          '🐱⛏️ ¡Stella ya está minando STL!',
      'prepareAd':
          '📺 Stella está preparando un anuncio...',
      'miningStarted':
          '🐱⛏️📺 ¡Anuncio visto! Stella ha iniciado un ciclo de minería de 24 horas.',
      'miningCollected':
          '🐱✨ Stella recogió {amount} STL y comenzó un nuevo ciclo de minería de 24 horas. ⛏️',
      'miningStartFailed':
          '🐱 No se pudo iniciar la minería.',

      'stellaPowerBoost': 'STELLA POWER BOOST',
      'watchAdHelpStella':
          'Mira un anuncio y ayuda a Stella ⚡',
      'watchAd': 'VER ANUNCIO',
      'adLoading': 'CARGANDO ANUNCIO...',
      'adUnavailable': 'ANUNCIO NO DISPONIBLE',
      'powerBoost': 'Power Boost',
      'hashRateBonus': '+{amount} Hash Rate',
      'dailyAds': 'Anuncios diarios',
      'dailyLimit': 'Anuncios diarios',
      'dailyLimitReached':
          'Límite diario de anuncios alcanzado',
      'nextAd': 'Próximo anuncio',
      'adsToday':
          '{current} / {max} Power Boosts hoy',
      'stellaResting':
          '🐱 Stella está descansando durante {time}.',
      'testAdRewardFailed':
          '🐱 No se pudo guardar la recompensa del anuncio.',
      'adRewardDuplicate':
          '🐱📺 La recompensa del anuncio ya fue procesada.',
      'powerBoostReward':
          '🐱⚡ ¡Stella recibió +{amount} Hash Rate con Power Boost!',
      'powerBoostFailed':
          '🐱 Power Boost falló.',

      'dailyClaim': 'Recompensa diaria',
      'dailyReward': 'RECLAMAR RECOMPENSA DIARIA',
      'claimed': 'Reclamado hoy',
      'streak': 'Racha diaria',
      'stellaDailyBonus': 'BONO DIARIO DE STELLA',
      'dailyBonusDescription':
          '+{amount} Hash Rate • 🔥 racha de {streak} días',
      'claimDailyBonus': '🎁 RECLAMAR BONO DIARIO',
      'bonusClaimedToday':
          '🐱 BONO RECLAMADO HOY',
      'dailyBonusAlreadyClaimed':
          '🐱 ¡El bono diario de Stella ya fue reclamado hoy!',
      'dailyBonusSuccess':
          '🐱🎁 +{amount} Hash Rate! Racha: {streak} 🔥',
      'dailyBonusFailed':
          '🐱 El bono diario falló.',

      'stellaFacts': 'Dato curioso de Stella 🐱',

      'menu': 'Menú de Stella',
      'about': 'Sobre Stelluriini',
      'whitePaper': 'White Paper',
      'token': 'Token STL',
      'tokenomics': 'Tokenomics',
      'roadmap': 'Hoja de ruta',
      'transactionHistory': 'Historial de transacciones',
      'comingSoon':
          '🐱✨ {title} llegará pronto con el estilo de Stella.',

      'footerTagline':
          'Stella está minando el futuro.',
      'footerToken':
          'STELLURIINI • STL',

      'watchEarn': 'Mira y gana',
      'pointsAdded': '+3 STL añadidos!',
      'info': 'Sobre Stelluriini',
      'solanaToken':
          'Stelluriini (STL) es un proyecto de token relacionado con el ecosistema Solana.',
      'stellaCompany':
          'Los puntos STL de esta aplicación son puntos virtuales dentro de la aplicación.',
      'login': 'Iniciar sesión',
      'register': 'Crear cuenta',
      'email': 'Correo electrónico',
      'password': 'Contraseña',
      'logout': 'Cerrar sesión',
    },

    // ========================================================
    // 🇫🇷 FRANÇAIS
    // ========================================================

    'fr': {
      'stella': 'Stella',
      'yourBalance': 'TON SOLDE STL',
      'virtualPoints': 'Points virtuels dans l’application',
      'selectLanguage': 'Choisir la langue',

      'stellaMining': 'Stella Mining',
      'stellaIsMining': 'STELLA MINE',
      'miningComplete': 'MINAGE TERMINÉ !',
      'stellaIsResting': 'STELLA SE REPOSE',
      'stellaMiningNow':
          '🐾 Stella mine actuellement du STL',
      'stlReadyToCollect':
          '🐱✨ Le STL est prêt à être récupéré !',
      'stellaWaiting':
          '🐱 Stella attend le prochain cycle de minage',
      'stlMined': 'STL MINÉ',
      'timeRemaining': 'TEMPS RESTANT',
      'miningFinished': 'MINAGE TERMINÉ',
      'waitingForStella': 'EN ATTENTE DE STELLA',
      'ready': 'PRÊT',
      'hashRate': 'HASH RATE',
      'totalStl': 'TOTAL STL',
      'stellaMiningProgress':
          '⛏️ PROGRESSION DU MINAGE DE STELLA',
      'stlPerHour': '⚡ {amount} STL / heure',

      'stellaIsWorking': 'STELLA TRAVAILLE...',
      'stellaIsMiningButton':
          '🐱 STELLA MINE',
      'watchAdCollectRestart':
          '📺 REGARDER LA PUB • RÉCUPÉRER & RECOMMENCER',
      'watchAdStartMining':
          '📺 REGARDER LA PUB • COMMENCER LE MINAGE',
      'stellaAlreadyMining':
          '🐱⛏️ Stella mine déjà du STL !',
      'prepareAd':
          '📺 Stella prépare une publicité...',
      'miningStarted':
          '🐱⛏️📺 Publicité regardée ! Stella a commencé un cycle de minage de 24 heures !',
      'miningCollected':
          '🐱✨ Stella a récupéré {amount} STL et a commencé un nouveau cycle de minage de 24 heures ! ⛏️',
      'miningStartFailed':
          '🐱 Impossible de démarrer le minage.',

      'stellaPowerBoost': 'STELLA POWER BOOST',
      'watchAdHelpStella':
          'Regardez une publicité et aidez Stella ⚡',
      'watchAd': 'REGARDER LA PUB',
      'adLoading': 'CHARGEMENT DE LA PUB...',
      'adUnavailable': 'PUBLICITÉ NON DISPONIBLE',
      'powerBoost': 'Power Boost',
      'hashRateBonus': '+{amount} Hash Rate',
      'dailyAds': 'Publicités quotidiennes',
      'dailyLimit': 'Publicités quotidiennes',
      'dailyLimitReached':
          'Limite quotidienne atteinte',
      'nextAd': 'Prochaine publicité',
      'adsToday':
          '{current} / {max} Power Boosts aujourd’hui',
      'stellaResting':
          '🐱 Stella se repose encore {time}.',
      'testAdRewardFailed':
          '🐱 Impossible d’enregistrer la récompense publicitaire.',
      'adRewardDuplicate':
          '🐱📺 La récompense publicitaire a déjà été traitée.',
      'powerBoostReward':
          '🐱⚡ Stella a reçu +{amount} Hash Rate grâce au Power Boost !',
      'powerBoostFailed':
          '🐱 Échec du Power Boost.',

      'dailyClaim': 'Récompense quotidienne',
      'dailyReward': 'RÉCLAMER LA RÉCOMPENSE',
      'claimed': 'Réclamée aujourd’hui',
      'streak': 'Série quotidienne',
      'stellaDailyBonus': 'BONUS QUOTIDIEN DE STELLA',
      'dailyBonusDescription':
          '+{amount} Hash Rate • 🔥 série de {streak} jours',
      'claimDailyBonus': '🎁 RÉCLAMER LE BONUS QUOTIDIEN',
      'bonusClaimedToday':
          '🐱 BONUS RÉCLAMÉ AUJOURD’HUI',
      'dailyBonusAlreadyClaimed':
          '🐱 Le bonus quotidien de Stella a déjà été réclamé aujourd’hui !',
      'dailyBonusSuccess':
          '🐱🎁 +{amount} Hash Rate ! Série : {streak} 🔥',
      'dailyBonusFailed':
          '🐱 Échec du bonus quotidien.',

      'stellaFacts':
          'Le fait sur les chats de Stella 🐱',

      'menu': 'Menu de Stella',
      'about': 'À propos de Stelluriini',
      'whitePaper': 'White Paper',
      'token': 'Token STL',
      'tokenomics': 'Tokenomics',
      'roadmap': 'Feuille de route',
      'transactionHistory':
          'Historique des transactions',
      'comingSoon':
          '🐱✨ {title} arrive bientôt avec le style Stella !',

      'footerTagline':
          'Stella mine l’avenir.',
      'footerToken':
          'STELLURIINI • STL',

      'watchEarn': 'Regarder et gagner',
      'pointsAdded': '+3 STL ajoutés !',
      'info': 'À propos de Stelluriini',
      'solanaToken':
          'Stelluriini (STL) est un projet de token lié à l’écosystème Solana.',
      'stellaCompany':
          'Les points STL dans cette application sont des points virtuels internes.',
      'login': 'Se connecter',
      'register': 'Créer un compte',
      'email': 'E-mail',
      'password': 'Mot de passe',
      'logout': 'Se déconnecter',
    },

    // ========================================================
    // 🇨🇳 中文
    // ========================================================

    'zh': {
      'stella': 'Stella',
      'yourBalance': '你的 STL 余额',
      'virtualPoints': '应用内虚拟积分',
      'selectLanguage': '选择语言',

      'stellaMining': 'Stella 挖矿',
      'stellaIsMining': 'STELLA 正在挖矿',
      'miningComplete': '挖矿完成！',
      'stellaIsResting': 'STELLA 正在休息',
      'stellaMiningNow':
          '🐾 Stella 正在挖掘 STL',
      'stlReadyToCollect':
          '🐱✨ STL 已准备好领取！',
      'stellaWaiting':
          '🐱 Stella 正在等待下一轮挖矿',
      'stlMined': '已挖出 STL',
      'timeRemaining': '剩余时间',
      'miningFinished': '挖矿结束',
      'waitingForStella': '等待 Stella',
      'ready': '准备好了',
      'hashRate': '算力',
      'totalStl': 'STL 总量',
      'stellaMiningProgress':
          '⛏️ STELLA 挖矿进度',
      'stlPerHour': '⚡ {amount} STL / 小时',

      'stellaIsWorking': 'STELLA 正在工作...',
      'stellaIsMiningButton':
          '🐱 STELLA 正在挖矿',
      'watchAdCollectRestart':
          '📺 观看广告 • 领取并重新开始',
      'watchAdStartMining':
          '📺 观看广告 • 开始挖矿',
      'stellaAlreadyMining':
          '🐱⛏️ Stella 已经在挖 STL 了！',
      'prepareAd':
          '📺 Stella 正在准备广告...',
      'miningStarted':
          '🐱⛏️📺 广告已观看！Stella 开始了 24 小时挖矿！',
      'miningCollected':
          '🐱✨ Stella 收集了 {amount} STL，并开始了新的 24 小时挖矿！⛏️',
      'miningStartFailed':
          '🐱 无法开始挖矿。',

      'stellaPowerBoost': 'STELLA POWER BOOST',
      'watchAdHelpStella':
          '观看广告帮助 Stella ⚡',
      'watchAd': '观看广告',
      'adLoading': '正在加载广告...',
      'adUnavailable': '广告暂时不可用',
      'powerBoost': 'Power Boost',
      'hashRateBonus': '+{amount} 算力',
      'dailyAds': '每日广告',
      'dailyLimit': '每日广告',
      'dailyLimitReached':
          '已达到每日广告限制',
      'nextAd': '下一次广告',
      'adsToday':
          '今天的 Power Boost：{current} / {max}',
      'stellaResting':
          '🐱 Stella 还需要休息 {time}。',
      'testAdRewardFailed':
          '🐱 无法保存广告奖励。',
      'adRewardDuplicate':
          '🐱📺 广告奖励已经处理过了。',
      'powerBoostReward':
          '🐱⚡ Stella 通过 Power Boost 获得了 +{amount} 算力！',
      'powerBoostFailed':
          '🐱 Power Boost 失败。',

      'dailyClaim': '每日奖励',
      'dailyReward': '领取每日奖励',
      'claimed': '今天已领取',
      'streak': '连续签到',
      'stellaDailyBonus': 'STELLA 每日奖励',
      'dailyBonusDescription':
          '+{amount} 算力 • 🔥 连续 {streak} 天',
      'claimDailyBonus': '🎁 领取每日奖励',
      'bonusClaimedToday':
          '🐱 今天已领取奖励',
      'dailyBonusAlreadyClaimed':
          '🐱 Stella 的每日奖励今天已经领取过了！',
      'dailyBonusSuccess':
          '🐱🎁 +{amount} 算力！连续签到：{streak} 🔥',
      'dailyBonusFailed':
          '🐱 每日奖励失败。',

      'stellaFacts':
          'Stella 的猫咪知识 🐱',

      'menu': 'Stella 菜单',
      'about': '关于 Stelluriini',
      'whitePaper': '白皮书',
      'token': 'STL 代币',
      'tokenomics': '代币经济学',
      'roadmap': '路线图',
      'transactionHistory': '交易记录',
      'comingSoon':
          '🐱✨ {title} 即将以 Stella 风格推出！',

      'footerTagline':
          'Stella 正在挖掘未来。',
      'footerToken':
          'STELLURIINI • STL',

      'watchEarn': '观看并赚取',
      'pointsAdded': '已添加 +3 STL！',
      'info': '关于 Stelluriini',
      'solanaToken':
          'Stelluriini (STL) 是一个与 Solana 生态系统相关的代币项目。',
      'stellaCompany':
          '此应用中的 STL 积分是应用内的虚拟积分。',
      'login': '登录',
      'register': '创建账户',
      'email': '电子邮箱',
      'password': '密码',
      'logout': '退出登录',
    },

    // ========================================================
    // 🇻🇳 TIẾNG VIỆT
    // ========================================================

    'vi': {
      'stella': 'Stella',
      'yourBalance': 'SỐ DƯ STL CỦA BẠN',
      'virtualPoints': 'Điểm ảo trong ứng dụng',
      'selectLanguage': 'Chọn ngôn ngữ',

      'stellaMining': 'Stella Mining',
      'stellaIsMining': 'STELLA ĐANG ĐÀO',
      'miningComplete': 'ĐÃ ĐÀO XONG!',
      'stellaIsResting': 'STELLA ĐANG NGHỈ',
      'stellaMiningNow':
          '🐾 Stella đang đào STL ngay bây giờ',
      'stlReadyToCollect':
          '🐱✨ STL đã sẵn sàng để nhận!',
      'stellaWaiting':
          '🐱 Stella đang chờ chu kỳ đào tiếp theo',
      'stlMined': 'STL ĐÃ ĐÀO',
      'timeRemaining': 'THỜI GIAN CÒN LẠI',
      'miningFinished': 'ĐÃ KẾT THÚC ĐÀO',
      'waitingForStella': 'ĐANG CHỜ STELLA',
      'ready': 'SẴN SÀNG',
      'hashRate': 'HASH RATE',
      'totalStl': 'TỔNG STL',
      'stellaMiningProgress':
          '⛏️ TIẾN ĐỘ ĐÀO CỦA STELLA',
      'stlPerHour': '⚡ {amount} STL / giờ',

      'stellaIsWorking': 'STELLA ĐANG LÀM VIỆC...',
      'stellaIsMiningButton':
          '🐱 STELLA ĐANG ĐÀO',
      'watchAdCollectRestart':
          '📺 XEM QUẢNG CÁO • NHẬN & ĐÀO LẠI',
      'watchAdStartMining':
          '📺 XEM QUẢNG CÁO • BẮT ĐẦU ĐÀO',
      'stellaAlreadyMining':
          '🐱⛏️ Stella đang đào STL rồi!',
      'prepareAd':
          '📺 Stella đang chuẩn bị quảng cáo...',
      'miningStarted':
          '🐱⛏️📺 Đã xem quảng cáo! Stella bắt đầu chu kỳ đào 24 giờ!',
      'miningCollected':
          '🐱✨ Stella đã nhận {amount} STL và bắt đầu chu kỳ đào 24 giờ mới! ⛏️',
      'miningStartFailed':
          '🐱 Không thể bắt đầu đào.',

      'stellaPowerBoost': 'STELLA POWER BOOST',
      'watchAdHelpStella':
          'Xem quảng cáo và giúp Stella ⚡',
      'watchAd': 'XEM QUẢNG CÁO',
      'adLoading': 'ĐANG TẢI QUẢNG CÁO...',
      'adUnavailable': 'QUẢNG CÁO KHÔNG KHẢ DỤNG',
      'powerBoost': 'Power Boost',
      'hashRateBonus': '+{amount} Hash Rate',
      'dailyAds': 'Quảng cáo hàng ngày',
      'dailyLimit': 'Quảng cáo mỗi ngày',
      'dailyLimitReached':
          'Đã đạt giới hạn quảng cáo hàng ngày',
      'nextAd': 'Quảng cáo tiếp theo',
      'adsToday':
          '{current} / {max} Power Boost hôm nay',
      'stellaResting':
          '🐱 Stella đang nghỉ thêm {time}.',
      'testAdRewardFailed':
          '🐱 Không thể lưu phần thưởng quảng cáo.',
      'adRewardDuplicate':
          '🐱📺 Phần thưởng quảng cáo đã được xử lý.',
      'powerBoostReward':
          '🐱⚡ Stella nhận được +{amount} Hash Rate từ Power Boost!',
      'powerBoostFailed':
          '🐱 Power Boost thất bại.',

      'dailyClaim': 'Phần thưởng hàng ngày',
      'dailyReward': 'NHẬN PHẦN THƯỞNG HÀNG NGÀY',
      'claimed': 'Đã nhận hôm nay',
      'streak': 'Chuỗi ngày liên tiếp',
      'stellaDailyBonus': 'THƯỞNG HÀNG NGÀY CỦA STELLA',
      'dailyBonusDescription':
          '+{amount} Hash Rate • 🔥 chuỗi {streak} ngày',
      'claimDailyBonus':
          '🎁 NHẬN THƯỞNG HÀNG NGÀY',
      'bonusClaimedToday':
          '🐱 ĐÃ NHẬN THƯỞNG HÔM NAY',
      'dailyBonusAlreadyClaimed':
          '🐱 Phần thưởng hàng ngày của Stella đã được nhận hôm nay!',
      'dailyBonusSuccess':
          '🐱🎁 +{amount} Hash Rate! Chuỗi: {streak} 🔥',
      'dailyBonusFailed':
          '🐱 Nhận thưởng hàng ngày thất bại.',

      'stellaFacts':
          'Sự thật về mèo của Stella 🐱',

      'menu': 'Menu Stella',
      'about': 'Thông tin về Stelluriini',
      'whitePaper': 'White Paper',
      'token': 'Token STL',
      'tokenomics': 'Tokenomics',
      'roadmap': 'Lộ trình',
      'transactionHistory':
          'Lịch sử giao dịch',
      'comingSoon':
          '🐱✨ {title} sẽ sớm ra mắt với phong cách Stella!',

      'footerTagline':
          'Stella đang đào tương lai.',
      'footerToken':
          'STELLURIINI • STL',

      'watchEarn': 'Xem và nhận thưởng',
      'pointsAdded': 'Đã thêm +3 STL!',
      'info': 'Thông tin về Stelluriini',
      'solanaToken':
          'Stelluriini (STL) là một dự án token liên quan đến hệ sinh thái Solana.',
      'stellaCompany':
          'Điểm STL trong ứng dụng này là điểm ảo bên trong ứng dụng.',
      'login': 'Đăng nhập',
      'register': 'Tạo tài khoản',
      'email': 'Email',
      'password': 'Mật khẩu',
      'logout': 'Đăng xuất',
    },

    // ========================================================
    // 🇯🇵 日本語
    // ========================================================

    'ja': {
      'stella': 'Stella',
      'yourBalance': 'あなたの STL 残高',
      'virtualPoints': 'アプリ内の仮想ポイント',
      'selectLanguage': '言語を選択',

      'stellaMining': 'Stella Mining',
      'stellaIsMining': 'STELLA は採掘中',
      'miningComplete': '採掘完了！',
      'stellaIsResting': 'STELLA は休憩中',
      'stellaMiningNow':
          '🐾 Stella は今 STL を採掘しています',
      'stlReadyToCollect':
          '🐱✨ STL を受け取る準備ができました！',
      'stellaWaiting':
          '🐱 Stella は次の採掘サイクルを待っています',
      'stlMined': '採掘済み STL',
      'timeRemaining': '残り時間',
      'miningFinished': '採掘終了',
      'waitingForStella': 'STELLA を待っています',
      'ready': '準備完了',
      'hashRate': 'ハッシュレート',
      'totalStl': 'STL 合計',
      'stellaMiningProgress':
          '⛏️ STELLA 採掘進行状況',
      'stlPerHour': '⚡ {amount} STL / 時間',

      'stellaIsWorking': 'STELLA が作業中...',
      'stellaIsMiningButton':
          '🐱 STELLA は採掘中',
      'watchAdCollectRestart':
          '📺 広告を見る • 受け取って再スタート',
      'watchAdStartMining':
          '📺 広告を見る • 採掘を開始',
      'stellaAlreadyMining':
          '🐱⛏️ Stella はすでに STL を採掘中です！',
      'prepareAd':
          '📺 Stella が広告を準備しています...',
      'miningStarted':
          '🐱⛏️📺 広告を視聴しました！Stella が24時間の採掘を開始しました！',
      'miningCollected':
          '🐱✨ Stella は {amount} STL を受け取り、新しい24時間の採掘を開始しました！⛏️',
      'miningStartFailed':
          '🐱 採掘を開始できませんでした。',

      'stellaPowerBoost': 'STELLA POWER BOOST',
      'watchAdHelpStella':
          '広告を見て Stella を助けよう ⚡',
      'watchAd': '広告を見る',
      'adLoading': '広告を読み込み中...',
      'adUnavailable': '広告を利用できません',
      'powerBoost': 'Power Boost',
      'hashRateBonus': '+{amount} ハッシュレート',
      'dailyAds': '毎日の広告',
      'dailyLimit': '1日の広告',
      'dailyLimitReached':
          '1日の広告上限に達しました',
      'nextAd': '次の広告',
      'adsToday':
          '本日の Power Boost: {current} / {max}',
      'stellaResting':
          '🐱 Stella はあと {time} 休憩します。',
      'testAdRewardFailed':
          '🐱 広告報酬を保存できませんでした。',
      'adRewardDuplicate':
          '🐱📺 広告報酬はすでに処理されています。',
      'powerBoostReward':
          '🐱⚡ Power Boost で Stella が +{amount} ハッシュレートを獲得しました！',
      'powerBoostFailed':
          '🐱 Power Boost に失敗しました。',

      'dailyClaim': '毎日の報酬',
      'dailyReward': '毎日の報酬を受け取る',
      'claimed': '本日は受け取り済み',
      'streak': '連続記録',
      'stellaDailyBonus': 'STELLA デイリーボーナス',
      'dailyBonusDescription':
          '+{amount} ハッシュレート • 🔥 {streak}日連続',
      'claimDailyBonus':
          '🎁 デイリーボーナスを受け取る',
      'bonusClaimedToday':
          '🐱 本日のボーナスは受け取り済み',
      'dailyBonusAlreadyClaimed':
          '🐱 Stella のデイリーボーナスは本日すでに受け取っています！',
      'dailyBonusSuccess':
          '🐱🎁 +{amount} ハッシュレート！連続記録：{streak} 🔥',
      'dailyBonusFailed':
          '🐱 デイリーボーナスに失敗しました。',

      'stellaFacts':
          'Stella の猫の豆知識 🐱',

      'menu': 'Stella メニュー',
      'about': 'Stelluriini について',
      'whitePaper': 'ホワイトペーパー',
      'token': 'STL トークン',
      'tokenomics': 'トークノミクス',
      'roadmap': 'ロードマップ',
      'transactionHistory':
          '取引履歴',
      'comingSoon':
          '🐱✨ {title} は Stella テーマで近日公開！',

      'footerTagline':
          'Stella は未来を採掘しています。',
      'footerToken':
          'STELLURIINI • STL',

      'watchEarn': '視聴して獲得',
      'pointsAdded': '+3 STL を追加しました！',
      'info': 'Stelluriini について',
      'solanaToken':
          'Stelluriini（STL）は、Solanaエコシステムに関連するトークンプロジェクトです。',
      'stellaCompany':
          'このアプリ内のSTLポイントは仮想的なアプリ内ポイントです。',
      'login': 'ログイン',
      'register': 'アカウントを作成',
      'email': 'メールアドレス',
      'password': 'パスワード',
      'logout': 'ログアウト',
    },
  };

  // ==========================================================
  // 🔤 GET TRANSLATION
  // ==========================================================

  String get(String key) {
    return _translations[languageCode]?[key] ??
        _translations['en']?[key] ??
        _translations['fi']?[key] ??
        key;
  }

  // ==========================================================
  // 🔤 GET TRANSLATION WITH PARAMETERS
  // ==========================================================

  String getWithParams(
    String key, {
    Map<String, String> params = const {},
  }) {
    String text = get(key);

    for (final MapEntry<String, String> entry
        in params.entries) {
      text = text.replaceAll(
        '{${entry.key}}',
        entry.value,
      );
    }

    return text;
  }
}