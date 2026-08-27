import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

const Color backgroundColor = Color(0xFF0B1112);
const Color cardColor = Color(0xFF151B1C);
const Color accentColor = Color(0xFF35D0A0);

// Google TEST Rewarded Ad.
// Vaihda omaan tuotanto-ID:hen ennen julkaisua.
const String rewardedAdUnitId =
    'ca-app-pub-3940256099942544/5224354917';

const int maxAdsPerDay = 5;
const int adReward = 3;
const Duration adCooldown = Duration(hours: 1);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();
  await MobileAds.instance.initialize();

  runApp(const StelluriiniApp());
}

// ==========================================================
// APP
// ==========================================================

class StelluriiniApp extends StatefulWidget {
  const StelluriiniApp({super.key});

  @override
  State<StelluriiniApp> createState() => _StelluriiniAppState();
}

class _StelluriiniAppState extends State<StelluriiniApp> {
  String languageCode = 'fi';
  bool loaded = false;

  @override
  void initState() {
    super.initState();
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      languageCode = prefs.getString('language') ?? 'fi';
      loaded = true;
    });
  }

  Future<void> changeLanguage(String language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', language);

    if (!mounted) return;

    setState(() => languageCode = language);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Stelluriini',
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        scaffoldBackgroundColor: backgroundColor,
        colorScheme: ColorScheme.fromSeed(
          seedColor: accentColor,
          brightness: Brightness.dark,
        ),
        cardTheme: const CardThemeData(
          color: cardColor,
          elevation: 2,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: backgroundColor,
          foregroundColor: Colors.white,
          centerTitle: true,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: accentColor,
            foregroundColor: Colors.black,
          ),
        ),
      ),
      home: loaded
          ? AuthGate(
              languageCode: languageCode,
              changeLanguage: changeLanguage,
            )
          : const LoadingPage(),
    );
  }
}

// ==========================================================
// AUTH GATE
// ==========================================================

class AuthGate extends StatelessWidget {
  final String languageCode;
  final Future<void> Function(String) changeLanguage;

  const AuthGate({
    super.key,
    required this.languageCode,
    required this.changeLanguage,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingPage();
        }

        if (snapshot.hasData) {
          return HomePage(
            languageCode: languageCode,
            changeLanguage: changeLanguage,
          );
        }

        return LoginPage(
          languageCode: languageCode,
          changeLanguage: changeLanguage,
        );
      },
    );
  }
}

// ==========================================================
// LOADING
// ==========================================================

class LoadingPage extends StatelessWidget {
  const LoadingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(
          color: accentColor,
        ),
      ),
    );
  }
}

// ==========================================================
// LOGIN
// ==========================================================

class LoginPage extends StatefulWidget {
  final String languageCode;
  final Future<void> Function(String) changeLanguage;

  const LoginPage({
    super.key,
    required this.languageCode,
    required this.changeLanguage,
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool loading = false;
  bool showPassword = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void _message(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _login() async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _message('Anna sähköposti ja salasana.');
      return;
    }

    setState(() => loading = true);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      _message(_firebaseError(e.code));
    } catch (_) {
      _message('Kirjautuminen epäonnistui.');
    }

    if (mounted) {
      setState(() => loading = false);
    }
  }

