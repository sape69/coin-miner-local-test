const Map<String, String> jaTranslations = {
  // ============================================================
  // 🌍 GENERAL
  // ============================================================

  'appTitle': 'STELLURIINI',
  'home': 'ホーム',
  'about': '概要',
  'history': '取引履歴',
  'roadmap': 'ロードマップ',
  'token': 'STLトークン',
  'tokenomics': 'トークノミクス',
  'whitepaper': 'ホワイトペーパー',
  'language': '言語',
  'logout': 'ログアウト',
  'menu': 'メニュー',

  // ============================================================
  // 💰 BALANCE / MINING
  // ============================================================

  'balance': '残高',
  'mining': 'マイニング',
  'miningRate': 'マイニング速度',
  'hashRate': 'ハッシュレート',
  'effectiveHashRate': '実効ハッシュレート',
  'effectiveHashRateLabel': '実効ハッシュレート',

  'dailyHashRateLabel': 'デイリーハッシュレート',
  'dailyHashRateDay': '{day}日目',
  'dailyHashRateMaximum': '最大: {rate} HR',
  'dailyHashRateSuccess': '{day}日目のハッシュレート: {rate} HR',

  'stellaMiningProgress': 'Stellaマイニング進捗',
  'stlPerHour': '1時間あたりのSTL',
  'hashRateBonus': 'ハッシュレートボーナス',

  'startMining': 'マイニング開始',
  'claimMining': 'STLを受け取る',
  'miningActive': 'マイニング中',
  'miningComplete': 'マイニングサイクル完了',

  'timeRemaining': '残り時間',
  'remaining': '残り: {time}',

  'streak': '連続日数',
  'days': '日',

  // ============================================================
  // 🎁 DAILY BONUS
  // ============================================================

  'dailyBonus': 'デイリーボーナス',
  'dailyClaim': 'デイリーボーナスを受け取る',
  'dailyReward': 'デイリー報酬',
  'claimedToday': '本日受け取り済み',
  'alreadyClaimed': '本日の報酬はすでに受け取っています。',

  // ============================================================
  // 📺 ADS
  // ============================================================

  'watchAd': '広告を見る',
  'watchAndEarn': '広告を見て獲得',
  'loadingAd': '広告を読み込み中...',
  'adLoading': '広告を読み込み中...',
  'adReward': '+{amount} HR',

  // ============================================================
  // ⚡ STELLA POWER BOOST
  // ============================================================

  'powerBoost': 'Stella Power Boost',

  'powerBoostOffer':
      '広告を見て、4時間の間Stella Power Boost +{amount} HRを有効にします。',

  'powerBoostActive':
      'Power Boost有効中',

  'powerBoostActiveTitle':
      'Stella Power Boostが有効になりました！',

  'powerBoostActiveMessage':
      '+{amount} HRがマイニングサイクルに適用されます。',

  'powerBoostAlreadyActive':
      'Power Boostはすでに有効です。',

  'nextPowerBoostMessage':
      '現在のBoostが終了すると、次のPower Boostを使用できます。',

  'nextAdAfterBoost':
      'Boost終了後に次の広告を見ることができます。',

  'maxBoostsInfo':
      'Power Boostは1日最大{count}回まで有効にできます。',

  'adsToday':
      '本日の広告: {current}/{max}',

  'dailyLimitReached':
      '本日の広告上限に達しました。',

  'powerBoostReward':
      'Stella Power Boost: +{amount} HR',

  'adRewardDuplicate':
      'この広告報酬はすでに処理されています。',

  'testAdRewardFailed':
      '広告報酬を処理できませんでした。',

  // ============================================================
  // 🌐 SERVER
  // ============================================================

  'serverConnectionFailed':
      'サーバーに接続できませんでした。',

  'refresh':
      '更新',

  // ============================================================
  // 👤 GENERAL UI
  // ============================================================

  'profile':
      'プロフィール',

  'comingSoon':
      '近日公開',

  'information':
      '情報',

  // ============================================================
  // 🐱 STELLA
  // ============================================================

  'catFact':
      'Stellaの猫豆知識',

  'stellaFacts':
      'Stellaの猫豆知識',

  'stellaPower':
      'Stella Power',

  'stellaMining':
      'Stella Mining',

  'stellaIsMining':
      'Stellaがマイニング中',

  'stellaMiningNow':
      'Stellaは現在マイニング中です',

  'stellaIsResting':
      'Stellaは休憩中です',

  'stellaWaiting':
      'Stellaは次のマイニングサイクルを待っています',

  'stlReadyToCollect':
      'STLを受け取る準備ができました',

  'stlMined':
      'マイニングしたSTL',

  'waitingForStella':
      'Stellaを待っています',

  'stellaIsWorking':
      'STELLA 作業中...',

  'stellaIsMiningButton':
      'マイニング中',

  'stellaAlreadyMining':
      'Stellaはすでにマイニング中です。',

  'prepareAd':
      '広告を準備中...',

  'miningCollected':
      '{amount} STLを受け取りました',

  'miningStartFailed':
      'マイニングを開始できませんでした。',

  // ============================================================
  // 💎 TRANSACTIONS
  // ============================================================

  'transactions':
      '取引',

  'noTransactions':
      'まだ取引はありません。',

  'totalStl':
      'STL合計',

  'points':
      'ポイント',

  'pointsAdded':
      'ポイントを追加しました',

  // ============================================================
  // 🔄 TEST ACCOUNT
  // ============================================================

  'resetAccount':
      'テストアカウントをリセット',

  'resetConfirm':
      'テストアカウントをリセットしてもよろしいですか？',

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

  // ============================================================
  // 🔐 LOGIN
  // ============================================================

  'email':
      'メールアドレス',

  'password':
      'パスワード',

  'forgotPassword':
      'パスワードをお忘れですか？',

  'login':
      'ログイン',

  'loggingIn':
      'ログイン中...',

  'createAccount':
      'アカウントをお持ちでないですか？新規登録',

  'loginFillFields':
      'メールアドレスとパスワードを入力してください。',

  'loginInvalidEmail':
      'メールアドレスが正しくありません。',

  'loginUserNotFound':
      'ユーザーが見つかりません。',

  'loginInvalidCredentials':
      'メールアドレスまたはパスワードが正しくありません。',

  'loginUserDisabled':
      'このユーザーアカウントは無効になっています。',

  'loginTooManyRequests':
      '試行回数が多すぎます。しばらくしてからもう一度お試しください。',

  'loginNetworkError':
      'ネットワーク接続に失敗しました。',

  'loginFailed':
      'ログインに失敗しました',

  // ============================================================
  // 📝 REGISTER
  // ============================================================

  'confirmPassword':
      'パスワードを確認',

  'passwordsDoNotMatch':
      'パスワードが一致しません。',

  'passwordTooShort':
      'パスワードは6文字以上で入力してください。',

  'creatingAccount':
      'アカウントを作成中...',

  'accountCreated':
      'アカウントが正常に作成されました。',

  'emailAlreadyInUse':
      'このメールアドレスはすでに使用されています。',

  'passwordTooWeak':
      'パスワードが弱すぎます。',

  'registrationNotAllowed':
      '現在、アカウント登録は許可されていません。',

  'registrationFailed':
      'アカウントの登録に失敗しました。',

  // ============================================================
  // 📜 TRANSACTION HISTORY
  // ============================================================

  'transactionHistory':
      '取引履歴',

  'stellaActivity':
      'Stellaのアクティビティ',

  'latestTransactions':
      '最近の{count}件の取引',

  'dailyStellaBonus':
      'Stellaデイリーボーナス',

  'dailyBonusDescription':
      'Stellaからのデイリーボーナス',

  'stellaAdReward':
      'Stella広告報酬',

  'adRewardDescription':
      '広告視聴後に獲得した報酬',

  'stlTransaction':
      'STL取引',

  'stelluriiniActivity':
      'Stelluriiniアクティビティ',

  'transactionBalance':
      '残高: {balance} STL',

  'tryAgain':
      'もう一度試す',

  'noTransactionsYet':
      'まだ取引はありません',

  'rewardsAppearHere':
      'あなたのSTL報酬はここに表示されます。🐱',

  'startMiningWithStella':
      'Stellaと一緒にマイニングを始めましょう',

  'historyRecorded':
      'マイニング、デイリーボーナス、広告報酬の履歴がここに記録されます。',

  'stellaCheckingHistory':
      'Stellaが履歴を確認しています...',

  'everyRewardJourney':
      'すべての報酬がStelluriiniの旅の一部です。🐾',

  // ============================================================
  // ℹ️ ABOUT
  // ============================================================

  'aboutWelcome':
      'Stelluriiniへようこそ',

  'aboutWelcomeDescription':
      'Stelluriiniは、マスコットでありガイドでもある猫のStellaとともに、Solana上でコミュニティを中心に構築されたプロジェクトです。',

  'aboutDescription':
      'Stelluriiniは、コミュニティ、デジタルトークン、Stellaを中心としたアプリ体験を組み合わせています。',

  'meetStella':
      'Stellaに会おう',

  'aboutStellaIntro':
      'StellaはStelluriiniの中心的な存在であり、プロジェクトを象徴するかわいい猫です。',

  'aboutStellaDescription':
      'Stellaは、マイニング、報酬の獲得、Stelluriiniエコシステムの探索をユーザーと一緒に進めます。',

  'community':
      'コミュニティ',

  'aboutCommunityDescription':
      'Stelluriiniはコミュニティを中心に構築されています。オープンで楽しく、誰でも参加しやすいエコシステムを目指しています。',

  'builtOnSolana':
      'Solana上に構築',

  'aboutSolanaDescription':
      'StelluriiniはSolanaブロックチェーンを使用し、STLトークンのための高速かつ低コストな環境を提供します。',

  'stlToken':
      'STLトークン',

  'importantInformation':
      '重要なお知らせ',

  'aboutImportantDescription':
      '現在アプリに表示されているSTL残高は、アプリ内の仮想ポイントを表しています。自動的に出金可能な暗号資産を意味するものではありません。',

  // ============================================================
  // 🗺️ ROADMAP
  // ============================================================

  'roadmapTitle':
      'Stelluriiniロードマップ',

  'roadmapSubtitle':
      'Stelluriiniの開発ロードマップ。一歩ずつ未来へ進みます。',

  'roadmapPhase1':
      'フェーズ1 – 基盤',

  'roadmapPhase1Title':
      'Stelluriiniの構築',

  'roadmapPhase1Description':
      'Stelluriiniプロジェクト、STLトークン、そしてマスコットStellaを構築します。',

  'roadmapPhase2':
      'フェーズ2 – アプリ',

  'roadmapPhase2Title':
      'Stelluriiniアプリの開発',

  'roadmapPhase2Description':
      'マイニング、デイリーボーナス、Stella Power Boost、取引履歴を実装します。',

  'roadmapPhase3':
      'フェーズ3 – コミュニティ',

  'roadmapPhase3Title':
      'コミュニティの成長',

  'roadmapPhase3Description':
      'コミュニティを構築し、フィードバックを集め、Stelluriiniブランドを成長させます。',

  'roadmapPhase4':
      'フェーズ4 – エコシステム',

  'roadmapPhase4Title':
      'STLエコシステムの拡大',

  'roadmapPhase4Description':
      'STLトークンのユースケースを開発し、Stelluriiniエコシステムを拡大します。',

  'roadmapPhase5':
      'フェーズ5 – 未来',

  'roadmapPhase5Title':
      'Stelluriiniの次の章',

  'roadmapPhase5Description':
      '新機能、将来的なパートナーシップ、コミュニティからのアイデアを探求します。',

  // ============================================================
  // 🪙 TOKEN
  // ============================================================

  'tokenTitle':
      'Stelluriini STL',

  'tokenSubtitle':
      'Solanaネットワーク上のStelluriini公式トークン。',

  'tokenName':
      '名前',

  'tokenSymbol':
      'シンボル',

  'tokenBlockchain':
      'ブロックチェーン',

  'tokenSupply':
      '総供給量',

  'tokenMint':
      'Mintアドレス',

  'tokenDescription':
      'StelluriiniはSolanaブロックチェーン上に構築されたコミュニティ中心のトークンです。',

  'solana':
      'Solana',

  'copyAddress':
      'アドレスをコピー',

  'addressCopied':
      'アドレスをコピーしました。',

  // ============================================================
  // 📊 TOKENOMICS
  // ============================================================

  'tokenomicsTitle':
      'STLトークノミクス',

  'tokenomicsSubtitle':
      'Stelluriini STLトークンの基本情報とトークンエコノミー。',

  'totalSupply':
      '総供給量',

  'tokenAllocation':
      'トークン配分',

  'communityAllocation':
      'コミュニティ',

  'ecosystemAllocation':
      'エコシステム',

  'developmentAllocation':
      '開発',

  'liquidityAllocation':
      '流動性',

  'marketingAllocation':
      'マーケティング',

  'tokenomicsImportant':
      '具体的なトークン配分は、プロジェクトの開発に伴って更新される場合があります。変更がある場合は、コミュニティに対して透明性を持って公開されるべきです。',

  // ============================================================
  // 📄 WHITEPAPER
  // ============================================================

  'whitepaperTitle':
      'Stelluriiniホワイトペーパー',

  'whitepaperSubtitle':
      'Stelluriiniのビジョン、テクノロジー、そして将来の開発方針。',

  'whitepaperIntroduction':
      'はじめに',

  'whitepaperVision':
      'ビジョン',

  'whitepaperMission':
      'ミッション',

  'whitepaperTechnology':
      'テクノロジー',

  'whitepaperMining':
      'マイニングシステム',

  'whitepaperStella':
      'Stella',

  'whitepaperToken':
      'STLトークン',

  'whitepaperTokenomics':
      'トークノミクス',

  'whitepaperCommunity':
      'コミュニティ',

  'whitepaperRoadmap':
      'ロードマップ',

  'whitepaperSecurity':
      'セキュリティ',

  'whitepaperFuture':
      '未来',

  'whitepaperDisclaimer':
      'このホワイトペーパーはStelluriiniプロジェクトの概要を説明するものです。機能や計画は開発の進行に伴って変更される場合があります。',

  // ============================================================
  // ⚠️ IMPORTANT INFORMATION
  // ============================================================

  'virtualPointsNotice':
      'アプリに表示されるSTL報酬は、現在アプリ内の仮想ポイントです。',

  'withdrawalsDisabled':
      '現在、出金機能は利用できません。',

  'futureWithdrawals':
      '将来的にSTL出金システムを導入する場合は、個別に設計され、導入前に条件が公開されます。',

  // ============================================================
  // 🐾 FOOTER
  // ============================================================

  'footerTagline':
      'Stelluriiniと一緒にマイニングし、未来を築きましょう。',

  'footerToken':
      'STL • STELLURIINI',
};