import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_localizations.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

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
      home: AuthGate(
        languageCode: languageCode,
        onLanguageChanged: _changeLanguage,
      ),
    );
  }
}

// ============================================================
// FIREBASE AUTH GATE
// ============================================================

class AuthGate extends StatelessWidget {
  final String languageCode;
  final Future<void> Function(String) onLanguageChanged;

  const AuthGate({
    super.key,
    required this.languageCode,
    required this.onLanguageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasData) {
          return HomePage(
            languageCode: languageCode,
            onLanguageChanged: onLanguageChanged,
          );
        }

        return LoginPage(
          languageCode: languageCode,
        );
      },
    );
  }
}

// ============================================================
// LOGIN PAGE
// ============================================================

class LoginPage extends StatefulWidget {
  final String languageCode;

  const LoginPage({
    super.key,
    required this.languageCode,
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool loading = false;
  bool registerMode = false;
  bool hidePassword = true;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showMessage('Syötä sähköposti ja salasana.');
      return;
    }

    if (password.length < 6) {
      _showMessage('Salasanassa pitää olla vähintään 6 merkkiä.');
      return;
    }

    setState(() {
      loading = true;
    });

    try {
      if (registerMode) {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
      } else {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      }
    } on FirebaseAuthException catch (e) {
      _showMessage(_firebaseErrorMessage(e));
    } catch (_) {
      _showMessage('Tapahtui odottamaton virhe.');
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  String _firebaseErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Sähköpostiosoite ei ole kelvollinen.';

      case 'user-not-found':
        return 'Käyttäjää ei löytynyt.';

      case 'wrong-password':
      case 'invalid-credential':
        return 'Sähköposti tai salasana on väärä.';

      case 'email-already-in-use':
        return 'Tämä sähköpostiosoite on jo käytössä.';

      case 'weak-password':
        return 'Salasana on liian heikko.';

      case 'network-request-failed':
        return 'Tarkista internet-yhteytesi.';

      default:
        return 'Kirjautuminen epäonnistui.';
    }
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isRegister = registerMode;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF101720),
        title: const Text(
          'Stelluriini',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Card(
              color: const Color(0xFF161C26),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircleAvatar(
                      radius: 48,
                      backgroundColor: Color(0xFF12322F),
                      child: Text(
                        '🐱',
                        style: TextStyle(fontSize: 50),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'STELLURIINI',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4DE3C1),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isRegister
                          ? 'Luo uusi käyttäjätili'
                          : 'Kirjaudu sisään',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 30),

                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [
                        AutofillHints.email,
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Sähköposti',
                        prefixIcon: Icon(Icons.email),
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 16),

                    TextField(
                      controller: passwordController,
                      obscureText: hidePassword,
                      autofillHints: isRegister
                          ? const [AutofillHints.newPassword]
                          : const [AutofillHints.password],
                      decoration: InputDecoration(
                        labelText: 'Salasana',
                        prefixIcon: const Icon(Icons.lock),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            hidePassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              hidePassword = !hidePassword;
                            });
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: loading ? null : _submit,
                        icon: loading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(
                                isRegister
                                    ? Icons.person_add
                                    : Icons.login,
                              ),
                        label: Text(
                          isRegister
                              ? 'LUO KÄYTTÄJÄTILI'
                              : 'KIRJAUDU SISÄÄN',
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextButton(
                      onPressed: loading
                          ? null
                          : () {
                              setState(() {
                                registerMode = !registerMode;
                              });
                            },
                      child: Text(
                        isRegister
                            ? 'Onko sinulla jo tili? Kirjaudu sisään'
                            : 'Ei vielä tiliä? Luo käyttäjätili',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// HOME PAGE
// ============================================================

class HomePage extends StatefulWidget {
  final String languageCode;
  final Future<void> Function(String) onLanguageChanged;

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

  RewardedAd? rewardedAd;

  static const String rewardedAdUnitId =
      'ca-app-pub-3940256099942544/5224354917';

  final List<String> catFacts = [
    '🐱 Kissat nukkuvat jopa 12–16 tuntia päivässä.',
    '🐱 Kissalla on erittäin hyvä kuulo.',
    '🐱 Kissan viikset auttavat sitä arvioimaan tilaa.',
    '🐱 Kissat voivat kehrätä monista eri syistä.',
    '🐱 Kissan nenän kuvio on yksilöllinen.',
    '🐱 Kissat käyttävät häntäänsä tasapainon ylläpitämiseen.',
    '🐱 Stella on Stelluriinin inspiraation lähde!',
  ];

  int factIndex = 0;

  String get todayKey {
    final now = DateTime.now();

    return '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  String get _userPrefix {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'guest';
    return 'user_$uid';
  }

  String get _balanceKey => '${_userPrefix}_balance';
  String get _streakKey => '${_userPrefix}_streak';
  String get _lastClaimKey => '${_userPrefix}_lastClaimDate';
  String get _adDateKey => '${_userPrefix}_adDate';
  String get _adCountKey => '${_userPrefix}_adCount';

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

    final savedBalance = prefs.getDouble(_balanceKey) ?? 0.0;
    final savedStreak = prefs.getInt(_streakKey) ?? 0;
    final savedClaimDate = prefs.getString(_lastClaimKey) ?? '';
    final savedAdDate = prefs.getString(_adDateKey) ?? '';
    final savedAdCount = prefs.getInt(_adCountKey) ?? 0;

    int currentAdCount = savedAdCount;

    if (savedAdDate != todayKey) {
      currentAdCount = 0;

      await prefs.setString(_adDateKey, todayKey);
      await prefs.setInt(_adCountKey, 0);
    }

    if (!mounted) return;

    setState(() {
      balance = savedBalance;
      streak = savedStreak;
      lastClaimDate = savedClaimDate;
      adDate = todayKey;
      adCount = currentAdCount;
      loading = false;
    });

    _loadRewardedAd();
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setDouble(_balanceKey, balance);
    await prefs.setInt(_streakKey, streak);
    await prefs.setString(_lastClaimKey, lastClaimDate);
    await prefs.setString(_adDateKey, adDate);
    await prefs.setInt(_adCountKey, adCount);
  }

  Future<void> _loadRewardedAd() async {
    if (adLoading || rewardedAdReady) return;

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
          rewardedAd = ad;

          if (!mounted) {
            ad.dispose();
            return;
          }

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
            _loadRewardedAd,
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

    int newStreak;

    if (lastClaimDate == yesterdayKey) {
      newStreak = streak + 1;
    } else {
      newStreak = 1;
    }

    final double reward = newStreak >= 7 ? 7.0 : 1.0;

    setState(() {
      streak = newStreak;
      balance += reward;
      lastClaimDate = todayKey;
    });

    await _saveData();

    if (!mounted) return;

    _showMessage('+${reward.toStringAsFixed(0)} STL! 🐱');
  }

  Future<void> _watchAd() async {
    final t = AppLocalizations(widget.languageCode);

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
    });

    bool rewardEarned = false;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _loadRewardedAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();

        if (mounted) {
          _showMessage(t.get('adFailed'));
        }

        _loadRewardedAd();
      },
    );

    ad.show(
      onUserEarnedReward: (adWithoutView, reward) async {
        if (rewardEarned || !mounted) return;

        rewardEarned = true;

        setState(() {
          balance += 3.0;
          adCount++;
          adDate = todayKey;
        });

        await _saveData();

        if (mounted) {
          _showMessage('+3 STL! 🐱');
        }
      },
    );
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  Future<void> _resetTestData() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_balanceKey);
    await prefs.remove(_streakKey);
    await prefs.remove(_lastClaimKey);
    await prefs.remove(_adDateKey);
    await prefs.remove(_adCountKey);

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
      ),
    );
  }

  void _nextFact() {
    setState(() {
      factIndex = (factIndex + 1) % catFacts.length;
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

    final claimedToday = lastClaimDate == todayKey;
    final user = FirebaseAuth.instance.currentUser;

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
            tooltip: 'Kieli',
            onPressed: _showLanguageDialog,
            icon: const Icon(Icons.language),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                _signOut();
              }

              if (value == 'reset') {
                _resetTestData();
              }
            },
            itemBuilder: (context) {
              return const [
                PopupMenuItem(
                  value: 'reset',
                  child: Row(
                    children: [
                      Icon(Icons.refresh),
                      SizedBox(width: 10),
                      Text('Nollaa testidata'),
                    ],
                  ),
                ),
                PopupMenuDivider(),
                PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout),
                      SizedBox(width: 10),
                      Text('Kirjaudu ulos'),
                    ],
                  ),
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
            _buildHeader(t, user),

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

  Widget _buildHeader(AppLocalizations t, User? user) {
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
                    user?.email ?? languageName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    languageName,
                    style: const TextStyle(
                      color: Color(0xFF4DE3C1),
                      fontSize: 12,
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
            const SizedBox(height: 8),
            const Text(
              'Virtual in-app points',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 12,
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
            const SizedBox(height: 12),
            Text(
              t.get('dailyAd'),
              style: const TextStyle(
                color: Colors.white70,
              ),
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
    final limitReached = adCount >= 5;

    String buttonText;

    if (limitReached) {
      buttonText = '${t.get('dailyLimit')} 5/5';
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
                onPressed: limitReached ? null : _watchAd,
                icon: rewardedAdReady
                    ? const Icon(Icons.play_arrow)
                    : const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      ),
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
              catFacts[factIndex],
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
              label: const Text('Next'),
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
                    children: AppLocalizations.supportedLanguages.entries
                        .map(
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

                            if (mounted) {
                              final newT =
                                  AppLocalizations(entry.key);

                              _showMessage(
                                newT.get('languageChanged'),
                              );
                            }
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