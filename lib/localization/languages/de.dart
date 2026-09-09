const Map<String, String> deTranslations = {
  // ============================================================
  // 🌍 GENERAL
  // ============================================================

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

  // ============================================================
  // 💰 BALANCE / MINING
  // ============================================================

  'balance': 'Guthaben',
  'mining': 'Mining',
  'miningRate': 'Mining-Rate',
  'hashRate': 'Hashrate',
  'effectiveHashRate': 'Effektive Hashrate',
  'effectiveHashRateLabel': 'Effektive Hashrate',

  'dailyHashRateLabel': 'Tägliche Hashrate',
  'dailyHashRateDay': 'Tag {day}',
  'dailyHashRateMaximum': 'Maximum: {rate} HR',
  'dailyHashRateSuccess': 'Hashrate an Tag {day}: {rate} HR',

  'stellaMiningProgress': 'Stellas Mining-Fortschritt',
  'stlPerHour': 'STL pro Stunde',
  'hashRateBonus': 'Hashrate-Bonus',

  'startMining': 'MINING STARTEN',
  'claimMining': 'STL EINSAMMELN',
  'miningActive': 'Mining aktiv',
  'miningComplete': 'Mining-Zyklus abgeschlossen',

  'timeRemaining': 'Verbleibende Zeit',
  'remaining': 'Verbleibende Zeit: {time}',

  'streak': 'Tages-Serie',
  'days': 'Tage',

  // ============================================================
  // 🎁 DAILY BONUS
  // ============================================================

  'dailyBonus': 'Täglicher Bonus',
  'dailyClaim': 'Täglichen Bonus sammeln',
  'dailyReward': 'Tägliche Belohnung',
  'claimedToday': 'Heute gesammelt',
  'alreadyClaimed':
      'Du hast die heutige Belohnung bereits gesammelt.',

  // ============================================================
  // 📺 ADS
  // ============================================================

  'watchAd': 'WERBUNG ANSEHEN',
  'watchAndEarn': 'ANSEHEN & VERDIENEN',
  'loadingAd': 'WERBUNG WIRD GELADEN...',
  'adLoading': 'WERBUNG WIRD GELADEN...',
  'adReward': '+{amount} HR',

  // ============================================================
  // ⚡ STELLA POWER BOOST
  // ============================================================

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
      'Der nächste Power Boost ist verfügbar, sobald der aktuelle Boost endet.',

  'nextAdAfterBoost':
      'Die nächste Werbung ist nach Ende des Boosts verfügbar.',

  'maxBoostsInfo':
      'Du kannst bis zu {count} Power Boosts pro Tag aktivieren.',

  'adsToday':
      'Werbung heute: {current}/{max}',

  'dailyLimitReached':
      'Tägliches Werbelimit erreicht.',

  'powerBoostReward':
      'Stella Power Boost: +{amount} HR',

  'adRewardDuplicate':
      'Diese Werbebelohnung wurde bereits verarbeitet.',

  'testAdRewardFailed':
      'Die Werbebelohnung konnte nicht verarbeitet werden.',

  // ============================================================
  // 🌐 SERVER
  // ============================================================

  'serverConnectionFailed':
      'Serververbindung fehlgeschlagen.',

  'refresh': 'Aktualisieren',

  // ============================================================
  // 👤 GENERAL UI
  // ============================================================

  'profile': 'Profil',
  'comingSoon': 'Demnächst',
  'information': 'Information',

  // ============================================================
  // 🐱 STELLA
  // ============================================================

  'catFact': 'Stellas Katzenfakt',
  'stellaFacts': 'Stellas Katzenfakt',
  'stellaPower': 'Stella Power',
  'stellaMining': 'Stella Mining',

  'stellaIsMining':
      'Stella miniert',

  'stellaMiningNow':
      'Stella miniert gerade',

  'stellaIsResting':
      'Stella ruht sich aus',

  'stellaWaiting':
      'Stella wartet auf den nächsten Mining-Zyklus',

  'stlReadyToCollect':
      'STL kann eingesammelt werden',

  'stlMined':
      'STL GEMINT',

  'waitingForStella':
      'Warte auf Stella',

  'stellaIsWorking':
      'STELLA ARBEITET...',

  'stellaIsMiningButton':
      'MINING AKTIV',

  'stellaAlreadyMining':
      'Stella miniert bereits.',

  'prepareAd':
      'Werbung wird vorbereitet...',

  'miningCollected':
      '{amount} STL gesammelt',

  'miningStartFailed':
      'Mining konnte nicht gestartet werden.',

  // ============================================================
  // 💎 TRANSACTIONS
  // ============================================================

  'transactions': 'Transaktionen',

  'noTransactions':
      'Noch keine Transaktionen.',

  'totalStl':
      'STL insgesamt',

  'points':
      'Punkte',

  'pointsAdded':
      'Punkte hinzugefügt',

  // ============================================================
  // 🔄 TEST ACCOUNT
  // ============================================================

  'resetAccount':
      'Testkonto zurücksetzen',

  'resetConfirm':
      'Möchtest du das Testkonto wirklich zurücksetzen?',

  'cancel':
      'Abbrechen',

  'reset':
      'Zurücksetzen',

  'error':
      'Fehler',

  'success':
      'Erfolgreich',

  'close':
      'Schließen',

  // ============================================================
  // 🔐 LOGIN
  // ============================================================

  'email':
      'E-Mail',

  'password':
      'Passwort',

  'forgotPassword':
      'Passwort vergessen?',

  'login':
      'ANMELDEN',

  'loggingIn':
      'ANMELDUNG...',

  'createAccount':
      'Noch kein Konto? Neues Konto erstellen',

  'loginFillFields':
      'E-Mail und Passwort eingeben.',

  'loginInvalidEmail':
      'Die E-Mail-Adresse ist ungültig.',

  'loginUserNotFound':
      'Benutzer wurde nicht gefunden.',

  'loginInvalidCredentials':
      'E-Mail oder Passwort ist falsch.',

  'loginUserDisabled':
      'Dieses Benutzerkonto wurde deaktiviert.',

  'loginTooManyRequests':
      'Zu viele Versuche. Bitte später erneut versuchen.',

  'loginNetworkError':
      'Netzwerkverbindung fehlgeschlagen.',

  'loginFailed':
      'Anmeldung fehlgeschlagen',

  // ============================================================
  // 📝 REGISTER
  // ============================================================

  'confirmPassword':
      'Passwort bestätigen',

  'passwordsDoNotMatch':
      'Die Passwörter stimmen nicht überein.',

  'passwordTooShort':
      'Das Passwort muss mindestens 6 Zeichen enthalten.',

  'creatingAccount':
      'KONTO WIRD ERSTELLT...',

  'accountCreated':
      'Konto erfolgreich erstellt.',

  'emailAlreadyInUse':
      'Diese E-Mail-Adresse wird bereits verwendet.',

  'passwordTooWeak':
      'Das Passwort ist zu schwach.',

  'registrationNotAllowed':
      'Die Registrierung ist derzeit nicht möglich.',

  'registrationFailed':
      'Das Konto konnte nicht erstellt werden.',

  // ============================================================
  // 🔑 FORGOT PASSWORD
  // ============================================================

  'passwordResetSent':
      'Der Link zum Zurücksetzen des Passworts wurde an deine E-Mail-Adresse gesendet.',

  'passwordResetUserNotFound':
      'Für diese E-Mail-Adresse wurde kein Benutzerkonto gefunden.',

  'passwordResetNotAllowed':
      'Das Zurücksetzen des Passworts ist derzeit nicht möglich.',

  'passwordResetFailed':
      'Das Zurücksetzen des Passworts ist fehlgeschlagen.',

  'passwordResetDescription':
      'Gib die E-Mail-Adresse deines Kontos ein. Wir senden dir anschließend einen Link zum Zurücksetzen deines Passworts.',

  'sending':
      'WIRD GESENDET...',

  'sendPasswordReset':
      'LINK ZUM ZURÜCKSETZEN SENDEN',

  // ============================================================
  // 📜 TRANSACTION HISTORY
  // ============================================================

  'transactionHistory':
      'Transaktionsverlauf',

  'stellaActivity':
      'STELLA-AKTIVITÄT',

  'latestTransactions':
      '{count} letzte Transaktionen',

  'dailyStellaBonus':
      'Täglicher Stella-Bonus',

  'dailyBonusDescription':
      'Täglicher Bonus von Stella',

  'stellaAdReward':
      'Stella-Werbebelohnung',

  'adRewardDescription':
      'Belohnung für das Ansehen einer Werbung',

  'stlTransaction':
      'STL-Transaktion',

  'stelluriiniActivity':
      'Stelluriini-Aktivität',

  'transactionBalance':
      'Guthaben: {balance} STL',

  'tryAgain':
      'Erneut versuchen',

  'noTransactionsYet':
      'Noch keine Transaktionen',

  'rewardsAppearHere':
      'Deine STL-Belohnungen erscheinen hier. 🐱',

  'startMiningWithStella':
      'Starte das Mining mit Stella',

  'historyRecorded':
      'Mining, tägliche Boni und Werbebelohnungen werden hier gespeichert.',

  'stellaCheckingHistory':
      'Stella überprüft deinen Verlauf...',

  'everyRewardJourney':
      'Jede Belohnung ist Teil deiner Stelluriini-Reise. 🐾',

  // ============================================================
  // ℹ️ ABOUT
  // ============================================================

  'aboutWelcome':
      'Willkommen bei Stelluriini',

  'aboutWelcomeDescription':
      'Stelluriini ist ein community-orientiertes Solana-Projekt, bei dem Stella, die Katze, als Maskottchen und Begleiterin des Projekts dient.',

  'aboutDescription':
      'Stelluriini verbindet Community, einen digitalen Token und ein App-Erlebnis rund um Stella.',

  'meetStella':
      'Lerne Stella kennen',

  'aboutStellaIntro':
      'Stella ist das Herz von Stelluriini und das liebenswerte Katzenmaskottchen des Projekts.',

  'aboutStellaDescription':
      'Stella begleitet die Nutzer durch Mining, Belohnungen und das Stelluriini-Ökosystem.',

  'community':
      'Community',

  'aboutCommunityDescription':
      'Stelluriini wird rund um seine Community aufgebaut. Das Ziel ist ein offenes, unterhaltsames und leicht zugängliches Ökosystem.',

  'builtOnSolana':
      'Auf Solana aufgebaut',

  'aboutSolanaDescription':
      'Stelluriini nutzt die Solana-Blockchain und bietet damit eine schnelle und kosteneffiziente Umgebung für den STL-Token.',

  'stlToken':
      'STL Token',

  'importantInformation':
      'Wichtige Informationen',

  'aboutImportantDescription':
      'Das derzeit in der App angezeigte STL-Guthaben stellt virtuelle In-App-Punkte dar. Das Guthaben ist nicht automatisch als Kryptowährung auszahlbar.',

  // ============================================================
  // 🗺️ ROADMAP
  // ============================================================

  'roadmapTitle':
      'Stelluriini Roadmap',

  'roadmapSubtitle':
      'Die Reise von Stelluriini, Schritt für Schritt.',

  'roadmapPhase1':
      'Phase 1 – Grundlage',

  'roadmapPhase1Title':
      'Aufbau von Stelluriini',

  'roadmapPhase1Description':
      'Aufbau des Stelluriini-Projekts, des STL-Tokens und des Stella-Maskottchens.',

  'roadmapPhase2':
      'Phase 2 – App',

  'roadmapPhase2Title':
      'Entwicklung der Stelluriini-App',

  'roadmapPhase2Description':
      'Mining, tägliche Belohnungen, Stella Power Boost und Transaktionsverlauf.',

  'roadmapPhase3':
      'Phase 3 – Community',

  'roadmapPhase3Title':
      'Aufbau der Community',

  'roadmapPhase3Description':
      'Aufbau der Community, Sammeln von Feedback und Weiterentwicklung der Stelluriini-Marke.',

  'roadmapPhase4':
      'Phase 4 – Ökosystem',

  'roadmapPhase4Title':
      'Erweiterung des STL-Ökosystems',

  'roadmapPhase4Description':
      'Entwicklung von Anwendungsfällen für den STL-Token und Erweiterung des Stelluriini-Ökosystems.',

  'roadmapPhase5':
      'Phase 5 – Zukunft',

  'roadmapPhase5Title':
      'Die nächste Phase von Stelluriini',

  'roadmapPhase5Description':
      'Erkundung neuer Funktionen, möglicher Partnerschaften und Ideen aus der Community.',

  // ============================================================
  // 🪙 TOKEN
  // ============================================================

  'tokenTitle':
      'Stelluriini STL',

  'tokenSubtitle':
      'Der offizielle Stelluriini-Token im Solana-Netzwerk.',

  'tokenName':
      'Name',

  'tokenSymbol':
      'Symbol',

  'tokenBlockchain':
      'Blockchain',

  'tokenSupply':
      'Gesamtangebot',

  'tokenMint':
      'Mint-Adresse',

  'tokenDescription':
      'Stelluriini ist ein community-orientierter Token auf der Solana-Blockchain.',

  'solana':
      'Solana',

  'copyAddress':
      'Adresse kopieren',

  'addressCopied':
      'Adresse kopiert.',

  // ============================================================
  // 📊 TOKENOMICS
  // ============================================================

  'tokenomicsTitle':
      'STL Tokenomics',

  'tokenomicsSubtitle':
      'Grundlegende Informationen und wirtschaftliche Struktur des Stelluriini STL-Tokens.',

  'totalSupply':
      'Gesamtangebot',

  'tokenAllocation':
      'Token-Verteilung',

  'communityAllocation':
      'Community',

  'ecosystemAllocation':
      'Ökosystem',

  'developmentAllocation':
      'Entwicklung',

  'liquidityAllocation':
      'Liquidität',

  'marketingAllocation':
      'Marketing',

  'tokenomicsImportant':
      'Die genauen Token-Zuteilungen können während der Projektentwicklung aktualisiert werden. Alle Änderungen sollten der Community transparent mitgeteilt werden.',

  // ============================================================
  // 📄 WHITEPAPER
  // ============================================================

  'whitepaperTitle':
      'Stelluriini Whitepaper',

  'whitepaperSubtitle':
      'Die Vision, Technologie und zukünftige Ausrichtung des Stelluriini-Projekts.',

  'whitepaperIntroduction':
      'Einleitung',

  'whitepaperVision':
      'Vision',

  'whitepaperMission':
      'Mission',

  'whitepaperTechnology':
      'Technologie',

  'whitepaperMining':
      'Mining-System',

  'whitepaperStella':
      'Stella',

  'whitepaperToken':
      'STL Token',

  'whitepaperTokenomics':
      'Tokenomics',

  'whitepaperCommunity':
      'Community',

  'whitepaperRoadmap':
      'Roadmap',

  'whitepaperSecurity':
      'Sicherheit',

  'whitepaperFuture':
      'Zukunft',

  'whitepaperDisclaimer':
      'Dieses Whitepaper ist eine informative Beschreibung des Stelluriini-Projekts. Funktionen und Pläne können sich während der Entwicklung ändern.',

  // ============================================================
  // ⚠️ IMPORTANT INFORMATION
  // ============================================================

  'virtualPointsNotice':
      'Die in der App angezeigten STL-Belohnungen sind derzeit virtuelle In-App-Punkte.',

  'withdrawalsDisabled':
      'Auszahlungen sind derzeit nicht verfügbar.',

  'futureWithdrawals':
      'Ein mögliches zukünftiges Auszahlungssystem wird separat entwickelt. Die Bedingungen werden vor der Einführung bekannt gegeben.',

  // ============================================================
  // 🐾 FOOTER
  // ============================================================

  'footerTagline':
      'Gemeinsam für die Zukunft von Stelluriini minen.',

  'footerToken':
      'STL • STELLURIINI',
};