class AppLocalizations {
  final String languageCode;

  const AppLocalizations(this.languageCode);

  static const Map<String, String> supportedLanguages = {
    'fi': '🇫🇮 Suomi',
    'en': '🇬🇧 English',
    'sv': '🇸🇪 Svenska',
    'de': '🇩🇪 Deutsch',
    'es': '🇪🇸 Español',
    'fr': '🇫🇷 Français',
    'it': '🇮🇹 Italiano',
    'pt': '🇵🇹 Português',
    'ja': '🇯🇵 日本語',
    'zh': '🇨🇳 中文',
  };

  String get(String key) {
    final language =
        _translations[languageCode] ?? _translations['fi']!;

    return language[key] ?? _translations['fi']![key] ?? key;
  }

  static const Map<String, Map<String, String>> _translations = {
    'fi': {
      'appTitle': 'Stelluriini',
      'settings': 'Asetukset',
      'language': 'Kieli',
      'selectLanguage': 'Valitse kieli',
      'yourBalance': 'SALDOSI',
      'dailyClaim': 'PÄIVITTÄINEN PALKINTO',
      'watchEarn': 'KATSO JA ANSAITSE',
      'watchAd': 'Katso mainos',
      'watchAdReward': 'Katso mainos ja saat +3 STL.',
      'today': 'Tänään',
      'dailyLimit': 'PÄIVÄRAJA',
      'loadingAd': 'LADATAAN MAINOSTA...',
      'wait': 'ODOTA',
      'stella': '🐱 Stella',
      'stellaFacts': 'STELLAN KISSAFAKTA',
      'day': 'Päivä',
      'stats': 'TILASTOT',
      'streak': 'PUTKI',
      'ads': 'MAINOKSET',
      'info': 'TIETOJA',
      'solanaToken':
          'Stelluriini on Solana-verkossa oleva yhteisötokeni.',
      'stellaCompany':
          '🐱 Stella pitää sinulle seuraa Stelluriinin parissa!',
      'nextClaim': 'SEURAAVA PALKINTO',
      'claimed': 'KÄYTETTY',
      'dailyReward': 'PÄIVÄN PALKINTO',
      'sevenDayStreak': '🔥 7 päivän putki saavutettu!',
      'sevenDayReward':
          'Saat 7 STL joka päivä, kunnes päivä jää väliin.',
      'dailyAd':
          '📺 Päivittäinen palkinto näyttää mainoksen.',
      'logout': 'Kirjaudu ulos',
      'languageChanged': 'Kieli vaihdettu',
      'adLoading':
          'Mainos latautuu. Odota hetki.',
      'adFailed':
          'Mainosta ei voitu näyttää.',
      'dailyLimitReached':
          'Päivän mainosraja 5/5 on täynnä.',
      'waitMessage': 'Odota',
      'pointsAdded': '+3 STL! 🐱',
      'dailyAdded': 'Päivittäinen palkinto',
      'next': 'Seuraava',
      'resetTestData': 'Nollaa testidata',
      'testDataReset': 'Testidata nollattu',
      'virtualPoints': 'Virtuaalisia sovelluspisteitä',
    },

    'en': {
      'appTitle': 'Stelluriini',
      'settings': 'Settings',
      'language': 'Language',
      'selectLanguage': 'Select language',
      'yourBalance': 'YOUR BALANCE',
      'dailyClaim': 'DAILY CLAIM',
      'watchEarn': 'WATCH & EARN',
      'watchAd': 'Watch ad',
      'watchAdReward':
          'Watch an ad and receive +3 STL.',
      'today': 'Today',
      'dailyLimit': 'DAILY LIMIT',
      'loadingAd': 'LOADING AD...',
      'wait': 'WAIT',
      'stella': '🐱 Stella',
      'stellaFacts': "STELLA'S CAT FACT",
      'day': 'Day',
      'stats': 'STATS',
      'streak': 'STREAK',
      'ads': 'ADS',
      'info': 'INFORMATION',
      'solanaToken':
          'Stelluriini is a community token on the Solana network.',
      'stellaCompany':
          '🐱 Stella keeps you company while using Stelluriini!',
      'nextClaim': 'NEXT CLAIM',
      'claimed': 'CLAIMED',
      'dailyReward': "TODAY'S REWARD",
      'sevenDayStreak':
          '🔥 7-day streak achieved!',
      'sevenDayReward':
          'You receive 7 STL every day until you miss a day.',
      'dailyAd':
          '📺 Daily Claim requires watching an ad.',
      'logout': 'Log out',
      'languageChanged': 'Language changed',
      'adLoading':
          'The ad is loading. Please wait.',
      'adFailed':
          'The ad could not be shown.',
      'dailyLimitReached':
          'The daily ad limit of 5/5 has been reached.',
      'waitMessage': 'Wait',
      'pointsAdded': '+3 STL! 🐱',
      'dailyAdded': 'Daily Claim',
      'next': 'Next',
      'resetTestData': 'Reset test data',
      'testDataReset': 'Test data reset',
      'virtualPoints': 'Virtual in-app points',
    },

    'sv': {
      'appTitle': 'Stelluriini',
      'settings': 'Inställningar',
      'language': 'Språk',
      'selectLanguage': 'Välj språk',
      'yourBalance': 'DITT SALDO',
      'dailyClaim': 'DAGLIG BELÖNING',
      'watchEarn': 'TITTA & TJÄNA',
      'watchAd': 'Titta på annons',
      'watchAdReward':
          'Titta på en annons och få +3 STL.',
      'today': 'Idag',
      'dailyLimit': 'DAGLIG GRÄNS',
      'loadingAd': 'LADDAR ANNONS...',
      'wait': 'VÄNTA',
      'stella': '🐱 Stella',
      'stellaFacts': 'STELLAS KATTFAKTA',
      'day': 'Dag',
      'stats': 'STATISTIK',
      'streak': 'SVIT',
      'ads': 'ANNONSER',
      'info': 'INFORMATION',
      'solanaToken':
          'Stelluriini är en community-token på Solana-nätverket.',
      'stellaCompany':
          '🐱 Stella håller dig sällskap med Stelluriini!',
      'nextClaim': 'NÄSTA BELÖNING',
      'claimed': 'ANVÄND',
      'dailyReward': 'DAGENS BELÖNING',
      'sevenDayStreak':
          '🔥 7 dagars svit uppnådd!',
      'sevenDayReward':
          'Du får 7 STL varje dag tills du missar en dag.',
      'dailyAd':
          '📺 Den dagliga belöningen kräver en annons.',
      'logout': 'Logga ut',
      'languageChanged': 'Språket ändrades',
      'adLoading':
          'Annonsen laddas. Vänta.',
      'adFailed':
          'Annonsen kunde inte visas.',
      'dailyLimitReached':
          'Den dagliga annonsgränsen 5/5 är nådd.',
      'waitMessage': 'Vänta',
      'pointsAdded': '+3 STL! 🐱',
      'dailyAdded': 'Daglig belöning',
      'next': 'Nästa',
      'resetTestData': 'Återställ testdata',
      'testDataReset': 'Testdata återställd',
      'virtualPoints': 'Virtuella app-poäng',
    },

    'de': {
      'appTitle': 'Stelluriini',
      'settings': 'Einstellungen',
      'language': 'Sprache',
      'selectLanguage': 'Sprache auswählen',
      'yourBalance': 'DEIN GUTHABEN',
      'dailyClaim': 'TÄGLICHE BELOHNUNG',
      'watchEarn': 'ANSEHEN & VERDIENEN',
      'watchAd': 'Werbung ansehen',
      'watchAdReward':
          'Sieh dir eine Werbung an und erhalte +3 STL.',
      'today': 'Heute',
      'dailyLimit': 'TAGESLIMIT',
      'loadingAd': 'WERBUNG WIRD GELADEN...',
      'wait': 'WARTEN',
      'stella': '🐱 Stella',
      'stellaFacts': 'STELLAS KATZENFAKT',
      'day': 'Tag',
      'stats': 'STATISTIK',
      'streak': 'SERIE',
      'ads': 'WERBUNG',
      'info': 'INFORMATIONEN',
      'solanaToken':
          'Stelluriini ist ein Community-Token auf dem Solana-Netzwerk.',
      'stellaCompany':
          '🐱 Stella begleitet dich bei Stelluriini!',
      'nextClaim': 'NÄCHSTE BELOHNUNG',
      'claimed': 'VERWENDET',
      'dailyReward': 'HEUTIGE BELOHNUNG',
      'sevenDayStreak':
          '🔥 7-Tage-Serie erreicht!',
      'sevenDayReward':
          'Du erhältst jeden Tag 7 STL, bis du einen Tag verpasst.',
      'dailyAd':
          '📺 Die tägliche Belohnung erfordert eine Werbung.',
      'logout': 'Abmelden',
      'languageChanged': 'Sprache geändert',
      'adLoading':
          'Werbung wird geladen. Bitte warten.',
      'adFailed':
          'Die Werbung konnte nicht angezeigt werden.',
      'dailyLimitReached':
          'Das tägliche Werbelimit von 5/5 ist erreicht.',
      'waitMessage': 'Warten',
      'pointsAdded': '+3 STL! 🐱',
      'dailyAdded': 'Tägliche Belohnung',
      'next': 'Weiter',
      'resetTestData': 'Testdaten zurücksetzen',
      'testDataReset': 'Testdaten zurückgesetzt',
      'virtualPoints': 'Virtuelle App-Punkte',
    },

    'es': {
      'appTitle': 'Stelluriini',
      'settings': 'Ajustes',
      'language': 'Idioma',
      'selectLanguage': 'Seleccionar idioma',
      'yourBalance': 'TU SALDO',
      'dailyClaim': 'RECOMPENSA DIARIA',
      'watchEarn': 'VER Y GANAR',
      'watchAd': 'Ver anuncio',
      'watchAdReward':
          'Mira un anuncio y recibe +3 STL.',
      'today': 'Hoy',
      'dailyLimit': 'LÍMITE DIARIO',
      'loadingAd': 'CARGANDO ANUNCIO...',
      'wait': 'ESPERA',
      'stella': '🐱 Stella',
      'stellaFacts': 'DATO SOBRE STELLA',
      'day': 'Día',
      'stats': 'ESTADÍSTICAS',
      'streak': 'RACHA',
      'ads': 'ANUNCIOS',
      'info': 'INFORMACIÓN',
      'solanaToken':
          'Stelluriini es un token comunitario en la red Solana.',
      'stellaCompany':
          '🐱 Stella te acompaña mientras usas Stelluriini.',
      'nextClaim': 'SIGUIENTE RECOMPENSA',
      'claimed': 'USADO',
      'dailyReward': 'RECOMPENSA DE HOY',
      'sevenDayStreak':
          '🔥 ¡Racha de 7 días conseguida!',
      'sevenDayReward':
          'Recibes 7 STL cada día hasta que pierdas un día.',
      'dailyAd':
          '📺 La recompensa diaria requiere un anuncio.',
      'logout': 'Cerrar sesión',
      'languageChanged': 'Idioma cambiado',
      'adLoading':
          'El anuncio se está cargando. Espera.',
      'adFailed':
          'No se pudo mostrar el anuncio.',
      'dailyLimitReached':
          'Se alcanzó el límite diario de anuncios 5/5.',
      'waitMessage': 'Espera',
      'pointsAdded': '+3 STL! 🐱',
      'dailyAdded': 'Recompensa diaria',
      'next': 'Siguiente',
      'resetTestData': 'Restablecer datos de prueba',
      'testDataReset': 'Datos de prueba restablecidos',
      'virtualPoints': 'Puntos virtuales de la aplicación',
    },

    'fr': {
      'appTitle': 'Stelluriini',
      'settings': 'Paramètres',
      'language': 'Langue',
      'selectLanguage': 'Choisir la langue',
      'yourBalance': 'VOTRE SOLDE',
      'dailyClaim': 'RÉCOMPENSE QUOTIDIENNE',
      'watchEarn': 'REGARDER & GAGNER',
      'watchAd': 'Regarder une publicité',
      'watchAdReward':
          'Regardez une publicité et recevez +3 STL.',
      'today': "Aujourd'hui",
      'dailyLimit': 'LIMITE QUOTIDIENNE',
      'loadingAd': 'CHARGEMENT DE LA PUBLICITÉ...',
      'wait': 'ATTENDRE',
      'stella': '🐱 Stella',
      'stellaFacts': 'FAIT SUR STELLA',
      'day': 'Jour',
      'stats': 'STATISTIQUES',
      'streak': 'SÉRIE',
      'ads': 'PUBLICITÉS',
      'info': 'INFORMATIONS',
      'solanaToken':
          'Stelluriini est un token communautaire sur le réseau Solana.',
      'stellaCompany':
          '🐱 Stella vous accompagne avec Stelluriini !',
      'nextClaim': 'PROCHAINE RÉCOMPENSE',
      'claimed': 'UTILISÉ',
      'dailyReward': "RÉCOMPENSE D'AUJOURD'HUI",
      'sevenDayStreak':
          '🔥 Série de 7 jours atteinte !',
      'sevenDayReward':
          'Vous recevez 7 STL chaque jour jusqu’à manquer un jour.',
      'dailyAd':
          '📺 La récompense quotidienne nécessite une publicité.',
      'logout': 'Se déconnecter',
      'languageChanged': 'Langue modifiée',
      'adLoading':
          'La publicité se charge. Veuillez patienter.',
      'adFailed':
          'La publicité n’a pas pu être affichée.',
      'dailyLimitReached':
          'La limite quotidienne de publicités 5/5 est atteinte.',
      'waitMessage': 'Attendre',
      'pointsAdded': '+3 STL ! 🐱',
      'dailyAdded': 'Récompense quotidienne',
      'next': 'Suivant',
      'resetTestData': 'Réinitialiser les données de test',
      'testDataReset': 'Données de test réinitialisées',
      'virtualPoints': 'Points virtuels dans l’application',
    },

    'it': {
      'appTitle': 'Stelluriini',
      'settings': 'Impostazioni',
      'language': 'Lingua',
      'selectLanguage': 'Seleziona lingua',
      'yourBalance': 'IL TUO SALDO',
      'dailyClaim': 'RICOMPENSA GIORNALIERA',
      'watchEarn': 'GUARDA E GUADAGNA',
      'watchAd': 'Guarda annuncio',
      'watchAdReward':
          'Guarda un annuncio e ricevi +3 STL.',
      'today': 'Oggi',
      'dailyLimit': 'LIMITE GIORNALIERO',
      'loadingAd': 'CARICAMENTO ANNUNCIO...',
      'wait': 'ATTENDI',
      'stella': '🐱 Stella',
      'stellaFacts': 'CURIOSITÀ SU STELLA',
      'day': 'Giorno',
      'stats': 'STATISTICHE',
      'streak': 'SERIE',
      'ads': 'ANNUNCI',
      'info': 'INFORMAZIONI',
      'solanaToken':
          'Stelluriini è un token della comunità sulla rete Solana.',
      'stellaCompany':
          '🐱 Stella ti tiene compagnia con Stelluriini!',
      'nextClaim': 'PROSSIMA RICOMPENSA',
      'claimed': 'UTILIZZATO',
      'dailyReward': 'RICOMPENSA DI OGGI',
      'sevenDayStreak':
          '🔥 Serie di 7 giorni raggiunta!',
      'sevenDayReward':
          'Ricevi 7 STL ogni giorno finché non salti un giorno.',
      'dailyAd':
          '📺 La ricompensa giornaliera richiede un annuncio.',
      'logout': 'Esci',
      'languageChanged': 'Lingua cambiata',
      'adLoading':
          "L'annuncio si sta caricando. Attendi.",
      'adFailed':
          "L'annuncio non può essere mostrato.",
      'dailyLimitReached':
          'Il limite giornaliero di annunci 5/5 è stato raggiunto.',
      'waitMessage': 'Attendi',
      'pointsAdded': '+3 STL! 🐱',
      'dailyAdded': 'Ricompensa giornaliera',
      'next': 'Avanti',
      'resetTestData': 'Reimposta dati di test',
      'testDataReset': 'Dati di test reimpostati',
      'virtualPoints': 'Punti virtuali nell’app',
    },

    'pt': {
      'appTitle': 'Stelluriini',
      'settings': 'Configurações',
      'language': 'Idioma',
      'selectLanguage': 'Selecionar idioma',
      'yourBalance': 'SEU SALDO',
      'dailyClaim': 'RECOMPENSA DIÁRIA',
      'watchEarn': 'ASSISTA E GANHE',
      'watchAd': 'Assistir anúncio',
      'watchAdReward':
          'Assista a um anúncio e receba +3 STL.',
      'today': 'Hoje',
      'dailyLimit': 'LIMITE DIÁRIO',
      'loadingAd': 'CARREGANDO ANÚNCIO...',
      'wait': 'AGUARDE',
      'stella': '🐱 Stella',
      'stellaFacts': 'CURIOSIDADE DA STELLA',
      'day': 'Dia',
      'stats': 'ESTATÍSTICAS',
      'streak': 'SEQUÊNCIA',
      'ads': 'ANÚNCIOS',
      'info': 'INFORMAÇÕES',
      'solanaToken':
          'Stelluriini é um token comunitário na rede Solana.',
      'stellaCompany':
          '🐱 Stella faz companhia enquanto você usa Stelluriini!',
      'nextClaim': 'PRÓXIMA RECOMPENSA',
      'claimed': 'USADO',
      'dailyReward': 'RECOMPENSA DE HOJE',
      'sevenDayStreak':
          '🔥 Sequência de 7 dias alcançada!',
      'sevenDayReward':
          'Você recebe 7 STL todos os dias até perder um dia.',
      'dailyAd':
          '📺 A recompensa diária requer um anúncio.',
      'logout': 'Sair',
      'languageChanged': 'Idioma alterado',
      'adLoading':
          'O anúncio está carregando. Aguarde.',
      'adFailed':
          'Não foi possível mostrar o anúncio.',
      'dailyLimitReached':
          'O limite diário de anúncios 5/5 foi atingido.',
      'waitMessage': 'Aguarde',
      'pointsAdded': '+3 STL! 🐱',
      'dailyAdded': 'Recompensa diária',
      'next': 'Próximo',
      'resetTestData': 'Redefinir dados de teste',
      'testDataReset': 'Dados de teste redefinidos',
      'virtualPoints': 'Pontos virtuais no aplicativo',
    },

    'ja': {
      'appTitle': 'Stelluriini',
      'settings': '設定',
      'language': '言語',
      'selectLanguage': '言語を選択',
      'yourBalance': 'あなたの残高',
      'dailyClaim': 'デイリー報酬',
      'watchEarn': '広告を見て獲得',
      'watchAd': '広告を見る',
      'watchAdReward':
          '広告を見ると +3 STL を獲得できます。',
      'today': '今日',
      'dailyLimit': '1日の上限',
      'loadingAd': '広告を読み込み中...',
      'wait': '待機',
      'stella': '🐱 ステラ',
      'stellaFacts': 'ステラの猫豆知識',
      'day': '日',
      'stats': '統計',
      'streak': '連続日数',
      'ads': '広告',
      'info': '情報',
      'solanaToken':
          'StelluriiniはSolanaネットワーク上のコミュニティトークンです。',
      'stellaCompany':
          '🐱 ステラがStelluriiniと一緒にあなたをサポートします！',
      'nextClaim': '次の報酬',
      'claimed': '使用済み',
      'dailyReward': '今日の報酬',
      'sevenDayStreak':
          '🔥 7日連続達成！',
      'sevenDayReward':
          '1日休むまで毎日7 STLを獲得できます。',
      'dailyAd':
          '📺 デイリー報酬には広告が必要です。',
      'logout': 'ログアウト',
      'languageChanged': '言語を変更しました',
      'adLoading':
          '広告を読み込んでいます。お待ちください。',
      'adFailed':
          '広告を表示できませんでした。',
      'dailyLimitReached':
          '1日の広告上限5/5に達しました。',
      'waitMessage': '待機',
      'pointsAdded': '+3 STL! 🐱',
      'dailyAdded': 'デイリー報酬',
      'next': '次へ',
      'resetTestData': 'テストデータをリセット',
      'testDataReset': 'テストデータをリセットしました',
      'virtualPoints': 'アプリ内の仮想ポイント',
    },

    'zh': {
      'appTitle': 'Stelluriini',
      'settings': '设置',
      'language': '语言',
      'selectLanguage': '选择语言',
      'yourBalance': '你的余额',
      'dailyClaim': '每日奖励',
      'watchEarn': '观看并赚取',
      'watchAd': '观看广告',
      'watchAdReward':
          '观看广告可获得 +3 STL。',
      'today': '今天',
      'dailyLimit': '每日上限',
      'loadingAd': '正在加载广告...',
      'wait': '等待',
      'stella': '🐱 Stella',
      'stellaFacts': 'Stella 的猫咪知识',
      'day': '天',
      'stats': '统计',
      'streak': '连续天数',
      'ads': '广告',
      'info': '信息',
      'solanaToken':
          'Stelluriini 是 Solana 网络上的社区代币。',
      'stellaCompany':
          '🐱 Stella 会陪伴你使用 Stelluriini！',
      'nextClaim': '下一次奖励',
      'claimed': '已领取',
      'dailyReward': '今日奖励',
      'sevenDayStreak':
          '🔥 已连续7天！',
      'sevenDayReward':
          '只要不中断，每天可以获得7 STL。',
      'dailyAd':
          '📺 每日奖励需要观看广告。',
      'logout': '退出登录',
      'languageChanged': '语言已更改',
      'adLoading':
          '广告正在加载，请稍候。',
      'adFailed':
          '无法显示广告。',
      'dailyLimitReached':
          '已达到每日广告上限5/5。',
      'waitMessage': '等待',
      'pointsAdded': '+3 STL! 🐱',
      'dailyAdded': '每日奖励',
      'next': '下一个',
      'resetTestData': '重置测试数据',
      'testDataReset': '测试数据已重置',
      'virtualPoints': '应用内虚拟积分',
    },
  };
}