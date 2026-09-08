const Map<String, String> enTranslations = {
  // ============================================================
  // 🌍 GENERAL
  // ============================================================

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

  // ============================================================
  // 💰 BALANCE / MINING
  // ============================================================

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

  // ============================================================
  // 🎁 DAILY BONUS
  // ============================================================

  'dailyBonus': 'Daily Bonus',
  'dailyClaim': 'Claim Daily Bonus',
  'dailyReward': 'Daily Reward',
  'claimedToday': 'Claimed today',
  'alreadyClaimed': 'You have already claimed today’s reward.',

  // ============================================================
  // 📺 ADS
  // ============================================================

  'watchAd': 'WATCH AD',
  'watchAndEarn': 'WATCH & EARN',
  'loadingAd': 'LOADING AD...',
  'adLoading': 'LOADING AD...',
  'adReward': '+{amount} HR',

  // ============================================================
  // ⚡ STELLA POWER BOOST
  // ============================================================

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

  'adsToday':
      'Ads today: {current}/{max}',

  'dailyLimitReached':
      'Daily ad limit reached.',

  'powerBoostReward':
      'Stella Power Boost: +{amount} HR',

  'adRewardDuplicate':
      'This ad reward has already been processed.',

  'testAdRewardFailed':
      'Failed to process the ad reward.',

  // ============================================================
  // 🌐 SERVER
  // ============================================================

  'serverConnectionFailed':
      'Server connection failed.',

  'refresh': 'Refresh',

  // ============================================================
  // 👤 GENERAL UI
  // ============================================================

  'profile': 'Profile',
  'comingSoon': 'Coming Soon',
  'information': 'Information',

  // ============================================================
  // 🐱 STELLA
  // ============================================================

  'catFact': 'Stella Cat Fact',
  'stellaFacts': 'Stella Cat Fact',
  'stellaPower': 'Stella Power',
  'stellaMining': 'Stella Mining',

  'stellaIsMining':
      'Stella is mining',

  'stellaMiningNow':
      'Stella is mining right now',

  'stellaIsResting':
      'Stella is resting',

  'stellaWaiting':
      'Stella is waiting for the next mining cycle',

  'stlReadyToCollect':
      'STL is ready to collect',

  'stlMined':
      'STL MINED',

  'waitingForStella':
      'Waiting for Stella',

  'stellaIsWorking':
      'STELLA IS WORKING...',

  'stellaIsMiningButton':
      'MINING ACTIVE',

  'stellaAlreadyMining':
      'Stella is already mining.',

  'prepareAd':
      'Preparing ad...',

  'miningCollected':
      'Collected {amount} STL',

  'miningStartFailed':
      'Failed to start mining.',

  // ============================================================
  // 💎 TRANSACTIONS
  // ============================================================

  'transactions': 'Transactions',

  'noTransactions':
      'No transactions yet.',

  'totalStl':
      'Total STL',

  'points':
      'points',

  'pointsAdded':
      'Points added',

  // ============================================================
  // 🔄 TEST ACCOUNT
  // ============================================================

  'resetAccount':
      'Reset Test Account',

  'resetConfirm':
      'Are you sure you want to reset the test account?',

  'cancel':
      'Cancel',

  'reset':
      'Reset',

  'error':
      'Error',

  'success':
      'Success',

  'close':
      'Close',

  // ============================================================
  // 🔐 LOGIN
  // ============================================================

  'email':
      'Email',

  'password':
      'Password',

  'forgotPassword':
      'Forgot password?',

  'login':
      'LOG IN',

  'loggingIn':
      'LOGGING IN...',

  'createAccount':
      'No account yet? Create a new account',

  'loginFillFields':
      'Enter your email and password.',

  'loginInvalidEmail':
      'The email address is not valid.',

  'loginUserNotFound':
      'User not found.',

  'loginInvalidCredentials':
      'The email or password is incorrect.',

  'loginUserDisabled':
      'This user account has been disabled.',

  'loginTooManyRequests':
      'Too many attempts. Please try again later.',

  'loginNetworkError':
      'Network connection failed.',

  'loginFailed':
      'Login failed',

  // ============================================================
  // 📜 TRANSACTION HISTORY
  // ============================================================

  'transactionHistory':
      'Transaction History',

  'stellaActivity':
      'STELLA ACTIVITY',

  'latestTransactions':
      '{count} latest transactions',

  'dailyStellaBonus':
      'Daily Stella Bonus',

  'dailyBonusDescription':
      'Daily bonus from Stella',

  'stellaAdReward':
      'Stella Ad Reward',

  'adRewardDescription':
      'Rewarded ad bonus',

  'stlTransaction':
      'STL Transaction',

  'stelluriiniActivity':
      'Stelluriini activity',

  'transactionBalance':
      'Balance: {balance} STL',

  'tryAgain':
      'Try Again',

  'noTransactionsYet':
      'No transactions yet',

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

  // ============================================================
  // ℹ️ ABOUT
  // ============================================================

  'aboutWelcome':
      'Welcome to Stelluriini',

  'aboutWelcomeDescription':
      'Stelluriini is a community-driven Solana project where Stella the cat serves as the project mascot and guide.',

  'aboutDescription':
      'Stelluriini combines community, a digital token and an app experience built around Stella.',

  'meetStella':
      'Meet Stella',

  'aboutStellaIntro':
      'Stella is the heart of Stelluriini and the project’s lovable cat mascot.',

  'aboutStellaDescription':
      'Stella guides users through mining, rewards and the Stelluriini ecosystem.',

  'community':
      'Community',

  'aboutCommunityDescription':
      'Stelluriini is built around its community. The goal is to create an open, fun and approachable ecosystem.',

  'builtOnSolana':
      'Built on Solana',

  'aboutSolanaDescription':
      'Stelluriini uses the Solana blockchain, providing a fast and cost-efficient environment for the STL token.',

  'stlToken':
      'STL Token',

  'importantInformation':
      'Important Information',

  'aboutImportantDescription':
      'The STL balance currently shown in the app represents virtual in-app points. The balance is not automatically withdrawable cryptocurrency.',

  // ============================================================
  // 🗺️ ROADMAP
  // ============================================================

  'roadmapTitle':
      'Stelluriini Roadmap',

  'roadmapSubtitle':
      'The Stelluriini journey, step by step.',

  'roadmapPhase1':
      'Phase 1 – Foundation',

  'roadmapPhase1Title':
      'Building Stelluriini',

  'roadmapPhase1Description':
      'Establishing the Stelluriini project, STL token and Stella mascot.',

  'roadmapPhase2':
      'Phase 2 – App',

  'roadmapPhase2Title':
      'Stelluriini App Development',

  'roadmapPhase2Description':
      'Mining, daily rewards, Stella Power Boost and transaction history.',

  'roadmapPhase3':
      'Phase 3 – Community',

  'roadmapPhase3Title':
      'Growing the Community',

  'roadmapPhase3Description':
      'Building the community, collecting feedback and developing the Stelluriini brand.',

  'roadmapPhase4':
      'Phase 4 – Ecosystem',

  'roadmapPhase4Title':
      'Expanding the STL Ecosystem',

  'roadmapPhase4Description':
      'Developing STL token use cases and expanding the Stelluriini ecosystem.',

  'roadmapPhase5':
      'Phase 5 – Future',

  'roadmapPhase5Title':
      'The Next Stage of Stelluriini',

  'roadmapPhase5Description':
      'Exploring new features, potential partnerships and community ideas.',

  // ============================================================
  // 🪙 TOKEN
  // ============================================================

  'tokenTitle':
      'Stelluriini STL',

  'tokenSubtitle':
      'The official Stelluriini token on the Solana network.',

  'tokenName':
      'Name',

  'tokenSymbol':
      'Symbol',

  'tokenBlockchain':
      'Blockchain',

  'tokenSupply':
      'Total Supply',

  'tokenMint':
      'Mint Address',

  'tokenDescription':
      'Stelluriini is a community-driven token on the Solana blockchain.',

  'solana':
      'Solana',

  'copyAddress':
      'Copy Address',

  'addressCopied':
      'Address copied.',

  // ============================================================
  // 📊 TOKENOMICS
  // ============================================================

  'tokenomicsTitle':
      'STL Tokenomics',

  'tokenomicsSubtitle':
      'Basic information and economic structure of the Stelluriini STL token.',

  'totalSupply':
      'Total Supply',

  'tokenAllocation':
      'Token Allocation',

  'communityAllocation':
      'Community',

  'ecosystemAllocation':
      'Ecosystem',

  'developmentAllocation':
      'Development',

  'liquidityAllocation':
      'Liquidity',

  'marketingAllocation':
      'Marketing',

  'tokenomicsImportant':
      'Exact token allocations may be updated during project development. All changes should be communicated transparently to the community.',

  // ============================================================
  // 📄 WHITEPAPER
  // ============================================================

  'whitepaperTitle':
      'Stelluriini Whitepaper',

  'whitepaperSubtitle':
      'The vision, technology and future direction of the Stelluriini project.',

  'whitepaperIntroduction':
      'Introduction',

  'whitepaperVision':
      'Vision',

  'whitepaperMission':
      'Mission',

  'whitepaperTechnology':
      'Technology',

  'whitepaperMining':
      'Mining System',

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
      'Security',

  'whitepaperFuture':
      'Future',

  'whitepaperDisclaimer':
      'This whitepaper is an informational description of the Stelluriini project. Features and plans may change during development.',

  // ============================================================
  // ⚠️ IMPORTANT INFORMATION
  // ============================================================

  'virtualPointsNotice':
      'STL rewards shown in the app are currently virtual in-app points.',

  'withdrawalsDisabled':
      'Withdrawals are not currently available.',

  'futureWithdrawals':
      'A possible future withdrawal system will be designed separately, and its terms will be announced before implementation.',

  // ============================================================
  // 🐾 FOOTER
  // ============================================================

  'footerTagline':
      'Mining together for the future of Stelluriini.',

  'footerToken':
      'STL • STELLURIINI',
};