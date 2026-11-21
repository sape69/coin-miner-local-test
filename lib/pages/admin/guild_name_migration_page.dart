import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class GuildNameMigrationPage extends StatefulWidget {
  const GuildNameMigrationPage({super.key});

  @override
  State<GuildNameMigrationPage> createState() =>
      _GuildNameMigrationPageState();
}

class _GuildNameMigrationPageState extends State<GuildNameMigrationPage> {
  static const Color backgroundColor = Color(0xFF120B24);
  static const Color surfaceColor = Color(0xFF1A0E31);
  static const Color cardColor = Color(0xFF21113B);
  static const Color purpleColor = Color(0xFFB58CFF);
  static const Color pinkColor = Color(0xFFFFB7E8);
  static const Color goldColor = Color(0xFFFFD166);
  static const Color textColor = Color(0xFFF8F4FF);
  static const Color secondaryColor = Color(0xFFBDB4D1);
  static const Color successColor = Color(0xFF7DE3B0);
  static const Color errorColor = Color(0xFFFF7189);

  final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(region: 'us-central1');
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _loading = true;
  bool _isAdmin = false;
  bool _migrationCompleted = false;
  bool _statusReadFailed = false;

  Map<String, dynamic>? _previewData;
  String? _errorMessage;
  String? _successMessage;

  DocumentReference<Map<String, dynamic>> get _migrationRef =>
      _firestore.collection('guildSystem').doc('guildNameMigration');

  @override
  void initState() {
    super.initState();
    _initializePage();
  }

  Future<void> _initializePage() async {
    await _checkAdmin();
    if (!mounted || !_isAdmin) return;
    await _loadMigrationStatus();
  }

