const Map<String, String> frTranslations = {
  // ============================================================
  // 🌍 GENERAL
  // ============================================================

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

  // ============================================================
  // 💰 BALANCE / MINING
  // ============================================================

  'balance': 'Solde',
  'mining': 'Minage',
  'miningRate': 'Taux de minage',
  'hashRate': 'Hash Rate',
  'effectiveHashRate': 'Hash Rate effectif',
  'effectiveHashRateLabel': 'Hash Rate effectif',

  'dailyHashRateLabel': 'Hash Rate quotidien',
  'dailyHashRateDay': 'Jour {day}',
  'dailyHashRateMaximum': 'Maximum : {rate} HR',
  'dailyHashRateSuccess': 'Hash Rate du jour {day} : {rate} HR',

  'stellaMiningProgress': 'Progression du minage de Stella',
  'stlPerHour': 'STL par heure',
  'hashRateBonus': 'Bonus de Hash Rate',

  'startMining': 'DÉMARRER LE MINAGE',
  'claimMining': 'RÉCLAMER STL',
  'miningActive': 'Minage actif',
  'miningComplete': 'Cycle de minage terminé',

  'timeRemaining': 'Temps restant',
  'remaining': 'Temps restant : {time}',

  'streak': 'Série',
  'days': 'jours',

  // ============================================================
  // 🎁 DAILY BONUS
  // ============================================================

  'dailyBonus': 'Bonus quotidien',
  'dailyClaim': 'Réclamer le bonus quotidien',
  'dailyReward': 'Récompense quotidienne',
  'claimedToday': 'Réclamé aujourd’hui',
  'alreadyClaimed':
      'Vous avez déjà réclamé la récompense du jour.',

  // ============================================================
  // 📺 ADS
  // ============================================================

  'watchAd': 'REGARDER LA PUB',
  'watchAndEarn': 'REGARDER & GAGNER',
  'loadingAd': 'CHARGEMENT DE LA PUB...',
  'adLoading': 'CHARGEMENT DE LA PUB...',
  'adReward': '+{amount} HR',

  // ============================================================
  // ⚡ STELLA POWER BOOST
  // ============================================================

  'powerBoost': 'Stella Power Boost',

  'powerBoostOffer':
      'Regardez une publicité pour activer +{amount} HR de Stella Power Boost pendant 4 heures.',

  'powerBoostActive': 'Power Boost actif',

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

  // ============================================================
  // 🌐 SERVER
  // ============================================================

  'serverConnectionFailed':
      'Échec de la connexion au serveur.',

  'refresh': 'Actualiser',

  // ============================================================
  // 👤 GENERAL UI
  // ============================================================

  'profile': 'Profil',
  'comingSoon': 'Bientôt disponible',
  'information': 'Informations',

  // ============================================================
  // 🐱 STELLA
  // ============================================================

  'catFact': 'Fait sur les chats de Stella',
  'stellaFacts': 'Fait sur les chats de Stella',
  'stellaPower': 'Stella Power',
  'stellaMining': 'Stella Mining',

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

  // ============================================================
  // 💎 TRANSACTIONS
  // ============================================================

  'transactions': 'Transactions',

  'noTransactions':
      'Aucune transaction pour le moment.',

  'totalStl':
      'STL total',

  'points':
      'points',

  'pointsAdded':
      'Points ajoutés',

  // ============================================================
  // 🔄 TEST ACCOUNT
  // ============================================================

  'resetAccount':
      'Réinitialiser le compte de test',

  'resetConfirm':
      'Voulez-vous vraiment réinitialiser le compte de test ?',

  'cancel':
      'Annuler',

  'reset':
      'Réinitialiser',

  'error':
      'Erreur',

  'success':
      'Succès',

  'close':
      'Fermer',

  // ============================================================
  // 🔐 LOGIN
  // ============================================================

  'email':
      'E-mail',

  'password':
      'Mot de passe',

  'forgotPassword':
      'Mot de passe oublié ?',

  'login':
      'SE CONNECTER',

  'loggingIn':
      'CONNEXION...',

  'createAccount':
      'Pas encore de compte ? Créer un compte',

  'loginFillFields':
      'Entrez votre e-mail et votre mot de passe.',

  'loginInvalidEmail':
      'L’adresse e-mail n’est pas valide.',

  'loginUserNotFound':
      'Utilisateur introuvable.',

  'loginInvalidCredentials':
      'L’e-mail ou le mot de passe est incorrect.',

  'loginUserDisabled':
      'Ce compte utilisateur a été désactivé.',

  'loginTooManyRequests':
      'Trop de tentatives. Réessayez plus tard.',

  'loginNetworkError':
      'Échec de la connexion réseau.',

  'loginFailed':
      'Échec de la connexion',

  // ============================================================
  // 📝 REGISTER
  // ============================================================

  'confirmPassword':
      'Confirmer le mot de passe',

  'passwordsDoNotMatch':
      'Les mots de passe ne correspondent pas.',

  'passwordTooShort':
      'Le mot de passe doit contenir au moins 6 caractères.',

  'creatingAccount':
      'CRÉATION DU COMPTE...',

  'accountCreated':
      'Compte créé avec succès.',

  'emailAlreadyInUse':
      'Cette adresse e-mail est déjà utilisée.',

  'passwordTooWeak':
      'Le mot de passe est trop faible.',

  'registrationNotAllowed':
      'L’inscription n’est actuellement pas autorisée.',

  'registrationFailed':
      'Impossible de créer le compte.',

  // ============================================================
  // 📜 TRANSACTION HISTORY
  // ============================================================

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

  // ============================================================
  // ℹ️ ABOUT
  // ============================================================

  'aboutWelcome':
      'Bienvenue sur Stelluriini',

  'aboutWelcomeDescription':
      'Stelluriini est un projet communautaire basé sur Solana, dans lequel Stella, la chatte, sert de mascotte et de guide du projet.',

  'aboutDescription':
      'Stelluriini associe une communauté, un token numérique et une expérience d’application construite autour de Stella.',

  'meetStella':
      'Rencontrez Stella',

  'aboutStellaIntro':
      'Stella est le cœur de Stelluriini et l’adorable mascotte féline du projet.',

  'aboutStellaDescription':
      'Stella accompagne les utilisateurs dans le minage, les récompenses et l’écosystème Stelluriini.',

  'community':
      'Communauté',

  'aboutCommunityDescription':
      'Stelluriini est construit autour de sa communauté. L’objectif est de créer un écosystème ouvert, amusant et accessible.',

  'builtOnSolana':
      'Construit sur Solana',

  'aboutSolanaDescription':
      'Stelluriini utilise la blockchain Solana, offrant un environnement rapide et économique pour le token STL.',

  'stlToken':
      'Token STL',

  'importantInformation':
      'Informations importantes',

  'aboutImportantDescription':
      'Le solde STL actuellement affiché dans l’application représente des points virtuels intégrés à l’application. Le solde n’est pas automatiquement une cryptomonnaie retirable.',

  // ============================================================
  // 🗺️ ROADMAP
  // ============================================================

  'roadmapTitle':
      'Feuille de route Stelluriini',

  'roadmapSubtitle':
      'Le parcours de Stelluriini, étape par étape.',

  'roadmapPhase1':
      'Phase 1 – Fondation',

  'roadmapPhase1Title':
      'Construire Stelluriini',

  'roadmapPhase1Description':
      'Création du projet Stelluriini, du token STL et de la mascotte Stella.',

  'roadmapPhase2':
      'Phase 2 – Application',

  'roadmapPhase2Title':
      'Développement de l’application Stelluriini',

  'roadmapPhase2Description':
      'Minage, récompenses quotidiennes, Stella Power Boost et historique des transactions.',

  'roadmapPhase3':
      'Phase 3 – Communauté',

  'roadmapPhase3Title':
      'Développer la communauté',

  'roadmapPhase3Description':
      'Développer la communauté, recueillir les commentaires et faire évoluer la marque Stelluriini.',

  'roadmapPhase4':
      'Phase 4 – Écosystème',

  'roadmapPhase4Title':
      'Développer l’écosystème STL',

  'roadmapPhase4Description':
      'Développer les cas d’utilisation du token STL et étendre l’écosystème Stelluriini.',

  'roadmapPhase5':
      'Phase 5 – Avenir',

  'roadmapPhase5Title':
      'La prochaine étape de Stelluriini',

  'roadmapPhase5Description':
      'Explorer de nouvelles fonctionnalités, des partenariats potentiels et les idées de la communauté.',

  // ============================================================
  // 🪙 TOKEN
  // ============================================================

  'tokenTitle':
      'Stelluriini STL',

  'tokenSubtitle':
      'Le token officiel de Stelluriini sur le réseau Solana.',

  'tokenName':
      'Nom',

  'tokenSymbol':
      'Symbole',

  'tokenBlockchain':
      'Blockchain',

  'tokenSupply':
      'Offre totale',

  'tokenMint':
      'Adresse Mint',

  'tokenDescription':
      'Stelluriini est un token communautaire sur la blockchain Solana.',

  'solana':
      'Solana',

  'copyAddress':
      'Copier l’adresse',

  'addressCopied':
      'Adresse copiée.',

  // ============================================================
  // 📊 TOKENOMICS
  // ============================================================

  'tokenomicsTitle':
      'Tokenomics STL',

  'tokenomicsSubtitle':
      'Informations de base et structure économique du token Stelluriini STL.',

  'totalSupply':
      'Offre totale',

  'tokenAllocation':
      'Répartition des tokens',

  'communityAllocation':
      'Communauté',

  'ecosystemAllocation':
      'Écosystème',

  'developmentAllocation':
      'Développement',

  'liquidityAllocation':
      'Liquidité',

  'marketingAllocation':
      'Marketing',

  'tokenomicsImportant':
      'Les allocations exactes de tokens peuvent être mises à jour pendant le développement du projet. Toute modification doit être communiquée de manière transparente à la communauté.',

  // ============================================================
  // 📄 WHITEPAPER
  // ============================================================

  'whitepaperTitle':
      'Whitepaper Stelluriini',

  'whitepaperSubtitle':
      'La vision, la technologie et l’orientation future du projet Stelluriini.',

  'whitepaperIntroduction':
      'Introduction',

  'whitepaperVision':
      'Vision',

  'whitepaperMission':
      'Mission',

  'whitepaperTechnology':
      'Technologie',

  'whitepaperMining':
      'Système de minage',

  'whitepaperStella':
      'Stella',

  'whitepaperToken':
      'Token STL',

  'whitepaperTokenomics':
      'Tokenomics',

  'whitepaperCommunity':
      'Communauté',

  'whitepaperRoadmap':
      'Feuille de route',

  'whitepaperSecurity':
      'Sécurité',

  'whitepaperFuture':
      'Avenir',

  'whitepaperDisclaimer':
      'Ce whitepaper est une description informative du projet Stelluriini. Les fonctionnalités et les plans peuvent changer au cours du développement.',

  // ============================================================
  // ⚠️ IMPORTANT INFORMATION
  // ============================================================

  'virtualPointsNotice':
      'Les récompenses STL affichées dans l’application sont actuellement des points virtuels intégrés à l’application.',

  'withdrawalsDisabled':
      'Les retraits ne sont actuellement pas disponibles.',

  'futureWithdrawals':
      'Un éventuel futur système de retrait sera conçu séparément et ses conditions seront annoncées avant sa mise en œuvre.',

  // ============================================================
  // 🐾 FOOTER
  // ============================================================

  'footerTagline':
      'Minons ensemble pour l’avenir de Stelluriini.',

  'footerToken':
      'STL • STELLURIINI',
};