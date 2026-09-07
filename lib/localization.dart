import 'package:flutter/material.dart';

class AppLocalizations {
  final String languageCode;

  const AppLocalizations(this.languageCode);

  /// Supported languages used by the language selectors.
  ///
  /// This must be a Map because the UI uses:
  /// AppLocalizations.supportedLanguages.entries
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

  static const Map<String, Map<String, String>> _translations = {
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
      'alreadyClaimed':
          'Olet jo kerännyt tämän päivän palkinnon.',
      'watchAd': 'KATSO MAINOS',
      'watchAndEarn': 'KATSO & ANSAITSE',
      'loadingAd': 'LADATAAN MAINOSTA...',
      'adReward': '+{amount} HR',
      'powerBoost': 'Stella Power Boost',
      'powerBoostOffer':
          'Katso mainos ja aktivoi +{amount} HR Stella Power Boost 4 tunniksi.',
      'powerBoostActive': 'Power Boost aktiivinen',
      'powerBoostActiveTitle':
          'Stella Power Boost on aktiivinen!',
      'powerBoostActiveMessage':
          '+{amount} HR on käytössä louhintasiirron aikana.',
      'powerBoostAlreadyActive':
          'Power Boost on jo aktiivinen.',
      'nextPowerBoostMessage':
          'Seuraava Power Boost on saatavilla, kun nykyinen boost päättyy.',
      'nextAdAfterBoost':
          'Seuraava mainos on saatavilla boostin päätyttyä.',
      'maxBoostsInfo':
          'Voit aktivoida enintään {count} Power Boostia päivässä.',
      'serverConnectionFailed':
          'Palvelinyhteys epäonnistui.',
      'refresh': 'Päivitä',
      'profile': 'Profiili',
      'comingSoon': 'Tulossa pian',
      'information': 'Tietoa',
      'catFact': 'Stellan kissafakta',
      'stellaPower': 'Stella Power',
      'transactions': 'Tapahtumat',
      'noTransactions': 'Ei tapahtumia vielä.',
      'points': 'pistettä',
      'pointsAdded': 'Pisteitä lisätty',
      'resetAccount': 'Nollaa testitili',
      'resetConfirm':
          'Haluatko varmasti nollata testitilin?',
      'cancel': 'Peruuta',
      'reset': 'Nollaa',
      'error': 'Virhe',
      'success': 'Onnistui',
      'close': 'Sulje',
    },

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
      'balance': 'Balance',
      'mining': 'Mining',
      'miningRate': 'Mining Rate',
      'hashRate': 'Hash Rate',
      'effectiveHashRate': 'Effective Hash Rate',
      'effectiveHashRateLabel': 'Effective Hash Rate',
      'dailyHashRateLabel': 'Daily Hash Rate',
      'dailyHashRateDay': 'Day {day}',
      'dailyHashRateMaximum': 'Maximum: {rate} HR',
      'dailyHashRateSuccess':
          'Day {day} Hash Rate: {rate} HR',
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
      'serverConnectionFailed':
          'Server connection failed.',
      'refresh': 'Refresh',
      'profile': 'Profile',
      'comingSoon': 'Coming Soon',
      'information': 'Information',
      'catFact': 'Stella Cat Fact',
      'stellaPower': 'Stella Power',
      'transactions': 'Transactions',
      'noTransactions': 'No transactions yet.',
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
    },

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
      'startMining': 'MINING STARTEN',
      'claimMining': 'STL EINSAMMELN',
      'miningActive': 'Mining aktiv',
      'miningComplete':
          'Mining-Zyklus abgeschlossen',
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
      'serverConnectionFailed':
          'Serververbindung fehlgeschlagen.',
      'refresh': 'Aktualisieren',
      'profile': 'Profil',
      'comingSoon': 'Demnächst',
      'information': 'Information',
      'catFact': 'Stellas Katzenfakt',
      'stellaPower': 'Stella Power',
      'transactions': 'Transaktionen',
      'noTransactions':
          'Noch keine Transaktionen.',
      'points': 'Punkte',
      'pointsAdded': 'Punkte hinzugefügt',
      'resetAccount':
          'Testkonto zurücksetzen',
      'resetConfirm':
          'Möchtest du das Testkonto wirklich zurücksetzen?',
      'cancel': 'Abbrechen',
      'reset': 'Zurücksetzen',
      'error': 'Fehler',
      'success': 'Erfolgreich',
      'close': 'Schließen',
    },

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
      'balance': 'Saldo',
      'mining': 'Minería',
      'miningRate': 'Tasa de minería',
      'hashRate': 'Hash Rate',
      'effectiveHashRate': 'Hash Rate efectivo',
      'effectiveHashRateLabel':
          'Hash Rate efectivo',
      'dailyHashRateLabel': 'Hash Rate diario',
      'dailyHashRateDay': 'Día {day}',
      'dailyHashRateMaximum': 'Máximo: {rate} HR',
      'dailyHashRateSuccess':
          'Hash Rate del día {day}: {rate} HR',
      'startMining': 'INICIAR MINERÍA',
      'claimMining': 'RECLAMAR STL',
      'miningActive': 'Minería activa',
      'miningComplete':
          'Ciclo de minería completado',
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
      'adReward': '+{amount} HR',
      'powerBoost': 'Stella Power Boost',
      'powerBoostOffer':
          'Mira un anuncio para activar +{amount} HR de Stella Power Boost durante 4 horas.',
      'powerBoostActive':
          'Power Boost activo',
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
      'serverConnectionFailed':
          'Error de conexión con el servidor.',
      'refresh': 'Actualizar',
      'profile': 'Perfil',
      'comingSoon': 'Próximamente',
      'information': 'Información',
      'catFact': 'Dato gatuno de Stella',
      'stellaPower': 'Stella Power',
      'transactions': 'Transacciones',
      'noTransactions':
          'Aún no hay transacciones.',
      'points': 'puntos',
      'pointsAdded': 'Puntos añadidos',
      'resetAccount':
          'Restablecer cuenta de prueba',
      'resetConfirm':
          '¿Seguro que quieres restablecer la cuenta de prueba?',
      'cancel': 'Cancelar',
      'reset': 'Restablecer',
      'error': 'Error',
      'success': 'Éxito',
      'close': 'Cerrar',
    },

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
      'balance': 'Solde',
      'mining': 'Minage',
      'miningRate': 'Taux de minage',
      'hashRate': 'Hash Rate',
      'effectiveHashRate':
          'Hash Rate effectif',
      'effectiveHashRateLabel':
          'Hash Rate effectif',
      'dailyHashRateLabel':
          'Hash Rate quotidien',
      'dailyHashRateDay': 'Jour {day}',
      'dailyHashRateMaximum':
          'Maximum : {rate} HR',
      'dailyHashRateSuccess':
          'Hash Rate du jour {day} : {rate} HR',
      'startMining': 'DÉMARRER LE MINAGE',
      'claimMining': 'RÉCLAMER STL',
      'miningActive': 'Minage actif',
      'miningComplete':
          'Cycle de minage terminé',
      'timeRemaining': 'Temps restant',
      'remaining':
          'Temps restant : {time}',
      'streak': 'Série',
      'days': 'jours',
      'dailyBonus': 'Bonus quotidien',
      'dailyClaim':
          'Réclamer le bonus quotidien',
      'dailyReward':
          'Récompense quotidienne',
      'claimedToday':
          'Réclamé aujourd’hui',
      'alreadyClaimed':
          'Vous avez déjà réclamé la récompense du jour.',
      'watchAd': 'REGARDER LA PUB',
      'watchAndEarn':
          'REGARDER & GAGNER',
      'loadingAd':
          'CHARGEMENT DE LA PUB...',
      'adReward': '+{amount} HR',
      'powerBoost':
          'Stella Power Boost',
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
      'serverConnectionFailed':
          'Échec de la connexion au serveur.',
      'refresh': 'Actualiser',
      'profile': 'Profil',
      'comingSoon':
          'Bientôt disponible',
      'information': 'Informations',
      'catFact':
          'Fait sur les chats de Stella',
      'stellaPower': 'Stella Power',
      'transactions': 'Transactions',
      'noTransactions':
          'Aucune transaction pour le moment.',
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
    },

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
      'balance': '余额',
      'mining': '挖矿',
      'miningRate': '挖矿速率',
      'hashRate': '哈希率',
      'effectiveHashRate':
          '有效哈希率',
      'effectiveHashRateLabel':
          '有效哈希率',
      'dailyHashRateLabel':
          '每日哈希率',
      'dailyHashRateDay':
          '第 {day} 天',
      'dailyHashRateMaximum':
          '最高：{rate} HR',
      'dailyHashRateSuccess':
          '第 {day} 天哈希率：{rate} HR',
      'startMining': '开始挖矿',
      'claimMining': '领取 STL',
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
      'days': '天',
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
      'serverConnectionFailed':
          '服务器连接失败。',
      'refresh': '刷新',
      'profile': '个人资料',
      'comingSoon':
          '即将推出',
      'information':
          '信息',
      'catFact':
          'Stella 猫咪知识',
      'stellaPower':
          'Stella Power',
      'transactions':
          '交易',
      'noTransactions':
          '暂无交易。',
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
    },

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
      'balance': 'Số dư',
      'mining': 'Khai thác',
      'miningRate':
          'Tốc độ khai thác',
      'hashRate': 'Hash Rate',
      'effectiveHashRate':
          'Hash Rate hiệu dụng',
      'effectiveHashRateLabel':
          'Hash Rate hiệu dụng',
      'dailyHashRateLabel':
          'Hash Rate hàng ngày',
      'dailyHashRateDay':
          'Ngày {day}',
      'dailyHashRateMaximum':
          'Tối đa: {rate} HR',
      'dailyHashRateSuccess':
          'Hash Rate ngày {day}: {rate} HR',
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
      'days': 'ngày',
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
      'stellaPower':
          'Stella Power',
      'transactions':
          'Giao dịch',
      'noTransactions':
          'Chưa có giao dịch.',
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
    },

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
      'balance': '残高',
      'mining': 'マイニング',
      'miningRate':
          'マイニング速度',
      'hashRate':
          'ハッシュレート',
      'effectiveHashRate':
          '実効ハッシュレート',
      'effectiveHashRateLabel':
          '実効ハッシュレート',
      'dailyHashRateLabel':
          'デイリーハッシュレート',
      'dailyHashRateDay':
          '{day}日目',
      'dailyHashRateMaximum':
          '最大：{rate} HR',
      'dailyHashRateSuccess':
          '{day}日目のハッシュレート：{rate} HR',
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
      'stellaPower':
          'Stella Power',
      'transactions':
          '取引',
      'noTransactions':
          'まだ取引はありません。',
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
    },
  };

  /// Normal translation lookup.
  String get(String key) {
    return _translations[languageCode]?[key] ??
        _translations['en']?[key] ??
        key;
  }

  /// Translation lookup with replacement parameters.
  ///
  /// Example:
  /// getWithParams(
  ///   'remaining',
  ///   {'time': '03:25:10'},
  /// )
  String getWithParams(
    String key,
    Map<String, dynamic> params,
  ) {
    String value = get(key);

    params.forEach((name, replacement) {
      value = value.replaceAll(
        '{$name}',
        replacement.toString(),
      );
    });

    return value;
  }

  /// Alias used by some existing code.
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

  static AppLocalizations of(BuildContext context) {
    final locale = Localizations.localeOf(context);

    final languageCode =
        supportedLanguages.containsKey(locale.languageCode)
            ? locale.languageCode
            : 'en';

    return AppLocalizations(languageCode);
  }
}