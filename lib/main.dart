import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await MobileAds.instance.initialize();

  runApp(const StelluriiniApp());
}

class StelluriiniApp extends StatefulWidget {
  const StelluriiniApp({super.key});

  @override
  State<StelluriiniApp> createState() => _StelluriiniAppState();
}

class _StelluriiniAppState extends State<StelluriiniApp> {
  String languageCode = 'fi';
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      languageCode = prefs.getString('languageCode') ?? 'fi';
      loading = false;
    });
  }

  Future<void> _changeLanguage(String newLanguage) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('languageCode', newLanguage);

    if (!mounted) return;

    setState(() {
      languageCode = newLanguage;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark(useMaterial3: true),
        home: const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Stelluriini',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0B0F16),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF22C7B8),
          brightness: Brightness.dark,
        ),
      ),
      home: HomePage(
        languageCode: languageCode,
        onLanguageChanged: _changeLanguage,
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  final String languageCode;
  final Future<void> Function(String languageCode) onLanguageChanged;

  const HomePage({
    super.key,
    required this.languageCode,
    required this.onLanguageChanged,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  double balance = 0.0;

  int streak = 0;
  int adCount = 0;

  String lastClaimDate = '';
  String adDate = '';

  bool loading = true;
  bool rewardedAdReady = false;
  bool adLoading = false;
  bool adShowing = false;

  RewardedAd? rewardedAd;

  static const String rewardedAdUnitId =
      'ca-app-pub-3940256099942544/5224354917';

  int factIndex = 0;

  String get todayKey {
    final now = DateTime.now();

    return '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    rewardedAd?.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();

    final savedBalance = prefs.getDouble('balance') ?? 0.0;
    final savedStreak = prefs.getInt('streak') ?? 0;
    final savedClaimDate = prefs.getString('lastClaimDate') ?? '';
    final savedAdDate = prefs.getString('adDate') ?? '';
    final savedAdCount = prefs.getInt('adCount') ?? 0;

    int currentAdCount = savedAdCount;
    String currentAdDate = savedAdDate;

    if (currentAdDate != todayKey) {
      currentAdCount = 0;
      currentAdDate = todayKey;

      await prefs.setString('adDate', currentAdDate);
      await prefs.setInt('adCount', currentAdCount);
    }

    if (!mounted) return;

    setState(() {
      balance = savedBalance;
      streak = savedStreak;
      lastClaimDate = savedClaimDate;
      adDate = currentAdDate;
      adCount = currentAdCount;
      loading = false;
    });

    _loadRewardedAd();
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setDouble('balance', balance);
    await prefs.setInt('streak', streak);
    await prefs.setString('lastClaimDate', lastClaimDate);
    await prefs.setString('adDate', adDate);
    await prefs.setInt('adCount', adCount);
  }

  Future<void> _loadRewardedAd() async {
    if (adLoading || rewardedAdReady || adShowing) {
      return;
    }

    if (mounted) {
      setState(() {
        adLoading = true;
      });
    }

    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }

          rewardedAd = ad;

          setState(() {
            rewardedAdReady = true;
            adLoading = false;
          });
        },
        onAdFailedToLoad: (error) {
          if (!mounted) return;

          setState(() {
            rewardedAd = null;
            rewardedAdReady = false;
            adLoading = false;
          });

          Future.delayed(
            const Duration(seconds: 5),
            () {
              if (mounted && !adShowing) {
                _loadRewardedAd();
              }
            },
          );
        },
      ),
    );
  }

  Future<void> _claimDailyReward() async {
    final t = AppLocalizations(widget.languageCode);

    if (lastClaimDate == todayKey) {
      _showMessage(t.get('claimed'));
      return;
    }

    final yesterday = DateTime.now().subtract(
      const Duration(days: 1),
    );

    final yesterdayKey =
        '${yesterday.year.toString().padLeft(4, '0')}-'
        '${yesterday.month.toString().padLeft(2, '0')}-'
        '${yesterday.day.toString().padLeft(2, '0')}';

    if (lastClaimDate == yesterdayKey) {
      streak++;
    } else {
      streak = 1;
    }

    final double reward = streak >= 7 ? 7.0 : 1.0;

    setState(() {
      balance += reward;
      lastClaimDate = todayKey;
    });

    await _saveData();

    if (!mounted) return;

    if (streak == 7) {
      _showMessage(
        '${t.get('sevenDayStreak')}\n${t.get('sevenDayReward')}',
      );
    } else {
      _showMessage('+${reward.toStringAsFixed(0)} STL! 🐱');
    }
  }

  Future<void> _watchAd() async {
    final t = AppLocalizations(widget.languageCode);

    if (adShowing) {
      return;
    }

    if (adDate != todayKey) {
      setState(() {
        adDate = todayKey;
        adCount = 0;
      });

      await _saveData();
    }

    if (adCount >= 5) {
      _showMessage(t.get('dailyLimitReached'));
      return;
    }

    if (!rewardedAdReady || rewardedAd == null) {
      _showMessage(t.get('adLoading'));
      _loadRewardedAd();
      return;
    }

    final ad = rewardedAd!;

    setState(() {
      rewardedAd = null;
      rewardedAdReady = false;
      adShowing = true;
    });

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {},

      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();

        if (!mounted) return;

        setState(() {
          adShowing = false;
        });

        _loadRewardedAd();
      },

      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();

        if (!mounted) return;

        setState(() {
          adShowing = false;
        });

        _showMessage(t.get('adFailed'));

        _loadRewardedAd();
      },
    );

    try {
      await ad.show(
        onUserEarnedReward: (adWithoutView, reward) async {
          if (!mounted) return;

          if (adCount >= 5) return;

          setState(() {
            balance += 3.0;
            adCount++;
            adDate = todayKey;
          });

          await _saveData();

          if (!mounted) return;

          _showMessage(t.get('pointsAdded'));
        },
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        adShowing = false;
      });

      _showMessage(t.get('adFailed'));

      _loadRewardedAd();
    }
  }

  Future<void> _resetTestData() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('balance');
    await prefs.remove('streak');
    await prefs.remove('lastClaimDate');
    await prefs.remove('adCount');
    await prefs.remove('adDate');

    if (!mounted) return;

    setState(() {
      balance = 0.0;
      streak = 0;
      adCount = 0;
      lastClaimDate = '';
      adDate = todayKey;
    });

    _showMessage('Testidata nollattu');
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          textAlign: TextAlign.center,
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  List<String> _getCatFacts(AppLocalizations t) {
    switch (widget.languageCode) {
      case 'en':
        return [
          '🐱 Cats can sleep 12–16 hours a day.',
          '🐱 Cats have excellent hearing.',
          '🐱 Whiskers help cats measure spaces.',
          '🐱 Cats can purr for many different reasons.',
          '🐱 Every cat has a unique nose pattern.',
          '🐱 Cats use their tails to maintain balance.',
          '🐱 Stella is the inspiration behind Stelluriini!',
        ];

      case 'sv':
        return [
          '🐱 Katter kan sova 12–16 timmar om dagen.',
          '🐱 Katter har mycket bra hörsel.',
          '🐱 Morrhår hjälper katter att bedöma utrymmen.',
          '🐱 Katter kan spinna av många olika orsaker.',
          '🐱 Varje katt har ett unikt nosmönster.',
          '🐱 Katter använder svansen för balansen.',
          '🐱 Stella är inspirationen bakom Stelluriini!',
        ];

      case 'de':
        return [
          '🐱 Katzen können 12–16 Stunden am Tag schlafen.',
          '🐱 Katzen haben ein ausgezeichnetes Gehör.',
          '🐱 Schnurrhaare helfen Katzen, Räume einzuschätzen.',
          '🐱 Katzen können aus vielen Gründen schnurren.',
          '🐱 Jede Katze hat ein einzigartiges Nasenmuster.',
          '🐱 Katzen benutzen ihren Schwanz für das Gleichgewicht.',
          '🐱 Stella ist die Inspiration hinter Stelluriini!',
        ];

      case 'es':
        return [
          '🐱 Los gatos pueden dormir entre 12 y 16 horas al día.',
          '🐱 Los gatos tienen un oído excelente.',
          '🐱 Los bigotes ayudan a medir los espacios.',
          '🐱 Los gatos pueden ronronear por muchas razones.',
          '🐱 Cada gato tiene un patrón de nariz único.',
          '🐱 Los gatos usan la cola para mantener el equilibrio.',
          '🐱 ¡Stella es la inspiración de Stelluriini!',
        ];

      case 'fr':
        return [
          '🐱 Les chats peuvent dormir 12 à 16 heures par jour.',
          '🐱 Les chats ont une excellente audition.',
          '🐱 Les moustaches aident les chats à mesurer les espaces.',
          '🐱 Les chats peuvent ronronner pour différentes raisons.',
          '🐱 Chaque chat possède un motif de nez unique.',
          '🐱 Les chats utilisent leur queue pour garder l’équilibre.',
          '🐱 Stella est l’inspiration derrière Stelluriini !',
        ];

      case 'it':
        return [
          '🐱 I gatti possono dormire 12–16 ore al giorno.',
          '🐱 I gatti hanno un udito eccellente.',
          '🐱 I baffi aiutano i gatti a valutare gli spazi.',
          '🐱 I gatti possono fare le fusa per molte ragioni.',
          '🐱 Ogni gatto ha un disegno del naso unico.',
          '🐱 I gatti usano la coda per mantenere l’equilibrio.',
          '🐱 Stella è l’ispirazione dietro Stelluriini!',
        ];

      case 'pt':
        return [
          '🐱 Os gatos podem dormir 12–16 horas por dia.',
          '🐱 Os gatos têm uma audição excelente.',
          '🐱 Os bigodes ajudam os gatos a avaliar espaços.',
          '🐱 Os gatos podem ronronar por muitos motivos.',
          '🐱 Cada gato tem um padrão de nariz único.',
          '🐱 Os gatos usam a cauda para manter o equilíbrio.',
          '🐱 Stella é a inspiração por trás do Stelluriini!',
        ];

      case 'ja':
        return [
          '🐱 猫は1日に12〜16時間眠ることがあります。',
          '🐱 猫はとても優れた聴覚を持っています。',
          '🐱 猫のひげは空間を判断するのに役立ちます。',
          '🐱 猫はさまざまな理由でゴロゴロ鳴きます。',
          '🐱 猫の鼻の模様はそれぞれ異なります。',
          '🐱 猫は尻尾を使ってバランスを取ります。',
          '🐱 StellaはStelluriiniのインスピレーションです！',
        ];

      case 'zh':
        return [
          '🐱 猫每天可以睡12到16个小时。',
          '🐱 猫拥有非常出色的听力。',
          '🐱 猫的胡须可以帮助判断空间。',
          '🐱 猫会因为不同原因发出呼噜声。',
          '🐱 每只猫的鼻子纹路都是独特的。',
          '🐱 猫使用尾巴保持平衡。',
          '🐱 Stella 是 Stelluriini 的灵感来源！',
        ];

      default:
        return [
          '🐱 Kissat nukkuvat jopa 12–16 tuntia päivässä.',
          '🐱 Kissalla on erittäin hyvä kuulo.',
          '🐱 Kissan viikset auttavat sitä arvioimaan tilaa.',
          '🐱 Kissat voivat kehrätä monista eri syistä.',
          '🐱 Kissan nenän kuvio on yksilöllinen.',
          '🐱 Kissat käyttävät häntäänsä tasapainon ylläpitämiseen.',
          '🐱 Stella on Stelluriinin inspiraation lähde!',
        ];
    }
  }

  String _nextButtonText() {
    switch (widget.languageCode) {
      case 'en':
        return 'Next';
      case 'sv':
        return 'Nästa';
      case 'de':
        return 'Weiter';
      case 'es':
        return 'Siguiente';
      case 'fr':
        return 'Suivant';
      case 'it':
        return 'Avanti';
      case 'pt':
        return 'Próximo';
      case 'ja':
        return '次へ';
      case 'zh':
        return '下一个';
      default:
        return 'Seuraava';
    }
  }

  void _nextFact() {
    final facts = _getCatFacts(AppLocalizations(widget.languageCode));

    setState(() {
      factIndex++;

      if (factIndex >= facts.length) {
        factIndex = 0;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations(widget.languageCode);

    if (loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final bool claimedToday = lastClaimDate == todayKey;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF101720),
        title: Text(
          t.get('appTitle'),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: t.get('language'),
            onPressed: _showLanguageDialog,
            icon: const Icon(Icons.language),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'reset') {
                _resetTestData();
              }
            },
            itemBuilder: (context) {
              return [
                const PopupMenuItem(
                  value: 'reset',
                  child: Text('Nollaa testidata'),
                ),
              ];
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildHeader(t),
            const SizedBox(height: 20),
            _buildBalanceCard(t),
            const SizedBox(height: 16),
            _buildDailyCard(t, claimedToday),
            const SizedBox(height: 16),
            _buildAdCard(t),
            const SizedBox(height: 16),
            _buildStatsCard(t),
            const SizedBox(height: 16),
            _buildStellaCard(t),
            const SizedBox(height: 16),
            _buildInfoCard(t),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations t) {
    final languageName =
        AppLocalizations.supportedLanguages[widget.languageCode] ??
            '🇫🇮 Suomi';

    return Card(
      color: const Color(0xFF101720),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 30,
              backgroundColor: Color(0xFF1D3D42),
              child: Text(
                '🐱',
                style: TextStyle(fontSize: 30),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.get('appTitle'),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    languageName,
                    style: const TextStyle(
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: _showLanguageDialog,
              icon: const Icon(Icons.translate),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard(AppLocalizations t) {
    return Card(
      color: const Color(0xFF12322F),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              t.get('yourBalance'),
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${balance.toStringAsFixed(2)} STL',
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4DE3C1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyCard(
    AppLocalizations t,
    bool claimedToday,
  ) {
    return Card(
      color: const Color(0xFF161C26),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(
                  Icons.card_giftcard,
                  color: Color(0xFFFFD166),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    t.get('dailyClaim'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: claimedToday ? null : _claimDailyReward,
                icon: Icon(
                  claimedToday
                      ? Icons.check_circle
                      : Icons.card_giftcard,
                ),
                label: Text(
                  claimedToday
                      ? t.get('claimed')
                      : t.get('dailyReward'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdCard(AppLocalizations t) {
    final bool limitReached = adCount >= 5;

    String buttonText;

    if (limitReached) {
      buttonText = '${t.get('dailyLimit')} 5/5';
    } else if (adShowing) {
      buttonText = t.get('wait');
    } else if (rewardedAdReady) {
      buttonText = '${t.get('watchEarn')} +3 STL';
    } else {
      buttonText = t.get('loadingAd');
    }

    return Card(
      color: const Color(0xFF161C26),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(
                  Icons.play_circle_fill,
                  color: Color(0xFF54A8FF),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    t.get('watchEarn'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  '$adCount/5',
                  style: const TextStyle(
                    color: Color(0xFF54A8FF),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              t.get('watchAdReward'),
              style: const TextStyle(
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: limitReached || adShowing ? null : _watchAd,
                icon: adLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.play_arrow),
                label: Text(buttonText),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard(AppLocalizations t) {
    return Card(
      color: const Color(0xFF161C26),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Text(
              t.get('stats'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _statItem(
                    Icons.local_fire_department,
                    t.get('streak'),
                    '$streak',
                    const Color(0xFFFF8C42),
                  ),
                ),
                Expanded(
                  child: _statItem(
                    Icons.play_circle_outline,
                    t.get('ads'),
                    '$adCount/5',
                    const Color(0xFF54A8FF),
                  ),
                ),
                Expanded(
                  child: _statItem(
                    Icons.today,
                    t.get('today'),
                    lastClaimDate == todayKey ? '✓' : '—',
                    const Color(0xFF4DE3C1),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statItem(
    IconData icon,
    String title,
    String value,
    Color color,
  ) {
    return Column(
      children: [
        Icon(
          icon,
          color: color,
          size: 28,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildStellaCard(AppLocalizations t) {
    final facts = _getCatFacts(t);

    return Card(
      color: const Color(0xFF1B2533),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Text(
              t.get('stella'),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              t.get('stellaFacts'),
              style: const TextStyle(
                color: Color(0xFF4DE3C1),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              facts[factIndex % facts.length],
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _nextFact,
              icon: const Icon(Icons.refresh),
              label: Text(_nextButtonText()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(AppLocalizations t) {
    return Card(
      color: const Color(0xFF161C26),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: Color(0xFF4DE3C1),
                ),
                const SizedBox(width: 10),
                Text(
                  t.get('info'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              t.get('solanaToken'),
              style: const TextStyle(
                color: Colors.white70,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              t.get('stellaCompany'),
              style: const TextStyle(
                color: Colors.white70,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguageDialog() {
    final t = AppLocalizations(widget.languageCode);

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161C26),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  t.get('selectLanguage'),
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children:
                        AppLocalizations.supportedLanguages.entries.map(
                      (entry) {
                        final selected =
                            entry.key == widget.languageCode;

                        return ListTile(
                          leading: Icon(
                            selected
                                ? Icons.check_circle
                                : Icons.language,
                            color: selected
                                ? const Color(0xFF4DE3C1)
                                : Colors.white54,
                          ),
                          title: Text(
                            entry.value,
                            style: TextStyle(
                              fontWeight: selected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          onTap: () async {
                            Navigator.pop(context);

                            await widget.onLanguageChanged(entry.key);

                            if (!mounted) return;

                            final newT =
                                AppLocalizations(entry.key);

                            _showMessage(
                              newT.get('languageChanged'),
                            );
                          },
                        );
                      },
                    ).toList(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}