  // Admin token check.
  Future<void> _checkAdmin() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _errorMessage = null;
      });
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Kirjautuminen vaaditaan.');
      }

      final tokenResult = await user.getIdTokenResult(true);
      final claims = tokenResult.claims ?? <String, dynamic>{};
      final admin = claims['admin'] == true;

      if (!mounted) return;
      setState(() {
        _isAdmin = admin;
        _loading = false;
        if (!admin) _errorMessage = 'Admin-oikeus vaaditaan.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isAdmin = false;
        _loading = false;
        _errorMessage = _cleanError(e);
      });
    }
  }

  // Read the persisted migration status, so reopening this page still
  // displays completion. This read is informational; backend callable remains
  // the authority for whether migration can execute.
  Future<void> _loadMigrationStatus() async {
    try {
      final snapshot = await _migrationRef.get();
      final data = snapshot.data() ?? <String, dynamic>{};
      final completed = data['status'] == 'completed';

      if (!mounted) return;
      setState(() {
        _migrationCompleted = completed;
        _statusReadFailed = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _statusReadFailed = true;
      });
    }
  }

  Future<Map<String, dynamic>> _callMigration({required bool dryRun}) async {
    final callable = _functions.httpsCallable(
      'migrateGuildNames',
      options: HttpsCallableOptions(timeout: const Duration(minutes: 9)),
    );
    final result = await callable.call(<String, dynamic>{'dryRun': dryRun});
    if (result.data is! Map) {
      throw Exception('Palvelin palautti virheellisen vastauksen.');
    }
    return Map<String, dynamic>.from(result.data as Map);
  }

  Future<void> _runDryRun() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
      _successMessage = null;
      _previewData = null;
    });

    try {
      final data = await _callMigration(dryRun: true);
      if (!mounted) return;
      setState(() {
        _previewData = data;
        _loading = false;
      });

      if (data['success'] == true) {
        _showMessage('Dry Run onnistui. Mitään ei kirjoitettu.');
      } else {
        setState(() {
          _errorMessage = data['message']?.toString() ??
              'Dry Run ei onnistunut.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = _cleanError(e);
      });
    }
  }

  Future<void> _executeMigration() async {
    if (_migrationCompleted) {
      _showError('Migraatio on jo merkitty valmiiksi.');
      return;
    }

    final preview = _previewData;
    if (preview == null) {
      _showError('Suorita Dry Run ennen migraatiota.');
      return;
    }
    if (preview['success'] != true) {
      _showError('Dry Run ei onnistunut. Migraatiota ei suoriteta.');
      return;
    }
    if (_asInt(preview['conflictCount']) != 0) {
      _showError('Nimiristiriitoja löytyi. Korjaa ne ennen migraatiota.');
      return;
    }

    final confirmed = await _showMigrationConfirmation();
    if (confirmed != true || !mounted) return;

    setState(() {
      _loading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      // Run a fresh preview immediately before attempting the migration.
      final latestPreview = await _callMigration(dryRun: true);
      if (latestPreview['success'] != true) {
        throw Exception(latestPreview['message']?.toString() ??
            'Viimeisin Dry Run ei onnistunut.');
      }
      if (_asInt(latestPreview['conflictCount']) != 0) {
        throw Exception('Uusia nimiristiriitoja löytyi. Migraatio pysäytettiin.');
      }

      final result = await _callMigration(dryRun: false);
      if (!mounted) return;

      if (result['success'] == true) {
        setState(() {
          _loading = false;
          _migrationCompleted = true;
          _previewData = result;
          _successMessage = result['message']?.toString() ??
              'Guild-nimien migraatio onnistui.';
        });
        // Re-read the persisted state after successful execution.
        await _loadMigrationStatus();
      } else {
        setState(() {
          _loading = false;
          _errorMessage = result['message']?.toString() ??
              'Migraatio epäonnistui.';
          _previewData = result;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = _cleanError(e);
      });
      // The callable may have completed before a network error surfaced.
      await _loadMigrationStatus();
    }
  }

  Future<bool?> _showMigrationConfirmation() {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: cardColor,
        title: const Text(
          'Suoritetaanko Guild-nimien migraatio?',
          style: TextStyle(color: textColor),
        ),
        content: const Text(
          'Tämä luo puuttuvat Guild-nimivaraukset ja merkitsee '
          'migraation valmiiksi. Tarkista Dry Run ennen jatkamista. '
          'Toiminto on tarkoitettu suoritettavaksi kerran.',
          style: TextStyle(color: secondaryColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Peruuta', style: TextStyle(color: secondaryColor)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: purpleColor,
              foregroundColor: backgroundColor,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Suorita migraatio'),
          ),
        ],
      ),
    );
  }

  String _cleanError(Object error) {
    final text = error.toString();
    return text.startsWith('Exception: ') ? text.substring(11) : text;
  }

  int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: surfaceColor),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    setState(() {
      _errorMessage = message;
    });
  }

  Widget _metricCard(String title, dynamic value, Color accent, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, color: accent, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: secondaryColor, fontSize: 12)),
                const SizedBox(height: 5),
                Text(
                  value?.toString() ?? '0',
                  style: TextStyle(color: accent, fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    final completed = _migrationCompleted ||
        _previewData?['migrationCompleted'] == true ||
        _previewData?['status'] == 'completed';

    final statusText = _statusReadFailed
        ? 'Tilaa ei voitu lukea Firestoresta. Backend tarkistaa tilan silti.'
        : completed
            ? 'Guild-nimien migraatio on merkitty valmiiksi.'
            : 'Migraation valmistumista ei ole vahvistettu.';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: completed
              ? successColor.withValues(alpha: 0.4)
              : goldColor.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          Icon(
            completed ? Icons.check_circle : Icons.info_outline,
            color: completed ? successColor : goldColor,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  completed ? 'Migraatio valmis' : 'Migraation tila',
                  style: TextStyle(
                    color: completed ? successColor : goldColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(statusText, style: const TextStyle(color: secondaryColor, fontSize: 12)),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Päivitä tila',
            onPressed: _loading ? null : _loadMigrationStatus,
            icon: const Icon(Icons.refresh, color: purpleColor),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    final data = _previewData;
    if (data == null) return const SizedBox.shrink();

    final isDryRun = data['dryRun'] == true;
    final hasPreviewMetrics = data.containsKey('validGuildNames') ||
        data.containsKey('missingReservations') ||
        data.containsKey('conflictCount');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isDryRun ? 'Dry Run - esikatselu' : 'Migraation tulos',
          style: const TextStyle(color: pinkColor, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        _metricCard('Guildit', data['guildCount'], purpleColor, Icons.groups),
        const SizedBox(height: 10),
        if (hasPreviewMetrics) ...[
          _metricCard('Kelvolliset nimet', data['validGuildNames'], pinkColor, Icons.verified),
          const SizedBox(height: 10),
          _metricCard('Jo rekisteröity', data['alreadyRegistered'], successColor, Icons.check_circle_outline),
          const SizedBox(height: 10),
          _metricCard('Puuttuvat varaukset', data['missingReservations'], goldColor, Icons.pending_actions),
          const SizedBox(height: 10),
        ] else ...[
          _metricCard('Luodut varaukset', data['registeredCount'], successColor, Icons.add_task),
          const SizedBox(height: 10),
          _metricCard('Jo rekisteröity', data['alreadyRegistered'], pinkColor, Icons.check_circle_outline),
          const SizedBox(height: 10),
        ],
        _metricCard(
          'Ristiriidat',
          data['conflictCount'],
          _asInt(data['conflictCount']) > 0 ? errorColor : successColor,
          Icons.warning_amber_rounded,
        ),
        const SizedBox(height: 14),
        if (data['message'] != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: surfaceColor, borderRadius: BorderRadius.circular(12)),
            child: Text(data['message'].toString(), style: const TextStyle(color: secondaryColor)),
          ),
        const SizedBox(height: 12),
        if (data['conflicts'] is List && (data['conflicts'] as List).isNotEmpty)
          _buildConflictList(data['conflicts'] as List),
      ],
    );
  }

  Widget _buildConflictList(List conflicts) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: errorColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: errorColor.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Havaitut ristiriidat', style: TextStyle(color: errorColor, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...conflicts.take(20).map((conflict) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  conflict is Map
                      ? '${conflict['type'] ?? 'Ristiriita'}: ${conflict['name'] ?? conflict['message'] ?? conflict}'
                      : conflict.toString(),
                  style: const TextStyle(color: textColor, fontSize: 12),
                ),
              )),
          if (conflicts.length > 20)
            Text('+ ${conflicts.length - 20} muuta ristiriitaa', style: const TextStyle(color: secondaryColor)),
        ],
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
    required Color color,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: _loading || _migrationCompleted ? null : onPressed,
        icon: Icon(icon),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: backgroundColor,
          disabledBackgroundColor: color.withValues(alpha: 0.25),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: surfaceColor,
        foregroundColor: textColor,
        title: const Text('Guild Name Migration'),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: purpleColor))
            : !_isAdmin
                ? _buildNotAdmin()
                : _buildAdminContent(),
      ),
    );
  }

  Widget _buildNotAdmin() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, color: errorColor, size: 64),
            const SizedBox(height: 16),
            const Text(
              'Admin access required',
              style: TextStyle(color: textColor, fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'Sinulla ei ole oikeutta avata tätä sivua.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: secondaryColor),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: _initializePage,
              child: const Text('Yritä uudelleen', style: TextStyle(color: purpleColor)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [surfaceColor, cardColor]),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: purpleColor.withValues(alpha: 0.35)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.groups_rounded, color: purpleColor, size: 36),
                SizedBox(height: 12),
                Text(
                  'Guild Name Initialization',
                  style: TextStyle(color: textColor, fontSize: 21, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'Tarkista nykyiset Guild-nimet. Dry Run ei tee tietokantakirjoituksia. '
                  'Varsinainen migraatio luo puuttuvat nimivaraukset.',
                  style: TextStyle(color: secondaryColor, height: 1.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildStatusCard(),
          const SizedBox(height: 20),
          _actionButton(
            label: 'Suorita Dry Run',
            icon: Icons.preview,
            color: purpleColor,
            onPressed: _runDryRun,
          ),
          const SizedBox(height: 12),
          _actionButton(
            label: 'Suorita migraatio',
            icon: Icons.rocket_launch,
            color: goldColor,
            onPressed: _executeMigration,
          ),
          const SizedBox(height: 20),
          if (_successMessage != null)
            _messageCard(_successMessage!, successColor, Icons.check_circle),
          if (_errorMessage != null)
            _messageCard(_errorMessage!, errorColor, Icons.error_outline),
          if (_previewData != null) ...[
            const SizedBox(height: 16),
            _buildPreview(),
          ],
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: goldColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: goldColor.withValues(alpha: 0.3)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.warning_amber_rounded, color: goldColor),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Migraatio on kertaluonteinen. Tarkista Dry Run -tulos aina ennen suoritusta. '
                    'Palvelin estää myös jo valmistuneen migraation uudelleensuorituksen.',
                    style: TextStyle(color: secondaryColor, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _messageCard(String message, Color color, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: TextStyle(color: color, height: 1.4))),
        ],
      ),
    );
  }
}