  String _firebaseError(String code) {
    switch (code) {
      case 'invalid-email':
        return 'Sähköpostiosoite ei ole kelvollinen.';
      case 'user-not-found':
        return 'Käyttäjää ei löytynyt.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Väärä sähköposti tai salasana.';
      case 'too-many-requests':
        return 'Liian monta yritystä. Odota hetki.';
      case 'network-request-failed':
        return 'Internet-yhteyttä ei löytynyt.';
      default:
        return 'Virhe: $code';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CatAvatar(size: 110),
                    const SizedBox(height: 20),
                    const Text(
                      'STELLURIINI',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('Kirjaudu Stelluriiniin 🐱'),
                    const SizedBox(height: 28),

                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Sähköposti',
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 16),

                    TextField(
                      controller: passwordController,
                      obscureText: !showPassword,
                      onSubmitted: (_) => _login(),
                      decoration: InputDecoration(
                        labelText: 'Salasana',
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            showPassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(
                              () => showPassword = !showPassword,
                            );
                          },
                        ),
                      ),
                    ),

                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: loading
                            ? null
                            : () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const ForgotPasswordPage(),
                                  ),
                                );
                              },
                        child: const Text('Unohditko salasanan?'),
                      ),
                    ),

                    const SizedBox(height: 12),

                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed: loading ? null : _login,
                        icon: loading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.black,
                                ),
                              )
                            : const Icon(Icons.login),
                        label: Text(
                          loading
                              ? 'KIRJAUDUTAAN...'
                              : 'KIRJAUDU SISÄÄN',
                        ),
                      ),
                    ),

                    TextButton(
                      onPressed: loading
                          ? null
                          : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const RegisterPage(),
                                ),
                              );
                            },
                      child: const Text(
                        'Ei vielä tiliä? Luo uusi tili',
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

// ==========================================================
// REGISTER
// ==========================================================

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();

  bool loading = false;
  bool showPassword = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  void _message(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _register() async {
    final email = emailController.text.trim();
    final password = passwordController.text;
    final confirm = confirmController.text;

    if (email.isEmpty || password.isEmpty || confirm.isEmpty) {
      _message('Täytä kaikki kentät.');
      return;
    }

    if (password.length < 6) {
      _message('Salasanassa pitää olla vähintään 6 merkkiä.');
      return;
    }

    if (password != confirm) {
      _message('Salasanat eivät ole samat.');
      return;
    }

    setState(() => loading = true);

    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (mounted) {
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      _message('Virhe: ${e.code}');
    } catch (_) {
      _message('Tilin luominen epäonnistui.');
    }

    if (mounted) {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('LUO TILI')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Icon(
                    Icons.person_add,
                    size: 70,
                    color: accentColor,
                  ),
                  const SizedBox(height: 20),

                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Sähköposti',
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 16),

                  TextField(
                    controller: passwordController,
                    obscureText: !showPassword,
                    decoration: InputDecoration(
                      labelText: 'Salasana',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          showPassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(
                            () => showPassword = !showPassword,
                          );
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  TextField(
                    controller: confirmController,
                    obscureText: !showPassword,
                    decoration: const InputDecoration(
                      labelText: 'Vahvista salasana',
                      prefixIcon: Icon(Icons.lock_outline),
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: loading ? null : _register,
                      icon: const Icon(Icons.person_add),
                      label: Text(
                        loading ? 'LUODAAN...' : 'LUO TILI',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================================
// FORGOT PASSWORD
// ==========================================================

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() =>
      _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final emailController = TextEditingController();
  bool loading = false;

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  void _message(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _reset() async {
    final email = emailController.text.trim();

    if (email.isEmpty) {
      _message('Anna sähköpostiosoitteesi.');
      return;
    }

    setState(() => loading = true);

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: email,
      );

      _message('Palautuslinkki lähetettiin sähköpostiin.');
    } on FirebaseAuthException catch (e) {
      _message('Virhe: ${e.code}');
    } catch (_) {
      _message('Palautuslinkin lähetys epäonnistui.');
    }

    if (mounted) {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PALAUTA SALASANA')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 30),
              const Icon(
                Icons.lock_reset,
                size: 70,
                color: accentColor,
              ),
              const SizedBox(height: 25),
              const Text(
                'Anna sähköpostiosoitteesi. Lähetämme sinulle palautuslinkin.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 25),

              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Sähköposti',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: loading ? null : _reset,
                  child: Text(
                    loading
                        ? 'LÄHETETÄÄN...'
                        : 'LÄHETÄ PALAUTUSLINKKI',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================================
// HOME
// ==========================================================

class HomePage extends StatefulWidget {
  final String languageCode;
  final Future<void> Function(String) changeLanguage;

  const HomePage({
    super.key,
    required this.languageCode,
    required this.changeLanguage,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int stl = 0;
  int streak = 0;
  int adsToday = 0;

  bool dailyClaimed = false;
  bool loading = true;
  bool adLoading = false;
  bool showingAd = false;

  DateTime? lastAdTime;
  RewardedAd? rewardedAd;

  Timer? cooldownTimer;

  AppLocalizations get t =>
      AppLocalizations(widget.languageCode);

  String get _userId =>
      FirebaseAuth.instance.currentUser?.uid ?? 'guest';

  String _key(String name) => '${name}_$_userId';

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadRewardedAd();

    cooldownTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) {
        if (mounted) setState(() {});
      },
    );
  }

  @override
  void dispose() {
    cooldownTimer?.cancel();
    rewardedAd?.dispose();
    super.dispose();
  }

  String _dateKey(DateTime date) {
    return '${date.year}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  String get today => _dateKey(DateTime.now());

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();

    final adDate = prefs.getString(_key('ad_date')) ?? '';
    int savedAds = prefs.getInt(_key('ads_today')) ?? 0;

    if (adDate != today) {
      savedAds = 0;

      await prefs.setString(_key('ad_date'), today);
      await prefs.setInt(_key('ads_today'), 0);
    }

    final lastAdString = prefs.getString(_key('last_ad_time'));

    if (!mounted) return;

    setState(() {
      stl = prefs.getInt(_key('stl_balance')) ?? 0;
      streak = prefs.getInt(_key('streak')) ?? 0;
      adsToday = savedAds;

      dailyClaimed =
          prefs.getString(_key('last_daily')) == today;

      lastAdTime = lastAdString == null
          ? null
          : DateTime.tryParse(lastAdString);

      loading = false;
    });
  }

  // ========================================================
  // DAILY REWARD
  // ========================================================

  Future<void> _dailyClaim() async {
    if (dailyClaimed) {
      _message(t.get('claimed'));
      return;
    }

    final prefs = await SharedPreferences.getInstance();

    final lastDate =
        prefs.getString(_key('last_daily')) ?? '';

    final yesterday = _dateKey(
      DateTime.now().subtract(const Duration(days: 1)),
    );

    final newStreak =
        lastDate == yesterday ? streak + 1 : 1;

    // Päivä 1-6 = +3 STL, päivä 7 = +7 STL
    final reward = newStreak >= 7 ? 7 : 3;
    final newBalance = stl + reward;

    await prefs.setInt(_key('stl_balance'), newBalance);
    await prefs.setInt(_key('streak'), newStreak);
    await prefs.setString(_key('last_daily'), today);

    if (!mounted) return;

    setState(() {
      stl = newBalance;
      streak = newStreak;
      dailyClaimed = true;
    });

    _message('+$reward STL! 🐱');
  }

  // ========================================================
  // AD COOLDOWN
  // ========================================================

  bool get canWatchAd {
    if (lastAdTime == null) return true;

    final next =
        lastAdTime!.add(adCooldown);

    return !DateTime.now().isBefore(next);
  }

  Duration get remainingAdTime {
    if (lastAdTime == null) {
      return Duration.zero;
    }

    final next = lastAdTime!.add(adCooldown);
    final remaining = next.difference(DateTime.now());

    return remaining.isNegative
        ? Duration.zero
        : remaining;
  }

  String get cooldownText {
    final remaining = remainingAdTime;

    if (remaining == Duration.zero) {
      return t.get('adAvailable');
    }

    final hours = remaining.inHours;
    final minutes = remaining.inMinutes.remainder(60);

    if (hours > 0) {
      return '${t.get('nextAd')}: ${hours} h ${minutes} min';
    }

    return '${t.get('nextAd')}: $minutes min';
  }

  // ========================================================
  // LOAD AD
  // ========================================================

  void _loadRewardedAd() {
    if (adLoading || rewardedAd != null) return;

    if (mounted) {
      setState(() => adLoading = true);
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

          setState(() {
            rewardedAd = ad;
            adLoading = false;
          });
        },
        onAdFailedToLoad: (_) {
          if (!mounted) return;

          setState(() {
            rewardedAd = null;
            adLoading = false;
          });
        },
      ),
    );
  }

  // ========================================================
  // WATCH AD
  // ========================================================

  Future<void> _watchAd() async {
    if (showingAd) return;

    if (adsToday >= maxAdsPerDay) {
      _message(t.get('dailyLimitReached'));
      return;
    }

    if (!canWatchAd) {
      _message(
        '${t.get('nextAd')} '
        '${cooldownText.replaceFirst('${t.get('nextAd')}: ', '')}',
      );
      return;
    }

    if (rewardedAd == null) {
      _message(t.get('adLoading'));
      _loadRewardedAd();
      return;
    }

    final ad = rewardedAd!;
    rewardedAd = null;

    setState(() => showingAd = true);

    var earnedReward = false;

    ad.fullScreenContentCallback =
        FullScreenContentCallback<RewardedAd>(
      onAdDismissedFullScreenContent: (ad) async {
        ad.dispose();

        if (earnedReward) {
          await _addAdReward();
        }

        if (mounted) {
          setState(() => showingAd = false);
        }

        _loadRewardedAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();

        if (mounted) {
          setState(() => showingAd = false);
        }

        _message('Mainoksen näyttäminen epäonnistui.');
        _loadRewardedAd();
      },
    );

    ad.show(
      onUserEarnedReward: (ad, reward) {
        earnedReward = true;
      },
    );
  }

  // ========================================================
  // ADD AD REWARD
  // ========================================================

  Future<void> _addAdReward() async {
    if (adsToday >= maxAdsPerDay) return;

    final prefs = await SharedPreferences.getInstance();

    final now = DateTime.now();
    final newBalance = stl + adReward;
    final newAds = adsToday + 1;

    await prefs.setInt(
      _key('stl_balance'),
      newBalance,
    );

    await prefs.setInt(
      _key('ads_today'),
      newAds,
    );

    await prefs.setString(
      _key('ad_date'),
      _dateKey(now),
    );

    await prefs.setString(
      _key('last_ad_time'),
      now.toIso8601String(),
    );

    if (!mounted) return;

    setState(() {
      stl = newBalance;
      adsToday = newAds;
      lastAdTime = now;
    });

    _message('+$adReward STL! 🐱');
  }

  // ========================================================
  // LANGUAGE
  // ========================================================

  void _openLanguageDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(t.get('selectLanguage')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: AppLocalizations.supportedLanguages.entries
                .map(
                  (entry) => ListTile(
                    title: Text(entry.value),
                    trailing:
                        widget.languageCode == entry.key
                            ? const Icon(
                                Icons.check,
                                color: accentColor,
                              )
                            : null,
                    onTap: () async {
                      await widget.changeLanguage(entry.key);

                      if (dialogContext.mounted) {
                        Navigator.pop(dialogContext);
                      }
                    },
                  ),
                )
                .toList(),
          ),
        );
      },
    );
  }

  void _message(String text) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(text)),
      );
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const LoadingPage();

    final user = FirebaseAuth.instance.currentUser;
    final fact = catFacts[
        DateTime.now().day % catFacts.length]
        .text(widget.languageCode);

    final adButtonEnabled =
        adsToday < maxAdsPerDay &&
        canWatchAd &&
        rewardedAd != null &&
        !adLoading &&
        !showingAd;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'STELLURIINI',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.language),
            onPressed: _openLanguageDialog,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),

      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // PROFILE
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const CatAvatar(size: 105),
                      const SizedBox(height: 12),
                      Text(
                        t.get('stella'),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        user?.email ?? '',
                        style: const TextStyle(
                          color: Colors.white60,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // BALANCE
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(26),
                  child: Column(
                    children: [
                      Text(
                        t.get('yourBalance'),
                        style: const TextStyle(
                          color: Colors.white60,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$stl',
                        style: const TextStyle(
                          fontSize: 56,
                          fontWeight: FontWeight.bold,
                          color: accentColor,
                        ),
                      ),
                      const Text(
                        'STL',
                        style: TextStyle(
                          fontSize: 18,
                          letterSpacing: 3,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        t.get('virtualPoints'),
                        style: const TextStyle(
                          color: Colors.white54,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // DAILY
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.card_giftcard,
                        size: 42,
                        color: accentColor,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        t.get('dailyClaim'),
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${t.get('streak')}: 🔥 $streak',
                        style: const TextStyle(
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 15),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed:
                              dailyClaimed ? null : _dailyClaim,
                          icon: const Icon(Icons.redeem),
                          label: Text(
                            dailyClaimed
                                ? t.get('claimed')
                                : t.get('dailyReward'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // ADS
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.play_circle_outline,
                        size: 45,
                        color: accentColor,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        t.get('watchEarn'),
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '${t.get('dailyLimit')}: '
                        '$adsToday / $maxAdsPerDay',
                        style: const TextStyle(
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        adsToday >= maxAdsPerDay
                            ? t.get('dailyLimitReached')
                            : cooldownText,
                        style: const TextStyle(
                          color: Colors.white60,
                        ),
                      ),
                      const SizedBox(height: 15),

                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed:
                              adButtonEnabled ? _watchAd : null,
                          icon: adLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.black,
                                  ),
                                )
                              : const Icon(Icons.play_arrow),
                          label: Text(
                            adLoading
                                ? t.get('adLoading')
                                : showingAd
                                    ? t.get('adShowing')
                                    : adsToday >= maxAdsPerDay
                                        ? t.get('limitReached')
                                        : !canWatchAd
                                            ? cooldownText
                                            : rewardedAd == null
                                                ? t.get('adUnavailable')
                                                : t.get('watchAd'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // CAT FACT
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    children: [
                      Text(
                        t.get('stellaFacts'),
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Icon(
                        Icons.pets,
                        size: 45,
                        color: accentColor,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        fact,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // INFO
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 38,
                        color: accentColor,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        t.get('info'),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 19,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        t.get('solanaToken'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        t.get('stellaCompany'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white60,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================================
// CAT AVATAR
// ==========================================================

class CatAvatar extends StatelessWidget {
  final double size;

  const CatAvatar({
    super.key,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: Image.asset(
        'assets/stella.jpg',
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          return Container(
            width: size,
            height: size,
            color: cardColor,
            alignment: Alignment.center,
            child: Icon(
              Icons.pets,
              size: size * 0.5,
              color: accentColor,
            ),
          );
        },
      ),
    );
  }
}

// ==========================================================
// LOCALIZATIONS
// ==========================================================

class AppLocalizations {
  final String languageCode;

  const AppLocalizations(this.languageCode);

  static const supportedLanguages = {
    'fi': '🇫🇮 Suomi',
    'en': '🇬🇧 English',
  };

  String get(String key) {
    return _translations[languageCode]?[key] ??
        _translations['fi']?[key] ??
        key;
  }

  static const _translations = {
    'fi': {
      'selectLanguage': 'Valitse kieli',
      'yourBalance': 'SALDOSI',
      'dailyClaim': 'PÄIVITTÄINEN PALKINTO',
      'dailyReward': 'HAE PÄIVÄN PALKINTO',
      'claimed': 'KÄYTETTY',
      'streak': 'PUTKI',
      'watchEarn': 'KATSO JA ANSAITSE',
      'watchAd': 'Katso mainos +3 STL',
      'dailyLimit': 'PÄIVÄRAJA',
      'dailyLimitReached': 'Päivän mainosraja on täynnä.',
      'limitReached': 'PÄIVÄRAJA TÄYNNÄ',
      'nextAd': 'Seuraava mainos',
      'adAvailable': 'Mainos on saatavilla!',
      'adLoading': 'MAINOSTA LADATAAN...',
      'adShowing': 'MAINOS AVAUTUU...',
      'adUnavailable': 'MAINOS EI SAATAVILLA',
      'stella': '🐱 Stella',
      'stellaFacts': 'STELLAN KISSAFAKTA',
      'info': 'TIETOJA',
      'solanaToken':
          'Stelluriini on Solana-verkossa oleva yhteisötokeni.',
      'stellaCompany':
          '🐱 Stella pitää sinulle seuraa Stelluriinin parissa!',
      'virtualPoints': 'Virtuaalisia sovelluspisteitä',
    },
    'en': {
      'selectLanguage': 'Select language',
      'yourBalance': 'YOUR BALANCE',
      'dailyClaim': 'DAILY REWARD',
      'dailyReward': 'CLAIM DAILY REWARD',
      'claimed': 'CLAIMED',
      'streak': 'STREAK',
      'watchEarn': 'WATCH & EARN',
      'watchAd': 'Watch ad +3 STL',
      'dailyLimit': 'DAILY LIMIT',
      'dailyLimitReached': 'The daily ad limit has been reached.',
      'limitReached': 'DAILY LIMIT REACHED',
      'nextAd': 'Next ad',
      'adAvailable': 'Ad is available!',
      'adLoading': 'LOADING AD...',
      'adShowing': 'OPENING AD...',
      'adUnavailable': 'AD UNAVAILABLE',
      'stella': '🐱 Stella',
      'stellaFacts': "STELLA'S CAT FACT",
      'info': 'INFORMATION',
      'solanaToken':
          'Stelluriini is a community token on the Solana network.',
      'stellaCompany':
          '🐱 Stella keeps you company while using Stelluriini!',
      'virtualPoints': 'Virtual in-app points',
    },
  };
}

// ==========================================================
// CAT FACTS
// ==========================================================

class CatFact {
  final Map<String, String> translations;

  const CatFact(this.translations);

  String text(String languageCode) {
    return translations[languageCode] ??
        translations['fi'] ??
        translations['en'] ??
        '';
  }
}

const List<CatFact> catFacts = [
  CatFact({
    'fi': 'Kissat nukkuvat usein noin 12–16 tuntia vuorokaudessa.',
    'en': 'Cats often sleep around 12–16 hours a day.',
  }),
  CatFact({
    'fi': 'Kissan viikset ovat erittäin herkkiä tuntoelimiä.',
    'en': 'A cat’s whiskers are very sensitive sensory organs.',
  }),
  CatFact({
    'fi': 'Kissan nenän kuvio on yksilöllinen.',
    'en': 'Every cat has a unique nose pattern.',
  }),
  CatFact({
    'fi': 'Kissat voivat kuulla erittäin korkeita ääniä.',
    'en': 'Cats can hear very high-frequency sounds.',
  }),
  CatFact({
    'fi': 'Kissan kynnet ovat sisäänvedettävät.',
    'en': 'Cats have retractable claws.',
  }),
  CatFact({
    'fi': 'Kissat käyttävät häntäänsä tasapainon apuna.',
    'en': 'Cats use their tails to help with balance.',
  }),
  CatFact({
    'fi': 'Hidas silmien räpytys voi olla kissan ystävällinen tervehdys.',
    'en': 'A slow blink can be a friendly greeting from a cat.',
  }),
];