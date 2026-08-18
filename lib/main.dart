import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const CoinMinerApp());
}

class CoinMinerApp extends StatelessWidget {
  const CoinMinerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'COIN MINER',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0E1119),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.amber,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  double coins = 0.0;
  bool minedToday = false;
  bool loading = true;

  static const double dailyReward = 10.0;
  static const double adReward = 5.0;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();

    final savedCoins = prefs.getDouble('coins') ?? 0.0;
    final lastMineDate = prefs.getString('lastMineDate');

    final today = dateKey(DateTime.now());

    setState(() {
      coins = savedCoins;
      minedToday = lastMineDate == today;
      loading = false;
    });
  }

  String dateKey(DateTime date) {
    return '${date.year}-${date.month}-${date.day}';
  }

  Future<void> mineCoins() async {
    if (minedToday) {
      showMessage('Olet jo louhinut tänään.');
      return;
    }

    final prefs = await SharedPreferences.getInstance();

    final newBalance = coins + dailyReward;
    final today = dateKey(DateTime.now());

    await prefs.setDouble('coins', newBalance);
    await prefs.setString('lastMineDate', today);

    setState(() {
      coins = newBalance;
      minedToday = true;
    });

    showMessage('+10 COINS lisätty!');
  }

  Future<void> watchAdReward() async {
    // Tähän lisätään myöhemmin oikea AdMob rewarded-mainos.
    // Nyt painike antaa testissä +5 coinsia.

    final prefs = await SharedPreferences.getInstance();

    final newBalance = coins + adReward;

    await prefs.setDouble('coins', newBalance);

    setState(() {
      coins = newBalance;
    });

    showMessage('+5 COINS mainospalkkiona!');
  }

  Future<void> resetDemo() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('coins');
    await prefs.remove('lastMineDate');

    setState(() {
      coins = 0.0;
      minedToday = false;
    });

    showMessage('Demo nollattu.');
  }

  void showMessage(String text) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'COIN MINER',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF17131C),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 25),

                // COIN ICON
                const Icon(
                  Icons.currency_bitcoin,
                  size: 95,
                  color: Colors.amber,
                ),

                const SizedBox(height: 25),

                const Text(
                  'YOUR BALANCE',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white70,
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  coins.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 52,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                  ),
                ),

                const Text(
                  'COINS',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.white70,
                  ),
                ),

                const SizedBox(height: 45),

                // DAILY MINING BUTTON
                SizedBox(
                  width: double.infinity,
                  height: 62,
                  child: ElevatedButton.icon(
                   
