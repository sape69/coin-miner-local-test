class AppLocalizations {
  final String languageCode;

  AppLocalizations(this.languageCode);

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

  static const Map<String, Map<String, String>> _translations = {
    // ==========================================================
    // SUOMI
    // ==========================================================
    'fi': {
      'stella': 'Stella',
      'yourBalance': 'SINUN STL-SALDOSI',
      'virtualPoints': 'Virtuaalisia sovelluspisteitä',
      'dailyClaim': 'Päivittäinen palkinto',
      'dailyReward': 'LUNASTA PÄIVÄN PALKINTO',
      'claimed': 'Lunastettu tänään',
      'streak': 'Päiväputki',
      'watchEarn': 'Katso ja ansaitse',
      'watchAd': 'KATSO MAINOS +3 STL',
      'adLoading': 'MAINOSTA LADATAAN...',
      'adUnavailable': 'MAINOS EI SAATAVILLA',
      'dailyLimit': 'Päivän mainokset',
      'dailyLimitReached': 'Päivän mainosraja saavutettu',
      'nextAd': 'Seuraava mainos',
      'pointsAdded': '+3 STL lisätty!',
      'stellaFacts': 'Stellan kissafakta 🐱',
      'info': 'Tietoa Stelluriinista',
      'solanaToken':
          'Stelluriini (STL) on Solana-ekosysteemiin liittyvä token-projekti.',
      'stellaCompany':
          'STL-pisteet tässä sovelluksessa ovat sovelluksen sisäisiä virtuaalisia pisteitä.',
      'selectLanguage': 'Valitse kieli',
      'login': 'Kirjaudu sisään',
      'register': 'Luo tili',
      'email': 'Sähköposti',
      'password': 'Salasana',
      'logout': 'Kirjaudu ulos',
    },

    // ==========================================================
    // ENGLISH
    // ==========================================================
    'en': {
      'stella': 'Stella',
      'yourBalance': 'YOUR STL BALANCE',
      'virtualPoints': 'Virtual in-app points',
      'dailyClaim': 'Daily reward',
      'dailyReward': 'CLAIM DAILY REWARD',
      'claimed': 'Claimed today',
      'streak': 'Daily streak',
      'watchEarn': 'Watch and earn',
      'watchAd': 'WATCH AD +3 STL',
      'adLoading': 'LOADING AD...',
      'adUnavailable': 'AD NOT AVAILABLE',
      'dailyLimit': 'Daily ads',
      'dailyLimitReached': 'Daily ad limit reached',
      'nextAd': 'Next ad',
      'pointsAdded': '+3 STL added!',
      'stellaFacts': 'Stella’s cat fact 🐱',
      'info': 'About Stelluriini',
      'solanaToken':
          'Stelluriini (STL) is a token project connected to the Solana ecosystem.',
      'stellaCompany':
          'The STL points in this app are virtual in-app points.',
      'selectLanguage': 'Select language',
      'login': 'Log in',
      'register': 'Create account',
      'email': 'Email',
      'password': 'Password',
      'logout': 'Log out',
    },

    // ==========================================================
    // DEUTSCH
    // ==========================================================
    'de': {
      'stella': 'Stella',
      'yourBalance': 'DEIN STL-GUTHABEN',
      'virtualPoints': 'Virtuelle Punkte in der App',
      'dailyClaim': 'Tägliche Belohnung',
      'dailyReward': 'TAGESBELOHNUNG ABHOLEN',
      'claimed': 'Heute abgeholt',
      'streak': 'Tagesserie',
      'watchEarn': 'Ansehen und verdienen',
      'watchAd': 'WERBUNG ANSEHEN +3 STL',
      'adLoading': 'WERBUNG WIRD GELADEN...',
      'adUnavailable': 'WERBUNG NICHT VERFÜGBAR',
      'dailyLimit': 'Tägliche Werbung',
      'dailyLimitReached': 'Tägliches Werbelimit erreicht',
      'nextAd': 'Nächste Werbung',
      'pointsAdded': '+3 STL hinzugefügt!',
      'stellaFacts': 'Stellas Katzenfakt 🐱',
      'info': 'Über Stelluriini',
      'solanaToken':
          'Stelluriini (STL) ist ein Token-Projekt im Zusammenhang mit dem Solana-Ökosystem.',
      'stellaCompany':
          'Die STL-Punkte in dieser App sind virtuelle Punkte innerhalb der App.',
      'selectLanguage': 'Sprache auswählen',
      'login': 'Anmelden',
      'register': 'Konto erstellen',
      'email': 'E-Mail',
      'password': 'Passwort',
      'logout': 'Abmelden',
    },

    // ==========================================================
    // ESPAÑOL
    // ==========================================================
    'es': {
      'stella': 'Stella',
      'yourBalance': 'TU SALDO DE STL',
      'virtualPoints': 'Puntos virtuales dentro de la aplicación',
      'dailyClaim': 'Recompensa diaria',
      'dailyReward': 'RECLAMAR RECOMPENSA DIARIA',
      'claimed': 'Reclamado hoy',
      'streak': 'Racha diaria',
      'watchEarn': 'Mira y gana',
      'watchAd': 'VER ANUNCIO +3 STL',
      'adLoading': 'CARGANDO ANUNCIO...',
      'adUnavailable': 'ANUNCIO NO DISPONIBLE',
      'dailyLimit': 'Anuncios diarios',
      'dailyLimitReached': 'Límite diario de anuncios alcanzado',
      'nextAd': 'Próximo anuncio',
      'pointsAdded': '+3 STL añadidos!',
      'stellaFacts': 'Dato curioso de Stella 🐱',
      'info': 'Sobre Stelluriini',
      'solanaToken':
          'Stelluriini (STL) es un proyecto de token relacionado con el ecosistema Solana.',
      'stellaCompany':
          'Los puntos STL de esta aplicación son puntos virtuales dentro de la aplicación.',
      'selectLanguage': 'Seleccionar idioma',
      'login': 'Iniciar sesión',
      'register': 'Crear cuenta',
      'email': 'Correo electrónico',
      'password': 'Contraseña',
      'logout': 'Cerrar sesión',
    },

    // ==========================================================
    // FRANÇAIS
    // ==========================================================
    'fr': {
      'stella': 'Stella',
      'yourBalance': 'TON SOLDE STL',
      'virtualPoints': 'Points virtuels dans l’application',
      'dailyClaim': 'Récompense quotidienne',
      'dailyReward': 'RÉCLAMER LA RÉCOMPENSE',
      'claimed': 'Réclamée aujourd’hui',
      'streak': 'Série quotidienne',
      'watchEarn': 'Regarder et gagner',
      'watchAd': 'REGARDER LA PUB +3 STL',
      'adLoading': 'CHARGEMENT DE LA PUB...',
      'adUnavailable': 'PUBLICITÉ NON DISPONIBLE',
      'dailyLimit': 'Publicités quotidiennes',
      'dailyLimitReached': 'Limite quotidienne atteinte',
      'nextAd': 'Prochaine publicité',
      'pointsAdded': '+3 STL ajoutés !',
      'stellaFacts': 'Le fait sur les chats de Stella 🐱',
      'info': 'À propos de Stelluriini',
      'solanaToken':
          'Stelluriini (STL) est un projet de token lié à l’écosystème Solana.',
      'stellaCompany':
          'Les points STL dans cette application sont des points virtuels internes.',
      'selectLanguage': 'Choisir la langue',
      'login': 'Se connecter',
      'register': 'Créer un compte',
      'email': 'E-mail',
      'password': 'Mot de passe',
      'logout': 'Se déconnecter',
    },

    // ==========================================================
    // 中文
    // ==========================================================
    'zh': {
      'stella': 'Stella',
      'yourBalance': '你的 STL 余额',
      'virtualPoints': '应用内虚拟积分',
      'dailyClaim': '每日奖励',
      'dailyReward': '领取每日奖励',
      'claimed': '今天已领取',
      'streak': '连续签到',
      'watchEarn': '观看并赚取',
      'watchAd': '观看广告 +3 STL',
      'adLoading': '正在加载广告...',
      'adUnavailable': '广告暂时不可用',
      'dailyLimit': '每日广告',
      'dailyLimitReached': '已达到每日广告限制',
      'nextAd': '下一次广告',
      'pointsAdded': '已添加 +3 STL！',
      'stellaFacts': 'Stella 的猫咪知识 🐱',
      'info': '关于 Stelluriini',
      'solanaToken':
          'Stelluriini (STL) 是一个与 Solana 生态系统相关的代币项目。',
      'stellaCompany':
          '此应用中的 STL 积分是应用内的虚拟积分。',
      'selectLanguage': '选择语言',
      'login': '登录',
      'register': '创建账户',
      'email': '电子邮箱',
      'password': '密码',
      'logout': '退出登录',
    },

    // ==========================================================
    // TIẾNG VIỆT
    // ==========================================================
    'vi': {
      'stella': 'Stella',
      'yourBalance': 'SỐ DƯ STL CỦA BẠN',
      'virtualPoints': 'Điểm ảo trong ứng dụng',
      'dailyClaim': 'Phần thưởng hàng ngày',
      'dailyReward': 'NHẬN PHẦN THƯỞNG HÀNG NGÀY',
      'claimed': 'Đã nhận hôm nay',
      'streak': 'Chuỗi ngày liên tiếp',
      'watchEarn': 'Xem và nhận thưởng',
      'watchAd': 'XEM QUẢNG CÁO +3 STL',
      'adLoading': 'ĐANG TẢI QUẢNG CÁO...',
      'adUnavailable': 'QUẢNG CÁO KHÔNG KHẢ DỤNG',
      'dailyLimit': 'Quảng cáo mỗi ngày',
      'dailyLimitReached': 'Đã đạt giới hạn quảng cáo hàng ngày',
      'nextAd': 'Quảng cáo tiếp theo',
      'pointsAdded': 'Đã thêm +3 STL!',
      'stellaFacts': 'Sự thật về mèo của Stella 🐱',
      'info': 'Thông tin về Stelluriini',
      'solanaToken':
          'Stelluriini (STL) là một dự án token liên quan đến hệ sinh thái Solana.',
      'stellaCompany':
          'Điểm STL trong ứng dụng này là điểm ảo bên trong ứng dụng.',
      'selectLanguage': 'Chọn ngôn ngữ',
      'login': 'Đăng nhập',
      'register': 'Tạo tài khoản',
      'email': 'Email',
      'password': 'Mật khẩu',
      'logout': 'Đăng xuất',
    },

    // ==========================================================
    // 日本語
    // ==========================================================
    'ja': {
      'stella': 'Stella',
      'yourBalance': 'あなたの STL 残高',
      'virtualPoints': 'アプリ内の仮想ポイント',
      'dailyClaim': '毎日の報酬',
      'dailyReward': '毎日の報酬を受け取る',
      'claimed': '本日は受け取り済み',
      'streak': '連続記録',
      'watchEarn': '視聴して獲得',
      'watchAd': '広告を見る +3 STL',
      'adLoading': '広告を読み込み中...',
      'adUnavailable': '広告を利用できません',
      'dailyLimit': '1日の広告',
      'dailyLimitReached': '1日の広告上限に達しました',
      'nextAd': '次の広告',
      'pointsAdded': '+3 STL を追加しました！',
      'stellaFacts': 'Stella の猫の豆知識 🐱',
      'info': 'Stelluriini について',
      'solanaToken':
          'Stelluriini（STL）は、Solanaエコシステムに関連するトークンプロジェクトです。',
      'stellaCompany':
          'このアプリ内のSTLポイントは仮想的なアプリ内ポイントです。',
      'selectLanguage': '言語を選択',
      'login': 'ログイン',
      'register': 'アカウントを作成',
      'email': 'メールアドレス',
      'password': 'パスワード',
      'logout': 'ログアウト',
    },
  };

  String get(String key) {
    return _translations[languageCode]?[key] ??
        _translations['en']?[key] ??
        _translations['fi']?[key] ??
        key;
  }
}