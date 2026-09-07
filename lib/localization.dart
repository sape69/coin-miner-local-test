import 'package:flutter/material.dart';

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
  // 🐱 TRANSLATIONS
  // ============================================================

  static const Map<String, Map<String, String>> _translations = {
    // ============================================================
    // 🇫🇮 FINNISH
    // ============================================================

    'fi': {
      'appTitle': 'STELLURIINI',
      'home': 'Etusivu',
      'about': 'Tietoa',
      'history': 'Tapahtumahistoria',
      'roadmap': 'Tiekartta',
      'token': 'STL Token',
      'tokenomics': 'Tokenomiikka',
      'whitepaper': 'Whitepaper',
      'language': 'Kieli',
      'logout': 'Kirjaudu ulos',
      'menu': 'Valikko',

      'balance': 'Saldo',
      'mining': 'Louhinta',
      'miningRate': 'Louhintanopeus',
      'hashRate': 'Hash Rate',
      'effectiveHashRate': 'Tehokas Hash Rate',
      'effectiveHashRateLabel': 'Tehokas Hash Rate',

      'dailyHashRateLabel': 'Päivittäinen Hash Rate',
      'dailyHashRateDay': 'Päivä {day}',
      'dailyHashRateMaximum': 'Maksimi: {rate} HR',
      'dailyHashRateSuccess': 'Päivän {day} Hash Rate: {rate} HR',

      'stellaMiningProgress': 'Stellan louhinnan edistyminen',
      'stlPerHour': 'STL tunnissa',
      'hashRateBonus': 'Hash Rate -bonus',

      'startMining': 'ALOITA LOUHINTA',
      'claimMining': 'KERÄÄ STL',
      'miningActive': 'Louhinta käynnissä',
      'miningComplete': 'Louhintajakso valmis',

      'timeRemaining': 'Aikaa jäljellä',
      'remaining': 'Aikaa jäljellä: {time}',

      'streak': 'Putki',
      'days': 'päivää',

      'dailyBonus': 'Päivittäinen bonus',
      'dailyClaim': 'Kerää päivittäinen bonus',
      'dailyReward': 'Päivittäinen palkinto',
      'claimedToday': 'Kerätty tänään',
      'alreadyClaimed': 'Olet jo kerännyt tämän päivän palkinnon.',

      'watchAd': 'KATSO MAINOS',
      'watchAndEarn': 'KATSO & ANSAITSE',
      'loadingAd': 'LADATAAN MAINOSTA...',
      'adLoading': 'LADATAAN MAINOSTA...',
      'adReward': '+{amount} HR',

      'powerBoost': 'Stella Power Boost',
      'powerBoostOffer':
          'Katso mainos ja aktivoi +{amount} HR Stella Power Boost 4 tunniksi.',
      'powerBoostActive': 'Power Boost aktiivinen',
      'powerBoostActiveTitle': 'Stella Power Boost on aktiivinen!',
      'powerBoostActiveMessage':
          '+{amount} HR on käytössä louhintasiirron aikana.',
      'powerBoostAlreadyActive': 'Power Boost on jo aktiivinen.',
      'nextPowerBoostMessage':
          'Seuraava Power Boost on saatavilla, kun nykyinen boost päättyy.',
      'nextAdAfterBoost':
          'Seuraava mainos on saatavilla boostin päätyttyä.',
      'maxBoostsInfo':
          'Voit aktivoida enintään {count} Power Boostia päivässä.',
      'adsToday': 'Mainoksia tänään: {current}/{max}',
      'dailyLimitReached': 'Päivittäinen mainosraja on saavutettu.',
      'powerBoostReward': 'Stella Power Boost: +{amount} HR',
      'adRewardDuplicate': 'Tämä mainospalkinto on jo käsitelty.',
      'testAdRewardFailed': 'Mainospalkinnon käsittely epäonnistui.',

      'serverConnectionFailed': 'Palvelinyhteys epäonnistui.',
      'refresh': 'Päivitä',

      'profile': 'Profiili',
      'comingSoon': 'Tulossa pian',
      'information': 'Tietoa',

      'catFact': 'Stellan kissafakta',
      'stellaFacts': 'Stellan kissafakta',
      'stellaPower': 'Stella Power',
      'stellaMining': 'Stella Mining',

      'transactions': 'Tapahtumat',
      'noTransactions': 'Ei tapahtumia vielä.',
      'totalStl': 'STL yhteensä',

      'points': 'pistettä',
      'pointsAdded': 'Pisteitä lisätty',

      'resetAccount': 'Nollaa testitili',
      'resetConfirm': 'Haluatko varmasti nollata testitilin?',

      'cancel': 'Peruuta',
      'reset': 'Nollaa',
      'error': 'Virhe',
      'success': 'Onnistui',
      'close': 'Sulje',

      'stellaIsMining': 'Stella louhii',
      'stellaMiningNow': 'Stella louhii juuri nyt',
      'stellaIsResting': 'Stella lepää',
      'stellaWaiting': 'Stella odottaa seuraavaa louhintaa',
      'stlReadyToCollect': 'STL on valmis kerättäväksi',
      'stlMined': 'LOUHITTU STL',
      'waitingForStella': 'Odotetaan Stellaa',

      'stellaIsWorking': 'STELLA TYÖSKENTELEE...',
      'stellaIsMiningButton': 'LOUHINTA KÄYNNISSÄ',
      'stellaAlreadyMining': 'Stella louhii jo.',
      'prepareAd': 'Valmistellaan mainosta...',
      'miningCollected': 'Kerätty {amount} STL',
      'miningStartFailed': 'Louhinnan aloittaminen epäonnistui.',

      // ==========================================================
      // TRANSACTION HISTORY
      // ==========================================================

      'transactionHistory': 'Tapahtumahistoria',
      'stellaActivity': 'STELLAN AKTIIVISUUS',
      'latestTransactions': '{count} viimeisintä tapahtumaa',
      'dailyStellaBonus': 'Stellan päivittäinen bonus',
      'dailyBonusDescription': 'Päivittäinen bonus Stellalta',
      'stellaAdReward': 'Stellan mainospalkinto',
      'adRewardDescription': 'Palkinto katsotusta mainoksesta',
      'stlTransaction': 'STL-tapahtuma',
      'stelluriiniActivity': 'Stelluriini-aktiviteetti',
      'transactionBalance': 'Saldo: {balance} STL',
      'tryAgain': 'Yritä uudelleen',
      'noTransactionsYet': 'Ei tapahtumia vielä',
      'rewardsAppearHere': 'STL-palkintosi näkyvät täällä. 🐱',
      'startMiningWithStella': 'Aloita louhinta Stellan kanssa',
      'historyRecorded':
          'Louhinta, päivittäiset bonukset ja mainospalkinnot tallennetaan tänne.',
      'stellaCheckingHistory': 'Stella tarkistaa historiaasi...',
      'everyRewardJourney':
          'Jokainen palkinto on osa Stelluriini-matkaasi. 🐾',

      // Footer
      'footerTagline': 'Louhitaan yhdessä Stelluriinin tulevaisuutta.',
      'footerToken': 'STL • STELLURIINI',
    },

    // ============================================================
    // 🇬🇧 ENGLISH
    // ============================================================

    'en': {
      'appTitle': 'STELLURIINI',
      'home': 'Home',
      'about': 'About',
      'history': 'Transaction History',
      'roadmap': 'Roadmap',
      'token': 'STL Token',
      'tokenomics': 'Tokenomics',
      'whitepaper': 'Whitepaper',
      'language': 'Language',
      'logout': 'Log out',
      'menu': 'Menu',

      'balance': 'Balance',
      'mining': 'Mining',
      'miningRate': 'Mining Rate',
      'hashRate': 'Hash Rate',
      'effectiveHashRate': 'Effective Hash Rate',
      'effectiveHashRateLabel': 'Effective Hash Rate',

      'dailyHashRateLabel': 'Daily Hash Rate',
      'dailyHashRateDay': 'Day {day}',
      'dailyHashRateMaximum': 'Maximum: {rate} HR',
      'dailyHashRateSuccess': 'Day {day} Hash Rate: {rate} HR',

      'stellaMiningProgress': 'Stella Mining Progress',
      'stlPerHour': 'STL per hour',
      'hashRateBonus': 'Hash Rate Bonus',

      'startMining': 'START MINING',
      'claimMining': 'CLAIM STL',
      'miningActive': 'Mining active',
      'miningComplete': 'Mining cycle complete',

      'timeRemaining': 'Time remaining',
      'remaining': 'Time remaining: {time}',

      'streak': 'Streak',
      'days': 'days',

      'dailyBonus': 'Daily Bonus',
      'dailyClaim': 'Claim Daily Bonus',
      'dailyReward': 'Daily Reward',
      'claimedToday': 'Claimed today',
      'alreadyClaimed':
          'You have already claimed today’s reward.',

      'watchAd': 'WATCH AD',
      'watchAndEarn': 'WATCH & EARN',
      'loadingAd': 'LOADING AD...',
      'adLoading': 'LOADING AD...',
      'adReward': '+{amount} HR',

      'powerBoost': 'Stella Power Boost',
      'powerBoostOffer':
          'Watch an ad to activate +{amount} HR Stella Power Boost for 4 hours.',
      'powerBoostActive': 'Power Boost active',
      'powerBoostActiveTitle':
          'Stella Power Boost is active!',
      'powerBoostActiveMessage':
          '+{amount} HR is active during your mining cycle.',
      'powerBoostAlreadyActive':
          'Power Boost is already active.',
      'nextPowerBoostMessage':
          'The next Power Boost is available when the current boost ends.',
      'nextAdAfterBoost':
          'The next ad is available after the boost ends.',
      'maxBoostsInfo':
          'You can activate up to {count} Power Boosts per day.',
      'adsToday': 'Ads today: {current}/{max}',
      'dailyLimitReached': 'Daily ad limit reached.',
      'powerBoostReward': 'Stella Power Boost: +{amount} HR',
      'adRewardDuplicate':
          'This ad reward has already been processed.',
      'testAdRewardFailed':
          'Failed to process the ad reward.',

      'serverConnectionFailed': 'Server connection failed.',
      'refresh': 'Refresh',

      'profile': 'Profile',
      'comingSoon': 'Coming Soon',
      'information': 'Information',

      'catFact': 'Stella Cat Fact',
      'stellaFacts': 'Stella Cat Fact',
      'stellaPower': 'Stella Power',
      'stellaMining': 'Stella Mining',

      'transactions': 'Transactions',
      'noTransactions': 'No transactions yet.',
      'totalStl': 'Total STL',

      'points': 'points',
      'pointsAdded': 'Points added',

      'resetAccount': 'Reset Test Account',
      'resetConfirm':
          'Are you sure you want to reset the test account?',

      'cancel': 'Cancel',
      'reset': 'Reset',
      'error': 'Error',
      'success': 'Success',
      'close': 'Close',

      'stellaIsMining': 'Stella is mining',
      'stellaMiningNow': 'Stella is mining right now',
      'stellaIsResting': 'Stella is resting',
      'stellaWaiting':
          'Stella is waiting for the next mining cycle',
      'stlReadyToCollect': 'STL is ready to collect',
      'stlMined': 'STL MINED',
      'waitingForStella': 'Waiting for Stella',

      'stellaIsWorking': 'STELLA IS WORKING...',
      'stellaIsMiningButton': 'MINING ACTIVE',
      'stellaAlreadyMining': 'Stella is already mining.',
      'prepareAd': 'Preparing ad...',
      'miningCollected': 'Collected {amount} STL',
      'miningStartFailed': 'Failed to start mining.',

      // Transaction History
      'transactionHistory': 'Transaction History',
      'stellaActivity': 'STELLA ACTIVITY',
      'latestTransactions': '{count} latest transactions',
      'dailyStellaBonus': 'Daily Stella Bonus',
      'dailyBonusDescription': 'Daily bonus from Stella',
      'stellaAdReward': 'Stella Ad Reward',
      'adRewardDescription': 'Rewarded ad bonus',
      'stlTransaction': 'STL Transaction',
      'stelluriiniActivity': 'Stelluriini activity',
      'transactionBalance': 'Balance: {balance} STL',
      'tryAgain': 'Try Again',
      'noTransactionsYet': 'No transactions yet',
      'rewardsAppearHere':
          'Your STL rewards will appear here. 🐱',
      'startMiningWithStella':
          'Start mining with Stella',
      'historyRecorded':
          'Your mining, daily bonuses and ad rewards will be recorded here.',
      'stellaCheckingHistory':
          'Stella is checking your history...',
      'everyRewardJourney':
          'Every reward is part of your Stelluriini journey. 🐾',

      // Footer
      'footerTagline':
          'Mining together for the future of Stelluriini.',
      'footerToken': 'STL • STELLURIINI',
    },

    // ============================================================
    // 🇩🇪 GERMAN
    // ============================================================

    'de': {
      'appTitle': 'STELLURIINI',
      'home': 'Startseite',
      'about': 'Über uns',
      'history': 'Transaktionsverlauf',
      'roadmap': 'Roadmap',
      'token': 'STL Token',
      'tokenomics': 'Tokenomics',
      'whitepaper': 'Whitepaper',
      'language': 'Sprache',
      'logout': 'Abmelden',
      'menu': 'Menü',

      'balance': 'Guthaben',
      'mining': 'Mining',
      'miningRate': 'Mining-Rate',
      'hashRate': 'Hash Rate',
      'effectiveHashRate': 'Effektive Hash Rate',
      'effectiveHashRateLabel': 'Effektive Hash Rate',

      'dailyHashRateLabel': 'Tägliche Hash Rate',
      'dailyHashRateDay': 'Tag {day}',
      'dailyHashRateMaximum': 'Maximum: {rate} HR',
      'dailyHashRateSuccess':
          'Hash Rate an Tag {day}: {rate} HR',

      'stellaMiningProgress': 'Stellas Mining-Fortschritt',
      'stlPerHour': 'STL pro Stunde',
      'hashRateBonus': 'Hash-Rate-Bonus',

      'startMining': 'MINING STARTEN',
      'claimMining': 'STL EINSAMMELN',
      'miningActive': 'Mining aktiv',
      'miningComplete': 'Mining-Zyklus abgeschlossen',

      'timeRemaining': 'Verbleibende Zeit',
      'remaining': 'Verbleibende Zeit: {time}',

      'streak': 'Serie',
      'days': 'Tage',

      'dailyBonus': 'Täglicher Bonus',
      'dailyClaim': 'Täglichen Bonus sammeln',
      'dailyReward': 'Tägliche Belohnung',
      'claimedToday': 'Heute gesammelt',
      'alreadyClaimed':
          'Du hast die heutige Belohnung bereits gesammelt.',

      'watchAd': 'WERBUNG ANSEHEN',
      'watchAndEarn': 'ANSEHEN & VERDIENEN',
      'loadingAd': 'WERBUNG WIRD GELADEN...',
      'adLoading': 'WERBUNG WIRD GELADEN...',
      'adReward': '+{amount} HR',

      'powerBoost': 'Stella Power Boost',
      'powerBoostOffer':
          'Werbung ansehen und +{amount} HR Stella Power Boost für 4 Stunden aktivieren.',
      'powerBoostActive': 'Power Boost aktiv',
      'powerBoostActiveTitle':
          'Stella Power Boost ist aktiv!',
      'powerBoostActiveMessage':
          '+{amount} HR ist während deines Mining-Zyklus aktiv.',
      'powerBoostAlreadyActive':
          'Power Boost ist bereits aktiv.',
      'nextPowerBoostMessage':
          'Der nächste Power Boost ist verfügbar, wenn der aktuelle Boost endet.',
      'nextAdAfterBoost':
          'Die nächste Werbung ist nach Ende des Boosts verfügbar.',
      'maxBoostsInfo':
          'Du kannst bis zu {count} Power Boosts pro Tag aktivieren.',
      'adsToday': 'Werbung heute: {current}/{max}',
      'dailyLimitReached': 'Tägliches Werbelimit erreicht.',
      'powerBoostReward': 'Stella Power Boost: +{amount} HR',
      'adRewardDuplicate':
          'Diese Werbeprämie wurde bereits verarbeitet.',
      'testAdRewardFailed':
          'Die Werbeprämie konnte nicht verarbeitet werden.',

      'serverConnectionFailed':
          'Serververbindung fehlgeschlagen.',
      'refresh': 'Aktualisieren',

      'profile': 'Profil',
      'comingSoon': 'Demnächst',
      'information': 'Information',

      'catFact': 'Stellas Katzenfakt',
      'stellaFacts': 'Stellas Katzenfakt',
      'stellaPower': 'Stella Power',
      'stellaMining': 'Stella Mining',

      'transactions': 'Transaktionen',
      'noTransactions': 'Noch keine Transaktionen.',
      'totalStl': 'STL insgesamt',

      'points': 'Punkte',
      'pointsAdded': 'Punkte hinzugefügt',

      'resetAccount': 'Testkonto zurücksetzen',
      'resetConfirm':
          'Möchtest du das Testkonto wirklich zurücksetzen?',

      'cancel': 'Abbrechen',
      'reset': 'Zurücksetzen',
      'error': 'Fehler',
      'success': 'Erfolgreich',
      'close': 'Schließen',

      'stellaIsMining': 'Stella miniert',
      'stellaMiningNow': 'Stella miniert gerade',
      'stellaIsResting': 'Stella ruht sich aus',
      'stellaWaiting':
          'Stella wartet auf den nächsten Mining-Zyklus',
      'stlReadyToCollect': 'STL kann gesammelt werden',
      'stlMined': 'STL GEMINT',
      'waitingForStella': 'Warte auf Stella',

      'stellaIsWorking': 'STELLA ARBEITET...',
      'stellaIsMiningButton': 'MINING AKTIV',
      'stellaAlreadyMining': 'Stella miniert bereits.',
      'prepareAd': 'Werbung wird vorbereitet...',
      'miningCollected': '{amount} STL gesammelt',
      'miningStartFailed': 'Mining konnte nicht gestartet werden.',

      // Transaction History
      'transactionHistory': 'Transaktionsverlauf',
      'stellaActivity': 'STELLA-AKTIVITÄT',
      'latestTransactions': '{count} letzte Transaktionen',
      'dailyStellaBonus': 'Täglicher Stella-Bonus',
      'dailyBonusDescription': 'Täglicher Bonus von Stella',
      'stellaAdReward': 'Stella-Werbebelohnung',
      'adRewardDescription': 'Belohnung für angesehene Werbung',
      'stlTransaction': 'STL-Transaktion',
      'stelluriiniActivity': 'Stelluriini-Aktivität',
      'transactionBalance': 'Guthaben: {balance} STL',
      'tryAgain': 'Erneut versuchen',
      'noTransactionsYet': 'Noch keine Transaktionen',
      'rewardsAppearHere':
          'Deine STL-Belohnungen erscheinen hier. 🐱',
      'startMiningWithStella': 'Starte das Mining mit Stella',
      'historyRecorded':
          'Mining, tägliche Boni und Werbebelohnungen werden hier gespeichert.',
      'stellaCheckingHistory':
          'Stella überprüft deinen Verlauf...',
      'everyRewardJourney':
          'Jede Belohnung ist Teil deiner Stelluriini-Reise. 🐾',

      // Footer
      'footerTagline':
          'Gemeinsam für die Zukunft von Stelluriini minen.',
      'footerToken': 'STL • STELLURIINI',
    },

    // ============================================================
    // 🇪🇸 SPANISH
    // ============================================================

    'es': {
      'appTitle': 'STELLURIINI',
      'home': 'Inicio',
      'about': 'Acerca de',
      'history': 'Historial de transacciones',
      'roadmap': 'Hoja de ruta',
      'token': 'Token STL',
      'tokenomics': 'Tokenómica',
      'whitepaper': 'Whitepaper',
      'language': 'Idioma',
      'logout': 'Cerrar sesión',
      'menu': 'Menú',

      'balance': 'Saldo',
      'mining': 'Minería',
      'miningRate': 'Tasa de minería',
      'hashRate': 'Hash Rate',
      'effectiveHashRate': 'Hash Rate efectivo',
      'effectiveHashRateLabel': 'Hash Rate efectivo',

      'dailyHashRateLabel': 'Hash Rate diario',
      'dailyHashRateDay': 'Día {day}',
      'dailyHashRateMaximum': 'Máximo: {rate} HR',
      'dailyHashRateSuccess':
          'Hash Rate del día {day}: {rate} HR',

      'stellaMiningProgress': 'Progreso de minería de Stella',
      'stlPerHour': 'STL por hora',
      'hashRateBonus': 'Bono de Hash Rate',

      'startMining': 'INICIAR MINERÍA',
      'claimMining': 'RECLAMAR STL',
      'miningActive': 'Minería activa',
      'miningComplete': 'Ciclo de minería completado',

      'timeRemaining': 'Tiempo restante',
      'remaining': 'Tiempo restante: {time}',

      'streak': 'Racha',
      'days': 'días',

      'dailyBonus': 'Bono diario',
      'dailyClaim': 'Reclamar bono diario',
      'dailyReward': 'Recompensa diaria',
      'claimedToday': 'Reclamado hoy',
      'alreadyClaimed':
          'Ya has reclamado la recompensa de hoy.',

      'watchAd': 'VER ANUNCIO',
      'watchAndEarn': 'VER Y GANAR',
      'loadingAd': 'CARGANDO ANUNCIO...',
      'adLoading': 'CARGANDO ANUNCIO...',
      'adReward': '+{amount} HR',

      'powerBoost': 'Stella Power Boost',
      'powerBoostOffer':
          'Mira un anuncio para activar +{amount} HR de Stella Power Boost durante 4 horas.',
      'powerBoostActive': 'Power Boost activo',
      'powerBoostActiveTitle':
          '¡Stella Power Boost está activo!',
      'powerBoostActiveMessage':
          '+{amount} HR está activo durante tu ciclo de minería.',
      'powerBoostAlreadyActive':
          'Power Boost ya está activo.',
      'nextPowerBoostMessage':
          'El próximo Power Boost estará disponible cuando termine el actual.',
      'nextAdAfterBoost':
          'El próximo anuncio estará disponible después de que termine el boost.',
      'maxBoostsInfo':
          'Puedes activar hasta {count} Power Boosts al día.',
      'adsToday': 'Anuncios hoy: {current}/{max}',
      'dailyLimitReached':
          'Se alcanzó el límite diario de anuncios.',
      'powerBoostReward':
          'Stella Power Boost: +{amount} HR',
      'adRewardDuplicate':
          'Esta recompensa publicitaria ya fue procesada.',
      'testAdRewardFailed':
          'No se pudo procesar la recompensa publicitaria.',

      'serverConnectionFailed':
          'Error de conexión con el servidor.',
      'refresh': 'Actualizar',

      'profile': 'Perfil',
      'comingSoon': 'Próximamente',
      'information': 'Información',

      'catFact': 'Dato gatuno de Stella',
      'stellaFacts': 'Dato gatuno de Stella',
      'stellaPower': 'Stella Power',
      'stellaMining': 'Stella Mining',

      'transactions': 'Transacciones',
      'noTransactions': 'Aún no hay transacciones.',
      'totalStl': 'STL total',

      'points': 'puntos',
      'pointsAdded': 'Puntos añadidos',

      'resetAccount': 'Restablecer cuenta de prueba',
      'resetConfirm':
          '¿Seguro que quieres restablecer la cuenta de prueba?',

      'cancel': 'Cancelar',
      'reset': 'Restablecer',
      'error': 'Error',
      'success': 'Éxito',
      'close': 'Cerrar',

      'stellaIsMining': 'Stella está minando',
      'stellaMiningNow': 'Stella está minando ahora',
      'stellaIsResting': 'Stella está descansando',
      'stellaWaiting':
          'Stella está esperando el próximo ciclo de minería',
      'stlReadyToCollect':
          'STL está listo para reclamar',
      'stlMined': 'STL MINADO',
      'waitingForStella': 'Esperando a Stella',

      'stellaIsWorking': 'STELLA ESTÁ TRABAJANDO...',
      'stellaIsMiningButton': 'MINERÍA ACTIVA',
      'stellaAlreadyMining': 'Stella ya está minando.',
      'prepareAd': 'Preparando anuncio...',
      'miningCollected': 'Recolectado {amount} STL',
      'miningStartFailed':
          'No se pudo iniciar la minería.',

      // Transaction History
      'transactionHistory': 'Historial de transacciones',
      'stellaActivity': 'ACTIVIDAD DE STELLA',
      'latestTransactions':
          '{count} transacciones recientes',
      'dailyStellaBonus': 'Bono diario de Stella',
      'dailyBonusDescription': 'Bono diario de Stella',
      'stellaAdReward':
          'Recompensa de anuncio de Stella',
      'adRewardDescription':
          'Recompensa por anuncio visto',
      'stlTransaction': 'Transacción STL',
      'stelluriiniActivity':
          'Actividad de Stelluriini',
      'transactionBalance':
          'Saldo: {balance} STL',
      'tryAgain': 'Intentar de nuevo',
      'noTransactionsYet':
          'Aún no hay transacciones',
      'rewardsAppearHere':
          'Tus recompensas STL aparecerán aquí. 🐱',
      'startMiningWithStella':
          'Empieza a minar con Stella',
      'historyRecorded':
          'La minería, los bonos diarios y las recompensas por anuncios se registrarán aquí.',
      'stellaCheckingHistory':
          'Stella está revisando tu historial...',
      'everyRewardJourney':
          'Cada recompensa forma parte de tu viaje con Stelluriini. 🐾',

      // Footer
      'footerTagline':
          'Minando juntos por el futuro de Stelluriini.',
      'footerToken': 'STL • STELLURIINI',
    },

    // ============================================================
    // 🇫🇷 FRENCH
    // ============================================================

    'fr': {
      'appTitle': 'STELLURIINI',
      'home': 'Accueil',
      'about': 'À propos',
      'history': 'Historique des transactions',
      'roadmap': 'Feuille de route',
      'token': 'Token STL',
      'tokenomics': 'Tokenomics',
      'whitepaper': 'Whitepaper',
      'language': 'Langue',
      'logout': 'Se déconnecter',
      'menu': 'Menu',

      'balance': 'Solde',
      'mining': 'Minage',
      'miningRate': 'Taux de minage',
      'hashRate': 'Hash Rate',
      'effectiveHashRate': 'Hash Rate effectif',
      'effectiveHashRateLabel': 'Hash Rate effectif',

      'dailyHashRateLabel': 'Hash Rate quotidien',
      'dailyHashRateDay': 'Jour {day}',
      'dailyHashRateMaximum': 'Maximum : {rate} HR',
      'dailyHashRateSuccess':
          'Hash Rate du jour {day} : {rate} HR',

      'stellaMiningProgress':
          'Progression du minage de Stella',
      'stlPerHour': 'STL par heure',
      'hashRateBonus': 'Bonus de Hash Rate',

      'startMining': 'DÉMARRER LE MINAGE',
      'claimMining': 'RÉCLAMER STL',
      'miningActive': 'Minage actif',
      'miningComplete':
          'Cycle de minage terminé',

      'timeRemaining': 'Temps restant',
      'remaining': 'Temps restant : {time}',

      'streak': 'Série',
      'days': 'jours',

      'dailyBonus': 'Bonus quotidien',
      'dailyClaim':
          'Réclamer le bonus quotidien',
      'dailyReward': 'Récompense quotidienne',
      'claimedToday':
          'Réclamé aujourd’hui',
      'alreadyClaimed':
          'Vous avez déjà réclamé la récompense du jour.',

      'watchAd': 'REGARDER LA PUB',
      'watchAndEarn':
          'REGARDER & GAGNER',
      'loadingAd':
          'CHARGEMENT DE LA PUB...',
      'adLoading':
          'CHARGEMENT DE LA PUB...',
      'adReward': '+{amount} HR',

      'powerBoost': 'Stella Power Boost',
      'powerBoostOffer':
          'Regardez une publicité pour activer +{amount} HR de Stella Power Boost pendant 4 heures.',
      'powerBoostActive':
          'Power Boost actif',
      'powerBoostActiveTitle':
          'Stella Power Boost est actif !',
      'powerBoostActiveMessage':
          '+{amount} HR est actif pendant votre cycle de minage.',
      'powerBoostAlreadyActive':
          'Le Power Boost est déjà actif.',
      'nextPowerBoostMessage':
          'Le prochain Power Boost sera disponible lorsque le boost actuel sera terminé.',
      'nextAdAfterBoost':
          'La prochaine publicité sera disponible après la fin du boost.',
      'maxBoostsInfo':
          'Vous pouvez activer jusqu’à {count} Power Boosts par jour.',
      'adsToday':
          'Publicités aujourd’hui : {current}/{max}',
      'dailyLimitReached':
          'La limite quotidienne de publicités est atteinte.',
      'powerBoostReward':
          'Stella Power Boost : +{amount} HR',
      'adRewardDuplicate':
          'Cette récompense publicitaire a déjà été traitée.',
      'testAdRewardFailed':
          'Impossible de traiter la récompense publicitaire.',

      'serverConnectionFailed':
          'Échec de la connexion au serveur.',
      'refresh': 'Actualiser',

      'profile': 'Profil',
      'comingSoon':
          'Bientôt disponible',
      'information': 'Informations',

      'catFact':
          'Fait sur les chats de Stella',
      'stellaFacts':
          'Fait sur les chats de Stella',
      'stellaPower':
          'Stella Power',
      'stellaMining':
          'Stella Mining',

      'transactions':
          'Transactions',
      'noTransactions':
          'Aucune transaction pour le moment.',
      'totalStl':
          'STL total',

      'points': 'points',
      'pointsAdded':
          'Points ajoutés',

      'resetAccount':
          'Réinitialiser le compte de test',
      'resetConfirm':
          'Voulez-vous vraiment réinitialiser le compte de test ?',

      'cancel': 'Annuler',
      'reset': 'Réinitialiser',
      'error': 'Erreur',
      'success': 'Succès',
      'close': 'Fermer',

      'stellaIsMining':
          'Stella mine',
      'stellaMiningNow':
          'Stella est en train de miner',
      'stellaIsResting':
          'Stella se repose',
      'stellaWaiting':
          'Stella attend le prochain cycle de minage',
      'stlReadyToCollect':
          'STL est prêt à être récupéré',
      'stlMined':
          'STL MINÉ',
      'waitingForStella':
          'En attente de Stella',

      'stellaIsWorking':
          'STELLA TRAVAILLE...',
      'stellaIsMiningButton':
          'MINAGE ACTIF',
      'stellaAlreadyMining':
          'Stella mine déjà.',
      'prepareAd':
          'Préparation de la publicité...',
      'miningCollected':
          '{amount} STL récupérés',
      'miningStartFailed':
          'Impossible de démarrer le minage.',

      // Transaction History
      'transactionHistory':
          'Historique des transactions',
      'stellaActivity':
          'ACTIVITÉ DE STELLA',
      'latestTransactions':
          '{count} dernières transactions',
      'dailyStellaBonus':
          'Bonus quotidien de Stella',
      'dailyBonusDescription':
          'Bonus quotidien de Stella',
      'stellaAdReward':
          'Récompense publicitaire de Stella',
      'adRewardDescription':
          'Récompense pour publicité regardée',
      'stlTransaction':
          'Transaction STL',
      'stelluriiniActivity':
          'Activité Stelluriini',
      'transactionBalance':
          'Solde : {balance} STL',
      'tryAgain':
          'Réessayer',
      'noTransactionsYet':
          'Aucune transaction pour le moment',
      'rewardsAppearHere':
          'Vos récompenses STL apparaîtront ici. 🐱',
      'startMiningWithStella':
          'Commencez à miner avec Stella',
      'historyRecorded':
          'Votre minage, vos bonus quotidiens et vos récompenses publicitaires seront enregistrés ici.',
      'stellaCheckingHistory':
          'Stella vérifie votre historique...',
      'everyRewardJourney':
          'Chaque récompense fait partie de votre aventure Stelluriini. 🐾',

      // Footer
      'footerTagline':
          'Minons ensemble pour l’avenir de Stelluriini.',
      'footerToken':
          'STL • STELLURIINI',
    },

    // ============================================================
    // 🇨🇳 CHINESE
    // ============================================================

    'zh': {
      'appTitle': 'STELLURIINI',
      'home': '首页',
      'about': '关于',
      'history': '交易历史',
      'roadmap': '路线图',
      'token': 'STL 代币',
      'tokenomics': '代币经济学',
      'whitepaper': '白皮书',
      'language': '语言',
      'logout': '退出登录',
      'menu': '菜单',

      'balance': '余额',
      'mining': '挖矿',
      'miningRate': '挖矿速率',
      'hashRate': '哈希率',
      'effectiveHashRate': '有效哈希率',
      'effectiveHashRateLabel': '有效哈希率',

      'dailyHashRateLabel': '每日哈希率',
      'dailyHashRateDay': '第 {day} 天',
      'dailyHashRateMaximum': '最高：{rate} HR',
      'dailyHashRateSuccess':
          '第 {day} 天哈希率：{rate} HR',

      'stellaMiningProgress':
          'Stella 挖矿进度',
      'stlPerHour':
          '每小时 STL',
      'hashRateBonus':
          '哈希率奖励',

      'startMining':
          '开始挖矿',
      'claimMining':
          '领取 STL',
      'miningActive':
          '挖矿进行中',
      'miningComplete':
          '挖矿周期完成',

      'timeRemaining':
          '剩余时间',
      'remaining':
          '剩余时间：{time}',

      'streak':
          '连续天数',
      'days':
          '天',

      'dailyBonus':
          '每日奖励',
      'dailyClaim':
          '领取每日奖励',
      'dailyReward':
          '每日奖励',
      'claimedToday':
          '今日已领取',
      'alreadyClaimed':
          '您今天已经领取过奖励。',

      'watchAd':
          '观看广告',
      'watchAndEarn':
          '观看并赚取',
      'loadingAd':
          '正在加载广告...',
      'adLoading':
          '正在加载广告...',
      'adReward':
          '+{amount} HR',

      'powerBoost':
          'Stella Power Boost',
      'powerBoostOffer':
          '观看广告，激活 +{amount} HR Stella Power Boost，持续 4 小时。',
      'powerBoostActive':
          'Power Boost 已激活',
      'powerBoostActiveTitle':
          'Stella Power Boost 已激活！',
      'powerBoostActiveMessage':
          '+{amount} HR 将在您的挖矿周期中生效。',
      'powerBoostAlreadyActive':
          'Power Boost 已经激活。',
      'nextPowerBoostMessage':
          '当前 Boost 结束后即可使用下一个 Power Boost。',
      'nextAdAfterBoost':
          'Boost 结束后即可观看下一条广告。',
      'maxBoostsInfo':
          '每天最多可以激活 {count} 个 Power Boost。',
      'adsToday':
          '今日广告：{current}/{max}',
      'dailyLimitReached':
          '已达到每日广告上限。',
      'powerBoostReward':
          'Stella Power Boost：+{amount} HR',
      'adRewardDuplicate':
          '此广告奖励已经处理过。',
      'testAdRewardFailed':
          '广告奖励处理失败。',

      'serverConnectionFailed':
          '服务器连接失败。',
      'refresh':
          '刷新',

      'profile':
          '个人资料',
      'comingSoon':
          '即将推出',
      'information':
          '信息',

      'catFact':
          'Stella 猫咪知识',
      'stellaFacts':
          'Stella 猫咪知识',
      'stellaPower':
          'Stella Power',
      'stellaMining':
          'Stella Mining',

      'transactions':
          '交易',
      'noTransactions':
          '暂无交易。',
      'totalStl':
          'STL 总计',

      'points':
          '积分',
      'pointsAdded':
          '积分已添加',

      'resetAccount':
          '重置测试账户',
      'resetConfirm':
          '确定要重置测试账户吗？',

      'cancel':
          '取消',
      'reset':
          '重置',
      'error':
          '错误',
      'success':
          '成功',
      'close':
          '关闭',

      'stellaIsMining':
          'Stella 正在挖矿',
      'stellaMiningNow':
          'Stella 正在挖矿',
      'stellaIsResting':
          'Stella 正在休息',
      'stellaWaiting':
          'Stella 正在等待下一轮挖矿',
      'stlReadyToCollect':
          'STL 已准备好领取',
      'stlMined':
          '已挖出的 STL',
      'waitingForStella':
          '正在等待 Stella',

      'stellaIsWorking':
          'STELLA 正在工作...',
      'stellaIsMiningButton':
          '挖矿进行中',
      'stellaAlreadyMining':
          'Stella 已经在挖矿。',
      'prepareAd':
          '正在准备广告...',
      'miningCollected':
          '已领取 {amount} STL',
      'miningStartFailed':
          '挖矿启动失败。',

      // Transaction History
      'transactionHistory':
          '交易历史',
      'stellaActivity':
          'STELLA 活动',
      'latestTransactions':
          '最近 {count} 笔交易',
      'dailyStellaBonus':
          'Stella 每日奖励',
      'dailyBonusDescription':
          'Stella 的每日奖励',
      'stellaAdReward':
          'Stella 广告奖励',
      'adRewardDescription':
          '观看广告获得的奖励',
      'stlTransaction':
          'STL 交易',
      'stelluriiniActivity':
          'Stelluriini 活动',
      'transactionBalance':
          '余额：{balance} STL',
      'tryAgain':
          '重试',
      'noTransactionsYet':
          '暂无交易',
      'rewardsAppearHere':
          '您的 STL 奖励将显示在这里。🐱',
      'startMiningWithStella':
          '与 Stella 一起开始挖矿',
      'historyRecorded':
          '您的挖矿、每日奖励和广告奖励都会记录在这里。',
      'stellaCheckingHistory':
          'Stella 正在检查您的历史记录...',
      'everyRewardJourney':
          '每一份奖励都是您 Stelluriini 旅程的一部分。🐾',

      // Footer
      'footerTagline':
          '一起挖矿，共创 Stelluriini 的未来。',
      'footerToken':
          'STL • STELLURIINI',
    },

    // ============================================================
    // 🇻🇳 VIETNAMESE
    // ============================================================

    'vi': {
      'appTitle': 'STELLURIINI',
      'home': 'Trang chủ',
      'about': 'Giới thiệu',
      'history': 'Lịch sử giao dịch',
      'roadmap': 'Lộ trình',
      'token': 'Token STL',
      'tokenomics': 'Tokenomics',
      'whitepaper': 'Whitepaper',
      'language': 'Ngôn ngữ',
      'logout': 'Đăng xuất',
      'menu': 'Menu',

      'balance': 'Số dư',
      'mining': 'Khai thác',
      'miningRate': 'Tốc độ khai thác',
      'hashRate': 'Hash Rate',
      'effectiveHashRate': 'Hash Rate hiệu dụng',
      'effectiveHashRateLabel': 'Hash Rate hiệu dụng',

      'dailyHashRateLabel': 'Hash Rate hàng ngày',
      'dailyHashRateDay': 'Ngày {day}',
      'dailyHashRateMaximum': 'Tối đa: {rate} HR',
      'dailyHashRateSuccess':
          'Hash Rate ngày {day}: {rate} HR',

      'stellaMiningProgress':
          'Tiến độ khai thác của Stella',
      'stlPerHour':
          'STL mỗi giờ',
      'hashRateBonus':
          'Thưởng Hash Rate',

      'startMining':
          'BẮT ĐẦU KHAI THÁC',
      'claimMining':
          'NHẬN STL',
      'miningActive':
          'Đang khai thác',
      'miningComplete':
          'Chu kỳ khai thác hoàn tất',

      'timeRemaining':
          'Thời gian còn lại',
      'remaining':
          'Thời gian còn lại: {time}',

      'streak':
          'Chuỗi ngày',
      'days':
          'ngày',

      'dailyBonus':
          'Thưởng hàng ngày',
      'dailyClaim':
          'Nhận thưởng hàng ngày',
      'dailyReward':
          'Phần thưởng hàng ngày',
      'claimedToday':
          'Đã nhận hôm nay',
      'alreadyClaimed':
          'Bạn đã nhận phần thưởng hôm nay.',

      'watchAd':
          'XEM QUẢNG CÁO',
      'watchAndEarn':
          'XEM & NHẬN',
      'loadingAd':
          'ĐANG TẢI QUẢNG CÁO...',
      'adLoading':
          'ĐANG TẢI QUẢNG CÁO...',
      'adReward':
          '+{amount} HR',

      'powerBoost':
          'Stella Power Boost',
      'powerBoostOffer':
          'Xem quảng cáo để kích hoạt +{amount} HR Stella Power Boost trong 4 giờ.',
      'powerBoostActive':
          'Power Boost đang hoạt động',
      'powerBoostActiveTitle':
          'Stella Power Boost đang hoạt động!',
      'powerBoostActiveMessage':
          '+{amount} HR đang được áp dụng trong chu kỳ khai thác của bạn.',
      'powerBoostAlreadyActive':
          'Power Boost đã đang hoạt động.',
      'nextPowerBoostMessage':
          'Power Boost tiếp theo sẽ khả dụng khi boost hiện tại kết thúc.',
      'nextAdAfterBoost':
          'Quảng cáo tiếp theo khả dụng sau khi boost kết thúc.',
      'maxBoostsInfo':
          'Bạn có thể kích hoạt tối đa {count} Power Boost mỗi ngày.',
      'adsToday':
          'Quảng cáo hôm nay: {current}/{max}',
      'dailyLimitReached':
          'Đã đạt giới hạn quảng cáo hàng ngày.',
      'powerBoostReward':
          'Stella Power Boost: +{amount} HR',
      'adRewardDuplicate':
          'Phần thưởng quảng cáo này đã được xử lý.',
      'testAdRewardFailed':
          'Không thể xử lý phần thưởng quảng cáo.',

      'serverConnectionFailed':
          'Kết nối máy chủ thất bại.',
      'refresh':
          'Làm mới',

      'profile':
          'Hồ sơ',
      'comingSoon':
          'Sắp ra mắt',
      'information':
          'Thông tin',

      'catFact':
          'Sự thật về mèo Stella',
      'stellaFacts':
          'Sự thật về mèo Stella',
      'stellaPower':
          'Stella Power',
      'stellaMining':
          'Stella Mining',

      'transactions':
          'Giao dịch',
      'noTransactions':
          'Chưa có giao dịch.',
      'totalStl':
          'Tổng STL',

      'points':
          'điểm',
      'pointsAdded':
          'Đã thêm điểm',

      'resetAccount':
          'Đặt lại tài khoản thử nghiệm',
      'resetConfirm':
          'Bạn có chắc muốn đặt lại tài khoản thử nghiệm không?',

      'cancel':
          'Hủy',
      'reset':
          'Đặt lại',
      'error':
          'Lỗi',
      'success':
          'Thành công',
      'close':
          'Đóng',

      'stellaIsMining':
          'Stella đang khai thác',
      'stellaMiningNow':
          'Stella đang khai thác ngay bây giờ',
      'stellaIsResting':
          'Stella đang nghỉ',
      'stellaWaiting':
          'Stella đang chờ chu kỳ khai thác tiếp theo',
      'stlReadyToCollect':
          'STL đã sẵn sàng để nhận',
      'stlMined':
          'STL ĐÃ KHAI THÁC',
      'waitingForStella':
          'Đang chờ Stella',

      'stellaIsWorking':
          'STELLA ĐANG LÀM VIỆC...',
      'stellaIsMiningButton':
          'ĐANG KHAI THÁC',
      'stellaAlreadyMining':
          'Stella đang khai thác.',
      'prepareAd':
          'Đang chuẩn bị quảng cáo...',
      'miningCollected':
          'Đã nhận {amount} STL',
      'miningStartFailed':
          'Không thể bắt đầu khai thác.',

      // Transaction History
      'transactionHistory':
          'Lịch sử giao dịch',
      'stellaActivity':
          'HOẠT ĐỘNG CỦA STELLA',
      'latestTransactions':
          '{count} giao dịch gần nhất',
      'dailyStellaBonus':
          'Thưởng hàng ngày của Stella',
      'dailyBonusDescription':
          'Phần thưởng hàng ngày từ Stella',
      'stellaAdReward':
          'Phần thưởng quảng cáo Stella',
      'adRewardDescription':
          'Phần thưởng từ quảng cáo đã xem',
      'stlTransaction':
          'Giao dịch STL',
      'stelluriiniActivity':
          'Hoạt động Stelluriini',
      'transactionBalance':
          'Số dư: {balance} STL',
      'tryAgain':
          'Thử lại',
      'noTransactionsYet':
          'Chưa có giao dịch',
      'rewardsAppearHere':
          'Phần thưởng STL của bạn sẽ xuất hiện tại đây. 🐱',
      'startMiningWithStella':
          'Bắt đầu khai thác cùng Stella',
      'historyRecorded':
          'Hoạt động khai thác, thưởng hàng ngày và thưởng quảng cáo sẽ được ghi lại tại đây.',
      'stellaCheckingHistory':
          'Stella đang kiểm tra lịch sử của bạn...',
      'everyRewardJourney':
          'Mỗi phần thưởng là một phần trong hành trình Stelluriini của bạn. 🐾',

      // Footer
      'footerTagline':
          'Cùng khai thác vì tương lai của Stelluriini.',
      'footerToken':
          'STL • STELLURIINI',
    },

    // ============================================================
    // 🇯🇵 JAPANESE
    // ============================================================

    'ja': {
      'appTitle': 'STELLURIINI',
      'home': 'ホーム',
      'about': '概要',
      'history': '取引履歴',
      'roadmap': 'ロードマップ',
      'token': 'STL トークン',
      'tokenomics': 'トークノミクス',
      'whitepaper': 'ホワイトペーパー',
      'language': '言語',
      'logout': 'ログアウト',
      'menu': 'メニュー',

      'balance': '残高',
      'mining': 'マイニング',
      'miningRate': 'マイニング速度',
      'hashRate': 'ハッシュレート',
      'effectiveHashRate': '実効ハッシュレート',
      'effectiveHashRateLabel': '実効ハッシュレート',

      'dailyHashRateLabel':
          'デイリーハッシュレート',
      'dailyHashRateDay':
          '{day}日目',
      'dailyHashRateMaximum':
          '最大：{rate} HR',
      'dailyHashRateSuccess':
          '{day}日目のハッシュレート：{rate} HR',

      'stellaMiningProgress':
          'Stellaのマイニング進行状況',
      'stlPerHour':
          '1時間あたりのSTL',
      'hashRateBonus':
          'ハッシュレートボーナス',

      'startMining':
          'マイニング開始',
      'claimMining':
          'STLを受け取る',
      'miningActive':
          'マイニング中',
      'miningComplete':
          'マイニングサイクル完了',

      'timeRemaining':
          '残り時間',
      'remaining':
          '残り時間：{time}',

      'streak':
          '連続日数',
      'days':
          '日',

      'dailyBonus':
          'デイリーボーナス',
      'dailyClaim':
          'デイリーボーナスを受け取る',
      'dailyReward':
          'デイリー報酬',
      'claimedToday':
          '本日受け取り済み',
      'alreadyClaimed':
          '本日の報酬はすでに受け取っています。',

      'watchAd':
          '広告を見る',
      'watchAndEarn':
          '見て獲得',
      'loadingAd':
          '広告を読み込み中...',
      'adLoading':
          '広告を読み込み中...',
      'adReward':
          '+{amount} HR',

      'powerBoost':
          'Stella Power Boost',
      'powerBoostOffer':
          '広告を見て、+{amount} HR の Stella Power Boost を4時間有効にします。',
      'powerBoostActive':
          'Power Boost 有効',
      'powerBoostActiveTitle':
          'Stella Power Boost が有効です！',
      'powerBoostActiveMessage':
          'マイニングサイクル中、+{amount} HR が有効です。',
      'powerBoostAlreadyActive':
          'Power Boost はすでに有効です。',
      'nextPowerBoostMessage':
          '現在のBoostが終了すると、次のPower Boostを利用できます。',
      'nextAdAfterBoost':
          'Boost終了後に次の広告を利用できます。',
      'maxBoostsInfo':
          '1日に最大 {count} 回の Power Boost を有効にできます。',
      'adsToday':
          '本日の広告：{current}/{max}',
      'dailyLimitReached':
          '1日の広告上限に達しました。',
      'powerBoostReward':
          'Stella Power Boost：+{amount} HR',
      'adRewardDuplicate':
          'この広告報酬はすでに処理されています。',
      'testAdRewardFailed':
          '広告報酬の処理に失敗しました。',

      'serverConnectionFailed':
          'サーバーへの接続に失敗しました。',
      'refresh':
          '更新',

      'profile':
          'プロフィール',
      'comingSoon':
          '近日公開',
      'information':
          '情報',

      'catFact':
          'Stellaの猫豆知識',
      'stellaFacts':
          'Stellaの猫豆知識',
      'stellaPower':
          'Stella Power',
      'stellaMining':
          'Stella Mining',

      'transactions':
          '取引',
      'noTransactions':
          'まだ取引はありません。',
      'totalStl':
          'STL 合計',

      'points':
          'ポイント',
      'pointsAdded':
          'ポイントが追加されました',

      'resetAccount':
          'テストアカウントをリセット',
      'resetConfirm':
          'テストアカウントをリセットしますか？',

      'cancel':
          'キャンセル',
      'reset':
          'リセット',
      'error':
          'エラー',
      'success':
          '成功',
      'close':
          '閉じる',

      'stellaIsMining':
          'Stellaがマイニング中',
      'stellaMiningNow':
          'Stellaが現在マイニングしています',
      'stellaIsResting':
          'Stellaは休憩中',
      'stellaWaiting':
          'Stellaは次のマイニングサイクルを待っています',
      'stlReadyToCollect':
          'STLを受け取る準備ができました',
      'stlMined':
          'マイニング済みSTL',
      'waitingForStella':
          'Stellaを待っています',

      'stellaIsWorking':
          'STELLA 作業中...',
      'stellaIsMiningButton':
          'マイニング中',
      'stellaAlreadyMining':
          'Stellaはすでにマイニング中です。',
      'prepareAd':
          '広告を準備しています...',
      'miningCollected':
          '{amount} STLを受け取りました',
      'miningStartFailed':
          'マイニングを開始できませんでした。',

      // Transaction History
      'transactionHistory':
          '取引履歴',
      'stellaActivity':
          'STELLA アクティビティ',
      'latestTransactions':
          '最新 {count} 件の取引',
      'dailyStellaBonus':
          'Stella デイリーボーナス',
      'dailyBonusDescription':
          'Stellaからのデイリーボーナス',
      'stellaAdReward':
          'Stella 広告報酬',
      'adRewardDescription':
          '広告視聴による報酬',
      'stlTransaction':
          'STL 取引',
      'stelluriiniActivity':
          'Stelluriini アクティビティ',
      'transactionBalance':
          '残高：{balance} STL',
      'tryAgain':
          'もう一度試す',
      'noTransactionsYet':
          'まだ取引はありません',
      'rewardsAppearHere':
          'STL報酬がここに表示されます。🐱',
      'startMiningWithStella':
          'Stellaと一緒にマイニングを始めましょう',
      'historyRecorded':
          'マイニング、デイリーボーナス、広告報酬がここに記録されます。',
      'stellaCheckingHistory':
          'Stellaが履歴を確認しています...',
      'everyRewardJourney':
          'すべての報酬がStelluriiniの旅の一部です。🐾',

      // Footer
      'footerTagline':
          'Stelluriiniの未来のために、一緒にマイニングしましょう。',
      'footerToken':
          'STL • STELLURIINI',
    },
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