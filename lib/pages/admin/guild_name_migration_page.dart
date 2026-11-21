import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class GuildNameMigrationPage extends StatefulWidget {
  const GuildNameMigrationPage({super.key});
  @override
  State<GuildNameMigrationPage> createState() => _GuildNameMigrationPageState();
}


class _GuildNameMigrationPageState extends State<GuildNameMigrationPage> {
  static const bg = Color(0xFF120B24);
  static const card = Color(0xFF21113B);
  static const purple = Color(0xFFB58CFF);
  static const gold = Color(0xFFFFD166);
  static const green = Color(0xFF65D6A0);
  static const red = Color(0xFFFF6B7A);
  static const white = Color(0xFFF8F4FF);
  static const secondary = Color(0xFFBDB4D1);

  final _auth = FirebaseAuth.instance;
  final _functions = FirebaseFunctions.instanceFor(region: 'us-central1');
  bool _checking = true;
  bool _admin = false;
  bool _busy = false;
  String? _error;
  Map<String, dynamic>? _preview;
  Map<String, dynamic>? _result;


  @override
  void initState() {
    super.initState();
    _checkAdmin();
  }


  Future<void> _checkAdmin() async {
    try {
      final user = _auth.currentUser;
      final token = user == null ? null : await user.getIdTokenResult(true);
      if (!mounted) return;
      setState(() {
        _checking = false;
        _admin = token?.claims?['admin'] == true;
        if (!_admin) _error = 'Vain admin voi käyttää tätä työkalua.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _checking = false;
        _admin = false;
        _error = 'Admin-oikeuden tarkistus epäonnistui.';
      });
    }
  }


  Future<Map<String, dynamic>> _callMigration(bool dryRun) async {
    final callable = _functions.httpsCallable(
      'migrateGuildNames',
      options: HttpsCallableOptions(timeout: const Duration(minutes: 10)),
    );
    final response = await callable.call({'dryRun': dryRun});
    return Map<String, dynamic>.from(response.data as Map);
  }


  int _int(dynamic value) => value is num ? value.toInt() : int.tryParse(value?.toString() ?? '') ?? 0;


  Future<void> _preview() async {
    if (!_admin || _busy) return;
    setState(() { _busy = true; _error = null; _preview = null; _result = null; });
    try {
      final response = await _callMigration(true);
      if (!mounted) return;
      setState(() { _preview = response; _busy = false; });
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      setState(() { _busy = false; _error = e.message ?? 'Esitarkistus epäonnistui (${e.code}).'; });
    } catch (_) {
      if (!mounted) return;
      setState(() { _busy = false; _error = 'Esitarkistus epäonnistui. Yritä uudelleen.'; });
    }
  }


  Future<void> _execute() async {
    final p = _preview;
    if (!_admin || _busy || p == null || p['success'] != true || _int(p['conflictCount']) != 0) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: card,
        title: const Text('Suorita Guild-nimien migraatio?', style: TextStyle(color: white)),
        content: const Text('Migraatio luo puuttuvat Guild-nimivaraukset ja avaa Guildien luomisen. Toimintoa ei voi peruuttaa. Esitarkistus tehdään uudelleen ennen kirjoitusta.', style: TextStyle(color: secondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Peruuta')),
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: gold, foregroundColor: bg), onPressed: () => Navigator.pop(ctx, true), child: const Text('Suorita')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() { _busy = true; _error = null; _result = null; });
    try {
      // Fresh dry-run immediately before actual write.
      final latestPreview = await _callMigration(true);
      if (latestPreview['success'] != true || _int(latestPreview['conflictCount']) != 0) {
        if (!mounted) return;
        setState(() { _preview = latestPreview; _busy = false; _error = 'Esitarkistus ei enää hyväksy migraatiota. Kirjoituksia ei tehty.'; });
        return;
      }
      final result = await _callMigration(false);
      if (!mounted) return;
      setState(() { _result = result; _preview = null; _busy = false; });
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      setState(() { _busy = false; _error = e.message ?? 'Migraatio epäonnistui (${e.code}).'; });
    } catch (_) {
      if (!mounted) return;
      setState(() { _busy = false; _error = 'Migraatio epäonnistui. Tarkista Firebase Functions -lokit.'; });
    }
  }


