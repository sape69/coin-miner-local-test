import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class GuildNameMigrationPage extends StatefulWidget {
  const GuildNameMigrationPage({super.key});

  @override
  State<GuildNameMigrationPage> createState() =>
      _GuildNameMigrationPageState();
}

class _GuildNameMigrationPageState
    extends State<GuildNameMigrationPage> {
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

  bool _loading = false;
  bool _isAdmin = false;
  bool _migrationCompleted = false;

  Map<String, dynamic>? _previewData;
  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    _checkAdmin();
  }

  // ============================================================
  // ADMIN CHECK
  // ============================================================

  Future<void> _checkAdmin() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        throw Exception('You must be logged in.');
      }

      final tokenResult = await user.getIdTokenResult(true);
      final claims = tokenResult.claims ?? {};

      final isAdmin = claims['admin'] == true;

      if (!mounted) return;

      setState(() {
        _isAdmin = isAdmin;
        _loading = false;
      });

      if (!isAdmin) {
        setState(() {
          _errorMessage = 'Admin access required.';
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _errorMessage = e.toString();
      });
    }
  }

  // ============================================================
  // DRY RUN
  // ============================================================

  Future<void> _runDryRun() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
      _successMessage = null;
      _previewData = null;
    });

    try {
      final callable = _functions.httpsCallable('migrateGuildNames');

      final result = await callable.call({
        'dryRun': true,
      });

      final data = Map<String, dynamic>.from(result.data as Map);

      if (!mounted) return;

      setState(() {
        _previewData = data;
        _loading = false;
      });

      if (data['success'] == true) {
        _showMessage('Dry Run completed successfully.');
      } else {
        setState(() {
          _errorMessage =
              data['message']?.toString() ?? 'Dry Run failed.';
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _errorMessage = e.toString();
      });
    }
  }

  // ============================================================
  // EXECUTE MIGRATION
  // ============================================================

  Future<void> _executeMigration() async {
    final preview = _previewData;

    if (preview == null) {
      _showError('Run Dry Run before migration.');
      return;
    }

    if (preview['success'] != true) {
      _showError('Dry Run was not successful.');
      return;
    }

    final conflicts = preview['conflictCount'] ?? 0;

    if (conflicts != 0) {
      _showError(
        'Migration cannot run while conflicts exist.',
      );
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
      // Recheck database immediately before the actual migration.
      final dryRunCallable =
          _functions.httpsCallable('migrateGuildNames');

      final dryRunResult = await dryRunCallable.call({
        'dryRun': true,
      });

      final latestPreview =
          Map<String, dynamic>.from(dryRunResult.data as Map);

      if (latestPreview['success'] != true) {
        throw Exception(
          'The latest Dry Run was not successful.',
        );
      }

      if ((latestPreview['conflictCount'] ?? 0) != 0) {
        throw Exception(
          'Name conflicts were detected. Migration stopped.',
        );
      }

      // Execute migration.
      final migrationCallable =
          _functions.httpsCallable('migrateGuildNames');

      final migrationResult = await migrationCallable.call({
        'dryRun': false,
      });

      final data =
          Map<String, dynamic>.from(migrationResult.data as Map);

      if (!mounted) return;

      if (data['success'] == true) {
        setState(() {
          _loading = false;
          _migrationCompleted = true;
          _previewData = data;
          _successMessage =
              data['message']?.toString() ??
                  'Guild name migration completed successfully.';
        });
      } else {
        setState(() {
          _loading = false;
          _errorMessage =
              data['message']?.toString() ??
                  'Migration failed.';
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _errorMessage = e.toString();
      });
    }
  }

  // ============================================================
  // CONFIRMATION
  // ============================================================

  Future<bool?> _showMigrationConfirmation() {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: cardColor,
          title: const Text(
            'Run Guild Name Migration?',
            style: TextStyle(color: textColor),
          ),
          content: const Text(
            'This will register Guild name reservations '
            'and mark the migration as completed.\n\n'
            'This operation is intended to be performed once.',
            style: TextStyle(color: secondaryColor),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(
                'Cancel',
                style: TextStyle(color: secondaryColor),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: purpleColor,
                foregroundColor: backgroundColor,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Run Migration'),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // MESSAGES
  // ============================================================

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: surfaceColor,
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;

    setState(() {
      _errorMessage = message;
    });
  }

  // ============================================================
  // UI HELPERS
  // ============================================================

  Widget _buildMetricCard(
    String title,
    dynamic value,
    Color accent,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accent.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: accent, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: secondaryColor,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  value?.toString() ?? '0',
                  style: TextStyle(
                    color: accent,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    final completed =
        _migrationCompleted ||
        _previewData?['migrationCompleted'] == true ||
        _previewData?['status'] == 'completed';

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
                  completed
                      ? 'Migration Completed'
                      : 'Migration Not Confirmed',
                  style: TextStyle(
                    color: completed ? successColor : goldColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  completed
                      ? 'Guild name initialization is complete.'
                      : 'Run Dry Run to inspect the current status.',
                  style: const TextStyle(
                    color: secondaryColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    final data = _previewData;

    if (data == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Migration Preview',
          style: TextStyle(
            color: pinkColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _buildMetricCard(
          'Guilds found',
          data['guildCount'],
          purpleColor,
          Icons.groups,
        ),
        const SizedBox(height: 10),
        _buildMetricCard(
          'Valid Guild names',
          data['validGuildNames'],
          pinkColor,
          Icons.verified,
        ),
        const SizedBox(height: 10),
        _buildMetricCard(
          'Already registered',
          data['alreadyRegistered'],
          successColor,
          Icons.check_circle_outline,
        ),
        const SizedBox(height: 10),
        _buildMetricCard(
          'Missing reservations',
          data['missingReservations'],
          goldColor,
          Icons.pending_actions,
        ),
        const SizedBox(height: 10),
        _buildMetricCard(
          'Conflicts',
          data['conflictCount'],
          (data['conflictCount'] ?? 0) > 0
              ? errorColor
              : successColor,
          Icons.warning_amber_rounded,
        ),
        const SizedBox(height: 14),
        if (data['message'] != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              data['message'].toString(),
              style: const TextStyle(
                color: secondaryColor,
              ),
            ),
          ),
        const SizedBox(height: 12),
        if ((data['conflicts'] is List) &&
            (data['conflicts'] as List).isNotEmpty)
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
        border: Border.all(
          color: errorColor.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Detected conflicts',
            style: TextStyle(
              color: errorColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...conflicts.take(20).map(
                (conflict) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    conflict.toString(),
                    style: const TextStyle(
                      color: textColor,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
          if (conflicts.length > 20)
            Text(
              '+ ${conflicts.length - 20} more conflicts',
              style: const TextStyle(color: secondaryColor),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
    required Color color,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: _loading ? null : onPressed,
        icon: Icon(icon),
        label: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: backgroundColor,
          disabledBackgroundColor: color.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

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
            ? const Center(
                child: CircularProgressIndicator(
                  color: purpleColor,
                ),
              )
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
            const Icon(
              Icons.lock_outline,
              color: errorColor,
              size: 64,
            ),
            const SizedBox(height: 16),
            const Text(
              'Admin Access Required',
              style: TextStyle(
                color: textColor,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'You do not have permission to access this page.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: secondaryColor),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: _checkAdmin,
              child: const Text(
                'Retry',
                style: TextStyle(color: purpleColor),
              ),
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
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [surfaceColor, cardColor],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: purpleColor.withValues(alpha: 0.35),
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.groups_rounded,
                  color: purpleColor,
                  size: 36,
                ),
                SizedBox(height: 12),
                Text(
                  'Guild Name Initialization',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Initialize name reservations for existing Guilds. '
                  'Run the preview before executing the migration.',
                  style: TextStyle(
                    color: secondaryColor,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          _buildStatusCard(),

          const SizedBox(height: 20),

          // Dry Run
          _buildActionButton(
            label: 'Run Dry Run',
            icon: Icons.preview,
            color: purpleColor,
            onPressed: _runDryRun,
          ),

          const SizedBox(height: 12),

          // Actual migration
          _buildActionButton(
            label: 'Execute Migration',
            icon: Icons.rocket_launch,
            color: goldColor,
            onPressed: _migrationCompleted
                ? null
                : _executeMigration,
          ),

          const SizedBox(height: 20),

          if (_successMessage != null)
            _buildMessageCard(
              _successMessage!,
              successColor,
              Icons.check_circle,
            ),

          if (_errorMessage != null)
            _buildMessageCard(
              _errorMessage!,
              errorColor,
              Icons.error_outline,
            ),

          if (_previewData != null) ...[
            const SizedBox(height: 16),
            _buildPreview(),
          ],

          const SizedBox(height: 24),

          // Warning
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: goldColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: goldColor.withValues(alpha: 0.3),
              ),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: goldColor,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Migration is intended to be run once. '
                    'Always inspect Dry Run results before executing.',
                    style: TextStyle(
                      color: secondaryColor,
                      height: 1.5,
                    ),
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

  Widget _buildMessageCard(
    String message,
    Color color,
    IconData icon,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: color,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}