  Widget _panel(String title, String message, Color tint, IconData icon) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(14), border: Border.all(color: tint.withValues(alpha: .4))),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: tint, size: 25), const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: TextStyle(color: tint, fontWeight: FontWeight.bold)),
        const SizedBox(height: 5), Text(message, style: const TextStyle(color: secondary, fontSize: 13)),
      ])),
    ]),
  );


  Widget _metric(String label, dynamic value, Color tint) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: const Color(0xFF1A0E31), borderRadius: BorderRadius.circular(12)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(value?.toString() ?? '0', style: TextStyle(color: tint, fontSize: 22, fontWeight: FontWeight.bold)),
      const SizedBox(height: 4), Text(label, style: const TextStyle(color: secondary, fontSize: 12)),
    ]),
  );


  Widget _previewCard() {
    final data = _preview!;
    final conflicts = data['conflicts'] is List ? data['conflicts'] as List : <dynamic>[];
    final safe = data['success'] == true && _int(data['conflictCount']) == 0;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _panel(safe ? 'Esitarkistus hyväksytty' : 'Ristiriitoja löytyi', data['message']?.toString() ?? '', safe ? green : red, safe ? Icons.check_circle_outline : Icons.warning_amber),
      const SizedBox(height: 12),
      GridView.count(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisCount: 2, crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: 1.65, children: [
        _metric('Guildit', data['guildCount'], white),
        _metric('Kelvolliset nimet', data['validGuildNames'], purple),
        _metric('Jo rekisterissä', data['alreadyRegistered'], green),
        _metric('Puuttuvat varaukset', data['missingReservations'], gold),
        _metric('Ristiriidat', data['conflictCount'], conflicts.isEmpty ? green : red),
      ]),
      if (conflicts.isNotEmpty) ...[
        const SizedBox(height: 12),
        const Text('Ristiriidat', style: TextStyle(color: red, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        ...conflicts.map((item) {
          final m = item is Map ? item : <String, dynamic>{};
          final name = m['name']?.toString() ?? 'Guild ilman nimeä';
          final info = m['message']?.toString() ?? m['type']?.toString() ?? 'Tuntematon';
          return Container(margin: const EdgeInsets.only(bottom: 7), padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(10)), child: Text('$name — $info', style: const TextStyle(color: white, fontSize: 12)));
        }),
      ],
      if (safe) ...[
        const SizedBox(height: 14),
        SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: _busy ? null : _execute, icon: const Icon(Icons.lock_open), label: const Text('Suorita nimirekisterin migraatio'), style: ElevatedButton.styleFrom(backgroundColor: gold, foregroundColor: bg, padding: const EdgeInsets.symmetric(vertical: 14))),
        const SizedBox(height: 5),
        const Text('Varsinainen migraatio vaatii erillisen vahvistuksen.', textAlign: TextAlign.center, style: TextStyle(color: secondary, fontSize: 11)),
      ],
    ]);
  }


  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: bg,
    appBar: AppBar(backgroundColor: bg, foregroundColor: white, title: const Text('Guild-nimirekisteri')),
    body: SafeArea(child: _checking
      ? const Center(child: CircularProgressIndicator(color: purple))
      : !_admin
        ? Padding(padding: const EdgeInsets.all(20), child: Center(child: _panel('Admin-oikeus vaaditaan', _error ?? 'Kirjaudu admin-tilillä.', gold, Icons.lock_outline)))
        : ListView(padding: const EdgeInsets.all(16), children: [
            _panel('Turvallinen alustus', 'Esitarkistus (dry-run) ei kirjoita Firestoreen. Varsinainen migraatio vaatii erillisen vahvistuksen.', purple, Icons.shield_outlined),
            const SizedBox(height: 12),
            SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: _busy ? null : _preview, icon: const Icon(Icons.fact_check_outlined), label: const Text('Tee turvallinen esitarkistus'), style: ElevatedButton.styleFrom(backgroundColor: purple, foregroundColor: bg, padding: const EdgeInsets.symmetric(vertical: 14))),
            if (_busy) ...[const SizedBox(height: 12), const Center(child: CircularProgressIndicator(color: purple)), const SizedBox(height: 6), const Text('Käsitellään…', textAlign: TextAlign.center, style: TextStyle(color: secondary))],
            if (_error != null && !_busy) ...[const SizedBox(height: 12), _panel('Virhe', _error!, red, Icons.error_outline)],
            if (_preview != null) ...[const SizedBox(height: 12), _previewCard()],
            if (_result != null) ...[const SizedBox(height: 12), _panel(_result!['success'] == true ? 'Migraatio valmis' : 'Migraatio epäonnistui', _result!['message']?.toString() ?? '', _result!['success'] == true ? green : red, _result!['success'] == true ? Icons.check_circle : Icons.error_outline)],
          ]),
  );
}
